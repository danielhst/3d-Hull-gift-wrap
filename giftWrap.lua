require "vec3"

local points = {}

--[[
 returns the lower point of the points list. in the case of a tie
 the other y coordinate is used, and the x is used in the case of
 another tie. Trows an erro in the case of a duplicate minimum.
 ]]
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

	function edgeExists( p1, p2 ) return createdEdges["e" .. p1 .. "_" .. p2] end

	-- marks the edge (p1,p2) as created and adds the symetrical to the openEdges list
	function addEdge( p1, p2 )
		createdEdges["e" .. p1 .. "_" .. p2] = true
		if not edgeExists( p2, p1) then	table.insert( openEdges, { p2, p1 } ) end
	end

	local index1 = lower( p )
	local index2 = getNextPoint( p, index1, -1 )

	addEdge( index2, index1 )

	while #openEdges ~= 0 do
		index1 = openEdges[#openEdges][1]
		index2 = openEdges[#openEdges][2]
		table.remove(openEdges, #openEdges )

		-- check if this edge does remain open, since it could be closed in other iteration
		if not edgeExists(index1, index2) then
			local index3 = getNextPoint( p, index1, index2 )

			table.insert( polys, {index1, index2, index3 } )
			addEdge( index1, index2 )
			addEdge( index2, index3 )
			addEdge( index3, index1 )

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
