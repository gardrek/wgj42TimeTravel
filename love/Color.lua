local Vector = require 'Vector'

local Color = {
  FullBright   = Vector:new{1.0,   1.0,   1.0},
  ScreenBorder = Vector:new{0.15,  0.1,   0.2},
  BG           = Vector:new{0.25,  0.75,  0.25},
  FG           = Vector:new{0.5,   0.75,  0.25},
}

function Color:new(t)
  local v
  if type(t) == 'table' then
    v = Vector:new(t)
  elseif type(t) == 'string' then
    t = tonumber(t, 16)
  elseif type(t) ~= 'number' then
    error'bad color init'
  end
  if type(t) == 'number' then
    v = Vector:new{
      (math.floor(t / (256 * 256)) % 256) / 255,
      (math.floor(t / 256) % 256) / 255,
      (t % 256) / 255
    }
  end
  v.class = 'Color'
  return v
end

do
  local c = {
    [0] =
    0x000000,
    0x333333,
    0x884477,
    0xcc77aa,
    0x5599bb,
    0x88dddd,
    0xcccccc,
    0xeeeeee,
  }
  for i = 0, #c do
    Color[i] = Color:new(c[i])
  end
end

for index, color in pairs(Color) do
  if type(color) == 'table' and color.class == 'Vector' then
    color.class = 'Color'
  end
end

return Color
