#!/bin/bash
# configure_btrfs.sh - Configure Btrfs subvolumes (@, @home, @cache, @log) for Linux Mint 22.2

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root (use sudo)."
    exit 1
fi

# Function to select partition from list
select_partition() {
    local partition_type=$1
    local type_name=""
    local filter_fstype=""
    
    case "$partition_type" in
        efi)
            type_name="EFI"
            filter_fstype="vfat"
            ;;
        btrfs)
            type_name="Btrfs"
            filter_fstype="btrfs"
            ;;
        swap)
            type_name="Swap"
            filter_fstype="swap"
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
        local name=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local fstype=$(echo "$line" | awk '{print $3}')
        local mountpoint=$(echo "$line" | awk '{print $4}')
        local uuid=$(echo "$line" | awk '{print $5}')
        
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
            local name=$(echo "$line" | awk '{print $1}')
            local size=$(echo "$line" | awk '{print $2}')
            local fstype=$(echo "$line" | awk '{print $3}')
            local mountpoint=$(echo "$line" | awk '{print $4}')
            local uuid=$(echo "$line" | awk '{print $5}')
            
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
    read selection < /dev/tty
    
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

# Unmount any existing mounts
umount -R /mnt 2>/dev/null
mkdir -p /mnt

# Mount Btrfs top-level
mount "$BTRFS_DEV" /mnt || { echo "Error: Failed to mount $BTRFS_DEV."; exit 1; }

# Create subvolumes with dynamic check
SUBVOLS=(@home @log @cache)
for subvol in "${SUBVOLS[@]}"; do
    if btrfs subvolume list /mnt | grep -q "$subvol"; then
        echo "Subvolume $subvol already exists, skipping."
    else
        btrfs subvolume create "/mnt/$subvol" || { echo "Error: Failed to create $subvol."; exit 1; }
    fi
done

# Unmount top-level
umount /mnt

# Mount @ subvolume and migrate data
mount -o subvol=@ "$BTRFS_DEV" /mnt || { echo "Error: Failed to mount @ subvolume."; exit 1; }
mkdir -p /mnt_log /mnt_cache /mnt_home
mount -o subvol=@log "$BTRFS_DEV" /mnt_log || { echo "Error: Failed to mount @log."; exit 1; }
mount -o subvol=@cache "$BTRFS_DEV" /mnt_cache || { echo "Error: Failed to mount @cache."; exit 1; }
mount -o subvol=@home "$BTRFS_DEV" /mnt_home || { echo "Error: Failed to mount @home."; exit 1; }

# Migrate data from existing directories to subvolumes
# Format: "source_path|destination_mount_point|display_name"
MIGRATE_DIRS=(
    "/mnt/var/log|/mnt_log|/var/log"
    "/mnt/var/cache|/mnt_cache|/var/cache"
    "/mnt/home|/mnt_home|/home"
)

for migrate_info in "${MIGRATE_DIRS[@]}"; do
    IFS='|' read -r src dst name <<< "$migrate_info"
    if [ -d "$src" ] && [ "$(ls -A "$src")" ]; then
        mv "$src"/* "$dst"/ || { echo "Error: Failed to migrate $name."; exit 1; }
        rmdir "$src"
    fi
done

# Unmount temporary mounts
umount /mnt_log /mnt_cache /mnt_home
rm -rf /mnt_log /mnt_cache /mnt_home

# Create permanent mount points and mount subvolumes
mkdir -p /mnt/{var/log,var/cache,home}
mount -o subvol=@home "$BTRFS_DEV" /mnt/home || { echo "Error: Failed to mount @home."; exit 1; }
mount -o subvol=@log "$BTRFS_DEV" /mnt/var/log || { echo "Error: Failed to mount @log."; exit 1; }
mount -o subvol=@cache "$BTRFS_DEV" /mnt/var/cache || { echo "Error: Failed to mount @cache."; exit 1; }

# Update fstab
FSTAB=/mnt/etc/fstab
cat > "$FSTAB" << EOF
# /boot/efi
UUID=$EFI_UUID  /boot/efi       vfat    umask=0077      0 1

# / (Root Subvolume)
UUID=$BTRFS_UUID /               btrfs   subvol=@,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /home
UUID=$BTRFS_UUID /home           btrfs   subvol=@home,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /var/log
UUID=$BTRFS_UUID /var/log        btrfs   subvol=@log,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# /var/cache
UUID=$BTRFS_UUID /var/cache      btrfs   subvol=@cache,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2 0 0
# swap
UUID=$SWAP_UUID  none            swap    sw              0 0

# ssd
# UUID=cb6285a3-5e94-4376-a9fc-38b10c28d40e /mnt/github btrfs rw,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2,subvol=/@github 0 0
# UUID=cb6285a3-5e94-4376-a9fc-38b10c28d40e /mnt/data btrfs rw,noatime,ssd,compress=zstd:3,discard=async,space_cache=v2,subvol=/@data 0 0

# dnas
# 10.10.10.2:/fs/1000/nfs /mnt/dnas nfs defaults,_netdev,soft,timeo=50,retrans=3,proto=tcp,vers=4,rsize=1048576,wsize=1048576 0 0

EOF

# Verify fstab
findmnt --verify --fstab "$FSTAB" || { echo "Error: fstab verification failed."; exit 1; }

# Unmount all
cd ~
umount -R /mnt

# Enable swap
swapon "$SWAP_DEV" || { echo "Error: Failed to enable swap on $SWAP_DEV."; exit 1; }
echo "Swap enabled successfully."

echo "Configuration complete! Reboot now: sudo reboot"

# /dev/nvme1n1p2
UUID=50e83160-79ba-44b0-869e-8d5e00d15d97	/         	btrfs     	rw,noatime,ssd,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=/@	0 0