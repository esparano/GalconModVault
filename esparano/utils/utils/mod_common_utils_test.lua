require("mod_assert")
require("mod_common_utils")

function before_each()
end

function test_available_functions()
    assert.not_nil(common_utils)
    assert.not_nil(common_utils.pass)
    assert.not_nil(common_utils.shuffle)
    assert.not_nil(common_utils.shallow_copy)
    assert.not_nil(common_utils.copy)
    assert.not_nil(common_utils.round)
    assert.not_nil(common_utils.dump)
    assert.not_nil(common_utils.find)
    assert.not_nil(common_utils.map)
    assert.not_nil(common_utils.reduce)
    assert.not_nil(common_utils.sumList)
    assert.not_nil(common_utils.joinToString)
end

function test_local_functions()
    assert.is_nil(pass)
    assert.is_nil(shuffle)
    assert.is_nil(shallow_copy)
    assert.is_nil(copy)
    assert.is_nil(round)
    assert.is_nil(dump)
    assert.is_nil(find)
    assert.is_nil(map)
    assert.is_nil(reduce)
    assert.is_nil(sumList)
    assert.is_nil(joinToString)
end

function test_pass()
    common_utils.pass()
end

function test_shallow_copy()
    local list = {{1, 2}, 2, 3}
    local copiedList = common_utils.shallow_copy(list)

    assert.equals(3, #list)
    assert.equals(3, #copiedList)

    assert.equals(1, list[1][1])
    copiedList[1][1] = 7
    assert.equals(7, list[1][1])
end
 
function test_copy()
    local list = {1, 2, 3}
    local copiedList = common_utils.copy(list)

    assert.equals(3, #list)
    assert.equals(3, #copiedList)

    assert.equals(1, list[1])
    list[1] = 7
    assert.equals(7, list[1])
    assert.equals(1, copiedList[1])
end

function _test_shuffle()
    local list = {1, 2, 3, 4, 5, 6, 7, 8, 9}
    print(common_utils.dump(list))

    print("shuffling")
    common_utils.shuffle(list)
    print(common_utils.dump(list))

    print("shuffling")
    common_utils.shuffle(list)
    print(common_utils.dump(list))
end

function test_round()
    assert.equals(10, common_utils.round(10.49))
    assert.equals(11, common_utils.round(10.5))
    assert.equals(11, common_utils.round(10.51))
    assert.equals(0, common_utils.round(0))
    assert.equals(0, common_utils.round(-0.00000001))
    assert.equals(0, common_utils.round(0.00000001))
    assert.equals(-10, common_utils.round(-10.49))
    assert.equals(-10, common_utils.round(-10.5))
    assert.equals(-11, common_utils.round(-10.51))
end

function test_toPrecision()
    assert.equals(0, common_utils.toPrecision(11.43819, -2))
    assert.equals(10, common_utils.toPrecision(11.43819, -1))
    assert.equals(11, common_utils.toPrecision(11.43819, 0))
    assert.equals(11.4, common_utils.toPrecision(11.43819, 1))
    assert.equals(11.44, common_utils.toPrecision(11.43819, 2))
    assert.equals(11.438, common_utils.toPrecision(11.43819, 3))
    assert.equals(11.4382, common_utils.toPrecision(11.43819, 4))
    assert.equals(11.43819, common_utils.toPrecision(11.43819, 5))
    assert.equals(11.438190, common_utils.toPrecision(11.43819, 6))
end

function test_clamp()
    assert.equals(6, common_utils.clamp(5.9999, 6, 10))
    assert.equals(6, common_utils.clamp(6, 6, 10))
    assert.equals(8, common_utils.clamp(8, 6, 10))
    assert.equals(10, common_utils.clamp(10, 6, 10))
    assert.equals(10, common_utils.clamp(10.00001, 6, 10))
    assert.equals(10, common_utils.clamp(11, 6, 10))
    assert.equals(10.1111, common_utils.clamp(11, 6, 10.1111))

    assert.equals(0, common_utils.clamp(-0.0001))
    assert.equals(0, common_utils.clamp(0))
    assert.equals(0.0001, common_utils.clamp(0.0001))
    assert.equals(0.9999, common_utils.clamp(0.9999))
    assert.equals(1, common_utils.clamp(1))
    assert.equals(1, common_utils.clamp(1.00001))
end

function _test_dump()
    print("Dumping 17")
    print(common_utils.dump(17))

    print("Dumping '17'")
    print(common_utils.dump('17'))

    print("Dumping nil")
    print(common_utils.dump(nil))

    print("Dumping {1, 2, 3}")
    print(common_utils.dump({1, 2, 3}))

    print("Dumping {key='value', 43, nil, nilKey=nil, 'afterNils'}")
    print(common_utils.dump({key='value', 43, nil, nilKey=nil, "afterNils"}))

    print("Dumping {1, 2, {3, 4}}")
    print(common_utils.dump({1, 2, {3, 4}}))

    print("Dumping {key='value',nestedTable={nestedKey='nestedValue'}}")
    print(common_utils.dump({key='value',nestedTable={nestedKey='nestedValue'}}))
end

function test_find()
    local list = {7, 1, 8, 3, 400, 1, 2}
    local best = common_utils.find(list, function (o) return o end)
    assert.equals(400, best)
end

function test_filter()
    local list = {7, 1, 8, 3, 400, 1, 2}
    local matches = common_utils.filter(list, function (o) return o % 2 == 0 end)
    assert.equals(3, #matches)
    assert.equals(8, matches[1])
    assert.equals(400, matches[2])
    assert.equals(2, matches[3])
end

function test_map()
    local list = {1, 2, 3, 4, 5}
    local mapped = common_utils.map(list, function (a) return a * 2 end)
    assert.equals(2, mapped[1])
    assert.equals(8, mapped[4])
    assert.equals(10, mapped[5])
end

function test_forEach()
    local list = {1, 2, 3, 4, 5}
    local sum = 0
    common_utils.forEach(list, function (a) sum = sum + a end)
    assert.equals(15, sum)

    common_utils.forEach({}, function (a) assert.fail("should not run this function") end)
end

function test_reduce()
    local list = {1, 2, 3, 4, 5}
    local reduced = common_utils.reduce(list, function (a, b) return a * b end)
    assert.equals(120, reduced)
end

function test_sumList()
    local list = {1, 2, 3, 4, 5}
    local sum = common_utils.sumList(list)
    assert.equals(15, sum)
end

function test_joinToString()
    -- slightly weird behavior with "nils", but that's the way ipairs works in lua...
    assert.equals("1, a, 2", common_utils.joinToString({1, "a", 2, nil, 3}))
    assert.equals("5, 1", common_utils.joinToString({5, 1}))
    assert.equals("-1", common_utils.joinToString({-1}))
    assert.equals("", common_utils.joinToString({}))
end

require("mod_test_runner")
