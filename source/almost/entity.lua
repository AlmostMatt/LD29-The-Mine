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
DEBRIS = 3
OBJECTS = 4
SHADOW = 5
PARTICLES = 6
FOREGROUND = 7
LIGHTS = 8
OVERLAY = 9

LAST_LAYER = OVERLAY

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

