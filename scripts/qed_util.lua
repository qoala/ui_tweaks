--
-- Custom utils with support for cyclic data structures and optionally only operate on data values.
--
-- A k,v pair in a table is considered a data value if it has a number or string key,
-- and the key does not begin with "__" (metamethod prefix).
-- This restriction helps avoid infinite recursion cases, such as the following sequence.
-- (Note that t is not the return value of either call. This looks like it should be safe to call
-- on shared data, but it isn't. The UI has some values that aren't)
--    util.inherit(t){} -- Assigns t.__index=t and uses t as a metatable.
--    util.extend(t){} -- Fails because t contains a cycle through a non-data value.
--

local _M = {}

-- Recursively copies all absent data entries from tSrc into t.
-- (Reversed args compared to the vanilla util.extend helper.)
function tMergeCopy( t, tSrc, dataKeysOnly, _cache )
	assert( type(t) == "table" and type(tSrc) == "table", string.format("type(t) == %s, type(tSrc) == %s", type(t), type(tSrc)) )
	if _cache then _cache[tSrc] = t else _cache = { [tSrc] = t } end

	-- Deep-merge all of tSrc into t
	for k,v in pairs( tSrc ) do
		local kType = type(k)
		if kType ~= "string" and kType ~= "number" then
			-- continue
		elseif dataKeysOnly and kType == "string" and string.sub(k, 1, 2) == "__" then
			-- continue (metamethod)
		elseif type(v) == "table" then
			local cached = _cache[v]
			if t[k] == nil then
				if cached then
					t[k] = cached
				else
					t[k] = tMergeCopy( {}, v, dataKeysOnly, _cache )
				end
			elseif t[k]._OVERRIDE then
				-- continue (OVERRIDE tables fully replace the src value, so can stop here)
			elseif cached then
				assert(t[k] == cached, tostring(k)) -- Fail unless the exact same cycle is already present.
			else
				tMergeCopy( t[k], v, dataKeysOnly, _cache )
			end
		else
			if t[k] == nil then
				t[k] = v
			else
				assert( type(t[k]) == type(v), tostring(k) )
			end
		end
	end

	return t
end

-- Variant of vanilla util.extend that handles cycles.
function _M.extend( ... )
	local tbases = { ... }
	return function( t )
		for _, tbase in ipairs( tbases ) do
			t = tMergeCopy( t or {}, tbase )
		end
		return t
	end
end

-- Variant of vanilla util.extend that only copies data entries, and handles cycles.
function _M.extendData( ... )
	local tbases = { ... }
	return function( t )
		for _, tbase in ipairs( tbases ) do
			t = tMergeCopy( t or {}, tbase, true )
		end
		return t
	end
end

return _M
