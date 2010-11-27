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

function Vec3.equals(self, v)
	return self.x == v.x and self.y == v.y  and self.z == v.z
end


function Vec3.dot(self, v)
	return self.x * v.x + self.y * v.y  + self.z * v.z
end

function Vec3.projectOver(self, v)
	local length = self:dot(v)
	return newVec3( length * v.x, length * v.y, length * v.z )
end

function Vec3.length2(self)
	return self.x * self.x + self.y * self.y + self.z * self.z
end


function Vec3.normalize(self)
	local length = self:length2()
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
