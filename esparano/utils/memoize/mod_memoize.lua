function _memoize_init()
    local function cache_get(cache, params)
        local node = cache
        for i = 1, #params do
            node = node.children and node.children[params[i]]
            if not node then
                return nil
            end
        end
        return node.results
    end

    local function cache_put(cache, params, results)
        local node = cache
        local param
        for i = 1, #params do
            param = params[i]
            node.children = node.children or {}
            node.children[param] = node.children[param] or {}
            node = node.children[param]
        end
        node.results = results
    end

    return function(f, cache)
        cache = cache or {}

        if type(f) ~= "function" then
            error(string.format("Only functions are memoizable. Received %s (a %s)", tostring(f), type(f)))
        end

        return function(...)
            local params = {...}

            local results = cache_get(cache, params)
            if not results then
                results = {f(...)}
                cache_put(cache, params, results)
            end

            return table.unpack(results)
        end
    end
end
memoize = _memoize_init()
_memoize_init = nil

local _LICENSE =
    [[
    MIT LICENSE
    Copyright (c) 2018 Enrique García Cota
    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
