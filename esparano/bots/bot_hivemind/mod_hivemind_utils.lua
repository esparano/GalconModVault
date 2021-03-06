require("mod_hivemind_action")
require("mod_hivemind_plan")
require("mod_game_utils")
require("mod_common_utils")
require("mod_set")
 
-- make sure not to send more than 'shipsReserved' can afford
function getPercentToUseWithReservation(source, ships, shipsReserved)
    local percentReserved = 0
    if shipsReserved > 0 then
        percentReserved = game_utils.percentToUse(source, shipsReserved)
    end

    local desiredPercentToUse = game_utils.percentToUse(source, ships)
    return math.min(100 - percentReserved, desiredPercentToUse)
end

function getAmountSent(source, percent)
    local amt = source.ships * percent / 100
    if amt < 1 then amt = 0 end 
    return amt
end

function getPlanetDesc(map, botUser, neutral)
    local home = getHome(map, botUser)
    local enemyHome = getHome(map, map:getEnemyUser(botUser))
    local ownership = "My"
    if not home and not enemyHome then 
        ownership = "Nobody's"
    elseif not home or enemyHome and game_utils.distance(enemyHome, neutral) < game_utils.distance(home, neutral) then 
        ownership = "Their"
    end
    return ownership .. common_utils.round(neutral.ships)
end

function getNetIncomingAndPresentShips(mapFuture, target)
    return target.ships - mapFuture:getNetIncomingShips(target)
end

-- TODO: this is really an approximation. A bit hacky
function getHome(map, user)
    return common_utils.find(map:getPlanetList(user), function(p) return p.production end)
end

function debugDrawTunnels(botUser, map, mapTunnels, owner, targets)
    local tunnelPairs = {}
    for i,source in ipairs(map:getPlanetList(owner)) do 
        local closestTarget = getClosestTarget(mapTunnels, source, targets)
        if closestTarget ~= nil and source.n ~= closestTarget.n then
            local tunnelAlias = mapTunnels:getTunnelAlias(source, closestTarget)
            table.insert(tunnelPairs, {source = source, target = tunnelAlias})
        end
    end
    DEBUG.debugDrawPaths(botUser, tunnelPairs, owner)
end
