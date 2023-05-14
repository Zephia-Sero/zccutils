local args = {...}

local function print_usage()
  print("cat [-nb] [FILE]...")
  print("Print FILEs to stdout")
  print("\t-n\tNumber output lines")
  print("\t-b\tNumber nonempty lines")
end

local function characters(str)
  local i = 0
  return function()
    if i < #str then
      i = i + 1
      return i, str:sub(i, i)
    else return nil end
  end
end

local posixargs = {}
local infiles = {}

for _, arg in ipairs(args) do
  if arg == "--help" then
    print_usage()
    return 0
  end
  if #arg > 0 and arg:sub(1,1) == "-" then
    for _, ch in characters(arg:sub(2,-1)) do
      if posixargs[ch] == nil then
        posixargs[ch] = 1
      else posixargs[ch] = posixargs[ch] + 1 end
    end
  else
    infiles[#infiles + 1] = arg
  end
end

local lineno = 1
local outstr = ""
for _, filepath in ipairs(infiles) do
  local fh = fs.open(filepath, "r")
  if fh == nil then
    print("File '" .. filepath .. "' does not exist.")
    print_usage()
    return 1
  end
  local line = fh.readLine()
  while line ~= nil do
    if posixargs.b ~= nil then
      if line ~= "" then
        outstr = outstr .. "\t" .. lineno .. " " .. line .. "\n"
        lineno = lineno + 1
      else outstr = outstr .. "\n" end
    elseif posixargs.n ~= nil then
      outstr = outstr .. "\t" .. lineno .. " " .. line .. "\n"
      lineno = lineno + 1
    else
      outstr = outstr .. line .. "\n"
    end
    line = fh.readLine()
  end
  fh.close()
end

print(outstr)
