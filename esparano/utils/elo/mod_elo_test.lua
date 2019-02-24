require("mod_assert")
require("mod_elo")

function before_each()
    elo.reset()
    elo.save_ratings()
end

function test_available_functions()
    assert.not_nil(elo)
    assert.not_nil(elo.update_elo)
    assert.not_nil(elo.get_elo)
    assert.not_nil(elo.set_elo)
    assert.not_nil(elo.get_default_elo)
    assert.not_nil(elo.set_default_elo)
    assert.not_nil(elo.get_k)
    assert.not_nil(elo.set_k)
    assert.not_nil(elo.print_ratings)
    assert.not_nil(elo.save_ratings)
    assert.not_nil(elo.load_ratings)
    assert.not_nil(elo.clear_ratings)
    assert.not_nil(elo._win_probability)
    assert.not_nil(elo._calculate_new_elos)
end

function test_local_functions()
    assert.is_nil(update_elo)
    assert.is_nil(get_elo)
    assert.is_nil(set_elo)
    assert.is_nil(get_default_elo)
    assert.is_nil(set_default_elo)
    assert.is_nil(get_k)
    assert.is_nil(set_k)
    assert.is_nil(print_ratings)
    assert.is_nil(save_ratings)
    assert.is_nil(load_ratings)
    assert.is_nil(clear_ratings)
    assert.is_nil(_win_probability)
    assert.is_nil(_calculate_new_elos)
end

function _test_win_probability()
    print(elo._win_probability(0, 1500))
    print(elo._win_probability(1000, 1500))
    print(elo._win_probability(1300, 1500))
    print(elo._win_probability(1500, 1500))
    print(elo._win_probability(2000, 1500))
    print(elo._win_probability(20000, 1500))
    print(elo._win_probability(1800, 1800))
    print(elo._win_probability(18000, 18000))
    print(elo._win_probability(1850, 1800))
    print(elo._win_probability(18050, 18000))
end

function _test_calculate_new_elos()
    print(elo._calculate_new_elos(1200, 1000, true))
    print(elo._calculate_new_elos(1200, 1200, true))
    print(elo._calculate_new_elos(2000, 1200, true))
    print(elo._calculate_new_elos(2000, 1200, false))
end

function test_get_and_set_elo()
    elo.set_elo(72, 1243)
    elo.set_elo(6, 1647)
    assert.equals(1243, elo.get_elo(72))
    assert.equals(1647, elo.get_elo(6))
end

function _test_get_elos()
    elo.get_elo(5)
    elo.set_elo(3, 1523)
    print(elo.get_elos())
    for user, elo in pairs(elo.get_elos()) do
        print("user: " .. user .. ", elo: " .. elo)
    end
end

function test_get_and_set_default_elo()
    assert.equals(1500, elo.get_elo(3))
    assert.equals(1500, elo.get_default_elo())
    elo.set_default_elo(1234)
    assert.equals(1234, elo.get_default_elo())
    assert.equals(1234, elo.get_elo(5))
end

function test_get_and_set_k()
    assert.equals(32, elo.get_k())
    elo.set_k(100)
    assert.equals(100, elo.get_k())
end

function test_update()
    elo.set_elo("esparano", 1500)
    elo.set_elo("tycho2", 1500)
    elo.update_elo("esparano", "tycho2", true)
    assert.equals(1516, elo.get_elo("esparano"))
    assert.equals(1484, elo.get_elo("tycho2"))
end

function _test_update_multiple()
    elo.set_default_elo(2000)
    elo.set_elo(3, 1800)
    elo.print_ratings()
    elo.update_elo(3, 5, true)
    elo.print_ratings()
    elo.update_elo(3, 5, true)
    elo.print_ratings()
    elo.update_elo(3, 5, false)
    elo.print_ratings()
    elo.update_elo(3, 5, true)
    elo.print_ratings()
end

function test_save_and_load_ratings()
    local username = "sdf"
    elo.set_elo(username, 1800)
    elo.save_ratings()
    elo.set_elo(username, 100)
    assert.equals(100, elo.get_elo(username))
    elo.load_ratings()
    assert.equals(1800, elo.get_elo(username))
end

require("mod_test_runner")
