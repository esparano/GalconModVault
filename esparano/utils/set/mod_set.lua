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

function Set:diff(set2) -- set difference
    local diff = Set.new()
    for e in pairs(self._values) do
      if not set2:contains(e) then diff:add(e) end
    end
    return diff
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
        