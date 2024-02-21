-- 新版大富翁 排行榜管理器

local WorldTripShowTopMgr = class("WorldTripShowTopMgr", BaseActivityControl)

function WorldTripShowTopMgr:ctor()
    WorldTripShowTopMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WorldTripRank)
    self:addPreRef(ACTIVITY_REF.WorldTrip)
end

function WorldTripShowTopMgr:showMainLayer(_bClick)
    if not self:isCanShowLayer() then
        return nil
    end

    local worldTripRankUI = nil
    if gLobalViewManager:getViewByExtendData("WorldTripRankUI") == nil then
        gLobalNoticManager:postNotification(ViewEventType.RANK_BTN_CLICKED, {name = ACTIVITY_REF.WorldTrip})
        worldTripRankUI = util_createView("Activity.WorldTripRank.WorldTripRankUI")
        gLobalViewManager:showUI(worldTripRankUI, ViewZorder.ZORDER_POPUI)
    end
    return worldTripRankUI
end

return WorldTripShowTopMgr
