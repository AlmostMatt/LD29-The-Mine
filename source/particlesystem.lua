
Type.ParticleSystem = Type.new()
ParticleSystem = Entity:new{t=Type.ParticleSystem}

function ParticleSystem:add(o, layer)
    o = o or {}
    o = Entity.add(self, o, layer)
    
    local fire = love.graphics.newParticleSystem(love.graphics.newImage("assets/circle_soft.png"), 1000)
    fire:setColors(255,255,255,255,0,128,128,64,0,0,255,0)
    fire:setSizeVariation(0, 1)
    fire:setRadialAcceleration(-50)
    fire:setDirection(0)
    fire:setParticleLifetime(1.0, 2.5)
    fire:setEmitterLifetime(-1) -- -1 is infinite
    fire:setColors(
        255,255,200,200,
        255,255,0,190,
        255,0,0,140,
        0,0,0,160,
        0,0,0,120,
        0,0,0,64,
        0,0,0,48,
        0,0,0,0)
    fire:setSizes(1.4, 1.5, 1.5, 2.0, 2.5, 2.0, 1.7, 1.2)
    fire:setSpread(2 * math.pi)
    fire:start()
    o.fire = fire
    return o
end

function ParticleSystem:update(dt)
    self.fire:update(dt)
end

function ParticleSystem:burn(pos, size)
    -- multiply values by size/16 or size/32
    local fire = self.fire
    fire:setPosition(pos[1], pos[2])
    fire:setSpeed(10, 10 + 2 * size)
    fire:setSizes(1.4, 1.5, 1.5, 2.0, 2.5, 2.0, 1.7, 1.2)
    fire:emit(1)
end

function ParticleSystem:draw()
    love.graphics.draw(self.fire, 0, 0)--, 0, 1, 1, 0, 0, 1, 1)
end