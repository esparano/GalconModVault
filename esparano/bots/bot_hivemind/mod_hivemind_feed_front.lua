require("mod_hivemind_action")
require("mod_hivemind_utils")

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
        instance.MAX_SHIPS_TO_SEND = 50

        return instance
    end

    -- TODO: cross-front actions (fronts never help one another! Is that okay and we will assume that defense /attacking will suffice?)
    -- TODO: limit to a certain amount like max 50 ships per send??
    function FeedFrontMind:suggestActions(plans)
        local candidates = {}

        candidates = common_utils.combineLists(candidates, self:suggestFeedFronts(plans))

        return candidates
    end

    function FeedFrontMind:gradeAction(action, plans)
       
    end

    -- split map into "sub-maps", performing full enemy attacks on each front planet. 
    -- front planets' desired ship proportions are balanced by an auto-optimized distribution equation
    -- Reassign neutrals to different mini-maps until balanced, roughly. 
    -- For each mini-map, attempt a max-efficiency multi-select tunnel, selecting % that sends most total (unreserved) ships to alias
    -- Grade priority based on total ships sent as well as

    -- for each source, suggest a (trainable) best front to feed
    function FeedFrontMind:suggestFeedFronts(plans)
        local candidates = {}
        
        -- if we reserve ships to attack the neutral planet, will we lose a front planet in a full attack?
        local friendlyPlannedCapturesSet = Set.new()
        for i,p in ipairs(plans) do 
            -- add expansion targets here
            if p.mindName == "Expand" then
                friendlyPlannedCapturesSet:add(p.data.targetN)
            end
        end
        -- TODO: memoize/centralize getFrontPlanets calls
        local frontPlanets = self.mapTunnels:getFrontPlanets(self.botUser, friendlyPlannedCapturesSet)
        local frontPlanetNs = common_utils.map(frontPlanets, function(p) return p.n end)
        local frontPlanetNSet = Set.new(frontPlanetNs)
        local nonFrontPlanets = common_utils.filter(self.map:getPlanetList(self.botUser), function(p) return not frontPlanetNSet:contains(p.n) end)

        while #nonFrontPlanets > 0 do
            local sourceInfo = self:getBestFeedSource(nonFrontPlanets)
            -- can't feed if there are no planets to feed from or no planets can send at least 1 ship
            if not sourceInfo then 
                break
            end
    
            local frontPlanetPs = common_utils.map(frontPlanets, function(p) return p.ships end)
            
            local targetInfo = self:getBestFeedTarget(frontPlanets, sourceInfo.p, plans)
            if not targetInfo then 
                break
            end
    
            local initialPriority = self:getFeedPriority(sourceInfo, targetInfo)
            local alias = self.mapTunnels:getTunnelAlias(sourceInfo.p, targetInfo.p)
            local desc = "Feed@" .. getPlanetDesc(self.map, self.botUser, targetInfo.p)
            -- no plan because this is not a multi-turn action
            local action = Action.newSend(initialPriority, self, desc, {}, {sourceInfo.p}, alias, sourceInfo.percent)
            table.insert(candidates, action)

            nonFrontPlanets = common_utils.filter(nonFrontPlanets, function(p) return p.n ~= sourceInfo.p.n end)
        end

        return candidates
    end

    -- introduce various nonlinearities 
    -- Should this use source/target weights?
    function FeedFrontMind:getFeedPriority(sourceInfo, targetInfo)
        local priority = self.feedSendAmountWeight * sourceInfo.amountSent ^ self.feedSendAmountExponent / 3 + self.feedDistWeight * targetInfo.dist ^ self.feedDistExponent / 300 
        priority = priority * self.overallWeight + self.overallBias - 1
        return priority
    end

    -- TODO: if aliases are the same, merge weights?
    function FeedFrontMind:getBestFeedTarget(frontPlanets, source, plans)
        local frontWeights = self:getDesiredFrontWeights(frontPlanets, plans)
        
        local targetDatas = common_utils.map(frontPlanets, function(front)
            local dist = self.mapTunnels:getSimplifiedTunnelDist(source, front)
            local weight = frontWeights[front] ^ self.targetWeightExponent / dist ^ self.targetDistExponent 
                - dist ^ self.targetDistDiscountExponent * self.targetDistDiscount / 100000
            return {
                p = front, 
                dist = dist,
                weight = weight
            }
        end)
        
        return common_utils.find(targetDatas, function(data) return data.weight end)
    end

    function FeedFrontMind:getBestFeedSource(nonFrontPlanets)
        local sourceDatas = {}
        for i,p in ipairs(nonFrontPlanets) do
            local shipsReserved = self.mapFuture.reservations:getShipReservations(p)
            local amountToSend = math.min(self.MAX_SHIPS_TO_SEND, p.ships)
            local percent = getPercentToUseWithReservation(p, amountToSend, shipsReserved)
            local amountSent = getAmountSent(p, percent)
            if amountSent > 0 then 
                table.insert(sourceDatas, {
                    p = p, 
                    percent = percent,
                    amountSent = amountSent
                })
            end
        end
        return common_utils.find(sourceDatas, function(data) return data.amountSent end)
    end

    function FeedFrontMind:getDesiredFrontWeights(frontPlanets, plans)
        local weights = {}
        local totalWeight = 0
        local minWeight = 0
        for i,front in ipairs(frontPlanets) do 
            weights[front] = self:getDesiredFrontWeight(front, plans)
            totalWeight = totalWeight + weights[front]
            if weights[front] < minWeight then 
                minWeight = weights[front]
            end
        end

        local shiftedTotalWeight = common_utils.toPrecision(totalWeight - #frontPlanets * minWeight, 3) 
        for i,front in ipairs(frontPlanets) do 
            -- if shiftedTotalWeight == 0, the weights must all be equal
            if shiftedTotalWeight == 0 then 
                weights[front] = 1/#frontPlanets
            else
                weights[front] = math.min(1, (weights[front] - minWeight) / shiftedTotalWeight)
            end 
        end

        return weights
    end

    -- TODO: add more stuff for front weight like distance to nearby enemies?
    function FeedFrontMind:getDesiredFrontWeight(front, plans)
        local weight = self.frontWeightFrontProd * front.production / 50

        -- TODO: is this right to pass no reservations???
        -- must pass no-reservations for enemy
        -- TODO: this doesn't take into account expansion plans
        local fullAttackData = self.mapFuture:simulateFullAttack(self.map, self.mapTunnels, self.botUser, front, MapReservations.new(self.map._items), plans)
        weight = weight - fullAttackData.netShips * self.frontWeightNetShips + fullAttackData.enemyProdFromTarget * self.frontWeightStolenProd

        for i,enemy in ipairs(self.map:getNonNeutralPlanetAndFleetList(self.map:getEnemyUser(self.botUser))) do 
            -- avoid divide by zero errors
            local dist
            if enemy.is_fleet then
                dist = self.mapTunnels:getApproxFleetTunnelDist(enemy, front)
            else
                dist = self.mapTunnels:getSimplifiedTunnelDist(enemy, front)
            end
            local distToEnemy = math.max(5, dist - 5 * self.frontWeightEnemyDistIntercept)
            local production = enemy.production or 0
            -- let's say 50 is an average distance to an enemy unit (1.25 seconds travel is a bit low... hmm...)
            local enemyWeight = 50 * self.frontWeightEnemyOverall * (
                (enemy.ships ^ self.frontWeightEnemyShipsExponent + self.frontWeightEnemyProdShipsBalance * production ^ self.frontWeightEnemyProdExponent)
                / distToEnemy ^ self.frontWeightEnemyDistExponent
            )
           
            weight = weight + enemyWeight
        end

        return weight
    end

    return FeedFrontMind
end
FeedFrontMind = _m_init()
_m_init = nil
