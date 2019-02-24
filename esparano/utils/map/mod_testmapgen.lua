require("mod_mapgenhelper")

function genMap()
    local map = mapgenhelper.new()
    local neutralUser = map:createUser(true)
    local friendlyUser = map:createUser(false)
    local enemyUser = map:createUser(false)

    local users = {neutralUser, friendlyUser, enemyUser}
    local rand = function(a) return a * math.random() end 
    for i, user in pairs(users) do
        for i = 1, 5 do
            map:createPlanet(rand(100), rand(100), rand(10) + 10, rand(100), rand(100), user)
        end
    end

    return map:build()
end
