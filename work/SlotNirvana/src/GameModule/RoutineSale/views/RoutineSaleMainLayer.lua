--[[
    新版常规促销
--]]

local RoutineSaleMainLayer = class("RoutineSaleMainLayer", BaseLayer)

function RoutineSaleMainLayer:initDatas(_params)
    self.m_data = G_GetMgr(G_REF.RoutineSale):getRunningData()
    self.m_params = _params or {}
    self.m_pop = self.m_params.pop
    self.m_saleNodes = {}

    self.m_triggerPosition = self.m_params.pos or "Stroe"
    -- 是否需要弹出广告
    -- self.m_closePlayAds = self.m_params.playAds or false

    self:setPortraitCsbName("Sale_New/csb/main/SaleMain_shu.csb")
    self:setLandscapeCsbName("Sale_New/csb/main/SaleMain.csb")
    self:setPauseSlotsEnabled(true)
    self:setExtendData("RoutineSaleMainLayer")
end

function RoutineSaleMainLayer:initCsbNodes()
    self.m_lb_time = self:findChild("lb_time")
    self.m_node_turntable = self:findChild("node_turntable")
    self.m_node_middle = self:findChild("node_spinBG")
    self.m_node_spin = self:findChild("node_spin")
end

function RoutineSaleMainLayer:initView()
    self:initSale()
    self:intiTurntable()
    self:initSpinNode()
    self:updateTime()
    self:setBgResPath()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function RoutineSaleMainLayer:initSale()
    for i = 1, 3 do
        local node_prize = self:findChild("node_prize_" .. i)
        local saleList = self.m_data:getSaleData()
        local saleData = saleList[i]
        local saleNode = util_createView("GameModule.RoutineSale.views.RoutineSalePrize", saleData, self.m_isShownAsPortrait, self)
        node_prize:addChild(saleNode)
        table.insert(self.m_saleNodes, saleNode)
    end
end

function RoutineSaleMainLayer:intiTurntable()
    local curPro = self.m_data:getWheelCurPro()
    local totalPro = self.m_data:getWheelAllPro()
    self.m_turntable = util_createView("GameModule.RoutineSale.views.RoutineSaleTurntable")
    self.m_node_turntable:addChild(self.m_turntable)
end

function RoutineSaleMainLayer:initSpinNode()
    local maxUsd = self.m_data:getWheelMaxUsd()
    self.m_spin = util_createView("GameModule.RoutineSale.views.RoutineSaleSpinNode", maxUsd, self)
    self.m_node_spin:addChild(self.m_spin)
end

function RoutineSaleMainLayer:updateTime(_gameData)
    local expireAt = self.m_data:getExpireAt()
    local updateTimeLable = function()
        local strLeftTime, isOver = util_daysdemaining(expireAt, true)
        if isOver then
            self.m_lb_time:stopAllActions()
            self:closeUI(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ROUTINE_SALE_TIME_OUT)
                if self.m_pop then
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
            end)
        else
            self.m_lb_time:setString(strLeftTime)
        end
    end
    util_schedule(self.m_lb_time, updateTimeLable, 1)
    updateTimeLable()
end

function RoutineSaleMainLayer:setBgResPath()
    self.m_bgResPath = {}
    if self.m_isShownAsPortrait then
        table.insert(self.m_bgResPath, "Sale_New/ui/main/ui_main_prize_bg1_shu_1.png")
        table.insert(self.m_bgResPath, "Sale_New/ui/main/ui_main_prize_bg2_shu_1.png")
        table.insert(self.m_bgResPath, "Sale_New/ui/main/ui_main_prize_bg3_shu_1.png")
    else
        table.insert(self.m_bgResPath, "Sale_New/ui/main/ui_main_prize_bg1_1.png")
        table.insert(self.m_bgResPath, "Sale_New/ui/main/ui_main_prize_bg2_1.png")
        table.insert(self.m_bgResPath, "Sale_New/ui/main/ui_main_prize_bg3_1.png")
    end
end

function RoutineSaleMainLayer:getTouch()
    return self.m_isTouch
end

function RoutineSaleMainLayer:setTouch(_flag)
    self.m_isTouch = _flag
end

function RoutineSaleMainLayer:setBuy(_flag)
    self.m_isBuy = _flag
end

function RoutineSaleMainLayer:clickFunc(_sender)
    if self:getTouch() then
        return
    end

    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI(function ()
            if self.m_pop then
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        end)
    elseif name == "btn_spin" then
        local params = {}
        params.baseCoins = self.m_data:getWheelBaseCoins()
        params.maxUsd = self.m_data:getWheelMaxUsd()
        params.wheelChunk = self.m_data:getWheelChunk()
        params.count = self.m_data:getWheelAllPro()
        params.isReward = false
        G_GetMgr(G_REF.RoutineSale):showTurntableLayer(params)
    end
end

-- 充值成功
function RoutineSaleMainLayer:onBuySuccessEvt(_params)
    local index = _params.index
    local saleNode = self.m_saleNodes[index]
    local saleData = saleNode:getData()

    self.m_buyIndex = index

    local view = util_createView("GameModule.Shop.BuyTip")
    local buyType = BUY_TYPE.ROUTINE_SALE
    view:initBuyTip(buyType, saleData, saleData.p_coins, nil)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function RoutineSaleMainLayer:updateWheelData()
    if not self.m_buyIndex or self.m_buyIndex <= 0 then
        return
    end

    local index = self.m_buyIndex
    local saleNode = self.m_saleNodes[index]
    local func2 = function ()
        local startPos = saleNode:getPrizeBgPos()
        local worldPos, rotate = self.m_turntable:getPosAndRotate()
        local bgPath = self.m_bgResPath[index]
        local sp_bg = util_createSprite(bgPath)
        local pos = self.m_node_middle:convertToNodeSpace(cc.p(startPos.x, startPos.y))
        sp_bg:setPosition(pos)
        self.m_node_middle:addChild(sp_bg)

        local scale = 1
        if self.m_isShownAsPortrait then
            local scaleList = {0.39, 0.35, 0.34}
            scale = scaleList[index]
        else
            local scaleList = {0.39, 0.35, 0.28}
            scale = scaleList[index]
        end

        local endPos = self.m_node_middle:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
        local move = cc.MoveTo:create(0.5, endPos)
        local scaleTo = cc.ScaleTo:create(0.5, scale)
        local rotateTo = cc.RotateTo:create(0.5, rotate)
        local spawn = cc.Spawn:create(move, scaleTo, rotateTo)
        sp_bg:runAction(spawn)

        -- self.m_node_turntable:setRotation()

        local delay = cc.DelayTime:create(0.7)
        local callFun = cc.CallFunc:create(function ()
            -- sp_bg:setVisible(false)
            -- self.m_turntable:updateView()

            local curPro = self.m_data:getWheelCurPro()
            local totalPro = self.m_data:getWheelAllPro()
            if curPro >= totalPro then
                self:showTurntableLayer()
            else
                self:closeUI(function ()
                    if self.m_pop then
                        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    end
                end)
            end
        end)
        sp_bg:runAction(cc.Sequence:create(delay, callFun))
    end
    saleNode:playHideReward(func2)
    self.m_turntable:playIdle()
    self.m_spin:playIdle()
end

function RoutineSaleMainLayer:showTurntableLayer()
    local wheelReward = self.m_data:getWheelReward()
    if wheelReward then
        local params = {}
        params.baseCoins = self.m_data:getWheelBaseCoins()
        params.maxUsd = self.m_data:getWheelMaxUsd()
        params.wheelChunk = self.m_data:getWheelChunk()
        params.count = self.m_data:getWheelAllPro()
        params.wheelReward = wheelReward
        params.isReward = true
        self:closeUI(function ()
            G_GetMgr(G_REF.RoutineSale):showTurntableLayer(params)
        end)
    else
        self:closeUI(function ()
            if self.m_pop then
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        end)
    end
end

-- 充值失败
function RoutineSaleMainLayer:onBuyFailedEvt(_params)
    if _params.errorInfo then
        local view = self:checkPopPayConfirmLayer(_params)
        if not view then
            self:setTouch(false)
        end
    else
        self:setTouch(false)
    end
end

function RoutineSaleMainLayer:checkPopPayConfirmLayer(_params)
    local errorInfo = _params.errorInfo
    if not errorInfo or not errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end
    
    local index = _params.index
    local saleNode = self.m_saleNodes[index]
    local saleData = saleNode:getData()

    local payCoins = saleData.p_coins
    local priceV = saleData.p_price
    local params = {
        coins = payCoins,
        price = priceV,
        expireAt = self.m_data:getExpireAt(),
        confirmCB = function()
            if not tolua.isnull(self) then
                saleNode:buySale(saleData, index)
            end
        end,
        cancelCB = function()
            if not tolua.isnull(self) then
                self:setTouch(false)
            end
        end
    }

    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

function RoutineSaleMainLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    RoutineSaleMainLayer.super.playShowAction(self, "start")
end

function RoutineSaleMainLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function RoutineSaleMainLayer:registerListener()
    RoutineSaleMainLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onBuySuccessEvt", ViewEventType.NOTIFY_ROUTINE_SALE_BUY_SUCCESS) -- 充值成功
    gLobalNoticManager:addObserver(self, "onBuyFailedEvt", ViewEventType.NOTIFY_ROUTINE_SALE_BUY_FAILED) -- 充值失败
    gLobalNoticManager:addObserver(self, "updateWheelData", ViewEventType.NOTIFY_ROUTINE_SALE_WHEEL_UPDATE) -- 更新轮盘数据
end

function RoutineSaleMainLayer:closeUI(_func)
    local callBack = function()
        if not self.m_isBuy and self.m_params.levelUp then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
        end

        --弹窗逻辑执行下一个事件
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        if self.m_triggerPosition ~= "Login" then
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end

        if _func then
            _func()
        end
    end

    RoutineSaleMainLayer.super.closeUI(self, callBack)
end

return RoutineSaleMainLayer