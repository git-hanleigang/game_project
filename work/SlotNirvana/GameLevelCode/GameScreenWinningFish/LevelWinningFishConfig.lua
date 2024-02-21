--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelWinningFishConfig = class("LevelWinningFishConfig", LevelConfigData)

LevelWinningFishConfig.m_bnBasePro1 = nil
LevelWinningFishConfig.m_bnBaseTotalWeight1 = nil

function LevelWinningFishConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelWinningFishConfig:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Base1_pro" then
            self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      elseif colKey == "BN_Base2_pro" then
            self.m_bnBasePro2 , self.m_bnBaseTotalWeight2 = self:parsePro(colValue)
      end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelWinningFishConfig:getBnBasePro(type)
      if type == 1 then
            local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
            return value[1]
      else
            local value = self:getValueByPros(self.m_bnBasePro2 , self.m_bnBaseTotalWeight2)
            return value[1]
      end
      
end

--需要提高层级的类型
function LevelWinningFishConfig:checkSpecialSymbol(symbolType)
	if not symbolType then
		return false
	end

	if not self.p_specialSymbolList or #self.p_specialSymbolList== 0 then
		return false
      end
      --预告中奖link图标层级修改
      if self.m_machine and self.m_machine.SYMBOL_BONUS_LINK == symbolType and self.m_machine.m_isRespin_normal then
            return true
      elseif self.m_machine and globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            --配置的特殊层级信号
            for i=1,#self.p_specialSymbolList do
	      	if self.p_specialSymbolList[i] == symbolType then
	      		return true
	      	end
	      end
      end
	
	return false
end

return  LevelWinningFishConfig