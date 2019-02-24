-- TODO: documentation
function _features_init()
    local features = {}

    local TOTAL_SHIPS_NORMALIZATION_FACTOR = 100
    local TOTAL_PROD_NORMALIZATION_FACTOR = 100
    local PROD_COM_DIST_NORMALIZATION_FACTOR = 300
    local SHIPS_COM_DIST_NORMALIZATION_FACTOR = 300

    function features.totalShips(map, user)
        return map:totalShips(user.n) / TOTAL_SHIPS_NORMALIZATION_FACTOR
    end

    function features.totalProd(map, user)
        return map:totalProd(user.n) / TOTAL_PROD_NORMALIZATION_FACTOR
    end

    function features.prodFraction(map, user, enemy)
        local userProd = map:totalProd(user.n)
        local enemyProd = map:totalProd(enemy.n)
        return userProd / (userProd + enemyProd)
    end

    function features.shipsFraction(map, user, enemy)
        local userShips = map:totalShips(user.n)
        local enemyShips = map:totalShips(enemy.n)
        return userShips / (userShips + enemyShips)
    end

    local function centerOfMass(items, property)
        local weightedX, weightedY, totalX, totalY = 0, 0, 0, 0
        for _, p in ipairs(items) do
            weightedX = weightedX + p[property] * p.x
            weightedY = weightedY + p[property] * p.y
            totalX = totalX + p[property]
            totalY = totalY + p[property]
        end
        return {
            x = weightedX / totalX,
            y = weightedY / totalY
        }
    end

    local function cOMDistance(a, b)
        local xDiff = a.x - b.x
        local yDiff = a.y - b.y
        return math.sqrt(xDiff * xDiff + yDiff * yDiff)
    end

    function features.prodCenterOfMassDistance(map, user, enemy)
        local userCOM = centerOfMass(map:getPlanetList(user.n), "production")
        local enemyCOM = centerOfMass(map:getPlanetList(enemy.n), "production")
        return cOMDistance(userCOM, enemyCOM) / PROD_COM_DIST_NORMALIZATION_FACTOR
    end

    -- includes fleets
    function features.shipsCenterOfMassDistance(map, user, enemy)
        local userCOM = centerOfMass(map:getPlanetAndFleetList(user.n), "ships")
        local enemyCOM = centerOfMass(map:getPlanetAndFleetList(enemy.n), "ships")
        return cOMDistance(userCOM, enemyCOM) / SHIPS_COM_DIST_NORMALIZATION_FACTOR
    end

    -- number of ships that would be gained by sending a fleet from "from" to "to" before horizon seconds
    -- including production after capture and subtracting
    -- "from" may be a fleet so this can be used for redirecting
    -- only used for neutral planets
    function returnOnNeutral(to)
        local timeDist = distToTime(distance(to, _playerCenters[USER]))
        if S.horizon < timeDist then
            return -1000000
        end -- won't produce enough ships by the time they are potentially needed
        return producedNonNeutral(to, S.horizon - timeDist) - to.ships -- cost to capture plus ship production before S.horizon
    end

    function features.getAll(map, user, enemy)
        local f = {}
        table.insert(f, features.totalShips(map, user))
        table.insert(f, features.totalProd(map, user))
        table.insert(f, features.totalShips(map, enemy))
        table.insert(f, features.totalProd(map, enemy))
        table.insert(f, features.prodFraction(map, user, enemy))
        table.insert(f, features.shipsFraction(map, user, enemy))
        table.insert(f, features.prodCenterOfMassDistance(map, user, enemy))
        table.insert(f, features.shipsCenterOfMassDistance(map, user, enemy))
        return f
    end

    return features
end
features = _features_init()
_features_init = nil