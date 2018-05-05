local Timeline = {}
local Action = {}

Timeline.__index = Timeline
Timeline.class = 'Timeline'

Action.__index = Action
Action.class = 'Action'

Timeline.moveActions = {
  move = true,
  pushObject = true,
  getPushed = true,
}

-- A timeline represents an objects lifetime. It contains a initial position and a list of actions/movements.

function Action:new(t)
  return Action.dup(t)
end

function Action:dup()
  local new = {}
  local member
  --[[
  for _, name in ipairs{'loc', 'target', 'action',} do
    member = self[name]
    if type(member) == 'table' then
      if type(member.dup) == 'function' then
        new[name] = member:dup()
      else
        error'passed table has no dup function'
      end
    else
      new[name] = member
    end
  end
  --]]
  new.loc = self.loc:dup()
  new.target = self.target and self.target:dup()
  new.action = self.action
  setmetatable(new, Action)
  return new
end

function Timeline:new(t)
  local new = Timeline.dup(t)
  if t.initial then
    new:push{
      action = 'spawn',
      loc = t.initial:dup(),
    }
  end
  return new
end

function Timeline:dup()
  local copy = {}
  for i, v in ipairs(self) do
    copy[i] = v:dup()
  end
  setmetatable(copy, Timeline)
  return copy
end

function Timeline:push(action)
  table.insert(self, Action:new(action))
end

function Timeline:tick()
  local lastAction = self[#self]
  local loc = self[#self].loc
  if Timeline.moveActions[lastAction.action] then
    loc = loc + lastAction.target
  end
  table.insert(self, Action:new{
    action = 'tick',
    loc = loc, -- NOTE: not duplicated
  })
end

function Timeline:locationAtTime(t)
  local action = self[math.floor(t)]
  if not action then
    error'oob'
  end
  local loc
  if Timeline.moveActions[action.action] then
    loc = action.loc + action.target
  else
    loc = action.loc:dup()
  end
  return loc
end

return Timeline, Action
