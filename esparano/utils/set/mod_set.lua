-- TODO: documentation
function _set_init()
local Set = {}

function Set.new(list)
    local instance = {}
    for k, v in pairs(Set) do
        instance[k] = v
    end
    instance._values = {}
    instance._size = 0
    if list then
        instance:addAll(list)
    end
    return instance
end

function Set:addAll(list)
    for _, l in ipairs(list) do self:add(l) end
end

-- TODO: THIS ENTIRE CLASS ONLY WORKS FOR PRIMITIVES??
function Set:add(e)
    if not self._values[e] then
        self._size = self._size + 1
    end
    self._values[e] = true
end

function Set:remove(e)
    if self._values[e] then
        self._size = self._size - 1
    end
    self._values[e] = nil
end

function Set:contains(key) 
    return self._values[key] ~= nil
end

 -- set difference, not symmetric!
function Set:difference(set2)
    local diff = Set.new()
    for e in pairs(self._values) do
      if not set2:contains(e) then diff:add(e) end
    end
    return diff
end

function Set:symmetricDifference(set2)
    local diff = Set.new()
    for e in pairs(self._values) do
      if not set2:contains(e) then diff:add(e) end
    end
    for e in pairs(set2._values) do
        if not self:contains(e) then diff:add(e) end
    end
    return diff
end

function Set:union(set2)
    local union = Set.new()
    for e in pairs(self._values) do
        union:add(e)
    end
    for e in pairs(set2._values) do
        union:add(e)
    end
    return union
end 

function Set:intersection(set2)
    local intersection = Set.new()
    local smaller = self
    local larger = set2 
    if smaller:size() > larger:size() then 
        smaller = set2 
        larger = self
    end
    for e in pairs(smaller._values) do
      if larger:contains(e) then intersection:add(e) end
    end
    return intersection
end

function Set:randomItem()
    for e in pairs(self._values) do
        return e 
    end
end

function Set:size()
    return self._size
end

-- TODO: test
function Set:getValues()
    return self._values
end

return Set
end; Set = _set_init(); _set_init = nil
        