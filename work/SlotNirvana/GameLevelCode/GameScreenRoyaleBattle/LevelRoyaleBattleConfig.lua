--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelRoyaleBattleConfig = class("LevelRoyaleBattleConfig", LevelConfigData)

LevelRoyaleBattleConfig.m_bnBasePro1 = nil
LevelRoyaleBattleConfig.m_bnBaseTotalWeight1 = nil


function LevelRoyaleBattleConfig:parsePro( value )
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

function LevelRoyaleBattleConfig:CsvDataRule_ParseSelfData(colKey, colValue)
    
    if colKey == "BN_Base1_pro" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelRoyaleBattleConfig:getFixSymbolPro( )
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
function LevelRoyaleBattleConfig:getValueByPros( proValues , totalWeight )
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

--需要提高层级的类型
function LevelRoyaleBattleConfig:checkSpecialSymbol(symbolType)
	if not symbolType then
		return false
	end
	--!!! 不在滚动状态时 不需要提层
    if globalData.slotRunData.gameSpinStage == IDLE  then
        return false
    end

	--是否所有关卡SCATTER都提高层级
	-- if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
	-- 	return true
	-- end

	if not self.p_specialSymbolList or #self.p_specialSymbolList== 0 then
		return false
	end
	--配置的特殊层级信号
	for i=1,#self.p_specialSymbolList do
		if self.p_specialSymbolList[i] == symbolType then
			return true
		end
	end
	return false
end

return  LevelRoyaleBattleConfig