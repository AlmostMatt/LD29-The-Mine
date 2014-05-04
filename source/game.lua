require("almost/entity")
require("objects")
require("particlesystem")
require("map")
require("pathfind")
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
        local mx, my = love.mouse.getPosition()
        local dx,dy = mx - width, my - height
        love.window.setMode(s.w,s.h)
        love.mouse.setPosition(s.w + dx, s.h + dy)
        width = s.w
        height = s.h
        if love.graphics.isSupported("npot") then
            buffer = love.graphics.newCanvas(width, height)
        else
            -- make the canvas a power of 2
            local bwidth = 2^math.ceil(math.log(width)/math.log(2))
            local bheight = 2^math.ceil(math.log(height)/math.log(2))
            buffer = love.graphics.newCanvas(bwidth, bheight)
        end
        -- initially white so that the player doesnt spawn a new torch whenever you resize the screen
        buffer:clear(255, 255, 255, 255)
        
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
    markedSomething = false
    clearedMarks = false
    builtSomething = false
    scrolled = 0
    
    setSize(MEDIUM)
    OUTLINES = true
    gameUI()
    
    --player = Player(P(0,0),50)
    
    frame = 0
    
    InitEntities()
    InitObjects()
    
    ps = ParticleSystem:add({}, PARTICLES)
    map = Map:add({}, TILES)
    
    --love.mouse.setGrabbed(true)
    camera = P(0,140)
    Game:update(1/30) --force an update before any draw function is possible.
end

function Game:update(dt)
    if not PAUSED then
        dt = math.min(dt,1/30)
        frame = frame + 1
        mx,my = love.mouse.getPosition()
        screenMouse = P(mx, my)
        mouse = GameCoordinate(screenMouse)
            
        -- move camera
        local border = 10
        local camspeed = 400
        local prox = math.max(border - mx, border - my, mx - (width - border - 1), my - (height - border - 1))
        
        if prox > 0 and prox <= border then
            -- mouse position is off the screen during resize
            local dir = unitV(Vsub(screenMouse, screenCenter))
            scrolled = scrolled + camspeed * dt * prox / border
            camera = Vadd(camera, Vmult(camspeed * dt * prox / border, dir))
        end
        
        screenMin = GameCoordinate(P(0,0))
        screenMax = GameCoordinate(P(width,height))

        -- update objects
        for i = #entities,1,-1 do
            local o = entities[i]
            o:update(dt)
            
            if o.destroyed then
                table.remove(entities,i)
            end
        end
        
        
        --[[
        if newTiles ~= 0 then
            print("Smooth " .. newTiles .. " new tiles in  " .. smoothTime .." s")
            print("Flood " .. newTiles .. " new tiles in  " .. floodTime .." s")
        end
        if mergedTiles ~= 0 then
            print("Flood merge " .. mergedTiles .. " existing tiles in " .. floodTime2 .. "s")
        end
        ]]
        --print("time spent on pathing: " .. pathingTime .. "s")
        pathingTime = 0
        --[[
        newTiles = 0
        mergedTiles = 0
        smoothTime = 0
        floodTime = 0
        floodTime2 = 0
        ]]
    end
end

pathingTime = 0
mergedTiles = 0
newTiles = 0
smoothTime = 0
floodTime = 0
floodTime2 = 0

function ScreenCoordinate(pos)
    return Vadd(Vsub(pos, camera), screenCenter)
end
function GameCoordinate(pos)
    return Vsub(Vadd(pos, camera), screenCenter)
end
function onScreen(p)
    return p[1] > screenMin[1] and p[2] > screenMin[2] and p[1] < screenMax[1] and p[2] < screenMax[2]
end



function Canvas:draw()
    -- background fill
    love.graphics.setColor(200,200,255)
    love.graphics.rectangle("fill", 0,0,width,height)
    
    love.graphics.push()
    local p = camera
    love.graphics.translate(math.floor(width/2-p[1]),math.floor(height/2-p[2]))
    
    -- draw a light mask to the canvas)
    -- there is light around each unit
    buffer:clear(0, 0, 0, 255)
    love.graphics.setCanvas(buffer)
    local w, h = softCircle:getWidth(), softCircle:getHeight()
    local ox, oy = w/2, h/2
    local time = love.timer.getTime()
    for i,u in ipairs(lights) do
        local r = Torch.radius + 4 * math.sin(math.pi * (time + i))
        local scale = 2*r/w
        love.graphics.setColor(255,255,255,Torch.alpha1)
        love.graphics.draw(softCircle, u.p[1], u.p[2], 0, scale, scale, ox, oy)
        love.graphics.setColor(255,255,255,Torch.alpha2)
        love.graphics.draw(softCircle, u.p[1], u.p[2], 0, scale * Torch.size2, scale * Torch.size2, ox, oy)
    end
    love.graphics.setCanvas()

    for layer = 0, LAST_LAYER do
        for i = #drawables[layer],1,-1 do
            local o = drawables[layer][i]
            o:draw()
            
            if o.destroyed then
                table.remove(drawables[layer],i)
            end
        end
        if layer == SHADOW and not DEBUG_NO_SHADOWS then
            -- apply the shadow mask
            love.graphics.pop()    
            love.graphics.setColor(255,255,255,255)
            love.graphics.setBlendMode("multiplicative")
            love.graphics.draw(buffer, 0, 0)    
            love.graphics.setBlendMode("alpha")
            love.graphics.push()
            love.graphics.translate(width/2-p[1],height/2-p[2])
        elseif layer == MAP_OVERLAY then
            map:drawOverlay()
            if DEBUG_PATHING then
                for _, u in ipairs(units) do
                --map:raycastPoints(u:center(), mouse)
                    map:findPath(u, mouse)
                end
            end
        end
    end
    
    love.graphics.pop()
    if PAUSED then
        love.graphics.setColor(255,255,255, 128)
        love.graphics.rectangle("fill", 0,0,width,height)
    end
end

function Canvas:mousepress(x,y, button)
    if button == "r" then
        clearTargets()
        return true
    elseif  button == "l" then
        local gx, gy = map:gridCoordinate(mouse)
        return markTarget(mouse)
    end
    return false
end

function Game:mouserelease(x,y, button)
end

function Game:keypress(key, isrepeat)
    if key == KEYS.JUMP and not isrepeat then
    end
end

function Game:keyrelease(key)

end