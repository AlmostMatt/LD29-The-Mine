require("almost/vmath")
require("almost/entity")
    
Type.Map = Type.new()
Map = Entity:new{t=Type.Map, x1 = 0, x2 = 0, y1 = 0, y2 = 0, unit = 12}
-- underground tiles
-- must be indexed from 1 to n
Map.numTiles = 0
function Map.nextType()
    Map.numTiles = Map.numTiles + 1
    return Map.numTiles
end
Map.DIRT = Map.nextType()
Map.ROCK = Map.nextType()
Map.SILVER = Map.nextType()
Map.GOLD = Map.nextType()
Map.MOONSTONE = Map.nextType()
Map.SAND = Map.nextType()
Map.DARK_ROCK = Map.nextType()
Map.BKG = Map.nextType()
Map.BLUE_ROCK = Map.nextType()

Map.BLANK = Map.nextType()

Map.BKG4 = Map.nextType()
Map.BKG5 = Map.nextType()
Map.BKG2 = Map.nextType()
Map.BKG3 = Map.nextType()

-- unnatural/surface (not randomly placed) tiles
Map.GRASS = Map.nextType()
Map.PLATFORM = Map.nextType()
Map.LAST_TYPE = Map.numTiles

Map.biomes = {
    {
        depth = 8,
        bkg = Map.BKG,
        frequency = {1000, 100,  0, 0, 0, 40, 0, 300, 0}, -- initial frequency before smoothing
        spreadRate = {20, 4, 2, 2, 4, 2, 4, 6, 10} -- "expected" frequency in a group of size ~25
    },
    {   -- near surface
        depth = 80,
        bkg = Map.BKG,
        frequency = {1000, 100,  6, 6, 1, 35, 1, 400, 0},
        spreadRate = {20, 4, 2, 2, 4, 2, 4, 8, 10} 
    },
    {   -- mostly rock
        depth = 150,
        bkg = Map.BKG2,
        frequency = {100, 1000,  7, 7, 5, 40, 100, 500, 0},
        spreadRate = {4, 20, 2, 2, 2, 3, 4, 8, 10} 
    },
    {   -- mostly dark rock
        depth = 260, 
        bkg = Map.BKG3,
        frequency = {10, 350,  8, 8, 5, 20, 800, 400, 1},
        spreadRate = {3, 10, 3, 3, 3, 5, 20, 8, 10} 
    },
    {   -- mostly blue rock
        depth = 350, -- 500  is very deep, it takes a long time to reach
        bkg = Map.BKG5,
        frequency = {0, 0,  8, 8, 5, 20, 150, 420, 800},
        spreadRate = {3, 4, 3, 3, 3, 5, 5, 8, 20} 
    },
    {   -- same as 2 before, slightly more gold/silver/sand/dirt
        depth = 500, 
        bkg = Map.BKG4,
        frequency = {15, 350,  9, 9, 5, 25, 800, 400, 1},
        spreadRate = {4, 10, 3, 3, 3, 5, 20, 8, 10} 
    },
}

-- load tile images
Map.tileset = love.graphics.newImage( "assets/tiles.png")
Map.batch = love.graphics.newSpriteBatch(Map.tileset, 8000, "stream")
Map.quads = {}
for tile = 1, Map.LAST_TYPE do
    Map.quads[tile] = love.graphics.newQuad(1 + (tile-1) * (Map.unit + 2), 1, Map.unit, Map.unit, Map.tileset:getWidth(), Map.tileset:getHeight())
end

Map.colors = {
    [Map.DIRT] = {104, 58, 31},
    [Map.ROCK] = {63, 63, 63},
    [Map.SILVER] = {216, 216, 216},
    [Map.GOLD] = {255, 241, 96},
    [Map.MOONSTONE] = {151, 158, 200},
    [Map.SAND] = {219, 159, 91},
    [Map.GRASS] = {0, 216, 92},
    [Map.DARK_ROCK] = {30, 30, 30},
    [Map.BLUE_ROCK] = {15, 19, 40},
    [Map.PLATFORM] = {216, 216, 216}
}

Map.digTime = {
    [Map.DIRT] = 0.15,
    [Map.ROCK] = 0.3,
    [Map.SILVER] = 0.4,
    [Map.GOLD] = 0.4,
    [Map.MOONSTONE] = 0.4,
    [Map.SAND] = 0.1,
    [Map.GRASS] = 0.2,
    [Map.DARK_ROCK] = 0.4,
    [Map.BLUE_ROCK] = 0.5,
    [Map.PLATFORM] = 0.15
}

BKGColor = {54, 37, 27}

DEBUG_COLLISION = false


-- tile type information
function Map:isWall(tileType)
    return (not self:isBKG(tileType)) and (not self:isPlatform(tileType))
end

function Map:isBKG(tileType)
    return tileType == Map.BKG
end

function Map:isPlatform(tileType)
    return tileType == Map.PLATFORM
end

function Map:canRotate(tileType)
    return tileType ~= Map.GRASS and tileType ~= Map.PLATFORM
end

function Map:biome(x,y)
    local depth = y - self.surface[x]
    local biome = nil
    for _, nextBiome in ipairs(Map.biomes) do
        biome = nextBiome
        if biome.depth >= depth then
            break
        end
    end
    return biome
end

function Map:randomTile(x, y)
    local depth = y - self.surface[x]
    if depth < 0 then
        return Map.BKG
    elseif depth == 0 then
        return Map.GRASS
    elseif depth < 2 then
        return Map.DIRT
    else
        local biome = self:biome(x,y)
        local total = 0
        for tile = 1, #biome.frequency do
            total = total + biome.frequency[tile]
        end
        local index = math.random(1, total)
        local total = 0
        for tile = 1, #biome.frequency do
            total = total + biome.frequency[tile]
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
    love.graphics.setColor(255,255,255,255)
    tilecount = 0
    local x1,y1 = self:gridCoordinate(screenMin)
    local x2,y2 = self:gridCoordinate(screenMax)

    Map.batch:bind()
    Map.batch:clear()
    for x = x1, x2 do
        for y = y1, y2 do
            local tileType = self:gridValue(x, y)
            if self:isPlatform(tileType) or self:isBKG(tileType) and y >= self.surface[x] then
                local bkgType = self:biome(x,y).bkg
                self:drawTile(bkgType, x, y)
            end
            if not self:isBKG(tileType) then
                self:drawTile(tileType, x, y)
            end
        end
        Map.batch:unbind()
        love.graphics.draw(Map.batch, 0, 0)
    end
    self:drawGrid()
end

function Map:drawTile(tileType, gx, gy)
    local r = 0
    if self:canRotate(tileType) then
        math.randomseed(gx * gy + gx + gy)
        r = math.pi * math.random(0,3)/2
    end
    Map.batch:add(Map.quads[tileType], (gx + 0.5) * self.unit, (gy + 0.5) * self.unit, r, 1, 1, self.unit/2, self.unit/2)
    tilecount = tilecount + 1
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
    local x1,y1 = self:gridCoordinate(screenMin)
    local x2,y2 = self:gridCoordinate(screenMax)

    love.graphics.setColor(0,0,0)
    for x = x1, x2 do
        for y = y1, y2 do
            local tileType = self:gridValue(x, y)
            if not self:isWall(tileType) then
                -- draw outlines
                for ox = -1, 1 do
                    for oy = -1, 1 do
                        if (ox == 0) ~= (oy == 0) then
                            local otherTileType = self:gridValue(x + ox, y + oy)
                            if self:isWall(otherTileType) then
                                if ox == 0 then
                                    love.graphics.line(x * self.unit, (y + 0.5 + oy/2) * self.unit, (x+1) * self.unit, (y + 0.5 + oy/2) * self.unit)
                                else
                                    love.graphics.line((x + 0.5 + ox/2) * self.unit, y * self.unit, (x + 0.5 + ox/2) * self.unit, (y + 1) * self.unit)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    --[[
    love.graphics.setColor(64,64,64,128)
    love.graphics.setLineWidth(1)
    for x = self.x1, self.x2 + 1 do
        love.graphics.line(x * self.unit, self.y1 * self.unit, x * self.unit, (self.y2 +1) * self.unit)
    end
    for y = self.y1, self.y2 + 1 do
        love.graphics.line(self.x1 * self.unit, y * self.unit, (self.x2 + 1) * self.unit, y * self.unit)
    end
    ]]
end


Tile = {val=Map.BKG, debugVal=0, reachable=false, illuminated=false}
function Map:newTile(value)
    local o = {val=value}
    setmetatable(o, Tile)
    o.__index = Tile
    return o
end

function Map:setTile(p, value)
    local gx, gy = self:gridCoordinate(p)
    self:extendMap(gx, gy)
    if (not self:isPlatform(value)) or gy >= self.surface[gx] then
        self.tiles[gx][gy].val = value
    end
    local tileP = P((gx+0.5) * self.unit, (gy+0.5) * self.unit)
    return tileP
end

function Map:setTileValue(gx, gy, value)
    if gx < self.x1 or gx > self.x2 or gy < self.y1 or gy > self.y2 then
        print("New tile at " .. gx .. ", " .. gy)
        self:setTile(P((gx + 0.5) * self.unit, (gy + 0.5) * self.unit))
    end
    self.tiles[gx][gy].debugVal = value
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

-- this shape of tiles was just added, cluster similar values together (including similar to the adjacent area)
-- do not affect values above the surface
function Map:smoothValues(gx1, gy1, gx2, gy2)
    for iteration = 1,1 do
        local newMap = {}
        for x = gx1, gx2 do
            newMap[x] = {}
            for y = gy1, gy2 do
                if y > self.surface[x] then
                    local biome = self:biome(x,y)
                    -- check neighbors
                    local nCount = 0
                    local fTotal = 0
                    local nCounts = {}
                    for tileType = 1, #biome.spreadRate do
                        nCounts[tileType] = 0
                        fTotal = fTotal + biome.spreadRate[tileType]
                    end
                    local o = 2
                    for ox = -o, o do
                        for oy = -o, o do
                            local nx = x + ox
                            local ny = y + oy
                            --if ox ~= 0 or oy ~= 0 then
                                if nx >= self.x1 and nx <= self.x2 and ny >= self.y1 and ny <= self.y2 and ny > self.surface[nx] then
                                    local nType = self.tiles[nx][ny].val
                                    if nCounts[nType] ~= nil then
                                        nCounts[nType] = nCounts[nType] + 1
                                        nCount = nCount + 1
                                    end
                                end
                            --end
                        end
                    end
                    -- want to see how the neighbor type distribution compares to the statistical frequency
                    -- and change to the type of the most common neighbor
                    -- to make things cluster
                    -- I think this means that everything near a gold will become a gold (since gold is supposed to be 1 in 400)
                    -- so maybe I apply the algorithm a few times
                    -- and have ratios > 2.0 or < 0.5 be ignored (overcrowding)
                    local maxRatio = 0
                    local maxType = 0
                    local variance = 0.5
                    for tileType = 1, #biome.spreadRate do
                        local r1 = nCounts[tileType]/nCount
                        local r2 = biome.spreadRate[tileType]/fTotal
                        --local ratio = r1
                        local ratio = r1/r2 --* (1 - variance/2 + math.random() * variance)
                        if ratio > maxRatio then
                            maxRatio = ratio
                            maxType = tileType
                        end
                    end
                    newMap[x][y] = maxType
                end
            end
        end
        for x = gx1, gx2 do
            for y = gy1, gy2 do
                if y > self.surface[x] then
                    self.tiles[x][y].val = newMap[x][y]
                end
            end
        end
    end
    -- if a cave occurs too close to the surface, make it act as a natural entrance, by lowering the surface level
    for x = gx1, gx2 do
        if gy1 <= self.surface[x] and gy2 >= self.surface[x] then
            while self.tiles[x][self.surface[x] + 1] and self:isBKG(self.tiles[x][self.surface[x] + 1].val) do
                self.tiles[x][self.surface[x]].val = Map.BKG
                self.surface[x] = self.surface[x] + 1
                self.tiles[x][self.surface[x]].val = Map.GRASS
            end
        end
    end
    -- find "pockets" of empty space to place stuff in
    for x = gx1, gx2 do
        for y = gy1, gy2 do
            
        end
    end
end

-- make the map larger to contain a specified point
function Map:extendMap(gx, gy)
    local surfaceVariance = 0.3
    local blocksize = 16
    math.randomseed(love.timer.getTime())
    while gx < self.x1 do
        for n = 1,blocksize do
            self.x1 = self.x1 - 1
            self.tiles[self.x1] = {}
            self.surface[self.x1] = math.floor(0.5 + self.surface[self.x1 + 1] + (math.random() - 0.5) * (1.0 + surfaceVariance))
            for y = self.y1, self.y2 do
                self.tiles[self.x1][y] = self:newTile(self:randomTile(self.x1, y))
            end
        end
        self:smoothValues(self.x1, self.y1, self.x1 + blocksize - 1, self.y2)
    end
    while gx > self.x2 do
        for n = 1,blocksize do
            self.x2 = self.x2 + 1
            self.tiles[self.x2] = {}
            self.surface[self.x2] = math.floor(0.5 + self.surface[self.x2 - 1] + (math.random() - 0.5) * (1.0 + surfaceVariance))
            for y = self.y1, self.y2 do
                self.tiles[self.x2][y] = self:newTile(self:randomTile(self.x2, y))
            end
        end
        self:smoothValues(self.x2 - blocksize + 1, self.y1, self.x2, self.y2)
    end
    while gy < self.y1 do
        for n = 1,blocksize do
            self.y1 = self.y1 - 1
            for x = self.x1, self.x2 do
                self.tiles[x][self.y1] = self:newTile(self:randomTile(x, self.y1))
            end
        end
        self:smoothValues(self.x1, self.y1, self.x2, self.y1 + blocksize - 1)
    end
    while gy > self.y2 do
        for n = 1,blocksize do
            self.y2 = self.y2 + 1
            for x = self.x1, self.x2 do
                self.tiles[x][self.y2] = self:newTile(self:randomTile(x, self.y2))
            end
        end
        self:smoothValues(self.x1, self.y2 - blocksize + 1, self.x2, self.y2)
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
                local tileType = self:gridValue(x, y)
                if (not self:isBKG(tileType)) and ((not self:isPlatform(tileType)) or (speed[2] > 0 and not object.fallThroughPlatforms)) then
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
                local tileType = self:gridValue(x, y)
                if  self:isWall(tileType) then
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
                        if self:isWall(self:gridValue(x, y)) then
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