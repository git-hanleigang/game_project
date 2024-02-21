--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-17 11:33:00
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-17 14:25:51
FilePath: /SlotNirvana/src/GameModule/CardNovice/controller/CardNoviceSaleMgr.lua
Description: 新手期集卡 促销双倍奖励  mgr
--]]
local ActNewUserAlbumSaleMgr = class("ActNewUserAlbumSaleMgr", BaseGameControl)

function ActNewUserAlbumSaleMgr:ctor()
    ActNewUserAlbumSaleMgr.super.ctor(self)
    
    self:setRefName(G_REF.CardNoviceSale)
    self:setDataModule("GameModule.CardNovice.model.CardNoviceSaleData")
end

-- 获取网络 obj
function ActNewUserAlbumSaleMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local CardNoviceSaleNet = util_require("GameModule.CardNovice.net.CardNoviceSaleNet")
    self.m_net = CardNoviceSaleNet:getInstance()
    return self.m_net
end

-- 支付
function ActNewUserAlbumSaleMgr:goPurchase()
    local data = self:getData()
    self:getNetObj():goPurchase(data)
end

-- 显示促销 弹板
function ActNewUserAlbumSaleMgr:showSaleLayer()
    if not self:isCanShowLayer() then
        return
    end

    if not self:isSaleRunning() then
        return false
    end

    local layer = gLobalViewManager:getViewByName("CardNoviceSaleMainLayer")
    if layer then
        return
    end

    local view = util_createView("GameModule.CardNovice.views.CardNoviceSaleMainLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示双倍奖励弹板
function ActNewUserAlbumSaleMgr:showDoubleRewardLayer(_bInCardView)
    if not self:isCanShowLayer() then
        return
    end

    local layer = gLobalViewManager:getViewByName("CardNoviceDoubleRewardMainLayer")
    if layer then
        return
    end

    local view = util_createView("GameModule.CardNovice.views.CardNoviceDoubleRewardMainLayer", _bInCardView)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 创建 新手期集卡双倍奖励加成标签
function ActNewUserAlbumSaleMgr:createDoubleRewardSignUI()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("GameModule.CardNovice.views.CardNoviceDoubleRewardSignUI")
    return view
end

-- 是否可以显示 双倍奖励 轮播展示
function ActNewUserAlbumSaleMgr:canShowDoubleRewardHallSlide()
    if not self:isCanShowLayer() then
        return false
    end

    return true
end

-- 是否可以显示 促销 轮播展示
function ActNewUserAlbumSaleMgr:canShowSaleHallSlide()
    if not self:isCanShowLayer() then
        return false
    end

    if not self:isSaleRunning() then
        return false
    end
    
    local bFirstSaleExit = G_GetMgr(G_REF.FirstCommonSale):checkIsFirstSaleType()
    if bFirstSaleExit then
        return false
    end

    return true
end

-- 关闭新手期集卡界面 弹版
-- 有首冲弹首冲
-- 没有首冲弹促销弹板
function ActNewUserAlbumSaleMgr:checkCloseCardPopLayer()
    local layer = gLobalViewManager:getViewByName("CardNoviceDoubleRewardMainLayer")
    if layer then
        layer:closeUI()
    end

    local bFirstSaleExit = G_GetMgr(G_REF.FirstCommonSale):checkIsFirstSaleType()
    if bFirstSaleExit then
        G_GetMgr(G_REF.FirstCommonSale):showMainLayer()
    else
        self:showSaleLayer()
    end
end

function ActNewUserAlbumSaleMgr:isSaleRunning()
    local data = self:getData()
    if not data:isSaleRunning() then
        return false
    end

    return true
end

return ActNewUserAlbumSaleMgr