--[[--
    小猪主界面
]]
local PiggyBankLayer = class("PiggyBankLayer", BaseLayer)
function PiggyBankLayer:initDatas(data)
    -- 外部传递数据
    self.m_collectData = data

    -- 小猪网络数据
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    self.m_iprice = piggyBankData.p_price
    self.m_iapId = piggyBankData.p_productKey
    self.m_oldIprice = piggyBankData.p_valuePrice
    self.m_iCollectCoin = piggyBankData.p_coins
    self.m_vipPoint = piggyBankData.p_vipPoint

    self.m_gotoBreakPiging = false
    self.m_isBreakingPig = false

    self:setLandscapeCsbName("PigBank2022/csb/main/PiggyBank.csb")
    self:setPortraitCsbName("PigBank2022/csb/main/PiggyBank_Portrait.csb")
    self:setPauseSlotsEnabled(true)
end

function PiggyBankLayer:isGoingBreakPig()
    return self.m_gotoBreakPiging
end

function PiggyBankLayer:isBreakingPig()
    return self.m_isBreakingPig
end

function PiggyBankLayer:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self.m_btnInfo = self:findChild("btn_tip")
    -- 光线
    self.m_nodeLight = self:findChild("node_light")
    -- 金币显示面板
    self.m_nodeCoinBoard = self:findChild("node_board")
    -- 小猪
    self.m_nodePig = self:findChild("node_pig")
    -- 小猪后背气泡
    self.m_nodeBubble1 = self:findChild("node_qipao_1")
    self.m_nodeBubble2 = self:findChild("node_qipao_2")
    -- 小猪送卡系列活动
    self.m_nodeChallenge = self:findChild("node_challenge")
    -- 被砸的小猪
    self.m_nodeBreakPig = self:findChild("node_break_pig")
    -- 砸小猪引导
    self.m_nodeBreakGuide = self:findChild("node_guide")
    -- 砸小猪的人
    self.m_nodeBreakNpc = self:findChild("node_break_npc")
end

function PiggyBankLayer:initView()
    self:initLight()
    self:initPigSpine()
    self:initBubbles()
    self:initCoinBoard()
    self:initPigChallengeUI()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function PiggyBankLayer:initLight()
    local lightCsb = nil
    if globalData.slotRunData.isPortrait == true then
        lightCsb = "PigBank2022/csb/main/PBLight_Portrait.csb"
    else
        lightCsb = "PigBank2022/csb/main/PBLight.csb"
    end
    local light = util_createAnimation(lightCsb)
    self.m_nodeLight:addChild(light)
    light:playAction("idle", true, nil, 60)
end

function PiggyBankLayer:initPigSpine()
    --  免费时用免费小猪spine
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if data and data:isMax() then
        self.m_piggySpine = util_spineCreate("PigBank2022/other/spine/xiaozhu", true, true, 1)
        util_spinePlay(self.m_piggySpine, "start")
        util_spineEndCallFunc(
            self.m_piggySpine,
            "start",
            function()
                util_spinePlay(self.m_piggySpine, "idle", true)
            end
        )
    else
        self.m_piggySpine = util_spineCreate("PigBank2022/other/spine/PigBank_npc1", true, true, 1)
        util_spinePlay(self.m_piggySpine, "idle", true)
    end
    self.m_piggySpine:setScale(0.8)
    self.m_nodePig:addChild(self.m_piggySpine)

    -- 折扣挂在小猪spine插槽里
    self:initDiscount()
    -- max挂在小猪spine插槽里
    if data and data:isMax() then
        self:initMax()
    end
end

function PiggyBankLayer:playPiggyOver(_over)
    util_spinePlay(self.m_piggySpine, "over", false)
    util_spineEndCallFunc(
        self.m_piggySpine,
        "over",
        function()
            if _over then
                _over()
            end
        end
    )
end

function PiggyBankLayer:initDiscount()
    local upperRate = G_GetMgr(G_REF.PiggyBank):getDiscountRate()
    if upperRate and upperRate > 0 then
        assert(self.m_piggySpine ~= nil, "得先创建spine")
        local discountNode = util_createView("views.piggy.main.PBMainDiscountNode")
        -- discountNode:setScaleX(-1)
        -- discountNode:setRotation(10) -- 客户端设置74，spine换了好几次了角度不对
        util_spinePushBindNode(self.m_piggySpine, "ef_shuzi", discountNode)
    end
end

function PiggyBankLayer:initMax()
    local maxTip = util_createAnimation("PigBank2022/csb/main/PBMaxTip.csb")
    util_spinePushBindNode(self.m_piggySpine, "biaoqian", maxTip)
end

function PiggyBankLayer:initBubbles()
    self.m_bubble = util_createView("views.piggy.main.PBMainBubbleNode")
    self.m_nodeBubble2:addChild(self.m_bubble)
end

function PiggyBankLayer:initCoinBoard()
    self.m_coinBoard = util_createView("views.piggy.main.PBMainCoinBoardNode", handler(self, self.buyPiggy), handler(self, self.buyFreePiggy))
    self.m_nodeCoinBoard:addChild(self.m_coinBoard)
end

function PiggyBankLayer:initPigChallengeUI()
    if gLobalActivityManager:checktActivityOpen(ACTIVITY_REF.PiggyChallenge) then
        if not self.m_pigProgressUI then
            self.m_pigProgressUI = util_createView("activities.Activity_PiggyChallenge.view.PigChallengeProcess")
        end
        if self.m_pigProgressUI then
            self.m_pigProgressUI:setName("Activity_PiggyBankProgress")
            self.m_nodeChallenge:addChild(self.m_pigProgressUI)
        end
    end
end

function PiggyBankLayer:removePigChallenge()
    if not tolua.isnull(self) and not tolua.isnull(self.m_pigProgressUI) then
        self.m_pigProgressUI:removeFromParent()
        self.m_pigProgressUI = nil
    end
end

-- 被砸裂的小猪
function PiggyBankLayer:createBreakPiggy()
    self.m_breakPiggy = util_createView("views.piggy.main.PBMainBrokenNode", handler(self, self.breakPiggy))
    self.m_nodeBreakPig:addChild(self.m_breakPiggy)
end

-- 砸小猪的npc
function PiggyBankLayer:playBreakNpcStart(_over)
    gLobalSoundManager:playSound("PigBank2022/other/music/breakNpc_show.mp3")
    self.m_breakNpcSpine = util_spineCreate("PigBank2022/other/spine/PigBank_npc2", false, true, 1)
    self.m_nodeBreakNpc:addChild(self.m_breakNpcSpine)
    util_spinePlay(self.m_breakNpcSpine, "start", false)
    util_spineEndCallFunc(
        self.m_breakNpcSpine,
        "start",
        function()
            util_spinePlay(self.m_breakNpcSpine, "idle", true)
            if _over then
                _over()
            end
        end
    )
end

function PiggyBankLayer:playBreakNpcSmash(_over)
    if not self.m_breakNpcSpine then
        return
    end
    util_spinePlay(self.m_breakNpcSpine, "show", false)
    util_spineEndCallFunc(
        self.m_breakNpcSpine,
        "show",
        function()
            util_spinePlay(self.m_breakNpcSpine, "idle", true)
            if _over then
                _over()
            end
        end
    )
end

function PiggyBankLayer:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function PiggyBankLayer:playRise1(_over)
    gLobalSoundManager:playSound("PigBank2022/other/music/npc_piggy_hide.mp3")
    util_performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("PigBank2022/other/music/coinBoard_hide.mp3")
        end,
        1
    )
    self:runCsbAction("rise1", false, _over, 60)
end

function PiggyBankLayer:playRise2(_over)
    gLobalSoundManager:playSound("PigBank2022/other/music/desk_show.mp3")
    self:runCsbAction("rise2", false, _over, 60)
end

function PiggyBankLayer:playFall(_over)
    -- 创建掉落的小猪
    self:createBreakPiggy()
    gLobalSoundManager:playSound("PigBank2022/other/music/brokenPiggy_show.mp3")
    self:runCsbAction("fall", false, _over, 60)
end

function PiggyBankLayer:buyFreePiggy()
    if self.m_isBuyingFree then
        return
    end
    self.m_isBuyingFree = true

    -- 每次购买前都保存一下结算界面显示的金币， 因为购买后会升档，基础金币会变化，促销倍数也可能会变化
    local isPromotion, upperRate = self:checkPromotion()
    local totalCoins = self.m_iCollectCoin
    if isPromotion and upperRate then
        totalCoins = self.m_iCollectCoin + self.m_iCollectCoin * upperRate / 100
    end
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    data:setRewardCoin(totalCoins)

    G_GetMgr(G_REF.PiggyBank):buyFree()
end

function PiggyBankLayer:buySuccessFreeCallBack()
    -- 清空价值
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    piggyBankData:clearData()
    -- 刷新数据消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_PIGBANK_DATA)
    -- 转到砸小猪
    self:gotoBreakPig()
end

function PiggyBankLayer:buyPiggy(_isRePay)
    if self.m_isOpenPiggy and not _isRePay then
        return
    end
    self.m_isOpenPiggy = true

    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(self, "btn_buy", DotUrlType.UrlName, false)
    end
    if not _isRePay then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end

    local isPromotion, upperRate = self:checkPromotion()
    local totalCoins = self.m_iCollectCoin
    if isPromotion and upperRate then
        totalCoins = self.m_iCollectCoin + self.m_iCollectCoin * upperRate / 100
    end

    -- 每次购买前都保存一下结算界面显示的金币， 因为购买后会升档，基础金币会变化，促销倍数也可能会变化
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    data:setRewardCoin(totalCoins)

    gLobalSaleManager:setBuyVippoint(self.m_vipPoint)
    --添加道具log
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    local itemList = gLobalItemManager:checkAddLocalItemList(piggyBankData)
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.PIGGYBANK_TYPE,
        self.m_iapId,
        self.m_iprice,
        totalCoins,
        0,
        function()
            if not tolua.isnull(self) then
                self:buySuccess()
            end
        end,
        function(_errorInfo)
            if not tolua.isnull(self) then
                -- 检查 是否是玩家主动取消并去弹出 挽留弹板
                local view = self:checkPopPayConfirmLayer(_errorInfo)
                if not view then
                    -- 没有弹出二次确认弹板 真正失败所做的事
                    self:buyFail()
                end                
            end
        end
    )
end

function PiggyBankLayer:buySuccess()
    -- 清空价值
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    piggyBankData:clearData()
    -- 刷新数据消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_PIGBANK_DATA)
    -- 打点
    self:setLogIap()
    -- 转到砸小猪
    self:gotoBreakPig()
end

-- 支付失败
function PiggyBankLayer:buyFail()
    self.m_isOpenPiggy = false
end

-- 检查是否弹出 二次确认弹板
function PiggyBankLayer:checkPopPayConfirmLayer(_errorInfo)
    if not _errorInfo or not _errorInfo.bCancel then
        -- 非用户自主取消 返回
        return
    end
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    if not piggyBankData then
        return
    end
    local totalCoins = piggyBankData:getRewardCoin() or 0
    local params = {
        coins = totalCoins, --弹板需要显示的金币数量
        price = self.m_iprice, --弹板需要显示的价格
        confirmCB = function()
            -- 确认按钮点击 重新发起支付
            if not tolua.isnull(self) then
                self:buyPiggy(true)
            end
        end,
        cancelCB = function()
            -- 取消按钮点击，真正支付失败
            if not tolua.isnull(self) then
                self:buyFail()
            end
        end
    }
    local view = G_GetMgr(G_REF.PaymentConfirm):showPayCfmLayer(params)
    return view
end

--[[--
    切换到砸小猪界面流程：
        先arise
        arise到195播放npc1中的over，播完
        [停顿0.5s]播放drop
        drop播完后播放npc2中的人出现，接idle
]]
function PiggyBankLayer:gotoBreakPig()
    self.m_triggerGoBreakFuncList = {
        handler(self, self.startGoBreak),
        handler(self, self.playRise1),
        handler(self, self.playRise2),
        handler(self, self.playPiggyOver),
        handler(self, self.playFall),
        handler(self, self.playBreakNpcStart),
        handler(self, self.overGoBreak)
    }
    self:triggerGoBreakFuncNext()
end

function PiggyBankLayer:triggerGoBreakFuncNext()
    if not self.m_triggerGoBreakFuncList or #self.m_triggerGoBreakFuncList <= 0 then
        return
    end
    local function callFunc()
        if not tolua.isnull(self) then
            self:triggerGoBreakFuncNext()
        end
    end
    local func = table.remove(self.m_triggerGoBreakFuncList, 1)
    func(callFunc)
end

function PiggyBankLayer:startGoBreak(_over)
    self.m_gotoBreakPiging = true
    if _over then
        _over()
    end
end

function PiggyBankLayer:overGoBreak(_over)
    self.m_gotoBreakPiging = false
    self:startBreakTip()
    if _over then
        _over()
    end
end

-- 砸小猪时，若玩家2s无操作，则增加光圈引导点击
function PiggyBankLayer:startBreakTip()
    self:stopBreakTip()
    local totalTime = 2
    local curTime = 0
    self.m_breakTimer =
        schedule(
        self,
        function()
            curTime = curTime + 1
            if curTime >= totalTime then
                self:createBreakTipNode()
                if self.m_breakTimer then
                    self:stopAction(self.m_breakTimer)
                    self.m_breakTimer = nil
                end
            end
        end,
        1
    )
end

function PiggyBankLayer:stopBreakTip()
    if self.m_breakTimer then
        self:stopAction(self.m_breakTimer)
        self.m_breakTimer = nil
    end
end

function PiggyBankLayer:createBreakTipNode()
    -- 如果正在砸小猪动作，不创建
    if self.m_isBreakingPig == true then
        return
    end
    if not self.m_breakTipNode then
        self.m_breakTipNode = util_createAnimation("PigBank2022/csb/main/PBGuide.csb")
        self.m_nodeBreakGuide:addChild(self.m_breakTipNode)
        self.m_breakTipNode:playAction(
            "start",
            false,
            function()
                self.m_breakTipNode:playAction("idle", true, nil, 60)
            end,
            60
        )
    end
    self:hideBreakTipNode(false)
end

function PiggyBankLayer:hideBreakTipNode(_isHide)
    if self.m_breakTipNode then
        self.m_breakTipNode:setVisible(not _isHide)
    end
end

--[[--
    砸小猪流程：
    点1次：播放npc2中的挥锤子的动作，确定在哪一帧播放PiggyBank_Break_pig的lie1
    点2次：播放npc2中的挥锤子的动作，确定在哪一帧播放PiggyBank_Break_pig的lie2
    点3次：播放npc2中的挥锤子的动作，确定在哪一帧播放PiggyBank_Break_pig的lie3
    lie3播放结束，弹出领奖弹板
]]
function PiggyBankLayer:breakPiggy()
    -- 移除砸小猪引导光圈计时器
    self:stopBreakTip()
    -- 移除砸小猪引导光圈节点
    self:hideBreakTipNode(true)
    -- 动效流程
    self.m_isBreakingPig = true
    gLobalSoundManager:playSound("PigBank2022/other/music/breakNpc_break.mp3")
    self:playBreakNpcSmash(
        function()
            self.m_isBreakingPig = false
        end
    )
    util_performWithDelay(
        self,
        function()
            self.m_breakPiggy:breakPiggy(
                function()
                    self:startBreakTip()
                end
            )
        end,
        13 / 30
    )
end

--小猪转盘断线重连
function PiggyBankLayer:reconnectGoodWheelPiggyMainLayer()
    local data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
    if data and data:checkIsReconnectPop() then
        G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):showMainLayer()
    else
        local limitExpansion = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
        if limitExpansion then
            limitExpansion:showLogoLayer()
            limitExpansion:playStartAction()
        end
    end
end

function PiggyBankLayer:onShowedCallFunc()
    if self.m_collectData then
        -- 打开界面直接展示砸小猪逻辑，因为已经在外部付费了
        if self.m_collectData.isFree then
            self:buySuccessFreeCallBack()
        else
            self:buySuccess()
        end
    else
        self:playIdle()
        self:reconnectGoodWheelPiggyMainLayer()
    end
end

function PiggyBankLayer:closeUI(_over)
    if self.m_closed then
        return
    end
    self.m_closed = true
    gLobalSendDataManager:getLogIap():closeIapLogInfo()
    -- 小猪累充活动隐藏 粒子
    if self.m_pigProgressUI then
        self.m_pigProgressUI:setParticleVisible(false)
    end
    PiggyBankLayer.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
        end
    )
end

function PiggyBankLayer:canClick()
    if self:isShowing() then
        return false
    end
    if self:isHiding() then
        return false
    end
    if self.m_gotoBreakPiging then
        return false
    end
    if self.m_isBuyingFree then
        return false
    end
    if self.m_isOpenPiggy then
        return false
    end
    return true
end

function PiggyBankLayer:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI(
            function()
                G_GetMgr(G_REF.PiggyBank):doMainCloseFunc()
            end
        )
    elseif name == "btn_tip" then
        G_GetMgr(G_REF.PiggyBank):showInfoLayer()
    elseif name == "btn_pb" then
        local saleData = {p_price = self.m_iprice, p_vipPoint = self.m_vipPoint}
        G_GetMgr(G_REF.PBInfo):showPBInfoLayer(saleData)
    end
end

function PiggyBankLayer:onEnter()
    PiggyBankLayer.super.onEnter(self)

    G_GetMgr(G_REF.FirstCommonSale):requestFirstSale()
    --刷新商店UI
    globalData.saleRunData:setShowTopeSale(true)
    -- 打点
    if not self.m_collectData then
        self:setLogOpen()
    end

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params then
                if params.isSuc == true then
                    self:buySuccessFreeCallBack()
                else
                    self.m_isBuyingFree = false
                end
            end
        end,
        ViewEventType.PIGGY_BANK_BUY_FREE
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_PIG_CHALLENGE_PROCESS_CLICKED
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            self.m_isOpenPiggy = false
        end,
        ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    )
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.PiggyChallenge then
                self:removePigChallenge()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
    -- 活动完成
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.PiggyChallenge then
                self:removePigChallenge()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_COMPLETED
    )
end

-- 优先显示新手期 先判断
function PiggyBankLayer:checkPromotion()
    -- 根据服务器数据来显示具体内容 加成促销活动--
    local upperRate = G_GetMgr(G_REF.PiggyBank):getPiggySaleRate()
    local logName = self:getLogName()

    if upperRate and upperRate > 0 then
        return true, upperRate, logName
    end
    return false, 0
end

function PiggyBankLayer:getLogName()
    local logName = nil
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    local isInNoviceDiscount = piggyBankData:checkInNoviceDiscount() -- 小猪新手折扣活动促销
    local pigRandomCardData = G_GetMgr(ACTIVITY_REF.PigRandomCard):getRunningData()
    -- 小猪送缺卡活动
    local pigCoinsData = G_GetMgr(ACTIVITY_REF.PigCoins):getRunningData() -- 小猪促销活动
    local clanSaleData = G_GetMgr(ACTIVITY_REF.PigClanSale):getRunningData() -- 公会小猪折扣
    if isInNoviceDiscount then
        logName = "noviceDiscount"
    elseif pigRandomCardData and pigRandomCardData:isRunning() then
        logName = "common"
    elseif pigCoinsData and pigCoinsData:isRunning() then -- TODO：测试是否有isRunning
        logName = "common"
    elseif clanSaleData and clanSaleData:isRunning() then
        logName = LOG_IAP_ENMU.purchaseName.PigClanSale
    end
    return logName
end

function PiggyBankLayer:setLogIap()
    local isPromotion, upperRate = self:checkPromotion()
    local totalCoins = self.m_iCollectCoin
    local addCoinsActivity = 0
    if isPromotion and upperRate then
        totalCoins = self.m_iCollectCoin + self.m_iCollectCoin * upperRate / 100
        addCoinsActivity = totalCoins - self.m_iCollectCoin
    end
    gLobalSendDataManager:getLogIap():setAddCoins(self.m_iCollectCoin, nil, addCoinsActivity, self.m_vipPoint)
end

function PiggyBankLayer:setLogOpen()
    local saleRate = G_GetMgr(G_REF.PiggyBank):getPiggySaleRate(true)
    local goodsInfo = {}
    goodsInfo.goodsTheme = "PiggyBankLayer"
    goodsInfo.goodsId = self.m_iapId
    goodsInfo.goodsPrice = self.m_iprice
    goodsInfo.discount = saleRate

    local totalCoins = self.m_iCollectCoin
    if goodsInfo.discount and goodsInfo.discount > 0 then
        totalCoins = self.m_iCollectCoin + self.m_iCollectCoin * goodsInfo.discount / 100
    end
    goodsInfo.totalCoins = totalCoins
    local isPromotion, upperRate, promotionType = self:checkPromotion()
    local buffId = nil
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "pig"

    if buffId then
        purchaseInfo.purchaseName = LOG_IAP_ENMU.purchaseName.pigBuff --
        purchaseInfo.purchaseStatus = self:getPigLogBuff(buffId)
    elseif isPromotion then
        if promotionType == "noviceDiscount" then
            purchaseInfo.purchaseName = LOG_IAP_ENMU.purchaseName.pigNewUser
        elseif promotionType == LOG_IAP_ENMU.purchaseName.PigClanSale then
            purchaseInfo.purchaseName = LOG_IAP_ENMU.purchaseName.PigClanSale
        else
            purchaseInfo.purchaseName = LOG_IAP_ENMU.purchaseName.pigSale --
        end

        purchaseInfo.purchaseStatus = saleRate
    else
        purchaseInfo.purchaseName = LOG_IAP_ENMU.purchaseName.pigBank --
        purchaseInfo.purchaseStatus = "normal"
    end
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

--检测小猪buff
function PiggyBankLayer:getPigLogBuff(buffId)
    local buffData = globalData.buffConfigData:getBuffInfoById(tonumber(buffId))
    if buffData and buffData.buffType then
        return buffData.buffType
    end
    return "normal"
end

return PiggyBankLayer
