local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFrogPrinceConfig = class("LevelFrogPrinceConfig", LevelConfigData)

function LevelFrogPrinceConfig:ctor()
    LevelConfigData.ctor(self)
end
function LevelFrogPrinceConfig:initMachine(machine)
	self.m_machine=machine
end

function LevelFrogPrinceConfig:getNormalReelDatasByColumnIndex(columnIndex)
	local  baseType = self.m_machine:getMachineBaseType() 
	local colKey = "reel_cloumn"..columnIndex
	if baseType ~= nil then
		local index = 1
		if baseType == "base1" then
			index = "1"
		elseif baseType == "base2" then
			index = "2"
		elseif baseType == "base3" then
			index = "3"
		elseif baseType == "base4" then
			index = "4"
		elseif baseType == "base5" then
			index = "5"
		end
		colKey = "reel_cloumn"..index..columnIndex
	end
    return self[colKey]
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelFrogPrinceConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
	
    local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
    
    return self[colKey]
end

function LevelFrogPrinceConfig:parseScoreImage( colKey, imageStr )

	local iamgeStrs = util_string_split(imageStr,";")
	if iamgeStrs == nil or #iamgeStrs == 1 then
		self[colKey] = iamgeStrs[1]
	elseif #iamgeStrs == 4 then
		self[colKey] = iamgeStrs
	end
	
end

return  LevelFrogPrinceConfig