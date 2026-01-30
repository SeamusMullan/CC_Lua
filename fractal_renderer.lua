-- GPU Fractal Renderer - Mandelbrot Set
-- Renders a colorful Mandelbrot fractal on the GPU

-- Find and wrap the GPU peripheral
local gpu = peripheral.find("tm_gpu")
if not gpu then
    print("No GPU found! Connect a Tom's Peripherals GPU.")
    return
end

-- Detect connected screens
gpu.refreshSize()

-- Get screen dimensions
local sizeInfo = gpu.getSize()
local w, h

if type(sizeInfo) == "table" then
    w = sizeInfo.width or sizeInfo[1] or 100
    h = sizeInfo.height or sizeInfo[2] or 100
else
    w, h = gpu.getSize()
    w = w or 100
    h = h or 100
end

print("Rendering Mandelbrot fractal at " .. w .. "x" .. h)

-- Mandelbrot parameters
local maxIterations = 100
local zoom = 200
local centerX = -0.5
local centerY = 0

-- Color palette for fractal
local colors = {}
for i = 0, maxIterations do
    if i == maxIterations then
        colors[i] = 0xFF000000  -- Black for points in set
    else
        -- Create gradient colors
        local hue = (i / maxIterations) * 360
        local r = math.floor(128 + 127 * math.sin(math.rad(hue)))
        local g = math.floor(128 + 127 * math.sin(math.rad(hue + 120)))
        local b = math.floor(128 + 127 * math.sin(math.rad(hue + 240)))
        colors[i] = (r << 16) | (g << 8) | b | 0xFF000000
    end
end

-- Calculate Mandelbrot set membership
function mandelbrot(cx, cy)
    local x = 0
    local y = 0
    local iteration = 0
    
    while x*x + y*y <= 4 and iteration < maxIterations do
        local xTemp = x*x - y*y + cx
        y = 2*x*y + cy
        x = xTemp
        iteration = iteration + 1
    end
    
    return iteration
end

-- Clear screen with black background
gpu.fill(0xFF000000)

print("Calculating fractal...")
local startTime = os.clock()

-- Render the fractal pixel by pixel
for py = 0, h-1 do
    for px = 0, w-1 do
        -- Convert pixel coordinates to complex plane
        local x = (px - w/2) / zoom + centerX
        local y = (py - h/2) / zoom + centerY
        
        -- Calculate Mandelbrot value
        local iterations = mandelbrot(x, y)
        
        -- Draw pixel
        gpu.drawPixel(px, py, colors[iterations])
    end
    
    -- Show progress every 10 lines
    if py % 10 == 0 then
        print("Progress: " .. math.floor(py/h*100) .. "%")
    end
end

local endTime = os.clock()
print("Fractal rendered in " .. math.floor((endTime - startTime) * 1000) .. "ms")

-- Update the screen
gpu.sync()

print("Mandelbrot fractal complete! Touch to zoom (Ctrl+T to exit)")

-- Interactive zoom on touch
while true do
    local event, x, y, sneaking = os.pullEvent("tm_monitor_touch")
    print("Touched at: " .. x .. ", " .. y)
    
    -- Zoom in on touched area
    centerX = centerX + (x - w/2) / zoom
    centerY = centerY + (y - h/2) / zoom
    zoom = zoom * 2
    
    print("Zooming in. New center: " .. centerX .. ", " .. centerY .. " Zoom: " .. zoom)
    
    -- Re-render with new zoom
    gpu.fill(0xFF000000)
    
    for py = 0, h-1 do
        for px = 0, w-1 do
            local x = (px - w/2) / zoom + centerX
            local y = (py - h/2) / zoom + centerY
            local iterations = mandelbrot(x, y)
            gpu.drawPixel(px, py, colors[iterations])
        end
    end
    
    gpu.sync()
    print("Re-render complete!")
end