--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-08-09 10:22:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-08-09 10:30:55
FilePath: /SlotNirvana/src/GameModule/Shop2023/views/ShopTopTicketUI.lua
Description: 商城优惠卷  全档位的
--]]
local ShopTopTicketUI = class("ShopTopTicketUI", BaseView)

function ShopTopTicketUI:initUI(_mainLayer, _bPortrait)
    ShopTopTicketUI.super.initUI(self)

    self._mainLayer = _mainLayer
    self._bPortrait = _bPortrait 
    
    -- 初始化 金币 钻石 ticket
    self:initTicketUI()
    self:setVisible(G_GetMgr(G_REF.Shop):getPromomodeOpen())
    schedule(self,util_node_handler(self, self.onUpdateSec), 1)
end

-- 初始化 金币 钻石 ticket
function ShopTopTicketUI:initTicketUI()
    self.m_coinsView = util_createView(SHOP_CODE_PATH.BaseShopTopTicketUI, SHOP_VIEW_TYPE.COIN, self._bPortrait)
    self:addChild(self.m_coinsView)

    self.m_gemsView = util_createView(SHOP_CODE_PATH.BaseShopTopTicketUI, SHOP_VIEW_TYPE.GEMS, self._bPortrait)
    self:addChild(self.m_gemsView)
end

function ShopTopTicketUI:onUpdateSec()
    self.m_coinsView:onUpdateSec()
    self.m_gemsView:onUpdateSec()
end

function ShopTopTicketUI:updateBtnStatus(_type, _bRefreshData)
    if _bRefreshData then
        self.m_coinsView:updateTicketInfo(SHOP_VIEW_TYPE.COIN)
        self.m_gemsView:updateTicketInfo(SHOP_VIEW_TYPE.GEMS)
    end

    -- 统一档位优惠卷 显示到主界面topUI 单独档位处不用显示
    local coinTicketType = globalData.shopRunData:getTicketType(SHOP_VIEW_TYPE.COIN)
    local gemsTicketType = globalData.shopRunData:getTicketType(SHOP_VIEW_TYPE.GEMS)
    self.m_coinsView:setVisible(self:isVisible() and coinTicketType == "All" and _type == SHOP_VIEW_TYPE.COIN and self.m_coinsView:isTicketEnabled())
    self.m_gemsView:setVisible(self:isVisible() and gemsTicketType == "All" and _type == SHOP_VIEW_TYPE.GEMS and self.m_gemsView:isTicketEnabled())

    self._showType = _type
    if _bRefreshData then
        self:noticeMianLayerListViewSize()
    end
end

function ShopTopTicketUI:onChangePromEvt()
    self:setVisible(G_GetMgr(G_REF.Shop):getPromomodeOpen())
    self:updateBtnStatus(self._showType)

    -- 商城竖版 优惠劵显隐 变化listView大小
    self:noticeMianLayerListViewSize()
end

function ShopTopTicketUI:onEnter()
    ShopTopTicketUI.super.onEnter(self)

    -- 折扣开关
    gLobalNoticManager:addObserver(self, "onChangePromEvt", ViewEventType.NOTIFY_SHOP_PROMO_SWITCH)
end

-- 商城竖版 优惠劵显隐 变化listView大小
function ShopTopTicketUI:noticeMianLayerListViewSize()
    if self._bPortrait then
        self._mainLayer:updateLsitViewSize(self.m_coinsView:isVisible(), self.m_gemsView:isVisible())
    end
end

function ShopTopTicketUI:getNodeFrameSize()
    return self.m_coinsView:getSpBgSize()
end

return ShopTopTicketUI