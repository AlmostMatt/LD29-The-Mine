require("almost/entity")
require("almost/abilities")

MOVE_ACCEL = 1300
MAX_SPEED = 370
GRAVITY = 700
TERMINAL_V = 1200
JUMP_SPEED = -300
FRICTION = 400



function InitObjects()
    explosives = {}
    units = {}
    lights = {}
    materials = {}
    targets = {}
    spawnUnit()
end





Torch = Entity:new{}
function Torch:add(o)
    local o = Entity.add(self, o, LIGHTS)
    table.insert(lights, o)
    return o
end
function Torch:update(dt)
    ps:burn(self.p, 8)
end




-- a target indicates something for a unit to do
Type.Target = Type.new()
Target = Entity:new{t=Type.Target, p=P(0,0)}

function Target:update(dt)
    -- closer idle worker -> change to new worker
    -- closer busy worker + closer than busy worker's task -> change to new worker
    
    local newWorker = nil
    local maxD = math.huge
    if self.worker then
        maxD = Vdd(Vsub(self.worker:center(), self.p))
    end
    for _, u in ipairs(units) do
        --check if the worker is closer than the current worker and that this target is closer than his current task
        local dd = Vdd(Vsub(u:center(), self.p))
        if dd < maxD then
            if u.target == nil then
                newWorker = u
                break
            else
                local otherD = Vdd(Vsub(u:center(), u.target.p))
                if dd < otherD then
                    newWorker = u
                    break
                end
            end
        end
    end
    if newWorker then
        if self.worker then
            self.worker.target = nil
        end
        if newWorker.target then
            newWorker.target.worker = nil
        end
        newWorker.target = self
        newWorker:dropAll()
        self.worker = newWorker
    end
    if map:getTile(self.p) == 0 then
        self.destroyed = true
        if self.worker then
            self.worker.target = nil
            self.worker = nil
        end
    end
end

function Target:draw(a)
    if self.worker == nil then
        love.graphics.setColor(128,0,0,255)
    else
        love.graphics.setColor(128,128,128,255)
        local p2 = self.worker:center()
        love.graphics.line(self.p[1], self.p[2], p2[1], p2[2])
        love.graphics.setColor(0,0,128,255)
    end
    local r1 = 16
    local r2 = 20
    love.graphics.circle("line", self.p[1], self.p[2], r1)
    love.graphics.line(self.p[1], self.p[2] + r2, self.p[1], self.p[2] - r2)
    love.graphics.line(self.p[1] + r2, self.p[2], self.p[1] - r2, self.p[2])
end

function markTarget(point)
    local target = Target:add({p=point}, FOREGROUND)
    table.insert(targets, target)
end




-- physics object
Type.Object = Type.new()
Object = Entity:new{t=Type.Object, onGround = false, hitWall = false, falls=true, elastic=0, drag=0, airdrag=0, size={16,16}}
function Object:add(o, layer)
    o = o or {}
    o.p = o.p or P(0, 0)
    o.v = o.v or P(0, 0)
    return Entity.add(self, o, layer)
end

function Object:update(dt)
    if self.falls then
        self.v[2] = self.v[2] + GRAVITY * dt
        self.v[2] = math.min(self.v[2], TERMINAL_V)
    end
    
    map:collide(self, dt)
    local drag = self.onGround and (self.drag * FRICTION) or (self.airdrag * FRICTION)
    if drag ~= 0 then
        drag = drag * dt
        local spd = Vmagn(self.v)
        if spd < drag then
            self.v = P(0,0)
        else
            self.v = Vmult((spd - drag)/spd, self.v)
        end
    end
end

--[[
function Object:collisionCheck(map)
    local pen = map:getLeastPen(self.p, self.size)
    if pen[1] ~= 0 or pen[2] ~= 0 then
        if pen[2] ~= 0 and (pen[1] == 0 or math.abs(pen[1]) > math.abs(pen[2])) then
            self.p[2] = self.p[2] + pen[2]
            self.v[2] = 0
            if pen[2] < 0 then
                self.onGround = true
            end
        else
            self.p[1] = self.p[1] + pen[1]
            self.v[1] = 0
        end
    end
end
]]

function Object:center()
    return Vadd(self.p, Vmult(0.5, self.size))
end

function Object:draw(a)
    if a then
        self.col[4] = a
        self.line[4] = a
    else
        self.col[4] = 255
        self.line[4] = 255
    end
    love.graphics.setColor(colormult(0.7, self.col))
    love.graphics.rectangle("fill", self.p[1], self.p[2], self.size[1], self.size[2])
    love.graphics.setColor(self.col)
    love.graphics.rectangle("fill", self.p[1], self.p[2], self.size[1] * 0.2, self.size[2])
    
    if OUTLINES then
        love.graphics.setColor(self.line)
        love.graphics.rectangle("line", self.p[1], self.p[2], self.size[1], self.size[2])
    end
end






--Unit
Unit = Object:new{size={24,32}, col={140,160,240},drag=1, line={10,30,10}, capacity=30}
function Unit:add(o, layer)
    o = o or {}
    o.actions = ActionMap:new(o)
    o.actions:add(Action.JUMP, Jump:new())
    o.actions:add(Action.THROW, Throw:new())
    o.actions:add(Action.DIG, Dig:new())
    o.materials = {}
    table.insert(units, o)
    return Object.add(self, o, layer)
end

function Unit:update(dt)
    for k,dir in pairs(DIRS) do
        if love.keyboard.isDown(KEYS[k]) then
            if k == "LEFT" then
                self.v[1] = self.v[1] - MOVE_ACCEL * dt
            elseif k == "RIGHT" then
                self.v[1] = self.v[1] + MOVE_ACCEL * dt
            elseif k == "UP" then
                self.actions:use(Action.JUMP)
            end
        end
    end
    
    self.actions:update(dt)
    
    -- run away from danger
    local dir = P(0,0)
    for i = #explosives, 1, -1 do
        local e = explosives[i]
        
        if e.timer < 0.7 * Explosive.timer then
            local diff = Vsub(self:center(), e:center()) 
            if diff == P(0,0) then
                diff = P(1,-1)
            end
            local dd = Vdd(diff)
            local tooclose = self.size[1]/2 + e.radius --* 1.5 * (1 - e.timer/Explosive.timer)
            if dd < tooclose ^ 2 then
                 local dist = math.sqrt(dd)
                 dir = Vadd(dir, Vmult(1/dist, diff)) 
            end
        end
        if e.destroyed then
            table.remove(explosives, i)
        end
    end

    -- run toward current target
    if dir ~= P(0,0) then
        local diff = nil
        if self.target then
            local target = self.target
            diff = Vsub(target.p, self:center())
        elseif #self.materials < self.capacity then
            local maxD = math.huge
            local closest = nil
            for _, mat in ipairs(materials) do
                if mat.owner == nil then
                    local matDiff = Vsub(mat:center(), self:center())
                    local dd = Vdd(matDiff)
                    if dd < self.size[2] ^ 2 then
                        self:collect(mat)
                    elseif dd < maxD then
                        maxD = dd
                        diff = matDiff
                    end
                end
            end
        else
            diff = Vsub(P(0,0), self:center())
            if Vdd(diff) < self.size[2] then
                for _, mat in ipairs(self.materials) do
                    collect(mat.resource, 1)
                    mat.destroyed = true
                end
                self.materials = {}
            end
        end
        if diff and diff ~= P(0,0) then
            if math.abs(diff[1]) < Explosive.radius * 0.5 then
                dir = diff
                self.actions:use(Action.DIG, dir)
                if self.waitForExplosion == nil then
                --    self.waitForExplosion = self.actions:use(Action.THROW, target.p, 0)
                end
            elseif self.hitWall and self.onGround then
                if math.abs(diff[2]) > math.abs(diff[1]) then
                    -- too steep to dig.
                    dir = diff
                    if (diff[2] < 0) then
                        self.actions:use(Action.JUMP)
                    else
                        if self.waitForExplosion == nil then
                            self.waitForExplosion = self.actions:use(Action.THROW, diff, 0)
                        end
                    end
                else
                    dir = diff
                    self.actions:use(Action.DIG, dir)
                end
            else
                dir = diff
            end
        end
    end
    
    -- if moving somewhere, steer accordingly
    if dir ~= P(0,0) then
        if dir[1] > 0 then
            self.v[1] = self.v[1] + MOVE_ACCEL * dt
        elseif dir[1] < 0 then
            self.v[1] = self.v[1] - MOVE_ACCEL * dt
        end
        
        if dir[2] < 0 and math.abs(dir[2]) > math.abs(dir[1]) then
            self.actions:use(Action.JUMP)
        end
    end
    --
    
    -- if "waiting" for something, check if it has happened
    if self.waitForExplosion ~= nil then
        local expl = self.waitForExplosion
        if expl.destroyed then self.waitForExplosion = nil end
    end
    
    
    self.v[1] = math.max(-MAX_SPEED, math.min(self.v[1], MAX_SPEED))
    Object.update(self, dt)

    -- update the position of any carried materials
    for i, material in ipairs(self.materials) do
        local p = self:center()
        local n = 4
        local y = math.floor((i-1)/n)
        local x = (i-1)%n
        local sz = material.size
        material.p = Vadd(p, P((x-n/2) * sz[1], -y * sz[2]))
    end    
    
    -- place torches
    --local pos = Vadd(self:center(), P(0, -self.size[2]/2))
    local pos = self:center()
    local gx, gy = 
    local screenPos = ScreenCoordinate(pos) 
    local r = buffer:getPixel(math.floor(screenPos[1]), math.floor(screenPos[2]))
    if r < 64 then
        Torch:add{p=pos}
    end
end

-- pick up a material
function Unit:collect(material)
    if material.owner == nil and #self.materials < self.capacity then
        material.owner = self
        --material.size = Vmult(0.5, material.size)
        --table.insert(self.materials, material)
        material.destroyed = true
        collect(material.resource, 1)
    end
end

-- drop all held materials
function Unit:dropAll()
    for _, material in ipairs(self.materials) do
        material.owner = nil
        material.p = self:center()        
        local dir = math.random() * 2 * math.pi
        local spd = 20 + math.random() * 80
        material.v = Vmult(spd, Vxyof(dir))        
        material.size = Vmult(2, material.size)
    end
    self.materials = {}
end







-- little resource blocks
Material = Object:new{size={8,8}, resource=0, elastic = 0.4, drag = 1, line = {30,0,0}}
function Material:add(o, layer)
    local o = Object.add(self, o, layer)
    table.insert(materials, o)
    return o
end
-- if it is being carried, it does not collide or accelerate
function Material:update(dt)
    if self.owner == nil then
        Object.update(self, dt)
    end
end








-- Explosive
Explosive = Object:new{radius=48, timer=1.2, size={12,12}, col={160,0,0}, elastic = 0.3, drag=1, line={30,0,0}}
function Explosive:update(dt)
    self.timer = self.timer - dt
    if self.timer <= 0 then
        self.destroyed = true
        ps:explode(self.p, self.radius*2/3)
        -- destroy tiles
        for _, tile in ipairs(map:getTilesNear(self:center(), self.radius)) do
            if tile.val ~= 0 then
                map:setTile(tile.p, 0)
                -- spawn debris / gold object
                local dir = - math.random() * math.pi
                local spd = 50 + math.random() * 200
                local v = Vmult(spd, Vxyof(dir))
                Material:add({p=tile.p, v=v, resource=tile.val, col=Map.colors[tile.val]}, DEBRIS)
            end
        end
    end
    Object.update(self, dt)
end






-- jump upwards
Jump = Action:new{maxcd = 0.5}
function Jump:ready()
    return self.owner.onGround and Action.ready(self)
end

function Jump:use()
    if self:ready() then
        self.owner.v[2] = JUMP_SPEED
        Action.use(self)
    end
end



-- Throw an explosive
Throw = Action:new{maxcd = 0.5}

function Throw:use(direction, speed)
    if self:ready() then
        local pos = Vsub(self.owner:center(), Vmult(0.5, Explosive.size))
        local spd = Vscale(direction, speed)
        local expl = Explosive:add({p=pos, v=spd}, OBJECTS)
        table.insert(explosives, expl)
        Action.use(self)
        return expl
    end
end



-- Dig in some direction (left or right with slight vertical)
-- Dig a single tile or a row of tiles?
Dig = Action:new{maxcd = 0.15}
function Dig:use(direction)
    if self:ready() then
        Action.use(self)
        local u = self.owner
        -- vertical dig
        if math.abs(direction[2]) > math.abs(direction[1]) then
            local y = (direction[2] > 0) and (u.p[2] + u.size[2] + map.unit/2) or (u.p[2] - map.unit/2)
            for x = u.p[1] , u.p[1] + u.size[1], map.unit do
                local p = P(x,y)
                local tileType = map:getTile(p)
                if tileType ~= 0 then
                    map:setTile(p, 0)
                    -- spawn debris / gold object
                    local dir = Vangleof(direction) + math.pi + (math.random() - 0.5) * (math.pi / 4)
                    local spd = 20 + math.random() * 80
                    local v = Vmult(spd, Vxyof(dir))
                    Material:add({p=p, v=v, resource=tileType, col=Map.colors[tileType]}, DEBRIS)
                    break
                end
            end
        --horizontal dig
        else
            local x = (direction[1] > 0) and (u.p[1] + u.size[1] + map.unit/2) or (u.p[1] - map.unit/2)
            for y = u.p[2] + map.unit/2 , u.p[2] + u.size[2], map.unit do
                local p = P(x,y)
                local tileType = map:getTile(p)
                if tileType ~= 0 then
                    map:setTile(p, 0)
                    -- spawn debris / gold object
                    local dir = Vangleof(direction) + math.pi + (math.random() - 0.5) * (math.pi / 4)
                    local spd = 20 + math.random() * 80
                    local v = Vmult(spd, Vxyof(dir))
                    Material:add({p=p, v=v, resource=tileType, col=Map.colors[tileType]}, DEBRIS)
                    break
                end
            end
        end
    end
end