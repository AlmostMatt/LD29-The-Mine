--layouts, buttons, scrolling, pictures, dynamic content (level previews) , titles, settings (sliders), game states and menu screen navigation

--button styles (bordered, padded, grow on hover, fade on focus out)

FILL="fill"

LAYOUT = {
    H = 1,
    V = 2,
    REL = 3
}

ALIGNH = {
    LEFT = 1,
    CENTER = 2,
    RIGHT = 3
}
ALIGNV = {
    TOP = 1,
    CENTER = 2,
    BOTTOM = 3
}
REL = { -- options for a relative layout.
    N = "N",
    E = "E",
    W = "W",
    S = "S",
    C = "C"
}

--takes a style option (linear, relative, grid, absolute) and a list of content objects
--trying lua object oriented logic
Container = {x=0,y=0,w=FILL,h=FILL,layout=LAYOUT.V, alignV = ALIGNV.CENTER, alignH = ALIGNH.CENTER, padV = 5, padH = 5, spacing = 5}
function Container:new (c)
  c = c or {}
  setmetatable(c, self)
  c.children = {}
  self.__index = self
  return c
end

function Container:screenPosition()
    local px, py = 0, 0
    if self.parent then
        px, py = self.parent:screenPosition()
    end
    return self.x + px, self.y + py
end

function Container:add (c, r)
  table.insert(self.children,c)
  c.parent = self
  if self.layout == LAYOUT.V then
    if self.alignH == ALIGNH.LEFT then
        c.x = self.padH
    elseif self.alignH == ALIGNH.CENTER then
        c.x = self.w/2 - c.w/2
    elseif self.alignH == ALIGNH.RIGHT then
        c.x = self.w - self.padH - c.w
    end
    if #self.children == 1 then
        if self.alignV == ALIGNV.TOP then
            c.y = self.padV
        elseif self.alignV == ALIGNV.CENTER then
            c.y = self.h/2 - c.h/2
        elseif self.alignV == ALIGNV.BOTTOM then
            c.y = self.h - self.padV - c.h
        end
    else
        local child = self.children[#self.children-1]
        c.y = child.y + child.h + self.spacing
        for i,ch in ipairs(self.children) do
            if self.alignV == ALIGNV.CENTER then
                ch.y = ch.y - (c.h + self.spacing)/2 
            elseif self.alignV == ALIGNV.BOTTOM then
                ch.y = ch.y - (c.h + self.spacing)
            end
        end
    end
  elseif self.layout == LAYOUT.H then
    if self.alignV == ALIGNV.TOP then
        c.y = self.padV
    elseif self.alignV == ALIGNV.CENTER then
        c.y = self.h/2 - c.h/2
    elseif self.alignH == ALIGNH.RIGHT then
        c.y = self.h - self.padV - c.h
    end
    if #self.children == 1 then
        if self.alignH == ALIGNH.LEFT then
            c.x = self.padH
        elseif self.alignH == ALIGNH.CENTER then
            c.x = self.w/2 - c.w/2
        elseif self.alignH == ALIGNH.RIGHT then
            c.x = self.w - self.padH - c.w
        end
    else
        local child = self.children[#self.children-1]
        c.x = child.x + child.w + self.spacing
        for i,ch in ipairs(self.children) do
            if self.alignH == ALIGNH.CENTER then
                ch.x = ch.x - (c.w + self.spacing)/2 
            elseif self.alignH == ALIGNH.RIGHT then
                ch.x = ch.x - (c.w + self.spacing)
            end
        end
    end
  elseif self.layout == LAYOUT.REL then
    if r == REL.N then
        c.x = (self.w-c.w) / 2
        c.y = self.padV
    elseif r == REL.S then
        c.x = (self.w-c.w) / 2
        c.y = self.h - self.padV - c.h
    elseif r == REL.E then
        c.x = self.w-c.w-self.padH
        c.y = (self.h - c.h)/2
    elseif r == REL.W then
        c.x = self.padH
        c.y = (self.h - c.h)/2
    elseif r == REL.C then
        c.x = (self.w-c.w) / 2
        c.y = (self.h - c.h)/2
    end
  end
end

function BoxRel(w,h,visible)
    if visible == nil then
        visible = true
    end
    return Container:new({w=w,h=h,layout=LAYOUT.REL,visible=visible})
end

function BoxV(w,h,visible)
    if visible == nil then
        visible = true
    end
    return Container:new({w=w,h=h,layout = LAYOUT.V,visible=visible})
end
function BoxH(w,h,visible)
    if visible == nil then
        visible = true
    end
    return Container:new({w=w,h=h,layout = LAYOUT.H,visible=visible})
end

function text()

end

function button()

end

function drawbox(box,px,py)
--    love.graphics.setLineWidth(1)
    if (box.visible) then
        local a1 = 192
        local a2 = 255
        if box.hover then
            a1 = 255
            a2 = 255
        end
        love.graphics.setColor(225,225,225,a1)
        love.graphics.rectangle("fill",px,py,box.w,box.h)
        love.graphics.setColor(0,0,0,a2)
        love.graphics.rectangle("line",px,py,box.w,box.h)
        if box.label then
            love.graphics.setColor(0,0,0,196)
            love.graphics.printf(box.label,px,py+(box.h-15)/2,box.w,"center")
        end
    end
    for i,b in ipairs(box.children) do
        drawbox(b,px+b.x,py+b.y)
    end
end

function drawui(root)
    drawbox(root, 0, 0)
end

-- return whether or not this box is clickable
function clickbox(box)
    local clicked = false
    if box.hover then 
        if box.visible then
            clicked = true
        end
        if box.onclick then
            box.onclick()
        end
    end
    for i,h in ipairs(box.children) do
        clicked = clicked or clickbox(h)
    end
    return clicked
end

function hittest(box,mx,my)
    local childhover = false
    for i,b in ipairs(box.children) do
        local h = hittest(b,mx-b.x,my-b.y)
        childhover = childhover or h
    end
    if (not childhover) and 0<mx and 0<my and mx < box.w and my < box.h then
        box.hover = true
    else
        box.hover = false
    end
    return childhover or box.hover
end

function isui(layer)
    return layer.ui
end