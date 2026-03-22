#!/bin/bash
# configure_btrfs.sh - Configure Btrfs subvolumes (@, @home, @cache, @log, @docker, @tmp, @srv, @libvirt) for Linux Mint 22.2

# --- Dry-run support ---
DRY_RUN=false

usage() {
    echo "Usage: $0 [--dry-run | -n]"
    echo "  --dry-run, -n  Preview all operations without making changes"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run|-n)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        *)
            echo "Unknown option: $1"; usage ;;
    esac
done

run() {
    if $DRY_RUN; then
        echo "[DRY-RUN] $*"
    else
        "$@"
    fi
}

# Ensure running as root (skip check in dry-run mode)
if ! $DRY_RUN && [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (use sudo)."
    exit 1
fi

if $DRY_RUN; then
    echo "========================================"
    echo " DRY-RUN MODE - No changes will be made"
    echo "========================================"
    echo ""
fi

# Function to select partition from list
select_partition() {
    local partition_type=$1
    local type_name=""

    case "$partition_type" in
        efi)
            type_name="EFI"
            ;;
        btrfs)
            type_name="Btrfs"
            ;;
        swap)
            type_name="Swap"
            ;;
        *)
            echo "Error: Invalid partition type: $partition_type"
            exit 1
            ;;
    esac

    echo "" >&2
    echo "=== 选择 $type_name 分区 ===" >&2

    # Get all partitions and filter by type
    local -a candidates=()
    local -a devices=()

    # Get all block devices (partitions)
    while IFS= read -r line; do
        local name size fstype mountpoint uuid
        name=$(echo "$line" | awk '{print $1}')
        size=$(echo "$line" | awk '{print $2}')
        fstype=$(echo "$line" | awk '{print $3}')
        mountpoint=$(echo "$line" | awk '{print $4}')
        uuid=$(echo "$line" | awk '{print $5}')

        # Skip if name is empty
        [ -z "$name" ] && continue

        local device="/dev/$name"

        # Verify it's a block device
        [ ! -b "$device" ] && continue

        # Check if partition matches the filter
        local match=0
        case "$partition_type" in
            efi)
                # EFI: vfat or fat32
                if [[ "$fstype" == "vfat" ]] || [[ "$fstype" == "fat32" ]]; then
                    match=1
                fi
                ;;
            btrfs)
                # Btrfs: btrfs filesystem
                if [[ "$fstype" == "btrfs" ]]; then
                    match=1
                fi
                ;;
            swap)
                # Swap: swap type or any block device (could be unformatted)
                if [[ "$fstype" == "swap" ]] || [[ -z "$fstype" ]]; then
                    match=1
                fi
                ;;
        esac

        if [ $match -eq 1 ]; then
            candidates+=("$device|$size|$fstype|$mountpoint|$uuid")
            devices+=("$device")
        fi
    done < <(lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID -n -l | grep -E '^[a-z]')

    # If no candidates found, show all partitions
    if [ ${#candidates[@]} -eq 0 ]; then
        echo "未找到匹配的 $type_name 分区，显示所有可用分区：" >&2
        while IFS= read -r line; do
            local name size fstype mountpoint uuid
            name=$(echo "$line" | awk '{print $1}')
            size=$(echo "$line" | awk '{print $2}')
            fstype=$(echo "$line" | awk '{print $3}')
            mountpoint=$(echo "$line" | awk '{print $4}')
            uuid=$(echo "$line" | awk '{print $5}')

            [ -z "$name" ] && continue
            local device="/dev/$name"
            [ ! -b "$device" ] && continue

            candidates+=("$device|$size|$fstype|$mountpoint|$uuid")
            devices+=("$device")
        done < <(lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT,UUID -n -l | grep -E '^[a-z]')
    fi

    if [ ${#candidates[@]} -eq 0 ]; then
        echo "错误: 未找到任何可用分区。" >&2
        exit 1
    fi

    # Display formatted list
    echo "" >&2
    printf "%-4s %-20s %-12s %-12s %-40s %-20s\n" "编号" "设备" "大小" "文件系统" "UUID" "挂载点" >&2
    echo "------------------------------------------------------------------------------------------------------------------------" >&2

    local index=1
    for candidate in "${candidates[@]}"; do
        IFS='|' read -r device size fstype mountpoint uuid <<< "$candidate"
        [ -z "$fstype" ] && fstype="未格式化"
        [ -z "$mountpoint" ] && mountpoint="-"
        [ -z "$uuid" ] && uuid="-"
        printf "%-4s %-20s %-12s %-12s %-40s %-20s\n" "$index" "$device" "$size" "$fstype" "$uuid" "$mountpoint" >&2
        ((index++))
    done

    echo "" >&2
    echo -n "请选择 $type_name 分区编号 (1-${#candidates[@]}): " >&2
    read -r selection < /dev/tty

    # Validate input
    if [ -z "$selection" ]; then
        echo "错误: 未输入选择。" >&2
        exit 1
    fi

    if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
        echo "错误: 无效的输入，请输入数字。" >&2
        exit 1
    fi

    if [ "$selection" -lt 1 ] || [ "$selection" -gt ${#candidates[@]} ]; then
        echo "错误: 选择超出范围 (1-${#candidates[@]})。" >&2
        exit 1
    fi

    # Get selected device
    local selected_device="${devices[$((selection-1))]}"

    # Final validation
    if [ ! -b "$selected_device" ]; then
        echo "错误: $selected_device 不是有效的块设备。" >&2
        exit 1
    fi

    echo "已选择: $selected_device" >&2
    echo "$selected_device"
}

# Select Btrfs partition
BTRFS_DEV=$(select_partition btrfs)

# Select EFI partition
EFI_DEV=$(select_partition efi)

# Select swap partition
SWAP_DEV=$(select_partition swap)

# Get Btrfs UUID
BTRFS_UUID=$(lsblk -no UUID "$BTRFS_DEV")
if [ -z "$BTRFS_UUID" ]; then
    echo "Error: Failed to get UUID for $BTRFS_DEV."
    exit 1
fi
echo "Btrfs UUID: $BTRFS_UUID"

# Get EFI UUID
EFI_UUID=$(lsblk -no UUID "$EFI_DEV")
if [ -z "$EFI_UUID" ]; then
    echo "Error: Failed to get UUID for $EFI_DEV."
    exit 1
fi
echo "EFI UUID: $EFI_UUID"

# Get swap UUID
SWAP_UUID=$(lsblk -no UUID "$SWAP_DEV")
if [ -z "$SWAP_UUID" ]; then
    echo "Error: Failed to get UUID for $SWAP_DEV."
    exit 1
fi
echo "Swap UUID: $SWAP_UUID"

# --- [1/6] Unmount existing mounts and prepare ---
echo ""
echo "[1/6] 准备挂载环境..."
run umount -R /mnt 2>/dev/null
run mkdir -p /mnt

# Mount Btrfs top-level
run mount "$BTRFS_DEV" /mnt || { echo "Error: Failed to mount $BTRFS_DEV."; exit 1; }

# --- [2/6] Create subvolumes ---
echo "[2/6] 创建子卷..."
SUBVOLS=(@home @log @cache @docker @tmp @srv @libvirt)
for subvol in "${SUBVOLS[@]}"; do
    if btrfs subvolume list /mnt | grep -q "$subvol"; then
        echo "Subvolume $subvol already exists, skipping."
    else
        run btrfs subvolume create "/mnt/$subvol" || { echo "Error: Failed to create $subvol."; exit 1; }
    fi
done

# Unmount top-level
run umount /mnt

# --- [3/6] Mount subvolumes and migrate data ---
echo "[3/6] 挂载子卷并迁移数据..."
run mount -o subvol=@ "$BTRFS_DEV" /mnt || { echo "Error: Failed to mount @ subvolume."; exit 1; }
run mkdir -p /mnt_log /mnt_cache /mnt_home /mnt_var_lib_docker /mnt_var_tmp /mnt_srv /mnt_var_lib_libvirt_images
run mount -o subvol=@log "$BTRFS_DEV" /mnt_log || { echo "Error: Failed to mount @log."; exit 1; }
run mount -o subvol=@cache "$BTRFS_DEV" /mnt_cache || { echo "Error: Failed to mount @cache."; exit 1; }
run mount -o subvol=@home "$BTRFS_DEV" /mnt_home || { echo "Error: Failed to mount @home."; exit 1; }
run mount -o subvol=@docker "$BTRFS_DEV" /mnt_var_lib_docker || { echo "Error: Failed to mount @docker."; exit 1; }
run mount -o subvol=@tmp "$BTRFS_DEV" /mnt_var_tmp || { echo "Error: Failed to mount @tmp."; exit 1; }
run mount -o subvol=@srv "$BTRFS_DEV" /mnt_srv || { echo "Error: Failed to mount @srv."; exit 1; }
run mount -o subvol=@libvirt "$BTRFS_DEV" /mnt_var_lib_libvirt_images || { echo "Error: Failed to mount @libvirt."; exit 1; }

# Migrate data from existing directories to subvolumes
# Format: "source_path|destination_mount_point|display_name"
MIGRATE_DIRS=(
    "/mnt/var/log|/mnt_log|/var/log"
    "/mnt/var/cache|/mnt_cache|/var/cache"
    "/mnt/home|/mnt_home|/home"
    "/mnt/var/lib/docker|/mnt_var_lib_docker|/var/lib/docker"
    "/mnt/var/tmp|/mnt_var_tmp|/var/tmp"
    "/mnt/srv|/mnt_srv|/srv"
    "/mnt/var/lib/libvirt/images|/mnt_var_lib_libvirt_images|/var/lib/libvirt/images"
)

for migrate_info in "${MIGRATE_DIRS[@]}"; do
    IFS='|' read -r src dst name <<< "$migrate_info"
    if [ -d "$src" ] && [ "$(ls -A "$src")" ]; then
        run mv "$src"/* "$dst"/ || { echo "Error: Failed to migrate $name."; exit 1; }
        run rmdir "$src"
    fi
done

# Unmount temporary mounts
run umount /mnt_log /mnt_cache /mnt_home /mnt_var_lib_docker /mnt_var_tmp /mnt_srv /mnt_var_lib_libvirt_images
run rm -rf /mnt_log /mnt_cache /mnt_home /mnt_var_lib_docker /mnt_var_tmp /mnt_srv /mnt_var_lib_libvirt_images

# --- [4/6] Setup permanent mounts ---
echo "[4/6] 设置永久挂载..."
run mkdir -p /mnt/{var/log,var/cache,var/lib/docker,var/tmp,var/lib/libvirt/images,srv,home}
run mount -o subvol=@home "$BTRFS_DEV" /mnt/home || { echo "Error: Failed to mount @home."; exit 1; }
run mount -o subvol=@log "$BTRFS_DEV" /mnt/var/log || { echo "Error: Failed to mount @log."; exit 1; }
run mount -o subvol=@cache "$BTRFS_DEV" /mnt/var/cache || { echo "Error: Failed to mount @cache."; exit 1; }
run mount -o subvol=@docker,nodatacow "$BTRFS_DEV" /mnt/var/lib/docker || { echo "Error: Failed to mount @docker."; exit 1; }
run mount -o subvol=@tmp "$BTRFS_DEV" /mnt/var/tmp || { echo "Error: Failed to mount @tmp."; exit 1; }
run mount -o subvol=@srv "$BTRFS_DEV" /mnt/srv || { echo "Error: Failed to mount @srv."; exit 1; }
run mount -o subvol=@libvirt,nodatacow "$BTRFS_DEV" /mnt/var/lib/libvirt/images || { echo "Error: Failed to mount @libvirt."; exit 1; }

# --- [5/6] Generate fstab ---
echo "[5/6] 生成 fstab..."

FSTAB_CONTENT="# /boot/efi
UUID=$EFI_UUID  /boot/efi       vfat    umask=0077      0 1

# / (Root Subvolume)
UUID=$BTRFS_UUID /               btrfs   subvol=@,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /home
UUID=$BTRFS_UUID /home           btrfs   subvol=@home,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /var/log
UUID=$BTRFS_UUID /var/log        btrfs   subvol=@log,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /var/cache
UUID=$BTRFS_UUID /var/cache      btrfs   subvol=@cache,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /var/lib/docker
UUID=$BTRFS_UUID /var/lib/docker btrfs   subvol=@docker,noatime,ssd,discard=async,space_cache=v2,nodatacow 0 0
# /var/tmp
UUID=$BTRFS_UUID /var/tmp        btrfs   subvol=@tmp,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /srv
UUID=$BTRFS_UUID /srv            btrfs   subvol=@srv,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /var/lib/libvirt/images (KVM)
UUID=$BTRFS_UUID /var/lib/libvirt/images btrfs subvol=@libvirt,noatime,ssd,discard=async,space_cache=v2,nodatacow,compress=no 0 0
# swap
UUID=$SWAP_UUID  none            swap    sw              0 0"

if $DRY_RUN; then
    echo ""
    echo "[DRY-RUN] Would write to /mnt/etc/fstab:"
    echo "----------------------------------------"
    echo "$FSTAB_CONTENT"
    echo "----------------------------------------"
else
    echo "$FSTAB_CONTENT" > /mnt/etc/fstab
fi

# Verify fstab
if ! $DRY_RUN; then
    findmnt --verify --fstab /mnt/etc/fstab || { echo "Error: fstab verification failed."; exit 1; }
fi

# --- [6/6] Cleanup ---
echo "[6/6] 清理..."
run umount -R /mnt
run swapon "$SWAP_DEV" || { echo "Error: Failed to enable swap on $SWAP_DEV."; exit 1; }

# --- Done ---
echo ""
if $DRY_RUN; then
    echo "========================================"
    echo " Dry-run complete. Review above output."
    echo " Run without --dry-run to apply changes."
    echo "========================================"
else
    echo "Swap enabled successfully."
    echo "Configuration complete! Reboot now: sudo reboot"
fi
