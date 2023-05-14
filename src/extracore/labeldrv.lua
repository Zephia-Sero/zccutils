local args = {...}

local function print_usage()
  print("labeldrv <side> <label>")
end

if #args ~= 2 then
  print("Incorrect number of arguments provided")
  print_usage()
  return 1
end

-- Check that a FLOPPY disk is actually in the drive 
-- (isPresent tests if any disk (including music) is
-- in the drive, so not using that here, since those
-- cannot be labeled)
if disk.hasData(args[1]) then
  disk.setLabel(args[1], args[2])
  return 0
end

return 1
