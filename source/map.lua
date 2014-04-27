require("almost/vmath")
require("almost/entity")
    
Type.Map = Type.new()
Map = Entity:new{t=Type.Map, x1 = -50, x2 = 50, y1 = -10, y2 = 75, unit = 12}
-- underground tiles
-- must be indexed from 1 to n
Map.DIRT = 1
Map.ROCK = 2
Map.SILVER = 3
Map.GOLD = 4
Map.frequency = {60, 20, 4, 1}
-- non random / surface tiles
Map.GRASS = 5
Map.PLATFORM = 6

Map.colors = {
    [Map.DIRT] = {104, 58, 31},
    [Map.ROCK] = {63, 63, 63},
    [Map.SILVER] = {216, 216, 216},
    [Map.GOLD] = {255, 241, 96},
    [Map.GRASS] = {0, 216, 92},
    [Map.PLATFORM] = {216, 216, 216}
}
BKGColor = {54, 37, 27}

DEBUG_COLLISION = false

function Map:randomTile(x, depth)
    if depth < self.surface[x] then
        return 0
    elseif depth == self.surface[x] then
        return Map.GRASS
    else
        local total = 0
        for tile = Map.DIRT, Map.GOLD do
            total = total + Map.frequency[tile]
        end
        local index = math.random(1, total)
        local total = 0
        for tile = Map.DIRT, Map.GOLD do
            total = total + Map.frequency[tile]
            if total >= index then
                return tile
            end
        end
    end
end

function Map:add(o, layer)
    o = o or {}
    o = Entity.add(self, o, layer)
    o.origin = o.origin or P(0,0)
    o.surface = {}
    o.tiles = {}
    o.surface[0] = 0
    local variance = 0.3
    for x = 1, o.x2 do
        o.surface[x] = math.floor(0.5 + o.surface[x-1] + (math.random() - 0.5) * (1.0 + variance))
    end
    for x = -1, o.x1, -1 do
        o.surface[x] = math.floor(0.5 + o.surface[x+1] + (math.random() - 0.5) * (1.0 + variance))
    end
    for x = o.x1, o.x2 do
        o.tiles[x] = {}
        for y = o.y1, o.y2 do
            o.tiles[x][y] = o:newTile(o:randomTile(x, y))
        end
    end
    return o
end

function Map:draw()
    for x = self.x1, self.x2 do
        for y = self.y1, self.y2 do
            local tileType = self:gridValue(x, y)
            if DEBUG_COLLISION then
                local color = {0,0,0,255}
                if tileType == 0 then
                    color[4] = 128
                end
                color[1] = 255 * self.tiles[x][y][2]
                self.tiles[x][y][2] = math.max(0, self.tiles[x][y][2] - 0.1)
                love.graphics.setColor(color)
                love.graphics.rectangle("fill", x * self.unit, y * self.unit, self.unit, self.unit)
            else
                if tileType ~= 0 or y >= self.surface[x] then
                    local color = BKGColor
                    if tileType ~= 0 then
                        color = self.colors[tileType]
                    end
                    love.graphics.setColor(color)
                    love.graphics.rectangle("fill", x * self.unit, y * self.unit, self.unit, self.unit)
                    if OUTLINES and tileType ~= 0 then
                        love.graphics.setColor(colormult(0.5, color))
                        love.graphics.rectangle("line", x * self.unit, y * self.unit, self.unit, self.unit)
                    end
                end
            end
        end
    end
    --self:drawGrid()
end

function Map:drawGrid()
    love.graphics.setColor(64,64,64,128)
    love.graphics.setLineWidth(1)
    for x = self.x1, self.x2 + 1 do
        love.graphics.line(x * self.unit, self.y1 * self.unit, x * self.unit, (self.y2 +1) * self.unit)
    end
    for y = self.y1, self.y2 + 1 do
        love.graphics.line(self.x1 * self.unit, y * self.unit, (self.x2 + 1) * self.unit, y * self.unit)
    end
end

function Map:newTile(value)
    --tiletype, debugValue, reachable
    return {value, 0, false}
end

function Map:setTile(p, value)
    local gx = math.floor(p[1]/self.unit)
    local gy = math.floor(p[2]/self.unit)
    while gx < self.x1 do
        self.x1 = self.x1 - 1
        self.tiles[self.x1] = {}
        self.surface[self.x1] = self.surface[self.x1 + 1]
        for y = self.y1, self.y2 do
            self.tiles[self.x1][y] = self:newTile(self:randomTile(x, y))
        end
    end
    while gx > self.x2 do
        self.x2 = self.x2 + 1
        self.tiles[self.x2] = {}
        self.surface[self.x2] = self.surface[self.x2 - 1]
        for y = self.y1, self.y2 do
            self.tiles[self.x2][y] = self:newTile(self:randomTile(x, y))
        end
    end
    while gy < self.y1 do
        self.y1 = self.y1 - 1
        for x = self.x1, self.x2 do
            self.tiles[x][self.y1] = self:newTile(self:randomTile(x, y))
        end
    end
    while gy > self.y2 do
        self.y2 = self.y2 + 1
        for x = self.x1, self.x2 do
            self.tiles[x][self.y2] = self:newTile(self:randomTile(x, y))   
        end
    end
    self.tiles[gx][gy][1] = value
end

function Map:setTileValue(gx, gy, value)
    if gx < self.x1 or gx > self.x2 or gy < self.y1 or gy > self.y2 then
        print("New tile at " .. gx .. ", " .. gy)
        self:setTile(P((gx + 0.5) * self.unit, (gy + 0.5) * self.unit))
    end
    self.tiles[gx][gy][2] = value
end

function Map:isWall(p)
    return getTile(p) ~= 0
end

function Map:gridCoordinate(p)
    return math.floor(p[1]/self.unit), math.floor(p[2]/self.unit)
end

function Map:getTile(p)
    local gx, gy = gridCoordinate(p)
    return self:gridValue(gx, gy)
end

-- returns the game coordinates of the centers of all of the tiles in an area
function Map:getTilesNear(p, r)
    result = {}
    local gx, gy = gridCoordinate(p)
    local gr = math.ceil(r/self.unit)
    for x = gx - r, gx + r do
        for y = gy - r, gy + r do
            local tileP = P((x+0.5) * self.unit, (y+0.5) * self.unit)
            if Vdd(Vsub(tileP, p)) < r^2 then
                table.insert(result, {p=tileP, val=self:gridValue(x,y)})
            end
        end
    end
    return result
end

function Map:gridValue(gx, gy)
    if gx >= self.x1 and gx <= self.x2 and gy >= self.y1 and gy <= self.y2 then
        tile = self.tiles[gx][gy]
        if tile[1] == nil then
            tile[1] = 0
        end
        --print(gx, gy, #tile)
        return tile[1]
    else
        return 0
    end
end

-- returns new position and speed
function Map:collide(object, dt)
    local p1 = object.p
    local size = object.size
    local speed = object.v
    local elasticity = object.elastic
    
    object.onGround = false
    object.hitWall = false
    
    local p2 = Vadd(p1, Vmult(dt, speed))
    local speed2 = P(speed[1], speed[2])
    
    -- assume that this was called last frame as well
    -- so the object is not currently in a wall.
    local oldx1 = math.floor(p1[1]/self.unit)
    local oldy1 = math.floor(p1[2]/self.unit)
    local oldx2 = math.ceil((p1[1] + size[1])/self.unit) - 1
    local oldy2 = math.ceil((p1[2] + size[2])/self.unit) - 1

    local x1 = math.floor(p2[1]/self.unit)
    local y1 = math.floor(p2[2]/self.unit)
    local x2 = math.ceil((p2[1] + size[1])/self.unit) - 1
    local y2 = math.ceil((p2[2] + size[2])/self.unit) - 1
    
    -- consider only new tiles reached by moving horizontally, vertically, or diagonally
    
    --vertical collision check
    for y = y1, y2 do
        if y < oldy1 or y > oldy2 then
            for x = oldx1, oldx2 do
                if DEBUG_COLLISION then self:setTileValue(x, y, 1) end
                if self:gridValue(x, y) ~= 0 then
                    speed2[2] = speed[2] * -elasticity
                    if y > oldy2 then
                        object.onGround = true
                        p2[2] = math.min(p2[2], y * self.unit - size[2])
                    else
                        p2[2] = math.max(p2[2], (y + 1) * self.unit)
                    end
                end
            end
        end
    end

    --horizontal collision check
    for x = x1, x2 do
        if x < oldx1 or x > oldx2 then
            for y = oldy1, oldy2 do
                if DEBUG_COLLISION then self:setTileValue(x, y, 1) end
                if self:gridValue(x, y) ~= 0 then
                    speed2[1] = speed[1] * -elasticity
                    object.hitWall = true
                    if x > oldx2 then
                        p2[1] = math.min(p2[1], x * self.unit - size[1])
                    else
                        p2[1] = math.max(p2[1], (x + 1) * self.unit)
                    end
                end
            end
        end
    end
    
    -- only check for diagonal collisions if there was no horizontal or diagonal collision
    if speed2[1] ~= 0 and speed2[2] ~= 0 then
        local deltax = 0
        local deltay = 0
        
        for x = x1, x2 do
            if x < oldx1 or x > oldx2 then
                for y = y1, y2 do
                    if y < oldy1 or y > oldy2 then
                        -- this is a tile that did not previously overlap the hitbox but now it does.
                        -- it is also diagonal with respect to the old hitbox position
                        if self:gridValue(x, y) ~= 0 then
                            if x > oldx2 then
                                deltax = math.min(deltax, (x * self.unit - size[1]) - p2[1])
                            else
                                deltax = math.max(deltax, (x + 1) * self.unit - p2[1])
                            end
                            if y > oldy2 then
                                deltay = math.min(deltay, (y * self.unit - size[2]) - p2[2])
                            else
                                deltay = math.max(deltay, (y + 1) * self.unit - p2[2])
                            end
                        end
                    end
                end
            end
        end
        -- move the unit either horizontally or vertically depending on which requires less displacement
        if math.abs(deltax) < math.abs(deltay) then
            p2[1] = p2[1] + deltax
            speed2[1] = speed[1] * -elasticity
            object.hitWall = true
        elseif deltay ~= 0 then
            p2[2] = p2[2] + deltay
            speed2[2] = speed[1] * -elasticity
            if deltay < 0 then
                object.onGround = true
            end
        end
    end
    
    object.p = p2
    object.v = speed2
end

-- returns a vector indicating how far (and in what direction) a box would need to be moved 
-- to not be in a wall
-- this gives the smallest offset to push the object out of some wall, but it may still be in another so this may be repeated for collision logic

-- this behaves poorly for tiles smaller than the player (and gaps between groups of tiles smaller than the player)
function Map:getLeastPen(p1, size)
    local maxDepth = 2 -- how many tiles a valid offset is likely to be bounded by
    -- (depends on how fast the object is traveling -> magn9speed) / tile size
    
    local x1 = math.floor(p1[1]/self.unit)
    local y1 = math.floor(p1[2]/self.unit)
    local x2 = math.ceil((p1[1] + size[1])/self.unit) - 1
    local y2 = math.ceil((p1[2] + size[2])/self.unit) - 1
    
    local penX = math.huge
    local penY = math.huge
    
    local hCollision = 0
    local vCollision = 0
    
    for dir = -1, 1, 2 do
        local dirPenX = 0
        local dirPenY = 0
        
        -- check rows for horizontal collisions
        local startX = dir == 1 and x1 or x2
        local endX = dir == 1 and x2 + maxDepth or x1 - maxDepth
        for y = y1, y2 do
            local collision = false
            local newPenX = 0
            for x = startX, endX, dir do
                if (x < x1 or x > x2) and not collision then
                    break
                end
                if DEBUG_COLLISION then self:setTileValue(x, y, 1) end
                if self:gridValue(x, y) ~= 0 then
                    collision = true
                    if dir == 1 then
                        newPenX = (x + 1) * self.unit - p1[1] + 0.001
                    else
                        newPenX = (x) * self.unit - (p1[1] + size[1]) - 0.001
                    end
                elseif collision then
                    break
                end
            end
            
            if dirPenX == 0 or (newPenX ~= 0 and math.abs(newPenX) < math.abs(dirPenX)) then
                dirPenX = newPenX
            end
        end
        
        -- check columns for vertical collisions
        local startY = dir == 1 and y1 or y2
        local endY = dir == 1 and y2 + maxDepth or y1 - maxDepth
        for x = x1, x2 do
            local collision = false
            local newPenY = 0
            for y = startY, endY, dir do
                if (y < y1 or y > y2) and not collision then
                    break
                end
                if DEBUG_COLLISION then self:setTileValue(x, y, 1) end
                if self:gridValue(x, y) ~= 0 then
                    collision = true
                    if dir == 1 then
                        newPenY = (y + 1) * self.unit - p1[2]
                    else
                        newPenY = (y) * self.unit - (p1[2] + size[2])
                    end
                elseif collision then
                    break
                end
            end
            
            if dirPenY == 0 or (newPenY ~= 0 and math.abs(newPenY) < math.abs(dirPenY)) then
                dirPenY = newPenY
            end
        end

        if math.abs(dirPenX) < math.abs(penX) then
            penX = dirPenX
        end
        if math.abs(dirPenY) < math.abs(penY) then
            penY = dirPenY
        end
    end
    
    return P(penX, penY)
end

