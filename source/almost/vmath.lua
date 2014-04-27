require("almost/listf")

--object types: constructors
TYPES = {
    POINT = "P",
    SEGMENT = "S",
    RAY = "R",
    LINE = "L",
    MATRIX = "M",
    VECTOR = "V"}
--shape, edges, matrix?

function to_s(obj)
    if type(obj) == "table" then
        if obj.t == TYPES.MATRIX then
            return "{ (" .. (obj.t or "nil" ) .. ") \n  ".. table.concat(map(to_s,Mtranspose(obj)),"\n  ") .. " }"
        elseif obj.t == TYPES.VECTOR then
            return "| ".. table.concat(map(to_s,obj)," ") .. " |"
        else
            return "{ (" .. (obj.t or "nil" ) .. ") ".. table.concat(map(to_s,obj),",") .. " }"
        end
    else
        return obj
    end
end

function copy(obj)
    if type(obj) == "table" then
        return map(copy,obj)
    else
        return obj
    end
end

--CONSTRUCTORS
function P(x,y) --point (vector)
    return {x,y,t=TYPES.POINT}
end
function R(A,B) --ray (extends forwards)
    return {A,B,t=TYPES.RAY}
end
function L(A,B) --line (extends both sides)
    return {A,B,t=TYPES.LINE}
end
function S(A,B) --segment (two points)
    return {A,B,t=TYPES.SEGMENT}
end
function M(v1,v2,v3) --matrix (three vectors)
    return {v1,v2,v3,t=TYPES.MATRIX}
end
function V(x,y,z) --vector (column of a matrix)
    return {x,y,z,t=TYPES.VECTOR}
end
--all vectors are given as x,yend ex 1,2end


--dot product of A and B
function Vdot(a, b)
    return a[1] * b[1] + a[2] * b[2]
end
--magnitude squared of A
function Vdd(a)
    if a.t == TYPES.VECTOR then
        return a[1] * a[1] + a[2] * a[2] + a[3]*b[3]
    end
    return a[1] * a[1] + a[2] * a[2]
end
--magnitude of A
function Vmagn(a) 
    return math.sqrt(Vdd(a))
end
--scalar multiple n of vector A
function Vmult(n, a) 
    return P(a[1] * n, a[2] * n)
end
--projection of A onto B
function Vproj(a, b) 
    return Vmult(Vdot(a, b) / Vdd(b), b)
end
--a normal vector of OA
function Vnorm(a)
    return P(a[2], -a[1])
end
--Addition of vectors A+B
function Vadd(a, b) 
    return P(a[1] + b[1], a[2] + b[2])
end
--Subtraction of vectors A-B
function Vsub(a, b) 
    return P(a[1] - b[1], a[2] - b[2])
end
--Distance between vectors A-B
function Vdist(a, b) 
    return Vmagn(Vsub(a,b))
end
--returns a multiple of a that has magnitude n
function Vscale(a, n) 
    local mag = Vmagn(a)
    if (mag == 0) then return P(n,0)--a
    else return Vmult(n / mag, a) end
end
--rotate a point by theta degrees input point costheta sintheta
function Vrotate(a, cosa, sina) 
    return P(a[1] * cosa - a[2] * sina, a[2] * cosa + a[1] * sina)
end

function Vavg(p1,...)
    local av = p1
    for i,p in ipairs(arg) do
        av = Vadd(av,p)
    end
	return Vmult(1/(1+#arg),av)
end

function Vsamedir(a,b)
    return Vdot(a,b) > 0
end

function unitV(a)
    return Vscale(a,1)
end

--rename
function Vvectorvector(A, B) 
    --print(to_s(A))
    --print(to_s(B))
    local a = flatten({A[1],Vsub(A[2],A[1])})
    local b = flatten({B[1],Vsub(B[2],B[1])})
    --x y dx dy for each, both continue in both directions
    if (a[3] * b[4] == a[4] * b[3]) then return nil end
    local s = (-a[1] * b[4] + a[2] * b[3] - b[2] * b[3] + b[1] * b[4]) / (a[3] * b[4] - a[4] * b[3])
    local t
    if (b[4] == 0) then
        t = (a[1] + s * a[3] - b[1]) / b[3]
    else
        t  = (a[2] + s * a[4] - b[2]) / b[4]
    end
    return {s, t}
end

function Vxyof(theta) 
    return P(math.cos(theta), math.sin(theta))
end
function Vangleof(A) 
    return math.atan2(A[2],A[1])
end

function Ssize(A)
    return Vdd(Vsub(A[2],A[1]))
end

-- for a pair of line/segment/ray do they intersect, and if so where?
function intersection(A,B)
    local st = Vvectorvector(A, B)
    if (not st 
        or (st[1] <= 0 and A.t ~= TYPES.LINE)
        or (st[2] <= 0 and B.t ~= TYPES.LINE)
        or (st[2] > 1 and B.t == TYPES.SEGMENT)
        or (st[1] > 1 and A.t == TYPES.SEGMENT)) then
        return false
    else
        return Vadd(A[1],Vmult(st[1],Vsub(A[2],A[1]))) --p + s * delta
    end
end

-- for a point and a line/segment/ray, what is the closest point on the line to the point
function pointclosest(P,E)
    local A,B = E[1], E[2]
    if samepoint(E[1],E[2]) then return A end -- zero division case later
    local r = Vdot(Vsub(P, A), Vsub(B, A)) / Vdd(Vsub(B, A))
    if (r < 0 and E.t ~= TYPES.LINE) then return A
    elseif (r > 1 and E.t == TYPES.SEGMENT) then return B
    else return Vadd(A,Vmult(r,Vsub(B,A))) end
end

--for a point and a entity, how far away are they?
function pointdistance(P,Q)
    if Q.t == TYPES.POINT then
        return Vdd(Vsub(Q,P))
    else
        local A,B = Q[1],Q[2]
        if samepoint(A,B) then return Vdd(Vsub(P, A)) end -- zero division case later
        local r = Vdot(Vsub(P, A), Vsub(B, A)) / Vdd(Vsub(B, A))
        if (r < 0 and Q.t ~= TYPES.LINE) then return Vdd(Vsub(P, A))
        elseif (r > 1 and Q.t == TYPES.SEGMENT) then return Vdd(Vsub(P, B))
        else return math.pow(((A[1] - B[1])*(B[2] - P[2])-(B[1] - P[1])*(A[2] - B[2])),2) / Vdd(Vsub(A, B)) end
    end
end

-- for two entities, what is the closest point on each to the other (returns {closest point on p to q, closest point on q to p})
-- returns a line segment
function closest(P,Q)
    if P.t == TYPES.POINT then
        if Q.t == TYPES.POINT then
            return S(P,Q)
        else
            return S(P,pointclosest(P,Q))
        end
    elseif Q.t == TYPES.POINT then
        return S(pointclosest(Q,P),Q)
    else
        --two line/edge/segments
        local I = intersection(P,Q)
        if I then return S(I,I) end
        --if no intersection, mindist must contain one of the ends of the rays/line segments
        local sets = {}
        if (P.t ~= TYPES.LINE) then
            table.insert(sets,{P[1],Q})
        end
        if (Q.t ~= TYPES.LINE) then
            table.insert(sets,{P,Q[1]})
        end
        if (P.t == TYPES.SEGMENT) then
            table.insert(sets,{P[2],Q})
        end
        if (Q.t == TYPES.SEGMENT) then
            table.insert(sets,{P,Q[2]})
        end
        --sets is pairs of points and segments/rays/lines
        sets = map(function(s) return closest(s[1],s[2]) end, sets) --terminating recursion because either s[1] or s[2] is a point
        --sets is min dist line segment for each pair
        sets = map(function(s) return {d=Ssize(s),e=s} end, sets) --
        -- sets is min dist line segment with a "size" value set to d
        local result = fold(function(a,b) return (a.d < b.d) and a or b end,sets)
        --result is min dist line segment of smallest size
        return result.e
    end
end

-- for two entities, how far apart are they?
function distance(P,Q)
    if P.t == TYPES.POINT then
        return pointdistance(P,Q)
    elseif Q.t == TYPES.POINT then
        return pointdistance(Q,P)
    else
        return Ssize(closest(P,Q))
    end
end

--cross product
function Vproduct(A,B)
    local c1 = a[2] * b[3] - a[3] * b[2]
    local c2 = a[3] * b[1] - a[1] * b[3]
    local c3 = a[1] * b[2] - a[2] * b[1]
    return V(c1,c2,c3)
end

--affine matrix transformations

function Mmult(m,p) --matrix product M V to transform a vector, [[1,0],[0,1]] is identity matrix M should be 2x2
	local v = V(p[1],p[2],1) --affine vector
    return P(m[1][1]*v[1] + m[2][1]*v[2] + m[3][1]*v[3],m[1][2]*v[1] + m[2][2]*v[2] + m[3][2]*v[3])
end

function Midentity()
	return M(V(1,0,0),V(0,1,0),V(0,0,1))
end

function Mtranspose(A)
	local At = M(V(),V(),V()) --assuming 3x3
    for i=1,#A do
        for j=1, #A[1] do
            At[j][i] = A[i][j]
        end
    end
    return At
end

function Mproduct(M1,M2)
	local A = M(V(),V(),V()) --assuming 3x3
    for i,row in ipairs(Mtranspose(M1)) do
        for j,column in ipairs(M2) do
            A[j][i] = fold(
                function(a,b) return a+b end, 
                map(
                    function(a,b) return a*b end, 
                    row, 
                    column
                )
            )
        end        
    end
    return A
end

function Mtranslate(x,y)
    return M(V(1,0,0),V(0,1,0),V(x,y,1))
end
--need to thin jabout set of vectors and set of rows
--clockwise vs cclockwise
function Mrotate(theta)
    local cosa = math.cos(theta)
    local sina = math.sin(theta)
    return M(V(cosa,sina,0),V(-sina,cosa,0),V(0,0,1))
end

function Mscale(s)
    return M(V(s,0,0),V(0,s,0),V(0,0,1))
end

function Mshear(sx,sy) --might have sx and sy backwards
    return M(V(1,sy,0),V(sx,1,0),V(0,0,1))
end

function Mreflect(edge)
    local A,B = edge[1],Vsub(edge[2],edge[1])
    local T1 = Mtranslate(A[1],A[2])
    local T2 = Mtranslate(-A[1],-A[2])
    local R = M(
        V(B[1]*B[1] - B[2]*B[2],2*B[1]*B[2],0),
        V(2*B[1]*B[2],B[2]*B[2] - B[1]*B[1],0),
        V(0,0,1))
    R = Mproduct(Mscale(1/Vdd(B)),R)
    --translate, reflect, inverse translate
    return Mproduct(T1,Mproduct(R,T2))
end

function Mproject(edge)
    local A,B = edge[1],Vsub(edge[2],edge[1])
    local T1 = Mtranslate(A[1],A[2])
    local T2 = Mtranslate(-A[1],-A[2])
    local P = M(
        V(B[1]*B[1],B[1]*B[2],0),
        V(B[1]*B[2],B[2]*B[2],0),
        V(0,0,1))
    P = Mproduct(Mscale(1/Vdd(B)),P)
    --translate, reflect, inverse translate
    return Mproduct(T1,Mproduct(P,T2))
end

function Minvert(A)
    --assuming 3x3
    --http://en.wikipedia.org/wiki/Invertible_matrix#Inversion_of_3.C3.973_matrices 
    local a,b,c,d,e,f,g,h,k = A[1][1],A[2][1],A[3][1],A[1][2],A[2][2],A[3][2],A[1][3],A[2][3],A[3][3]
    local A,B,C = e*k-f*h, f*g-k*d, d*h-e*g
    local D,E,F = c*h - b*k, a*k-c*g, g*b - a*h
    local G,H,K = b*f - c*e, c*d-a*f, a*e - b*d
    local det = 1 / (a*(A) + b*(B) + c*(C))
    local At = M(V(A,B,C),
        V(D,E,F),
        V(G,H,K))
    --the test Ainverse x A returned some rounding errors away from the identity matrix,
    return Mproduct( M(V(det,0,0),V(0,det,0),V(0,0,det)), At)
end

--http://en.wikipedia.org/wiki/Transformation_matrix#Reflection

--generalize product to be cross product, matrix product, multiplaction, scalar mult etc
--generalize matrix functions, points, and vectors to be NxM maxtrices and vectors of size N


function randompoint(p,r)
    local angle = math.random()*6.28
    local d = math.random()*r
    return P(p[1] + math.cos(angle)*d,p[2]+math.sin(angle)*d)
end

-- color manipulation as a vector

function colormult(s,col)
    new = {}
    for i=1,3 do
        new[i] = s * col[i] 
    end
    new[4] = col[4]
    return new
end

function coloradd(col1,col2)
    new = {}
    for i=1,#col1 do
        new[i] = col1[i] + col2[i] 
    end
    return new
end