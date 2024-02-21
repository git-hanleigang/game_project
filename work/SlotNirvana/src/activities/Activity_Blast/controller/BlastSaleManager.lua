--[[
    blast促销
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local BlastSaleManager = class("BlastSaleManager", BaseActivityControl)

function BlastSaleManager:ctor()
    BlastSaleManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BlastSale)
    self:addPreRef(ACTIVITY_REF.Blast)

    self:addExtendResList("Promotion_BlastCode")
end

function BlastSaleManager:showMainLayer(params)
    if not self:isCanShowLayer() then
        return nil
    end

    local promotion_path = "Activity/Promotion_Blast"
    assert(promotion_path, "blast 促销界面创建路径不存在")
    local uiView = util_createFindView(promotion_path, params)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

return BlastSaleManager
