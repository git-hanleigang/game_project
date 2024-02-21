
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelApolloConfig = class("LevelApolloConfig", LevelConfigData)

LevelApolloConfig.m_bnBasePro1 = nil
LevelApolloConfig.m_bnBaseTotalWeight1 = nil

function LevelApolloConfig:parsePro( value )
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

function LevelApolloConfig:parseSelfConfigData(colKey, colValue)
    if colKey == "BN_Base1_pro" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    elseif colKey == "free_multiple" then
        self.m_freeBasePro1 , self.m_freeBaseTotalWeight1 = self:parsePro(colValue)
    end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelApolloConfig:getFixSymbolPro()
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end
--获得freespin下的倍数
function LevelApolloConfig:getFreespinMultiple()
    local value = self:getValueByPros(self.m_freeBasePro1 , self.m_freeBaseTotalWeight1)
    return value[1]
end
--[[
    @desc: 根据权重返回对应的值
    time:2018-11-28 16:28:13
    --@proValues:
    --@totalWeight:
    @return:
]]
function LevelApolloConfig:getValueByPros( proValues , totalWeight )
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

return  LevelApolloConfig