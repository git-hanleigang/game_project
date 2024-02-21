--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2020-07-08 15:30:59
]]

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFourInOne_Base_Charms_Config = class("LevelFourInOne_Base_Charms_Config", LevelConfigData)

function LevelFourInOne_Base_Charms_Config:ctor()
      LevelConfigData.ctor(self)
end



function LevelFourInOne_Base_Charms_Config:parseSelfConfigData(colKey, colValue)
    
      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelFourInOne_Base_Charms_Config:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end
  

  

return LevelFourInOne_Base_Charms_Config