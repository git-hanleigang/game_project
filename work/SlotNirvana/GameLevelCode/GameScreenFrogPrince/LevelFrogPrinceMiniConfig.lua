local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFrogPrinceMiniConfig = class("LevelFrogPrinceMiniConfig", LevelConfigData)

function LevelFrogPrinceMiniConfig:ctor()
    LevelConfigData.ctor(self)
end
function LevelFrogPrinceMiniConfig:initMachine(machine)
	self.m_machine=machine
end

function LevelFrogPrinceMiniConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    return self[colKey]
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelFrogPrinceMiniConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
    
    local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
    
    return self[colKey]
end

function LevelFrogPrinceMiniConfig:parseScoreImage( colKey, imageStr )

	local iamgeStrs = util_string_split(imageStr,";")
	if iamgeStrs == nil or #iamgeStrs == 1 then
		self[colKey] = iamgeStrs[1]
	elseif #iamgeStrs == 4 then
		self[colKey] = iamgeStrs
	end
	
end
return  LevelFrogPrinceMiniConfig