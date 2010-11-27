require("giftWrap")
require("luaUnit")

test("simple lower point test",
function()
	local points = { Vec3(0,0,0), Vec3(0,0,1), Vec3(0,2,1) }
	return lower( points ) == 1
end
)

test("lower point with tie test",
function()
	local points = { Vec3(0,1,0), Vec3(0,0,0), Vec3(0,2,1) }
	return lower( points ) == 2
end
)

testAll()
