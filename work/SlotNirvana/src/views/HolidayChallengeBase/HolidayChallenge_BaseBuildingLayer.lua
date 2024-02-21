--[[
    感恩节新版聚合挑战 滑动背景
    author:csc
    time:2021-11-10 17:53:25
]]
local HolidayChallenge_BaseBuildingLayer = class("HolidayChallenge_BaseBuildingLayer", BaseLayer)

function HolidayChallenge_BaseBuildingLayer:ctor()
    HolidayChallenge_BaseBuildingLayer.super.ctor(self)

    -- 不需要播放动画
    self.m_isShowActionEnabled = false 
    self.m_isHideActionEnabled = false
    self.m_isMaskEnabled = false
end

function HolidayChallenge_BaseBuildingLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.MAPBUILDING_LAYER)
end

function HolidayChallenge_BaseBuildingLayer:initCsbNodes()
    self.m_spBuildingBg = {}
    for i = 1, 8 do
        local node = self:findChild("sp_building_" .. i)
        if node then
            table.insert(self.m_spBuildingBg, node)
        end
    end
end

function HolidayChallenge_BaseBuildingLayer:getContentLen()
    local len = 0
    for i = 1, #self.m_spBuildingBg do
        len = len + self.m_spBuildingBg[i]:getContentSize().width
    end
    return len
end


-- 重写父类
function HolidayChallenge_BaseBuildingLayer:setAutoScale(_autoScale)
    -- 因为是滑动层 继承了baselayer 不希望被缩放
end

return HolidayChallenge_BaseBuildingLayer
