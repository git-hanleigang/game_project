---
-- island li
-- 2019年1月26日
-- CodeGameScreenLuckyDollarMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenLuckyDollarMachine = class("CodeGameScreenLuckyDollarMachine", BaseNewReelMachine)

CodeGameScreenLuckyDollarMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_9_2 = 108
CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_8_2 = 107
CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_7_2 = 106
CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_6_2 = 105
CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_5_2 = 104
CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_4_2 = 103
CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_3_2 = 102
CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_2_2 = 101
CodeGameScreenLuckyDollarMachine.SYMBOL_SCORE_1_2 = 100

CodeGameScreenLuckyDollarMachine.SYMBOL_SCATTER_2 = 190
CodeGameScreenLuckyDollarMachine.SYMBOL_BONUS_1 = 94
CodeGameScreenLuckyDollarMachine.SYMBOL_BONUS_2 = 194
CodeGameScreenLuckyDollarMachine.SYMBOL_WILD_2 = 192

CodeGameScreenLuckyDollarMachine.m_playAnimIndex = 0

local FIT_HEIGHT_MAX = 1300
local FIT_HEIGHT_MIN = 1136
-- 构造函数
function CodeGameScreenLuckyDollarMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_playAnimIndex = 0
    self.m_bInBonus = false
    self.m_symbolFrameList = {}
    self.m_scatterLineValue = nil
    self.m_bonusLineValue = nil
    self.m_bonusWin = false
    self.m_isFeatureOverBigWinInFree = true
    
    self:initGame()
end

function CodeGameScreenLuckyDollarMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("LuckyDollarConfig.csv", "LevelLuckyDollarConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function CodeGameScreenLuckyDollarMachine:initUI()
    self:initFreeSpinBar()
    self.m_BonusBg = util_createAnimation("LuckyDollar_jiqi.csb")
    self:findChild("jiqi"):addChild(self.m_BonusBg)
    self.m_BonusBg:runCsbAction("idle2", true)
    self.m_logo1 = util_createAnimation("LuckyDollar_logo_1.csb")
    self:findChild("Node_Logo"):addChild(self.m_logo1)
    self.m_logo1:runCsbAction("idle")
    self.m_logo2 = util_createAnimation("LuckyDollar_logo_2.csb")
    self:findChild("Node_Logo_2"):addChild(self.m_logo2)

    self.m_tips = util_createAnimation("LuckyDollar_shuoming.csb")
    self:findChild("shuoming"):addChild(self.m_tips)
    self.m_tips:runCsbAction("idle", true)

    self.m_bonusView = util_createView("CodeLuckyDollarSrc.LuckyDollarBonusView")
    self:findChild("bonus"):addChild(self.m_bonusView)
    self.m_bonusView:initMachine(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin  then
                local winCoin = params[1]
                local totalBet = globalData.slotRunData:getCurTotalBet()
                local winRate = winCoin / totalBet
                if winRate > 1 then
                    self.m_logo1:runCsbAction("start2", true)
                end
                return
            end
            if self.m_bonusWin then
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
            elseif winRate > 3 then
                soundIndex = 3
            end

            if winRate > 1 then
                self.m_logo1:runCsbAction("start2", true)
            end

            local soundName = "LuckyDollarSounds/sound_LuckyDollar_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, 3, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenLuckyDollarMachine:initFreeSpinBar()
    local node_bar = self.m_bottomUI:findChild("node_bar")
    self.m_baseFreeSpinBar = util_createView("Levels.FreeSpinBar")
    node_bar:addChild(self.m_baseFreeSpinBar)
    local pos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,node_bar)
    self.m_baseFreeSpinBar:setPosition(cc.p(pos.x,73))
    self.m_baseFreeSpinBar:setScale(0.8)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenLuckyDollarMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:changeFreeSpinByCount()
end
--小块
function CodeGameScreenLuckyDollarMachine:getBaseReelGridNode()
    return "CodeLuckyDollarSrc.LuckyDollarSlotsNode"
end

-- 断线重连
function CodeGameScreenLuckyDollarMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        end
    elseif self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self:triggerFreeSpinCallFun()
        self:runCsbAction("freespin")
    end

    if self:isTriggerBonusGame() then
        self.m_bInBonus = true
        if self.m_bonusStartView == nil then
            self.m_bonusStartView = self:showBonusStart()
            self.m_bonusStartView:playStart(true)
        end
        self:setAllNodeDark()
        self.m_logo1:runCsbAction("idle2", false)
        self.m_tips:setVisible(false)
        globalData.slotRunData.currSpinMode = SPECIAL_SPIN_MODE
        if not self.m_lianzi then
            self.m_lianzi = util_spineCreate("Luckdollarlian", true, true)
            self:findChild("lianziNode"):addChild(self.m_lianzi)
            util_spinePlay(self.m_lianzi, "idle", true)
        end
        self:clearCurMusicBg()
        self:playBonusGameBgm()
        self.m_bonusView:initReconnectView()
    end
end

---
-- 进入关卡
--
function CodeGameScreenLuckyDollarMachine:enterLevel()
    BaseNewReelMachine.enterLevel(self)
    if self.m_bInBonus == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    end
end

function CodeGameScreenLuckyDollarMachine:isTriggerBonusGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData.leftTimes and selfData.leftTimes > 0 then
        return true
    end
    return false
end

function CodeGameScreenLuckyDollarMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)
    self.m_gameBg = gameBg
end

function CodeGameScreenLuckyDollarMachine:scaleMainLayer()
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
        end

        if display.height >= FIT_HEIGHT_MIN and display.height < FIT_HEIGHT_MAX then
            local pro = display.height / display.width
            if pro < 1.8 then
                mainScale = mainScale + 0.05
            end
        end

        local ratio = display.height / display.width
        if ratio == 1024 / 768 then
            mainScale = 0.78
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
        elseif ratio == 960 / 640 then
            mainScale = 0.83
        end
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

function CodeGameScreenLuckyDollarMachine:changeViewNodePos()
    if display.height >= FIT_HEIGHT_MAX then
        local pro = display.height / display.width
        if pro < 1.8 and pro > 1.6 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 50)
        elseif pro >= 1.8 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 20)
        end
    elseif display.height >= FIT_HEIGHT_MIN and display.height < FIT_HEIGHT_MAX then
        local pro = display.height / display.width
        if pro < 1.8 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 50)
        elseif pro >= 1.8 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 20)
        end
    end
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenLuckyDollarMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LuckyDollar"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenLuckyDollarMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_9_2 then
        return "Socre_LuckyDollar_1_2"
    elseif symbolType == self.SYMBOL_SCORE_8_2 then
        return "Socre_LuckyDollar_2_2"
    elseif symbolType == self.SYMBOL_SCORE_7_2 then
        return "Socre_LuckyDollar_3_2"
    elseif symbolType == self.SYMBOL_SCORE_6_2 then
        return "Socre_LuckyDollar_4_2"
    elseif symbolType == self.SYMBOL_SCORE_5_2 then
        return "Socre_LuckyDollar_5_2"
    elseif symbolType == self.SYMBOL_SCORE_4_2 then
        return "Socre_LuckyDollar_6_2"
    elseif symbolType == self.SYMBOL_SCORE_3_2 then
        return "Socre_LuckyDollar_7_2"
    elseif symbolType == self.SYMBOL_SCORE_2_2 then
        return "Socre_LuckyDollar_8_2"
    elseif symbolType == self.SYMBOL_SCORE_1_2 then
        return "Socre_LuckyDollar_9_2"
    elseif symbolType == self.SYMBOL_SCATTER_2 then
        return "Socre_LuckyDollar_Scatter_2"
    elseif symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_LuckyDollar_Bonus"
    elseif symbolType == self.SYMBOL_WILD_2 then
        return "Socre_LuckyDollar_Wild"
    elseif symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_LuckyDollar_Bonus_2"
    end

    return nil
end

--本列停止 判断下列是否有长滚
function CodeGameScreenLuckyDollarMachine:getNextReelIsLongRun(reelCol)
    return false
end

-- 每个reel条滚动到底
function CodeGameScreenLuckyDollarMachine:slotOneReelDown(reelCol)
    BaseNewReelMachine.slotOneReelDown(self, reelCol)
    if reelCol == 1 or reelCol == 3 or reelCol == 5 then
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            if targSp.p_symbolType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 and targSp.p_symbolType <= TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 then
                if self:checkIsLinesHaveSymbol(reelCol, iRow) then
                    self:addSymbolFrameToClipReel(reelCol, iRow, targSp.p_symbolType)
                end
            end
        end
    end
end

function CodeGameScreenLuckyDollarMachine:addSymbolFrameToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        local csb = util_createAnimation("Socre_LuckyDollar_kuang.csb")
        self.m_clipParent:addChild(csb, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + showOrder)
        csb:setPosition(cc.p(pos.x, pos.y))
        csb:runCsbAction("start02")
        table.insert(self.m_symbolFrameList, csb)
    end
end

--中奖线 上是否有信号
function CodeGameScreenLuckyDollarMachine:checkIsLinesHaveSymbol(_col, _row)
    --接下来判断连线上是否有信号
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
                        local fixPos = self:getRowAndColByPos(pos)
                        if _col == fixPos.iY and _row == fixPos.iX then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end
-- 显示free spin
function CodeGameScreenLuckyDollarMachine:showEffect_FreeSpin(effectData)
    local lineLen = #self.m_reelResultLines
    if self.m_scatterLineValue == nil then
        for i = 1, lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                self.m_scatterLineValue = lineValue
                table.remove(self.m_reelResultLines, i)
                break
            end
        end
    end
    self:setNotInLinesNodeDarkOrHight(true)
    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    if self.m_scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            self.m_scatterLineValue,
            function()
                self:showFreeSpinView(effectData)
            end
        )
        self.m_scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = self.m_scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

-- 触发freespin时调用
function CodeGameScreenLuckyDollarMachine:showFreeSpinView(effectData)
    local showFreeSpinView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinStart(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    self:resetMusicBg(true)
                end
            )
        else
            self:setNotInLinesNodeDarkOrHight(false)
            self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self.m_BonusBg:runCsbAction("idle", true)
                    self:triggerFreeSpinCallFun()
                    self:runCsbAction("freespin")
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_freespin_start.mp3")
            showFreeSpinView()
        end,
        15 / 30
    )
end

function CodeGameScreenLuckyDollarMachine:showFreeSpinStart(_num, func)
    local view = util_createView("CodeLuckyDollarSrc.LuckyDollarFreeSpinStart", {freespinCounts = _num})
    view:setFunCall(func)
    self:findChild("tb"):addChild(view)
    -- if globalData.slotRunData.machineData.p_portraitFlag then
    --     view.getRotateBackScaleFlag = function()
    --         return false
    --     end
    -- end
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI, {node = view})
    return view
end

--添加到 轮盘节点上 适配
function CodeGameScreenLuckyDollarMachine:showLuckyDollarDialog(ccbName, ownerlist, func, isAuto, index)
    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self, ccbName, func, isAuto, index)
    view:updateOwnerVar(ownerlist)
    self:findChild("tb"):addChild(view)
    return view
end

-- 触发freespin结束时调用
function CodeGameScreenLuckyDollarMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_freespin_over.mp3")
    self:runCsbAction("base")
    self.m_logo1:runCsbAction("start2", true)
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 20)
    self:hideFreeSpinBar()
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self.m_BonusBg:runCsbAction("idle2", true)
            self.m_logo1:runCsbAction("idle", false)
            -- 调用此函数才是把当前游戏置为freespin结束状态
            self:triggerFreeSpinOverCallFun()
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.93, sy = 0.93}, 645)
end

function CodeGameScreenLuckyDollarMachine:showFreeSpinOver(coins, num, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view = self:showLuckyDollarDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    -- if globalData.slotRunData.machineData.p_portraitFlag then
    --     view.getRotateBackScaleFlag = function()
    --         return false
    --     end
    -- end
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI, {node = view})
    return view
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenLuckyDollarMachine:showEffect_Bonus(effectData)
    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    -- -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    if self.m_bonusLineValue == nil then
        for i = 1, lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                self.m_bonusLineValue = lineValue
                table.remove(self.m_reelResultLines, i)
                break
            end
        end
    end
    self:setNotInLinesNodeDarkOrHight(true)
    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 播放bonus 元素不显示连线
    if self.m_bonusLineValue ~= nil then
        self:showBonusAndScatterLineTip(
            self.m_bonusLineValue,
            function()
                self:showBonusGameView(effectData)
            end
        )
        self.m_bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = self.m_bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenLuckyDollarMachine:showBonusTransition(funcEnd)
    if not self.m_lianzi then
        self.m_lianzi = util_spineCreate("Luckdollarlian", true, true)
        self:findChild("lianziNode"):addChild(self.m_lianzi)
        util_spinePlay(self.m_lianzi, "start", false)
        -- 动画结束
        util_spineEndCallFunc(
            self.m_lianzi,
            "start",
            function()
                util_spinePlay(self.m_lianzi, "idle", true)
                if funcEnd then
                    funcEnd()
                end
            end
        )
    end
end

function CodeGameScreenLuckyDollarMachine:showBonusGameView(effectData)
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_start.mp3")
            gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_start_tip.mp3")
            self:showBonusTransition()
            if self.m_bProduceSlots_InFreeSpin == true then
                self:hideFreeSpinBar()
            end
            if self.m_bonusStartView == nil then
                self.m_bonusStartView =
                    self:showBonusStart(
                    function()
                        globalData.slotRunData.currSpinMode = SPECIAL_SPIN_MODE
                        self.m_effectData = effectData
                    end
                )
                self.m_bonusStartView:playStart(false)
            -- self:setAllNodeDark()
            end
            -- self:setNotInLinesNodeDarkOrHight(false)
            self.m_bonusView:showBonusBtnPage()
            self.m_tips:setVisible(false)
            self.m_logo1:runCsbAction(
                "start",
                false,
                function()
                    self.m_logo1:runCsbAction("idle2", false)
                end
            )
            scheduler.performWithDelayGlobal(
                function()
                    self.m_bonusView:setBonusViewDark()
                    self:playBonusGameBgm()
                    self.m_bInBonus = true
                    self:showBonusBgAction()
                    self.m_bonusView:playBonusStart()
                end,
                94 / 30,
                self:getModuleName()
            )
        end,
        15 / 30
    )
end

function CodeGameScreenLuckyDollarMachine:playBonusGameBgm()
    self.m_currentMusicBgName = "LuckyDollarSounds/sound_LuckyDollar_bonus_bgm.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

function CodeGameScreenLuckyDollarMachine:showBonusBgAction()
    gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_up.mp3")
    gLobalSoundManager:setBackgroundMusicVolume(0.4)
    self.m_BonusBg:runCsbAction(
        "start",
        false,
        function()
            self.m_BonusBg:runCsbAction("idle", true)
        end
    )
end
function CodeGameScreenLuckyDollarMachine:playBonusOverEffect(funcEnd)
    if self.m_lianzi then
        util_spinePlay(self.m_lianzi, "over", false)
        -- 动画结束
        util_spineEndCallFunc(
            self.m_lianzi,
            "over",
            function()
                if funcEnd then
                    funcEnd()
                end
            end
        )
        scheduler.performWithDelayGlobal(
            function()
                self.m_lianzi:removeFromParent()
                self.m_lianzi = nil
            end,
            60 / 30,
            self:getModuleName()
        )
    end
end

function CodeGameScreenLuckyDollarMachine:showBonusOver(winCoins)
    self.m_BonusBg:runCsbAction("idleframe", true)
    if self.m_bProduceSlots_InFreeSpin == true then
        self:hideFreeSpinBar()
    end
    if self.m_bonusStartView then
        self.m_bonusStartView:runCsbAction(
            "over",
            false,
            function()
                self.m_bonusStartView:removeFromParent()
                self.m_bonusStartView = nil
                self:clearCurMusicBg()
                self.m_bonusWin = true
                gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_over.mp3")
                local totalBet = globalData.slotRunData:getCurTotalBet()
                local winRate = winCoins / totalBet
                if winRate >= 20 then
                    gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_win_2.mp3")
                else
                    gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_bonus_win_1.mp3")
                end
                self.m_logo1:runCsbAction("start2", true)
                local view = util_createView("CodeLuckyDollarSrc.LuckyDollarBonusOver", winCoins)
                winCoins = globalData.slotRunData.lastWinCoin + winCoins
                local beginCoins = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {winCoins, true, true, beginCoins})
                globalData.slotRunData.lastWinCoin = winCoins
                view:setFunCall(
                    function()
                        self.m_bInBonus = false
                        self.m_tips:setVisible(true)
                        if self.m_bProduceSlots_InFreeSpin == true then
                            globalData.slotRunData.currSpinMode = FREE_SPIN_MODE
                            self.m_BonusBg:runCsbAction("idle", true)
                            self:showFreeSpinBar()
                        else
                            globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
                            self.m_BonusBg:runCsbAction("idle2", true)
                        end

                        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                            if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                                local effectData = GameEffectData.new()
                                effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
                                self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                                self.m_bottomUI:checkClearWinLabel()
                            elseif self.m_runSpinResultData.p_freeSpinNewCount > 0 then
                                local effectData = GameEffectData.new()
                                effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
                                self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                            end
                        end

                        self:resetMusicBg(true)
                        self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)
                        self.m_logo1:runCsbAction("idle", false)
                        self.m_bonusView:playBonusOver()
                        if self.m_effectData then
                            self.m_effectData.p_isPlay = true
                        end
                        self:playGameEffect()
                    end,
                    function()
                        self:playBonusOverEffect()
                    end
                )
                self:findChild("tb"):addChild(view)
                -- if globalData.slotRunData.machineData.p_portraitFlag then
                --     view.getRotateBackScaleFlag = function()
                --         return false
                --     end
                -- end
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI, {node = view})
            end
        )
    end
end

function CodeGameScreenLuckyDollarMachine:showBonusStart(func)
    local view = util_createView("CodeLuckyDollarSrc.LuckyDollarBonusStart")
    view:setFunCall(func)
    self:findChild("tb"):addChild(view)
    -- if globalData.slotRunData.machineData.p_portraitFlag then
    --     view.getRotateBackScaleFlag = function()
    --         return false
    --     end
    -- end
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI, {node = view})
    return view
end
---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenLuckyDollarMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_logo1:runCsbAction("idle", false)
    self.m_scatterLineValue = nil
    self.m_bonusLineValue = nil
    self.m_bonusWin = false
    return false -- 用作延时点击spin调用
end

function CodeGameScreenLuckyDollarMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("LuckyDollarSounds/sound_LuckyDollar_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.m_bInBonus then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    else
                        self:playBonusGameBgm()
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

function CodeGameScreenLuckyDollarMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) -- 必须调用不许删除
    self:addObservers()
end

function CodeGameScreenLuckyDollarMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
end

function CodeGameScreenLuckyDollarMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenLuckyDollarMachine:addSelfEffect()
    -- 自定义动画创建方式
    -- local selfEffect = GameEffectData.new()
    -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenLuckyDollarMachine:MachineRule_playSelfEffect(effectData)
    -- if effectData.p_selfEffectType == self.QUICKHIT_JACKPOT_EFFECT then
    --
    -- end
    return true
end
function CodeGameScreenLuckyDollarMachine:slotReelDown()
    BaseNewReelMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenLuckyDollarMachine:playEffectNotifyNextSpinCall()
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenLuckyDollarMachine:setAllSoltsNodeShow()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow)
            if node then
                node:setVisible(true)
            end
        end
    end
end

function CodeGameScreenLuckyDollarMachine:beginReel()
    self:setAllSoltsNodeShow()
    BaseNewReelMachine.beginReel(self)
end

function CodeGameScreenLuckyDollarMachine:updateReelGridNode(node)
    local isLastSymbol = node.m_isLastSymbol
    if isLastSymbol == true and self:getCurrSpinMode() == FREE_SPIN_MODE then
        local symbolType = node.p_symbolType
        local row = node.p_rowIndex
        local col = node.p_cloumnIndex
        local reelsIndex = self:getPosReelIdx(row, col)
        local isHave, num = self:getMulNum(reelsIndex)
        local labNode = node:getCcbProperty("xbei")
        if labNode then
            labNode:removeAllChildren()
        end
        local totallabNode = node:getCcbProperty("xbei_0")
        if totallabNode then
            totallabNode:removeAllChildren()
        end
        if node and isHave then
            node:runAnim("idleframe")
            -- print("第   " .. reelsIndex .. "个格子=========倍数 ====" .. num)
            local labNode = node:getCcbProperty("xbei")
            if labNode then
                local lab = self:createMulCsb(num)
                if num >= 10 then
                    lab:setScale(0.6)
                    lab:setPositionX(-15)
                end
                labNode:addChild(lab)
            end
        end
        local isShow, totalnum = self:getTotalMulNum(reelsIndex)
        if node and isShow then
            node:runAnim("idleframe")
            node:setFreeSpinWin(true)
            -- print("第   " .. reelsIndex .. "个格子===========总倍数 ====" .. totalnum)
            totallabNode = node:getCcbProperty("xbei_0")
            if totallabNode and totalnum > 1 then
                local lab = self:createMulCsb(totalnum)
                totallabNode:addChild(lab)
            end
        end
    end
end

function CodeGameScreenLuckyDollarMachine:createMulCsb(num)
    local csb = util_createAnimation("Socre_LuckyDollar_xbei.csb")
    local lab = csb:findChild("m_lb_num")
    lab:setString(tostring(num))
    return csb
end

function CodeGameScreenLuckyDollarMachine:getMulNum(reelsIndex)
    local isHave = false
    local Num = 1
    local mulPos = self.m_runSpinResultData.p_selfMakeData.multiples
    if mulPos and type(mulPos) == "table" then
        if mulPos then
            for k, v in pairs(mulPos) do
                local index = tonumber(k)
                if reelsIndex == index then
                    isHave = true
                    Num = tonumber(v)
                    break
                end
            end
        end
    end

    return isHave, Num
end

function CodeGameScreenLuckyDollarMachine:getTotalMulNum(reelsIndex)
    local isHave = false
    local Num = 1
    local mulPos = self.m_runSpinResultData.p_selfMakeData.twinMultiples
    if mulPos and type(mulPos) == "table" then
        if mulPos then
            for k, v in pairs(mulPos) do
                local index = tonumber(k)
                if reelsIndex == index then
                    Num = tonumber(v)
                    isHave = true
                    break
                end
            end
        end
    end

    return isHave, Num
end

function CodeGameScreenLuckyDollarMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    if self:isTriggerFreeSpinOrBonus() then
        self:removeScatterAndBonusLines()
    end
    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)
    self:clearFrames_Fun()
    self:playInLineNodes()
end

function CodeGameScreenLuckyDollarMachine:showLineFrameByIndex(winLines, frameIndex)
end

function CodeGameScreenLuckyDollarMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end
    local isLoop = true
    if self:isTriggerFreeSpinOrBonus() then
        isLoop = false
    end
    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            slotsNode:runLineAnim(isLoop)
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

function CodeGameScreenLuckyDollarMachine:setNotInLinesNodeDarkOrHight(isDark)
    for reelCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            -- if targSp.p_symbolType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 and targSp.p_symbolType <= TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 then
            if not self:checkIsLinesHaveSymbol(reelCol, iRow) then
                if isDark then
                    targSp:runAnim("dark")
                else
                    targSp:runAnim("idleframe")
                end
            end
            -- end
        end
    end
end

function CodeGameScreenLuckyDollarMachine:setAllNodeDark()
    for reelCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                targSp:runAnim("dark")
            end
        end
    end
end

function CodeGameScreenLuckyDollarMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    for i, v in ipairs(self.m_symbolFrameList) do
        if not tolua.isnull(v) then
            v:removeFromParent()
        end
    end
    self.m_symbolFrameList = {}
    self:showLineFrame()
    self:setNotInLinesNodeDarkOrHight(true)
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            54 / 30
        )
    else
        if self:isTriggerFreeSpinOrBonus() then
            performWithDelay(
                self,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                80 / 30
            )
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    return true
end

function CodeGameScreenLuckyDollarMachine:isTriggerFreeSpinOrBonus()
    local isIn = false
    local features = self.m_runSpinResultData.p_features
    if features then
        for k, v in pairs(features) do
            if v == SLOTO_FEATURE.FEATURE_FREESPIN or v == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                isIn = true
            end
        end
    end

    return isIn
end
function CodeGameScreenLuckyDollarMachine:isScatterSymbol(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_2 then
        return true
    end
    return false
end

function CodeGameScreenLuckyDollarMachine:isBonusSymbol(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 or symbolType == self.SYMBOL_BONUS_2 then
        return true
    end
    return false
end

function CodeGameScreenLuckyDollarMachine:lineLogicEffectType(winLineData, lineInfo, iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData, lineInfo)

    if iconsPos ~= nil then
        if self:isScatterSymbol(enumSymbolType) == true then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
        elseif self:isBonusSymbol(enumSymbolType) then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end

function CodeGameScreenLuckyDollarMachine:removeScatterAndBonusLines()
    local lineLen = #self.m_reelResultLines
    self.m_scatterLineValue = nil
    self.m_bonusLineValue = nil
    for i = lineLen, 1, -1 do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            self.m_scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
        elseif lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            self.m_bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
        end
    end
end

function CodeGameScreenLuckyDollarMachine:resetMaskLayerNodes()
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
                util_changeNodeParent(preParent, lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
            -- lineNode:runIdleAnim()
            end
        end
    end
end

function CodeGameScreenLuckyDollarMachine:checkSymbolTypePlayTipAnima(symbolType)
    -- 本关不走底层播放
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        return false
    end
end
return CodeGameScreenLuckyDollarMachine
