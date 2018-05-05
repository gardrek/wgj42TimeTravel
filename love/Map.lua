local Tiles = require 'Tiles'
local Vector = require 'Vector'
local Timeline = require 'Timeline'
local Entity = require 'Entity'

local Map = {}

Map.__index = Map
Map.class = 'Map'

function Map:new(t)
  return Map.dup(t)
end

function Map:dup()
  local m = {
    w = self.w, h = self.h,
    tileset = self.tileset,
    player = self.player,
    entities = self.entities,
  }
  if self.blocks then
    m.blocks = {}
    for i, v in ipairs(self.blocks) do
      m.blocks = v:dup()
    end
  end
  for yi = 1, self.h do
    m[yi] = {}
    for xi = 1, self.w do
      m[yi][xi] = self[yi][xi]
    end
  end
  setmetatable(m, Map)
  return m
end

--[[
function Map.draw(map, x, y, z, callback, tileset)
  local t = tileset or Tiles
  local image = t.image --or map.tileset--.image
  --TODO: stop recreating this every frame, move it to the tileset object
  map.quad = love.graphics.newQuad(x, y, t.tileWidth, t.tileHeight, image:getWidth(), image:getHeight())

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
        map.quad:setViewport(
          (tile % t.tilesPerLine) * t.tileWidth,
          math.floor(tile / t.tilesPerLine) * t.tileHeight,
          t.tileWidth, t.tileHeight
        )
        love.graphics.draw(
          image, map.quad,
          (xi + tx - 1) * t.tileWidth + x,
          (yi + ty - 1) * t.tileHeight + y
        )
      end
    end
  end

  if map.entities then
    --print'drawing entities'
    for _, v in ipairs(map.entities) do
      tile = v.tile or 15
      tx, ty = v.timeline:locationAtTime(z):unpack()
      map.quad:setViewport(
        (tile % t.tilesPerLine) * t.tileWidth,
        math.floor(tile / t.tilesPerLine) * t.tileHeight,
        t.tileWidth, t.tileHeight
      )
      love.graphics.draw(
        image, map.quad,
        (tx - 1) * t.tileWidth + x,
        (ty - 1) * t.tileHeight + y
      )
    end
  end
end
--]]

function Map:draw(x, y, timeStep, options)
  options = options or {}
  local callback = options.callback
  local tileset = options.tileset or self.tileset --or Tiles
  local tileOffset = options.tileOffset-- or Vector:new{0, 0}
  local image = tileset.image
  --TODO: stop recreating this every frame, move it to the tileset object

  local tile, tx, ty

  for yi = 1, self.h do
    for xi = 1, self.w do
      tile = self[yi][xi]
      if callback then
        tile, tx, ty = callback(tile, xi - 1, yi - 1) -- FIXME: this off-by-one thing could be a problem
        error''
      else
        --tx, ty = 0, 0
      end
      if tileOffset then
        tx, ty = tileOffset(xi, yi)
      else
        tx, ty = 0, 0
      end
      if tile >= 0 then
        tileset.quad:setViewport(
          (tile % tileset.tilesPerLine) * tileset.tileWidth,
          math.floor(tile / tileset.tilesPerLine) * tileset.tileHeight,
          tileset.tileWidth, tileset.tileHeight
        )
        love.graphics.draw(
          image, tileset.quad,
          (xi + tx - 1) * tileset.tileWidth + x,
          (yi + ty - 1) * tileset.tileHeight + y
        )
      end
    end
  end

  if self.entities then
    --print'drawing entities'
    for _, v in ipairs(self.entities) do
      if v.timeline[timeStep] then
        tile = v.tile or 15
        local xi, yi = v.timeline:locationAtTime(timeStep):unpack()
        if tileOffset then
          tx, ty = tileOffset(xi, yi)
        else
          tx, ty = 0, 0
        end
        tileset.quad:setViewport(
          (tile % tileset.tilesPerLine) * tileset.tileWidth,
          math.floor(tile / tileset.tilesPerLine) * tileset.tileHeight,
          tileset.tileWidth, tileset.tileHeight
        )
        love.graphics.draw(
          image, tileset.quad,
          (xi + tx - 1) * tileset.tileWidth + x,
          (yi + ty - 1) * tileset.tileHeight + y
        )
      end
    end
  end
end

function Map.checksanity(map)
  assert(map.tileset)
  assert(map.h == #map)
  for yi = 1, #map do
    assert(map.w == #map[yi])
  end
  if map.entities then
    local timeLength = #map.entities[1].timeline
    for i = 2, #map.entities do
      assert(timeLength == #map.entities[i].timeline)
    end
  end
end

do
  local t = Tiles
  Map[1] = Map:new{
    tileset = t,
    w = 7, h = 9,
    {t.Wall, t.Wall, t.Wall, t.Wall, t.Wall, t.Wall, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Floor, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Block, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Block, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Player, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Target, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Target, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Floor, t.Floor, t.Floor, t.Floor, t.Floor, t.Wall},
    {t.Wall, t.Wall, t.Wall, t.Wall, t.Wall, t.Wall, t.Wall},
  }
end

function Map:load(map)
  map:checksanity()
  local loaded = --map:dup()
  {
    w = map.w, h = map.h,
    tileset = map.tileset,
    entities = {},
  }
  --local tset = loaded.tileset
  local tile
  local entity
  for yi = 1, map.h do
    loaded[yi] = {}
    for xi = 1, map.w do
      tile = map[yi][xi]
      if tile == Tiles.Player then
        table.insert(loaded.entities, Entity:new{
          tile = tile,
          timeline = Timeline:new{
            initial = Vector:new{xi, yi},
          },
          kind = 'player',
        })
        loaded[yi][xi] = Tiles.Floor
      elseif tile == Tiles.Block then
        table.insert(loaded.entities, Entity:new{
          tile = tile,
          timeline = Timeline:new{
            initial = Vector:new{xi, yi},
          },
          kind = 'block',
        })
        loaded[yi][xi] = Tiles.Floor
      --[[
        loaded.player = loaded.player or {}
        loaded.player.loc = Vector:new{xi, yi} -- Fixme: Curse you, Fencepost!
        loaded[yi][xi] = t.Floor
      elseif tile == t.Block then
        table.insert(loaded.blocks, Vector:new{xi, yi})
        loaded[yi][xi] = t.Floor
      --]]
      else
        loaded[yi][xi] = tile
      end
      --loaded[yi][xi] = tile
    end
  end
  return Map.dup(loaded)
end

function Map:find(tile)
  local found = {}
  for yi = 1, self.h do
    for xi = 1, self.w do
      if tile == self[yi][xi] then
        table.insert(found, Vector:new{xi, yi})
      end
    end
  end
  return found
end

function Map:findEntity(entity)
  local found = {}
  for i, v in ipairs(self.entities) do
    if v.kind == entity then
      table.insert(found, v)
    end
  end
  return found
end

function Map:findEntityAt(loc, zTime)
  local found = {}
  for i, v in ipairs(self.entities) do
    if loc == v.timeline:locationAtTime(zTime) then
      table.insert(found, v)
    end
  end
  return found
end

--[[
function Map:eachEntity(entity)
  if entity then
  else
  end
end
--]]

function Map:get(vec)
  if self:oob(vec) then error('Out of bounds map access.', 2) end
  local x, y = vec:unpack()
  return self[y][x]
end

function Map:set(vec, tile)
  if self:oob(vec) then error('Out of bounds map access.', 2) end
  local x, y = vec:unpack()
  self[y][x] = tile
end

function Map:oob(vec)
  local x, y = vec:unpack()
  return x < 1 or x > self.w or y < 1 or y > self.h
end

for i = 1, #Map do
--  setmetatable(Map[i], Map)
  Map[i]:checksanity()
end

return Map
