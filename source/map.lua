require("almost/vmath")
require("almost/entity")

DEBUG_COLLISION = false -- no longer does anything
DEBUG_GENERATION = false
DEBUG_NO_SHADOWS = false
DEBUG_REGIONS = false
DEBUG_INFO = true
DEBUG_PATHING = false

DEBUG_COLORS = {
    {255,128,128},
    {255,255,0},
    {0,128,255},
    {128,255,128},
    {0,128,0},
    {128,0,0},
    {0,0,128}
}

Type.Map = Type.new()
Map = Entity:new{t=Type.Map, x1 = 0, x2 = 0, y1 = 0, y2 = 0, unit = 12, blocksize = 16}
require("tileset")
function Map:add(o, layer)
    o = o or {}
    o = Entity.add(self, o, layer)
    o.origin = o.origin or P(0,0)
    o.surface = {}
    o.tiles = {}
    o.surface[0] = 0
    o.numRegions = 0
    o.regionSizes = {}
    o:extendMap(0, 0)
    --[[
    o.tiles[0] = {}
    o.tiles[0][0] = o:newTile(o:randomTile(0, 0))
    if not o:isWall(o:gridValue(0,0)) then
        o.tiles[0][0].region = 1
        o.regionSizes[1] = 1
        o.numRegions = 1
    end
    ]]
    return o
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
            if (not DEBUG_GENERATION) or self:containsTile(x,y) then
                local tileType = self:gridValue(x, y)
                local tile = self:getTileObject(x, y)
                if (tile.transparent or self:isBKG(tileType)) and y > self.surface[x] then
                --if self:isPlatform(tileType) or self:isBKG(tileType) and y >= self.surface[x] then
                    local bkgType = self:biome(x,y).bkg
                    local bkgImage = self.backgroundImages[bkgType]
                    if DEBUG_REGIONS then
                        Map.batch:setColor(DEBUG_COLORS[1 + (tile.region % #DEBUG_COLORS)])
                        self:drawTileImage(bkgImage, x, y)
                        Map.batch:setColor(255,255,255)
                    else
                        self:drawTileImage(bkgImage, x, y)
                    end
                end
                if not self:isBKG(tileType) then
                    self:drawTile(tile, x, y)
                end
            end
        end
        Map.batch:unbind()
        love.graphics.draw(Map.batch, 0, 0)
    end
    --self:drawGrid()
end

function Map:drawTile(tile, gx, gy)
    -- if debug generation is on, don't draw tiles that depend on unknown adjacent materials
    if (not DEBUG_GENERATION) or (self:containsTile(gx - 1, gy) and self:containsTile(gx + 1, gy) and self:containsTile(gx, gy - 1) and self:containsTile(gx, gy + 1)) then
        if not tile.img then
            self:getTileInfo(tile, gx, gy)
        end
        self:drawTileImage(tile.img, gx, gy, tile.flipped, tile.rotation)
    end
end

function Map:drawTileImage(quad, gx, gy, flipped, rotation)
    Map.batch:add(quad, (gx + 0.5) * self.unit, (gy + 0.5) * self.unit, rotation, flipped and -1 or 1, 1, self.unit/2, self.unit/2)
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
            if self:containsTile(x,y) then
                local tileType = self:gridValue(x, y)
                if not self:isWall(tileType) then
                    -- draw outlines
                    for ox = -1, 1 do
                        for oy = -1, 1 do
                            if (ox == 0) ~= (oy == 0) then
                                if self:containsTile(x + ox, y + oy) then
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
        end
    end
end


-- tiles that have the same region value are connected.
-- different values are not connected.
Tile = {val=Map.BKG, debugVal=0, region=0, illuminated=false}
Tile.__index = Tile
function Map:newTile(value)
    local o = {val=value}
    setmetatable(o, Tile)
    return o
end




-- REGION METHODS

-- when the map is extended, check to see which new tiles are connected to existing regions
-- and determine any new regions
function Map:newTiles(x1, y1, x2, y2)
    for x = x1, x2 do
        for y = y1, y2 do
            local t = self:gridValue(x, y)
            if (not self:isWall(t)) and self.tiles[x][y].region == 0 then
                self:floodFillRegion(x, y, self:newRegion())
            end
        end
    end
end

function Map:setTile(p, value)
    local gx, gy = self:gridCoordinate(p)
    self:extendMap(gx, gy)
    -- don't let the user build platforms in midair
    if gy >= self.surface[gx] or (not self:isPlatform(value)) then
        local tile = self.tiles[gx][gy]
        local oldValue = tile.val
        tile.val = value
        self:tileChanged(gx, gy, oldValue, value)
    end
    local tileP = P((gx+0.5) * self.unit, (gy+0.5) * self.unit)
    return tileP
end

function Map:tileChanged(gx, gy, oldValue, newValue)
    --update image info immediately
    local tileObj = self.tiles[gx][gy]
    tileObj.img = nil
    tileObj.flipped = nil
    tileObj.rotation = nil
    tileObj.transparent = nil
    self:getTileInfo(tileObj, gx, gy)

    -- update region information
    if self:isWall(oldValue) ~= self:isWall(newValue) then
        local adjacent = self:getAdjacent(gx, gy)
        if self:isWall(newValue) then
        -- if changed to wall, check for separation of areas
            local unconnected = {}
            local num_unconnected = #adjacent - 1
            local oldRegion = self.tiles[gx][gy].region
            self.tiles[gx][gy].region = 0
            for i, tile in ipairs(adjacent) do
                local x,y = tile[1], tile[2]
                if i ~= 0 then
                    unconnected[x] = unconnected[x] or {}
                    unconnected[x][y] = true
                end
            end
            for i, tile in ipairs(adjacent) do
                local x,y = tile[1], tile[2]
                if unconnected[x] and unconnected[x][y] and num_unconnected > 0 then
                    -- do a flood fill for each adjacent tile
                    -- and if it reaches another adjacent tile, mark it as connected
                    -- if it reaches the last unconnected, then destroy the old region.
                    -- otherwise, the last unconnected will continue to exist as the old region
                    -- want a modified version of flood fill that stops if it contains an entire set of tiles and then  undoes its changes
                    
                    -- flood fill with 4 starting points, if any of them reaches each other, merge them and if only 1 starting point is unmerged, do an "undo" fill of the original type
                end
            end
        else
        -- if changed from wall to empty space, check for joining of previously distinct regions
            local regions = {}
            local numregions = 0
            local largestRegion = nil
            for _, tile in ipairs(adjacent) do
                local x,y = tile[1], tile[2]
                local region = self.tiles[x][y].region
                if not regions[region] then
                    regions[region] = true
                    numregions = numregions + 1
                    if (largestRegion == nil) or self.regionSizes[region] > self.regionSizes[largestRegion] then
                        largestRegion = region
                    end
                end
            end
            if largestRegion then
                local oldSize = self.regionSizes[largestRegion]
                local t1 = love.timer.getTime()
                self:floodFillRegion(gx, gy, largestRegion)
                local t2 = love.timer.getTime()
                local newSize = self.regionSizes[largestRegion]
                floodTime2 = floodTime2 + t2 - t1
                mergedTiles = mergedTiles + newSize - oldSize
            else
                self.tiles[gx][gy].region = self:newRegion()
            end
        end
    end
end

-- fill a region with a specified type. if the fill encounters another larger region it will fill with the other region instead
function Map:floodFillRegion(gx, gy, value)
    self.tiles[gx][gy].region = value
    local count = 1
    local queue = {{gx, gy}}
    while #queue > 0 do
        local tx, ty = queue[1][1], queue[1][2]
        table.remove(queue,1)
        local t_adjacent = self:getAdjacent(tx, ty)
        for _, other_tile in ipairs(t_adjacent) do
            local otherx, othery = other_tile[1], other_tile[2]
            local oregion = self.tiles[otherx][othery].region
            if oregion ~= value then
                count = count + 1
                if oregion ~= 0 and self:isRegion(oregion) then
                    if self.regionSizes[oregion] > self.regionSizes[value] + count then
                        queue = {other_tile}
                        value = oregion
                        break
                    else
                        self:destroyRegion(oregion)
                    end
                end
                self.tiles[otherx][othery].region = value
                table.insert(queue, other_tile)
            end
        end
    end
    self.regionSizes[value] = self.regionSizes[value] + count
end

function Map:destroyRegion(region)
    self.regionSizes[region] = -1
    self.numRegions = self.numRegions - 1
end

-- the size of this region should be increased after the region is created since size 0 means that it no longer exists
function Map:newRegion()
    self.numRegions = self.numRegions + 1
    -- check for reuse of an existing region
    for i, size in ipairs(self.regionSizes) do
        if size < 0 then
            return i
        end
    end
    -- or add a new region. the 1st region should be "1"
    self.regionSizes[self.numRegions] = 0
    return self.numRegions
end

function Map:isRegion(region)
    return region ~= 0 and self.regionSizes[region] >= 0
end

-- get non-wall tiles adjacent to the current tile
function Map:getAdjacent(gx, gy)
    local adjacent = {}
    for ox = -1, 1 do
        for oy = -1, 1 do
            if ox ~= oy and (ox == 0 or oy == 0) then
                local x,y = gx + ox, gy + oy
                if self:containsTile(x,y) then
                    local tileType = self:gridValue(x, y)
                    if not self:isWall(tileType) then
                        table.insert(adjacent, {x,y})
                    end
                end
            end
        end
    end
    return adjacent
end

-- END REGION METHODS

function Map:containsTile(gx, gy)
    return self.tiles[gx] and self.tiles[gx][gy]
end

function Map:tileDrawable(gx, gy)
    return self.containsTile(gx, gy) and self.tiles[gx][gy].img
end

function Map:setTileValue(gx, gy, value)
    if not self:containsTile(gx, gy) then
        self:setTile(P((gx + 0.5) * self.unit, (gy + 0.5) * self.unit))
    end
    self.tiles[gx][gy].debugVal = value
end

function Map:gridCoordinate(p)
    return math.floor(p[1]/self.unit), math.floor(p[2]/self.unit)
end

function Map:gameCoordinate(gx, gy)
    return P((gx + 0.5) * self.unit, (gy + 0.5) * self.unit)
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
    if not self:containsTile(gx,gy) then
        self:extendMap(gx, gy)
    end
    local tile = self.tiles[gx][gy]
    return tile.val
end

function Map:getTileObject(gx, gy)
    if not self:containsTile(gx,gy) then
        self:extendMap(gx, gy)
    end
    return self.tiles[gx][gy]
end

-- this shape of tiles was just added, cluster similar values together (including similar to the adjacent area)
-- do not affect values above the surface
function Map:smoothValues(gx1, gy1, gx2, gy2)
    local t1 = love.timer.getTime()
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
                            if self:containsTile(nx, ny) and ny > self.surface[nx] then
                                local nType = self.tiles[nx][ny].val
                                if nCounts[nType] ~= nil then
                                    nCounts[nType] = nCounts[nType] + 1
                                    nCount = nCount + 1
                                end
                            end
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
    local t2 = love.timer.getTime()
    -- update region info
    self:newTiles(gx1, gy1, gx2, gy2)
    local t3 = love.timer.getTime()
    smoothTime = smoothTime + t2 - t1
    floodTime = floodTime + t3 - t2
    newTiles = newTiles + (gx2 - gx1 + 1) * (gy2 - gy1 + 1)
end

-- make the map larger to contain a specified point
function Map:extendMap(gx, gy)
    local surfaceVariance = 0.3
    math.randomseed(love.timer.getTime())
    -- new version
    if self.x1 == self.x2 then
        -- map initialization, x1, y1, ... = 0
        -- need to maintain that blocks are positioned mod blocksize
        self.tiles[0] = {}
        self.x2 = self.blocksize - 1
        self.y2 = self.blocksize - 1
        for x = 1, self.blocksize - 1 do
            self.tiles[x] = {}
            self.surface[x] = math.floor(0.5 + self.surface[x - 1] + (math.random() - 0.5) * (1.0 + surfaceVariance))
        end
    end
    while gx < self.x1 do
        for n = 1, self.blocksize do
            self.x1 = self.x1 - 1
            self.tiles[self.x1] = {}
            self.surface[self.x1] = math.floor(0.5 + self.surface[self.x1 + 1] + (math.random() - 0.5) * (1.0 + surfaceVariance))
        end
    end
    while gx > self.x2 do
        for n = 1, self.blocksize do
            self.x2 = self.x2 + 1
            self.tiles[self.x2] = {}
            self.surface[self.x2] = math.floor(0.5 + self.surface[self.x2 - 1] + (math.random() - 0.5) * (1.0 + surfaceVariance))
        end
    end
    if not self.tiles[gx][gy] then
        -- generate the block that contains this tile
        local bx1, by1 = self.blocksize * math.floor(gx/self.blocksize), self.blocksize * math.floor(gy/self.blocksize)
        local bx2, by2 = bx1 + self.blocksize - 1, by1 + self.blocksize - 1
        for x = bx1, bx2 do
            for y = by1, by2 do
                self.tiles[x][y] = self:newTile(self:randomTile(x, y))
            end
        end
        self:smoothValues(bx1, by1, bx2, by2)
        self.y1 =  math.min(self.y1, by1)
        self.y2 =  math.max(self.y2, by2)
    end
    --[[
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
    ]]
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