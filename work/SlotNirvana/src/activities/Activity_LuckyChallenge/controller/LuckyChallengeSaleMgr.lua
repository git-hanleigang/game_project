--[[

    author:{author}
    time:2021-11-14 14:22:05
]]

local LuckyChallengeSaleMgr = class("LuckyChallengeSaleMgr", BaseActivityControl)

function LuckyChallengeSaleMgr:ctor()
    LuckyChallengeSaleMgr.super.ctor(self)
    self.m_buying = false
    self:setRefName(ACTIVITY_REF.LuckyChallengeSale)
    self:addPreRef(ACTIVITY_REF.LuckyChallenge)
end

function LuckyChallengeSaleMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    local promotion = G_GetMgr(ACTIVITY_REF.LuckyChallengeSale):getRunningData()
    if promotion then
        view = util_createView("Activity.Promotion_LuckyChallenge", {name = promotion.p_popupImage, activityId = promotion:getID()})
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end

    return view
end

return LuckyChallengeSaleMgr