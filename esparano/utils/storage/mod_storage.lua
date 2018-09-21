-- TODO: documentation
function _storage_init()
local storage = {}

local function _load()
    return json.decode(g2.data)
end

function storage.save(key, o)
    local data = _load()
    data[key] = o
    local s = json.encode(data)
    -- TODO: figure out 
    if s.len > 64000 then
        print("storage: ERROR: object too large to save")
    else
        g2.data = s
    end
end

function storage.load(key)
    local data = _load()
    return data[key]
end

return storage
end; storage = _storage_init(); _storage_init = nil
