-- GPU Demo for Tom's Peripherals
-- Connect a GPU to a monitor/screen to use this

-- Find and wrap the GPU peripheral
local gpu = peripheral.find("tm_gpu")
if not gpu then
    print("No GPU found! Connect a Tom's Peripherals GPU.")
    return
end

-- Detect connected screens
gpu.refreshSize()

-- Get screen dimensions - returns table or multiple values
local sizeInfo = gpu.getSize()
local w, h

-- Handle different return formats
if type(sizeInfo) == "table" then
    w = sizeInfo.width or sizeInfo[1] or 100
    h = sizeInfo.height or sizeInfo[2] or 100
    print("Size info: ")
    for k, v in pairs(sizeInfo) do
        print("  " .. tostring(k) .. " = " .. tostring(v))
    end
else
    w, h = gpu.getSize()
    w = w or 100
    h = h or 100
end

print("Using screen size: " .. w .. "x" .. h)

-- Clear the screen with a dark background
gpu.fill(0xFF1a1a2e)

-- Scale drawings to fit screen
local scale = math.min(w / 300, h / 250)

-- Draw a filled rectangle (x, y, width, height, color)
gpu.filledRectangle(5, 5, math.floor(50 * scale), math.floor(30 * scale), 0xFF4a90d9)

-- Draw a rectangle outline
gpu.filledRectangle(5 + math.floor(60 * scale), 5, math.floor(40 * scale), math.floor(30 * scale), 0xFFe94560)

-- Draw some lines
local lineY = math.floor(50 * scale)
gpu.line(5, lineY, math.floor(100 * scale), lineY, 0xFF00ff00)

-- Draw text (x, y, text, color)
gpu.drawText(5, math.floor(70 * scale), "Hello GPU!", 0xFFffffff)

-- Update the screens with our drawing
gpu.sync()

print("GPU demo complete! Check your monitor.")

-- Optional: Handle touch events
print("Touch the screen to see coordinates (Ctrl+T to exit)")
while true do
    local event, x, y, sneaking = os.pullEvent("tm_monitor_touch")
    print("Touched at: " .. x .. ", " .. y)

    -- Draw a small square at touch location (with bounds check)
    local drawX = math.max(0, math.min(x - 2, w - 4))
    local drawY = math.max(0, math.min(y - 2, h - 4))
    gpu.filledRectangle(drawX, drawY, 4, 4, 0xFFff6b6b)
    gpu.sync()
end
