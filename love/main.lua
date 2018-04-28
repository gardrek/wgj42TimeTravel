require 'noglobals'

io.stdout:setvbuf('no') -- enable normal use of the print() command
love.graphics.setDefaultFilter('nearest', 'nearest') -- Pixel scaling

local Vector = require 'Vector'
local Color = require 'Color'
local Tiles = require 'Tiles'
local Maps = require 'Maps'

local Game = {}

Game.screen = love.graphics.newCanvas(256, 128)
Game.scale = 3
Game.width = 128
Game.height = 64
Game.minw = math.floor(Game.width * 1.03125)
Game.minh = math.floor(Game.height * 1.0625)
Game.center = {}
Game.center.x = math.floor(love.graphics.getWidth() / 2)
Game.center.y = math.floor(love.graphics.getHeight() / 2)

local Camera = {
  x, y = Game.width / 2, Game.height / 2
}

local Player = {
  loc = Vector:new{1, 1},
  image = love.graphics.newImage('player.png'),
  timeTravelAnim = 0.0,
  timeTravelAnimTarget = 0.0,
}


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

local currentMap = Maps[1]

local TILESIZE = 8

function love.load()
  love.resize()
end

function love.update(dt)
  if love.keyboard.isDown('x') then
    Player.timeTravelAnimTarget = Player.timeTravelAnimTarget + dt * 8
  end
  if love.keyboard.isDown('z') then
    Player.timeTravelAnimTarget = Player.timeTravelAnimTarget - dt * 8
  end
  Player.timeTravelAnimTarget = math.min(math.max(0.0, Player.timeTravelAnimTarget), 1.0)
  Player.timeTravelAnim = ease(Player.timeTravelAnim, Player.timeTravelAnimTarget, 16)
  Player.timeTravelAnim = math.min(math.max(0.0, Player.timeTravelAnim), 1.0)
end

function love.keypressed(key, scancode, isrepeat)
  if key == 'w' or key == 'up' then
    Player.loc.y = Player.loc.y - 1
  elseif key == 's' or key == 'down' then
    Player.loc.y = Player.loc.y + 1
  elseif key == 'a' or key == 'left' then
    Player.loc.x = Player.loc.x - 1
  elseif key == 'd' or key == 'right' then
    Player.loc.x = Player.loc.x + 1
  end
end

local tef = 0
function love.draw()
  love.graphics.clear(Color.ScreenBorder)

  Game.screen:renderTo(function ()
    love.graphics.clear(Color[1])

    tef = tef + 0.25
    love.graphics.setColor(Color.FullBright)

    -- TODO: put camera stuff here
    love.graphics.push()
    love.graphics.translate(70, 20)

    local count = -math.ceil(Player.timeTravelAnim * 11)
    for i = count, 0 do
      love.graphics.setColor(Vector:new{1, 1, 1, (count - i - 1) / (count - 1)})
      Maps.draw(
        currentMap,
        2 * i * math.sin((((tef + i * 5) % 100) / 100) * math.pi * 2),
        2 * i * math.cos((((tef + i * 5) % 100) / 100) * math.pi * 2),
        function(tile, x, y)
          local rx, ry = 
            --math.sin((((tef + x) % 100) / 100) * math.pi * 2),
            --math.sin((((tef + y + 12.5) % 100) / 100) * math.pi * 2)
            (x - Player.loc.x) * Player.timeTravelAnim,-- + math.sin((((tef + x) % 100) / 100) * math.pi * 2),
            (y - Player.loc.y) * Player.timeTravelAnim-- + math.tan((((tef + y) % 100) / 100) * math.pi * 2)
          if tile == Tiles.Floor then tile = -1 end
          return tile, rx, ry
        end
      )
    end

    love.graphics.setColor(Color.FullBright)

    love.graphics.draw(
      Player.image,
      Player.loc.x * TILESIZE, Player.loc.y * TILESIZE
    )

    love.graphics.pop()
  end)

  love.graphics.setColor(Color.FullBright)
  love.graphics.draw(Game.screen, Game.x, Game.y, 0, Game.scale, Game.scale)
end

function love.resize(w, h)
  w = w or love.graphics.getWidth()
  h = h or love.graphics.getHeight()
  Game.center.x = math.floor(w / 2)
  Game.center.y = math.floor(h / 2)
  local scale = 2 -- WHY THO
  Game.scale = math.floor(math.min(
    w / (Game.minw * scale),
    h / (Game.minh * scale)
  ))
  Game.scale = math.max(Game.scale, 1)
  Game.x = Game.center.x - math.floor(Game.width / 2) * Game.scale * scale
  Game.y = Game.center.y - math.floor(Game.height / 2) * Game.scale * scale
end
