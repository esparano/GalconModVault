-- TODO: documentation
function _profiler_init()
    local profiler = {}

    function profiler.new()
        local instance = {}
        for k, v in pairs(profiler) do
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
        end
    end

    -- note: functions on obj cannot change after this point or they won't be tracked
    function profiler:profile(obj)
        self.data[obj] = {}
        for k, v in pairs(obj) do
            if type(v) == "function" then
                obj[k] = getTrackedFunc(self, obj, k, v)
                self.data[obj][k] = {n = 0, elapsed = 0}
            end
        end
    end

    -- data[obj].funcName.n = num calls, data[obj].funcName.elapsed = total elapsed time for n calls
    function profiler:getData()
        return self.data
    end

    function profiler:printData(obj, objName)
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
                                    t.n .. ", t: " .. round(t.elapsed, 5) .. ", t/n: " .. round(t.elapsed / t.n, 5)
                )
            end
        end
    end

    return profiler
end
profiler = _profiler_init()
_profiler_init = nil
