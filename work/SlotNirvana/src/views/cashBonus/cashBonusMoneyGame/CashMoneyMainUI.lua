--[[--
    cashbonus小游戏：钞票小游戏
]]
local SOUND_RES = {
    curtain = "NewCashBonus/CashBonusMoney/music/cashMoney_curtain.mp3",
    showOver = "NewCashBonus/CashBonusMoney/music/cashMoney_showOver.mp3",
    waitClick = "NewCashBonus/CashBonusMoney/music/cashMoney_waitClick.mp3",
    click = "NewCashBonus/CashBonusMoney/music/cashMoney_click.mp3",
    selectNormal = "NewCashBonus/CashBonusMoney/music/cashMoney_selectNormal.mp3",
    selectDouble = "NewCashBonus/CashBonusMoney/music/cashMoney_selectDouble.mp3",
    roll = "NewCashBonus/CashBonusMoney/music/cashMoney_roll.mp3"
}

-- 5;5;10;10;20;20;50;50;100;1000;x2;x2
local ROLL_NODE_NAME = {
    "node_5_1",
    "node_5_2",
    "node_10_1",
    "node_10_2",
    "node_20_1",
    "node_20_2",
    "node_50_1",
    "node_50_2",
    "node_100",
    "node_1000",
    "node_2_1",
    "node_2_2"
}

local DELAY_AFTER_CURTAIN = 0.8
local DELAY_SELECT_INTERVAL = 1
local DELAY_SHOW_OVERUI = 1
local VIP_SHOW_TIME = 4

local CashMoneyMainUI = class("CashMoneyMainUI", util_require("base.BaseView"))
function CashMoneyMainUI:initUI(isReconn)
    self.m_maskUI = util_newMaskLayer()
    self:addChild(self.m_maskUI, -1)
    self.m_maskUI:setOpacity(192)

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end
    -- setDefaultTextureType("RGBA8888", nil)
    self:createCsbNode("NewCashBonus/CashBonusMoney/CashMoneyMainLayer.csb", isAutoScale)

    self.m_isReconn = isReconn
    self:initData()
    self:initCsbNode()
    self:initView()
    self:initAdapt()
    -- setDefaultTextureType("RGBA4444", nil)
end

--<<< 通用函数------------------------------------------------------------------------
--适配方案
function CashMoneyMainUI:getUIScalePro()
    local ratio = display.width / display.height
    if ratio <= 1.34 then -- 1024x768
        -- self:findChild("m_bg"):setScale(0.85)
        self:findChild("Node_money"):setScale(0.85)
        return 1
    else
        return 1
    end
    -- if ratio <= 1.34 then -- 1024x768
    --     return 0.65
    -- elseif ratio <= 1.5 then -- 960x640
    --     return 0.75
    -- elseif ratio <= 1.8 then -- 1370x768
    --     return 0.9
    -- else
    --     return 1
    -- end
end

function CashMoneyMainUI:onEnter()
    gLobalSoundManager:pauseBgMusic()

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local success = params.success
            local type = params.type
            self:sendCashMoneyPlayCallBack(success, type)
        end,
        ViewEventType.CASHBONUS_CASHMONEY_CALLBACK
    )
end

function CashMoneyMainUI:onExit()
    gLobalNoticManager:removeAllObservers(self)
    gLobalSoundManager:resumeBgMusic()
end

function CashMoneyMainUI:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    self:runCsbAction(
        "over",
        false,
        function()
            performWithDelay(
                self,
                function()
                    self.m_maskUI:setVisible(false)
                    self:findChild("m_bg"):setVisible(false)
                    self:findChild("Node_money"):setVisible(false)
                end,
                0.6
            )
            self:playSpine(
                "Exit",
                function()
                    util_playFadeOutAction(
                        self,
                        0.1,
                        function()
                            local checkOpenCTSView = function()
                                if G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasTaskCompleted() then
                                    local taskType = G_GetMgr(ACTIVITY_REF.HolidayChallenge).TASK_TYPE.CASHMONEY
                                    G_GetMgr(ACTIVITY_REF.HolidayChallenge):chooseCreatePopLayer(taskType)
                                end
                            end
                            if CardSysManager:needDropCards("Cash Money") == true then
                                CardSysManager:doDropCards("Cash Money", checkOpenCTSView)
                            else
                                checkOpenCTSView()
                            end
                            if not tolua.isnull(self) then
                                self:removeFromParent()
                            end
                        end
                    )
                end
            )
        end
    )
end

function CashMoneyMainUI:canClick()
    if self.isClose then
        return false
    end
    if self.m_isGameOver then
        return false
    end
    if self.m_clickTry then
        return false
    end
    if self.m_clickTake then
        return false
    end
    return true
end

function CashMoneyMainUI:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self:canClick() then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "Button_try" then
        if self.m_clickTry then
            return
        end
        self.m_clickTry = true
        self:stopWaitClickSound()
        gLobalSoundManager:playSound(SOUND_RES.click)
        -- TODO: 点击try就开始滚动，滚动结束后如果数据还没有，那么添加loading，知道有数据删除loading，并开始之后的流程逻辑

        G_GetMgr(G_REF.CashBonus):sendActionCashMoneyRequest(ActionType.MegaCashPlay)
    elseif name == "Button_take" then
        if self.m_clickTake then
            return
        end
        self.m_clickTake = true
        self:stopWaitClickSound()
        gLobalSoundManager:playSound(SOUND_RES.click)
        self:overGame(true)
        self:sendExtraRequest({"isClickTake", true})
    end
end

-- 记录玩家点击过take按钮，因为范铮不愿意添加新的接口，只能用自定义接口
function CashMoneyMainUI:sendExtraRequest(extraKV)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.cashMoneyTake] = extraKV
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

function CashMoneyMainUI:sendCashMoneyPlayCallBack(_success, _type)
    if _type == ActionType.MegaCashPlay then
        if _success then
            self.m_clickTry = false
            -- 记录baseCoins
            local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
            self.m_overBaseCoins = cashMoneyData.p_baseCoins
            -- TODO: 临时处理
            self:startRoll()
        else
            self.m_clickTry = false
        end
    end
end

--<<< 通用函数------------------------------------------------------------------------

function CashMoneyMainUI:initData()
    self.m_isGameOver = false

    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    self.m_overBaseCoins = cashMoneyData.p_baseCoins
end

function CashMoneyMainUI:initCsbNode()
    self.m_valueLb = self:findChild("txt_value")
    self.m_bottomNode = self:findChild("Node_bottom")
    self.m_vipNode = self:findChild("Node_vip")
    self.m_overUINode = self:findChild("Node_overui")
    self.m_lianziBgNode = self:findChild("Node_lianzi_bg")
    self.m_lianziTopNode = self:findChild("Node_lianzi_top")
    self.m_lianziLeftNode = self:findChild("Node_lianzi_left")
    self.m_lianziRightNode = self:findChild("Node_lianzi_right")
    -- 动效节点
    self.m_rollEffectNode = self:findChild("Node_Roll")
    self.m_LogoEffectNode = self:findChild("Node_LogoSG")
    self.m_btnTrySGNode = self:findChild("Node_Btn_Try_SG")
    self.m_btnTakeSGNode = self:findChild("Node_Btn_Take_SG")
    self.m_offerEffectNode = self:findChild("Node_KuangSG")
    -- 按钮
    self.m_btnTry = self:findChild("Button_try")
    self.m_btnTake = self:findChild("Button_take")
    -- offer
    self.m_winNode = self:findChild("Node_win")
    self.m_offerNode = self:findChild("Node_offer")
    self.m_txtCurrent = self:findChild("txt_current")
    self.m_txtLeft = self:findChild("txt_left")
    self.m_offerSps = {}
    for i = 1, globalData.constantData.MEGACASH_PLAY_TIMES do
        local sp_offser = self:findChild("sp_offer_" .. i)
        if sp_offser then
            self.m_offerSps[i] = sp_offser
        end
    end
end

function CashMoneyMainUI:initView()
    self:initValue()
    self:initRollNodes()
    self:initEffectNodes()
    self:initCurtainSpine()
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:updateUI()
    -- 断线重连
    if self.m_isReconn then
        self:reconnctGame()
    else
        self:startGame()
    end
end

function CashMoneyMainUI:initAdapt()
    local ratio = display.width / display.height
    if ratio <= 1.34 then -- 1024x768
        self.m_vipNode:setScale(0.75)
        self.m_overUINode:setScale(0.75)
    elseif ratio <= 1.5 then
        self.m_vipNode:setScale(0.85)
        self.m_overUINode:setScale(0.85)
    elseif ratio <= 1.78 then
        self.m_vipNode:setScale(0.9)
        self.m_overUINode:setScale(0.9)
    end
    -- if ratio <= 1.34 then -- 1024x768
    --     self.m_vipNode:setScale(0.55)
    --     self.m_overUINode:setScale(0.55)
    -- elseif ratio <= 1.5 then
    --     self.m_vipNode:setScale(0.65)
    --     self.m_overUINode:setScale(0.65)
    -- elseif ratio <= 1.8 then
    --     self.m_vipNode:setScale(0.8)
    --     self.m_overUINode:setScale(0.8)
    -- end
end

function CashMoneyMainUI:initValue()
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    self.m_valueLb:setString(util_formatCoins(tonumber(cashMoneyData.p_cashMultiply), 20))
end

function CashMoneyMainUI:initRollNodes()
    self.m_rollMainNodes = {}
    self.m_rollCsbs = {}
    for i = 1, #ROLL_NODE_NAME do
        self.m_rollMainNodes[i] = self:findChild(ROLL_NODE_NAME[i])
        self.m_rollCsbs[i] = util_createAnimation("NewCashBonus/CashBonusMoney/" .. ROLL_NODE_NAME[i] .. ".csb", true)
        self.m_rollMainNodes[i]:addChild(self.m_rollCsbs[i])
        self:setRollCsbState(i, true)
    end
end

function CashMoneyMainUI:initEffectNodes()
    -- 滚动特效
    self.m_rollAnima = util_createAnimation("NewCashBonus/CashBonusMoney/Cashmoney_Roll.csb", true)
    self.m_rollEffectNode:addChild(self.m_rollAnima)
    self.m_rollAnima:playAction("an", true)
    -- LOGO扫光特效
    self.m_logoSG = util_createAnimation("NewCashBonus/CashBonusMoney/Cashmoney_SG_Logo.csb", true)
    self.m_LogoEffectNode:addChild(self.m_logoSG)
    self.m_logoSG:playAction("roll", true)
    self.m_logoSG:setVisible(false)
    -- 按钮扫光特效
    self.m_btnTrySG = util_createAnimation("NewCashBonus/CashBonusMoney/Cashmoney_SG_Try.csb", true)
    self.m_btnTrySGNode:addChild(self.m_btnTrySG)
    self.m_btnTrySG:playAction("roll", true)
    self.m_btnTrySG:setVisible(false)
    self.m_btnTakeSG = util_createAnimation("NewCashBonus/CashBonusMoney/Cashmoney_SG_Take.csb", true)
    self.m_btnTakeSGNode:addChild(self.m_btnTakeSG)
    self.m_btnTakeSG:playAction("roll", true)
    self.m_btnTakeSG:setVisible(false)
    -- 中间扫光特效
    self.m_offerSG = util_createAnimation("NewCashBonus/CashBonusMoney/Cashmoney_SG_Kuang.csb", true)
    self.m_offerEffectNode:addChild(self.m_offerSG)
    self.m_offerSG:playAction("roll", true)
    self.m_offerSG:setVisible(false)
end

function CashMoneyMainUI:initCurtainSpine()
    self.m_curtainBgSpine = util_spineCreate("Hourbonus_new3/spine/CashBonus_lianzi", false, true, 1)
    self.m_curtainLeftSpine = util_spineCreate("Hourbonus_new3/spine/CashBonus_lianzi2", false, true, 1)
    self.m_curtainRightSpine = util_spineCreate("Hourbonus_new3/spine/CashBonus_lianzi2", false, true, 1)
    self.m_curtainTopSpine = util_spineCreate("Hourbonus_new3/spine/CashBonus_lianzi3", false, true, 1)
    self.m_lianziBgNode:addChild(self.m_curtainBgSpine)
    self.m_lianziLeftNode:addChild(self.m_curtainLeftSpine)
    self.m_lianziRightNode:addChild(self.m_curtainRightSpine)
    self.m_lianziTopNode:addChild(self.m_curtainTopSpine)

    self.m_lianziLeftNode:setScaleX(-1)

    util_spinePlay(self.m_curtainBgSpine, "idleframe", true)
    util_spinePlay(self.m_curtainLeftSpine, "idleframe", true)
    util_spinePlay(self.m_curtainRightSpine, "idleframe", true)
    util_spinePlay(self.m_curtainTopSpine, "idleframe", true)
end

function CashMoneyMainUI:updateUI()
    self:updateWinCoins()
    self:updateLeftCount()
end

function CashMoneyMainUI:updateWinCoins()
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    self.m_txtCurrent:setString(util_formatCoins(tonumber(cashMoneyData.p_baseCoins), 5))
end

function CashMoneyMainUI:updateLeftCount()
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    self.m_txtLeft:setString(cashMoneyData.p_leftPlayTimes)
end

-->>> 游戏逻辑流程------------------------------------------------------------------------------------
--[[--
    1.游戏开始
        点击小游戏入口请求数据
        获取数据后进入游戏
        播放spine进场动画和播放UI开始动画
    2.滚动流程

    3.游戏结束
        弹出结算界面
        播放spine退场动画
]]
function CashMoneyMainUI:reconnctGame()
    -- 中间滚动区域
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    if cashMoneyData and cashMoneyData.p_result then
        for i = 1, #cashMoneyData.p_result do
            self:setRollCsbState(i, cashMoneyData.p_result[i] == 1)
        end
    end
    self.m_rollAnima:setVisible(false)
    -- 下UI状态
    if self:checkGameOver() or (cashMoneyData and cashMoneyData:getMegaCashTakeData() == true) then
        self:setBottonUIState(false)
    else
        self:setBottonUIState(true)
    end
    -- 下UI特效
    self.m_offerSG:setVisible(true)

    -- self:playCurtainSound()
    self:playSpine("Enter")
    performWithDelay(
        self,
        function()
            self:runCsbAction(
                "start",
                false,
                function()
                    -- self:stopCurtainSound()
                    if self:checkGameOver() or (cashMoneyData and cashMoneyData:getMegaCashTakeData() == true) then
                        self:overGame(true)
                    else
                        self:playWaitClickSound()
                    end
                    self.m_logoSG:setVisible(true)
                end
            )
        end,
        DELAY_AFTER_CURTAIN
    )
end

function CashMoneyMainUI:startGame()
    -- -- 隐藏下UI
    -- self:showBottonUI(false)

    self:setBottonUIState(false)

    self:playCurtainSound()
    -- 播放入场spine动画
    self:playSpine("Enter")
    -- 显示vipUI
    performWithDelay(
        self,
        function()
            self:runCsbAction(
                "start",
                false,
                function()
                    self.m_logoSG:setVisible(true)
                    self:stopCurtainSound()
                    self:startRoll(true)
                end
            )
            -- self:initVipUI(function()
            -- end)
        end,
        DELAY_AFTER_CURTAIN
    )
end

function CashMoneyMainUI:overGame(noDelay)
    self.m_isGameOver = true
    self:setBottonInGameOver()
    if noDelay then
        self:showOverUI()
    else
        performWithDelay(
            self,
            function()
                self:showOverUI()
            end,
            DELAY_SHOW_OVERUI
        )
    end
end

function CashMoneyMainUI:startRoll(isInit)
    self:playRollSound()
    self.m_rollAnima:setVisible(true)
    if not isInit then
        -- 中间滚动区域保持亮着
        self:setRollCsbsState(true)
        self.m_rollAnima:playAction("an", true)
        -- 下UI状态
        self:setBottonUIState(false)
    end
    -- 播放滚动动画
    self:playRollAnim(handler(self, self.overRoll))
end

function CashMoneyMainUI:overRoll()
    performWithDelay(
        self,
        function()
            self:stopRollSound()
        end,
        0.7
    )
    -- 中间滚动区域变暗
    self:setRollCsbsState(false)
    self:startSelect()
end

function CashMoneyMainUI:startSelect()
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()

    local function overSelectFunc()
        performWithDelay(
            self,
            function()
                self:overSelect()
            end,
            DELAY_SELECT_INTERVAL
        )
    end

    local lightIndexs = {}
    for i = 1, #cashMoneyData.p_result do
        if tonumber(cashMoneyData.p_result[i]) == 1 then
            if self:isSelectDouble(i) then
                lightIndexs[#lightIndexs + 1] = {i, true}
            else
                lightIndexs[#lightIndexs + 1] = {i, false}
            end
        end
    end
    if #lightIndexs > 0 then
        -- 挨个点亮钞票
        local count = 0
        local function lightMoney()
            count = count + 1
            if count <= #lightIndexs then
                performWithDelay(
                    self,
                    function()
                        self:setRollCsbState(lightIndexs[count][1], true)
                        -- 声音
                        if lightIndexs[count][2] then
                            gLobalSoundManager:playSound(SOUND_RES.selectDouble)
                        else
                            gLobalSoundManager:playSound(SOUND_RES.selectNormal)
                        end
                        lightMoney()
                    end,
                    DELAY_SELECT_INTERVAL
                )
            else
                -- 判断结束
                overSelectFunc()
            end
        end
        lightMoney()
    else
        overSelectFunc()
    end
end

function CashMoneyMainUI:overSelect()
    -- 更新界面
    self:updateUI()
    -- 设置下UI状态
    self:setBottonUIState(true)

    -- 检测游戏是否弹结束面板
    if self:checkGameOver() then
        self:overGame()
    else
        self:playWaitClickSound()
    end
end
--<<< 游戏逻辑流程------------------------------------------------------------------------------------

function CashMoneyMainUI:playSpine(type, spineEndCallFunc)
    if type == "Enter" then
        util_spinePlay(self.m_curtainTopSpine, "animation2", false)
        util_spineEndCallFunc(
            self.m_curtainTopSpine,
            "animation2",
            function()
                util_spinePlay(self.m_curtainTopSpine, "idleframe", true)
            end
        )
        util_spinePlay(self.m_curtainLeftSpine, "animation2", false)
        util_spineEndCallFunc(
            self.m_curtainLeftSpine,
            "animation2",
            function()
                util_spinePlay(self.m_curtainLeftSpine, "idleframe", true)
            end
        )
        util_spinePlay(self.m_curtainRightSpine, "animation2", false)
        util_spineEndCallFunc(
            self.m_curtainRightSpine,
            "animation2",
            function()
                util_spinePlay(self.m_curtainRightSpine, "idleframe", true)
            end
        )
        util_spinePlay(self.m_curtainBgSpine, "animation2", false)
        util_spineEndCallFunc(
            self.m_curtainBgSpine,
            "animation2",
            function()
                if spineEndCallFunc then
                    spineEndCallFunc()
                end
            end
        )
    elseif type == "Exit" then
        util_spinePlay(self.m_curtainBgSpine, "animation", false)

        performWithDelay(
            self,
            function()
                util_spinePlay(self.m_curtainTopSpine, "animation3", false)
                util_spinePlay(self.m_curtainLeftSpine, "animation3", false)
                util_spinePlay(self.m_curtainRightSpine, "animation3", false)
                util_spinePlay(self.m_curtainBgSpine, "animation2", false)
                util_spineEndCallFunc(
                    self.m_curtainBgSpine,
                    "animation2",
                    function()
                        if spineEndCallFunc then
                            spineEndCallFunc()
                        end
                    end
                )
            end,
            1.5
        )
    end
end

function CashMoneyMainUI:setRollCsbsState(isLiang)
    for i = 1, #ROLL_NODE_NAME do
        self:setRollCsbState(i, isLiang)
    end
end

function CashMoneyMainUI:setRollCsbState(index, isLiang)
    if isLiang then
        self.m_rollCsbs[index]:playAction("light")
    else
        self.m_rollCsbs[index]:playAction("dark")
    end
end

-- function CashMoneyMainUI:showBottonUI(isShow)
--     self.m_bottomNode:setVisible(isShow)
-- end

function CashMoneyMainUI:setBottonUIState(isEnabled)
    if isEnabled then
        self.m_btnTrySG:setVisible(true)
        self.m_btnTakeSG:setVisible(true)
        self.m_btnTry:setTouchEnabled(true)
        self.m_btnTry:setBright(true)
        self.m_btnTake:setTouchEnabled(true)
        self.m_btnTake:setBright(true)
        self.m_winNode:setVisible(true)
        self.m_offerNode:setVisible(false)
    else
        self.m_btnTrySG:setVisible(false)
        self.m_btnTakeSG:setVisible(false)
        self.m_btnTry:setTouchEnabled(false)
        self.m_btnTry:setBright(false)
        self.m_btnTake:setTouchEnabled(false)
        self.m_btnTake:setBright(false)
        self.m_winNode:setVisible(false)
        self.m_offerNode:setVisible(true)
        local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
        for i = 1, 4 do
            self.m_offerSps[i]:setVisible(false)
        end
        for i = 1, 4 do
            if self.m_offerSps[i] then
                -- self.m_offerSps[i]:setVisible((globalData.constantData.MEGACASH_PLAY_TIMES-cashMoneyData.p_leftPlayTimes) == i)
                if cashMoneyData.p_leftPlayTimes == 0 and i == 4 then
                    self.m_offerSps[i]:setVisible(true)
                end
                if cashMoneyData.p_leftPlayTimes == 1 and i == 3 then
                    self.m_offerSps[i]:setVisible(true)
                end
                if cashMoneyData.p_leftPlayTimes == 2 and i == 2 then
                    self.m_offerSps[i]:setVisible(true)
                end
                if cashMoneyData.p_leftPlayTimes == 3 and i == 1 then
                    self.m_offerSps[i]:setVisible(true)
                end
                if cashMoneyData.p_leftPlayTimes == 4 and i == 1 then
                    self.m_offerSps[i]:setVisible(true)
                end
            end
        end
    end
end

function CashMoneyMainUI:setBottonInGameOver()
    self.m_btnTrySG:setVisible(false)
    self.m_btnTakeSG:setVisible(false)
    self.m_btnTry:setTouchEnabled(false)
    self.m_btnTry:setBright(false)
    self.m_btnTake:setTouchEnabled(false)
    self.m_btnTake:setBright(false)
end

function CashMoneyMainUI:initVipUI(hideCallBack)
    self.m_vipAddview = util_createView("views.cashBonus.cashBonusPickGame.CashBonusVipAddView")
    self.m_vipNode:addChild(self.m_vipAddview)
    self.m_vipAddview:runShowAction()
    self.m_vipAddview:initData()
    performWithDelay(
        self,
        function()
            -- -- 显示下UI
            -- self:showBottonUI(true)
            -- 显示中间的流光
            self.m_offerSG:setVisible(true)
            -- 设置下UI状态
            self:setBottonUIState(false)
            -- 关闭vip
            if self.m_vipAddview and self.m_vipAddview.closeUI then
                self.m_vipAddview:closeUI(hideCallBack)
                self.m_vipAddview = nil
            end
        end,
        VIP_SHOW_TIME
    )
end

function CashMoneyMainUI:playRollAnim(rollOverCall)
    self.m_rollAnima:playAction(
        "roll",
        false,
        function()
            if rollOverCall then
                rollOverCall()
            end
        end
    )
end

-- 判断游戏是否结束，弹结束面板
function CashMoneyMainUI:checkGameOver()
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    if tonumber(cashMoneyData.p_leftPlayTimes) == 0 then
        return true
    end
    return false
end

function CashMoneyMainUI:showOverUI()
    gLobalSoundManager:playSound(SOUND_RES.showOver)
    self.m_overUI =
        util_createView(
        "views.cashBonus.cashBonusMoneyGame.CashMoneyOverUI",
        self.m_overBaseCoins,
        function()
            G_GetMgr(G_REF.CashBonus):sendActionCashMoneyRequest(ActionType.MegaCashCollect)
            -- 重置自定义请求数据
            local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
            if cashMoneyData and cashMoneyData:getMegaCashTakeData() == true then
                self:sendExtraRequest({"isClickTake", false})
            end
        end
    )
    self.m_overUINode:addChild(self.m_overUI)
    self.m_overUI:setOverFunc(
        function()
            self.m_overUI = nil
            self:closeUI()
        end
    )
end

-->>> 声音 --------------------------------------------------------------------------------------
function CashMoneyMainUI:isSelectDouble(index)
    if index == 11 or index == 12 then
        return true
    end
    return false
end

function CashMoneyMainUI:playCurtainSound()
    self.m_curtainSoundID = gLobalSoundManager:playSound(SOUND_RES.curtain)
end

function CashMoneyMainUI:stopCurtainSound()
    if self.m_curtainSoundID ~= nil then
        gLobalSoundManager:stopAudio(self.m_curtainSoundID)
        self.m_curtainSoundID = nil
    end
end

function CashMoneyMainUI:playWaitClickSound()
    self.m_waitClickSoundID = gLobalSoundManager:playSound(SOUND_RES.waitClick)
end

function CashMoneyMainUI:stopWaitClickSound()
    if self.m_waitClickSoundID ~= nil then
        gLobalSoundManager:stopAudio(self.m_waitClickSoundID)
        self.m_waitClickSoundID = nil
    end
end

function CashMoneyMainUI:playRollSound()
    self.m_rollSoundID = gLobalSoundManager:playSound(SOUND_RES.roll)
end

function CashMoneyMainUI:stopRollSound()
    if self.m_rollSoundID ~= nil then
        gLobalSoundManager:stopAudio(self.m_rollSoundID)
        self.m_rollSoundID = nil
    end
end
--<<< 声音 --------------------------------------------------------------------------------------

return CashMoneyMainUI
