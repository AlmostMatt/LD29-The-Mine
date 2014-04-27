
Type.ParticleSystem = Type.new()
ParticleSystem = Entity:new{t=Type.ParticleSystem}

function ParticleSystem:add(o, layer)
    o = o or {}
    o = Entity.add(self, o, layer)

    local fire = love.graphics.newParticleSystem(love.graphics.newImage("assets/circle_soft.png"), 1000)
    fire:setSizeVariation(0, 1)
    fire:setRadialAcceleration(-50)
    fire:setLinearAcceleration(0, - 100)
    fire:setDirection(0)
    fire:setParticleLifetime(1.0, 2.5)
    fire:setEmitterLifetime(-1) -- -1 is infinite
    fire:setColors(
        255,255,200,200,
        255,255,0,190,
        255,0,0,140,
        0,0,0,160,
        0,0,0,120,
        0,0,0,32,
        0,0,0,0,
        0,0,0,0)
    fire:setSizes(1.4, 1.5, 1.5, 2.0, 2.5, 2.0, 1.7, 1.2)
    fire:setSpread(2 * math.pi)
    fire:start()
    o.fire = fire
    
    local explosion = love.graphics.newParticleSystem(love.graphics.newImage("assets/circle_soft.png"), 500)
    --explosion:setColors(0,0,0,255,0,0,0,64)
    explosion:setColors(
        255,255,200,200,
        255,255,0,190,
        255,0,0,140,
        0,0,0,160,
        0,0,0,120,
        0,0,0,64,
        0,0,0,48,
        0,0,0,0)
    explosion:setSizeVariation(0, 1)
    explosion:setLinearAcceleration(0, GRAVITY)
    explosion:setDirection(1.5 * math.pi)
    explosion:setSpread(math.pi)
    explosion:setParticleLifetime(0.4, 0.8)
    explosion:setEmitterLifetime(-1) -- -1 is infinite
    explosion:setSpeed(100, 100 + 300)
    explosion:setRadialAcceleration(-100)
    explosion:start()
    o.explosion = explosion
    
    return o
end

function ParticleSystem:update(dt)
    self.fire:update(dt)
    self.explosion:update(dt)
    
    if self.fire:getCount() >= 999 then
        print("TOO MUCH FIRE")
    end
end

function ParticleSystem:burn(pos, size)
    -- multiply values by size/16 or size/32
    local fire = self.fire
    local s = size/32
    fire:setPosition(pos[1], pos[2])
    fire:setSpeed(10, 10 + 2 * size)
    fire:setSizes(s * 1.4, s * 1.5, s * 1.5, s * 2.0, s * 2.5, s * 2.0, s * 1.7, s * 1.2)
    fire:emit(1)
end

function ParticleSystem:explode(pos, size)
    local explosion = self.explosion
    explosion:setPosition(pos[1], pos[2])
    explosion:setSizes (size/32 )
    explosion:setSizeVariation(0, 1)
    explosion:emit(20)
end

function ParticleSystem:draw()
    love.graphics.draw(self.fire, 0, 0)--, 0, 1, 1, 0, 0, 1, 1)
    love.graphics.draw(self.explosion, 0, 0)--, 0, 1, 1, 0, 0, 1, 1)
end