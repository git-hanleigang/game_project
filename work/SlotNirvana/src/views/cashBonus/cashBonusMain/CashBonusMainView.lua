--ios fix
local CashBonusMainView = class("CashBonusMainView", BaseLayer)

function CashBonusMainView:initDatas()
    self:setLandscapeCsbName("NewCashBonus/CashBonusNew/CashBonus_MainUi.csb")
    self.m_lastCDT = {}
    self:addClickSound("Button_close", SOUND_ENUM.SOUND_HIDE_VIEW)
end

function CashBonusMainView:initCsbNodes()
    CashBonusMainView.super.initCsbNodes(self)
    self.m_sprUnlockGold = self:findChild("sp_unlock_gold")
    self.m_labUnlockGold = self:findChild("lb_unlock_gold")
    self.m_sprUnlockSilver = self:findChild("sp_unlock_silver")
    self.m_labUnlockSilver = self:findChild("lb_unlock_silver")

    self.m_nodeGoldBtn = self:findChild("node_goldBtn")
    self.m_nodeSilverBtn = self:findChild("node_silverBtn")

    -- 新增节点
    self.m_nodeText1 = self:findChild("node_cashmoneytext1")
    self.m_nodeText2 = self:findChild("node_cashmoneytext2")
end

function CashBonusMainView:initUI()
    -- setDefaultTextureType("RGBA8888", nil)
    CashBonusMainView.super.initUI(self)

    --标题
    self:initTitle()
    --倍增器
    self:initMultBar()
    -- 钞票游戏
    self:initMoneyModular()
    --银库
    self:initSilverModular()
    --金库
    self:initGoldModular()
    --大轮盘
    self:initWheelModular()
    --计时器
    self:initCashTimer()
    --csc 2021-08-26 18:00:43 新手期ABTEST 第三版 A组用户 金库银库等级限制
    self:initButtonStatus()
    -- NPC 啤酒女郎
    self:initNPC()

    -- 检测当前Cashmoney 资源有没有下载好
    self:checkCashMoneyRes()

    gLobalSendDataManager:getLogFeature():sendCashBonusLog(LOG_ENUM_TYPE.CashBonus_OpenView)

    -- setDefaultTextureType("RGBA4444", nil)
end

function CashBonusMainView:onShowedCallFunc()
    CashBonusMainView.super.onShowedCallFunc(self)
    -- ADChallenge
    self:initADChallenge()
    self:runCsbAction("waiting", true)
end

function CashBonusMainView:initTitle()
    local title = util_createView("views.cashBonus.cashBonusMain.CashBonusTitleView")
    self:findChild("nodeTitle"):addChild(title)
end

function CashBonusMainView:initCashTimer()
    local updateFun = function(isInit)
        G_GetMgr(G_REF.CashBonus):getRunningData():updateCashBonusIncrease(isInit)
        self.m_cashBonusShowList = G_GetMgr(G_REF.CashBonus):getRunningData():getCashBonusShowList()
        self:updateSilverInfo()
        self:updateGoldInfo()
        self:updateWheelInfo()
        self:updateMoneyInfo()
    end
    updateFun(true)
    schedule(
        self,
        function()
            updateFun()
        end,
        0.1
    )
end

function CashBonusMainView:initButtonStatus()
    -- csc 2021-08-26 18:00:43 新手期ABTEST 第三版 A组用户 金库银库等级限制
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        if self.m_sprUnlockGold and self.m_sprUnlockSilver then
            if globalData.userRunData.levelNum < globalData.constantData.NOVICE_CASHBONUS_OPEN_LEVEL then
                self.m_nodeGoldBtn:setVisible(false)
                self.m_nodeSilverBtn:setVisible(false)
                self.m_sprUnlockGold:setVisible(true)
                self.m_sprUnlockSilver:setVisible(true)
                self.m_labUnlockGold:setString(globalData.constantData.NOVICE_CASHBONUS_OPEN_LEVEL)
                self.m_labUnlockSilver:setString(globalData.constantData.NOVICE_CASHBONUS_OPEN_LEVEL)
            else
                self.m_nodeGoldBtn:setVisible(true)
                self.m_nodeSilverBtn:setVisible(true)
                self.m_sprUnlockGold:setVisible(false)
                self.m_sprUnlockSilver:setVisible(false)
            end
        end
    end
end

-- 初始化ADChallenge
function CashBonusMainView:initADChallenge()
    local adNode = self:findChild("node_adChallenge")
    if adNode then
        if globalData.AdChallengeData:isHasAdChallengeActivity() and gLobalAdChallengeManager:checkOpenLevel() then
            local adsChallengeIconNode = util_createView("views.cashBonus.cashBonusMain.CashBonusADView")
            adNode:addChild(adsChallengeIconNode)
            adsChallengeIconNode:playADAction()
            self.m_adChallengeNode = adsChallengeIconNode
        end
    end
end

-- 初始化NPC
function CashBonusMainView:initNPC()
    local npcSpine = util_spineCreate("NewCashBonus/CashBonusNew/spine/cashbouns_npc", true, true, 1)
    if npcSpine then
        util_spinePlay(npcSpine, "idle", true)
        self:findChild("node_npc"):addChild(npcSpine)
    end
end

function CashBonusMainView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- if self.m_click then
    --     return
    -- end
    -- self.m_click = true
    if name ~= "Button_close" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end

    if name == "btn_playMoneyGame" then
        self:openMoneyGame()
    elseif name == "silverBtn" then
        local coins = self:getCashBonusTypeValue(CASHBONUS_TYPE.BONUS_SILVER)
        self:requestPickGame(CASHBONUS_TYPE.BONUS_SILVER, coins)
    elseif name == "Button_gold" then
        local coins = self:getCashBonusTypeValue(CASHBONUS_TYPE.BONUS_GOLD)
        self:requestPickGame(CASHBONUS_TYPE.BONUS_GOLD, coins)
    elseif name == "wheelBtn" then
        self:openWheelGame()
    elseif name == "Button_close" then
        --self:closeUI()
        self:closeAdChallenge()
    elseif name == "btn_vedio" then
        if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.VaultSpeedup) then
            gLobalViewManager:addLoadingAnima()
            self.m_click = nil
            gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.VaultSpeedup)
            gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
            gLobalAdsControl:playRewardVideo(PushViewPosType.VaultSpeedup)
            gLobalSendDataManager:getLogAds():createPaySessionId()
            gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.VaultSpeedup)
            gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
            globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.VaultSpeedup}, nil, "click")
            gLobalDataManager:setNumberByField("isPlayBronzeVedio", 2)
            self.m_waitingADBack = true
        else
            self:updateSilverInfo()
        end
    end
end

--打开大轮盘
function CashBonusMainView:openWheelGame()
    -- self.m_click = false --test
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

    local bonusWheelView = util_createView("views.cashBonus.DailyBonus.DailybonusLayer")
    gLobalViewManager:showUI(bonusWheelView, ViewZorder.ZORDER_UI)
    local overFunc = function()
        -- 有付费需要弹邮戳
        local data = G_GetMgr(G_REF.LuckyStamp):getData()
        if not self.m_reconnect and data then
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

    local cb = function()
        local fl_data = G_GetMgr(G_REF.Flower):getData()
        if fl_data and fl_data:getSilCkm() ~= 0 then
            local param = {}
            param.type = 1
            param.num = fl_data:getSilCkm()
            local callback_cb = function()
                fl_data:setSilCkm()
                overFunc()
            end
            param.cb = callback_cb
            G_GetMgr(G_REF.Flower):showRewardLayer(param)
            gLobalSoundManager:playSound(G_GetMgr(G_REF.Flower):getConfig().SOUND.PAY1)
        elseif G_GetMgr(G_REF.Flower) and G_GetMgr(G_REF.Flower):getFlowerCoins() ~= 0 then
            local cb = function()
                G_GetMgr(G_REF.Flower):setFlowerCoins(0)
                overFunc()
            end
            G_GetMgr(G_REF.Flower):showResultLayer(cb,G_GetMgr(G_REF.Flower):getFlowerCoins())
        else
            overFunc()
        end
    end

    bonusWheelView:setOverFunc(cb)
    self.m_click = false
end

--打开钞票游戏
function CashBonusMainView:openMoneyGame()
    self.m_click = false
    --这里需要兼容老版CashMoney游戏
    local tryData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    -- 拿到当前的自定义数据 tryData:getMegaCashTakeData()
    if not tryData then
        -- 此时玩家没有老的CashMoney数据,需要打开小游戏版的CashMoney
        self:openCashMoneyMiniGame()
        release_print("此时没有老版CashMoney数据，开始玩道具版小游戏 ********** 1")
    else
        if tryData and tryData:getMegaCashTakeData() then
            if tryData and tryData.p_leftPlayTimes == globalData.constantData.MEGACASH_PLAY_TIMES then
                self.m_bFirstOpenMoneyGame = true
                G_GetMgr(G_REF.CashBonus):sendActionCashMoneyRequest(ActionType.MegaCashPlay)
                release_print("此时存在有老版CashMoney数据 ********** 2")
            else
                -- 此时玩家已经玩过了
                local view = util_createView("views.cashBonus.cashBonusMoneyGame.CashMoneyMainUI", true)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                release_print("此时存在有老版CashMoney数据并且已经记录过玩家的Take状态 ********** 3")
            end
        else
            -- 玩家虽然有数据但是没有玩过这个老版的CashMoney，需要走道具通用化CashMoney小游戏
            self:openCashMoneyMiniGame()
            release_print("此时有老版CashMoney数据但是自定义数据为FALSE ********** 4")
        end
    end
end

function CashBonusMainView:openCashMoneyMiniGame()
    local dataType = G_GetMgr(G_REF.CashMoney):getDataType()
    local gameType = G_GetMgr(G_REF.CashMoney):getGameType()
    --当前来源为CashBonus的小游戏数据（正在玩）
    local gameData = G_GetMgr(G_REF.CashMoney):getPlayStatusGameData(dataType.CASHBONUS)

    if gameData then
        local isReward = gameData:getRewardStatus() -- 是否完成普通版
        local isMark = gameData:getMarkStatus() -- 是否带付费项
        local isPay = gameData:getPayStatus() -- 是否购买过付费版次数
        local type = gameType.NORMAL
        if isMark then
            if isReward or isPay then
                type = gameType.PAID
            end
        end
        local viewData = {
            gameData = gameData,
            isReconnc = true
        }

        G_GetMgr(G_REF.CashMoney):showCashMoneyGameView(viewData, type)
    else
        local data = G_GetMgr(G_REF.CashMoney):getData()
        if data then
            -- 获取来源为CashBonus的游戏数据
            local gameList = data:getGameListByType(dataType.CASHBONUS)
            if table.nums(gameList) > 0 then
                for i, v in pairs(gameList) do
                    self.m_gameId = v.gameData:getGameId()
                    G_GetMgr(G_REF.CashMoney):sendPlay(self.m_gameId)
                    break
                end
            end

            if not tolua.isnull(self) then
                gLobalNoticManager:addObserver(
                    self,
                    function(self, params)
                        gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CASH_MONEY_PLAY)
                        local success = params.success
                        if success then
                            local data = G_GetMgr(G_REF.CashMoney):getDataByGameId(self.m_gameId)
                            local gameType = G_GetMgr(G_REF.CashMoney):getGameType()
                            local viewData = {
                                gameData = data,
                                isReconnc = false
                            }

                            G_GetMgr(G_REF.CashMoney):showCashMoneyGameView(viewData, gameType.NORMAL)
                        end
                    end,
                    ViewEventType.NOTIFY_CASH_MONEY_PLAY
                )
            end
        else
            -- 此时拿不到小游戏数据，需要让玩家玩老数据
            local tryData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
            if not tryData or (tryData and tryData.p_leftPlayTimes == globalData.constantData.MEGACASH_PLAY_TIMES) then
                self.m_bFirstOpenMoneyGame = true
                G_GetMgr(G_REF.CashBonus):sendActionCashMoneyRequest(ActionType.MegaCashPlay)
            else
                local view = util_createView("views.cashBonus.cashBonusMoneyGame.CashMoneyMainUI", true)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            end
        end
    end
end

function CashBonusMainView:sendCashMoneyPlayCallBack(_success, _type)
    if not self.m_bFirstOpenMoneyGame then
        return
    end

    if _type == ActionType.MegaCashPlay then
        if _success then
            local view = util_createView("views.cashBonus.cashBonusMoneyGame.CashMoneyMainUI")
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            self.m_bFirstOpenMoneyGame = false
        end
    end
end

function CashBonusMainView:requestPickGame(type, coinsNum)
    local bl_open = globalData.deluexeClubData:getDeluexeClubStatus()
    G_GetMgr(G_REF.CashBonus):setOpenDeluex(bl_open)
    G_GetMgr(G_REF.CashBonus):sendActionCashVaultCollect(type, coinsNum)
end

function CashBonusMainView:requestPickGameCallBack(_isSucc,_type)
    if _isSucc then
        local view = util_createView("views.cashBonus.cashBonusPickGame.CashBonusPickGameView",_type)
        self._colType = _type
        view:setOverFunc(util_node_handler(self, self.checkOperateGuidePopup))
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    self.m_click = false
end

-- cxc 2023-12-04 14:17:21 CashBonus领奖后 检测运营弹板(1:银箱子， 2：金箱子， 3：轮盘， 4：cashMoney)
function CashBonusMainView:checkOperateGuidePopup(_cb)
    if tolua.isnull(self) then
        return
    end

    local checkType = 0
    if self._colType == CASHBONUS_TYPE.BONUS_SILVER then
        checkType = 1
    elseif self._colType == CASHBONUS_TYPE.BONUS_GOLD then
        checkType = 2
    end
    if checkType == 0 then
        return
    end 

    local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Cashbonus", "Cashbonus_" .. checkType)
    if view then
        view:setOverFunc(_cb)
    elseif _cb then
        _cb()
    end
end

--倍增器
function CashBonusMainView:initMultBar()
    local bar = util_createView("views.cashBonus.cashBonusMain.CashBonusMutiBar")
    self:findChild("multiplier"):addChild(bar)
end

--钞票游戏
function CashBonusMainView:initMoneyModular()
    --icon
    self.m_moneyIcon = util_createView("views.cashBonus.cashBonusMain.CashBonusIcon", "CashBonus_enterMoney")
    self:findChild("icon_money"):addChild(self.m_moneyIcon)

    -- x4000
    local node400 = util_createAnimation("NewCashBonus/CashBonusNew/CashBonus_x4000.csb")
    self:findChild("node_x400"):addChild(node400)
    node400:playAction("idle", true)

    -- x4000
    local node400_2 = util_createAnimation("NewCashBonus/CashBonusNew/CashBonus_x4000.csb")
    self:findChild("node_x400_2"):addChild(node400_2)
    node400_2:playAction("idle", true)

    self:updateMoneyInfo()
end

--银库
function CashBonusMainView:initSilverModular()
    --icon
    self.m_silverIcon = util_createView("views.cashBonus.cashBonusMain.CashBonusIcon", "CashBonus_enterSilver")
    self:findChild("icon_yin"):addChild(self.m_silverIcon)
end

--金库
function CashBonusMainView:initGoldModular()
    --icon
    self.m_goldIcon = util_createView("views.cashBonus.cashBonusMain.CashBonusIcon", "CashBonus_enterGold")
    self:findChild("icon_gold"):addChild(self.m_goldIcon)
end

--金库
function CashBonusMainView:initWheelModular()
    --icon
    self.m_wheelIcon = util_createView("views.cashBonus.cashBonusMain.CashBonusIcon", "CashBonus_enterWheel")
    self:findChild("icon_wheel"):addChild(self.m_wheelIcon)
end

function CashBonusMainView:updateGoldInfo()
    local lbs = self:findChild("Button_gold")
    local cashData = G_GetMgr(G_REF.CashBonus):getGoldData()
    local coolDownTime = cashData:getLeftTime()
    local lastCDT = self.m_lastCDT[CASHBONUS_TYPE.BONUS_GOLD] or 0
    self.m_lastCDT[CASHBONUS_TYPE.BONUS_GOLD] = coolDownTime
    if coolDownTime <= 0 then
        if lastCDT >= 0 then
            self.m_goldIcon:playAnim(true)
            if not self.m_updateGoldBen then
                self:setButtonLabelDisEnabled("Button_gold", true)
                self.m_updateGoldBen = true
            end

            -- self:findChild("gold_collect"):setVisible(true)
            -- lbs:setVisible(false)
            local _strGold = gLobalLanguageChangeManager:getStringByKey("CashBonusMainView:Button_gold")
            self:setButtonLabelContent("Button_gold", _strGold)
        end
    else
        -- self:findChild("gold_collect"):setVisible(false)
        self.m_goldIcon:playAnim(false)
        self:setButtonLabelDisEnabled("Button_gold", false)
        self.m_updateGoldBen = false
        -- lbs:setVisible(true)
        -- lbs:setString(util_count_down_str(coolDownTime))
        self:setButtonLabelContent("Button_gold", util_count_down_str(coolDownTime))
    end
    self:updateLbShow("goldLb", CASHBONUS_TYPE.BONUS_GOLD)
end

function CashBonusMainView:setBtnEnable(btnName, enable)
    if not self.m_btnState then
        self.m_btnState = {}
    end
    local btn = self:findChild(btnName)
    if self.m_btnState[btnName] and self.m_btnState[btnName] == enable then
        return
    end
    self.m_btnState[btnName] = enable
    btn:setEnabled(enable)
end

function CashBonusMainView:updateSilverInfo()
    local btn_vedio = self:findChild("btn_vedio")
    if btn_vedio then
        btn_vedio:setVisible(false)
    end

    local btnSilver = self:findChild("silverBtn")
    local cashData = G_GetMgr(G_REF.CashBonus):getSilverData()
    local coolDownTime = cashData:getLeftTime()
    local lastCDT = self.m_lastCDT[CASHBONUS_TYPE.BONUS_SILVER] or 0
    self.m_lastCDT[CASHBONUS_TYPE.BONUS_SILVER] = coolDownTime
    if coolDownTime <= 0 then
        if lastCDT >= 0 then
            self.m_silverIcon:playAnim(true)
            btnSilver:setVisible(true)
            if not self.m_updateSilverBtn then
                self:setButtonLabelDisEnabled("silverBtn", true)
                self.m_updateSilverBtn = true
            end

            -- lbs:setVisible(false)
            local _strSilver = gLobalLanguageChangeManager:getStringByKey("CashBonusMainView:silverBtn")
            self:setButtonLabelContent("silverBtn", _strSilver)
            -- self:findChild("silver_collect"):setVisible(true)
            btn_vedio:setVisible(false)
            self.m_adsTriggerLog = nil
        end
    else
        if not self.m_waitingADBack then
            local lastADTime = gLobalDataManager:getNumberByField("isPlayBronzeVedio_collectSilverTime", 0)
            local disTime = util_getCurrnetTime() - lastADTime
            if lastADTime ~= 0 and disTime > (15*60) then
                if gLobalDataManager:getNumberByField("isPlayBronzeVedio", 0) ~= 1 then
                    gLobalDataManager:setNumberByField("isPlayBronzeVedio", 1)
                end
            end
        end
        
        if globalData.adsRunData:isBronzeVedio() and btn_vedio then
            if not self.m_adsTriggerLog then
                self.m_silverIcon:playAnim(true)

                self.m_adsTriggerLog = true
                gLobalSendDataManager:getLogAds():createPaySessionId()
                gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.VaultSpeedup)
                gLobalSendDataManager:getLogAds():setOpenType("TapOpen")
                globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.VaultSpeedup})

                gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.VaultSpeedup)
                gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
                gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
                gLobalSendDataManager:getLogAdvertisement():setadType("Push")
                gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
            end
            btn_vedio:setVisible(true)
            btnSilver:setVisible(false)
        else
            self.m_silverIcon:playAnim(false)
            -- self:findChild("silver_collect"):setVisible(false)
            self.m_updateSilverBtn = false
            btnSilver:setVisible(true)
            self:setButtonLabelDisEnabled("silverBtn", false)
            btn_vedio:setVisible(false)

            -- lbs:setVisible(true)
            -- lbs:setString(util_count_down_str(coolDownTime))
            local _strCD = util_count_down_str(coolDownTime)
            self:setButtonLabelContent("silverBtn", _strCD)
        end
    end

    self:updateLbShow("silverLb", CASHBONUS_TYPE.BONUS_SILVER)
end

function CashBonusMainView:updateMoneyInfo()
    local vaultData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    if vaultData.p_processCurrent >= vaultData.p_processAll then
        self:findChild("Node_moneyNoReady"):setVisible(false)
        self:findChild("btn_playMoneyGame"):setVisible(true)
        self.m_nodeText1:setVisible(true)
        self.m_nodeText2:setVisible(false)
    else
        for i = 1, vaultData.p_processAll do
            self:findChild("moneyLoadBar" .. i):setVisible(i <= vaultData.p_processCurrent)
        end
        self:findChild("Node_moneyNoReady"):setVisible(true)
        self:findChild("btn_playMoneyGame"):setVisible(false)
        self.m_nodeText1:setVisible(false)
        self.m_nodeText2:setVisible(true)
    end
end

function CashBonusMainView:updateWheelInfo()
    local btnWheel = self:findChild("wheelBtn")
    local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
    local coolDownTime = wheelData:getLeftTime()
    local lastCDT = self.m_lastCDT["WHEEL"] or 0
    self.m_lastCDT["WHEEL"] = coolDownTime
    if coolDownTime <= 0 then
        if lastCDT >= 0 then
            self.m_wheelIcon:playAnim(true)
            local _strWheel = gLobalLanguageChangeManager:getStringByKey("CashBonusMainView:wheelBtn")
            self:setButtonLabelContent("wheelBtn", _strWheel)
            if not self.m_updateWhellBtn then
                self:setButtonLabelDisEnabled("wheelBtn", true)
                self.m_updateWhellBtn = true
            end
        end
    else
        self.m_updateWhellBtn = false
        self.m_wheelIcon:playAnim(false)
        self:setButtonLabelDisEnabled("wheelBtn", false)
        local _strCD = util_count_down_str(coolDownTime)
        self:setButtonLabelContent("wheelBtn", _strCD)
    end

    self:updateLbShow("wheelLb", CASHBONUS_TYPE.BONUS_WHEEL)
end

function CashBonusMainView:updateLbShow(lbName, type)
    local coins = self:getCashBonusTypeValue(type)
    self:findChild(lbName):setString(util_formatCoins(coins, 12))
    -- print("------------"..lbName.."==="..coins)
end

function CashBonusMainView:getCashBonusTypeValue(type)
    for i = 1, #self.m_cashBonusShowList do
        if self.m_cashBonusShowList[i].type == type then
            return self.m_cashBonusShowList[i].curValue
        end
    end
    return 0
end

function CashBonusMainView:setCloseFunc(func)
    self.m_closeFunc = func
end

function CashBonusMainView:onEnter()
    CashBonusMainView.super.onEnter(self)
    self:pauseForIndex(50)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_waitingADBack = false
            if params[1] == "success" then
                local cashData = G_GetMgr(G_REF.CashBonus):getSilverData()
                self.m_updateSilverBtn = false
                self:updateSilverInfo()
            else
                self:updateSilverInfo()
            end
        end,
        ViewEventType.NOTIFY_ADS_VAULTSPEEDUP
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local success = params.success
            -- 策划要区分宝箱背后的光效，因此在获取数据的时候将type传递进来
            local type = params.type
            self:requestPickGameCallBack(success , type)
        end,
        ViewEventType.CASHBONUS_VAULT_COLLECT_CALLBACK
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local success = params.success
            local type = params.type
            self:sendCashMoneyPlayCallBack(success, type)
        end,
        ViewEventType.CASHBONUS_CASHMONEY_CALLBACK
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, percent)
            self:checkCanShowGameLayer()
        end,
        "DL_Complete" .. tostring("CashMoney")
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, percent)
            self:checkCanShowGameLayer()
        end,
        "DL_Complete" .. tostring("CashMoney_Code")
    )
end

function CashBonusMainView:closeUI()
    -- 高倍场开了 弹出开启高倍场界面
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS)

    local callback = function()
        if self.m_closeFunc then
            self.m_closeFunc()
        end
        -- 更新diy任务数据
        self:sendDiyTaskUpdate()
    end
    CashBonusMainView.super.closeUI(self, callback)
end

function CashBonusMainView:sendDiyTaskUpdate()
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

-- FOR TEST
function CashBonusMainView:onKeyboard(code, event)
    if code == cc.KeyCode.KEY_F1 then
        print("你点击了F1键")
        local view = util_createView("views.cashBonus.cashBonusPickGame.CashBonusPickGameView")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function CashBonusMainView:checkCashMoneyRes()
    if not globalDynamicDLControl:checkDownloaded("CashMoney") and not globalDynamicDLControl:checkDownloaded("CashMoney_Code") then
        local nameStr = gLobalLanguageChangeManager:getStringByKey("CashBonusMainView:CashMoneyDown")
        self:setButtonLabelContent("btn_playMoneyGame", nameStr)
        self:setButtonLabelDisEnabled("btn_playMoneyGame", false)
    else
        local nameStr = gLobalLanguageChangeManager:getStringByKey("CashBonusMainView:CashMoneyCollect")
        self:setButtonLabelContent("btn_playMoneyGame", nameStr)
        self:setButtonLabelDisEnabled("btn_playMoneyGame", true)
    end
end

function CashBonusMainView:checkCanShowGameLayer()
    -- 将Cashmoney 的按钮置灰
    local canShowLayer = G_GetMgr(G_REF.CashMoney):checkCanShowLayer()
    if canShowLayer then
        local nameStr = gLobalLanguageChangeManager:getStringByKey("CashBonusMainView:CashMoneyCollect")
        self:setButtonLabelContent("btn_playMoneyGame", nameStr)
        self:setButtonLabelDisEnabled("btn_playMoneyGame", true)
    end
end

-- 关闭界面时需要播放广告挑战动效
function CashBonusMainView:closeAdChallenge()
    if globalData.AdChallengeData:isHasAdChallengeActivity() and gLobalAdChallengeManager:checkOpenLevel() then
        if self.m_adChallengeNode then
            if not tolua.isnull(self) then
                local call = function()
                    self:closeUI()
                end
                self.m_adChallengeNode:playADOverAction(call)
            end
        end
    else
        self:closeUI()
    end
end

return CashBonusMainView
