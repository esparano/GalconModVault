-- TODO: documentation
function _common_utils_init()
    local common_utils = {}
    
    function common_utils.pass()
    end

    function common_utils.boolToSign(bool)
        return bool and 1 or -1
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

    function common_utils.toPrecision(num, precision)
        return common_utils.round(10^precision * num)/10^precision
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
                if type(k) == 'table' then k = tostring(k) end
                if type(v) == 'function' then 
                    s = s .. k .. '(),'
                else
                    if type(k) ~= 'number' then k = '"'..k..'"' end
                    s = s .. '['..k..'] = ' .. common_utils.dump(v) .. ','
                end
            end
            return s .. '} '
        elseif type(o) == 'function' then 
            return 'function()'
        else
            return tostring(o)
        end
    end

    -- search list for the best match by greatest result
    -- TODO: rename to "findBest?"
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

    function common_utils.findFirst(items, predicate)
        for _, item in pairs(items) do
            if predicate(item) then
                return item
            end
        end
    end

    function common_utils.filter(items, predicate)
        local matches = {}
        for _, item in pairs(items) do
            if predicate(item) then
                matches[#matches + 1] = item
            end
        end
        return matches
    end

    -- TODO: should this work with pairs?
    function common_utils.map(list, f)
        local result = {}
        for i,v in ipairs(list) do
            result[i] = f(v)
        end
        return result
    end

    function common_utils.forEach(list, f)
        for _,v in ipairs(list) do
            f(v)
        end
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
        return common_utils.reduce(list, function (a, b) return a + b end) or 0
    end

    function common_utils.joinToString(list, delimiter)
        delimiter = delimiter or ', '
        return common_utils.reduce(common_utils.map(list, tostring), function (a, b) return a .. delimiter .. b end) or ""
    end

    function common_utils.combineLists(list1, list2)
        local combined = {}
        for k, v in ipairs(list1) do
            table.insert(combined, v)
        end
        for k, v in ipairs(list2) do
            table.insert(combined, v)
        end
        return combined
    end

    -- merges table t2 into t1, *modifying* t1
    function common_utils.mergeTableInto(t1, t2)
        for k, v in pairs(t2) do
            if (type(v) == "table") and (type(t1[k] or false) == "table") then
                common_utils.mergeTableInto(t1[k], t2[k])
            else
                t1[k] = v
            end
        end
        return t1
    end


    return common_utils

end
common_utils = _common_utils_init()
_common_utils_init = nil

