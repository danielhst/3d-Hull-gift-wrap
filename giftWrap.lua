require "vec3"

local points = {}

function lower( p )
	local index = 1
	for i = 2, #p do
		if p[i].z < p[index].z then index = i
		--tie
		elseif p[i].z == p[index].z then
			if p[i].y < p[index].y then index = i
			elseif p[i].x < p[index].x then index = i
			elseif p[i].y == p[index].y and p[i].x == p[index].x then
				error("duplicate point with index " .. i .. " and " .. index )
			end
		end
	end
	return index

end

-- returns the convex hull polygons of the list of points p
function getHullPolys ( p )
	local polys = {}
	local openEdges = {}
	local createdEdges = {}

	local index1 = lower( p )
	local index2 = getNextPoint( p, index1, -1 )

	table.insert( openEdges, { index1, index2 } )

	while #openEdges ~= 0 do
		index1 = openEdges[1][1]
		index2 = openEdges[1][2]
		table.remove(openEdges, 1)

		local index3 = getNextPoint( p, index1, index2 )

		if not createdEdges["e" .. index1 .. "_" .. index2] then

			table.insert( polys, {index1, index2, index3 } )

			createdEdges["e" .. index1 .. "_" .. index2] = true
			createdEdges["e" .. index2 .. "_" .. index3] = true
			createdEdges["e" .. index3 .. "_" .. index1] = true

			if not createdEdges["e" .. index3 .. "_" .. index2] then
				table.insert( openEdges, { index3, index2 } )
			end

			if not createdEdges["e" .. index1 .. "_" .. index3] then
				table.insert( openEdges, { index1, index3 } )
			end
		end

	end

	return polys
end

-- gets the next point on the list that forms an suport plane with the two other
function getNextPoint( p, p1Index, p2Index )
	local p1 = p[p1Index]
	local p2
	if p2Index < 1 then
		p2 = p1 - newVec3( 1, 1, 0 )
	else
		p2 = p[p2Index]
	end

	local edge = p2 - p1
	edge:normalize()

	local candidateIndex = -1

	for i = 1, #p do
		if i ~= p1Index and i ~=p2Index then
			if candidateIndex == -1 then
				candidateIndex = i
			else

				local v = p[i] - p1
				v =	v - v:projectOver( edge )
				local candidate = p[candidateIndex] - p1
				candidate = candidate - candidate:projectOver( edge )


				local cross = candidate:cross( v )
				if cross:dot( edge ) > 0 then
					candidateIndex = i
				end

			end
		end
	end

	return candidateIndex
end
