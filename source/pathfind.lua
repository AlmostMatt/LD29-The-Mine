require("map")

MOVE_TIME = math.floor(1000 * Map.unit / MAX_SPEED) -- the time required to move a single tile
print("Move time is " .. MOVE_TIME)
--[[
map is an object.
it has unit, x1, y1, x2, y2, and the ability to extend it's bounds

surface[x] is ground level
tiles[x][y] is Tile {val=Map.BKG, debugVal=0, reachable=false, illuminated=false}

this file adds methods to the map object
]]

--[[
Some existing map methods

function Map:isWall(tileType)

function Map:isBKG(tileType)

function Map:isPlatform(tileType)

function Map:gridCoordinate(p)
    return math.floor(p[1]/self.unit), math.floor(p[2]/self.unit)

function Map:gameCoordinate(gx, gy)
    return P((gx + 0.5) * self.unit, (gy + 0.5) * self.unit)

function Map:getTile(p)
    local gx, gy = self:gridCoordinate(p)
    return self:gridValue(gx, gy)

function Map:gridValue(gx, gy)
    if gx < self.x1 or gx > self.x2 or gy < self.y1 or gy > self.y2 then
        self:extendMap(gx, gy)
    end
    tile = self.tiles[gx][gy]
    return tile.val
]]

-- Memoize the size of object types (in tiles)
-- assuming objects that have custom sizes will also have custom types
Map.objSizes = {}
function Map:sizeOf(object)
    local t = object.t
    if not self.objSizes[t] then
        local size = object.size
        local w = math.ceil(size[1]/self.unit)
        local h = math.ceil(size[2]/self.unit)
        self.objSizes[t] = P(w, h)
    end
    return self.objSizes[t]
end

-- dest is a point
function Map:findPath(object, dest)
    local t1 = love.timer.getTime()
    local tSize = self:sizeOf(object)
    
    -- for now, do basic A*, ignoring the fact the the game has platformer mechanics and that the object has a size
    local path = nil
	
	local sx, sy = self:gridCoordinate(object:center())
	local fx, fy = self:gridCoordinate(dest)
    local u = self.unit
    sx = self:minmax(sx, self.x1, self.x2)
    sy = self:minmax(sy, self.y1, self.y2)
    fx = self:minmax(fx, self.x1, self.x2)
    fy = self:minmax(fy, self.y1, self.y2)
    
	local open = {{sx,sy}}
	local nodes = {}
	local closed={}
	for x = self.x1,self.x2 do closed[x]={} nodes[x]={} end
    local node = {}
    node.f=u * self:manhattan(sx,sy,fx,fy)
    node.g = 0
    node.h = node.f
	nodes[sx][sy] = node
	
    --find reachable tile nearest the destination
    --[[
	if (not self:containsTile(fx, fy)) or self.tiles[fx][fy].region ~= self.tiles[sx][sy].region then
		local x,y = fx,fy
		local done = false
		for n = 1,18 do
            -- check increasingly large diamond shapes
            for i = 1,n do
                love.graphics.setColor(0,0,  25 * n, 128)
                local x, y = fx -n + i, fy + i
                love.graphics.circle("line", (x+0.5) * self.unit, (y+0.5)*self.unit, self.unit/2)
                if self:containsTile(x, y) and self.tiles[x][y].region == self.tiles[sx][sy].region then
                    fx, fy = x, y
                    done = true
                    break
                end
                x, y = fx + i, fy + n - i
                love.graphics.circle("line", (x+0.5) * self.unit, (y+0.5)*self.unit, self.unit/2)
                if self:containsTile(x, y) and self.tiles[x][y].region == self.tiles[sx][sy].region then
                    fx, fy = x, y
                    done = true
                    break
                end
                x, y = fx + n - i, fy - i
                love.graphics.circle("line", (x+0.5) * self.unit, (y+0.5)*self.unit, self.unit/2)
                if self:containsTile(x, y) and self.tiles[x][y].region == self.tiles[sx][sy].region then
                    fx, fy = x, y
                    done = true
                    break
                end
                x, y = fx - i, fy - n + i
                love.graphics.circle("line", (x+0.5) * self.unit, (y+0.5)*self.unit, self.unit/2)
                if self:containsTile(x, y) and self.tiles[x][y].region == self.tiles[sx][sy].region then
                    fx, fy = x, y
                    done = true
                    break
                end
            end
            if done then break end
		end
        if not done then
            local t2 = love.timer.getTime()
            pathingTime = pathingTime + t2 - t1
            return path
        end
	end
    ]]
    
    --if the "time to reach" is large, only return a partial path (the path to the tile with the best expected cost)
	
    -- #open apparently takes log time.
    local numopen = 1
	while numopen > 0 and not path do
		local best = 1
		local x,y = unpack(open[1])
		local besth = nodes[x][y].h
		for i = 2,numopen do
			x,y = unpack(open[i])
			local h = nodes[x][y].h
			if h < besth then
				best = i
				besth = h
			end
		end
		
		local x,y = unpack(open[best])
        love.graphics.setColor(128,0,0,128)
        love.graphics.circle("line", (x+0.5) * self.unit, (y+0.5)*self.unit, self.unit/2)
        for _, tile in ipairs(self:getNeighbors(x, y, tSize)) do
            local nx, ny = tile[1], tile[2]
            local movecost = tile[3]
            if closed[nx] and not closed[nx][ny] then
                if not nodes[nx][ny] then
                    numopen = numopen + 1
                    table.insert(open,{nx,ny})
                    if nx==fx and ny==fy then
                        path={{fx,fy}}
                    end
                    local node = {}
                    node.par = {x,y}
                    node.f = u * self:manhattan(x,y,fx,fy)
                    node.g = nodes[x][y].g + movecost
                    node.h = node.f + node.g
                    nodes[nx][ny] = node
                elseif nodes[nx][ny].g > nodes[x][y].g + movecost then
                    nodes[nx][ny].par = {x,y}
                    nodes[nx][ny].g = nodes[x][y].g + movecost
                    nodes[nx][ny].h = nodes[nx][ny].f + nodes[nx][ny].g
                end
            end
		end
		table.remove(open, best)
        numopen = numopen - 1
		closed[x][y]=true
	end
	
	--found a path
	if path then
		--work backwards from the end to make the path
		while true do
			local x,y = unpack(path[1])
			local p = nodes[x][y].par
			if p then table.insert(path,1,p)
			else break end
		end
        -- remove the "start" from the path
		if #path > 1 then table.remove(path, 1) end
		--convert back to game coordinates, not tiles
		for i =1,#path-1 do
			path[i][1] = (path[i][1] + 0.5) * u
			path[i][2] = (path[i][2] + 0.5) * u
            
            love.graphics.setColor(0,128,0, 128)
            love.graphics.circle("fill", path[i][1], path[i][2], self.unit/2)
            love.graphics.setColor(0,64,0, 255)
            love.graphics.circle("line", path[i][1], path[i][2], self.unit/2)
		end
		path[#path] = dest
        --simplify path by taking diagonals for long sections
	end
	
    local t2 = love.timer.getTime()
    pathingTime = pathingTime + t2 - t1
	return path
end


-- returns nodes with relevant edge costs
function Map:getNeighbors(tx, ty, tSize)
    -- ideally this uses precomputed jump/fall trajectories
    -- to say that a tile up 6 and over 1 is reachable by jumping (max_jump) and accelerating after n tiles
    -- and some trajectories are only considered if the others result in a collision (jump accel_6 is only checked if jump accel_5 hits a wall, or if there is a platform up 6 and over 1)
    local neighbors = {}
    for ox=-1,1 do
		for oy=-1,1 do
            if (ox ~= oy) and (ox == 0 or oy == 0) then -- skip diagonals
                local x,y = tx + ox, ty + oy
                if x >= self.x1 and x <= self.x2 and y >= self.y1 + tSize[2] and y <= self.y2 then
                    -- the map may have bee nresized just now
                    -- if !closed 
                    --for x = self.x1,self.x2 do closed[x]={} nodes[x]={} end
                    local timeCost = MOVE_TIME
                    if ox ~= 0 then
                        for otherY = y, y - tSize[2] + 1, -1 do
                            local tileType = self:gridValue(x, otherY)
                            if self:isWall(tileType) then
                                timeCost = timeCost + math.floor(1000 * Map.digTime[tileType]/DIG_SPEED)
                            end
                        end
                    else
                        for otherX = x, x + tSize[1] - 1 do
                            local tileType = self:gridValue(otherX, y)
                            if self:isWall(tileType) then
                                timeCost = timeCost + Map.digTime[tileType]/DIG_SPEED
                            end
                        end
                    end
                    --local tileType = self:gridValue(x, y)
                    --if not self:isWall(tileType) then
                    table.insert(neighbors, {x, y, timeCost})
                    --end
                end
            end
        end
    end
    return neighbors
end

function Map:raycastPoints(p1, p2)
    --local x1, y1 = self:gridCoordinate(p1)
    --local x2, y2 = self:gridCoordinate(p2)
    local x1, y1 = p1[1], p1[2]
    local x2, y2 = p2[1], p2[2]
    local hitWall, hitX, hitY = self:raycast(x1, y1, x2, y2)
    -- this could factor in the direction of the ray to determine the side of the wall
    local hitP = self:gameCoordinate(hitX, hitY)
    love.graphics.setColor(255,0,0)
    love.graphics.line(p1[1], p1[2], hitP[1], hitP[2])
    return hitWall
end

function Map:manhattan(x1,y1,x2,y2)
	return math.abs(x2-x1) + math.abs(y2-y1)
end

function Map:minmax(v,minv,maxv)
	return math.max(math.min(v,maxv),minv)
end

function Map:raycast(x1,y1,x2,y2)
	local dx = (x2 < x1) and -1 or 1
	local dy = (y2 < y1) and -1 or 1
    local gu = self.unit
	for x = math.ceil(x1/gu),math.ceil(x2/gu),dx do
		local yin,yout
		if x == math.ceil(x1/gu) then
			yin = math.ceil(y1/gu)
		elseif dx==1 then
			yin = math.ceil( ((gu*(x-1)-x1)/(x2-x1) * (y2-y1) + y1 )/gu )
		else
			yin = math.ceil( ((gu*(x)-x1)/(x2-x1) * (y2-y1) + y1 )/gu )
		end
		if x == math.ceil(x2/gu) then
			yout = math.ceil(y2/gu)
		elseif dx==1 then
			yout = math.ceil( ((gu*(x)-x1)/(x2-x1) * (y2-y1) + y1 )/gu )
		else
			yout = math.ceil( ((gu*(x-1)-x1)/(x2-x1) * (y2-y1) + y1 )/gu )
		end
		for y = yin,yout,dy do
            love.graphics.setColor(0,0,128, 128)
            local p = self:gameCoordinate(x,y)
            --love.graphics.circle("fill", p[1], p[2], self.unit/2)
            local tileType = self:gridValue(x, y)
			if self:isWall(tileType) then
				return false, x, y
			end
		end
	end
	return true, math.floor(x2/gu), math.floor(y2/gu)
end