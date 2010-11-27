function Vec3( xVal, yVal, zVal )
	return { x = xVal, y = yVal, z = zVal }
end

Vec3 = {}
Vec3.__index = Vec3
Vec3.__add = function(self, other) return newVec3( self.x + other.x, self.y + other.y, self.z + other.z ) end
Vec3.__sub = function(self, other) return newVec3( self.x - other.x, self.y - other.y, self.z - other.z ) end
function Vec3.cross(self, v)
	return newVec3( self.y * v.z - self.z * v.y,
					self.z * v.x - self.x * v.z,
					self.x * v.y - self.y * v.x)
end

function Vec3.normalize(self)
	local length = self.x * self.x + self.y * self.y + self.z * self.z
	if length == 0 then return end
	length = math.sqrt ( length )
	self.x = self.x/length
	self.y = self.y/length
	self.z = self.z/length
end


function newVec3(xVal,yVal,zVal)
	local v = { x = xVal, y = yVal, z = zVal }
	setmetatable( v, Vec3 )
	return v
end
