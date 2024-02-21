--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
--fixios0223
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelLoveShotConfig = class("LevelLoveShotConfig", LevelConfigData)

-- normal, 红色hit, 紫色hit, 金色hit, freeFeature(带bonus的 暂时写个假的)
LevelLoveShotConfig.RUNDATA_CONFIG_NAME = {"reel_cloumn","freespinModeId_0_","freespinModeId_1_","freespinModeId_2_","freespinModeId_3_","freespinModeId_4_"}

LevelLoveShotConfig.m_runType = 1

LevelLoveShotConfig.RUNSTATE_NORMAL = 1
LevelLoveShotConfig.RUNSTATE_RED = 2
LevelLoveShotConfig.RUNSTATE_GREEN = 3
LevelLoveShotConfig.RUNSTATE_YELLOW = 4
LevelLoveShotConfig.RUNSTATE_BONUS = 5
LevelLoveShotConfig.RUNSTATE_RESPIN = 6

LevelLoveShotConfig.NET_CONFIG_TYPE_NORMAL = nil
LevelLoveShotConfig.NET_CONFIG_TYPE_RED = "red"
LevelLoveShotConfig.NET_CONFIG_TYPE_GREEN  = "green"
LevelLoveShotConfig.NET_CONFIG_TYPE_YELLOW = "gold"
LevelLoveShotConfig.NET_CONFIG_TYPE_BONUS = "free_feature" -- free 下射箭
LevelLoveShotConfig.NET_CONFIG_TYPE_RESPIN = "respin"
LevelLoveShotConfig.NET_CONFIG_TYPE_Base_BONUS = "base_feature" -- base下射箭


function LevelLoveShotConfig:setRunType( _runType )


    if _runType == self.NET_CONFIG_TYPE_RED then

        self.m_runType = self.RUNSTATE_RED

    elseif _runType == self.NET_CONFIG_TYPE_GREEN then

        self.m_runType = self.RUNSTATE_GREEN

    elseif _runType == self.NET_CONFIG_TYPE_YELLOW then

        self.m_runType = self.RUNSTATE_YELLOW

    elseif _runType == self.NET_CONFIG_TYPE_BONUS or _runType == self.NET_CONFIG_TYPE_Base_BONUS then

        self.m_runType = self.RUNSTATE_BONUS

    elseif _runType == self.NET_CONFIG_TYPE_RESPIN then

        self.m_runType = self.RUNSTATE_RESPIN 

    else
        self.m_runType = self.RUNSTATE_NORMAL

    end

    
end
---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelLoveShotConfig:getNormalReelDatasByColumnIndex(_columnIndex)
    local colKey = self.RUNDATA_CONFIG_NAME[self.m_runType].._columnIndex
    
    return self[colKey]
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelLoveShotConfig:getFsReelDatasByColumnIndex(fsModelID,_columnIndex)

    local colKey = self.RUNDATA_CONFIG_NAME[self.m_runType].._columnIndex
    
    return self[colKey]

end

return  LevelLoveShotConfig