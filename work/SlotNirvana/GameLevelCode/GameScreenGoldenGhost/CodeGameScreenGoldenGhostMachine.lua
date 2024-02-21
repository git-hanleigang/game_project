---
-- island li
-- 2019年1月26日
-- CodeGameScreenGoldenGhostMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local GameNetDataManager = require "network.SendDataManager"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenGoldenGhostMachine = class("CodeGameScreenGoldenGhostMachine", BaseFastMachine)
local GoldenGhostMachineConfig = require "GoldenGhostMachineConfig"



CodeGameScreenGoldenGhostMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 = 94
CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 = 96
CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 = 101

CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN     = 98
CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV2 = 99
CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_ADDSPIN_LV3 = 100


--播放收集wild和bonus动画
CodeGameScreenGoldenGhostMachine.EFFECT_SELF_PLAYFLYBONUS = GameEffect.EFFECT_SELF_EFFECT + 1

CodeGameScreenGoldenGhostMachine.m_chooseRepin = nil
--spine弹板的层级
local SpineTanbanOrder = {
    Tanban     = 1,
    Guadian    = 5,
    SecondView = 10,
}


function CodeGameScreenGoldenGhostMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)   -- 必须调用不予许删除
    self:addObservers()

    self:changeTopUIState()
    self:changeSpineBgShow()

end

-- 构造函数
function CodeGameScreenGoldenGhostMachine:ctor()
    print("CodeGameScreenGoldenGhostMachine:ctor")
    BaseFastMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    globalMachineController.p_GoldenGhostMachineConfig   = GoldenGhostMachineConfig

    self.m_spinRestMusicBG = true
    
    self.lv1TotalScore = 0
    --触发bonus游戏的bonus数量
    self.m_bonusNum = 0
    --需要收集的wild数量
    self.wildNum = 0
    --freespin需要收集的bonus数量
    self.bonusNum = 0
    self:setFreeSpinScore(0, false)
	--init
	self:initGame()
    --respin模式初始化时计算+1spin信号的数量
    self.addSpinSymbolNum = 0
    self.curEffectData = nil
    self.curRespinTimes = 0
    self.curTotalRespinTimes = 0
    self.curBonusLv1Idx = 0
    self.wildCounts = 0
    self.curPotActionIdx = nil
    self.collectTime = 20 / 60

    self.freeHasBonusLv1 = false
    self.freeHasBonusLv2 = false
    self.freeBonusLv2Count = 0
    self.hasWildFlag = false
    --pickBonus
    self.m_pickBonus_times = 0
end

function CodeGameScreenGoldenGhostMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("GoldenGhostConfig.csv", "LevelGoldenGhostCSVData.lua")
	--初始化基本数据
	self:initMachine(self.m_moduleName)
end  

function CodeGameScreenGoldenGhostMachine:initUI()
    self.m_chooseRepin = false
    
    self:initFreeSpinBar() -- FreeSpinbar

    -- reSpin 和 free改为使用一个滚轮背景
    self.m_reelRespinBg = self:findChild("reel_bg_frs")
    self:setReelBg()

    self:runCsbAction("idleframe", true)

    self.m_pumpkinParent = self:findChild("Pumpkin")
    self.m_pumpkin  = util_spineCreate("GoldenGhost_pumpkin",true,true)
    self.m_pumpkinParent:addChild(self.m_pumpkin)
    util_spinePlay(self.m_levelBg, "idleframe", true)
    
    self.coinNode = self:findChild("coins")
    local goldMidTopUI = util_createView("CodeGoldenGhostSrc.GoldenGhostGoldMidTopUI")
    self.goldMidTopUI = goldMidTopUI
    self.coinNode:addChild(goldMidTopUI)

    self.m_topUi_pot = util_createAnimation("GoldenGhost_pot.csb")
    self:findChild("pot"):addChild(self.m_topUi_pot)
    self.m_topUi_pot:runCsbAction("idle", true)

    self.jackPotLayer = self:findChild("Jackpot")
    local jackPotBar = util_createView("CodeGoldenGhostSrc.GoldenGhostJackPotBar")
    self.m_jackPotBar = jackPotBar
    self.jackPotLayer:addChild(jackPotBar)
    jackPotBar:initMachine(self)

    self.m_yugao  = util_spineCreate("GoldenGhost_yugao",true,true)
    self:findChild("yugao"):addChild(self.m_yugao)
    self.m_yugao:setVisible(false)

    self.jackPotLayer2 = self:findChild("Jackpot_0")
    local freeSpinTopUI = util_createView("CodeGoldenGhostSrc.GoldenGhostFreeSpinTopUI")
    self.freeSpinTopUI = freeSpinTopUI
    freeSpinTopUI:setExtraInfo(self)
    self.jackPotLayer2:addChild(freeSpinTopUI)

    local bonusTopUI = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusTopUI")
    self.bonusTopUI = bonusTopUI
    bonusTopUI:setExtraInfo(self)
    self.jackPotLayer2:addChild(bonusTopUI)

    self.respinBarNode = self:findChild("respin_bar")
    local bonusRespinBar = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusFreeSpinBar", "GoldenGhost_respin_bar.csb")
    self.bonusRespinBar = bonusRespinBar
    self.bonusRespinBar:findChild("left_0"):setVisible(false)
    -- self.bonusRespinBar:setType("respin")
    self.respinBarNode:addChild(bonusRespinBar)

    self.freeSpinNode = self:findChild("freespin_bar")
    local bonusFreeSpinBar = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusFreeSpinBar", "GoldenGhost_respin_bar.csb")
    self.bonusFreeSpinBar = bonusFreeSpinBar
    self.bonusFreeSpinBar:findChild("res"):setVisible(false)
    -- self.bonusFreeSpinBar:setType("free")
    self.freeSpinNode:addChild(bonusFreeSpinBar)

    self.m_spineTanbanParent = cc.Node:create()
    self:addChild(self.m_spineTanbanParent, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    --挂点 缩放/坐标适配
    local x = display.width / DESIGN_SIZE.width
    local y = display.height / DESIGN_SIZE.height
    local scale = x / y
    self.m_spineTanbanParent:setScale( math.min(1, scale) )
    local nodePos  = self.m_spineTanbanParent:getParent():convertToNodeSpace(cc.p(display.width/2, display.height/2))
    self.m_spineTanbanParent:setPosition(nodePos)

    self.m_spineTanban_mask = util_createAnimation("GoldenGhost_Choose_dark.csb")
    self.m_spineTanbanParent:addChild(self.m_spineTanban_mask)
    self.m_spineTanban_mask:setVisible(false)

    -- 一些根据模式展示的节点
    self.m_frame = self:findChild("frame")
    self.m_frame_0 = self:findChild("frame_0")
    self.m_lines_left = self:findChild("lines_left")
    self.m_lines_right = self:findChild("lines_right")

    --先注释 guang
    -- self.guang = self:findChild("guang")
    -- self.guang:setVisible(false)

    --先注释 
    -- self.centerNode = self:findChild("center_node")
    -- self.totalWin = self:findChild("TotalWin")
    -- self.baseLine = self:findChild("base_line")
    --先注释 fgLine
    -- self.fgLine = self:findChild("fg_line")
    --先注释 reLine
    -- self.reLine = self:findChild("re_lines")
    -- self.fgLine:setVisible(false)
    -- self.reLine:setVisible(false)
    
    --先注释
    -- local totalWinNode = util_createAnimation("GoldenGhost_TotalWin.csb")
    -- self.totalWin:addChild(totalWinNode)
   
    gLobalNoticManager:addObserver(
        self,
        function(self,params)  -- 更新赢钱动画
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                local isFreeSpinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
                if isFreeSpinOver then
                else
                    if self.m_bIsBigWin then
                        return
                    end
                end
            else
                if self.m_bIsBigWin then
                    return
                end
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]
            
            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 2
            if winRate <= 1 then
                soundIndex = 1
                soundTime = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 2
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 3
                soundTime = 3
            elseif winRate > 6 then
                soundIndex = 3
                soundTime = 3
            end

            local soundName = nil
            local curSpinMode = self:getCurrSpinMode()
            local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
            if curSpinMode == NORMAL_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
                soundName = string.format(levelConfig.Sound_WinCoin_Base, soundIndex)
            elseif curSpinMode == FREE_SPIN_MODE then
                soundName = string.format(levelConfig.Sound_WinCoin_Free, soundIndex)
            end

            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

            --大于 2倍 同时播 魔女赢钱
            if winRate >= 2 then
                soundName = string.format(levelConfig.Sound_WinCoin_Witch, math.random(1, 2))
                self.m_winSoundsId_2 = gLobalSoundManager:playSound(soundName)
            end
            
    end,
    ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenGoldenGhostMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    local bgNode =  self:findChild("bg")
    if not bgNode then
        bgNode =  self:findChild("gameBg")
        if not bgNode then
            bgNode =  self:findChild("gamebg")
        end
    end
    if bgNode  then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    local baseBg = util_spineCreate("GameScreenGoldenGhostBg1",true,true)
    util_spinePlay(baseBg, "idleframe", true)  
    gameBg:addChild(baseBg)
    baseBg:setName("GoldenGhost_baseBg")

    local freeBg = util_spineCreate("GameScreenGoldenGhostBg2",true,true)
    -- util_spinePlay(freeBg, "idleframe", true)  
    gameBg:addChild(freeBg)
    freeBg:setName("GoldenGhost_freeBg")

    local reSpinBg = util_spineCreate("GameScreenGoldenGhostBg3",true,true)
    -- util_spinePlay(reSpinBg, "idleframe", true)  
    gameBg:addChild(reSpinBg)
    reSpinBg:setName("GoldenGhost_reSpinBg")

    self.bgEffect = baseBg
    self.m_gameBg = gameBg
end

function CodeGameScreenGoldenGhostMachine:changeSpineBgShow(_spinMode)
    local baseBg   = self.m_gameBg:getChildByName("GoldenGhost_baseBg")
    local freeBg   = self.m_gameBg:getChildByName("GoldenGhost_freeBg")
    local reSpinBg = self.m_gameBg:getChildByName("GoldenGhost_reSpinBg")

    local spinMode = _spinMode or self:getCurrSpinMode()
    local isPickBonus = self:isInPickBonus()

    baseBg:setVisible(spinMode == NORMAL_SPIN_MODE and not isPickBonus)
    freeBg:setVisible(spinMode == FREE_SPIN_MODE)
    reSpinBg:setVisible(spinMode == RESPIN_MODE or isPickBonus)
end
function CodeGameScreenGoldenGhostMachine:getOneSpineBg(_spinMode)
    _spinMode = _spinMode or self:getCurrSpinMode()
    local isPickBonus = self:isInPickBonus()

    if _spinMode == NORMAL_SPIN_MODE and not isPickBonus then
        return self.m_gameBg:getChildByName("GoldenGhost_baseBg")
    end
    if _spinMode == FREE_SPIN_MODE then
        return self.m_gameBg:getChildByName("GoldenGhost_freeBg")
    end
    if _spinMode == RESPIN_MODE or isPickBonus then
        return self.m_gameBg:getChildByName("GoldenGhost_reSpinBg")
    end
end
function CodeGameScreenGoldenGhostMachine:playSpineBgStartAnim(_spinMode, _endFun)
    local spineBg = self:getOneSpineBg(_spinMode)
    util_spinePlay(spineBg,"start",false)
    util_spineEndCallFunc(spineBg,"start",handler(nil,function(  )
        --都接 idlefraem
        util_spinePlay(spineBg,"idlefraem",true)

        if _endFun then
            _endFun()
        end
    end))
end
function CodeGameScreenGoldenGhostMachine:playSpineBgOverAnim(_spinMode, _endFun)
    local spineBg = self:getOneSpineBg(_spinMode)
    util_spinePlay(spineBg,"over",false)
    util_spineEndCallFunc(spineBg,"over",handler(nil,function(  )
        if _endFun then
            _endFun()
        end
    end))
end


function CodeGameScreenGoldenGhostMachine:setReelBg( bgName )
    bgName = bgName or "normal"
    if bgName == "normal" then
        for i=0,4 do
            self.m_csbOwner["reel_bg_base_" .. i]:setVisible(true)
            self.m_csbOwner["reel_bg_frs_" .. i]:setVisible(false)
        end
    -- elseif bgName == "free" then
    else
        for i=0,4 do
            self.m_csbOwner["reel_bg_base_" .. i]:setVisible(true)
            self.m_csbOwner["reel_bg_frs_" .. i]:setVisible(false)
        end
    end
end

function CodeGameScreenGoldenGhostMachine:changeTopUIState()
    local spinMode = self:getCurrSpinMode()
    local isPickBonus = self:isInPickBonus()

    --正常模式
    if spinMode == NORMAL_SPIN_MODE then
        --respin
        self.m_jackPotBar:setVisible(true)
        self.m_pumpkinParent:setVisible(true)
        self.goldMidTopUI:setVisible(false)
        self.m_topUi_pot:setVisible(false)
        self.freeSpinTopUI:setVisible(false)
        self.bonusRespinBar:setVisible(false)
        self.bonusTopUI:setVisible(false)
        self.bonusFreeSpinBar:setVisible(false)

        self.m_frame:setVisible(not isPickBonus)
        self.m_frame_0:setVisible(false)
        self.m_lines_left:setVisible(not isPickBonus)
        self.m_lines_right:setVisible(not isPickBonus)
        --先注释
        -- self.potNode:setVisible(true)
        -- 
        -- 
        -- 
        -- 
        -- self.totalWin:setVisible(false)
        -- self.baseLine:setVisible(true)
        -- self.fgLine:setVisible(false)
        -- self.reLine:setVisible(false)
    elseif spinMode == RESPIN_MODE then
        --freespin
        self.m_jackPotBar:setVisible(false)
        self.m_pumpkinParent:setVisible(false)
        self.goldMidTopUI:setVisible(true)
        self.m_topUi_pot:setVisible(true)
        self.freeSpinTopUI:setVisible(false)
        self.bonusRespinBar:setVisible(true)
        self.bonusRespinBar:setCount(0,6)
        self.bonusTopUI:setVisible(true)
        self.bonusFreeSpinBar:setVisible(false)

        self.m_frame:setVisible(false)
        self.m_frame_0:setVisible(true)
        self.m_lines_left:setVisible(false)
        self.m_lines_right:setVisible(false)
        --先注释
        -- self.potNode:setVisible(false)
        -- 
        -- 
        -- 
        
        -- self.totalWin:setVisible(true)
        -- self.baseLine:setVisible(false)
        -- self.fgLine:setVisible(false)
        -- self.reLine:setVisible(true)
    elseif spinMode == FREE_SPIN_MODE then
        self.m_jackPotBar:setVisible(false)
        self.m_pumpkinParent:setVisible(false)
        self.goldMidTopUI:setVisible(true)
        self.m_topUi_pot:setVisible(true)
        self.freeSpinTopUI:setVisible(true)
        self.bonusRespinBar:setVisible(false)
        self.bonusTopUI:setVisible(false)
        self.bonusFreeSpinBar:setVisible(true)

        self.m_frame:setVisible(false)
        self.m_frame_0:setVisible(true)
        self.m_lines_left:setVisible(false)
        self.m_lines_right:setVisible(false)
        --先注释 
        -- self.potNode:setVisible(false)
        -- 
        -- 
        -- 
        -- self.bonusFreeSpinBar:setCount(0,8)
        -- 
        -- self.baseLine:setVisible(false)
        -- self.fgLine:setVisible(true)
        -- self.reLine:setVisible(false)
    end
end

function CodeGameScreenGoldenGhostMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
        hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end

    local isInFs = false
    local initSpinData = self.m_initSpinData
    local initFeatureData = self.m_initFeatureData
    if not hasFreepinFeature then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        if initFeatureData ~= nil then
            local initFeatureDataIn = initFeatureData.p_data
            if (initFeatureDataIn ~= nil and initFeatureDataIn.freespin ~= nil and initFeatureDataIn.freespin.freeSpinsLeftCount > 0 and initFeatureDataIn.freespin.freeSpinsTotalCount > 0) then
                isInFs = true
                self.m_runSpinResultData.p_freeSpinsLeftCount = initFeatureDataIn.freespin.freeSpinsLeftCount
                self.m_runSpinResultData.p_freeSpinsTotalCount = initFeatureDataIn.freespin.freeSpinsTotalCount
            end
        elseif (initSpinData.p_freeSpinsTotalCount ~= nil and initSpinData.p_freeSpinsTotalCount > 0 and initSpinData.p_freeSpinsLeftCount > 0) then
            isInFs = true
        end
    end

    if isInFs == true then
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:changeReSpinUpdateUI(globalData.slotRunData.freeSpinCount,globalData.slotRunData.totalFreeSpinCount)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        self:setCurrSpinMode(FREE_SPIN_MODE)
        --先注释 
        -- self.guang:setVisible(true)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenGoldenGhostMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    local initSpinData = self.m_initSpinData
    local initFeatureData = self.m_initFeatureData
    local triggerFlag = false
    if initFeatureData ~= nil then
        local initFeatureDataIn = initFeatureData.p_data
        triggerFlag = initFeatureDataIn ~= nil and initFeatureDataIn.respin ~= nil and initFeatureDataIn.respin.reSpinCurCount > 0 and initFeatureDataIn.respin.reSpinsTotalCount > 0
        if triggerFlag then
            initSpinData.p_reSpinsTotalCount = initFeatureDataIn.respin.reSpinsTotalCount
            initSpinData.p_reSpinCurCount = initFeatureDataIn.respin.reSpinCurCount
        end
    elseif initSpinData ~= nil then
        triggerFlag = initSpinData.p_reSpinsTotalCount ~= nil and initSpinData.p_reSpinsTotalCount > 0 and initSpinData.p_reSpinCurCount > 0
    end
    if triggerFlag then
        --手动添加freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        local reSpinEffect = GameEffectData.new()
        reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
        reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

        self.m_isRunningEffect = true

        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenGoldenGhostMachine:initFeatureInfo(spinData, featureData)
    local bonus = featureData.p_bonus
    if bonus ~= nil and bonus.extra then
        local bonusExtra = bonus.extra
        local pickTimes = bonusExtra.pickTimes
        if pickTimes ~= nil and pickTimes > 0 then
            util_spinePlay(self.m_pumpkin,"idle3",true)
            local bonusGame = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusGame")
            self.bonusGame = bonusGame
            self.isInBonus = true
            bonusGame:resetView(
                self,
                bonusExtra,
                function(extraData)
                    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
                    gLobalSoundManager:playSound(levelConfig.Sound_Guochang_RespinToBase)

                    self:playChangeEffect(
                        function()
                            util_spinePlay(self.m_pumpkin,"idle1",true)

                            self:closeBonusGame()
                            self:changeTopUIState()
                            self:changeSpineBgShow()
                        end,
                        function ( ... )
                            -- body
                            self:checkTriggerOtherGame(extraData)
                            self:changeTopUIState()
                            self:changeSpineBgShow()
                        end,
                        true
                    )
                end
            )
            self:findChild("bonusGameNode"):addChild(bonusGame)
            local bonusGameSize = bonusGame.m_csbNode:getContentSize()
            bonusGame:setPosition(-bonusGameSize.width/2, -bonusGameSize.height/2)
            -- gLobalViewManager:showUI(bonusGame)
        else
            local bonus = bonusExtra.bonuses
            if bonus ~= nil and #bonus > 0 then
                local bonusGameEffect = GameEffectData.new()
                bonusGameEffect.featureBonus = bonus
                bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
                bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
                self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
                if bonus[1] ~= "selectBonus" then
                    self:returnToNormalSpinMode()
                end
                --bugly 这个地方会和OnEnter()内重复调用，导致一个事件播两次
                -- self:playGameEffect()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
            end
        end
    end
end

-- 断线重连 
function CodeGameScreenGoldenGhostMachine:MachineRule_initGame(  )
    --是否重连reSpin模式
    self.m_bIsRespinReconnect = (self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0)

end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGoldenGhostMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "GoldenGhost"  
end

-- 继承底层respinView
function CodeGameScreenGoldenGhostMachine:getRespinView()
    return "CodeGoldenGhostSrc.GoldenGhostRespinView"
end
-- 继承底层respinNode
function CodeGameScreenGoldenGhostMachine:getRespinNode()
    return "CodeGoldenGhostSrc.GoldenGhostRespinNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGoldenGhostMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀

    if symbolType == self.SYMBOL_FIX_BONUS_LV1 then
        return "Socre_GoldenGhost_BonusBg"
    elseif symbolType == self.SYMBOL_FIX_BONUS_LV2 then
        return "Socre_GoldenGhost_BonusBg"
    elseif symbolType == self.SYMBOL_FIX_BONUS_LV3 then
        return "Socre_GoldenGhost_BonusBg"

    elseif symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN then
        return "Socre_GoldenGhost_SpinPlus"
    elseif symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 then
        return "Socre_GoldenGhost_BonusBg"
    elseif symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
        return "Socre_GoldenGhost_BonusBg"
    -- h2 h3 互换
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        return "Socre_GoldenGhost_7"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        return "Socre_GoldenGhost_8"
    end
    
    return nil
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenGoldenGhostMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    for k, v in ipairs(storedIcons) do
        if v[1] == id then
            score = v[2]
            break
        end
    end
    return score
end

function CodeGameScreenGoldenGhostMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    if symbolType == self.SYMBOL_FIX_BONUS_LV1 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 给respin小块进行赋值
function CodeGameScreenGoldenGhostMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    symbolNode:runAnim("idleframe", true)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local symbolType = symbolNode.p_symbolType
    symbolType = self:formatAddSpinSymbol(symbolType)
    local totalBet = globalData.slotRunData:getCurTotalBet()

    local addSpinSp = symbolNode:getCcbProperty("spin_1")
    if(addSpinSp) then
        addSpinSp:setVisible(false)
    end

    -- if self.changeEffect then
    --     symbolNode:setVisible(false)
    -- end
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        if(score ~= nil) then
            --respin更新分数
            local lbScore = symbolNode:getCcbProperty("m_lb_score")
            if lbScore == nil then
                return
            end
            -- local numStr = util_formatCoins(totalBet * score,3)
            local numStr = self:getCoinsByScore(score)
            lbScore:setString(numStr)

            local curSpinMode = self:getCurrSpinMode()
            if curSpinMode == RESPIN_MODE then
                if self.addSpinSymbolNum == 0 then
                    if  symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or 
                        symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
                        addSpinSp:setVisible(true)
                        addSpinSp:setOpacity(255)
                        lbScore:setVisible(false)
                    end
                else
                    if self:isBonusSymbol(symbolType) then
                        self.addSpinSymbolNum = self.addSpinSymbolNum - 1
                    end
                end
            else
                lbScore:setVisible(true)
            end
        end
    else
        local lbScore = symbolNode:getCcbProperty("m_lb_score")

        if  symbolType == self.SYMBOL_FIX_BONUS_LV2 or symbolType == self.SYMBOL_FIX_BONUS_LV3 then
            lbScore:setVisible(false)
        else
            local score = self:randomDownRespinSymbolScore(symbolType) -- 获取随机分数（本地配置）
            if score ~= nil then
                if lbScore then
                    -- local numStr = util_formatCoins(totalBet * score,3)
                    local numStr = self:getCoinsByScore(score)
                    lbScore:setString(numStr)
                end
            end
        end
    end

end

function CodeGameScreenGoldenGhostMachine:getBonusLv1TotalScore( ... )
    -- body
    local totalScore = 0
    if self.lv1TotalScore == 0 then
        local reelRow = self.m_iReelRowNum
        local reelCol = self.m_iReelColumnNum
        for i = 1,reelRow do
            for j = 1,reelCol do
                local symbolNode = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
                local symbolType = symbolNode.p_symbolType
                if symbolType == self.SYMBOL_FIX_BONUS_LV1 then
                    local score = self:getScoreInfoByPos(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
                    if score then
                        totalScore = totalScore + score
                    end
                end
            end
        end
        self.lv1TotalScore = totalScore
    else
        totalScore = self.lv1TotalScore 
    end
    return totalScore
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGoldenGhostMachine:getPreLoadSlotNodes()
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    local loadNode = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS, count = 3},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_ADDSPIN, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_ADDSPIN_LV2, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_ADDSPIN_LV3, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_LV1, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_LV2, count = 3},
        {symbolType = self.SYMBOL_FIX_BONUS_LV3, count = 3}
    }
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 是不是respinBonus小块
function CodeGameScreenGoldenGhostMachine:isFixSymbol(symbolType)
    if  symbolType == self.SYMBOL_FIX_BONUS_LV1 or
        symbolType == self.SYMBOL_FIX_BONUS_LV2 or 
        symbolType == self.SYMBOL_FIX_BONUS_LV3 or
        symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or 
        symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3
    then
        return true
    end
    return false
end
--
--单列滚动停止回调
--
function CodeGameScreenGoldenGhostMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self:getGameSpinStage() == QUICK_RUN then
        if reelCol == self.m_iReelColumnNum then
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
   
   self:checkPlayDownBonusNodeAnim(reelCol)
end

--播放特殊信号动画
function CodeGameScreenGoldenGhostMachine:checkPlayDownBonusNodeAnim(reelCol)
    local reelRow = self.m_iReelRowNum
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode ~= RESPIN_MODE then
        local hasBonus = false
        for i = 1, reelRow do
            local symbolNode = self:getFixSymbol(reelCol, i, SYMBOL_NODE_TAG)
            if symbolNode then

                if self:isBonusSymbol(symbolNode.p_symbolType) then
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = symbolNode.p_rowIndex, iY = symbolNode.p_cloumnIndex}
                    symbolNode.m_bInLine = true
                    symbolNode:setLinePos(linePos)

                    local order = self:getBounsScatterDataZorder(symbolNode.p_symbolType) - reelRow
                    symbolNode = util_setSymbolToClipReel(self,symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, order)
                end
                

                local symbolType = symbolNode.p_symbolType
                if symbolType == self.SYMBOL_FIX_BONUS_LV1 or 
                    symbolType == self.SYMBOL_FIX_BONUS_LV2 or 
                    symbolType == self.SYMBOL_FIX_BONUS_LV3 then
                    
                    hasBonus = true
                    symbolNode:runAnim("buling", false,function ( ... )
                        -- body
                        symbolNode:runAnim("idleframe1", true)

                    end)

                    if reelCol < self.m_iReelColumnNum then
                        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
                        local soundPath = levelConfig.Sound_Buling_Bonus
                        self:playBulingSymbolSounds( reelCol,soundPath )
                    end

                    if symbolType == self.SYMBOL_FIX_BONUS_LV1 then
                        if not self.freeHasBonusLv1 then
                            self.freeHasBonusLv1 = true
                        end
                    elseif symbolType == self.SYMBOL_FIX_BONUS_LV2 then
                        if not self.freeHasBonusLv2 then
                            self.freeHasBonusLv2 = true
                            -- 先注释
                            -- gLobalSoundManager:playSound("GoldenGhostSounds/music_GoldenGhost_surprises.mp3")
                        end

                    end
                -- 不播放wild落地 动效和音效
                elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    -- symbolNode:runAnim("buling", false,function ( ... )
                    --     symbolNode:runAnim("idleframe", true)
                    -- end)
                    if not self.hasWildFlag then
                        self.hasWildFlag = true
                        -- local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
                        -- gLobalSoundManager:playSound(levelConfig.Sound_Buling_Wild)
                    end
                end
            end
        end
        self.freeHasBonusLv1 = false
        self.hasWildFlag = false
    end
end

function CodeGameScreenGoldenGhostMachine:showFreeSpinStartView( ... )
    self.m_bIsSelectCall = false
    self:playGameEffect()
end

function CodeGameScreenGoldenGhostMachine:spinResultCallFun(param)
    BaseFastMachine.spinResultCallFun(self, param)
    if self.m_bIsSelectCall then
        local m_iSelectID = self.m_iSelectID
        self:returnToNormalSpinMode()

        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
        gLobalSoundManager:playSound(levelConfig.Sound_Guochang_BaseToRespin)

        if m_iSelectID == 1 then
            self.m_iFreeSpinTimes = 0
            globalData.slotRunData.freeSpinCount = 0
            globalData.slotRunData.totalFreeSpinCount = 0
            self.m_bProduceSlots_InFreeSpin = false
            if self.m_gameEffect then
                self.m_gameEffect.p_isPlay = true
            end

            self.m_chooseRepin = true

            self:playChangeEffect(
                function()
                    self.m_bottomUI:resetWinLabel()
                    self.m_bottomUI:checkClearWinLabel()

                    self:closeBonusPopUpUI()
                    self:showRespinStartView()
                    self:playGameEffect()
                    self:changeTopUIState()
                    self:changeSpineBgShow()
                    --刷新reSpinBar次数 首次默认是6
                    self:changeReSpinUpdateUI(6)
                end,
                function()
                    --
                    if self.m_bonusNum < 11 then
                        self:runNextReSpinReel()
                    end
                    
                end
            )
        else
            globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
            globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes

            self:playChangeEffect(
                function()
                    self.m_bottomUI:resetWinLabel()
                    self.m_bottomUI:checkClearWinLabel()

                    self:triggerFreeSpinCallFun()
                    --切换free背景
                    if self.m_gameEffect then
                        self.m_gameEffect.p_isPlay = true
                    end
                    self:closeBonusPopUpUI()
                    self:changeTopUIState()
                    self:changeSpineBgShow()
                    self:playSpineBgStartAnim()
                    -- self:checkChangeFsCount()
                    local totalFreeSpinCount = globalData.slotRunData.totalFreeSpinCount
                    self:changeReSpinUpdateUI(totalFreeSpinCount, totalFreeSpinCount)
                end,
                function()
                    self:showFreeSpinStartView()
                end
            )
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end
    end
    self.m_bIsSelectCall = false
end

function CodeGameScreenGoldenGhostMachine:playChangeEffect(callBack, endCallBack,actionReturn)
    local changeEffect = util_createView("CodeGoldenGhostSrc.GoldenGhostChangeEffect")
    self.changeEffect = changeEffect
    changeEffect:setScale(self.m_machineRootScale)
    changeEffect:setExtraInfo(self)
    changeEffect:setPosition(display.width / 2, display.height / 2)
    local function middleCallBack( ... )
        -- body
        if callBack then
            callBack()
        end
    end
    local function lEndCallBack( ... )
        -- body
        self:resetMusicBg()
        -- 先注释
        -- self:setMinMusicBGVolume()
        if endCallBack then
            endCallBack()
        else
            -- 先注释
            -- self:setMaxMusicBGVolume()
        end
    end
    changeEffect:play(middleCallBack, lEndCallBack,actionReturn)
    gLobalViewManager:showUI(changeEffect,ViewZorder.ZORDER_UI-1)-- ViewZorder.ZORDER_SPECIAL
    gLobalSoundManager:pauseBgMusic()
end

function CodeGameScreenGoldenGhostMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()
    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        -- self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)

    self.m_bProduceSlots_InFreeSpin = true
    self:setReelBg("free")
end

function CodeGameScreenGoldenGhostMachine:showEffect_Bonus(effectData)
    local runSpinResultData = self.m_runSpinResultData
    local selfMakeData = runSpinResultData.p_selfMakeData
    local freeSpinData = selfMakeData.triggerTimes_FREESPIN
    local respinData = selfMakeData.triggerTimes_RESPIN
    if selfMakeData and freeSpinData then
        if freeSpinData ~= nil then
            self.m_iFreeSpinTimes = freeSpinData.times
            self:changeReSpinUpdateUI(self.m_iFreeSpinTimes,freeSpinData.times)
        end
        if self.m_bProduceSlots_InFreeSpin == false and respinData ~= nil then
            self.m_iRespinTimes = respinData.times
        end
    end
    return BaseFastMachine.showEffect_Bonus(self, effectData)
end

--播放respin放回滚轴后播放的提示动画
function CodeGameScreenGoldenGhostMachine:checkRespinChangeOverTip(node, endAnimaName, loop)
    node:runAnim("idleframe", false)
    if not self:isBonusSymbol(node.p_symbolType) and node.p_symbolType ~= self.SYMBOL_FIX_BONUS_ADDSPIN then
        local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
        if imageName ~= nil then
            local name = imageName[1]
            node:spriteChangeImage(node.p_symbolImage, name)
            if node.p_symbolImage then
                if imageName[4] then
                    node.p_symbolImage:setScale(imageName[4])
                end
            end
        end
    end
end

--触发respin
function CodeGameScreenGoldenGhostMachine:triggerReSpinCallFun(endTypes, randomTypes)
    self:setCurrSpinMode(RESPIN_MODE)

    self.m_specialReels = true
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()

    local respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView = respinView
    respinView:setExtraInfo(self)
    respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )

    self:reSpinChangeReelSymbolVisible(false)
    --先注释 
    -- self.m_reelRespinBg:setVisible(true)
    self.m_reelRespinBg:addChild(respinView)

    self:initRespinView(endTypes, randomTypes)
end

function CodeGameScreenGoldenGhostMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()
    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
                    -- self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    if not self.m_bIsSelectCall then
                        self:runNextReSpinReel()
                    end
                end
            )
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--ReSpin开始改变UI状态
function CodeGameScreenGoldenGhostMachine:changeReSpinStartUI(respinCount)
end



function CodeGameScreenGoldenGhostMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - iRow + iCol + self:formatAddSpinSymbol(symbolType)
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}
            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale
            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end
-- 触发bonus时 先将顶部 ui 进化到 3阶段 维持 idle模式
function CodeGameScreenGoldenGhostMachine:bonusStartTopUiChange(_fun)
    local maxLevel = 3

    if self.curPotActionIdx < maxLevel then
        local idleName = string.format("idle%dto%d", self.curPotActionIdx, self.curPotActionIdx+1)
        util_spinePlay(self.m_pumpkin, idleName, false)
        util_spineEndCallFunc(self.m_pumpkin,idleName,function()
            self.curPotActionIdx = math.min(self.curPotActionIdx + 1, maxLevel) 
            self:bonusStartTopUiChange(_fun)
        end)
    else
        if _fun then
            _fun()
        end
    end
end
function CodeGameScreenGoldenGhostMachine:showBonusGame(func)
    self:bonusStartTopUiChange(function ()
        local actionName = string.format("actionframe4_%d", self.curPotActionIdx)
    
        util_spinePlay(self.m_pumpkin, actionName, false)
        util_spineEndCallFunc(self.m_pumpkin,actionName,function()
            self.triggerSmallGameFlag = false
            self.isInBonus = true

            local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
            gLobalSoundManager:playSound(levelConfig.Sound_Guochang_BaseToRespin)

            self:playChangeEffect(
                function()
                    self.m_bottomUI:resetWinLabel()
                    self.m_bottomUI:checkClearWinLabel()

                    util_spinePlay(self.m_pumpkin,"idle3",true)
                    local bonusGame = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusGame")
                    self.bonusGame = bonusGame
                    bonusGame:initViewData(self, func)
                    self:findChild("bonusGameNode"):addChild(bonusGame)
                    local bonusGameSize = bonusGame.m_csbNode:getContentSize()
                    bonusGame:setPosition(-bonusGameSize.width/2, -bonusGameSize.height/2)
                -- gLobalViewManager:showUI(bonusGame)

                    self:changeTopUIState()
                    self:changeSpineBgShow()
                end
            )
        end)
        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
        gLobalSoundManager:playSound(levelConfig.Sound_BonusPick_Start)
    end)
    
end

function CodeGameScreenGoldenGhostMachine:showBonusGameView(effectData)
    if effectData.p_effectType == GameEffect.EFFECT_BONUS then
        self:clearWinLineEffect()

        local gameType = self:getBonusGameType(effectData.featureBonus)
        if gameType == "selectBonus" then
            local levelConfig = globalMachineController.p_GoldenGhostMachineConfig

            local function createBonusUI()
                -- self:clearCurMusicBg()

                local bonusPopUpUI = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusPopUpUI")
                self.bonusPopUpUI = bonusPopUpUI
                bonusPopUpUI:setExtraInfo(
                    self,
                    function(index)
                        --延迟1s
                        local waitNode = cc.Node:create()
                        self:addChild(waitNode)
                        performWithDelay(waitNode,function()
                            self:sendSelectBonus(index)
                            self.m_bIsSelectCall = true
                            self.m_iSelectID = index
                            self.m_gameEffect = effectData

                            waitNode:removeFromParent()
                        end, 1)
                        
                    end
                )
                gLobalViewManager:showUI(bonusPopUpUI)
            end
            util_performWithDelay(self, function( )
                self:playTriggerBonusNodeAnim(
                    function()
                        util_performWithDelay(self, createBonusUI, 1)
                    end
                )
            end, 0.5)

            self.freeSpinTopUI:updateScore()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
            gLobalSoundManager:playSound(levelConfig.Sound_Bonus_Start)
        elseif gameType == "pickBonus" then
            self.m_gameEffect = effectData
            self:returnToNormalSpinMode()
            util_performWithDelay(self, function( )
                self:showBonusGame(
                    function(extraData)

                        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
                        gLobalSoundManager:playSound(levelConfig.Sound_Guochang_RespinToBase)

                        self:playChangeEffect(
                            function()
                                self.curPotActionIdx = 1
                                util_spinePlay(self.m_pumpkin,"idle1",true)

                                self:closeBonusGame()
                                self:changeTopUIState()
                                self:changeSpineBgShow()
                            end,
                            function ( ... )
                                self:checkTriggerOtherGame(extraData)
                                -- self:changeTopUIState()
                                -- self:changeSpineBgShow()
                            end,
                            true
                        )
                    end
                )
            end,0.5)
        end
    end
end

function CodeGameScreenGoldenGhostMachine:returnToNormalSpinMode()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        if self.m_handerIdAutoSpin ~= nil then
            scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
            self.m_handerIdAutoSpin = nil
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
end

function CodeGameScreenGoldenGhostMachine:playTriggerBonusNodeAnim(callBack)
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolNode = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
            if symbolNode ~= nil then
                local symbolType = symbolNode.p_symbolType
                if symbolType == self.SYMBOL_FIX_BONUS_LV1 then
                    symbolNode:runAnim(
                        "actionframe",
                        false,
                        function()
                            if callBack ~= nil then
                                callBack()
                                callBack = nil
                            end
                        end
                    )
                end
            end
        end
    end
end

function CodeGameScreenGoldenGhostMachine:getBonusGameType(featureBonus)
    local bonusExtraData = self.m_runSpinResultData.p_bonusExtra
    local bonuses = featureBonus or (bonusExtraData and bonusExtraData.bonuses) or {}
    local gameType = nil
    for k, v in ipairs(bonuses) do
        gameType = v
        if v == "pickBonus" then
            break
        end
    end
    return gameType
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenGoldenGhostMachine:levelFreeSpinEffectChange()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    if fsExtraData ~= nil then
        local collectBonusMultiples = fsExtraData.collectBonusMultiples or 0
        local coins = self:getCoinsNumByScore(collectBonusMultiples)
        self:setFreeSpinScore(coins, false)
    else
        self:setFreeSpinScore(0, false)
    end
    if self.changeEffect == nil then
        --先注释
        -- self.bgEffect:setVisible(false)
        -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"switch", false, function ( ... )
        --     gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
            -- self.bgEffect:setVisible(true)
            -- util_spinePlay(self.bgEffect, "freespin", true)
        -- end})
        self.freeSpinTopUI:updateScore()
        self:changeTopUIState()
        self:changeSpineBgShow()
    end
    
end

function CodeGameScreenGoldenGhostMachine:setFreeSpinScore(score, playAnimFlag)
    self.m_freeSpinScore = score
    if self.goldMidTopUI ~= nil then
        self.goldMidTopUI:setScore(score, playAnimFlag)
    end
end

function CodeGameScreenGoldenGhostMachine:getFreeSpinScore()
    return self.m_freeSpinScore
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenGoldenGhostMachine:levelFreeSpinOverChangeEffect()
    self:setFreeSpinScore(0, false)
end
---------------------------------------------------------------------------
-- 触发freespin结束时调用
function CodeGameScreenGoldenGhostMachine:showFreeSpinOverView()
    local freeSpinScore = self:getFreeSpinScore()
    local function callBack()
        local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 20)
        local view = self:showFreeSpinOver(strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,
            function()
                local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
                gLobalSoundManager:playSound(levelConfig.Sound_Guochang_RespinToBase)

                -- 调用此函数才是把当前游戏置为freespin结束状态
                self:playChangeEffect(
                    function()
                        self:setCurrSpinMode(NORMAL_SPIN_MODE)
                        self:changeTopUIState()
                        --先播放over再隐藏掉切换spine背景的展示
                        self:playSpineBgOverAnim(FREE_SPIN_MODE, function()
                            self:changeSpineBgShow()
                        end)
                        --先注释
                        -- self.bgEffect:setVisible(false)
                        -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"switch2", false, function ( ... )
                        --     gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
                            --先注释 
                            -- self.guang:setVisible(false)
                            self:setReelBg()
                            -- self.bgEffect:setVisible(true)
                            -- util_spinePlay(self.bgEffect, "normal", true)
                        -- end})
                    end,
                    function ( ... )
                        self:triggerFreeSpinOverCallFun()
                    end,
                    true
                )
            end
        )
        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
        gLobalSoundManager:playSound(levelConfig.Sound_Free_Over)
    end
    if freeSpinScore > 0 then
        self:flyBottomEffect(callBack, globalData.slotRunData.lastWinCoin,freeSpinScore)
    else
        callBack()
    end
end

function CodeGameScreenGoldenGhostMachine:showRespinJackpot(index,coins,func)
    self:showSpineTanbanMask()
    local endFun = function()
        self:closeSpineTanbanMask()

        if func then
            func()
        end
    end

    local jackPotWinView = util_createView("CodeGoldenGhostSrc.GoldenGhostJackPotWinView", self)
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,endFun,self)

    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
    gLobalSoundManager:playSound(levelConfig.Sound_BonusPick_JackPot)
end

--结束移除小块调用结算特效
function CodeGameScreenGoldenGhostMachine:reSpinEndAction()    
    self:clearCurMusicBg()
    local midTopScore = self.goldMidTopUI:getScore()
    if midTopScore > 0 then
        performWithDelay(
            self,
            function()
                self:flyBottomEffect(
                    function()
                        performWithDelay(self, handler(self, self.respinOver), 0.5)
                    end,
                    globalData.slotRunData.lastWinCoin
                )
            end,
            1
        )
    else
        self:respinOver()
    end
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenGoldenGhostMachine:getRespinRandomTypes()
    -- respin里不会有高级图标滚动
    local symbolList = {
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        -- TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
    }
    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenGoldenGhostMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_FIX_BONUS_LV1, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_FIX_BONUS_LV2, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_FIX_BONUS_LV3, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_FIX_BONUS_ADDSPIN_LV2, runEndAnimaName = "", bRandom = false},
        {type = self.SYMBOL_FIX_BONUS_ADDSPIN_LV3, runEndAnimaName = "", bRandom = false},
    }
    return symbolList
end

function CodeGameScreenGoldenGhostMachine:showRespinView(effectData)
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode ~= RESPIN_MODE then
        --先播放动画 再进入respin
        self:clearCurMusicBg()
        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes()
        --可随机的特殊信号
        local endTypes = self:getRespinLockTypes()
        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)
    end
end

function CodeGameScreenGoldenGhostMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

--ReSpin刷新数量
function CodeGameScreenGoldenGhostMachine:changeReSpinUpdateUI(curCount,totalCount)
    print("当前展示位置信息 %d ", curCount)
    local spinMode = self:getCurrSpinMode()
    if spinMode == RESPIN_MODE then
        totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
        if totalCount == 0 then
            totalCount = 6
        end
        self.curRespinTimes = curCount
        self.curTotalRespinTimes = totalCount
        -- self.m_baseFreeSpinBar:updateFreespinCount(curCount)
        local leftCount = self.curRespinTimes
        self.bonusRespinBar:setCount(leftCount, totalCount)

        self.bonusRespinBar:findChild("spins"):setVisible( leftCount>1 )
        self.bonusRespinBar:findChild("spin"):setVisible( leftCount<=1 )

    elseif spinMode == FREE_SPIN_MODE then
        totalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if totalCount == 0 then
            totalCount = globalData.slotRunData.totalFreeSpinCount
        end
        -- free模式左右两侧都展示剩余次数
        -- self.bonusFreeSpinBar:setCount(curCount, curCount)
        
        self.bonusFreeSpinBar:setCount(totalCount - curCount,totalCount)
    end
end

function CodeGameScreenGoldenGhostMachine:addRespinTimes( ... )

    self.curTotalRespinTimes = self.curTotalRespinTimes + 1
    if self.curTotalRespinTimes > self.m_runSpinResultData.p_reSpinsTotalCount then
        self.curTotalRespinTimes = self.m_runSpinResultData.p_reSpinsTotalCount
    end

    self.bonusRespinBar:setCount(nil,self.curTotalRespinTimes)
end

function CodeGameScreenGoldenGhostMachine:checkChangeFsCount()
    BaseFastMachine.checkChangeFsCount(self)
    local spinMode = self:getCurrSpinMode()
    if spinMode == FREE_SPIN_MODE then
        self:changeReSpinUpdateUI(globalData.slotRunData.freeSpinCount,globalData.slotRunData.totalFreeSpinCount)
    end
end

function CodeGameScreenGoldenGhostMachine:showRespinOverView(effectData)
    local midTopScore = self.goldMidTopUI:getScore()
    -- local strCoins = util_formatCoins(midTopScore, 11)
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 20)
    local view = self:showReSpinOver(strCoins,function()
                    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
                    gLobalSoundManager:playSound(levelConfig.Sound_Guochang_RespinToBase)

                    self:playChangeEffect(
                        function()
                            self:resetReSpinMode()
                            self:changeTopUIState()
                            self:changeSpineBgShow()
                            self:removeRespinNode()
                            self.lv1TotalScore = 0
                            --先注释 
                            -- self.m_reelRespinBg:setVisible(false)
                            self:reSpinChangeReelSymbolVisible(true)
                            self:setReelSlotsNodeVisible(true)
                            self:playBonusAnim()
                            --先注释
                            -- self.bgEffect:setVisible(false)
                            -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"switch2", false, function ( ... )
                            --     gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
                                --先注释 
                                -- self.guang:setVisible(false)
                                -- self.bgEffect:setVisible(true)
                                -- util_spinePlay(self.bgEffect, "normal", true)
                            -- end})
                        end,
                        function ( ... )
                            -- body
                            self:triggerReSpinOverCallFun(midTopScore)
                            self:reSetSymbolOrder()
                        end,
                        true
                    )
                end)
    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
    gLobalSoundManager:playSound(levelConfig.Sound_Respin_OverView)
end

function CodeGameScreenGoldenGhostMachine:reSpinChangeReelSymbolVisible(_visible)
    --裁切层小块放回滚轴
    self:checkChangeBaseParent()
    
    for iCol,_parentData in ipairs(self.m_slotParents) do
        -- 低层级
        if _parentData.slotParent then
            _parentData.slotParent:setVisible(_visible)
        end
        -- 高层级
        if _parentData.slotParentBig then
            _parentData.slotParentBig:setVisible(_visible)
        end
    end
end
function CodeGameScreenGoldenGhostMachine:reSpinReelDown(addNode)
    self.m_respinView:handleTriggerResult(
        function()
            --10.27补充底层的两行代码，解决reSpin按钮点击后无法置灰可被多次点击问题
            self:setGameSpinStage(STOP_RUN)
            self:updateQuestUI()

            self.m_respinView:updatePreLockNodeList()

            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
                --结束
                self:reSpinEndAction()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_BONUS)
                self.m_isWaitingNetworkData = false
                return
            end

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
            if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
                self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
            end
            self:runNextReSpinReel()
        end
    )
end

function CodeGameScreenGoldenGhostMachine:respinOver()
    self:showRespinOverView()
end

function CodeGameScreenGoldenGhostMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
    local curSpinMode = self:getCurrSpinMode()
    if self.m_bQuestComplete and curSpinMode ~= RESPIN_MODE and curSpinMode ~= FREE_SPIN_MODE then
        if curSpinMode == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end
    if curSpinMode == AUTO_SPIN_MODE or curSpinMode == FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                -- gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif curSpinMode == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    elseif self.m_chooseRepin then
        self.m_chooseRepin = false
        self:showRespinView()
    end


end

function CodeGameScreenGoldenGhostMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        if self:checktriggerSpecialGame( ) then
            self:removeSoundHandler()
        else
            self:reelsDownDelaySetMusicBGVolume()
        end
    end)
    BaseFastMachine.slotReelDown(self)
end

function CodeGameScreenGoldenGhostMachine:playBonusAnim()
    local reelRow = self.m_iReelRowNum
    local reelColumn = self.m_iReelColumnNum
    for i = 1, reelRow do
        for j = 1, reelColumn do
            local symbolNode = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
            local symbolType = self:formatAddSpinSymbol(symbolNode.p_symbolType)
            if symbolNode and (symbolType == self.SYMBOL_FIX_BONUS_LV1 or symbolType == self.SYMBOL_FIX_BONUS_LV2 or symbolType == self.SYMBOL_FIX_BONUS_LV3) then
                symbolNode:runAnim("idleframe1", true)
            end
        end
    end
end

-- --重写组织respinData信息
function CodeGameScreenGoldenGhostMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        
        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenGoldenGhostMachine:MachineRule_SpinBtnCall()
    -- self:removeSoundHandler()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)
    -- if self.m_winSoundsId then
    --     gLobalSoundManager:stopAudio(self.m_winSoundsId)
    --     self.m_winSoundsId = nil
    -- end

    self:stopLinesWinSound()
    if self.m_winSoundsId_2 then
        gLobalSoundManager:stopAudio(self.m_winSoundsId_2)
        self.m_winSoundsId_2 = nil
    end
    self:setMaxMusicBGVolume( )

    

    return false -- 用作延时点击spin调用
end

function CodeGameScreenGoldenGhostMachine:MachineRule_respinTouchSpinBntCallBack()
    local status = self.m_respinView:getouchStatus()
    if status == ENUM_TOUCH_STATUS.ALLOW then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)
        self:startReSpinRun()
    elseif status == ENUM_TOUCH_STATUS.RUN then
        --快停
        self:quicklyStop()
        if self.m_respinView:quickStop(status) then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})   
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)
        end
    elseif status == ENUM_TOUCH_STATUS.QUICK_STOP then
        if self.m_respinView:quickStop(status) then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})    
        end    
    end
end

function CodeGameScreenGoldenGhostMachine:enterGamePlayMusic(  )
    local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
    self:playEnterGameSound(levelConfig.Music_enterLevel)
end

function CodeGameScreenGoldenGhostMachine:addObservers()
	BaseFastMachine.addObservers(self)
end

function CodeGameScreenGoldenGhostMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)  	-- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    globalMachineController.p_GoldenGhostMachineConfig = nil
end

-- ------------玩法处理 -- 

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGoldenGhostMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    -- 更新一下收集wild数据
    if selfData.wildCounts then
        self.wildCounts = selfData.wildCounts
    end

    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode == NORMAL_SPIN_MODE or curSpinMode == FREE_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SELF_PLAYFLYBONUS -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGoldenGhostMachine:MachineRule_playSelfEffect(effectData)
    --收集wild和bonus信号
    if effectData.p_selfEffectType == self.EFFECT_SELF_PLAYFLYBONUS then
        self:handleNormalSpinSlotReelDown(effectData)
    end
	return true
end

function CodeGameScreenGoldenGhostMachine:handleNormalSpinSlotReelDown(effectData)
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode == NORMAL_SPIN_MODE or curSpinMode == FREE_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
            self.freeHasBonusLv2 = false

            local reelRow = self.m_iReelRowNum
            local reelColumn = self.m_iReelColumnNum
            local hasWild = false
            local hasBonus = false

            for i = 1, reelColumn do
                for j = reelRow, 1, -1 do
                    local symbolNode = self:getFixSymbol(i, j, SYMBOL_NODE_TAG)
                    if curSpinMode == NORMAL_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
                        hasWild =self:playCollectWildAnimation(
                            hasWild,
                            symbolNode,
                            function()
                                    performWithDelay(
                                        self,
                                        function()
                                            self.wildNum = self.wildNum - 1
                                            if self.wildNum == 0 then
                                                effectData.p_isPlay = true
                                                self:playGameEffect()
                                            end
                                        end,
                                        0.1
                                    )
                            end
                        )
                    else
                        local symbolType = symbolNode.p_symbolType
                        if symbolType == self.SYMBOL_FIX_BONUS_LV2 then
                            hasBonus = true
                        end
                        performWithDelay(self,function ( ... )
                            -- body
                            --播放freeSpin收集小块动画
                            self:playCollectFreeSpinScoreAnimation(j, i, hasBonus, symbolNode,function ( ... )
                                -- body
                                performWithDelay(
                                    self,
                                    function()
                                        self.bonusNum = self.bonusNum - 1
                                        if self.bonusNum == 0 then
                                            self.freeBonusLv2Count = self:handleCheckFreeBonusLv2Count()
                                            if self.freeBonusLv2Count >= 3 then
                                                self.curEffectData = effectData
                                                self:showFreeSpinMoreUI()
                                            else
                                                effectData.p_isPlay = true
                                                self:playGameEffect()
                                            end
                                        end
                                    end,
                                    1
                                )
                            end)
                        end,0.3)
                    end
                end
            end

            if not hasWild and not hasBonus then
                effectData.p_isPlay = true
                self:playGameEffect()
            end

            if hasWild then
                local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
                gLobalSoundManager:playSound(levelConfig.Sound_Wild_Collect)
            end
    end
end

function CodeGameScreenGoldenGhostMachine:playCollectWildAnimation(hasWild, symbolNode, callBack)
    local curSpinMode = self:getCurrSpinMode()
    local rootParent = self.m_root:getParent()
    local diamondPos = self.m_pumpkin:getParent():convertToWorldSpace(cc.p(self.m_pumpkin:getPosition()))
    local pos = rootParent:convertToNodeSpace(cc.p(diamondPos.x, diamondPos.y + 150))

    if curSpinMode == NORMAL_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
        local symbolType = nil
        if symbolNode then
            symbolType = symbolNode.p_symbolType
        end
        if symbolType and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            self.wildNum = self.wildNum + 1
            hasWild = true

            local startPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
            local endPos = pos
            -- 创建粒子
            local flyNode = util_createAnimation( "GoldenGhost_wild_tuowei.csb" )
            rootParent:addChild(flyNode, REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
            flyNode:setPosition(startPos)

            flyNode:runCsbAction("actionframe",true,function()
                flyNode:stopAllActions()
                flyNode:removeFromParent()
                -- 策划要求,该事件取消spin按钮的点击禁用
                -- if callBack ~= nil then
                --     callBack()
                -- end
            end)

            local function getScoreLabel(node)
                local name = node:getName()
                if name == "Sprite_R" then
                    return node
                else
                    for k, v in ipairs(node:getChildren()) do
                        local n = getScoreLabel(v)
                        if n ~= nil then
                            return n
                        end
                    end
                end
            end
            local sp = getScoreLabel(flyNode)
            if sp then
                performWithDelay(sp,function ()
                    local startPos2 = cc.p(startPos.x - 50,startPos.y + 50)
                    local angle = util_getAngleByPos(startPos2,endPos)
                    sp:setRotation( - angle - 90)
    
                    local scaleSize = math.sqrt( math.pow( startPos2.x - endPos.x ,2) + math.pow( startPos2.y - endPos.y,2 ))
                    local scaleX = scaleSize / 250
                    sp:setScaleY(scaleX * 2)
                end,16/60)
            end
           
            self:playPotCollectAni()
            -- performWithDelay(self,function ()
            --     if callBack ~= nil then
            --         callBack()
            --     end
            -- end,16 / 60)

            if callBack ~= nil then
                callBack()
            end
        end
    end
    return hasWild
end

function CodeGameScreenGoldenGhostMachine:checkTriggerOtherGame(extraData)
    local bonus = extraData.bonuses
    if bonus ~= nil and #bonus > 0 then
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.featureBonus = bonus
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
        if bonus[1] ~= "selectBonus" then
            self:returnToNormalSpinMode()
        end
    end
    performWithDelay(self,function ( ... )
        -- body
        if self.m_gameEffect then
            self.m_gameEffect.p_isPlay = true
        end
        self:playGameEffect()
    end,0.7)
end

function CodeGameScreenGoldenGhostMachine:closeBonusGame()
    if self.bonusGame ~= nil then
        self.bonusGame:playCloseAnim()
        self.bonusGame = nil
        self.isInBonus = nil
    end
end

function CodeGameScreenGoldenGhostMachine:handleCheckFreeBonusLv2Count()
    local curSpinMode = self:getCurrSpinMode()
    local reelRow = self.m_iReelRowNum
    local reelCol = self.m_iReelColumnNum
    local bonusLv2Count = 0
    if curSpinMode == FREE_SPIN_MODE then
        for i = 1, reelRow do
            for j = 1, reelCol do
                local symbolNode = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
                if symbolNode and symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS_LV2 then
                    bonusLv2Count = bonusLv2Count + 1
                end
            end
        end
    end
    return bonusLv2Count
end

function CodeGameScreenGoldenGhostMachine:showFreeSpinMoreUI()
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinMore(
            self.m_runSpinResultData.p_freeSpinNewCount,
            function()
                self.bonusFreeSpinBar:playCollectEffect()
                self:changeReSpinUpdateUI(globalData.slotRunData.freeSpinCount,globalData.slotRunData.totalFreeSpinCount)
                self:clearCurEffectData()
            end,
            true
        )
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
        gLobalSoundManager:playSound(levelConfig.Sound_Free_More)
    end
end

function CodeGameScreenGoldenGhostMachine:playCollectFreeSpinScoreAnimation(rowIndex, colIndex, hasBonus, symbolNode,callBack)
    local curSpinMode = self:getCurrSpinMode()
    if curSpinMode == FREE_SPIN_MODE or curSpinMode == AUTO_SPIN_MODE then
        local rootParent = self.m_root:getParent()
        local goldPos = self.goldMidTopUI:getParent():convertToWorldSpace(cc.p(self.goldMidTopUI:getPosition()))
        local pos = rootParent:convertToNodeSpace(cc.p(goldPos.x, goldPos.y))

        local totalBet = globalData.slotRunData:getCurTotalBet()

        local symbolType = symbolNode.p_symbolType
        if symbolType == self.SYMBOL_FIX_BONUS_LV2 then
            -- performWithDelay(self,function ( ... )
                -- body
                hasBonus = true
                self.bonusNum = self.bonusNum + 1
                local score = self:getScoreInfoByPos(rowIndex, colIndex)
                if not score then
                    score = 1
                end

                symbolNode:runAnim("shouji", false,function ( ... )
                    symbolNode:runAnim("idleframe", true)
                end)

                local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
                gLobalSoundManager:playSound(levelConfig.Sound_BonusGreen_Collect_Start)

                util_performWithDelay(self,function ( ... )
                    local moveActionNode, effectLabelAct = util_csbCreate("GoldenGhost_coins.csb", true)
                    util_csbPauseForIndex(effectLabelAct, 30)
                    local function getScoreLabel(node)
                        local name = node:getName()
                        if name == "m_lb_coins" then
                            return node
                        else
                            for k, v in ipairs(node:getChildren()) do
                                local n = getScoreLabel(v)
                                if n ~= nil then
                                    return n
                                end
                            end
                        end
                    end
                    local lab = getScoreLabel(moveActionNode)
                    local coins = self:getCoinsNumByScore(score)
                    local coinsStr = self:getCoinsByScore(score)
                    -- lab:setString(util_formatCoins(totalBet * score,3))
                    lab:setString(coinsStr)
                    moveActionNode:setPosition(symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition())))
                    self:addChild(moveActionNode,symbolNode:getLocalZOrder() + REEL_SYMBOL_ORDER.REEL_ORDER_2_1)
                    local actionList = {}
                    actionList[#actionList + 1] = cc.Spawn:create(cc.MoveTo:create(0.5, pos),cc.ScaleTo:create(0.5,0.5))
                    actionList[#actionList + 1] = cc.CallFunc:create(function ( sender )
                        sender:removeFromParent()
                        self:addFreeSpinScore(coins)

                        gLobalSoundManager:playSound(levelConfig.Sound_BonusGreen_Collect_End)

                            if callBack then
                                callBack()
                            end
  
                    end)
                    local seq = cc.Sequence:create(actionList)
                    moveActionNode:runAction(seq)

                end,self.collectTime)
            -- end,0.1)
        end
    end
    return hasBonus
end

function CodeGameScreenGoldenGhostMachine:MachineRule_InterveneReelList()
    local curSpinMode = self:getCurrSpinMode()
    --self.m_reelRunInfo 中存放轮盘滚动信息
    if curSpinMode == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    end
end

function CodeGameScreenGoldenGhostMachine:formatAddSpinSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 then
        return self.SYMBOL_FIX_BONUS_LV2
    elseif symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3 then
        return self.SYMBOL_FIX_BONUS_LV3
    end
    return symbolType
end

function CodeGameScreenGoldenGhostMachine:getScoreInfoByPos(rowIndex, colIndex)
    return self:getReSpinSymbolScore(self:getPosReelIdx(rowIndex, colIndex)) --获取分数（网络数据）
end

function CodeGameScreenGoldenGhostMachine:addFreeSpinScore(score)
    self:setFreeSpinScore(self.m_freeSpinScore + score, true)
end

function CodeGameScreenGoldenGhostMachine:closeBonusPopUpUI()
    if self.bonusPopUpUI ~= nil then
        self.bonusPopUpUI:playCloseAnim()
        self.bonusPopUpUI = nil
    end
end

function CodeGameScreenGoldenGhostMachine:initHasFeature( )
    -- self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    self:initCloumnSlotNodesByNetData()
end

function CodeGameScreenGoldenGhostMachine:initCloumnSlotNodesByNetData()
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()

    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP = true
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowNum then
                                -- body
                                isUP = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH

            if colIndex == 3 then
                node.p_showOrder = self:getBounsScatterDataZorder(symbolType) + 10
            else
                node.p_showOrder = self:getBounsScatterDataZorder(symbolType) + colIndex
            end

            if self:isBonusSymbol(symbolType) then
                node:runAnim("idleframe1", true)
                node.p_showOrder = node.p_showOrder + colIndex
                self.addSpinSymbolNum = self.addSpinSymbolNum + 1
            end

            parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 + rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount


        end -- end while
    end

    self:initGridList()
end

function CodeGameScreenGoldenGhostMachine:isBonusSymbol(symbolType)
    if  symbolType == self.SYMBOL_FIX_BONUS_LV1 or 
        symbolType == self.SYMBOL_FIX_BONUS_LV2 or 
        symbolType == self.SYMBOL_FIX_BONUS_LV3 or 
        symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV2 or
        symbolType == self.SYMBOL_FIX_BONUS_ADDSPIN_LV3
    then
        return true
    end
    return false
end

function CodeGameScreenGoldenGhostMachine:initNoneFeature( )
    if globalData.GameConfig:checkSelectBet() then
        local questConfig = G_GetActivityDataByRef(ACTIVITY_REF.Quest)
        if questConfig and questConfig.m_IsQuestLogin then
            --quest进入也使用服务器bet
        else
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest()then
                --quest进入也使用服务器bet
            else
                self.m_initBetId = -1
            end
        end
    end
    -- self:checkUpateDefaultBet()
    -- 直接使用 关卡bet 选择界面的bet 来使用
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    self:initRandomSlotNodes()
end

function CodeGameScreenGoldenGhostMachine:randomSlotNodesByReel()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType

            if colIndex == 3 then
                node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex + 10
            else
                node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex + colIndex
            end

            parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function CodeGameScreenGoldenGhostMachine:calculateLastWinCoin()
    BaseFastMachine.calculateLastWinCoin(self)
    --最后一次赢得中bonus
    local lastFreeSpinScore = 0
    local totalBet = globalData.slotRunData:getCurTotalBet()
    for i = 1, self.m_iReelRowNum do
        for j = self.m_iReelColumnNum, 1, -1 do
            local score = self:getScoreInfoByPos(i, j)
            if score then
                lastFreeSpinScore = lastFreeSpinScore + totalBet / 60 * score
            end
        end
    end
    local curSpinMode = self:getCurrSpinMode()
    --getFreeSpinScore动画统计的分数+最后一次网络发来的数据才是真实的数据
    local freeSpinScore = self:getFreeSpinScore() + lastFreeSpinScore
    -- freeSpinScore = freeSpinScore / 60
    local winCount = self.m_iOnceSpinLastWin
    if globalData.slotRunData.freeSpinCount == 0 and curSpinMode == FREE_SPIN_MODE and freeSpinScore > 0 then
        local disScore = self.m_iOnceSpinLastWin - freeSpinScore
        if disScore > 0 then
            winCount = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - freeSpinScore
            self.m_iOnceSpinLastWin = disScore
            self.isSubFreeSpinScore = true
        end
    end
end

function CodeGameScreenGoldenGhostMachine:showEffect_newFreeSpinOver()
    local freeSpinScore = self:getFreeSpinScore()
    if self.isSubFreeSpinScore then
        globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin + freeSpinScore
        self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin + freeSpinScore
        self.isSubFreeSpinScore = nil
    end
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin(globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
    self:clearCurMusicBg()
    self:showFreeSpinOverView()
end

function CodeGameScreenGoldenGhostMachine:flyBottomEffect(callBack, score,freeSpinScore)
    if score > 0 then
        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig

        local curSpinMode = self:getCurrSpinMode()
        local rootParent = gLobalViewManager.p_ViewLayer

        local m_bottomUI = self.m_bottomUI
        local coinWinNode = m_bottomUI.m_normalWinLabel

        if coinWinNode ~= nil then
            local effectLabel, effectLabelAct = util_csbCreate("GoldenGhost_coins.csb", true)

            util_csbPlayForKey(effectLabelAct,"actionframe2",false,function ( ... )
                performWithDelay(self, callBack, 1)
            end)

            performWithDelay(self, function ( ... )
                self:playCoinWinEffectUI()
                m_bottomUI:updateWinCount(util_getFromatMoneyStr(score))
            end, 85 / 60)


            rootParent:addChild(effectLabel)
            local function getScoreLabel(node)
                local name = node:getName()
                if name == "m_lb_coins" then
                    return node
                else
                    for k, v in ipairs(node:getChildren()) do
                        local n = getScoreLabel(v)
                        if n ~= nil then
                            return n
                        end
                    end
                end
            end
            local lbEffectScore = getScoreLabel(effectLabel)
            if freeSpinScore then
                lbEffectScore:setString(util_formatCoins(freeSpinScore, 3))
            else
                lbEffectScore:setString(util_formatCoins(score, 3))
            end

            local startPos = util_convertToNodeSpace(self.goldMidTopUI, rootParent)
            local endPos = util_convertToNodeSpace(coinWinNode, rootParent)


            effectLabel:setPosition(startPos.x, startPos.y)
            effectLabel:runAction(
                cc.Sequence:create(
                    cc.MoveTo:create(110 / 60, cc.p(endPos.x,endPos.y + 585)),
                    cc.CallFunc:create(
                        function(sender)
                            sender:removeFromParent()
                        end
                    )
                )
            )
            gLobalSoundManager:playSound(levelConfig.Sound_Respin_Wincoin)
        else
            m_bottomUI:updateWinCount(util_getFromatMoneyStr(score))
            performWithDelay(self, callBack, 1)
        end
    else
        if callBack ~= nil then
            callBack()
        end
    end
end

function CodeGameScreenGoldenGhostMachine:clearCurEffectData( ... )
    -- body
    if self.curEffectData then
        self.curEffectData.p_isPlay = true
        self.curEffectData = nil
        self:playGameEffect()
        -- self.freeBonusLv2Count = 0
    end
end

function CodeGameScreenGoldenGhostMachine:playPotCollectAni(playSound)
    -- body
    local wildCounts = self.wildCounts
    local actionIdx = 1

    if self.curPotActionIdx and wildCounts == 0 then
        actionIdx = self.curPotActionIdx
    else
        if 31 < wildCounts and wildCounts <= 78 then
            actionIdx = 2
        elseif 78 < wildCounts then
            actionIdx = 3
        end
        self.curPotActionIdx = actionIdx
    end
    local actionframeName = "actionframe" .. tostring(actionIdx)
    local idleframeName = "idle" .. tostring(actionIdx)

    util_spinePlay(self.m_pumpkin,actionframeName, false)
    util_spineEndCallFunc( self.m_pumpkin,actionframeName,function()
        util_spinePlay(self.m_pumpkin,idleframeName, true)
    end)
end

-------------------------------
---
-- 进入关卡
--
function CodeGameScreenGoldenGhostMachine:initGameStatusData(gameData)
    CodeGameScreenGoldenGhostMachine.super.initGameStatusData(self, gameData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    -- wild收集数量
    if nil ~= selfData.wildCounts then
        self.wildCounts = selfData.wildCounts
    end
end
function CodeGameScreenGoldenGhostMachine:enterLevel()
    self:checkUpateDefaultBet()
    CodeGameScreenGoldenGhostMachine.super.enterLevel(self)

    --关闭spin按钮点击状态, 如果重连处于选择玩法切剩余次数大于0
    if self.m_initFeatureData ~= nil then
        if self:isInPickBonus() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
        else
            self:playPotCollectAni(0)
        end
    else
        self:playPotCollectAni(0)
    end
end

--顶部补块
function CodeGameScreenGoldenGhostMachine:createResNode(parentData)
    local slotParent = parentData.slotParent
    local columnData = self.m_reelColDatas[parentData.cloumnIndex]
    local rowIndex = parentData.rowIndex + 1
    local symbolType = nil
    if self.m_bCreateResNode == false then
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = self:getResNodeSymbolType(parentData)
    end
    parentData.symbolType = symbolType
    parentData.order =  self:getBounsScatterDataZorder(symbolType) - rowIndex
    parentData.layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    parentData.tag = parentData.cloumnIndex * SYMBOL_NODE_TAG + rowIndex
    parentData.reelDownAnima = nil
    parentData.reelDownAnimaSound = nil
    parentData.m_isLastSymbol = false
    parentData.rowIndex = rowIndex
end

function CodeGameScreenGoldenGhostMachine:getCoinsByScore(score)
    local coins = self:getCoinsNumByScore(score)
    local coinsStr = util_formatCoins(coins,3)
    return coinsStr
end

function CodeGameScreenGoldenGhostMachine:getCoinsNumByScore(score)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local coins = totalBet / 60 * score
    return coins
end

-- 重置当前背景音乐名称
function CodeGameScreenGoldenGhostMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        if not self.isInBonus then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        else
            self.m_currentMusicBgName = "GoldenGhostSounds/music_GoldenGhost_pick.mp3"
        end
    end
end

function CodeGameScreenGoldenGhostMachine:checkTriggerOrInSpecialGame( func )
    if  self:getCurrSpinMode() == FREE_SPIN_MODE or
        self:getCurrSpinMode() == RESPIN_MODE or
        self:getCurrSpinMode() == AUTO_SPIN_MODE or
        self.isInBonus or 
        self.m_chooseRepin then

        self:removeSoundHandler() -- 移除监听
    else
       if func then
            func()
       end
    end
end

--------------------------------------------发送网络消息---------------------------------------
function CodeGameScreenGoldenGhostMachine:sendSelectBonus(index)
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
    local httpSendMgr = GameNetDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData, self.m_isShowTournament)
end

--------------------------------------------发送网络消息---------------------------------------

--[[
    @desc: 新增接口
    time:2021-09-24 09:56:21
]]
function CodeGameScreenGoldenGhostMachine:isLevelBonus(_symbolType)
    return nil ~= self:getLevelBonusConfigData(_symbolType)
end
function CodeGameScreenGoldenGhostMachine:getLevelBonusConfigData(_symbolType)
    -- [bonus索引，spine皮肤名称]
    local bonusData = {
        [self.SYMBOL_FIX_BONUS_LV1] = {1, "blue"},
        [self.SYMBOL_FIX_BONUS_LV2] = {2, "green"},
        [self.SYMBOL_FIX_BONUS_LV3] = {3, "yellow"},
    }

    local data = bonusData[_symbolType]
    return data
end
function CodeGameScreenGoldenGhostMachine:isLevelAddSpinTimes(_symbolType)
    return nil ~= self:getLevelAddSpinTimesConfigData(_symbolType)
end
function CodeGameScreenGoldenGhostMachine:getLevelAddSpinTimesConfigData(_symbolType)
    -- [索引，spine皮肤名称]
    local bonusData = {
        [self.SYMBOL_FIX_BONUS_ADDSPIN_LV2] = {2, "green"},
        [self.SYMBOL_FIX_BONUS_ADDSPIN_LV3] = {3, "yellow"},
    }

    local data = bonusData[_symbolType]
    return data
end


function CodeGameScreenGoldenGhostMachine:addLevelBonusSpine(_symbol)
    -- spine的数据数组 {索引, spine皮肤名称,}
    local spineData = nil
    -- bonus
    if not spineData then
        spineData = self:getLevelBonusConfigData(_symbol.p_symbolType)
    end
    -- addSpin
    if not spineData then
        spineData = self:getLevelAddSpinTimesConfigData(_symbol.p_symbolType)
    end

    if nil == spineData then
        return 
    end

    
    _symbol:checkLoadCCbNode()
    local spineParent = _symbol:getCcbProperty("SpineNode")
    if spineParent then
        local spine = spineParent:getChildByName("bonusSpine")

        if not spine then
            local spineName = "Socre_GoldenGhost_Bonus"
            spine = util_spineCreate(spineName, true, true)
            spineParent:addChild(spine)
            spine:setName("bonusSpine")

            spine:setSkin(spineData[2])
            util_spinePlay(spine, "idleframe")

            -- 分值 和 +1 spinTimes 分情况展示
            local labScore = _symbol:getCcbProperty("m_lb_score")
            local imgSpin  = _symbol:getCcbProperty("spin_1")
            local isBonus = self:isLevelBonus(_symbol.p_symbolType)
            local isAddSpinTimes = self:isLevelAddSpinTimes(_symbol.p_symbolType)
            labScore:setVisible(isBonus)
            imgSpin:setVisible(isAddSpinTimes)

            --挂载父节点 播放时间线时自己也播放一下
            _symbol:registerAniamCallBackFun(function(_slotsNode)
                local spineParent = _symbol:getCcbProperty("SpineNode")
                if spineParent then
                    local bonusSpine = spineParent:getChildByName("bonusSpine")
                    if bonusSpine then
                        util_spinePlay(spine, _symbol.m_currAnimName, _symbol.m_slotAnimaLoop)
                    end
                end
            end)
        end

    end

end
function CodeGameScreenGoldenGhostMachine:removeLevelBonusSpine(_symbol)
    if not self:isLevelBonus(_symbol.p_symbolType) and
        not self:isLevelAddSpinTimes(_symbol.p_symbolType) then
        return 
    end
    local spineParent = _symbol:getCcbProperty("SpineNode")
    if spineParent then
        local spine = spineParent:getChildByName("bonusSpine")
        if  spine then
            spine:removeFromParent()
        end
    end
end
-- 解决Bonus小块上面附加的spine节点问题
--新滚动使用
function CodeGameScreenGoldenGhostMachine:updateReelGridNode(symblNode)
    CodeGameScreenGoldenGhostMachine.super.updateReelGridNode(self, symblNode)
    self:addLevelBonusSpine(symblNode)

    if self:isFixSymbol(symblNode.p_symbolType) then
        self:setSpecialNodeScore(self,{symblNode})
    end
end
-- 根据类型获取对应节点
--
function CodeGameScreenGoldenGhostMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = CodeGameScreenGoldenGhostMachine.super.getSlotNodeBySymbolType(self, symbolType)
    self:addLevelBonusSpine(reelNode)
    return reelNode
end
function CodeGameScreenGoldenGhostMachine:pushAnimNodeToPool(animNode, symbolType)
    self:removeLevelBonusSpine(animNode )
    CodeGameScreenGoldenGhostMachine.super.pushAnimNodeToPool(self,animNode, symbolType)
end
function CodeGameScreenGoldenGhostMachine:getAnimNodeFromPool(symbolType, ccbName)
    local node = CodeGameScreenGoldenGhostMachine.super.getAnimNodeFromPool(self,symbolType, ccbName)
    self:removeLevelBonusSpine(node )

    return node
end
--[[
    @desc: 预告中奖
]]
function CodeGameScreenGoldenGhostMachine:playYugaoAnim()
    local animTime = 0
    
    local selfdata      = self.m_runSpinResultData.p_selfMakeData or {}
    local features      = self.m_runSpinResultData.p_features or {}
    local probability   = (math.random(1,10) <= 4)
    if #features >= 2 and probability then
        animTime  = 120/30

        local levelConfig = globalMachineController.p_GoldenGhostMachineConfig
        gLobalSoundManager:playSound(levelConfig.Sound_Notice)

        self.m_yugao:setVisible(true)
        util_spinePlay(self.m_yugao, "actionframe", false)
        util_spineEndCallFunc( self.m_yugao,"actionframe",function()
            self.m_yugao:setVisible(false)
        end)

        self:runCsbAction("actionframe2",false, function()
            self:runCsbAction("idleframe",false)
        end)
    end

    return animTime
end

---
-- 处理spin 返回消息的数据结构
--
function CodeGameScreenGoldenGhostMachine:operaSpinResultData(param)
    CodeGameScreenGoldenGhostMachine.super.operaSpinResultData(self,param)
    --!!! 预告中奖停轮时间
    local animTime = self:playYugaoAnim()
    if animTime > 0 then
        self:setWaitChangeReelTime(animTime)
    end
end

--[[
    @desc: 处理free和reSpin的弹板spine , 将start和over弹板绑定在spine上
]]
function CodeGameScreenGoldenGhostMachine:addViewToSpineTanban(_dialogName, _ownerlist, _autoType, _func, _skinName)
    -- @ func 放到spine结束回调内
    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self, _dialogName, nil, _autoType)
    view:updateOwnerVar(_ownerlist)
    view.m_allowClick = false

    -- 打开遮罩
    self:showSpineTanbanMask()

    local spineTanbanParent = self.m_spineTanbanParent

    -- local scale = view:getUIScalePro()
    -- spineTanbanParent:setScale( math.min(1, scale) )
    -- local nodePos  = spineTanbanParent:getParent():convertToNodeSpace(cc.p(display.width/2, display.height/2))
    -- self.m_spineTanbanParent:setPosition(nodePos)

    --spine做背景
    self.m_spineTanban  = util_spineCreate("GoldenGhost_tanban",true,true)
    spineTanbanParent:addChild(self.m_spineTanban)
    self.m_spineTanban:setLocalZOrder(SpineTanbanOrder.Tanban)
    self.m_spineTanban:setSkin(_skinName)

    --cocos弹板挂在另外一个spine上面 
    self.m_spineGuadian = util_spineCreate("GoldenGhost_tanban_guadian",true,true)
    spineTanbanParent:addChild(self.m_spineGuadian)
    self.m_spineGuadian:setLocalZOrder(SpineTanbanOrder.Guadian)
    util_spinePushBindNode(self.m_spineGuadian,"diban",view)

    --用于触发事件的第二个cocos界面
    local viewPos  = cc.p(view:getPosition())
    local worldPos = view:getParent():convertToWorldSpace(viewPos)
    local secondView = self:createSecondCocosView(_dialogName, _autoType, worldPos, _func)

    self:bindSecondViewBtnState(view, secondView)

    return view
end
--创建第二个cocos界面, 解决cocos按钮挂载在spine上面不生效的问题, 第二界面不做展示 只触发事件
function CodeGameScreenGoldenGhostMachine:createSecondCocosView(_dialogName, _autoType, _worldPos, _func)
    local parent = self.m_spineTanbanParent
    -- local parent = self:findChild("spineTanban")
    
    local view = util_createView("Levels.BaseDialog")
    self:reSetDialogFun_runCsbAction(view)
    view:initViewData(self, _dialogName, nil, _autoType)
    parent:addChild(view)
    view:setLocalZOrder(SpineTanbanOrder.SecondView)
    local nodePos   = parent:convertToNodeSpace(_worldPos)
    view:setPosition(nodePos)
    --这个数值是目测的
    -- view:setScale(0.85)
    --修改所有节点展示状态: button 打开可见性，清零 透明度, 只有root一层
    self:setSecondViewNodeShowState(view:findChild("root"))
    --等over时间线播放完毕再移除
    view:setOverAniRunFunc(function()
        self:closeSpineTanbanMask()

        if _func then
            _func()
        end
        self:clearSpineTanbanAddView()
    end)
    return view
end

function CodeGameScreenGoldenGhostMachine:setSecondViewNodeShowState(_node)
    local childList = _node:getChildren()
    for _index,_child in ipairs(childList) do
        if tolua.type(_child) == "ccui.Button" then
            _child:setVisible(true)
            _child:setOpacity(0)
        elseif(tolua.type(_child) == "ccui.Layout")then
            _child:setVisible(true)
            _child:setOpacity(0)
        else
            _child:setVisible(false)
        end
    end
end
-- 绑定两个界面的按钮状态，逻辑界面的按钮被点击时 展示界面的按钮状态也要发生变化
-- 注意保证所有界面的按钮名称 都为 "Button_collect" 且只有一个按钮
function CodeGameScreenGoldenGhostMachine:bindSecondViewBtnState(_view, _secondView)
    local secondViewRoot = _secondView:findChild("root")
    
    -- 触摸开始
    _secondView.clickStartFunc = function(_viewObj,_sender)
        local btnName = "Button_collect"
        local btnNode = _view:findChild(btnName)
        if not tolua.isnull(btnNode) and btnNode.setEnabled then
            btnNode:setEnabled(false)
        end

    end
    -- 触摸结束
    _secondView.clickEndFunc = function(_viewObj,_sender)
        local btnName = "Button_collect"
        local btnNode = _view:findChild(btnName)
        if not tolua.isnull(btnNode) and btnNode.setEnabled then
            btnNode:setEnabled(true)
        end

    end
    
end

function CodeGameScreenGoldenGhostMachine:clearSpineTanbanAddView()
    --弹板
    if self.m_spineTanban then
        self.m_spineTanban:removeFromParent()
        self.m_spineTanban = nil
    end
    --挂点
    if self.m_spineGuadian then
        self.m_spineGuadian:removeFromParent()
        self.m_spineGuadian = nil
    end
    --第二弹板，父类方法会自动移除
end
function CodeGameScreenGoldenGhostMachine:reSetDialogFun_runCsbAction(_csbView)
    --重写view的指定方法
    _csbView.runCsbAction = function(_dialog,key, loop, func, fps)
        if nil ~= _dialog then
            --播放csb时间线的 通知播放spine时间线,函数回调放在spine结束回调内。
            util_csbPlayForKey(_dialog.m_csbAct, key, loop, nil, fps)
            -- util_csbPlayForKey(_dialog.m_csbAct, key, loop, func, fps)

            util_spinePlay(self.m_spineTanban,key,loop)
            util_spinePlay(self.m_spineGuadian,key,loop)
            util_spineEndCallFunc(self.m_spineTanban,key,handler(nil,function(  )
                if nil ~= func then
                    func()
                end
            end))

        end
    end
end

--free
function CodeGameScreenGoldenGhostMachine:showFreeSpinMore(num,func,isAuto)

    local function newFunc()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local dialogName = BaseDialog.DIALOG_TYPE_FREESPIN_MORE
    local ownerlist = {
        m_lb_num   = num,
    }
    local autoType   = BaseDialog.AUTO_TYPE_ONLY
    local skinName   = "FreeGameMore"
    local view = self:addViewToSpineTanban("FreeGameMore", ownerlist, autoType, newFunc, skinName)

    return view
end
function CodeGameScreenGoldenGhostMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    
    local dialogName = BaseDialog.DIALOG_TYPE_FREESPIN_OVER
    local ownerlist = {
        m_lb_num   = num,
        m_lb_coins = util_formatCoins(coins, 30),
    }
    local autoType   = nil
    local skinName   = "FreeSpinOver"
    local view = self:addViewToSpineTanban(dialogName, ownerlist, autoType, func, skinName)

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 600)

    node = view:findChild("m_lb_num")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 72)

    return view
end

--reSpin
function CodeGameScreenGoldenGhostMachine:showRespinStartView( ... )
    --先注释 弹板界面移动到 showReSpinStart接口内
    -- if self.m_bonusNum < 11 then
        -- self:runNextReSpinReel()
    -- else
        -- local respinStartUI = util_createView("CodeGoldenGhostSrc.GoldenGhostManyBonusReSpinStart")
        -- respinStartUI:setExtraInfo(self,function ( ... )
        --     -- body
        --     self:runNextReSpinReel()
        -- end)
        -- gLobalViewManager:showUI(respinStartUI)
    -- end

    self.m_bIsSelectCall = false
end
function CodeGameScreenGoldenGhostMachine:showReSpinStart(func)
    self:clearCurMusicBg()
    -- spin触发时 需要延迟滚动， 断线重连时可以直接滚动
    local waitTime = self.m_bIsRespinReconnect and 0 or 100/30
    if self.m_bIsRespinReconnect then
        self:resetMusicBg()
    end
    self.m_bIsRespinReconnect = false

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()

        if self.m_bonusNum < 11 then
            if nil ~= func then
                func()       
            end
        else
            local dialogName = "ReSpinStart_special"
            local ownerlist = {
                m_lb_num   = string.format("%d", self.m_bonusNum),
                m_lb_multiply   = string.format("X%d", self.m_bonusNum-9),
            }
            local autoType   = BaseDialog.AUTO_TYPE_NOMAL
            local skinName   = "ReSpinStart_special"
            local view = self:addViewToSpineTanban(dialogName, ownerlist, autoType, func, skinName)
        end

        waitNode:removeFromParent()
    end, waitTime)    
end

function CodeGameScreenGoldenGhostMachine:showReSpinOver(coins, func, index)
    self:clearCurMusicBg()

    local dialogName = BaseDialog.DIALOG_TYPE_RESPIN_OVER
    local ownerlist = {
        m_lb_coins   = util_formatCoins(coins, 30),
    }
    local autoType   = nil
    local skinName   = "ReSpinOver"
    local view = self:addViewToSpineTanban(dialogName, ownerlist, autoType, func, skinName)

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 600)

    return view
end

--bonus pick
function CodeGameScreenGoldenGhostMachine:showGoldenGhostBonusOverView(_conis, _func)
    -- 一些参数
    local dialogName = "GoldenGhost_BonusGameOver"
    local ownerlist = {
        m_lb_coins   = util_formatCoins(_conis, 30),
    }
    local autoType   = nil
    local skinName   = "GoldenGhost_BonusGameOver"
    
    -- 用于展示的cocos界面
    local view = util_createView("CodeGoldenGhostSrc.GoldenGhostBonusGameOverUI")
    view:setExtraInfo(self.bonusGame, nil)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 600)
    view.m_allowClick = false
    -- 打开遮罩
    self:showSpineTanbanMask()

    local spineTanbanParent = self.m_spineTanbanParent
    
    -- local scale = view:getUIScalePro()
    -- spineTanbanParent:setScale( math.min(1, scale) )
    -- local nodePos  = spineTanbanParent:getParent():convertToNodeSpace(cc.p(display.width/2, display.height/2))
    -- self.m_spineTanbanParent:setPosition(nodePos)

    -- spine做背景
    self.m_spineTanban  = util_spineCreate("GoldenGhost_tanban",true,true)
    spineTanbanParent:addChild(self.m_spineTanban)
    self.m_spineTanban:setLocalZOrder(SpineTanbanOrder.Tanban)
    self.m_spineTanban:setSkin(skinName)

    --cocos弹板挂在另外一个spine上面 
    self.m_spineGuadian = util_spineCreate("GoldenGhost_tanban_guadian",true,true)
    spineTanbanParent:addChild(self.m_spineGuadian)
    self.m_spineGuadian:setLocalZOrder(SpineTanbanOrder.Guadian)
    util_spinePushBindNode(self.m_spineGuadian,"diban",view)

    --用于触发事件的第二个cocos界面
    local viewPos  = cc.p(view:getPosition())
    local worldPos = view:getParent():convertToWorldSpace(viewPos)
    local secondView = util_createView("Levels.BaseDialog")
    self:reSetDialogFun_runCsbAction(secondView)
    secondView:initViewData(self, dialogName, nil, autoType)
    spineTanbanParent:addChild(secondView)
    secondView:setLocalZOrder(SpineTanbanOrder.SecondView)
    local nodePos   = spineTanbanParent:convertToNodeSpace(worldPos)
    secondView:setPosition(nodePos)
    -- secondView:setScale(0.85)
    self:setSecondViewNodeShowState(secondView:findChild("root"))
    secondView:setOverAniRunFunc(function()
        self:closeSpineTanbanMask()

        if _func then
            _func()
        end
        self:clearSpineTanbanAddView()
    end)

    self:bindSecondViewBtnState(view, secondView)
end

--bonus界面打开关闭时修改界面展示
function CodeGameScreenGoldenGhostMachine:bonusChangeReelUiVisible(_visible)
    self:findChild("candle_left"):setVisible(_visible)
    self:findChild("candle_right"):setVisible(_visible)
    self:findChild("reel_ui"):setVisible(_visible)
    self:findChild("Node_1"):setVisible(_visible)
end

--展示spine弹板遮罩
function CodeGameScreenGoldenGhostMachine:showSpineTanbanMask()
    self.m_spineTanban_mask:setVisible(true)   

    self.m_spineTanban_mask:runCsbAction("start", false, function()
        self.m_spineTanban_mask:runCsbAction("idle", true)
    end)
end
--隐藏spine弹板遮罩
function CodeGameScreenGoldenGhostMachine:closeSpineTanbanMask()
    self.m_spineTanban_mask:runCsbAction("over", false, function()
        self.m_spineTanban_mask:setVisible(false) 
    end)
end

--重置棋盘的信号层级
function CodeGameScreenGoldenGhostMachine:reSetSymbolOrder()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if nil ~= symbol then
                symbol.p_showOrder = self:getBounsScatterDataZorder(symbol.p_symbolType) - iRow
                symbol:setLocalZOrder(symbol.p_showOrder)
            end
        end
    end
end


function CodeGameScreenGoldenGhostMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    symbolType = self:formatAddSpinSymbol(symbolType)

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:isBonusSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + symbolType
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + TAG_SYMBOL_TYPE.SYMBOL_SCATTER
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + symbolType
        end
    end


    return order
end

function CodeGameScreenGoldenGhostMachine:setPickBonusTimes(_times)
    self.m_pickBonus_times = _times or 0
end
function CodeGameScreenGoldenGhostMachine:isInPickBonus()
    return self.m_pickBonus_times > 0 
end

function CodeGameScreenGoldenGhostMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        --!!! 要求适当放大，使jackPot顶到上栏底部
        local offsetScale = 1.08
        if display.width < DESIGN_SIZE.width then
            local viewScale = display.width / DESIGN_SIZE.width
            offsetScale = offsetScale - (DESIGN_SIZE.width - display.width)/100*0.0116
        end
       
        mainScale = mainScale * offsetScale

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

return CodeGameScreenGoldenGhostMachine






