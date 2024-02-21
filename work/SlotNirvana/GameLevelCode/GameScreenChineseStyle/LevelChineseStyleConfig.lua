--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelChineseStyleConfig = class("LevelChineseStyleConfig", LevelConfigData)

LevelChineseStyleConfig.m_bnBasePro1 = nil
LevelChineseStyleConfig.m_bnBaseTotalWeight1 = nil

function LevelChineseStyleConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelChineseStyleConfig:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Base1_pro" then
            self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
        end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelChineseStyleConfig:getBnBasePro1( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
end

return  LevelChineseStyleConfig