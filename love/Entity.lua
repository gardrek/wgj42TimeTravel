-- A game entity. An object in the game world with a location, and a timeline.

local Tiles = require 'Tiles'

local Entity = {}

Entity.__index = Entity
Entity.class = 'Entity'

function Entity:new(t)
  return Entity.dup(t)
end

function Entity:dup()
  local copy = {}
  local t
  for _, v in ipairs{'tile', 'timeline', 'kind'} do
    t = type(self[v])
    if t == 'table' then
      copy[v] = self[v]:dup()
    elseif t == 'nil' then
      --error('')
    else
      copy[v] = self[v]
    end
  end
  ---[[FIXME: blanket copying/referencing of all values in dup is bad mkay
  for k, v in pairs(self) do
    if type(v) ~= 'function' and copy[k] == nil then
      copy[k] = v
    end
  end
  --]]
  setmetatable(copy, Entity)
  return copy
end

function Entity:getPushed(map, zTime, vec)
  local loc = self.timeline:locationAtTime(zTime)
  local finalLocation = loc + vec
  local target = map:get(finalLocation)
  if target == Tiles.Floor or target == Tiles.Target then
    if #map:findEntityAt(finalLocation, zTime) == 0 then
      self.timeline:push{
        action = 'getPushed',
        loc = loc,
        target = vec:dup(),
      }
      return true
    end
  end
  return false
end

return Entity
