require("almost/entity")
require("particles")
require("particlesystem")
require("map")

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

camera = P(0,0)

SIZE = nil
function setSize(size)
    local s = WINDOW_SIZES[size]
    SIZE = s.size
    if s.w ~= width or s.h ~= height then
        love.window.setMode(s.w,s.h)
        width = s.w
        height = s.h
        gameUI()
    end
end

function gameUI()
    local ui = BoxRel(width,height)
    local b = BoxV(150,height-40,false)
    b.alignV = ALIGNV.BOTTOM
    ui:add(b,REL.E)
    
    local b2
    b2 = BoxV(120,30)
    b2.label = "Toggle Lines"
    b2.onclick = function() OUTLINES = not OUTLINES end
    b:add(b2)
    if SIZE ~= SMALL then
        b2 = BoxV(120,30)
        b2.label = "Small"
        b2.onclick = function() setSize(SMALL) end
        b:add(b2)
    end
    if SIZE ~= MEDIUM then
        b2 = BoxV(120,30)
        b2.label = "Medium"
        b2.onclick = function() setSize(MEDIUM) end
        b:add(b2)
    end
    if SIZE ~= LARGE then
        b2 = BoxV(120,30)
        b2.label = "Large"
        b2.onclick = function() setSize(LARGE) end
        b:add(b2)
    end
    
    if UI then
        UI.ui = ui
    else
        UI = UILayer(ui)
        Game:addlayer(UI)
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
    ps = ParticleSystem:add({}, PARTICLES)
    map = Map:add({}, TILES)
    
    for n =0,2 do
        o = Unit:add({p=P(-200 + 140 * n, - 50)}, UNITS)
    end
    
    Game:update(1/30) --force an update before any draw function is possible.
end

function Game:update(dt)
	dt = math.min(dt,1/30)
    frame = frame + 1
    mx,my = love.mouse.getPosition()
    mouse = P(mx + camera[1] - width/2, my + camera[2] - height/2)
        
	for i = #entities,1,-1 do
		local o = entities[i]
        o:update(dt)
		
		if o.destroyed then
            table.remove(entities,i)
        end
	end
    
    -- sample input
    if love.mouse.isDown("l") then
        local size = 8
        map:setTile(mouse, 0)
        --ps:burn(mouse, size)
    end
    if love.mouse.isDown("r") then
        map:setTile(mouse, map.DIRT)
        --blood(omouse, 0)
        --ps:setColors(255,255,255,255,0,128,128,64,0,0,255,0)
        --ps:emit(1)
    end

    --player.v = P(0,0)
    for k,dir in pairs(DIRS) do
        if love.keyboard.isDown(KEYS[k]) then
            moved[k] = true
        end
    end
end

function Canvas:draw()
    -- background fill
    love.graphics.setColor(200,200,255)
    love.graphics.rectangle("fill", 0,0,width,height)
    
    love.graphics.push()
    camera = P(0,0)
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

    love.graphics.pop()
    
    -- the following should be generalized and moved to the UI
    local tl = P (10,10)
    local br = P(width-10,height-10)
    local wh = Vsub(br,tl)

    love.graphics.setColor(128,0,0,64)
    love.graphics.rectangle("line",tl[1],tl[2],wh[1],wh[2])

    love.graphics.setColor(0,0,0)
    love.graphics.print("Entities: " .. #entities,20,35)
    love.graphics.print("Drawables: " .. #drawables,20,50)

    --[[
    local c = 0
    for k,v in pairs(moved) do
        if v then c = c + 1 end
    end
    if c < 2 then
        notify("W A S D to move",y)
        y = y + h
    end
    if not jumped then
        notify("Space to jump",y)
        y = y + h
    end
    if not clicked then
        notify("Click on stuff",y)
        y = y + h
    end
    ]]
end


function Game:mousepress(x,y, button)
    if button == "r" then
    elseif  button == "l" then
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

function notify(msg,y)
    local w,h = 200,24
    local x = width - w - 15
    love.graphics.setColor(255,255,255,128)
    love.graphics.rectangle("fill",x,y,w,h)
    love.graphics.setColor(0,0,0,196)
    love.graphics.rectangle("line",x,y,w,h)
    love.graphics.printf(msg,x,y+5,w,"center")
end