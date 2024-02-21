--[[
    ---每日轮盘
    ---4-27
    ---何佳宝
]]
-- FIX IOS 139 3
local BaseRotateLayer = util_require("base.BaseRotateLayer")
local DailybonusLayer = class("DailybonusLayer", BaseRotateLayer)
DailybonusLayer.m_cashWheel = nil
DailybonusLayer.m_spineT = nil
DailybonusLayer.m_bgLightT = nil

DailybonusLayer.m_wheelState = nil --轮盘状态 付费轮盘还是基础轮盘
DailybonusLayer.m_bAdsReward = nil --是否播放过广告视频再转一次 用于轮盘转完判断
DailybonusLayer.m_payWheelBuySuccess = nil
DailybonusLayer.m_mulitipJp = nil
DailybonusLayer.m_bJpResult = nil
DailybonusLayer.m_bHasDeluexe = nil

GD.WHEELTYPE = {
    WHEELTYPE_NORMAL = 1, -- 基础轮盘
    WHEELTYPE_PAY = 2, -- 支付轮盘
    WHEELTYPE_NewJp = 4 -- 添加jP Item轮盘
}

function DailybonusLayer:ctor()
    DailybonusLayer.super.ctor(self)
    self:setLandscapeCsbName("Hourbonus_new3/DailyBonusLayer.csb")

    self:setPauseSlotsEnabled(true)
    self:setShowActionEnabled(false)
    self:setBgm("Hourbonus_new3/sound/DailybonusNormalBG.mp3")
    -- self:setHideActionEnabled(false)

    self.m_spineT = {}
    self.m_bgLightT = {}
    self.m_wheelState = WHEELTYPE.WHEELTYPE_NORMAL
    self.m_bAdsReward = false
    self.m_payWheelBuySuccess = false
    self.m_mulitipJp = 1
    self.m_bJpResult = false
    self.m_isWatchAds = nil
    self.m_bTouchSpeedBtn = true

    self:setShowBgOpacity(0)
    G_GetMgr(G_REF.CashBonus):setJackpotData(0)
    self.m_bHasDeluexe = globalData.deluexeClubData:getDeluexeClubStatus() --记录下是否有高倍场 防止购买后触发高倍场结算
end

function DailybonusLayer:initUI()
    -- setDefaultTextureType("RGBA8888", nil)
    DailybonusLayer.super.initUI(self)

    local spinBtn = self:findChild("tempCloseBtn")
    spinBtn:setVisible(false)
    self:addClick(spinBtn)

    --适配
    self:adaptBonusLayer()

    self:showWheelNode(false)

    --将功能分解
    self:initWheelNode()

    self:initUIAdd()
    -- setDefaultTextureType("RGBA4444", nil)

    self:setExtendData("DailyBonusLayer")
    if G_GetMgr(G_REF.Flower) and G_GetMgr(G_REF.Flower):getData() then
        G_GetMgr(G_REF.Flower):getData():setSilCkm()
    end
end

--轮盘
function DailybonusLayer:initWheelNode()
    self.m_bonusWheel = util_createView("views.cashBonus.DailyBonus.DailybonusWheel")
    self:addChild(self.m_bonusWheel)
    local normalWheel = self:findChild("NormalWheelNode")
    self.m_bonusWheel:setWheelNode(self, normalWheel)
end

--ui节点添加
function DailybonusLayer:initUIAdd()
    --门帘
    self:initAddCurtainSpine()

    self:initNpcSpine()

    --vip弹板
    self:addVipView()

    --添加翻倍的label
    self:addMultipLabel()

    self:initJackPot()

    --设置付费轮盘倍数
    self:resetMultiple()

    self:initSpeedBtn()
end

--设置付费轮盘倍数
function DailybonusLayer:resetMultiple()
    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    self:findChild("LableBuyMulitip"):setString("X" .. self.m_bonusWheel:getNormalPayProShow())
    self:updateLabelSize({label = self:findChild("LableBuyMulitip")}, 140)
end

--适配
function DailybonusLayer:initSpeedBtn()
    self.m_btnSpeed = self:findChild("btnSpeed")
    if self.m_btnSpeed then
        self.m_btnSpeed:setOpacity(0)
        self.m_btnSpeed:setTouchEnabled(false)
        local posx = self.m_btnSpeed:getPositionX()
        local size = self.m_btnSpeed:getContentSize()
        local a = 1
        if posx - size.width / 2 < -display.width / 2 then
            self.m_btnSpeed:setPositionX(-display.width / 2 + size.width / 2 + 15)
        end
    end
end

--适配
function DailybonusLayer:adaptBonusLayer()
    -- self:adaptNodePos( self:findChild("Button_1") )
    -- self:adaptNodePos(self:findChild("tempCloseBtn"))
    -- self:adaptNodePos(self:findChild("NodeRward"))
    -- -- self:adaptNodePos( self:findChild("NodecCurtainRight") )
    -- local btn = self:findChild("Button_1")
    -- local posx = btn:getPositionX()
    -- local diffPosX = (1370 / 2 - posx + btn:getContentSize().width / 2) * UIScalePro
    -- btn:setPositionX(display.width / 2 - diffPosX)
end

function DailybonusLayer:adaptNodePos(node, bInner)
    local pos = cc.p(node:getPosition())
    local scale = self:getUIScalePro()
    if CC_RESOLUTION_RATIO == 3 then
        scale = 1
    end
    local posX = pos.x * scale
    node:setPositionX(posX)
end

function DailybonusLayer:initJackPot()
    ---jp
    self.m_JackpotLabel = self:findChild("jpLabel")
    self:updateJackpot(WHEELTYPE.WHEELTYPE_NORMAL)
    local jpAction = util_createAnimation("Hourbonus_new3/DailybonusJpLight.csb")
    jpAction:playAction("idle2", true)
    self:findChild("NodeJpLight"):addChild(jpAction)
end

function DailybonusLayer:addVipView()
    --vip
    self.m_vipAddview = util_createView("views.cashBonus.cashBonusPickGame.CashBonusVipAddView")
    self:findChild("NodeVip"):addChild(self.m_vipAddview)
    self.m_vipAddview:setScale(self:getUIScalePro()) --缩放下 vip版子
    self.m_vipAddview:setVisible(false)
    self.m_vipAddview:setPositionY(-10)
    self.m_vipAddview:initData2()
end

function DailybonusLayer:initNpcSpine()
    local spine_npc = util_spineCreate("Hourbonus_new3/spine/npc", true, true, 1)
    self:findChild("node_spine_npc"):addChild(spine_npc)
    util_spinePlay(spine_npc, "idle", true)
end

--显示finger
function DailybonusLayer:showFinger()
    if self.sp_finger then
        return
    end

    local finger = util_createAnimation("Hourbonus_new3/DailyBonus_NormalWheel_sz.csb")
    if finger then
        self:findChild("NormalWheelNode"):addChild(finger)
        finger:runCsbAction("idle", true, nil, 60)
        self.sp_finger = finger
    end
end

--隐藏finger
function DailybonusLayer:hideFinger()
    if self.sp_finger then
        self.sp_finger:setVisible(false)
    end
end

function DailybonusLayer:initAddCurtainSpine()
    local posX = display.width / 2 / UIScalePro
    local node_curtain = self:findChild("node_curtain")
    if util_IsFileExist("Hourbonus_new3/spine/lianziyouce.atlas") and util_IsFileExist("Hourbonus_new3/spine/lianziyouce.skel") and util_IsFileExist("Hourbonus_new3/spine/lianziyouce.png") then
        self:addCurtainSpine(node_curtain, "Hourbonus_new3/spine/lianziyouce", cc.p(-1 * posX, 0), true, nil, self.m_spineT)
        self:addCurtainSpine(node_curtain, "Hourbonus_new3/spine/lianziyouce", cc.p(posX, 0), false, nil, self.m_spineT)
    end
    self:addCurtainSpine(
        self:findChild("NodecCurtainMid"),
        "Hourbonus_new3/spine/lianzi",
        cc.p(0, -20),
        false,
        function()
            self:playShwoAnima()
        end,
        self.m_spineT
    )
end

--添加数字
function DailybonusLayer:addMultipLabel()
    self.m_labelMultip = util_createView("views.cashBonus.DailyBonus.DailybonusMultipLabel")
    self:addChild(self.m_labelMultip)
    self.m_labelMultip:setVisible(false)
end

function DailybonusLayer:addCurtainSpine(parentNode, spinName, pos, bFlip, curtainAnimaEndCallFun, spineT)
    local spine = util_spineCreate(spinName, true, true, 1)
    spineT[#spineT + 1] = spine
    parentNode:addChild(spine)
    if pos then
        spine:setPosition(pos)
    end
    spine:setName(spinName)

    if bFlip then
        spine:setScaleX(-1)
    end
    util_spinePlay(spine, "animation", false)
    util_spineEndCallFunc(
        spine,
        "animation",
        function()
            if curtainAnimaEndCallFun then
                curtainAnimaEndCallFun()
            end
            util_spinePlay(spine, "idleframe", false)
        end
    )
end

--播放showAnima
function DailybonusLayer:playShwoAnima()
    --隐藏大厅
    self:setHideLobbyEnabled(true) -- 但是因为没有复写onenter的动画 所以要手动调用一些隐藏大厅,但是 flag值也需要设置
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_SHOW_VISIBLED, {isHideLobby = true})
    --显示轮盘上的元素
    self:showWheelNode(true)

    --播放vip
    self.m_vipAddview:setVisible(true)
    self.m_vipAddview:runShowAction()
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusWheelJump.mp3")
        end,
        0.5
    )

    self:runCsbAction(
        "show",
        false,
        function()
            --播放vip特效
            if self.m_vipAddview then
                self.m_vipAddview:playVipEffect(
                    function()
                        self:flyMultipLabel()
                    end
                )
            end
            ---播放倍增器动画
            self.m_bonusWheel:playRewardXAction()
        end
    )
end

--播放数字数
function DailybonusLayer:flyMultipLabel()
    --倍数飞
    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusVipMulitipFly.mp3")

    --转换坐标 设置下初始坐标
    local vipNodeWorldPos = self.m_vipAddview:getNowVipNodeWorldPos()
    local pos = self:convertToNodeSpace(vipNodeWorldPos)
    self.m_labelMultip:setPosition(pos)

    --获取endPos
    local endPostion = self:getNodePos(self:findChild("NormalWheelNode"), self)
    self.m_labelMultip:setVisible(true)
    self.m_labelMultip:playFlyAction(
        cc.p(endPostion),
        function()
            self:playShow2Action()
        end
    )
end

function DailybonusLayer:getNodePos(node, convertNode)
    local nodeWorldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local endPostion = convertNode:convertToNodeSpace(nodeWorldPos)
    return endPostion
end

function DailybonusLayer:playShow2Action()
    self.m_labelMultip:removeFromParent()

    --特效层级原因在 spin按钮上再创建一个数字 播放动画
    self.m_labelMultip = self.m_bonusWheel:addMulitipLabel()

    self:runCsbAction(
        "show2",
        false,
        function()
        end
    )

    --播放增倍器动画
    self.m_bonusWheel:playCollectAction(
        function()
            --闪电结束回调
            --翻倍
            self.m_labelMultip:playLightHitAction()
            self:runCsbAction("zengbei", false)
            performWithDelay(
                self,
                function()
                    self:updateJackpot(WHEELTYPE.WHEELTYPE_NORMAL)
                    self.m_mulitipJp = self:getCoinMulitip()
                    self.m_jackpotCurCoin = self.m_jackpotCurCoin * self.m_mulitipJp
                end,
                2.5
            )
            --播放后可点击spin
            performWithDelay(
                self,
                function()
                    self.m_labelMultip:playMulitpXAction()
                    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusVipMulitipDown.mp3")
                    self:runCsbAction(
                        "chengbei",
                        false,
                        function()
                            if not tolua.isnull(self.m_btnSpeed) then
                                self.m_btnSpeed:runAction(
                                    cc.Sequence:create(
                                        cc.DelayTime:create(1),
                                        cc.FadeIn:create(0.5),
                                        cc.CallFunc:create(
                                            function()
                                                self.m_btnSpeed:setTouchEnabled(true)
                                            end
                                        )
                                    )
                                )
                            end
                            self:showFinger()

                            self.m_bonusWheel:setSpinTouchState(true)
                            self.m_bonusWheel:playSpinLightTouch()
                        end
                    )

                    --vip关闭
                    if self.m_vipAddview then
                        self.m_vipAddview:closeUI(
                            function()
                                self.m_vipAddview = nil
                            end
                        )
                    end
                end,
                2
            )
        end,
        function()
            --整个动画结束回调
        end
    )
end

function DailybonusLayer:getCoinMulitip()
    local mulitipValue = 1
    if self.m_wheelState == WHEELTYPE.WHEELTYPE_NORMAL then
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
        mulitipValue = self.m_bonusWheel:getRewardMulitip() * wheelData.p_vipMultiple
    end
    return mulitipValue
end
--点击转盘
function DailybonusLayer:playSpinAction()
    if self.m_wheelState == WHEELTYPE.WHEELTYPE_PAY then
        -- 弹出购买提示框
        self:buyWheelPay()
    else
        self:hideFinger()
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction(
            "switch",
            false,
            function()
                self.m_bonusWheel:rotateWheel()
            end
        )
    end
end

function DailybonusLayer:showBuyTipView()
    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    local funcBuy = function()
        --开转
        if not tolua.isnull(self) then
            self:buyRunPayWheel()
        end
    end
    local funcClose = function()
        if not tolua.isnull(self) then
            self:closeUI()
        end
    end

    local funcGetJpValue = function()
        if not tolua.isnull(self) then
            self:getJackpotAddValue()
        end
    end
    self.m_buyTipView =
        util_createView("views.cashBonus.DailyBonus.DailybonusBuyView", funcBuy, funcClose, funcGetJpValue, wheelPayData.p_coinsShowMax, self.m_bonusWheel:getNormalPayProShow(), wheelPayData.p_price)
    gLobalViewManager:showUI(self.m_buyTipView, ViewZorder.ZORDER_UI)
    --self.m_buyTipView:setPosition(cc.p(display.width / 2, display.height / 2))

    if not tolua.isnull(self.buyView) then
        self.buyView:closeUI()
    end
end

function DailybonusLayer:closeUI()
    self:findChild("Button_1"):setTouchEnabled(false)
    self:findChild("Button_1"):setVisible(false)
    if not tolua.isnull(self.m_luckyStampTipView) then
        self.m_luckyStampTipView:removeFromParent()
        self.m_luckyStampTipView = nil
    end
    if not tolua.isnull(self.m_infoPBnode) then
        self.m_infoPBnode:removeFromParent()
        self.m_infoPBnode = nil
    end

    self.m_bonusWheel:setSpinTouchState(false)

    self:runCsbAction("over2", false)

    -- 调用了每日轮盘关闭,就要隐藏手
    self:hideFinger()

    G_GetMgr(G_REF.CashBonus):checkDelayrefreshMultiply()
    DailybonusLayer.super.closeUI(
        self,
        function()
            local cb = function()
                if gLobalAdChallengeManager:isShowMainLayer() then
                    gLobalAdChallengeManager:showMainLayer()
                end
            end
            -- cxc 2023-12-04 12:05:40 每日轮盘结束后 检测运营弹板(1:银箱子， 2：金箱子， 3：轮盘， 4：cashMoney)
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Cashbonus", "Cashbonus_" .. 3)
            if view then
                view:setOverFunc(cb)
            else
                cb()
            end
           
            -- 更新diy任务数据
            self:sendDiyTaskUpdate()
        end
    )
end

function DailybonusLayer:sendDiyTaskUpdate()
    local mgr = G_GetMgr(ACTIVITY_REF.DIYFeatureMission)
    if nil == mgr then
        return nil
    end
    local actData = mgr:getRunningData()
    if not actData then
        return nil
    end
    --更新数据
    mgr:sendDiyTaskUpdate()
end

function DailybonusLayer:playHideAction()
    local action = function(_callback)
        performWithDelay(
            self,
            function()
                -- --关帘子
                for i = 1, #self.m_spineT do
                    local spine = self.m_spineT[i]
                    if spine:getName() == "Hourbonus_new3/spine/lianzi" then
                        util_spinePlay(spine, "animation", false)
                    end
                end
            end,
            0.4
        )

        performWithDelay(
            self,
            function()
                local pay_bg = self:findChild("node_bg_pay")
                if not tolua.isnull(pay_bg) then
                    pay_bg:setVisible(false)
                end
                --
                for i = 1, #self.m_spineT do
                    local spine = self.m_spineT[i]
                    if spine:getName() == "Hourbonus_new3/spine/lianzi" then
                        util_spinePlay(spine, "animation2", false)
                    end
                end
            end,
            1.8
        )

        performWithDelay(
            self,
            function()
                -- util_playFadeOutAction(self,0.6,function(  )
                --移植
                -- csc 2022-01-11 10:54:58 需要检测玩家是否看过之前的again激励
                if not self.m_isWatchAds then
                    if globalData.adsRunData:isPlayAutoForPos(PushViewPosType.FirstLogin) then
                        gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.FirstLogin)
                        gLobalAdsControl:playAutoAds(PushViewPosType.FirstLogin)
                    end
                end
                globalData.adsRunData.p_haveCashBonusWheel = false

                gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_UPDATE_MULTIPLE)
                gLobalSendDataManager:getLogIap():closeIapLogInfo()

                if _callback then
                    _callback()
                end
                -- end)
            end,
            3
        )
    end
    DailybonusLayer.super.playHideAction(self, action)
end

function DailybonusLayer:buyRunPayWheel()
    self:findChild("Button_1"):setVisible(false)
    --开转
    self.m_bonusWheel:setSpinTouchState(false)
    performWithDelay(
        self,
        function()
            self:runCsbAction(
                "switch2",
                false,
                function()
                    self.m_bonusWheel:rotateWheel()
                end
            )
        end,
        0.5
    )
end

function DailybonusLayer:buyWheelPay()
    self.m_bJpResult = false

    if self:getBuyWheelRewardIsJp() then
        self.m_bJpResult = true
        local jp_data = self:getJackpotAddValue()
        G_GetMgr(G_REF.CashBonus):setJackpotData(jp_data)
    end

    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    local buyRase = 0 ---翻倍
    local iapId = wheelPayData.p_key
    local price = wheelPayData.p_price
    local totalCoins = wheelPayData.p_value
    self.m_randomIndex = wheelPayData:getResultCoinIndex()

    if globalData.deluexeClubData:getDeluexeClubStatus() then
        totalCoins = totalCoins + totalCoins * globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD / 100
    end
    gLobalSendDataManager:getLogIap():setAddCoins(totalCoins)
    local goodsInfo = {}
    goodsInfo.totalCoins = totalCoins
    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:stopPayWheelJackpot()
    -- 购买成功
    local function buySuccessCallFun()
        -- 隐藏benefits
        gLobalSendDataManager:getLogIap():setLastEntryType()
        if self.m_luckyStampTipView ~= nil then
            self.m_luckyStampTipView:setVisible(false)
        end
        if self.m_infoPBnode ~= nil then
            self.m_infoPBnode:setVisible(false)
        end
        G_GetMgr(G_REF.CashBonus):setJackpotData(0)
        self.m_payWheelBuySuccess = true
        self:buyRunPayWheel()

        if not tolua.isnull(self.buyView) then
            self.buyView:closeUI()
        end
    end
    -- 购买失败
    local function buyFaildCallFun()
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.Roulette_purchase_failed1)
        end
        G_GetMgr(G_REF.CashBonus):setJackpotData(0)
        if not tolua.isnull(self) then
            -- 恢复购买按钮
            self.m_bonusWheel:setSpinTouchState(true)
        end
    end
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(wheelPayData)
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(BUY_TYPE.CASHBONUS_TYPE_NEW, iapId, price, totalCoins, buyRase, buySuccessCallFun, buyFaildCallFun)
end

function DailybonusLayer:wheelRotateEnd()
    --
    if self.m_wheelState == WHEELTYPE.WHEELTYPE_NewJp then
        self.m_bonusWheel:playNewJpAnimation()
        self:rotateEndCloseUI()
    else
        self:showResultLayer()
    end
end

function DailybonusLayer:rotateEndCloseUI()
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusJpAdd.mp3")
        end,
        1
    )
    performWithDelay(
        self,
        function()
            self:closeUI()
        end,
        3
    )
end

function DailybonusLayer:showResultLayer()
    if self.m_resultLayer then
        self.m_resultLayer:removeFromParent()
        self.m_resultLayer = nil
    end
    --弹出结算框
    self.m_resultLayer =
        util_createView(
        "views.cashBonus.DailyBonus.DaliyBonusReslutLayer",
        function()
            if self.m_wheelState == WHEELTYPE.WHEELTYPE_NORMAL then
                if not tolua.isnull(self) then
                    self:collectClickCallFun()
                end
            else
                if not tolua.isnull(self) then
                    self:collectSuccessCallFun()
                end
            end
        end,
        self.m_bHasDeluexe
    )
    self.m_resultLayer:setWheelType(self.m_wheelState)
    local totalCoins = self:getTotleRewardCoin()

    self.m_resultLayer:setWinCoinNum(totalCoins)
    gLobalViewManager:showUI(self.m_resultLayer, ViewZorder.ZORDER_UI)
    -- self.m_resultLayer:playStartAnima()
    --self.m_resultLayer:setPosition(cc.p(display.width / 2, display.height / 2))
end

function DailybonusLayer:showResultLayerSpeedMode()
    if self.m_resultLayer then
        self.m_resultLayer:removeFromParent()
        self.m_resultLayer = nil
    end
    --弹出结算框
    self.m_resultLayer =
        util_createView(
        "views.cashBonus.DailyBonus.DaliyBonusReslutLayer",
        function()
            if self.m_wheelState == WHEELTYPE.WHEELTYPE_NORMAL then
                if not tolua.isnull(self) then
                    self:collectClickCallFun()
                end
            else
                if not tolua.isnull(self) then
                    self:collectSuccessCallFun()
                end
            end
            -- self:collectNextWheelShow(  )
        end,
        self.m_bHasDeluexe
    )
    self.m_resultLayer:setWheelType(self.m_wheelState)
    local totalCoins = self:getTotleRewardCoin()

    self.m_resultLayer:setWinCoinNum(totalCoins)
    gLobalViewManager:showUI(self.m_resultLayer, ViewZorder.ZORDER_UI)
    --self.m_resultLayer:playStartAnima()
    --self.m_resultLayer:setPosition(cc.p(display.width / 2, display.height / 2))
end

function DailybonusLayer:getTotleRewardCoin()
    local totalCoins = 0

    if self.m_wheelState == WHEELTYPE.WHEELTYPE_NORMAL then
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
        totalCoins = wheelData.p_value * wheelData.p_vipMultiple * self.m_bonusWheel:getRewardMulitip()
    else
        G_GetMgr(G_REF.CashBonus):setJackpotData(0)
        if self.m_bJpResult then
            totalCoins = math.ceil(self.m_jackpotCurCoin)
        else
            totalCoins = self.m_bonusWheel:getPayTotleCoin()
        end
    end
    return totalCoins
end

function DailybonusLayer:getBuyWheelRewardIsJp()
    --添加jp
    local wheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    if wheelData:getResultCoinIndex() == 1 then
        return true
    end
    local jackpotList = self.m_bonusWheel:getJackpotList()
    if jackpotList then
        for i = 1, #jackpotList do
            local item = jackpotList[i]
            if item.index == wheelData:getResultCoinIndex() then
                return true
            end
        end
    end
    return false
end

function DailybonusLayer:collectNextWheelShow()
    if self.m_wheelState == WHEELTYPE.WHEELTYPE_NORMAL then
        if self:judgeAdsVideo() and self.m_bAdsReward == false then
            self:showAdsRewardView()
            self.m_bAdsReward = true
        else
            self.m_bAdsReward = false
            self:changePayWheel()
        end
    else
        --付费轮盘自动转一次添加jp
        self.m_wheelState = WHEELTYPE.WHEELTYPE_NewJp

        local addNewJpIndex = self.m_bonusWheel:getNewJpIndex()
        if addNewJpIndex ~= 0 then
            performWithDelay(
                self,
                function()
                    if not tolua.isnull(self) then
                        self:runAddNewJpWheel(addNewJpIndex)
                    end
                end,
                1.5
            )
        else
            self:closeUI()
        end
    end
end

function DailybonusLayer:showFun()
    -- 需要清空对象
    self.m_resultLayer = nil
    if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_PAYROULETTE then -- 这里是一个逻辑上的需求 ???
        self:closeUI()
    elseif self.m_bJpResult then --领取一个tournament
        self:closeUI()
    else
        self:collectNextWheelShow()
    end
end

function DailybonusLayer:collectSuccessCallFun()
    globalLocalPushManager:pushNotifyCashbonus()
    gLobalViewManager:removeLoadingAnima()

    --补丁
    if not self.m_resultLayer or not self.m_resultLayer.getCoinLabelWorldPos then
        self.m_resultLayer = nil
        self:closeUI()
        return
    end
    -- 获取飞行目标位置
    local endPos = globalData.flyCoinsEndPos
    local startPos = self.m_resultLayer:getCoinLabelWorldPos()
    local baseCoins = globalData.topUICoinCount
    local targetCoins = self.m_resultLayer:getWinCoinNum() or 0

    gLobalViewManager:pubPlayFlyCoin(
        startPos,
        endPos,
        baseCoins,
        targetCoins,
        function()
            -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            --播放关闭结算弹窗
            performWithDelay(
                self,
                function()
                    if tolua.isnull(self) or tolua.isnull(self.m_resultLayer) then
                        return
                    end
                    self.m_resultLayer:closeUI(
                        function()
                            if tolua.isnull(self) then
                                return
                            end
                            self:showFun()
                        end
                    )
                end,
                1
            )
        end
    )
end

--[[
    收集奖励
]]
function DailybonusLayer:collectClickCallFun()
    gLobalViewManager:addLoadingAnimaDelay()
    G_GetMgr(G_REF.CashBonus):sendActionCashBonus(CASHBONUS_TYPE.BONUS_WHEEL, self.m_isWatchAds)
end

--[[
    @desc: 付费轮盘操作
]]
function DailybonusLayer:changePayWheel()
    self.m_wheelState = WHEELTYPE.WHEELTYPE_PAY

    --隐藏加速按钮
    self:hideBtnSpeed()

    --掀开帘子
    for i = 1, #self.m_spineT do
        local spine = self.m_spineT[i]
        util_spinePlay(spine, "animation2", false)
    end

    for i = 1, #self.m_bgLightT do
        local item = self.m_bgLightT[i]
        item:setVisible(true)
        item:playAction("idle2", true)
    end

    --x按钮暂时不允许点击
    self:findChild("Button_1"):setTouchEnabled(false)
    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusWheellight.mp3")

    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusWheelBack.mp3")
        end,
        0.5
    )
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusPayWheelHoo.mp3")
        end,
        2.4
    )

    performWithDelay(
        self,
        function()
            self:updateJackpot(WHEELTYPE.WHEELTYPE_PAY)
            self.m_mulitipJp = self:getCoinMulitip()
            self.m_jackpotCurCoin = self.m_jackpotCurCoin * self.m_mulitipJp
        end,
        3.8
    )
    gLobalSoundManager:stopBgMusic()
    --播放转换为付费轮盘动画
    self:runCsbAction(
        "zhuanchang",
        false,
        function()
            if tolua.isnull(self) then
                return
            end
            local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
            self.m_labelMultip = self.m_bonusWheel:addMulitipLabel()
            self.m_labelMultip:setMultipNum(self.m_bonusWheel:getNormalPayPro())
            self.m_labelMultip:playbuyWheelMulitpXAction(
                function()
                    if tolua.isnull(self) then
                        return
                    end
                    --打点付费轮盘
                    gLobalSendDataManager:getLogFeature():sendCashBonusWheelLog("Pay")
                    local wheel_data = G_GetMgr(G_REF.CashBonus):getPayWheelData()
                    if wheel_data and wheel_data.p_values then
                        self.m_bonusWheel:changeBuyWheelCoinLabel(wheel_data.p_values)
                    end
                    self:runCsbAction(
                        "chengbei2",
                        false,
                        function()
                            if tolua.isnull(self) then
                                return
                            end
                            self:setBgm("Hourbonus_new3/sound/DailybonusPayBG.mp3")
                            --x按钮可以点击
                            self:findChild("Button_1"):setTouchEnabled(true)
                            --spin按钮准信点击
                            self.m_bonusWheel:setSpinTouchState(true)

                            self:runCsbAction("idle3", true)

                            local ef_light = util_createAnimation("Hourbonus_new3/DailybonusJpyuanpan.csb")
                            local node_light = self:findChild("node_light")
                            if ef_light and node_light then
                                ef_light:addTo(node_light)
                                ef_light:runCsbAction("idle2", true, nil, 30)
                            end

                            self:showBuyLayer()
                        end
                    )
                    self.m_labelMultip:setVisible(false)
                end
            )
        end
    )
    self:hideFinger()
    self.m_bonusWheel:switchToPayWheel(self:findChild("BuyWheelNode"))
    --添加付费打点
    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
    local goodsInfo = {}
    goodsInfo.goodsTheme = "CashBonusWheelView"
    goodsInfo.goodsId = wheelPayData.p_key
    goodsInfo.goodsPrice = wheelPayData.p_price
    goodsInfo.discount = wheelPayData.p_multiple * 100
    goodsInfo.totalCoins = nil
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "dayRoulette"
    purchaseInfo.purchaseName = "dayRoulette" .. wheelPayData:getPayIdx()
    purchaseInfo.purchaseStatus = "normal"
    gLobalSendDataManager:getLogIap():setEntryType("Wheel")
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

function DailybonusLayer:showBuyLayer()
    local node_Buycell = self:findChild("node_Buycell")
    if not node_Buycell then
        return
    end
    local buyView = util_createView("views.cashBonus.DailyBonus.DailybonusBuyLayer")
    if buyView then
        buyView:addTo(node_Buycell)
        self.buyView = buyView
    end
end

--付费轮盘后添加newJp
function DailybonusLayer:runAddNewJpWheel(newJpIndex)
    gLobalSoundManager:playSound("Hourbonus_new3/sound/DailybonusJpWheelLight.mp3")
    self:runCsbAction(
        "Jackpotshengcheng",
        false,
        function()
            if tolua.isnull(self) then
                return
            end
            self.m_bonusWheel:playAddJpAction(newJpIndex)
        end
    )
end

function DailybonusLayer:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "tempCloseBtn" then
        self:closeUI()
    elseif senderName == "Button_1" then
        self:showBuyTipView()
    elseif senderName == "btnSpeed" then
        if not self:getTouchBtnSpeed() then
            return
        end

        -- 跳过一切....
        self.m_bonusWheel:stopAllActions()
        self:stopAllActions()
        util_resetCsbAction(self.m_csbAct)

        self:resetCsbAction(self.m_vipAddview)
        self:resetCsbAction(self.m_labelMultip)

        self.m_bonusWheel:pauseAllEffect()
        self:runCsbAction("zhongjiang", false)

        self:hideFinger()

        self:stopViewAciton(self.m_labelMultip)
        self:stopViewAciton(self.m_vipAddview)

        --转圈
        self.m_bonusWheel:rotateWheel()
        self.m_bonusWheel:imdStopWheel()

        self:setTouchBtnSpeed(false)
    end
end

function DailybonusLayer:hideBtnSpeed()
    local btnSpeed = self:findChild("btnSpeed")
    if btnSpeed then
        btnSpeed:stopAllActions()
        btnSpeed:setVisible(false)
    end
end

function DailybonusLayer:setTouchBtnSpeed(_bTouch)
    self.m_bTouchSpeedBtn = _bTouch
end

function DailybonusLayer:getTouchBtnSpeed()
    return self.m_bTouchSpeedBtn
end

function DailybonusLayer:resetCsbAction(_view)
    if _view and not tolua.isnull(_view) and _view.m_csbAct then
        util_resetCsbAction(_view.m_csbAct)
    end
end

function DailybonusLayer:stopViewAciton(_view)
    if _view and not tolua.isnull(_view) then
        _view:stopAllActions()
        _view:pauseForIndex()
        _view:setVisible(false)
        util_resetCsbAction(_view.m_csbAct)
    end
end

function DailybonusLayer:showWheelNode(bHide)
    self:findChild("NodeBg1"):setVisible(bHide)
    self:findChild("NodeBg2"):setVisible(bHide)
    self:findChild("root"):setVisible(bHide)
end

--jppot信息--------------------------
function DailybonusLayer:updateJackpot(jackpotType)
    self.m_JackpotLabel:stopAllActions()

    local wheelData = nil
    if jackpotType == WHEELTYPE.WHEELTYPE_NORMAL then
        wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
        printInfo("----- > normal")
    elseif jackpotType == WHEELTYPE.WHEELTYPE_PAY then
        wheelData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
        printInfo("----- > pay")
    end
    local baseCoin = wheelData.p_coinsShowBase
    local maxCoin = wheelData.p_coinsShowMax
    local perAdd = wheelData.p_coinsShowPerSecond
    self.m_jackpotCurCoin = wheelData.p_coinsShowBase + util_random(1, (maxCoin - baseCoin) * 0.5)
    self.m_JackpotLabel:setString(util_formatCoins(tonumber(self.m_jackpotCurCoin), 12))
    if self.m_wheelJackpotTimer then
        self.m_JackpotLabel:stopAction(self.m_wheelJackpotTimer)
        self.m_wheelJackpotTimer = nil
    end
    self.m_wheelJackpotTimer =
        schedule(
        self.m_JackpotLabel,
        function()
            local isStop = false
            if jackpotType == WHEELTYPE.WHEELTYPE_NORMAL then
                if self.m_stopFreeWheelJackpotTimer == true then
                    isStop = true
                end
            elseif jackpotType == WHEELTYPE.WHEELTYPE_PAY then
                if self.m_stopPayWheelJackpotTimer == true then
                    isStop = true
                end
            end
            if isStop == true or self.m_isClose == true then
                self.m_JackpotLabel:stopAction(self.m_wheelJackpotTimer)
                self.m_wheelJackpotTimer = nil
                return
            end
            local addCoin = self:randomPreAddVale(perAdd)
            self.m_jackpotCurCoin = addCoin + self.m_jackpotCurCoin

            if self.m_jackpotCurCoin >= (maxCoin * self.m_mulitipJp) then
                self.m_jackpotCurCoin = baseCoin
            end
            self.m_JackpotLabel:setString(util_formatCoins(tonumber(math.ceil(self.m_jackpotCurCoin)), 12))
        end,
        0.1
    )
end

--重新随机 防止出现 100000 1000等情况
function DailybonusLayer:randomPreAddVale(perAdd)
    local strAdd = tostring(math.floor(perAdd * 0.1))
    local newStrAdd = ""
    for i = 1, string.len(strAdd) do
        local char = string.sub(strAdd, i, i)
        if i ~= 1 then
            char = tostring(math.random(0, 9))
        end
        newStrAdd = newStrAdd .. char
    end
    return tonumber(newStrAdd)
end

function DailybonusLayer:getJackpotAddValue()
    local addV = self.m_jackpotCurCoin - G_GetMgr(G_REF.CashBonus):getPayWheelData().p_coinsShowBase
    return addV
end

function DailybonusLayer:stopFreeWheelJackpot()
    self.m_stopFreeWheelJackpotTimer = true
end

function DailybonusLayer:stopPayWheelJackpot()
    self.m_stopPayWheelJackpotTimer = true
end

function DailybonusLayer:getRunWheelState()
    return self.m_wheelState
end

--jppot信息-----------------------end

--广告视频
function DailybonusLayer:judgeAdsVideo()
    if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.DialyBonus) then
        return true
    end
    return false
end

--视频弹窗
function DailybonusLayer:showAdsRewardView()
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.DialyBonus)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    local view =
        util_createView(
        "views.dialogs.AdsRewardLayer",
        AdsRewardDialogType.DailyBonus,
        PushViewPosType.DialyBonus,
        function()
            gLobalViewManager:addLoadingAnimaDelay()
            gLobalAdsControl:playRewardVideo(PushViewPosType.DialyBonus)
            --添加一个一分钟计时器 防止没播广告 没回调的情况
            self.m_adsPlayHandler =
                performWithDelay(
                self,
                function()
                    self.m_adsPlayHandler = nil
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CASHBONUS_VIDEO_REWARD, {"failed"})
                end,
                60
            )
        end,
        function()
            --付费轮盘
            self:changePayWheel()
            gLobalViewManager:removeLoadingAnima()
        end,
        "Hourbonus_new3/DailyBonusVideoLayer.csb"
    )
    -- view:setPosition(cc.p(display.width / 2, display.height / 2))
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.DialyBonus)
    gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.DialyBonus})
end

function DailybonusLayer:onEnter()
    DailybonusLayer.super.onEnter(self)
    self:runCsbAction("idle")

    --打点免费轮盘
    gLobalSendDataManager:getLogFeature():sendCashBonusWheelLog("Free")

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            release_print("Mopub    " .. params[1])
            gLobalViewManager:removeLoadingAnima()
            if self.m_adsPlayHandler then
                self:stopAction(self.m_adsPlayHandler)
                self.m_adsPlayHandler = nil
            end

            if params[1] == "success" then
                --普通轮盘再转一次
                self.m_bonusWheel:initAdsWheel()
                self.m_bonusWheel:rotateWheel()
                self:setTouchBtnSpeed(true)

                self:setTouchBtnSpeed(true)
                self.m_isWatchAds = true

                local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
                local totalCoins = wheelData.p_value * wheelData.p_vipMultiple * self.m_bonusWheel:getRewardMulitip()

                --加成
                if self.m_bHasDeluexe then
                    totalCoins = totalCoins * globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD / 100
                end

                gLobalSendDataManager:getLogAds():setadTaskStatus("Full")
                gLobalSendDataManager:getLogAds():setdialyTimes(totalCoins)
                gLobalSendDataManager:getLogAds():sendAdsLog()

                gLobalSendDataManager:getLogAdvertisement():setadType("Close")
                gLobalSendDataManager:getLogAdvertisement():setadStatus("FullClose")
                gLobalSendDataManager:getLogAdvertisement():setStatus("Success")
                gLobalSendDataManager:getLogAdvertisement():setdialyTimes(totalCoins)
                gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
            else
                gLobalSendDataManager:getLogAds():setadTaskStatus("Return")
                gLobalSendDataManager:getLogAds():sendAdsLog()

                gLobalSendDataManager:getLogAdvertisement():setadType("Close")
                gLobalSendDataManager:getLogAdvertisement():setadStatus("MidwayClose")
                gLobalSendDataManager:getLogAdvertisement():setStatus("Fail")
                gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
                --付费轮盘
                self:changePayWheel()
            end
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CASHBONUS_VIDEO_REWARD)
        end,
        ViewEventType.NOTIFY_CASHBONUS_VIDEO_REWARD
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local data = params.data
            local success = params.success
            if success then
                gLobalDataManager:setNumberByField("lastRewardWheelTime", os.time())
                self:collectSuccessCallFun()
            else
                gLobalViewManager:removeLoadingAnima()
                gLobalViewManager:showReConnect()
            end
        end,
        ViewEventType.CASHBONUS_COLLECT_ACTION_CALLBACK
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateJackpot(WHEELTYPE.WHEELTYPE_PAY)
            if self.m_bonusWheel then
                self.m_bonusWheel:setValues(true)
                if params.bl_showAnim then
                    self:resetMultiple()
                    local wheel_data = G_GetMgr(G_REF.CashBonus):getPayWheelData()
                    if wheel_data and wheel_data.p_values then
                        self.m_bonusWheel:changeBuyWheelCoinLabel(wheel_data.p_values)
                    end
                    self:runCsbAction(
                        "chengbei2",
                        false,
                        function()
                            self:runCsbAction("idle3", true, nil, 30)
                            if not tolua.isnull(self.buyView) then
                                self.buyView:setTouchEnabled(true)
                            end
                        end,
                        30
                    )
                    if not tolua.isnull(self.buyView) then
                        self.buyView:setTouchEnabled(false)
                    end

                    local wheelPayData = G_GetMgr(G_REF.CashBonus):getPayWheelData()
                    local goodsInfo = {}
                    goodsInfo.goodsTheme = "CashBonusWheelView"
                    goodsInfo.goodsId = wheelPayData.p_key
                    goodsInfo.goodsPrice = wheelPayData.p_price
                    goodsInfo.discount = wheelPayData.p_multiple * 100
                    goodsInfo.totalCoins = nil
                    local purchaseInfo = {}
                    purchaseInfo.purchaseType = "dayRoulette"
                    purchaseInfo.purchaseName = "dayRoulette" .. wheelPayData:getPayIdx()
                    purchaseInfo.purchaseStatus = "dayRoulette"
                    gLobalSendDataManager:getLogIap():setEntryType("Wheel")
                    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
                end
            end
        end,
        ViewEventType.NOTIFY_CASHBONUS_WHEEL_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:playSpinAction()
        end,
        ViewEventType.NOTIFY_CASHBONUS_WHEEL_PAY
    )

    globalData.adsRunData.p_haveCashBonusWheel = true
end

function DailybonusLayer:onKeyBack()
    --吞噬掉
end

return DailybonusLayer
