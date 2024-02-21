-- 卡牌商店 主界面

local CardStoreResetLayer = class("CardStoreResetLayer", BaseLayer)

function CardStoreResetLayer:ctor()
    CardStoreResetLayer.super.ctor(self)

    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    -- 设置横屏csb
    self:setLandscapeCsbName(p_config.ResetUI)
    self:setExtendData("CardStoreResetLayer")

    self.store_data = G_GetMgr(G_REF.CardStore):getRunningData()
end

function CardStoreResetLayer:initCsbNodes()
    self.node_anim = self:findChild("node_anim")
    self.lb_gemsOwn = self:findChild("lb_gemsOwn")
end

function CardStoreResetLayer:initView()
    self:onRefresh()
end

function CardStoreResetLayer:onRefresh()
    if not self.store_data then
        return
    end
    local gems = self.store_data:getResetGems()
    self:setButtonLabelContent("btn_buy", gems)
    local userGems = globalData.userRunData.gemNum or 0 -- 当前玩家的宝石数
    self.lb_gemsOwn:setString(userGems)
    -- 第二货币不够刷新
    if gems > userGems then
        self.lb_gemsOwn:setTextColor(cc.c3b(254, 90, 220))
        local p_config = G_GetMgr(G_REF.CardStore):getConfig()
        local eff_ani = util_createAnimation(p_config.ResetEff)
        if eff_ani then
            eff_ani:addTo(self.node_anim)
            eff_ani:runCsbAction("start", true)
        end
    else
        self.lb_gemsOwn:setTextColor(cc.c3b(255, 255, 255))
    end
end

function CardStoreResetLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function CardStoreResetLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_buy" then
        --gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:onBuy()
    end
end

-- 发起购买
function CardStoreResetLayer:onBuy()
    if not self.store_data then
        return
    end
    local gems = self.store_data:getResetGems()
    self:setButtonLabelContent("btn_buy", gems)
    local userGems = globalData.userRunData.gemNum or 0 -- 当前玩家的宝石数
    self.lb_gemsOwn:setString(userGems)

    if gems > userGems then
        -- 第二货币不够 跳转钻石商店
        G_GetMgr(G_REF.CardStore):changeLogEnterType()
        local params = {shopPageIndex = 2, dotKeyType = "btn_buy", dotUrlType = DotUrlType.UrlName, dotIsPrep = false}
        local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
        if view then
            view.buyShop = true
        end
        self:closeUI()
    else
        G_GetMgr(G_REF.CardStore):sendToReset("manual")
        self:closeUI()
    end
end

function CardStoreResetLayer:onEnter()
    CardStoreResetLayer.super.onEnter(self)

    -- 跨天商品数据刷新了 需要关闭弹板
    --gLobalNoticManager:addObserver(
    --    self,
    --    function(sender, params)
    --        self:closeUI()
    --    end,
    --    ViewEventType.NOTIFY_EVENT_CARD_STORE_REFRESH
    --)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:onReset()
        end,
        ViewEventType.NOTIFY_EVENT_CARD_STORE_RESET
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:onRefresh()
        end,
        ViewEventType.NOTIFY_TOP_UPDATE_GEM
    )
end

-- 处理重置商店
function CardStoreResetLayer:onReset()
    --self:closeUI()
end

return CardStoreResetLayer
