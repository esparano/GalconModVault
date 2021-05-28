function _module_init()
    local Logger = {}

    Logger.NONE = -1000000
    Logger.FATAL = 0
    Logger.ERROR = 1
    Logger.WARN = 2
    Logger.INFO = 3
    Logger.DEBUG = 4
    Logger.TRACE = 5

    Logger.MAX_LINE_WIDTH = 60

    -- TODO: info/debug/trace/etc. 
    -- TODO: info to print for instance of logger
    function Logger.new(loggerName, level)
        local instance = {}
        for k, v in pairs(Logger) do
            instance[k] = v
        end

        instance.name = loggerName
        instance.level = level or Logger.WARN

        return instance
    end

    local function splitByChunk(text, chunkSize, indent)
        local s = {}
        local i = 1
        while i <= #text do
            local newI = i + chunkSize - ((i == 1) and 0 or #indent)
            s[#s+1] = string.sub(text, i, newI - 1)
            i = newI
        end
        return s
    end

    function Logger:_doLog(level, levelName, msg)
        local indentText = "    " 
        if self.level >= level then 
            local prefix = levelName .. "[" .. self.name .. "]: "
            local messages = splitByChunk(msg, Logger.MAX_LINE_WIDTH - #prefix, indentText)
            for i,msg in ipairs(messages) do 
                local indent = (i == 1) and "" or indentText
                print(prefix .. indent .. msg) 
            end
        end
    end

    function Logger:fatal(msg)
        self:_doLog(Logger.FATAL, "FATAL", msg)
    end

    function Logger:error(msg)
        self:_doLog(Logger.ERROR, "ERROR", msg)
    end

    function Logger:warn(msg)
        self:_doLog(Logger.WARN, "WARN ", msg)
    end

    function Logger:info(msg)
        self:_doLog(Logger.INFO, "INFO ", msg)
    end

    function Logger:debug(msg)
        self:_doLog(Logger.DEBUG, "DEBUG", msg)
    end

    function Logger:trace(msg)
        self:_doLog(Logger.TRACE, "TRACE", msg)
    end

    return Logger
end
Logger = _module_init()
_module_init = nil
