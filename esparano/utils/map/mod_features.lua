require("mod_map")

-- TODO: documentation
function _features_init()
    local features = {}

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
        return cOMDistance(userCOM, enemyCOM)
    end

    -- includes fleets
    function features.shipsCenterOfMassDistance(map, user, enemy)
        local userCOM = centerOfMass(map:getPlanetAndFleetList(user.n), "ships")
        local enemyCOM = centerOfMass(map:getPlanetAndFleetList(enemy.n), "ships")
        return cOMDistance(userCOM, enemyCOM)
    end

    return features
end
features = _features_init()
_features_init = nil
