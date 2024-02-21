--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelBingoPriatesConfig = class("LevelBingoPriatesConfig", LevelConfigData)

LevelBingoPriatesConfig.SYMBOL_MYSTER_1 = 101

LevelBingoPriatesConfig.m_MYSTER_RunSymbol_1 = 0


function LevelBingoPriatesConfig:ctor()
      LevelConfigData.ctor(self)
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelBingoPriatesConfig:getNormalReelDatasByColumnIndex(columnIndex)
	local colKey = "reel_cloumn"..columnIndex

	local rundata = {}

	for i=1,#self[colKey] do
		local symbolType =  self[colKey][i]
		if symbolType ==  self.SYMBOL_MYSTER_1 then

			symbolType = self.m_MYSTER_RunSymbol_1

		end

		
		table.insert(rundata,symbolType)

	end


	return rundata
  end

  ---
  -- 获取freespin model 对应的reel 列数据
  --
  function LevelBingoPriatesConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	  local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

	  local rundata = {}

		for i=1,#self[colKey] do
			local symbolType =  self[colKey][i]
			if symbolType ==  self.SYMBOL_MYSTER_1 then

				symbolType = self.m_MYSTER_RunSymbol_1
			end

			
			table.insert(rundata,symbolType)

		end

	  return rundata
  end

function LevelBingoPriatesConfig:setMysterSymbol( symbolType1)

		self.m_MYSTER_RunSymbol_1 = symbolType1

end



return  LevelBingoPriatesConfig