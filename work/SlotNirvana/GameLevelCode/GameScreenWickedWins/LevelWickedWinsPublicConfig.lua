local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelWickedWinsPublicConfig = class("LevelWickedWinsPublicConfig", LevelConfigData)

LevelWickedWinsPublicConfig.m_bnBasePro1 = nil
LevelWickedWinsPublicConfig.m_bnBaseTotalWeight1 = nil


function LevelWickedWinsPublicConfig:parsePro( value )
    local verStrs = util_string_split(value,";")

    local proValues = {}
    local totalWeight = 0
    for i=1,#verStrs do
        local proValue = verStrs[i]
        local vecPro = util_string_split(proValue,"-" , true)

        proValues[#proValues + 1] = vecPro
        totalWeight = totalWeight + vecPro[2]
    end
    return proValues , totalWeight
end

function LevelWickedWinsPublicConfig:parseSelfConfigData(colKey, colValue)
    
    if colKey == "BN_Base1_pro" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end

function LevelWickedWinsPublicConfig:getFixSymbolPro( )
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end

function LevelWickedWinsPublicConfig:getValueByPros( proValues , totalWeight )
    local random = util_random(1,totalWeight)
    local preValue = 0
    local triggerValue = -1
    for i=1,#proValues do
        local value = proValues[i]
        if value[2] ~= 0 then
            if random > preValue and random <= preValue + value[2] then
                triggerValue = value
                break
            end
            preValue = preValue + value[2]
        end
    end

    return triggerValue

end

return LevelWickedWinsPublicConfig
