require 'noglobals'

io.stdout:setvbuf('no') -- enable normal use of the print() command
love.graphics.setDefaultFilter('nearest', 'nearest') -- Pixel scaling

local Vector = require 'Vector'
local Color = require 'Color'
local Tiles = require 'Tiles'
local Map = require 'Map'
local Timeline, Action = require 'Timeline'
local Entity = require 'Entity'

local inspect = require 'inspect'

local function prinspect(...)
  print(inspect(...))
end

local Game = {}

local MinimapTileset = Tiles:new{
  image = love.graphics.newImage('maptiles.png'),
  tileWidth = 8,
  tileHeight = 8,
  tilesPerLine = 4,
}

Game.scale = 3
Game.width = 384 --256
Game.height = 216 --160
Game.screen = love.graphics.newCanvas(Game.width, Game.height)

-- 8 game-pixel wide border
Game.minw = math.floor(Game.width / 8 + 1) * 8
Game.minh = math.floor(Game.height / 8 + 1) * 8

Game.center = Vector:new{
  math.floor(love.graphics.getWidth() / 2),
  math.floor(love.graphics.getHeight() / 2),
}

local Camera = {
  x, y = Game.width / 2, Game.height / 2
}

--[[
local player1 = Entity:new{
  loc = Vector:new{1, 1},
  image = love.graphics.newImage('player.png'),
  timeTravelAnim = 0.0,
  timeTravelAnimTarget = 1.0,
  time = 0,
}

player1.timeline = Timeline:new{initial = player1.loc:dup()}
player1.timeline:push{action = 'spawn', loc = player1.loc:dup()}
--]]

local function ease(x, tx, drag, min)
  drag = drag or 8
  min = min or 0.001
  local dx = (tx - x) / drag
  if math.abs(dx) < min then
    return tx
  else
    return x + dx
  end
end

local currentMap = Map:load(Map[1])

local currentTime = 1

local timeline = {currentMap}

local player1 = currentMap:findEntity'player'[1]

player1.timeTravelAnim = 0.0
player1.timeTravelAnimTarget = 0.0
player1.time = 0

function player1:move(vec)

  if #self.timeline ~= currentTime then
    for _, v in ipairs(currentMap.entities) do
      for i in ipairs(v.timeline) do
        if i > currentTime then
          v.timeline[i] = nil
        end
      end
    end
  end

  local laststep = self.timeline[currentTime]
  local lastloc
  if laststep then
    if Timeline.moveActions[laststep.action] then
      lastloc = laststep.loc + laststep.target
    else
      lastloc = laststep.loc:dup()
    end
  else
    error'empty timeline'
  --  lastloc = player1.timeline.initial
  end
  local finalLocation = lastloc + vec

  local pushedObject

  if currentMap:get(finalLocation) == Tiles.Wall then
    self.timeline:push{
      action = 'tick',
      loc = lastloc,
    }
  else
    local ents = currentMap:findEntityAt(finalLocation, currentTime)
    if #ents > 0 then
      pushedObject = ents[1]:getPushed(currentMap, currentTime, vec)
      if pushedObject then
        self.timeline:push{
          action = 'pushObject',
          loc = lastloc,
          target = vec:dup(),
        }
      else
        self.timeline:push{
          action = 'tick',
          loc = lastloc,
        }
      end
    else
      self.timeline:push{
        action = 'move',
        loc = lastloc,
        target = vec:dup(),
      }
    end
  end

  for _, v in ipairs(currentMap.entities) do
    if not v.timeline[currentTime + 1] then
      v.timeline:tick()
    end
  end

  currentMap:checksanity()

  --[[
  for _, v in ipairs(self.timeline) do
    print(v.action)
  end
  print'---'
  --]]

  currentTime = currentTime + 1

--[[
  player1.time = player1.time + 1
  local oldMap = currentMap
  currentMap = oldMap:dup()
  table.insert(timeline, currentMap)
  local players = currentMap:find(Tiles.Player)
  if #players == 1 then
    local oldPlayerLoc = players[1]
    --oldMap[t.y][t.x] = Tiles.Floor
    currentMap:set(oldPlayerLoc, Tiles.Floor)
  else
    print'time paradox'
  end
  self.loc = self.loc + vec
  currentMap.player = currentMap.player or {}
  currentMap.player.loc = self.loc
  if not currentMap:oob(self.loc) then
    currentMap:set(self.loc, Tiles.Player)
  else
    print'oob'
  end
  --]]
end

local TILESIZE = 16

function love.load()
  --[[ loop track forever
  local music = love.audio.newSource("music_loop.wav")
  music:setLooping(true)
  music:play()
  --]]

  love.resize()
end

function love.update(dt)
  player1.timeTravelAnimTarget = math.min(math.max(0.0, player1.timeTravelAnimTarget), 1.0)
  player1.timeTravelAnim = ease(player1.timeTravelAnim, player1.timeTravelAnimTarget, 8)
  player1.timeTravelAnim = math.min(math.max(0.0, player1.timeTravelAnim), 1.0)
end

local c = 5
function love.keypressed(key, scancode, isrepeat)
  local moveVector
  if key == 'escape' then
    --love.event.quit()
  elseif key == 'w' or key == 'up' then
    moveVector = Vector:new{0, -1}
  elseif key == 's' or key == 'down' then
    moveVector = Vector:new{0, 1}
  elseif key == 'a' or key == 'left' then
    moveVector = Vector:new{-1, 0}
  elseif key == 'd' or key == 'right' then
    moveVector = Vector:new{1, 0}
  elseif key == 'z' then
    currentTime = math.max(currentTime - 1, 1)
    --player1.time = player1.time - 1
  elseif key == 'x' then
    currentTime = math.min(currentTime + 1, #player1.timeline)
    --player1.time = player1.time + 1
  elseif key == 'c' then
    if player1.timeTravelAnimTarget > 0.5 then
      player1.timeTravelAnimTarget = 0.0
    else
      player1.timeTravelAnimTarget = 1.0
    end
  elseif key == 'y' then
    c = (c + 1) % 8
  end
  if moveVector then
    player1:move(moveVector)
    --player1.loc = player1.loc + moveVector
  end
end

local tef = 0

local function drawWorldLayer(x, y)
--  currentMap:draw(x, y, currentTime)
end

function love.draw()
  love.graphics.clear(Color.ScreenBorder)

  Game.screen:renderTo(function()
    --love.graphics.clear(Color[5])
    love.graphics.clear(Color[c])

    tef = tef + 0.25
    love.graphics.setColor(Color.FullBright)

    local timeZ
    local count = math.floor(5 * player1.timeTravelAnim + 0.5)
    for i = -count, count do
      love.graphics.setColor(1, 1, 1, (5 - math.abs(i)) / 5)
      timeZ = math.floor(currentTime + i)
      currentMap:draw(40, 40, timeZ, {
        tileOffset = function(x, y)
          return i * player1.timeTravelAnim * 0.25 * math.sin((((tef + i) % 100) / 100) * math.pi * 2),
          i * player1.timeTravelAnim * 0.25 * math.cos((((tef + i) % 100) / 100) * math.pi * 2)
        end,
      })
    end

    love.graphics.setColor(Color.FullBright)

    --[======[
    -- TODO: put camera stuff here
    love.graphics.push()
    love.graphics.translate(70, 20)

    --[==[
    local count = -math.ceil(player1.timeTravelAnim * 11)
    for i = -11, 0 do
      love.graphics.setColor(1, 1, 1, (count - i - 1) / (count - 1))
      if timeline[-i + 1] then
        Map.draw(
          timeline[-i + 1],
          3 * i,-- * math.sin((((tef + i * 5) % 100) / 100) * math.pi * 2),
          3 * i,-- * math.cos((((tef + i * 5) % 100) / 100) * math.pi * 2),
          function(tile, x, y)
            if tile == Tiles.Floor then tile = -1 end
            return tile, ((Vector:new{x, y} - player1.loc) * player1.timeTravelAnim):unpack()
          end
        )
      end
    end
    --]==]

    ---[=====[
    local count = math.floor(10.5 * player1.timeTravelAnim)
    --local count = math.floor((#timeline + 0.5) * player1.timeTravelAnim)
    local intensity, tensity, tl, signedIntensity
    for i = -count, count do
      if count == 0 then
        intensity = 1.0
      else
        intensity = (count - math.abs(i)) / count
      end
      signedIntensity = intensity * (count >= 0 and 1 or -1)
      tensity = 1 - intensity
      if i == 0 then
        love.graphics.setColor(1, 1, 1, 1)
      else
        love.graphics.setColor(1, 1, 1, intensity)
      end
      --love.graphics.setColor(1, 1, 1, intensity)
      tl = timeline[i + player1.time + 1]
      if tl then
        Map.draw(
          tl,
          30 * signedIntensity * math.sin((((tef + signedIntensity * 5) % 100) / 100) * math.pi * 2),
          30 * signedIntensity * math.cos((((tef + signedIntensity * 5) % 100) / 100) * math.pi * 2),
          function(tile, x, y)
            if tile == Tiles.Floor then tile = -1 end
            return tile, ((Vector:new{x, y} - player1.loc) * player1.timeTravelAnim):unpack()
          end
        )
      end
    end
    --]=====]

    love.graphics.setColor(Color.FullBright)

    --[[
    love.graphics.draw(
      player1.image,
      player1.loc.x * TILESIZE, player1.loc.y * TILESIZE
    )
    --]]

    love.graphics.pop()
    --]======]

    currentMap:draw(
      256, 0,
      currentTime,
      {tileset = MinimapTileset}
    )
  end)

  love.graphics.setColor(Color.FullBright)
  love.graphics.draw(Game.screen, Game.x, Game.y, 0, Game.scale, Game.scale)
end

function love.resize(w, h)
  w = w or love.graphics.getWidth()
  h = h or love.graphics.getHeight()
  Game.center.x = math.floor(w / 2)
  Game.center.y = math.floor(h / 2)
  local scale = 1 -- WHY THO
  Game.scale = math.floor(math.min(
    w / (Game.minw * scale),
    h / (Game.minh * scale)
  ))
  Game.scale = math.max(Game.scale, 1)
  Game.x = Game.center.x - math.floor(Game.width / 2) * Game.scale * scale
  Game.y = Game.center.y - math.floor(Game.height / 2) * Game.scale * scale
end
