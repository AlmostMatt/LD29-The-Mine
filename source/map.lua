require("almost/vmath")
require("almost/entity")
    
Type.Map = Type.new()
Map = Entity:new{t=Type.Map, x1 = 0, x2 = 0, y1 = 0, y2 = 0, unit = 12}
-- underground tiles
-- must be indexed from 1 to n
Map.DIRT = 1
Map.ROCK = 2
Map.SILVER = 3
Map.GOLD = 4
Map.frequency = {200, 80, 3, 1}
-- non random / surface tiles
Map.GRASS = 5
Map.BKG = 6
Map.PLATFORM = 7
Map.LAST_TYPE = Map.PLATFORM

-- load tile images
Map.tileset = love.graphics.newImage( "assets/tiles.png")
Map.batch = love.graphics.newSpriteBatch(Map.tileset, 7000, "stream")
Map.quads = {}
for tile = 1, Map.LAST_TYPE do
    Map.quads[tile] = love.graphics.newQuad(1 + (tile-1) * (Map.unit + 2), 1, Map.unit, Map.unit, Map.tileset:getWidth(), Map.tileset:getHeight())
end

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
    o.tiles[0] = {}
    o.tiles[0][0] = o:newTile(o:randomTile(0, 0))
    return o
end

function Map:redraw()
-- TODO
-- only redraw the map when the camera has moved a full tile's distance, or if a tile was destroyed/created this frame
end

function Map:draw()
    tilecount = 0
    local x1,y1 = self:gridCoordinate(screenMin)
    local x2,y2 = self:gridCoordinate(screenMax)

    Map.batch:bind()
    Map.batch:clear()
    for x = x1, x2 do
        for y = y1, y2 do
            local tileType = self:gridValue(x, y)
            if tileType ~= 0 or y >= self.surface[x] then
                if tileType == 0 then
                    tileType = Map.BKG
                end
                local r = 0
                if tileType ~= Map.GRASS then
                    math.randomseed(x + y)
                    r = math.pi * math.random(0,3)/2
                end
                Map.batch:add(Map.quads[tileType], (x + 0.5) * self.unit, (y + 0.5) * self.unit, r, 1, 1, self.unit/2, self.unit/2)
                tilecount = tilecount + 1
            end
        end
        Map.batch:unbind()
        love.graphics.setColor(255,255,255,255)
        love.graphics.draw(Map.batch, 0, 0)
    end
end

-- this is drawn in front of everything (in front of shadows, anyways)
function Map:drawOverlay()
    local mx, my = self:gridCoordinate(mouse)
    love.graphics.setColor(128,0,0, 128)
    love.graphics.rectangle("fill", mx * self.unit, my * self.unit, self.unit, self.unit)
    love.graphics.setColor(192,0,0, 255)
    love.graphics.rectangle("line", mx * self.unit, my * self.unit, self.unit, self.unit)
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


Tile = {val=0, debugVal=0, reachable=false, illuminated=false}
function Map:newTile(value)
    local o = {val=value}
    setmetatable(o, Tile)
    o.__index = Tile
    return o
end

function Map:setTile(p, value)
    local gx, gy = self:gridCoordinate(p)
    self:extendMap(gx, gy)
    self.tiles[gx][gy].val = value
end

function Map:setTileValue(gx, gy, value)
    if gx < self.x1 or gx > self.x2 or gy < self.y1 or gy > self.y2 then
        print("New tile at " .. gx .. ", " .. gy)
        self:setTile(P((gx + 0.5) * self.unit, (gy + 0.5) * self.unit))
    end
    self.tiles[gx][gy].debugVal = value
end

function Map:isWall(p)
    return getTile(p) ~= 0
end

function Map:gridCoordinate(p)
    return math.floor(p[1]/self.unit), math.floor(p[2]/self.unit)
end

function Map:getTile(p)
    local gx, gy = self:gridCoordinate(p)
    return self:gridValue(gx, gy)
end

-- returns the game coordinates of the centers of all of the tiles in an area
function Map:getTilesNear(p, r)
    result = {}
    local gx, gy = self:gridCoordinate(p)
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
    if gx < self.x1 or gx > self.x2 or gy < self.y1 or gy > self.y2 then
        self:extendMap(gx, gy)
    end
    tile = self.tiles[gx][gy]
    return tile.val
end

-- make the map larger to contain a specified point
function Map:extendMap(gx, gy)
    local surfaceVariance = 0.3
    while gx < self.x1 do
        self.x1 = self.x1 - 1
        self.tiles[self.x1] = {}
        self.surface[self.x1] = math.floor(0.5 + self.surface[self.x1 + 1] + (math.random() - 0.5) * (1.0 + surfaceVariance))
        for y = self.y1, self.y2 do
            self.tiles[self.x1][y] = self:newTile(self:randomTile(self.x1, y))
        end
    end
    while gx > self.x2 do
        self.x2 = self.x2 + 1
        self.tiles[self.x2] = {}
        self.surface[self.x2] = math.floor(0.5 + self.surface[self.x2 - 1] + (math.random() - 0.5) * (1.0 + surfaceVariance))
        for y = self.y1, self.y2 do
            self.tiles[self.x2][y] = self:newTile(self:randomTile(self.x2, y))
        end
    end
    while gy < self.y1 do
        self.y1 = self.y1 - 1
        for x = self.x1, self.x2 do
            self.tiles[x][self.y1] = self:newTile(self:randomTile(x, self.y1))
        end
    end
    while gy > self.y2 do
        self.y2 = self.y2 + 1
        for x = self.x1, self.x2 do
            self.tiles[x][self.y2] = self:newTile(self:randomTile(x, self.y2))
        end
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