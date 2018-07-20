function _s_encode(s)
    if s == nil then return "" end
    s = tostring(s)
    s = s:gsub("\\","\\s")
    s = s:gsub("\t","\\t")
    s = s:gsub("\n","\\n")
    return s
end

function _s_decode(s)
    s = tostring(s)
    s = s:gsub("\\n","\n")
    s = s:gsub("\\t","\t")
    s = s:gsub("\\s","\\")
    return s
end

function t_encode(r)
    local cols = {}
    local rows = {}
    for n,e in pairs(r) do
        for k,v in pairs(e) do 
            if cols[k] == nil then
                cols[k] = k
                cols[#cols+1] = k
            end
        end
        local row = {}
        for n,k in pairs(cols) do
            row[n] = _s_encode(e[k])
        end
        rows[#rows+1] = table.concat(row,"\t")
    end
    return table.concat(cols,"\t") .. "\n" .. table.concat(rows,"\n")
end

function t_decode(s)
    local cols = nil
    local rows = (s.."\n"):gmatch("([^\n]*)\n")
    local r = {}
    for line in rows do
        if cols == nil then
            cols = {}
            for k in (line.."\t"):gmatch("([^\t]*)\t") do
                cols[#cols+1] = k
            end
        else
            local n = 1
            local e = {}
            for v in (line.."\t"):gmatch("([^\t]*)\t") do
                e[cols[n]] = _s_decode(v)
                n = n+1
            end
            r[#r+1] = e
        end
    end
    return r
end
                
function _strict_init()
    local G = _ENV or _G
    local globals = {}
    local setmetatable = setmetatable
    local rawset = rawset
    local error = error
    local mt = getmetatable(G)
    function strict(enable)
        setmetatable(G,mt)
        if enable ~= true then return end
        setmetatable(G,{
            __newindex = function(self,k,v)
                if type(v) == "function" or globals[k] ~= nil then
                    rawset(self,k,v)
                else
                    error("undeclared global '"..k.."'")
                end
            end,
        })
    end
    function global(k)
        globals[k] = true
    end
    G["_strict_init"] = nil
end
_strict_init()

-- r = {{name="phil",type="human",legs=2,fingers=10,toes=10},{legs=4,name="cuzco",type="goat",horns=2,toes=8,beard="no",fur="tri-color"}}
-- txt = t_encode(r)
-- print(txt)
-- r2 = t_decode(txt)
-- txt2 = t_encode(r2)
-- print(txt2)
-- print(txt == txt2)
-- -- may result in false, as order of keys won't always be the same