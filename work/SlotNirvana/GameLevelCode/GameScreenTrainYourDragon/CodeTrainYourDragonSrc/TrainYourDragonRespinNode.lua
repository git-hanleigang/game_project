

local TrainYourDragonNode = class("TrainYourDragonNode", util_require("Levels.RespinNode"))
-- FIX IOS 139 1
--获取小块类型
function TrainYourDragonNode:getBaseNodeType()
    if self.m_runNodeNum == 0 and self.m_runLastNodeType ~= nil then
        if self.m_machine:isFixSymbol(self.m_runLastNodeType) == false then
            return self.m_machine.SYMBOL_SCORE_10
        else
            return self.m_runLastNodeType
        end
    else 
        if self.m_runningData == nil then
            return self:randomRuningSymbolType()
        else
            return self:getRunningSymbolTypeByConfig()
        end
    end
end

--获取随机信号
function TrainYourDragonNode:randomRuningSymbolType()
    local nodeType = nil
    if xcyy.SlotsUtil:getArc4Random() % 5 == 1 and self.m_runNodeNum ~= 0 then
        nodeType = self:getRandomEndType()
        if nodeType == nil then
            nodeType = self:randomSymbolRandomType()
        end
    else 
        nodeType = self:randomSymbolRandomType()
    end
    return nodeType
end

--随机获取end信号
function TrainYourDragonNode:getRandomEndType()
    local randomInfos = {}
    for i = 1,#self.m_symbolTypeEnd do           
        local bRamdom = self.m_symbolTypeEnd[i].bRandom
        if bRamdom == nil or bRamdom == true then
            randomInfos[#randomInfos + 1] = self.m_symbolTypeEnd[i]
        end
    end
    
    if #randomInfos > 0 then
        local totalNum = 0
        for i, v in ipairs(randomInfos) do
            totalNum = totalNum + v.weight
        end
        local randomNum = math.random(0, totalNum)
        totalNum = 0
        local randomIdx = 0
        for i, v in ipairs(randomInfos) do
            totalNum = totalNum + v.weight
            if randomNum <= totalNum then
                randomIdx = i
                break
            end
        end
        local info = randomInfos[randomIdx]
        return info.type
    end
    return nil
end

return TrainYourDragonNode