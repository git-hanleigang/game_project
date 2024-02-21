--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelClassicRapid2Config = class("LevelClassicRapid2Config", LevelConfigData)

LevelClassicRapid2Config.SYMBOL_MYSTER = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
LevelClassicRapid2Config.m_MYSTER_RunSymbol = 0

function LevelClassicRapid2Config:ctor()
      LevelConfigData.ctor(self)
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelClassicRapid2Config:getNormalReelDatasByColumnIndex(columnIndex)
	local colKey = "reel_cloumn"..columnIndex

	for i=1,#self[colKey] do
		local symbolType =  self[colKey][i]
		if symbolType ==  self.SYMBOL_MYSTER then
			self[colKey][i] = self.m_MYSTER_RunSymbol
		end

	end


	return self[colKey]
  end

  ---
  -- 获取freespin model 对应的reel 列数据
  --
  function LevelClassicRapid2Config:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	  local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

	  for i=1,#self[colKey] do
		  local symbolType =  self[colKey][i]
		  if symbolType ==  self.SYMBOL_MYSTER then
			self[colKey][i] = self.m_MYSTER_RunSymbol
		  end

	  end

	  return self[colKey]
  end

function LevelClassicRapid2Config:setMysterSymbol( symbolType)
	if type(symbolType) == "number" then
		self.m_MYSTER_RunSymbol = symbolType
	end
end



return  LevelClassicRapid2Config