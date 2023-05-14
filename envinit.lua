-- Get side of computer with a disk drive labeled `searchLabel`
-- `searchSides` optionally allows you to restrict searching to
-- a table of side strings, for example { "top", "bottom" }
-- by default though, it searches every side.
local function get_side_with_disk_label(searchLabel, searchSides)
  if searchLabel == nil then return nil end
  local sides = { "back", "right", "front", "left", "top", "bottom" }
  if searchSides ~= nil then
    sides = searchSides
  end
  for _, side in pairs(sides) do
    if disk.getLabel(side) == searchLabel then
      return side
    end
  end
end

-- Internal function to copy files recursively from `from` to `to`. See
-- copy_recursive for more info. Mid is internally used to add the path to the
-- output file of recursed directories.
local function _copy_recursive(from, to, verbose, maxDepth, mid)
  -- Remove /path/to/from/ from the input file
  local baseToRemove = from
  if not fs.isDir(from) then
    baseToRemove = fs.getDir(from)
  end

  local retVal = true

  for _, path in pairs(fs.find(from .. "/*")) do
    -- Cut off the first part of the path and add the recursed directory path
    local newMid = mid .. "/" .. path:sub(#baseToRemove + 1, -1)
    -- Add in the path to copy to
    local toPath = to .. "/" .. newMid
    -- Keep copying if we haven't hit our maxDepth yet
    if fs.isDir(path) and maxDepth ~= 0 then
      -- Make a directory for the recursed files inside
      if verbose then
        print("mkdir \"" .. toPath .. "\"")
      end
      fs.makeDir(toPath)
      -- Decrease max depth unless we're negative, then it doesn't matter.
      local newDepth = maxDepth - 1
      if maxDepth < 0 then
        newDepth = -1
      end
      -- And recurse further
      retVal = _copy_recursive(path, to, newDepth, newMid) and retVal
    else
      if fs.exists(toPath) and not fs.isDir(toPath) then
        if verbose then
          print("rm \"" .. toPath .. "\"")
        end
        fs.delete(toPath)
      elseif fs.exists(toPath) then
        print("error: could not copy file `" .. path .. "` to `" .. toPath .. "`: cannot delete directories")
        retVal = false
      end
      if not (fs.isDir(path) and maxDepth == 0) then
        if verbose then
          print("\"" .. path .. "\" -> \"" .. toPath .. "\"")
        end
        fs.copy(path, toPath)
      end
    end
  end
  return retVal
end

-- Copies files recursively. If verbose is true (defaults to true), prints each
-- file name copied in the form `from/path/file -> to/path/file`. If maxDepth is
-- negative (defaults to -1), recurses infinitely. Returns false on failure, true
-- on success.
local function copy_recursive(from, to, verbose, maxDepth)
  -- Defaults
  if verbose == nil then verbose = true end
  if maxDepth == nil then maxDepth = -1 end
  return _copy_recursive(from, to, verbose, maxDepth, "")
end

-- Actual code
local args = {...}
env = "programming"
if #args == 1 then
  if args[1] == "programming" or args[1] == "p" then
    env = "programming"
  end
end

local zccutilsDiskSide = get_side_with_disk_label("zccutils")
if zccutilsDiskSide == nil then
  print("Could not find zccutils disk in adjacent drives!")
  return 1
end

local zccutilsPath = disk.getMountPath(zccutilsDiskSide)

-- copy stuff over
copy_recursive(zccutilsPath .. "/environments/" .. env, "/")
copy_recursive(zccutilsPath .. "/extracore/", "/extracore/")
copy_recursive(zccutilsPath, "/", true, 0)
fs.delete("/envinit.lua")

-- vim:set expandtab:
-- vim:set shiftwidth=2:
-- vim:set tabstop=2:
