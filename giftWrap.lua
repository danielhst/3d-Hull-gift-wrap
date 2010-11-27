function Vec3( xVal, yVal, zVal )
	return { x = xVal, y = yVal, z = zVal }
end

local points = {}

function lower( p )
	local index = 1
	for i = 1, #p do
		if p[i].z < p[index].z then index = i
		--tie
		elseif p[i].y < p[index].y then index = i
		elseif p[i].x < p[index].x then index = i
		end
	end
	return index

end
