--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelCashTornadoConfig = class("LevelCashTornadoConfig", LevelConfigData)

LevelCashTornadoConfig.m_bnBasePro1 = nil
LevelCashTornadoConfig.m_bnBaseTotalWeight1 = nil
LevelCashTornadoConfig.m_bnBasePro2 = nil
LevelCashTornadoConfig.m_bnBaseTotalWeight2 = nil
LevelCashTornadoConfig.m_baseIndex = nil

function LevelCashTornadoConfig:parseSelfConfigData(colKey, colValue)
    
	if colKey == "BN_Base1_pro" then
	    self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
	end
    if colKey == "BN_Base2_pro" then
	    self.m_bnBasePro2 , self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
	end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelCashTornadoConfig:getFixSymbolPro( )
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end

function LevelCashTornadoConfig:getFixSymbolPro2( )
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
function LevelCashTornadoConfig:getValueByPros( proValues , totalWeight )
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

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelCashTornadoConfig:getNormalReelDatasByColumnIndex(columnIndex)
    if not self.m_baseIndex then
        self.m_baseIndex = 1
    end
    local colKey = "reel_cloumn_"..self.m_baseIndex.."_"..columnIndex
    return self[colKey]
end

function LevelCashTornadoConfig:setBaseIndex(index)
    self.m_baseIndex = index
end

return  LevelCashTornadoConfig