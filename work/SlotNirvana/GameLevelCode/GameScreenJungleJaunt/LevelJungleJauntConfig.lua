--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelJungleJauntConfig = class("LevelJungleJauntConfig", LevelConfigData)

LevelJungleJauntConfig.m_buffReelData = {}

LevelJungleJauntConfig.m_bnBasePro1 = nil
LevelJungleJauntConfig.m_bnBaseTotalWeight1 = nil

LevelJungleJauntConfig.m_bnBasePro2 = nil
LevelJungleJauntConfig.m_bnBaseTotalWeight2 = nil

function LevelJungleJauntConfig:parsePro( value )
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

function LevelJungleJauntConfig:parseSelfConfigData(colKey, colValue)
    
    if colKey == "bonus1" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    elseif colKey == "bonus2" then
        self.m_bnBasePro2 , self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
    elseif colKey == "buffReel_1" then
        -- buff1卷轴的假滚
        self.m_buffReelData[1] = self:parseSelfDefinePron(colValue)
    elseif colKey == "buffReel_2" then
        -- buff2卷轴的假滚
        self.m_buffReelData[2] = self:parseSelfDefinePron(colValue)
    end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelJungleJauntConfig:getBonus1FixSymbolPro()
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelJungleJauntConfig:getBonus2FixSymbolPro()
    local value = self:getValueByPros(self.m_bnBasePro2 , self.m_bnBaseTotalWeight2)
    return value[1]
end

--[[
    @desc: 根据权重返回对应的值
    time:2018-11-28 16:28:13
    --@proValues: 
    --@totalWeight: 
    @return:
]]
function LevelJungleJauntConfig:getValueByPros( proValues , totalWeight )
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

--buff棋盘假滚
function LevelJungleJauntConfig:getReSpinBuffReelData(_reelType)
    local reelData = self.m_buffReelData[_reelType]
    return reelData
end


return  LevelJungleJauntConfig