require("mod_neural_net")
require("mod_map_wrapper")
require("mod_features")

local evalNet

local function getOtherPlayerN(map, userN)
    for i, p in ipairs(map:getPlanetList()) do
        if not p.neutral and p.owner ~= userN then
            return p.owner
        end
    end
end

function eval_predict_with_map(m, user)
    local enemyN = getOtherPlayerN(m, user.n)
    local f = features.getAll(m, user, m._items[enemyN])
    for _, val in ipairs(f) do
        -- if any feature is undefined, return nil
        -- TODO: stop NaNs in the first place
        if val ~= val then
            error("invalid training data")
            return
        end
    end
    return evalNet:predict(f)[1] * 2 - 1
end

-- TODO: make it work for teams or players
function eval_predict(items, user)
    local m = Map.new(items)
    return eval_predict_with_map(m, user)
end

local weights = {
    {
        {1.6840228, 1.2080216, 1.3890104, 0.6936591, 0.6201604, -1.0781312},
        {0.85501254, 0.14242889, 0.015221793, 0.5609272, 0.15892643, 0.7637075},
        {-1.7778802, -0.98465693, -1.2283139, -0.12462513, -0.33503926, 2.1325994},
        {-0.27260488, 0.021732453, 0.24134208, 0.24100713, -0.059519954, 1.2957598},
        {-0.21612136, -0.41285786, -0.20107973, -0.16087301, 0.44857815, 1.0908333},
        {2.1532454, 0.94359815, 1.0784339, 1.0867945, 0.7331096, -1.3116993},
        {0.23970893, 0.20522864, -0.045297023, -0.23538433, 0.44485608, 0.9502267},
        {0.69320583, 0.26774937, -0.17918186, 0.5230778, -0.25542137, 1.209758},
        {-0.054367118, -0.12507842, 0.028775942, -0.1498849, -0.10822733, 1.7348676}
    },
    {
        {0.87698644},
        {1.0883582},
        {0.8230581},
        {0.43343285},
        {0.52687174},
        {-0.64260894},
        {-0.6699466}
    }
}

function initTestEval()
    evalNet = nn.new()
    for i = 1, #weights - 1 do
        evalNet:addLayer(weights[i], "relu", true)
    end
    evalNet:addLayer(weights[#weights], "sigmoid", true)
end
initTestEval()
initTestEval = nil
