--[[
    
    author: 徐袁
    time: 2021-09-03 11:14:16
]]
local RichManSaleManager = class("RichManSaleManager", BaseActivityControl)

RichManSaleManager.richmanData = nil

function RichManSaleManager:ctor()
    RichManSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RichManSale)
    self:addPreRef(ACTIVITY_REF.RichMan)
end

function RichManSaleManager:showMainLayer(data)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalSendDataManager.getLogIap and gLobalSendDataManager:getLogIap().setEnterOpen then
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", entry_name)
    end

    local uiView = util_createFindView("Activity/Promotion_RichMan", data)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
    return uiView
end

return RichManSaleManager
