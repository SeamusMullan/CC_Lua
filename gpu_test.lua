-- Minimal GPU test
local gpu = peripheral.find("tm_gpu")
if not gpu then
    print("No GPU found!")
    return
end

gpu.refreshSize()

-- Print all available methods
print("GPU methods:")
for k, v in pairs(gpu) do
    print("  " .. k)
end

-- Try to get size and print everything
print("\ngetSize() returns:")
local result = {gpu.getSize()}
for i, v in ipairs(result) do
    print("  [" .. i .. "] = " .. tostring(v))
end

-- Simple fill and sync
print("\nTrying fill...")
gpu.fill(0xFF0000FF)  -- Blue
print("Trying sync...")
gpu.sync()
print("Done!")
