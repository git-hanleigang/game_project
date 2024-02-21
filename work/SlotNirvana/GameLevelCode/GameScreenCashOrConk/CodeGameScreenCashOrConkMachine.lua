local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData" 
local CodeGameScreenCashOrConkMachine = class("CodeGameScreenCashOrConkMachine", BaseNewReelMachine)
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"
local CashOrConkDefine = util_require("CashOrConkDefine")

CodeGameScreenCashOrConkMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCashOrConkMachine.EFFECT_COLLECT   = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenCashOrConkMachine.EFFECT_PICK   = GameEffect.EFFECT_SELF_EFFECT - 2


-- 构造函数
function CodeGameScreenCashOrConkMachine:ctor()
    CodeGameScreenCashOrConkMachine.super.ctor(self)
    self._isHaveShowBonusTip = false
    self.m_isconnect = false
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0 
    self.m_totalWinCoin = 0

    self._isSpinEnabled = true

    self.b_checkLevelRes = true
    self.m_spinRestMusicBG = true
    self.b_roomHeadHideFlag = true
    self.m_isFeatureOverBigWinInFree = true

    self.m_respinViewTab = {}
    self.m_iBetLevel = 1
    self:initGame()
end

function CodeGameScreenCashOrConkMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    -- self:setReelRunSound(LeoWealthPublicConfig.sound_LeoWealth_reelRun)
end

function CodeGameScreenCashOrConkMachine:getModuleName()
    return "CashOrConk"
end

function CodeGameScreenCashOrConkMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    self:initJackPotBarView()

    self._npc = util_createView("CashOrConk.CashOrConkNPC",{machine = self})
    self:findChild("Node_juese"):addChild(self._npc)

    self._node_reward = util_createView("CashOrConkReward",{machine = self})
    self:findChild("jianglilan_classic"):addChild(self._node_reward)

    self:levelPerformWithDelay(self,0.3,function()
        self:addClick(self:findChild("Panel_1"))
        
        -- self:playTrans("1_1",function()
            
        -- end)
    end)
end

function CodeGameScreenCashOrConkMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    
    local name_parent = sender:getParent():getName()

    util_require("CashOrConkUtil",true)(self)
    -- self:createDFView("1_1")
end

function CodeGameScreenCashOrConkMachine:initMachineBg()
    self.super.initMachineBg(self)
    self.m_gameBg:runCsbAction("idle",true)
    self:changeBgTo()
end

function CodeGameScreenCashOrConkMachine:changeBgTo(state)
    if not state then
        self.m_gameBg:findChild("CashOrConk_BaseBG_1"):show()
        self.m_gameBg:findChild("CashOrConk_DFCBG1_2"):hide()
        self.m_gameBg:findChild("CashOrConk_DFCBG2_3"):hide()
        self.m_gameBg:findChild("Node_D_BaseBG"):show()
        self.m_gameBg:findChild("Node_D_DFCBG1&2"):hide()
    else
        self.m_gameBg:findChild("CashOrConk_BaseBG_1"):hide()
        if string.sub(state,3,3) == "1" then
            self.m_gameBg:findChild("CashOrConk_DFCBG1_2"):show()
            self.m_gameBg:findChild("CashOrConk_DFCBG2_3"):hide()
        else
            self.m_gameBg:findChild("CashOrConk_DFCBG1_2"):hide()
            self.m_gameBg:findChild("CashOrConk_DFCBG2_3"):show()
        end
        self.m_gameBg:findChild("Node_D_BaseBG"):hide()
        self.m_gameBg:findChild("Node_D_DFCBG1&2"):show()
    end
end

function CodeGameScreenCashOrConkMachine:initJackPotBarView()
    self.m_jackpotView = util_createView("CashOrConk.CashOrConkJackPotBarView",{
        machine = self
    })
    self.m_jackpotView:initMachine(self)
    self:findChild("jackpot_classic"):addChild(self.m_jackpotView)
end


function CodeGameScreenCashOrConkMachine:initGameStatusData(gameData)
    local feature = clone(gameData.feature)
    gameData.feature = nil
    if feature then
        gameData.spin.selfData.bonus = feature.selfData.bonus
    end
    if gameData.spin and gameData.spin.selfData and gameData.spin.selfData.bonus.status and gameData.spin.selfData.bonus.status == "OPEN" then
        gameData.spin.features[2] = 5
    elseif gameData.spin then
        gameData.spin.features[2] = nil
    end
	CodeGameScreenCashOrConkMachine.super.initGameStatusData(self,gameData)
end


function CodeGameScreenCashOrConkMachine:initHasFeature( )
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self:initCloumnSlotNodesByNetData()
end

function CodeGameScreenCashOrConkMachine:showBonusGameView(effectData)
    self._effectData_df = effectData
    self:resumePickGame()
end

function CodeGameScreenCashOrConkMachine:getPickIndex()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local mode = extra.mode

    return tonumber(string.sub(mode,1,1))
end

function CodeGameScreenCashOrConkMachine:getMainStatus()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local mode = extra.mode

    return tonumber(string.sub(mode,2,2))
end

function CodeGameScreenCashOrConkMachine:getSubStatus()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local mode = extra.mode

    return tonumber(string.sub(mode,3,3)),tonumber(string.sub(mode,4,4))
end

function CodeGameScreenCashOrConkMachine:getStateByData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local bonus = selfData.bonus
    local extra = bonus.extra
    local mode = tonumber(extra.mode)
    local len = string.len(mode)
    local df_1 = math.floor(mode/1000)
    local df_2 = math.floor((mode - df_1*1000)/100)
    
    return string.format("%d_%d",df_1,df_2)
end

function CodeGameScreenCashOrConkMachine:resumePickGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if self.m_isconnect then
        local status_main = self:getMainStatus()
        local status1,status2 = self:getSubStatus()
        local view
        if status_main == 1 and status1 == 1 and status2 == 1 then
            view = self:createDFView(string.format("%d_%d",self:getPickIndex(),2))
        else
            view = self:createDFView(self:getStateByData())
        end
        view:setLockClick(false)
        view:refreshStatus(true)
        self:changeBgTo(self:getStateByData())
        self:updateBottomUICoins(self.m_runSpinResultData.p_selfMakeData.bonus.extra.bonus0win)
    else
        self.m_totalWinCoin = self.m_runSpinResultData.p_selfMakeData.bonus.extra.bonus0win or 0
        self:changePickToState(self:getStateByData())
    end
end

local state2view = {
    ["1_1"] = {view = "Pick.CashOrConkDF11",node = "DF11"},
    ["1_2"] = {view = "Pick.CashOrConkDF12",node = "DF12"},
    ["2_1"] = {view = "Pick.CashOrConkDF21",node = "DF21"},
    ["2_2"] = {view = "Pick.CashOrConkDF22",node = "DF22"},
    ["3_1"] = {view = "Pick.CashOrConkDF31",node = "DF31"},
    ["3_2"] = {view = "Pick.CashOrConkDF32",node = "DF32"},
    ["4_0"] = {view = "Pick.CashOrConkDF4",node = "DF21"},
}
function CodeGameScreenCashOrConkMachine:changePickToState(state,funcChange)
    local view
    self:playTrans(state,function()
        if funcChange then
            funcChange()
        end
        view = self:createDFView(state)
        view:refreshStatus()
        self:changeBgTo(state)
        self:checkChangeBaseParent()
        self:findChild("xianshu"):hide()
    end,function()
        -- view:setLockClick(false)
    end)
end

function CodeGameScreenCashOrConkMachine:createDFView(state)
    self:findChild("xianshu"):hide()
    self:findChild(state2view[state]["node"]):removeAllChildren()
    local view = util_require(state2view[state]["view"],true):create()
    if view.initData_ then
        view:initData_({machine = self})
    end
    self:findChild(state2view[state]["node"]):addChild(view)
    view:setLockClick(true)
    return view
end

function CodeGameScreenCashOrConkMachine:showDFEndView(coins,state,over4,func_trans)
    local endEffc = function()
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_ULTRAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)

        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winCoinsLine = self:getClientWinCoins()
        local winCoinsBonus = self.m_runSpinResultData.p_selfMakeData.bonus.extra.bonus0win - winCoinsLine

        local winCoinsPick = 0
        for i = 1,3 do
            if self.m_runSpinResultData.p_selfMakeData.bonus.extra["bonus"..i.."_win"] then
                winCoinsPick = self.m_runSpinResultData.p_selfMakeData.bonus.extra["bonus"..i.."_win"]
            end
        end

        local totalWinCoins = (winCoinsPick + winCoinsBonus + winCoinsLine)
        local isLineWinBig = (winCoinsLine / lTatolBetNum) >= self.m_BigWinLimitRate
        local isBonusWinBig = (winCoinsBonus / lTatolBetNum) >= self.m_BigWinLimitRate
        local isPickWinBig = (winCoinsPick / lTatolBetNum) >= self.m_BigWinLimitRate            
        local isTotalWinBif = (totalWinCoins / lTatolBetNum) >= self.m_BigWinLimitRate            

        if isTotalWinBif  then
            self:checkFeatureOverTriggerBigWin(totalWinCoins, self.EFFECT_COLLECT)
        end
        self:updateBottomUICoins(winCoinsPick,true,true,true)

        self._effectData_df.p_isPlay = true
        self:playGameEffect()

        self:removeSoundHandler()
        self:reelsDownDelaySetMusicBGVolume()

        self.m_bottomUI:notifyTopWinCoin()
    end

    self:levelPerformWithDelay(self,15/60,function()
        if func_trans then
            func_trans()
        end
        self:hideDark()
        self:findChild("xianshu"):show()
        self:findChild(state2view[state]["node"]):removeAllChildren()
        self._node_reward:plalHideIdle()
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local extra = selfData.bonus.extra
        local startReel   = extra.bonustrigger
        if not startReel then
            return
        end
        for _lineIndex,_lineData in ipairs(startReel) do
            local iRow   = self.m_iReelRowNum - _lineIndex + 1
            for _iCol,_symbolType in ipairs(_lineData) do
                local symbol = self:getFixSymbol(_iCol, iRow, SYMBOL_NODE_TAG)
                if symbol then
                    self:changeSymbolType(symbol, _symbolType)
                end
            end
        end

        local hashSymbol2AnimSwitch = {
            [CashOrConkDefine.bonus2] = {"switch_1bonus","idleframe2_1","actionframe1"},
            [CashOrConkDefine.bonus3] = {"switch_2bonus","idleframe2_2","actionframe2"},
            [CashOrConkDefine.bonus4] = {"switch_3bonus","idleframe2_3","actionframe3"},
        }
        local betCoin = globalData.slotRunData:getCurTotalBet()
        local hash_index2mu = {}
        for i,v in ipairs(extra.first_stored_icon) do
            hash_index2mu[v[1]] = tonumber(v[2])
        end
        for i,v in ipairs(extra.first_bonus_signal) do
            local rowColData = self:getRowAndColByPos(v[1])
            local slotsNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
            if tonumber(v[2]) == CashOrConkDefine.bonus1 then
                local animNode = slotsNode:checkLoadCCbNode()
                local strCoins=util_formatCoinsLN(hash_index2mu[v[1]] * betCoin,3)
                animNode.m_slotCsb:findChild("m_lb_coins"):setString(strCoins)
                slotsNode:runAnim("switch_bonus_idleframe",true)
            else
                slotsNode:runAnim(hashSymbol2AnimSwitch[tonumber(v[2])][1].."_idleframe",true)
            end
        end

        self._npc:show()
        self._npc._animBubble:show()
        self:changeBgTo()
    end)

    self:clearCurMusicBg()
    local view = GD.util_createView("Pick.CashOrConkDFEndView",{
        coins = coins or 9999999999,
        state = state,
        over4 = over4
    })
    view:popView()
    view:setOverAniRunFunc(function()
        endEffc()
        self:resetMusicBg(true,"CashOrConkSounds/sound_COC_baseLineFrame_base.mp3")
    end)
    view:findChild("z"):setScale(self.m_machineRootScale)
    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
end

local hash__state__2__enter_music = {
    ["1_1"] = CashOrConkPublicConfig.sound_CashOrConk_15,
    ["1_2"] = CashOrConkPublicConfig.sound_CashOrConk_56,
    ["2_1"] = CashOrConkPublicConfig.sound_CashOrConk_11,
    ["2_2"] = CashOrConkPublicConfig.sound_CashOrConk_45,
    ["3_1"] = CashOrConkPublicConfig.sound_CashOrConk_4,
    ["3_2"] = CashOrConkPublicConfig.sound_CashOrConk_24,
}
function CodeGameScreenCashOrConkMachine:playTrans(skin,funcChange,funcEnd)
    if skin ~= "4_0" then
        gLobalSoundManager:playSound(hash__state__2__enter_music[skin])
    else
        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_trans_4)
    end

    skin = skin == "4_0" and "4" or skin
    local spine = util_spineCreate("CashOrConk_guochang",true,true)
    spine:setSkin(skin)
    local anim = "actionframe_guochang"
    local ends = tonumber(string.sub(skin,3,3))

    if ends == 1 then
        anim = "actionframe_guochang"
    elseif ends == 2 then
        anim = "actionframe_guochang2"
    else
        anim = "actionframe_guochang3"
    end
    
    util_spinePlayAction(spine, anim,false,function()
        if funcEnd then
            funcEnd()
        end
        self:levelPerformWithDelay(self,0.001,function()
            spine:removeFromParent()
        end)
    end)
    -- spine:setPosition(display.center)

    self:findChild("Node_trans"):addChild(spine)

    self:levelPerformWithDelay(spine,13/30,funcChange)
end

function CodeGameScreenCashOrConkMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == 94 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分值越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

function CodeGameScreenCashOrConkMachine:syncData(spinData,initData)
    if initData then
        if initData.spin then
            self._selfData = clone(initData.spin.selfData) 
        else
            self._selfData = {
                betData = {}
            }
        end
    elseif spinData then
        self._selfData = clone(self.m_runSpinResultData.p_selfMakeData) 
        if not self._selfData.betData then
            self._selfData.betData = {}
        end
    end
end


function CodeGameScreenCashOrConkMachine:updateReelGridNode(symbolNode)
    if symbolNode.p_symbolType == CashOrConkDefine.bonus1 then
        self:checkBonusAndAddInfo(symbolNode)
        symbolNode:runAnim("idleframe")
    elseif symbolNode.p_symbolType == 92 then
        local animNode = symbolNode:checkLoadCCbNode()
        util_spineResetAnim(animNode.m_spineNode)
    end
end

function CodeGameScreenCashOrConkMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent,lineNode,nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:resetReelStatus()
            end
        end
    end
end

function CodeGameScreenCashOrConkMachine:checkBonusAndAddInfo(symbolNode)
    local animNode = symbolNode:checkLoadCCbNode()
    if not animNode.m_slotCsb or tolua.isnull(animNode.m_slotCsb) then
        animNode.m_slotCsb = nil
        animNode.m_slotCsb = util_createAnimation("Socre_CashOrConk_Bonus2_info.csb")
        animNode.m_slotCsb.m_csbAct:retain()
        animNode.m_slotCsb:playAction("idleframe")
        util_spinePushBindNode(animNode.m_spineNode, "shuzi", animNode.m_slotCsb)
    else
        animNode.m_slotCsb:playAction("idleframe")
    end
end

function CodeGameScreenCashOrConkMachine:enterGamePlayMusic()
    
    scheduler.performWithDelayGlobal(function(  )
        self:playEnterGameSound(CashOrConkPublicConfig.sound_CashOrConk_enterLevel)
    end,0.4,self:getModuleName())
end

function CodeGameScreenCashOrConkMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCashOrConkMachine.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

end



function CodeGameScreenCashOrConkMachine:addObservers()
    CodeGameScreenCashOrConkMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            -- 此时不应该播放赢钱音效
            if params[self.m_stopUpdateCoinsSoundIndex] then
                return
            end
            if self.m_bIsBigWin then
                -- return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]
            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
            elseif winRate > 3 then
                soundIndex = 3
            end

            
            local soundName = CashOrConkPublicConfig["sound_COC_baseLineFrame_"..soundIndex]
            -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --     soundName = "LeoWealthSounds/sound_LeoWealth_freeLineFrame_" .. soundIndex .. ".mp3"
            -- end
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenCashOrConkMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCashOrConkMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    self:clearLevelsCodeCache()
end

local hash_symbol_2_res  ={
    [9] = "Socre_CashOrConk_10",
    [10] = "Socre_CashOrConk_11",
    [11] = "Socre_CashOrConk_12",
    -- [12] = "Socre_CashOrConk_12",
    [94] = "Socre_CashOrConk_Bonus",
}
function CodeGameScreenCashOrConkMachine:MachineRule_GetSelfCCBName(symbolType)
    return hash_symbol_2_res[symbolType]
end

-- 断线重连
function CodeGameScreenCashOrConkMachine:MachineRule_initGame()
    self.m_isconnect = true
end

function CodeGameScreenCashOrConkMachine:slotOneReelDown(reelCol)
    CodeGameScreenCashOrConkMachine.super.slotOneReelDown(self, reelCol)
end

function CodeGameScreenCashOrConkMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    self:showDark()

    CodeGameScreenCashOrConkMachine.super.slotReelDown(self)
end

function CodeGameScreenCashOrConkMachine:showDark()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    selfData = clone(selfData)

    if #selfData.stored_icon >= 6 and math.random(1,10) > 3 then
        local anim = util_createAnimation("CashOrConk_base_yaan.csb")
        anim:playAction("start",false,function()
            anim:playAction("idle")
        end)
        self:findChild("sp_reel"):addChild(anim,REEL_SYMBOL_ORDER.REEL_ORDER_2 - 1)
        self._anim_dark = anim
    end
end

function CodeGameScreenCashOrConkMachine:hideDark()
    if self._anim_dark then
        self._anim_dark:playAction("over",false,function()
            self._anim_dark:removeFromParent()
            self._anim_dark = nil
        end)
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCashOrConkMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    self.m_totalWinCoin = 0
    return false -- 用作延时点击spin调用
end

function CodeGameScreenCashOrConkMachine:updateNetWorkData()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- self:syncData(self.m_runSpinResultData)

    local func = function()
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            -- self._leo:playBlink()
            CodeGameScreenCashOrConkMachine.super.updateNetWorkData(self)
        else
            CodeGameScreenCashOrConkMachine.super.updateNetWorkData(self)
        end
    end

    func()

end

function CodeGameScreenCashOrConkMachine:initFeatureInfo(spinData,featureData)
    local s=  spinData
end

function CodeGameScreenCashOrConkMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.bonus_signal and #selfData.bonus_signal > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_COLLECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_COLLECT
    end
end

function CodeGameScreenCashOrConkMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_COLLECT then

        self:removeSoundHandler()
        
        self:playSelfEffectCollect(function()
            local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
            local winCoinsLine = self:getClientWinCoins()
            local winCoinsBonus = self.m_runSpinResultData.p_selfMakeData.bonus.extra.bonus0win - winCoinsLine
            local isLineWinBig = (winCoinsLine / lTatolBetNum) >= self.m_BigWinLimitRate
            local isBonusWinBig = (winCoinsBonus / lTatolBetNum) >= self.m_BigWinLimitRate
            local isTotalWinBig = ((winCoinsBonus + winCoinsLine) / lTatolBetNum) >= self.m_BigWinLimitRate

            if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
                self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
                self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
                self:removeGameEffectType(GameEffect.EFFECT_ULTRAWIN)
                self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            else
                if isBonusWinBig and winCoinsLine == 0 then
                    self:checkFeatureOverTriggerBigWin((winCoinsBonus + winCoinsLine), self.EFFECT_COLLECT)
                end
            end

            if winCoinsLine == 0 and not self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
                self.m_bottomUI:notifyTopWinCoin()
            end
            
            if not self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
                self:removeSoundHandler()
                self:reelsDownDelaySetMusicBGVolume()
            end

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    return true
end

function CodeGameScreenCashOrConkMachine:playSelfEffectCollect(func)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    selfData = clone(selfData)

    local hash_index2mu = {}
    for i,v in ipairs(selfData.stored_icon) do
        hash_index2mu[v[1]] = tonumber(v[2])
    end

    local funcGetBonusSlots = function(valueMap)
        local bonusSlots = {}
        for k,v in pairs(selfData.bonus_signal) do
            v[2] = tonumber(v[2])
            if valueMap[v[2]] then
                bonusSlots[#bonusSlots + 1] = v
            end
        end
        table.sort(bonusSlots,function(av,bv)
            local a = self:getRowAndColByPos(av[1])
            local b = self:getRowAndColByPos(bv[1])
            if a.iY == b.iY then
                return a.iX > b.iX
            else
                return a.iY < b.iY
            end
        end)
        return bonusSlots
    end

    local bonusCoin = funcGetBonusSlots({
        [CashOrConkDefine.bonus1] = true
    })
    
    local bonusAll = funcGetBonusSlots({
        [CashOrConkDefine.bonus1] = true,
        [CashOrConkDefine.bonus2] = true,
        [CashOrConkDefine.bonus3] = true,
        [CashOrConkDefine.bonus4] = true,
    })

    local bonusPick = funcGetBonusSlots({
        [CashOrConkDefine.bonus2] = true,
        [CashOrConkDefine.bonus3] = true,
        [CashOrConkDefine.bonus4] = true,
    })

    local funcYield = function(...)
        coroutine.yield(...)
    end
    local funcGetSlotNodeAndAnimNode = function(posIdx)
        local rowColData = self:getRowAndColByPos(posIdx)
        local slotsNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
        local animNode = slotsNode:checkLoadCCbNode()
        return slotsNode,animNode
    end
    local hashSymbol2AnimSwitch = {
        [CashOrConkDefine.bonus2] = {"switch_1bonus","idleframe2_1","actionframe1"},
        [CashOrConkDefine.bonus3] = {"switch_2bonus","idleframe2_2","actionframe2"},
        [CashOrConkDefine.bonus4] = {"switch_3bonus","idleframe2_3","actionframe3"},
    }

    self._hash_opened = {}
    self._is_in_quick_open = false
    for k,v in pairs(bonusCoin) do
        self._hash_opened[v] = false
    end
    
    local co
    co = coroutine.create(function()
        self.m_bottomUI:showBtnStopCpy()

        self:levelPerformWithDelay(self,0.5,function()
            util_resumeCoroutine(co)
        end)
        funcYield()
        --翻开bonus1
        for i,v in ipairs(bonusAll) do
            if self._is_in_quick_open then
                break
            end
            local slotsNode,animNode = funcGetSlotNodeAndAnimNode(v[1])
            if v[2] == CashOrConkDefine.bonus1 then
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_2)
                self._hash_opened[v] = true
                local strCoins=util_formatCoinsLN(hash_index2mu[v[1]] * betCoin,3,nil,nil,nil,true)
                animNode.m_slotCsb:findChild("m_lb_coins"):setString(strCoins)
                slotsNode:runAnim("switch_bonus",false,function()
                    slotsNode:runAnim("idleframe2_je",true)
                end)
                self:levelPerformWithDelay(self,0.5,function()
                    util_resumeCoroutine(co)
                end)
            else
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_48)
                slotsNode:runAnim("dj",false,function()
                    self._npc:playDFSpecial("0","caijiangli")
                    self._npc:playAnim("actionframe2",false)
                    slotsNode:runAnim("idleframe3",true,function()
                        util_resumeCoroutine(co)
                    end)
                end)
            end
            
            funcYield()
        end

        self._hash_opened = {}
        self.m_bottomUI:hideBtnStopCpy()

        if #bonusCoin > 0 then
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_31)
        end

        for i,v in ipairs(bonusCoin) do
            local slotsNode,animNode = funcGetSlotNodeAndAnimNode(v[1])
            local zo = slotsNode:getLocalZOrder()
            slotsNode:setLocalZOrder(4344)
            slotsNode:runAnim("actionframe",false,function()
                slotsNode:setLocalZOrder(zo)
                if i == #bonusCoin then
                    self:levelPerformWithDelay(self,0.5,function()
                        util_resumeCoroutine(co)
                    end)
                end
            end)
        end

        if #bonusCoin > 0 then
            funcYield()
            -- gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_31)
        end

        local totalCoins = 0
        for i,v in ipairs(bonusCoin) do
            totalCoins = totalCoins + hash_index2mu[v[1]] * betCoin
            local slotsNode,animNode = funcGetSlotNodeAndAnimNode(v[1])
            local zo = slotsNode:getLocalZOrder()
            slotsNode:setLocalZOrder(4344)
            slotsNode:runAnim("actionframe_js",false,function()
                -- animNode.m_slotCsb:playAction("actionframe_js2",false)
                slotsNode:setLocalZOrder(zo)
                if i == #bonusCoin then
                    self:levelPerformWithDelay(self,1,function()
                        util_resumeCoroutine(co)
                    end)
                end
            end)
        end
        
        if #bonusCoin > 0 then
            self:levelPerformWithDelay(self,7/30,function()
                self:playCeleBottom()
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_16)
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_25)
                self:updateBottomUICoins(totalCoins,false,true,false)
                local info = {
                    overCoins = totalCoins,
                    animName = "actionframe3",
                    jumpTime = 0.8
                }
                self:playBottomBigWinLabAnim(info)

                if #bonusPick == 0 then
                    self:hideDark()
                end
            end)
            funcYield()
        end

        for i,v in ipairs(bonusPick) do
            local slotsNode,animNode = funcGetSlotNodeAndAnimNode(v[1])
            self._hash_opened[slotsNode] = true
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_26)
            local zo = slotsNode:getLocalZOrder()
            slotsNode:setLocalZOrder(8344)
            slotsNode:runAnim(hashSymbol2AnimSwitch[v[2]][1],false,function()
                slotsNode:setLocalZOrder(zo)
                self._npc:playAnim("actionframe3",false)
                self:runCsbAction("qpk_wy")
                slotsNode:runAnim(hashSymbol2AnimSwitch[v[2]][2],true)
                util_resumeCoroutine(co)
            end)

            funcYield()
        end

        --触发
        for i,v in ipairs(bonusPick) do
            self:clearCurMusicBg()
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_8)
            self._npc:playDFSpecial("0","chuwanfa")
            local slotsNode,animNode = funcGetSlotNodeAndAnimNode(v[1])
            local zo = slotsNode:getLocalZOrder()
            slotsNode:setLocalZOrder(8344)
            slotsNode:runAnim(hashSymbol2AnimSwitch[v[2]][3],false,function()
                slotsNode:setLocalZOrder(zo)
                util_resumeCoroutine(co)
            end)
            funcYield()
        end

        func()
    end)
    self._co_collect = co
    util_resumeCoroutine(co)
end

function CodeGameScreenCashOrConkMachine:quickOpen()
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_2)
    self._is_in_quick_open = true

    local betCoin = globalData.slotRunData:getCurTotalBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local hash_index2mu = {}
    for i,v in ipairs(extra.first_stored_icon) do
        hash_index2mu[v[1]] = tonumber(v[2])
    end

    local funcGetSlotNodeAndAnimNode = function(posIdx)
        local rowColData = self:getRowAndColByPos(posIdx)
        local slotsNode = self:getFixSymbol(rowColData.iY, rowColData.iX, SYMBOL_NODE_TAG)
        local animNode = slotsNode:checkLoadCCbNode()
        return slotsNode,animNode
    end

    for k,v in pairs(self._hash_opened) do
        if v == false then
            local slotsNode,animNode = funcGetSlotNodeAndAnimNode(k[1])
            local strCoins=util_formatCoinsLN(hash_index2mu[k[1]] * betCoin,3,nil,nil,nil,true)
            local animNode = slotsNode:checkLoadCCbNode()
            animNode.m_slotCsb:findChild("m_lb_coins"):setString(strCoins)
            slotsNode:runAnim("idleframe2_je",true)
        end
    end
end

function CodeGameScreenCashOrConkMachine:getBottomUINode( )
    return "CashOrConkBottomUI"
end

function CodeGameScreenCashOrConkMachine:beginReel()
    self._isThisSpinHaveMulti = false
    self._scatterSoundIndex = 1
    self._isPlayedLongRunStart = false
    self._isThisSpinPlayPre = false
    self.m_isconnect = false

    self._thisSpinBonusBulingCnt = 0
    CodeGameScreenCashOrConkMachine.super.beginReel(self)
end

function CodeGameScreenCashOrConkMachine:symbolBulingEndCallBack(_slotNode)
    if _slotNode.p_symbolType == CashOrConkDefine.bonus1 then
        _slotNode:runAnim(
            "idleframe2",
            true
        )
    end
end




function CodeGameScreenCashOrConkMachine:getMinBet( )
    local minBetGrand = 0

    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 1
        return 0
    end
    if not self.m_specialBets then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    if self.m_specialBets and self.m_specialBets[1] then
        minBetGrand = self.m_specialBets[1].p_totalBetValue
    end

    return minBetGrand
end

function CodeGameScreenCashOrConkMachine:showEffect_NewWin(effectData,winType)
    local superWinFunc = function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        CodeGameScreenCashOrConkMachine.super.showEffect_NewWin(self, effectData, winType)
    end

    
    if math.random(1,10) <= 3 then
        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_9)
    end
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_notice_1)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    util_shakeNode(self:findChild("root1"), 4, 4, 2)



    local labelCoins = self.m_bottomUI.m_normalWinLabel
    local sizeLabel = labelCoins:getContentSize()
    local wp1 = labelCoins:convertToWorldSpace(cc.p(sizeLabel.width/2,sizeLabel.height/2))
    local np1 = self.m_bottomUI:convertToNodeSpace(cc.p(wp1))
    np1.y = np1.y + 15

    if selfData and selfData.bonus and selfData.bonus.extra and selfData.bonus.extra.mode then
        local extra = self.m_runSpinResultData.p_selfMakeData.bonus.extra
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local win_df = 0

        if extra.bonus1_win then
            win_df = extra.bonus1_win
        elseif extra.bonus2_win then
            win_df = extra.bonus2_win
        elseif extra.bonus3_win then
            win_df = extra.bonus3_win
        end
        local winCoinsBonus = win_df
        local isPlayPNC = (winCoinsBonus / lTatolBetNum) >= 15
        if isPlayPNC then
            self._npc:playBaseBigWin()
        end
        local spine = util_spineCreate("CashOrConk_qingzhu",true,true)
        util_spinePlayAction(spine, "actionframe", false,function()
            self:levelPerformWithDelay(self,0.0001,function()
                spine:removeFromParent()
            end)
            superWinFunc()
        end)
        spine:setPosition(cc.p(np1))
        self.m_bottomUI:addChild(spine,-1)
        spine:setScale(self.m_machineRootScale)
    else
        local spine = util_spineCreate("CashOrConk_bigwin",true,true)
        util_spinePlayAction(spine, "actionframe_bigwin", false,function()
            self:levelPerformWithDelay(self,0.0001,function()
                spine:removeFromParent()
            end)
            superWinFunc()
        end)
        spine:setPosition(cc.p(np1))
        self.m_bottomUI:addChild(spine,-1)
        spine:setScale(self.m_machineRootScale)
    end


    local info = {
        overCoins = self.m_llBigOrMegaNum,
        animName = "actionframe3",
        jumpTime = 0.8
    }
    self:playBottomBigWinLabAnim(info)
end


function CodeGameScreenCashOrConkMachine:cheakGameEffect(effectType)
    for i,v in ipairs(self.m_gameEffects) do
        if v.p_effectOrder == effectType then
            return true
        end
    end
end

function CodeGameScreenCashOrConkMachine:isTriggerPickPre()
    local features = self.m_runSpinResultData.p_features or {} 
    if features[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER and math.random(1,10) > 6 then
        return true
    end
end

function CodeGameScreenCashOrConkMachine:playPickPre()
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_notice)
    
    local spine = util_spineCreate("CashOrConk_yugao",true,true)
    util_spinePlayAction(spine, "actionframe_yugao", false, function()
        self:levelPerformWithDelay(spine,0.001,function()
            spine:removeFromParent()
        end)
    end)
    -- spine:setPositionY(-2)
    spine:setScaleY(1.007)
    self:findChild("Node_yugao"):addChild(spine)
end

function CodeGameScreenCashOrConkMachine:showFeatureGameTip(_fun)
    if self:isTriggerPickPre() then
        local delayTime = 90/30
        self.b_gameTipFlag = true
        self:playPickPre()
        self:levelPerformWithDelay(self, delayTime, _fun)
    else
        _fun()
    end
end

function CodeGameScreenCashOrConkMachine:levelPerformWithDelay(_parent, _time, _fun)
	if _time <= 0 then
		_fun()
		return
	end
	local waitNode = cc.Node:create()
	_parent:addChild(waitNode)
	performWithDelay(waitNode,function()
		_fun()
		waitNode:removeFromParent()
	end, _time)
	return waitNode
end

function CodeGameScreenCashOrConkMachine:clearLevelsCodeCache()
    if device.platform == "mac" and DEBUG == 2 then
        for path,v in pairs(package.loaded) do
            local modelName = self:getModuleName()
            local startIndex, endIndex = string.find(path, modelName)
            if startIndex and endIndex then
                package.loaded[path] = nil
            end
        end
    end
end

function CodeGameScreenCashOrConkMachine:updateBottomUICoins(addCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    globalData.slotRunData.lastWinCoin = 0
    local data = {
        self.m_totalWinCoin + addCoins,isNotifyUpdateTop,_bJump,self.m_totalWinCoin,
        [self.m_stopUpdateCoinsSoundIndex] = false
    }
    data[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,data)
    self.m_totalWinCoin = self.m_totalWinCoin + addCoins
end

function CodeGameScreenCashOrConkMachine:playCeleBottom()
    local eff = util_createAnimation("CashOrConk_yyqFK.csb")
    eff:playAction("actionframe",false,function()
        eff:removeFromParent()
    end)
    eff:setScale(1.1)
    local labelCoins = self.m_bottomUI.m_normalWinLabel
    local sizeLabel = labelCoins:getContentSize()
    local wp1 = labelCoins:convertToWorldSpace(cc.p(sizeLabel.width/2,sizeLabel.height/2))
    local np1 = self.m_bottomUI:convertToNodeSpace(cc.p(wp1))
    self.m_bottomUI:getCoinWinNode():addChild(eff,1)
    -- np1.y = np1.y + 10
    eff:setPosition(cc.p(10,-30))
end

function CodeGameScreenCashOrConkMachine:initSlotNodes( )
    CodeGameScreenCashOrConkMachine.super.initSlotNodes(self)

    for reelCol=2,4 do
        local targSp = self:getFixSymbol(reelCol, 2, SYMBOL_NODE_TAG)
        if targSp and targSp.p_symbolType and targSp.p_symbolType == CashOrConkDefine.bonus1 then
            targSp:runAnim("switch_"..(reelCol-1).."bonus_idleframe",true)
        end
    end

end




function CodeGameScreenCashOrConkMachine:changeSymbolType(_symbol, _symbolType)
    --移除静态图
    if _symbol.p_symbolImage then
        _symbol.p_symbolImage:removeFromParent()
        _symbol.p_symbolImage = nil
    end
    --ui切换
    local ccbName = self:getSymbolCCBNameByType(self,_symbolType)
    _symbol:changeCCBByName(ccbName, _symbolType)
    _symbol.p_showOrder  = self:getBounsScatterDataZorder(_symbolType)
    _symbol.p_symbolType = _symbolType
    --恢复静帧
    _symbol:runAnim("idleframe", false)
end

function CodeGameScreenCashOrConkMachine:checkBigWin( )
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or 
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        
        return true
    end
    return false
end

function CodeGameScreenCashOrConkMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winCoinsLine = self:getClientWinCoins()

    local bonusWin = 0
    if self.m_runSpinResultData.p_selfMakeData and
    self.m_runSpinResultData.p_selfMakeData.bonus and
    self.m_runSpinResultData.p_selfMakeData.bonus.extra and
    self.m_runSpinResultData.p_selfMakeData.bonus.extra.bonus0win then
        bonusWin = self.m_runSpinResultData.p_selfMakeData.bonus.extra.bonus0win
    end
    
    local winCoinsBonus = bonusWin - winCoinsLine

    local winCoinsPick = 0
    for i = 1,3 do
        if self.m_runSpinResultData.p_selfMakeData.bonus.extra["bonus"..i.."_win"] then
            winCoinsPick = self.m_runSpinResultData.p_selfMakeData.bonus.extra["bonus"..i.."_win"]
        end
    end

    local totalWinCoins = (winCoinsPick + winCoinsBonus + winCoinsLine)
    local isLineWinBig = (winCoinsLine / lTatolBetNum) >= self.m_BigWinLimitRate
    local isBonusWinBig = (winCoinsBonus / lTatolBetNum) >= self.m_BigWinLimitRate
    local isPickWinBig = (winCoinsPick / lTatolBetNum) >= self.m_BigWinLimitRate            
    local isTotalWinBif = (totalWinCoins / lTatolBetNum) >= self.m_BigWinLimitRate   
    
    

    local ishaveDF = self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)

    local isHaveBonus = ishaveDF or winCoinsBonus > 0

    if isHaveBonus then
        self:updateBottomUICoins(winCoinsLine,not ishabeDF,true,true)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
    end
end

function CodeGameScreenCashOrConkMachine:getShowLineWaitTime()
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
        or self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN)
        or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
        or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        return 0.5
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
        return 0.5
    end
end

function CodeGameScreenCashOrConkMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)

                    --回弹
                    local newSpeedActionTable = {}
                    for i = 1, #speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                if _slotNode.p_symbolType == CashOrConkDefine.bonus1 then
                    self._thisSpinBonusBulingCnt = self._thisSpinBonusBulingCnt + 1
                    if self._thisSpinBonusBulingCnt == 6 and not self.m_isNewReelQuickStop then
                        self._npc:playDFSpecial("0","duobonus")
                    end
                end
                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            elseif _slotNode.p_symbolType == CashOrConkDefine.bonus1 then
                _slotNode:runAnim(
                    "idleframe",
                    true
                )
            end
        end
    end
end

function CodeGameScreenCashOrConkMachine:scaleMainLayer()
    self.super.scaleMainLayer(self)
    local mainScale = self.m_machineRootScale
    if display.width / display.height <= 920/768 then
        mainScale = mainScale * 0.92
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 30 )
    elseif display.width / display.height <= 1152/768 then
        mainScale = mainScale * 0.90
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 30)
    elseif display.width / display.height <= 1228/768 then
        mainScale = mainScale * 0.90
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 30)   
    elseif display.width / display.height > 1228/768 and display.width / display.height < 1370/768 then
        mainScale = mainScale * 0.95
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 30)  
    elseif display.width / display.height < 1530/768 then
        mainScale = mainScale * 1
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 30) 
    elseif display.width / display.height < 1660/768 then
        mainScale = mainScale * 1.1
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 10)
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 30)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end

---
-- 显示五个元素在同一条线效果
function CodeGameScreenCashOrConkMachine:showEffect_FiveOfKind(effectData)

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

return CodeGameScreenCashOrConkMachine