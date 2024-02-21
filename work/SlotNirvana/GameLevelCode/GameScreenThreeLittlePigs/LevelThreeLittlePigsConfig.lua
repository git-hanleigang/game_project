
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelThreeLittlePigsConfig = class("LevelThreeLittlePigsConfig", LevelConfigData)

function LevelThreeLittlePigsConfig:ctor()
    LevelThreeLittlePigsConfig.super.ctor(self)
    self.m_curSuperFreeIdx = 0
end

function LevelThreeLittlePigsConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
    local colKey = ""
    if self.m_curSuperFreeIdx == 0 then
        colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
    else
        colKey = string.format("superfreespinModeId_%d_%d",fsModelID,columnIndex)
    end
	return self[colKey]
end
return  LevelThreeLittlePigsConfig