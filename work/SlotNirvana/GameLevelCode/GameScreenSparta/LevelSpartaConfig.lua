--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelSpartaConfig = class("LevelSpartaConfig", LevelConfigData)

function LevelSpartaConfig:ctor()
      LevelConfigData.ctor(self)
end
function LevelSpartaConfig:initMachine(machine)
	self.m_machine=machine
end
---
-- 获取freespin model 对应的reel 列数据
--
function LevelSpartaConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
	local bonusList = self.m_machine:getBonusColList( )
	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
	if bonusList ~= nil  then
		for k,v in pairs(bonusList) do
			if columnIndex == v then
				colKey = string.format("freespinModeId_1_1")
			end
		end
	end
	return self[colKey]
end

  



return  LevelSpartaConfig