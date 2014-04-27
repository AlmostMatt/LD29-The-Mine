require("almost/entity")
require("objects")
require("particlesystem")
require("map")
require("hud")

Game = State:new()
Canvas = Layer:new()
Game:addlayer(Canvas)

SMALL = 0
MEDIUM = 1
LARGE = 2

WINDOW_SIZES = {
    [SMALL] = {
        w=800,
        h=600,
        size=SMALL
        },
    [MEDIUM]={
        w = 1024,
        h = 768,
        size=MEDIUM
        },
    [LARGE]={
        w = 1200,
        h = 800,
        size=LARGE
    }
}

softCircle = love.graphics.newImage("assets/circle_soft_edges.png")

SIZE = nil
function setSize(size)
    local s = WINDOW_SIZES[size]
    SIZE = s.size
    if s.w ~= width or s.h ~= height then
        love.window.setMode(s.w,s.h)
        width = s.w
        height = s.h
        buffer = love.graphics.newCanvas(width, height)
        screenCenter = P(width/2, height/2)
        gameUI()
    end
end

function Game:load()
    KEYS = {JUMP=" ",DASH="x",LEFT="a",RIGHT="d",UP="w",DOWN="s",ATTACK="c"}
    DIRS = {UP=P(0,1), LEFT=P(-1,0), RIGHT=P(1,0), DOWN=P(0,-1)}

    --check if the player knows his controls
    moved = {}
    for k,v in pairs(DIRS) do
        moved[k] = false
    end
    jumped = false
    clicked = false

    setSize(LARGE)
    OUTLINES = true
    gameUI()
    
    --player = Player(P(0,0),50)
    
    frame = 0
    
    InitEntities()
    InitObjects()
    
    ps = ParticleSystem:add({}, PARTICLES)
    map = Map:add({}, TILES)
    
    love.mouse.setGrabbed(true)
    camera = P(0,0)
    Game:update(1/30) --force an update before any draw function is possible.
end

function Game:update(dt)
	dt = math.min(dt,1/30)
    frame = frame + 1
    mx,my = love.mouse.getPosition()
    screenMouse = P(mx, my)
    mouse = GameCoordinate(screenMouse)
        
	for i = #entities,1,-1 do
		local o = entities[i]
        o:update(dt)
		
		if o.destroyed then
            table.remove(entities,i)
        end
	end
    
    for k,dir in pairs(DIRS) do
        if love.keyboard.isDown(KEYS[k]) then
            moved[k] = true
        end
    end
    
    local border = 10
    local camspeed = 400
    local prox = math.max(border - mx, border - my, mx - (width - border - 1), my - (height - border - 1))
    if prox > 0 then
        local dir = unitV(Vsub(screenMouse, screenCenter))
        camera = Vadd(camera, Vmult(camspeed * dt * prox / border, dir))
    end
end


function ScreenCoordinate(pos)
    return Vadd(Vsub(pos, camera), screenCenter)
end
function GameCoordinate(pos)
    return Vsub(Vadd(pos, camera), screenCenter)
end

function Canvas:draw()
    -- background fill
    love.graphics.setColor(200,200,255)
    love.graphics.rectangle("fill", 0,0,width,height)
    
    love.graphics.push()
    local p = camera
    love.graphics.translate(width/2-p[1],height/2-p[2])

    for layer = 0, LAST_LAYER do
        for i = #drawables[layer],1,-1 do
            local o = drawables[layer][i]
            o:draw()
            
            if o.destroyed then
                table.remove(drawables[layer],i)
            end
        end
    end
    
    -- draw a light mask to the canvas)
    -- there is light around each unit
    buffer:clear(16, 16, 16, 255)
    love.graphics.setCanvas(buffer)
    love.graphics.setColor(255,255,255,128)
    local w, h = softCircle:getWidth(), softCircle:getHeight()
    local ox, oy = w/2, h/2
    local time = love.timer.getTime()
    for i,u in ipairs(lights) do
        local r = 150 + 4 * math.sin(math.pi * (time + i))
        local scale = 2*r/w
        love.graphics.draw(softCircle, u.p[1], u.p[2], 0, scale, scale, ox, oy)
    end
    love.graphics.pop()    
    love.graphics.setCanvas()
    love.graphics.setColor(255,255,255,255)
    love.graphics.setBlendMode("multiplicative")
    love.graphics.draw(buffer, 0, 0)    
    love.graphics.setBlendMode("alpha")
end

function Game:mousepress(x,y, button, isrepeat)
    if button == "r" and not isrepeat then
        clicked = true
        markTarget(mouse)
    elseif  button == "l" and not isrepeat then
    end
end

function Game:mouserelease(x,y, button)
end

function Game:keypress(key, isrepeat)
    if key == KEYS.JUMP and not isrepeat then
    end
end

function Game:keyrelease(key)

end