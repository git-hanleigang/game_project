-- 新版大富翁 促销管理器

local WorldTripSaleManager = class("WorldTripSaleManager", BaseActivityControl)

function WorldTripSaleManager:ctor()
    WorldTripSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WorldTripSale)
    self:addPreRef(ACTIVITY_REF.WorldTrip)
end

function WorldTripSaleManager:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalSendDataManager.getLogIap and gLobalSendDataManager:getLogIap().setEnterOpen then
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "Promotion_WorldTrip")
    end

    local uiView = util_createView("Activity.Promotion_WorldTrip", data)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

return WorldTripSaleManager
