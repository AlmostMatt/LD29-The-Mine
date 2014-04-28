-- in this game the player is not an object
-- but it has a lot of state info

function numEntries(t)
    local count = 0
    for k,v in pairs(t) do
        count = count + 1
    end
    return count
end

resourceIcons = {}
inventory = {}

function collect(resource, qty)
    if resource == Map.DARK_ROCK then
        resource = Map.ROCK
    end
    inventory[resource] = (inventory[resource] or 0) + (qty or 1)
end

function consume(resource, qty)
    local amount = inventory[resource]
    if amount and amount >= qty then
        inventory[resource] = amount - qty
        return true
    end
    return false
end

function gameUI()
    local ui = BoxRel(width,height, false)
    screenSizes = BoxV(150,height-40,false)
    screenSizes.alignV = ALIGNV.BOTTOM
    ui:add(screenSizes,REL.E)
    
    local b2
    --b2 = BoxV(120,30)
    --b2.label = "Toggle Lines"
    --b2.onclick = function() OUTLINES = not OUTLINES end
    --b:add(b2)
    if SIZE ~= SMALL then
        b2 = BoxV(120,30)
        b2.label = "Small"
        b2.onclick = function() setSize(SMALL) end
        screenSizes:add(b2)
    end
    if SIZE ~= MEDIUM then
        b2 = BoxV(120,30)
        b2.label = "Medium"
        b2.onclick = function() setSize(MEDIUM) end
        screenSizes:add(b2)
    end
    if SIZE ~= LARGE then
        b2 = BoxV(120,30)
        b2.label = "Large"
        b2.onclick = function() setSize(LARGE) end
        screenSizes:add(b2)
    end
    


    
    -- PURCHASES
    local b3 = BoxV(170, height-40, false)

    buildUnit = BoxV(140,70)
    buildUnit.onclick = purchaseUnit
    b3:add(buildUnit)

    digFaster = BoxV(140,70)
    digFaster.onclick = purchaseDigFaster
    b3:add(digFaster)

    betterTorches = BoxV(140,70)
    betterTorches.onclick = purchaseBetterTorches
    b3:add(betterTorches)
    
    ui:add(b3,REL.E)


    if UI then
        UI.ui = ui
    else
        UI = UILayer(ui)
        Game:addlayer(UI)
        
        Game:addlayer(HUD)
    end
end




-- purchase functions
unitCost = {[Map.GOLD]=2, [Map.SILVER]=2}
digFasterCost = {[Map.DIRT]=15, [Map.ROCK]=20}
betterTorchesCost = {[Map.SAND]=25, [Map.ROCK]=10}

function purchaseDigFaster()
    -- check balance
    for res, qty in pairs(digFasterCost) do
        if (inventory[res] or 0) < qty then
            return
        end
    end
    -- descrease balance
    for res, qty in pairs(digFasterCost) do
        inventory[res] = (inventory[res] or 0) - qty
        digFasterCost[res] = qty * 2
    end
    builtSomething = true
    DIG_SPEED = DIG_SPEED + 1
end

function purchaseBetterTorches()
    -- check balance
    for res, qty in pairs(betterTorchesCost) do
        if (inventory[res] or 0) < qty then
            return
        end
    end
    -- descrease balance
    for res, qty in pairs(betterTorchesCost) do
        inventory[res] = (inventory[res] or 0) - qty
        betterTorchesCost[res] = math.floor(qty * 1.3)
    end
    builtSomething = true
    TORCH_LEVEL = TORCH_LEVEL + 1
    if TORCH_LEVEL <= 10 then
        Torch.alpha2 = Torch.alpha2 + 2
        Torch.alpha1 = Torch.alpha1 + 6
    end
    Torch.radius = Torch.radius + 4
end

function purchaseUnit()
    -- check balance
    for res, qty in pairs(unitCost) do
        if (inventory[res] or 0) < qty then
            return
        end
    end
    -- descrease balance
    for res, qty in pairs(unitCost) do
        inventory[res] = (inventory[res] or 0) - qty
        unitCost[res] = math.floor(qty * 1.6)
    end
    builtSomething = true
    spawnUnit()
end


function drawButtonInfo(box, msg, cost)
    local x,y = box:screenPosition()
    local w,h = box.w, box.h
    love.graphics.setColor(0,0,0)
    love.graphics.printf(msg,x,y+5,w,"center")
    local i = 0
    local numIcons = numEntries(cost)
    for res, qty in pairs(cost) do
        drawCost(x + w/2 + (i - (numIcons-1)/2) * 44, y + 40, res, qty)
        i = i + 1
    end
end

HUD = Layer:new()
function HUD:draw()
    local tl = P (10,10)
    local br = P(width-10,height-10)
    local wh = Vsub(br,tl)

    love.graphics.setColor(255,255,255,128)
    love.graphics.rectangle("line",tl[1],tl[2],wh[1],wh[2])

    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Entities: " .. #entities,20,35)
    love.graphics.print("Tiles on screen: " .. tilecount,20,50)
    love.graphics.print("Fire particles: " .. ps.fire:getCount(),20,65)

    local n = numEntries(inventory)
    local i = 0
    for resource, qty in pairs(inventory) do
        local w = 40
        local h = 40
        local y = height - h - 16
        local x = width/2 + (i - n/2) * (w + 6)
        drawInventoryItem(x, y, w, h, resource, qty)
        i = i + 1
    end
    
    -- draw costs for build buttons
    drawButtonInfo(buildUnit, "Build a Unit (" .. #units .. ")", unitCost)
    drawButtonInfo(digFaster, "Dig Faster (" .. DIG_SPEED - 1 .. ")", digFasterCost)
    drawButtonInfo(betterTorches, "Better Torches (" .. TORCH_LEVEL - 1 .. ")", betterTorchesCost)
    
    local y = height/2 - 22
    local w,h = 200,44
    local x = 25 -- width - w - 15
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
    ]]
    if not markedSomething then
        notify("Click underground to start mining",x, y, w, h)
        y = y + h + 4
    elseif not clearedMarks then
        notify("Units collect resources when they are not busy",x, y, w, h)
        y = y + h + 4
        notify("Right click to cancel all instructions",x, y, w, h)
        y = y + h + 4
    else
        if not builtSomething then
            notify("If you have enough resources, you can purchase stuff.",x, y, w, h)
            y = y + h + 4
        end
        if scrolled < 20 then
            notify("Move your mouse to the edge fo the screen to scroll",x, y, w, h)
            y = y + h + 4
        end
    end
    
    love.graphics.setColor(255,255,255)
    local box = screenSizes.children[1]
    local px, py = box:screenPosition()
    love.graphics.printf("Screen Size: ",px, py - 20, box.w, "center")
end

function drawIcon(resource, x, y)
    local icon = resourceIcons[resource]
    if icon == nil then
        icon = Material:new{col=Map.colors[resource]}
        resourceIcons[resource] = icon
    end
    icon.p = P(x - icon.size[1]/2, y - icon.size[2]/2)
    icon:draw()
end

function drawCost(x, y, resource, qty)
    local w = 40 -- text width
    love.graphics.printf(qty,x-w/2,y - 12,w,"center")
    drawIcon(resource, x, y + 12)
end

function drawInventoryItem(x, y, w, h, resource, qty)
    love.graphics.setColor(255,255,255,192)
    love.graphics.rectangle("fill",x,y,w,h)
    love.graphics.setColor(0,0,0,196)
    love.graphics.rectangle("line",x,y,w,h)
    love.graphics.printf(qty,x,y+5,w,"center")
    drawIcon(resource, x+w/2, y+h/2 + 8)
end

function notify(msg, x, y, w, h)
    love.graphics.setColor(255,255,255,192)
    love.graphics.rectangle("fill",x,y,w,h)
    love.graphics.setColor(0,0,0,196)
    love.graphics.rectangle("line",x,y,w,h)
    love.graphics.printf(msg,x,y+8,w,"center")
end