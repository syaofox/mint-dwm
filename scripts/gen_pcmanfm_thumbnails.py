#!/usr/bin/env python3
import os
import sys
import hashlib
import urllib.parse
import subprocess
import shutil

# 配置
CACHE_DIR = os.path.expanduser("~/.cache/thumbnails/normal")
LARGE_CACHE_DIR = os.path.expanduser("~/.cache/thumbnails/large")

# 确保目录存在
os.makedirs(CACHE_DIR, exist_ok=True)
os.makedirs(LARGE_CACHE_DIR, exist_ok=True)

def check_dependencies():
    missing = []
    if not shutil.which("ffmpeg"):
        missing.append("ffmpeg")
    if not shutil.which("convert") or not shutil.which("mogrify"):
        missing.append("imagemagick")
    
    if missing:
        print(f"错误: 缺少依赖: {', '.join(missing)}", file=sys.stderr)
        return False
    return True

def get_thumb_info(file_path):
    # 获取绝对路径
    abs_path = os.path.abspath(file_path)
    # 构造URI: file:// + quoted path
    # urllib.parse.quote 默认不转义 '/'，但为了兼容性，我们显式指定 safe='/'
    # 并且处理 file:// 协议的三斜杠问题 (file:///path)
    # 很多系统上 path 已经包含开头的 /，所以 file:// + path 变成 file:///
    quoted_path = urllib.parse.quote(abs_path, safe='/')
    uri = "file://" + quoted_path
    
    # 计算MD5
    # 标准要求对 URI 进行 md5 计算
    md5_hash = hashlib.md5(uri.encode('utf-8')).hexdigest()
    
    # 目标路径 (默认使用 normal 128x128)
    thumb_path = os.path.join(CACHE_DIR, md5_hash + ".png")
    
    return uri, thumb_path

def generate_thumbnail(file_path):
    if not os.path.exists(file_path):
        return False

    try:
        uri, thumb_path = get_thumb_info(file_path)
        mtime = int(os.path.getmtime(file_path))
        
        # 临时文件
        temp_thumb = thumb_path + ".tmp.png"
        
        # 识别类型
        ext = os.path.splitext(file_path)[1].lower()
        video_exts = {'.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.ts', '.m4v'}
        image_exts = {'.jpg', '.jpeg', '.png', '.bmp', '.gif', '.webp', '.tiff'}
        
        success = False
        
        if ext in video_exts:
            # 视频处理: 尝试截取第5秒，失败则第1秒
            # 使用 scale 滤镜确保适应 128x128
            vf_filter = "thumbnail,scale=128:128:force_original_aspect_ratio=decrease"
            
            cmd = [
                "ffmpeg", "-ss", "00:00:05", "-i", file_path,
                "-vf", vf_filter,
                "-vframes", "1", "-f", "image2", "-y", temp_thumb
            ]
            
            ret = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if ret.returncode != 0:
                # 重试: 0秒
                cmd[2] = "00:00:00"
                ret = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
            if ret.returncode == 0 and os.path.exists(temp_thumb):
                success = True

        elif ext in image_exts:
            # 图片处理
            cmd = [
                "convert", file_path + "[0]", # [0] 取第一帧(防gif过大)
                "-thumbnail", "128x128",
                "-auto-orient", # 自动旋转
                temp_thumb
            ]
            ret = subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if ret.returncode == 0 and os.path.exists(temp_thumb):
                success = True

        if success:
            # 添加元数据 (必须)
            # 使用 mogrify 添加 Thumb::URI 和 Thumb::MTime
            # 注意：PCManFM 极其依赖这两个属性
            # 确保路径中的空格被正确处理，subprocess 列表参数会自动处理
            
            # 先 strip 掉可能存在的无用信息
            # 然后添加属性
            meta_cmd = [
                "mogrify",
                "-strip",
                "-set", "Thumb::URI", uri,
                "-set", "Thumb::MTime", str(mtime),
                "-set", "Software", "GNOME::ThumbnailFactory", 
                temp_thumb
            ]
            # 加上 Software 伪装成标准生成器有时候会有奇效
            
            res = subprocess.run(meta_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf-8')
            if res.returncode != 0:
                print(f"Error setting metadata for {file_path}: {res.stderr}", file=sys.stderr)
            
            # 移动到最终位置
            os.replace(temp_thumb, thumb_path)
            # 赋予读取权限
            os.chmod(thumb_path, 0o600)
            return True
            
    except Exception as e:
        # 忽略错误，继续处理下一个
        pass
    
    if os.path.exists(temp_thumb):
        os.remove(temp_thumb)
        
    return False

def expand_targets(args):
    targets = []
    for arg in args:
        if os.path.isdir(arg):
            try:
                # 只查找一层，不递归
                with os.scandir(arg) as it:
                    for entry in it:
                        if entry.is_file():
                            targets.append(entry.path)
            except PermissionError:
                pass
        elif os.path.isfile(arg):
            targets.append(arg)
    return targets

def main():
    if not check_dependencies():
        sys.exit(1)
        
    # 收集文件
    targets = expand_targets(sys.argv[1:])
    total = len(targets)
    
    if total == 0:
        print("未找到可处理的文件。")
        sys.exit(0)

    print(f"# 正在分析 {total} 个文件...")
    
    count = 0
    for filepath in targets:
        filename = os.path.basename(filepath)
        
        # 更新进度条
        percent = int((count / total) * 100)
        print(f"{percent}")
        print(f"# 正在生成: {filename}")
        sys.stdout.flush()
        
        generate_thumbnail(filepath)
        count += 1

    print("100")
    print("# 完成")

if __name__ == "__main__":
    main()

