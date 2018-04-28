local Tiles = {
  None = 0,
  Air = 33,
  Floor = 16,
  Wall = 64,
}

Tiles.image = love.graphics.newImage('tiles.png')
Tiles.tileWidth = 8
Tiles.tileHeight = 8

return Tiles
