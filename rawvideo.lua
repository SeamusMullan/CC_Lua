-- Raw Video Player for Tom's Peripherals GPU
-- Plays raw ARGB pixel data frames
--
-- Frame format: raw binary file with ARGB pixels (4 bytes per pixel)
-- First 8 bytes: width (4 bytes LE) + height (4 bytes LE)
-- Rest: pixel data (width * height * 4 bytes)
--
-- Convert with Python script (see rawvideo_convert.py)

local args = {...}
local videoFile = args[1] or "video.raw"
local fps = tonumber(args[2]) or 20

local gpu = peripheral.find("tm_gpu")
if not gpu then
    print("No GPU found!")
    return
end

gpu.refreshSize()
gpu.setSize(64)

local W, H = gpu.getSize()
print("Screen: " .. W .. "x" .. H)

if not fs.exists(videoFile) then
    print("Video file '" .. videoFile .. "' not found!")
    print("")
    print("Usage: rawvideo [file.raw] [fps]")
    print("")
    print("Create raw video with Python:")
    print("  python3 rawvideo_convert.py input.gif output.raw 128 72")
    return
end

-- Read video file
print("Loading video...")
local file = fs.open(videoFile, "rb")
if not file then
    print("Failed to open file!")
    return
end

-- Read header
local function readInt()
    local b1 = file.read()
    local b2 = file.read()
    local b3 = file.read()
    local b4 = file.read()
    if not b1 then return nil end
    return b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
end

local frameWidth = readInt()
local frameHeight = readInt()
local frameCount = readInt()

if not frameWidth then
    print("Invalid video file!")
    file.close()
    return
end

print("Video: " .. frameWidth .. "x" .. frameHeight .. ", " .. frameCount .. " frames")

-- Read all frames into memory
local frames = {}
local pixelsPerFrame = frameWidth * frameHeight

for f = 1, frameCount do
    local pixels = {}
    for p = 1, pixelsPerFrame do
        local b = file.read()
        local g = file.read()
        local r = file.read()
        local a = file.read()
        if not a then break end
        pixels[p] = 0xFF000000 + r * 0x10000 + g * 0x100 + b
    end
    frames[f] = pixels

    if f % 10 == 0 then
        print("Loaded frame " .. f .. "/" .. frameCount)
    end
end

file.close()
print("Loaded " .. #frames .. " frames")
print("Press any key to stop")

-- Calculate centering
local offsetX = math.floor((W - frameWidth) / 2)
local offsetY = math.floor((H - frameHeight) / 2)

-- Playback
local frameIndex = 1
local frameDelay = 1 / fps

while true do
    local frame = frames[frameIndex]
    if frame then
        gpu.fill(0xFF000000)

        -- Draw pixel by pixel (slow but works)
        for y = 0, frameHeight - 1 do
            for x = 0, frameWidth - 1 do
                local idx = y * frameWidth + x + 1
                local color = frame[idx]
                if color then
                    gpu.filledRectangle(offsetX + x, offsetY + y, 1, 1, color)
                end
            end
        end

        gpu.sync()
    end

    frameIndex = frameIndex + 1
    if frameIndex > #frames then
        frameIndex = 1
    end

    -- Check for stop
    local timer = os.startTimer(frameDelay)
    while true do
        local event, p1 = os.pullEvent()
        if event == "timer" and p1 == timer then
            break
        elseif event == "key" or event == "char" then
            print("Stopped")
            return
        end
    end
end
