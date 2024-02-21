---
--zhpx
--2017年12月5日
--LevelGoldenGhostCSVData.lua
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelGoldenGhostCSVData = class("LevelGoldenGhostCSVData",LevelConfigData)

LevelGoldenGhostCSVData.m_bnBasePro1 = nil
LevelGoldenGhostCSVData.m_bnBaseTotalWeight1 = nil

--[[
      @return: 返回中的倍数
--]]
function LevelGoldenGhostCSVData:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
end

function LevelGoldenGhostCSVData:parseSelfConfigData(colKey, colValue)
      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end
end

return LevelGoldenGhostCSVData