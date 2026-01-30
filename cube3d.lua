-- 3D Rotating Cube Demo
-- Tom's Peripherals GPU

-- Cube triangles (12 triangles = 6 faces)
local tris = {
    -- SOUTH (front)
    { 0.0, 0.0, 0.0,    0.0, 1.0, 0.0,    1.0, 1.0, 0.0 },
    { 0.0, 0.0, 0.0,    1.0, 1.0, 0.0,    1.0, 0.0, 0.0 },
    -- NORTH (back)
    { 1.0, 0.0, 1.0,    1.0, 1.0, 1.0,    0.0, 1.0, 1.0 },
    { 1.0, 0.0, 1.0,    0.0, 1.0, 1.0,    0.0, 0.0, 1.0 },
    -- EAST (right)
    { 1.0, 0.0, 0.0,    1.0, 1.0, 0.0,    1.0, 1.0, 1.0 },
    { 1.0, 0.0, 0.0,    1.0, 1.0, 1.0,    1.0, 0.0, 1.0 },
    -- WEST (left)
    { 0.0, 0.0, 1.0,    0.0, 1.0, 1.0,    0.0, 1.0, 0.0 },
    { 0.0, 0.0, 1.0,    0.0, 1.0, 0.0,    0.0, 0.0, 0.0 },
    -- TOP
    { 0.0, 1.0, 0.0,    0.0, 1.0, 1.0,    1.0, 1.0, 1.0 },
    { 0.0, 1.0, 0.0,    1.0, 1.0, 1.0,    1.0, 1.0, 0.0 },
    -- BOTTOM
    { 1.0, 0.0, 1.0,    0.0, 0.0, 1.0,    0.0, 0.0, 0.0 },
    { 1.0, 0.0, 1.0,    0.0, 0.0, 0.0,    1.0, 0.0, 0.0 },
}

-- Face colors: Red, Green, Blue (2 shades each)
local faceColors = {
    {255, 0, 0},    -- South - Red
    {127, 0, 0},
    {0, 255, 0},    -- North - Green
    {0, 127, 0},
    {0, 0, 255},    -- East - Blue
    {0, 0, 127},
    {255, 255, 0},  -- West - Yellow
    {127, 127, 0},
    {255, 0, 255},  -- Top - Magenta
    {127, 0, 127},
    {0, 255, 255},  -- Bottom - Cyan
    {0, 127, 127},
}

-- Find GPU
local gpu = peripheral.find("tm_gpu")
if not gpu then
    print("No GPU found!")
    return
end

gpu.refreshSize()
gpu.setSize(64)

-- Create 3D context
local gl = gpu.createWindow3D(1, 1, 768, 320)
gl.glFrustum(90, 0.1, 1000)
gl.glDirLight(0, 0, -1)

local rotY = 0
local rotZ = 0

print("3D Cube running! (Ctrl+T to stop)")

while true do
    gl.clear()
    gl.glDisable(0xDE1)  -- Disable culling

    -- Position and rotate
    gl.glTranslate(0, 1, 3)
    gl.glRotate(rotY, 0, 1, 0)
    gl.glRotate(rotZ, 0, 0, 1)

    rotY = rotY + 2
    rotZ = rotZ + 1

    -- Draw triangles
    gl.glBegin()
    for i, tri in ipairs(tris) do
        local c = faceColors[i]
        gl.glColor(c[1], c[2], c[3])
        gl.glVertex(tri[1], tri[2], tri[3])
        gl.glVertex(tri[4], tri[5], tri[6])
        gl.glVertex(tri[7], tri[8], tri[9])
    end
    gl.glEnd()

    gl.render()
    gl.sync()
    gpu.sync()

    sleep(0.02)
end
