--[[--
    金币商城的金币数量
]]
local ShopBaseItemNum = util_require(SHOP_CODE_PATH.ShopBaseItemNum)
local ShopItemCoinNumNode = class("ShopItemCoinNumNode", ShopBaseItemNum)

function ShopItemCoinNumNode:getHasDiscount()
    local originalCoins = self.m_itemData.p_originalCoins
    if originalCoins and originalCoins ~= 0 and (originalCoins < self.m_itemData.p_coins) then
        return true
    end
    return false
end

function ShopItemCoinNumNode:getItemNumbers()
    return self.m_itemData.p_originalCoins or 0, self.m_itemData.p_coins or 0
end

function ShopItemCoinNumNode:initView(_itemData)
    self.m_itemData = _itemData

    local baseCoins, coins = self:getShowNumbers()
    self.m_curCoins = baseCoins
    self:setCurNum(self.m_curCoins)

    -- if not G_GetMgr(G_REF.Shop):getPromomodeOpen() then
    --     self.m_curCoins = baseCoins
    --     self:setCurNum(self.m_curCoins)
    --     return
    -- end

    self.m_factor = 1
    if G_GetMgr(G_REF.Shop):getEnterPageIdx() == 1 then
        local levelRoadMgr = G_GetMgr(G_REF.LevelRoad)
        if levelRoadMgr and levelRoadMgr:isCanShowLogoLayer() then
            self.m_factor = self.m_factor + levelRoadMgr:getExpansionRatio()
        end

        local shopCarnival = G_GetMgr(ACTIVITY_REF.ShopCarnival)
        if self.m_factor == 1 and shopCarnival and globalData.constantData.NOVICE_SHOP_CARNIVAL_ANI_ACTIVE then
            local _data = shopCarnival:getRunningData()
            if _data then
                self.m_factor = _data:getFactor()
            end
        end

        if self.m_factor == 1 then
            local timeLimitExpansion = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
            if timeLimitExpansion then
                self.m_factor = self.m_factor + timeLimitExpansion:getExpansionRatio()
            end
        end

        if self.m_factor == 1 then
            --vipBoost活动是否开启
            local vipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
            local isShowVip = G_GetMgr(ACTIVITY_REF.VipBoost):checkIsCanShowLayer()
            local isOpen = G_GetMgr(G_REF.Shop):getPromomodeOpen()
            if vipBoostData and vipBoostData:isOpenBoost() and isShowVip and isOpen then
                local boost = vipBoostData:getBoost()
                local discount = self.m_itemData:getDiscount()
                local ticketDiscount = self.m_itemData:getTicketDiscount()
                local allDiscount = (discount + ticketDiscount) / 100
                self.m_factor = (allDiscount + 1) / ((allDiscount + 1) - boost)
            end
        end
    end

    local curCoins = baseCoins
    if G_GetMgr(G_REF.Shop):getPromomodeOpen() then
        curCoins = coins
    end

    self.m_curCoins = math.floor(curCoins / self.m_factor)
    -- self.m_baseCoins = math.floor(baseCoins / self.m_factor)
    self:setCurNum(self.m_curCoins)
    -- self:setBaseNum(self.m_baseCoins)

    if self.m_factor > 1 then
        gLobalNoticManager:addObserver(
            self,
            function()
                self:carnivalCoinsAction()
                gLobalNoticManager:removeObserver(self, "ShopCarnival")
            end,
            "ShopCarnival"
        )
        gLobalNoticManager:addObserver(
            self,
            function()
                self:carnivalCoinsAction()
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_TIMELIMITEXPANSION_LOGOLAYER_CLOSE)
            end,
            ViewEventType.NOTIFY_TIMELIMITEXPANSION_LOGOLAYER_CLOSE
        )
        gLobalNoticManager:addObserver(
            self,
            function()
                self:carnivalCoinsAction()
                gLobalNoticManager:removeObserver(self, "showShopVip")
            end,
            "showShopVip"
        )
    end
end

function ShopItemCoinNumNode:carnivalCoinsAction()
    if self.m_factor > 1 then
        gLobalViewManager:addLoadingAnima(true)
        local baseCoins, coins = self:getShowNumbers()
        local interval = 1 / 30
        local rolls = 33
        local curCoins = baseCoins
        if G_GetMgr(G_REF.Shop):getPromomodeOpen() then
            curCoins = coins
        end
        -- local baseStep = math.floor((baseCoins - self.m_baseCoins) / rolls)
        local curStep = math.floor((curCoins - self.m_curCoins) / rolls)

        self.m_scheduleId =
            schedule(
            self,
            function()
                self.m_curCoins = math.min(self.m_curCoins + curStep, curCoins)
                self:setCurNum(self.m_curCoins)
                -- self.m_baseCoins = math.min(self.m_baseCoins + baseStep, baseCoins)
                -- self:setBaseNum(self.m_baseCoins)
                if self.m_curCoins >= curCoins then
                    if self.m_scheduleId then
                        self:stopAction(self.m_scheduleId)
                        self.m_scheduleId = nil
                    end
                    gLobalViewManager:removeLoadingAnima()
                -- self:playBaoZaAction()
                end
            end,
            interval
        )

        local _ts = (rolls + 2) * interval
        local _action = {}
        _action[1] = cc.EaseBackInOut:create(cc.ScaleTo:create(_ts, 1.2))
        _action[2] = cc.ScaleTo:create(0.1, 1)
        _action[3] =
            cc.CallFunc:create(
            function()
                self:playBaoZaAction()
            end
        )
        self.m_nodeCur:runAction(cc.Sequence:create(_action))

        local _action2 = {}
        _action2[1] = cc.EaseBackInOut:create(cc.ScaleTo:create(_ts, 1.5))
        _action2[2] = cc.ScaleTo:create(0.1, 1)
        self.m_nodeBase:runAction(cc.Sequence:create(_action2))
    end
end

function ShopItemCoinNumNode:playBaoZaAction()
    local sp = util_createAnimation(SHOP_RES_PATH.CoinLizi)
    if sp then
        self:addChild(sp, 10)
        if self.m_index == 3 then
            -- 只播放一次音效
            gLobalSoundManager:playSound(SHOP_RES_PATH.Sound_carnival_baoza)
        end
        sp:playAction(
            "start",
            false,
            function()
                sp:removeFromParent()
            end,
            60
        )
    end
end

return ShopItemCoinNumNode
