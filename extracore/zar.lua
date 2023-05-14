-- Sub'string' of a table, inclusive on both ends, just like string.sub
local function table_sub(tbl, s, e)
  local out = {}
  for i=s,e do
    out[#out + 1] = tbl[i]
  end
  return out
end

-- Returns number from little-endian 32 bit value
local function u32_to_number(u32)
  local num = 0
  local scale = 1
  for i=1,4 do
    num = num + u32[i] * scale
    scale = scale * 256
  end
  return num
end

-- Get file from zar data
local function _zar_file(data, offset)
  local fileNameLen = u32_to_number(table_sub(data, offset, offset + 3))
  local fileName = string.char(table.unpack(table_sub(data, offset + 4, offset + 4 + fileNameLen - 1)))
  local fileContentLen = u32_to_number(table_sub(data, offset+4+fileNameLen, offset+7+fileNameLen))
  local fileContent = table_sub(data, offset+8+fileNameLen, offset+8+fileNameLen+fileContentLen-1)
  return {
    ["fileName"] = fileName,
    ["fileContent"] = fileContent,
    ["_zarLength"] = 8 + fileNameLen + fileContentLen
  }
end

-- Extract files from ZAR-archived data bytes
local function zar_extract(data)
  local magic = table_sub(data, 1, 3)
  magic = string.char(table.unpack(magic))
  if magic ~= "ZAR" then return false end
  local fileCount = u32_to_number(table_sub(data, 4, 7))
  print("File count: " .. fileCount)
  local offset = 8
  local files = {}
  for i=1,fileCount do
    files[#files + 1] = _zar_file(data, offset)
    offset = offset + files[#files]._zarLength
  end
  return files
end

local function table_append(tbl, appendTbl)
  local ln = #tbl
  for k, v in pairs(appendTbl) do
    tbl[ln + k] = v
  end
end

-- Returns little-endian 32 bit value of floor(num)
local function number_to_u32(num)
  num = math.floor(num)
  local tbl = { 0, 0, 0, 0 }

  for i=1,4 do
    tbl[i] = num % 256
    num = math.floor(num / 256)
  end

  return tbl
end

-- Internal function, please don't use zar to create single-file archives.
local function _zar_create_file(pathpfx, path)
  local fh = fs.open(pathpfx .. "/" .. path, "rb")
  local fileContents = { }
  local s = fh:read()
  while s ~= nil do
    fileContents[#fileContents + 1] = s
    s = fh:read()
  end
  fh:close()

  local outBytes = number_to_u32(#path)
  table_append(outBytes, { path:byte(1, #path) })
  table_append(outBytes, number_to_u32(#fileContents))
  table_append(outBytes, fileContents)

  return outBytes
end

-- Internal function to get files recursively. See recursive_path for more info.
-- Mid is internally used to add the path to the output file of recursed
-- directories.
local function _recursive_path(from, maxDepth, mid)
  -- Remove /path/to/from/ from the input file
  local baseToRemove = from
  if not fs.isDir(from) then
    baseToRemove = fs.getDir(from)
  end

  local retVal = {}

  for _, path in pairs(fs.find(from .. "/*")) do
    -- Cut off the first part of the path and add the recursed directory path
    local newMid = mid .. "/" .. path:sub(#baseToRemove + 1, -1)
    -- Keep recursing if we haven't hit our maxDepth yet
    if fs.isDir(path) and maxDepth ~= 0 then
      -- Decrease max depth unless we're negative, then it doesn't matter.
      local newDepth = maxDepth - 1
      if maxDepth < 0 then
        newDepth = -1
      end
      -- And recurse further
      table_append(retVal, _recursive_path(path, newDepth, newMid))
    else
      if not (fs.isDir(path) and maxDepth == 0) then
        retVal[#retVal + 1] = newMid
      end
    end
  end
  return retVal
end

-- Internal function to get files recursively. From is the path (omitted!) to
-- look for files, and maxDepth is the max depth to recurse to. If it's negative,
-- recurses infinitely.
local function recursive_path(from, maxDepth)
  -- Defaults
  if maxDepth == nil then maxDepth = -1 end
  return _recursive_path(from, maxDepth, "")
end


-- Create ZAR archive data from a path
local function zar_create(path)
  local files = recursive_path(path)
  local out = { string.byte("ZAR", 1, 3) }
  table_append(out, number_to_u32(#files))
  for k, v in ipairs(files) do
    if not fs.isDir(path .. "/" .. v) then
      table_append(out, _zar_create_file(path, v))
    end
  end
  return out
end

-- Create ZAR archive and output!
local function zar_create_full(path, zarfile)
  local bytes = zar_create(path)
  local fh = fs.open(zarfile, "wb")
  for _, byte in ipairs(bytes) do
    fh.write(byte)
  end
  fh.close()
end

-- Extract ZAR archive and output!
local function zar_extract_full(path, zarfile)
  local bytes = {}
  local fh = fs.open(zarfile, "rb")
  local b = fh.read()
  while b ~= nil do
    bytes[#bytes + 1] = b
    b = fh.read()
  end
  local files = zar_extract(bytes)
  for _, v in ipairs(files) do
    local outPath = path .. "/" .. v.fileName
    if not fs.isDir(fs.getDir(outPath)) then
      fs.makeDir(fs.getDir(outPath))
    end
    local fh = fs.open(outPath, "wb")
    for _, b in ipairs(v.fileContent) do
      fh.write(b)
    end
    fh.close()
  end
end

local function print_usage()
  print("tar c|x ZARFILE DIR")
  print("Create or extract files from a zar archive.")
  print("\tc\tCreate")
  print("\tx\tExtract")
end

-- Actual executable!
local args = {...}
if #args ~= 3 then
  print_usage()
  return 1
end
if args[1] == "x" then
  zar_extract_full(args[3], args[2])
elseif args[1] == "c" then
  zar_create_full(args[3], args[2])
else
  print("Expected 'x' or 'c' for eXtract or Create, got " .. args[1])
  print_usage()
  return 1
end

return 0

-- vim:set expandtab:
-- vim:set shiftwidth=2:
-- vim:set tabstop=2:
