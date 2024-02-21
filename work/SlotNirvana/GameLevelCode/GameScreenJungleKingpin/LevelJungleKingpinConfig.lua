local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelJungleKingpinConfig = class("LevelJungleKingpinConfig", LevelConfigData)

function LevelJungleKingpinConfig:ctor()
    LevelConfigData.ctor(self)
end
function LevelJungleKingpinConfig:initMachine(machine)
	self.m_machine=machine
end

function LevelJungleKingpinConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    return self[colKey]
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelJungleKingpinConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
   
    -- if self.m_machine.m_iBigLevelFreeSpinNum == 1 then
    --     if self.m_machine.m_bBigLevelFreeSpinWild == false then
    --         fsModelID = 11
    --     else
    --         fsModelID = 12
    --     end
    -- elseif self.m_machine.m_iBigLevelFreeSpinNum == 2 then
    --     fsModelID = 21
    -- elseif  self.m_machine.m_iBigLevelFreeSpinNum == 3 then
    --     if self.m_machine.m_bBigLevelFreeSpinWild == false then
    --         fsModelID = 31
    --     else
    --         fsModelID = 32
    --     end
    -- elseif  self.m_machine.m_iBigLevelFreeSpinNum == 4 then
    --     if self.m_machine.m_bBigLevelFreeSpinWild == false then
    --         fsModelID = 41
    --     else
    --         fsModelID = 42
    --     end
    -- end
    local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
    
    return self[colKey]
end


return  LevelJungleKingpinConfig