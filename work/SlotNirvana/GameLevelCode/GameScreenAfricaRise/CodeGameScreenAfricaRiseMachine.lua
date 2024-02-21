---
-- island li
-- 2019年1月26日
-- CodeGameScreenAfricaRiseMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseDialog = util_require("Levels.BaseDialog")
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local AfricaRiseSlotsNode = require "CodeAfricaRiseSrc.AfricaRiseSlotsNode"

local CodeGameScreenAfricaRiseMachine = class("CodeGameScreenAfricaRiseMachine", BaseFastMachine)

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136

CodeGameScreenAfricaRiseMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenAfricaRiseMachine.SYMBOL_WILD_X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 107
CodeGameScreenAfricaRiseMachine.SYMBOL_SPIN_ADD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 108

CodeGameScreenAfricaRiseMachine.EFFECT_COLLECT_ICON = GameEffect.EFFECT_SELF_EFFECT - 1 --收集
CodeGameScreenAfricaRiseMachine.EFFECT_ADD_SPIN = GameEffect.EFFECT_SELF_EFFECT - 2 --增加spin次数
CodeGameScreenAfricaRiseMachine.EFFECT_ADD_REEL = GameEffect.EFFECT_SELF_EFFECT - 3 --增加行数滚动

-- 构造函数
function CodeGameScreenAfricaRiseMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_iAddReelRowNum = 3
    self.m_bBonusGame = false
    self.m_bTriggerFreespin = false
    self.m_scatterDownNum = 1
    self.m_WildXNodeList = {}
    self.m_ScatterNodeList = {}
    self.m_iFreeSpinStartDelayTime = 0
    self:initGame()
end

function CodeGameScreenAfricaRiseMachine:initGame()
    self:changeConfigData()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    self.m_collectList = {}
end

function CodeGameScreenAfricaRiseMachine:changeConfigData()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("AfricaRiseConfig.csv", "LevelAfricaRiseConfig.lua")
    self.m_configData:initMachine(self)
    globalData.slotRunData.levelConfigData = self.m_configData
end

function CodeGameScreenAfricaRiseMachine:initUI()
    self.m_collectView = util_createView("CodeAfricaRiseSrc.AfricaRiseCollectView")
    self.m_csbOwner["jindutiao"]:addChild(self.m_collectView)
    local collectData = self:BaseMania_getCollectData()
    self.m_collectView:initViewData(collectData.p_collectCoinsPool, collectData.p_collectLeftCount, collectData.p_collectTotalCount)
    self.m_logo = util_createView("CodeAfricaRiseSrc.AfricaRiseLogo")
    self:findChild("logo"):addChild(self.m_logo)
    self.m_lineEffect = util_createAnimation("AfricaRise_lineEffect.csb")
    self:findChild("lineNode"):addChild(self.m_lineEffect)
    -- self.m_lineEffect:playAction("3x5",true)
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_EffectNode = self:findChild("effectNode")
    self:changeNormalAndFreespinBg(1)
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
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end
            gLobalSoundManager:setBackgroundMusicVolume(0.4)
            local soundName = "AfricaRiseSounds/sound_AfricaRise_last_win_" .. soundIndex .. ".mp3"
            local winSoundsId =
                gLobalSoundManager:playSound(
                soundName,
                false,
                function()
                    gLobalSoundManager:setBackgroundMusicVolume(1)
                end
            )
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenAfricaRiseMachine:initFreeSpinBar()
    local node_bar = self:findChild("freespin")
    self.m_baseFreeSpinBar = util_createView("CodeAfricaRiseSrc.AfricaRiseFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end

-- 断线重连
function CodeGameScreenAfricaRiseMachine:MachineRule_initGame()
    local isFreespin = false
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_bBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        else
            local frssSpinType = self.m_runSpinResultData.p_selfMakeData.freeSpinType
            if frssSpinType == 0 then
            end
        end
        isFreespin = true
        self.m_collectView:setVisible(false)
        self:changeNormalAndFreespinBg(2)
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
    elseif self.m_bBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        self:triggerFreeSpinCallFun()
        self:changeNormalAndFreespinBg(2)
        self.m_collectView:setVisible(false)
        isFreespin = true
    end

    if self:isTriggerBonusGame() then
        self:showBonusReel(true)
        self:clearCurMusicBg()
    end
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
        self.m_collectView:setButtonTouchEnabled(true)
    else
        self.m_collectView:setButtonTouchEnabled(false)
    end
end

function CodeGameScreenAfricaRiseMachine:isTriggerBonusGame()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- type bonus类型 0： 小关 1：大关--ext spin 次数  --num spin 总次数
    if selfData.currCell and selfData.currCell.type == 1 and selfData.currCell.ext > 0 then
        if selfData.reconnect and selfData.reconnect == true then --标记是否玩过 没玩过的话就是刚触发
            return true
        end
    end
    return false
end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAfricaRiseMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "AfricaRise"
end

function CodeGameScreenAfricaRiseMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)
    self.m_gameBg = gameBg
end

function CodeGameScreenAfricaRiseMachine:enterLevel()
    self.m_outOnlin = true

    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect,isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end
    
    -- 初始化下部轮盘
    self:createSmallReels()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects( )
        self:playGameEffect()
    end

    self:addRunChangeWildXReel() --随机选择的滚动条
end

--缩放主界面
function CodeGameScreenAfricaRiseMachine:scaleMainLayer()
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

--适配
function CodeGameScreenAfricaRiseMachine:changeViewNodePos()
    local bonusReelHeight = 0
    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro > 2 and pro < 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 200)
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

function CodeGameScreenAfricaRiseMachine:getBaseReelGridNode()
    return "CodeAfricaRiseSrc.AfricaRiseSlotsNode"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAfricaRiseMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_WILD_X then
        return "Socre_AfricaRise_wild"
    elseif symbolType == self.SYMBOL_SPIN_ADD then
        return "Socre_AfricaRise_SpinAdd"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAfricaRiseMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_X, count = 5}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SPIN_ADD, count = 5}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenAfricaRiseMachine:levelFreeSpinEffectChange()
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenAfricaRiseMachine:levelFreeSpinOverChangeEffect()
end
---------------------------------------------------------------------------
-- 显示free spin
function CodeGameScreenAfricaRiseMachine:showEffect_FreeSpin(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    if self.m_iAddReelRowNum == 3 then
        self:setReelSlotsNodeVisible(true)
        self.m_SmallReelsView:setVisible(false)
    end
    self:removeScatterNodeList()
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

function CodeGameScreenAfricaRiseMachine:showFreeSpinView(effectData)
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_scatter_trigger.mp3")
    self:findChild("heng_xian"):setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + 500)
    self:findChild("lineNode"):setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + 500)
    local showFreeSpinView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self.m_bTriggerFreespin = true
            gLobalSoundManager:playSound(
                "AfricaRiseSounds/sound_AfricaRise_tip.mp3",
                false,
                function()
                    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_freespin_start.mp3")
                end
            )
            self:showFreeSpinStart(
                self.m_iFreeSpinTimes,
                function()
                    self.m_iFreeSpinStartDelayTime = 2
                    self:triggerFreeSpinCallFun()
                    self.m_collectView:setVisible(false)
                    self:changeNormalAndFreespinBg(3)
                    if self.m_iAddReelRowNum > 3 then
                        self:changeScatterToSlotParent()
                        self.m_SmallReelsView:removeAddReelRespinElement()
                        local str = self.m_iAddReelRowNum .. "x5down"
                        local direction = self.m_iReelRowNum - self.m_iAddReelRowNum
                        self:changeReelLength(direction)
                        if self.m_iAddReelRowNum >= 5 then
                            self.m_logo:runCsbAction("animation2", false)
                        end
                        self:runCsbAction(
                            str,
                            false,
                            function()
                                self:showSingleReelSlotsNodeVisible(true)
                                self:removeReelSlotsNode()
                                self.m_iAddReelRowNum = 3
                                self:playAddWildEffect()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        )
                    else
                        self:playAddWildEffect()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                end
            )
        end
    end
    --全部scatter的触发动画
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iAddReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    targSp:runAnim("actionframe", false)
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
        4.5
    )
end

-- 添加 addWild Effect
function CodeGameScreenAfricaRiseMachine:playAddWildEffect(func)
    local node = self:findChild("addWildNode")
    local addWildEffect = util_createView("CodeAfricaRiseSrc.AfricaRiseAddWildEffect")
    node:addChild(addWildEffect)
    addWildEffect:playAddWildEffect(func)
end

function CodeGameScreenAfricaRiseMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound(
        "AfricaRiseSounds/sound_AfricaRise_tip.mp3",
        false,
        function()
            gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_freespin_over.mp3")
        end
    )
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self.m_collectView:setVisible(true)
            self:triggerFreeSpinOverCallFun()
            self:changeNormalAndFreespinBg(4)
            self:setRespinViewLight()
            self:resetMusicBg(true)
            -- if  self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
                self.m_collectView:setButtonTouchEnabled(true)
            -- end
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
end

--进入游戏 音效处理
function CodeGameScreenAfricaRiseMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.m_bBonusGame then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    else
                        self:playBonusBgm()
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

function CodeGameScreenAfricaRiseMachine:playBonusBgm()
    self.m_currentMusicBgName = "AfricaRiseSounds/music_AfricaRise_classic_bgm.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

function CodeGameScreenAfricaRiseMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
    -- self:addRunChangeWildXReel() --随机选择的滚动条
end

function CodeGameScreenAfricaRiseMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local selfData = self.m_runSpinResultData.p_selfMakeData
            local data = {}
            if selfData and selfData.currCell then
                data = selfData.currCell
            end
            self:showBonusMap(
                data,
                true,
                function()
                    self.m_collectView:setButtonTouchEnabled(true)
                    self.m_map = nil
                end
            )
        end,
        "SHOW_BONUS_MAP"
    )
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenAfricaRiseMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_WILD_X, runEndAnimaName = "actionframe", bRandom = true},
        {type = self.SYMBOL_SPIN_ADD, runEndAnimaName = "buling", bRandom = true},
        {type = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, runEndAnimaName = "buling", bRandom = true}
    }
    return symbolList
end

function CodeGameScreenAfricaRiseMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
    if self.m_updateReelHeightID then
        scheduler.unscheduleGlobal(self.m_updateReelHeightID)
        self.m_updateReelHeightID = nil
    end
end

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenAfricaRiseMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenAfricaRiseMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCoins = self.m_runSpinResultData.p_collectNetData[1].collectCoinsPool
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount
        self:BaseMania_updateCollect(addCount, addCoins, 1, totalCount)
    end
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end

function CodeGameScreenAfricaRiseMachine:addLastWinSomeEffect()
    BaseFastMachine.addLastWinSomeEffect(self)
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end

--初始化上方滚轴
function CodeGameScreenAfricaRiseMachine:addRunChangeWildXReel()
    local addReelSymbol = {}
    self.m_ChangeReelView = util_createView("CodeAfricaRiseSrc.AfricaRiseRunReel")
    self:findChild("gundong"):addChild(self.m_ChangeReelView)
    self.m_ChangeReelView:setMachine(self)
    self.m_ChangeReelView:changeFrameBg()
    --传入信号池
    self.m_ChangeReelView:setNodePoolFunc(
        function(symbolType)
            return self:getSlotNodeBySymbolType(symbolType)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )

    self.m_ChangeReelView:initFeatureUI()

    self.m_ChangeReelView:setOverCallBackFun(
        function()
            scheduler.performWithDelayGlobal(
                function()
                    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_frame_small.mp3",false)
                    performWithDelay(self,function()
                        gLobalSoundManager:setBackgroundMusicVolume(1)
                    end,1)
                    self.m_ChangeReelView:playOver()
                end,
                1.5,
                self:getModuleName()
            )

            self.m_ChangeReelView:playWinEffect()
            self:setWinSymbolLight()
            scheduler.performWithDelayGlobal(
                function()
                    self:changeXWildToSymbol()
                end,
                0.4,
                self:getModuleName()
            )
        end
    )
end

---上方随机滚动条开始滚动
function CodeGameScreenAfricaRiseMachine:playAddRunChangeWildXReel()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata.changeSignal then
        local data = {}
        data.type = selfdata.changeSignal
        self.m_ChangeReelView:InitBeginMove()
        gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_frame_big.mp3")
        self.m_ChangeReelView:setEndValue(data)
        self.m_ChangeReelView:beginMove()
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
    end
end

function CodeGameScreenAfricaRiseMachine:setWinSymbolLight( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata.changeSignal then
        local winType = selfdata.changeSignal
        for iRow = self.m_iAddReelRowNum, 1, -1 do
            for iCol = 1, self.m_iReelColumnNum do
                local type = self:getMatrixPosSymbolType(iRow, iCol)
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if type == winType then
                    if targSp then
                        targSp:runAnim("light", false)
                    end
                end
            end
        end
    end
end
--钻石飞上去
function CodeGameScreenAfricaRiseMachine:flyWild()
    local node = self:findChild("gundong")
    local endPos = node:convertToWorldSpace(cc.p(0, 0))
    local num = 1
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_wild_fly.mp3")
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iAddReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            --self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node and node.p_symbolType == self.SYMBOL_WILD_X then
                -- 对应位置创建
                local targSp = self:getSlotNodeWithPosAndType(self.SYMBOL_WILD_X, iRow, iCol, true)
                targSp:setScale(self.m_machineRootScale)
                self:addChild(targSp, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                local pos = cc.p(util_getConvertNodePos(node, targSp))
                targSp:setPosition(pos)
                local actionList = {}
                actionList[#actionList + 1] = cc.DelayTime:create(0.1 + num * 0.05)
                actionList[#actionList + 1] = cc.ScaleTo:create(0.2, 1.5)
                actionList[#actionList + 1] = cc.Spawn:create(cc.ScaleTo:create(0.6, 1), cc.MoveTo:create(0.6, cc.p(endPos.x, endPos.y)))
                actionList[#actionList + 1] =
                    cc.CallFunc:create(
                    function()
                        targSp:removeFromParent()
                        targSp:resetReelStatus()
                        self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
                    end
                )
                local sq = cc.Sequence:create(actionList)
                targSp:runAction(sq)
                num = num + 1
            end
        end
    end

    scheduler.performWithDelayGlobal(
        function()
            self.m_ChangeReelView:changeToWild()
        end,
        0.95,
        self:getModuleName()
    )
    local delayTime = 1 + num * 0.05
    scheduler.performWithDelayGlobal(
        function()
            self:playAddRunChangeWildXReel()
        end,
        delayTime,
        self:getModuleName()
    )
end
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAfricaRiseMachine:addSelfEffect()
    self.m_bClickSpin = false
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local clickEnable = true
    if selfdata ~= nil then
        --收集金币效果
        if selfdata.collectPositions ~= nil and #selfdata.collectPositions > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 5
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_COLLECT_ICON -- 动画类型
            clickEnable = false
        end
        --升行
        if selfdata.xPositions ~= nil and #selfdata.xPositions > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 2
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_ADD_REEL -- 动画类型
            clickEnable = false
        end
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --spin +1
        if self:isAddSpinSymbol() then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 3
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_ADD_SPIN -- 动画类型
        end
    end
    if clickEnable == true and self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
        self.m_collectView:setButtonTouchEnabled(true)
    end
end

function CodeGameScreenAfricaRiseMachine:isAddSpinSymbol()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == self.SYMBOL_SPIN_ADD then
                return true
            end
        end
    end
    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAfricaRiseMachine:MachineRule_playSelfEffect(effectData)
    local isCollectGame = nil
    if effectData.p_selfEffectType == self.EFFECT_COLLECT_ICON then
        self:collectSymbolIconFly(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_ADD_REEL then
        self:playAddReelEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_ADD_SPIN then
        self:playAddSpinEffect(effectData)
    end
    return true
end

function CodeGameScreenAfricaRiseMachine:removeFlynode(node)
    node:setVisible(true)
    node:removeFromParent()
    local symbolType = node.p_symbolType
    self:pushSlotNodeToPoolBySymobolType(symbolType, node)
end

--收集不触发效果可以快点
function CodeGameScreenAfricaRiseMachine:IsCanClickSpin()
    local isSpin = true
    for i = 1, #self.m_gameEffects do
        local effectData = self.m_gameEffects[i]
        local effectType = effectData.p_effectType
        if effectType == GameEffect.EFFECT_BONUS or effectType == GameEffect.EFFECT_FREE_SPIN then
            isSpin = false
        end
    end
    return isSpin
end

-- 收集动画
function CodeGameScreenAfricaRiseMachine:collectSymbolIconFly(effectData)
    local flyTime = 0.5
    local actionframeTimes = 0.5
    local FlyNum = 0
    local lastData = self:BaseMania_getCollectData()
    local collectData = {}
    collectData.collectCoinsPool = lastData.p_collectCoinsPool
    collectData.collectLeftCount = lastData.p_collectLeftCount
    collectData.collectTotalCount = lastData.p_collectTotalCount
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_collect.mp3")
    local endPos = self.m_collectView:getCollectPos()
    self.m_SmallReelsView:removeAllSlotsNodeMark()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iAddReelRowNum, 1, -1 do
            local reelsIndex = self:getPosReelIdx(iRow, iCol)
            local isHave = self:getSymbolIcon(reelsIndex)
            if isHave then
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if node then
                    -- 对应位置创建 jackpot 图标
                    local newCorn = self:createMoveMarker()
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
                    actionList[#actionList + 1] = cc.ScaleTo:create(0.1, 2)
                    actionList[#actionList + 1] = cc.DelayTime:create(0.2)
                    -- local scale = cc.ScaleTo:create(flyTime, 1)
                    local bez = cc.BezierTo:create(flyTime, {cc.p(pos.x + (pos.x - endPos.x) * 0.5, pos.y), cc.p(endPos.x, pos.y), endPos})
                   --cc.Spawn:create(scale, bez)
                    actionList[#actionList + 1] = bez 
                    actionList[#actionList + 1] =
                        cc.CallFunc:create(
                        function()
                            newCorn:removeFromParent()
                        end
                    )
                    local sq = cc.Sequence:create(actionList)
                    newCorn:runAction(sq)

                    local particle = self:createFlyPart()
                    particle:setPosition(pos)
                    self:addChild(particle, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                    local actionList2 = {}
                    actionList2[#actionList2 + 1] = cc.DelayTime:create(0.3)
                    -- local scale1 = cc.ScaleTo:create(flyTime, 1)
                    local bez1 = cc.BezierTo:create(flyTime, {cc.p(pos.x + (pos.x - endPos.x) * 0.5, pos.y), cc.p(endPos.x, pos.y), endPos})
                    actionList2[#actionList2 + 1] = bez1 --cc.Spawn:create(scale1, bez1)
                    actionList2[#actionList2 + 1] =
                        cc.CallFunc:create(
                        function()
                            particle:removeFromParent()
                        end
                    )
                    local particleSq = cc.Sequence:create(actionList2)
                    particle:runAction(particleSq)

                    FlyNum = FlyNum + 1
                end
            end
        end
    end

    if FlyNum and FlyNum > 0 then
        if self:IsCanClickSpin() then
            if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
                self.m_collectView:setButtonTouchEnabled(true)
            end
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            scheduler.performWithDelayGlobal(
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                2.8,
                self:getModuleName()
            )
        end
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_collect_coin_fankui.mp3")
                self:updateCollect(1.0, collectData)
                self.m_collectView:showAddAnim()
            end,
            0.8,
            self:getModuleName()
        )
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end
--创建spin +1
function CodeGameScreenAfricaRiseMachine:createSpinSymbol()
    local csb = util_createAnimation("Socre_AfricaRise_scatter_add1.csb")
    return csb
end

--开始播放升行效果
function CodeGameScreenAfricaRiseMachine:playAddSpinEffect(effectData)
    local FlyNum = 0
    local data = self.m_runSpinResultData
    if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
        self.m_iFreeSpinTimes = data.p_freeSpinsTotalCount
        self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    end
    self:removeScatterNodeList()
    local endPos = self.m_baseFreeSpinBar:getCollectPos()
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_add_spin_fly.mp3")

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node and node.p_symbolType == self.SYMBOL_SPIN_ADD then
                -- 对应位置创建 jackpot 图标
                local respinNode = self.m_SmallReelsView:getRespinNode(iRow, iCol)
                if respinNode then
                    local slotNode = respinNode:getLastNode()
                    if slotNode then
                        slotNode:setVisible(true)
                    end
                end
                self.m_SmallReelsView:playAllSpinAddNodeIdle(iCol, iRow)
                local fly = self:createSpinSymbol()
                local root = self.m_machineNode:getChildByName("root")
                node:runAnim("idleframe2")
                fly:setScale(self.m_machineRootScale)
                self:addChild(fly, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                local pos = cc.p(util_getConvertNodePos(node, fly))
                fly:setPosition(pos)
                local actionList = {}
                actionList[#actionList + 1] = cc.DelayTime:create(0.2)
                actionList[#actionList + 1] = cc.ScaleTo:create(0.1, 2)
                actionList[#actionList + 1] = cc.Spawn:create(cc.ScaleTo:create(0.5, 1), cc.MoveTo:create(0.5, cc.p(endPos.x, endPos.y)))
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
    end

    globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount + FlyNum --data.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = globalData.slotRunData.totalFreeSpinCount + FlyNum -- data.p_freeSpinsTotalCount

    if FlyNum and FlyNum > 0 then
        scheduler.performWithDelayGlobal(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            1.0,
            self:getModuleName()
        )
        scheduler.performWithDelayGlobal(
            function()
                self.m_baseFreeSpinBar:runCsbAction("animation0", false)
            end,
            0.8,
            self:getModuleName()
        )
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_addspin_change_num.mp3")
                self.m_baseFreeSpinBar:changeFreeSpinByCount()
            end,
            1.0,
            self:getModuleName()
        )
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

--升行
function CodeGameScreenAfricaRiseMachine:playAddReelEffect(effectData)
    self.m_addRow = 1
    self.m_effectData = effectData
    self:setRespinViewDark()
    self:playAllWildXNodeAni()
    scheduler.performWithDelayGlobal(
        function()
            self:playAddRowEffect()
        end,
        0.2,
        self:getModuleName()
    )
end

--进行下一轮
function CodeGameScreenAfricaRiseMachine:playNextAddReel()
    --如果有spin+1则先收集 没有的话进行下一次升行
    if self:isAddReelAddSpinSymbol() then
        self:playAddReelAddSpinEffect()
    else
        self:playNextAddReelEffect()
    end
end
--再次升行
function CodeGameScreenAfricaRiseMachine:playNextAddReelEffect()
    self.m_addRow = self.m_addRow + 1
    local _row = self.m_iReelRowNum + self.m_addRow
    --到达升行的的目标后钻石开始飞上去
    if _row > self.m_iAddReelRowNum then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --刷新 freespin 次数
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        end
        self:setRespinViewDark()
        self:showAllSoltNodeDark()
        scheduler.performWithDelayGlobal(
            function()
                self:showSingleReelSlotsNodeVisible(false)
                self:removeWildXNodeList()
                self:changeAddReelData()
                scheduler.performWithDelayGlobal(
                    function()
                        --变信号
                        self:flyWild()
                        self.m_ChangeReelView:playFlyWild()
                    end,
                    1.5,
                    self:getModuleName()
                )
            end,
            0.4,
            self:getModuleName()
        )
        return
    else
        scheduler.performWithDelayGlobal(
            function()
                self:setRespinViewDark()
                self:playAllWildXNodeAni()
                self:playAddRowEffect()
            end,
            0.2,
            self:getModuleName()
        )
    end
end

function CodeGameScreenAfricaRiseMachine:isAddReelAddSpinSymbol()
    local iRow = self.m_iReelRowNum + self.m_addRow
    for iCol = 1, self.m_iReelColumnNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        if symbolType == self.SYMBOL_SPIN_ADD then
            return true
        end
    end
    return false
end

-- 一行一行的添加spin +1 的效果
function CodeGameScreenAfricaRiseMachine:playAddReelAddSpinEffect()
    local FlyNum = 0
    local endPos = self.m_baseFreeSpinBar:getCollectPos()
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_add_spin_fly.mp3")
    local iRow = self.m_iReelRowNum + self.m_addRow
    self:removeScatterNodeList()
    for iCol = 1, self.m_iReelColumnNum do
        local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
        if node and node.p_symbolType == self.SYMBOL_SPIN_ADD then
            -- 对应位置创建
            local respinNode = self.m_SmallReelsView:getRespinNode(iRow, iCol)
            if respinNode then
                local slotNode = respinNode:getLastNode()
                if slotNode then
                    slotNode:setVisible(true)
                end
            end
            self.m_SmallReelsView:playAllSpinAddNodeIdle(iCol, iRow)
            local fly = self:createSpinSymbol()
            local root = self.m_machineNode:getChildByName("root")
            node:runAnim("idleframe2")
            fly:setScale(self.m_machineRootScale)
            self:addChild(fly, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
            local pos = cc.p(util_getConvertNodePos(node, fly))
            fly:setPosition(pos)
            local actionList = {}
            actionList[#actionList + 1] = cc.DelayTime:create(0.2)
            actionList[#actionList + 1] = cc.ScaleTo:create(0.1, 2)
            actionList[#actionList + 1] = cc.Spawn:create(cc.ScaleTo:create(0.5, 1), cc.MoveTo:create(0.5, cc.p(endPos.x, endPos.y)))
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
    globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount + FlyNum
    globalData.slotRunData.totalFreeSpinCount = globalData.slotRunData.totalFreeSpinCount + FlyNum
    if FlyNum and FlyNum > 0 then
        scheduler.performWithDelayGlobal(
            function()
                self.m_baseFreeSpinBar:runCsbAction("animation0", false)
            end,
            0.8,
            self:getModuleName()
        )
        scheduler.performWithDelayGlobal(
            function()
                gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_addspin_change_num.mp3")
                self.m_baseFreeSpinBar:changeFreeSpinByCount()
                self:playNextAddReelEffect()
            end,
            1.0,
            self:getModuleName()
        )
    end
end

function CodeGameScreenAfricaRiseMachine:playAddRowEffect()
    local _row = self.m_iReelRowNum + self.m_addRow
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_reel_up.mp3")
    if _row == 5 then
        self.m_logo:runCsbAction("animation1", false)
    end
    self:runCsbAction(
        _row .. "x5",
        false,
        function()
            local node = self:findChild("Node_eff")
            local worldPos = node:convertToWorldSpace(cc.p(0, 0))
            local addWildEffect = util_createView("CodeAfricaRiseSrc.AfricaRiseAddRowEffect")
            addWildEffect:setPosition(worldPos)
            addWildEffect:setScale(self.m_machineRootScale)
            self:addChild(addWildEffect, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
            if globalData.slotRunData.machineData.p_portraitFlag then
                addWildEffect.getRotateBackScaleFlag = function(  ) return false end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = addWildEffect})
            addWildEffect:playAddRowEffect(
                function()
                    addWildEffect:removeFromParent()
                end
            )
            --开始滚动
            scheduler.performWithDelayGlobal(
                function()
                    self.m_SmallReelsView:startAddReelMove()
                end,
                0.2,
                self:getModuleName()
            )
            --开始停止
            scheduler.performWithDelayGlobal(
                function()
                    self:stopAddReelSmallReelsRun()
                end,
                0.5,
                self:getModuleName()
            )
        end
    )
    --构造盘面数据
    local SmallReelsNodeInfo = self:createAddReelSmallReelsNodeInfo()
    self.m_SmallReelsView:initAddReelRespinElement(
        SmallReelsNodeInfo,
        _row,
        self.m_iReelColumnNum,
        function()
        end
    )
end

function CodeGameScreenAfricaRiseMachine:changeXWildToSymbol()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local symbolType
    if selfdata.changeSignal then
        symbolType = selfdata.changeSignal
    else
        return
    end

    local node = self:findChild("gundong")
    local startPos = node:convertToWorldSpace(cc.p(0, 0))
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_fly_down.mp3")

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iAddReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            --self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node and node.p_symbolType == self.SYMBOL_WILD_X then
                -- 对应位置创建图标
                local targSp = self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, true)
                targSp:setScale(self.m_machineRootScale * 1.8)
                targSp:runAnim("idleframe")
                self:addChild(targSp, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
                local endPos = cc.p(util_getConvertNodePos(node, targSp))
                targSp:setPosition(startPos)

                local actionList = {}
                actionList[#actionList + 1] = cc.DelayTime:create(0.2)
                actionList[#actionList + 1] = cc.Spawn:create(cc.ScaleTo:create(0.6, 1), cc.MoveTo:create(0.6, cc.p(endPos.x, endPos.y)))
                actionList[#actionList + 1] =
                    cc.CallFunc:create(
                    function()
                        --换类型加换层级
                        node:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                        local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
                        local pos = self.m_slotParents[iCol].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                        node:removeFromParent()
                        node:resetReelStatus()
                        node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                        local zorder = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + self:getBounsScatterDataZorder(self.SYMBOL_WILD_X)
                        node:setLocalZOrder(zorder + iCol)
                        node:setPosition(cc.p(pos.x, pos.y))
                        self.m_slotParents[iCol].slotParent:addChild(node, zorder)
                        node:runAnim("idleframe")
                        --删除飞行的
                        targSp:removeFromParent()
                        targSp:resetReelStatus()
                        self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
                    end
                )
                local sq = cc.Sequence:create(actionList)
                targSp:runAction(sq)
            end
        end
    end
    scheduler.performWithDelayGlobal(
        function()
            self:showAllSoltNodeLight() --没有连线则全部变亮
            --这时候背景音乐再渐变
            if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE or self:checktriggerSpecialGame() then
                self:removeSoundHandler() -- 移除监听
            else
                self:reelsDownDelaySetMusicBGVolume()
                if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
                    self.m_collectView:setButtonTouchEnabled(true)
                end
            end
            self.m_effectData.p_isPlay = true
            self:playGameEffect()
        end,
        2.5,
        self:getModuleName()
    )
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenAfricaRiseMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenAfricaRiseMachine:initCollectInfo(spinData, lastBetId, isTriggerCollect)
    self:updateCollect(time)
end

function CodeGameScreenAfricaRiseMachine:updateCollect(time)
    local collectData = self:BaseMania_getCollectData()
    self.m_collectView:updateCollect(collectData.p_collectCoinsPool, collectData.p_collectLeftCount, collectData.p_collectTotalCount, time)
end

function CodeGameScreenAfricaRiseMachine:BaseMania_initCollectDataList()
    local CollectData = require "data.slotsdata.CollectData"
    --收集数组
    self.m_collectDataList = {}
    --默认总数
    local pools = {200, 20}
    for i = 1, 2 do
        self.m_collectDataList[i] = CollectData.new()
        self.m_collectDataList[i].p_collectTotalCount = pools[i]
        self.m_collectDataList[i].p_collectLeftCount = 0
        self.m_collectDataList[i].p_collectCoinsPool = 0
        self.m_collectDataList[i].p_collectChangeCount = 0
    end
end

--更新收集数据 addCount增加的数量  addCoins增加的奖金
function CodeGameScreenAfricaRiseMachine:BaseMania_updateCollect(addCount, addCoins, index, totalCount)
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
function CodeGameScreenAfricaRiseMachine:BaseMania_completeCollectBonus(index, totalCount)
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

function CodeGameScreenAfricaRiseMachine:getSymbolIcon(reelsIndex)
    local isHave = false
    if self.m_runSpinResultData.p_selfMakeData then
        local posTable = self.m_runSpinResultData.p_selfMakeData.collectPositions
        if posTable and #posTable >= 0 then
            for k, v in pairs(posTable) do
                local index = tonumber(v)
                if reelsIndex == index then
                    isHave = true
                end
            end
        end
    end
    return isHave
end

--角标
function CodeGameScreenAfricaRiseMachine:creatMarker()
    local csb = util_createAnimation("AfricaRise_shoujitubiao.csb")
    return csb
end

--收集图标
function CodeGameScreenAfricaRiseMachine:createMoveMarker()
    local addNode = cc.Node:create()
    local csb = util_createAnimation("AfricaRise_shoujitubiao.csb")
    csb:playAction("shouji", false)
    addNode:addChild(csb)
    return addNode
end

--收集粒子效果
function CodeGameScreenAfricaRiseMachine:createFlyPart()
    local par = cc.ParticleSystemQuad:create("effect/AfricaRise_Traillizi.plist")
    return par
end

--添加收集角标
function CodeGameScreenAfricaRiseMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self, node, symbolType, row, col, isLastSymbol)
    if node:isLastSymbol() then
        node:changeImage()
        if self.m_outOnlin then
            --第一次进游戏 不显示收集的图标
            return
        end
        local reelsIndex = self:getPosReelIdx(row, col)
        local isHave = self:getSymbolIcon(reelsIndex)
        if isHave then
            if node.m_icon == nil then
                node.m_icon = self:creatMarker()
                node.m_icon:setPosition(cc.p(40, -30))
                node:addChild(node.m_icon, 2)
            end
        end
    end
end

--[[
    @desc: 计算单线
]]
function CodeGameScreenAfricaRiseMachine:getWinLineSymboltType(winLineData, lineInfo)
    local enumSymbolType = winLineData.p_type
    local iconsPos = winLineData.p_iconPos
    for posIndex = 1, #iconsPos do
        local posData = iconsPos[posIndex]
        local rowColData = self:getRowAndColByPos(posData)
        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData -- 连线元素的 pos信息
    end

    return enumSymbolType
end

--设置基础轮盘 长度
function CodeGameScreenAfricaRiseMachine:changeAddReelData()
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iAddReelRowNum
        columnData:updateShowColCount(self.m_iAddReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iAddReelRowNum
    end
    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x,
            y = rect.y,
            width = rect.width,
            height = self.m_fReelHeigth
        }
    )
end

--设置基础轮盘 长度
function CodeGameScreenAfricaRiseMachine:changeReelLength(direction)
    for i = 1, self.m_iReelColumnNum, 1 do
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum
    end

    local NowHeight = self.m_iReelRowNum * self.m_SlotNodeH
    local endHeight = self.m_iAddReelRowNum * self.m_SlotNodeH
    local moveSpeed = 0
    local scheduleDelayTime = 0.016

    if direction > 0 then
        direction = 1
        local _row = self.m_iReelRowNum + self.m_addRow
        NowHeight = (_row - 1) * self.m_SlotNodeH
        endHeight = _row * self.m_SlotNodeH
        moveSpeed = self.m_SlotNodeH / 20
    else
        -- scheduleDelayTime = 0.5 * moveSpeed
        direction = -1
        NowHeight = self.m_iAddReelRowNum * self.m_SlotNodeH
        endHeight = self.m_iReelRowNum * self.m_SlotNodeH
        moveSpeed = ((self.m_iAddReelRowNum - self.m_iReelRowNum) * self.m_SlotNodeH) / 20
    end

    self.m_updateReelHeightID =
        scheduler.scheduleGlobal(
        function(delayTime)
            local distance = 0
            if direction > 0 then
                if NowHeight + moveSpeed > endHeight then
                    distance = endHeight
                    scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                else
                    distance = NowHeight + moveSpeed
                    NowHeight = NowHeight + moveSpeed
                end
            else
                if NowHeight + moveSpeed * direction < endHeight then
                    distance = endHeight
                    NowHeight = endHeight
                    scheduler.unscheduleGlobal(self.m_updateReelHeightID)
                else
                    distance = moveSpeed * direction
                    NowHeight = NowHeight + moveSpeed * direction
                end
            end
            local rect = self.m_onceClipNode:getClippingRegion()
            self.m_onceClipNode:setClippingRegion(
                {
                    x = rect.x,
                    y = rect.y,
                    width = rect.width,
                    height = NowHeight
                }
            )
        end,
        scheduleDelayTime
    )
end

-- 创建单个滚动小块轮盘
function CodeGameScreenAfricaRiseMachine:createSmallReels()
    local endTypes = {}
    local randomTypes = {0, 1, 2, 3, 4, 5, 6, 7, 8, 200}

    self.m_SmallReelsView = util_createView("CodeAfricaRiseSrc.AfricaRiseRespinView", "CodeAfricaRiseSrc.AfricaRiseRespinNode", self)
    self.m_SmallReelsView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_SmallReelsView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 100)

    --构造盘面数据
    local SmallReelsNodeInfo = self:createSmallReelsNodeInfo()

    self.m_SmallReelsView:setEndSymbolType(endTypes, randomTypes)
    self.m_SmallReelsView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_SmallReelsView:initRespinElement(
        SmallReelsNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            -- self:runNextReSpinReel()
        end
    )
    --显示单独滚轮盘信息，并且隐藏整个滚轮盘
    self:showSingleReelSlotsNodeVisible(true)
end

-- 是否显示单独滚的小块轮盘
function CodeGameScreenAfricaRiseMachine:showSingleReelSlotsNodeVisible(states)
    if states then
        --隐藏 盘面信息
        self:setReelSlotsNodeVisible(false)
        self.m_SmallReelsView:setVisible(true)
        self.m_SmallReelsView:setAllSymbolSlotsNodeVisible()
        local wildXData = self.m_SmallReelsView:getAllWildXSlotsNode()
        for i, v in ipairs(wildXData) do
            v:setVisible(true)
        end
        self:findChild("heng_xian"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
        self:findChild("lineNode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    else
        self:setReelSlotsNodeVisible(true)
        self:removeScatterNodeList()
        self.m_SmallReelsView:setVisible(false)
        self:findChild("heng_xian"):setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + 500)
        self:findChild("lineNode"):setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + 500)
    end
end
--所有的滚轴图片变暗
function CodeGameScreenAfricaRiseMachine:showAllSoltNodeDark()
    for iRow = self.m_iAddReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            local type = self:getMatrixPosSymbolType(iRow, iCol)
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if type ~= self.SYMBOL_WILD_X then
                if targSp then
                    targSp:runAnim("darkidle", false)
                end
            else
                if targSp then
                    targSp:runAnim("idleframe2", true)
                end
            end
        end
    end
end
--所有的滚轴图片变liang
function CodeGameScreenAfricaRiseMachine:showAllSoltNodeLight()
    if #self.m_reelResultLines < 1 then
        for iRow = self.m_iAddReelRowNum, 1, -1 do
            for iCol = 1, self.m_iReelColumnNum do
                local type = self:getMatrixPosSymbolType(iRow, iCol)
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    targSp:runAnim("light", false)
                end
            end
        end
    end
end
--隐藏盘面信息
function CodeGameScreenAfricaRiseMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iAddReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:setVisible(status)
            end
        end
    end
end

----构造小块单独滚 所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenAfricaRiseMachine:createSmallReelsNodeInfo()
    local smallNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            -- 处理第一次进入轮盘时的情况
            if symbolType == nil then
                symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
            end

            -- 不是freespin或者freespin触发的状态 每次进入都随机普通轮盘
            if self:isTriggerFreespinOrInFreespin() == false then
                symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
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

function CodeGameScreenAfricaRiseMachine:createAddReelSmallReelsNodeInfo()
    local smallNodeInfo = {}
    local iRow = self.m_iReelRowNum + self.m_addRow
    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        --信号类型
        -- local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

        local symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)

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
    return smallNodeInfo
end

function CodeGameScreenAfricaRiseMachine:isTriggerFreespinOrInFreespin()
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

---
---
-- 点击快速停止reel
--
function CodeGameScreenAfricaRiseMachine:quicklyStopReel()
    print("quicklyStopReel  调用了快停")

    self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。

    if self.m_SmallReelsView then
        self.m_SmallReelsView:quicklyStop()
    end
end

-- 开始刷帧
function CodeGameScreenAfricaRiseMachine:registerReelSchedule()
    self.m_SmallReelsView:startMove()
    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:onUpdate(
            function(delayTime)
                self:reelSchedulerHanlder(delayTime)
            end
        )
    end
end

function CodeGameScreenAfricaRiseMachine:reelSchedulerHanlder(delayTime)
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
            for iRow = self.m_iAddReelRowNum, 1, -1 do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if targSp then
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                    local order = self:getBounsScatterDataZorder(symbolType) + 10 * iCol - iRow
                    targSp.p_showOrder = order
                    targSp:setLocalZOrder(order)
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = iRow, iY = iCol}
                    targSp.m_bInLine = true
                    targSp:setLinePos(linePos)
                    targSp:setVisible(false)
                    targSp:setTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_WILD_X then
                        local slotParent = targSp:getParent()
                        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                        targSp:removeFromParent()
                        targSp:resetReelStatus()
                        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + targSp.m_showOrder, targSp:getTag())
                        targSp:setPosition(cc.p(pos.x, pos.y))
                    end
                else
                    local columnData = self.m_reelColDatas[iCol]
                    local pos = self:getPosByColAndRow(iCol, iRow)
                    targSp = self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, true)
                    local order = self:getBounsScatterDataZorder(symbolType) + 10 * iCol - iRow
                    targSp.p_slotNodeH = columnData.p_showGridH
                    targSp.p_showOrder = order
                    targSp.p_cloumnIndex = iCol
                    targSp.p_rowIndex = iRow
                    targSp.m_isLastSymbol = true
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = iRow, iY = iCol}
                    targSp.m_bInLine = true
                    targSp:setLinePos(linePos)
                    targSp:setPosition(pos)
                    targSp:setVisible(false)
                    targSp:setTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_WILD_X then
                        local slotParent = self:getReelParent(iCol)
                        local posWorld = slotParent:convertToWorldSpace(cc.p(pos.x, pos.y))
                        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + order, targSp:getTag())
                        targSp:setPosition(cc.p(pos.x, pos.y))
                    else
                        self:getReelParent(iCol):addChild(targSp, order, self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                    end
                end
            end
        end

        self:stopSmallReelsRun()

        self.m_reelDownAddTime = 0
    end
end

function CodeGameScreenAfricaRiseMachine:getPosByColAndRow(col, row)
    local posX = self.m_SlotNodeW
    local posY = (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end

--接收到数据开始停止滚动
function CodeGameScreenAfricaRiseMachine:stopSmallReelsRun()
    local storedNodeInfo = {}
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_SmallReelsView:setRunEndInfo(storedNodeInfo, unStoredReels)
end

--添加的一行开始停止滚动
function CodeGameScreenAfricaRiseMachine:stopAddReelSmallReelsRun()
    local storedNodeInfo = {}
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_SmallReelsView:setRunEndInfo(storedNodeInfo, unStoredReels)
end

function CodeGameScreenAfricaRiseMachine:getRespinReelsButStored(storedInfo)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iAddReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            local type = self:getMatrixPosSymbolType(iRow, iCol)
            if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
            end
        end
    end
    return reelData
end

function CodeGameScreenAfricaRiseMachine:getMatrixPosSymbolType(iRow, iCol)
    local rowCount = #self.m_runSpinResultData.p_reels
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowIndex == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end

---滚轮停止复用respin停止自定义事件
function CodeGameScreenAfricaRiseMachine:reSpinReelDown(addNode)
    self:slotReelDown()
    self.m_SmallReelsView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
end

-- 老虎机滚动结束调用
function CodeGameScreenAfricaRiseMachine:slotReelDown()
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

    self:reelDownNotifyChangeSpinStatus()

    self:delaySlotReelDown()

    self:stopAllActions()

    self:reelDownNotifyPlayGameEffect()

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenAfricaRiseMachine:checkUpdateReelDatas(parentData )
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

    return reelDatas

end

function CodeGameScreenAfricaRiseMachine:beginReel()
    self.m_clickBegin = true
    if self.m_bBonusGame == true then
        if self.m_bonusGameReel ~= nil then
            self.m_bonusGameReel:beginMiniReel()
        end
    else
        self.m_collectView:setButtonTouchEnabled(false)

        self:resetReelDataAfterReel()

        for i = 1, #self.m_slotParents do
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            local reelDatas = self:checkUpdateReelDatas(parentData)

            self:checkReelIndexReason(parentData)

            parentData.isDone = false
            parentData.isResActionDone = false
            parentData.isReeling = false
            parentData.moveSpeed = self.m_configData.p_reelMoveSpeed
            -- 判断处理是否每列需要等待时间 开始滚动
            if self.m_reelDelayTime > 0 and i > 1 then
                parentData.moveSpeed = 0
                local clipNode = slotParent:getParent()
                clipNode:stopAllActions()
                self:registerReelSchedule()
            else
                parentData.isReeling = true
                self:registerReelSchedule()
            end
        end
    end
end

--
--单个滚动停止回调
--
function CodeGameScreenAfricaRiseMachine:slotLocalOneReelDown(icol, irow)
   
    if self.m_stcValidSymbolMatrix == nil then
        return
    end
    if #self.m_stcValidSymbolMatrix < irow then
        return
    end
    if #self.m_stcValidSymbolMatrix[irow] < icol then
        return
    end
    -- 播放落地动画
    local symbolType = self.m_stcValidSymbolMatrix[irow][icol]
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local index = 1
        if self.m_scatterDownNum == 1 then
            index = 1
        elseif self.m_scatterDownNum == 2 then
            index = 2
        elseif self.m_scatterDownNum >= 3 then
            index = 3
        end
        if (icol == 5 and self.m_scatterDownNum > 1) or icol < 5 then
            local scatterDownSounds = "AfricaRiseSounds/sound_AfricaRise_scatter" .. index .. ".mp3"
            
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( icol,scatterDownSounds,TAG_SYMBOL_TYPE.SYMBOL_SCATTER )
            else
                gLobalSoundManager:playSound(scatterDownSounds)
            end
            
            
            local node = self.m_SmallReelsView:getRespinNode(irow, icol)
            if node then
                local slotNode = node:getLastNode()
                if slotNode then
                    slotNode:setVisible(false)
                    -- slotNode:runAnim("buling", false)
                    self:createScatterSymbol(node, symbolType)
                end
            end
            self.m_scatterDownNum = self.m_scatterDownNum + 1
        end
    elseif symbolType == self.SYMBOL_SPIN_ADD then
        local node = self.m_SmallReelsView:getRespinNode(irow, icol)
        if node then
            local slotNode = node:getLastNode()
            if slotNode then
                slotNode:setVisible(false)
                self:createScatterSymbol(node, symbolType)
            end
        end
    elseif symbolType == self.SYMBOL_WILD_X then
        gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_wild_ground.mp3")
    end
end
-- 创建一个reels上层的特殊显示信号信号
function CodeGameScreenAfricaRiseMachine:createScatterSymbol(endNode, symbolType)
    local fatherNode = endNode

    local symbolNode = self:getSlotNodeBySymbolType(symbolType)
    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("Sp_reel"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    self:findChild("Sp_reel"):addChild(symbolNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + endNode.p_rowIndex)
    symbolNode:setPosition(pos)
    symbolNode:runAnim("buling", false)
    if self.m_ScatterNodeList == nil then
        self.m_ScatterNodeList = {}
    end
    symbolNode.p_colIndex = endNode.p_colIndex
    symbolNode.p_rowIndex = endNode.p_rowIndex
    table.insert(self.m_ScatterNodeList, symbolNode)
end
function CodeGameScreenAfricaRiseMachine:removeScatterNodeList()
    for i, v in ipairs(self.m_ScatterNodeList) do
        v:removeFromParent()
        v:resetReelStatus()
        self:pushSlotNodeToPoolBySymobolType(v.p_symbolType, v)
    end
    self.m_ScatterNodeList = {}
end

-- 创建一个reels上层的特殊显示信号信号
function CodeGameScreenAfricaRiseMachine:createOneActionSymbol(endNode)
    local fatherNode = endNode

    local wildNode = self:getSlotNodeBySymbolType(self.SYMBOL_WILD_X)
    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("Sp_reel"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    self:findChild("Sp_reel"):addChild(wildNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + endNode.p_rowIndex)
    wildNode:setPosition(pos)
    wildNode:runAnim(
        "actionframe",
        false,
        function()
            wildNode:runAnim("idleframe2", true)
        end
    )
    table.insert(self.m_WildXNodeList, wildNode)

    return node
end

function CodeGameScreenAfricaRiseMachine:playAllWildXNodeAni()
    for i, v in ipairs(self.m_WildXNodeList) do
        v:runAnim(
            "actionframe",
            false,
            function()
                v:runAnim("idleframe2", true)
            end
        )
    end
end

function CodeGameScreenAfricaRiseMachine:removeWildXNodeList()
    for i, v in ipairs(self.m_WildXNodeList) do
        v:removeFromParent()
        v:resetReelStatus()
        self:pushSlotNodeToPoolBySymobolType(v.p_symbolType, v)
    end
    self.m_WildXNodeList = {}
end


----
--- 处理spin 成功消息
--
function CodeGameScreenAfricaRiseMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" or spinData.action == "FEATURE" then
        release_print("消息返回胡来了")
        self.m_clickBegin = false

        self:operaSpinResultData(param)
        
        local rowNum = #self.m_runSpinResultData.p_reels
        if self.m_runSpinResultData.p_selfMakeData and rowNum > 3 then
            -- print("一共行 m_iAddReelRowNum ---" .. self.m_iAddReelRowNum)
            local num = rowNum - 3
            for i = 1, num do
                self.m_stcValidSymbolMatrix[3 + i] = {0, 0, 0, 0, 0}
                self.m_iAddReelRowNum = self.m_iAddReelRowNum + 1
            end
        else
            self.m_iAddReelRowNum = 3
            self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()
        end

        self:operaUserInfoWithSpinResult(param )
        
        gLobalNoticManager:postNotification("TopNode_updateRate")

        if self.m_bonusGameReel ~= nil then
            --设置主轮盘数据  防止阻塞
            self.m_isWaitingNetworkData = false
            self:setGameSpinStage(GAME_MODE_ONE_RUN)
            --设置副轮盘 数据
            local resultData = spinData.result
            self.m_BonusWinCoins = spinData.result.selfData.bonusWinCoins
            -- local totalNum = self.m_runSpinResultData.p_collectNetData[1].collectCoinsPool
            self.m_bonusGameReel:netWorkCallFun(resultData)
            self.m_bonusGameReel:setBonusLeftTimes(spinData.result.selfData.currCell.ext)
            self.m_bonusGameReel:setBonusWinCoin(self.m_BonusWinCoins)
            -- self.m_bonusGameReel:UpdataTotalBetNum(totalNum)
            self:setLastWinCoin(self.m_runSpinResultData.p_bonusWinCoins)
        else
            --处理freespin 开始是wild 下落效果
            if self.m_iFreeSpinStartDelayTime  > 0 then
                performWithDelay(
                    self,
                    function()
                        self:updateNetWorkData()
                        self.m_iFreeSpinStartDelayTime = 0
                    end,
                    self.m_iFreeSpinStartDelayTime
                )
            else
                self:updateNetWorkData()
            end
        end

    end
end

function CodeGameScreenAfricaRiseMachine:getRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = self.m_iAddReelRowNum - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

function CodeGameScreenAfricaRiseMachine:getPosReelIdx(iRow, iCol)
    local index = (self.m_iAddReelRowNum - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenAfricaRiseMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_bSlotRunning = true
    --显示单独滚轮盘信息，并且隐藏整个滚轮盘
    self.m_outOnlin = false
    self.m_scatterDownIndex = 1
    local isWait = self:changeNormalReel()
    if self.m_map then
        self.m_map:hideMapView()
    end
    if isWait then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    self.m_scatterDownNum = 1
    return isWait -- 用作延时点击spin调用
end

function CodeGameScreenAfricaRiseMachine:normalSpinBtnCall()
    BaseSlotoManiaMachine.normalSpinBtnCall(self)
    self:removeScatterNodeList()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
end

--轮盘切换 变回 3x5
function CodeGameScreenAfricaRiseMachine:changeNormalReel()
    if self.m_iAddReelRowNum > 3 then
        self:clearWinLineEffect()
        self.m_SmallReelsView:removeAddReelRespinElement()
        self:changeScatterToSlotParent()
        local str = self.m_iAddReelRowNum .. "x5down"
        local direction = self.m_iReelRowNum - self.m_iAddReelRowNum
        self:changeReelLength(direction)
        if self.m_iAddReelRowNum >= 5 then
            self.m_logo:runCsbAction("animation2", false)
        end
        self:runCsbAction(
            str,
            false,
            function()
                self:showSingleReelSlotsNodeVisible(true)
                self:removeReelSlotsNode()
                self:callSpinBtn()
                self.m_iAddReelRowNum = 3
            end
        )
        return true
    else
        self:clearWinLineEffect()
        self:showSingleReelSlotsNodeVisible(true)
        self:removeReelSlotsNode()
        return false
    end
end

function CodeGameScreenAfricaRiseMachine:playEffectNotifyNextSpinCall()
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
        --处理选择freespin wild 下落效果
        if self.m_bTriggerFreespin == true then
            self.m_bTriggerFreespin = false
            delayTime = 0.5
        end
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
    elseif self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end

    self.m_bSlotRunning = false
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenAfricaRiseMachine:showEffect_Bonus(effectData)
    self:clearCurMusicBg()

    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

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

    self.m_effectData = effectData
    local bonusGame = function()
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local data = {}
        if selfData and selfData.currCell then
            data = selfData.currCell
        end
        self:showBonusMap(
            data,
            false,
            function()
                self:clearWinLineEffect()

                self.m_collectView:resetProgress(
                    function()
                        if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
                            self.m_collectView:setButtonTouchEnabled(true)
                        end
                        self:resetMusicBg(true)
                        self.m_effectData.p_isPlay = true
                        self:playGameEffect()
                        self.m_map = nil
                    end
                )
            end
        )
    end

    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_bonus_trigger.mp3")
            self.m_collectView:playCollectfull(
                function()
                    performWithDelay(
                        self,
                        function()
                            bonusGame()
                        end,
                        0.5
                    )
                end
            )
        end,
        1.0
    )

    return true
end

function CodeGameScreenAfricaRiseMachine:showSmallBonusCollect(_winCoins, _parent)
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_tip.mp3")
    local bonusView = util_createView("CodeAfricaRiseSrc.AfricaRiseSmallBonusCollect")
    bonusView:setWinCoins(_winCoins)
    bonusView:setViewParent(_parent)
    bonusView:setFunCall(
        function()
            globalData.slotRunData.lastWinCoin = 0
            self.m_bottomUI:checkClearWinLabel()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {_winCoins, true, true})
            globalData.slotRunData.lastWinCoin = _winCoins
        end
    )

    if globalData.slotRunData.machineData.p_portraitFlag then
        bonusView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(bonusView, ViewZorder.ZORDER_UI + 10)
end

function CodeGameScreenAfricaRiseMachine:getNodePosByColAndRow(col, row)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

---
-- 处理spin 结果轮盘数据
--
function CodeGameScreenAfricaRiseMachine:MachineRule_network_ProbabilityCtrl()
    local rowCount = #self.m_runSpinResultData.p_reels
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            local symbolType = rowDatas[colIndex]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_NIL_TYPE then
                symbolType = nil
            end
            --反的 重写
            self.m_stcValidSymbolMatrix[rowIndex][colIndex] = symbolType
        end
    end

    -- 处理大信号信息
    if self.m_hasBigSymbol == true then
        self.m_bigSymbolColumnInfo = {}
    else
        self.m_bigSymbolColumnInfo = nil
    end

    local iColumn = self.m_iReelColumnNum
    local iRow = self.m_iReelRowNum

    for colIndex = 1, iColumn do
        local rowIndex = 1

        while true do
            if rowIndex > iRow then
                break
            end
            local symbolType = self.m_stcValidSymbolMatrix[rowIndex][colIndex]
            -- 判断是否有大信号内容
            if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil then
                local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG, changeRows = {}}

                local colDatas = self.m_bigSymbolColumnInfo[colIndex]
                if colDatas == nil then
                    colDatas = {}
                    self.m_bigSymbolColumnInfo[colIndex] = colDatas
                end

                colDatas[#colDatas + 1] = bigInfo

                local symbolCount = self.m_bigSymbolInfos[symbolType]

                local hasCount = 1

                bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex

                for checkIndex = rowIndex + 1, iRow do
                    local checkType = self.m_stcValidSymbolMatrix[checkIndex][colIndex]
                    if checkType == symbolType then
                        hasCount = hasCount + 1

                        bigInfo.changeRows[#bigInfo.changeRows + 1] = checkIndex
                    end
                end

                if symbolCount == hasCount or rowIndex > 1 then -- 表明从对应索引开始的
                    bigInfo.startRowIndex = rowIndex
                else
                    bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
                end

                rowIndex = rowIndex + hasCount - 1 -- 跳过上面有的
            end -- end if ~= nil

            rowIndex = rowIndex + 1
        end
    end
end

--删除所有节点
function CodeGameScreenAfricaRiseMachine:removeReelSlotsNode()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iAddReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                node:removeFromParent()
                node:resetReelStatus()
                self:pushSlotNodeToPoolBySymobolType(node.p_symbolType, node)
            end
        end
    end
    self.m_lineSlotNodes = {}
end

--[[
    @desc: 显示收集地图
    --@_data:现有数据 显示游戏进度
	--@_flag:主动点开 还是触发bonus打开
	--@callback: 关闭时回调函数
]]
function CodeGameScreenAfricaRiseMachine:showBonusMap(_data, _flag, callback)
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_show_map.mp3")
    self.m_map = util_createView("CodeAfricaRiseSrc.AfricaRiseBonusMap")

    self.m_map:setMachine(self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_map.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(self.m_map, ViewZorder.ZORDER_UI)
    self.m_map:setFunCall(callback)
    self.m_map:setOpenBonusFlag(_flag)
    self.m_map:showBoxView(_data)
end

--[[
    @desc: 显示bonus 轮盘
    --@_isReConnet: false or true 是否断线重连
]]
function CodeGameScreenAfricaRiseMachine:showBonusReel(_isReConnet)
    local data = {}
    data.parent = self
    self.m_bBonusGame = true
    self.m_bonusGameReel = util_createView("CodeAfricaRiseSrc.AfricaRiseMiniMachine", data)
    if display.height / display.width == 1024 / 768 then
        self.m_bonusGameReel:setScale(0.95)
        self.m_logo:setScale(0.95)
        self.m_logo:setPositionY(self.m_logo:getPositionY() - 50)
    end
    self:findChild("shuiguoji"):addChild(self.m_bonusGameReel)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_bonusGameReel.getRotateBackScaleFlag = function(  ) return false end
    end


    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE or self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        globalData.slotRunData.m_isAutoSpinAction = false
        -- globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
        globalData.slotRunData.currSpinMode = SPECIAL_SPIN_MODE
    end
    self.m_bottomUI:showAverageBet()
    if _isReConnet == false then
        self.m_baseFreeSpinBar:setVisible(false)
        self.m_collectView:setVisible(false)
        gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_show_bonus.mp3")
        self:runCsbAction(
            "change",
            false,
            function()
                if self.m_SmallReelsView then
                    self.m_SmallReelsView:setVisible(false)
                end
                self:playBonusBgm()
                self.m_effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    else
        self.m_baseFreeSpinBar:setVisible(false)
        self.m_collectView:setVisible(false)
        self:runCsbAction("bonus")
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_runSpinResultData.p_bonusWinCoins))
        if self.m_SmallReelsView then
            self.m_SmallReelsView:setVisible(false)
        end
    end
    local leftCount = self.m_runSpinResultData.p_selfMakeData.currCell.ext
    self.m_bonusGameReel:setBonusLeftTimes(leftCount)
    self.m_bonusGameReel:UpdataSpinCount()
    self.m_bonusGameReel:enterLevel()
    local winCoins = self.m_runSpinResultData.p_selfMakeData.bonusWinCoins
    if winCoins then
        self.m_bonusGameReel:setBonusWinCoin(winCoin)
        self.m_bonusGameReel:setWinCoins(winCoins)
    end
    local totalNum = self.m_runSpinResultData.p_collectNetData[1].collectCoinsPool
    self.m_bonusGameReel:UpdataTotalBetNum(totalNum)
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    globalData.slotRunData.lastWinCoin = 0
    self.m_bottomUI:checkClearWinLabel()
end

function CodeGameScreenAfricaRiseMachine:setNormalAllRunDown()
    if self.m_runSpinResultData.p_selfMakeData.currCell ~= nil and self.m_runSpinResultData.p_selfMakeData.ext == 0 then
    else
        BaseFastMachine.playEffectNotifyChangeSpinStatus(self)
    end

    self:setGameSpinStage(STOP_RUN)
end

function CodeGameScreenAfricaRiseMachine:showBonusGameOver(func)
    performWithDelay(
        self,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, false)
            local coins = self.m_BonusWinCoins
            local ownerlist = {}
            ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
            self:clearCurMusicBg()

            gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_tip.mp3")
            local view =
                self:showDialog(
                "SmallBonusCollect",
                ownerlist,
                function()
                    if self.m_bonusStartTag then
                        gLobalSoundManager:stopAudio(self.m_bonusStartTag)
                        self.m_bonusStartTag = nil
                    end
                    self.m_bBonusGame = false

                    scheduler.performWithDelayGlobal(
                        function()
                            self:setGameSpinStage(STOP_RUN)
                            if display.height / display.width == 1024 / 768 then
                                self.m_logo:setScale(1)
                                self.m_logo:setPositionY(self.m_logo:getPositionY() + 50)
                            end
                            self:runCsbAction(
                                "change2",
                                false,
                                function()
                                    self.m_collectView:resetProgress(
                                        function()
                                            if func then
                                                func()
                                            end
                                            local selfData = self.m_runSpinResultData.p_selfMakeData
                                            if selfData and selfData.currCell then
                                                if selfData.currCell.position and selfData.currCell.position == 24 then
                                                    self.m_runSpinResultData.p_selfMakeData.currCell = nil
                                                end
                                            end
                                            if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
                                                self.m_collectView:setButtonTouchEnabled(true)
                                            end
                                            if self.m_bonusGameReel ~= nil then
                                                self.m_bonusGameReel:removeFromParent()
                                                self.m_bonusGameReel = nil
                                                globalData.slotRunData.lastWinCoin = 0
                                                self.m_bottomUI:checkClearWinLabel()
                                                self.m_bottomUI:hideAverageBet()
                                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_BonusWinCoins, true, true})
                                                globalData.slotRunData.lastWinCoin = self.m_BonusWinCoins
                                                self:checkFeatureOverTriggerBigWin(self.m_BonusWinCoins, GameEffect.EFFECT_BONUS)
                                                self:playGameEffect()
                                                if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
                                                    self.m_collectView:setBtnTouch(true)
                                                end
                                            end
                                            self:changeConfigData()
                                        end
                                    )
                                end
                            )
                            if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
                                globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
                                globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
                                self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
                                self:triggerFreeSpinCallFun()
                                self.m_baseFreeSpinBar:setVisible(true)
                                self.m_collectView:setVisible(false)
                            elseif self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                                local selfdata = self.m_runSpinResultData.p_selfMakeData
                                local frssSpinType = selfdata.freeSpinType
                                local effectData = GameEffectData.new()
                                effectData.p_effectType = GameEffect.EFFECT_FREE_SPIN
                                self.m_gameEffects[#self.m_gameEffects + 1] = effectData
                                self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
                                self.m_bottomUI:checkClearWinLabel()
                            else
                                self.m_bonusOverAndFreeSpinOver = true
                                if self.m_runSpinResultData.p_freeSpinsTotalCount <= 0 then
                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                                end
                                self.m_baseFreeSpinBar:setVisible(false)
                                self.m_collectView:setVisible(true)
                            end
                            self:resetMusicBg(true)
                        end,
                        0.8,
                        self:getModuleName()
                    )
                end
            )
            if display.height / display.width == 1024 / 768 then
                local node = view:findChild("root")
                node:setScale(0.8)
            end
            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node, sx = 1, sy = 1}, 661)
            return view
        end,
        1
    )
end

--背景切换
function CodeGameScreenAfricaRiseMachine:changeNormalAndFreespinBg(_type)
    if _type == 3 then -- normal ->freespin
        self.m_gameBg:runCsbAction("actionframe1", false)
        self:findChild("lan_rell"):setVisible(false)
        self:findChild("zi_rell"):setVisible(true)
    elseif _type == 4 then -- freespin -> normal
        self.m_gameBg:runCsbAction("actionframe2", false)
        self:findChild("lan_rell"):setVisible(true)
        self:findChild("zi_rell"):setVisible(false)
    elseif _type == 1 then -- normal
        self.m_gameBg:runCsbAction("idle1", false)
        self:findChild("lan_rell"):setVisible(true)
        self:findChild("zi_rell"):setVisible(false)
    elseif _type == 2 then -- freespin
        self.m_gameBg:runCsbAction("idle2", false)
        self:findChild("lan_rell"):setVisible(false)
        self:findChild("zi_rell"):setVisible(true)
    end
    if self.m_ChangeReelView then
        self.m_ChangeReelView:changeSymbolBg()
    end
end

--
function CodeGameScreenAfricaRiseMachine:setRespinViewLight()

    local nodes = self.m_SmallReelsView:getAllEndSlotsNode()
    for i = 1, #nodes do
        local node = nodes[i]
        if node and node.p_symbolType ~= self.SYMBOL_SPIN_ADD then
            node:runAnim("idleframe", false)
        else
            node:runAnim("idleframe2", false)
        end
    end

end

--渐变置灰
function CodeGameScreenAfricaRiseMachine:setRespinViewDark()
    local nodes = self.m_SmallReelsView:getAllEndSlotsNode()
    if self.m_addRow > 1 then
        local _row = self.m_iReelRowNum + self.m_addRow - 1
        for i = 1, #nodes do
            local node = nodes[i]
            if node and node.p_symbolType ~= self.SYMBOL_WILD_X then
                if (node.p_rowIndex > (_row - 1)) and node.p_rowIndex <= _row then
                    node:runAnim("dark", false)
                end
            end
        end
        for i, v in ipairs(self.m_ScatterNodeList) do
            if (v.p_rowIndex > (_row - 1)) and v.p_rowIndex <= _row then
                v:runAnim("dark", false)
            end
        end
    else
        for i = 1, #nodes do
            local node = nodes[i]
            if node and node.p_symbolType ~= self.SYMBOL_WILD_X then
                if node.p_rowIndex <= self.m_iReelRowNum then
                    node:runAnim("dark", false)
                end
            end
        end
        for i, v in ipairs(self.m_ScatterNodeList) do
            v:runAnim("dark", false)
        end
    end
end

function CodeGameScreenAfricaRiseMachine:showEffect_LineFrame(effectData)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
        end 
    end
    
    if self.m_iAddReelRowNum == 3 then
        self:showSingleReelSlotsNodeVisible(false)
    end
    self:findChild("heng_xian"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 1)
    self:findChild("lineNode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + 1)
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
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true
end

function CodeGameScreenAfricaRiseMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            slotsNode:runAnim("dark", false)
        end
    end
end

function CodeGameScreenAfricaRiseMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            slotsNode:runLineAnim()
            local symbolType = slotsNode.p_symbolType
            local order = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + self:getBounsScatterDataZorder(symbolType) + 10 * slotsNode.p_cloumnIndex - slotsNode.p_rowIndex
            slotsNode.p_showOrder = order
            slotsNode:setLocalZOrder(order)
            slotsNode.p_isPlayRunLine = true
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

--
function CodeGameScreenAfricaRiseMachine:showLineFrameByIndex(winLines, frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        for i = 1, #self.m_eachLineSlotNode do
            local vecSlotNodes = self.m_eachLineSlotNode[i]
            if i == frameIndex then
                if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
                    for i = 1, #vecSlotNodes, 1 do
                        local slotsNode = vecSlotNodes[i]
                        if slotsNode ~= nil then
                            slotsNode:runLineAnim()
                            slotsNode.p_isPlayRunLine = true
                            local symbolType = slotsNode.p_symbolType
                            local order = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + self:getBounsScatterDataZorder(symbolType) + 10 * slotsNode.p_cloumnIndex - slotsNode.p_rowIndex
                            slotsNode.p_showOrder = order
                            slotsNode:setLocalZOrder(order)
                        end
                    end
                end
            else
                if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
                    for i = 1, #vecSlotNodes, 1 do
                        local slotsNode = vecSlotNodes[i]
                        if slotsNode ~= nil then
                            slotsNode.p_isPlayRunLine = false
                        end
                    end
                end
            end
        end
    end
end

function CodeGameScreenAfricaRiseMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = globalData.slotRunData.levelConfigData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期
    local normalTime = self.m_changeLineFrameTime
    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil, nil)

    self:showAllSlotNodeRunIdle()
    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                self:showAllSlotNodeRunIdle()

                -- if frameIndex > #winLines then
                --     frameIndex = 1
                --     if self.m_showLineHandlerID ~= nil then
                --         scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                --         self.m_showLineHandlerID = nil
                --     end
                self:playInLineNodes()
                -- showLienFrameByIndex()
                --     return
                -- else
                --     while true do
                --         if frameIndex > #winLines then
                --             break
                --         end
                --         local lineData = winLines[frameIndex]
                --         if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
                --             if #winLines == 1 then
                --                 break
                --             end
                --             frameIndex = frameIndex + 1
                --             if frameIndex > #winLines then
                --                 frameIndex = 1
                --             end
                --         else
                --             break
                --         end
                --     end
                --     self:showLineFrameByIndex(winLines, frameIndex)
                --     frameIndex = frameIndex + 1
                -- end
            end,
            self.m_changeLineFrameTime,
            self:getModuleName()
        )
    end
    showLienFrameByIndex()
end

function CodeGameScreenAfricaRiseMachine:showAllSlotNodeRunIdle()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iAddReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                -- targSp:runAnim("darkaction", true)
                targSp:runAnim("darkidle", true)
                local symbolType = targSp.p_symbolType
                local order = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE -- + self:getBounsScatterDataZorder(symbolType)
                targSp.p_showOrder = order
                targSp:setLocalZOrder(order)
            end
        end
    end
    self.m_lineEffect:setVisible(true)
    self.m_lineEffect:playAction(self.m_iAddReelRowNum .. "x5", true)
end

-- 重写无连线框
function CodeGameScreenAfricaRiseMachine:showAllFrame(winLines)
end

--设置bonus scatter 层级
function CodeGameScreenAfricaRiseMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SPIN_ADD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_WILD_X then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    else
        order = REEL_SYMBOL_ORDER.REEL_ORDER_1
    end
    return order
end

--背景音乐声音变小
function CodeGameScreenAfricaRiseMachine:checkTriggerOrInSpecialGame(func)
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == RESPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE or self:checktriggerSpecialGame() then
        self:removeSoundHandler() -- 移除监听
    else
        local selfdata = self.m_runSpinResultData.p_selfMakeData
        if selfdata and selfdata.xPositions ~= nil and #selfdata.xPositions > 0 then
            return
        end
        if self.m_bonusGameReel then
            return
        end
        if func then
            func()
        end
    end
end

function CodeGameScreenAfricaRiseMachine:clearWinLineEffect()
    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)

        self.m_showLineHandlerID = nil
    end

    self:clearLineAndFrame()

    -- 改变lineSlotNodes 的层级
    self:resetMaskLayerNodes()

    -- 隐藏长条模式下 大长条的遮罩问题
    self:operaBigSymbolMask(false)
    --恢复静止
    self:showAllNodeRunIdle()
    self.m_lineEffect:setVisible(false)
end

--恢复为亮图
function CodeGameScreenAfricaRiseMachine:showAllNodeRunIdle()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iAddReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp then
                targSp:setVisible(true)
                targSp:runAnim("idleframe", false)
            end
        end
    end
end

function CodeGameScreenAfricaRiseMachine:callSpinBtn()

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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self.m_bBonusGame == false and betCoin > totalCoin then
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
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE and self.m_bBonusGame == false then
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

--把层级改回去 否则在播放轮盘下降时会有下降过程中残留
function CodeGameScreenAfricaRiseMachine:changeScatterToSlotParent()
    --全部scatter的触发动画
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iAddReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
                    local pos = self.m_slotParents[iCol].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    targSp:removeFromParent()
                    targSp:resetReelStatus()
                    targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                    local zorder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                    targSp:setLocalZOrder(zorder + iCol)
                    targSp:setPosition(cc.p(pos.x, pos.y))
                    self.m_slotParents[iCol].slotParent:addChild(targSp)
                end
            end
        end
    end
end

return CodeGameScreenAfricaRiseMachine
