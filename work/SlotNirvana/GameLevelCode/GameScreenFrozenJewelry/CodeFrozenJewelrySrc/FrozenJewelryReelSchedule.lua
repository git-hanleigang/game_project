---
--xcyy
--2018年5月23日
--FrozenJewelryReelSchedule.lua

local FrozenJewelryReelSchedule = class("FrozenJewelryReelSchedule",util_require("reels.ReelSchedule"))

--初始化滚动配置
function FrozenJewelryReelSchedule:initData(parentData,configData)
    self.m_parentData = parentData
    self.m_configData = configData
    self.m_quickDelayTime = configData.p_quickStopDelayTime --快停延时时间
    self.m_reelMoveSpeed = configData.p_reelMoveSpeed --滚动速度
    self.m_backTime = configData.p_reelResTime --回弹时间
    self.m_backDistance = configData.p_reelResDis --回弹距离
    self.m_longRunMoveSpeed = configData.p_reelLongRunSpeed --快滚速度
    self.m_longRunTime = configData.p_reelLongRunTime -- 快滚时间
    self.m_reelBeginTime = configData.p_reelBeginJumpTime --点击spin向上跳的时间
    self.m_beginDistance = configData.p_reelBeginJumpHight --点击spin向上跳的高度

    self.m_backType = configData.p_reelResType --回弹类型 还没有实现
    self.m_reelTime = nil --滚动时间
    self.m_moveDistance = nil --获得真实数据停止距离

    self.m_maxMoveDis = 160 --每一帧滚动最大距离
    self:resetReel()
end

return FrozenJewelryReelSchedule