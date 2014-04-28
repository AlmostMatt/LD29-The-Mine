Class = {}
function Class:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- a group of actions for an object
ActionMap = Class:new{}
function ActionMap:new(owner)
    return Class.new(self, {owner=owner, map={}})
end

function ActionMap:add(actionName, action)
    action.owner = self.owner
    self.map[actionName] = action
end

function ActionMap:use(actionName, ...)
    return self.map[actionName]:use(...)
end

function ActionMap:ready(actionName)
    return self.map[actionName]:ready()
end

function ActionMap:update(dt)
    for _, action in pairs(self.map) do
        action:update(dt)
    end
end

-- map action -> input object
-- map action -> cooldown / max cooldown
-- set actions
-- map status -> object with duration, begin, update, end (periodic, persistent, stacking/refreshing, unique)

Action = Class:new{cd=0, maxcd=1}
Action.JUMP = 0
Action.THROW = 1
Action.DIG = 2
Action.PLACE = 3


function Action:ready()
    return self.cd <= 0
end

function Action:use()
    self.cd = self.maxcd
end

function Action:update(dt)
    self.cd = math.max(0, self.cd - dt)
end


-- status object methods
Status = Class:new{t=nil, dur=0, stacks=0, maxStacks=1}

function Status:begin(owner)
end

function Status:expire(owner)
end

Digging = Status:new{t=1}

-- for an object/unit that has a group of statuses
StatusMap = Class:new{}
function StatusMap:new(owner)
    return Class.new(self, {owner=owner, statusMap={}})
end

function StatusMap:add(status, duration)
    if self:has(status) then
        status = self.statusMap[status.t]
        status.dur = math.max(status.dur, duration)
        status.stacks = math.min(status.maxStacks, status.stacks + 1)
    else
        status.dur = duration
        self.statusMap[status.t] = status
        status:begin(self.owner)
    end
end

function StatusMap:has(status)
    return self.statusMap[status.t] ~= nil
end

function StatusMap:duration(status)
    return self.statusMap[status.t].dur
end

function StatusMap:update(dt)
    for statusType, status in pairs(self.statusMap) do
        status.dur = status.dur - dt
        if status.dur <= 0 then
            status:expire(self.owner)
            self.statusMap[status.t] = nil
        end
    end
end