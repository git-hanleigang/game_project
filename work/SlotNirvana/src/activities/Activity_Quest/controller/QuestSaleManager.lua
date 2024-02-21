--[[
    
    author: 徐袁
    time: 2021-08-18 15:40:18
]]
local QuestSaleManager = class("QuestSaleManager", BaseActivityControl)

function QuestSaleManager:ctor()
    QuestSaleManager.super.ctor(self)
    self:addPreRef(ACTIVITY_REF.Quest)
    self:setRefName(ACTIVITY_REF.QuestSale)

    self:addExtendResList("Promotion_QuestBase")
end

function QuestSaleManager:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("Promotion_Quest") then
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

return QuestSaleManager
