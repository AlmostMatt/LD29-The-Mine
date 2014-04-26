sqrt2 = math.sqrt(2)

unit = 32
skew = sqrt2/2

--local shift = Mtranslate(width/2,height/2)
local shear = M(V(1,skew,0),V(1,-skew,0),V(0,0,1))
isoM = shear
isoMI = Minvert(isoM)

function iso(p)
    return Mmult(isoM,p)
end
function cartesian(p)
    return Mmult(isoMI,p)
end

function Iline(p1,p2)
    local a,b = iso(p1),iso(p2)
    love.graphics.line(a[1],a[2],b[1],b[2])
end

function Icircle(mode,p,r)
    love.graphics.push()
    love.graphics.scale(1,-skew)
    love.graphics.shear(1,-1)
    love.graphics.circle(mode,p[1],p[2],r,20)
    love.graphics.pop()
end

function Irectangle(mode,p,v1,v2)
    local a = iso(p)
    local b = iso(Vadd(p,v1))
    local c = iso(Vadd(Vadd(p,v1),v2))
    local d = iso(Vadd(p,v2))
    love.graphics.polygon(mode,a[1],a[2],b[1],b[2],c[1],c[2],d[1],d[2])
end

function Itriangle(mode,p,v1,v2)
    local a = iso(p,z)
    local b = iso(Vadd(p,v1))
    local c = iso(Vadd(p,v2))
    love.graphics.polygon(mode,a[1],a[2],b[1],b[2],c[1],c[2])
end

function Ivectors()
    --world vectors
    local o = P(0,0)
    local r = 40
    love.graphics.setColor(255,0,0)
    Iline(o,P(r,0))
    love.graphics.setColor(0,255,0)
    Iline(o,P(0,r))
    r = 20*unit
    love.graphics.setColor(255,0,0,64)
    Iline(P(-r,0),P(r,0))
    love.graphics.setColor(0,255,0,64)
    Iline(P(0,-r),P(0,r))
end

function Ipoint(p)
    local p = iso(p)
    love.graphics.point(p[1],p[2])
end