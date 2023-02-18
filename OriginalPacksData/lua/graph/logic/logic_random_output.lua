class 'logic_random_output' ( LuaGraphNodeSelector )

function logic_random_output:__init()
    LuaGraphNodeSelector.__init(self, self)
end

function logic_random_output:init()
end

function logic_random_output:GetWeightedRandom(maxValue)
    local totalWeight = 0.0

    local values = {}
    for it=0,maxValue do

        local rangeStart = totalWeight

        if self.data:HasFloat(tostring(it)) then
            totalWeight = totalWeight + self.data:GetFloat(tostring(it))
        else
            totalWeight = totalWeight + 1.0
        end

        local rangeEnd = totalWeight

        LogService:Log("  * Weight: [" .. tostring(it) .. "] - " .. tostring(totalWeight))

        values[it] = { min = rangeStart, max = rangeEnd }
    end

    local rand = math.random(0.0, (totalWeight*100) - 1) / 100
    LogService:Log("  *** Random: " .. tostring(rand))

    for k,v in pairs(values) do
        LogService:Log("  * Key: " .. tostring(k) .. ", range: " .. tostring(v.min) .. " - " .. tostring(v.max) )

        if v.min <= rand and v.max > rand then
            return k;
        end
    end

    Assert(false, "Shouldn't happen!")
end

function logic_random_output:Activated()
    local maxValue = self.data:GetInt("outputs")

    local output = tostring(self:GetWeightedRandom(maxValue-1));
    LogService:Log("Output: " .. output )

    self:SetFinished(output)
end

return logic_random_output