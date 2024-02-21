--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelPiggyLegendPirateConfig = class("LevelPiggyLegendPirateConfig", LevelConfigData)

LevelPiggyLegendPirateConfig.m_bnBasePro1 = nil
LevelPiggyLegendPirateConfig.m_bnBaseTotalWeight1 = nil


function LevelPiggyLegendPirateConfig:parsePro( value )
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

function LevelPiggyLegendPirateConfig:parseSelfConfigData(colKey, colValue)
    
    if colKey == "BN_Base1_pro" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelPiggyLegendPirateConfig:getFixSymbolPro( )
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end


--[[
    @desc: 根据权重返回对应的值
    time:2018-11-28 16:28:13
    --@proValues: 
    --@totalWeight: 
    @return:
]]
function LevelPiggyLegendPirateConfig:getValueByPros( proValues , totalWeight )
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
-- 根据ccb name 获取信号图片
--
function LevelPiggyLegendPirateConfig:getSymbolImageByCCBName(ccbName)
	if self.p_showScoreIamge == 0 then  -- 表明不使用图片滚动的方式来代替Node创建
		return nil
	end
	if self[ccbName] == nil then
		-- do nothing
		return nil
    end
    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        if ccbName == "Socre_PiggyLegendPirate_Bonus1" then
            ccbName = "Socre_PiggyLegendPirate_Bonus4"
        end
    end

	return self[ccbName]
end

return  LevelPiggyLegendPirateConfig