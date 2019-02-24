require("mod_map_builder")

function genMap()
    local map = MapBuilder.new()
    local neutralUser = map:addUser(true)
    local friendlyUser = map:addUser(false)
    local enemyUser = map:addUser(false)

    local users = {neutralUser, friendlyUser, enemyUser}
    local rand = function(a)
        return a * math.random()
    end
    for i, user in pairs(users) do
        for i = 1, 5 do
            map:addPlanet(rand(100), rand(100), rand(10) + 10, rand(100), rand(100), user)
        end
    end

    return map:build()
end
