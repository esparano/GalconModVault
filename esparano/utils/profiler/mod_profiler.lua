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
    -- NOTE: If functions do not take at least 1ms, they don't get counted :(. Lua sucks sometimes.
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

    return profiler
end
profiler = _profiler_init()
_profiler_init = nil
