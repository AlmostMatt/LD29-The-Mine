-- a set of type identifiers
-- each type has a unique value, which is one more than the previous value
Type = {}
function Type.new()
    return #Type
end

Type.Drawable = Type.new()
Drawable = {t=Type.Drawable, destroyed=false}

-- layers
BKG = 0
TILES = 1
UNITS = 2
PARTICLES = 3
FOREGROUND = 4
OVERLAY = 5

LAST_LAYER = 5

function InitEntities()
    drawables = {}
    entities = {}
    for layer = 0, LAST_LAYER do
        drawables[layer] = {}
    end
end

function Drawable:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Drawable:add(o, layer)
    o = Drawable.new(self, o)
    table.insert(drawables[layer], o)
    return o
end

function Drawable:draw(a)
end

Type.Entity = Type.new()
Entity = Drawable:new{t=Type.Entity, x = 0, y = 0}
function Entity:add(o, layer)
    o = Drawable.add(self, o, layer)
    table.insert(entities, o)
    return o
end

function Entity:update(dt)
end


MAX_SPEED = 400
GRAVITY = 600
TERMINAL_V = 1200


Type.Unit = Type.new()
Unit = Entity:new{t=Type.Unit, onGround = fals,  col={140,160,240},line={10,30,10}}
function Unit:add(o, layer)
    o = o or {}
    o.p = o.p or P(0,0)
    o.v = P(0, 0)
    o.size = o.size or P(32, 44)
    return Entity.add(self, o, layer)
end

function Unit:update(dt)
    self.v[1] = 0
    for k,dir in pairs(DIRS) do
        if love.keyboard.isDown(KEYS[k]) then
            if k == "LEFT" then
                self.v[1] = - MAX_SPEED
            elseif k == "RIGHT" then
                self.v[1] = MAX_SPEED
            end
        end
    end

    self.v[2] = self.v[2] + GRAVITY * dt
    self.v[1] = math.max(-MAX_SPEED, math.min(self.v[1], MAX_SPEED))
    self.v[2] = math.min(self.v[2], TERMINAL_V)
    
    self.p, self.v = map:collide(self.p, self.size, self.v, dt)
    self.onGround = false
    --self:collisionCheck(map)
    --self:collisionCheck(map)
end

function Unit:collisionCheck(map)
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

function Unit:draw(a)
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