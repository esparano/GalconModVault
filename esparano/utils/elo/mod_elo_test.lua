require("mod_elo")

function init()
    --test_available_functions()
    --test_local_functions()
    --test_win_probability()
    --test_calculate_new_elos()
    --test_get_and_set_elo()
    --test_get_elos()
    --test_get_and_set_default_elo()
    --test_get_and_set_k()
    --test_update()
    --test_update_multiple()
    --test_save_rankings()
    --test_load_rankings()
end

function test_available_functions()
    print(elo)
    print(elo.update_elo)
    print(elo.get_elo)
    print(elo.set_elo)
    print(elo.get_default_elo)
    print(elo.set_default_elo)
    print(elo.get_k)
    print(elo.set_k)
    print(elo.print_rankings)
    print(elo.save_rankings)
    print(elo.load_rankings)
    print(elo._win_probability)
    print(elo._calculate_new_elos)
end

function test_local_functions()
    print(update_elo)
    print(get_elo)
    print(set_elo)
    print(get_default_elo)
    print(set_default_elo)
    print(get_k)
    print(set_k)
    print(print_rankings)
    print(save_rankings)
    print(load_rankings)
    print(_win_probability)
    print(_calculate_new_elos)
end

function test_win_probability()
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

function test_calculate_new_elos()
    print(elo._calculate_new_elos(1200, 1000, true))
    print(elo._calculate_new_elos(1200, 1200, true))
    print(elo._calculate_new_elos(2000, 1200, true))
    print(elo._calculate_new_elos(2000, 1200, false))
end

function test_get_and_set_elo()
    print(elo.get_elo(72))
    elo.set_elo(72, 1243)
    elo.set_elo(6, 1647)
    print(elo.get_elo(72))
end

function test_get_elos()
    elo.get_elo(5)
    elo.set_elo(3, 1523)
    print(elo.get_elos())
    for user,elo in pairs(elo.get_elos()) do
        print("user: " .. user .. ", elo: " .. elo)
    end
end

function test_get_and_set_default_elo()
    print(elo.get_elo(3))
    print(elo.get_default_elo())
    elo.set_default_elo(1234)
    print(elo.get_default_elo())
    print(elo.get_elo(5))
end

function test_get_and_set_k()
    print(elo._calculate_new_elos(1200, 1200, true))
    print(elo.get_k())
    elo.set_k(100)
    print(elo.get_k())
    print(elo._calculate_new_elos(1200, 1200, true))
end

function test_update()
    elo.print_rankings()
    elo.update_elo("esparano", "tycho2", true)
    elo.print_rankings()
end

function test_update_multiple()
    elo.set_default_elo(2000)
    elo.set_elo(3, 1800)
    elo.print_rankings()
    elo.update_elo(3, 5, true)
    elo.print_rankings()
    elo.update_elo(3, 5, true)
    elo.print_rankings()
    elo.update_elo(3, 5, false)
    elo.print_rankings()
    elo.update_elo(3, 5, true)
    elo.print_rankings()
end

function test_save_rankings()
    elo.set_elo("sdf", 1800)
    elo.set_elo(4, 1700)
    elo.set_elo(400, 1100)
    elo.save_rankings()
end

function test_load_rankings()
    elo.load_rankings()
    elo.print_rankings()
end

function loop(t)
end

function event(e)
end
