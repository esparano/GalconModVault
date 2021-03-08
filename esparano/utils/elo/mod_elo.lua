-- TODO: documentation
function _elo_init()
    local elo = {}

    local ELOS = {}
    local RESET_DEFAULT_ELO = 1500
    local DEFAULT_ELO = RESET_DEFAULT_ELO

    local RESET_K = 32
    local K = RESET_K

    function elo.get_elo(user)
        ELOS[user] = ELOS[user] or DEFAULT_ELO
        return ELOS[user]
    end

    function elo.set_elo(user, v)
        ELOS[user] = v
    end

    function elo.get_elos()
        return ELOS
    end

    function elo.player_win_probability(user1, user2)
        local r1 = elo.get_elo(user1)
        local r2 = elo.get_elo(user2)
        return elo._win_probability(r1, r2)
    end

    function elo._win_probability(r1, r2)
        return 1 / (1 + math.pow(10, (r2 - r1) / 400))
    end

    function elo._calculate_new_elos(r1, r2, first_won)
        local actual = first_won and 1 or 0
        local expected = elo._win_probability(r1, r2)
        local change = K * (actual - expected)
        return r1 + change, r2 - change
    end

    function elo.update_elo(user1, user2, first_won)
        if user1 == user2 then return end 
        local r1 = elo.get_elo(user1)
        local r2 = elo.get_elo(user2)
        r1, r2 = elo._calculate_new_elos(r1, r2, first_won)
        elo.set_elo(user1, r1)
        elo.set_elo(user2, r2)
    end

    function elo.get_default_elo()
        return DEFAULT_ELO
    end

    function elo.set_default_elo(v)
        DEFAULT_ELO = v
    end

    function elo.get_k()
        return K
    end

    function elo.set_k(k)
        K = k
    end

    function elo.print_ratings()
        print("elo: Printing all stored elo ratings:")
        for user, elo in pairs(ELOS) do
            print("user: " .. user .. ", elo: " .. elo)
        end
    end

    function elo.save_ratings()
        local data = json.decode(g2.data)
        data.elo = ELOS
        g2.data = json.encode(data)
    end

    function elo.load_ratings()
        local data = json.decode(g2.data)
        local ratings = data.elo
        print("elo: Loaded ratings from g2.data.elo")
        if (ratings == nil) then
            print("elo: WARNING: No ratings loaded")
        else
            ELOS = ratings
        end
    end

    function elo.clear_ratings()
        ELOS = {}
    end

    function elo.reset()
        ELOS = {}
        K = RESET_K
        DEFAULT_ELO = RESET_DEFAULT_ELO
    end

    return elo
end
elo = _elo_init()
_elo_init = nil
