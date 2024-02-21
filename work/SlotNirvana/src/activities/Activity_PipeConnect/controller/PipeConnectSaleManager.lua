--[[
    blast促销
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local PipeConnectSaleManager = class("PipeConnectSaleManager", BaseActivityControl)

function PipeConnectSaleManager:ctor()
    PipeConnectSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PipeConnectSale)
    self:addPreRef(ACTIVITY_REF.PipeConnect)
end

function PipeConnectSaleManager:showMainLayer(params)
    if not self:isCanShowLayer() then
        return nil
    end

    local promotion_path = "Activity/Promotion_PipeConnect"
    local uiView = util_createFindView(promotion_path, params)
    if uiView then
       self:showLayer(uiView, ViewZorder.ZORDER_UI)
    end

    return uiView
end

return PipeConnectSaleManager
