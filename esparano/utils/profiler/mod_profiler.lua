require("mod_common_utils")

--[[
    Example usage: 
    -- local p = Profiler.new()
    -- p:profile(someObject)
    -- someObject:doSomeExpensiveStuff()
    -- p:printData(someObject, "objectName")
]]

-- TODO: documentation
function _m_init()
    local Profiler = {}

    function Profiler.new()
        local instance = {}
        for k, v in pairs(Profiler) do
            instance[k] = v
        end
        instance.data = {}
        return instance
    end

    local function trackCall(self, obj, funcName, elapsed)
        local data = self.data[obj][funcName]
        data.n = data.n + 1
        data.elapsed = data.elapsed + elapsed
    end

    local function getTrackedFunc(self, obj, funcName, func)
        return function(...)
            local start = os.clock()
            local result = func(...)
            trackCall(self, obj, funcName, os.clock() - start)
            return result -- DOES NOT WORK FOR MULTIPLE RETURN VALUES
            -- TODO: use table.unpack
        end
    end

    -- note: functions on obj cannot change after this point or they won't be tracked
    -- NOTE: If functions do not take at least 1ms, they don't get counted :(. Lua sucks sometimes.
    function Profiler:profile(obj)
        self.data[obj] = {}
        for k, v in pairs(obj) do
            if type(v) == "function" then
                obj[k] = getTrackedFunc(self, obj, k, v)
                self.data[obj][k] = {n = 0, elapsed = 0}
            end
        end
    end

    -- data[obj].funcName.n = num calls, data[obj].funcName.elapsed = total elapsed time for n calls
    function Profiler:getData()
        return self.data
    end

    local function verifyHasData(data, obj, funcName)
        if data[obj] == nil then
            print("ERROR: No profiling data for unknown object " .. tostring(obj))
            return false
        end
        if data[obj][funcName] == nil then
            print("ERROR: No profiling data for unknown function " .. funcName)
            return false
        end
        return true
    end

    function Profiler:getN(obj, funcName)
        if not verifyHasData(self.data, obj, funcName) then return 0 end
        return self.data[obj][funcName].n
    end

    function Profiler:getElapsed(obj, funcName)
        if not verifyHasData(self.data, obj, funcName) then return 0 end
        return self.data[obj][funcName].elapsed
    end
    
    function Profiler:printData(obj, objName)
        if self.data[obj] == nil then
            print("obj " .. objName .. " was not found. Profiling statistics cannot be printed")
            return
        else
            objName = objName == nil and tostring(obj) or objName
            print("Profiling obj " .. objName .. ": _________")
            for funcName, t in pairs(self.data[obj]) do
                print(
                    objName ..
                        "." ..
                            funcName ..
                                ":  n: " ..
                                    t.n .. ", t: " .. common_utils.round(t.elapsed, 5) .. ", t/n: " .. common_utils.round(t.elapsed / t.n, 5)
                )
            end
        end
    end

    return Profiler
end
Profiler = _m_init()
_m_init = nil
