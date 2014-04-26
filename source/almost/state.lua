--loaded property and reset layers to {} on reload
State = {}

function State:new(s)
    s = s or {}
    s.layers = {}
    setmetatable(s,self)
    self.__index = self
    return s
end

function State:load()

end

function State:update(dt)

end

function State:mousepress(button,x,y)

end

function State:mouserelease(button,x,y)

end

function State:keypress(key)

end

function State:keyrelease(key)

end


function State:addlayer(layer)
    table.insert(self.layers,layer)
end

function State:draw()
    for i,layer in ipairs(self.layers) do
        layer:draw()
    end
end

--default layer object

Layer = {}

function Layer:new(l)
    l = l or {}
    setmetatable(l,self)
    self.__index = self
    return l
end

function Layer:draw()

end

function UILayer(root)
    local l = Layer:new({ui = root})    
    function l:draw()
        hittest(l.ui,love.mouse.getX(),love.mouse.getY())
        drawui(l.ui)
    end
    return l
end

--give uilayer a default mousepress logic