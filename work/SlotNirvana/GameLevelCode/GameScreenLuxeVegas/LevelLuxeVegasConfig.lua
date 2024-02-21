--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelLuxeVegasConfig = class("LevelLuxeVegasConfig", LevelConfigData)

LevelLuxeVegasConfig.m_bnBasePro1 = nil
LevelLuxeVegasConfig.m_bnBaseTotalWeight1 = nil

function LevelLuxeVegasConfig:ctor()
      LevelConfigData.ctor(self)
end


function LevelLuxeVegasConfig:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Base1_pro" then
            self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end
end
--[[
    time:2018-11-28 16:39:26
    @return: 返回中的倍数
]]
function LevelLuxeVegasConfig:getBnBasePro(type)
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
end

return  LevelLuxeVegasConfig
