-- Variables
local Constructor = {}
local Index, NewIndex

-- Types
export type Constructor = {
	new: (data: { [any]: any }, public: { [any]: any }?) -> ({}, { [any]: any }),
}

-- Constructor
Constructor.new = function(data, public)
	local proxy = newproxy(true)
	local metatable = getmetatable(proxy)
	for index, value in data do
		metatable[index] = value
	end
	metatable.__index = Index
	metatable.__newindex = NewIndex
	metatable.__public = public or {}
	return proxy, metatable
end

-- Functions
Index = function(proxy, index)
	local metatable = getmetatable(proxy)
	local public = metatable.__public[index]
	return if public == nil then metatable.__shared[index] else public
end

NewIndex = function(proxy, index, value)
	local metatable = getmetatable(proxy)
	local set = metatable.__set[index]
	if set == nil then
		metatable.__public[index] = value
	elseif set == false then
		error("Attempt to modify a readonly value", 2)
	else
		set(proxy, metatable, value)
	end
end

return table.freeze(Constructor) :: Constructor
