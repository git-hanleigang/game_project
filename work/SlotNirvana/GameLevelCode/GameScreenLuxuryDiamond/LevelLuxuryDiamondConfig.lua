
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelLuckeyMoneyConfig = class("LevelLuckeyMoneyConfig", LevelConfigData)

LevelLuckeyMoneyConfig.m_bnBasePro1 = nil
LevelLuckeyMoneyConfig.m_bnBaseTotalWeight1 = nil

LevelLuckeyMoneyConfig.m_bnBasePro2 = nil
LevelLuckeyMoneyConfig.m_bnBaseTotalWeight2 = nil

LevelLuckeyMoneyConfig.m_bnBasePro3 = nil
LevelLuckeyMoneyConfig.m_bnBaseTotalWeight3 = nil

LevelLuckeyMoneyConfig.SYMBOL_LEVEL1  = 200 -- 自定义的小块类型
LevelLuckeyMoneyConfig.SYMBOL_LEVEL2  = 201 -- 自定义的小块类型
LevelLuckeyMoneyConfig.SYMBOL_LEVEL3  = 202 -- 自定义的小块类型

--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelLuckeyMoneyConfig:ctor()
      LevelConfigData.ctor(self)
end

function LevelLuckeyMoneyConfig:parseSelfConfigData(colKey,colValue)
	if colKey == "BN_Base1_pro"  then
		self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    elseif colKey == "BN_Base2_pro"  then
        self.m_bnBasePro2 , self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
    elseif colKey == "BN_Base3_pro"  then
        self.m_bnBasePro3 , self.m_bnBaseTotalWeight3 = self:parsePro(colValue)
	end
end

function LevelLuckeyMoneyConfig:getFixSymbolPro(symbolType)
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    if symbolType == self.SYMBOL_LEVEL2 then
        value = self:getValueByPros(self.m_bnBasePro2 , self.m_bnBaseTotalWeight2)
    elseif symbolType == self.SYMBOL_LEVEL3 then
        value = self:getValueByPros(self.m_bnBasePro3 , self.m_bnBaseTotalWeight3)
    end
    return value[1]
end

return  LevelLuckeyMoneyConfig