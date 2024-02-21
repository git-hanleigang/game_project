
local QuestNewSaleManager = class("QuestNewSaleManager", BaseActivityControl)

function QuestNewSaleManager:ctor()
    QuestNewSaleManager.super.ctor(self)
    self:addPreRef(ACTIVITY_REF.QuestNew)
    self:setRefName(ACTIVITY_REF.QuestNewSale)
end

function QuestNewSaleManager:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    
    if gLobalViewManager:getViewByExtendData("Promotion_QuestNew") then
        return nil
    end

    local pop_name = self:getPopModule()
    if not pop_name then
        return
    end
    local uiView = util_createView(pop_name)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

return QuestNewSaleManager
