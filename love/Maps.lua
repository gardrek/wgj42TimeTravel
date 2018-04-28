local t = require 'Tiles'

local Maps = {
  {
    w = 7, h = 7,
    {t.Wall, t.Wall, t.Wall, t.Wall, t.Wall, t.Wall, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Floor, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Air, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Air, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Air, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Floor, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Wall, t.Wall, t.Wall, t.Wall, t.Wall, t.Wall},
    tileset = t.image,
  },
}

function Maps.draw(map, x, y, callback)
  local w, h = 1, #map
  local image = map.tileset
  assert(image)
  Maps.quad = Maps.quad or love.graphics.newQuad(x, y, t.tileWidth, t.tileHeight, image:getWidth(), image:getHeight())
  for yi = 1, #map do
    assert(map.w == #map[yi])
  end
  assert(map.h == #map)
  local tile, tx, ty
  for yi = 1, map.h do
    for xi = 1, map.w do
      tile = map[yi][xi]
      if callback then
        tile, tx, ty = callback(tile, xi - 1, yi - 1) -- FIXME: this off-by-one thing could be a problem
      else
        tx, ty = 0, 0
      end
      if tile >= 0 then
        Maps.quad:setViewport((tile % 16) * t.tileWidth, math.floor(tile / 16) * t.tileHeight, t.tileWidth, t.tileHeight)
        love.graphics.draw(image, Maps.quad, (xi + tx - 1) * t.tileWidth + x, (yi + ty - 1) * t.tileHeight + y)
      end
    end
  end
end

return Maps
