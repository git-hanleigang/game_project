---
-- island li
-- 2019年1月26日
-- CodeGameScreenThorMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"

local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenThorMachine = class("CodeGameScreenThorMachine", BaseNewReelMachine)

--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136

CodeGameScreenThorMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenThorMachine.SYMBOL_BONUS_X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenThorMachine.SYMBOL_BONUS_Y = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenThorMachine.SYMBOL_BONUS_Z = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenThorMachine.SYMBOL_WILD_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 100 --乘倍wild

CodeGameScreenThorMachine.SYMBOL_BONUS_X_BG = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 200
CodeGameScreenThorMachine.SYMBOL_BONUS_Y_BG = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 201
CodeGameScreenThorMachine.SYMBOL_BONUS_Z_BG = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 202

CodeGameScreenThorMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集BONUS
CodeGameScreenThorMachine.CHANGE_REEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 改变轮盘行数
CodeGameScreenThorMachine.ADD_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --随机掉落Wild
CodeGameScreenThorMachine.CHANGE_WILD_2_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- 变成2倍Wild
CodeGameScreenThorMachine.COLLECT_BONUS_ADDSPIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 -- 添加freespin次数

-- 构造函数
function CodeGameScreenThorMachine:ctor()
    BaseNewReelMachine.ctor(self)
    self.m_isOutLine = true
    self.m_iReelMinRow = 3 --最小行数
    self.m_iReelMaxRow = 6 --最大行数
    self.m_betIndex = -1 -- 当前bet id
    self.m_betData = {} -- 不同bet对应不同的收集进度
    self.m_bInBonus = false
    self.m_moveWild = {}
    self.m_playingDark = false --base下背景是否压暗
    self.m_iPlayEffectIndex = -1 --正在播放的轮盘特效
    self.m_towerSoundId = nil
    self.m_isTriggerFreeSpin = false
    self.m_iColletctList = {} -- 收集类型 及数量
    self.m_iNewReelRowNum = self.m_iReelMinRow
    self.m_change2wildEffectList = {}
    self:initGame()
end

function CodeGameScreenThorMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("ThorConfig.csv", "LevelThorConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenThorMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Thor"
end

function CodeGameScreenThorMachine:initUI()
    self.m_reelRunSound = "ThorSounds/sound_Thor_reel_run.mp3"
    self:initFreeSpinBar()
    self:createThorTower()

    self:changeGameBG(0)
    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if self.m_bIsBigWin then
                return
            end

            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 1
            local soundTime = 2
            if winRate <= 1 then
                soundIndex = 1
                soundTime = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 1.5
            elseif winRate > 3 then
                soundTime = 2
                soundIndex = 3
            end
            local soundName = "ThorSounds/sound_Thor_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenThorMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("ThorSounds/sound_Thor_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    self:resetMusicBg()
                    self:setMinMusicBGVolume()
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end
--小块
function CodeGameScreenThorMachine:getBaseReelGridNode()
    return "ThorSrc.ThorSlotsNode"
end
function CodeGameScreenThorMachine:initFreeSpinBar()
    local node_bar = self:findChild("freespin")
    self.m_baseFreeSpinBar = util_createView("ThorSrc.ThorFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end

function CodeGameScreenThorMachine:createThorTower()
    self.m_TowerSpine = {}

    self.m_GreenTower = util_createAnimation("Socre_Thor_ta_lv.csb")
    self:findChild("Node_lvta"):addChild(self.m_GreenTower)
    self:playTowerEffect(self.m_GreenTower, "idleframe", true)
    self.m_TowerSpine[#self.m_TowerSpine + 1] = self.m_GreenTower

    self.m_RedTower = util_createAnimation("Socre_Thor_ta_hong.csb")
    self:findChild("Node_hongta"):addChild(self.m_RedTower)
    self:playTowerEffect(self.m_RedTower, "idleframe", true)
    self.m_TowerSpine[#self.m_TowerSpine + 1] = self.m_RedTower

    self.m_BlueTower = util_createAnimation("Socre_Thor_ta_lan.csb")
    self:findChild("Node_lanta"):addChild(self.m_BlueTower)
    self:playTowerEffect(self.m_BlueTower, "idleframe", true)
    self.m_TowerSpine[#self.m_TowerSpine + 1] = self.m_BlueTower

    self.m_maskGreen = util_createView("ThorSrc.ThorTowerMaskView", 1)
    self:findChild("lvta"):addChild(self.m_maskGreen)
    self.m_maskGreen:setVisible(false)

    self.m_maskRed = util_createView("ThorSrc.ThorTowerMaskView", 2)
    self:findChild("hongta"):addChild(self.m_maskRed)
    self.m_maskRed:setVisible(false)

    self.m_maskBlue = util_createView("ThorSrc.ThorTowerMaskView", 3)
    self:findChild("lanta"):addChild(self.m_maskBlue)
    self.m_maskBlue:setVisible(false)
end

function CodeGameScreenThorMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("BgNode"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)
    self.m_gameBg = gameBg
end

function CodeGameScreenThorMachine:scaleMainLayer()
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
    end
    self:scaleReel()
    if display.width / display.height >= 768 / 1024 then
        local mainScale = 0.65
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end

    if globalData.slotRunData.isPortrait then
        local bangHeight = util_getBangScreenHeight()
        local bottomHeight = util_getSaveAreaBottomHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bottomHeight - bangHeight)
    end
end

function CodeGameScreenThorMachine:scaleReel()
    -- local pro = display.height / display.width
    -- if pro > 2 and pro < 2.2 then
    --     self.m_machineRootScale = self.m_machineRootScale --- 0.1
    -- elseif pro >= 2.2 then
    --     self.m_machineRootScale = self.m_machineRootScale --- 0.05
    -- elseif pro <= 2 and pro >= 1.867 then
    --     self.m_machineRootScale = self.m_machineRootScale -- 0.1
    -- elseif pro <= 1.867 and pro >= 1.6 then
    --     self.m_machineRootScale = self.m_machineRootScale -- 0.2
    -- elseif pro < 1.6 and pro >= 1.5 then
    --     self.m_machineRootScale = self.m_machineRootScale -- 0.05
    -- else
    -- end
    util_csbScale(self.m_machineNode, self.m_machineRootScale)
end

--塔播放动画
function CodeGameScreenThorMachine:playTowerEffect(_tower, anctionName, isLoop, func)
    if not _tower then
        return
    end
    _tower:runCsbAction(
        anctionName,
        isLoop,
        function()
            if func then
                func()
            end
        end
    )
end

--spin播放动画
function CodeGameScreenThorMachine:playSpineEffect(_spine, anctionName, isLoop, func)
    if not _spine then
        return
    end
    util_spinePlay(_spine, anctionName, isLoop)
    -- 动画结束
    util_spineEndCallFunc(
        _spine,
        anctionName,
        function()
            if func then
                func()
            end
        end
    )
end

function CodeGameScreenThorMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    if self.m_bProduceSlots_InFreeSpin == true and (self.m_runSpinResultData.p_freeSpinsTotalCount ~= self.m_runSpinResultData.p_freeSpinsLeftCount) then
        self:initFSTower()
    else
        self:upateBetLevel()
    end
end

function CodeGameScreenThorMachine:addObservers()
    BaseNewReelMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upateBetLevel()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenThorMachine:initGameStatusData(gameData)
    if gameData.gameConfig.bets ~= nil then
        self.m_betData = gameData.gameConfig.bets
    end
    BaseNewReelMachine.initGameStatusData(self, gameData)
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenThorMachine:upateBetLevel()
    -- 不同的bet切换才刷新
    if self.m_betIndex ~= globalData.slotRunData:getCurTotalBet() then
        self.m_betIndex = globalData.slotRunData:getCurTotalBet()
        local betid = globalData.slotRunData:getCurTotalBet()
        local collectData = self.m_betData[tostring(toLongNumber(betid))]
        if collectData == nil then
            self.m_betData[tostring(toLongNumber(betid))] = {}
            collectData = self.m_betData[tostring(toLongNumber(betid))]
            collectData.collects = {}
            collectData.collects["101"] = 0
            collectData.collects["102"] = 0
            collectData.collects["103"] = 0
        end
        self:changeTowerCollect(collectData)
    end
end

function CodeGameScreenThorMachine:changeTowerCollect(collectData)
    local bonus = collectData.collects
    if not bonus then
        return
    end
    local bonusXNum = bonus["101"]
    local bonusYNum = bonus["102"]
    local bonusZNum = bonus["103"]

    local idleName = bonusXNum .. "idleframe"
    if bonusXNum == 0 then
        idleName = "idleframe"
    elseif bonusXNum == 2 then
        idleName = bonusXNum .. "idleframe2"
    end
    self:playTowerEffect(self.m_TowerSpine[1], idleName, true)

    local idleName = bonusYNum .. "idleframe"
    if bonusYNum == 0 then
        idleName = "idleframe"
    elseif bonusYNum == 2 then
        idleName = bonusYNum .. "idleframe2"
    end
    self:playTowerEffect(self.m_TowerSpine[2], idleName, true)

    local idleName = bonusZNum .. "idleframe"
    if bonusZNum == 0 then
        idleName = "idleframe"
    elseif bonusZNum == 2 then
        idleName = bonusZNum .. "idleframe2"
    end
    self:playTowerEffect(self.m_TowerSpine[3], idleName, true)
end
function CodeGameScreenThorMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    self:updateBetNetData()
end

function CodeGameScreenThorMachine:updateBetNetData()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata then
        local betid = globalData.slotRunData:getCurTotalBet()
        local collectsData = self.m_betData[tostring(toLongNumber(betid))]
        if collectsData == nil then
            self.m_betData[tostring(toLongNumber(betid))] = {}
            collectsData = self.m_betData[tostring(toLongNumber(betid))]
        end
        if selfdata.bonusCounts then
            collectsData.collects = selfdata.bonusCounts
        end
    end
end

function CodeGameScreenThorMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    if self.m_updateReelHeightID then
        scheduler.unscheduleGlobal(self.m_updateReelHeightID)
        self.m_updateReelHeightID = nil
    end
    if self.m_towerSoundId then
        gLobalSoundManager:stopAudio(self.m_towerSoundId)
        self.m_towerSoundId = nil
    end
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenThorMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS_X then
        return "Socre_Thor_Bonus_1"
    elseif symbolType == self.SYMBOL_BONUS_Y then
        return "Socre_Thor_Bonus_2"
    elseif symbolType == self.SYMBOL_BONUS_Z then
        return "Socre_Thor_Bonus_3"
    elseif symbolType == self.SYMBOL_WILD_2 then
        return "Socre_Thor_Wild_0"
    elseif symbolType == self.SYMBOL_BONUS_X_BG then
        return "Socre_Thor_Bonustuowei_lv"
    elseif symbolType == self.SYMBOL_BONUS_Y_BG then
        return "Socre_Thor_Bonustuowei_hong"
    elseif symbolType == self.SYMBOL_BONUS_Z_BG then
        return "Socre_Thor_Bonustuowei_lan"
    end

    return nil
end
---
-- 根据类型获取对应节点
--
function CodeGameScreenThorMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initMachine(self)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

function CodeGameScreenThorMachine:createBonusBg(_type)
    local name = self:getSymbolCCBNameByType(self, _type)
    local BonusBg = util_createAnimation(name .. ".csb")
    return BonusBg
end

----------------------------- 玩法处理 -----------------------------------
-- 断线重连
function CodeGameScreenThorMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            return
        else
            local freespinTrigger = self.m_runSpinResultData.p_selfMakeData.freespinTrigger
            if freespinTrigger then
                if freespinTrigger["101"] == 1 then
                    self.m_iReelRowNum = self.m_iReelMaxRow
                    self.m_iNewReelRowNum = self.m_iReelMaxRow

                    if self.changeTouchSpinLayerSize then
                        self:changeTouchSpinLayerSize()
                    end

                    self:runCsbAction("upidle", true)
                    self.m_iPlayEffectIndex = 1
                    self:setNetReelLength()
                else
                    if freespinTrigger["102"] == 1 then
                        self.m_iPlayEffectIndex = 2
                        self:playReelEffectStart()
                    else
                        if freespinTrigger["103"] == 1 then
                            self.m_iPlayEffectIndex = 3
                            self:playReelEffectStart()
                        end
                    end
                end
            end

            self:changeGameBG(1)
        end
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
    else
        self:initTowerCollect()
    end
end

function CodeGameScreenThorMachine:initFSTower()
    self:playTriggerFreeSpinTowerEffect2()
    local freespinTrigger = self.m_runSpinResultData.p_selfMakeData.freespinTrigger

    local isloopX = false
    local isloopY = false
    local isloopZ = false
    if freespinTrigger["101"] == 1 then
        isloopX = true
    end
    if freespinTrigger["102"] == 1 then
        isloopY = true
    end
    if freespinTrigger["103"] == 1 then
        isloopZ = true
    end

    if isloopX then
        self.m_maskGreen:setVisible(false)
        self:playTowerEffect(self.m_TowerSpine[1], "freespin_idleframe", isloopX)
    end

    if isloopY then
        self.m_maskRed:setVisible(false)
        self:playTowerEffect(self.m_TowerSpine[2], "freespin_idleframe", isloopY)
    end

    if isloopZ then
        self.m_maskBlue:setVisible(false)
        self:playTowerEffect(self.m_TowerSpine[3], "freespin_idleframe", isloopZ)
    end
end

function CodeGameScreenThorMachine:setNetReelLength()
    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i, self.m_iReelRowNum, true)
    end
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum
    end
    local NowHeight = self.m_iReelRowNum * self.m_SlotNodeH
    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x,
            y = rect.y,
            width = rect.width,
            height = NowHeight
        }
    )
end

function CodeGameScreenThorMachine:initTowerCollect()
    if self.m_bProduceSlots_InFreeSpin == true then
        return
    end
    local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
    if not bonus then
        return
    end
    local bonusXNum = bonus["101"]
    local bonusYNum = bonus["102"]
    local bonusZNum = bonus["103"]

    local idleName = bonusXNum .. "idleframe"
    if bonusXNum == 0 then
        idleName = "idleframe"
    elseif bonusXNum == 2 then
        idleName = bonusXNum .. "idleframe2"
    end
    self:playTowerEffect(self.m_TowerSpine[1], idleName, true)

    local idleName = bonusYNum .. "idleframe"
    if bonusYNum == 0 then
        idleName = "idleframe"
    elseif bonusYNum == 2 then
        idleName = bonusYNum .. "idleframe2"
    end
    self:playTowerEffect(self.m_TowerSpine[2], idleName, true)

    local idleName = bonusZNum .. "idleframe"
    if bonusZNum == 0 then
        idleName = "idleframe"
    elseif bonusZNum == 2 then
        idleName = bonusZNum .. "idleframe2"
    end
    self:playTowerEffect(self.m_TowerSpine[3], idleName, true)
end
---------------------------------------------------------------------------
-- 获取Bonus的触发类型
function CodeGameScreenThorMachine:calTriggerFreeSpinType()
    local num = 0
    local has_lv = false
    local has_hong = false
    local has_lan = false
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow)
            if node then
                local symbolType = node.p_symbolType
                if symbolType == self.SYMBOL_BONUS_X then
                    has_lv = true
                    num = num + 1
                elseif symbolType == self.SYMBOL_BONUS_Y then
                    has_hong = true
                    num = num + 1
                elseif symbolType == self.SYMBOL_BONUS_Z then
                    has_lan = true
                    num = num + 1
                end
            end
        end
    end
    return num, has_lv, has_hong, has_lan
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenThorMachine:showFreeSpinView(effectData)
    gLobalSoundManager:playSound("ThorSounds/sound_Thor_trigger_freespin.mp3")

    local showFreeSpinView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            -- print("触发次数 =======================" .. self.m_iFreeSpinTimes)
            globalData.slotRunData.freeSpinCount = self.m_iFreeSpinTimes
            self.m_isTriggerFreeSpin = true
            local num, has_lv, has_hong, has_lan = self:calTriggerFreeSpinType()
            local hasData = {has_lv, has_hong, has_lan}
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes, {_num = num, has = hasData})
            gLobalSoundManager:playSound("ThorSounds/sound_Thor_freespin_start_show.mp3")
            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound("ThorSounds/sound_Thor_freespin_start_idle.mp3")
                end,
                0.5
            )
            self.m_effectData = effectData
            view:setFunCall(
                function()
                    gLobalSoundManager:playSound("ThorSounds/sound_Thor_freespin_tips_hide.mp3")
                    view:runCsbAction(
                        "over",
                        false,
                        function()
                            view:removeFromParent()
                            self:playFreeSpinBonusCollect()
                        end
                    )
                end
            )
        end
    end
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        performWithDelay(
            self,
            function()
                showFreeSpinView()
            end,
            0.2
        )
    else
        scheduler.performWithDelayGlobal(
            function()
                self:showTransitionView()
                self:showMaskLayer()
                self:playTriggerFreeSpin()
                performWithDelay(
                    self,
                    function()
                        --scatter 放回滚轴
                        for iCol = 1, self.m_iReelColumnNum do
                            for iRow = 1, self.m_iReelRowNum do
                                local targSp = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                                if targSp and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                                    self:setSymbolClipToSlotReel(iCol, iRow, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                                end
                            end
                        end
                        showFreeSpinView()
                        self:changeGameBG(1)
                        self:playTriggerFreeSpinTowerEffect2()
                        if self.m_MaskLayer then
                            self.m_MaskLayer:setVisible(false)
                        end
                    end,
                    65 / 30
                )
            end,
            1.5,
            self:getModuleName()
        )
        performWithDelay(
            self,
            function()
                gLobalSoundManager:playSound("ThorSounds/sound_Thor_guochang.mp3")
            end,
            59 / 30
        )
    end
end

--freespin 开始进行
function CodeGameScreenThorMachine:playStartFreeSpin()
    local num, has_lv, has_hong, has_lan = self:calTriggerFreeSpinType()
    self:triggerFreeSpinCallFun()
    if has_lv == true then
        self.m_iReelRowNum = self.m_iReelMaxRow
        self.m_iNewReelRowNum = self.m_iReelMaxRow

        if self.changeTouchSpinLayerSize then
            self:changeTouchSpinLayerSize()
        end

        self:playBonusXTowerEffect()
        self:runCsbAction(
            "up",
            false,
            function()
                self:runCsbAction("upidle", true)
                self.m_iPlayEffectIndex = 1
                local strOver = "xuanzhuan_jieshu"
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    strOver = "xuanzhuan_jieshu2"
                end
                if self.m_effectData then
                    self.m_effectData.p_isPlay = true
                    self:playGameEffect()
                    self.m_effectData = nil
                end
                self:playTowerEffect(
                    self.m_TowerSpine[1],
                    strOver,
                    false,
                    function()
                        if self.m_towerSoundId then
                            gLobalSoundManager:stopAudio(self.m_towerSoundId)
                            self.m_towerSoundId = nil
                        end
                        self:playTowerEffect(self.m_TowerSpine[1], "freespin_idleframe", true)
                    end
                )
            end
        )
        gLobalSoundManager:playSound("ThorSounds/sound_Thor_up_reel.mp3")
        self:changeReelLength(1)
    else
        local freespinTrigger = self.m_runSpinResultData.p_selfMakeData.freespinTrigger
        if freespinTrigger then
            if freespinTrigger["102"] == 1 then
                self.m_iPlayEffectIndex = 2
                self:playReelEffectStart()
            else
                if freespinTrigger["103"] == 1 then
                    self.m_iPlayEffectIndex = 3
                    self:playReelEffectStart()
                end
            end
        end
        if self.m_effectData then
            self.m_effectData.p_isPlay = true
            self:playGameEffect()
            self.m_effectData = nil
        end
    end
end

--播放bonus 收集效果
function CodeGameScreenThorMachine:playFreeSpinBonusCollect()
    self.m_playFSAnimIndex = 1
    self.m_triggerFSType = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow)
            if node then
                local symbolType = node.p_symbolType
                if symbolType == self.SYMBOL_BONUS_X or symbolType == self.SYMBOL_BONUS_Y or symbolType == self.SYMBOL_BONUS_Z then
                    self.m_triggerFSType[#self.m_triggerFSType + 1] = node
                end
            end
        end
    end
    self:playFSCollectAnim()
end

--播放下一个收集
function CodeGameScreenThorMachine:playNextFSCollectAnim()
    self.m_playFSAnimIndex = self.m_playFSAnimIndex + 1
    self:playFSCollectAnim()
end

--飞行效果表现
function CodeGameScreenThorMachine:playFSCollectAnim()
    if self.m_playFSAnimIndex > #self.m_triggerFSType then
        scheduler.performWithDelayGlobal(
            function()
                self:playStartFreeSpin()
            end,
            45 / 30,
            self:getModuleName()
        )
        return
    end

    local pNode = self.m_triggerFSType[self.m_playFSAnimIndex]
    local endNode
    if pNode.p_symbolType == self.SYMBOL_BONUS_X then
        endNode = "NodeCollectLv"
    elseif pNode.p_symbolType == self.SYMBOL_BONUS_Y then
        endNode = "NodeCollectHong"
    elseif pNode.p_symbolType == self.SYMBOL_BONUS_Z then
        endNode = "NodeCollectLan"
    end

    local startPos = pNode:getParent():convertToWorldSpace(cc.p(pNode:getPosition()))
    local endPos = self:findChild(endNode):getParent():convertToWorldSpace(cc.p(self:findChild(endNode):getPosition()))

    -- 添加飞行轨迹
    local function collectFly()
        local flyNode = self:createBonusStone(pNode.p_symbolType)
        flyNode:setPosition(startPos.x, startPos.y)
        flyNode:setScale(self.m_machineRootScale)
        self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_collect.mp3")

        local action_time = 15 / 30
        local bezier = {}
        local action
        if pNode.p_symbolType == self.SYMBOL_BONUS_X then
            bezier[1] = cc.p(startPos.x - startPos.x / 2 - 50, startPos.y + 30)
            bezier[2] = cc.p(endPos.x - endPos.x / 3 - 30, endPos.y - 50)
            bezier[3] = endPos
            action = cc.BezierTo:create(action_time, bezier)
        elseif pNode.p_symbolType == self.SYMBOL_BONUS_Y then
            action = cc.MoveTo:create(action_time, endPos)
        elseif pNode.p_symbolType == self.SYMBOL_BONUS_Z then
            bezier[1] = cc.p(startPos.x + startPos.x / 2, startPos.y + 30)
            bezier[2] = cc.p(endPos.x + endPos.x / 3 - 30, endPos.y - 50)
            bezier[3] = endPos
            action = cc.BezierTo:create(action_time, bezier)
        end

        local scaleTo1 = cc.ScaleTo:create(action_time / 2, self.m_machineRootScale * 1.5)
        local scaleTo2 = cc.ScaleTo:create(action_time / 2, self.m_machineRootScale * 0.6)
        local spwan = cc.Spawn:create(action, cc.Sequence:create(scaleTo1, scaleTo2))
        local call_set =
            cc.CallFunc:create(
            function()
                flyNode:removeFromParent()
                gLobalSoundManager:playSound("ThorSounds/sound_Thor_collect_bonus_ground.mp3")
                -- 光柱播放动画
                self:playNextFSCollectAnim()
                self:playTriggerFreeSpinTowerEffect(pNode.p_symbolType)
            end
        )
        local seq = cc.Sequence:create({spwan, call_set})
        flyNode:runAction(seq)
    end

    scheduler.performWithDelayGlobal(
        function()
            collectFly()
        end,
        20 / 30,
        self:getModuleName()
    )
end

function CodeGameScreenThorMachine:showTransitionView()
    local effectBg = util_createAnimation("Socre_Thor_guochang_0.csb")
    self:findChild("guochangNode"):addChild(effectBg)
    effectBg:runCsbAction(
        "actionframe",
        false,
        function()
            effectBg:removeFromParent()
        end
    )
    local guochangView = util_createView("ThorSrc.ThorTransitionView")
    self:findChild("zong"):addChild(guochangView)
    guochangView:runCsbAction(
        "actionframe",
        false,
        function()
            guochangView:removeFromParent()
        end
    )
end

function CodeGameScreenThorMachine:playTriggerFreeSpinTowerEffect(_type)
    local freespinTrigger = self.m_runSpinResultData.p_selfMakeData.freespinTrigger

    local isloopX = false
    local isloopY = false
    local isloopZ = false
    if freespinTrigger["101"] == 1 then
        isloopX = true
    end
    if freespinTrigger["102"] == 1 then
        isloopY = true
    end
    if freespinTrigger["103"] == 1 then
        isloopZ = true
    end

    if isloopX and _type == self.SYMBOL_BONUS_X then
        self.m_maskGreen:setVisible(false)
        self:playTowerEffect(
            self.m_TowerSpine[1],
            "4actionframe2",
            false,
            function()
                self:playTowerEffect(self.m_TowerSpine[1], "freespin_idleframe", isloopX)
            end
        )
    end

    if isloopY and _type == self.SYMBOL_BONUS_Y then
        self.m_maskRed:setVisible(false)
        self:playTowerEffect(
            self.m_TowerSpine[2],
            "4actionframe2",
            false,
            function()
                self:playTowerEffect(self.m_TowerSpine[2], "freespin_idleframe", isloopY)
            end
        )
    end

    if isloopZ and _type == self.SYMBOL_BONUS_Z then
        self.m_maskBlue:setVisible(false)
        self:playTowerEffect(
            self.m_TowerSpine[3],
            "4actionframe2",
            false,
            function()
                self:playTowerEffect(self.m_TowerSpine[3], "freespin_idleframe", isloopZ)
            end
        )
    end
end

--触发freespin 塔添加黑色遮照
function CodeGameScreenThorMachine:playTriggerFreeSpinTowerEffect2()
    self.m_maskGreen:setVisible(true)
    self.m_maskGreen:runCsbAction("open")
    self:playTowerEffect(self.m_TowerSpine[1], "idleframe2", false)

    self.m_maskRed:setVisible(true)
    self.m_maskRed:runCsbAction("open")
    self:playTowerEffect(self.m_TowerSpine[2], "idleframe2", false)

    self.m_maskBlue:setVisible(true)
    self.m_maskBlue:runCsbAction("open")
    self:playTowerEffect(self.m_TowerSpine[3], "idleframe2", false)
end

--触发freespin 信号块表现处理
function CodeGameScreenThorMachine:playTriggerFreeSpin()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    if self.m_isOutLine then
                        targSp = self:setSymbolToClipReel(iCol, iRow, targSp.p_symbolType)
                    end
                    targSp:runAnim(
                        "actongframe",
                        false,
                        function()
                            targSp:resetReelStatus()
                        end
                    )
                elseif self:checkSymbolIsBonus(targSp.p_symbolType) then
                    self:setSymbolToClipReel(iCol, iRow, targSp.p_symbolType)
                end
            end
        end
    end
end

function CodeGameScreenThorMachine:checkSymbolIsBonus(symbolType)
    if symbolType == self.SYMBOL_BONUS_X or symbolType == self.SYMBOL_BONUS_Y or symbolType == self.SYMBOL_BONUS_Z then
        return true
    end
    return false
end

--创建飞行宝石
function CodeGameScreenThorMachine:createBonusStone(symbolType)
    local flyNode = cc.Node:create()
    local baoshi_node = nil
    if symbolType == self.SYMBOL_BONUS_X then
        baoshi_node = util_spineCreate("Socre_Thor_Bonus_1_fei_baoshi", true, true)
    elseif symbolType == self.SYMBOL_BONUS_Y then
        baoshi_node = util_spineCreate("Socre_Thor_Bonus_2_fei_baoshi", true, true)
    elseif symbolType == self.SYMBOL_BONUS_Z then
        baoshi_node = util_spineCreate("Socre_Thor_Bonus_3_fei_baoshi", true, true)
    end
    self:playSpineEffect(baoshi_node, "fei_baoshi", true)
    flyNode:addChild(baoshi_node, 20)
    return flyNode
end

function CodeGameScreenThorMachine:showFreeSpinStart(_num, _data)
    local view = util_createView("ThorSrc.ThorFreeSpinStart", {freespinCounts = _num, triggerData = _data})
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function()
            return false
        end
    end
    self:findChild("tanBanNode"):addChild(view)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI, {node = view})
    return view
end

function CodeGameScreenThorMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("ThorSounds/sound_Thor_freespin_over.mp3")
    self:playReelEffectOver()
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self.m_maskGreen:runCsbAction("over", false)
            self.m_maskBlue:runCsbAction("over", false)
            self.m_maskRed:runCsbAction(
                "over",
                false,
                function()
                    self.m_maskRed:setVisible(false)
                    self.m_maskGreen:setVisible(false)
                    self.m_maskBlue:setVisible(false)
                end
            )
            self:changeGameBG(0)
            self:triggerFreeSpinOverCallFun()
            self:initTowerCollect()
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 1, sy = 1}, 576)
end

function CodeGameScreenThorMachine:changeGameBG(_type)
    if _type == 0 then
        self.m_gameBg:runCsbAction("normal", false)
    elseif _type == 1 then
        self.m_gameBg:runCsbAction("free", false)
    end
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenThorMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_isOutLine = false

    if self.m_isCollect then
        self.m_isCollect = false
        for i = 1, #self.m_collectList do
            if i > self.m_playAnimIndex then
                local symbolType = self.m_collectList[i].symbolType
                self:playQuickStopTowerAddCollect(symbolType, true)
            end
        end
        self.m_playAnimIndex = -1
    end

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    if self.m_towerSoundId then
        gLobalSoundManager:stopAudio(self.m_towerSoundId)
        self.m_towerSoundId = nil
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
    self:removeBonusBgPanel()

    self:showBonusOrFreeSpinEffect()
    if self.m_moveWild then
        for i, v in ipairs(self.m_moveWild) do
            v:stopAllActions()
            v:removeFromParent()
        end
        self.m_moveWild = {}
    end
    if self.m_bInBonus == false and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_iReelRowNum = self.m_iReelMinRow
        if self.changeTouchSpinLayerSize then
            self:changeTouchSpinLayerSize()
        end
    end
    if self.m_change2wildEffectList then
        for i, v in ipairs(self.m_change2wildEffectList) do
            v:removeFromParent()
        end
        self.m_change2wildEffectList = {}
    end
    return false
end

--轮盘切换 变回 3x5
function CodeGameScreenThorMachine:changeNormalReel()
    if self.m_bInBonus == false and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self.m_iNewReelRowNum > self.m_iReelMinRow then
            self.m_waitChangeReelTime = 1
            self:clearWinLineEffect()
            gLobalSoundManager:playSound("ThorSounds/sound_Thor_down_reel.mp3")
            self:changeReelLength(-1)
            self.m_iReelRowNum = self.m_iReelMinRow
            self.m_iNewReelRowNum = self.m_iReelMinRow

            if self.changeTouchSpinLayerSize then
                self:changeTouchSpinLayerSize()
            end

            self:runCsbAction(
                "down",
                false,
                function()
                    self.m_waitChangeReelTime = nil
                end
            )
        end
    end
end

function CodeGameScreenThorMachine:isTriggerFreespinOrInFreespin()
    local isIn = false
    local features = self.m_runSpinResultData.p_features
    if features then
        for k, v in pairs(features) do
            if v == SLOTO_FEATURE.FEATURE_FREESPIN then
                isIn = true
            end
        end
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        isIn = true
    end

    return isIn
end
------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenThorMachine:addSelfEffect()
    -- print("添加新效果 =============================")
    if self.m_MaskLayer then
        self.m_MaskLayer:setVisible(false)
    end
    self.m_isTriggerFreeSpin = false
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    --base 下bonus收集
    self.m_collectList = {}
    local isInFreeSpin = self:isTriggerFreespinOrInFreespin()
    if isInFreeSpin == false then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow)
                if node then
                    local symbolType = node.p_symbolType
                    if symbolType == self.SYMBOL_BONUS_X or symbolType == self.SYMBOL_BONUS_Y or symbolType == self.SYMBOL_BONUS_Z then
                        local nodeData = {}
                        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
                        nodeData.startPos = startPos
                        nodeData.symbolType = symbolType
                        nodeData.node = node
                        self.m_collectList[#self.m_collectList + 1] = nodeData
                    end
                end
            end
        end

        if self.m_collectList and #self.m_collectList > 0 then
            --收集bonus
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 5
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT
        end
    end

    if selfdata ~= nil then
        if selfdata.wildPositions and #selfdata.wildPositions > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 4
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.ADD_WILD_EFFECT
        end
        if selfdata.multiplyWild and selfdata.multiplyWild == 1 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.CHANGE_WILD_2_EFFECT
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_collectAddSpinList = {}
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow)
                if node then
                    local symbolType = node.p_symbolType
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self.m_collectAddSpinList[#self.m_collectAddSpinList + 1] = node
                    end
                end
            end
        end
        if self.m_collectAddSpinList and #self.m_collectAddSpinList > 0 then
            --收集bonus
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 5
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECT_BONUS_ADDSPIN_EFFECT
        end
    end

    if self.m_bInBonus == true then
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        self.m_bInBonus = false
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenThorMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        self:playBonusCollect(effectData)
    elseif effectData.p_selfEffectType == self.ADD_WILD_EFFECT then
        self:changeMoveWildEffect(effectData)
    elseif effectData.p_selfEffectType == self.CHANGE_WILD_2_EFFECT then
        self:playChangeWild2Effect(effectData)
    elseif effectData.p_selfEffectType == self.COLLECT_BONUS_ADDSPIN_EFFECT then
        self:playCollectAddSpinEffect(effectData)
    end
    return true
end
--是否触发bonus
function CodeGameScreenThorMachine:isTriggerBonus()
    local isIn = false
    local features = self.m_runSpinResultData.p_features
    if features then
        for k, v in pairs(features) do
            if v == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
                isIn = true
            end
        end
    end
    return isIn
end
--播放bonus 收集效果
function CodeGameScreenThorMachine:playBonusCollect(effectData)
    self.m_isCollect = true
    self.m_playAnimIndex = 1
    self.m_effectData = effectData
    self:playCollectAnim()
    --收集不触发玩法 可以点击下次spin
    if not self:isTriggerBonus() then
        -- scheduler.performWithDelayGlobal(
        --     function()
                if self.m_effectData then
                    self.m_effectData.p_isPlay = true
                    self:playGameEffect()
                    self.m_effectData = nil
                -- print("可以Spin了 =============================")
                end
        --     end,
        --     0.5,
        --     self:getModuleName()
        -- )
    end
end

--播放下一个收集
function CodeGameScreenThorMachine:playNextBonusCollect()
    if not self.m_isCollect then
        return
    end
    if self.m_playAnimIndex == #self.m_collectList then
        -- 此处跳出
        if self.m_isCollect == true then
            self.m_isCollect = false
            -- print("收集完毕 =================================================")
            if self.m_effectData then
                self.m_effectData.p_isPlay = true
                self:playGameEffect()
                self.m_effectData = nil
            -- print("可以Spin了2 =============================")
            end
        end
        return
    end
    self.m_playAnimIndex = self.m_playAnimIndex + 1
    self:playCollectAnim()
end

--飞行效果表现
function CodeGameScreenThorMachine:playCollectAnim()
    if self.m_playAnimIndex > #self.m_collectList then
        return
    end

    local data = self.m_collectList[self.m_playAnimIndex]
    local symboltype = data.symbolType
    local endNode
    if symboltype == self.SYMBOL_BONUS_X then
        endNode = "NodeCollectLv"
    elseif symboltype == self.SYMBOL_BONUS_Y then
        endNode = "NodeCollectHong"
    elseif symboltype == self.SYMBOL_BONUS_Z then
        endNode = "NodeCollectLan"
    end

    local startPos = data.startPos --pNode:getParent():convertToWorldSpace(cc.p(pNode:getPosition()))
    local endPos = self:findChild(endNode):getParent():convertToWorldSpace(cc.p(self:findChild(endNode):getPosition()))
    -- 添加飞行轨迹
    local function collectFly()
        gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_collect.mp3")

        local flyNode = self:createBonusStone(symboltype)
        flyNode:setPosition(startPos.x, startPos.y)
        flyNode:setScale(self.m_machineRootScale)
        self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        local action_time = 15 / 30

        local bezier = {}
        local action
        if symboltype == self.SYMBOL_BONUS_X then
            bezier[1] = cc.p(startPos.x - startPos.x / 2 - 50, startPos.y + 30)
            bezier[2] = cc.p(endPos.x - endPos.x / 3 - 30, endPos.y - 50)
            bezier[3] = endPos
            action = cc.BezierTo:create(action_time, bezier)
        elseif symboltype == self.SYMBOL_BONUS_Y then
            action = cc.MoveTo:create(action_time, endPos)
        elseif symboltype == self.SYMBOL_BONUS_Z then
            bezier[1] = cc.p(startPos.x + startPos.x / 2, startPos.y + 30)
            bezier[2] = cc.p(endPos.x + endPos.x / 3 - 30, endPos.y - 50)
            bezier[3] = endPos
            action = cc.BezierTo:create(action_time, bezier)
        end

        local scaleTo1 = cc.ScaleTo:create(action_time / 2, self.m_machineRootScale * 1.5)
        local scaleTo2 = cc.ScaleTo:create(action_time / 2, self.m_machineRootScale * 0.6)
        local spwan = cc.Spawn:create(action, cc.Sequence:create(scaleTo1, scaleTo2))
        local call_set =
            cc.CallFunc:create(
            function()
                flyNode:removeFromParent()
                gLobalSoundManager:playSound("ThorSounds/sound_Thor_collect_bonus_ground.mp3")
                -- 光柱播放动画
                self:playTowerAddCollect(symboltype)
            end
        )
        local seq = cc.Sequence:create({spwan, call_set})
        flyNode:runAction(seq)
    end
    gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_huiju.mp3")
    local pNode = data.node
    if not tolua.isnull(pNode) then
        pNode:runAnim(
            "actionframe",
            false,
            function()
                if not tolua.isnull(pNode) then
                    pNode:runAnim("idleframe", true)
                end
            end
        )
    end
    scheduler.performWithDelayGlobal(
        function()
            collectFly()
        end,
        20 / 30,
        self:getModuleName()
    )
end

--根据index 播放塔触发旋转
function CodeGameScreenThorMachine:playTowerXuanZhuan(_index)
    if self.m_towerSoundId then
        gLobalSoundManager:stopAudio(self.m_towerSoundId)
        self.m_towerSoundId = nil
    end
    self:playTowerEffect(
        self.m_TowerSpine[_index],
        "xuanzhuan_chufa",
        false,
        function()
            if self.m_towerSoundId then
                gLobalSoundManager:stopAudio(self.m_towerSoundId)
                self.m_towerSoundId = nil
            end
            self.m_towerSoundId = gLobalSoundManager:playSound("ThorSounds/sound_Thor_tower_xuanzhuan.mp3", true)
            self:playTowerEffect(self.m_TowerSpine[_index], "xuanzhuan_xunhuan", true)
        end
    )
end

function CodeGameScreenThorMachine:playTowerAddCollect(_type)
    -- print("播放收集效果  ........ type =="  .. _type)
    local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
    local bonusXNum = bonus["101"]
    local bonusYNum = bonus["102"]
    local bonusZNum = bonus["103"]
    gLobalSoundManager:playSound("ThorSounds/sound_Thor_tower_light.mp3")
    if _type == self.SYMBOL_BONUS_X then
        local anctionName = bonusXNum .. "actionframe"
        self:playTowerEffect(
            self.m_TowerSpine[1],
            anctionName,
            false,
            function()
                local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
                local bonusXNum2 = bonus["101"]
                --点击快停收集 数量不一致直接不刷新
                if bonusXNum2 ~= bonusXNum then
                    return
                end

                if bonusXNum == 3 then
                    gLobalSoundManager:playSound("ThorSounds/sound_Thor_tower_collect_full.mp3")
                    self:playTowerEffect(self.m_TowerSpine[1], "freespin_idleframe", true)
                else
                    local idleName = bonusXNum .. "idleframe"
                    if bonusXNum == 2 then
                        idleName = bonusXNum .. "idleframe2"
                    end
                    self:playTowerEffect(self.m_TowerSpine[1], idleName, true)
                end
            end
        )
    elseif _type == self.SYMBOL_BONUS_Y then
        local anctionName = bonusYNum .. "actionframe"
        self:playTowerEffect(
            self.m_TowerSpine[2],
            anctionName,
            false,
            function()
                local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
                local bonusYNum2 = bonus["102"] --点击快停收集 数量不一致直接不刷新
                if bonusYNum2 ~= bonusYNum then
                    return
                end
                if bonusYNum == 3 then
                    gLobalSoundManager:playSound("ThorSounds/sound_Thor_tower_collect_full.mp3")
                    self:playTowerEffect(self.m_TowerSpine[2], "freespin_idleframe", true)
                else
                    local idleName = bonusYNum .. "idleframe"
                    if bonusYNum == 2 then
                        idleName = bonusYNum .. "idleframe2"
                    end
                    self:playTowerEffect(self.m_TowerSpine[2], idleName, true)
                end
            end
        )
    elseif _type == self.SYMBOL_BONUS_Z then
        local anctionName = bonusZNum .. "actionframe"
        self:playTowerEffect(
            self.m_TowerSpine[3],
            anctionName,
            false,
            function()
                local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
                local bonusZNum2 = bonus["103"] --点击快停收集 数量不一致直接不刷新
                if bonusZNum2 ~= bonusZNum then
                    return
                end
                if bonusZNum == 3 then
                    gLobalSoundManager:playSound("ThorSounds/sound_Thor_tower_collect_full.mp3")
                    self:playTowerEffect(self.m_TowerSpine[3], "freespin_idleframe", true)
                else
                    local idleName = bonusZNum .. "idleframe"
                    if bonusZNum == 2 then
                        idleName = bonusZNum .. "idleframe2"
                    end
                    self:playTowerEffect(self.m_TowerSpine[3], idleName, true)
                end
            end
        )
    end
    scheduler.performWithDelayGlobal(
        function()
            self:playNextBonusCollect()
        end,
        30 / 30,
        self:getModuleName()
    )
end
--收集时点
function CodeGameScreenThorMachine:playQuickStopTowerAddCollect(type, bStop)
    local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
    local bonusXNum = bonus["101"]
    local bonusYNum = bonus["102"]
    local bonusZNum = bonus["103"]
    if type == self.SYMBOL_BONUS_X then
        local idleName = bonusXNum .. "idleframe"
        if bonusXNum == 2 then
            idleName = bonusXNum .. "idleframe2"
        elseif bonusXNum == 3 then
            idleName = "freespin_idleframe"
        end
        if bStop then
            self.m_TowerSpine[1]:stopAllActions()
        end
        -- print("快停 ==============================================bonusXNum ==" .. idleName )
        self:playTowerEffect(self.m_TowerSpine[1], idleName, true)
    elseif type == self.SYMBOL_BONUS_Y then
        local idleName = bonusYNum .. "idleframe"
        if bonusYNum == 2 then
            idleName = bonusYNum .. "idleframe2"
        elseif bonusXNum == 3 then
            idleName = "freespin_idleframe"
        end
        if bStop then
            self.m_TowerSpine[2]:stopAllActions()
        end
        self:playTowerEffect(self.m_TowerSpine[2], idleName, true)
    elseif type == self.SYMBOL_BONUS_Z then
        local idleName = bonusZNum .. "idleframe"
        if bonusZNum == 2 then
            idleName = bonusZNum .. "idleframe2"
        elseif bonusXNum == 3 then
            idleName = "freespin_idleframe"
        end
        if bStop then
            self.m_TowerSpine[3]:stopAllActions()
        end
        self:playTowerEffect(self.m_TowerSpine[3], idleName, true)
    end
end

--base下收集满 后播放塔旋转动画
function CodeGameScreenThorMachine:playTowerCollectFull()
    local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
    local bonusXNum = bonus["101"]
    local bonusYNum = bonus["102"]
    local bonusZNum = bonus["103"]

    if bonusXNum == 3 then
        gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_x.mp3")
        self:playTowerXuanZhuan(1)
        self.m_iPlayEffectIndex = 1
        self:playReelEffectStart()
        if self.m_playingDark == false then
            self.m_playingDark = true
            self.m_gameBg:runCsbAction("opendark", false)
        end
    else
        if bonusYNum == 3 then
            if self.m_playingDark == false then
                self:playTowerXuanZhuan(2)
                gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_y.mp3")
                self.m_iPlayEffectIndex = 2
                self:playReelEffectStart()
                self.m_playingDark = true
                self.m_gameBg:runCsbAction("opendark", false)
            end
        else
            if bonusZNum == 3 then
                if self.m_playingDark == false then
                    gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_z.mp3")
                    self:playTowerXuanZhuan(3)
                    self.m_iPlayEffectIndex = 3
                    self:playReelEffectStart()
                    self.m_playingDark = true
                    self.m_gameBg:runCsbAction("opendark", false)
                end
            end
        end
    end
end

function CodeGameScreenThorMachine:changeMoveWildEffect(effectData)
    if self.m_moveWild then
        for i, v in ipairs(self.m_moveWild) do
            v:stopAllActions()
            v:removeFromParent()
        end
        self.m_moveWild = {}
    end
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.wildPositions and #selfdata.wildPositions > 0 then
            local moveWild = selfdata.wildPositions
            for i = 1, #moveWild do
                local fixPos = self:getRowAndColByPos(moveWild[i])
                local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                --换类型
                if targSp then
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    local order = self:getBounsScatterDataZorder(self.SYMBOL_WILD_2) - targSp.p_rowIndex
                    targSp:setLocalZOrder(order)
                end
            end
        end
    end
    effectData.p_isPlay = true
    self:playGameEffect()
end

--wild X2 效果播放
function CodeGameScreenThorMachine:playChangeWild2Effect(effectData)
    self.m_wildNodeList = {}
    self.m_change2wildEffectList = {}
    self.m_playChangeAnimIndex = 1
    self.m_effectData = effectData
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow)
            if node then
                local symbolType = node.p_symbolType
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    self.m_wildNodeList[#self.m_wildNodeList + 1] = node
                end
            end
        end
    end
    self:playBonusZTowerEffect()
    self:changeWildToWild2()
end

function CodeGameScreenThorMachine:changeWildToWild2()
    if self.m_playChangeAnimIndex > #self.m_wildNodeList then
        -- 此处跳出
        local strOver = "xuanzhuan_jieshu"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            strOver = "xuanzhuan_jieshu2"
        end
        self:playTowerEffect(
            self.m_TowerSpine[3],
            strOver,
            false,
            function()
                if self.m_towerSoundId then
                    gLobalSoundManager:stopAudio(self.m_towerSoundId)
                    self.m_towerSoundId = nil
                end
                local strName = "idleframe"
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    strName = "freespin_idleframe"
                end
                self:playTowerEffect(self.m_TowerSpine[3], strName, true)
            end
        )
        if self.m_playingDark then
            self:playReelEffectOver()
            self.m_playingDark = false
            self.m_gameBg:runCsbAction("overdark", false)
        end
        scheduler.performWithDelayGlobal(
            function()
                if self.m_effectData then
                    self.m_effectData.p_isPlay = true
                    self:playGameEffect()
                    self.m_effectData = nil
                end
            end,
            1.0,
            self:getModuleName()
        )
        return
    end

    local pNode = self.m_wildNodeList[self.m_playChangeAnimIndex]

    local posWorld = pNode:getParent():convertToWorldSpace(cc.p(pNode:getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
    local startWorldPos = self:findChild("NodeCollectLan"):getParent():convertToWorldSpace(cc.p(self:findChild("NodeCollectLan"):getPosition()))
    local startPos = self:convertToNodeSpace(cc.p(startWorldPos.x, startWorldPos.y))

    -- 添加飞行轨迹
    local function FlyPar()
        self:runFlyAct(
            startPos,
            endPos,
            function()
                local effect = util_createAnimation("Socre_Thor_Wild_0.csb")
                table.insert(self.m_change2wildEffectList, effect)
                self.m_clipParent:addChild(effect, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + pNode.p_rowIndex)
                local endPos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                effect:setPosition(endPos)
                pNode:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_WILD_2), self.SYMBOL_WILD_2)
                local order = self:getBounsScatterDataZorder(self.SYMBOL_WILD_2) - pNode.p_rowIndex
                pNode:setLocalZOrder(order)
                effect:runCsbAction(
                    "actionframe2",
                    false,
                    function()
                        -- effect:removeFromParent()
                        effect:setVisible(false)
                    end
                )
            end
        )
        scheduler.performWithDelayGlobal(
            function()
                self.m_playChangeAnimIndex = self.m_playChangeAnimIndex + 1
                self:changeWildToWild2()
            end,
            10 / 30,
            self:getModuleName()
        )
    end

    FlyPar()
end

function CodeGameScreenThorMachine:getAngleByPos(p1, p2)
    local p = {}
    p.x = p2.x - p1.x
    p.y = p2.y - p1.y

    local r = math.atan2(p.y, p.x) * 180 / math.pi
    return r
end

function CodeGameScreenThorMachine:runFlyAct(startPos, endPos, func1, func2)
    local flyNode = util_createAnimation("Socre_Thor_feixing_lizi.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    flyNode:setPosition(startPos)
    local angle = self:getAngleByPos(startPos, endPos)
    flyNode:findChild("Node_1"):setRotation(-angle)
    local scaleSize = math.sqrt(math.pow(startPos.x - endPos.x, 2) + math.pow(startPos.y - endPos.y, 2))
    flyNode:findChild("Node_1"):setScaleX((scaleSize / 342))

    scheduler.performWithDelayGlobal(
        function()
            if func1 then
                func1()
            end
        end,
        6 / 30,
        self:getModuleName()
    )
    gLobalSoundManager:playSound("ThorSounds/sound_Thor_shandian.mp3")
    flyNode:runCsbAction(
        "actionframe",
        false,
        function()
            if func2 then
                func2()
            end
            flyNode:stopAllActions()
            flyNode:removeFromParent()
        end
    )
end

function CodeGameScreenThorMachine:playCollectAddSpinEffect(effectData)
    --
    local endPos = self.m_baseFreeSpinBar:getCollectPos()
    local FlyNum = 0
    if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
        self.m_iFreeSpinTimes = data.p_freeSpinsTotalCount
        self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    end
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    -- print("totalFreeSpinCount =======================" .. globalData.slotRunData.totalFreeSpinCount)
    -- print("p_freeSpinsLeftCount =====================" .. self.m_runSpinResultData.p_freeSpinsLeftCount)
    for i = 1, #self.m_collectAddSpinList do
        local node = self.m_collectAddSpinList[i]
        if node then
            node:removeSpin()
            local fly = self:createAddSpin()
            fly:setScale(self.m_machineRootScale)
            self:addChild(fly, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
            local pos = cc.p(util_getConvertNodePos(node, fly))
            fly:setPosition(pos)
            local actionList = {}
            actionList[#actionList + 1] = cc.DelayTime:create(0.2)
            actionList[#actionList + 1] = cc.MoveTo:create(0.5, cc.p(endPos.x, endPos.y + 31))
            actionList[#actionList + 1] =
                cc.CallFunc:create(
                function()
                    fly:removeFromParent()
                end
            )
            local sq = cc.Sequence:create(actionList)
            fly:runAction(sq)
            FlyNum = FlyNum + 1
        end
    end

    if FlyNum and FlyNum > 0 then
        scheduler.performWithDelayGlobal(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
                self.m_baseFreeSpinBar:playAddSpinFreeSpinCount()
                gLobalSoundManager:playSound("ThorSounds/sound_Thor_add_spin.mp3")
            end,
            0.6,
            self:getModuleName()
        )
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end
---
-- 显示bonus 触发的小游戏
function CodeGameScreenThorMachine:showEffect_Bonus(effectData)
    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    -- self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then
        self:showBonusAndScatterLineTip(
            bonusLineValue,
            function()
                self:showBonusGameView(effectData)
            end
        )
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenThorMachine:showBonusGameView(effectData)
    performWithDelay(
        self,
        function()
            self:playTowerCollectFull()
            self:showBonusView(effectData)
        end,
        45 / 30
    )
end

function CodeGameScreenThorMachine:showBonusView(effectData)
    local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
    if not bonus then
        return
    end
    self.m_bInBonus = true
    self:setCurrSpinMode(REWAED_SPIN_MODE)
    local bonusXNum = bonus["101"]
    local bonusYNum = bonus["102"]
    local bonusZNum = bonus["103"]

    if bonusXNum == 3 then
        self.m_iReelRowNum = self.m_iReelMaxRow
        self.m_iNewReelRowNum = self.m_iReelMaxRow
        gLobalSoundManager:playSound("ThorSounds/sound_Thor_up_reel.mp3")
        self:changeReelLength(1)

        if self.changeTouchSpinLayerSize then
            self:changeTouchSpinLayerSize()
        end
        
        self:runCsbAction(
            "up",
            false,
            function()
                self.m_iPlayEffectIndex = 1
                if self.m_iReelRowNum == self.m_iReelMaxRow then
                    self:runCsbAction("upidle", true)
                end

                effectData.p_isPlay = true
                self:playGameEffect()

                self:playTowerEffect(
                    self.m_TowerSpine[1],
                    "xuanzhuan_jieshu2",
                    false,
                    function()
                        if self.m_towerSoundId then
                            gLobalSoundManager:stopAudio(self.m_towerSoundId)
                            self.m_towerSoundId = nil
                        end
                        -- self:playTowerEffect(self.m_TowerSpine[1], "idleframe", true)
                        self:playTowerEffect(self.m_TowerSpine[1], "freespin_idleframe", true)
                        if bonusYNum == 3 or bonusZNum == 3 then
                            if bonusYNum == 3 then
                                gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_y.mp3")
                                self:playTowerXuanZhuan(2)
                            elseif bonusZNum == 3 then
                                gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_z.mp3")
                                self:playTowerXuanZhuan(3)
                            end
                        else
                            if self.m_iReelRowNum == self.m_iReelMaxRow then
                                if self.m_playingDark then
                                    -- self.m_iPlayEffectIndex = -1
                                    self.m_playingDark = false
                                    self.m_gameBg:runCsbAction("overdark", false)
                                end
                            end
                        end
                    end
                )
            end
        )
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function CodeGameScreenThorMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(self.m_iReelMaxRow, self.m_iReelColumnNum, TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function CodeGameScreenThorMachine:changeReelLength(direction)
    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i, self.m_iReelMaxRow, true)
    end
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum
    end
    local NowHeight = self.m_iReelRowNum * self.m_SlotNodeH
    local endHeight = self.m_iReelMaxRow * self.m_SlotNodeH

    if direction > 0 then
        direction = 1
        local _row = self.m_iReelRowNum
        endHeight = _row * self.m_SlotNodeH
    else
        direction = -1
        endHeight = self.m_iReelMinRow * self.m_SlotNodeH
    end
    local hightNode = self:findChild("Node_2")
    local bottomNode = self:findChild("Node_2_0")
    local posBY = bottomNode:getPositionY()
    if self.m_updateReelHeightID then
        scheduler.unscheduleGlobal(self.m_updateReelHeightID)
        self.m_updateReelHeightID = nil
    end
    self.m_updateReelHeightID =
        scheduler.scheduleUpdateGlobal(
        function(delayTime)
            local distance = 0
            local posHY = hightNode:getPositionY()
            local hight = posHY - posBY
            if direction > 0 then
                if hight >= endHeight then
                    hight = endHeight
                    scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                end
            else
                if hight <= endHeight then
                    hight = endHeight
                    scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                end
            end

            local rect = self.m_onceClipNode:getClippingRegion()
            self.m_onceClipNode:setClippingRegion(
                {
                    x = rect.x,
                    y = rect.y,
                    width = rect.width,
                    height = hight
                }
            )
        end
    )


end

function CodeGameScreenThorMachine:updateNetWorkData()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local moveWild = selfData.wildPositions or {}
    if moveWild and #moveWild > 0 then
        self:playMoveWildEffect(
            function()
                BaseNewReelMachine.updateNetWorkData(self)
            end
        )
    else
        BaseNewReelMachine.updateNetWorkData(self)
    end
end

function CodeGameScreenThorMachine:showMaskLayer()
    local nowHeight = self.m_iReelRowNum * self.m_SlotNodeH
    local nowWidth = 663
    if not self.m_MaskLayer then
        self.m_MaskLayer = cc.LayerColor:create(cc.c4f(0, 0, 0, 200))
        self.m_MaskLayer:setContentSize(nowWidth, nowHeight)
        local reel = self:findChild("sp_reel_0")
        local posWorld = reel:getParent():convertToWorldSpace(cc.p(reel:getPosition()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        self.m_MaskLayer:setPosition(pos)
        self.m_clipParent:addChild(self.m_MaskLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 5)
    end
    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_MaskLayer:setContentSize(nowWidth, nowHeight)
    self.m_MaskLayer:setVisible(true)
end

-- 播放wild移动效果
function CodeGameScreenThorMachine:playMoveWildEffect(func)
    self.m_moveWild = {} --移动的wild
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata ~= nil then
        if selfdata.wildPositions and #selfdata.wildPositions > 0 then
            local moveWild = {}
            for i, v in ipairs(selfdata.wildPositions) do
                local data = v
                table.insert(moveWild, data)
            end
            self:moveWild(moveWild, func)
        end
    end
end

--停止播放轮盘周边效果
function CodeGameScreenThorMachine:playReelEffectStart()
    if self.m_iPlayEffectIndex > 0 then
        local startStr = "start" .. self.m_iPlayEffectIndex
        -- print("self.m_iPlayEffectIndex start ===========================" .. self.m_iPlayEffectIndex)
        self:runCsbAction(
            startStr,
            false,
            function()
                local idleStr = "idle" .. self.m_iPlayEffectIndex
                -- print("self.m_iPlayEffectIndex  idle===========================" .. self.m_iPlayEffectIndex)
                self:runCsbAction(idleStr, true)
            end
        )
    end
end

--停止播放轮盘周边效果
function CodeGameScreenThorMachine:playReelEffectOver()
    if self.m_iPlayEffectIndex > 0 then
        local str = "over" .. self.m_iPlayEffectIndex
        self:runCsbAction(str, false)
        if self.m_iPlayEffectIndex == 1 then
            self:playTowerEffect(self.m_TowerSpine[1], "idleframe", true)
        end
        self.m_iPlayEffectIndex = -1
    end
end

function CodeGameScreenThorMachine:moveWild(wildPositions, func)
    if #wildPositions == 0 then
        -- 停止红塔光柱的动画播放
        local strOver = "xuanzhuan_jieshu"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            strOver = "xuanzhuan_jieshu2"
        end
        self:playTowerEffect(
            self.m_TowerSpine[2],
            strOver,
            false,
            function()
                if self.m_towerSoundId then
                    gLobalSoundManager:stopAudio(self.m_towerSoundId)
                    self.m_towerSoundId = nil
                end
                local strName = "idleframe"
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    strName = "freespin_idleframe"
                end
                self:playTowerEffect(self.m_TowerSpine[2], strName, true)
            end
        )
        if self.m_bInBonus then
            local selfdata = self.m_runSpinResultData.p_selfMakeData
            if not selfdata then
                return
            end
            if self.m_playingDark then
                if selfdata.multiplyWild and selfdata.multiplyWild == 1 then
                    gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_z.mp3")
                    self:playTowerXuanZhuan(3)
                else
                    self.m_playingDark = false
                    self:playReelEffectOver()
                    self.m_gameBg:runCsbAction("overdark", false)
                end
            end
        end
        if self.m_MaskLayer then
            self.m_MaskLayer:setVisible(false)
        end
        -- 轮盘停止

        if func ~= nil then
            func()
        end
        return
    end

    local node = self:findChild("NodeCollectHong")
    local posWorld = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local startPos = self:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))

    local pos = wildPositions[1]
    local fixPos = self:getRowAndColByPos(pos)
    local targetPos = self:getMoveNodePosByColAndRow(fixPos.iY, fixPos.iX)
    local posWorld = self.m_clipParent:convertToWorldSpace(targetPos)
    local endPos = self:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))

    self:runFlyAct(
        startPos,
        endPos,
        function()
            --创建新的wild
            local targSp = util_createAnimation("Socre_Thor_Wild.csb")
            local endPos = self:getNodePosByColAndRow(fixPos.iY, fixPos.iX)
            targSp:setPosition(endPos)
            local order = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - fixPos.iX
            self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + order)
            table.insert(self.m_moveWild, targSp)
            targSp:runCsbAction("actionframe2", false)
        end
    )
    scheduler.performWithDelayGlobal(
        function()
            table.remove(wildPositions, 1)
            self:moveWild(wildPositions, func)
        end,
        10 / 30,
        self:getModuleName()
    )
end

function CodeGameScreenThorMachine:getMoveNodePosByColAndRow(col, row)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function CodeGameScreenThorMachine:getReelsTarSpPos(index)
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos = self:getNodePosByColAndRow(fixPos.iY, fixPos.iX)
    return targSpPos
end

function CodeGameScreenThorMachine:getNodePosByColAndRow(col, row)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

function CodeGameScreenThorMachine:beginReel()
    BaseNewReelMachine.beginReel(self)
    self:changeNormalReel()
end

function CodeGameScreenThorMachine:playBonusXTowerEffect()
    self:playTowerXuanZhuan(1)
end

function CodeGameScreenThorMachine:playBonusYTowerEffect()
    self:showMaskLayer()
    self:playTowerXuanZhuan(2)
end

function CodeGameScreenThorMachine:playBonusZTowerEffect()
    if self.m_bInBonus then
        gLobalSoundManager:playSound("ThorSounds/sound_Thor_bonus_z.mp3")
    end
    self:playTowerXuanZhuan(3)
end

function CodeGameScreenThorMachine:showBonusOrFreeSpinEffect()
    if self.m_bInBonus or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local bonus = self.m_runSpinResultData.p_selfMakeData.bonusCounts
        if bonus then
            local bonusYNum = bonus["102"]
            if bonusYNum == 3 then
                self:showMaskLayer()
            end
        end
        local freespinTrigger = self.m_runSpinResultData.p_selfMakeData.freespinTrigger
        if freespinTrigger then
            if freespinTrigger["102"] == 1 then
                self:playBonusYTowerEffect()
            end
        end
    end
end

function CodeGameScreenThorMachine:slotReelDown()
    BaseNewReelMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

-- 处理spin 返回结果
function CodeGameScreenThorMachine:checkOperaSpinSuccess(param)
    if param[1] == true then
        local spinData = param[2]

        local freeGameCost = spinData.freeGameCost
        if freeGameCost then
            self.m_rewaedFSData = freeGameCost
        end

        if spinData.action == "SPIN" or spinData.action == "FEATURE" then
            release_print("消息返回胡来了")

            self:operaSpinResultData(param)

            self:operaUserInfoWithSpinResult(param)

            self:updateNetWorkData()
            gLobalNoticManager:postNotification("TopNode_updateRate")
        end
    end
end

function CodeGameScreenThorMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end
    --添加bonus时免费自动spin
    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_SPIN_MODE then
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

--设置bonus scatter 信息
function CodeGameScreenThorMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount
    local isTrigger = false
    if self:isTriggerFreespinOrInFreespin() then
        isTrigger = true
    end
    for row = 1, iRow do
        local targetSymbolType = self:getSymbolTypeForNetData(column, row, runLen)
        if targetSymbolType == symbolType or targetSymbolType == self.SYMBOL_BONUS_X or targetSymbolType == self.SYMBOL_BONUS_Y or targetSymbolType == self.SYMBOL_BONUS_Z then
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
                    bPlaySymbolAnima = true
                end
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and column == 5 then
                    if isTrigger == true then
                        reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)
                    end
                else
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)
                end
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

function CodeGameScreenThorMachine:checkIsInLongRun(col, symbolType)
    if col > 1 and col < 4 then
        return true
    else
        return false
    end
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenThorMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i = 1, self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    if col == 1 and nodeNum >= 1 then
        return runStatus.DUANG, true
    else
        return runStatus.NORUN, false
    end
end

function CodeGameScreenThorMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_BONUS_X or symbolType == self.SYMBOL_BONUS_Y or symbolType == self.SYMBOL_BONUS_Z then
        return true
    end
    return false
end

--设置长滚信息
function CodeGameScreenThorMachine:setReelRunInfo()
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
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        else
            if addLens == true then
                if col == 5 then
                    self.m_reelRunInfo[col]:setReelLongRun(false)
                    self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 18)
                    self:setLastReelSymbolList()
                end
            end
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)
        -- bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col, bonusNum, bRunLong)
        if bRunLong == true and col == 4 then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
            addLens = true
        end
    end --end  for col=1,iColumn do
end

-- 每个reel条滚动到底
function CodeGameScreenThorMachine:slotOneReelDown(reelCol)
    BaseNewReelMachine.slotOneReelDown(self, reelCol)

    local isTrigger = false
    if self:isTriggerFreespinOrInFreespin() then
        isTrigger = true
    end
    local isPlayBuling = false
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getFixSymbol(reelCol, iRow, SYMBOL_NODE_TAG)
        if targSp and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if reelCol == 1 then
                isPlayBuling = true
            elseif reelCol == 5 and isTrigger then
                isPlayBuling = true
            end
            if isPlayBuling then
                targSp = self:setSymbolToClipReel(reelCol, iRow, targSp.p_symbolType)
                targSp:runAnim(
                    "buling",
                    false,
                    function()
                        targSp:resetReelStatus()
                    end
                )

                local soundPath = "ThorSounds/sound_Thor_scatter_ground.mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

            end
        end

        if targSp and self:checkSymbolIsBonus(targSp.p_symbolType) then
            targSp:playBonusBgBuling()
            targSp = self:setSymbolToClipReel(reelCol, iRow, targSp.p_symbolType)

            local soundPath = "ThorSounds/sound_Thor_bonus_ground.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end


            targSp:runAnim(
                "buling",
                false,
                function()
                    if not tolua.isnull(targSp) then
                        targSp:runAnim("idleframe", true)
                    end
                end
            )
        end
    end
end

--本列停止 判断下列是否有长滚
function CodeGameScreenThorMachine:getNextReelIsLongRun(reelCol)
    if reelCol < self.m_iReelColumnNum then
        local bHaveLongRun = false
        for i = 1, reelCol do
            local reelRunData = self.m_reelRunInfo[i]
            if reelRunData:getNextReelLongRun() == true then
                bHaveLongRun = true
                break
            end
        end
        if self:isLongRun(reelCol) and bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() == false then
            return true
        end
    end
    return false
end
--设置bonus scatter 层级
function CodeGameScreenThorMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_3
    elseif symbolType == self.SYMBOL_BONUS_X or symbolType == self.SYMBOL_BONUS_Y or symbolType == self.SYMBOL_BONUS_Z then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD_2 then
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

function CodeGameScreenThorMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

function CodeGameScreenThorMachine:setSymbolClipToSlotReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_slotParents[_iCol].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp:removeFromParent()
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        local zorder = self:getBounsScatterDataZorder(_type)
        targSp:setLocalZOrder(zorder - _iRow)
        targSp:setPosition(cc.p(pos.x, pos.y))
        self.m_slotParents[_iCol].slotParent:addChild(targSp)
    end
    return targSp
end

function CodeGameScreenThorMachine:updateReelGridNode(node)
    --symbolType, row, col, isLastSymbol
    if self.m_isOutLine then
        return
    end
    local symbolType = node.p_symbolType
    local row = node.p_rowIndex
    local col = node.p_cloumnIndex
    local isLastSymbol = node.m_isLastSymbol
    if symbolType == self.SYMBOL_BONUS_X or symbolType == self.SYMBOL_BONUS_Y or symbolType == self.SYMBOL_BONUS_Z then
        if isLastSymbol == false then
            local bonusBg
            if symbolType == self.SYMBOL_BONUS_X then
                bonusBg = self:createBonusBg(self.SYMBOL_BONUS_X_BG)
            elseif symbolType == self.SYMBOL_BONUS_Y then
                bonusBg = self:createBonusBg(self.SYMBOL_BONUS_Y_BG)
            elseif symbolType == self.SYMBOL_BONUS_Z then
                bonusBg = self:createBonusBg(self.SYMBOL_BONUS_Z_BG)
            end

            local pos = self:getBgNodePosByColAndRow(row, col)
            local node = self:findChild("Panel_" .. col)
            if node then
                node:addChild(bonusBg)
                bonusBg:setPosition(pos)
                local actionList = {}
                actionList[#actionList + 1] = cc.MoveTo:create(2, cc.p(pos.x, -2000))
                actionList[#actionList + 1] =
                    cc.CallFunc:create(
                    function()
                        bonusBg:removeFromParent()
                    end
                )
                local sq = cc.Sequence:create(actionList)
                bonusBg:runAction(sq)
            end
        end
    end
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if isLastSymbol == true and not self.m_isTriggerFreeSpin and self:getCurrSpinMode() == FREE_SPIN_MODE and not self.m_isOutLine then
            if node.m_spin == nil then
                node.m_spin = self:createAddSpin()
                node.m_spin:runCsbAction("actionframe", false)
                node:addChild(node.m_spin, 2)
            end
        end
    end
end
--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function CodeGameScreenThorMachine:getBgNodePosByColAndRow(row, col)
    local reelNode = self:findChild("Panel_" .. col)
    local size = reelNode:getContentSize()
    local posX = size.width * 0.5
    local posY = size.height - 0.5 * self.m_SlotNodeH
    return cc.p(posX, posY)
end

--移除bonus拖尾
function CodeGameScreenThorMachine:removeBonusBgPanel()
    for i = 1, 5 do
        local panel = self:findChild("Panel_" .. i)
        panel:removeAllChildren()
    end
end

function CodeGameScreenThorMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    elseif self.m_bInBonus then
        reelDatas = self.m_configData:getBonusReelDatasByColumnIndex(parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

--
function CodeGameScreenThorMachine:createAddSpin()
    local csb = util_createAnimation("Thor_AddSpin.csb")
    return csb
end

-- 检测处理effect 结束后的逻辑
function CodeGameScreenThorMachine:operaEffectOver()
    printInfo("run effect end")
    if self.m_iPlayEffectIndex == 1 and not self.m_bInBonus then
        self:playTowerEffect(self.m_TowerSpine[1], "idleframe", true)
        self.m_iPlayEffectIndex = -1
    end
    self:changeNormalReel()
    self:setGameSpinStage(IDLE)

    self:setPlayGameEffectStage(GAME_EFFECT_OVER_STATE)

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

return CodeGameScreenThorMachine
