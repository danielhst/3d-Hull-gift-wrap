allTests = {}

function test(testName, testFunc)
	table.insert(allTests,{ name = testName, run = testFunc } )
end

function assert_list_eq(l1, l2)
	if #l1 ~= #l2 then
		error( "the lists size are diferent. expected " .. #l1 .. " got " .. #l2 )
	end

	for i,v in ipairs(l1) do
		if l1[i] ~= l2[i] then

			local getString = function(value)
				if not value then return " nil " else return value end
			end

		error("The lists ".. i .. " term differ. expected ".. getString(l1[i]) .. " got " .. getString(l2[i]))
	end
  end
end

function testAll()
	local falhas = 0
	for i,v in ipairs(allTests) do
		if not v.run() then
			print( "teste " .. i .. ":'" .. v.name .. "' falhou!" )
			falhas = falhas + 1
		end
	end
	if falhas == 0 then
		print( "Todos os " .. table.getn(allTests) .. " testes passaram" )
	else
		print( falhas .. " testes falharam!!!" )
	end
end
