
Vector = {}
Vector.__index = Vector
function Vector.new(xVal,yVal,zVal)
	local v = { x = xVal, y = yVal, z = zVal }
	setmetatable( v, Vector )
	return v
end


HalfEdge = {}

function HalfEdge.new( org, dest )
	local he = {}
	he.
end

