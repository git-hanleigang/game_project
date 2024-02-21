local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelDragonsConfig = class("LevelDragonsConfig", LevelConfigData)

function LevelDragonsConfig:ctor()
    LevelConfigData.ctor(self)
end
function LevelDragonsConfig:initMachine(machine)
	self.m_machine=machine
end

function LevelDragonsConfig:getNormalReelDatasByColumnIndex(columnIndex)
	local colKey = "reel_cloumn"..columnIndex
    return self[colKey]
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelDragonsConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
	local secletType =  self.m_machine:getFreeSpinSecletType()
	if secletType > 0 then
		fsModelID = secletType
	else
		fsModelID = 0
	end
    local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
    
    return self[colKey]
end

function LevelDragonsConfig:parseScoreImage( colKey, imageStr )

	local iamgeStrs = util_string_split(imageStr,";")
	if iamgeStrs == nil or #iamgeStrs == 1 then
		self[colKey] = iamgeStrs[1]
	elseif #iamgeStrs == 4 then
		self[colKey] = iamgeStrs
	end
	
end

return  LevelDragonsConfig