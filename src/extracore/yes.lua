local args = {...}
local yesstr = "y"
if #args ~= 0 then
  yesstr = ""
end

for i, v in ipairs(args) do
  yesstr = yesstr .. v
  if i ~= #args then
    yesstr = yesstr .. " "
  end
end

while true do
  print(yesstr)
end
