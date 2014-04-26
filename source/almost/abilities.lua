Class = {}
function Class:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- map action -> input object
-- map action -> cooldown / max cooldown
-- set actions
-- map status -> object with duration, begin, update, end (periodic, persistent, stacking/refreshing, unique)

Action = Class:new{cd=0, maxcd=1}

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


-- for an object/unit that has a group of statuses
StatusMap = Class:new{}
function StatusMap:new(owner)
    map = Class.new(self, {owner=owner, statusMap={}})
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

function StatusMap:update(dt)
    for statusType, status in pairs(self.statusMap) do
        status.t = status.t - dt
        if status.t <= 0 then
            status:expire(self.owner)
            statusMap[statusType] = nil
        end
    end
end