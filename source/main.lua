function love.load()
    width = love.graphics.getWidth( )
    height = love.graphics.getHeight()
    
    require("almost/vmath")
    require("almost/geom")
    require("almost/files")
    require("almost/ui")
    require("almost/state")
	
    require("game")
    
    love.graphics.setBackgroundColor(255,255,255)
    
    loadstate(Game)
    --loadstate(Menu)

    timediff = 0
    timestep = 1/30
end

function love.draw()
    activestate:draw()
    love.graphics.setColor(0,0,0)
    local fps = "FPS: " .. love.timer.getFPS()
    love.graphics.print(fps,20,20)
end

function love.update(dt)
    timediff = timediff + dt
    while timediff > timestep do
        timediff = timediff - timestep
        activestate:update(timestep)
    end
end

function love.mousepressed(x,y, button)
    activestate:mousepress(x,y,button)
    for i,layer in ipairs(activestate.layers) do
        if isui(layer) then
            clickbox(layer.ui)
        end
    end
end

function love.mousereleased(x,y, button)
    activestate:mouserelease(x,y,button)
end

function love.keypressed(key, isrepeat)
    if key == "r" then
        love.load()
    elseif key == "q" or key == "escape" then
        love.event.quit()
    else
        activestate:keypress(key, isrepeat)
    end
end

function love.keyreleased(key)
    activestate:keyrelease(key)
end

function loadstate(s)
    activestate = s
    s:load()
end

function resumestate(s)
    activestate = s
    if not s.loaded then
        s:load()
        s.loaded = true
    end
end