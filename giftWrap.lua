require "vec3"

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

-- returns the convex hull polygons of the list of points p
function getHullPolys ( p )
	local polys = {}

	local index = lower( p )
	local planeVec = newVec3( 0, 0, 1 )
	local dummyPoint = newVec3( p[index].x, p[index].y - 1, p[index].z )
	local nextPoint = getNextPoint( p, planeVec, p[index], dummyPoint )

	--local thirdPoint = getNextPoint( p, planeVec, p[index], p[nextPoint] )


	--table.insert( polys, {index, thirdPoint, nextPoint } )


end

-- gets the next point on the list that touches the plane first when we
-- rotate it around the edge defined by ( p1, p2 )
function getNextPoint( p, planeVec, p1, p2 )
	local edge = p2 - p1
	local reference = edge:cross(planeVec)
	reference:normalize()
 return
end
