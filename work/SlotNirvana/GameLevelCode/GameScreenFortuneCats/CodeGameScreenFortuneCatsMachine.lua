---
-- island li
-- 2019年1月26日
-- CodeGameScreenFortuneCatsMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseDialog = util_require("Levels.BaseDialog")
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local FortuneCatsShopData = util_require("CodeFortuneCatsShopSrc.FortuneCatsShopData")

local CodeGameScreenFortuneCatsMachine = class("CodeGameScreenFortuneCatsMachine", BaseFastMachine)

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136

--单个滚动 中间有格子框住 为了规定好位置 计算格子之间差值
local Symbol_Interval = 3.5
CodeGameScreenFortuneCatsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFortuneCatsMachine.SYMBOL_ReSpin_CAT = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
--绿猫 --wild
--蓝猫 --SYMBOL_ReSpin_CAT
--红猫 --scatter
--金猫 --bonus

CodeGameScreenFortuneCatsMachine.EFFECT_COLLECT_ICON = GameEffect.EFFECT_SELF_EFFECT - 1 --收集
CodeGameScreenFortuneCatsMachine.EFFECT_PLAY_SMALL_REEL = GameEffect.EFFECT_SELF_EFFECT - 2 --小轮盘转动
CodeGameScreenFortuneCatsMachine.EFFECT_TYPE_SHOW_JACKPOT = GameEffect.EFFECT_SELF_EFFECT - 3 --触发jackpot
CodeGameScreenFortuneCatsMachine.EFFECT_ADD_RESPIN = GameEffect.EFFECT_SELF_EFFECT - 4 --增加respin次数

-- 构造函数
function CodeGameScreenFortuneCatsMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_bBonusGame = false
    self.m_bTriggerFreespin = false
    self.m_scatterDownNum = 1
    self.m_addRepin = false
    self.m_RespinSymbol = {} --respin锁定的位置
    self.m_RespinSymbolEff = {} --respin锁定的效果
    self.m_freespinSymbolEff = {} --freespin锁定的效果
    self.m_lockFramePos = {} --所有锁定的信号
    self.m_jackpotCatNum = 0 --触发jackpot猫的个数
    self.m_jackpotMul = 1 ----jackpot倍数
    self.m_bsuperFreeOver = false
    self.m_bShopOpen = false
    self.m_bshowFreeSpinStart = false
    self.m_bReSpinOver = false
    self.m_bInSuperFreeSpin = false
    self.m_avgBet = 0
    self.m_firstBegin = false
    self.m_bJackpotWin = false
    self.m_bOpenShop = false
    self.m_isFeatureOverBigWinInFree = true
    
    self:initGame()
end

function CodeGameScreenFortuneCatsMachine:initGame()
    self:changeConfigData()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

function CodeGameScreenFortuneCatsMachine:changeConfigData()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FortuneCatsConfig.csv", "LevelFortuneCatsConfig.lua")
    globalData.slotRunData.levelConfigData = self.m_configData
end

function CodeGameScreenFortuneCatsMachine:initReelEffect()
    if self.m_reelEffectName == nil then
        self.m_reelEffectName = self.m_defaultEffectName --"ReelEffect"
    -- display.loadPlistFile("Common1.plist")
    end

    -- 初始化滚动金边  TODO
    self.m_reelRunAnima = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            self:createReelEffect(iCol, iRow)
        end
    end
end

function CodeGameScreenFortuneCatsMachine:getBottomUINode()
    return "CodeFortuneCatsSrc.FortuneCatsGameBottomNode"
end

function CodeGameScreenFortuneCatsMachine:MachineRule_respinTouchSpinBntCallBack()
    self:normalSpinBtnCall()
end

function CodeGameScreenFortuneCatsMachine:initUI()
    self.m_reelRunSound = "FortuneCatsSounds/sound_FortuneCats_run_reel.mp3"

    self.m_jackPotBar = util_createView("CodeFortuneCatsSrc.FortuneCatsJackPotLayer", self)
    self:findChild("jackpot"):addChild(self.m_jackPotBar)
    -- self.m_jackPotBar:setVisible(false)
    self.m_collectView = util_createView("CodeFortuneCatsSrc.FortuneCatsCollectView")
    self:findChild("collectNode"):addChild(self.m_collectView)
    -- self.m_collectView:setVisible(false)
    self.m_Logo = util_createView("CodeFortuneCatsSrc.FortuneCatsLogo")
    self.m_Logo:setLocalZOrder(-1)
    self:findChild("zhaocaimao"):addChild(self.m_Logo)
    self.m_Logo:setBaseMachine(self)
    -- self.m_Logo:setVisible(false)
    -- self:findChild("reel"):setVisible(false)
    self:initFreeSpinBar() -- FreeSpinbar
    self:initTips()
    self.b_closeTips = false

    self:changeNormalAndFreespinBg(1)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bOpenShop ==false then
                if self.m_bIsBigWin then
                    return
                end
                if  self.m_bJackpotWin then
                    self.m_bJackpotWin = false
                    return
                end
            end
          
            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 1
            local soundTime = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end

            local soundName = "FortuneCatsSounds/sound_FortuneCats_last_win_" .. soundIndex .. ".mp3"
            local winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenFortuneCatsMachine:initFreeSpinBar()
    local node_bar = self:findChild("freespin")
    self.m_baseFreeSpinBar = util_createView("CodeFortuneCatsSrc.FortuneCatsFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setPosition(0, 0)
    self.m_baseFreeSpinBar:runCsbAction("idle2")
end

--默认按钮监听回调
function CodeGameScreenFortuneCatsMachine:tipClickFunc()
    if self.b_closeTips == false then
        self.b_closeTips = true
        self:removeTips()
    end
end

function CodeGameScreenFortuneCatsMachine:initTips()
    local node_bar = self:findChild("tipsNode")
    self.m_tips = util_createView("CodeFortuneCatsSrc.FortuneCatsTips", 2)
    self.m_tips:setMachine(self)
    node_bar:addChild(self.m_tips)
end

function CodeGameScreenFortuneCatsMachine:removeTips()
    if self.m_tips then
        self.m_tips:playOver(
            function()
                self.m_tips:removeFromParent()
                self.m_tips = nil
            end
        )
    end
end

function CodeGameScreenFortuneCatsMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:runCsbAction("idle")
end

function CodeGameScreenFortuneCatsMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:runCsbAction("idle2")
end
-- 断线重连
function CodeGameScreenFortuneCatsMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_bBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        else
            local selfdata = self.m_runSpinResultData.p_selfMakeData
            if selfdata and selfdata.jackpotMul then
                self.m_bInSuperFreeSpin = true
                self.m_jackpotMul = selfdata.jackpotMul
                self.m_avgBet = selfdata.avgBet or 0
                self.m_bottomUI:showAverageBet()
            end
            self:changeNormalAndFreespinBg(2)
            self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        end
    elseif self.m_bBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        self:triggerFreeSpinCallFun()
        self:changeNormalAndFreespinBg(2)
        local selfdata = self.m_runSpinResultData.p_selfMakeData
        if selfdata and selfdata.jackpotMul then
            self.m_bInSuperFreeSpin = true
            self.m_jackpotMul = selfdata.jackpotMul
            self.m_avgBet = selfdata.avgBet or 0
            self.m_bottomUI:showAverageBet()
        end
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenFortuneCatsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FortuneCats"
end

function CodeGameScreenFortuneCatsMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)
    self.m_gameBg = gameBg
    -- self.m_gameBg:setVisible(false)
end

---
-- 进入关卡
--
function CodeGameScreenFortuneCatsMachine:enterLevel()
    
    self.m_outOnlin = true
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect,isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    -- 设置位置
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                if iRow == 1 or iRow == 3 then
                    local posY = targSp:getPositionY()
                    if iRow == 1 then
                        posY = posY - Symbol_Interval
                    elseif iRow == 3 then
                        posY = posY + Symbol_Interval
                    end
                    targSp:setPositionY(posY)
                end
            end
        end
    end
    if self.m_bProduceSlots_InFreeSpin == true then
        self:createFreeSpinLockSymbolFrame()
    end
    -- 初始化下部轮盘
    self:createSmallReels()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

--计算位置
function CodeGameScreenFortuneCatsMachine:getSymbolPosYByRow(_row, posy)
    if _row == 1 then
        posy = posy - Symbol_Interval
    elseif _row == 3 then
        posy = posy + Symbol_Interval
    end
    return posy
end


function CodeGameScreenFortuneCatsMachine:scaleMainLayer()
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

    if globalData.slotRunData.isPortrait then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
        end
        local bangHeight = util_getBangScreenHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - bangHeight)
    end

    if display.height / display.width == 1024 / 768 then
        mainScale = 0.70
    end

    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
end

function CodeGameScreenFortuneCatsMachine:changeViewNodePos()
    local bonusReelHeight = 0
    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro > 2 and pro < 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 180)
        elseif pro >= 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 150)
        elseif pro == 2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 100)
        elseif pro <= 1.867 and pro > 1.6 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 20)
        else
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 30)
        end
    elseif display.height >= FIT_HEIGHT_MIN and display.height < FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro > 2 and pro < 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 200)
        elseif pro >= 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 150)
        elseif pro == 2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 100)
        elseif pro <= 1.867 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 10)
        end
    elseif display.height < FIT_HEIGHT_MIN then
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 5)
    end
end

--小块
function CodeGameScreenFortuneCatsMachine:getBaseReelGridNode()
    return "CodeFortuneCatsSrc.FortuneCatsSlotsNode"
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFortuneCatsMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_ReSpin_CAT then
        return "Socre_FortuneCats_Respin"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFortuneCatsMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ReSpin_CAT, count = 5}

    return loadNode
end

function CodeGameScreenFortuneCatsMachine:initGameStatusData(gameData)
    if gameData.gameConfig ~= nil and gameData.gameConfig.init ~= nil and gameData.gameConfig.init.freespinTimes ~= nil then
        self.m_vecFreeSpinTimeInitData = gameData.gameConfig.init.freespinTimes
    end

    if gameData.gameConfig ~= nil and gameData.gameConfig.betData ~= nil then
        self.m_vecFreeSpinTimeByBet = gameData.gameConfig.betData
    end

    ------father start---------------------------------------------------------
    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
    if gameData.gameConfig ~= nil and gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    -- spin
    -- feature
    -- sequenceId
    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    local spin = gameData.spin
    -- spin = nil
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local jackpot = gameData.jackpot
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum ---gameData.totalWinCoins
    self.m_freeSpinOffSetCoins = 0
    --gameData.totalWinCoins
    self:setLastWinCoin(totalWinCoins)

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin, self.m_lineDataPool, self.m_symbolCompares, feature)
        self.m_initSpinData = self.m_runSpinResultData
    end

    if gameData.special then
        -- self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData.p_features = gameData.special.features
        if gameData.special.freespin ~= nil then
            self.m_runSpinResultData.p_freeSpinsTotalCount = gameData.special.freespin.freeSpinsTotalCount -- fs 总数量
            self.m_runSpinResultData.p_freeSpinsLeftCount = gameData.special.freespin.freeSpinsLeftCount -- fs 剩余次数
            self.m_runSpinResultData.p_fsMultiplier = gameData.special.freespin.fsMultiplier -- fs 当前轮数的倍数
            self.m_runSpinResultData.p_freeSpinNewCount = gameData.special.freespin.freeSpinNewCount -- fs 增加次数
            self.m_runSpinResultData.p_fsWinCoins = gameData.special.freespin.fsWinCoins -- fs 累计赢钱数量
            self.m_runSpinResultData.p_freeSpinAddList = gameData.special.freespin.freeSpinAddList
            self.m_runSpinResultData.p_newTrigger = gameData.special.freespin.newTrigger
            self.m_runSpinResultData.p_fsExtraData = gameData.special.freespin.extra
        end

        self.m_runSpinResultData.p_selfMakeData = gameData.special.selfData

        self.m_initSpinData = self.m_runSpinResultData
    end

    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                if feature.bonus.status == "CLOSED" and feature.bonus.content ~= nil then
                    local bet = feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1]
                    feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1] = -bet
                end
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status
            end
        end
        self.m_initFeatureData:parseFeatureData(feature)
    -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost 
    end
    
    if collect and type(collect) == "table" and #collect > 0 then
        for i = 1, #collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end
    if jackpot and type(jackpot) == "table" and #jackpot > 0 then
        self.m_jackpotList = jackpot
    end
    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    if gameData.gameConfig ~= nil and gameData.gameConfig.bonusReels ~= nil then
        self.m_runSpinResultData["p_bonusReels"] = gameData.gameConfig.bonusReels
    end

    self:initMachineGame()
    ------father end---------------------------------------------------------

    if gameData.feature ~= nil then
        self:checkReconnectFeatures(gameData.feature)
        self:getBonusResult(gameData.feature.selfData.wheel)
    -- self:checkJackPot()
    end

    -- 触发的freespin的断线重连
    if gameData.special ~= nil then
        self.m_gameDataSpecial = gameData.special
        self.m_spinActionType = "SPECIAL"
    end
    -- 商店数据
    if gameData.gameConfig.init and gameData.gameConfig.init.beardData then
        FortuneCatsShopData:parseData(gameData.gameConfig.init.beardData)
    end
end
----------------------------- 玩法处理 -----------------------------------

--
--单列滚动停止回调
--
function CodeGameScreenFortuneCatsMachine:slotOneReelDown(reelCol)
    BaseFastMachine.slotOneReelDown(self, reelCol)
    
end

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenFortuneCatsMachine:levelFreeSpinEffectChange()
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenFortuneCatsMachine:levelFreeSpinOverChangeEffect()
end
---------------------------------------------------------------------------
-- 显示free spin
function CodeGameScreenFortuneCatsMachine:showEffect_FreeSpin(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
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

    -- 停掉背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end
    self:showFreeSpinView(effectData)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenFortuneCatsMachine:setAllCatIdle()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if self:isCatSymbolType(symbolType) then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    targSp:runAnim("idleframe", false)
                end
            end
        end
    end
end
function CodeGameScreenFortuneCatsMachine:showFreeSpinView(effectData)
    self.m_bshowFreeSpinStart = true
    self:clearCurMusicBg()
    if self.m_jackPotBar then
        self.m_jackPotBar:playIdle()
    end
    self:setAllCatIdle()

    local delayTimes = 3.3
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local bTriggerSuperFreespin = false
    if selfdata and selfdata.triggerSuperFree and selfdata.triggerSuperFree == "true" then
        bTriggerSuperFreespin = true
        delayTimes = 0.1
    end
    local showFreeSpinView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        else
            if bTriggerSuperFreespin then
                self.m_bInSuperFreeSpin = true
                gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_superfree_start_tips.mp3")
                self:showFreeSpinStart(
                    self.m_iFreeSpinTimes,
                    function()
                        self:changeFresSpinSymbol(
                            function()
                                self.m_bottomUI:showAverageBet()
                                self:changeNormalAndFreespinBg(3)
                                self:showFreespinEff()
                                globalData.slotRunData.lastWinCoin = 0
                                self.m_bottomUI:checkClearWinLabel()
                                local jackpotMul = 1
                                if selfdata.jackpotMul then
                                    jackpotMul = selfdata.jackpotMul
                                end
                                self:triggerFreeSpinCallFun()
                                self.m_jackPotBar:playChangeEff(jackpotMul,
                                    function()
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end
                                )
                                self.m_jackpotMul = jackpotMul
                                --平均bet
                                if selfdata.avgBet then
                                    self.m_avgBet = selfdata.avgBet
                                end
                            end
                        )
                    end
                )
            else
               self.m_bTriggerFreespin = true 
                local startView = util_createView("CodeFortuneCatsSrc.FortuneCatsFreeSpinStart", self.m_iFreeSpinTimes)
                if globalData.slotRunData.machineData.p_portraitFlag then
                    startView.getRotateBackScaleFlag = function(  ) return false end
                end
                gLobalViewManager:showUI(startView, ViewZorder.ZORDER_UI)
                startView:setCallFunc(
                    function()
                        self:changeFresSpinSymbol(
                            function()
                                self:changeNormalAndFreespinBg(3)
                                self:showFreespinEff()
                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        )
                    end
                )
                startView:showFreeSpinAmi()
            end
        end
    end
    if bTriggerSuperFreespin == false then
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_scatter_trigger.mp3")
        --全部scatter的触发动画
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp then
                        targSp:runAnim("actionframe", false)
                    end
                end
            end
        end
    end
    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFreeSpinView()
        end,
        delayTimes
    )
end

function CodeGameScreenFortuneCatsMachine:showFreespinEff()
    self.m_freespinEff = util_createView("CodeFortuneCatsSrc.FortuneCatsFreeSpinEff")
    self:findChild("freespinEffNode"):addChild(self.m_freespinEff)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_freespinEff.getRotateBackScaleFlag = function(  ) return false end
    end

    

    self.m_freespinEff:runCsbAction(
        "animationStart",
        false,
        function()
            self.m_freespinEff:runCsbAction("idleframe", true)
        end
    )
end

--重写FreeSpinStart
function CodeGameScreenFortuneCatsMachine:showFreeSpinStart(num, func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local view = self:showDialog("SuperFreeSpinStart", ownerlist, func)
    view:findChild("red_0"):setVisible(false)
    view:findChild("green_0"):setVisible(false)
    view:findChild("blue_0"):setVisible(false)
    view:findChild("gold_0"):setVisible(false)
    local pageIndex = 1
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.triggerPage then
        pageIndex = selfdata.triggerPage
    end
    if pageIndex == 0 then
        view:findChild("red_0"):setVisible(true)
    elseif pageIndex == 1 then
        view:findChild("green_0"):setVisible(true)
    elseif pageIndex == 2 then
        view:findChild("blue_0"):setVisible(true)
    elseif pageIndex == 3 then
        view:findChild("gold_0"):setVisible(true)
    end
    return view
end

function CodeGameScreenFortuneCatsMachine:changeFresSpinSymbol(func)
    local symbolList = self.m_respinView:getChangeFreeSpinSlotsNode()
    for i = 1, #symbolList do
        local node = symbolList[i]
        local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
        node:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
    end

    self:createFreeSpinLockSymbolFrame(true)
    -- gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_lock_frame.mp3")

    performWithDelay(
        self,
        function()
            if func then
                func()
            end
        end,
        2.5
    )
end

function CodeGameScreenFortuneCatsMachine:createFreeSpinLockSymbolFrame(_isFreeStart)
    local num = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            if (iRow == 3 and iCol == 1) or (iRow == 2 and iCol == 2) or (iRow == 1 and iCol == 3) then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                    local slotParent = targSp:getParent()
                    local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    local effect = self:creatLockSymbolEffect()
                    effect:setPosition(pos)
                    if _isFreeStart then
                        effect:setVisible(false)
                        scheduler.performWithDelayGlobal(
                            function()
                                effect:setVisible(true)
                                effect:playLock()
                                gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_lock_frame.mp3")
                            end,
                            num * 0.3,
                            self:getModuleName()
                        )
                    else
                        effect:playLock()
                    end

                    self.m_clipParent:addChild(effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
                    table.insert(self.m_freespinSymbolEff, effect)
                    self:addLockFramePos(iCol, iRow)
                    num = num + 1
                end
            end
        end
    end
end

function CodeGameScreenFortuneCatsMachine:showEffect_newFreeSpinOver()
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
    if self.m_jackpotCatNum >= 4 or self.m_bReSpinOver == true then
        self:showFreeSpinOverView()
    else
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_freespin_over.mp3",false)
        scheduler.performWithDelayGlobal(
            function()
                self:showFreeSpinOverView()
            end,
            1.5,
            self:getModuleName()
        )
    end
end

function CodeGameScreenFortuneCatsMachine:showFreeSpinOverView()
    FortuneCatsShopData:setFreeSpinState(false)
    self.m_freespinOverTips = gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_freespin_over_tips.mp3")
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            if self.m_freespinOverTips then
                gLobalSoundManager:stopAudio(self.m_freespinOverTips)
                self.m_freespinOverTips = nil
            end
            --删掉锁定框
            for i = 1, #self.m_freespinSymbolEff do
                local node = self.m_freespinSymbolEff[i]
                node:removeFromParent()
            end
            self.m_freespinSymbolEff = {}
            self.m_lockFramePos = {}
            self:changeNormalAndFreespinBg(4)
            self:resetMusicBg(true)
            self.m_jackpotMul = 1
            if self.m_freespinEff then
                self.m_freespinEff:runCsbAction(
                    "animationOver",
                    false,
                    function()
                        self.m_freespinEff:removeFromParent()
                        self.m_freespinEff = nil
                    end
                )
            end
            local selfdata = self.m_runSpinResultData.p_selfMakeData
            local bTriggerSuperFreespin = false
            if selfdata and selfdata.triggerSuperFree and selfdata.triggerSuperFree == "true" then
                bTriggerSuperFreespin = true
            end

            self.m_bInSuperFreeSpin = false
            self.m_avgBet = 0

            if bTriggerSuperFreespin then
                self.m_bottomUI:hideAverageBet()
                local pageIndex = selfdata.triggerPage
                self.m_bsuperFreeOver = true
                gLobalNoticManager:postNotification("SHOW_SHOP")
                self:showSuperFreeSpinOverTips(
                    pageIndex,
                    function()
                        self:triggerFreeSpinOverCallFun()
                        local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
                        if hasFsEffect == true then
                            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
                            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
                            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
                        end
                    end
                )
            else
                self:triggerFreeSpinOverCallFun()
            end
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1.38, sy = 1.38}, 473)
end

function CodeGameScreenFortuneCatsMachine:showSuperFreeSpinOverTips(pageIndex, func)
    local view = util_createView("CodeFortuneCatsSrc.FortuneCatsSuperFreeSpinOverTips", pageIndex)
    view:setCallFunc(func)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI + 1)
end

function CodeGameScreenFortuneCatsMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if self.m_bshowFreeSpinStart then
                        self.m_bshowFreeSpinStart = false
                        return
                    end
                    self:resetMusicBg()
                    if self.m_bProduceSlots_InFreeSpin == true then
                    else
                        self:setMinMusicBGVolume()
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

function CodeGameScreenFortuneCatsMachine:playRespinBgm()
    self.m_currentMusicBgName = "FortuneCatsSounds/music_FortuneCats_respin_bgm.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

function CodeGameScreenFortuneCatsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    --3秒后移除
    scheduler.performWithDelayGlobal(
        function()
            if self.b_closeTips == false then
                self.b_closeTips = true
                self:removeTips()
            end
        end,
        5,
        self:getModuleName()
    )
end

function CodeGameScreenFortuneCatsMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_bOpenShop = true
            self.m_bottomUI:showAverageBet()
            globalData.slotRunData.lastWinCoin = 0
            self.m_bottomUI:resetWinLabel()
            self.m_bottomUI:checkClearWinLabel()
            self:showShop(
                function()
                    self.m_bOpenShop = false
                    self.m_bottomUI:hideAverageBet()
                    self.m_shop = nil
                    self.m_bShopOpen = false
                    self:resetMusicBg(true)
                    gLobalSoundManager:setBackgroundMusicVolume(0)
                end
            )
        end,
        "SHOW_SHOP"
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params == "start" then
                performWithDelay(
                    self,
                    function()
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                        globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
                        globalData.slotRunData.totalFreeSpinCount = self.m_iFreeSpinTimes

                        local selfEffect = GameEffectData.new()
                        selfEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
                        selfEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
                        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                        self:playGameEffect()
                    end,
                    1
                )
            end
        end,
        "NOTIFY_SHOP_FREE_SPIN"
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:playCoinWinEffectUI()
        end,
        "SHOP_PLAY_WIN_EFFECT"
    )
    
end

function CodeGameScreenFortuneCatsMachine:showShop(callback)
    if self.m_bShopOpen == true then
        return
    end
    self.m_bShopOpen = true
    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_open_shop.mp3")
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:clearCurMusicBg()
    self:removeSoundHandler()
    self:setMaxMusicBGVolume()
    self.m_currentMusicBgName = "FortuneCatsSounds/music_FortuneCats_shop_bgm.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)

    self.m_shop = util_createView("CodeFortuneCatsShopSrc.FortuneCatsShop")
    self.m_shop:setMachine(self)
    self.m_shop:setCloseShopCallFun(callback)
    self:findChild("shopNode"):addChild(self.m_shop)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_shop.getRotateBackScaleFlag = function(  ) return false end
    end


    -- gLobalViewManager:showUI(self.m_shop, ViewZorder.ZORDER_UI)
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenFortuneCatsMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_ReSpin_CAT, runEndAnimaName = "buling", bRandom = true}
    }
    return symbolList
end

function CodeGameScreenFortuneCatsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
    FortuneCatsShopData:release()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFortuneCatsMachine:MachineRule_afterNetWorkLineLogicCalculate()
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end

function CodeGameScreenFortuneCatsMachine:addLastWinSomeEffect()
    BaseFastMachine.addLastWinSomeEffect(self)
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end

--是否触发收集小游戏
function CodeGameScreenFortuneCatsMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index = 1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFortuneCatsMachine:addSelfEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local clickEnable = true
    if selfdata ~= nil then
        --收集金币效果
        if selfdata.scorePositions ~= nil then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 5
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_COLLECT_ICON -- 动画类型
            clickEnable = false
        end
        --jackpot 弹板处理
        if selfdata.jackpots ~= nil then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 3
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TYPE_SHOW_JACKPOT
        end
    end

    if not self:isHaveNewRespinSymbol() then
        if self.m_addRepin == true then
            self:resetRespinInfo()
        end
    end

    if self:isHaveNewGreenCatSymbol() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 4
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_PLAY_SMALL_REEL
    end
end

--添加respin触发效果
function CodeGameScreenFortuneCatsMachine:addRespinEffect()
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.EFFECT_ADD_RESPIN
    self:addNewRespinSymbol()
end

function CodeGameScreenFortuneCatsMachine:resetRespinInfo()
    self.m_addRepin = false

    --播放猫头动画
    if self.m_jackpotCatNum >= self.m_jackpotCatNum then
        self.m_jackPotBar:playEndIdle(self.m_jackpotCatNum)
    end

    --删掉锁定框
    for i = 1, #self.m_RespinSymbolEff do
        local node = self.m_RespinSymbolEff[i]
        node:removeFromParent()
    end
    self.m_RespinSymbolEff = {}
end

function CodeGameScreenFortuneCatsMachine:isLock(_col, _row)
    for i = 1, #self.m_lockFramePos do
        local pos = self.m_lockFramePos[i]
        if pos.iCol == _col and pos.iRow == _row then
            return true
        end
    end
    return false
end

--是否有绿色的猫
function CodeGameScreenFortuneCatsMachine:isHaveNewGreenCatSymbol()
    local isNew = false
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.classicScoreInfo then
        isNew = true
    end
    return isNew
end
--
function CodeGameScreenFortuneCatsMachine:checkHaveRespinSymbolInSamePos(data)
    if #self.m_RespinSymbol > 0 then
        for i = 1, #self.m_RespinSymbol do
            local symbolPos = self.m_RespinSymbol[i]
            if symbolPos.icol == data.icol and symbolPos.irow == data.irow then
                return false
            end
        end
    end
    return true
end

--是否有新添加的蓝色respin信号块 如果有继续spin
function CodeGameScreenFortuneCatsMachine:isHaveNewRespinSymbol()
    for i = 1, #self.m_RespinSymbol do
        self.m_RespinSymbol[i].isNew = false
    end
    local isNew = false
    --先判断有无蓝色猫 SYMBOL_ReSpin_CAT
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == self.SYMBOL_ReSpin_CAT then
                local data = {}
                data.icol = iCol
                data.irow = iRow
                if self:checkHaveRespinSymbolInSamePos(data) then
                    if symbolType == self.SYMBOL_ReSpin_CAT then
                        return true
                    end
                end
            end
        end
    end
    if self:getAllCatNum() == 9 then
        isNew = false
    end
    return isNew
end

--存储信号块
function CodeGameScreenFortuneCatsMachine:addNewRespinSymbol()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if symbolType == self.SYMBOL_ReSpin_CAT or symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                local data = {}
                data.icol = iCol
                data.irow = iRow
                data.type = symbolType
                if self:checkHaveRespinSymbolInSamePos(data) then
                    data.isNew = true
                    table.insert(self.m_RespinSymbol, data)
                end
            end
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFortuneCatsMachine:MachineRule_playSelfEffect(effectData)
    local isCollectGame = nil
    if effectData.p_selfEffectType == self.EFFECT_COLLECT_ICON then
        self:collectSymbolIconFly(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_TYPE_SHOW_JACKPOT then
        self:showJackPotView(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_ADD_RESPIN then
        self:playAddReSpinEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_PLAY_SMALL_REEL then
        self:playGreenCatFlyCoins(effectData)
    end
    return true
end

function CodeGameScreenFortuneCatsMachine:playGreenCatFlyCoins(effectData)
    --删除多个绿猫触发的连线
    local lineLen = #self.m_reelResultLines
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    local flyTime = 0.5
    local actionframeTimes = 1
    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_collect_fly.mp3")
    local endPos = self.m_collectView:getCollectPos()
    endPos.y = endPos.y - 45.2
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                -- 对应位置创建 jackpot 图标
                node:runAnim("idleframe2")
                local newCorn = self:creatGreenMarker()
                newCorn:playAction("animation0", false)
                newCorn:setScale(self.m_machineRootScale)
                self:addChild(newCorn, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                local pos = cc.p(util_getConvertNodePos(node, newCorn))
                newCorn:setPosition(pos)
                --移除小块内的jackpot 图标
                local actionList = {}
                actionList[#actionList + 1] = cc.DelayTime:create(actionframeTimes)
                actionList[#actionList + 1] = cc.MoveTo:create(10 / 30, cc.p(endPos.x, endPos.y))
                actionList[#actionList + 1] =
                    cc.CallFunc:create(
                    function()
                        newCorn:removeFromParent()
                    end
                )
                local sq = cc.Sequence:create(actionList)
                newCorn:runAction(sq)

                local particle = self:createFlyPart()
                if particle then
                    particle:setPosition(pos)
                    particle:setVisible(false)
                    self:addChild(particle, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                    local actionList2 = {}
                    actionList2[#actionList2 + 1] = cc.DelayTime:create(actionframeTimes)
                    actionList2[#actionList2 + 1] =
                        cc.CallFunc:create(
                        function()
                            particle:setVisible(true)
                            particle:resetSystem()
                        end
                    )
                    actionList2[#actionList2 + 1] = cc.MoveTo:create(10 / 30, cc.p(endPos.x, endPos.y))
                    actionList2[#actionList2 + 1] =
                        cc.CallFunc:create(
                        function()
                            particle:removeFromParent()
                        end
                    )
                    local particleSq = cc.Sequence:create(actionList2)
                    particle:runAction(particleSq)
                end
            end
        end
    end

    scheduler.performWithDelayGlobal(
        function()
            self:updateCollect(0, 1)
            self:playSmallReelEffect(effectData)
        end,
        1.3,
        self:getModuleName()
    )
end
--respin 处理
function CodeGameScreenFortuneCatsMachine:playSmallReelEffect(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local totalNum = 0
    self.m_SmallIndex = 1
    local greenCatPos = {}
    --全部绿猫的触发动画
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                local pos = {}
                pos.iCol = iCol
                pos.iRow = iRow
                table.insert(greenCatPos, pos)
                if targSp then
                    targSp:runAnim("actionframe2", false)
                end
            end
        end
    end

    if self.m_MiniReel == nil then
        local node = self:findChild("small_reel")
        self.m_MiniReel = util_createView("CodeFortuneCatsSrc.FortuneCatsMiniReel")
        node:addChild(self.m_MiniReel)
        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_MiniReel.getRotateBackScaleFlag = function(  ) return false end
        end

    else
        self.m_MiniReel:setVisible(true)
    end
    self:clearCurMusicBg()

    --小轮盘不再滚动
    local function playMiniReelRunOver()
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_classic_mini_shou.mp3")
                self:runCsbAction(
                    "animation1Over",
                    false,
                    function()
                        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_classic_num_move.mp3")

                        scheduler.performWithDelayGlobal(
                            function()
                                self.m_MiniReel:removeFromParent()
                                self.m_MiniReel = nil
                                self:resetMusicBg(true)
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end,
                            13 / 30,
                            self:getModuleName()
                        )
                    end
                )
            end,
            2.0,
            self:getModuleName()
        )
    end
    --播放小轮盘滚动
    local function playMiniReelRun()
        local num1, num2, num3
        if selfdata.classicScoreInfo and self.m_SmallIndex <= #selfdata.classicScoreInfo then
            num1 = selfdata.classicScoreInfo[self.m_SmallIndex][1]
            num2 = selfdata.classicScoreInfo[self.m_SmallIndex][2]
            num3 = selfdata.classicScoreInfo[self.m_SmallIndex][3]
            totalNum = num1 + num2 + num3
        end
        local pos = greenCatPos[self.m_SmallIndex]
        self:playGreenCatRunEffect(pos.iCol, pos.iRow)
        gLobalSoundManager:playSound("FortuneCatsSounds/music_FortuneCats_classic_bgm.mp3")
        self.m_MiniReel:runCsbAction(
            "animation0",
            false,
            function()
                gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_classic_num_show.mp3")
                self:updateCollect(totalNum, 1)
                if self.m_SmallIndex < #selfdata.classicScoreInfo then
                    self.m_SmallIndex = self.m_SmallIndex + 1
                    scheduler.performWithDelayGlobal(
                        function()
                            playMiniReelRun()
                        end,
                        1,
                        self:getModuleName()
                    )
                elseif self.m_SmallIndex == #selfdata.classicScoreInfo then
                    for i = 1, #self.m_reelRunAnima do
                        local reelEffectNode = self.m_reelRunAnima[i]
                        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
                            reelEffectNode[1]:runAction(cc.Hide:create())
                        end
                    end
                    playMiniReelRunOver()
                end
            end
        )
        scheduler.performWithDelayGlobal(
            function()
                self.m_MiniReel:setOverNum(num1, num2, num3)
            end,
            0.2,
            self:getModuleName()
        )
    end

    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_green_cat_trigger.mp3")
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_classic_num_show.mp3")
            self:runCsbAction(
                "animation1Start",
                false,
                function()
                    playMiniReelRun()
                end
            )
        end,
        2,
        self:getModuleName()
    )
end

function CodeGameScreenFortuneCatsMachine:playGreenCatRunEffect(icol, irow)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end
    for i = 1, #self.m_reelRunAnima do
        local reelEffectNode = self.m_reelRunAnima[i]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    local index = (irow - 1) * 3 + (3 - icol + 1)
    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[index] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col, irow)
    else
        local reelObj = self.m_reelRunAnima[index]
        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    self:setLongAnimaInfo(reelEffectNode, icol, irow)

    reelEffectNode:setVisible(true)
    util_setCascadeOpacityEnabledRescursion(reelEffectNode, true)
    reelEffectNode:setOpacity(0)
    util_playFadeInAction(reelEffectNode, 0.1)
    util_csbPlayForKey(reelAct, "run", true)
end

function CodeGameScreenFortuneCatsMachine:getAllCatNum()
    local num = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType =  self:getMatrixPosSymbolType(iRow, iCol)
            if self:isCatSymbolType(symbolType) then
                num = num + 1
            end
        end
    end
    return num
end

function CodeGameScreenFortuneCatsMachine:getMatrixPosSymbolType(iRow, iCol)
    if self.m_runSpinResultData.p_reels then
        local rowCount = #self.m_runSpinResultData.p_reels
        for rowIndex = 1, rowCount do
            local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
            local colCount = #rowDatas
    
            for colIndex = 1, colCount do
                if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                    return rowDatas[colIndex]
                end
            end
        end
    else
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                return symbolType
            end
        end
    end
end

function CodeGameScreenFortuneCatsMachine:showRespinView(effectData)
    if self.m_outOnlin then
        self.m_addRepin = true
        self:addNewRespinSymbol()

        for i = 1, #self.m_RespinSymbol do
            local data = self.m_RespinSymbol[i]
            local iCol = data.icol
            local iRow = data.irow
            if ((iRow == 3 and iCol == 1) or (iRow == 2 and iCol == 2) or (iRow == 1 and iCol == 3)) and self.m_bProduceSlots_InFreeSpin then
                --freespin 时 固定位置的不再画
            else
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local effect = self:creatLockSymbolEffect()
                    local slotParent = targSp:getParent()
                    local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    self.m_clipParent:addChild(effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
                    effect:setPosition(pos)
                    effect:playLockIdle()
                    table.insert(self.m_RespinSymbolEff, effect)
                    self:addLockFramePos(iCol, iRow)
                end
            end
        end

    end

    self:setCurrSpinMode(RESPIN_MODE)
    if self:getAllCatNum() == 9 then
        self:setReSpinModeStatus()
    end
    effectData.p_isPlay = true
    self:playGameEffect()
end

--改变 reSpin 的 状态
function CodeGameScreenFortuneCatsMachine:setReSpinModeStatus()
    if self:getCurrSpinMode() == RESPIN_MODE then
        self.m_runSpinResultData.p_reSpinCurCount = 0
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_RESPIN_OVER
        self.m_gameEffects[#self.m_gameEffects + 1] = effectData
    end
end
--respin 处理
function CodeGameScreenFortuneCatsMachine:playAddReSpinEffect(effectData)
    --先播放动画 再进入respin
    self:setLockEffectVisible(true)
    local delayTime = 1.6
    if self.m_addRepin == false then
        self.m_addRepin = true
        self:clearCurMusicBg()
        delayTime = 2
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_respin_trigger.mp3")
        scheduler.performWithDelayGlobal(
            function()
                self:playRespinBgm()
            end,
            delayTime,
            self:getModuleName()
        )
    end
    --所有非蓝猫变亮
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if self:isCatSymbolType(symbolType) and symbolType ~= self.SYMBOL_ReSpin_CAT then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    targSp:runAnim("idleframe", false)
                end
            end
        end
    end

    self:clearFrames_Fun()
    local isRespinNew = false
    for i = 1, #self.m_RespinSymbol do
        local data = self.m_RespinSymbol[i]
        local iCol = data.icol
        local iRow = data.irow
        local isNew = data.isNew
        local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        if targSp and data.type == self.SYMBOL_ReSpin_CAT then
            if isNew == true then
                targSp:runAnim(
                    "actionframestart",
                    false,
                    function()
                        targSp:runAnim("idle2", false)
                    end
                )
            else
                targSp:runAnim("idle2", false)
            end
        end
    end

    self.m_respinView:playReSpinCatIdle()
    scheduler.performWithDelayGlobal(
        function()
            for i = 1, #self.m_RespinSymbol do
                local data = self.m_RespinSymbol[i]
                local iCol = data.icol
                local iRow = data.irow
                local isNew = data.isNew
                if ((iRow == 3 and iCol == 1) or (iRow == 2 and iCol == 2) or (iRow == 1 and iCol == 3)) and self.m_bProduceSlots_InFreeSpin then
                    --freespin 时 固定位置的不再画
                else
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if targSp and isNew == true then
                        isRespinNew = true
                        local effect = self:creatLockSymbolEffect()
                        local slotParent = targSp:getParent()
                        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                        self.m_clipParent:addChild(effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
                        effect:setPosition(pos)
                        effect:playLock()
                        table.insert(self.m_RespinSymbolEff, effect)
                        self:addLockFramePos(iCol, iRow)
                    end
                end
            end
            if isRespinNew == true then
                -- for i = 1, #self.m_RespinSymbolEff do
                --     local effect = self.m_RespinSymbolEff[i]
                --     effect:playLock()
                -- end
                gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_lock_frame.mp3")
            end
        end,
        1.0,
        self:getModuleName()
    )
    scheduler.performWithDelayGlobal(
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,
        delayTime,
        self:getModuleName()
    )
end

--设置锁定框的可见行
function CodeGameScreenFortuneCatsMachine:setLockEffectVisible(_bshow)
    for i = 1, #self.m_RespinSymbolEff do
        local effect = self.m_RespinSymbolEff[i]
        effect:setVisible(_bshow)
    end
    for i = 1, #self.m_freespinSymbolEff do
        local effect = self.m_freespinSymbolEff[i]
        effect:setVisible(_bshow)
    end
end

--jackpot 数据处理
function CodeGameScreenFortuneCatsMachine:showJackPotView(_effectData)
    self.m_jackPotBar:playAddCatHeadEffect(self.m_jackpotCatNum)
    gLobalSoundManager:pauseBgMusic() --暂停背景音
    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_trigger.mp3")

    local jackpots = self.m_runSpinResultData.p_selfMakeData.jackpots
    local jackpotsWin = self.m_runSpinResultData.p_selfMakeData.jackpotLinesWin
    local jackpotScore = jackpotsWin[1].amount
    local jackpotType = #jackpots.position -- 猫的个数
    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS or lineValue.enumSymbolType == self.SYMBOL_ReSpin_CAT then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    self:setLockEffectVisible(false)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if self:isCatSymbolType(symbolType) then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                local isVisible = targSp:isVisible()
                if targSp then
                    targSp:runAnim("actionframe", true)
                end
            end
        end
    end
    --判断是否只有jackpot 赢钱
    if  self.m_serverWinCoins == jackpotScore then
        self.m_bJackpotWin = true
    end

    if jackpotType > 4 then
      
        performWithDelay(
            self,
            function()
                self:showJackpotWin(
                    jackpotType,
                    jackpotScore,
                    function()
                        if self:getCurrSpinMode() ~= RESPIN_MODE then
                            gLobalSoundManager:resumeBgMusic()
                        else
                            self:clearCurMusicBg()
                        end
                        --移除bigwin 等相关效果
                        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
                        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
                        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
                    
                        _effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            end,
            2.8
        )
    else
        local delayTime = 2.8
        if self.m_bProduceSlots_InFreeSpin == true then
            delayTime = 1.2
            if  self.m_bTriggerFreespin == true then
                delayTime = 2.8
            end
        end
        performWithDelay(
            self,
            function()
                if self:getCurrSpinMode() ~= RESPIN_MODE then
                    gLobalSoundManager:resumeBgMusic()
                else
                    self:clearCurMusicBg()
                end
                _effectData.p_isPlay = true
                self:playGameEffect()
            end,
            delayTime
        )
    end
end

--jackpot 弹板
function CodeGameScreenFortuneCatsMachine:showJackpotWin(index, coins, func)
    local jackPotWinView = util_createView("CodeFortuneCatsSrc.FortuneCatsJackPotWin")
    jackPotWinView:initViewData(index, coins, func)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView, ViewZorder.ZORDER_UI - 1)
end

--收集不触发效果可以快点
function CodeGameScreenFortuneCatsMachine:IsCanClickSpin()
    local isSpin = true
    for i = 1, #self.m_gameEffects do
        local effectData = self.m_gameEffects[i]
        local effectType = effectData.p_effectType
        if effectType == GameEffect.EFFECT_FREE_SPIN then
            isSpin = false
        end
    end
    return isSpin
end

-- 收集动画
function CodeGameScreenFortuneCatsMachine:collectSymbolIconFly(effectData)
    local flyTime = 0.5
    local actionframeTimes = 1
    local FlyNum = 0
    local TotalAddNum = 0
    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_collect_fly.mp3")
    local endPos = self.m_collectView:getCollectPos()
    self.m_respinView:removeAllSlotsNodeMark()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local reelsIndex = self:getPosReelIdx(iRow, iCol)
            local isHave, num = self:getSymbolIcon(reelsIndex)
            TotalAddNum = TotalAddNum + num
            if isHave then
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    -- 对应位置创建 jackpot 图标
                    local newCorn = self:creatMarker(num)
                    newCorn:runCsbAction("animation0", false)
                    newCorn:setScale(self.m_machineRootScale)
                    self:addChild(newCorn, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                    local pos = cc.p(util_getConvertNodePos(node.m_icon, newCorn))
                    newCorn:setPosition(pos)
                    --移除小块内的jackpot 图标
                    if node.m_icon then
                        node.m_icon:stopAllActions()
                        node.m_icon:removeFromParent()
                        node.m_icon = nil
                    end
                    local actionList = {}
                    actionList[#actionList + 1] = cc.DelayTime:create(actionframeTimes)
                    actionList[#actionList + 1] = cc.MoveTo:create(10 / 30, cc.p(endPos.x, endPos.y))
                    actionList[#actionList + 1] =
                        cc.CallFunc:create(
                        function()
                            newCorn:removeFromParent()
                        end
                    )
                    local sq = cc.Sequence:create(actionList)
                    newCorn:runAction(sq)

                    local particle = self:createFlyPart()
                    if particle then
                        particle:setPosition(pos)
                        particle:setVisible(false)
                        self:addChild(particle, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                        local actionList2 = {}
                        actionList2[#actionList2 + 1] = cc.DelayTime:create(actionframeTimes)
                        actionList2[#actionList2 + 1] =
                            cc.CallFunc:create(
                            function()
                                particle:setVisible(true)
                                particle:resetSystem()
                            end
                        )
                        actionList2[#actionList2 + 1] = cc.MoveTo:create(10 / 30, cc.p(endPos.x, endPos.y))
                        actionList2[#actionList2 + 1] =
                            cc.CallFunc:create(
                            function()
                                particle:removeFromParent()
                            end
                        )
                        local particleSq = cc.Sequence:create(actionList2)
                        particle:runAction(particleSq)
                    end
                    FlyNum = FlyNum + 1
                end
            end
        end
    end

    if FlyNum and FlyNum > 0 then
        if self:IsCanClickSpin() then
            scheduler.performWithDelayGlobal(
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                0.5,
                self:getModuleName()
            )
        else
            scheduler.performWithDelayGlobal(
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                1.3,
                self:getModuleName()
            )
        end

        scheduler.performWithDelayGlobal(
            function()
                --gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_collect_coin_fankuaii.mp3")
                self:updateCollect(TotalAddNum, 0)
            end,
            1.3,
            self:getModuleName()
        )
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFortuneCatsMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenFortuneCatsMachine:initCollectInfo(spinData, lastBetId, isTriggerCollect)
    local scoreTotal = FortuneCatsShopData:getShopCollectCoins()
    if scoreTotal then
        self.m_collectView:initTotalNum(scoreTotal)
    end
end

--[[
    @desc: 收集效果 金币增长
    --@_num:收集数量
	--@_collect: 收集类型 0 普通收集 1 小轮盘收集
]]
function CodeGameScreenFortuneCatsMachine:updateCollect(_num, _collect)
    self.m_collectView:updateCollect(_num, _collect)
end

function CodeGameScreenFortuneCatsMachine:getSymbolIcon(reelsIndex)
    local isHave = false
    local num = 0
    if self.m_runSpinResultData.p_selfMakeData then
        local posTable = self.m_runSpinResultData.p_selfMakeData.scorePositions
        if posTable and #posTable >= 0 then
            for k, v in pairs(posTable) do
                local index = tonumber(k)
                if reelsIndex == index then
                    isHave = true
                    num = tonumber(v)
                end
            end
        end
    end
    return isHave, num
end

--绿猫角标
function CodeGameScreenFortuneCatsMachine:creatGreenMarker()
    local item = util_createAnimation("FortuneCats_lvjinbi.csb")
    -- node:playAction("start",true)
    return item
end

--角标
function CodeGameScreenFortuneCatsMachine:creatMarker(_num)
    local item = util_createView("CodeFortuneCatsSrc.FortuneCatsCollectItem", _num)
    return item
end

--收集粒子效果
function CodeGameScreenFortuneCatsMachine:createFlyPart()
    local par = cc.ParticleSystemQuad:create("particle/FortuneCats_TWlizi1.plist")
    return par
end

--添加收集角标
function CodeGameScreenFortuneCatsMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self, node, symbolType, row, col, isLastSymbol)
end

function CodeGameScreenFortuneCatsMachine:updateReelGridNode(node)
    if node:isLastSymbol() then
        -- print("CodeGameScreenFortuneCatsMachine == symbolType" .. node.p_symbolType)
        node:changeImage()
        if self.m_outOnlin then
            --第一次进游戏 不显示收集的图标
            return
        end
        self:addItemToSymbol(node, node.p_rowIndex, node.p_cloumnIndex)
    end
end

--在信号块上添加收集图标
function CodeGameScreenFortuneCatsMachine:addItemToSymbol(node, irow, icol)
    local reelsIndex = self:getPosReelIdx(irow, icol)
    local isHave, num = self:getSymbolIcon(reelsIndex)
    if isHave then
        if node.m_icon == nil then
            node.m_icon = self:creatMarker(num)
            node.m_icon:setPosition(cc.p(80, -42))
            node:addChild(node.m_icon, 2)
        end
    end
end

-- 创建单个滚动小块轮盘
function CodeGameScreenFortuneCatsMachine:createSmallReels()
    local endTypes = {}
    -- local randomTypes = {0, 1, 2, 3, 4, 5, 6, 90, 91, 92, 94} 去掉绿猫
    local randomTypes = {0, 1, 2, 3, 4, 5, 6, 90, 91, 94}

    self.m_respinView = util_createView("CodeFortuneCatsSrc.FortuneCatsRespinView", "CodeFortuneCatsSrc.FortuneCatsRespinNode", self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 100)
    self:findChild("reel_kuang"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 99)
    -- self.m_respinView:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 100)
    --构造盘面数据
    local SmallReelsNodeInfo = self:createSmallReelsNodeInfo()

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        SmallReelsNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            -- self:runNextReSpinReel()
        end
    )
    -- self.m_respinView:changeImage()
    --显示单独滚轮盘信息，并且隐藏整个滚轮盘
    self:showSingleReelSlotsNodeVisible(true)
end

-- 是否显示单独滚的小块轮盘
function CodeGameScreenFortuneCatsMachine:showSingleReelSlotsNodeVisible(states)
    local zorder = self.m_clipParent:getLocalZOrder()
    if states then
        --隐藏 盘面信息
        self:setReelSlotsNodeVisible(false)
        self.m_respinView:setVisible(true)
        -- self.m_respinView:shopPos()
    else
        self:setReelSlotsNodeVisible(true)
        self.m_respinView:setVisible(false)
        self.m_respinView:playFreespinCatIdle()
        -- self.m_respinView:shopPos()
    end
end

--隐藏盘面信息
function CodeGameScreenFortuneCatsMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(status)
                -- local slotParent = node:getParent()
                -- local posWorld = slotParent:convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
                -- print("轮盘 " .. iCol .."列" .. iRow .. "行" .."posWorld.x ===" .. posWorld.x  .. "posWorld.y ==="  .. posWorld.y)
            end
        end
    end
end

----构造小块单独滚 所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenFortuneCatsMachine:createSmallReelsNodeInfo()
    local smallNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            -- 处理第一次进入轮盘时的情况
            if symbolType == nil then
                symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, TAG_SYMBOL_TYPE.SYMBOL_SCORE_3)
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
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
            pos.y = self:getSymbolPosYByRow(iRow, pos.y)

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
            smallNodeInfo[#smallNodeInfo + 1] = symbolNodeInfo
        end
    end
    return smallNodeInfo
end

function CodeGameScreenFortuneCatsMachine:isTriggerFreespinOrInFreespin()
    local isIn = false

    local features = self.m_runSpinResultData.p_features

    if features then
        for k, v in pairs(features) do
            if v == 1 then
                isIn = true
            end
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        isIn = true
    end

    return isIn
end

-- 点击快速停止reel
function CodeGameScreenFortuneCatsMachine:quicklyStopReel()
    print("quicklyStopReel  调用了快停")

    self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。

    if self.m_respinView then
        self.m_respinView:quicklyStop()
    end
end

---快停
function CodeGameScreenFortuneCatsMachine:quicklyStop()
    self:quicklyStopReel()
end

-- 开始刷帧
function CodeGameScreenFortuneCatsMachine:registerReelSchedule()
    self.m_respinView:startMove()
    if self.m_firstBegin == false then
        self.m_firstBegin = true
        self:showFastRunEff(1, 3, true) --第一个格子也参与快滚
    end
    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:onUpdate(
            function(delayTime)
                self:reelSchedulerHanlder(delayTime)
            end
        )
    end
end

function CodeGameScreenFortuneCatsMachine:reelSchedulerHanlder(delayTime)
    if (self:getGameSpinStage() ~= GAME_MODE_ONE_RUN and self:getGameSpinStage() ~= QUICK_RUN) or self:checkGameRunPause() then
        return
    end
    -- 真实网络数据返回
    if self.m_isWaitingNetworkData == false then
        if self.m_reelScheduleDelegate ~= nil then
            self.m_reelScheduleDelegate:unscheduleUpdate()
        end
        -- print("根据网络数据手动刷新小块")
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                    if self:isLock(iCol, iRow) and symbolType == self.SYMBOL_ReSpin_CAT then
                        targSp:runAnim("idle2")
                    else
                        targSp:runIdleAnim()
                    end
                    -- targSp:runIdleAnim()
                    targSp:resetReelStatus()
                    targSp:changeImage()
                    local order = self:getBounsScatterDataZorder(symbolType) + 10 * iCol - iRow
                    targSp.p_showOrder = order
                    targSp:setLocalZOrder(order)
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = iRow, iY = iCol}
                    targSp.m_bInLine = true
                    targSp:setLinePos(linePos)
                    targSp:setVisible(false)
                    if self:isCatSymbolType(symbolType) then
                        local slotParent = targSp:getParent()
                        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                        targSp:removeFromParent()
                        targSp:resetReelStatus()
                        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + targSp.p_showOrder, targSp:getTag())
                        targSp:setPosition(cc.p(pos.x, pos.y))
                    end
                    if self.m_outOnlin == false then
                        self:addItemToSymbol(targSp, iRow, iCol)
                    end
                end
            end
        end
        self:stopSmallReelsRun()
        self.m_reelDownAddTime = 0
    end
end

--接收到数据开始停止滚动
function CodeGameScreenFortuneCatsMachine:stopSmallReelsRun()
    local storedNodeInfo = {}
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    self.m_runLong = true
end

---滚轮停止复用respin停止自定义事件
function CodeGameScreenFortuneCatsMachine:reSpinReelDown(addNode)
    self:slotReelDown()
    self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
end

-- 老虎机滚动结束调用
function CodeGameScreenFortuneCatsMachine:slotReelDown()
    self:setGameSpinStage(STOP_RUN)
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    -- 还原reel parent 信息
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local posx, posy = slotParent:getPosition()
        slotParent:setPosition(0, 0) -- 还原位置信息

        local childs = slotParent:getChildren()
        --        printInfo("xcyy  剩余 child count %d", #childs)

        local lastType = nil
        local preRow = 0
        local maxLastNodePosY = nil
        local minLastNodePosY = nil

        parentData:reset()
    end

    -- 判断是否是长条模式，处理长条只显示一部分的遮罩问题
    -- self:operaBigSymbolMask(true)

    self:reelDownNotifyChangeSpinStatus()

    self:delaySlotReelDown()

    self:stopAllActions()

    local jackpotCatNum = self:getCatNum(3, 1)
    if jackpotCatNum > self.m_jackpotCatNum then
        self.m_jackpotCatNum = jackpotCatNum
        self.m_jackPotBar:playAddCatEffect(jackpotCatNum)
    end
    --播放猫头动画
    if jackpotCatNum >= 4 and self.m_addRepin == false and not self:isHaveNewRespinSymbol() then
        self.m_jackPotBar:playEndIdle(jackpotCatNum)
    end

    if self.m_reelRunAnima ~= nil then
        for i = 1, #self.m_reelRunAnima do
            local reelEffectNode = self.m_reelRunAnima[i]
            if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
                reelEffectNode[1]:runAction(cc.Hide:create())
            end
        end
    end
    
    self:showSingleReelSlotsNodeVisible(false)

    self:reelDownNotifyPlayGameEffect()

end

function CodeGameScreenFortuneCatsMachine:beginReel()
    self:resetReelDataAfterReel()

    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local reelDatas = nil

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(0, parentData.cloumnIndex)
        else
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        end

        parentData.reelDatas = reelDatas

        --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
        if parentData.beginReelIndex == nil then
            parentData.beginReelIndex = util_random(1, #reelDatas)
        end

        self:checkReelIndexReason(parentData)

        parentData.isDone = false
        parentData.isResActionDone = false
        parentData.isReeling = false
        if self.getMoveSpeedBySpinMode then
            parentData.moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
        else
            parentData.moveSpeed = self.m_configData.p_reelMoveSpeed
        end
        -- 判断处理是否每列需要等待时间 开始滚动
        parentData.isReeling = true
        self:registerReelSchedule()
    end
end

--获取当前落地前的所有cat的数量
function CodeGameScreenFortuneCatsMachine:getCatNum(icol, irow)
    local catNum = 0
    -- 固定的先算上
    if #self.m_lockFramePos > 0 then
        catNum = #self.m_lockFramePos
    end
    local function addCatNum(_icol, _irow, symbolType)
        if self:isCatSymbolType(symbolType) then
            if self:isLock(_icol, _irow) == false then
                catNum = catNum + 1
            end
        end
    end
    if irow == 3 then
        for i = 1, icol do
            local symbolType = self.m_stcValidSymbolMatrix[irow][i]
            addCatNum(i, irow, symbolType)
        end
    elseif irow == 2 then
        for i = 1, self.m_iReelColumnNum do
            local symbolType = self.m_stcValidSymbolMatrix[3][i]
            addCatNum(i, 3, symbolType)
        end
        for i = 1, icol do
            local symbolType = self.m_stcValidSymbolMatrix[irow][i]
            addCatNum(i, irow, symbolType)
        end
    elseif irow == 1 then
        for iRow = self.m_iReelRowNum, 2, -1 do
            for iCol = 1, self.m_iReelColumnNum do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                addCatNum(iCol, iRow, symbolType)
            end
        end
        for i = 1, icol do
            local symbolType = self.m_stcValidSymbolMatrix[irow][i]
            addCatNum(i, irow, symbolType)
        end
    end
    return catNum
end

--按照列和行 获取位置
function CodeGameScreenFortuneCatsMachine:getPosReelIdx(iRow, iCol)
    local index = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

--单个滚动停止回调
function CodeGameScreenFortuneCatsMachine:slotLocalOneReelDown(icol, irow)
    --jackpot 效果
    local jackpotCatNum = self:getCatNum(icol, irow)
    if jackpotCatNum > self.m_jackpotCatNum then
        self.m_jackpotCatNum = jackpotCatNum
        self.m_jackPotBar:playAddCatEffect(jackpotCatNum)
    end
    --快滚
    self:showFastRunEff(icol, irow, false)

    -- 播放落地动画
    local symbolType = self.m_stcValidSymbolMatrix[irow][icol]
    if self:isCatSymbolType(symbolType) then
        local node = self:getFixSymbolSmallReels(irow, icol)
        if node then
            local slotNode = node:getLastNode()
            if slotNode then
                slotNode:runAnim("buling", false)
            end
        end

        local soundPath = "FortuneCatsSounds/sound_FortuneCats_scatter_reel_stop.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( icol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end
    
    if self.playQuickStopBulingSymbolSound then
        self:playQuickStopBulingSymbolSound(icol)
    end
    
end

function CodeGameScreenFortuneCatsMachine:showFastRunEff(icol, irow, isbegin)
    --快滚
    local nextCol = icol
    local nextRow = irow
    if icol == 1 and irow == 3 and isbegin == true then
        nextCol = 1
        nextRow = 3
    elseif icol == 3 and irow > 1 then
        nextCol = 1
        nextRow = irow - 1
    else
        nextCol = icol + 1
    end

    if self:getNextReelIsLongRun(icol, irow) and self:getGameSpinStage() ~= QUICK_RUN then
        local nextCol2, nextRow2 = self:getNextFastRunColAndRow(nextCol, nextRow)
        -- print("nextCol =============" .. nextCol .. "nextRow ========" ..nextRow)
        -- print("nextCol2 =============" .. nextCol2 .. "nextRow2 ========" ..nextRow2)
        if nextCol2 <= self.m_iReelColumnNum and nextRow2 >= 1 then
            self.m_respinView:setRunRespinNodeLong(19)
            self:creatReelRunAnimation(nextCol2, nextRow2)
        end
    end
    if isbegin == false then
        if self.m_reelRunAnima ~= nil then
            local index = (irow - 1) * 3 + (3 - icol + 1)
            local reelEffectNode = self.m_reelRunAnima[index]
            if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
                reelEffectNode[1]:runAction(cc.Hide:create())
            end
        end
    end
end

--因为有的图标已被锁住 不用播放快滚，则下一个直接播放
function CodeGameScreenFortuneCatsMachine:getNextFastRunColAndRow(iCol, iRow)
    if self:isLock(iCol, iRow) then
        local firstCol = true --只有第一次从下一列开始 其他的从头开始
        local nextCol = true
        for row = iRow, 1, -1 do
            if firstCol == true then
                nextCol = iCol
                firstCol = false
            else
                nextCol = 1
            end
            for col = nextCol, self.m_iReelColumnNum do
                if self:isLock(col, row) == false then
                    return col, row
                end
            end
        end
        return 0, 0
    else
        return iCol, iRow
    end
end
--是否是cat图标
function CodeGameScreenFortuneCatsMachine:isCatSymbolType(_type)
    if _type == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _type == TAG_SYMBOL_TYPE.SYMBOL_WILD or _type == TAG_SYMBOL_TYPE.SYMBOL_BONUS or _type == self.SYMBOL_ReSpin_CAT then
        return true
    end
    return false
end

--获取当前掉落前的所有cat的数量
function CodeGameScreenFortuneCatsMachine:getScatterCatNum(icol, irow)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local catNum = 0
    if irow == 2 then
        for iCol = 1, self.m_iReelColumnNum do
            local symbolType = self.m_stcValidSymbolMatrix[3][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                catNum = catNum + 1
            end
        end
        for i = 1, icol do
            local symbolType = self.m_stcValidSymbolMatrix[irow][i]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                catNum = catNum + 1
            end
        end
    elseif irow == 1 then
        for iRow = self.m_iReelRowNum, 2, -1 do
            for iCol = 1, self.m_iReelColumnNum do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    catNum = catNum + 1
                end
            end
        end
        for i = 1, icol do
            local symbolType = self.m_stcValidSymbolMatrix[irow][i]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                catNum = catNum + 1
            end
        end
    end
    if catNum >= 2 then
        return true
    end
    return false
end

--本列停止 判断下列是否有长滚
function CodeGameScreenFortuneCatsMachine:getNextReelIsLongRun(icol, irow)
    if icol <= self.m_iReelColumnNum and irow >= 1 then
        --cat数量大于4个后显示
        local jackpotCatNum = self:getCatNum(icol, irow)
        if jackpotCatNum >= 4 then
            return true
        end
    --触发freespin 固定格子显示5，8，9 只在之前的格子做判断
    -- if ((irow == 2 and icol == 1) or (irow == 2 and icol == 3) or (irow == 1 and icol == 2)) then
    --     if self:getScatterCatNum(icol, irow) then
    --         return true
    --     end
    -- end
    end
    return false
end

--添加快滚框
function CodeGameScreenFortuneCatsMachine:creatReelRunAnimation(icol, irow)
    for i = 1, #self.m_lockFramePos do
        local pos = self.m_lockFramePos[i]
        if pos.iCol == icol and irow == pos.iRow then
            return
        end
    end
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end
    local index = (irow - 1) * 3 + (3 - icol + 1)
    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[index] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col, irow)
    else
        local reelObj = self.m_reelRunAnima[index]
        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    self:setLongAnimaInfo(reelEffectNode, icol, irow)

    reelEffectNode:setVisible(true)
    util_setCascadeOpacityEnabledRescursion(reelEffectNode, true)
    reelEffectNode:setOpacity(0)
    util_playFadeInAction(reelEffectNode, 0.1)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--单独创建
function CodeGameScreenFortuneCatsMachine:createReelEffect(icol, irow)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    local index = (irow - 1) * 3 + (3 - icol + 1)
    reelEffectNode:retain()
    effectAct:retain()
    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[index] = {reelEffectNode, effectAct}
    reelEffectNode:setVisible(false)
    return reelEffectNode, effectAct
end

function CodeGameScreenFortuneCatsMachine:setLongAnimaInfo(reelEffectNode, icol, irow)
    local worldPos, reelHeight, reelWidth = self:getSmallReelPos(icol, irow)
    local pos = self.m_slotEffectLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    pos.y = self:getSymbolPosYByRow(irow, pos.y)
    reelEffectNode:setPosition(cc.p(pos.x, pos.y))
end

function CodeGameScreenFortuneCatsMachine:getSmallReelPos(icol, irow)
    local index = (irow - 1) * 3 + (3 - icol + 1)
    local reelNode = self:findChild("reel_" .. (index))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

-- 创建一个reels上层的特殊显示信号信号
function CodeGameScreenFortuneCatsMachine:createOneActionSymbol(endNode)
end

function CodeGameScreenFortuneCatsMachine:getFixSymbolSmallReels(iRow, iCol)
    local node = nil
    if self.m_respinView then
        for i = 1, #self.m_respinView.m_respinNodes do
            local respinNode = self.m_respinView.m_respinNodes[i]
            if respinNode.p_colIndex == iCol then
                if respinNode.p_rowIndex == iRow then
                    return respinNode
                end
            end
        end
    end
    return node
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFortuneCatsMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_bSlotRunning = true
    --显示单独滚轮盘信息，并且隐藏整个滚轮盘
    self.m_outOnlin = false
    self.m_scatterDownIndex = 1
    self.m_scatterDownNum = 1
    self:showSingleReelSlotsNodeVisible(true)
    self:setLockEffectVisible(true)
    if self.b_closeTips == false then
        self.b_closeTips = true
        self:removeTips()
    end
    if self.m_addRepin == false then
        self.m_jackpotCatNum = 0
        self.m_RespinSymbol = {}
        if self.m_jackPotBar then
            self.m_jackPotBar:playIdle()
        end
        self.m_lockFramePos = {}
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:addLockFramePos(1, 3)
            self:addLockFramePos(2, 2)
            self:addLockFramePos(3, 1)
        end
    end
    if self.m_superMul then
        self.m_superMul:hide(
            function()
                self.m_superMul:setVisible(false)
            end
        )
    end
    self.m_bReSpinOver = false
    self.m_bsuperFreeOver = false
    self.m_firstBegin = false
    self.m_bJackpotWin = false
    self.m_bTriggerFreespin = false 
    return false -- 用作延时点击spin调用
end

function CodeGameScreenFortuneCatsMachine:addLockFramePos(_col, _row)
    if self.m_lockFramePos == nil then
        self.m_lockFramePos = {}
    end
    local pos = {}
    pos.iCol = _col
    pos.iRow = _row
    table.insert(self.m_lockFramePos, pos)
end

function CodeGameScreenFortuneCatsMachine:normalSpinBtnCall()
    BaseSlotoManiaMachine.normalSpinBtnCall(self)

    if self.m_winSoundsId then
        --gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
end

function CodeGameScreenFortuneCatsMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if (self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE) then
        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()
        --处理选择freespin wild 下落效果
        if self.m_bTriggerFreespin == true then
            self.m_bTriggerFreespin = false
            delayTime = 0.5
        end
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                --gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
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

    self.m_bSlotRunning = false
    if self.m_bShopOpen then
        return
    end
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenFortuneCatsMachine:getNodePosByColAndRow(col, row)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

--背景切换
function CodeGameScreenFortuneCatsMachine:changeNormalAndFreespinBg(_type)
    if _type == 3 then -- normal ->freespin
        self.m_gameBg:runCsbAction("normal_to_freespin", false)
    elseif _type == 4 then -- freespin -> normal
        self.m_gameBg:runCsbAction("freespin_to_normal", false)
    elseif _type == 1 then -- normal
        self.m_gameBg:runCsbAction("idle1", false)
    elseif _type == 2 then -- freespin
        self.m_gameBg:runCsbAction("idle2", false)
    end
end

--设置bonus scatter 层级
function CodeGameScreenFortuneCatsMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or symbolType == self.SYMBOL_ReSpin_CAT then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    else
        order = REEL_SYMBOL_ORDER.REEL_ORDER_1
    end
    return order
end

----
--- 处理spin 成功消息
--
function CodeGameScreenFortuneCatsMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or spinData.action == "SPECIAL" then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        

        if spinData.action == "SPECIAL" then
            if spinData.result then
                self.m_runSpinResultData.p_features = spinData.result.features
                if spinData.result.freespin ~= nil then
                    self.m_runSpinResultData.p_freeSpinsTotalCount = spinData.result.freespin.freeSpinsTotalCount -- fs 总数量
                    self.m_runSpinResultData.p_freeSpinsLeftCount = spinData.result.freespin.freeSpinsLeftCount -- fs 剩余次数
                    self.m_runSpinResultData.p_fsMultiplier = spinData.result.freespin.fsMultiplier -- fs 当前轮数的倍数
                    self.m_runSpinResultData.p_freeSpinNewCount = spinData.result.freespin.freeSpinNewCount -- fs 增加次数
                    self.m_runSpinResultData.p_fsWinCoins = spinData.result.freespin.fsWinCoins -- fs 累计赢钱数量
                    self.m_runSpinResultData.p_freeSpinAddList = spinData.result.freespin.freeSpinAddList
                    self.m_runSpinResultData.p_newTrigger = spinData.result.freespin.newTrigger
                    self.m_runSpinResultData.p_fsExtraData = spinData.result.freespin.extra
                end
                self.m_runSpinResultData.p_selfMakeData = spinData.result.selfData
            end
            -- 网络请求状态重置
            FortuneCatsShopData:setNetState(false)
            -- 商店兑换后更新商店数据和UI
            self:exchangeSymbol()
        end

        local istrue = false
        if self.m_runSpinResultData.p_features and #self.m_runSpinResultData.p_features > 0 then
            istrue = true
        end

        if spinData.action == "SPIN" then
            self:updateNetWorkData()
            --刷新
            local selfdata = self.m_runSpinResultData.p_selfMakeData
            if selfdata and selfdata.beardData then
                local data = selfdata.beardData
                FortuneCatsShopData:parseSpinResultData(data)
                FortuneCatsShopData:parseExchangeData(data)
            end
        end
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end
end


-- 商店兑换后更新商店数据和UI
function CodeGameScreenFortuneCatsMachine:exchangeSymbol()
    local features = self.m_runSpinResultData.p_features
    if features and #features == 2 and (features[2] == SLOTO_FEATURE.FEATURE_FREESPIN) then
        FortuneCatsShopData:setFreeSpinState(true)
    end
    FortuneCatsShopData:savePagesFree()
    local data = self.m_runSpinResultData.p_selfMakeData.beardData
    FortuneCatsShopData:parseExchangeData(data)
    gLobalNoticManager:postNotification("NOTIFY_SHOP_PAGE", {exchange = true})
    self.m_collectView:updateChangeCollect(data.scoreTotal)
end

--respin出现猫的锁定框
function CodeGameScreenFortuneCatsMachine:creatLockSymbolEffect()
    local eff = util_createView("CodeFortuneCatsSrc.FortuneCatsLockSymbolEffect")
    return eff
end

function CodeGameScreenFortuneCatsMachine:checkChangeFsCount()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount ~= nil and globalData.slotRunData.freeSpinCount > 0 then
        --减少free spin 次数
        globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1
        print(" globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1")
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        globalData.userRate:pushFreeSpinCount(1)
    end
end

function CodeGameScreenFortuneCatsMachine:showAllSlotNodeRunIdle()
    self:setLockEffectVisible(false)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                if targSp.p_symbolType == self.SYMBOL_ReSpin_CAT then
                    if self:isLock(iCol, iRow) then
                        targSp:runAnim("dark2", true)
                    else
                        targSp:runAnim("dark", true)
                    end
                else
                    targSp:runAnim("dark", true)
                end
                local symbolType = targSp.p_symbolType
                local order = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE -- + self:getBounsScatterDataZorder(symbolType)
                targSp.p_showOrder = order
                targSp:setLocalZOrder(order)
            end
        end
    end
end

--显示赢钱倍数
function CodeGameScreenFortuneCatsMachine:showSuperMulLab()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.lineMul then
        if self.m_superMul == nil then
            self.m_superMul = util_createView("CodeFortuneCatsSrc.FortuneCatsSuperMul")
            self:findChild("superfreeNode"):addChild(self.m_superMul)
            if globalData.slotRunData.machineData.p_portraitFlag then
                self.m_superMul.getRotateBackScaleFlag = function(  ) return false end
            end

        end
        local num = selfdata.lineMul
        if num > 1 then
            self.m_superMul:setVisible(true)
            self.m_superMul:show(num)
        end
    end
end

function CodeGameScreenFortuneCatsMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel  then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end
    end

    
    
    self:showLineFrame()

    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            0.5
        )
    else
        if self:isHaveNewRespinSymbol() then
            performWithDelay(
                self,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                1
            )
        else
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    end

    return true
end

function CodeGameScreenFortuneCatsMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期

    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()
    if #winLines <= 0 then
        return
    end
    self:showSuperMulLab()
    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:clearFrames_Fun()
    self:showAllSlotNodeRunIdle()
    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > #winLines then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                        self:showAllFrame(winLines)
                        self:playInLineNodes()
                        showLienFrameByIndex()
                    end
                    return
                end
                self:playInLineNodesIdle()
                -- 跳过scatter bonus 触发的连线
                while true do
                    if frameIndex > #winLines then
                        break
                    end
                    -- print("showLine ... ")
                    local lineData = winLines[frameIndex]

                    if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                        if #winLines == 1 then
                            break
                        end

                        frameIndex = frameIndex + 1
                        if frameIndex > #winLines then
                            frameIndex = 1
                        end
                    else
                        break
                    end
                end
                -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
                -- 所以打上一个判断
                if frameIndex > #winLines then
                    frameIndex = 1
                end

                self:showLineFrameByIndex(winLines, frameIndex)

                frameIndex = frameIndex + 1
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showAllFrame(winLines) -- 播放全部线框

        showLienFrameByIndex()
    else
        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines, 1)
        end
    end
end

---
-- 显示所有的连线框
--
function CodeGameScreenFortuneCatsMachine:showAllFrame(winLines)
    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0

    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            -- end
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen()

                local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
                local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
                posY = self:getSymbolPosYByRow(symPosData.iX, posY) --位置重设
                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(cc.p(posX, posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenFortuneCatsMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end
        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        posY = self:getSymbolPosYByRow(symPosData.iX, posY)
        node:setPosition(cc.p(posX, posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

function CodeGameScreenFortuneCatsMachine:checkNotifyUpdateWinCoin()
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end


----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenFortuneCatsMachine:operaEffectOver(  )
    
    printInfo("run effect end")
    if self:isHaveNewRespinSymbol() then
        self:addRespinEffect()
        self:playGameEffect()
    else
        self:setGameSpinStage(IDLE)
        -- 结束动画播放
        self.m_isRunningEffect = false

        if self.checkControlerReelType and self:checkControlerReelType( ) then
            globalMachineController.m_isEffectPlaying = false
        end
        
        self.m_autoChooseRepin = self.m_chooseRepin --防止被清空
        self:playEffectNotifyNextSpinCall()

        self:playEffectNotifyChangeSpinStatus()

        if not self.m_bProduceSlots_InFreeSpin then
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, false)
        -- self:setLastWinCoin(  0) -- 重置累计的金钱。
        end
        if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self:showFreeSpinOverAds()
        end
    end
end
--判断改变freespin的状态
function CodeGameScreenFortuneCatsMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --freespin最后一次触发respin respin结束 表现freepsin over 效果
        if globalData.slotRunData.freeSpinCount == 0 and self:isHaveNewRespinSymbol() == false then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
            end
        end
    end

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
            self.m_bTriggerFreespin = true
        end
    end
end

function CodeGameScreenFortuneCatsMachine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin =
                    scheduler.performWithDelayGlobal(
                    function(delay)
                        self:normalSpinBtnCall()
                    end,
                    0.5,
                    self:getModuleName()
                )
            end
        else
            if self.m_bsuperFreeOver == false then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
        end
    end
end

function CodeGameScreenFortuneCatsMachine:triggerFreeSpinOverCallFun()

    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    if self.postFreeSpinOverTriggerBigWIn then
        self:postFreeSpinOverTriggerBigWIn( _coins) 
    end
    
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
    -- print("222self.m_bProduceSlots_InFreeSpin = false")
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:hideFreeSpinBar()
    ---super不播放
    if self.m_bsuperFreeOver == false then
        self:resetMusicBg()
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function CodeGameScreenFortuneCatsMachine:showEffect_RespinOver(effectData)
    -- self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
    -- self:clearCurMusicBg()
    -- if self.m_bProduceSlots_InFreeSpin then
    --     local addCoin = self.m_serverWinCoins
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    -- else
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    -- end
    self:triggerRespinComplete()
    self:resetReSpinMode()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            local spinEffect = GameEffectData.new()
            spinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            spinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = spinEffect
        end
    end

    self.m_bReSpinOver = true
    self.m_iReSpinScore = 0
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    if self.m_jackpotCatNum >= 4 or hasFreepinFeature then
        self:resetMusicBg()
        effectData.p_isPlay = true
        self:playGameEffect()
    else
        self:resetMusicBg()
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_respin_over.mp3")
        scheduler.performWithDelayGlobal(
            function(delay)
                self:resetMusicBg()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            0.5,
            self:getModuleName()
        )
    end

    return true
end

function CodeGameScreenFortuneCatsMachine:callSpinBtn()

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

    self:notifyClearBottomWinCoin()
    
    local betCoin = self:getSpinCostCoins() or toLongNumber(0)
    local totalCoin = globalData.userRunData.coinNum or 1

    -- freespin时不做钱的计算
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and betCoin > totalCoin then
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
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
            self:callSpinTakeOffBetCoin(betCoin)

        else
            self.m_spinNextLevel = globalData.userRunData.levelNum
            self.m_spinNextProVal = globalData.userRunData.currLevelExper
            self.m_spinIsUpgrade = false
        end
       

        --统计quest spin次数
        self:staticsQuestSpinData()

        --向服务器更新一次quest任务统计
        -- if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        --     gLobalQuestManager:updateTaskProcess()
        -- end

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

--freespin下的respin钱停留在win框 及frrepisn 停留 base下的repsin 
function CodeGameScreenFortuneCatsMachine:notifyClearBottomWinCoin()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE  then
        if self.m_bProduceSlots_InFreeSpin == true then
            local isClearWin = false
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN,isClearWin)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
        end
    else
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, isClearWin)
    end
end

--superFreespin 使用平均Bet
function CodeGameScreenFortuneCatsMachine:BaseMania_updateJackpotScore(index, totalBet)
    if not totalBet then
        totalBet = globalData.slotRunData:getCurTotalBet()
    end

    if self.m_bInSuperFreeSpin and self.m_avgBet ~= 0 then
        totalBet = self.m_avgBet
    end

    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] then
        return 0
    end
    local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index], true, totalBet)
    return totalScore
end


--服务器没有基础值初始化一份
function CodeGameScreenFortuneCatsMachine:updateJackpotList()
    self.m_jackpotList = {}
    local  totalBet = globalData.slotRunData:getCurTotalBet()
    if self.m_bInSuperFreeSpin and self.m_avgBet ~= 0 then
        totalBet = self.m_avgBet
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools ~= nil and #jackpotPools > 0 then
        for index ,poolData in pairs(jackpotPools) do 
            local totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData,false,totalBet)
            self.m_jackpotList[index]=totalScore-baseScore
        end
    end
end

function CodeGameScreenFortuneCatsMachine:checkTriggerINFreeSpin( )
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
    if hasFreepinFeature == false and 
            self.m_initSpinData.p_freeSpinsTotalCount ~= nil and 
            self.m_initSpinData.p_freeSpinsTotalCount > 0 and 
            (self.m_initSpinData.p_freeSpinsLeftCount > 0 or 
                (hasReSpinFeature == true  or hasBonusFeature == true)) then
        -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
        isInFs = true
    end

    if isInFs == true then
    
        self:changeFreeSpinReelData()
        
        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
        
        self:setCurrSpinMode( FREE_SPIN_MODE)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 and hasReSpinFeature == false then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff=true
    end

    return isPlayGameEff
end
return CodeGameScreenFortuneCatsMachine
