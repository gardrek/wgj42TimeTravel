local Tiles = {
  None = -1,
  Floor = 0,
  Wall = 1,
  Block = 2,
  Target = 3,
  Player = 12,
}

Tiles.image = love.graphics.newImage('tiles.png')
Tiles.tileWidth = 16
Tiles.tileHeight = 16
Tiles.tilesPerLine = 4

Tiles.quad = love.graphics.newQuad(
  0, 0,
  Tiles.tileWidth, Tiles.tileHeight,
  Tiles.image:getWidth(), Tiles.image:getHeight()
)

function Tiles:new(t)
  local new = {}

  for _, v in ipairs{
    'image',
    'tileWidth',
    'tileHeight',
    'tilesPerLine',
  } do
    new[v] = t[v]
  end

  new.quad = love.graphics.newQuad(
    0, 0,
    new.tileWidth, new.tileHeight,
    new.image:getWidth(), new.image:getHeight()
  )

  return new
end

return Tiles
