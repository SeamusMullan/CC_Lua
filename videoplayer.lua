-- Video Player for Tom's Peripherals GPU
-- Plays a sequence of image frames from a folder
--
-- SETUP: Convert your video to frames using ffmpeg:
--   ffmpeg -i video.mp4 -vf "scale=256:144" frames/frame_%04d.bmp
--   ffmpeg -i video.gif -vf "scale=256:144" frames/frame_%04d.bmp
--
-- Then copy the frames folder to this computer's directory

local args = {...}
local framesDir = args[1] or "frames"
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

-- Check if frames directory exists
if not fs.exists(framesDir) then
    print("Frames directory '" .. framesDir .. "' not found!")
    print("")
    print("Usage: videoplayer [frames_folder] [fps]")
    print("  Example: videoplayer myframes 30")
    print("")
    print("To create frames from a video:")
    print("  ffmpeg -i video.mp4 -vf scale=256:144 frames/frame_%04d.bmp")
    return
end

-- Find all frame files
local frameFiles = {}
for _, file in ipairs(fs.list(framesDir)) do
    if file:match("%.bmp$") or file:match("%.nfp$") then
        table.insert(frameFiles, fs.combine(framesDir, file))
    end
end

table.sort(frameFiles)

if #frameFiles == 0 then
    print("No frame files found in '" .. framesDir .. "'")
    print("Supported formats: .bmp, .nfp")
    return
end

print("Found " .. #frameFiles .. " frames")
print("Playing at " .. fps .. " FPS")
print("Press any key to stop")

-- Try to load and decode frames
local frames = {}
local loadedCount = 0

print("Loading frames...")
for i, path in ipairs(frameFiles) do
    local file = fs.open(path, "rb")
    if file then
        local data = file.readAll()
        file.close()

        -- Try to decode the image
        local ok, img = pcall(function()
            return gpu.decodeImage(data)
        end)

        if ok and img then
            frames[i] = img
            loadedCount = loadedCount + 1
        end
    end

    -- Progress indicator
    if i % 10 == 0 then
        print("Loaded " .. i .. "/" .. #frameFiles)
    end
end

print("Successfully loaded " .. loadedCount .. " frames")

if loadedCount == 0 then
    print("Failed to load any frames!")
    print("Make sure frames are in a supported format.")
    return
end

-- Calculate timing
local frameDelay = 1 / fps

-- Playback loop
local frameIndex = 1
local running = true

-- Start playback timer
local lastTime = os.clock()

while running do
    -- Draw current frame
    if frames[frameIndex] then
        gpu.fill(0xFF000000)

        -- Center the image
        local imgW, imgH = 256, 144  -- Assumed size
        local x = math.floor((W - imgW) / 2)
        local y = math.floor((H - imgH) / 2)

        gpu.drawImage(x, y, frames[frameIndex])
        gpu.sync()
    end

    -- Next frame
    frameIndex = frameIndex + 1
    if frameIndex > #frames then
        frameIndex = 1  -- Loop
    end

    -- Timing
    local elapsed = os.clock() - lastTime
    local sleepTime = frameDelay - elapsed
    if sleepTime > 0 then
        sleep(sleepTime)
    else
        sleep(0.01)  -- Minimum sleep
    end
    lastTime = os.clock()

    -- Check for key press to stop
    local timer = os.startTimer(0.001)
    local event = os.pullEvent()
    if event == "key" or event == "char" then
        running = false
    end
end

print("Playback stopped")
