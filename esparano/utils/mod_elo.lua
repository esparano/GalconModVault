function _elo_init()

local ELOS = {}
local DEFAULT_ELO = 1500
local K = 16

local function get_elo(user)
    ELOS[user] = ELOS[user] or DEFAULT_ELO
    return ELOS[user]
end

local function set_elo(user, elo)
    ELOS[user] = elo
end

local function get_elos()
    return ELOS
end

local function _win_probability(r1, r2)
    return 1 - 1 / (1 + math.pow(10, (r1 - r2) / 400));
end

local function _calculate_new_elos(r1, r2, first_won) 
    local actual = first_won and 1 or 0
    local expected = _win_probability(r1, r2)
    local change = K * (actual - expected)
    return r1 + change, r2 - change
end

local function update_elo(user1, user2, first_won) 
    local r1 = get_elo(user1)
    local r2 = get_elo(user2)
    r1, r2 = _calculate_new_elos(r1, r2, first_won)
    set_elo(user1, r1)
    set_elo(user2, r2)
end

local function get_default_elo()
    return DEFAULT_ELO
end

local function set_default_elo(elo)
    DEFAULT_ELO = elo
end

local function get_k()
    return K
end

local function set_k(k)
    K = k
end

local function print_rankings()
    for user,elo in pairs(ELOS) do
        print("user: " .. user .. ", elo: " .. elo)
    end
end

local elo = {
    update_elo = update_elo,
    get_elo = get_elo,
    set_elo = set_elo,
    get_elos = get_elos,
    get_default_elo = get_default_elo,
    set_default_elo = set_default_elo,
    get_k = get_k,
    set_k = set_k,
    print_rankings = print_rankings,
    _win_probability = _win_probability,
    _calculate_new_elos = _calculate_new_elos
}
return elo

end; elo = _elo_init(); _elo_init = nil
