-- Fast Video Player using drawBuffer
-- Much faster than pixel-by-pixel rendering

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
    print("Usage: fastvideo [file.raw] [fps]")
    print("")
    print("Create video with Python:")
    print("  python3 convert_video.py input.gif output.raw 64 36")
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

-- Loading bar helper
local function drawLoadingBar(progress, msg)
    gpu.fill(0xFF1a1a2e)

    -- Title
    gpu.drawText(W/2 - 40, H/2 - 40, "LOADING VIDEO", 0xFFFFFFFF)

    -- Bar background
    local barW = math.floor(W * 0.6)
    local barH = 20
    local barX = math.floor((W - barW) / 2)
    local barY = math.floor(H / 2)
    gpu.filledRectangle(barX, barY, barW, barH, 0xFF333355)

    -- Bar fill
    local fillW = math.floor(barW * progress)
    if fillW > 0 then
        gpu.filledRectangle(barX, barY, fillW, barH, 0xFF44AAFF)
    end

    -- Percentage text
    local pct = math.floor(progress * 100)
    gpu.drawText(W/2 - 15, barY + barH + 10, pct .. "%", 0xFFFFFFFF)

    -- Status message
    if msg then
        gpu.drawText(W/2 - 50, barY + barH + 30, msg, 0xFFAAAAAA)
    end

    gpu.sync()
end

-- Read all frames - store as flat ARGB arrays for drawBuffer
local frames = {}
local pixelsPerFrame = frameWidth * frameHeight

drawLoadingBar(0, "Starting...")

for f = 1, frameCount do
    local pixels = {}
    for p = 1, pixelsPerFrame do
        local b = file.read()
        local g = file.read()
        local r = file.read()
        local a = file.read()
        if not a then break end
        -- ARGB format
        pixels[p] = 0xFF000000 + r * 0x10000 + g * 0x100 + b

        -- Yield every 5000 pixels to prevent timeout
        if p % 5000 == 0 then
            os.queueEvent("yield")
            os.pullEvent("yield")
        end
    end
    frames[f] = pixels

    -- Update loading bar
    local progress = f / frameCount
    drawLoadingBar(progress, "Frame " .. f .. "/" .. frameCount)

    -- Yield after each frame
    os.queueEvent("yield")
    os.pullEvent("yield")
end

file.close()
print("Loaded " .. #frames .. " frames")
print("Press Q to stop, SPACE to pause")

-- Calculate scale to fit screen (use smaller axis to not cut off)
local scaleX = W / frameWidth
local scaleY = H / frameHeight
local scale = math.floor(math.min(scaleX, scaleY))
if scale < 1 then scale = 1 end

local scaledW = frameWidth * scale
local scaledH = frameHeight * scale

-- Calculate centering - ensure offsets are at least 1
local offsetX = math.max(1, math.floor((W - scaledW) / 2))
local offsetY = math.max(1, math.floor((H - scaledH) / 2))

print("Scale: " .. scale .. "x (" .. scaledW .. "x" .. scaledH .. ")")
print("Offset: " .. offsetX .. ", " .. offsetY)

-- Playback
local frameIndex = 1
local frameDelay = 1 / fps
local paused = false

while true do
    if not paused then
        local frame = frames[frameIndex]
        if frame then
            gpu.fill(0xFF000000)

            -- Use drawBuffer for fast rendering
            -- drawBuffer(x, y, width, scale, pixels...)
            -- Ensure we stay in bounds
            local drawX = math.max(1, offsetX)
            local drawY = math.max(1, offsetY)
            local drawScale = scale

            -- If video is larger than screen, don't scale up
            if frameWidth * scale > W or frameHeight * scale > H then
                drawScale = 1
                drawX = 1
                drawY = 1
            end

            gpu.drawBuffer(drawX, drawY, frameWidth, drawScale, table.unpack(frame))

            gpu.sync()
        end

        frameIndex = frameIndex + 1
        if frameIndex > #frames then
            frameIndex = 1
        end
    end

    -- Timing and input handling
    local timer = os.startTimer(frameDelay)
    while true do
        local event, p1 = os.pullEvent()
        if event == "timer" and p1 == timer then
            break
        elseif event == "key" then
            if p1 == keys.q then
                print("Stopped")
                return
            elseif p1 == keys.space then
                paused = not paused
                print(paused and "Paused" or "Playing")
            elseif p1 == keys.left and paused then
                frameIndex = math.max(1, frameIndex - 1)
            elseif p1 == keys.right and paused then
                frameIndex = math.min(#frames, frameIndex + 1)
            end
        end
    end
end
