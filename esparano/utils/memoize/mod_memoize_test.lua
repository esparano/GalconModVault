require("mod_assert")
require("mod_memoize")

local counter

local count = function()
    counter = counter + 1
    return counter
end
local memoized_count
function before_each()
    counter = 0
    memoized_count = memoize(count)
end

function test_errors()
    --memoize()
    --memoize('foo')
    --memoize(1)
    --memoize({})
end

function test_0_params()
    memoized_count()
    assert.equals(1, memoized_count())
    assert.equals(1, counter)
end

function test_1_param()
    memoized_count("foo")
    assert.equals(1, memoized_count("foo"))
    assert.equals(2, memoized_count("bar"))
    assert.equals(1, memoized_count("foo"))
    assert.equals(2, memoized_count("bar"))
    assert.equals(counter, 2)
end

function test_2_params()
    memoized_count("foo", "bar")
    assert.equals(1, memoized_count("foo", "bar"))
    assert.equals(2, memoized_count("foo", "baz"))
    assert.equals(1, memoized_count("foo", "bar"))
    assert.equals(2, memoized_count("foo", "baz"))
    assert.equals(counter, 2)
end

function test_multi_return()
    local switch =
        memoize(
        function(x, y)
            counter = counter + 1
            return y, x
        end
    )
    local memoized_switch = memoize(switch)
    local x, y = memoized_switch(100, 200)
    assert.equals(200, x)
    assert.equals(100, y)
    assert.equals(counter, 1)
    x, y = memoized_switch(400, 500)
    assert.equals(500, x)
    assert.equals(400, y)
    assert.equals(counter, 2)
    x, y = memoized_switch(100, 200)
    assert.equals(200, x)
    assert.equals(100, y)
    assert.equals(counter, 2)
    x, y = memoized_switch(400, 500)
    assert.equals(500, x)
    assert.equals(400, y)
    assert.equals(counter, 2)
end

-- test cache param --------------

local len = function(...)
    counter = counter + 1
    return #{...}
end

function test_cache_partial_clear()
    local cache = {}
    local mlen = memoize(len, cache)
    assert.equals(1, mlen("freddie"))
    assert.equals(1, counter)
    assert.equals(1, mlen("freddie"))
    assert.equals(1, counter)

    assert.equals(3, mlen("freddie", "tina", "bowie"))
    assert.equals(2, counter)
    assert.equals(3, mlen("freddie", "tina", "bowie"))
    assert.equals(2, counter)

    assert.equals(1, mlen("michael"))
    assert.equals(3, counter)
    assert.equals(1, mlen("michael"))
    assert.equals(3, counter)

    cache.children["freddie"] = nil

    assert.equals(1, mlen("freddie"))
    assert.equals(4, counter)
    assert.equals(1, mlen("freddie"))
    assert.equals(4, counter)

    -- NOTE: clearing cache starting with first param ("freddie")
    -- clears multi-param calls starting with "freddie"
    assert.equals(3, mlen("freddie", "tina", "bowie"))
    assert.equals(5, counter)
    assert.equals(3, mlen("freddie", "tina", "bowie"))
    assert.equals(5, counter)

    assert.equals(1, mlen("michael"))
    assert.equals(5, counter)
end

function test_shared_cache()
    local len2 = function(...)
        counter = counter + 10
        return #{...}
    end

    local cache = {}
    local mlen = memoize(len, cache)
    local mlen2 = memoize(len2, cache)

    assert.equals(1, mlen("a"))
    assert.equals(1, counter)

    assert.equals(1, mlen2("a"))
    assert.equals(1, counter)

    assert.equals(4, mlen2("a", "b", "c", "d"))
    assert.equals(11, counter)

    assert.equals(4, mlen("a", "b", "c", "d"))
    assert.equals(11, counter)
end

require("mod_test_runner")
