require("almost/entity")

FRICTION = 400
GRAVITY = 500

particles = {}

Type.Particle = Type.new()
Particle = Entity:new{t=Type.Particle, timer = 1, r = 5,col={30,30,30},line={0,0,0},friction=0.5,gravity=1}
StaticParticle = Particle:new{}

bloodcolor = {180,161,147}
bloodcolor = {0,0,0}
bloodcolor = {128,0,0}

Blood = Particle:new{friction=0.4,col=bloodcolor,line={64,0,0}}

firecolors = {
	[1.5]	= {255,255,255,200},--white
	[1.4]	={255,255,0,190},--yellow
	[1.3]	= {255,0,0,140},--red
	[1.2]	= {0,0,0,100},--black
	[0.6]	= {0,0,0,64},--black
	[0.0]	= {0,0,0,48},
}

Fire = Particle:new{elastic=0, gravity=-0.1,friction = 0.07, cols = firecolors, line=false}
Smoke = Particle:new{gravity=0}

function debris(p,z)
    local size = math.random(4,12)
	local angle = math.random()*6.3
	local angle2 = math.random()*3.14
	local speed = math.random(300,400)
    --vz
    local v = P(math.cos(angle)*math.cos(angle2),math.sin(angle)*math.cos(angle2))
    local vz = math.sin(angle2)*speed
    Particle:add({p=p,z=z,v=Vmult(speed,v),vz = vz,r=size,timer=1+1*math.random(),elastic = 0.7,friction=0.5})
end

function burn(point,z,size)
    --z = z + 10
	local angle = math.random()*6.3
	local angle2 = math.random()*3.14
	local speed = 10+math.random()*size*2
    --vz
    local v = P(math.cos(angle)*math.cos(angle2),math.sin(angle)*math.cos(angle2))
    local vz = math.sin(angle2)*speed*1.5
    Fire:add({p=point,z=z,v=Vmult(speed,v),vz = vz,r=size,timer=1.6})
end

function blood(p,z)
    z = z + 10
    local size = math.random(2,6)
	local angle = math.random()*6.3
	local angle2 = math.random()*3.14
	local speed = 120+math.random(50,100)*2/size
    --vz
    local v = P(math.cos(angle)*math.cos(angle2),math.sin(angle)*math.cos(angle2))
    local vz = math.sin(angle2)*speed*0.75
    Blood:add({p=p,z=z,v=Vmult(speed,v),vz = vz,r=size,timer=1+1*math.random()})
end


function Blood:update(dt)
    Particle.update(self,dt)
    if self.onground then --or on collision
        if frame%3 == 1 then
            splat(self.p,self.z,self.r)
        end
        self.r = self.r-dt*10
    end
    if self.r < 1 then
        self.timer = 0
    end
end

function splat(p,z,size)
    StaticParticle:add({p=p,z=z,r=size,timer = 1+size*0.5+0.5*math.random(),col=bloodcolor,line={64,0,0}})--,line=false}))
end

function StaticParticle:update(dt)
    self.timer = self.timer-dt
end

function Particle:update(dt)
    self.timer = self.timer-dt
    if self.timer <= 0 then
        self.destroyed = true
    end
    --whether or not it is affected by gravity or wind
    
    local groundz = 0
    self.onground = self.z <= groundz
    if self.onground then
        self.vz = math.max(0,self.vz)
        if self.z < groundz then
            self.z = math.min(groundz, self.z + CLIMBSPEED*dt)
        end
    else
        self.vz = self.vz - GRAVITY * dt * self.gravity
    end
    --friction
    local d = Vmagn(self.v)
    self.v = Vscale(self.v,math.max(0,d-FRICTION*self.friction*dt))
    self.p = Vadd(self.p,Vmult(dt,self.v))
    --change colour over time
end


function Particle:draw(a)
    local p = ortho(self.p,self.z+self.r)
    local a = a or 255
    if self.timer < 0.5 then
        a = a * self.timer / 0.5
    end
    local col
    if self.cols then
        local minkey,maxkey = nil,nil
        for k,v in pairs(self.cols) do
            if k < self.timer and ((not minkey) or minkey < k) then
                minkey = k
            end
            if k >= self.timer and ((not maxkey) or maxkey > k) then
                maxkey = k
            end
        end
        if minkey and maxkey then
            local diff = maxkey-minkey
            local s = (self.timer - minkey)/diff
            local col1,col2 = self.cols[minkey],self.cols[maxkey]
            col = coloradd(colormult(1-s,col1), colormult(s,col2))
            col[4] = (1-s)*col1[4] + s*col2[4] --alpha isnt mixed normally
        elseif minkey or maxkey then
            col = table.copy(self.cols[(minkey or maxkey)])
        else
            col = table.copy(self.col)
        end
        --need fix for not in range
    else
        col = table.copy(self.col)
    end
    col[4] = (col[4] or 255) * math.max(0,a/255)
    love.graphics.setColor(col)
    love.graphics.circle("fill",p[1],p[2],self.r)
    if self.line and OUTLINES then
        local line = table.copy(self.line)
        line[4] = (line[4] or 255) * math.max(0,a/255)
        love.graphics.setColor(line)
        love.graphics.circle("line",p[1],p[2],self.r)
    end
end


-- instead of drawing individual particles as entities , have particles 
Type.ParticleSystem = Type.new()
ParticleSystem = Entity:new{t=Type.ParticleSystem}
function ParticleSystem:add(o)
    o = o or {}
    o.particles = {}
    return Entity.add(self, o)
end

function ParticleSystem:update(dt)

end

--[[
function updateparticles(dt)
	for i = #particles,1,-1 do
		local p = particles[i]
        p:move(dt)
		
		if p.timer <= 0 then
            table.remove(particles,i)
        end
	end
end

function drawparticles()
	for i,p in ipairs(particles) do
		local n = 1-p.t/p.ti
		
		local s = p.s*(0.4+n*0.6)--^2 + 2*math.max(0,p.s*(n-0.3))
		
		local r,g,b,a = 255,255,255,200
		if n>0.25 then r=math.max(0,255*(0.3-n)/0.05) end
		if n>0.15 then g=math.max(0,255*(0.25-n)/0.1) end
		if n>0.0 then b=math.max(0,255*(0.15-n)/0.15) end
		if n>0.3 then a=math.max(0,200* ((1-n)/0.7)^2 ) end
		love.graphics.setColor(r,g,b,a)
        local point = ortho(p.p,p.z)
		love.graphics.circle('fill',point[1],point[2],s)
	end
end
]]