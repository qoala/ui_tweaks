local function origName(name)
	return "__orig_" .. name
end

local function wrapFunction( package, fname, newFunction )
	local oName = origName(fname)
	if not package[oName] then
		package[oName] = package[fname]
	end
	local origFunction = package[oName]
	package[fname] = function( ... ) return newFunction(origFunction, unpack(arg)) end
end

local function unwrapFunction( package, fname )
	if package[origName(fname)] then
		package[fname] = package[origName(fname)]
	end
end

-- we need to make this a global function, as the modApi doesn't make
-- it possible to re-get at our script directory
function monkeyPatch( table )
	return function( enabled )
		for i, patch in ipairs(table) do
			if enabled then
				wrapFunction( patch.package, patch.name, patch.f )
			else
				unwrapFunction( patch.package, patch.name )
			end
		end
	end
end
