unit = 32 -- this can be changed by other files

skew = 1 --sort of like an angle. 0.7 is close to 45 degrees so it feels natural
zskew = -1
sqrt2 = math.sqrt(2)
skew = sqrt2/2

--local shift = Mtranslate(width/2,height/2)
local shear = M(V(1,skew,0),V(1,-skew,0),V(0,0,1))
orthoM = shear -- Mproduct(shift,shear) --just shear?
orthoMI = Minvert(orthoM)

function ortho(p,z)
    local p = Mmult(orthoM,p)
    return Vadd(p,P(0,zskew*z))
end
function cartesian(p,z)
    if not z then z = 0 end
    local p = Vsub(p,P(0,zskew*z))
    return Mmult(orthoMI,p)
end

function Oline(p1,z1,p2,z2)
    if not z2 then z2 = z1 end
    local a,b = ortho(p1,z1),ortho(p2,z2)
    love.graphics.line(a[1],a[2],b[1],b[2])
end

function Ocircle(mode,p,z,r)
    if not z then z = 0 end
    love.graphics.push()
--    love.graphics.translate(width/2,height/2)
    love.graphics.translate(0,zskew*z)
    love.graphics.scale(1,-skew)
    love.graphics.shear(1,-1)
    love.graphics.circle(mode,p[1],p[2],r,20)
    love.graphics.pop()
end

function Osemicircletop(mode,p,z,r)
    if not z then z = 0 end
    love.graphics.push()
--    love.graphics.translate(width/2,height/2)
    love.graphics.translate(0,zskew*z)
    love.graphics.scale(1,-skew)
    love.graphics.shear(1,-1)
    --rectangle containing the bottom half of the circle after the transformations to use as a stencil
    local v1,v2 = P(-4*r,-4*r),P(-4*r,4*r)
    local p1 = Vsub(p,Vmult(0.5,v1))
    local s = function() love.graphics.polygon("fill",
        flatten({p1,Vadd(p1,v1), Vadd(Vadd(p1,v1),v2), Vadd(p1,v2) })) end
    love.graphics.setStencil(s)
    --draw the portion of the circle that exists in the stenciled area
    love.graphics.circle(mode,p[1],p[2],r)
    love.graphics.setStencil()
    love.graphics.pop()
end

function Osemicirclebottom(mode,p,z,r)
    if not z then z = 0 end
    love.graphics.push()
--    love.graphics.translate(width/2,height/2)
    love.graphics.translate(0,zskew*z)
    love.graphics.scale(1,-skew)
    love.graphics.shear(1,-1)
    --rectangle containing the bottom half of the circle after the transformations to use as a stencil
    local v1,v2 = P(-4*r,-4*r),P(4*r,-4*r)
    local p1 = Vsub(p,Vmult(0.5,v1))
    local s = function() love.graphics.polygon("fill",
        flatten({p1,Vadd(p1,v1), Vadd(Vadd(p1,v1),v2), Vadd(p1,v2) })) end
    love.graphics.setStencil(s)
    --draw the portion of the circle that exists in the stenciled area
    love.graphics.circle(mode,p[1],p[2],r)
    love.graphics.setStencil()
    love.graphics.pop()
end

function Orectangle(mode,p,z,v1,v2)
    local a = ortho(p,z)
    local b = ortho(Vadd(p,v1),z+v1[3])
    local c = ortho(Vadd(Vadd(p,v1),v2),z+v1[3]+v2[3])
    local d = ortho(Vadd(p,v2),z+v2[3])
    love.graphics.polygon(mode,a[1],a[2],b[1],b[2],c[1],c[2],d[1],d[2])
end

function Ocone(mode, p, z, r, h)
    if mode == "fill" then
        Osemicirclebottom(mode,p,z,r)
        local vr = V(sqrt2*r/2,sqrt2*r/2,0)
        local vw = V(sqrt2*r,sqrt2*r,0)
        local vh = V(sqrt2*r/2,sqrt2*r/2,h)
        Otriangle(mode,Vsub(p,vr),z,vw,vh)
    elseif mode == "line" then
        Osemicirclebottom(mode,p,z,r)
        local vr = V(sqrt2*r/2,sqrt2*r/2,0)
        Oline(Vsub(p,vr),z,p,z+h)
        Oline(Vadd(p,vr),z,p,z+h)
    end
end

function Ocylinder(mode,p,z,r,h) --only works for flat v1 and v2, and only draws the front half
    if h < 0 then
        --invert
        Ocylinder(mode,Vadd(p,P(0,h)),z+h,r,-h)
    elseif mode == "fill" then
        --bottom
        Osemicirclebottom(mode,p,z,r)
        --middle
        local vr = V(sqrt2*r/2,sqrt2*r/2,0)
        local vw = V(sqrt2*r,sqrt2*r,0)
        local vh = V(0,0,h)
        Orectangle(mode,Vsub(p,vr),z,vw,vh)
        --top
        Osemicircletop(mode,p,z+h,r)
    elseif mode == "line" then
        --bottom
        Osemicirclebottom(mode,p,z,r)
        --middle
        local vr = V(sqrt2*r/2,sqrt2*r/2,0)
        Oline(Vsub(p,vr),z,Vsub(p,vr),z+h)
        Oline(Vadd(p,vr),z,Vadd(p,vr),z+h)
        --top
        Ocircle(mode,p,z+h,r)
    end
end
--doesnt use cross product of v1 and v2, but rather uses the 0,0,h vector for height and uses z as the base
function Oprism(mode,p,z,v1,v2,h) --only works for flat v1 and v2, and only draws the front half
    Oprismfront(mode,p,z,v1,v2,h)
    Orectangle(mode,p,z+h,v1,v2)
end
function Oprismtop(mode,p,z,v1,v2,h) --only works for flat v1 and v2, and only draws the front half
    Orectangle(mode,p,z+h,v1,v2)
end
function Oprismfront(mode,p,z,v1,v2,h) --only works for flat v1 and v2, and only draws the front half
    --need to determine which two sides are visible
    local a = ortho(p,z)
    local b = ortho(Vadd(p,v1),z+v1[3])
    local c = ortho(Vadd(Vadd(p,v1),v2),z+v1[3]+v2[3])
    local d = ortho(Vadd(p,v2),z+v2[3])
    --aka which of p, p+v1, p+v2, p+v1+v2 is lowest on screen (largest y)
    local vh = V(0,0,h)
    local newp = fold(
        function(p1,p2)
            return (p1[2] > p2[2] and p1) or p2
        end,
        {a,b,c,d})
    if samepoint(newp, a) then
        --side1
        Orectangle(mode,p,z,v1,vh)
        --side2
        Orectangle(mode,p,z,v2,vh)
    elseif samepoint(newp,b) then
        Oprismfront(mode,Vadd(p,v1), z+v1[3], V(-v1[1],-v1[2],-v1[3]), v2, h)
    elseif samepoint(newp,c) then
        Oprismfront(mode,Vadd(Vadd(p,v1),v2), z+v1[3]+v2[3], V(-v1[1],-v1[2],-v1[3]), V(-v2[1],-v2[2],-v2[3]), h)
    elseif samepoint(newp,d) then
        Oprismfront(mode,Vadd(p,v2), z+v2[3], v1, V(-v2[1],-v2[2],-v2[3]), h)
    end
end
function Oprismback(mode,p,z,v1,v2,h) --only works for flat v1 and v2, and only draws the front half
    --need to determine which two sides are visible
    local a = ortho(p,z)
    local b = ortho(Vadd(p,v1),z+v1[3])
    local c = ortho(Vadd(Vadd(p,v1),v2),z+v1[3]+v2[3])
    local d = ortho(Vadd(p,v2),z+v2[3])
    --aka which of p, p+v1, p+v2, p+v1+v2 is lowest on screen (largest y)
    local vh = V(0,0,h)
    local newp = fold(
        function(p1,p2)
            return (p1[2] < p2[2] and p1) or p2
        end,
        {a,b,c,d})
    if samepoint(newp, a) then
        --bottom
        Orectangle(mode,p,z,v1,v2)
        --side1
        Orectangle(mode,p,z,v1,vh)
        --side2
        Orectangle(mode,p,z,v2,vh)
    elseif samepoint(newp,b) then
        Oprismback(mode,Vadd(p,v1), z+v1[3], V(-v1[1],-v1[2],-v1[3]), v2, h)
    elseif samepoint(newp,c) then
        Oprismback(mode,Vadd(Vadd(p,v1),v2), z+v1[3]+v2[3], V(-v1[1],-v1[2],-v1[3]), V(-v2[1],-v2[2],-v2[3]), h)
    elseif samepoint(newp,d) then
        Oprismback(mode,Vadd(p,v2), z+v2[3], v1, V(-v2[1],-v2[2],-v2[3]), h)
    end
end
function Otriangle(mode,p,z,v1,v2)
    local a = ortho(p,z)
    local b = ortho(Vadd(p,v1),z+v1[3])
    local c = ortho(Vadd(p,v2),z+v2[3])
    love.graphics.polygon(mode,a[1],a[2],b[1],b[2],c[1],c[2])
end

function Ovectors()
    --world vectors
    local o = P(0,0)
    local r = 40
    love.graphics.setColor(255,0,0)
    Oline(o,0,P(r,0))
    love.graphics.setColor(0,255,0)
    Oline(o,0,P(0,r))
    love.graphics.setColor(0,0,255)
    Oline(o,0,P(0,0),r)
    r = 20*unit
    love.graphics.setColor(255,0,0,64)
    Oline(P(-r,0),0,P(r,0))
    love.graphics.setColor(0,255,0,64)
    Oline(P(0,-r),0,P(0,r))
    love.graphics.setColor(0,0,255,64)
    Oline(P(0,0),-r,P(0,0),r)
end

function Opoint(p,z)
    local p = ortho(p,z)
    love.graphics.point(p[1],p[2])
end