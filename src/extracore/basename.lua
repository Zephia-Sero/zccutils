local args = {...}
function print_usage()
  print("basename FILE [SUFFIX]")
  print("Strip directory and SUFFIX from file.")
end

if #args == 1 then print(fs.getName(args[1]))
elseif #args == 2 then
  local name = fs.getName(args[1])
  local suffix = args[2]
  if suffix == name:sub(-#suffix, -1) then
    print(name:sub(1, -#suffix - 1))
  else print(name) end
else
  print_usage()
end
