--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelCatchMonstersConfig = class("LevelCatchMonstersConfig", LevelConfigData)

LevelCatchMonstersConfig.m_bnBasePro0 = nil
LevelCatchMonstersConfig.m_bnBaseTotalWeight0 = nil
LevelCatchMonstersConfig.m_bnBasePro1 = nil
LevelCatchMonstersConfig.m_bnBaseTotalWeight1 = nil
LevelCatchMonstersConfig.m_bnBasePro2 = nil
LevelCatchMonstersConfig.m_bnBaseTotalWeight2 = nil
LevelCatchMonstersConfig.m_bnBasePro3 = nil
LevelCatchMonstersConfig.m_bnBaseTotalWeight3 = nil


function LevelCatchMonstersConfig:parsePro( value )
    local verStrs = util_string_split(value,";")

    local proValues = {}
    local totalWeight = 0
    for i=1,#verStrs do
        local proValue = verStrs[i]
        local vecPro = util_string_split(proValue,"-")

        proValues[#proValues + 1] = vecPro
        totalWeight = totalWeight + vecPro[2]
    end
    return proValues , totalWeight
end

function LevelCatchMonstersConfig:parseSelfConfigData(colKey, colValue)
    
    if colKey == "BN_Base1_pro0" then
        self.m_bnBasePro0 , self.m_bnBaseTotalWeight0 = self:parsePro(colValue)
    elseif colKey == "BN_Base1_pro1" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    elseif colKey == "BN_Base1_pro2" then
        self.m_bnBasePro2 , self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
    elseif colKey == "BN_Base1_pro3" then
        self.m_bnBasePro3 , self.m_bnBaseTotalWeight3 = self:parsePro(colValue)
    end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelCatchMonstersConfig:getFixSymbolPro0( )
    local value = self:getValueByPros(self.m_bnBasePro0 , self.m_bnBaseTotalWeight0)
    return value[1]
end

function LevelCatchMonstersConfig:getFixSymbolPro1( )
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end

function LevelCatchMonstersConfig:getFixSymbolPro2( )
    local value = self:getValueByPros(self.m_bnBasePro2 , self.m_bnBaseTotalWeight2)
    return value[1]
end

function LevelCatchMonstersConfig:getFixSymbolPro3( )
    local value = self:getValueByPros(self.m_bnBasePro3 , self.m_bnBaseTotalWeight3)
    return value[1]
end

--[[
    @desc: 根据权重返回对应的值
    time:2018-11-28 16:28:13
    --@proValues: 
    --@totalWeight: 
    @return:
]]
function LevelCatchMonstersConfig:getValueByPros( proValues , totalWeight )
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

return  LevelCatchMonstersConfig