--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFloweryPixieConfig = class("LevelFloweryPixieConfig", LevelConfigData)


LevelFloweryPixieConfig.SYMBOL_MYSTER_ONE = 105
LevelFloweryPixieConfig.SYMBOL_MYSTER_TWO = 106
LevelFloweryPixieConfig.m_MYSTER_RunSymbol_ONE  = 6
LevelFloweryPixieConfig.m_MYSTER_RunSymbol_TWO  = 7
LevelFloweryPixieConfig.SYMBOL_SCATTER_GLOD  = 97

LevelFloweryPixieConfig.m_bnBasePro1 = nil
LevelFloweryPixieConfig.m_bnBaseTotalWeight1 = nil

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelFloweryPixieConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex

    local rundata = {}

    for i=1,#self[colKey] do
      local symbolType =  self[colKey][i]

      if symbolType ==  self.SYMBOL_MYSTER_ONE then
              
        symbolType = self.m_MYSTER_RunSymbol_ONE

      elseif symbolType ==  self.SYMBOL_MYSTER_TWO then

        symbolType = self.m_MYSTER_RunSymbol_TWO

      elseif symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        
        local num =  math.random(1,10)
        if num <= 4 then
            symbolType = self.SYMBOL_SCATTER_GLOD
        end

      end
  
      table.insert(rundata,symbolType)

    end
  


	return rundata
end


function LevelFloweryPixieConfig:parseSelfConfigData(colKey, colValue)
    
  if colKey == "BN_Base1_pro" then
      self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
  end
end
--[[
  time:2018-11-28 16:39:26
  @return: 返回中的倍数
]]
function LevelFloweryPixieConfig:getFixSymbolPro( )
  local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
  return value[1]
end


---
-- 获取freespin model 对应的reel 列数据
--
function LevelFloweryPixieConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

    local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

    local rundata = {}

    for i=1,#self[colKey] do
        local symbolType =  self[colKey][i]

        if symbolType ==  self.SYMBOL_MYSTER_ONE then
                
            symbolType = self.m_MYSTER_RunSymbol_ONE

        elseif symbolType ==  self.SYMBOL_MYSTER_TWO then

            symbolType = self.m_MYSTER_RunSymbol_TWO
          
        elseif symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
          
            local num =  math.random(1,10)
            if num <= 4 then
                symbolType = self.SYMBOL_SCATTER_GLOD
            end

        end

        table.insert(rundata,symbolType)

    end

    return rundata
    
end

function LevelFloweryPixieConfig:setMysterSymbol( symbolType1,symbolType2)
	if type(symbolType1) == "number" then
		  self.m_MYSTER_RunSymbol_ONE = symbolType1
  end
    
  if type(symbolType2) == "number" then
		  self.m_MYSTER_RunSymbol_TWO = symbolType2
	end
end


return  LevelFloweryPixieConfig