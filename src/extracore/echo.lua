local args = {...}
local echostr = ""

for i, v in ipairs(args) do
  echostr = echostr .. v
  if i ~= #args then
    echostr = echostr .. " "
  end
end

print(echostr)
