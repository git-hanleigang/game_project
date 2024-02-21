--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于MiracleEgyptConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFarmMiniConfig = class("LevelFarmMiniConfig", LevelConfigData)

LevelFarmMiniConfig.m_gameLevel = nil

function LevelFarmMiniConfig:ctor()
      LevelConfigData.ctor(self)
end



function LevelFarmMiniConfig:parseSelfConfigData(colKey, colValue)
    
      if colKey == "BN_Base1_pro" then
          self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
      end
  end
  --[[
      time:2018-11-28 16:39:26
      @return: 返回中的倍数
  ]]
  function LevelFarmMiniConfig:getFixSymbolPro( )
      local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
      return value[1]
  end

function LevelFarmMiniConfig:setGameLevel( level )
      self.m_gameLevel = level
end

function LevelFarmMiniConfig:checkChangToWild(colIndex )
      local change = false
      if self.m_gameLevel then
            
            if self.m_gameLevel:checkIsWildCol(colIndex ) then
                  change = true
            end
      end 


      return change
end

function LevelFarmMiniConfig:getFreeSpinType( )
      local fsType = 0

      if self.m_gameLevel then
            
            local selfdata = self.m_gameLevel.m_parent.m_runSpinResultData.p_selfMakeData or {}

            local machineFsType = selfdata.freeSpinType 
    
            if machineFsType then
                  fsType = machineFsType  
            end
      end 

      return fsType

end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelFarmMiniConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

      local data = self[colKey]
      if self:checkChangToWild( columnIndex) then
            for i=1,#data do
                  data[i] = 92 -- 变成wild 
            end
      end  

	return data
end


---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelFarmMiniConfig:getNormalReelDatasByColumnIndex(columnIndex)
      
      local colKey = string.format("freespinModeId_%d_%d",self:getFreeSpinType( ),columnIndex)

      local data = self[colKey]
      if self:checkChangToWild( columnIndex) then
            for i=1,#data do
                  data[i] = 92 -- 变成wild 
            end
      end  

	return data
end


return  LevelFarmMiniConfig