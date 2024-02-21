-- 2020年1月3日
-- CodeGameScreenJungleKingpinMachine.lua

-- 玩法1：fade away feature
-- 条件 ：出现bonus wild（金色大猩猩）时触发
-- 触发时轮盘上的低级图标L1~L6会消失，上方落下新的图标，直到全部为高级图标

-- 玩法2：banana droppin' feature
-- 条件 ：6个或以上的普通wild或bonus wild触发
-- （触发时出现一行三列轮盘，给8次spin，可转出bonus wild，普通wild，或无图标
-- 若转出bonus wild，则可获得该列对应的香蕉奖励、bonus奖金、jackpot的奖励
-- 若转出普通wild，则获得该列最下方的图标，可能是香蕉、金币或jackpot）

-- 玩法3：free spin
-- 条件 ：3个或以上scatter触发
-- （fade away feature可频繁触发， 可触发pop n'drop feature，可再触发free spin）

-- 玩法4：super free spin
-- 条件 ：累计触发到第5次free spin时，直接触发super freespin
-- super free spin时，第三行中间列固定为bonus wild

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local JungleKingpinSlotFastNode = require "CodeJungleKingpinSrc.JungleKingpinSlotFastNode"
local BaseMachine = require "Levels.BaseMachine"
local CodeGameScreenJungleKingpinMachine = class("CodeGameScreenJungleKingpinMachine", BaseFastMachine)

CodeGameScreenJungleKingpinMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenJungleKingpinMachine.m_betLevel = nil -- betlevel 0 1 2
CodeGameScreenJungleKingpinMachine.m_BonusWinCoins = 0
--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}
----自定义信号块
CodeGameScreenJungleKingpinMachine.SYMBOL_SCORE_GOLD_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE --金色的猩猩wild
CodeGameScreenJungleKingpinMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 --金色的猩猩wild

--effect Type

CodeGameScreenJungleKingpinMachine.EFFECT_GOLD_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --fade away feature
CodeGameScreenJungleKingpinMachine.EFFECT_COLLECT_SCATTER = GameEffect.EFFECT_SELF_EFFECT - 2 --收集scatter
CodeGameScreenJungleKingpinMachine.EFFECT_TIRIGGER_SCATTER = GameEffect.EFFECT_SELF_EFFECT - 3 --触发freespin
CodeGameScreenJungleKingpinMachine.EFFECT_SUPER_FREESPIN = GameEffect.EFFECT_SELF_EFFECT - 4 --super spin
CodeGameScreenJungleKingpinMachine.EFFECT_SHOW_FIRST_WINLINE = GameEffect.EFFECT_SELF_EFFECT - 5 --bonus wild 第一次连线

CodeGameScreenJungleKingpinMachine.m_fisrtLinesWinCoin = nil
CodeGameScreenJungleKingpinMachine.m_bonusGameFlag = nil

--banana droppin' feature 玩法中的奖励类型
local BONUS_TYPE = {
    BONUS_NORMAL_TYPE = 1, --金币奖励
    BONUS_MINI_TYPE = 2,
    --香蕉最小奖励
    BONUS_MAX_TYPE = 3, --香蕉最大奖励
    BONUS_MINOR_TYPE = 4, --minor
    BONUS_MAJOR_TYPE = 5,
    --major
    BONUS_GRAND_TYPE = 6 --grand
}

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136
-- 构造函数
function CodeGameScreenJungleKingpinMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    --init
    self.m_bBonusGame = false
    self.m_firstWinCoin = false --第一次消除播放赢钱音效
    self.m_SuperLockWild = nil
    self.m_betLevel = nil
    self.m_bJackpotHeight = false
    self.m_bonusOverAndFreeSpinOver = false
    self:initGame()
end

function CodeGameScreenJungleKingpinMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("JungleKingpinConfig.csv", "LevelJungleKingpinConfig.lua")
    self.m_configData:initMachine(self)
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

--小块
function CodeGameScreenJungleKingpinMachine:getBaseReelGridNode()
    return "CodeJungleKingpinSrc.JungleKingpinSlotFastNode"
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenJungleKingpinMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "JungleKingpin"
end

function CodeGameScreenJungleKingpinMachine:getBottomUINode()
    return "CodeJungleKingpinSrc.JungleKingpinBoottomNode"
end

function CodeGameScreenJungleKingpinMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar
    self:initSuperCollectBar() --super collect
    self:initBonusReels() --bonusReel
    self:initTips() --玩法小提示弹板
    -- 创建view节点方式
    self.m_jackPotBar = util_createView("CodeJungleKingpinSrc.JungleKingpinJackPotBarView", self)
    self:findChild("jackpot1"):addChild(self.m_jackPotBar)

    --过场动画
    self.m_transitionView = util_createView("CodeJungleKingpinSrc.JungleKingpinTransitionView", self)
    self:addChild(self.m_transitionView, 9999999)
    self.m_transitionView:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_transitionView:setVisible(false)
    self:changeNormalAndFreespinReel(0)

    --  快滚背景
    self.m_RunDi = {}
    for i = 1, 5 do
        local longRunDi = util_createAnimation("WinFrameJungleKingpin_run_BG.csb")
        self:findChild("reelDiNode"):addChild(longRunDi, 1)
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_" .. (i - 1)):getPosition()))
        table.insert(self.m_RunDi, longRunDi)
        longRunDi:setVisible(false)
    end

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin and self.m_firstWinCoin == false then
                return
            end
            if self.m_bBonusGame and self.m_firstWinCoin == false then
                return
            end

            if self:isTriggerFreespin() and self.m_firstWinCoin == false then
                return
            end
            self.m_firstWinCoin = false
            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 1
            local soundTime = 1
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 2
            else
                soundIndex = 3
                soundTime = 2
            end
            local soundName = "JungleKingpinSounds/sound_JungleKingpin_win" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenJungleKingpinMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            self:playEnterGameSound("JungleKingpinSounds/sound_JungleKingpin_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.m_bBonusGame then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    else
                        self.m_currentMusicBgName = "JungleKingpinSounds/music_JungleKingpin_BonusBg.mp3"
                        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
                    end
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenJungleKingpinMachine:scaleMainLayer()
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
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
    if display.height == 1024 and display.width == 768 then
        local mainScale = 0.72
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end

    if globalData.slotRunData.isPortrait then
        local bangHeight = util_getBangScreenHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - bangHeight)
    end

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
    if bangDownHeight > 0 then
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 15)
    end
end

function CodeGameScreenJungleKingpinMachine:changeViewNodePos()
    self.m_bJackpotHeight = false
    local bonusReelHeight = 0
    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro > 2 and pro < 2.2 then
            self.m_bJackpotHeight = true
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 100)
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() + 160)
            bonusReelHeight = 80
        elseif pro >= 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 120)
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() + 240)
            self.m_bJackpotHeight = true
            bonusReelHeight = 120
        elseif pro == 2 then
            self.m_bJackpotHeight = true
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 55)
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() + 140)
            bonusReelHeight = 70
        elseif pro <= 1.867 and pro > 1.6 then
            self.m_bJackpotHeight = false
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 10)
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() + 10)
        else
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 20)
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() + 30)
            bonusReelHeight = 15
        end
    elseif display.height >= FIT_HEIGHT_MIN and display.height < FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro > 2 and pro < 2.2 then
            self.m_bJackpotHeight = true
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 100)
            bonusReelHeight = 50
        elseif pro >= 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 120)
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() + 200)
            self.m_bJackpotHeight = true
            bonusReelHeight = 100
        elseif pro == 2 then
            self.m_bJackpotHeight = true
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 55)
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() + 140)
            bonusReelHeight = 70
        elseif pro <= 1.867 then
            self.m_bJackpotHeight = true
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 10)
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() + 10)
            bonusReelHeight = 5
        end
    elseif display.height < FIT_HEIGHT_MIN then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro < 1.5 then
            self:findChild("jackpot1"):setPositionY(self:findChild("jackpot1"):getPositionY() - 10)
            bonusReelHeight = 10
        end
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 20)
    end
    self:setBonusReelPos(bonusReelHeight)
end

function CodeGameScreenJungleKingpinMachine:setBonusReelPos(_height)
    for i = 1, 3 do
        local node = self:findChild("BonusNode" .. i)
        node:setPositionY(node:getPositionY() + _height)
    end
end

function CodeGameScreenJungleKingpinMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除


    self:addObservers()
    --初始化一下界面
    self:showCollectScatterNum()

    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            self.m_tip1:setVisible(true)
            self.m_tip1:ShowTip()
        end
        if self.m_bBonusGame == false then
            self.m_tip2:setVisible(true)
        end
    end
end

function CodeGameScreenJungleKingpinMachine:bonusIconBuling()
    if not self.m_bBonusGame then
        local col = xcyy.SlotsUtil:getArc4Random() % 3 + 1
        if self.m_bonusReels then
            self.m_bonusReels[col]:playBonusBuling()
        end
    end
end

function CodeGameScreenJungleKingpinMachine:updateJackpot()
    self.m_jackPotBar:updateJackpotInfo()
end

--中奖线 上是否有信号wild
function CodeGameScreenJungleKingpinMachine:checkIsLinesHaveWildSymbol()
    --接下来判断连线上是否有信号块Wild
    local winLines = self.m_runSpinResultData.p_winLines
    if winLines and #winLines > 0 then
        for i = 1, #winLines do
            local lineData = winLines[i]
            if lineData.p_iconPos and #lineData.p_iconPos > 0 then
                for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                    local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                    local checkEnd = false
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]
                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_SCORE_GOLD_WILD then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

--初始香蕉轮盘
function CodeGameScreenJungleKingpinMachine:initBonusReels()
    self.m_bonusReels = {}
    for i = 1, 3 do
        local node = self:findChild("BonusNode" .. i)
        local bonusReel = util_createView("CodeJungleKingpinSrc.JungleKingpinBonusReelView", self)
        bonusReel:initBonus()
        self.m_bonusReels[i] = bonusReel
        node:addChild(bonusReel)
        bonusReel:setPosition(0, 0)
        -- bonusReel:setVisible(false)
    end
    local node = self:findChild("BonusNode1")
    self.m_updataAction =
        schedule(
        node,
        function()
            self:bonusIconBuling()
        end,
        2
    )
end

--初始freespin tips
function CodeGameScreenJungleKingpinMachine:initFreeSpinBar()
    local node_bar = self:findChild("freespinBar")
    self.m_baseFreeSpinBar = util_createView("CodeJungleKingpinSrc.JungleKingpinFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, true)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end

--freespin 触发次数
function CodeGameScreenJungleKingpinMachine:initSuperCollectBar()
    local node_bar = self:findChild("Node_spinbonus")
    self.m_SuperCollectBar = util_createView("CodeJungleKingpinSrc.JungleKingpinSuperCollectBarView")
    node_bar:addChild(self.m_SuperCollectBar)
    util_setCsbVisible(self.m_SuperCollectBar, true)
    self.m_SuperCollectBar:setPosition(0, 0)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_SuperCollectBar.getRotateBackScaleFlag = function()
            return false
        end
    end
end

--freespin 触发次数
function CodeGameScreenJungleKingpinMachine:initTips()
    local node1 = self:findChild("tip")
    self.m_tip1 = util_createView("CodeJungleKingpinSrc.JungleKingpinTips1")
    node1:addChild(self.m_tip1)
    self.m_tip1:setVisible(false)
    local node2 = self:findChild("tip_1")
    self.m_tip2 = util_createView("CodeJungleKingpinSrc.JungleKingpinTips2")
    node2:addChild(self.m_tip2)
    self.m_tip2:ShowTip()
    self.m_tip2:setVisible(false)
end

--过场动画
function CodeGameScreenJungleKingpinMachine:playTransitionEffect(funcEnd)
    self.m_transitionView:setVisible(true)
    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_guochang.mp3")
    self:clearWinLineEffect()
    self.m_transitionView:playTransitionEffect(
        function()
            self.m_transitionView:setVisible(false)
            if funcEnd then
                funcEnd()
            end
        end
    )
end

function CodeGameScreenJungleKingpinMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_SuperCollectBar:setVisible(false)
end

function CodeGameScreenJungleKingpinMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    util_setCsbVisible(self.m_SuperCollectBar, true)
end

function CodeGameScreenJungleKingpinMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.getCurrSpinMode() ~= RESPIN_MODE and self.getCurrSpinMode() ~= FREE_SPIN_MODE and self.getCurrSpinMode() ~= AUTO_SPIN_MODE then
                if self.m_tip1:isVisible() then
                    self.m_tip1:HideTip()
                else
                    self.m_tip1:setVisible(true)
                    self.m_tip1:ShowTip()
                end
            end
        end,
        "SHOW_TIP1"
    )
end

function CodeGameScreenJungleKingpinMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    if self.m_updataAction then
        local node = self:findChild("BonusNode1")
        node:stopAction(self.m_updataAction)
        self.m_updataAction = nil
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenJungleKingpinMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_GOLD_WILD then
        return "Socre_JungleKingpin_BonusWild"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_JungleKingpin_10"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenJungleKingpinMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 15}
    }
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 15}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_GOLD_WILD, count = 5}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenJungleKingpinMachine:MachineRule_initGame()
    local isFreespin = false
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        else
            local frssSpinType = self.m_runSpinResultData.p_selfMakeData.freeSpinType
            if frssSpinType == 0 then
                self:playWildAddToReel(false)
            end
            self:changeNormalAndFreespinReel(1)
        end
        isFreespin = true
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
    elseif self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        self:triggerFreeSpinCallFun()
        self:changeNormalAndFreespinReel(1)
        isFreespin = true
    end

    if self:isTriggerBonusGame() then
        self.m_bBonusGame = true
        self:showBonusReel(true)
        self:clearCurMusicBg()
        self:changeNormalAndFreespinReel(1)
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self:InitBonusMap(selfData.bonusMaps)
        self.m_tip2:setVisible(false)
    else
        self.m_tip2:setVisible(true)
    end

    if self.m_bBonusGame ~= true and isFreespin == false then
        self.m_tip1:setVisible(true)
        self.m_tip1:ShowTip()
    else
        self.m_tip1:setVisible(false)
        self.m_SuperCollectBar:setBotTouch(false)
    end
end

function CodeGameScreenJungleKingpinMachine:InitBonusMap(_maps)
    for i, v in ipairs(_maps) do
        self.m_bonusReels[i]:InitReconnetMap(v)
    end
end

function CodeGameScreenJungleKingpinMachine:isTriggerBonusGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.bonusLeftCount and selfData.bonusLeftCount > 0 and selfData.bonusLeftCount ~= selfData.bonusTotalCount then
        return true
    end
    return false
end

function CodeGameScreenJungleKingpinMachine:initGameStatusData(gameData)
    if gameData.collect ~= nil then
        self.m_collectNum = self:getCollectNum(gameData.collect[1])
    else
        self.m_collectNum = 0
    end

    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenJungleKingpinMachine:getCollectNum(collect)
    local collectTotalCount = collect.collectTotalCount
    local collectCount = nil

    if collectTotalCount ~= nil then
        collectCount = collect.collectTotalCount - collect.collectLeftCount
    else
        collectTotalCount = collect.p_collectTotalCount
        collectCount = collect.p_collectTotalCount - collect.p_collectLeftCount
    end

    return collectCount
end

function CodeGameScreenJungleKingpinMachine:showCollectScatterNum()
    if self.m_SuperCollectBar ~= nil then
        self.m_SuperCollectBar:showCollectNum(self.m_collectNum)
    end
end

function CodeGameScreenJungleKingpinMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "JungleKingpinSounds/sound_JungleKingpin_scatter_ground.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenJungleKingpinMachine:specialSymbolActionTreatment( node)
    -- print("dada")

    if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        node = self:setSymbolToClipReel(node.p_cloumnIndex, node.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        if node then
            node:runAnim("buling")
        end
    end

   
end

--单列滚动停止回调
--
function CodeGameScreenJungleKingpinMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        self:playReelDownSound(reelCol,self.m_reelDownSound )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end
    

    

    --GoldWild and Scatter  play "buling" animation
    local isHaveWild = false
    for iRow = 1, self.m_iReelRowNum do
        local selfdata = self.m_runSpinResultData.p_selfMakeData
        local frssSpinType = selfdata.freeSpinType
        -- local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, iRow, SYMBOL_NODE_TAG))
        if targSp and targSp.p_symbolType == self.SYMBOL_SCORE_GOLD_WILD then
            if frssSpinType == 0 and (iRow == 1 and reelCol == 3) then
                targSp:setVisible(false)
                break
            end
            targSp = self:setSymbolToClipReel(reelCol, iRow, self.SYMBOL_SCORE_GOLD_WILD)
            if targSp then
                targSp:runAnim("buling")
            end
            isHaveWild = true
        end
       
    end
    if isHaveWild then

        local soundPath = "JungleKingpinSounds/sound_JungleKingpin_goldwild_ground.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

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
    if reelCol > 2 then
        local rundi = self.m_RunDi[reelCol]
        if rundi:isVisible() then
            util_playFadeOutAction(
                rundi,
                0.5,
                function()
                    rundi:setVisible(false)
                end
            )
        end
    end
    if reelCol == 5 then
        if self.m_fastRunID then
            gLobalSoundManager:stopAudio(self.m_fastRunID)
            self.m_fastRunID = nil
        end
    end
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

function CodeGameScreenJungleKingpinMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3 - slotNode.p_rowIndex
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)

    self.m_clipParent:addChild(slotNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

--添加金边
function CodeGameScreenJungleKingpinMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)
    -- if self.m_fastRunID == nil  then
    --     self.m_fastRunID = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_reel_run.mp3")
    -- end
    if col > 2 then
        local rundi = self.m_RunDi[col]
        if rundi then
            rundi:setVisible(true)
            util_setCascadeOpacityEnabledRescursion(rundi, true)
            rundi:setOpacity(0)
            util_playFadeInAction(rundi, 0.1)
        end
    end
    reelEffectNode:setVisible(true)
    util_setCascadeOpacityEnabledRescursion(reelEffectNode, true)
    reelEffectNode:setOpacity(0)
    util_playFadeInAction(reelEffectNode, 0.1)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_reel_run.mp3")
    -- self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenJungleKingpinMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        -- local slotParent = targSp:getParent()
        -- local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        -- local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        -- targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        -- local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        -- targSp.m_showOrder = showOrder
        -- targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        -- targSp:removeFromParent()
        -- self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        -- targSp:setPosition(cc.p(pos.x, pos.y))
        -- 上面的代码没有考虑到快停时，图标的当前位置就不准确的问题 --22.02.22
        util_setSymbolToClipReel(self, targSp.p_cloumnIndex, targSp.p_rowIndex, targSp.p_symbolType, 0)

        local linePos = {}
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = true
        targSp:setLinePos(linePos)
    end
    return targSp
end


----------------------------- 玩法处理 -----------------------------------
---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenJungleKingpinMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local frssSpinType = selfdata.freeSpinType
    if frssSpinType == 0 then
        local avgBet = self.m_runSpinResultData.p_avgBet
        if avgBet <= 0 then
            local selfdata = self.m_runSpinResultData.p_selfMakeData
            if selfdata.bet then
                avgBet = selfdata.bet
            end
        end
        self.m_jackPotBar:setCurrBet(avgBet)
        self:setCurrBet(avgBet)
        for i = 1, 3 do
            self.m_bonusReels[i]:setCurrBet(avgBet)
        end
        self.m_bottomUI:showAverageBet()
    end
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenJungleKingpinMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenJungleKingpinMachine:showFreeSpinView(effectData)
    self:clearCurMusicBg()
    local delayTime = 0.5
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        delayTime = 1.5
    end
    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_freespin_more.mp3")
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes, effectData)
        end
    end

    performWithDelay(
        self,
        function()
            showFSView()
        end,
        delayTime
    )
end

function CodeGameScreenJungleKingpinMachine:addReelEffect(_iCol)
    local addBonusSymbol = {}
    for iRow = 1, self.m_iReelRowNum, 1 do
        local node = self:getReelParent(_iCol):getChildByTag(self:getNodeTag(_iCol, iRow, SYMBOL_NODE_TAG))
        local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(_iCol, iRow, SYMBOL_NODE_TAG))
        if not node then
            node = clipSp
        end
        if node then
            node:setVisible(false)
            addBonusSymbol[iRow] = node.p_symbolType
        end
    end

    local str = "addReelNode" .. _iCol
    local addReelView = util_createView("CodeJungleKingpinSrc.JungleKingpinAddView")

    self:findChild(str):addChild(addReelView)

    if globalData.slotRunData.machineData.p_portraitFlag then
        addReelView.getRotateBackScaleFlag = function()
            return false
        end
    end

    addReelView:initFirstSymbol(addBonusSymbol)
    --传入信号池
    addReelView:setNodePoolFunc(
        function(symbolType)
            return self:getSlotNodeBySymbolType(symbolType)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )

    addReelView:initFeatureUI()

    addReelView:setOverCallBackFun(
        function()
            -- util_playFadeOutAction(addReelView,0.5,function()
            addReelView:removeFromParent()
            self.m_playAddBonus = false
            -- end)

            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getReelParent(_iCol):getChildByTag(self:getNodeTag(_iCol, iRow, SYMBOL_NODE_TAG))
                local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(_iCol, iRow, SYMBOL_NODE_TAG))
                if not node then
                    node = clipSp
                end
                if node then
                    node:setVisible(true)
                -- util_setCascadeOpacityEnabledRescursion(node,true)
                -- node:setOpacity(0)
                -- util_playFadeInAction(node,0.1)
                end
            end
            --开始spin
            -- if self.m_effectData.p_isPlay == false then
            --     -- self.m_bFirstInFreeSpin = true
            --     -- self.m_effectData.p_isPlay = true
            --     -- self:playGameEffect()
            -- end
            self:playWildAddToReel(true)
            --test
            -- scheduler.performWithDelayGlobal(
            --     function()
            --         self.m_playAddBonus = true
            --         self:addReelEffect(_iCol)
            --     end,
            --     3.5,
            --     self:getModuleName()
            -- )
        end
    )
    addReelView:setAddBonusFlyEffectCallBackFun(
        function()
            --  self:playAddBonusFlyEffect(_iCol)
        end
    )
    addReelView:beginMove()
end

function CodeGameScreenJungleKingpinMachine:playWildAddToReel(_playBuling)
    local targSp = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)
    if targSp then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local endPos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        -- local startPos = cc.p(endPos.x, endPos.y + 100)

        local wild = self:getSlotNodeBySymbolType(self.SYMBOL_SCORE_GOLD_WILD)
        wild.p_cloumnIndex = targSp.p_cloumnIndex
        wild.p_rowIndex = targSp.p_rowIndex
        wild.m_isLastSymbol = targSp.m_isLastSymbol
        wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        local showOrder = self:getBounsScatterDataZorder(self.SYMBOL_SCORE_GOLD_WILD) - wild.p_rowIndex
        wild.m_showOrder = showOrder
        self.m_clipParent:addChild(wild, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder)
        local tag = self:getNodeTag(3, 1, SYMBOL_NODE_TAG)
        wild:setTag(tag)
        wild:setPosition(endPos)
        local linePos = {}
        linePos[#linePos + 1] = {iX = 1, iY = 3}
        wild.m_bInLine = true
        wild:setLinePos(linePos)
        self.m_SuperLockWild = wild

        local symbolType = targSp.p_symbolType
        targSp:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(symbolType, targSp)
        if _playBuling then
            gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_superfreespin_addwild.mp3")
            wild:runAnim(
                "buling2",
                false,
                function()
                    -- wild:runAnim("houjiao")
                    self:createSuperLockWildEffect(endPos, _playBuling)
                end
            )
        end

        local moveTo = cc.MoveTo:create(0.3, endPos)
        local fun =
            cc.CallFunc:create(
            function()
            end
        )
        wild:runAction(cc.Sequence:create(moveTo, fun))
    else
        local wild = self:getSlotNodeBySymbolType(self.SYMBOL_SCORE_GOLD_WILD)
        wild.p_cloumnIndex = 3
        wild.p_rowIndex = 1
        wild.m_isLastSymbol = false
        wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        local tag = self:getNodeTag(3, 1, SYMBOL_NODE_TAG)
        wild:setTag(tag)
        local startPos = self:getNodePosByColAndRow(3, 1)
        local slotParent = self:getReelParent(3)
        local posWorld = slotParent:convertToWorldSpace(cc.p(startPos.x, startPos.y))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        local showOrder = self:getBounsScatterDataZorder(_type) - wild.p_rowIndex
        wild.m_showOrder = showOrder
        self.m_clipParent:addChild(wild, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder)
        wild:setPosition(pos)
        local linePos = {}
        linePos[#linePos + 1] = {iX = 1, iY = 3}
        wild.m_bInLine = true
        wild:setLinePos(linePos)
        self.m_SuperLockWild = wild
        if _playBuling then
            wild:runAnim(
                "buling",
                false,
                function()
                    self:createSuperLockWildEffect(pos, _playBuling)
                end
            )
        else
            self:createSuperLockWildEffect(pos, _playBuling)
        end
    end
end

--创建锁定 superFreeSpin wild 的效果
function CodeGameScreenJungleKingpinMachine:createSuperLockWildEffect(pos, _playBuling)
    self.m_SuperLockWildEffect = util_createView("CodeJungleKingpinSrc.JungleKingpinLockWildView")
    self.m_SuperLockWildEffect:setPosition(pos)
    local showOrder = self:getBounsScatterDataZorder(self.SYMBOL_SCORE_GOLD_WILD)
    self.m_clipParent:addChild(self.m_SuperLockWildEffect, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
    self.m_SuperLockWildEffect:setPosition(pos)
    if _playBuling then
        gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_gold_xian.mp3")
        self.m_SuperLockWildEffect:runCsbAction(
            "actionframe",
            false,
            function()
                self.m_SuperLockWildEffect:runCsbAction("idle2", true)
                -- self.m_SuperLockWildEffect:removeFromParent()
                -- self.m_SuperLockWildEffect = nil
                if self.m_SuperLockWild then
                    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_goldwild_hou.mp3")
                    self.m_SuperLockWild:runAnim(
                        "houjiao",
                        false,
                        function()
                            self.m_effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
                end
            end
        )
    else
        self.m_SuperLockWildEffect:runCsbAction("idle2", true)
    end
end

function CodeGameScreenJungleKingpinMachine:showFreeSpinStart(num, effectData)
    if not self.m_freespinStartTag then
        self.m_freespinStartTag = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_freespin_start.mp3", false)
        performWithDelay(
            self,
            function()
                self.m_freespinStartTag = nil
            end,
            2
        )
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local frssSpinType = selfdata.freeSpinType
    if frssSpinType == 0 then
        self.m_superfsStartTag = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_superfreespin_tip.mp3", false)
        performWithDelay(
            self,
            function()
                self.m_superfsStartTag = nil
            end,
            1
        )

        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        local view =
            self:showDialog(
            "SuperFreeSpinStart",
            ownerlist,
            function()
                self:playTransitionEffect(
                    function()
                        local avgBet = self.m_runSpinResultData.p_avgBet
                        if avgBet <= 0 then
                            local selfdata = self.m_runSpinResultData.p_selfMakeData
                            if selfdata.bet then
                                avgBet = selfdata.bet
                            end
                        end
                        self.m_jackPotBar:setCurrBet(avgBet)
                        self:setCurrBet(avgBet)
                        for i = 1, 3 do
                            self.m_bonusReels[i]:setCurrBet(avgBet)
                        end
                        self.m_bottomUI:showAverageBet()
                    end
                )
                if self.m_freespinStartTag then
                    gLobalSoundManager:stopAudio(self.m_freespinStartTag)
                    self.m_freespinStartTag = nil
                end
                if self.m_superfsStartTag then
                    gLobalSoundManager:stopAudio(self.m_superfsStartTag)
                    self.m_superfsStartTag = nil
                end
                self.m_effectData = effectData
                scheduler.performWithDelayGlobal(
                    function()
                        self:triggerFreeSpinCallFun()
                        self:changeNormalAndFreespinReel(1)
                    end,
                    1,
                    self:getModuleName()
                )
                scheduler.performWithDelayGlobal(
                    function()
                        self:playWildAddToReel(true)
                        -- self:addReelEffect(3)
                    end,
                    2.5,
                    self:getModuleName()
                )
                self:resetMusicBg(true)
            end
        )
        return view
    else
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        local view =
            self:showDialog(
            BaseDialog.DIALOG_TYPE_FREESPIN_START,
            ownerlist,
            function()
                self:playTransitionEffect(
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
                if self.m_freespinStartTag then
                    gLobalSoundManager:stopAudio(self.m_freespinStartTag)
                    self.m_freespinStartTag = nil
                end
                scheduler.performWithDelayGlobal(
                    function()
                        self:triggerFreeSpinCallFun()
                        self:changeNormalAndFreespinReel(1)
                    end,
                    1,
                    self:getModuleName()
                )
                self:resetMusicBg(true)
            end
        )
        return view
    end
end

function CodeGameScreenJungleKingpinMachine:showFreeSpinOverView()
    -- gLobalSoundManager:playSound("JungleKingpinSounds/music_JungleKingpin_over_fs.mp3")
    scheduler.performWithDelayGlobal(
        function()
            local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
            local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount)
            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node, sx = 1, sy = 1}, 565)
        end,
        1.0,
        self:getModuleName()
    )
end

function CodeGameScreenJungleKingpinMachine:showFreeSpinOver(coins, num)
    self:clearCurMusicBg()

    if not self.m_FsOverTag then
        self.m_FsOverTag = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_freespin_over.mp3", false)
        performWithDelay(
            self,
            function()
                self.m_FsOverTag = nil
            end,
            5
        )
    end
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local frssSpinType = selfdata.freeSpinType
    if frssSpinType == 0 then
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        return self:showDialog(
            "SuperFreeSpinOver",
            ownerlist,
            function()
                if self.m_FsOverTag then
                    gLobalSoundManager:stopAudio(self.m_FsOverTag)
                    self.m_FsOverTag = nil
                end
                if self.m_bonusOverAndFreeSpinOver == true then
                    self.m_jackPotBar:setCurrBet()
                    self:setCurrBet()
                    for i = 1, 3 do
                        self.m_bonusReels[i]:setCurrBet()
                    end
                    self.m_bottomUI:hideAverageBet()
                    self.m_bonusOverAndFreeSpinOver = false
                else
                    self:playTransitionEffect(
                        function()
                            self.m_jackPotBar:setCurrBet()
                            self:setCurrBet()
                            for i = 1, 3 do
                                self.m_bonusReels[i]:setCurrBet()
                            end
                            self.m_bottomUI:hideAverageBet()
                        end
                    )
                end
                self:resetMusicBg(true)
                scheduler.performWithDelayGlobal(
                    function()
                        if self.m_SuperLockWild ~= nil then
                            self:setWildOldReel(self.m_SuperLockWild, 3, 1)
                            self.m_SuperLockWild = nil
                        end
                        if self.m_SuperLockWildEffect ~= nil then
                            self.m_SuperLockWildEffect:removeFromParent()
                            self.m_SuperLockWildEffect = nil
                        end
                        self.m_collectNum = 0
                        self.m_SuperCollectBar:showCollectNum(self.m_collectNum)
                        self:changeNormalAndFreespinReel(0)
                        self:triggerFreeSpinOverCallFun()
                        if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
                            self.m_SuperCollectBar:setBotTouch(true)
                        end
                    end,
                    1,
                    self:getModuleName()
                )
            end
        )
    else
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
        return self:showDialog(
            BaseDialog.DIALOG_TYPE_FREESPIN_OVER,
            ownerlist,
            function()
                if self.m_FsOverTag then
                    gLobalSoundManager:stopAudio(self.m_FsOverTag)
                    self.m_FsOverTag = nil
                end

                if self.m_bonusOverAndFreeSpinOver == true then
                    self.m_bonusOverAndFreeSpinOver = false
                else
                    self:playTransitionEffect()
                end

                self:resetMusicBg(true)
                scheduler.performWithDelayGlobal(
                    function()
                        self:changeNormalAndFreespinReel(0)
                        self:triggerFreeSpinOverCallFun()
                        if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
                            self.m_SuperCollectBar:setBotTouch(true)
                        end
                    end,
                    1,
                    self:getModuleName()
                )
            end
        )
    end
end

function CodeGameScreenJungleKingpinMachine:changeNormalAndFreespinReel(_type)
    if _type == 1 then
        self:findChild("Node_reel_nomal"):setVisible(false)
        self:findChild("Node_reel_spin"):setVisible(true)
        self.m_gameBg:runCsbAction("idle2", false)
    elseif _type == 0 then
        self:findChild("Node_reel_nomal"):setVisible(true)
        self:findChild("Node_reel_spin"):setVisible(false)
        self.m_gameBg:runCsbAction("idle1", true)
    elseif _type == 3 then
        self:findChild("Node_reel_nomal"):setVisible(true)
        self:findChild("Node_reel_spin"):setVisible(false)
        self.m_gameBg:runCsbAction("bianse", false)
    end
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenJungleKingpinMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_fisrtLinesWinCoin = 0
    self.m_bonusGameFlag = false
    if globalData.slotRunData.currSpinMode == SPECIAL_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, false)
    end
    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenJungleKingpinMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenJungleKingpinMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end
--设置bonus scatter 层级
function CodeGameScreenJungleKingpinMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_SCORE_GOLD_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
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

-- 处理特殊关卡 遮罩层级
function CodeGameScreenJungleKingpinMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    slotParent:getParent():setLocalZOrder(parentData.cloumnIndex * 10)
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenJungleKingpinMachine:getResNodeSymbolType(parentData)
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4
    elseif symbolType == self.SYMBOL_SCORE_GOLD_WILD then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8
    end
    return symbolType
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenJungleKingpinMachine:addSelfEffect()
    if self:isTriggerFirstWinLine() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 5
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SHOW_FIRST_WINLINE
    end

    --是否触发 bonus wild的掉落玩法
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local frssSpinType = selfdata.freeSpinType

    if self:isTriggerGlodWildEffect() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 4
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_GOLD_WILD_EFFECT
    end
    --收集scatter 增加触发super free次数
    if self:isTriggerFreespin() and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_COLLECT_SCATTER

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 3
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TIRIGGER_SCATTER
    end

    if frssSpinType and frssSpinType == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SUPER_FREESPIN
    end

    local hasFreepinFeature = false
    if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end
    local hasBonusFeature = false
    if self:checkHasEffectType(GameEffect.EFFECT_BONUS) == true then
        hasBonusFeature = true
    end
    if hasFreepinFeature == false and hasBonusFeature == false and self.getCurrSpinMode() == NORMAL_SPIN_MODE then
        self.m_SuperCollectBar:setBotTouch(true)
    end
end

--是否触发 glod wild 掉落玩法
function CodeGameScreenJungleKingpinMachine:isTriggerFirstWinLine()
    self.m_vecFirstGetLineInfo = {}
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local winLines = selfdata.fallLines
    if selfdata.fallWinAmount then
        self.m_fisrtLinesWinCoin = self.m_runSpinResultData.p_winAmount - selfdata.fallWinAmount
        if
            self.m_runSpinResultData.p_freeSpinsTotalCount == 0 or
                (self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount)
         then
            self:setLastWinCoin(self.m_fisrtLinesWinCoin)
        else
            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins - selfdata.fallWinAmount)
        end
    end

    if winLines and #winLines > 0 then
        self:compareFirstScatterWinLines(winLines)

        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.icons

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()

            local enumSymbolType = self:getFirstWinLineSymboltType(winLineData, lineInfo)

            if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
                if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
                elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                end
            end

            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.amount / (self.m_runSpinResultData:getBetValue())

            if lineInfo.iLineSymbolNum >= 5 then
            -- isFiveOfKind = true
            end

            self.m_vecFirstGetLineInfo[#self.m_vecFirstGetLineInfo + 1] = lineInfo
        end
    end
    self:keepCurrentFirstSpinData()
    if self.m_FirstReelResultLines ~= nil and #self.m_FirstReelResultLines > 0 then
        return true
    end
    return false
end
--[[
    @desc: 计算单线
    time:2018-08-16 19:35:49
    --@lineData: 
    @return:
]]
function CodeGameScreenJungleKingpinMachine:getFirstWinLineSymboltType(winLineData, lineInfo)
    local iconsPos = winLineData.icons
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex = 1, #iconsPos do
        local posData = iconsPos[posIndex]

        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData -- 连线元素的 pos信息

        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            enumSymbolType = symbolType
        end
    end
    return enumSymbolType
end
--[[
    @desc: 对比 winline 里面的所有线， 将相同的线 进行合并，
    这个主要用来处理， winLines 里面会存在两条一样的触发 fs的线，其中一条线winAmount为0，另一条
    有值， 这中情况主要使用与
    time:2018-08-16 19:30:23
    @return:  只保留一份 scatter 赢钱的线，如果存在允许scatter 赢钱的话
]]
function CodeGameScreenJungleKingpinMachine:compareFirstScatterWinLines(winLines)
    local scatterLines = {}
    local winAmountIndex = -1
    for i = 1, #winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.icons
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        for posIndex = 1, #iconsPos do
            local posData = iconsPos[posIndex]
            local rowColData = self:getRowAndColByPos(posData)

            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            scatterLines[#scatterLines + 1] = {i, winLineData.p_amount}
            if winLineData.amount > 0 then
                winAmountIndex = i
            end
        end
    end

    if #scatterLines > 0 and winAmountIndex > 0 then
        for i = #scatterLines, 1, -1 do
            local lineData = scatterLines[i]
            if lineData[2] == 0 then
                table.remove(winLines, lineData[1])
            end
        end
    end
end

local function cloneLineInfo(originValue, targetValue)
    targetValue.enumSymbolType = originValue.enumSymbolType
    targetValue.enumSymbolEffectType = originValue.enumSymbolEffectType
    targetValue.iLineIdx = originValue.iLineIdx
    targetValue.iLineSymbolNum = originValue.iLineSymbolNum
    targetValue.iLineMulti = originValue.iLineMulti
    targetValue.lineSymbolRate = originValue.lineSymbolRate

    local matrixPosLen = #originValue.vecValidMatrixSymPos
    for i = 1, matrixPosLen do
        local value = originValue.vecValidMatrixSymPos[i]

        table.insert(targetValue.vecValidMatrixSymPos, {iX = value.iX, iY = value.iY})
    end
end

function CodeGameScreenJungleKingpinMachine:keepCurrentFirstSpinData() --保留本轮数据
    self.m_FirstReelResultLines = {}
    if #self.m_vecFirstGetLineInfo ~= 0 then
        local lines = self.m_vecFirstGetLineInfo
        local lineLen = #lines
        local hasBonus = false
        local hasScatter = false
        for i = 1, lineLen do
            local value = lines[i]

            local function copyLineValue()
                local cloneValue = self:getReelLineInfo()
                cloneLineInfo(value, cloneValue)
                table.insert(self.m_FirstReelResultLines, cloneValue)

                if #cloneValue.vecValidMatrixSymPos > 5 then
                -- printInfo("")
                end
            end

            if value.enumSymbolEffectType == GameEffect.EFFECT_BONUS or value.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                if value.enumSymbolEffectType == GameEffect.EFFECT_BONUS and hasBonus == false then
                    copyLineValue()
                    hasBonus = true
                elseif value.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN and hasScatter == false then
                    copyLineValue()
                    hasScatter = true
                end
            else
                copyLineValue()
            end
        end
    end
end
--是否触发 glod wild 掉落玩法
function CodeGameScreenJungleKingpinMachine:isTriggerGlodWildEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.fallSignals ~= nil and #selfdata.fallSignals > 0 then
            return true
        end
    end
    return false
end
--
function CodeGameScreenJungleKingpinMachine:setGoldWildList()
    self.m_goldWildList = nil
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                -- print("iCol == " .. iCol .. "iRow == " .. iRow .. "node.p_symbolType == " .. node.p_symbolType)
                if node.p_symbolType == self.SYMBOL_SCORE_GOLD_WILD then
                    if not self.m_goldWildList then
                        self.m_goldWildList = {}
                    end
                    self.m_goldWildList[#self.m_goldWildList + 1] = node
                end
            end
        end
    end
end
--是否有低级图标
function CodeGameScreenJungleKingpinMachine:isHaveLowSymbol()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if
                    node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 or node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 or node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 or
                        node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_2 or
                        node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 or
                        node.p_symbolType == self.SYMBOL_SCORE_10
                 then
                    return true
                end
            end
        end
    end
    return false
end

--是否触发freespin
function CodeGameScreenJungleKingpinMachine:isTriggerFreespin()
    if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
        return true
    end
    return false
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenJungleKingpinMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_GOLD_WILD_EFFECT then
        self:setGoldWildList()
        self:playGoldWildEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_TIRIGGER_SCATTER then
        self:playTirggerScatterEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_SCATTER then
        self:playCollectScatterEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_SUPER_FREESPIN then
        self:playSuperFreeSpinEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_SHOW_FIRST_WINLINE then
        self:playFirstWinLineEffect(effectData)
    end

    return true
end

function CodeGameScreenJungleKingpinMachine:playFirstWinLineEffect(effectData)
    local winLines = self.m_FirstReelResultLines
    if #winLines <= 0 then
        return
    end
    self:removeFirstScatterWinLines()
    self.m_firstWinCoin = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_fisrtLinesWinCoin, false})

    self.m_lineSlotNodes = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()

    self:playInLineNodes()

    self:showAllFrame(winLines) -- 播放全部线框
    -- 判断什么时候停调用
    local delayTime = self.m_changeLineFrameTime
    scheduler.performWithDelayGlobal(
        function()
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()

            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        delayTime,
        self:getModuleName()
    )
end

function CodeGameScreenJungleKingpinMachine:removeFirstScatterWinLines()
    if self.m_FirstReelResultLines and type(self.m_FirstReelResultLines) == "table" then
        local scatterLineValue = nil
        for i = #self.m_FirstReelResultLines, 1, -1 do
            local lineData = self.m_FirstReelResultLines[i]
            if lineData then
                if lineData.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    table.remove(self.m_FirstReelResultLines, i)
                end
            end
        end
    end
end

--播放gold wild 的效果
function CodeGameScreenJungleKingpinMachine:playGoldWildEffect(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    self.m_iFallNum = 1 --下落次数
    if selfdata ~= nil then
        if selfdata.fallSignals ~= nil and #selfdata.fallSignals > 0 then
            self:playGoldWildStartEffect()
            scheduler.performWithDelayGlobal(
                function()
                    self:playRemoveLowSymbolEffect()
                end,
                0.5,
                self:getModuleName()
            )
            self.m_effectData = effectData
        end
    end
end

--播放猩猩怒吼
function CodeGameScreenJungleKingpinMachine:playGoldWildStartEffect()
    if self.m_goldWildList and #self.m_goldWildList > 0 then
        gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_goldwild_hou.mp3")
        for _, node in pairs(self.m_goldWildList) do
            node:runAnim("houjiao")
            -- scheduler.performWithDelayGlobal(
            --     function()
            --         local effectNode = util_createAnimation("hou.csb")
            --         local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
            --         local startPos = self:convertToNodeSpace(pos)
            --         -- node:addChild(effectNode, 2)
            --         self:addChild(effectNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
            --         effectNode:setPosition(startPos)
            --         effectNode:playAction(
            --             "animation0",
            --             false,
            --             function()
            --                 effectNode:removeFromParent()
            --             end
            --         )
            --     end,
            --     0.5,
            --     self:getModuleName()
            -- )
        end
    end
    if
        self.m_runSpinResultData.p_freeSpinsTotalCount == 0 or
            (self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount)
     then
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
    end
end

--计算所在列位置坐标
function CodeGameScreenJungleKingpinMachine:getNodePosByColAndRow(col, row)
    local posX, posY = 0, 0
    posX = posX + self.m_SlotNodeW
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

--消除低级图标
function CodeGameScreenJungleKingpinMachine:playRemoveLowSymbolEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.removeSignals ~= nil and #selfdata.removeSignals > 0 then
            if #selfdata.removeSignals >= self.m_iFallNum then
                local removeSymbolInfo = selfdata.removeSignals[self.m_iFallNum]
                gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_symbol_sui.mp3")
                for i, v in ipairs(removeSymbolInfo) do
                    local fixPos = self:getRowAndColByPos(v)
                    local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    if targSp then
                        targSp:runAnim(
                            "actionframe_sui",
                            false,
                            function()
                                targSp:removeFromParent()
                                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
                            end
                        )
                    end
                end
                scheduler.performWithDelayGlobal(
                    function()
                        self:playFallSymbolEffect()
                    end,
                    0.8,
                    self:getModuleName()
                )
            else
                self.m_effectData.p_isPlay = true
                self:playGameEffect()
            end
        end
    end
end

function CodeGameScreenJungleKingpinMachine:isNeedMove(_col, _row)
    for iRow = self.m_iReelRowNum, 1, -1 do
        local node = self:getFixSymbol(_col, iRow, SYMBOL_NODE_TAG)
        if _row > iRow and node == nil then
            return true
        end
    end
    return false
end

function CodeGameScreenJungleKingpinMachine:needMovePos(_col, _row)
    local num = 0
    for iRow = _row, 1, -1 do
        local node = self:getFixSymbol(_col, iRow, SYMBOL_NODE_TAG)
        if node == nil then
            num = num + 1
        end
    end
    return num
end

--重新掉落图标
function CodeGameScreenJungleKingpinMachine:playFallSymbolEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.fallSignals ~= nil and #selfdata.fallSignals > 0 then
            if #selfdata.fallSignals >= self.m_iFallNum then
                for iCol = 1, self.m_iReelColumnNum do
                    for iRow = self.m_iReelRowNum, 1, -1 do
                        if self:isNeedMove(iCol, iRow) then
                            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                            if targSp then
                                local posNum = self:needMovePos(iCol, iRow)
                                local pos = cc.p(targSp:getPosition())
                                pos.y = pos.y - posNum * self.m_SlotNodeH
                                local moveTo = cc.MoveTo:create(0.2, pos)
                                local fun =
                                    cc.CallFunc:create(
                                    function()
                                        local tag = self:getNodeTag(iCol, iRow - posNum, SYMBOL_NODE_TAG)
                                        targSp:setTag(tag)
                                    end
                                )
                                -- if targSp.p_symbolType == self.SYMBOL_SCORE_GOLD_WILD then
                                local linePos = {}
                                linePos[#linePos + 1] = {iX = iRow - posNum, iY = iCol}
                                targSp.m_bInLine = true
                                targSp:setLinePos(linePos)
                                -- end
                                targSp:runAction(cc.Sequence:create(moveTo, fun))
                            end
                        end
                    end
                end
                local fallSymbolInfo = selfdata.fallSignals[self.m_iFallNum]
                --破碎音效
                self:playSymbolSuiSound(fallSymbolInfo)
                --破碎动画
                for i, v in ipairs(fallSymbolInfo) do
                    local pos = v[1]
                    local _type = v[2]
                    local fixPos = self:getRowAndColByPos(pos)
                    local symbol = self:getSlotNodeBySymbolType(_type)
                    local tag = self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    symbol.p_cloumnIndex = fixPos.iY
                    symbol.p_rowIndex = fixPos.iX
                    symbol:setTag(tag)
                    local showOrder = self:getBounsScatterDataZorder(_type) - fixPos.iX
                    symbol.m_showOrder = showOrder
                    self:getReelParent(fixPos.iY):addChild(symbol, showOrder)
                    local num = self:getColNum(fixPos.iY, fixPos.iX)
                    local startpos = self:getNodePosByColAndRow(fixPos.iY, 3 + num)
                    symbol:setPosition(startpos)
                    if self:getIsLowType(_type) then
                        symbol:runAnim(
                            "actionframe_sui",
                            false,
                            function()
                                symbol:removeFromParent()
                                self:pushSlotNodeToPoolBySymobolType(symbol.p_symbolType, symbol)
                            end
                        )
                    end

                    local endPos = self:getNodePosByColAndRow(fixPos.iY, fixPos.iX)
                    local moveTo = cc.MoveTo:create(0.2, endPos)
                    local fun =
                        cc.CallFunc:create(
                        function()
                            if _type == self.SYMBOL_SCORE_GOLD_WILD or _type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                                symbol = self:setSymbolToClipReel(fixPos.iY, fixPos.iX, _type)
                                if _type == self.SYMBOL_SCORE_GOLD_WILD then
                                    local linePos = {}
                                    linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                                    symbol.m_bInLine = true
                                    symbol:setLinePos(linePos)
                                end
                            end
                        end
                    )
                    symbol:runAction(cc.Sequence:create(moveTo, fun))
                end
                scheduler.performWithDelayGlobal(
                    function()
                        self.m_iFallNum = self.m_iFallNum + 1
                        self:playFallSymbolEffect()
                    end,
                    0.8,
                    self:getModuleName()
                )
            else
                self.m_effectData.p_isPlay = true
                local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_BONUS)
                if hasFsEffect == true then
                    self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
                    self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
                    self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
                end
                self:playGameEffect()
                --第一次有连线 第二次无连线刷新top数据
                self:updataTopWinCoin()
            end
        end
    end
end

function CodeGameScreenJungleKingpinMachine:updataTopWinCoin()
    local winLines = self.m_reelResultLines
    if #winLines <= 0 and self.m_iOnceSpinLastWin > 0 then
        -- 如果freespin 未结束，不通知左上角玩家钱数量变化
        local isNotifyUpdateTop = true
        if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 or self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
            isNotifyUpdateTop = false
        end
        if isNotifyUpdateTop then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
        end
    end
end

function CodeGameScreenJungleKingpinMachine:playSymbolSuiSound(_fallSymbolInfo)
    if _fallSymbolInfo and #_fallSymbolInfo > 0 then
        local haveLow = false
        for i, v in ipairs(_fallSymbolInfo) do
            local pos = v[1]
            local _type = v[2]
            if self:getIsLowType(_type) then
                haveLow = true
            end
        end
        if haveLow then
            scheduler.performWithDelayGlobal(
                function()
                    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_symbol_sui.mp3")
                end,
                0.2,
                self:getModuleName()
            )
        end
    end
end
--是否是低级图标
function CodeGameScreenJungleKingpinMachine:getIsLowType(_type)
    if
        _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 or _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 or _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 or _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_2 or
            _type == TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 or
            _type == self.SYMBOL_SCORE_10
     then
        return true
    end
    return false
end

function CodeGameScreenJungleKingpinMachine:getColNum(_col, _row)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local upNum = 1
    if selfdata ~= nil then
        if selfdata.fallSignals ~= nil and #selfdata.fallSignals > 0 then
            if #selfdata.fallSignals >= self.m_iFallNum then
                local fallSymbolInfo = selfdata.fallSignals[self.m_iFallNum]
                for i, v in ipairs(fallSymbolInfo) do
                    local pos = v[1]
                    local fixPos = self:getRowAndColByPos(pos)
                    if _col == fixPos.iY and _row > fixPos.iX then
                        upNum = upNum + 1
                    end
                end
            end
        end
    end
    return upNum
end

function CodeGameScreenJungleKingpinMachine:playTirggerScatterEffect(effectData)
    --全部scatter的触发动画
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_scatter_start.mp3")
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                targSp:runAnim(
                    "chufa",
                    false,
                    function()
                        -- targSp:runAnim("idleframe2", false)
                    end
                )
            end
        end
    end
    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        2.8
    )
end
--播放scatter 收集效果
function CodeGameScreenJungleKingpinMachine:playCollectScatterEffect(effectData)
    self:updateCollect()

    -- local endPos = self.m_SuperCollectBar:getCollectPos(self.m_collectNum)
    -- gLobalSoundManager:playSound("PirateSounds/sound_pirate_fly_wild.mp3")
    local endPos = self.m_SuperCollectBar:getEndPos(self.m_collectNum)
    local scatter = self:getSlotNodeBySymbolType(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    self.m_SuperCollectBar:addChild(scatter)
    scatter:setPosition(endPos)
    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_scatter_collect.mp3")
    scatter:runAnim(
        "shoujifankui",
        false,
        function()
            scatter:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(scatter.p_symbolType, scatter)
            self.m_SuperCollectBar:showCollectNum(self.m_collectNum)
            if self.m_collectNum == 5 then
                gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_superfreespin_shan.mp3")
                self.m_SuperCollectBar:runCsbAction(
                    "animation0",
                    false,
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            else
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        end
    )

    -- scheduler.performWithDelayGlobal(
    --     function()
    --         effectData.p_isPlay = true
    --         self:playGameEffect()
    --     end,
    --     1.5,
    --     self:getModuleName()
    -- )
    -- end
end

function CodeGameScreenJungleKingpinMachine:playSuperFreeSpinEffect(_effectData)
    local targSp = self:getReelParent(3):getChildByTag(self:getNodeTag(3, 1, SYMBOL_NODE_TAG))
    -- local targSp = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)
    if targSp then
        if self.m_SuperLockWild then
            local symbolType = self.m_SuperLockWild.p_symbolType
            self.m_SuperLockWild:removeFromParent()
            self:pushSlotNodeToPoolBySymobolType(symbolType, self.m_SuperLockWild)
            self.m_SuperLockWild = nil
        end

        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        local wild = self:getSlotNodeBySymbolType(self.SYMBOL_SCORE_GOLD_WILD)
        wild.p_cloumnIndex = 3
        wild.p_rowIndex = 1
        wild.m_isLastSymbol = false
        local showOrder = self:getBounsScatterDataZorder(self.SYMBOL_SCORE_GOLD_WILD) - 1
        wild.m_showOrder = showOrder
        wild.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        wild:setPosition(cc.p(pos.x, pos.y))
        self.m_clipParent:addChild(wild, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:removeFromParent()
        local symbolType = targSp.p_symbolType
        self:pushSlotNodeToPoolBySymobolType(symbolType, targSp)
        local linePos = {}
        linePos[#linePos + 1] = {iX = 1, iY = 3}
        wild.m_bInLine = true
        wild:setLinePos(linePos)
        self.m_SuperLockWild = wild
    end

    performWithDelay(
        self,
        function()

            _effectData.p_isPlay = true
            self:playGameEffect()
        end,
        0.5
    )
end

--锁定wild
function CodeGameScreenJungleKingpinMachine:setWildSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        local linePos = {}
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = true
        targSp:setLinePos(linePos)
    end
    return targSp
end
--重新设置wild层级
function CodeGameScreenJungleKingpinMachine:setWildOldReel(_target, _iCol, _iRow)
    if _target ~= nil then
        if _target.__cname ~= nil and _target.__cname == "SlotsNode" then
            _target:resetReelStatus()
        end
        if _target.p_layerTag ~= nil and _target.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE then
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(_target:getPositionX(), _target:getPositionY()))
            local pos = self.m_slotParents[_iCol].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            _target:removeFromParent()
            local zorder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
            _target:setLocalZOrder(zorder + _iCol)
            _target:setPosition(cc.p(pos.x, pos.y))
            _target.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            self.m_slotParents[_iCol].slotParent:addChild(_target)
        end
    end
end

function CodeGameScreenJungleKingpinMachine:updateCollect()
    local lastData = self.m_runSpinResultData.p_collectNetData[1]
    local collectTotalCount = lastData.collectTotalCount
    local collectCount = nil
    if collectTotalCount ~= nil then
        collectCount = lastData.collectTotalCount - lastData.collectLeftCount
    else
        collectTotalCount = lastData.p_collectTotalCount
        collectCount = lastData.p_collectTotalCount - lastData.p_collectLeftCount
    end
    self.m_collectNum = collectCount
end

-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenJungleKingpinMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenJungleKingpinMachine:showEffect_Bonus(effectData)
    if self.m_tip1:isVisible() then
        self.m_tip1:HideTip()
    end
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    self:bonusGameStart(
        function()
            -- self:playTransitionEffect()
            self.m_currentMusicBgName = "JungleKingpinSounds/music_JungleKingpin_BonusBg.mp3"
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
            scheduler.performWithDelayGlobal(
                function()
                    self:showBonusReel(false)
                    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
                        self:changeNormalAndFreespinReel(3)
                    end
                end,
                1,
                self:getModuleName()
            )
            scheduler.performWithDelayGlobal(
                function()
                    effectData.p_isPlay = true
                    -- self:playGameEffect()
                end,
                3,
                self:getModuleName()
            )
        end
    )
    return true
end

function CodeGameScreenJungleKingpinMachine:showBonusReel(_isReConnet)
    local data = {}
    data.index = 3
    data.parent = self

    self.m_bonusGameReel = util_createView("CodeJungleKingpinSrc.JungleKingpinMiniMachine", data)
    local posX, posY = self:findChild("BonusReelNode"):getPosition()
    self:findChild("root"):addChild(self.m_bonusGameReel)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_bonusGameReel.getRotateBackScaleFlag = function()
            return false
        end
    end

    self.m_bonusGameReel:setPosition(cc.p(posX, posY))
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE or self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.currSpinMode = SPECIAL_SPIN_MODE
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
    self.m_tip2:setVisible(false)
    if _isReConnet == false then
        gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_change_reel.mp3")
        self.m_bonusGameReel:runCsbAction(
            "buling",
            false,
            function()
                self.m_bonusGameReel:playEffectNotifyNextSpinCall()
                self:playEffectNotifyChangeSpinStatus()
            end
        )
        scheduler.performWithDelayGlobal(
            function()
                self:runCsbAction(
                    "FadeOut",
                    false,
                    function()
                        self:findChild("NormalReel"):setVisible(false)
                    end
                )
                self.m_baseFreeSpinBar:setVisible(false)
                self.m_SuperCollectBar:setVisible(false)
            end,
            1.7,
            self:getModuleName()
        )
    else
        self:findChild("NormalReel"):setVisible(false)
        self.m_baseFreeSpinBar:setVisible(false)
        self.m_SuperCollectBar:setVisible(false)
        self.m_bonusGameReel:runCsbAction("show")
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_runSpinResultData.p_bonusWinCoins))
    end
    local leftCount = self.m_runSpinResultData.p_selfMakeData.bonusLeftCount
    self.m_bonusGameReel:setBonusLeftTimes(leftCount)
    self.m_bonusGameReel:UpdataSpinCount()
    self.m_bonusGameReel:enterLevel()
    self.m_bBonusGame = true
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
end

function CodeGameScreenJungleKingpinMachine:bonusGameStart(func)
    self:clearCurMusicBg()
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp and (targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or targSp.p_symbolType == self.SYMBOL_SCORE_GOLD_WILD) then
                targSp:runAnim("idleframe2", false)
            end
        end
    end
    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_scatter_start.mp3")
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_bonus_tip.mp3")
            gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_superfreespin_rensheng.mp3")
            local view = self:bonusGameStartView("FeatureWon", func, true)
        end,
        4
    )
end

function CodeGameScreenJungleKingpinMachine:bonusGameStartView(csb_path, func, isAuto)
    local function newFunc()
        if func then
            func()
        end
    end
    local ownerlist = {}
    return self:showJungleKingpinDialog(csb_path, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
end

--添加到 轮盘节点上 适配
function CodeGameScreenJungleKingpinMachine:showJungleKingpinDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)
    self:findChild("middleNode"):addChild(view)

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end

    return view
end

function CodeGameScreenJungleKingpinMachine:showBonusGameOver(func)
    performWithDelay(
        self,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, false)
            local coins = self.m_BonusWinCoins
            local ownerlist = {}
            ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
            self:clearCurMusicBg()
            if not self.m_bonusStartTag then
                self.m_bonusStartTag = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_tip_over.mp3", false)
                performWithDelay(
                    self,
                    function()
                        self.m_bonusStartTag = nil
                    end,
                    4
                )
            end
            local view =
                self:showDialog(
                "FeatureOver",
                ownerlist,
                function()
                    if self.m_bonusStartTag then
                        gLobalSoundManager:stopAudio(self.m_bonusStartTag)
                        self.m_bonusStartTag = nil
                    end
                    self.m_bBonusGame = false
                    self:playTransitionEffect(
                        function()
                            if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                                local selfdata = self.m_runSpinResultData.p_selfMakeData
                                local frssSpinType = selfdata.freeSpinType
                                local effectData = GameEffectData.new()
                                effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
                                self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                                self.m_bottomUI:checkClearWinLabel()
                            end
                            if self.m_bProduceSlots_InFreeSpin ~= true then
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                            end
                            self:checkFeatureOverTriggerBigWin(self.m_BonusWinCoins, GameEffect.EFFECT_BONUS)
                            self:playGameEffect()
                        end
                    )
                    scheduler.performWithDelayGlobal(
                        function()
                            if func then
                                func()
                            end
                            self:resetReelMap()
                            self.m_tip2:setVisible(true)
                            self:setGameSpinStage(STOP_RUN)
                            if self.m_bonusGameReel ~= nil then
                                self.m_bonusGameReel:removeFromParent()
                                self.m_bonusGameReel = nil
                                if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
                                    self.m_SuperCollectBar:setBotTouch(true)
                                end
                                if self.m_WinCoins and #self.m_WinCoins > 0 then
                                    for i, v in ipairs(self.m_WinCoins) do
                                        v:removeFromParent()
                                    end
                                    self.m_WinCoins = nil
                                end
                            end
                            self:runCsbAction(
                                "FadeIn",
                                false,
                                function()
                                    self:findChild("NormalReel"):setVisible(true)
                                end
                            )

                            self:resetMusicBg(true)
                            if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
                                -- self:playGameEffect()
                                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                                self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
                                self:triggerFreeSpinCallFun()
                                self:changeNormalAndFreespinReel(1)
                                self.m_baseFreeSpinBar:setVisible(true)
                                self.m_SuperCollectBar:setVisible(false)
                            else
                                self.m_bonusOverAndFreeSpinOver = true
                                if self.m_runSpinResultData.p_freeSpinsTotalCount <= 0 then
                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                                end
                                self:changeNormalAndFreespinReel(0)
                                self.m_baseFreeSpinBar:setVisible(false)
                                self.m_SuperCollectBar:setVisible(true)
                            end
                        end,
                        0.8,
                        self:getModuleName()
                    )
                end
            )
            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node, sx = 1, sy = 1}, 661)
            return view
        end,
        1
    )
end

--重置bonus掉落轮盘
function CodeGameScreenJungleKingpinMachine:resetReelMap()
    for i = 1, 3 do
        self.m_bonusReels[i]:resetReelMap()
    end
end

function CodeGameScreenJungleKingpinMachine:beginReel()
    if self.m_bBonusGame == true then
        if self.m_bonusGameReel ~= nil then
            if self.m_WinCoins and #self.m_WinCoins > 0 then
                for i, v in ipairs(self.m_WinCoins) do
                    v:removeFromParent()
                end
                self.m_WinCoins = nil
            end
            self.m_bonusGameReel:beginMiniReel()
        end
    else
        BaseSlotoManiaMachine.beginReel(self)
        self.m_SuperCollectBar:setBotTouch(false)
    end
end

function CodeGameScreenJungleKingpinMachine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenJungleKingpinMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self.m_topUI:updataPiggy(betCoin)
        if self.m_bBonusGame == true then
            isFreeSpin = false
        end
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_SPIN_PROGRESS, data = self.m_collectDataList, jackpot = self.m_jackpotList, betLevel = self:getBetLevel()}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

----
--- 处理spin 成功消息
--
function CodeGameScreenJungleKingpinMachine:checkOperaSpinSuccess(param)
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or spinData.action == "FEATURE" then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)

        self:operaUserInfoWithSpinResult(param)

        -- self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")

        local resultData = spinData.result
        if self.m_bonusGameReel ~= nil and resultData and resultData.action == "BONUS" then
            --设置主轮盘数据  防止阻塞
            self.m_isWaitingNetworkData = false
            self:setGameSpinStage(GAME_MODE_ONE_RUN)
            --设置副轮盘 数据
            local resultData = spinData.result.selfData.bonusReel
            self.m_BonusWinCoins = spinData.result.bonus.bsWinCoins
            resultData.bet = 1
            self.m_bonusGameReel:setBonusLeftTimes(spinData.result.selfData.bonusLeftCount)
            self.m_bonusGameReel:netWorkCallFun(resultData)
            if
                spinData.result.freespin.freeSpinsTotalCount == 0 or
                    (spinData.result.freespin.freeSpinsTotalCount > 0 and spinData.result.freespin.freeSpinsLeftCount == spinData.result.freespin.freeSpinsTotalCount)
             then
                self:setLastWinCoin(self.m_runSpinResultData.p_bonusWinCoins)
            end
        else
            self:updateNetWorkData()
        end
    end
end

---
-- 处理spin 返回结果
function CodeGameScreenJungleKingpinMachine:spinResultCallFun(param)
    self.m_iFixSymbolNum = 0
    self.m_bFlagRespinNumChange = false
    self.m_vecExpressSound = {false, false, false, false, false}
    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = 2

    self:checkTestConfigType(param)

    local isOpera = self:checkOpearReSpinAndSpecialReels(param) -- 处理respin逻辑
    if isOpera == true then
        return
    end

    if param[1] == true then -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else -- 处理spin失败
        self:checkOpearSpinFaild(param)
    end
end

function CodeGameScreenJungleKingpinMachine:playEffectNotifyNextSpinCall()
    if self.m_bonusGameReel ~= nil then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenJungleKingpinMachine:setNormalAllRunDown()
    if self.m_runSpinResultData.p_selfMakeData.bonusLeftCount ~= nil and self.m_runSpinResultData.p_selfMakeData.bonusLeftCount == 0 then
    else
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)
    end

    self:setGameSpinStage(STOP_RUN)
end

function CodeGameScreenJungleKingpinMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue then
        -- 关卡特殊处理 不显示scatter赢钱线动画
        if lineValue.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            print("scatter")
        else
            BaseMachineGameEffect.showLineFrameByIndex(self, winLines, frameIndex)
        end
    end
end

function CodeGameScreenJungleKingpinMachine:callSpinBtn()

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_startSpinTime = nil
        end
    end

    
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToAutospinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToAutospinReelRunLen()
            end
        end
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE  then
        for i = 1, #self.m_reelRunInfo do
            if self.m_reelRunInfo[i].setReelRunLenToFreespinReelRunLen then
                self.m_reelRunInfo[i]:setReelRunLenToFreespinReelRunLen()
            end
        end
    end


    -- 去除掉 ， auto和 freespin的倒计时监听
    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end
    if self.m_bBonusGame == false then
        self:notifyClearBottomWinCoin()
    end

    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= SPECIAL_SPIN_MODE and betCoin > totalCoin then
        --金币不足
        -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
        gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NoCoins)
        end
        -- cxc 2023-12-05 15:57:06 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
        local checkOperaGuidePop = function()
            if tolua.isnull(self) then
                return
            end
            
            local betCoin = self:getSpinCostCoins() or toLongNumber(0)
            local totalCoin = globalData.userRunData.coinNum or 1
            if betCoin <= totalCoin then
                globalData.rateUsData:resetBankruptcyNoPayCount()
                self:showLuckyVedio()
                return
            end

            -- cxc 2023年12月02日13:57:48 没钱弹板逻辑后发现 用户没有付费(拿金币看下还是不足就行了)， 监测弹运营引导弹板
            globalData.rateUsData:addBankruptcyNoPayCount()
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Bankruptcy", "BankruptcyNoPay_" .. globalData.rateUsData:getBankruptcyNoPayCount())
            if view then
                view:setOverFunc(util_node_handler(self, self.showLuckyVedio))
            else
                self:showLuckyVedio()
            end
        end
        gLobalPushViewControl:setEndCallBack(checkOperaGuidePop)
        
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        end
    else
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= SPECIAL_SPIN_MODE then
            self:callSpinTakeOffBetCoin(betCoin)
        else
            self.m_spinNextLevel = globalData.userRunData.levelNum
            self.m_spinNextProVal = globalData.userRunData.currLevelExper
            self.m_spinIsUpgrade = false
        end

        --统计quest spin次数
        self:staticsQuestSpinData()

        self:spinBtnEnProc()

        self:setGameSpinStage(GAME_MODE_ONE_RUN)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        globalData.userRate:pushSpinCount(1)
        globalData.userRate:pushUsedCoins(betCoin)
        globalData.rateUsData:addSpinCount()
    end
    -- 修改freespin count 的信息
    self:checkChangeFsCount()

    -- 修改 respin count 的信息
    self:checkChangeReSpinCount()
end

local SYMBOL_BIG_WILD = 201
local SYMBOL_BIG_WILD_GOLD = 202
--显示香蕉掉落效果
function CodeGameScreenJungleKingpinMachine:playDropBananaEffect(_bonusResult, func)
    local isGlodWild = false --是否有金色bonus
    local playGoldReelNum = 0 --轮流停止次数
    self.m_iPlayGoldReelNum = 0 --停止个数

    self.m_vecJackpot = {} --存储赢的jackpot 可能同时几个
    for i, v in ipairs(_bonusResult) do
        if v.type >= BONUS_TYPE.BONUS_MINOR_TYPE then
            self.m_vecJackpot[#self.m_vecJackpot + 1] = {_type = v.type, _amount = v.amount}
        end
    end

    local function playChooseWinSymbolCallBack()
        self.m_iPlayGoldReelNum = self.m_iPlayGoldReelNum + 1
        --判断是否都停止
        if self.m_iPlayGoldReelNum == playGoldReelNum then
            for i, v in ipairs(_bonusResult) do
                if v.type > 0 then
                    self:createDropNodeByType(i, v.id, v.type, v.amount)
                end
            end
            if self.m_vecJackpot and #self.m_vecJackpot > 0 then
                self.m_iJackpotIndex = 1
                self:playShowJackpot(func, 2.1)
            else
                scheduler.performWithDelayGlobal(
                    function()
                        if func then
                            func()
                        end
                    end,
                    3,
                    self:getModuleName()
                )
            end
        end
    end
    for i, v in ipairs(_bonusResult) do
        if v.type > 0 then
            local winType = self.m_bonusGameReel:getBigWildType(i)
            if winType == SYMBOL_BIG_WILD_GOLD then
                isGlodWild = true
                --金色bonus  播放流光选择动画 停止后掉落
                self:playChooseWinSymbolEffect(
                    i,
                    v.id,
                    v.type,
                    function()
                        playChooseWinSymbolCallBack()
                    end
                )
                playGoldReelNum = playGoldReelNum + 1
            end
        end
    end
    --普通bonus 直接掉落
    if isGlodWild == false then
        for i, v in ipairs(_bonusResult) do
            if v.type > 0 then
                self:createDropNodeByType(i, v.id, v.type, v.amount)
            end
        end
        if self.m_vecJackpot and #self.m_vecJackpot > 0 then
            self.m_iJackpotIndex = 1
            self:playShowJackpot(func, 2.1)
        else
            scheduler.performWithDelayGlobal(
                function()
                    if func then
                        func()
                    end
                end,
                3,
                self:getModuleName()
            )
        end
    end
end

--显示jackpot
function CodeGameScreenJungleKingpinMachine:playShowJackpot(func, delayTime)
    if self.m_vecJackpot and self.m_iJackpotIndex and #self.m_vecJackpot > 0 then
        local jackpotInfo = self.m_vecJackpot[self.m_iJackpotIndex]
        self:ShowJackPotView(jackpotInfo, func, delayTime)
    end
end

--jackpot 数据处理
function CodeGameScreenJungleKingpinMachine:ShowJackPotView(_info, func, delayTime)
    local jackpotScore = _info._amount
    local jackpotType = _info._type

    performWithDelay(
        self,
        function()
            self:clearCurMusicBg()
            self:showJackpotWin(
                jackpotType,
                jackpotScore,
                function()
                    -- local lastWinCoin = globalData.slotRunData.lastWinCoin
                    -- globalData.slotRunData.lastWinCoin = 0
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {jackpotScore, false, false})
                    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum) -- 立即更改金币数量
                    -- globalData.slotRunData.lastWinCoin = lastWinCoin

                    if self.m_bBonusGame then
                        self.m_currentMusicBgName = "JungleKingpinSounds/music_JungleKingpin_BonusBg.mp3"
                        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
                    else
                        self:resetMusicBg(true)
                    end

                    if self.m_iJackpotIndex >= #self.m_vecJackpot then
                        if func then
                            func()
                        end
                    else
                        self.m_iJackpotIndex = self.m_iJackpotIndex + 1
                        self:playShowJackpot(func, 1.2)
                    end
                end
            )
        end,
        delayTime
    )
end

function CodeGameScreenJungleKingpinMachine:showJackpotWin(index, coins, func)
    local jackPotWinView = util_createView("CodeJungleKingpinSrc.JungleKingpinJackPotWinView")
    jackPotWinView:initViewData(self, index, coins, func)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(jackPotWinView, ViewZorder.ZORDER_UI)
end

--播放流光
function CodeGameScreenJungleKingpinMachine:playChooseWinSymbolEffect(_index, _id, _type, _func)
    self.m_bonusReels[_index]:setWinSymbol(_id, _type, _func)
end

--掉落
function CodeGameScreenJungleKingpinMachine:createDropNodeByType(_index, _id, _type, _coins)
    local startPos = self.m_bonusReels[_index]:getMoveStartPos(_id)
    local MoveNode = nil

    if _type == BONUS_TYPE.BONUS_NORMAL_TYPE then
        MoveNode = util_createView("CodeJungleKingpinSrc.JungleKingpinCoins")
        MoveNode:runCsbAction("animation0")
        gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_win_banana.mp3")
    else
        MoveNode = util_createView("CodeJungleKingpinSrc.JungleKingpinBanana", _type)
        MoveNode:showBananaType()
        if _type == BONUS_TYPE.BONUS_MINI_TYPE then
            MoveNode:changeBonusNum(self:getBonusMinNum())
        elseif _type == BONUS_TYPE.BONUS_MAX_TYPE then
            MoveNode:changeBonusNum(self:getBonusMaxNum())
        end

        if _type >= BONUS_TYPE.BONUS_MINOR_TYPE then
            gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_win2.mp3")
        else
            gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_win_banana.mp3")
        end

        MoveNode:runCsbAction("animation1")
    end
    self:addChild(MoveNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    MoveNode:setPosition(startPos)
    local endPos = self.m_bonusGameReel:getMoveEndPos(_index)
    --隐藏
    self.m_bonusReels[_index]:setReelNodeVisibleByID(_id)
    --移动
    scheduler.performWithDelayGlobal(
        function()
            self.m_bonusReels[_index]:bonusReelMoveDown(_id, _type)
        end,
        0.7,
        self:getModuleName()
    )
    local dealy = cc.DelayTime:create(0.5)
    local moveTo = cc.MoveTo:create(0.4, endPos)
    local FadeOut = cc.FadeOut:create(0.1)
    local fun =
        cc.CallFunc:create(
        function()
            MoveNode:removeFromParent()
            --移除
            self.m_bonusReels[_index]:removeReelNodeByID(_id)
            if self.m_bonusGameFlag == false then
                local isNotifyUpdateTop = false
                self.m_bonusGameFlag = true
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_winAmount, isNotifyUpdateTop})
            end
        end
    )
    local root = self.m_machineNode:getChildByName("root")
    if root then
        local scale = root:getScale()
        MoveNode:setScale(scale)
    end

    MoveNode:runAction(cc.Sequence:create(dealy, moveTo, FadeOut, fun))
    scheduler.performWithDelayGlobal(
        function()
            if self.m_eatId == nil then
                self.m_eatId = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_wild_eat.mp3", false)
                performWithDelay(
                    self,
                    function()
                        self.m_eatId = nil
                    end,
                    1
                )
            end
            self.m_bonusGameReel:showEatAnimal(_index)
            scheduler.performWithDelayGlobal(
                function()
                    --显示金币数值
                    if _type == BONUS_TYPE.BONUS_NORMAL_TYPE or _type == BONUS_TYPE.BONUS_MINI_TYPE or _type == BONUS_TYPE.BONUS_MAX_TYPE then
                        local pos = self.m_bonusGameReel:getEatCoinsPos(_index)
                        if self.m_WinCoins == nil then
                            self.m_WinCoins = {}
                        end
                        local coins = util_createAnimation("JungleKingpin_CoinsNum.csb")
                        local label = coins:findChild("BitmapFontLabel_1")
                        label:setString(util_formatCoins(_coins, 3))
                        coins:playAction("animation0")
                        table.insert(self.m_WinCoins, label)
                        self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                        coins:setPosition(pos)
                    end
                end,
                0.6,
                self:getModuleName()
            )
        end,
        0.7,
        self:getModuleName()
    )
end

--获取奖励数值
function CodeGameScreenJungleKingpinMachine:getBonusMaxNum()
    local totalBet = self.m_currBet or globalData.slotRunData:getCurTotalBet()
    local bonus_max = totalBet / 150 * 2000
    return bonus_max
end

function CodeGameScreenJungleKingpinMachine:getBonusMinNum()
    local totalBet = self.m_currBet or globalData.slotRunData:getCurTotalBet() 
    local bonus_min = totalBet / 150 * 1000
    return bonus_min
end

function CodeGameScreenJungleKingpinMachine:setCurrBet(_currBet)
    if not _currBet or  _currBet == 0 then
        self.m_currBet = nil
    else
        self.m_currBet = _currBet
    end
end

--移除scatter 连线
function CodeGameScreenJungleKingpinMachine:showLineFrame()
    if self.m_reelResultLines and type(self.m_reelResultLines) == "table" then
        local scatterLineValue = nil
        for i = #self.m_reelResultLines, 1, -1 do
            local lineData = self.m_reelResultLines[i]
            if lineData then
                if lineData.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    table.remove(self.m_reelResultLines, i)
                end
            end
        end
    end

    BaseMachineGameEffect.showLineFrame(self)
end

function CodeGameScreenJungleKingpinMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 or self:getCurrSpinMode() == SPECIAL_SPIN_MODE then
        isNotifyUpdateTop = false
    end
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) then
        isNotifyUpdateTop = false
    end

    self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin - self.m_fisrtLinesWinCoin
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenJungleKingpinMachine:normalSpinBtnCall()
    BaseSlotoManiaMachine.normalSpinBtnCall(self)
    if self.m_tip1:isVisible() then
        self.m_tip1:HideTip()
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
end

function CodeGameScreenJungleKingpinMachine:slotReelDown()
    BaseMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

return CodeGameScreenJungleKingpinMachine
