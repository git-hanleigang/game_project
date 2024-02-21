---
-- island li
-- 2019年1月26日
-- CodeGameScreenPirateMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseMachine = require "Levels.BaseMachine"
local PirateSlotsNode = require "CodePirateSrc.PirateSlotsNode"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenPirateMachine = class("CodeGameScreenPirateMachine", BaseFastMachine)

CodeGameScreenPirateMachine.m_vecBigLevel = {4, 8, 13, 19}
CodeGameScreenPirateMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenPirateMachine.m_bIsBonusFreeGame = nil
CodeGameScreenPirateMachine.m_iReelMinRow = 3
CodeGameScreenPirateMachine.m_iScatterNum = 0
CodeGameScreenPirateMachine.m_isPlayGemeEffect = nil
local L_ABS = math.abs
--背景切换
local BG_TYPE = {
    NORMAL_TYPE = 0,
    NORMAL_TO_FREESPIN = 1,
    FREESPIN_TO_NORMAL = 2
}

--轮盘位置切换 类型
local WHEEL_TYPE = {
    NORMAL_TYPE = 0, --正常情况下
    MIDDLE_TYPE = 1, --bonus游戏
    ADD_ROW_TYPE = 2, --bonus游戏添加一行
    DOUBLE_TYPE = 3 --bonus游戏双轮
}

--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}
--freespin 类型
local FREE_SPIN_TYPE = {
    LOCK_WILD = 0, --锁定wild
    EXPAND_WILD = 1, --整列变成wild
    WILD_CHANGE = 2, --随机变成wild
    MOVE_WILD = 3 --wild 移动
}

--背景切换
local BG_TYPE = {
    NORMAL_TYPE = 0,
    NORMAL_TO_FREESPIN = 1,
    FREESPIN_TO_NORMAL = 2
}
----自定义信号块
CodeGameScreenPirateMachine.SYMBOL_SCORE_SCATTER_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8 -- Lock Wild 双刀
CodeGameScreenPirateMachine.SYMBOL_SCORE_SCATTER_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9 -- Expand Wild 章鱼
CodeGameScreenPirateMachine.SYMBOL_SCORE_SCATTER_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 -- Change Wild 圣杯
CodeGameScreenPirateMachine.SYMBOL_SCORE_SCATTER_4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 -- Move Wild

CodeGameScreenPirateMachine.EFFECT_MINI_SLOTDOWN = GameEffect.EFFECT_SELF_EFFECT - 1 --收集wild
CodeGameScreenPirateMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 2 --收集wild
CodeGameScreenPirateMachine.EFFECT_TYPE_COLLECT_BONUS = GameEffect.EFFECT_SELF_EFFECT - 3 --触发bonus
CodeGameScreenPirateMachine.EFFECT_TYPE_SHOW_JACKPOT = GameEffect.EFFECT_SELF_EFFECT - 4 --触发jackpot

CodeGameScreenPirateMachine.EFFECT_TYPE_LOCK_WILD = GameEffect.EFFECT_SELF_EFFECT - 5 --锁定wild
CodeGameScreenPirateMachine.EFFECT_TYPE_EXPAND_WILD = GameEffect.EFFECT_SELF_EFFECT - 6 --整列变成wild
CodeGameScreenPirateMachine.EFFECT_TYPE_WILD_CHANGE = GameEffect.EFFECT_SELF_EFFECT - 7 --随机变成wild
CodeGameScreenPirateMachine.EFFECT_TYPE_MOVE_WILD = GameEffect.EFFECT_SELF_EFFECT - 8 --wild 移动
CodeGameScreenPirateMachine.EFFECT_TYPE_ADD_MOVE_WILD = GameEffect.EFFECT_SELF_EFFECT - 9 --添加wild移动新掉落信号块
CodeGameScreenPirateMachine.m_isOutLines = nil --是否是断线
CodeGameScreenPirateMachine.m_bIsBonusFreeGameOver = nil
-- 构造函数
function CodeGameScreenPirateMachine:ctor()
    BaseFastMachine.ctor(self)

    self.m_betLevel = nil
    self.m_isOutLines = false
    self.m_norDownTimes = 0
    self.m_bJackpotWin = false
    self.m_isReconnectTrig = false
    self.m_isFeatureOverBigWinInFree = true
    
    --init
    self:initGame()
end

function CodeGameScreenPirateMachine:initGame()

    --初始化基本数据LevelPiratelConfig
    self.m_configData = gLobalResManager:getCSVLevelConfigData("PirateConfig.csv", "LevelPirateConfig.lua")
    self.m_configData:initMachine(self)
    self.m_iBigLevelFreeSpinNum = 0
    self.m_bBigLevelFreeSpinWild = false
    self:initMachine(self.m_moduleName)
    self.m_collectList = {}
end

function CodeGameScreenPirateMachine:initUI()
    -- 创建view节点方式
    self.m_jackPotBar = util_createView("CodePirateSrc.PirateJackPotLayer", self)
    self:findChild("jackpot"):addChild(self.m_jackPotBar)
    self.m_progress = util_createView("CodePirateSrc.PirateCollectView")
    self.m_csbOwner["node_top"]:addChild(self.m_progress)
    self.m_progress:setBaseState()
    --船桨特效
    self.m_OarsNode = self:findChild("Node_chuanjing")
    self.m_OarsView = util_createView("CodePirateSrc.PirateOarsView")
    self.m_OarsNode:addChild(self.m_OarsView)

    local data = {}
    data.index = 1
    data.parent = self
    self.m_FastReels = util_createView("CodePirateSrc.PirateMiniMachine", data)
    self:findChild("side"):addChild(self.m_FastReels)
    self.m_FastReels:setPositionX(-4)

    self.m_bonusFreeGameBar = util_createView("CodePirateSrc.PirateBnousFreeGameBar")
    self:findChild("Node_iswild"):addChild(self.m_bonusFreeGameBar)
    self.m_bonusFreeGameBar:setVisible(false)

    self:changeWheelPos(WHEEL_TYPE.NORMAL_TYPE)
    self:runCsbAction("idle")

    self.m_guochang = util_spineCreate("Pirate_guochangdonghua", true, true)
    self:addChild(self.m_guochang, ViewZorder.ZORDER_UI - 1)
    self.m_guochang:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochang:setVisible(false)

    --收集玩法特效层
    self.m_effectNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)

    self:initFreeSpinBar() -- FreeSpinbar
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end
            if self.m_bJackpotWin then
                self.m_bJackpotWin = false
                return --去掉jackpot赢钱
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
                if self:checkIsLinesHaveSymbol9() then
                    local _index = xcyy.SlotsUtil:getArc4Random() % 3
                    if _index == 0 then
                        soundIndex = 31
                    elseif _index == 1 then
                        soundIndex = 32
                    elseif _index == 2 then
                        soundIndex = 33
                    end
                else
                    soundIndex = 3
                end
            end
            local soundName = "PirateSounds/sound_pirate_win" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,3,0.4,1)
            
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end
--中奖线 上是否有信号9
function CodeGameScreenPirateMachine:checkIsLinesHaveSymbol9()
    --接下来判断连线上是否有信号块9
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
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
                            return true
                        end
                    end
                end
            end
        end
    end

    return false
end

function CodeGameScreenPirateMachine:updateJackpot()
    self.m_jackPotBar:updateJackpotInfo()
end

function CodeGameScreenPirateMachine:getReelHeight()
    return 555
end

function CodeGameScreenPirateMachine:getReelWidth()
    return 1136
end


function CodeGameScreenPirateMachine:scaleMainLayer()
    
    BaseFastMachine.scaleMainLayer(self)
    local ratio = display.height/display.width
    if  ratio >= 768/1024 then
        local mainScale = 0.85
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    elseif ratio < 768/1024 and ratio >= 640/960 then
        local mainScale = 0.95 - 0.05*((ratio-640/960)/(768/1024 - 640/960))
        self.m_machineRootScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
    end

end

function CodeGameScreenPirateMachine:changeScaleMainLayer(_type)
    local reel = self:findChild("reel")
    local scale = 1
    if WHEEL_TYPE.NORMAL_TYPE == _type then
        reel:setScale(scale)
    elseif _type == WHEEL_TYPE.MIDDLE_TYPE then
        local posX, posY = self:findChild("Node_Middle"):getPosition()
        self.m_bonusFreeGameBar:setPosition(0, 5)
        self.m_bonusFreeGameBar:setScale(1)
        reel:setPosition(posX, posY - 10)
    elseif _type == WHEEL_TYPE.ADD_ROW_TYPE then
        local posX, posY = self:findChild("Node_Middle"):getPosition()
        reel:setPosition(posX, posY - 50)
        self.m_bonusFreeGameBar:setPositionY(144)
        self.m_bonusFreeGameBar:setScale(1)
        scale = 0.75
        if display.width <= 1070 then
            scale = 0.85
        end
        reel:setScale(scale)
    elseif _type == WHEEL_TYPE.DOUBLE_TYPE then
        local posX, posY = self:findChild("Node_DoubleWheel"):getPosition()

        if display.width >= 1370 then
            self.m_bonusFreeGameBar:setPosition(410, 30)
            reel:setPosition(posX - 50, posY)
            self.m_bonusGameReel:setPositionX(self.m_bonusGameReel:getPositionX() + 50)
            scale = 0.75
            self.m_bonusFreeGameBar:setScale(1.5)
        elseif display.width <= 1250 then
            self.m_bonusFreeGameBar:setPosition(410, 30)
            reel:setPosition(posX - 10, posY)
            self.m_bonusGameReel:setPositionX(self.m_bonusGameReel:getPositionX() + 10)
            self.m_bonusFreeGameBar:setScale(1.5)
            scale = 0.65
        else
            self.m_bonusFreeGameBar:setPosition(415, 30)
            reel:setPosition(posX - 30, posY)
            self.m_bonusGameReel:setPositionX(self.m_bonusGameReel:getPositionX() + 30)
            scale = 0.7
            self.m_bonusFreeGameBar:setScale(1.5)
        end

        reel:setScale(scale)
        self.m_bonusGameReel:setScale(scale)
    end
end

--小块
function CodeGameScreenPirateMachine:getBaseReelGridNode()
    return "CodePirateSrc.PirateSlotsNode"
end

-- 断线重连
function CodeGameScreenPirateMachine:MachineRule_initGame()
    if self.m_runSpinResultData.p_reSpinCurCount ~= nil and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self.m_bIsRespinReconnect = true
    end

    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_progress:setVisible(true)
        self:runCsbAction("idle")
        if self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_isReconnectTrig = true
            return
        else
            -- self.m_progress:setVisible(false)
            self:runCsbAction("freespin")
        end
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
    elseif self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        self:triggerFreeSpinCallFun()
    -- self.m_progress:setVisible(false)
    end

    if self:BaseMania_isTriggerCollectBonus() then
        if self.m_bonusData[self.m_nodePos] ~= nil and self.m_bonusData[self.m_nodePos].type == "BIG" and self.m_initSpinData.p_freeSpinsLeftCount and self.m_initSpinData.p_freeSpinsLeftCount > 0 then
            self:changeWheelPos(WHEEL_TYPE.MIDDLE_TYPE)
            self:runCsbAction("bonusIdle1")
            self:changeScaleMainLayer(WHEEL_TYPE.MIDDLE_TYPE)
            self:bonusFreeGameInfo()
            performWithDelay(
                self,
                function()
                    self:initFixWild()
                end,
                0.3
            )
            self.m_progress:setVisible(false)
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
            self.m_iBonusFreeTimes = self.m_iFreeSpinTimes
            self.m_bIsBonusFreeGame = true
            -- util_setCsbVisible(self.m_baseFreeSpinBar, true)
            self.m_bottomUI:showAverageBet()
            self:setCurrSpinMode(FREE_SPIN_MODE)
        else
            self.m_progress:setVisible(true)
        end
        self.m_mapNodePos = self.m_nodePos - 1
        self.m_bonusReconnect = true

        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeReelsBg(true)
    end

    self.m_isOutLines = true
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPirateMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Pirate"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPirateMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_SCATTER_1 then
        return "Socre_Pirate_Scatter_1"
    elseif symbolType == self.SYMBOL_SCORE_SCATTER_2 then
        return "Socre_Pirate_Scatter_2"
    elseif symbolType == self.SYMBOL_SCORE_SCATTER_3 then
        return "Socre_Pirate_Scatter_3"
    elseif symbolType == self.SYMBOL_SCORE_SCATTER_4 then
        return "Socre_Pirate_Scatter_4"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenPirateMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 20},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 20}
    }
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_SCATTER_1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_SCATTER_2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_SCATTER_3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_SCATTER_4, count = 2}

    return loadNode
end
--

--[[
    @desc: 获取滚动停止时替换小块 类型
]] function CodeGameScreenPirateMachine:getResNodeSymbolType(parentData)
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
    if self:symbolIsScatter() then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3
    end
    return symbolType
end

function CodeGameScreenPirateMachine:changeFastReelsRunData()
    -- if self:getBetLevel() == 0 then
    --     return
    -- end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fastLuck = selfdata.fastLuck or {}
    local lines = fastLuck.lines
    local isWin = false
    if lines and #lines > 0 then
        isWin = true
    end

    if isWin then
        local rundata = {self.m_reelRunInfo[#self.m_reelRunInfo]:getReelRunLen() + 80}
        self.m_FastReels:slotsReelRunData(
            rundata,
            self.m_FastReels.m_configData.p_bInclScatter,
            self.m_FastReels.m_configData.p_bInclBonus,
            self.m_FastReels.m_configData.p_bPlayScatterAction,
            self.m_FastReels.m_configData.p_bPlayBonusAction
        )
    else
        local rundata = {self.m_reelRunInfo[#self.m_reelRunInfo]:getReelRunLen() + 13}
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            rundata = {self.m_reelRunInfo[#self.m_reelRunInfo]:getReelRunLen() + 16}
        end
        self.m_FastReels:slotsReelRunData(
            rundata,
            self.m_FastReels.m_configData.p_bInclScatter,
            self.m_FastReels.m_configData.p_bInclBonus,
            self.m_FastReels.m_configData.p_bPlayScatterAction,
            self.m_FastReels.m_configData.p_bPlayBonusAction
        )
    end
end
----------------------------- 玩法处理 -----------------------------------
--
--单列滚动停止回调
--
function CodeGameScreenPirateMachine:slotOneReelDown(reelCol)
    -- BaseFastMachine.slotOneReelDown(self, reelCol)
    local haveScatter = false
    if reelCol == 1 then
        self.m_iScatterNum = 0
    end
    for iRow = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if self:symbolIsScatter(symbolType) then
            haveScatter = true
            self.m_iScatterNum = self.m_iScatterNum + 1
        end
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata.freeSpinType and selfdata.freeSpinType == FREE_SPIN_TYPE.LOCK_WILD then
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local targSp = self:setSymbolToClipReel(reelCol, iRow, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                if targSp then
                    targSp:runAnim("buling")

                    local soundPath = "PirateSounds/sound_pirate_wild_ground.mp3"
                    if self.playBulingSymbolSounds then
                        self:playBulingSymbolSounds( reelCol,soundPath )
                    else
                        gLobalSoundManager:playSound(soundPath)
                    end
                end
            end
        end
    end

    --快滚重写
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol)
    end

    if self.m_reelDownSoundPlayed then
        self:playReelDownSound(reelCol,self.m_reelDownSound )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end

    
    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)
    --最后列滚完之后隐藏长滚
    if haveScatter and (self.m_iScatterNum == 1 and reelCol == 2) and self:getGameSpinStage() ~= QUICK_RUN then
        self:creatReelRunAnimation(reelCol)
    end

    if haveScatter and self.m_iScatterNum == 3 then
        for i = 1, #self.m_ScatterShowCol, 1 do
            self:creatReelRunAnimation(self.m_ScatterShowCol[i])
        end
    end

    if self.m_reelRunAnima ~= nil and reelCol <= self.m_ScatterShowCol[#self.m_ScatterShowCol] and haveScatter == false then
        for i = self.m_ScatterShowCol[1], self.m_ScatterShowCol[#self.m_ScatterShowCol] do
            local reelEffectNode = self.m_reelRunAnima[i]
            if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
                -- reelEffectNode[1]:runAction(cc.Hide:create())
                util_playFadeOutAction(reelEffectNode[1], 0.3)
                if self.m_fastRunID then
                    gLobalSoundManager:stopAudio(self.m_fastRunID)
                    self.m_fastRunID = nil
                end
            end
        end
    end
    --fast特效 第五列落地后播放
    if reelCol == 5 then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local fastLuck = selfdata.fastLuck or {}
        local lines = fastLuck.lines
        local isWin = false
        if lines and #lines > 0 then
            isWin = true
        end
        self:checkIsRunFastWinAct(isWin)
    end
    if reelCol == 4 then
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

--[[
    单列滚动停止
]]
function CodeGameScreenPirateMachine:slotOneReelDownFinishCallFunc( reelCol )

    CodeGameScreenPirateMachine.super.slotOneReelDownFinishCallFunc(self,reelCol)

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if self:getCurrSpinMode() == FREE_SPIN_MODE and selfData then
        --移动wild
        if selfData.moveWild then
            local moveWild = selfData.moveWild
            for i=1, #moveWild do
                local endPos = moveWild[i][2]
                if endPos ~= -1 then
                    local fixPos = self:getRowAndColByPos(endPos)
                    if fixPos.iY == reelCol then
                        local fixNode = self:getFixSymbol(fixPos.iY , fixPos.iX, SYMBOL_NODE_TAG)
                        fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                        fixNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD))
                        fixNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - fixNode.p_rowIndex)
        
                        fixNode:runIdleAnim()
                    end
                end
            end
        end

        --固定wild
        if selfData.lockWild then
            local lockWild = selfData.lockWild
            for i=1, #lockWild do
                local fixPos = self:getRowAndColByPos(lockWild[i])
                if fixPos.iY == reelCol then
                    local fixNode = self:getFixSymbol(fixPos.iY , fixPos.iX, SYMBOL_NODE_TAG)
                    fixNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD ), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    fixNode:changeSymbolImageByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD))
                    fixNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - fixNode.p_rowIndex)
    
                    fixNode:runIdleAnim()
                end
            end
        end
    end
end

--提高层级
function CodeGameScreenPirateMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = self:getPosReelIdx(_iRow ,_iCol)
        local pos = util_getOneGameReelsTarSpPos(self, index)
        local showOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + self:getBounsScatterDataZorder(_type)
        util_changeNodeParent(self.m_clipParent, targSp, showOrder)
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end
--设置bonus scatter 层级
function CodeGameScreenPirateMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_SCORE_SCATTER_2 or symbolType == self.SYMBOL_SCORE_SCATTER_1 or symbolType == self.SYMBOL_SCORE_SCATTER_3 or symbolType == self.SYMBOL_SCORE_SCATTER_4 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + 10
    elseif symbolType == self.SYMBOL_SCORE_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
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
-- 处理特殊关卡 遮罩层级
function CodeGameScreenPirateMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    slotParent:getParent():setLocalZOrder(parentData.cloumnIndex * 10)
end

-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenPirateMachine:levelFreeSpinEffectChange()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenPirateMachine:levelFreeSpinOverChangeEffect()
end
---------------------------------------------------------------------------

function CodeGameScreenPirateMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("PirateSounds/sound_pirate_scatter_start.mp3")

    local showFreeSpinView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            -- self:showFreeSpinMore(
            --     self.m_runSpinResultData.p_freeSpinNewCount,
            --     function()
            --         effectData.p_isPlay = true
            --         self:playGameEffect()
            --     end,
            --     true
            -- )
        else
            self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    -- self.m_progress:setVisible(false)
                    self.m_progress:setFreespinState()
                    self:runCsbAction("freespin")
                end
            )
        end
    end
    --全部scatter的触发动画
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if
                symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCORE_SCATTER_1 or symbolType == self.SYMBOL_SCORE_SCATTER_2 or symbolType == self.SYMBOL_SCORE_SCATTER_3 or
                    symbolType == self.SYMBOL_SCORE_SCATTER_4
             then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    targSp:runAnim("actionframe", false)
                -- gLobalSoundManager:playSound("PirateSounds/sound_Pirate_scatter_ground.mp3")
                end
            end
        end
    end
    gLobalSoundManager:playSound("PirateSounds/sound_pirate_scatter_start.mp3")
    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            self:playTransitionEffect(
                function()
                    if self.m_reelRunAnima ~= nil then
                        for i = self.m_ScatterShowCol[1], self.m_ScatterShowCol[#self.m_ScatterShowCol] do
                            local reelEffectNode = self.m_reelRunAnima[i]
                            if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
                                -- reelEffectNode[1]:runAction(cc.Hide:create())
                                util_playFadeOutAction(reelEffectNode[1], 0.3)
                            end
                        end
                    end
                    self:levelBgEffectChange(BG_TYPE.NORMAL_TO_FREESPIN)
                    -- gLobalSoundManager:playSound("PirateSounds/sound_pirate_freespin_start.mp3")
                    showFreeSpinView()
                end,
                function()
                end
            )
        end,
        3.5
    )
end

function CodeGameScreenPirateMachine:showFreeSpinStart(num, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local frssSpinType = FREE_SPIN_TYPE.LOCK_WILD
    if selfdata ~= nil then
        frssSpinType = selfdata.freeSpinType
    end
    if frssSpinType == FREE_SPIN_TYPE.LOCK_WILD then
        view:findChild("zi_1"):setVisible(true)
        view:findChild("zi_2"):setVisible(false)
        view:findChild("zi_3"):setVisible(false)
        view:findChild("zi_4"):setVisible(false)
    elseif frssSpinType == FREE_SPIN_TYPE.EXPAND_WILD then
        view:findChild("zi_1"):setVisible(false)
        view:findChild("zi_2"):setVisible(true)
        view:findChild("zi_3"):setVisible(false)
        view:findChild("zi_4"):setVisible(false)
    elseif frssSpinType == FREE_SPIN_TYPE.WILD_CHANGE then
        view:findChild("zi_1"):setVisible(false)
        view:findChild("zi_2"):setVisible(false)
        view:findChild("zi_3"):setVisible(true)
        view:findChild("zi_4"):setVisible(false)
    elseif frssSpinType == FREE_SPIN_TYPE.MOVE_WILD then
        view:findChild("zi_1"):setVisible(false)
        view:findChild("zi_2"):setVisible(false)
        view:findChild("zi_3"):setVisible(false)
        view:findChild("zi_4"):setVisible(true)
    end

    return view
end

function CodeGameScreenPirateMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("PirateSounds/sound_pirate_freespin_over.mp3")
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    if self.m_fsReelDataIndex ~= 0 then
        self.m_fsReelDataIndex = 0
    end
    if self.m_bIsBonusFreeGame == true then
        self.m_bIsBonusFreeGame = false
        self.m_bIsBonusFreeGameOver = true
        local ownerlist = {}
        ownerlist["m_lb_num"] = self.m_iBonusFreeTimes
        ownerlist["m_lb_coins"] = util_formatCoins(self.m_runSpinResultData.p_selfMakeData.countCoins, 30)
        local view =
            self:showDialog(
            "SuperFreeSpinOver",
            ownerlist,
            function()
                self:playTransitionEffect(
                    function()
                        self.m_bonusFreeGameBar:setVisible(false)
                        self.m_bottomUI:hideAverageBet()
                        self.m_progress:setVisible(true)

                        self:clearWinLineEffect()
                        self:resetMaskLayerNodes()

                        if self.m_iReelRowNum > self.m_iReelMinRow then
                            self.m_iReelRowNum = self.m_iReelMinRow
                            self:changeReelData()
                        end
                        if self.m_bonusGameReel ~= nil then
                            self.m_bonusGameReel:removeFromParent()
                            self.m_bonusGameReel = nil
                        end
                        self:changeWheelPos(WHEEL_TYPE.NORMAL_TYPE)
                        self:runCsbAction("idle")
                        self:changeScaleMainLayer(WHEEL_TYPE.NORMAL_TYPE)
                        self:resetBigLevelReelInfo()
                    end,
                    function()
                        performWithDelay(
                            self,
                            function()
                                self:showBonusMap(
                                    function()
                                        local index = nil
                                        if self.m_nodePos < #self.m_bonusData then
                                            index = self.m_bonusData[self.m_nodePos + 1].levelID
                                        else
                                            self.m_nodePos = 0
                                            self:updateMapData(self.m_runSpinResultData.p_selfMakeData.map)
                                            self.m_map:mapReset(self.m_bonusData)
                                        end
                                        self.m_progress:resetProgress(
                                            index,
                                            function()
                                                self:resetViewAfterBigLevel()
                                                local haveNext = false
                                                if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
                                                    haveNext = true
                                                end
                                                self:triggerFreeSpinOverCallFun(haveNext)
                                                self.m_effectNode:removeAllChildren()
                                                self.m_progress:setBtnTouchEnabled(true)
                                                self:changeReelsBg(false)
                                                if haveNext == true then
                                                    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                                                    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                                                    self:changeReelsBg(true)
                                                end
                                                self:resetMusicBg()
                                                gLobalSoundManager:setBackgroundMusicVolume(0)
                                            end
                                        )
                                    end,
                                    self.m_nodePos
                                )
                            end,
                            1
                        )
                    end
                )
            end
        )
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 760)
        --设置显示信息 区分三个及以下 和三个以上的UI显示
        self:setSuperFreeSpinOverView(view)
    else
        local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)

        local view =
            self:showFreeSpinOver(
            strCoins,
            self.m_runSpinResultData.p_freeSpinsTotalCount,
            function()
                self:playTransitionEffect(
                    function()
                        self:changeMoveSymbolToNormalReel()
                        self.m_progress:setVisible(true)
                        self:runCsbAction("idle")
                        self.m_progress:setBaseState()
                        self:triggerFreeSpinOverCallFun()
                        self.m_progress:setBtnTouchEnabled(true)
                        self:levelBgEffectChange(BG_TYPE.FREESPIN_TO_NORMAL)
                        self.m_effectNode:removeAllChildren()
                    end,
                    function()
                    end
                )
            end
        )
        local node = view:findChild("m_lb_coins")
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 773)
    end
end

function CodeGameScreenPirateMachine:setSuperFreeSpinOverView(_view)
    if _view == nil then
        return
    end
    _view:findChild("Node_3"):setVisible(false)
    _view:findChild("Node_5"):setVisible(false)
    local info = self.m_bonusData[self.m_nodePos]
    if #info.allGames > 3 then
        _view:findChild("Node_5"):setVisible(true)
        for i = 1, 5 do
            _view:findChild("extra_id_" .. i):setVisible(false)
            _view:findChild("dui_" .. i):setVisible(false)
            _view:findChild("cha_" .. i):setVisible(false)
        end

        local info = self.m_bonusData[self.m_nodePos]
        for i = 1, #info.allGames, 1 do
            _view:findChild("extra_id_" .. i):setVisible(true)
            local tittle = util_createView("CodePirateSrc.PirateBonusExtraGamesTittle")
            _view:findChild("extra_words_" .. i):addChild(tittle)
            tittle:unselected(info.allGames[i])
            _view:findChild("cha_" .. i):setVisible(true)
            for j = 1, #info.extraGames, 1 do
                if info.extraGames[j] == info.allGames[i] then
                    tittle:selected(info.allGames[i])
                    _view:findChild("dui_" .. i):setVisible(true)
                    _view:findChild("cha_" .. i):setVisible(false)
                    break
                end
            end
        end
    else
        _view:findChild("Node_3"):setVisible(true)
        for i = 1, 3 do
            _view:findChild("extra_id_" .. i .. "_1"):setVisible(false)
            _view:findChild("dui_" .. i .. "_1"):setVisible(false)
            _view:findChild("cha_" .. i .. "_1"):setVisible(false)
        end

        local info = self.m_bonusData[self.m_nodePos]
        for i = 1, #info.allGames, 1 do
            _view:findChild("extra_id_" .. i .. "_1"):setVisible(true)
            local tittle = util_createView("CodePirateSrc.PirateBonusExtraGamesTittle")
            _view:findChild("extra_words_" .. i .. "_1"):addChild(tittle)
            tittle:unselected(info.allGames[i])
            _view:findChild("cha_" .. i .. "_1"):setVisible(true)
            for j = 1, #info.extraGames, 1 do
                if info.extraGames[j] == info.allGames[i] then
                    tittle:selected(info.allGames[i])
                    _view:findChild("dui_" .. i .. "_1"):setVisible(true)
                    _view:findChild("cha_" .. i .. "_1"):setVisible(false)
                    break
                end
            end
        end
    end
end

function CodeGameScreenPirateMachine:resetViewAfterBigLevel()
    self.m_bonusFreeGameBar:setPositionY(0)
end
---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPirateMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    self.m_winSoundsId = nil

    if self.m_map:getMapIsShow() == true then
        self:showBonusMap()
    end
    self.m_bSlotRunning = true
    self.m_norDownTimes = 0
    self.m_norSlotsDownTimes = 0
    self.m_isPlayGemeEffect = true
    self.m_isOutLines = false

    return false -- 用作延时点击spin调用
end

function CodeGameScreenPirateMachine:enterGamePlayMusic()
    self:delayCallBack(0.4,function()
        gLobalSoundManager:playSound("PirateSounds/sound_pirate_enter.mp3")
        self:delayCallBack(2.5,function()
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end
        end)
    end)
end

function CodeGameScreenPirateMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    if self.m_bonusData then
        local levelId = nil
        if self.m_bonusData[self.m_mapNodePos + 1] and self.m_bonusData[self.m_mapNodePos + 1].levelID then
            self.m_progress:setPercent(self.m_collectProgress, levelId)
            levelId = self.m_bonusData[self.m_mapNodePos + 1].levelID
        else
            self.m_progress:setPercent(self.m_collectProgress)
        end
    end

    if self.m_map == nil then
        self.m_map = util_createView("CodePirateSrc.PirateBonusMapScrollView", self.m_bonusData, self.m_mapNodePos)

        self:addChild(self.m_map, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
        -- self:addChild(self.m_map, ViewZorder.ZORDER_UI)
        self.m_map:setPosition(display.width * 0.5, display.height * 0.5)
        self.m_map:setVisible(false)
    end
end

function CodeGameScreenPirateMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if self.getCurrSpinMode() ~= RESPIN_MODE and self.getCurrSpinMode() ~= FREE_SPIN_MODE and self.getCurrSpinMode() ~= AUTO_SPIN_MODE then
                gLobalSoundManager:playSound("PirateSounds/sound_pirate_freespin_start.mp3")
                self:showBonusMap()
            end
        end,
        "SHOW_BONUS_MAP"
    )
end

function CodeGameScreenPirateMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenPirateMachine:initGameStatusData(gameData)
    if gameData.collect ~= nil then
        self.m_collectProgress = self:getProgress(gameData.collect[1])
    else
        self.m_collectProgress = 0
    end
    if gameData.gameConfig.extra then
        self.m_nodePos = gameData.gameConfig.extra.currPosition
        self:updateMapData(gameData.gameConfig.extra.map)
    end
    if self.m_nodePos == nil then
        self.m_nodePos = 0
    end
    self.m_mapNodePos = self.m_nodePos
    self:setBigLevelReelInfo()
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenPirateMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == false then
        -- self:BaseMania_completeCollectBonus()
        -- self:updateCollect()
        self:playGameEffect()
        return
    end

    if featureData.p_status == "OPEN" then
        local bonusView = util_createView("CodePirateSrc.PirateBonusGameLayer", self.m_nodePos)

        bonusView:resetView(
            featureData,
            (function(coins, extraGame)
                self:clearCurMusicBg()
                self:bonusGameOver(
                    coins,
                    extraGame,
                    function()
                        bonusView:removeFromParent()
                    end,
                    function()
                        -- self:resetViewAfterBigLevel()
                        self:showBonusMap(
                            function()
                                self.m_bIsInBonusGame = false
                                self.m_progress:resetProgress(
                                    self.m_bonusData[self.m_nodePos + 1].levelID,
                                    function()
                                        self:resetMusicBg()
                                        gLobalSoundManager:setBackgroundMusicVolume(0)
                                        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
                                            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                                            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                                            self:triggerFreeSpinCallFun()
                                            self:changeReelsBg(true)
                                        end
                                        self:playGameEffect()
                                        self.m_progress:setBtnTouchEnabled(true)
                                    end
                                )
                            end,
                            self.m_nodePos
                        )
                        if self.m_bProduceSlots_InFreeSpin == true or self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins + coins)
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
                        else
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                        end
                    end
                )

                self.m_progress:setVisible(true)
            end),
            self
        )
        gLobalViewManager:showUI(bonusView, ViewZorder.ZORDER_UI - 3)

        -- self:addChild(bonusView, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
        if self.m_bProduceSlots_InFreeSpin ~= true then
            self.m_bottomUI:checkClearWinLabel()
        else
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(spinData.p_fsWinCoins))
        end
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(spinData.p_fsWinCoins))
        end
        performWithDelay(
            self,
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            end,
            0.1
        )
        self.m_bIsInBonusGame = true
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        local featureID = spinData.p_features[#spinData.p_features]

        if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            table.remove(self.m_runSpinResultData.p_features, #self.m_runSpinResultData.p_features)
        end

        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        end
        self.m_mapNodePos = self.m_nodePos - 1
    end

    if featureData.p_data ~= nil and featureData.p_data.freespin ~= nil then
        self.m_runSpinResultData.p_freeSpinsLeftCount = featureData.p_data.freespin.freeSpinsLeftCount
        self.m_runSpinResultData.p_freeSpinsTotalCount = featureData.p_data.freespin.freeSpinsTotalCount
    end
end

function CodeGameScreenPirateMachine:getProgress(collect)
    local collectTotalCount = collect.collectTotalCount
    local collectCount = nil

    if collectTotalCount ~= nil then
        collectCount = collect.collectTotalCount - collect.collectLeftCount
    else
        collectTotalCount = collect.p_collectTotalCount
        collectCount = collect.p_collectTotalCount - collect.p_collectLeftCount
    end

    local percent = collectCount / collectTotalCount * 100
    return percent
end

-- ------------玩法处理 --

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenPirateMachine:MachineRule_network_InterveneSymbolMap()
end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenPirateMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCoins = self.m_runSpinResultData.p_collectNetData[1].collectCoinsPool
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        self:BaseMania_updateCollect(addCount, addCoins, 1, totalCount)
    end
end

--是否触发收集小游戏
function CodeGameScreenPirateMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end
---
--添加金边
function CodeGameScreenPirateMachine:creatReelRunAnimation(col)
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

    if reelEffectNode:isVisible() == true and reelEffectNode:getOpacity() >= 240 then
        return
    end

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end
    if col == 2 then
        if self.m_fastRunID == nil then
            self.m_fastRunID = gLobalSoundManager:playSound("PirateSounds/sound_pirate_reel_run.mp3")
        end
    end
    reelEffectNode:setVisible(true)
    util_setCascadeOpacityEnabledRescursion(reelEffectNode, true)
    reelEffectNode:setOpacity(0)
    util_playFadeInAction(reelEffectNode, 0.3)
    util_csbPlayForKey(reelAct, "run", true)
    -- gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    -- self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenPirateMachine:initCloumnSlotNodesByNetData()
    BaseSlotoManiaMachine.initCloumnSlotNodesByNetData(self)

    self:initFixWild()
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPirateMachine:addSelfEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    -- dump(self.m_runSpinResultData.p_reels, "")
    --只在base下 才会收集wild
    if self.getCurrSpinMode() ~= RESPIN_MODE and self.getCurrSpinMode() ~= FREE_SPIN_MODE and self.getCurrSpinMode() ~= AUTO_SPIN_MODE then
        local hasFreepinFeature = false
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            hasFreepinFeature = true
        end
        if hasFreepinFeature then
            self.m_progress:setBtnTouchEnabled(false)
        else
            self.m_progress:setBtnTouchEnabled(true)
        end
    else
        self.m_progress:setBtnTouchEnabled(false)
    end
    self.m_collectList = nil
    if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE or globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        if not self.m_collectList then
                            self.m_collectList = {}
                        end
                        self.m_collectList[#self.m_collectList + 1] = node
                    -- node:runAnim("actionframe")
                    end
                end
            end
        end
        if self.m_collectList and #self.m_collectList > 0 then
            local addCount = #self.m_collectList
            --收集金币
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT

            --是否触发收集小游戏
            if self:BaseMania_isTriggerCollectBonus() then
                -- 收集满了之后的自定义操作
                self.m_bHaveBonusGame = true
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 1
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_COLLECT_BONUS
            end
        end
    end
    --freespin 下各种效果处理
    if selfdata.freeSpinType ~= nil then
        if selfdata.freeSpinType == FREE_SPIN_TYPE.LOCK_WILD then
            if selfdata.lockWild ~= nil and #selfdata.lockWild > 0 then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_LOCK_WILD
            end
        elseif selfdata.freeSpinType == FREE_SPIN_TYPE.EXPAND_WILD then
            if selfdata.wildExpand ~= nil and #selfdata.wildExpand > 0 then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_EXPAND_WILD
            end
        elseif selfdata.freeSpinType == FREE_SPIN_TYPE.WILD_CHANGE then
            if selfdata.changeSignal ~= nil then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_WILD_CHANGE
            end
        elseif selfdata.freeSpinType == FREE_SPIN_TYPE.MOVE_WILD then
            if selfdata.moveWild ~= nil and #selfdata.moveWild > 0 then
                -- dump(selfdata.moveWild, "需要移动的信号块")
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_MOVE_WILD
            end
            if selfdata.newWild ~= nil and #selfdata.newWild > 0 then
                -- dump(selfdata.newWild, "需要新建的信号块")
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_ADD_MOVE_WILD
            end
        end
    end

    --jackpot 弹板处理
    if selfdata.fastLuck ~= nil then
        if selfdata.fastLuck.lines ~= nil then
            local winLines = selfdata.fastLuck.lines
            local jackpotScore = 0
            local jackpotType = 1001
            if #winLines > 0 and winLines[1].type ~= 1001 then
                jackpotType = winLines[1].type
                jackpotScore = winLines[1].amount
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_TYPE_SHOW_JACKPOT
            end
        end
    end
end
---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPirateMachine:MachineRule_playSelfEffect(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local isCollectGame = nil
    if effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT then
        if self.m_collectList and #self.m_collectList > 0 then
            self:flyWild(
                self.m_collectList,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    self.m_collectList = nil
                end
            )
        end
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_COLLECT_BONUS then
        effectData.p_isPlay = true
        self:playGameEffect()
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_SHOW_JACKPOT then
        self:ShowJackPotView(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_LOCK_WILD then
        self:LockWildEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_EXPAND_WILD then
        self:ExpandWildEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_WILD_CHANGE then
        self:WildChangeEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_ADD_MOVE_WILD then
        self:CreateMoveWildEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_MOVE_WILD then
        self:removeMoveWildEffect(effectData)
    end

    return true
end

--jackpot 数据处理
function CodeGameScreenPirateMachine:ShowJackPotView(_effectData)
    local fastLuck = self.m_runSpinResultData.p_selfMakeData.fastLuck or {}
    local winLines = fastLuck.lines
    local jackpotScore = 0
    local jackpotType = 1001
    if #winLines > 0 and winLines[1].type ~= 1001 then
        jackpotType = winLines[1].type
        jackpotScore = winLines[1].amount

        performWithDelay(
            self,
            function()
                self.m_FastReels:playWinJackpotEffect()
                performWithDelay(
                    self,
                    function()
                        self:clearCurMusicBg()
                        -- 播放震动
                        if self.levelDeviceVibrate then
                            self:levelDeviceVibrate(6, "jackpot")
                        end
                        
                        self:showJackpotWin(
                            jackpotType,
                            jackpotScore,
                            function()
                                self.m_bJackpotWin = true
                                local lastWinCoin = globalData.slotRunData.lastWinCoin
                                globalData.slotRunData.lastWinCoin = 0
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {jackpotScore, false, false})
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum) -- 立即更改金币数量
                                globalData.slotRunData.lastWinCoin = lastWinCoin
                                if self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines > 0 then
                                else
                                    self:checkFeatureOverTriggerBigWin(jackpotScore , GameEffect.EFFECT_BONUS)
                                end
                                _effectData.p_isPlay = true
                                self:playGameEffect()
                                self:resetMusicBg(true)
                                gLobalSoundManager:setBackgroundMusicVolume(0)
                            end
                        )
                    end,
                    3
                )
            end,
            0.4
        )
    end
end

--jackpot 弹板
function CodeGameScreenPirateMachine:showJackpotWin(index, coins, func)
    local jackPotWinView = util_createView("CodePirateSrc.PirateJackPotWinView")
    jackPotWinView:initViewData(index, coins, self, func)
    gLobalViewManager:showUI(jackPotWinView, ViewZorder.ZORDER_UI - 1)
end

--------------------------freespin下 四种玩法效果处理----------------------
--锁定wild
function CodeGameScreenPirateMachine:LockWildEffect(_effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    self.m_effectNode:removeAllChildren()
    if selfdata.lockWild ~= nil and #selfdata.lockWild > 0 then
        self:clearWinLineEffect()
        self:resetMaskLayerNodes()
        local vecFixWild = selfdata.lockWild
        for i = 1, #vecFixWild, 1 do
            local fixPos = self:getRowAndColByPos(vecFixWild[i])
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            if not targSp then
                local colParent = self:getReelParent(fixPos.iY)
                local children = colParent:getChildren()
                for i = 1, #children, 1 do
                    local child = children[i]
                    if child.p_cloumnIndex == fixPos.iY and child.p_rowIndex == fixPos.iX then
                        targSp = child
                        break
                    end
                end
            end

            if targSp then
                if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    self:changeSymbolType(targSp,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                end
                local clipSp = self:createWildEffectSymbol(fixPos.iY, fixPos.iX)
                util_spinePlay(clipSp,"idleframe")
            end
        end
        performWithDelay(
            self,
            function()
                _effectData.p_isPlay = true
                self:playGameEffect()
            end,
            1
        )
    end
end

function CodeGameScreenPirateMachine:isHaveNewWild(_list, _tag)
    for k, v in pairs(_list) do
        if _tag == v.tag then
            return true
        end
    end
    return false
end

--锁定wild
function CodeGameScreenPirateMachine:setWildSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = self:getPosReelIdx(_iRow ,_iCol)
        local pos = util_getOneGameReelsTarSpPos(self, index)
        local showOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + self:getBounsScatterDataZorder(_type)
        util_changeNodeParent(self.m_clipParent, targSp, showOrder)
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

--wild转到滚轮上
function CodeGameScreenPirateMachine:changeMoveSymbolToNormalReel()

end

--整列变成wild
function CodeGameScreenPirateMachine:ExpandWildEffect(_effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata.wildExpand ~= nil and #selfdata.wildExpand > 0 then
        local wildCol = selfdata.wildExpand
        gLobalSoundManager:playSound("PirateSounds/sound_pirate_move_wild.mp3")
        for i, iCol in ipairs(wildCol) do
            local wildInRow = 1
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getReelParent(iCol + 1):getChildByTag(self:getNodeTag(iCol + 1, iRow, SYMBOL_NODE_TAG))
                local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol + 1, iRow, SYMBOL_NODE_TAG))
                if not targSp then
                    targSp = clipSp
                end
                if targSp then
                    if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        wildInRow = iRow
                    end
                end
            end
            self:createReelAddWildEffect(iCol + 1, wildInRow)
        end

        performWithDelay(
            self,
            function()
                _effectData.p_isPlay = true
                self:playGameEffect()
            end,
            1.2
        )
    end
end

--整列变成wild 移动效果
function CodeGameScreenPirateMachine:createReelAddWildEffect(_iCol, _iRow)
    local moveWild = {}
    if _iRow == 3 then --向上
        moveWild[1] = {nCol = _iCol, nRow = _iRow - 1}
        moveWild[2] = {nCol = _iCol, nRow = _iRow - 2}
    elseif _iRow == 2 then
        moveWild[1] = {nCol = _iCol, nRow = _iRow - 1}
        moveWild[2] = {nCol = _iCol, nRow = _iRow + 1}
    elseif _iRow == 1 then
        moveWild[1] = {nCol = _iCol, nRow = _iRow + 1}
        moveWild[2] = {nCol = _iCol, nRow = _iRow + 2}
    end

    for i = 1, #moveWild do
        local clipSp = util_spineCreate("Socre_Pirate_Wild",true,true)
        local wildInfo = moveWild[i]
        local startPos = self:getNodePosByColAndRow(_iCol, _iRow)
        local endPos = self:getNodePosByColAndRow(wildInfo.nCol, wildInfo.nRow)
        util_spinePlay(clipSp,"moveframe")
        local moveTo = cc.MoveTo:create(0.8, endPos)

        local zOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
        self.m_clipParent:addChild(clipSp,zOrder + 10000)
        clipSp:setPosition(startPos)

        local fun =
            cc.CallFunc:create(
            function()
                clipSp:setVisible(false)
                self:delayCallBack(0.1,function()
                    clipSp:removeFromParent()
                end)
                

                local targSp = self:getFixSymbol(wildInfo.nCol, wildInfo.nRow, SYMBOL_NODE_TAG)
                if targSp then
                    if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        self:changeSymbolType(targSp,TAG_SYMBOL_TYPE.SYMBOL_WILD)
                        targSp:runAnim("dichuxian")
                    end
                end
            end
        )
        clipSp:runAction(cc.Sequence:create(moveTo, fun))
    end
end

--随机变成wild
function CodeGameScreenPirateMachine:WildChangeEffect(_effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata.changeSignal ~= nil and #selfdata.changeSignal > 0 then
        gLobalSoundManager:playSound("PirateSounds/sound_pirate_move_wild.mp3")
        self:addWildChangeEffect()
        local changeSignal = selfdata.changeSignal

        for i = 1, #changeSignal, 1 do
            local fixPos = self:getRowAndColByPos(changeSignal[i])
            local wild = util_spineCreate("Socre_Pirate_Wild",true,true)
            wild:setPosition(cc.p(0, 0))
            self:findChild("addWildNode"):addChild(wild)
            local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

            if targSp then
                local posWorld = targSp:getParent():convertToWorldSpace(cc.p(targSp:getPosition()))
                local endPos = self:findChild("addWildNode"):convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                util_spinePlay(wild,"moveframe")
                local moveTo = cc.MoveTo:create(1.2, endPos)

                local fun =
                    cc.CallFunc:create(
                    function()
                        wild:removeFromParent()
                        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                        if targSp then
                            if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                                self:changeSymbolType(targSp, TAG_SYMBOL_TYPE.SYMBOL_WILD)
                                targSp:runAnim("dichuxian")
                            end
                        end
                    end
                )
                wild:runAction(cc.Sequence:create(moveTo, fun))
            end
        end

        performWithDelay(
            self,
            function()
                if self.m_SeaView ~= nil then
                    self.m_SeaView:setVisible(false)
                end
                _effectData.p_isPlay = true
                self:playGameEffect()
            end,
            1.7
        )
    end
end

--波光粼粼特效
function CodeGameScreenPirateMachine:addWildChangeEffect()
    if self.m_SeaView ~= nil then
        self.m_SeaView:setVisible(true)
        self.m_SeaView:playIdle()
    else
        self.m_SeaView = util_createView("CodePirateSrc.PirateSeaView")
        self.m_SeaView:playIdle()
        self:findChild("seaNode"):addChild(self.m_SeaView, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    end
end

--设置连线 重新绘制wild
function CodeGameScreenPirateMachine:removeMoveWildEffect(_effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        _effectData.p_isPlay = true
        self:playGameEffect()
    end
end

--添加wild 移动新掉落的信号块
function CodeGameScreenPirateMachine:CreateMoveWildEffect(_effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.newWild ~= nil and #selfdata.newWild > 0 then
            local vecFixWild = selfdata.newWild
            for i=1, #vecFixWild do
                local fixPos = self:getRowAndColByPos(vecFixWild[i])
                self:createWildEffectSymbol(fixPos.iY, fixPos.iX)
            end
            _effectData.p_isPlay = true
            self:playGameEffect()
        end
    end
end

function CodeGameScreenPirateMachine:createWildEffectSymbol(_iCol, _iRow)
    local wild = util_spineCreate("Socre_Pirate_Wild",true,true)
    local index = self:getPosReelIdx(_iRow ,_iCol)
    self.m_effectNode:addChild(wild,index)
    --转化坐标位置    
    local pos = cc.p(util_getOneGameReelsTarSpPos(self,index))  
    wild:setPosition(pos)
    return wild
end

-- 播放wild移动效果
function CodeGameScreenPirateMachine:playMoveWildEffect(_endCallFunc)
    -- moveWild = {data1 = 初始位置,data2 = 移动到位置 -1 移除盘面 ,data3 初始移动数量 ,data4 移动到位置后数量}
    self.m_effectNode:removeAllChildren()
    self.m_vecMoveFixWild = {} --移动停止后固定的wild
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.moveWild and #selfdata.moveWild > 0 then
            local moveWild = selfdata.moveWild
            gLobalSoundManager:playSound("PirateSounds/sound_pirate_move_wild.mp3")
            local totalCount = #moveWild
            for i = 1, #moveWild do
                local fixPos = self:getRowAndColByPos(moveWild[i][1])
                local clipSp = self:createWildEffectSymbol(fixPos.iY, fixPos.iX)
                if clipSp ~= nil then
                    local endPos = cc.p(clipSp:getPositionX() - 200, clipSp:getPositionY())
                    if moveWild[i][2] ~= -1 then
                        util_spinePlay(clipSp,"moveframe")
                        local fixEndPos = self:getRowAndColByPos(moveWild[i][2])
                        endPos = self:getNodePosByColAndRow(fixEndPos.iY, fixEndPos.iX)
                        if moveWild[i][3] > 1 then
                            self:creatWildMarkIdleNum(clipSp, moveWild[i][3])
                        end
                    else
                        util_spinePlay(clipSp,"over")
                        if moveWild[i][3] > 1 then
                            self:creatWildMarkOverNum(clipSp, moveWild[i][3])
                        end
                    end

                    local moveTo = cc.MoveTo:create(1, endPos)
                    --移动完成固定的wild
                    local fixWildSymbol = nil
                    local fixEndPos = self:getRowAndColByPos(moveWild[i][2])
                    local tag = fixEndPos.iY * 10 + fixEndPos.iX
                    fixWildSymbol = self:createWildEffectSymbol(fixEndPos.iY, fixEndPos.iX)
                    if moveWild[i][4] == moveWild[i][3] then
                        self:creatWildMarkIdleNum(fixWildSymbol, moveWild[i][4])
                    else
                        self:creatWildMarkStartNum(fixWildSymbol, moveWild[i][4])
                    end
                    fixWildSymbol:setVisible(false)

                    local fun =
                        cc.CallFunc:create(
                        function()
                            clipSp:removeFromParent()
                            if moveWild[i][2] ~= -1 then
                                if fixWildSymbol ~= nil then
                                    fixWildSymbol:setVisible(true)
                                    util_spinePlay(fixWildSymbol,"dichuxian")
                                    if moveWild[i][4] == moveWild[i][3] then
                                        self:creatWildMarkIdleNum(fixWildSymbol, moveWild[i][4])
                                    else
                                        self:creatWildMarkStartNum(fixWildSymbol, moveWild[i][4])
                                    end
                                end
                            end
                            if i == totalCount and type(_endCallFunc) == "function" then
                                _endCallFunc()
                            end
                        end
                    )
                    clipSp:runAction(cc.Sequence:create(moveTo, fun))
                end
            end
        end
    end
end

--添加数量
function CodeGameScreenPirateMachine:creatWildMarkStartNum(_wildSymbol, _num)
    if _wildSymbol.m_mark == nil then
        local csb = util_createAnimation("Pirate_wildNum.csb")
        _wildSymbol.m_mark = csb
        _wildSymbol.m_mark:setPosition(cc.p(40, -30))
        _wildSymbol.m_mark:playAction("start_" .. _num, false)
        _wildSymbol:addChild(csb, 2)
    else
        _wildSymbol.m_mark:playAction("start_" .. _num, false)
    end
end

--添加数量
function CodeGameScreenPirateMachine:creatWildMarkOverNum(_wildSymbol, _num)
    if _wildSymbol.m_mark == nil then
        local csb = util_createAnimation("Pirate_wildNum.csb")
        _wildSymbol.m_mark = csb
        _wildSymbol.m_mark:setPosition(cc.p(40, -30))
        _wildSymbol.m_mark:playAction("over_" .. _num, false)
        _wildSymbol:addChild(csb, 2)
    else
        _wildSymbol.m_mark:playAction("over_" .. _num, false)
    end
end

--播放数量idle
function CodeGameScreenPirateMachine:creatWildMarkIdleNum(_wildSymbol, _num)
    if _wildSymbol.m_mark == nil then
        local csb = util_createAnimation("Pirate_wildNum.csb")
        _wildSymbol.m_mark = csb
        _wildSymbol.m_mark:setPosition(cc.p(40, -30))
        _wildSymbol.m_mark:playAction("idle_" .. _num, false)
        _wildSymbol:addChild(csb, 2)
    else
        _wildSymbol.m_mark:playAction("idle_" .. _num, false)
    end
end

function CodeGameScreenPirateMachine:getReelsTarSpPos(index)
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos = self:getNodePosByColAndRow(fixPos.iY, fixPos.iX)
    return targSpPos
end

function CodeGameScreenPirateMachine:getNodePosByColAndRow(col, row)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function CodeGameScreenPirateMachine:playEffectNotifyChangeSpinStatus()
    if self.m_isOutLines then
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)
    else
        self:setNormalAllRunDown(1)
    end
end

function CodeGameScreenPirateMachine:setNormalAllRunDown(times)
    self.m_norDownTimes = self.m_norDownTimes + times
    print("setNormalAllRunDown   " .. self.m_norDownTimes)
    if self.m_norDownTimes == 2 or self.m_bIsBonusFreeGame == true or self.m_bIsBonusFreeGameOver == true then
        self.m_bIsBonusFreeGameOver = false
        BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self)
        self.m_norDownTimes = 0
    end
end

function CodeGameScreenPirateMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()

    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end
    self:produceSlots()
    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    self:netBackCheckAddAction()
end

function CodeGameScreenPirateMachine:netBackCheckAddAction()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local isRunFunc = true
    if selfData.freeSpinType and selfData.freeSpinType == FREE_SPIN_TYPE.MOVE_WILD then
        local moveWild = selfData.moveWild or {}
        if moveWild and #moveWild > 0 then
            isRunFunc = false
            self:playMoveWildEffect(function()
                self:netBackReelsStop()
            end)
        end
    end
    if isRunFunc then
        self:netBackReelsStop()
    end
end

function CodeGameScreenPirateMachine:netBackReelsStop()
    self.m_isWaitChangeReel = nil
    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()
end

function CodeGameScreenPirateMachine:removeAllReelsNode()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

            if targSp then
                targSp:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end
        end
    end
end

--收集玩法
function CodeGameScreenPirateMachine:flyWild(list, func)
    local endPos = self.m_progress:getCollectPos()
    local bezTime = 1
    -- gLobalSoundManager:playSound("PirateSounds/sound_despicablewolf_bonus.mp3")
    local isShowCollect = false
    local lastData = self:BaseMania_getCollectData()
    local collectData = {}
    collectData.collectCoinsPool = lastData.p_collectCoinsPool
    collectData.collectLeftCount = lastData.p_collectLeftCount
    collectData.collectTotalCount = lastData.p_collectTotalCount

    gLobalSoundManager:playSound("PirateSounds/sound_pirate_fly_wild.mp3")
    for _, node in pairs(list) do
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)

        local coins = util_spineCreate("Socre_Pirate_Wild",true,true)
        self:addChild(coins, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        util_spinePlay(coins,"wild_shouji")
        coins:setPosition(newStartPos)
        local bez = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        coins:runAction(cc.Sequence:create(cc.DelayTime:create(bezTime / 2), bez))
        local par = self:createFlyPart()
        par:setPosition(newStartPos)
        self:addChild(par, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        local bez2 = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        par:runAction(cc.Sequence:create(cc.DelayTime:create(bezTime / 2), bez2))
        self:delayCallBack(bezTime + 0.1,function(  )
            if isShowCollect == false then
                self.m_progress:showAddAnim()
                isShowCollect = true
            end
            par:removeFromParent()
            coins:removeFromParent()
            coins = nil
        end)
    end
    if list and #list > 0 then
        local isCanSpin = self:IsCanClickSpin()
        if isCanSpin then
            func()
        end

        self:delayCallBack(bezTime + 0.1,function(  )
            self:updateCollect(1.1, collectData)
            if not isCanSpin and type(func) == "function" then
                func()
            end
        end)
    else
        if func ~= nil then
            func()
        end
    end
end

--收集不触发效果可以快 点
function CodeGameScreenPirateMachine:IsCanClickSpin()
    for i = 1, #self.m_gameEffects + 1 do
        local effectData = self.m_gameEffects[i]
        local effectType = effectData.p_effectType
        if effectType ~= GameEffect.EFFECT_BONUS and effectType ~= GameEffect.EFFECT_FREE_SPIN then
            return true
        end
    end
    return false
end

--创建收集粒子跟随
function CodeGameScreenPirateMachine:createFlyPart()
    -- local par = util_createAnimation("Pirate_wild_shouji.csb")
    local par = cc.ParticleSystemQuad:create("effect/wild_shouji_lizi.plist")
    return par
end

--移除
function CodeGameScreenPirateMachine:removeSlotNode(node)
    if type(node.isSlotsNode) == "function" and node:isSlotsNode() then
        node:clear()
    end
    
    node:removeFromParent()

end

-- 高低bet
function CodeGameScreenPirateMachine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenPirateMachine:updatJackPotLock(minBet)
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            -- gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_jackpot_Reels_unlock.mp3")
            -- self.m_FastReels:runCsbAction("shangsheng")

            self.m_betLevel = 1
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            -- gLobalSoundManager:playSound("BeerGirlSounds/music_BeerGirl_jackpot_Reels_lock.mp3")
            self.m_FastReels:stopAllActions()
            self.m_FastReels:clearWinLineEffect()

            -- self.m_FastReels:runCsbAction("xialuo",false,function(  )
            -- end)

            self.m_betLevel = 0
        end
    end
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPirateMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenPirateMachine:initCollectInfo(spinData, lastBetId, isTriggerCollect)
    local collectData = self:BaseMania_getCollectData()
    self.m_progress:updateCollect(collectData.p_collectCoinsPool, collectData.p_collectLeftCount, collectData.p_collectTotalCount, 0)
end

function CodeGameScreenPirateMachine:updateCollect(time, collectData)
    gLobalSoundManager:playSound("PirateSounds/sound_pirate_collect_wild.mp3")
    self.m_progress:updateCollect(collectData.collectCoinsPool, collectData.collectLeftCount, collectData.collectTotalCount, 0)
end

function CodeGameScreenPirateMachine:BaseMania_initCollectDataList()
    local CollectData = require "data.slotsdata.CollectData"
    --收集数组
    self.m_collectDataList = {}
    --默认总数
    for i = 1, 2 do
        self.m_collectDataList[i] = CollectData.new()
        self.m_collectDataList[i].p_collectTotalCount = 123
        self.m_collectDataList[i].p_collectLeftCount = 123
        self.m_collectDataList[i].p_collectCoinsPool = 0
        self.m_collectDataList[i].p_collectChangeCount = 0
    end
end
--更新收集数据 addCount增加的数量  addCoins增加的奖金
function CodeGameScreenPirateMachine:BaseMania_updateCollect(addCount, addCoins, index, totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectCoinsPool = addCoins
        self.m_collectDataList[index].p_collectChangeCount = 0
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

--收集完成重置收集进度
function CodeGameScreenPirateMachine:BaseMania_completeCollectBonus(index, totalCount)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index]) == "table" then
        self.m_collectDataList[index].p_collectTotalCount = totalCount or 200
        self.m_collectDataList[index].p_collectLeftCount = totalCount or 200
        self.m_collectDataList[index].p_collectCoinsPool = 0
        self.m_collectDataList[index].p_collectChangeCount = 0
    end
end

function CodeGameScreenPirateMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local FsReelDatasIndex = 0
        if self.m_runSpinResultData.p_selfMakeData then -- 添加这段代码是为了加上两个假滚滚轮
            local typeNum = self.m_runSpinResultData.p_selfMakeData.freeSpinType
            if typeNum then
                if typeNum == FREE_SPIN_TYPE.LOCK_WILD then
                    FsReelDatasIndex = 0
                elseif typeNum == FREE_SPIN_TYPE.EXPAND_WILD then
                    FsReelDatasIndex = 1
                elseif typeNum == FREE_SPIN_TYPE.WILD_CHANGE then
                    FsReelDatasIndex = 2
                elseif typeNum == FREE_SPIN_TYPE.MOVE_WILD then
                    FsReelDatasIndex = 3
                end
            end
        end
        self.m_fsReelDataIndex = FsReelDatasIndex
    end

    BaseSlotoManiaMachine.beginReel(self)
    self.m_vecMoveFixWildList = {} --移动完成 和 重新掉落的wild 集合
    if self.m_FastReels:isVisible() then
        self.m_FastReels:beginMiniReel()
    end

    if self.m_bonusGameReel ~= nil then
        self.m_bonusGameReel:beginReel()
    end
end

function CodeGameScreenPirateMachine:slotReelDown()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fastLuck = selfdata.fastLuck or {}
    local lines = fastLuck.lines
    local isWin = false
    if lines and #lines > 0 then
        isWin = true
    end
    if not isWin then
        BaseFastMachine.slotReelDown(self)
        self:checkTriggerOrInSpecialGame(
            function()
                self:reelsDownDelaySetMusicBGVolume()
            end
        )
    else
        self:setDownTimes(1)
    end
end

function CodeGameScreenPirateMachine:checkIsRunFastWinAct(isWin)
    if isWin then
        local rodTime = math.random(1, 100)
        if self:checkIsTright(rodTime, 100) then
            self.m_jackPotRunSoundsId =
                gLobalSoundManager:playSound(
                "PirateSounds/sound_pirate_jackpot_longrun.mp3",
                false,
                function()
                    self.m_jackPotRunSoundsId = nil
                end
            )
            gLobalSoundManager:setBackgroundMusicVolume(0)
            self.m_FastReels:playWinEffect()
        end
    end
end

function CodeGameScreenPirateMachine:checkIsTright(rodTime, courTime)
    if rodTime <= courTime then
        return true
    end

    return false
end
function CodeGameScreenPirateMachine:setDownTimes(time)
    self.m_norSlotsDownTimes = self.m_norSlotsDownTimes + time
    if self.m_norSlotsDownTimes == 2 then
        BaseFastMachine.slotReelDown(self)

        self:checkTriggerOrInSpecialGame(
            function()
                self:reelsDownDelaySetMusicBGVolume()
            end
        )

        self.m_norSlotsDownTimes = 0
    end
end
---
-- 老虎机滚动结束调用
function CodeGameScreenPirateMachine:fastReelsWinslotReelDown()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fastLuck = selfdata.fastLuck or {}
    local lines = fastLuck.lines

    if lines and #lines > 0 then
        self:setDownTimes(1)
        if self.m_jackPotRunSoundsId then
            gLobalSoundManager:stopAudio(self.m_jackPotRunSoundsId)
            self.m_jackPotRunSoundsId = nil
        end
    end
end

--[[
    @desc: 重新更新赢钱方法
    author:{author}
    time:2021-06-08 16:03:08
    --@param: 
    @return:
]]

function CodeGameScreenPirateMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        if self.m_bonusGameReel ~= nil then
            winLines = self.m_bonusGameReel.m_runSpinResultData.p_winLines
        end
        if #winLines <= 0 then
            return
        else
            self.m_bIsBigWin = false
            self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin, GameEffect.EFFECT_LINE_FRAME)
        end
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
     end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
end

---
--添加连线动画
function CodeGameScreenPirateMachine:addLineEffect()
    if #self.m_vecGetLineInfo ~= 0 then
        BaseFastMachine.addLineEffect(self)
    elseif self.m_bonusGameReel ~= nil then
        local winLines = self.m_bonusGameReel.m_runSpinResultData.p_winLines
        if #winLines > 0 then
            local effectData = GameEffectData.new()
            effectData.p_effectType = self.m_LineEffectType
            self.m_gameEffects[#self.m_gameEffects + 1] = effectData
        end
    end
end

----
--- 处理spin 成功消息
--
function CodeGameScreenPirateMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or (self:getIsBigLevel() == true and spinData.action == "FEATURE")  then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")

        if self.m_bonusGameReel ~= nil then
            local resultData = spinData.result.selfData.otherReel
            resultData.bet = 1
            self.m_bonusGameReel:netWorkCallFun(resultData)
        end
        -- print(cjson.encode(param[2]))
        
        if self.m_bonusGameReel ~= nil then
            local resultData = spinData.result.selfData.otherReel
            resultData.bet = 1
            self.m_bonusGameReel:netWorkCallFun(resultData)
        end

    end
end

---
-- 处理spin 返回结果
function CodeGameScreenPirateMachine:spinResultCallFun(param)

    self.m_iFixSymbolNum = 0
    self.m_bFlagRespinNumChange = false
    self.m_vecExpressSound = {false, false, false, false, false}

    --获得服务器数据重置freespin等待时间
    self.m_freeSpinOverCurrentTime = 2
    
    self:checkTestConfigType(param)
    
    local isOpera = self:checkOpearReSpinAndSpecialReels(param)  -- 处理respin逻辑
    if isOpera == true then
        return 
    end

    if param[1] == true then                -- 处理spin成功
        self:checkOperaSpinSuccess(param)
    else                                    -- 处理spin失败
        self:checkOpearSpinFaild(param)                            
    end
end


function CodeGameScreenPirateMachine:getIsBigLevel()
    for i = 1, #self.m_vecBigLevel, 1 do
        if self.m_vecBigLevel[i] == self.m_nodePos then
            return true
        end
    end
    return false
end

function CodeGameScreenPirateMachine:playEffectNotifyNextSpinCall()
    BaseSlotoManiaMachine.playEffectNotifyNextSpinCall(self)
    self.m_bSlotRunning = false
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenPirateMachine:bonusFreeGameInfo()
    self.m_fsReelDataIndex = 1
    local info = self.m_bonusData[self.m_nodePos]
    local m4IsWild = false
    local isAddWild = false
    local isAddRow = false
    local isAddWheel = false
    local isDoubleWin = false
    for i = 1, #info.extraGames, 1 do
        local game = info.extraGames[i]
        if game == 3 or game == 11 or game == 16 then
            m4IsWild = true
        end
        if game == 5 then
            isDoubleWin = true
        end
        if game == 1 or game == 14 then
            isAddWild = true
        end
        if game == 9 then
            isAddRow = true
        end
        if game == 18 then
            isAddWheel = true
        end
    end
    if m4IsWild == true and isAddWild == true then
        self.m_fsReelDataIndex = 4
    elseif m4IsWild == true then
        self.m_fsReelDataIndex = 2
    elseif isAddWild == true then
        self.m_fsReelDataIndex = 3
    end

    if m4IsWild == true then
        self.m_bonusFreeGameBar:setVisible(true)
        self.m_bonusFreeGameBar:m4IsWild()
    end

    if isDoubleWin == true then
        self.m_bonusFreeGameBar:setVisible(true)
        self.m_bonusFreeGameBar:doubleWins()
    end

    if isAddRow == true then
        self.m_iReelRowNum = 4
        self:changeReelData()
        self:changeWheelPos(WHEEL_TYPE.ADD_ROW_TYPE)
        self:changeScaleMainLayer(WHEEL_TYPE.ADD_ROW_TYPE)
    end

    if isAddWheel == true then
        self.m_bonusGameReel = util_createView("CodePirateSrc.PirateBonusGameMachine")
        local posX, posY = self:findChild("Node_Bonus_Game"):getPosition()
        self:findChild("root"):addChild(self.m_bonusGameReel)
        self.m_bonusGameReel:setPosition(cc.p(posX, posY))
        self:runCsbAction("bonusIdle1")
        self:changeWheelPos(WHEEL_TYPE.DOUBLE_TYPE)
        self:changeScaleMainLayer(WHEEL_TYPE.DOUBLE_TYPE)
        if self.m_runSpinResultData.p_storedIcons ~= nil then
            self.m_bonusGameReel:setStoredIcons(self.m_runSpinResultData.p_storedIcons)
        end
        if self.m_runSpinResultData.p_selfMakeData.otherReel == nil then
            self.m_bonusGameReel:initSlotNode(self.m_runSpinResultData.p_reels)
        else
            self.m_bonusGameReel:initSlotNode(self.m_runSpinResultData.p_selfMakeData.otherReel.reels)
        end

        self.m_bonusGameReel:initFixWild(self.m_runSpinResultData.p_selfMakeData.lockWild)
        self.m_bonusGameReel:setFSReelDataIndex(self.m_fsReelDataIndex)

        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end
end



--切换轮盘位置
function CodeGameScreenPirateMachine:changeWheelPos(_type)
    local reel = self:findChild("reel")
    if WHEEL_TYPE.NORMAL_TYPE == _type then
        local posX, posY = self:findChild("Node_Normal"):getPosition()
        self.m_OarsNode:setVisible(true)
        reel:setPosition(posX, posY)
        self.m_progress:setVisible(true)
        self.m_FastReels:setVisible(true)
        self.m_jackPotBar:setVisible(true)
        reel:setScale(1)
    elseif _type == WHEEL_TYPE.MIDDLE_TYPE then
        self.m_progress:setVisible(false)
        self.m_FastReels:setVisible(false)
        self.m_jackPotBar:setVisible(false)
        self.m_OarsNode:setVisible(false)
    elseif _type == WHEEL_TYPE.ADD_ROW_TYPE then
        self.m_progress:setVisible(false)
        self.m_FastReels:setVisible(false)
        self.m_jackPotBar:setVisible(false)
        self.m_OarsNode:setVisible(false)
    elseif _type == WHEEL_TYPE.DOUBLE_TYPE then
        self.m_OarsNode:setVisible(false)
        self.m_progress:setVisible(false)
        self.m_FastReels:setVisible(false)
        self.m_jackPotBar:setVisible(false)
    end
end

function CodeGameScreenPirateMachine:changeReelData()
    if self.m_iReelRowNum == 3 then
        self:runCsbAction("bonusIdle1")
    elseif self.m_iReelRowNum == 4 then
        self:runCsbAction("bonusIdle2")
    end

    if self.m_iReelRowNum == self.m_iReelMinRow then
        self.m_bonusFreeGameBar:setPositionY(0)
        self.m_stcValidSymbolMatrix[4] = nil
    else
        self.m_bonusFreeGameBar:setPositionY(self.m_bonusFreeGameBar:getPositionY() + 90)
        if self.m_stcValidSymbolMatrix[4] == nil then
            self.m_stcValidSymbolMatrix[4] = {92, 92, 92, 92, 92}
        end
        -- 主要为断线重连处理的 触发后断线 第四行会是空的
        if self.m_isReconnectTrig == true then
            local symbolTypeList = {1,3,5,8,3}
            for iCol = 1, self.m_iReelColumnNum do
                local  symbolType = symbolTypeList[iCol]
                local targSp = self:getFixSymbol(iCol, 4, SYMBOL_NODE_TAG)
                if targSp ==  nil then
                    local columnData = self.m_reelColDatas[iCol]
                    local pos = self:getNodePosByColAndRow(iCol, 4)
                    targSp = self:getSlotNodeWithPosAndType(symbolType, 4, iCol, true)
                    local order = self:getBounsScatterDataZorder(symbolType) + 10 * iCol - 4
                    targSp.p_slotNodeH = columnData.p_showGridH
                    targSp.p_showOrder = order
                    targSp.p_cloumnIndex = iCol
                    targSp.p_rowIndex = 4
                    targSp.m_isLastSymbol = true
                    targSp:setPosition(pos)
                    targSp:setTag(self:getNodeTag(iCol, 4, SYMBOL_NODE_TAG))
                    self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE, targSp:getTag())
                end
            end
        end
    end


    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum

        local rect = self.m_onceClipNode:getClippingRegion()
        self.m_onceClipNode:setClippingRegion(
            {
                x = rect.x,
                y = rect.y,
                width = rect.width,
                height = columnData.p_slotColumnHeight
            }
        )
    end
end

function CodeGameScreenPirateMachine:updateMapData(map)
    local vecSelectedID = {}
    local vecAllID = {}
    local bigLevelID = 1
    for i = 1, #map, 1 do
        local info = map[i]
        if info.type == "SMALL" then
            if info.selected == true then
                vecSelectedID[#vecSelectedID + 1] = info.position
            end
            vecAllID[#vecAllID + 1] = info.position
        elseif info.type == "BIG" then
            info.extraGames = {}
            info.allGames = {}
            info.levelID = bigLevelID
            bigLevelID = bigLevelID + 1
            for j = #vecSelectedID, 1, -1 do
                table.insert(info.extraGames, 1, vecSelectedID[j])
                table.remove(vecSelectedID, j)
            end
            for j = #vecAllID, 1, -1 do
                table.insert(info.allGames, 1, vecAllID[j])
                table.remove(vecAllID, j)
            end
        end
    end
    self.m_bonusData = map
end

function CodeGameScreenPirateMachine:bonusGameStart(func)
    performWithDelay(
        self,
        function()
            self.m_tiggerBonus = true
            self:playTransitionEffect(
                function()
                    local view = self:showDialog("MiniGameStart", nil, nil, nil, nil)
                    view:setLocalZOrder(ViewZorder.ZORDER_UI - 2)
                    if func ~= nil then
                        func()
                    end
                end,
                function()
                end
            )
        end,
        1
    )
end

-- function CodeGameScreenPirateMachine:showDialog(ccbName,ownerlist,func,isAuto,index,zorder)
--     local view=util_createView("Levels.BaseDialog")
--     view:initViewData(self,ccbName,func,isAuto,index)
--     view:updateOwnerVar(ownerlist)
--     gLobalViewManager:showUI(view,zorder)
--     return view
-- end

function CodeGameScreenPirateMachine:bonusGameOver(coins, extraGame, func1, func2)
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("PirateSounds/sound_pirate_mini_over.mp3")
    if extraGame == nil then
        local view =
            self:showDialog(
            "MiniGameOver",
            ownerlist,
            function()
                self:playTransitionEffect(
                    function()
                        if func1 ~= nil then
                            func1()
                        end
                        if func1 ~= nil then
                            func2()
                        end
                    end,
                    function()
                    end
                )
            end
        )
        local node = view:findChild("m_lb_coins")
        view:findChild("2"):setVisible(false)
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 760)
        view:setLocalZOrder(ViewZorder.ZORDER_UI - 2)
    else
        local view =
            self:showDialog(
            "MiniGameOver",
            ownerlist,
            function()
                self:playTransitionEffect(
                    function()
                        if func1 ~= nil then
                            func1()
                        end
                        if func1 ~= nil then
                            func2()
                        end
                    end,
                    function()
                    end
                )
            end
        )
        local tittle = util_createView("CodePirateSrc.PirateBonusExtraGamesDialog", self.m_nodePos)
        view:findChild("Extra_Game"):addChild(tittle)
        local node = view:findChild("m_lb_coins")
        view:findChild("3"):setVisible(false)
        view:updateLabelSize({label = node, sx = 1, sy = 1}, 760)
        view:setLocalZOrder(ViewZorder.ZORDER_UI - 2)
    end
    self.m_freeSpinOverCurrentTime = 2
end

function CodeGameScreenPirateMachine:showEffect_Bonus(effectData)
    self.m_nodePos = self.m_runSpinResultData.p_selfMakeData.currPosition
    if self.m_bonusReconnect ~= true then
        self.m_mapNodePos = self.m_nodePos
    else
        self.m_bonusReconnect = false
    end

    self:updateMapData(self.m_runSpinResultData.p_selfMakeData.map)
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("PirateSounds/sound_pirate_collect_over.mp3")
        end,
        1
    )
    local bonusGame = function()
        local gameType = self.m_bonusData[self.m_nodePos].type
        if gameType == "SMALL" then
            performWithDelay(
                self,
                function()
                    self:clearCurMusicBg()
                    -- 播放震动
                    if self.levelDeviceVibrate then
                        self:levelDeviceVibrate(6, "bonus")
                    end
                    self:bonusGameStart(
                        function()
                            self.m_tiggerBonus = false
                            self.m_currentMusicBgName = "PirateSounds/music_pirate_minibg.mp3"
                            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
                            local bonusView = util_createView("CodePirateSrc.PirateBonusGameLayer", self.m_nodePos)
                            bonusView:initViewData(
                                function(coins, extraGame)
                                    self:clearCurMusicBg()
                                    self:bonusGameOver(
                                        coins,
                                        extraGame,
                                        function()
                                            local lastWinCoin = coins
                                            --self:getLastWinCoin()
                                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lastWinCoin, false, false})
                                            bonusView:removeFromParent()
                                        end,
                                        function()
                                            self:resetMusicBg()
                                            gLobalSoundManager:setBackgroundMusicVolume(0)
                                            self:showBonusMap(
                                                function()
                                                    self.m_progress:resetProgress(
                                                        self.m_bonusData[self.m_nodePos + 1].levelID,
                                                        function()
                                                            self.m_progress:runCsbAction("idle", true)
                                                            effectData.p_isPlay = true
                                                            self:playGameEffect()
                                                            self.m_progress:setBtnTouchEnabled(true)
                                                            self:resetMusicBg()
                                                            gLobalSoundManager:setBackgroundMusicVolume(0)
                                                        end
                                                    )
                                                end,
                                                self.m_nodePos
                                            )

                                            if self.m_bProduceSlots_InFreeSpin == true or self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                                                self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins + coins)
                                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
                                            else
                                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
                                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                                            end
                                        end
                                    )
                                end,
                                self
                            )
                            gLobalViewManager:showUI(bonusView, ViewZorder.ZORDER_UI - 3)
                            if self.m_bProduceSlots_InFreeSpin ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
                                self.m_bottomUI:checkClearWinLabel()
                            end
                        end
                    )
                end,
                3
            )
        else
            performWithDelay(
                self,
                function()
                    if self.m_mapNodePos ~= self.m_nodePos then
                        self.m_mapNodePos = self.m_nodePos
                    end
                    if self.m_normalFreeSpinTimes == 0 then
                        globalData.slotRunData.lastWinCoin = 0
                        self.m_bottomUI:checkClearWinLabel()
                    end

                    self:clearCurMusicBg()
                    -- 播放震动
                    if self.levelDeviceVibrate then
                        self:levelDeviceVibrate(6, "bonus")
                    end
                    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

                    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                    self.m_iBonusFreeTimes = self.m_iFreeSpinTimes
                    self.m_bIsBonusFreeGame = true
                    -- gLobalSoundManager:playSound("PirateSounds/sound_pirate_freespin_start.mp3")
                    local ownerlist = {}
                    ownerlist["m_lb_num"] = self.m_iFreeSpinTimes
                    self:playTransitionEffect(
                        function()
                            performWithDelay(
                                self,
                                function()
                                    self:runCsbAction("bonusIdle1")
                                    self:changeWheelPos(WHEEL_TYPE.MIDDLE_TYPE)
                                    self:changeScaleMainLayer(WHEEL_TYPE.MIDDLE_TYPE)
                                    self:bonusFreeGameInfo()
                                    self:initFixWild()
                                    -- globalData.slotRunData.lastWinCoin = 0
                                    -- self.m_bottomUI:checkClearWinLabel()
                                    self.m_bottomUI:showAverageBet()
                                    self.m_progress:setVisible(false)
                                end,
                                0
                            )
                            local view =
                                self:showDialog(
                                "SuperFreeSpinStart",
                                ownerlist,
                                function()
                                    -- 调用此函数才是把当前游戏置为freespin状态
                                    self:triggerFreeSpinCallFun()
                                    self:setBigLevelReelInfo()
                                    self:changeReelsBg(true)

                                    effectData.p_isPlay = true
                                    self:playGameEffect()

                                    -- if self.m_nodePos == #self.m_bonusPath then
                                    --     self.m_map:resetMapUI()
                                    -- end
                                end
                            )
                            for i = 1, 5 do
                                view:findChild("extra_id_" .. i):setVisible(false)
                                view:findChild("dui_" .. i):setVisible(false)
                                view:findChild("cha_" .. i):setVisible(false)
                                if i < 5 then
                                    view:findChild("fix_wild_" .. i):setVisible(false)
                                end
                            end

                            local info = self.m_bonusData[self.m_nodePos]
                            view:findChild("fix_wild_" .. info.levelID):setVisible(true)
                            for i = 1, #info.allGames, 1 do
                                view:findChild("extra_id_" .. i):setVisible(true)
                                local tittle = util_createView("CodePirateSrc.PirateBonusExtraGamesTittle")
                                view:findChild("extra_words_" .. i):addChild(tittle)
                                tittle:unselected(info.allGames[i])
                                view:findChild("cha_" .. i):setVisible(true)
                                for j = 1, #info.extraGames, 1 do
                                    if info.extraGames[j] == info.allGames[i] then
                                        tittle:selected(info.allGames[i])
                                        view:findChild("dui_" .. i):setVisible(true)
                                        view:findChild("cha_" .. i):setVisible(false)
                                        break
                                    end
                                end
                            end
                        end,
                        function()
                        end
                    )
                end,
                3
            )
        end
    end

    performWithDelay(
        self,
        function()
            bonusGame()
        end,
        2
    )

    return true
end

function CodeGameScreenPirateMachine:setBigLevelReelInfo()
    if self.m_nodePos == 0 then
        return
    end
    if self.m_nodePos == 4 then
        self.m_iBigLevelFreeSpinNum = 1
    elseif self.m_nodePos == 8 then
        self.m_iBigLevelFreeSpinNum = 2
    elseif self.m_nodePos == 13 then
        self.m_iBigLevelFreeSpinNum = 3
    elseif self.m_nodePos == 18 then
        self.m_iBigLevelFreeSpinNum = 4
    end
    local info = self.m_bonusData[self.m_nodePos]
    if info.extraGames then
        for i = 1, #info.extraGames, 1 do
            local game = info.extraGames[i]
            if game == 3 or game == 11 or game == 17 then
                self.m_bBigLevelFreeSpinWild = true
            end
        end
    end
end

function CodeGameScreenPirateMachine:resetBigLevelReelInfo()
    self.m_iBigLevelFreeSpinNum = 0
    self.m_bBigLevelFreeSpinWild = false
end

function CodeGameScreenPirateMachine:initFixWild()
    self.m_effectNode:removeAllChildren()
    local vecFixWild = nil
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.lockWild ~= nil then
        vecFixWild = self.m_runSpinResultData.p_selfMakeData.lockWild
    end
    if vecFixWild == nil then
        return
    end
    self:clearWinLineEffect()
    self:resetMaskLayerNodes()

    for i = 1, #vecFixWild, 1 do
        local fixPos = self:getRowAndColByPos(vecFixWild[i])
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

        if not targSp then
            local colParent = self:getReelParent(fixPos.iY)
            local children = colParent:getChildren()
            for i = 1, #children, 1 do
                local child = children[i]
                if child.p_cloumnIndex == fixPos.iY and child.p_rowIndex == fixPos.iX then
                    targSp = child
                    break
                end
            end
        end
        if targSp then
            if targSp.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                self:changeSymbolType(targSp,TAG_SYMBOL_TYPE.SYMBOL_WILD)
            end
            local clipSp = self:createWildEffectSymbol(fixPos.iY, fixPos.iX)
            
            util_spinePlay(clipSp,"idleframe")
        end
    end
end

function CodeGameScreenPirateMachine:showBonusMap(callback, nodePos)
    if (self.m_bCanClickMap == false or self.m_bSlotRunning == true) and callback == nil then
        return
    end
    self.m_bCanClickMap = false
    if self.m_map:getMapIsShow() == true then
        self.m_map:mapDisappear(
            function()
                self.m_bCanClickMap = true
            end
        )
    else
        local isAuto = false
        isAuto = callback ~= nil

        self.m_map:mapAppear(
            function()
                self.m_bCanClickMap = true
                if callback ~= nil then
                    self.m_map:pandaMove(callback, self.m_bonusData, nodePos)
                end
            end,
            isAuto
        )

        if callback ~= nil then
            self.m_map:setMapCanTouch(true)
        end
    end
end

--过场动画
function CodeGameScreenPirateMachine:playTransitionEffect(funcFrame, funcEnd)
    self.m_guochang:setVisible(true)
    gLobalSoundManager:playSound("PirateSounds/sound_pirate_guochang.mp3")
    util_spinePlay(self.m_guochang, "animation", false)
    -- 动画帧事件
    util_spineFrameEvent(
        self.m_guochang,
        "animation",
        "show",
        function()
            if funcFrame then
                funcFrame()
            end
        end
    )
    -- 动画结束
    util_spineEndCallFunc(
        self.m_guochang,
        "animation",
        function()
            self.m_guochang:setVisible(false)
            if funcEnd then
                funcEnd()
            end
        end
    )
end

function CodeGameScreenPirateMachine:changeReelsBg(isFur)
    for i = 1, 5 do
        local bg = self:findChild("sp_reel_" .. (i - 1) .. "_1")
        if bg then
            if isFur then
                bg:setVisible(true)
            else
                bg:setVisible(false)
            end
        end
    end
end

function CodeGameScreenPirateMachine:quicklyStopReel(colIndex)
    -- print("quicklyStopReel  调用了快停")
    BaseFastMachine.quicklyStopReel(self, colIndex) 

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local FsReelDatasIndex = 0
        if self.m_runSpinResultData.p_selfMakeData then -- 添加这段代码是为了加上两个假滚滚轮
            local typeNum = self.m_runSpinResultData.p_selfMakeData.freeSpinType
            if typeNum == FREE_SPIN_TYPE.MOVE_WILD then
                -- self:clearMoveWild()
                -- self.m_MovingWildList = {}
            end
        end
    end
end

---
-- 滚动停止和回弹效果
--

function CodeGameScreenPirateMachine:reelSchedulerCheckColumnReelDown(parentData, parentY, halfH)
    local timeDown = 0
    --
    --停止reel
    if L_ABS(parentY - parentData.moveDistance) < 0.1 then -- 浮点数精度问题
        local colIndex = parentData.cloumnIndex
        local slotParentData = self.m_slotParents[colIndex]
        local slotParent = slotParentData.slotParent

        if parentData.isDone ~= true then
            timeDown = 0
            if self.m_bClickQuickStop ~= true or self.m_iBackDownColID == parentData.cloumnIndex then
                parentData.isDone = true
            elseif self.m_bClickQuickStop == true and self:getGameSpinStage() ~= QUICK_RUN then
                return
            end
            
            local quickStopDistance = 0
            if self:getGameSpinStage() == QUICK_RUN or self.m_bClickQuickStop == true then
                quickStopDistance = self.m_quickStopBackDistance
            end
            slotParent:stopAllActions()
            self:slotOneReelDown(colIndex)
            slotParent:setPosition(cc.p(slotParent:getPositionX(), parentData.moveDistance - quickStopDistance))

            local slotParentBig = parentData.slotParentBig
            if slotParentBig then
                slotParentBig:stopAllActions()
                slotParentBig:setPosition(cc.p(slotParentBig:getPositionX(), parentData.moveDistance - quickStopDistance))
                self:removeNodeOutNode(colIndex, true, halfH)
            end

            if self:getGameSpinStage() == QUICK_RUN and self.m_hasBigSymbol == false then
            --播放滚动条落下的音效
            -- if parentData.cloumnIndex == self.m_iReelColumnNum then

            -- gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            end
            -- release_print("滚动结束 .." .. 1)
            --移除屏幕下方的小块
            self:removeNodeOutNode(colIndex, true, halfH)

            local speedActionTable, addTime = self:MachineRule_reelDown(slotParent, parentData)
            if slotParentBig then
                local seq = cc.Sequence:create(speedActionTable)
                slotParentBig:runAction(seq:clone())
            end
            timeDown = timeDown + (addTime + 0.1) -- 这里补充0.1 主要是因为以免计算出来的结果不够一帧的时间， 造成 action 执行和stop reel 有误差

            local tipSlotNoes = {}
            self:foreachSlotParent(
                colIndex,
                function(index, realIndex, slotNode)
                    local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

                    if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
                        --播放关卡中设置的小块效果
                        self:playCustomSpecialSymbolDownAct(slotNode)

                        if self:symbolIsScatter(slotNode.p_symbolType) or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                            if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                                tipSlotNoes[#tipSlotNoes + 1] = slotNode
                            end
                        end
                    end
                end
            )


            if tipSlotNoes ~= nil then
                local nodeParent = parentData.slotParent
                for i = 1, #tipSlotNoes do
                    local slotNode = tipSlotNoes[i]
                    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_SPECIAL_BONUS)
                    self:playScatterBonusSound(slotNode)
                    slotNode:runAnim(
                        "buling",
                        false,
                        function()
                            slotNode:resetReelStatus()
                        end
                    )
                    -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
                    self:specialSymbolActionTreatment(slotNode)
                end -- end for
            end
            
            self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

            local actionFinishCallFunc =
                cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_bClickQuickStop == true then
                        self:quicklyStopReel(parentData.cloumnIndex)
                    end
                    if tipSlotNoes ~= nil then
                        local nodeParent = parentData.slotParent
                        for i = 1, #tipSlotNoes do
                            local slotNode = tipSlotNoes[i]
                            self:setSymbolToClipReel(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType)
                        end -- end for
                    end
                    print("滚动彻底停止了")
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end
            )

            speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

            slotParent:runAction(cc.Sequence:create(speedActionTable))
            timeDown = timeDown + self.m_reelDownAddTime
        end
    end -- end if L_ABS(parentY - parentData.moveDistance) < 0.1

    return timeDown
end

-- 特殊信号下落时播放的音效
function CodeGameScreenPirateMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then

        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil
        local soundType = nil
        if self:symbolIsScatter(slotNode.p_symbolType) then
            soundType = "symbolIsScatter"
            if slotNode.p_cloumnIndex == 2 then
                soundPath = "PirateSounds/sound_pirate_scatter2.mp3"
            elseif slotNode.p_cloumnIndex == 3 then
                soundPath = "PirateSounds/sound_pirate_scatter3.mp3"
            end
            if slotNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local index = 4
                local soundName = "PirateSounds/sound_pirate_scatter" .. index .. ".mp3"
                soundPath = soundName
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            soundType = TAG_SYMBOL_TYPE.SYMBOL_BONUS
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            end
        end

        if soundPath then
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( iCol,soundPath,soundType )
            else
                gLobalSoundManager:playSound(soundPath)
            end
        end
    end
end

-- 快滚相关
function CodeGameScreenPirateMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]

    local nodeData = reelRunData:getSlotsNodeInfo()

    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true -- 触发了长滚动
        -- if  self:getGameSpinStage() == QUICK_RUN  then
        --     gLobalSoundManager:playSound(self.m_reelDownSound)
        -- end
        for i = reelCol + 1, self.m_iReelColumnNum do
            --添加金边
            if i == reelCol + 1 then
                if self.m_reelRunInfo[i]:getReelLongRun() then
                    self:creatReelRunAnimation(i - 1)
                end
            end
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end
    return isTriggerLongRun
end

--设置bonus scatter 信息
function CodeGameScreenPirateMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        local targetSymbolType = self:getSymbolTypeForNetData(column,row,runLen)
        if self:symbolIsScatter(targetSymbolType) then
            local bPlaySymbolAnima = bPlayAni

            allSpecicalSymbolNum = allSpecicalSymbolNum + 1

            if bRun == true then
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)
            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效

                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenPirateMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()
    self:findChild("reel"):addChild(reelEffectNode, 1)
    reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

function CodeGameScreenPirateMachine:symbolIsScatter(symbolType)
    if
        symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCORE_SCATTER_1 or symbolType == self.SYMBOL_SCORE_SCATTER_2 or symbolType == self.SYMBOL_SCORE_SCATTER_3 or
            symbolType == self.SYMBOL_SCORE_SCATTER_4
     then
        return true
    end
    return false
end

--背景切换
function CodeGameScreenPirateMachine:levelBgEffectChange(_type)
    if _type == BG_TYPE.NORMAL_TYPE then
        self.m_gameBg:runCsbAction("normal", true)
    elseif _type == BG_TYPE.FREESPIN_TO_NORMAL then
        self.m_gameBg:runCsbAction(
            "freespin_change_normal",
            false,
            function()
                self.m_gameBg:runCsbAction("normal_idle", true)
            end
        )
    elseif _type == BG_TYPE.NORMAL_TO_FREESPIN then
        self.m_gameBg:runCsbAction(
            "normal_change_freespin",
            false,
            function()
                self.m_gameBg:runCsbAction("freespin", true)
            end
        )
    end
end

--设置长滚信息
function CodeGameScreenPirateMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    local addLens = false

    for col = 1, iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col] -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1

            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            for checkRunIndex = preRunLen + iRow, 1, -1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        else
            if addLens == true then
                if col == 5 then
                    self.m_reelRunInfo[col]:setReelLongRun(false)
                    self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 3)
                    self:setLastReelSymbolList()
                end
            end
        end

        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)

        if col == 2 and scatterNum == 1 then
            addLens = true
        end
        if bRunLong == true and col == 3 and scatterNum < 2 then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
            addLens = true
        end
    end --end  for col=1,iColumn do


    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    if selfData.fastLuck then
        if self.m_FastReels then
            selfData.fastLuck.bet = 0
            selfData.fastLuck.payLineCount = 0
            self:changeFastReelsRunData()
            self.m_FastReels:netWorkCallFun(selfData.fastLuck)
        end
    end
end

-- 背景音乐点击spin后播放
function CodeGameScreenPirateMachine:normalSpinBtnCall()
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    self.m_progress:setBtnTouchEnabled(false)
    BaseMachine.normalSpinBtnCall(self)
end

--[[
    延迟回调
]]
function CodeGameScreenPirateMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return CodeGameScreenPirateMachine
