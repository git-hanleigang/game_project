--[[
    三联优惠券
]]
local CouponRewardsNet = require("activities.Activity_CouponRewards.net.CouponRewardsNet")
local CouponRewardsMgr = class("CouponRewardsMgr", BaseActivityControl)

function CouponRewardsMgr:ctor()
    CouponRewardsMgr.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.CouponRewards)

    self.m_lastStage = 1
    self.m_net = CouponRewardsNet:getInstance()
end

function CouponRewardsMgr:showMainLayer(_params)
    local view = self:createPopLayer(_params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function CouponRewardsMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function CouponRewardsMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function CouponRewardsMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function CouponRewardsMgr:checkOpenLayer()
    local flag = false

    local gameData = self:getRunningData()
    if not gameData then
        return flag
    end

    local stageList = gameData:getStageList()
    for i,v in ipairs(stageList) do
        if v.p_completed and not v.p_collected then
            flag = true
            break
        end
    end

    return flag
end

function CouponRewardsMgr:setShowStage(_stage)
    self.m_lastStage = _stage or 0
end

function CouponRewardsMgr:getShowStage()
    return self.m_lastStage
end

function CouponRewardsMgr:collectReward(_index)
    self.m_net:collectReward(_index)
end

return CouponRewardsMgr