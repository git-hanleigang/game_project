
local OutsideCaveSaleManager = class("OutsideCaveSaleManager", BaseActivityControl)

function OutsideCaveSaleManager:ctor()
    OutsideCaveSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.OutsideCaveSale)
    self:addPreRef(ACTIVITY_REF.OutsideCave)
end

function OutsideCaveSaleManager:showMainLayer(params)
    if not self:isCanShowLayer() then
        return nil
    end
    if self:getLayerByName("Promotion_OutsideCave") ~= nil then
        return
    end
    local promotion_path = "Activity/Promotion_OutsideCave"
    local uiView = util_createFindView(promotion_path, params)
    if uiView then
       self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end

    return uiView
end

return OutsideCaveSaleManager
