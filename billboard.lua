-- Pure 3D Billboard (no 2D calls)
local gpu = peripheral.find("tm_gpu")
if not gpu then
    print("No GPU found!")
    return
end

gpu.refreshSize()
gpu.setSize(64)

-- Get actual screen size
local W, H = gpu.getSize()
print("Screen: " .. W .. "x" .. H)

-- Calculate scale based on screen size
local scale = math.min(W / 768, H / 320)
local aspect = W / H

-- Create 3D window to fill the screen
local gl = gpu.createWindow3D(1, 1, W, H)
gl.glFrustum(75, 0.1, 1000)
gl.glDirLight(0, 0, -1)

-- Diamond mesh
local diamond = {
    { 0, 1, 0,   -0.5, 0, -0.5,   0.5, 0, -0.5 },
    { 0, 1, 0,   0.5, 0, -0.5,    0.5, 0, 0.5 },
    { 0, 1, 0,   0.5, 0, 0.5,    -0.5, 0, 0.5 },
    { 0, 1, 0,  -0.5, 0, 0.5,    -0.5, 0, -0.5 },
    { 0, -1, 0,  0.5, 0, -0.5,   -0.5, 0, -0.5 },
    { 0, -1, 0,  0.5, 0, 0.5,     0.5, 0, -0.5 },
    { 0, -1, 0, -0.5, 0, 0.5,     0.5, 0, 0.5 },
    { 0, -1, 0, -0.5, 0, -0.5,   -0.5, 0, 0.5 },
}

-- Floating cubes around the diamond
local cubes = {
    { 0, 0, 0,    0, 1, 0,    1, 1, 0 },
    { 0, 0, 0,    1, 1, 0,    1, 0, 0 },
    { 1, 0, 1,    1, 1, 1,    0, 1, 1 },
    { 1, 0, 1,    0, 1, 1,    0, 0, 1 },
    { 1, 0, 0,    1, 1, 0,    1, 1, 1 },
    { 1, 0, 0,    1, 1, 1,    1, 0, 1 },
    { 0, 0, 1,    0, 1, 1,    0, 1, 0 },
    { 0, 0, 1,    0, 1, 0,    0, 0, 0 },
    { 0, 1, 0,    0, 1, 1,    1, 1, 1 },
    { 0, 1, 0,    1, 1, 1,    1, 1, 0 },
    { 1, 0, 1,    0, 0, 1,    0, 0, 0 },
    { 1, 0, 1,    0, 0, 0,    1, 0, 0 },
}

local tick = 0

print("3D Billboard running! (Ctrl+T to stop)")

while true do
    tick = tick + 1
    gl.clear()
    gl.glDisable(0xDE1)

    -- Background panel - scaled to fill screen
    local bgW = 4 * aspect  -- Width based on aspect ratio
    local bgH = 3.5
    local bgZ = 7  -- Push back from camera

    gl.glPushMatrix()
    gl.glTranslate(0, 0, bgZ)
    gl.glBegin()
    -- Dark blue background quad
    gl.glColor(20, 20, 60)
    gl.glVertex(-bgW, -bgH, 0)
    gl.glVertex(-bgW, bgH, 0)
    gl.glVertex(bgW, bgH, 0)
    gl.glVertex(-bgW, -bgH, 0)
    gl.glVertex(bgW, bgH, 0)
    gl.glVertex(bgW, -bgH, 0)
    -- Top banner (pulsing orange)
    local pulse = math.floor(150 + 100 * math.sin(tick * 0.1))
    gl.glColor(pulse, math.floor(pulse * 0.5), 0)
    gl.glVertex(-bgW, bgH - 0.5, -0.01)
    gl.glVertex(-bgW, bgH, -0.01)
    gl.glVertex(bgW, bgH, -0.01)
    gl.glVertex(-bgW, bgH - 0.5, -0.01)
    gl.glVertex(bgW, bgH, -0.01)
    gl.glVertex(bgW, bgH - 0.5, -0.01)
    -- Bottom banner
    gl.glColor(pulse, math.floor(pulse * 0.3), 0)
    gl.glVertex(-bgW, -bgH, -0.01)
    gl.glVertex(-bgW, -bgH + 0.5, -0.01)
    gl.glVertex(bgW, -bgH + 0.5, -0.01)
    gl.glVertex(-bgW, -bgH, -0.01)
    gl.glVertex(bgW, -bgH + 0.5, -0.01)
    gl.glVertex(bgW, -bgH, -0.01)
    gl.glEnd()
    gl.glPopMatrix()

    -- Main rotating diamond
    gl.glPushMatrix()
    gl.glTranslate(0, 0, 5)
    gl.glScale(1.2, 1.2, 1.2)
    gl.glRotate(tick * 2, 0, 1, 0)
    gl.glRotate(tick * 0.5, 1, 0, 0)
    gl.glBegin()
    for i, tri in ipairs(diamond) do
        local shade = (i <= 4) and 255 or 180
        gl.glColor(math.floor(shade * 0.3), math.floor(shade * 0.9), shade)
        gl.glVertex(tri[1], tri[2], tri[3])
        gl.glVertex(tri[4], tri[5], tri[6])
        gl.glVertex(tri[7], tri[8], tri[9])
    end
    gl.glEnd()
    gl.glPopMatrix()

    -- Orbiting mini cubes - wider orbit
    for j = 1, 4 do
        gl.glPushMatrix()
        local angle = tick * 0.03 + j * 1.57
        local radius = 2 * aspect  -- Scale orbit with aspect
        local ox = math.cos(angle) * radius
        local oy = math.sin(tick * 0.02 + j) * 0.8
        local oz = 5 + math.sin(angle) * 1.5
        gl.glTranslate(ox, oy, oz)
        gl.glScale(0.5, 0.5, 0.5)
        gl.glRotate(tick * 3, 1, 1, 0)
        gl.glBegin()
        for i, tri in ipairs(cubes) do
            local colors = {{255,100,100}, {100,255,100}, {100,100,255}, {255,255,100}}
            local c = colors[j]
            local shade = (i % 2 == 0) and 1 or 0.6
            gl.glColor(c[1] * shade * 0.3, c[2] * shade * 0.3, c[3] * shade * 0.3)
            gl.glVertex(tri[1]-0.5, tri[2]-0.5, tri[3]-0.5)
            gl.glVertex(tri[4]-0.5, tri[5]-0.5, tri[6]-0.5)
            gl.glVertex(tri[7]-0.5, tri[8]-0.5, tri[9]-0.5)
        end
        gl.glEnd()
        gl.glPopMatrix()
    end

    gl.render()
    gl.sync()
    gpu.sync()

    sleep(0.03)
end
