---
-- island li
-- 2019年1月26日
-- CodeGameScreenJungleJauntMachine.lua
--
-- 玩法：
--
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local PBC = require "JungleJauntPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenJungleJauntMachine = class("CodeGameScreenJungleJauntMachine", BaseSlotoManiaMachine)

CodeGameScreenJungleJauntMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型

CodeGameScreenJungleJauntMachine.SYMBOL_BONUS_SPEC = 96 -- 特殊bonus 骰子
CodeGameScreenJungleJauntMachine.SYMBOL_BONUS_1 = 94
CodeGameScreenJungleJauntMachine.SYMBOL_BONUS_2 = 95
CodeGameScreenJungleJauntMachine.SYMBOL_BONUS_BLACK = 110

CodeGameScreenJungleJauntMachine.m_chipList = nil
CodeGameScreenJungleJauntMachine.m_playAnimIndex = 0
CodeGameScreenJungleJauntMachine.m_lightScore = 0

CodeGameScreenJungleJauntMachine.SYMBOL_JungleJaunt_9_2 = 100
CodeGameScreenJungleJauntMachine.SYMBOL_JungleJaunt_10 = 9

-- buff3 按列随机wild位置 连线前
CodeGameScreenJungleJauntMachine.BASEBUFF_EFFECT_3 = GameEffect.EFFECT_SELF_EFFECT - 99
-- buff4 任意随机wild位置 连线前
CodeGameScreenJungleJauntMachine.BASEBUFF_EFFECT_4 = GameEffect.EFFECT_SELF_EFFECT - 95

-- buff1 蝙蝠pick 连线后
CodeGameScreenJungleJauntMachine.BASEBUFF_EFFECT_1 = GameEffect.EFFECT_LINE_FRAME + 1
-- buff2 随机增长钱数 连线后
CodeGameScreenJungleJauntMachine.BASEBUFF_EFFECT_2 = GameEffect.EFFECT_LINE_FRAME + 2

-- 构造函数
function CodeGameScreenJungleJauntMachine:ctor()
    self.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("JungleJauntSrc.JungleJauntSymbolExpect", self)

    -- 引入控制插件
    self.m_longRunControl = util_createView("JungleJauntLongRunControl", self)
    -- 食人花插件
    self.m_chomperGame = util_createView("JungleJauntSrc.ChomperGame.JungleJauntChomperGameControl", self)
    -- 猴子插件
    self.m_monkeyGame = util_createView("JungleJauntSrc.MonkeyGame.JungleJauntMonkeyGameControl", self)
    -- 犀牛插件
    self.m_hippoGame = util_createView("JungleJauntSrc.HippoGame.JungleJauntHippoGameControl", self)
    -- free 小游戏插件
    self.m_freeGame = util_createView("JungleJauntSrc.freeGame.JungleJauntFreeGameControl", self)
    -- 预告中奖插件
    self.m_featureTip = util_createView("JungleJauntSrc.FeatureTip.JungleJauntFeatureTipControl", self)
    -- respin 小游戏插件
    self.m_rsEff = util_createView("JungleJauntSrc.RsReel.JungleJauntRsEffControl", self)
    
    self.m_voiceIndex = 2
    self.m_rsOutLine = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PBC
    self.m_isFeatureOverBigWinInFree = true
    self.m_roadManType = PBC.RoadManType[math.random(1,#PBC.RoadManType)]

    self.m_bulingIndex = 0
    self.m_bonusbulingIndex = 0
    self.m_hasBigSymbol = false

    --init
    self:initGame()
end

function CodeGameScreenJungleJauntMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenJungleJauntMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "JungleJaunt"
end

function CodeGameScreenJungleJauntMachine:initUI()
    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_reelStopNode = cc.Node:create()
    self:addChild(self.m_reelStopNode)

    self:findChild("Panel_StopBuff3"):setVisible(false)
    self:addClick(self:findChild("Panel_StopBuff3"))

    self:initLayerBlack()
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenJungleJauntMachine:initSpineUI()
    --free下移动bonus所用的移动层
    self.m_effectNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 1)

    self:initFreeSpinBar() -- FreeSpinbar

    --添加respin计数条
    self.m_respinBar = util_createAnimation("JungleJaunt_respin_spinbar.csb")
    self:findChild("respin_spinbar"):addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)

    --多福多彩
    self.m_colorfulGameView = util_createView("JungleJauntSrc.PickGame.JungleJauntColorfulGame", {machine = self})
    self:findChild("base_buff1"):addChild(self.m_colorfulGameView)
    self.m_colorfulGameView:setVisible(false)

    self:initJackPotBarView()

    self.m_roadMainView = util_createView("JungleJauntSrc.RoadGame.JungleJauntRoadMainView", {machine = self})
    self:findChild("jumanji"):addChild(self.m_roadMainView)


    self.m_rsTopWheelNor = util_createView("JungleJauntSrc.RsTopWheel.JungleJauntRespinTopReel",{machine = self,buffReelIndex = 1})
    self:findChild("respin_zhuanlun"):addChild(self.m_rsTopWheelNor)
    self.m_rsTopWheelNor:setVisible(false)

    self.m_rsTopWheelSpec = util_createView("JungleJauntSrc.RsTopWheel.JungleJauntRespinTopReel",{machine = self,buffReelIndex = 2})
    self:findChild("respin_zhuanlun"):addChild(self.m_rsTopWheelSpec)
    self.m_rsTopWheelSpec:setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self:findChild("free_spinbar"), true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("respin_spinbar"), true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("jumanji"), true)
    
    self.m_chomperGame:initSpineUI()
    self.m_monkeyGame:initSpineUI()
    self.m_hippoGame:initSpineUI()
end

function CodeGameScreenJungleJauntMachine:enterGamePlayMusic()
    self:delayCallBack(
        0.4,
        function()
            self:playEnterGameSound( PBC.SoundConfig.JUNGLEJAUNT_SOUND_12 )
        end
    )
end

function CodeGameScreenJungleJauntMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.super.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self.m_iBetLevel = self:updateBetLevel()
    self:changeGrandJpLockStates(true)

    --选择bet档位界面
    if self.m_isEOChooseV and PBC.isCanOpenChooseView(self) then
        self:showChooseView(true)
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeMainUI(PBC.freeId)
    else
        self:changeMainUI(PBC.baseId)
    end

    self.m_bottomUI.m_bigWinLabCsb:setPositionY(self.m_bottomUI.m_bigWinLabCsb:getPositionY() + 20)
    self.m_bottomUI.m_bigWinLabCsb:setScale(0.7)

end

function CodeGameScreenJungleJauntMachine:changeGrandJpLockStates(_noSound)
    if self.m_iBetLevel == 1 then
        if not _noSound then
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_83) 
        end
        
        gLobalNoticManager:postNotification(PBC.ObserversConfig.GrandJpUnLock)
    else
        if not _noSound then
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_82) 
        end
        gLobalNoticManager:postNotification(PBC.ObserversConfig.GrandJpLock)
    end
end

function CodeGameScreenJungleJauntMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_betGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin == nil or betCoin >= self.m_betGear then
        return 1
    else
        return 0
    end
end

function CodeGameScreenJungleJauntMachine:unlockHigherBet()
    if
        self.m_bProduceSlots_InFreeSpin == true or (self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE) or
            (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE) or
            self.m_isRunningEffect == true or
            self:getCurrSpinMode() == AUTO_SPIN_MODE
     then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_betGear then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_betGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenJungleJauntMachine:addObservers()
    self.super.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if params[self.m_stopUpdateCoinsSoundIndex] then
                -- 此时不应该播放赢钱音效
                return
            end

            if self.m_bIsBigWin then
                return
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
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 3
            elseif winRate > 6 then
                soundIndex = 3
            end

            local soundTime = soundIndex
            if self.m_bottomUI then
                soundTime = self.m_bottomUI:getCoinsShowTimes(winCoin)
            end

            local soundName = PBC.SoundConfig["JUNGLEJAUNT_SOUND_1_LINE" .. soundIndex]
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                soundName = PBC.SoundConfig["JUNGLEJAUNT_SOUND_2_LINE" .. soundIndex]
            end 
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local perBetLevel = self:updateBetLevel()
            if self.m_iBetLevel ~= perBetLevel then
                self.m_iBetLevel = perBetLevel
                self:changeGrandJpLockStates()
            end
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_roadManType = params.manType
        end,
        PBC.ObserversConfig.UpdateRoadMan
    )
end

function CodeGameScreenJungleJauntMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenJungleJauntMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS_SPEC then
        return "Socre_JungleJaunt_Bonus_1"
    elseif symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_JungleJaunt_Bonus_2"
    elseif symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_JungleJaunt_Bonus_3"
    elseif symbolType == self.SYMBOL_BONUS_BLACK then
        return "Socre_JungleJaunt_Black"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        return "Socre_JungleJaunt_9_1"
    elseif symbolType == self.SYMBOL_JungleJaunt_9_2 then
        return "Socre_JungleJaunt_9_2"
    elseif symbolType == self.SYMBOL_JungleJaunt_10 then
        return "Socre_JungleJaunt_10"

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_JungleJaunt_Scatter2"
    
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenJungleJauntMachine:getPreLoadSlotNodes()
    local loadNode = self.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenJungleJauntMachine:MachineRule_initGame()
   
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenJungleJauntMachine:MachineRule_SpinBtnCall()
    self.m_bulingIndex = 0
    self.m_bonusbulingIndex = 0
    self.m_scNum = 0
    self:showLayerBlack()
    self.m_symbolExpectCtr:MachineSpinBtnCall()

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end



--
--单列滚动停止回调
--
function CodeGameScreenJungleJauntMachine:slotOneReelDown(reelCol)
    self.super.slotOneReelDown(self, reelCol)
    self:hideLayerBlack(reelCol)
end

--
--单列滚动停止回调
--
function CodeGameScreenJungleJauntMachine:slotOneReelDownFinishCallFunc(reelCol)
    self.super.slotOneReelDownFinishCallFunc(self, reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenJungleJauntMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    self.super.slotReelDown(self)
end

---------------------------------------------------------------------------

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenJungleJauntMachine:addSelfEffect()
    --  连线后播放逻辑的 需要提前减玩法的钱数 buff1,2,5
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local game_dice = selfData.game_dice or 0
    if game_dice == 1 then
        -- buff1 蝙蝠pick 连线后
        local winCoins = self.m_runSpinResultData.p_winAmount
        local currCoins = winCoins - selfData.dice_game1_win
        self:setLastWinCoin(currCoins)

        self:addOneSelfEffect(self.BASEBUFF_EFFECT_1, self.BASEBUFF_EFFECT_1)
    elseif game_dice == 2 then
        -- buff2 随机增长钱数 连线后
        local winCoins = self.m_runSpinResultData.p_winAmount
        local currCoins = winCoins - selfData.dice_game2_win
        self:setLastWinCoin(currCoins)

        self:addOneSelfEffect(self.BASEBUFF_EFFECT_2, self.BASEBUFF_EFFECT_2)
    elseif game_dice == 3 then
        -- buff3 按列随机wild位置 连线前
        self:addOneSelfEffect(self.BASEBUFF_EFFECT_3, self.BASEBUFF_EFFECT_3)
    elseif game_dice == 4 then
        -- buff4 任意随机wild位置 连线前
        self:addOneSelfEffect(self.BASEBUFF_EFFECT_4, self.BASEBUFF_EFFECT_4)
    end
end


function CodeGameScreenJungleJauntMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    local currCoins = self.m_iOnceSpinLastWin
    local winCoins = self.m_runSpinResultData.p_winAmount
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.dice_game1_win then
        currCoins = winCoins - selfData.dice_game1_win
    end
    if selfData.dice_game2_win then
        currCoins = winCoins - selfData.dice_game2_win 
    end
     
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {currCoins, isNotifyUpdateTop,nil,0})
end

function CodeGameScreenJungleJauntMachine:playDiceSymbolRandom(_func)
    
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_91)
    
    
    if not self.m_tbTouZi then
        self.m_tbTouZi = util_createAnimation("JungleJaunt_tb_touzi.csb")
        self.m_tbTouZi.touzi1 = util_spineCreate("Socre_JungleJaunt_Bonus_1", true, true)
        self.m_tbTouZi:findChild("Node_spine"):addChild(self.m_tbTouZi.touzi1)
        self.m_tbTouZi.touzi2 = util_spineCreate("Socre_JungleJaunt_Bonus_1_2", true, true)
        self.m_tbTouZi:findChild("Node_spine"):addChild(self.m_tbTouZi.touzi2, -1)
        self:findChild("tb_touzi"):addChild(self.m_tbTouZi)
        util_setCascadeOpacityEnabledRescursion(self.m_tbTouZi, true)
        self.m_tbTouZi:findChild("tbTouZiClick"):setVisible(false)
        self:addClick(self.m_tbTouZi:findChild("tbTouZiClick"))

    end

    self.m_tbTouZi:setVisible(true)

    local totalNum = self.m_roadMainView:getAddNum()

    if totalNum > 12 then
        util_logDevAssert("移动的总次数错了")
    end

    local t1num = 1
    local t2num = 1
    if totalNum > 6 then
        if totalNum == 12 then
            t1num = 6
            t2num = 6
        else
            local index = 1
            while true do
                index = index + 1
                t1num = math.random(1,6)
                t2num = math.random(1,6)
                if totalNum == (t1num + t2num) then
                    break
                end
                if index >= 999999 then
                    t1num = 6
                    t2num = totalNum - t1num
                    break
                end
            end
        end
    elseif totalNum == 4 then
        local rod = math.random(1, 2)
        if rod == 1 then
            t1num = 1
        else
            t1num = 3
        end
        t2num = totalNum - t1num
    else
        t1num = math.random(1, totalNum - 1)
        t2num = totalNum - t1num
    end

    
    if t1num > 6  then
        util_logDevAssert("随机错了 t1num > 6 ")
    end
    if t2num > 6  then
        util_logDevAssert("随机错了t2num > 6")
    end
    if t1num <= 0 then
        util_logDevAssert("随机错了 t1num <= 0 ")
    end
    if t2num <= 0  then
        util_logDevAssert("随机错了t2num <= 0")
    end
    self.m_tbTouZiEndFunc = function()

        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_14)
        
        self.m_tbTouZi:findChild("tbTouZiClick"):stopAllActions()
        self.m_tbTouZi:findChild("tbTouZiClick"):setVisible(false)
        self.m_tbTouZi:runCsbAction("idle", true)

        self.m_tbTouZi.touzi1:stopAllActions()
        self.m_tbTouZi.touzi2:stopAllActions()
        self.m_tbTouZi.touzi1:resetAnimation()
        self.m_tbTouZi.touzi2:resetAnimation()

        util_spinePlay(self.m_tbTouZi.touzi1, "1_" .. t1num)
        performWithDelay(
            self.m_tbTouZi:findChild("tbTouZiClick"),
            function()
                util_spinePlay(self.m_tbTouZi.touzi2, "1_" .. t2num)
                util_spineEndCallFunc(
                    self.m_tbTouZi.touzi2,
                    "1_" .. t2num,
                    function()
                        performWithDelay(
                            self.m_tbTouZi:findChild("tbTouZiClick"),
                            function()

                                util_playFadeOutAction(self.m_roadMainView.m_midTipImg,0.2,function()
                                    self.m_roadMainView.m_midTipImg:setVisible(false)
                                end)

                                self.m_tbTouZi:runCsbAction(
                                    "over",
                                    false,
                                    function()
                                        self.m_tbTouZi:setVisible(false)
                                        -- 更新本地棋子位置信息 在函数内
                                        -- 动物开跑 🏃🏻‍♀️ go!go!go!
                                        self.m_roadMainView:playManRunAnim(
                                            totalNum,
                                            function()
                                                if _func then
                                                    _func()
                                                end
                                            end
                                        )
                                    end
                                )
                            end,
                            1.3
                        )
                    end
                )
            end,
            3 / 30
        )
    end

    util_spinePlay(self.m_tbTouZi.touzi1, "start")
    util_spinePlay(self.m_tbTouZi.touzi2, "start")
    util_spineEndCallFunc(self.m_tbTouZi.touzi2, "start",function()
        util_spinePlay(self.m_tbTouZi.touzi1, "idle7", true)
        util_spinePlay(self.m_tbTouZi.touzi2, "idle7", true)
    end)
    self.m_tbTouZi:findChild("tbTouZiClick"):setVisible(false)
    self.m_tbTouZi:runCsbAction(
        "start",
        false,
        function()
            self:addClick(self.m_tbTouZi:findChild("tbTouZiClick"))
            self.m_tbTouZi:findChild("tbTouZiClick"):setVisible(false)
            performWithDelay(self.m_tbTouZi:findChild("tbTouZiClick"),function()
                self.m_tbTouZi:findChild("tbTouZiClick"):setVisible(true)
                performWithDelay(self.m_tbTouZi:findChild("tbTouZiClick"),function()
                    if self.m_tbTouZiEndFunc then
                        self.m_tbTouZiEndFunc()
                        self.m_tbTouZiEndFunc = nil
                    end
                end,2)
            end,1)
            
            
        end
    )
end

function CodeGameScreenJungleJauntMachine:playDiceSymbolTriggerAinm(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_13)
    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local waitTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode then
                if symbolNode.p_symbolType == self.SYMBOL_BONUS_SPEC then
                    local oldZOrder = symbolNode:getLocalZOrder()
                    symbolNode:runAnim(
                        "actionframe",
                        false,
                        function()
                            symbolNode:setLocalZOrder(oldZOrder)
                        end
                    )
                    symbolNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE + oldZOrder)
                    local duration = symbolNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime, duration)
                end
            end
        end
    end

    performWithDelay(
        self,
        function()
            self:playDiceSymbolRandom(
                function()
                    self.m_roadMainView:playMidTipStartAinm(
                        function()
                            if _func then
                                _func()
                            end
                        end
                    )
                end
            )
        end,
        waitTime
    )
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenJungleJauntMachine:MachineRule_playSelfEffect(effectData)

    if self.m_voiceIndex == 2 then
        self.m_voiceIndex = 1
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_88) 
    else
        self.m_voiceIndex = 2
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_89) 
    end
    self:removeSoundHandler() -- 移除监听

    if effectData.p_selfEffectType == self.BASEBUFF_EFFECT_1 then
        -- buff1 蝙蝠pick 连线后
        local waitTime = 0
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local winCoins = self.m_runSpinResultData.p_winAmount
        local currCoins = winCoins - selfData.dice_game1_win
        if currCoins > 0 then
            waitTime = self.m_changeLineFrameTime
        end

        performWithDelay(
            self,
            function()
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
                self.m_roadMainView:setMidTipImg(1)
                self:playDiceSymbolTriggerAinm(
                    function()
                        self:playEffectBuff1(
                            function()
                                self.m_roadMainView.m_midTipImg:setVisible(true)
                                util_playFadeInAction(self.m_roadMainView.m_midTipImg,0.2)
                                
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        )
                    end
                )
            end,
            waitTime
        )
    elseif effectData.p_selfEffectType == self.BASEBUFF_EFFECT_2 then
        -- buff2 随机增长钱数 连线后

        local waitTime = 0
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local winCoins = self.m_runSpinResultData.p_winAmount
        local currCoins = winCoins - selfData.dice_game2_win
        if currCoins > 0 then
            waitTime = self.m_changeLineFrameTime
        end

        performWithDelay(
            self,
            function()
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
                self.m_roadMainView:setMidTipImg(2)
                self:playDiceSymbolTriggerAinm(
                    function()
                        self:playEffectBuff2(
                            function()
                                self.m_roadMainView.m_midTipImg:setVisible(true)
                                util_playFadeInAction(self.m_roadMainView.m_midTipImg,0.2)

                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        )
                    end
                )
            end,
            waitTime
        )
    elseif effectData.p_selfEffectType == self.BASEBUFF_EFFECT_3 then
        -- buff3 按列随机wild位置 连线前
        self.m_roadMainView:setMidTipImg(3)
        self:playDiceSymbolTriggerAinm(
            function()
                self:playEffectBuff3(
                    function()
                        self.m_roadMainView.m_midTipImg:setVisible(true)
                        util_playFadeInAction(self.m_roadMainView.m_midTipImg,0.2)

                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            end
        )
    elseif effectData.p_selfEffectType == self.BASEBUFF_EFFECT_4 then
        -- buff4 任意随机wild位置 连线前
        self.m_roadMainView:setMidTipImg(4)
        self:playDiceSymbolTriggerAinm(
            function()
                self:playEffectBuff4(
                    function()
                        self.m_roadMainView.m_midTipImg:setVisible(true)
                        util_playFadeInAction(self.m_roadMainView.m_midTipImg,0.2)

                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            end
        )
    end
    return true
end

-- buff1 蝙蝠pick 连线后
function CodeGameScreenJungleJauntMachine:playEffectBuff1(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local dice_game1_list = selfData.dice_game1_list

    local dCurFunc = function()
        self.m_colorfulGameView:runCsbAction("idleHide")
        self.m_colorfulGameView:setVisible(true)
        self.m_roadMainView:findChild("Node_road"):setVisible(false)
        self.m_colorfulGameView:resetView(
            dice_game1_list,
            function()
                self.m_roadMainView:playDoorAnimClose(
                    function()
                        self.m_roadMainView:findChild("Node_road"):setVisible(true)
                        self.m_colorfulGameView:setVisible(false)
                    end,
                    function()
                        if _func then
                            _func()
                        end
                    end
                )
            end
        )
        self:runCsbAction(
            "start",
            false,
            function()
                self:runCsbAction("idle", true)
            end
        )
        self.m_colorfulGameView:showView()

    end
    local dEndfunc = function()
        
    end
    self.m_roadMainView:playDoorAnimClose(dCurFunc, dEndfunc)
end

-- buff2 随机增长钱数 连线后
function CodeGameScreenJungleJauntMachine:playEffectBuff2(_func)
    self.m_chomperGame:playChomperGameStart(
        function()
            if _func then
                _func()
            end
        end
    )
end
-- buff3 按列随机wild位置 连线前
function CodeGameScreenJungleJauntMachine:playEffectBuff3(_func)
    self.m_monkeyGame:playMonkeyGameStart(
        function()
            if _func then
                _func()
            end
        end
    )
end
-- buff4 任意随机wild位置 连线前
function CodeGameScreenJungleJauntMachine:playEffectBuff4(_func)
    self.m_hippoGame:playMonkeyGameStart(
        function()
            if _func then
                _func()
            end
        end
    )
end

function CodeGameScreenJungleJauntMachine:playEffectNotifyNextSpinCall()
    self.super.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

-- free和freeMore特殊需求
function CodeGameScreenJungleJauntMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        else
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        end
    end
end

-- 不用系统音效
function CodeGameScreenJungleJauntMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        self.super.checkSymbolTypePlayTipAnima(self, symbolType)
    end

    return false
end

function CodeGameScreenJungleJauntMachine:checkRemoveBigMegaEffect()
    self.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenJungleJauntMachine:getShowLineWaitTime()
    local time = self.super.getShowLineWaitTime(self)
    local winLines = self.m_reelResultLines or {}
    local lineValue = winLines[1] or {}
    if #winLines == 1 and lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        time = 0
    end
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------

function CodeGameScreenJungleJauntMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("JungleJauntSrc.JungleJauntFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("free_spinbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点
end

function CodeGameScreenJungleJauntMachine:showFreeSpinMore(num, func, isAuto)
    local view = self.super.showFreeSpinMore(self, num, func, isAuto)

    local scatter = util_spineCreate("Socre_JungleJaunt_Scatter2", true, true)
    view:findChild("Node_9"):addChild(scatter,-1)
    util_spinePlay(scatter, "tanban_start")
    util_spineEndCallFunc(
        scatter,
        "tanban_start",
        function()
            util_spinePlay(scatter, "tanban_idle")
        end
    )

    local shuzi = util_createAnimation("JungleJaunt/FreeSpin_shuzi.csb")
    shuzi:findChild("m_lb_num"):setString(num)
    shuzi:updateLabelSize({label = shuzi:findChild("m_lb_num"), sx = 1, sy = 1}, 346)  

    util_spinePushBindNode(scatter, "shuzi", shuzi)
    view:findChild("root1"):setScale(self.m_machineRootScale)
    util_setCascadeOpacityEnabledRescursion(view, true)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5)
    end)

    return view
end

function CodeGameScreenJungleJauntMachine:showFreeSpinStart(num, func, isAuto)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_43)

    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, {}, func, BaseDialog.AUTO_TYPE_ONLY)

    local scatter = util_spineCreate("Socre_JungleJaunt_Scatter2", true, true)
    view:findChild("Node_spine"):addChild(scatter)
    util_spinePlay(scatter, "tanban_start")
    util_spineEndCallFunc(
        scatter,
        "tanban_start",
        function()
            util_spinePlay(scatter, "tanban_idle")
        end
    )

    local shuzi = util_createAnimation("JungleJaunt/FreeSpin_shuzi.csb")
    shuzi:findChild("m_lb_num"):setString(num)
    shuzi:updateLabelSize({label = shuzi:findChild("m_lb_num"), sx = 1, sy = 1}, 346)  
    util_spinePushBindNode(scatter, "shuzi", shuzi)

    view:findChild("root1"):setScale(self.m_machineRootScale)
    util_setCascadeOpacityEnabledRescursion(view, true)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5)
    end)

    return view
end

function CodeGameScreenJungleJauntMachine:showFreeSpinView(effectData)


    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_62)  
            local view =
                self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_63)  
                    self.m_baseFreeSpinBar:runCsbAction("switch")

                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            local view =
                self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_44)
                    self:showFreeGuoChang(
                        function()
                            self:changeMainUI(PBC.freeId)
                            self:triggerFreeSpinCallFun()
                        end,
                        function()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end
            )
        end
    end

    self:delayCallBack(
        0.5,
        function()
            showFSView()
        end
    )
end

function CodeGameScreenJungleJauntMachine:showFreeSpinOverView(effectData)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_58) 
    local overFunc = function()
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_60)
        self:showFreeGuoChang(
            function()
                self.m_effectNode:removeAllChildren()
                self:changeMainUI(PBC.baseId)
                self.m_baseFreeSpinBar:setVisible(false)
            end,
            function()
                self:triggerFreeSpinOverCallFun()
            end
        )
    end

    if globalData.slotRunData.lastWinCoin > 0 then
        local strCoins = util_formatCoinsLN(globalData.slotRunData.lastWinCoin, 30)
        local view =
            self:showFreeSpinOver(
            strCoins,
            self.m_runSpinResultData.p_freeSpinsTotalCount,
            function()
                overFunc()
            end
        )
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 656)
        view:findChild("root1"):setScale(self.m_machineRootScale)

        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5)
        end)

        local glow = util_createAnimation("JungleJaunt/jungleJaunt_tb_glow.csb")
        view:findChild("Node_glow"):addChild(glow)
        glow:runCsbAction("idle", true)
        view:setOverAniRunFunc(function()
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_59) 
        end)
    else
        local view =
            self:showFreeSpinOverNoWin(
            function()
                overFunc()
            end
        )
        view:findChild("root1"):setScale(self.m_machineRootScale)
        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5)
        end)
        view:setOverAniRunFunc(function()
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_59) 
        end)
    end
end

function CodeGameScreenJungleJauntMachine:showFreeSpinOverNoWin(func)
    self:clearCurMusicBg()
    local ownerlist = {}
    return self:showDialog("FeatureOver", ownerlist, func)
end

function CodeGameScreenJungleJauntMachine:playScatterOpen(_func)
    performWithDelay(
        self,
        function()
            local waitTime = 0
            local num = 0

           

            for iCol = 1, self.m_iReelColumnNum do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if symbolNode then
                        local duration = symbolNode:getAniamDurationByName("open")
                        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            self:setScatterNode(symbolNode)
                            local parent = symbolNode:getParent()
                            if parent ~= self.m_clipParent then
                                symbolNode = util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER, 0)
                            end

                            local cutTime = num * duration
                            performWithDelay(
                                symbolNode,
                                function()
                                    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_41)
                                    local symbol_node = symbolNode:checkLoadCCbNode()
                                    local spineNode = symbol_node:getCsbAct()
                                    spineNode.m_nodeNum:setVisible(true)
                                    symbolNode:runAnim("open")
                                end,
                                cutTime
                            )
                            num = num + 1
                            waitTime = num * duration
                        end
                    end
                end
            end

            performWithDelay(
                self,
                function()
                    if _func then
                        _func()
                    end
                end,
                waitTime
            )
        end,
        0.3
    )
end

function CodeGameScreenJungleJauntMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end


    self:playScatterOpen(
        function()
            local waitTime = 0
            if scatterLineValue ~= nil then
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    self.m_ScatterTipMusicPath = PBC.SoundConfig.JUNGLEJAUNT_SOUND_61
                else
                    self.m_ScatterTipMusicPath = PBC.SoundConfig.JUNGLEJAUNT_SOUND_42
                    
                end

                if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                    -- 停掉背景音乐
                    self:clearCurMusicBg()
                    -- freeMore时不播放
                    self:levelDeviceVibrate(6, "free")
                end
                
                -- 播放提示时播放音效
                self:playScatterTipMusicEffect()
                local frameNum = #scatterLineValue.vecValidMatrixSymPos
                for i = 1, frameNum do
                    local symPosData = scatterLineValue.vecValidMatrixSymPos[i]
                    local slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    if slotNode then
                        local parent = slotNode:getParent()
                        if parent ~= self.m_clipParent then
                            slotNode = util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, scatterLineValue.enumSymbolType, 0)
                        end
                        slotNode:runAnim(
                            "win",
                            false,
                            function()
                                slotNode:runAnim("idleframe4", true)
                            end
                        )
                        local duration = slotNode:getAniamDurationByName("win")
                        waitTime = util_max(waitTime, duration)
                    end
                end
                scatterLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
            else
                if device.platform == "mac" then
                    assert(false, "服务器没给连线数据")
                end
            end
            performWithDelay(
                self,
                function()
                    self:showFreeSpinView(effectData)
                end,
                waitTime
            )
            gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
        end
    )

    return true
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenJungleJauntMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        return
    end
    self.super.showLineFrameByIndex(self, winLines, frameIndex)
end

---
-- 显示所有的连线框
--
function CodeGameScreenJungleJauntMachine:showAllFrame(winLines)
    local tempLineValue = {}
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN then
            table.insert(tempLineValue, lineValue)
        end
    end
    self.super.showAllFrame(self, tempLineValue)
end

-- 继承底层respinView
function CodeGameScreenJungleJauntMachine:getRespinView()
    return "JungleJauntSrc.RsReel.JungleJauntRespinView"
end

-- 继承底层respinNode
function CodeGameScreenJungleJauntMachine:getRespinNode()
    return "JungleJauntSrc.RsReel.JungleJauntRespinNode"
end

function CodeGameScreenJungleJauntMachine:updateBonus3JpVisble(id,node)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    --  respin 过程中当中 bonus添加钱玩法时 需要减去因为服务器将结果加上了
    -- 普通 buff1，buff5
    -- 特殊 buff1
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}

    local rsStoredIcons = nil
    if self:getCurrSpinMode() == RESPIN_MODE then
        -- rsStoredIcons = rsExtraData.storedIcons
    end
    
    local storedIcons = rsStoredIcons or self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil
    local typeNode = nil
    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[3]
            idNode = values[1]
            typeNode = values[4]
            break
        end
    end

    -- 使用node作为区分
    -- 需要根据情况和数据，处理特殊JPbonus：刚触发时是钱，断线进来直接是对应JP
    if node and typeNode and (typeNode == "grand" or typeNode == "mega" or typeNode == "major" or typeNode == "minor" or typeNode == "mini") then
        if self:checkJpBonus2(node) then -- 必须是已经变成jpUI的状态才行
            -- 断线进来那就应该直接显示为JP并固定在棋盘
            local mType = PBC.Bonus3MType[typeNode]
            local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {} 
            local respinkind = rsExtraData.addcredit or {}
            local addCoins = respinkind[idNode + 1] or 0
            if addCoins > 0  then
                mType = PBC.Bonus3MType[typeNode .. "AddCoins"]
            end
            self:setBonus3Type(mType, node) 
            return mType,addCoins
        end
        
    end
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenJungleJauntMachine:getReSpinSymbolScore(id,node)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    --  respin 过程中当中 bonus添加钱玩法时 需要减去因为服务器将结果加上了
    -- 普通 buff1，buff5
    -- 特殊 buff1
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local rsStoredIcons = nil
    if self:getCurrSpinMode() == RESPIN_MODE then
        -- rsStoredIcons = rsExtraData.storedIcons
    end
    local storedIcons = rsStoredIcons or self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil
    local typeNode = nil
    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[3]
            idNode = values[1]
            typeNode = values[4]
            break
        end
    end

    -- 使用node作为区分
    -- 需要根据情况和数据，处理特殊JPbonus：刚触发时是钱，断线进来直接是对应JP
    if node and typeNode and (typeNode == "grand" or typeNode == "mega" or typeNode == "major" or typeNode == "minor" or typeNode == "mini")  then
        if not self.m_rsOutLine then
            -- 正常玩时出现，那就应该是用服务器专门给的钱然后变成JP
            local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {} 
            local jackpotReplaceIcons = rsExtraData.jackpotReplaceIcons or {}
            for i = 1, #jackpotReplaceIcons do
                local values = jackpotReplaceIcons[i]
                if values[1] == id then
                    score = values[3]
                    break
                end
            end
            -- score = self:randomDownRespinSymbolScore(node.p_symbolType)
        else
            -- 断线进来那就应该直接显示为JP并固定在棋盘
            local mType = PBC.Bonus3MType[typeNode]
            local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {} 
            local respinkind = rsExtraData.addcredit or {}
            local addCoins = respinkind[idNode + 1] or 0
            if addCoins > 0 then
                mType = PBC.Bonus3MType[typeNode .. "AddCoins"]
            end
            local symbol_node = node:checkLoadCCbNode()
            local spineNode = symbol_node:getCsbAct()
            local nodeScore = spineNode.m_nodeScore
            self:setBonus3Type(mType, nodeScore)
            score = addCoins
        end 
    end


    if node and not self.m_rsOutLine then
        -- 需要根据当前玩法；处理一下算钱，把钱先减去
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData
        local wheelkinds = rsExtraData.wheelkinds or {}
        for i=1,#wheelkinds do
            local wheelkind = wheelkinds[i]
            if wheelkind[2] == PBC.RS_GAME_BASE_TYPE.randomMul then
                local posIndexs = wheelkind[4] or {}
                for index=1,#posIndexs do
                    if idNode == posIndexs[index] then
                        score = score / wheelkind[3]
                    end
                end
            end
            if wheelkind[2] == PBC.RS_GAME_BASE_TYPE.addCoins then
                score = score - wheelkind[3]
            end
        end
        
        local specialwheelkinds = rsExtraData.specialwheelkinds or {}
        for i=1,#specialwheelkinds do
            local specialwheelkind = specialwheelkinds[i]
            if idNode == specialwheelkind[1] then
                if specialwheelkind[2] == PBC.RS_GAME_SPEC_TYPE.randomMul then
                    score = score / specialwheelkind[3]
                end
            end
            
        end
    end

    if not score then
        util_logDevAssert("小块上不可能获取不到赢钱") 
    end

    -- 最终结算时做的操作，懒得搞了，简单判断一下吧
    if not node and typeNode and (typeNode == "grand" or typeNode == "mega" or typeNode == "major" or typeNode == "minor" or typeNode == "mini") then
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {} 
        local respinkind = rsExtraData.addcredit or {}
        local addCoins = respinkind[idNode + 1] or 0
        return typeNode , addCoins
    end
    return score
end

function CodeGameScreenJungleJauntMachine:getMachineConfigParseLuaName()
    return "LevelJungleJauntConfig.lua"
end

function CodeGameScreenJungleJauntMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_BONUS_1 then
        score = self.m_configData:getBonus1FixSymbolPro()
    elseif symbolType == self.SYMBOL_BONUS_2 then
        score = self.m_configData:getBonus2FixSymbolPro()
    end
    return score
end

function CodeGameScreenJungleJauntMachine:checkJpBonus2(_node)
    if _node.mType == PBC.Bonus3MType.grand then
        return PBC.Bonus3MType.grand
    
    elseif _node.mType == PBC.Bonus3MType.mega then
        return PBC.Bonus3MType.mega
    
    elseif _node.mType == PBC.Bonus3MType.major then
        return PBC.Bonus3MType.major
    
    elseif _node.mType == PBC.Bonus3MType.minor then
        return PBC.Bonus3MType.minor
    
    elseif _node.mType == PBC.Bonus3MType.mini then
        return PBC.Bonus3MType.mini
    end
    return false
end

function CodeGameScreenJungleJauntMachine:setBonus3Type(_mType, _node)
    _node:findChild("wenzi_grand"):setVisible(_mType == PBC.Bonus3MType.grand or _mType == PBC.Bonus3MType.grandAddCoins)
    _node:findChild("wenzi_mega"):setVisible(_mType == PBC.Bonus3MType.mega or _mType == PBC.Bonus3MType.megaAddCoins)
    _node:findChild("wenzi_major"):setVisible(_mType == PBC.Bonus3MType.major or _mType == PBC.Bonus3MType.majorAddCoins)
    _node:findChild("wenzi_minor"):setVisible(_mType == PBC.Bonus3MType.minor or _mType == PBC.Bonus3MType.minorAddCoins)
    _node:findChild("wenzi_mini"):setVisible(_mType == PBC.Bonus3MType.mini or _mType == PBC.Bonus3MType.miniAddCoins)
    _node:findChild("jiahao"):setVisible(false)
    _node:findChild("m_lb_coins"):setVisible(false)
    _node:runCsbAction("idleframe")
    if _mType == PBC.Bonus3MType.norCoins then
        _node:findChild("m_lb_coins"):setVisible(true)
    elseif _mType == PBC.Bonus3MType.addCoins then
        _node:findChild("m_lb_coins"):setVisible(true)
        _node:findChild("jiahao"):setVisible(true)
    elseif _mType == PBC.Bonus3MType.grandAddCoins or 
            _mType == PBC.Bonus3MType.megaAddCoins or 
                _mType == PBC.Bonus3MType.majorAddCoins or 
                    _mType == PBC.Bonus3MType.minorAddCoins or 
                        _mType == PBC.Bonus3MType.miniAddCoins  then
        _node:findChild("m_lb_coins"):setVisible(true)
        _node:findChild("jiahao"):setVisible(true)
        _node:runCsbAction("idleframe2")
    end
    _node.mType = _mType
end

function CodeGameScreenJungleJauntMachine:createBonusLab(_symbolType, _spineNode)
    local nodeScore = nil
    local mType = nil
    if _symbolType == self.SYMBOL_BONUS_1 then
        nodeScore = util_createAnimation("Socre_JungleJaunt_Bonus_2_info.csb")
        nodeScore:runCsbAction("idleframe",true)
    else
        nodeScore = util_createAnimation("Socre_JungleJaunt_Bonus_3_info.csb")
        mType = PBC.Bonus3MType.norCoins
        self:setBonus3Type(mType, nodeScore)
    end
    nodeScore:setPosition(cc.p(0, 0))
    util_spinePushBindNode(_spineNode, "shuzi", nodeScore)
    
    return nodeScore
end

-- 给respin小块进行赋值
function CodeGameScreenJungleJauntMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local symbolType = symbolNode.p_symbolType

    symbolNode:runAnim("idleframe2", true)

    -- 添加Bonus挂数字
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeScore = nil
    if not tolua.isnull(spineNode.m_nodeScore) then
        nodeScore = spineNode.m_nodeScore
        nodeScore:runCsbAction("idleframe",true)
        if symbolType == self.SYMBOL_BONUS_2 then
            local mType = PBC.Bonus3MType.norCoins
            self:setBonus3Type(mType, nodeScore)
        end
        nodeScore:setPosition(cc.p(0, 0))
        nodeScore.score = 0
    else
        spineNode.m_nodeScore = self:createBonusLab(symbolType, spineNode)
        nodeScore = spineNode.m_nodeScore
        nodeScore.score = 0
    end

    
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol),symbolNode) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()
            nodeScore.score = score * lineBet
            score = util_formatCoinsLN(nodeScore.score, 3)
            nodeScore:findChild("m_lb_coins"):setString(score)
            nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolType then
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                if score == nil then
                    score = 1
                end
                nodeScore.score = score * lineBet
                score = util_formatCoinsLN(nodeScore.score, 3)
                nodeScore:findChild("m_lb_coins"):setString(score)
                nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)
                nodeScore.score = 0
            end
        end
    end
end

function CodeGameScreenJungleJauntMachine:removeScoreNode(_symbolNode)
    local symbolNode = _symbolNode
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if spineNode and spineNode.m_nodeScore then
        local nodeScore = spineNode.m_nodeScore
        util_spineRemoveBindNode(spineNode, nodeScore)
    end
end

function CodeGameScreenJungleJauntMachine:setScatterNode(symbolNode)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    symbolNode:runAnim("idleframe2", true)
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    local nodeNum = nil
    if not tolua.isnull(spineNode.m_nodeNum) then
        nodeNum = spineNode.m_nodeNum
    else
        nodeNum = util_createAnimation("Socre_JungleJaunt_Scatter_info.csb")
        nodeNum:setPosition(cc.p(0, 0))
        util_spinePushBindNode(spineNode, "shuzi", nodeNum)
        spineNode.m_nodeNum = nodeNum
    end
    nodeNum:setVisible(false)
    nodeNum:findChild("m_lb_num"):setString("")
    if iRow and iRow <= self.m_iReelRowNum and iCol and symbolNode.m_isLastSymbol then
        local num = 0
        local nodePosIndex = self:getPosReelIdx(iRow, iCol)
        local sc_icons = selfData.sc_icons or {}
        for index = 1, #sc_icons do
            local infos = sc_icons[index]
            if nodePosIndex == infos[2] then
                num = infos[3]
                break
            end
        end

        if num ~= 0 then
            nodeNum:findChild("m_lb_num"):setString(num)
        end
    end
end
function CodeGameScreenJungleJauntMachine:updateReelGridNode(symbolNode)
    local symbolType = symbolNode.p_symbolType
    if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 then
        self:setSpecialNodeScore(self, {symbolNode})
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        symbolNode.p_idleIsLoop = true
        symbolNode.m_idleAnimName = "idleframe2"
        self:setScatterNode(symbolNode)
    end
end

-- 是不是 respinBonus小块
function CodeGameScreenJungleJauntMachine:isNorBonusSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 then
        return true
    end
    return false
end


-- 结束respin收集
function CodeGameScreenJungleJauntMachine:playLightEffectEnd()

    performWithDelay(self,function()
        self:showRespinOverView()
    end,0.5)

    
end

function CodeGameScreenJungleJauntMachine:getJackpotScore(_jpName)
    local jackpotCoinData = self.m_runSpinResultData.p_jackpotCoins or {}
    local coins = jackpotCoinData[_jpName]
    return coins
end

function CodeGameScreenJungleJauntMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
        local rows = rsExtraData.rows or 4
        if #self.m_chipList >= (rows * self.m_iReelColumnNum) then
            -- 如果全部都固定了，会中JackPot档位中的Grand
            local jackpotScore = self:getJackpotScore("Grand")
            self.m_lightScore = self.m_lightScore + jackpotScore
            local currCoins = self.m_lightScore

            self:showJackpotView(jackpotScore, "grand", function()
                gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_55)   
                self:playCoinWinEffectUI(jackpotScore)
                self:setLastWinCoin(currCoins)
                local params = {jackpotScore, true, false}
                params[self.m_stopUpdateCoinsSoundIndex] = true
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(currCoins))
                self:playLightEffectEnd()
            end)
        else
            self:playLightEffectEnd()
        end
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(), chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol

    -- 根据网络数据获得当前固定小块的分数
    local score,addCoins = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()

    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "grand" then
            jackpotScore = self:getJackpotScore("Grand")
            addScore = jackpotScore --+ addCoins * lineBet
            nJackpotType = "grand"
        elseif score == "mega" then
            jackpotScore = self:getJackpotScore("Mega")
            addScore = jackpotScore --+ addCoins * lineBet
            nJackpotType = "mega"
        elseif score == "major" then
            jackpotScore = self:getJackpotScore("Major")
            addScore = jackpotScore --+ addCoins * lineBet
            nJackpotType = "major"
        elseif score == "minor" then
            jackpotScore = self:getJackpotScore("Minor")
            addScore = jackpotScore --+ addCoins * lineBet
            nJackpotType = "minor"
        elseif score == "mini" then
            jackpotScore = self:getJackpotScore("Mini")
            addScore = jackpotScore --+ addCoins * lineBet
            nJackpotType = "mini"
        end
    end

    -- 已兼容FREE下的赢钱显示 利用 m_lastReSpinWinCoins 统一处理
    self.m_lightScore = self.m_lightScore + addScore
    local currCoins = self.m_lightScore
    local function runCollect()

        if type(nJackpotType) == "number" then
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_55) 
            self:playCoinWinEffectUI(addScore)
            self:setLastWinCoin(currCoins)
            local params = {addScore, true, false}
            params[self.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(currCoins))
            
            performWithDelay(self,function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim()
            end,0.4)
            
        else

            self:showJackpotView(addScore, nJackpotType, function()
                gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_55) 
                    -- jp图标当有 钱+jp 的表现方式时，目前的做法是直接弹板的钱是总钱=钱+jp
                    self:playCoinWinEffectUI(addScore)
                    self:setLastWinCoin(currCoins)

                    local params = {addScore, true, false}
                    params[self.m_stopUpdateCoinsSoundIndex] = true
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
    
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(currCoins))

                    performWithDelay(self,function()
                        self.m_playAnimIndex = self.m_playAnimIndex + 1
                        self:playChipCollectAnim()
                    end,0.4)
                end
            )
        end
    end
    runCollect()
    chipNode:runAnim("jiesuan")

    local symbolNode = chipNode
    local symbol_node = symbolNode:checkLoadCCbNode()
    local spineNode = symbol_node:getCsbAct()
    if not tolua.isnull(spineNode.m_nodeScore) then
        if symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
            spineNode.m_nodeScore:runCsbAction("darkstart1")
            if spineNode.m_nodeScore.mType == PBC.Bonus3MType.norCoins then
                spineNode.m_nodeScore:runCsbAction("darkstart1")
            elseif spineNode.m_nodeScore.mType == PBC.Bonus3MType.addCoins then
                spineNode.m_nodeScore:runCsbAction("darkstart1")
            elseif
                spineNode.m_nodeScore.mType == PBC.Bonus3MType.grandAddCoins or 
                spineNode.m_nodeScore.mType == PBC.Bonus3MType.megaAddCoins or 
                spineNode.m_nodeScore.mType == PBC.Bonus3MType.majorAddCoins or
                spineNode.m_nodeScore.mType == PBC.Bonus3MType.minorAddCoins or
                spineNode.m_nodeScore.mType == PBC.Bonus3MType.miniAddCoins
            then
                spineNode.m_nodeScore:runCsbAction("darkstart2")
            end
        else
            spineNode.m_nodeScore:runCsbAction("darkstart")
        end
    end
     
end

--结束移除小块调用结算特效
function CodeGameScreenJungleJauntMachine:reSpinEndAction()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    for i=1,#self.m_respinView.m_lockFrames do
        local lockFrames = self.m_respinView.m_lockFrames[i]
        util_playFadeOutAction(lockFrames,0.2,function()
            lockFrames:setVisible(false)
            util_playFadeInAction(lockFrames,0.1)
        end)
        util_playFadeOutAction(lockFrames.bg,0.2,function()
            lockFrames.bg:setVisible(false) 
            util_playFadeInAction(lockFrames.bg,0.1)
        end)
    end
    

    self.m_lightScore = self.m_lastReSpinWinCoins
    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    performWithDelay(self,function()
        self:playChipCollectAnim()
    end,1.5)
    
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenJungleJauntMachine:getRespinRandomTypes()
    local symbolList = {
        self.SYMBOL_BONUS_BLACK
    }
    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenJungleJauntMachine:getRespinLockTypes()
    local symbolList = {{type = self.SYMBOL_BONUS_1, runEndAnimaName = "buling", bRandom = true,runIdleAnimaName = "idleframe2"}}
    -- 触发时有bonus2 才能滚bonus2 
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {} 
    local respinkind = rsExtraData.respinkind
    if respinkind == "special" then
        symbolList[#symbolList+1] = {type = self.SYMBOL_BONUS_2, runEndAnimaName = "buling", bRandom = true,runIdleAnimaName = "idleframe2"} 
    end  
    return symbolList
end

function CodeGameScreenJungleJauntMachine:respinChangeReelGridCount(count)
    for i = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end

function CodeGameScreenJungleJauntMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(7, 5, TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function CodeGameScreenJungleJauntMachine:reSpinReelDown(addNode)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self.m_rsEff:playEffStart(function()
        self.super.reSpinReelDown(self,addNode)
    end)
   
end

function CodeGameScreenJungleJauntMachine:outLinesInRs()

    self:changeMainUI(PBC.rsId)
    
    self.m_iReelRowNum = 7
    self:respinChangeReelGridCount(self.m_iReelRowNum)
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()
    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()
    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)
    self.m_respinView:initRsBg()
    self.m_respinView:initSpecLockFrame()
    self.m_respinView:initRsViwePos()
    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
    self:findChild("Button_1"):setVisible(false)
    self.m_respinBar:setVisible(true)
    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    -- 更改respin 状态下的背景音乐
    self:changeReSpinBgMusic()

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {} 
    local respinkind = rsExtraData.respinkind
    if respinkind == "special" then
        self.m_rsTopWheelSpec:initRunSymbolNode()
    end 
    self.m_rsTopWheelNor:initRunSymbolNode()
    self.m_rsTopWheelNor:setVisible(true)
    
    self:runNextReSpinReel()
end

function CodeGameScreenJungleJauntMachine:runNextReSpinReel()

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local rows = rsExtraData.rows or 4
    self.m_currRow = rsExtraData.rows

    self.m_rsOutLine = false
    self.super.runNextReSpinReel(self)
    
end

function CodeGameScreenJungleJauntMachine:showRespinView()
    local waitTime = 0

    self.m_baseFreeSpinBar:setVisible(false)
    
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local rows = rsExtraData.rows or 4
    self.m_currRow = rsExtraData.rows

    -- FREE下中respin的算钱显示，respin 完全结束才会加到fsWinCoins
    local rsWinCoins = self.m_runSpinResultData.p_resWinCoins or 0
    if self.m_bProduceSlots_InFreeSpin then
        -- FREE下需要给玩家显示FREE的的总累计钱数
        local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
        rsWinCoins = rsWinCoins + fsWinCoins
    end

    self.m_lastReSpinWinCoins = rsWinCoins

    if not rsWinCoins or rsWinCoins == 0 then
        rsWinCoins = ""
    else
        rsWinCoins = util_getFromatMoneyStr(rsWinCoins)
    end
    self.m_bottomUI:updateWinCount(rsWinCoins)
    


    self.m_respinBar.m_curCount = self.m_runSpinResultData.p_reSpinCurCount
    self.m_respinBar.m_totalCount = self.m_runSpinResultData.p_reSpinsTotalCount

    if self.m_respinBar.m_totalCount ~= self.m_respinBar.m_curCount then
        performWithDelay(self,function()
            self:outLinesInRs()
        end,0)
        return
    end

    -- 先移除掉假的bonus
    self.m_effectNode:removeAllChildren()

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_46)
    
    -- 将棋盘固定位置的小块变成上bonus
    local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    for i = 1, #storedIcons do
        local info = storedIcons[i]
        local score = info[3]
        local posIndex = info[1]
        local symbolType = info[2]
        local fixPos = self:getRowAndColByPos(posIndex)
        local iCol = fixPos.iY
        local iRow = fixPos.iX
        local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if symbolNode  then
            if symbolNode.p_symbolType ~= symbolType  then
                -- 改变小块
                self:changeSymbolType(symbolNode, symbolType, true)
                self:updateReelGridNode(symbolNode)
                symbolNode.m_isLastSymbol = true
                self:setSpecialNodeScore(self, {symbolNode})
            end
            if symbolNode:getParent() ~= self.m_clipParent then
                symbolNode = util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, REEL_SYMBOL_ORDER.REEL_ORDER_2_2)
            else
                symbolNode:setLocalZOrder(symbolNode:getLocalZOrder() + REEL_SYMBOL_ORDER.REEL_ORDER_2_2) 
            end
            -- 播放触发动画
            symbolNode:runAnim(
                "actionframe",
                false,
                function()
                    symbolNode:runAnim("idleframe2", true)
                end
            )
            waitTime = util_max(waitTime, symbolNode:getAniamDurationByName("actionframe"))
        end
        
    end

    performWithDelay(
        self,
        function()

            self.m_iReelRowNum = 7
            self:respinChangeReelGridCount(self.m_iReelRowNum)

            --可随机的普通信息
            local randomTypes = self:getRespinRandomTypes()
            --可随机的特殊信号
            local endTypes = self:getRespinLockTypes()
            --构造盘面数据
            self:triggerReSpinCallFun(endTypes, randomTypes)
            self.m_respinView:initRsBg()
            self.m_respinView:initSpecLockFrame(true)
            self.m_respinView:setVisible(false)

            local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {} 
            local respinkind = rsExtraData.respinkind
            if respinkind == "special" then
                self.m_rsTopWheelSpec:initRunSymbolNode()
            end 
            self.m_rsTopWheelNor:initRunSymbolNode()

            util_playFadeOutAction(self.m_respinBar,1/30)
            util_playFadeOutAction(self.m_rsTopWheelNor,1/30)

            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_47)
            self:playReSpinGc(
                function()

                    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_48)
                    self:showReSpinStart(
                        function()
                            self.m_respinView:playRsViewLockFrameShow(function()
                                self:runNextReSpinReel()
                            end)
                        end
                    ) 
                    
                end,
                function()

                    self.m_roadMainView:setVisible(false)
                    self.m_respinView:initRsViwePos()
                    --隐藏 盘面信息
                    self:setReelSlotsNodeVisible(false)
                    self:findChild("Button_1"):setVisible(false)
                    self.m_roadMainView:playBaseMenIdle()

                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()

                    self.m_rsTopWheelNor:setVisible(true)
                    self.m_respinView:setVisible(true)
                    self.m_respinBar:setVisible(true)
                    util_playFadeInAction(self.m_respinBar,0.3)
                    util_playFadeInAction(self.m_rsTopWheelNor,0.3)
                    

                end
            )
        end,
        waitTime + 0.1
    )
end

function CodeGameScreenJungleJauntMachine:showReSpinStart(_func)
    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self, BaseDialog.DIALOG_TYPE_RESPIN_START, _func, BaseDialog.AUTO_TYPE_ONLY)
    view:updateOwnerVar({})

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end
    self:findChild("RespinStart"):addChild(view)

end

function CodeGameScreenJungleJauntMachine:getFsLockInfo(_iCol, _iRow)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local storedIcons = selfData.storedIcons or {}
    for i = 1, #storedIcons do
        local info = storedIcons[i]
        local score = info[3]
        local posIndex = info[1]
        local symbolType = info[2]
        local fixPos = self:getRowAndColByPos(posIndex)
        local iCol = fixPos.iY
        local iRow = fixPos.iX
        if iCol == _iCol and iRow == _iRow then
            return symbolType
        end
    end
end

function CodeGameScreenJungleJauntMachine:triggerChangeRespinNodeInfo(respinNodeInfo)
    local randomTypes = self:getRespinRandomTypes()
    local reels = self.m_runSpinResultData.p_rsExtraData.reels
    for i = 1, #respinNodeInfo do
        local info = respinNodeInfo[i]
        local iCol = info.ArrayPos.iY
        local iRow = info.ArrayPos.iX
        local rsSymbolType = self:getMatrixPosSymbolType(iRow, iCol,reels)
        respinNodeInfo[i].Type = rsSymbolType
        local lockType = self:getFsLockInfo(iCol, iRow)
        if lockType then
            respinNodeInfo[i].Type = lockType
        end
        if not self:isNorBonusSymbol(respinNodeInfo[i].Type) then
            respinNodeInfo[i].Type = randomTypes[math.random(1, #randomTypes)]
        end
        local zorder = self:getBounsScatterDataZorder(respinNodeInfo[i].Type)
        respinNodeInfo[i].Zorder = zorder - iRow + iCol * self.m_iReelRowNum

    end
end

function CodeGameScreenJungleJauntMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_SlotNodeH * self.m_iReelRowNum )

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
        end
    )
end

function CodeGameScreenJungleJauntMachine:playReSpinGc(_func, _currFunc)
    performWithDelay(self.m_spineBg,function()
        self:runCsbAction("respin_guochang")
        self.m_spineBg2:setVisible(true)
        util_spinePlay(self.m_spineBg2, "respin_guochang")
        util_spinePlay(self.m_spineBg, "respin_guochang")
        util_spineEndCallFunc(
            self.m_spineBg,
            "respin_guochang",
            function()
                if _func then
                    _func()
                end
            end
        )
    
        performWithDelay(
            self.m_spineBg,
            function()
                self:findChild("base_reel"):setVisible(false)
                self:findChild("free_reel"):setVisible(false)
                self:findChild("basefree_jackpot"):setVisible(false)
                self:findChild("respin_jackpot"):setVisible(true)
                if _currFunc then
                    _currFunc()
                end
            end,
            140 / 60
        ) 
    end,0)
    
end

--ReSpin开始改变UI状态
function CodeGameScreenJungleJauntMachine:changeReSpinStartUI(respinCount)
    self:changeReSpinUpdateUI()
end

--ReSpin刷新数量
function CodeGameScreenJungleJauntMachine:changeReSpinUpdateUI(_curCount,_totalCount)
    local curNum = _curCount or self.m_runSpinResultData.p_reSpinCurCount
    local totalNum = _totalCount or self.m_runSpinResultData.p_reSpinsTotalCount
    local curLab = self.m_respinBar:findChild("m_lb_num_1")
    local totalLab = self.m_respinBar:findChild("m_lb_num_2")

    if self.m_respinBar.m_totalCount < totalNum then
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_54)  
        self.m_respinBar:runCsbAction("switch") 
    end
    curLab:setString(totalNum - curNum)
    totalLab:setString(totalNum)
    self.m_respinBar.m_curCount = curNum
    self.m_respinBar.m_totalCount = totalNum
    
   
    
end

--ReSpin结算改变UI状态
function CodeGameScreenJungleJauntMachine:changeReSpinOverUI()
end

function CodeGameScreenJungleJauntMachine:showRespinOverView(effectData)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_56) 

    local rsWinCoins =  self.m_runSpinResultData.p_resWinCoins or 0
    local strCoins = util_formatCoinsLN(rsWinCoins, 30)
    local view =
        self:showReSpinOver(
        strCoins,
        function()
            
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg()
        end
    )
    -- gLobalSoundManager:playSound("JungleJauntSounds/music_JungleJaunt_linghtning_over_win.mp3")
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 656)

    local labNum = view:findChild("m_lb_num")
    labNum:setString(self.m_runSpinResultData.p_reSpinsTotalCount)


    local glow = util_createAnimation("JungleJaunt/jungleJaunt_tb_glow.csb")
    view:findChild("Node_glow"):addChild(glow)
    glow:runCsbAction("idle", true)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5) 
    end)
    view:setOverAniRunFunc(function()
        
        gLobalSoundManager:playSound(PBC.SoundConfig.JungleJaunt_Sound_57) 
        if self.m_bProduceSlots_InFreeSpin then
            self:changeMainUI(PBC.freeId)
            local curtimes = self.m_runSpinResultData.p_freeSpinsLeftCount
            local totaltimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_baseFreeSpinBar:updateFreespinCount(totaltimes - curtimes, totaltimes)
            self.m_baseFreeSpinBar:setVisible(true)
        else
            self:changeMainUI(PBC.baseId)
        end
        
        -- 通知respin结束
        self:setReelSlotsNodeVisible(true)
        -- 更新游戏内每日任务进度条 -- r
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        self:removeRespinNode()
        self.m_iReelRowNum = 4
        self:respinChangeReelGridCount(self.m_iReelRowNum)

        self.m_rsTopWheelNor:setVisible(false)
        self.m_rsTopWheelSpec:setVisible(false)
        self.m_respinBar:setVisible(false) 
    end)
    view:findChild("root1"):setScale(self.m_machineRootScale)
    
end

--结束移除小块调用结算特效
function CodeGameScreenJungleJauntMachine:removeRespinNode()
    if self.m_respinView == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNode = self.m_respinView:getAllEndSlotsNode()
    for i = 1, #allEndNode do
        local targSp = allEndNode[i]
        targSp:removeFromParent(false)
        self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
    end
    self.m_respinView:removeFromParent()
    self.m_respinView = nil

    -- 重新随机一下轮盘
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType ~= self.SYMBOL_JungleJaunt_9_2  then
                -- 简单随机一个得了
                self:changeSymbolType(symbolNode, math.random(1,6) - 1, true)
                symbolNode:runAnim("idleframe")
            end
        end
    end
end

-- --重写组织respinData信息
function CodeGameScreenJungleJauntMachine:getRespinSpinData()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local rsStoredIcons = nil
    if self:getCurrSpinMode() == RESPIN_MODE then
        -- rsStoredIcons = rsExtraData.storedIcons
    end
    local storedIcons = rsStoredIcons or self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i = 1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

function CodeGameScreenJungleJauntMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("JungleJauntSrc.JpBar.JungleJauntJackPotBarBaseView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("basefree_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点

    self.m_rsJPBarView = util_createView("JungleJauntSrc.JpBar.JungleJauntJackPotBarRsView")
    self.m_rsJPBarView:initMachine(self)
    self:findChild("respin_jackpot"):addChild(self.m_rsJPBarView) --修改成自己的节点

end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenJungleJauntMachine:showJackpotView(coins, jackpotType, func)
    local view =
        util_createView(
        "JungleJauntSrc.JungleJauntJackpotWinView",
        {
            jackpotType = jackpotType,
            winCoin = coins,
            machine = self,
            func = function()
                if type(func) == "function" then
                    func()
                end
            end
        }
    )

    gLobalViewManager:showUI(view)
    view:findChild("root1"):setScale(self.m_machineRootScale)
end

function CodeGameScreenJungleJauntMachine:setReelRunInfo()
    local reels = self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    local longRunConfigs = {}
    table.insert(longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"], ["symbolType"] = {90}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenJungleJauntMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    self.super.MachineRule_ResetReelRunData(self)
end

function CodeGameScreenJungleJauntMachine:playBulingSymbolSounds(_iCol, _soundName, _soundType)

    if _soundName == PBC.SoundConfig.JUNGLEJAUNT_SOUND_6 then
        self.m_scNum = self.m_scNum + 1
        _soundType = "scatter"
        if self.m_scNum == 2 then
            _soundName = PBC.SoundConfig.JUNGLEJAUNT_SOUND_7
        elseif self.m_scNum >= 3 then
            _soundName = PBC.SoundConfig.JUNGLEJAUNT_SOUND_8
        end
    end

    return self.super.playBulingSymbolSounds(self,_iCol, _soundName, _soundType)
end


-- 有特殊需求判断的 重写一下
function CodeGameScreenJungleJauntMachine:checkSymbolBulingSoundPlay(_slotNode)
    local isPlay = self.super.checkSymbolBulingSoundPlay(self, _slotNode)
    if self:isNorBonusSymbol(_slotNode.p_symbolType) then
        if _slotNode.p_cloumnIndex >= self.m_iReelColumnNum then
            if self.m_bonusbulingIndex < 1 then
                -- 前几列一个bonus都没有就没有有几率中respin
                isPlay = false
            end
        end
    end
    return isPlay
end

function CodeGameScreenJungleJauntMachine:checkSymbolBulingAnimPlay(_slotNode, _noAdd)
    local isPlay = self.super.checkSymbolBulingAnimPlay(self, _slotNode)

    if self:isNorBonusSymbol(_slotNode.p_symbolType) then
        if _slotNode.p_cloumnIndex >= self.m_iReelColumnNum then
            if self.m_bonusbulingIndex < 1 then
                -- 前几列一个bonus都没有就没有有几率中respin
                isPlay = false
            end
        else
            self.m_bonusbulingIndex = self.m_bonusbulingIndex + 1
        end
    elseif _slotNode.p_symbolType == self.SYMBOL_BONUS_SPEC and _slotNode.p_cloumnIndex >= self.m_iReelColumnNum then
        isPlay = false
        local num = 0
        for iCol = 1, self.m_iReelColumnNum -1 do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
                if symbolType == self.SYMBOL_BONUS_SPEC then
                    num = num + 1
                end
            end
        end
        if num >= 1  then
            isPlay = true
        else
            local num = 0
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = self:getMatrixPosSymbolType(iRow, self.m_iReelColumnNum)
                if symbolType == self.SYMBOL_BONUS_SPEC then
                    num = num + 1
                end
            end
            if num > 1  then
                isPlay = true
            end
        end
            
    end

    if isPlay and not _noAdd then
        self.m_bulingIndex = self.m_bulingIndex + 1
    end

    return isPlay
end

function CodeGameScreenJungleJauntMachine:reelDownNotifyPlayGameEffect()
    if self.m_bulingIndex > 0 then
        schedule(
            self.m_reelStopNode,
            function()
                if self.m_bulingIndex <= 0 then
                    self.m_reelStopNode:stopAllActions()
                    self.super.reelDownNotifyPlayGameEffect(self)
                end
            end,
            1 / 60
        )
    else
        self.super.reelDownNotifyPlayGameEffect(self)
    end
end

function CodeGameScreenJungleJauntMachine:symbolBulingEndCallBack(_slotNode)
    self.m_bulingIndex = self.m_bulingIndex - 1
    local symbolType = _slotNode.p_symbolType
    if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 then
        _slotNode:runAnim("idleframe2", true)
    elseif symbolType == self.SYMBOL_BONUS_SPEC then
        _slotNode:runAnim("idleframe2", true)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        _slotNode:runAnim("idleframe2", true)
    end

    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenJungleJauntMachine:isPlayExpect(reelCol)
    if reelCol <= self.m_iReelColumnNum then
        local bHaveLongRun = false
        for i = 1, reelCol do
            local reelRunData = self.m_reelRunInfo[i]
            if reelRunData:getNextReelLongRun() == true then
                bHaveLongRun = true
                break
            end
        end
        if bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() then
            return true
        end
    end
    return false
end

function CodeGameScreenJungleJauntMachine:getFeatureGameTipChance(_probability)
    local probability = 40
    local isplay = self.super.getFeatureGameTipChance(self, _probability)
    if not isplay then
        -- base骰子玩法单独处理
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local game_dice = selfData.game_dice or 0
        if game_dice > 0 then
            isplay = (math.random(1, 100) <= 30)
        end
    end
    return isplay
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenJungleJauntMachine:showFeatureGameTip(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local end_pos_v2 = selfData.end_pos_v2 
    local currStandIndex = self.m_roadMainView.m_currStandIndex
    if end_pos_v2 and end_pos_v2 ~= currStandIndex then
        -- util_logDevAssert("本地位置对不上")
    end

    self.m_featureTip:playFeatureTipFunc(
        function()
            if _func then
                _func()
            end
        end
    )
end

--[[
        获取jackpot类型及赢得的金币数
    ]]
function CodeGameScreenJungleJauntMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType, coins in pairs(jackpotCoins) do
        return string.lower(jackpotType), coins
    end
    return "", 0
end

--[[
    bet档位相关
]]
function CodeGameScreenJungleJauntMachine:showChooseView(_bOnEnter)
    self:findChild("Button_1"):setTouchEnabled(false)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if not self.m_chooseView then
        self.m_chooseView = util_createView("JungleJauntSrc.JungleJauntChooseView", {machine = self})
        self:findChild("Node_jinru"):addChild(self.m_chooseView)
    end
    self.m_chooseView:setVisible(true)
    local currData = {
        fnOver = function()
            self:findChild("Button_1"):setTouchEnabled(true)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end,
        bOnEnter = _bOnEnter
    }
    self.m_chooseView:playChooseViewStartAnim(currData)
end

function CodeGameScreenJungleJauntMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenJungleJauntMachine:getSpinMessageData()
    local messageData = self.super.getSpinMessageData(self)
    messageData.clickPos = {}
    messageData.clickPos.manType = self.m_roadManType
    return messageData
end

function CodeGameScreenJungleJauntMachine:initMachineBg()
    self.super.initMachineBg(self)
    self.m_gameBg:setPosition(cc.p(0, 0))
    self.m_spineBg = util_spineCreate("GameScreenJungleJauntBg", true, true)
    self.m_gameBg:findChild("Node_spine"):addChild(self.m_spineBg, 1)

    self.m_spineBg2 = util_spineCreate("GameScreenJungleJauntBg_respin", true, true)
    self.m_gameBg:findChild("Node_spine"):addChild(self.m_spineBg2, 2)
    self.m_spineBg2:setVisible(false)
end

function CodeGameScreenJungleJauntMachine:changeMainUI(_stateID)
    self:findChild("Button_1"):setVisible(_stateID == PBC.baseId)
    self:findChild("base_reel"):setVisible(_stateID == PBC.baseId)
    self:findChild("free_reel"):setVisible(_stateID == PBC.freeId)

    self:findChild("basefree_jackpot"):setVisible(_stateID == PBC.freeId or _stateID == PBC.baseId)
    self:findChild("respin_jackpot"):setVisible(_stateID == PBC.rsId)

    self.m_roadMainView:setVisible(_stateID == PBC.freeId or _stateID == PBC.baseId)

    self.m_spineBg2:setVisible(_stateID == PBC.rsId)

    if _stateID == PBC.baseId then
        self.m_roadMainView:playBaseMenIdle()
        self:runCsbAction("normal")
        util_spinePlay(self.m_spineBg, "base_idle", true)
    elseif _stateID == PBC.freeId then
        self:runCsbAction("normal")
        self.m_roadMainView:playFreeMenIdle()
        util_spinePlay(self.m_spineBg, "free_idle", true)
    elseif _stateID == PBC.rsId then
        self.m_roadMainView:playBaseMenIdle()
        self.m_roadMainView:setVisible(false)
        util_spinePlay(self.m_spineBg2, "respin_idle",true)
        util_spinePlay(self.m_spineBg, "respin_idle", true)
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenJungleJauntMachine:showBigWinLight(func)


    local rod = math.random(1,100)
    if rod <= 30 then
        gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_85)
    end
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_84)

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl, self:findChild("Node_bigwin"))
    if not self.m_bigwinSP then
        self.m_bigwinSP = util_spineCreate("JungleJaunt_bigwin", true, true)
        self:findChild("Node_bigwin"):addChild(self.m_bigwinSP)
        self.m_bigwinSP:setPosition(pos)
    end

    self.m_bigwinSP:setVisible(true)
    util_spinePlay(self.m_bigwinSP, "actionframe_bigwin")

    local aniTime = self.m_bigwinSP:getAnimationDurationTime("actionframe_bigwin")
    util_shakeNode(self:findChild("root"), 5, 10, aniTime)

    self:delayCallBack(
        aniTime,
        function()
            self.m_bigwinSP:setVisible(false)
            if type(func) == "function" then
                func()
            end
        end
    )
end

function CodeGameScreenJungleJauntMachine:showFreeGuoChang(_func, _endFunc)
    if not self.m_fsGC then
        self.m_fsGC = util_spineCreate("JungleJaunt_guochang_free", true, true)
        self:findChild("Node_guochang"):addChild(self.m_fsGC)
    end
    self.m_fsGC:setVisible(true)
    util_spinePlay(self.m_fsGC, "actionframe_guochang")
    util_spineEndCallFunc(
        self.m_fsGC,
        "actionframe_guochang",
        function()
            self.m_fsGC:setVisible(false)
            if _endFunc then
                _endFunc()
            end
        end
    )
    performWithDelay(
        self.m_fsGC,
        function()
            if _func then
                _func()
            end
        end,
        30 / 30
    )
end

function CodeGameScreenJungleJauntMachine:requestSpinResult()

    if self:getCurrSpinMode() == RESPIN_MODE then
        -- 存储一下上一次的respin赢钱

        local rsWinCoins =  self.m_runSpinResultData.p_resWinCoins or 0
        if self.m_bProduceSlots_InFreeSpin then
            -- FREE下需要给玩家显示FREE的的总累计钱数
            local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
            rsWinCoins = rsWinCoins + fsWinCoins
        end
        self.m_lastReSpinWinCoins = rsWinCoins

        self.m_respinView:playRsViewLockFrameShow(function()
            self.super.requestSpinResult(self)
        end)
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_freeGame:playFreeBonusMove(
            function()

                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    local childs = self.m_effectNode:getChildren()
                    for i = 1, #childs do
                        local node = childs[i]
                        if node.iCol < self.m_iReelColumnNum then
                            self.m_bonusbulingIndex = self.m_bonusbulingIndex + 1
                        end
                    end
                end
                
                self.super.requestSpinResult(self)
            end
        )
    else
        self.super.requestSpinResult(self)
    end

end

function CodeGameScreenJungleJauntMachine:freeRequest()
    self:requestSpinResult()
end

---
-- 触发respin 玩法
--
function CodeGameScreenJungleJauntMachine:showEffect_Respin(effectData)
    self.m_beInSpecialGameTrigger = true
    -- 停掉背景音乐
    self:clearCurMusicBg()
    self:stopLinesWinSound()
    self:levelDeviceVibrate(6, "respin")
    -- 取消掉赢钱线的显示
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearWinLineEffect()
    performWithDelay(
        self,
        function()
            self:showRespinView(effectData)
        end,
        0.1
    )
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin, self.m_iOnceSpinLastWin)
    return true
end

--隐藏盘面信息
function CodeGameScreenJungleJauntMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode then
                symbolNode:setVisible(status)
            end
        end

        local slotParent = self.m_slotParents[iCol].slotParent
        slotParent:setVisible(status)
        local slotParentBig = self.m_slotParents[iCol].slotParentBig
        if slotParentBig then
            slotParentBig:setVisible(status)
        end
    end

    


end

-- -- 测试代码
-- function CodeGameScreenJungleJauntMachine:checkOperaSpinSuccess(param)
--     local spinData = param[2]
--     if spinData.action == "SPIN" then
--         -- buff1
--         -- spinData.result.selfData = {}
--         spinData.result.selfData.chess_bet_list =  {
-- 			houzi = spinData.result.selfData.chess_bet_list["houzi"] + 9,
-- 			daxiang = spinData.result.selfData.chess_bet_list["daxiang"] + 9,
-- 			shizi = spinData.result.selfData.chess_bet_list["shizi"] + 9,
-- 			xiniu = spinData.result.selfData.chess_bet_list["xiniu"] + 9
-- 		}  -- 棋子停止位置
--         spinData.result.selfData.chess_max = 50 -- 顶部棋盘长度
--         spinData.result.selfData.dice_game1_list = {1,1,1,1,1,1,1,1,10000} -- 玩法1的结果列表
--         spinData.result.selfData.dice_game1_win  = 80000
--         spinData.result.selfData.game_dice = 1
--         spinData.result.selfData.special_stored_icons = {}
--         spinData.result.reels = {
--             {9,0,0,9,3},
--             {3,96,0,3,9},
--             {1,0,0,92,0},
--             {1,8,0,5,96}
--         }

--     end
--     self.super.checkOperaSpinSuccess(self,param)
-- end

function CodeGameScreenJungleJauntMachine:playCoinWinEffectUI(_score,_currAnimName)

    
    
    if _score then
        --通用底部跳字动效
        local winCoins = _score
        local params = {
            overCoins  = winCoins,
            jumpTime   = 3/30,
            animName   = "actionframe2",
        }
        self:playBottomBigWinLabAnim(params)
    end

    self.m_bottomUI.m_bigWinLabCsb:setLocalZOrder(10)
    if not self.m_winLight then
        self.m_winLight = util_spineCreate("JungleJaunt_totalwin", true, true)
        self.m_bottomUI.coinWinNode:addChild(self.m_winLight)
    end
    self.m_winLight:setVisible(true)
    util_spinePlay(self.m_winLight, _currAnimName or "actionframe")
    util_spineEndCallFunc(
        self.m_winLight,
        "actionframe",
        function()
            self.m_winLight:setVisible(false)
        end
    )
end

--默认按钮监听回调
function CodeGameScreenJungleJauntMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_1" then
        if PBC.isCanOpenChooseView(self) then
            self:showChooseView(false)
        end
    elseif name == "Panel_StopBuff3" then
        self.m_chomperGame:cutOffFunc() -- 跳过流程
    elseif name == "tbTouZiClick" then
        if self.m_tbTouZiEndFunc then
            self.m_tbTouZiEndFunc()
            self.m_tbTouZiEndFunc = nil
        end
        

    end
end

function CodeGameScreenJungleJauntMachine:checkQuickStopStage()
    return self:getGameSpinStage() ~= QUICK_RUN
end

-- 延时
function CodeGameScreenJungleJauntMachine:levelPerformWithDelay(_parent, _time, _fun)
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

function CodeGameScreenJungleJauntMachine:initGameStatusData(gameData)
    self.super.initGameStatusData(self,gameData)
    self.m_isEOChooseV = false
    if gameData.gameConfig and gameData.gameConfig.extra then
        if gameData.gameConfig.extra.popup and gameData.gameConfig.extra.popup == 1 then
            self.m_isEOChooseV = true
        end
        if gameData.gameConfig.extra.lastChoice then
            self.m_roadManType = gameData.gameConfig.extra.lastChoice
        end
    end
end

function CodeGameScreenJungleJauntMachine:initSlotNodes()
    self.super.initSlotNodes(self)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode then
                symbolNode = util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, REEL_SYMBOL_ORDER.REEL_ORDER_2_2)
                local symbol_node = symbolNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                local nodeScore = nil
                if not tolua.isnull(spineNode.m_nodeScore) then
                    nodeScore = spineNode.m_nodeScore
                    if nodeScore then
                        local lineBet = globalData.slotRunData:getCurTotalBet()
                        if symbolNode.p_symbolType == self.SYMBOL_BONUS_1 then
                            nodeScore.score = 2 * lineBet
                        elseif symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
                            nodeScore.score = 4 * lineBet
                        end
                        local score = util_formatCoinsLN(nodeScore.score, 3)
                        nodeScore:findChild("m_lb_coins"):setString(score) 
                        nodeScore:updateLabelSize({label = nodeScore:findChild("m_lb_coins"), sx = 1, sy = 1}, 134)     
                    end
                end
            end
        end
    end
end

--[[
    初始化黑色遮罩层
]]
function CodeGameScreenJungleJauntMachine:initLayerBlack()

    local colorLayers = util_createReelMaskColorLayers( self ,REEL_SYMBOL_ORDER.REEL_ORDER_2 ,cc.c3b(0, 0, 0),130)
    self.m_layer_colors = colorLayers
    for key,layer in pairs(self.m_layer_colors) do
        layer:setVisible(false)
        local colorLayer = layer:getChildByName("Clayer")
        colorLayer:setScaleX(1.05)
        util_setCascadeOpacityEnabledRescursion(layer, true)
    end
end

--[[
    显示黑色遮罩层
]]
function CodeGameScreenJungleJauntMachine:showLayerBlack()
    for key,layer in pairs(self.m_layer_colors) do
        layer:setOpacity(0)
        layer:runAction(cc.Sequence:create({
            cc.Show:create(),
            cc.FadeIn:create(0.2)
        }))
    end
end

--[[
    显示黑色遮罩层
]]
function CodeGameScreenJungleJauntMachine:hideLayerBlack(currCol)
    for key,layer in pairs(self.m_layer_colors) do
        if currCol == key then
            layer:runAction(cc.Sequence:create({
                cc.FadeOut:create(0.2),
                cc.Hide:create()
            }))
            break
        end
    end
end

function CodeGameScreenJungleJauntMachine:checkIsAddLastWinSomeEffect()
    local notAdd = self.super.checkIsAddLastWinSomeEffect(self)
    notAdd = false -- 这关玩法特殊，所有情况下都检测大赢
    return notAdd
end

--小块
function CodeGameScreenJungleJauntMachine:getBaseReelGridNode()
    return "JungleJauntSrc.JungleJauntSlotsNode"
end


function CodeGameScreenJungleJauntMachine:checkQuickStopBulingState()
    local isRsQuickStop = false
    if self.m_respinView and self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.QUICK_STOP then
        isRsQuickStop = true
    end

    return self:getGameSpinStage() == QUICK_RUN or isRsQuickStop
end


function CodeGameScreenJungleJauntMachine:playQuickStopBulingSymbolSound(_iCol)

    if self:checkQuickStopBulingState() then

        local bulingDatas = self.m_symbolQsBulingSoundArray
        if bulingDatas["scatter"]  then
            self.m_symbolQsBulingSoundArray = {["scatter"] = bulingDatas["scatter"]} 
        end
        if bulingDatas[PBC.SoundConfig.JUNGLEJAUNT_SOUND_10]  then
            self.m_symbolQsBulingSoundArray = {[PBC.SoundConfig.JUNGLEJAUNT_SOUND_10] = bulingDatas[PBC.SoundConfig.JUNGLEJAUNT_SOUND_10]} 
        end
    end

    CodeGameScreenJungleJauntMachine.super.playQuickStopBulingSymbolSound(self,_iCol)
end

function CodeGameScreenJungleJauntMachine:scaleMainLayer()
    self.super.scaleMainLayer(self)
    
    if  display.height / display.width < 1024 / 768 then
        self.m_machineRootScale = self.m_machineRootScale * 1.155
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 25)
    elseif display.height / display.width >= 1024 / 768 and display.height / display.width < 1152 / 768 then
        self.m_machineRootScale = self.m_machineRootScale * 1.1
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 18)
    elseif display.height / display.width >= 1152 / 768 and display.height / display.width < 1228 / 768 then
        self.m_machineRootScale = self.m_machineRootScale * 1.05
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 13 )
    elseif display.height / display.width >= 1228 / 768 and display.height / display.width < 1370 / 768 then
        self.m_machineRootScale = self.m_machineRootScale * 1.03
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 9)
    elseif display.height / display.width >= 1370 / 768 and display.height / display.width < 1530 / 768 then
        self.m_machineRootScale = self.m_machineRootScale * 1
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 2)
    elseif display.height / display.width >= 1530 / 768  then
        self.m_machineRootScale = self.m_machineRootScale * 1
        util_csbScale(self.m_machineNode, self.m_machineRootScale)
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 2)
    end

    local bangHeight = util_getBangScreenHeight()
    local bottomHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bottomHeight - bangHeight)
    
end

return CodeGameScreenJungleJauntMachine
