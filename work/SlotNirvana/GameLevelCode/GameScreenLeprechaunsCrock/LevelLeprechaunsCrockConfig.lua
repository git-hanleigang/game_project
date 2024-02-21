local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelLeprechaunsCrockConfig = class("LevelLeprechaunsCrockConfig", LevelConfigData)

function LevelLeprechaunsCrockConfig:ctor()
    LevelConfigData.ctor(self)
end
function LevelLeprechaunsCrockConfig:initMachine(machine)
	self.m_machine = machine
end

function LevelLeprechaunsCrockConfig:getNormalReelDatasByColumnIndex(columnIndex)
	local baseType = self.m_machine:getMachineBaseType() 
	local colKey = "reel_cloumn"..columnIndex
	if baseType ~= nil then
		if baseType == "reels2" then
			colKey = "reel_cloumn"..columnIndex.."_2"
		elseif baseType == "reels1" then
			colKey = "reel_cloumn"..columnIndex
		elseif baseType == "reels3" then
			colKey = "reel_cloumn"..columnIndex
		end
	end
    return self[colKey]
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelLeprechaunsCrockConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
	local freeType = self.m_machine:getMachineFreeType() 
	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
	if freeType ~= nil then
		if freeType == "reels2" then
			colKey = string.format("freespinModeId_0_%d_2",columnIndex)
		elseif freeType == "reels1" then
			colKey = string.format("freespinModeId_0_%d",columnIndex)
		elseif freeType == "reels2-1" then
			colKey = string.format("freespinModeId_1_%d_2",columnIndex)
		elseif freeType == "reels1-1" then
			colKey = string.format("freespinModeId_1_%d",columnIndex)
		elseif freeType == "reels2-2" then
			colKey = string.format("freespinModeId_2_%d_2",columnIndex)
		elseif freeType == "reels1-2" then
			colKey = string.format("freespinModeId_2_%d",columnIndex)
		elseif freeType == "reels2-3" then
			colKey = string.format("freespinModeId_3_%d_2",columnIndex)
		elseif freeType == "reels1-3" then
			colKey = string.format("freespinModeId_3_%d",columnIndex)
		end
	end
    
    return self[colKey]
end

return  LevelLeprechaunsCrockConfig