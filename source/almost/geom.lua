--point is {x,y}
--polygon is {point,point,...}
--edge is {point,point}
--ray is {point, delta} where delta is a point ?
--segment is same as edge
--http://en.wikipedia.org/wiki/Polygon_triangulation in order to draw a concave polygon

--reflection as composition of translate, rotate, scale/shear, inverse rotate, inverse translate?
--stencil polygon as a mask
-- and vmath to transform positions that are possibly in mask region

require("almost/listf")

--[[ this is actually two different incomplete attempts at the function, priority changed
--make this a vmath extension of intersection?
function overlap(A,B) --assuming simple shapes like triangles, this isn't terribly efficient
	--each shape is a list of points
    --there will only be one resulting shape
	local C = {}
    local alongA = false
	local eA = edges(A)
	local eB = edges(B)
	local onA,onB = true,false
	local i,j = 1,1
	local lastpoint = A[1]
	local nextindex = 2
	local start = nil
	if not inpolygon(lastpoint,B) then
		while not start do
			local e1 = eA[i]
			local x = nil
			for j,e2 in ipairs(eB) do
				x = intersection(e1,e2)
				if x then
					e1 = S(e1[1],x)
				end
			end
			if x then
				start = x
				lastpoint = x
				nextindex = i + 1
			else
				i = i + 1
			end
		end
	else
		start = lastpoint
		nextindex = i + 1
	end
	--i > #A case?
	--no intersections and not in B case?
	table.insert(C,copy(a))
	while true do
		local x = nil
		if onA then
			for _,e2 in ipairs(eB) do
				local x = intersection(e1,e2)
		elseif onB then
			for _,e1 in ipairs(eA) do
				local x = intersection(e1,e2)
		end
		--set onb, lastpoint, nextindex, check for closed ( is start /startindex )
	end
        alongA = true
		table.insert(C,copy(a))
		local i,j = 1,1
        while i <= #eA do --go around A until reach last edge of A
            if alongA then
                local e1 = eA[i]
                local x = false
                local xi = false
                for bi,e2 in ipairs(eB) do
                    x = intersection(e1,e2)
                    if x then
                        e1 = S(e1[1],x)
                        xi = bi
                    end
                end
				if x then
                    table.insert(C,x)
                    j = bi
                    alongA = false
                else
                    i = i + 1
                end
            end
        for i,e in ipairs(eA) do
				if x then
					table.insert(C,x)
					--change flow (move around B now)
					--and stop if passing first inpoint
				end
			end
		end
	end
	if #C > 0 then
		return C
	else
		return nil
	end
end]]

function inpolygon(p,points)
    local count = 0
    for i,e in ipairs(edges(points)) do
        if intersection(R(p,Vadd(p,P(1,0.001))),e) then -- the ray is slightly offset from horizontal to make it unlikely that the ray will pass exactly through a point
            count=count+1
        end
    end
    return count%2 == 1
end

--list of segments
function edges(points) --do this with as_pairs, map, concat and foldr
    e = {S(points[#points],points[1])}
    for i = 1, #points-1 do
        table.insert(e,S(points[i],points[i+1]))
    end
    return e
end

function normalof(edge)
    return unitV(Vnorm(Vsub(edge[2],edge[1])))
end

function midpoint(edge)
    return Vavg(edge[1],edge[2])
end

function flatten(points) --do this with map, concat, and folder. or look for built in flatten function
    if #points == 0 or type(points[1]) == "number" then
        return points
    else
        local new = {}
        for i,pair in ipairs(points) do
            table.insert(new,pair[1])
            table.insert(new,pair[2])
        end
        return new
    end
end

function expand(flatpoints) --{a,b,c,d} to {{a,b},{c,d}}
    if #points == 0 or type(points[1]) == "table" then
        return points
    else
        local new = {}
        for i = 1,#points,2 do
            table.insert(new,{points[i],points[i+1]})
        end
        return new
    end
end

function polyfill(points)
--    love.graphics.polygon("fill",flatten(points))
    for i,t in ipairs(triangles(points)) do
        --love.graphics.setColor(0,0,0,64)
        love.graphics.polygon("fill",flatten(t))
        --love.graphics.polygon("line",flatten(t))
    end
end

function triangles(polygon)
    if #polygon < 3 then
        return {}
    elseif #polygon == 3 then
        return {polygon}
    else
        --an "ear" is a set of verts ABC such that AB and BC are edges and AC is completely inside the polygon
        local ear
        for i = 1,#polygon do
            if i == #polygon then
                ear = {i,1,2}
            elseif i+1 == #polygon then
                ear = {i,i+1,1}
            else
                ear = {i,i+1,i+2}
            end
            if isear(polygon,ear) then
                -- every poly with >3 edges and no "holes" has an ear
                break
            end
        end
        --if the ear is removed (v1 v2 A B C v3 v4 to v1 v2 A C v3 v4) then triangulize this shape with same algorith recursively, and ABC is a triangle
        local newtri = {polygon[ear[1]],polygon[ear[2]],polygon[ear[3]]}
        local newpoly = copy(polygon)
        table.remove(newpoly,ear[2])
        local tris = triangles(newpoly)
        table.insert(tris,newtri)
        return tris
    end
end

function isear(polygon, ear)
    -- checking points ABC
    local A = polygon[ear[1]]
    local B = polygon[ear[2]]
    local C = polygon[ear[3]]
    --if average(A,C) is in polygon and AC does not intersect any edges that do not contain A or C then ABC is an ear. 
    if not inpolygon(Vavg(A,C),polygon) then
        return false
    end
    local edge = S(A,C)
    for i,e in ipairs(edges(polygon)) do
        if not commonpoint(edge,e) then
            --check for intersection
            if intersection(edge,e) then
                return false
            end
        end
    end
    local lw = love.graphics.getLineWidth()
    local r,g,b,a = love.graphics.getColor()
    if (DEBUG) then
        love.graphics.setLineWidth(1)
        love.graphics.setColor(255,0,0)
        love.graphics.line(A[1],A[2],C[1],C[2])
        love.graphics.setColor(r,g,b,a)
        love.graphics.setLineWidth(3)
    end
    return true
end

function polyline(points, closed)
    if closed then
        table.insert(points, points[1])
    end
    for i = 1,#points-1 do
        local e = {{points[i][1],points[i][2]},{points[i+1][1],points[i+1][2]}}
        love.graphics.setColor(0,0,0)
        love.graphics.line(flatten(e))
        if DEBUG then
            love.graphics.setColor(0,255,0)
            love.graphics.line(flatten({ midpoint(e), Vadd(midpoint(e),Vmult(20,normalof(e))) }))
        end
    end
    if closed then
        table.remove(points)
    end
end

function samepoint(a,b) --check if two poitns are the same
    return a[1] == b[1] and a[2] == b[2]
end

function commonpoint(e1,e2) --check if two edges have one or more points in common
    return samepoint(e1[1],e2[1]) or samepoint(e1[1],e2[2]) or samepoint(e1[2],e2[1]) or samepoint(e1[2],e2[2])
end