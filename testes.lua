require("giftWrap")
require("luaUnit")

test("add vec3 test",
function()
	local a = newVec3(1,2,3)
	local b = newVec3(1,1,4)
	local c = a + b
	return c.x == 2 and c.y == 3 and c.z == 7
end
)

test("subtrac vec3 test",
function()
	local a = newVec3(1,2,3)
	local b = newVec3(1,1,4)
	local c = a - b
	return c.x == 0 and c.y == 1 and c.z == -1
end
)

test("cross vec3 test",
function()
	local y = newVec3(0,1,0)
	local x = newVec3(1,0,0)
	local v = x:cross(y)
	return v.x == 0 and v.y == 0 and v.z == 1
end
)


test("axis aligned normalize test",
function()
	local a = newVec3(3,0,0)
	a:normalize()
	return a.x == 1 and a.y == 0 and a.z == 0
end
)

test("length 1 normalize test",
function()
	local a = newVec3(1,2,3)
	a:normalize()
	return a.x * a.x + a.y * a.y + a.z * a.z == 1
end
)

test("project over axis test",
function()
	local a = newVec3(1,1,0)
	local x = newVec3(1,0,0)
	local b = a:projectOver(x)
	return b.x == 1 and b.y == 0 and b.z == 0
end
)


test("simple lower point test",
function()
	local points = { newVec3(0,0,0), newVec3(0,0,1), newVec3(0,2,1) }
	return lower( points ) == 1
end
)

test("lower point with tie test",
function()
	local points = { newVec3(0,1,0), newVec3(0,0,0), newVec3(0,2,1) }
	return lower( points ) == 2
end
)

test("lower point bug case test",
function()
	local points = {
	newVec3( -0.58, -0.63, 0.94 ),
	newVec3( -0.56,  0.68, 0.87 ),
	newVec3( -0.11, -0.15, 0.09 ),
	newVec3( -0.53, -0.16, 0.25 ),
	newVec3(  0.28,  0.59, 1.13 ),
	newVec3(  0.55,  0.89, 0.31 ),
	newVec3(  0.30, -0.53, 1.38 ),
	newVec3(  0.72, -0.84, 0.95 ),
	newVec3( -0.87, -0.44, 0.94 ),
	newVec3(  0.28, -0.87, 0.75 )
	}

	return lower( points ) == 3
end
)


test("tetrahedron convex Hull test",
function()
	local points = { newVec3(0,0,0), newVec3(1,0,0), newVec3(0,1,0), newVec3(0,0,1) }
	local polys = getHullPolys( points )

	if #polys ~= 4 then return false end
	if #(polys[1]) ~= 3 then return false end
	if polys[1][1] ~= 1 then return false end
	if polys[1][2] ~= 4 then return false end
	if polys[1][3] ~= 3 then return false end
	return true
end
)



testAll()
