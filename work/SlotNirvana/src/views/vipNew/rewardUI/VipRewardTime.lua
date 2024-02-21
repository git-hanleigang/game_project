--[[
    倒计时
]]
local VipRewardTime = class("VipRewardTime", BaseView)

function VipRewardTime:getCsbName()
    return "VipNew/csd/rewardUI/VipRewardTime.csb"
end

function VipRewardTime:initCsbNodes()
    self.m_lbLimited = self:findChild("lb_limited")
    self.m_lbTime = self:findChild("lb_time")
end

function VipRewardTime:initUI()
    VipRewardTime.super.initUI(self)
    self:initLimit()
    self:initTimer()
end

function VipRewardTime:initLimit()
    local vipData = G_GetMgr(G_REF.Vip):getData()
    if not vipData then
        return
    end
    local vipLevel = globalData.userRunData.vipLevel
    local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if not VipBoostData or not VipBoostData:isOpenBoost() then
        return
    end
    local nextData = vipData:getVipLevelInfo(vipLevel + VipBoostData.p_extraVipLevel) --获取下一个等级的VIP数据
    if nextData then
        self.m_lbLimited:setString("Limited " .. VipConfig.LISTVIEW_CONFIG[nextData.levelIndex].name)
        self:updateLabelSize({label = self.m_lbLimited}, 175)
    end
end

function VipRewardTime:initTimer()
    if self.m_sch then
        self:stopAction(self.m_sch)
        self.m_sch = nil
    end
    self:updateTime()
    self.m_sch =
        util_schedule(
        self,
        function()
            self:updateTime()
        end,
        1
    )
end

function VipRewardTime:updateTime()
    local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if VipBoostData and VipBoostData:isOpenBoost() then
        self.m_lbTime:setString(util_count_down_str(VipBoostData:getLeftTime()))
    end
end

function VipRewardTime:onExit()
    VipRewardTime.super.onExit(self)
    if self.m_sch then
        self:stopAction(self.m_sch)
        self.m_sch = nil
    end
end

return VipRewardTime
