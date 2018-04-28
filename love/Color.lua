local Vector = require 'Vector'

local Color = {
  FullBright   = Vector:new{1.0,   1.0,   1.0},
  ScreenBorder = Vector:new{0.15,  0.1,   0.2},
  BG           = Vector:new{0.25,  0.75,  0.25},
  FG           = Vector:new{0.5,   0.75,  0.25},
  [0] =
  Vector:new{0.2,   0.2,   0.2},
  Vector:new{0.522, 0.584, 0.631},
}

for index, color in pairs(Color) do
  if type(color) == 'table' and color.class == 'Vector' then
    color.class = 'Color'
  end
end

function Color.new(t)
  local v = Vector:new(t)
  v.class = 'Color'
  return v
end

return Color
