#!/usr/bin/env python3
"""
Convert GIF/MP4 to raw format for Tom's Peripherals GPU
Run this OUTSIDE Minecraft on your regular computer

Requirements:
    pip install pillow imageio imageio-ffmpeg

Usage:
    python3 convert_video.py input.gif output.raw 128 72
    python3 convert_video.py input.mp4 output.raw 128 72 --max-frames 100
"""

import sys
import struct

def convert_video(input_path, output_path, width, height, max_frames=None):
    try:
        import imageio.v3 as iio
    except ImportError:
        print("Install required packages:")
        print("  pip install pillow imageio imageio-ffmpeg")
        sys.exit(1)

    from PIL import Image

    print(f"Reading {input_path}...")

    # Read video/gif frames
    try:
        frames_raw = iio.imread(input_path, plugin="pyav")
    except:
        try:
            frames_raw = iio.imread(input_path)
        except Exception as e:
            print(f"Error reading file: {e}")
            sys.exit(1)

    # Handle single image vs video
    if len(frames_raw.shape) == 3:
        frames_raw = [frames_raw]

    total_frames = len(frames_raw)
    if max_frames:
        total_frames = min(total_frames, max_frames)

    print(f"Found {len(frames_raw)} frames, processing {total_frames}")
    print(f"Resizing to {width}x{height}")

    # Process frames
    frames = []
    for i, frame in enumerate(frames_raw[:total_frames]):
        # Convert to PIL Image and resize
        img = Image.fromarray(frame)
        img = img.convert("RGBA")
        img = img.resize((width, height), Image.Resampling.LANCZOS)

        # Get pixel data
        pixels = list(img.getdata())
        frames.append(pixels)

        if (i + 1) % 10 == 0:
            print(f"Processed {i + 1}/{total_frames}")

    # Write output file
    print(f"Writing {output_path}...")
    with open(output_path, "wb") as f:
        # Header: width, height, frame count (4 bytes each, little endian)
        f.write(struct.pack("<III", width, height, len(frames)))

        # Frame data: BGRA pixels
        for frame_idx, pixels in enumerate(frames):
            for r, g, b, a in pixels:
                f.write(struct.pack("BBBB", b, g, r, a))

            if (frame_idx + 1) % 10 == 0:
                print(f"Written {frame_idx + 1}/{len(frames)}")

    file_size = len(frames) * width * height * 4 + 12
    print(f"Done! Output: {output_path} ({file_size / 1024:.1f} KB)")
    print(f"\nTo play in Minecraft:")
    print(f"  rawvideo {output_path} 20")


if __name__ == "__main__":
    if len(sys.argv) < 5:
        print("Usage: python3 convert_video.py <input> <output.raw> <width> <height> [--max-frames N]")
        print("")
        print("Examples:")
        print("  python3 convert_video.py animation.gif video.raw 128 72")
        print("  python3 convert_video.py movie.mp4 video.raw 64 36 --max-frames 200")
        print("")
        print("Recommended sizes (smaller = faster):")
        print("  64x36   - Very fast, chunky pixels")
        print("  128x72  - Good balance")
        print("  256x144 - High quality, slower")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    width = int(sys.argv[3])
    height = int(sys.argv[4])

    max_frames = None
    if "--max-frames" in sys.argv:
        idx = sys.argv.index("--max-frames")
        max_frames = int(sys.argv[idx + 1])

    convert_video(input_file, output_file, width, height, max_frames)
