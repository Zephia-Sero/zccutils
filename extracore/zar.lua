-- Extract files from ZAR-archived data bytes
local function zar_extract(data)

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
    num = num // 256
  end

  return tbl
end

-- Internal function, please don't use zar to create single-file archives.
local function _zar_create_file(pathpfx, path)
  local file = io.open(pathpfx .. "/" .. path, "rb")
  local str = file:read()
  local fileContents = { str:byte(1, #str) }

  local outBytes = number_to_u32(#path)
  table_append(outBytes, { path:byte(1, #path) })
  table_append(outBytes, number_to_u32(#fileContents))
  table_append(outBytes, fileContents)
  for k, v in ipairs(outBytes) do
    print(v .. " '" ..  string.char(v) .. "'")
  end
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
      table_append(retVal, _copy_recursive(path, newDepth, newMid))
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
  
end

for k, v in recursive_path("zartest/") do
  print(k .. ": " .. v)
end

--_zar_create_file("zartest")


-- vim:set expandtab:
-- vim:set shiftwidth=2:
-- vim:set tabstop=2:
