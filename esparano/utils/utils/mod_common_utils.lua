-- TODO: documentation
function _common_utils_init()
    local common_utils = {}
    
    function common_utils.pass()
    end
    
    function common_utils.shuffle(t)
        for i, v in ipairs(t) do
            local n = math.random(i, #t)
            t[i] = t[n]
            t[n] = v
        end
    end

    function common_utils.shallow_copy(o)
        if type(o) ~= "table" then
            return o
        end
        local r = {}
        for k, v in pairs(o) do
            r[k] = v
        end
        return r
    end
    
    function common_utils.copy(o)
        if type(o) ~= "table" then
            return o
        end
        local r = {}
        for k, v in pairs(o) do
            r[k] = common_utils.copy(v)
        end
        return r
    end
    
    function common_utils.round(num)
        return math.floor(num + 0.5)
    end

    function common_utils.clamp(val, min, max)
        min = min or 0
        max = max or 1
        return math.min(math.max(val, min), max)
    end

    function common_utils.dump(o)
        if type(o) == 'table' then
            local s = '{ '
            for k,v in pairs(o) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. common_utils.dump(v) .. ','
            end
            return s .. '} '
        else
            return tostring(o)
        end
    end

    -- search list for the best match by greatest result
    function common_utils.find(Q, f)
        local r, v
        for _, o in pairs(Q) do
            local _v = f(o)
            if _v and ((not r) or _v > v) then
                r, v = o, _v
            end
        end
        return r
    end

    function common_utils.map(list, f)
        local result = {}
        for i,v in ipairs(list) do
            result[i] = f(v)
        end
        return result
      end

    function common_utils.reduce(list, f) 
        local acc
        for k, v in ipairs(list) do
            if 1 == k then
                acc = v
            else
                acc = f(acc, v)
            end 
        end 
        return acc 
    end 

    function common_utils.sumList(list)
        return common_utils.reduce(list, function (a, b) return a + b end)
    end

    return common_utils


end
common_utils = _common_utils_init()
_common_utils_init = nil

