--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-18 16:55:51
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-18 17:12:12
FilePath: /SlotNirvana/src/GameModule/CardNovice/views/CardNoviceSaleMainLayer.lua
Description: 新手期集卡 促销 主弹板
--]]
local CardNoviceSaleMainLayer = class("CardNoviceSaleMainLayer", BaseLayer)

function CardNoviceSaleMainLayer:initDatas()
    CardNoviceSaleMainLayer.super.initDatas(self)
    
    self.m_data = G_GetMgr(G_REF.CardNoviceSale):getData()

    self:setKeyBackEnabled(true)
    self:setName("CardNoviceSaleMainLayer")
    self:setLandscapeCsbName("NewUserAlbum_AlbumSale/Activity/csd/Activity_NewUserAlbum_AlbumSale.csb")
end

function CardNoviceSaleMainLayer:initCsbNodes()
    CardNoviceSaleMainLayer.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
end

function CardNoviceSaleMainLayer:initView()
    CardNoviceSaleMainLayer.super.initView(self)
    
    -- 金币 道具
    self:initCoinsUI()
    -- 购买按钮价格
    self:initBtnLbUI()
    -- 时间
    self.m_scheduler = schedule(self, util_node_handler(self, self.onUpdateSec), 1)
    self:onUpdateSec()

    self:runCsbAction("idle", true)
end

-- 金币 道具
function CardNoviceSaleMainLayer:initCoinsUI()
    local lbCoins = self:findChild("lb_coin")
    local itemParent = self:findChild("node_item")
    local coinsV = self.m_data:getCoins()
    local itemList = self.m_data:getItems()
    lbCoins:setString(util_formatCoins(coinsV, 9) .. "+")
    local nodeItems = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.TOP, nil, nil, true)
    itemParent:addChild(nodeItems)

    util_alignCenter({
        {node = self:findChild("sp_coin")},
        {node = lbCoins, alignX = 5},
        {node = itemParent, alignX = 5}
    })
end

-- 购买按钮价格
function CardNoviceSaleMainLayer:initBtnLbUI()
    local price = self.m_data:getPrice()
    self:setButtonLabelContent("btn_buy", "$ " .. price)
end

function CardNoviceSaleMainLayer:onUpdateSec()
    local expireAt = self.m_data:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self.m_lbTime:setString(timeStr)

    if bOver then
        self:clearScheduler()
        self:closeUI()
    end
end

function CardNoviceSaleMainLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_buy" then
        G_GetMgr(G_REF.CardNoviceSale):goPurchase()
    elseif senderName == "btn_pb" then
        local price = self.m_data:getPrice()
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer({p_price = price})
    end
end

-- 清楚定时器
function CardNoviceSaleMainLayer:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

function CardNoviceSaleMainLayer:closeUI()
    if self.m_bClose then
        return
    end
    self.m_bClose = true

    CardNoviceSaleMainLayer.super.closeUI(self)
end

-- 充值成功
function CardNoviceSaleMainLayer:onBuySuccessEvt()
    local cb = function()
        self:closeUI()
        gLobalViewManager:checkBuyTipList()
    end
    self:flyCurrency(cb)
end

function CardNoviceSaleMainLayer:flyCurrency(func)
    local coins = self.m_data:getCoins()
    if coins <= 0 then
        func()
        return
    end
    
    local btnCollect = self:findChild("btn_buy")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local flyList = {}
        if coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
        end
        curMgr:playFlyCurrency(flyList, func)
    end
end

function CardNoviceSaleMainLayer:registerListener()
    CardNoviceSaleMainLayer.super.registerListener(self)
    
    gLobalNoticManager:addObserver(self, "onBuySuccessEvt", CardNoviceCfg.EVENT_NAME.CARD_NOVICE_SALE_BUY_SUCCESS) -- 充值成功
end

return CardNoviceSaleMainLayer