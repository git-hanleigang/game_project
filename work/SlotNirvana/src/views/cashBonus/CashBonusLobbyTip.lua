--
-- Cash Bonus 领奖提示， 倒计时提示
-- Author:{author}
-- Date: 2019-04-17 16:24:57
--
local BaseDownLoadNodeUI = util_require("baseActivity.BaseDownLoadNodeUI")
local CashBonusLobbyTip = class("CashBonusLobbyTip", BaseDownLoadNodeUI)

CashBonusLobbyTip.m_leftTimeLB = nil -- 剩余时间

CashBonusLobbyTip.m_currentShowBonusType = nil -- 当前显示的bonus 类型

function CashBonusLobbyTip:initUI()
    BaseDownLoadNodeUI.initUI(self)
    self.m_silverNode = self.m_csbOwner["silverNode"]
    self.m_goldNode = self.m_csbOwner["goldNode"]
    self.m_wheelNode = self.m_csbOwner["wheelNode"]
    self.m_moneyNode = self.m_csbOwner["moneyNode"]
    self.m_noRewardNode = self.m_csbOwner["noRewardNode"]
    self.m_leftTimeLB = self:findChild("leftTime")
    self:addClick(self:findChild("btn_enter"))
    self:updateTipByData()
end

function CashBonusLobbyTip:getCsbName()
    return "Activity_LobbyIconRes/CashBonusLobbyIcon.csb"
end

--[[
    @desc: 更新cash bonus 提示节点信息
    time:2019-04-17 17:03:59
    @return:
]]
function CashBonusLobbyTip:updateTipByData()
    self:hideAllNodes()
    self:runCsbAction("idle", true)
    release_print(" ----- updateTipByData ----- ")
    local bonusType = G_GetMgr(G_REF.CashBonus):getRunningData():getCurCollectBonus()
    release_print(" ----- updateTipByData ----- bonusType = " .. bonusType)
    if bonusType == CASHBONUS_TYPE.BONUS_NONE then
        self:showCollectInfo()
        self.m_noRewardNode:setVisible(true)
        self:findChild("Button_1"):setVisible(false)
    elseif bonusType == CASHBONUS_TYPE.BONUS_SILVER then -- 银库
        self:findChild("Button_1"):setVisible(true)
        self.m_silverNode:setVisible(true)
    elseif bonusType == CASHBONUS_TYPE.BONUS_GOLD then -- 金库
        self:findChild("Button_1"):setVisible(true)
        self.m_goldNode:setVisible(true)
    elseif bonusType == CASHBONUS_TYPE.BONUS_MONEY then -- 钞票游戏
        self:findChild("Button_1"):setVisible(true)
        self.m_moneyNode:setVisible(true)
        self:runCsbAction("idle2", true)
    elseif bonusType == CASHBONUS_TYPE.BONUS_WHEEL then -- 轮盘
        self:findChild("Button_1"):setVisible(true)
        self.m_wheelNode:setVisible(true)
    end

    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        if globalData.userRunData.levelNum < globalData.constantData.NOVICE_CASHBONUS_OPEN_LEVEL then
            if bonusType == CASHBONUS_TYPE.BONUS_GOLD or bonusType == CASHBONUS_TYPE.BONUS_SILVER then
                self:hideAllNodes()
                self:updateWheelCoolDown()
                self.m_noRewardNode:setVisible(true)
                self:findChild("Button_1"):setVisible(false)
            end
        end
    end

    self.m_currentShowBonusType = bonusType
end
--[[
    @desc:
    time:2019-04-20 14:23:04
    @return:
]]
function CashBonusLobbyTip:checkBonusTipStatus()
    local cashBonusData = G_GetMgr(G_REF.CashBonus):getRunningData()
    schedule(
        self,
        function()
            local bonusType = cashBonusData:getCurCollectBonus()
            if bonusType ~= self.m_currentShowBonusType then
                -- 重置当前状态
                self:updateTipByData()
            end
        end,
        0.2
    )
end

--[[
    @desc: 显示待收集信息
    time:2019-04-17 17:36:04
    @return:
]]
function CashBonusLobbyTip:showCollectInfo()
    local miniBonusData = G_GetMgr(G_REF.CashBonus):getRunningData():getCoolDownLateBonus()
    local leftTime1 = miniBonusData.p_coolDown
    local leftTimeStr1 = util_count_down_str(leftTime1)
    self.m_leftTimeLB:setString(leftTimeStr1)
    --113 98
    if globalData.adsRunData:isBronzeVedio() then
        -- self:findChild("sp_clock"):setVisible(false)
        self.m_leftTimeLB:setPositionX(66)
        local sp_vedio = self:findChild("sp_vedio")
        if sp_vedio then
            sp_vedio:setVisible(true)
        end
    else
        -- self:findChild("sp_clock"):setVisible(true)
        self.m_leftTimeLB:setPositionX(48)
        local sp_vedio = self:findChild("sp_vedio")
        if sp_vedio then
            sp_vedio:setVisible(false)
        end
    end
    if self.leftTimeLBAction ~= nil then
        self.m_leftTimeLB:stopAction(self.leftTimeLBAction)
        self.leftTimeLBAction = nil
    end
    self.leftTimeLBAction =
        schedule(
        self.m_leftTimeLB,
        function()
            local miniBonusData1 = G_GetMgr(G_REF.CashBonus):getRunningData():getCoolDownLateBonus()
            local leftTime = miniBonusData1.p_coolDown
            local leftTimeStr = util_count_down_str(leftTime)
            self.m_leftTimeLB:setString(leftTimeStr)
            if globalData.adsRunData:isBronzeVedio() then
                -- self:findChild("sp_clock"):setVisible(false)
                self.m_leftTimeLB:setPositionX(66)
                local sp_vedio = self:findChild("sp_vedio")
                if sp_vedio then
                    sp_vedio:setVisible(true)
                end
            else
                -- self:findChild("sp_clock"):setVisible(true)
                self.m_leftTimeLB:setPositionX(48)
                local sp_vedio = self:findChild("sp_vedio")
                if sp_vedio then
                    sp_vedio:setVisible(false)
                end
            end
        end,
        1
    )
end

function CashBonusLobbyTip:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
end
--[[
    @desc: 隐藏掉所有的节点
    time:2019-04-17 16:52:46
    @return:
]]
function CashBonusLobbyTip:hideAllNodes()
    release_print(" ------------ hideAllNodes ----------- ")
    self.m_silverNode:setVisible(false)
    self.m_goldNode:setVisible(false)
    self.m_wheelNode:setVisible(false)
    self.m_moneyNode:setVisible(false)
    self.m_noRewardNode:setVisible(false)
end

function CashBonusLobbyTip:onEnter()
    BaseDownLoadNodeUI.onEnter(self)
    self:checkBonusTipStatus()

    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            if param.removeGuide then
                self:resetWheelLocalZorder()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            --弹窗逻辑执行下一个事件
            end
        end,
        ViewEventType.NOTIFY_CHANGE_CASHWHEEL_GUIDE_ZORDER
    )

    -- cxc 2021年06月23日16:06:10 轮盘变为非强制引导，点击蒙版去除箭头
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not params then
                self:resetWheelLocalZorder()
            end
        end,
        ViewEventType.NOTIFY_CHANGE_CASHWHEEL_ZORDER
    )
end

function CashBonusLobbyTip:getDownLoadKey()
    return "cashBonusDy"
end

function CashBonusLobbyTip:getProgressPath()
    return "Activity_LobbyIconRes/ui/simpleCashBonusIcon.png"
end

function CashBonusLobbyTip:initProcessFunc()
    self:findChild("Panel_1"):setVisible(false)
    self._dlBlackBg = util_createSprite(self:getProgressPath())
    if self._dlBlackBg then
        self._dlBlackBg:addTo(self:getDownLoadingNode() or self)
        self._dlBlackBg:move(self:getProcessBgOffset())
        self._dlBlackBg:setVisible(true)
        self._dlBlackBg:setLocalZOrder(-1)
    end

    self.m_isDownloading = true
end

function CashBonusLobbyTip:endProcessFunc()
    self:findChild("Panel_1"):setVisible(true)
    if self._dlBlackBg then
        self._dlBlackBg:removeSelf()
        self._dlBlackBg = nil
    end

    util_nextFrameFunc(
        function()
            self.m_isDownloading = nil
        end
    )
end

function CashBonusLobbyTip:getProcessBgOffset()
    return -5, -50
end

function CashBonusLobbyTip:onExit()
    BaseDownLoadNodeUI.onExit(self)
    self:closeUI()
    gLobalNoticManager:removeAllObservers(self)
end
function CashBonusLobbyTip:clickFunc(event)
    print("show view")
    if self.m_isDownloading then
        return
    end

    if self.m_requestWheel then
        return
    end

    local name = event:getName()

    if event then
        --TODO-NEWGUIDE
        self:resetWheelLocalZorder()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_CASHWHEEL_ZORDER, false)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_CashBonus)
        end
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "downCollect")
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        local vaultData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
        if vaultData and vaultData.p_processCurrent >= vaultData.p_processAll then
            if globalDynamicDLControl:checkDownloaded("cashBonusDy")  then
                local cashBonusView = util_createView("views.cashBonus.cashBonusMain.CashBonusMainView")
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(cashBonusView, name, DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
                end
                cashBonusView:setCloseFunc(
                    function()
                        if gLobalDataManager:getBoolByField("newGuideShowCashMoney", false) and gLobalDataManager:getBoolByField("newGuideShowNextCashMoney", true) == false then
                            gLobalPopViewManager:showPopView(POP_VC_TYPE.CLICK_DAILYWHEEL)
                        end
                    end
                )
                cashBonusView:setActionType("Curve", event:getTouchEndPosition())
                gLobalViewManager:showUI(cashBonusView, ViewZorder.ZORDER_UI)
            end
        else
            local isGuide = globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.silverEntrepot)
            local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
            if not isGuide and wheelData.p_coolDown == 0 then
                local successCallbackFunc = function()
                    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
                    -- 显示轮盘界面
                    -- local bonusWheelView = util_createView("views.cashBonus.CashBonusWheelView")
                    local dailyBonusLayerUI = gLobalViewManager:getViewByExtendData("DailyBonusLayer")
                    if dailyBonusLayerUI then
                        return
                    end
                    local bonusWheelView = util_createView("views.cashBonus.DailyBonus.DailybonusLayer")
                    if gLobalSendDataManager.getLogPopub then
                        gLobalSendDataManager:getLogPopub():addNodeDot(bonusWheelView, name, DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
                    end
                    gLobalViewManager:showUI(bonusWheelView, ViewZorder.ZORDER_UI)
                    bonusWheelView:setOverFunc(
                        function()
                            self.m_requestWheel = nil
                            --这里应该写一个大厅轮盘的回调先这么写
                            G_GetMgr(G_REF.Inbox):getDataMessage()
                            if globalData.sendCouponFlag == true then
                                globalData.sendCouponFlag = false
                            end
                            local fl_data = G_GetMgr(G_REF.Flower):getData()
                            if fl_data and fl_data:getSilCkm() ~= 0 then
                                local param = {}
                                param.type = 1
                                param.num = fl_data:getSilCkm()
                                local callback_cb = function()
                                    fl_data:setSilCkm()
                                    if self.showGuideFirstBuy then
                                        self:showGuideFirstBuy()
                                    end
                                end
                                param.cb = callback_cb

                                G_GetMgr(G_REF.Flower):showRewardLayer(param)
                                gLobalSoundManager:playSound(G_GetMgr(G_REF.Flower):getConfig().SOUND.PAY1)
                            elseif G_GetMgr(G_REF.Flower) and G_GetMgr(G_REF.Flower):getFlowerCoins() ~= 0 then
                                local cb = function()
                                    G_GetMgr(G_REF.Flower):setFlowerCoins(0)
                                    if self.showGuideFirstBuy then
                                        self:showGuideFirstBuy()
                                    end
                                end
                                G_GetMgr(G_REF.Flower):showResultLayer(cb, G_GetMgr(G_REF.Flower):getFlowerCoins())
                            else
                                if self.showGuideFirstBuy then
                                    self:showGuideFirstBuy()
                                end
                            end
                            -- globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.silverEntrepot)
                            -- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)--弹窗逻辑执行下一个事件
                        end
                    )
                end
                self.m_requestWheel = true
                gLobalSendDataManager:getNetWorkSlots():sendRequestShopInfo({"CashBonus"}, successCallbackFunc, successCallbackFunc)
            else
                if globalDynamicDLControl:checkDownloaded("cashBonusDy") then
                    local cashBonusView = util_createView("views.cashBonus.cashBonusMain.CashBonusMainView")
                    if gLobalSendDataManager.getLogPopub then
                        gLobalSendDataManager:getLogPopub():addNodeDot(cashBonusView, name, DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
                    end
                    cashBonusView:setCloseFunc(
                        function()
                            if gLobalDataManager:getBoolByField("newGuideShowCashMoney", false) and gLobalDataManager:getBoolByField("newGuideShowNextCashMoney", true) == false then
                                gLobalPopViewManager:showPopView(POP_VC_TYPE.CLICK_DAILYWHEEL)
                            else
                                if gLobalAdChallengeManager:isShowMainLayer() then
                                    gLobalAdChallengeManager:showMainLayer()
                                end
                            end
                        end
                    )
                    cashBonusView:setActionType("Curve", event:getTouchEndPosition())
                    gLobalViewManager:showUI(cashBonusView, ViewZorder.ZORDER_UI)
                end
            end
        end
    end
end

--TODO-NEWGUIDE  第一次购买
function CashBonusLobbyTip:showGuideFirstBuy()
    local checkOpenView = function(_callback)
        if G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasTaskCompleted() then
            local taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.WHEELDAILY
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):chooseCreatePopLayer(taskType, _callback)
        else
            if _callback then
                _callback()
            end
        end
    end
    -- 有付费需要弹邮戳
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        --掉卡之前的提示
        gLobalViewManager:checkAfterBuyTipList(
            function()
                gLobalViewManager:checkBuyTipList(function()
                    checkOpenView(
                        function()
                            globalData.saleRunData:getCouponGift()
                        end
                    )
                end)
            end,
            "CashBonus"
        )
    end
end
--TODO-NEWGUIDE
function CashBonusLobbyTip:setGuide(lastNode, lastPos)
    self.m_lastNode = lastNode
    self.m_lastPos = lastPos
    local arrow = util_createView("views.newbieTask.GuideArrowNode")
    self:addChild(arrow, ViewZorder.ZORDER_GUIDE + 1)
    arrow:showIdle(3)
    arrow:setPosition(10, 50)
    self.m_guideArrow = arrow
end
--TODO-NEWGUIDE 隐藏轮盘引导
function CashBonusLobbyTip:resetWheelLocalZorder()
    if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.dallyWhell.id) then
        globalNoviceGuideManager:checkFinishGuide(NOVICEGUIDE_ORDER.dallyWhell)
    end
    if self.m_guideArrow then
        self.m_guideArrow:removeFromParent()
        self.m_guideArrow = nil
    end

    if self.m_guideCashMoney then
        self.m_guideCashMoney:removeFromParent()
        self.m_guideCashMoney = nil
    end

    if self.m_lastPos then
        util_changeNodeParent(self.m_lastNode, self)
        self:setPosition(self.m_lastPos)
        self:setScale(1)
        self.m_lastPos = nil
    end
end
-- 轮盘引导tips
function CashBonusLobbyTip:setCashMoneyTips(lastNode, lastPos, id)
    self.m_lastNode = lastNode
    self.m_lastPos = lastPos

    local cashBonus_tishi = util_createView("views.cashBonus.CashBonus_tishi", id)
    self:addChild(cashBonus_tishi, ViewZorder.ZORDER_GUIDE + 1)
    -- cashBonus_tishi:setPosition(0,140)
    self.m_guideCashMoney = cashBonus_tishi
end

-- 新手期abtest 专用状态切换
function CashBonusLobbyTip:updateWheelCoolDown()
    -- 隐藏 video 点s
    self.m_leftTimeLB:setPositionX(48)
    local sp_vedio = self:findChild("sp_vedio")
    if sp_vedio then
        sp_vedio:setVisible(false)
    end

    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
    self.activityAction =
        util_schedule(
        self,
        function()
            self:updateLeftTime()
        end,
        1
    )
    self:updateLeftTime()
end
-- 更新剩余时间
function CashBonusLobbyTip:updateLeftTime()
    --刷新轮盘的倒计时
    local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
    local left_time = wheelData:getLeftTime()
    if left_time <= 0 then
        if self.activityAction ~= nil then
            self:stopAction(self.activityAction)
            self.activityAction = nil
        end
    else
        self.m_leftTimeLB:setString(util_count_down_str(left_time))
    end
end

return CashBonusLobbyTip
