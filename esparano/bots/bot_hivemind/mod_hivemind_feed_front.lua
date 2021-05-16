require("mod_hivemind_action")
--[[
-suggests shuttling to nearest front planet
-grades moves based on whether headed from or away from front (handle penalty separately maybe?)
-prefer shuttling to front rather than sending from vulnerable planets usually?
]]
function _m_init()
    local FeedFrontMind = {}

    function FeedFrontMind.new(params)
        local instance = {}
        for k, v in pairs(FeedFrontMind) do
            instance[k] = v
        end
        for k,v in pairs(params) do 
            instance[k] = v
        end

        instance.name = "FeedFront"

        return instance
    end

    -- TODO: cross-front actions as well as to-enemy-center-of-mass actions.
    -- TODO: limit to a certain amount like max 50 ships per send??
    function FeedFrontMind:suggestActions(map, mapTunnels, mapFuture, botUser)
        local candidates = {}

        candidates = common_utils.combineLists(candidates, self:suggestSimpleFeedActions(map, mapTunnels, mapFuture, botUser))

        return candidates
    end

    function FeedFrontMind:gradeAction(map, mapTunnels, mapFuture, botUser, action)
       
    end

    function FeedFrontMind:suggestSimpleFeedActions(map, mapTunnels, mapFuture, botUser, action)
        local candidates = {}

        local enemyUser = map:getEnemyUser(botUser)
        local enemyHome = self:getHome(map, enemyUser)

        local sources = map:getPlanetList(botUser)
        for i,source in ipairs(sources) do 
            
            local alias = mapTunnels:getTunnelAlias(source.n, enemyHome.n)
            -- if feedAlias.owner ~= enemyUser.n then 

            local reservations = mapFuture:getReservations()[source.n] or 0
            local percentReserved = 0
            if reservations > 0 then
                percentReserved = game_utils.percentToUse(source, reservations)
            end
            -- make sure not to send more than 'reservations' can afford, and also make sure that the amount to send is at least 5%
            local percentToUse = 100 - percentReserved
            if percentToUse >= 5 then 
                local desc = "Feed@EHome"
                local initialPriority = self:getBasicFeedPriority(source, percentToUse, alias, enemyHome, mapTunnels)

                -- no plan because this is not a multi-turn action
                local action = Action.newSend(initialPriority, self, desc, {}, {source}, alias, percentToUse)
                table.insert(candidates, action)
            end
            
        end

        return candidates
    end

    -- introduce various nonlinearities 
    function FeedFrontMind:getBasicFeedPriority(source, percentToUse, alias, target, mapTunnels)
        local amountToSend = source.ships * percentToUse / 100

        local distToTarget = mapTunnels:getSimplifiedTunnelDist(source.n, target.n)

        local initialPriority = self.basicFeedFrontSendAmountWeight * amountToSend / 5 + self.basicFeedFrontDistWeight * distToTarget / 300 
        initialPriority = initialPriority * self.basicFeedFrontOverallWeight
        return initialPriority
    end

    function FeedFrontMind:getHome(map, user)
        return common_utils.find(map:getPlanetList(user.n), function(p) return p.production end)
    end

    return FeedFrontMind
end
FeedFrontMind = _m_init()
_m_init = nil
