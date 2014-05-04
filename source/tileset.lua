-- assuming Map object exists

-- (randomly generated) materials
-- must be indexed from 1 to n
-- platforms and sky are not random

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
        depth = 180,
        bkg = Map.BKG2,
        frequency = {100, 1000,  7, 7, 5, 40, 100, 500, 0},
        spreadRate = {4, 20, 2, 2, 2, 3, 4, 8, 10} 
    },
    {   -- mostly dark rock
        depth = 290, 
        bkg = Map.BKG3,
        frequency = {10, 350,  8, 8, 5, 20, 800, 400, 1},
        spreadRate = {3, 10, 3, 3, 3, 5, 20, 8, 10} 
    },
    {   -- mostly blue rock
        depth = 370, -- 500  is very deep, it takes a long time to reach
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
Map.tilesetWidth = 8 -- the tiles per row in the image
Map.tileset = love.graphics.newImage( "assets/tiles.png")
Map.batch = love.graphics.newSpriteBatch(Map.tileset, 8000, "stream")

function Map:getTile(row, column)
    return love.graphics.newQuad((column - 1) * Map.unit, (row - 1) * Map.unit, Map.unit, Map.unit, Map.tileset:getWidth(), Map.tileset:getHeight())
end
Map.quads = {}
for tile = 1, Map.LAST_TYPE do
    --Map.quads[tile] = love.graphics.newQuad(1 + (tile-1) * (Map.unit + 2), 1, Map.unit, Map.unit, Map.tileset:getWidth(), Map.tileset:getHeight())
    --Map.quads[tile] = love.graphics.newQuad((tile-1) * (Map.unit), 0, Map.unit, Map.unit, Map.tileset:getWidth(), Map.tileset:getHeight())
    Map.quads[tile] = Map:getTile(tile % Map.tilesetWidth, math.ceil(tile / Map.tilesetWidth))
end

-- define material + relative tile material info -> tile image maps
Map.tileMap = {
    [Map.GRASS] = {
        { -- middle of grass section
            img = Map:getTile(1,3),
            transparent = true,
            left = Map.GRASS,
            right = Map.GRASS,
            canFlip = true
        },
        { -- corner
            img = Map:getTile(1,4),
            transparent = true,
            notleft = Map.BKG,
            right = Map.BKG,
            canFlip = true
        },
        { -- single tile "island" of grass
            img = Map:getTile(1,2),
            transparent = true,
            notleft = Map.GRASS,
            notright = Map.GRASS,
            canFlip = true
        },
        default = {
            img = Map:getTile(1, 3),
            canFlip = true
        }
    },
    [Map.DIRT] = {
        {
        -- corner next to bkg
            img = Map:getTile(3,4),
            transparent = true,
            notright = Map.BKG,
            notbot = Map.BKG,
            left = Map.BKG,
            top = Map.BKG,
            canRotate = true
        },
        {
        -- edge next to bkg
            img = Map:getTile(3,5),
            transparent = true,
            notright = Map.BKG,
            notbot = Map.BKG,
            left = Map.BKG,
            nottop = Map.BKG,
            canRotate = true
        },
        {
        -- bkg on 3 sides
            img = Map:getTile(3,8),
            transparent = true,
            notright = Map.BKG,
            bot = Map.BKG,
            left = Map.BKG,
            top = Map.BKG,
            canRotate = true
        },
        default = {
            img = Map:getTile(1,1),
            canFlip = true,
            canRotate = true
        }
    },
    [Map.DARK_ROCK] = {
        default = {
            img = Map:getTile(1,6),
            canFlip = true,
            canRotate = true
        }
    },
    [Map.ROCK] = {
        {
        -- corner next to dirt
            img = Map:getTile(3,3),
            right = Map.DIRT,
            bot = Map.DIRT,
            notleft = Map.DIRT,
            nottop = Map.DIRT,
            canRotate = true
        },
        {
        -- corner next to bkg
            img = Map:getTile(3,6),
            transparent = true,
            right = Map.BKG,
            bot = Map.BKG,
            notleft = Map.BKG,
            nottop = Map.BKG,
            canRotate = true
        },
        {
        -- bkg on 3 sides
            img = Map:getTile(3,7),
            transparent = true,
            right = Map.BKG,
            bot = Map.BKG,
            notleft = Map.BKG,
            top = Map.BKG,
            canRotate = true
        },
        default = {
            img = Map:getTile(1,7),
            canFlip = true,
            canRotate = true
        }
    },
    [Map.SILVER] = {
        default = {
            img = Map:getTile(3,1)
        }
    },
    [Map.GOLD] = {
        default = {
            img = Map:getTile(2, 8)
        }
    },
    [Map.MOONSTONE] = {
        default = {
            img = Map:getTile(2, 7)
        }
    },
    [Map.SAND] = {
        default = {
            img = Map:getTile(3,2)
        }
    },
    [Map.BLUE_ROCK] = {
        default = {
            img = Map:getTile(1,5),
            canFlip = true,
            canRotate = true
        }
    },
    [Map.PLATFORM] = {
        default = {
            img = Map:getTile(1,8),
            transparent = true,
            canFlip = true
        }
    },
    [Map.BKG] = {
        default = {
            img = Map:getTile(2, 5)
        }
    }
}

Map.backgroundImages = {
    [Map.BKG] = Map:getTile(2, 5),
    [Map.BKG2] = Map:getTile(2, 4),
    [Map.BKG3] = Map:getTile(2, 3),
    [Map.BKG4] = Map:getTile(2, 2),
    [Map.BKG5] = Map:getTile(2, 1)
}

--[[
Map.BKG = Map.nextType()

Map.BKG4 = Map.nextType()
Map.BKG5 = Map.nextType()
Map.BKG2 = Map.nextType()
Map.BKG3 = Map.nextType()

]]

function Map:getTileInfo(tile, gx, gy)
    math.randomseed(gx * gy + gx + gy)

    local oleft = self:gridValue(gx - 1, gy)
    local oright = self:gridValue(gx + 1, gy)
    local otop = self:gridValue(gx, gy - 1)
    local obot = self:gridValue(gx, gy + 1)
    
    possibilities = {}
    for index, tileInfo in ipairs(self.tileMap[tile.val]) do
        for flipped = 0,1 do
            if flipped == 0 or tileInfo.canFlip then
                -- on the next iteration of this loop, we still want the old relative values
                local left, right, top, bot = oleft, oright, otop, obot
                if flipped == 1 then
                    left, right = oright, oleft
                end
                for r = 0, 3 do
                    if r == 0 or tileInfo.canRotate then
                        if  ((not tileInfo.left) or left == tileInfo.left) and
                            ((not tileInfo.right) or right == tileInfo.right) and
                            ((not tileInfo.top) or top == tileInfo.top) and
                            ((not tileInfo.bot) or bot == tileInfo.bot) and
                            ((not tileInfo.notleft) or left ~= tileInfo.notleft) and
                            ((not tileInfo.notright) or right ~= tileInfo.notright) and
                            ((not tileInfo.nottop) or top ~= tileInfo.nottop) and
                            ((not tileInfo.notbot) or bot ~= tileInfo.notbot) then
                            table.insert(possibilities, {img = tileInfo.img, flipped = (flipped == 1), rotation = r * math.pi/2, transparent = tileInfo.transparent})
                        end
                        right, bot, left, top = bot, left, top, right
                    end
                end
            end
        end
    end
    if #possibilities == 0 then
        tileInfo = self.tileMap[tile.val].default
        tile.flipped = (tileInfo.canFlip and math.random(0, 1) == 0)
        tile.rotation = tileInfo.canRotate and (math.pi * math.random(0,3)/2) or 0
        tile.img = tileInfo.img
        tile.transparent = tileInfo.transparent
    else
        local possibility = possibilities[math.random(1, #possibilities)]
        tile.flipped = possibility.flipped
        tile.rotation = possibility.rotation
        tile.img = possibility.img
        tile.transparent = possibility.transparent
    end
end
