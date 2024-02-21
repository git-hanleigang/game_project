---
-- island li
-- 2019年1月26日
-- CodeGameScreenAZTECMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SendDataManager = require "network.SendDataManager"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"

local CodeGameScreenAZTECMachine = class("CodeGameScreenAZTECMachine", BaseFastMachine)

CodeGameScreenAZTECMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenAZTECMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 
CodeGameScreenAZTECMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenAZTECMachine.SYMBOL_SCORE_12 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3   
CodeGameScreenAZTECMachine.SYMBOL_SCORE_13 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 4
CodeGameScreenAZTECMachine.SYMBOL_SCORE_14 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 5
CodeGameScreenAZTECMachine.SYMBOL_SCORE_15 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 6


CodeGameScreenAZTECMachine.EFFECT_COLLECT_COIN = GameEffect.EFFECT_SELF_EFFECT - 2 

CodeGameScreenAZTECMachine.EFFECT_FREECOUNT_ADD = GameEffect.EFFECT_FREE_SPIN + 1        --free增加次数

CodeGameScreenAZTECMachine.m_bIsSelectCall = nil
CodeGameScreenAZTECMachine.m_iSelectID = nil
CodeGameScreenAZTECMachine.m_iReelMinRow = 3
CodeGameScreenAZTECMachine.m_vecReelRow = {3, 4, 5, 6}
CodeGameScreenAZTECMachine.m_vecFsModel = {"3x5", "4x5", "5x5", "6x5"}
CodeGameScreenAZTECMachine.m_currGameStatus = 0
CodeGameScreenAZTECMachine.m_reelRunAnimaBG = nil
CodeGameScreenAZTECMachine.m_bIsReconnectGame = nil
CodeGameScreenAZTECMachine.m_bIsBonusGameOver = nil
CodeGameScreenAZTECMachine.m_iClickID = nil
CodeGameScreenAZTECMachine.m_vecScaleList = {0.9, 0.8, 0.5}
CodeGameScreenAZTECMachine.m_vecNewPosList = {100, 205, 285}
CodeGameScreenAZTECMachine.m_vecFsLines = {0, 0, 243, 1024, 3125, 7776}
local BG_MOVE_POS = 
{
    cc.p(-1,-2),
    cc.p(2,2),
    cc.p(-2,-2),
    cc.p(1,1),
    cc.p(-2,2),
    cc.p(2,0),
    cc.p(-2,2),
    cc.p(2,-2),
    cc.p(-2,2),
    cc.p(2,-2),
    cc.p(0,0),
    cc.p(-1,-2),
    cc.p(2,2),
    cc.p(-2,-2),
    cc.p(1,1),
    cc.p(-2,2),
    cc.p(2,0),
    cc.p(-2,2),
    cc.p(2,-2),
    cc.p(-2,2),
    cc.p(2,-2),
    cc.p(0,0),
    cc.p(-1,-2),
    cc.p(2,2),
    cc.p(-2,-2),
    cc.p(1,1),
    cc.p(-2,2),
    cc.p(2,0),
    cc.p(-2,2),
    cc.p(2,-2),
    cc.p(-2,2),
    cc.p(2,-2),
    cc.p(0,0),
    cc.p(-1,-2),
    cc.p(2,2),
    cc.p(-2,-2),
    cc.p(1,1),
    cc.p(-2,2),
    cc.p(1,0),
    cc.p(-2,2),
    cc.p(2,-2),
    cc.p(-2,2),
    cc.p(2,-2),
    cc.p(2,0),
    cc.p(0,0)
}

local betTipsStatus = {
    None    = 1,
    Start   = 2,
    ShuaXin = 3,
    Idle    = 4,
    Over    = 5,
}
-- 构造函数
function CodeGameScreenAZTECMachine:ctor()
    BaseFastMachine.ctor(self)
    --init
    self.m_reelRunAnimaBG = {}
    self.m_reelEffectOtherList = {}
    self.m_reelEffectOtherBgList = {}
    self.m_isFeatureOverBigWinInFree = true
	self:initGame()
end

function CodeGameScreenAZTECMachine:initGame()


    self.m_configData = gLobalResManager:getCSVLevelConfigData("AZTECConfig.csv", "LevelAZTECConfig.lua")
	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

function CodeGameScreenAZTECMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i >= 3 then
            soundPath = "AZTECSounds/sound_AZTEC_wild_scatter_down3.mp3"
        else
            soundPath = "AZTECSounds/sound_AZTEC_wild_scatter_down"..i..".mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenAZTECMachine:initUI()


    self:setReelRunSound("AZTECSounds/sound_AZTEC_quick_run.mp3")
    self:initFreeSpinBar() -- FreeSpinbar
   
    self.m_jackpotNode = util_createView("CodeAZTECSrc.AZTECJackPotBarView")
    self.m_jackpotNode:initMachine(self)
    self:findChild("jackpot"):addChild(self.m_jackpotNode)
    
    -- self.m_showSymbolNode = util_createView("CodeAZTECSrc.AZTECShowSymbols", self)
    -- self:findChild("bet_paytable"):addChild(self.m_showSymbolNode)
    
    self.m_guochangNode = util_spineCreate("AZTEC_guochangdonghua", true, true)
    self:addChild(self.m_guochangNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_guochangNode:setPosition(display.width * 0.5, display.height * 0.5)
    self.m_guochangNode:setVisible(false)
    self.m_guochangNode:setScale(self.m_machineRootScale)

    self.m_collectEffect = util_createView("CodeAZTECSrc.CollectWildEffect",{self})
    self.m_gameBg:findChild("Node_jinzita"):addChild(self.m_collectEffect)
    -- self.m_gameBg:setScale(self.m_machineRootScale)
    util_csbScale(self.m_gameBg.m_csbNode, self.m_machineRootScale)

    self:initLevelGoldIcon()

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
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
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundName = "AZTECSounds/sound_AZTEC_last_win_".. soundIndex .. ".mp3"
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
            self.m_winSoundsId = nil
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenAZTECMachine:initFreeSpinBar()
    local node_bar = self.m_bottomUI:findChild("node_bar")
    self.m_baseFreeSpinBar = util_createView("Levels.FreeSpinBar")
    node_bar:addChild(self.m_baseFreeSpinBar)
    local pos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,node_bar)
    self.m_baseFreeSpinBar:setPosition(cc.p(pos.x,73))
    self.m_baseFreeSpinBar:setScale(0.8)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenAZTECMachine:playGuochangAnimation(func, endFunc)
    self.m_guochangNode:setVisible(true)
    gLobalViewManager:addLoadingAnima(true)
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_bg_guochang.mp3")
    util_spinePlay(self.m_guochangNode, "animation", false)
    util_spineEndCallFunc(self.m_guochangNode, "animation", function()
        self.m_guochangNode:setVisible(false)
        gLobalViewManager:removeLoadingAnima()
        if endFunc ~= nil then 
            endFunc()
        end
    end)
    performWithDelay(self, function()
        if func ~= nil then
            func()
        end
    end, 1)
end

-- 断线重连 
function CodeGameScreenAZTECMachine:MachineRule_initGame()
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            self.m_baseFreeSpinBar:updateFreespinCount(self.m_runSpinResultData.p_freeSpinsLeftCount,"")        --断线重连刷新free次数
            self.m_bIsReconnectGame = true
            self.m_iSelectID = self.m_runSpinResultData.p_selfMakeData.freeSpinType + 1 
            self.m_iReelRowNum = self.m_vecReelRow[self.m_iSelectID]
            self.m_configData:setFsModel(self.m_vecFsModel[self.m_iSelectID])
            if self.m_iReelRowNum > self.m_iReelMinRow then
                self:changeReelData()
            end
            -- self:levelFreeSpinEffectChange()
        end
    end
end

-- bonus小游戏断线重连
function CodeGameScreenAZTECMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" then

        self:playGameEffect()
        return
    end

    if featureData.p_status == "OPEN" then
        self.isInBonus = true
        self.m_bIsReconnectGame = true
        local bonusLayer = util_createView("CodeAZTECSrc.AZTECBonusGame")
        self:addChild(bonusLayer, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
        util_csbScale(bonusLayer.m_csbNode, self.m_machineRootScale)
        if globalData.slotRunData.machineData.p_portraitFlag then
            bonusLayer.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = bonusLayer})

        bonusLayer:resetView(featureData, function(coins, jackpot)
            self:showBonusGameOver(coins,jackpot,function()
                -- performWithDelay(self, function()
                    self:playGuochangAnimation(function()
                        bonusLayer:removeFromParent()
                        self.m_currGameStatus = 0
                        self.m_bIsBonusGameOver = true
                        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idleframe"..self.m_currGameStatus)
                    end, function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                        self:playGameEffect()   
                        self:resetMusicBg()
                    end)
                -- end, 0.5)
            end)
        end, self)
        performWithDelay(self, function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end, 0.1)
    end
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenAZTECMachine:getModuleName()
	--TODO 修改对应本关卡moduleName，必须实现
    return "AZTEC"  
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenAZTECMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SCORE_10  then
        return "Socre_AZTEC_15"
    elseif symbolType == self.SYMBOL_SCORE_11  then
        return "Socre_AZTEC_14"
    elseif symbolType == self.SYMBOL_SCORE_12 then
        return "Socre_AZTEC_13"
    elseif symbolType == self.SYMBOL_SCORE_13 then
        return "Socre_AZTEC_12"
    elseif symbolType == self.SYMBOL_SCORE_14 then
        return "Socre_AZTEC_11"
    elseif symbolType == self.SYMBOL_SCORE_15 then
        return "Socre_AZTEC_10"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 then
        return "Socre_AZTEC_1_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_2 then
        return "Socre_AZTEC_2_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_3 then
        return "Socre_AZTEC_3_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_5 then
        return "Socre_AZTEC_5_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_6 then
        return "Socre_AZTEC_6_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_7 then
        return "Socre_AZTEC_7_1"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_8 then
        return "Socre_AZTEC_8_1"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenAZTECMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

--
--单列滚动停止回调
--
function CodeGameScreenAZTECMachine:slotOneReelDown(reelCol)    
    BaseFastMachine.slotOneReelDown(self,reelCol) 
    
    if self.m_iReelRowNum > 3 then
        if reelCol >= 3 then
            if self.m_reelEffectOtherList ~= nil then
                local reelEffectNode,reelAct = self:getReelEffect(self.m_reelEffectOtherList[reelCol])
                if reelEffectNode ~= nil and reelEffectNode:isVisible() then
                    reelEffectNode:runAction(cc.Hide:create())
                end
            end
        end
        
    end
    if self.m_iReelRowNum > 3 then
        if reelCol >= 3 then
            if self.m_reelEffectOtherBgList ~= nil then
                local reelEffectNode,reelAct = self:getReelEffect(self.m_reelEffectOtherBgList[reelCol])
                if reelEffectNode ~= nil and reelEffectNode:isVisible() then
                    reelEffectNode:runAction(cc.Hide:create())
                end
            end
        end
    else
        if self.m_reelRunAnimaBG ~= nil then
            local reelEffectNode = self.m_reelRunAnimaBG[reelCol]
    
            if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
                reelEffectNode[1]:runAction(cc.Hide:create())
            end
        end
    end
end



---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenAZTECMachine:levelFreeSpinEffectChange()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"freespin_idle", true})
    self.m_collectEffect:fsAnimation()
end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenAZTECMachine:levelFreeSpinOverChangeEffect()
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idleframe"..self.m_currGameStatus)
    self.m_collectEffect:runIdle()
end
---------------------------------------------------------------------------


function CodeGameScreenAZTECMachine:showBonusGameOver(coins, jackpot, func)
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_show_jackpot.mp3")
    globalData.slotRunData.lastWinCoin = coins
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins, false})
    local view = util_createView("CodeAZTECSrc.AZTECBonusOver")
    view:initViewData(self, coins, jackpot, function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN, false)
        if func ~= nil then
            func()
        end
    end)
    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(view)
end

function CodeGameScreenAZTECMachine:showEffect_Bonus(effectData)
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearWinLineEffect()
    self:clearFrames_Fun()
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then

        self:showBonusAndScatterLineTip(bonusLineValue,function()
            self:showBonusGameView(effectData)
        end)
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)

    return true
end

function CodeGameScreenAZTECMachine:showBonusGameView(effectData)
    -- effectData.p_isPlay = true
    -- self:playGameEffect() -- 播放下一轮
    if self.m_runSpinResultData.p_selfMakeData.bonusType == "select" then
        self.m_effectData = effectData
        self:playGuochangAnimation(function()
            self.m_chooseLayer = util_createView("CodeAZTECSrc.AZTECChooseFreespin")
            self:addChild(self.m_chooseLayer, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
            -- self.m_chooseLayer:setPosition(display.width * 0.5, display.height * 0.5)
            util_csbScale(self.m_chooseLayer.m_csbNode, self.m_machineRootScale)
            if globalData.slotRunData.machineData.p_portraitFlag then
                self.m_chooseLayer.getRotateBackScaleFlag = function(  ) return false end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = self.m_chooseLayer})
        end)
    elseif self.m_runSpinResultData.p_selfMakeData.bonusType == "pick" then
        self:runCsbAction("actionframe1")
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"doudong"..self.m_currGameStatus, false, function ()
            self.m_collectEffect:collectCompleted()
        end})
        self:bgMoveAnimation(function()
            -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "baofa"..self.m_currGameStatus)
            -- self.m_collectEffect:collectCompleted()
        end)
        local bonusLayer = util_createView("CodeAZTECSrc.AZTECBonusGame")
        self:addChild(bonusLayer, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT)
        util_csbScale(bonusLayer.m_csbNode, self.m_machineRootScale)
        if globalData.slotRunData.machineData.p_portraitFlag then
            bonusLayer.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = bonusLayer})

        bonusLayer:setVisible(false)
        performWithDelay(self, function()


            
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "baofa"..self.m_currGameStatus)
            bonusLayer:setVisible(true)
            --过场结束 重制金币堆
            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(waitNode, function()
                waitNode:removeFromParent()

                local data = {level = 1}
                self.m_collectEffect:setGoodData(data)
                self.m_collectEffect:upDateGoodIdleframe()
            end, 108/30)
            bonusLayer:initViewData(function(coins, jackpot)
                self:showBonusGameOver(coins,jackpot,function()
                    -- performWithDelay(self, function()
                        self:playGuochangAnimation(function()
                            bonusLayer:removeFromParent()
                            self.m_currGameStatus = 0
                            self.m_bIsBonusGameOver = true
                            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idleframe"..self.m_currGameStatus)
                        end, function()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                            effectData.p_isPlay = true
                            self:playGameEffect()   
                            self:resetMusicBg()
                        end)
                    -- end, 0.5)
                end)
            end, self)
        end, 2.2)
    end
end

function CodeGameScreenAZTECMachine:addFreeCount(effectData)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearWinLineEffect()
    self:clearFrames_Fun()
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then

        self:showBonusAndScatterLineTip(bonusLineValue,function()
            gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_freeMore.mp3")
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        end)
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else
        gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_freeMore.mp3")
        self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end,true)
    end
    
end

function CodeGameScreenAZTECMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("AZTECSounds/music_AZTEC_custom_enter_fs.mp3")
    --  延迟0.5 不做特殊要求都这么延迟

    local delayTime = 2.5
    if self.m_iClickID == 4 then
        delayTime = 8
        local randomTimes = math.random(3, 15)
        while randomTimes == globalData.slotRunData.totalFreeSpinCount do
            randomTimes = math.random(3, 15)
        end
        local model = string.upper(self.m_vecFsModel[self.m_iSelectID])
        local randomID = math.random(1, #self.m_vecFsModel)
        while randomID == self.m_iSelectID do
            randomID = math.random(1, #self.m_vecFsModel)
        end
        local randomModel = string.upper(self.m_vecFsModel[randomID])

        self.m_chooseLayer:initRandomUI(globalData.slotRunData.totalFreeSpinCount, model, randomTimes, randomModel)
        self.m_chooseLayer:randomAnimation()
    end

    -- performWithDelay(self,function(  )
        
    --     self:playGuochangAnimation(function()
    --         if self.m_iReelRowNum > self.m_iReelMinRow then
    --             self:changeReelData()
    --         end
    --         util_setCsbVisible(self.m_baseFreeSpinBar, true)
    --         self.m_baseFreeSpinBar:changeFreeSpinByCount()
    --         self:levelFreeSpinEffectChange()  
    --         self.m_chooseLayer:removeFromParent()
    --         self.m_chooseLayer = nil

    --         gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_enter_fs.mp3")
    --         self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
    --             self.m_iFreeSpinTimes = 0
    --             self:triggerFreeSpinCallFun()
    --             effectData.p_isPlay = true
    --             self:playGameEffect()
    --         end)
    --     end)  
    -- end, delayTime)
    performWithDelay(self,function(  )
        if self.m_iReelRowNum > self.m_iReelMinRow then
            self:changeReelData()
        end
        util_setCsbVisible(self.m_baseFreeSpinBar, true)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self:levelFreeSpinEffectChange()  

        self.m_chooseLayer:overAnimation(function()
            gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_enter_fs.mp3")
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self.m_iFreeSpinTimes = 0
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
            view:findChild("m_lb_line"):setString(self.m_vecFsLines[self.m_iReelRowNum])
            self.m_chooseLayer:removeFromParent()
            self.m_chooseLayer = nil
        end)
    end, delayTime)
end



function CodeGameScreenAZTECMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:playGuochangAnimation(function()
                if self.m_iReelRowNum > self.m_iReelMinRow then
                    self.m_iReelRowNum = self.m_iReelMinRow
                    self:clearWinLineEffect()
                    self:changeReelData()
                    self:runCsbAction("idle1", true)
                end
                self:triggerFreeSpinOverCallFun()
            end)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

end

function CodeGameScreenAZTECMachine:changeReelData()
    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i,self.m_iReelRowNum,true)
    end
    self:runCsbAction("idle"..self.m_iReelRowNum, true)
    if self.m_iReelRowNum == self.m_iReelMinRow then
        -- self.m_FortuneTreeTree:setPositionY(0)
        -- self.m_freespinBar:setPositionY(0)
        -- self.m_stcValidSymbolMatrix[4] = nil 
        -- self.m_stcValidSymbolMatrix[5] = nil
        self:findChild("kuang"):setContentSize({width = 686, height = 358})
        for i = 1, self.m_iReelColumnNum, 1 do
            self:findChild("hong_rell_"..i):setContentSize({width = 130, height = 330})
        end
        self.m_collectEffect:setScale(1)
        self.m_collectEffect:setPosition(0, 0)
        self.m_collectEffect:upDateGoodPosAndScale()
        
    else
        local distance = self.m_iReelRowNum - self.m_iReelMinRow
        -- local nodeH = self.m_SlotNodeH * 1.18
        -- self.m_FortuneTreeTree:setPositionY(nodeH * (self.m_iReelRowNum - self.m_iReelMinRow))
        -- self.m_freespinBar:setPositionY(nodeH * (self.m_iReelRowNum - self.m_iReelMinRow))
        for i = self.m_iReelMinRow + 1, self.m_iReelRowNum, 1 do
            if self.m_stcValidSymbolMatrix[i] == nil then
                self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
            end
        end
        self.m_collectEffect:setScale(self.m_vecScaleList[distance])
        self.m_collectEffect:setPosition(0, self.m_vecNewPosList[distance])
        self.m_collectEffect:upDateGoodPosAndScale()
        
        self:findChild("kuang"):setContentSize({width = 686, height = 358 + self.m_SlotNodeH * distance})
        
        for i = 1, self.m_iReelColumnNum, 1 do
            self:findChild("hong_rell_"..i):setContentSize({width = 130, height = 330 + self.m_SlotNodeH * distance})
        end
        
        -- self.m_jackpotBar:setVisible(false)
        -- self.m_jackpotFreespinBar:setVisible(true)
        -- self.m_jackpotFreespinBar:changeBarDisplay()
        -- self:addNewRandomSymbol()
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

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
end

function CodeGameScreenAZTECMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local index = math.random(1, #reelDatas - rowCount)
        local vecSymbol = {}
        for i = 1, rowCount, 1 do
            vecSymbol[i] = reelDatas[index + i]
        end
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = vecSymbol[rowIndex]
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex,symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
                -- 添加到显示列表
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end

            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = showOrder

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
    self:initGridList()
end

function CodeGameScreenAZTECMachine:addNewRandomSymbol()
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = self.m_iReelRowNum
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = self.m_iReelMinRow + 1, resultLen do
            local children = parentData.slotParent:getChildren()
            local haveSymbol = false
            for i = 1, #children, 1 do
                local child = children[i]
                if child.p_cloumnIndex == colIndex and child.p_rowIndex == rowIndex then
                    haveSymbol = true
                    child:setVisible(true)
                    break
                end
            end
            if haveSymbol == false then
                local symbolType = self:getRandomReelType(colIndex,reelDatas)
                while symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER do
                    symbolType = self:getRandomReelType(colIndex,reelDatas)
                end
                local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
                node.p_slotNodeH = reelColData.p_showGridH      
                
                node.p_symbolType = symbolType
                node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
            
                if not node:getParent() then
                    parentData.slotParent:addChild(node,node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                    node:setLocalZOrder(node.p_showOrder - rowIndex)
                    node:setVisible(true)
                end

                node.p_reelDownRunAnima = parentData.reelDownAnima

                node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                node:setPositionY(  (rowIndex - 1) * reelColData.p_showGridH + halfNodeH )
            end
        end
    end
    self:initGridList()
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenAZTECMachine:MachineRule_SpinBtnCall()
    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    gLobalSoundManager:setBackgroundMusicVolume(1)
 
    self.m_vecWildNode = {}
    self.m_bIsReconnectGame = false
    self.m_iClickID = nil
    
    return false -- 用作延时点击spin调用
end


function CodeGameScreenAZTECMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    
    local betCoin = globalData.slotRunData:getCurTotalBet()
    
    if self.m_specialBets and #self.m_specialBets > 0 then
        self.m_iBetLevel = #self.m_specialBets + 1
        for i = 1, #self.m_specialBets do
            if betCoin < self.m_specialBets[i].p_totalBetValue then
                self.m_iBetLevel = i
                break
            end
        end
    else
        self.m_iBetLevel = 1
    end
    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 5
    end
    self.m_fsReelDataIndex = self.m_iBetLevel
end

-- function CodeGameScreenAZTECMachine:chooseBetLayer()
--     if globalData.slotRunData.isDeluexeClub == true then
--         return
--     end
--     local betList = globalData.slotRunData.machineData:getMachineCurBetList()
--     local lowBet = betList[1].p_totalBetValue
--     local vecBet = {}
--     vecBet[#vecBet + 1] = lowBet
--     for i = 1, #self.m_specialBets, 1 do
--         vecBet[#vecBet + 1] = self.m_specialBets[i].p_totalBetValue
--     end
--     local chooeLayer = util_createView("CodeAZTECSrc.AZTECChooseBetView", vecBet)
--     self:addChild(chooeLayer, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

--     if globalData.slotRunData.machineData.p_portraitFlag then
--         chooeLayer.getRotateBackScaleFlag = function(  ) return false end
--     end
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = chooeLayer})

    
--     if display.height < 1200 then
--         local scale = display.height / 1200
--         util_csbScale(chooeLayer.m_csbNode, scale)
--     end
--     gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_choose_bet_window.mp3")
-- end

function CodeGameScreenAZTECMachine:chooseBetLayer()
    local csbPath = "AZTEC/GameScreenAZTEC_RaiseBetTips.csb"
    -- 热更时可能会存在文件不存在
    if not cc.FileUtils:getInstance():isFileExist(csbPath) then
        local sMsg = string.format("[CodeGameScreenAZTECMachine:chooseBetLayer] 文件不存在=(%s)", csbPath)
        print(sMsg)
        release_print(sMsg)
        return
    end

    local showLayer = util_createView("CodeAZTECSrc.AZTECShowBetView", self)
    self:addChild(showLayer, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    if globalData.slotRunData.machineData.p_portraitFlag then
    showLayer.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = showLayer})

    -- local showLayer = util_createView("CodeAZTECSrc.AZTECShowBetView", self) 
    -- showLayer:findChild("root"):setScale(self.m_machineRootScale)
    -- if globalData.slotRunData.machineData.p_portraitFlag then
    --     showLayer.getRotateBackScaleFlag = function(  ) return false end
    -- end
    -- showLayer:setPositionY(self.m_machineRootPosY  )

    -- gLobalViewManager:showUI(showLayer)
    
    if display.height < 1200 then
        local scale = display.height / 1200
        util_csbScale(showLayer.m_csbNode, scale)
    end
    -- gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_choose_bet_window.mp3")
end

function CodeGameScreenAZTECMachine:beginReel()
    CodeGameScreenAZTECMachine.super.beginReel(self)
    self:playBetTipsOverAnim()
end

--[[
    黄金图标
]]
function CodeGameScreenAZTECMachine:initLevelGoldIcon()
    local csbPath = "GameScreenAZTEC_BetTips.csb"
    -- 热更时可能会存在文件不存在
    if not cc.FileUtils:getInstance():isFileExist(csbPath) then
        local sMsg = string.format("[CodeGameScreenAZTECMachine:initLevelGoldIcon] 文件不存在=(%s)", csbPath)
        print(sMsg)
        release_print(sMsg)
        return
    end
    self.m_showBetTips = util_createAnimation("GameScreenAZTEC_BetTips.csb")
    self:addChild(self.m_showBetTips, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    local showBetPos = util_convertToNodeSpace(self.m_bottomUI:findChild("node_bet_tips"),  self)
    self.m_showBetTips:setVisible(false)
    self.m_showBetTips:setPosition(showBetPos)
    self.m_showBetTips:setScale(self.m_machineRootScale)
    --一些数据
    self.m_showBetTips.m_tipStatus   = betTipsStatus.None
    self.m_showBetTips.m_tipBetIndex = 0
end
function CodeGameScreenAZTECMachine:getLevelGoldIconTriggerState(_params)
    if not self.m_showBetTips or not self.m_specialBets then
        return false
    end
    -- 高倍场名称 = 普通关卡名称 + _H
    local levelName = self:getModuleName()
    local levelName_H = string.format("%s%s", levelName, "_H")
    if levelName ~= _params.levelName and levelName_H ~= _params.levelName then
        return false
    end

    return true
end
function CodeGameScreenAZTECMachine:checkLevelGoldIcon(_params)
    --[[
        _params = {
            levelName = "",
            bTrigger  = false,
        }
    ]]
    local bTrigger = self:getLevelGoldIconTriggerState(_params)
    if not bTrigger then
        return
    end
    -- 触发提示
    _params.bTrigger = true
end
function CodeGameScreenAZTECMachine:updateLevelGoldIcon(_params)
    --[[
        params = {
            levelName    = "",
            nowBetCoins  = 0,
            newBetCoins  = 0,
            popDefault   = nil, 
        }
    ]]
    local bTrigger = self:getLevelGoldIconTriggerState(_params)
    if not bTrigger then
        return
    end
    -- 刷新提示面板的ui
    local betIndex = #self.m_specialBets + 1
    local curBet      = globalData.slotRunData:getCurTotalBet()
    for _betIndex,_betData in ipairs(self.m_specialBets) do
        if curBet < _betData.p_totalBetValue then
            betIndex = _betIndex
            break
        end
    end
    if globalData.slotRunData.isDeluexeClub == true then
        betIndex = 5
    end
    local fnUpdateLevelGoldIcon = function(_newBetIndex)
        self.m_showBetTips.m_tipBetIndex = _newBetIndex
        for _index=1,4 do
            local nodeIndex = _index - 1
            local lowNode   = self.m_showBetTips:findChild(string.format("icon%d_low", nodeIndex))
            local highNode  = self.m_showBetTips:findChild(string.format("icon%d_high", nodeIndex))
            local bHigh     = _newBetIndex >= (6 - _index) 
            lowNode:setVisible(not bHigh)
            highNode:setVisible(bHigh)
        end
        local textNode = self.m_showBetTips:findChild("text1")
        textNode:setVisible(5 ~= _newBetIndex)
        local labNum   = self.m_showBetTips:findChild("m_lb_num")
        labNum:setString(tostring(_newBetIndex))
    end
    -- 弹板的其中三条时间线
    local fnPlayStartAnim = function(_fnNext)
        self.m_showBetTips.m_tipStatus = betTipsStatus.Start
        self.m_showBetTips:runCsbAction("start", false, nil)
        self.m_showBetTips:setVisible(true)
        performWithDelay(self.m_showBetTips,function()
            _fnNext()
        end, util_csbGetAnimTimes(self.m_showBetTips.m_csbAct, "start"))
    end
    local fnPlayShuaXinAnim = function(_betIndex, _fnNext)
        self.m_showBetTips.m_tipStatus = betTipsStatus.ShuaXin
        self.m_showBetTips:runCsbAction("shuaxin", false, nil)
        if nil ~= _betIndex then 
            fnUpdateLevelGoldIcon(_betIndex)
        end
        -- 第15帧播放粒子刷新图标
        performWithDelay(self.m_showBetTips,function()
            local particle = self.m_showBetTips:findChild("Particle_1")
            particle:setVisible(true)
            particle:setDuration(0.5)
            particle:setPositionType(0)
            particle:stopSystem()
            particle:resetSystem()
        end, 15/60)
        performWithDelay(self.m_showBetTips,function()
            _fnNext()
        end, util_csbGetAnimTimes(self.m_showBetTips.m_csbAct, "shuaxin"))
    end
    local fnPlayIdleAnim = function()
        self.m_showBetTips.m_tipStatus = betTipsStatus.Idle
        self.m_showBetTips:runCsbAction("idle", true)
    end

    -- 弹出提示面板
    local bSame = betIndex == self.m_showBetTips.m_tipBetIndex
    local idleTime = 4
    local curStatus = self.m_showBetTips.m_tipStatus
    -- print("[CodeGameScreenAZTECMachine:updateLevelGoldIcon]",betIndex,curStatus,bSame)
    if curStatus == betTipsStatus.None or 
        ((curStatus == betTipsStatus.Start or curStatus == betTipsStatus.Over) and not bSame) then
        -- 暂停延时回调
        self.m_showBetTips:stopAllActions()
        fnUpdateLevelGoldIcon(betIndex)
        fnPlayStartAnim(function()
            fnPlayShuaXinAnim(nil, function()
                fnPlayIdleAnim()
                performWithDelay(self.m_showBetTips,function()
                    self:playBetTipsOverAnim()
                end, idleTime)
            end)
        end)
    elseif curStatus == betTipsStatus.ShuaXin then
        if not bSame then 
            -- 暂停延时回调
            self.m_showBetTips:stopAllActions()
            fnPlayShuaXinAnim(betIndex, function()
                fnPlayIdleAnim()
                performWithDelay(self.m_showBetTips,function()
                    self:playBetTipsOverAnim()
                end, idleTime)
            end)
        end
    elseif curStatus == betTipsStatus.Idle then
        -- 暂停延时回调
        self.m_showBetTips:stopAllActions()
        if not bSame then 
            --立刻暂停idle刷新新的图标
            fnPlayShuaXinAnim(betIndex, function()
                fnPlayIdleAnim()
                performWithDelay(self.m_showBetTips,function()
                    self:playBetTipsOverAnim()
                end, idleTime)
            end)
        else
            --不刷新图标 但是要刷新倒计时
            fnPlayIdleAnim()
            performWithDelay(self.m_showBetTips,function()
                self:playBetTipsOverAnim()
            end, idleTime)
        end
    end
end
function CodeGameScreenAZTECMachine:playBetTipsOverAnim()
    if not self.m_showBetTips or not self.m_specialBets then
        return false
    end
    if not self.m_showBetTips:isVisible() then
        return
    end
    self.m_showBetTips:stopAllActions()
    self.m_showBetTips.m_tipStatus = betTipsStatus.Over
    self.m_showBetTips:runCsbAction("over", false, nil)
    performWithDelay(self.m_showBetTips,function()
        self.m_showBetTips:setVisible(false)
        self.m_showBetTips.m_tipStatus = betTipsStatus.None
    end, util_csbGetAnimTimes(self.m_showBetTips.m_csbAct, "over"))
end

function CodeGameScreenAZTECMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_enter_game.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:reelsDownDelaySetMusicBGVolume( ) 
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenAZTECMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) 	-- 必须调用不予许删除
    self:updateBetLevel()
    -- self.m_showSymbolNode:updateByBetLevel(self.m_iBetLevel)
    self.m_collectEffect:upDateGoodIdleframe()

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false and self.m_bIsReconnectGame ~= true then
        performWithDelay(self, function()
            self:chooseBetLayer()
        end, 0.3)
    end
    if self.m_runSpinResultData.p_freeSpinsLeftCount ~= nil and self.m_runSpinResultData.p_freeSpinsLeftCount <= 0 and
     self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idleframe"..self.m_currGameStatus)
    end
    
    self:addObservers()
end

function CodeGameScreenAZTECMachine:addObservers()
	BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        if perBetLevel ~= self.m_iBetLevel then
            -- gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_unLockJackpot"..self.m_iBetLevel..".mp3")
            -- self.m_showSymbolNode:updateByBetLevel(self.m_iBetLevel)
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:sendChooseIndex(params - 1)
        
    end, "CHOOSE_FS_MODEL")

    -- 切换bet检测黄金图标
    gLobalNoticManager:addObserver(self, function(target, _param)
        print(_param)
        self:checkLevelGoldIcon(_param)
    end,"checkLevelGoldIcon")
    
    gLobalNoticManager:addObserver(self, function(target, _param)
        print(_param)
        self:updateLevelGoldIcon(_param)
    end,"UpdateLevelGoldIcon")
end

function CodeGameScreenAZTECMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)  	-- 必须调用不予许删除

    for i, v in pairs(self.m_reelRunAnimaBG) do
        local reelNode = v[1]
        local reelAct = v[2]
        if reelNode:getParent() ~= nil then
            reelNode:removeFromParent()
        end

        reelNode:release()
        reelAct:release()

        self.m_reelRunAnimaBG[i] = v
    end

    -- 卸载自定义金边
    for i, v in pairs(self.m_reelEffectOtherList) do
        for j=1,3 do
            local reelNode = v[j][1]
            local reelAct = v[j][2]
            if not tolua.isnull(reelNode) then
                if reelNode:getParent() ~= nil then
                    reelNode:removeFromParent()
                end
                reelNode:release()
            end
    
            if not tolua.isnull(reelAct) then
                reelAct:release()
            end
            self.m_reelEffectOtherList[i][j] = nil
        end
        self.m_reelEffectOtherList[i] = nil
    end

    for i, v in pairs(self.m_reelEffectOtherBgList) do
        for j=1,3 do
            local reelNode = v[j][1]
            local reelAct = v[j][2]
            if not tolua.isnull(reelNode) then
                if reelNode:getParent() ~= nil then
                    reelNode:removeFromParent()
                end
                reelNode:release()
            end
    
            if not tolua.isnull(reelAct) then
                reelAct:release()
            end
            self.m_reelEffectOtherBgList[i][j] = nil
        end
        self.m_reelEffectOtherBgList[i] = nil
    end

    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

-- ------------玩法处理 -- 

--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenAZTECMachine:MachineRule_network_InterveneSymbolMap()

end
--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenAZTECMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据
    
end

---
-- 添加关卡中触发的玩法
--
function CodeGameScreenAZTECMachine:addSelfEffect()

    -- if self.m_bProduceSlots_InFreeSpin ~= true then
        self.m_vecWildNode = {}
        for i = 1, self.m_iReelRowNum, 1 do
            local vecRow = self.m_stcValidSymbolMatrix[i]
            for j = 1, self.m_iReelColumnNum, 1 do
                if vecRow[j] == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    self.m_vecWildNode[#self.m_vecWildNode + 1] = self:getFixSymbol(j, i, SYMBOL_NODE_TAG)
                end
            end
        end
        if #self.m_vecWildNode > 0 then 
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_COLLECT_COIN
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_COLLECT_COIN -- 动画类型
        end
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_freeSpinNewCount > 0 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.EFFECT_FREECOUNT_ADD -- 动画类型
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_FREECOUNT_ADD -- 动画类型
        end
    end
    -- end
end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenAZTECMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_COLLECT_COIN then
        self:collectWild(effectData)
    end
    if effectData.p_selfEffectType == self.EFFECT_FREECOUNT_ADD then
        self:addFreeCount(effectData)
    end
    
	return true
end

function CodeGameScreenAZTECMachine:collectWild(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    local triggerBonus = false
    local changeGameStatus = false
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.bonusType == "pick" then
        triggerBonus = true
    end

    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.status ~= 0 and self.m_runSpinResultData.p_selfMakeData.status ~= self.m_currGameStatus then 
        self.m_currGameStatus = self.m_runSpinResultData.p_selfMakeData.status
        changeGameStatus = true
    end

    local endPos = self.m_collectEffect:getGoodFlyEndPos()
    -- local endPos = self.m_collectEffect:getParent():convertToWorldSpace(cc.p(self.m_collectEffect:getPosition()))
    local newEndPos = self.m_slotEffectLayer:convertToNodeSpace(endPos)
    local totalWild = #self.m_vecWildNode
    -- 移除第一段音效，把第二段音效提前
    -- gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_wild_fire.mp3")
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_fire_boom.mp3")

    local coinCount = 8
    local createInterval = 0.05
    local symbolShoujiTime = 15/30
    --服务器有时会漏传 取当前值
    local newLevel = selfData.newStatus or self.m_collectEffect:getGoodLevel()
    for i = 1, #self.m_vecWildNode, 1 do
        local symbol = self.m_vecWildNode[i]
        symbol:runAnim("shouji")
        local delayNode = cc.Node:create()
        self:addChild(delayNode)
        performWithDelay(delayNode, function()
            delayNode:removeFromParent()

            -- gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_fire_boom.mp3")
            local startPos = symbol:getParent():convertToWorldSpace(cc.p(symbol:getPosition()))
            local newStartPos = self.m_slotEffectLayer:convertToNodeSpace(startPos)

            local flyTime = 15/30

            local angleList = {}
            --每个小块收集时 延时创建一定数量随机位置的金币飞往金币堆
            for _coinIndex=1,coinCount do
                local waitNode = cc.Node:create()
                self:addChild(waitNode)
                performWithDelay(waitNode, function()
                    waitNode:removeFromParent()

                    --创建单个金币
                    local effectNode = util_createAnimation("AZTEC_collect_fly.csb")
                    local actionName = "fly" 
                    local randomValue = math.random(0, 4)
                    if randomValue > 0 then
                        actionName = string.format("fly%d", randomValue) 
                    end
                    
                    effectNode:runCsbAction(actionName, true)
                    self.m_slotEffectLayer:addChild(effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
                    --修改初始位置
                    local effectAngle = self:getCollectCoinAngle(angleList, coinCount)
                    table.insert(angleList, effectAngle)
                    local radius = math.random(128/4, 128/2)
                    local effectPos = cc.p( util_getCirclePointPos(newStartPos.x, newStartPos.y, radius, effectAngle) )
                    effectNode:setPosition(effectPos)
                    --飞行动作
                    local actList = {}
                    table.insert(actList, self:getCollectMoveAction(symbol.p_cloumnIndex, flyTime, effectPos, newEndPos))
                    --结束回调
                    table.insert(actList, cc.CallFunc:create(function()
                        effectNode:removeFromParent()
        
                        if i == totalWild and 1 == _coinIndex then
                            if changeGameStatus == true then 
                                gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_change_wild_status.mp3")
                                self.m_collectEffect:playGoodCollectAnim(newLevel, true, function()
                                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, {"collect"..self.m_currGameStatus, false, function()
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end})
                                end)
                            else
                                self.m_collectEffect:playGoodCollectAnim(newLevel, false, function()
                                    if triggerBonus == true then
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end
                                end)
                            end
                        end

                    end))
                    effectNode:runAction(cc.Sequence:create( actList ))

                end, (_coinIndex-1)*createInterval)

            end
            
        end, symbolShoujiTime)
    end
    
    performWithDelay(self, function()
        gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_fire_fly.mp3")
    end, 0.5)
    if triggerBonus ~= true and changeGameStatus ~= true then
        -- 信号收集动效 -> 最后一个飞行动效 -> 金币堆收集 + 升阶动效
        local curLevel = self.m_collectEffect:getGoodLevel()
        local newLevel = selfData.newStatus or self.m_collectEffect:getGoodLevel()
        local isUpGrade = newLevel > curLevel

        local flyTime  = isUpGrade and (coinCount-1)*createInterval+15/30 or 0 
        local goodTime = isUpGrade and 45/30+45/30 or 0
        local delayTime = symbolShoujiTime + flyTime + goodTime
        local delayNode = cc.Node:create()
        self:addChild(delayNode)
        performWithDelay(delayNode, function()
            effectData.p_isPlay = true
            self:playGameEffect()

            delayNode:removeFromParent()
        end, delayTime)
        
    end
end
----根据列数获取移动轨迹
function CodeGameScreenAZTECMachine:getCollectMoveAction(_col, _flyTime, _startPos, _endPos)
    local act_move = nil
    -- 弧线移动
    if 3 ~= _col then
        local distance = math.sqrt((_endPos.x - _startPos.x) * (_endPos.x - _startPos.x) + (_endPos.y - _startPos.y) * (_endPos.y - _startPos.y))
        local radius = distance/2
        local flyAngle = util_getAngleByPos(_startPos, _endPos)
        local offsetAngle = _endPos.x > _startPos.x and -90 or 90
        local pos1 = cc.p( util_getCirclePointPos(_startPos.x, _startPos.y, radius, flyAngle + offsetAngle) )
        local pos2 = cc.p( util_getCirclePointPos(_endPos.x, _endPos.y, radius/2, flyAngle + offsetAngle) )
        act_move = cc.BezierTo:create(_flyTime, {pos1, pos2, _endPos})
    -- 直线移动
    else
        act_move = cc.MoveTo:create(_flyTime, _endPos)
    end

    return act_move
end
--随机获取一个以小块为中心的角度
function CodeGameScreenAZTECMachine:getCollectCoinAngle(_angleList, _maxCount)
    local angle = 270
    local intervalAngle = 360/(_maxCount-1)/2 /2

    local checkAngle = function(_angle)
        for _index,_angleValue in ipairs(_angleList) do
            if math.abs(_angle - _angleValue) < intervalAngle then
                return false
            end
        end

        return true
    end

    while not checkAngle(angle) do
        angle = math.random(0,360)
    end

    return angle
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenAZTECMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


----
--- 处理spin 成功消息
--
function CodeGameScreenAZTECMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end

    if spinData.action == "SPIN" then
        release_print("消息返回胡来了")

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        self.m_ScatterShowCol = {}
        local vecCol = {}

        -- for i = 1, self.m_iReelRowNum, 1 do
        --     local vecRow = spinData.result.reels[i]
        --     for j = 1, self.m_iReelColumnNum, 1 do
        --         if vecRow[j] == TAG_SYMBOL_TYPE.SYMBOL_WILD or vecRow[j] == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --             vecCol[j] = j
        --         end
        --     end
        -- end
        --上面的有报错 修改一下循环 21.07.30
        for i,_vecRow in ipairs(spinData.result.reels) do
            for j,_symbolType in ipairs(_vecRow) do
                if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    vecCol[j] = j
                end
            end
        end
        for col = 1, #vecCol, 1 do
            if col == vecCol[col] then
                self.m_ScatterShowCol[col] = col
            else
                break
            end
        end
        if #self.m_ScatterShowCol >= 2 then
            self.m_ScatterShowCol[#self.m_ScatterShowCol + 1] = #self.m_ScatterShowCol + 1
        end

        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    end

    if self.m_bIsSelectCall == true then
        local spinData = param[2]
        globalData.slotRunData.freeSpinCount = spinData.result.freespin.freeSpinsLeftCount 
        globalData.slotRunData.totalFreeSpinCount = spinData.result.freespin.freeSpinsTotalCount
        self.m_iFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        self.m_iSelectID = spinData.result.selfData.freeSpinType + 1 
        self.m_iReelRowNum = self.m_vecReelRow[self.m_iSelectID]
        self.m_configData:setFsModel(self.m_vecFsModel[self.m_iSelectID])
        self:showFreeSpinView(self.m_effectData)
    end

end


function CodeGameScreenAZTECMachine:sendChooseIndex(index)
    self.m_bIsSelectCall = true
    self.m_iClickID = index
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT, data = index}
    local httpSendMgr = SendDataManager:getInstance()
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)

end

function CodeGameScreenAZTECMachine:requestSpinResult()

    if self.m_classicMachine ~= nil then
        return
    end
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and
    self:getCurrSpinMode() ~= REWAED_SPIN_MODE and
    self:getCurrSpinMode() ~= RESPIN_MODE
    then

        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,
                        data=self.m_collectDataList,jackpot = self.m_jackpotList, betLevel = self.m_iBetLevel}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName,
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end

function CodeGameScreenAZTECMachine:playEffectNotifyNextSpinCall( )
    
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or 
    self:getCurrSpinMode() == FREE_SPIN_MODE then
        
        local delayTime = 0.5
        local winTime = self:getWinCoinTime()
        if self.m_bIsBonusGameOver == true then
            self.m_bIsBonusGameOver = false
            winTime = 0
        end
        delayTime = delayTime + winTime
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    elseif self.m_chooseRepin then
        self.m_chooseRepin = false
        self:normalSpinBtnCall()
    end
    self.m_bIsSelectCall = false

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenAZTECMachine:initGameStatusData(gameData)
    local goodData = {
        level = 1
    }
    if nil ~= gameData.gameConfig then
        if gameData.gameConfig.extra ~= nil  then
            goodData.level = gameData.gameConfig.extra.newStatus or 1
            self.m_currGameStatus = gameData.gameConfig.extra.status
        end
    end

    self.m_collectEffect:setGoodData(goodData)
    
    BaseFastMachine.initGameStatusData(self, gameData)
end

function CodeGameScreenAZTECMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end
    if self.m_reelEffectOtherList == nil then
        self.m_reelEffectOtherList ={}
    end

    local reelEffectNode = nil
    local reelAct = nil
    --判断当前行数是否大于3
    if self.m_iReelRowNum > 3 then
        if self.m_reelEffectOtherList[col] == nil then
            local tempList = self:createOtherReelEffect(col)
            reelEffectNode,reelAct = self:getReelEffect(tempList)
        else
            reelEffectNode,reelAct = self:getReelEffect(self.m_reelEffectOtherList[col])
        end
    else
        if self.m_reelRunAnima[col] == nil then
            reelEffectNode, reelAct = self:createReelEffect(col)
        else
            local reelObj = self.m_reelRunAnima[col]
    
            reelEffectNode = reelObj[1]
            reelAct = reelObj[2]
        end
    end
    

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    self:setLongAnimaInfo(reelEffectNode, col)

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)


    local reelEffectNodeBG = nil
    local reelActBG = nil
    if self.m_iReelRowNum > 3 then
        if self.m_reelEffectOtherBgList[col] == nil then
            local tempList = self:createOtherReelEffectBG(col)
            reelEffectNodeBG, reelActBG = self:getReelEffect(tempList)
        else
            reelEffectNodeBG, reelActBG = self:getReelEffect(self.m_reelEffectOtherBgList[col])
        end
    else
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]
    
            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end
    end

    reelEffectNodeBG:setScaleX(1)
    reelEffectNodeBG:setScaleY(1)

    reelEffectNodeBG:setVisible(true)
    util_csbPlayForKey(reelActBG, "ationframe", true)

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenAZTECMachine:createReelEffectBG(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. "_bg.csb")

    reelEffectNode:retain()
    effectAct:retain()

    self:findChild("rell"):addChild(reelEffectNode, 1)
    reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
    self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}
--设置bonus scatter 信息
function CodeGameScreenAZTECMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

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
        if targetSymbolType == symbolType or targetSymbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        
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
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenAZTECMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == nodeNum then
        if nodeNum <= 1 then
            return runStatus.DUANG, false
        elseif nodeNum >= 2 then
            return runStatus.DUANG, true
        end
    else
        return runStatus.NORUN, false
    end
end

function CodeGameScreenAZTECMachine:bgMoveAnimation(func)
    local actionTable = {}
    for i = 1, #BG_MOVE_POS, 1 do
        local moveTo = cc.MoveTo:create(1.0 / 30, BG_MOVE_POS[i])
        actionTable[#actionTable +1] = moveTo
    end
    local callback = cc.CallFunc:create(function()
        if func ~= nil then
            func()
        end
    end)
    actionTable[#actionTable +1] = callback
    self:runAction(cc.Sequence:create(actionTable))
    gLobalSoundManager:playSound("AZTECSounds/sound_AZTEC_bg_doudong.mp3")
end

function CodeGameScreenAZTECMachine:slotReelDown()
    --防止最后一次free增加次数，将freeOver加到effect中
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        if self.m_runSpinResultData.p_freeSpinNewCount > 0 then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        end
    end
    CodeGameScreenAZTECMachine.super.slotReelDown(self)
end

function CodeGameScreenAZTECMachine:initReelEffect( )
    CodeGameScreenAZTECMachine.super.initReelEffect(self)

    self.m_reelEffectOtherList = {}
    for i = 3, self.m_iReelColumnNum do
        self:createOtherReelEffect(i)
    end
    self.m_reelEffectOtherBgList = {}
    for i=3,self.m_iReelColumnNum do
        self:createOtherReelEffectBG(i)
    end
end

function CodeGameScreenAZTECMachine:createOtherReelEffect(col)
    self.m_reelEffectOtherList[col] = {}
    for i,v in ipairs(self.m_vecReelRow) do
        if i ~= 1 then
            local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .."_".. v..".csb")
            reelEffectNode:retain()
            effectAct:retain()
            self.m_slotEffectLayer:addChild(reelEffectNode)
            table.insert( self.m_reelEffectOtherList[col],{reelEffectNode, effectAct})

            reelEffectNode:setVisible(false)
        end
        
    end
    return self.m_reelEffectOtherList[col]
end

function CodeGameScreenAZTECMachine:createOtherReelEffectBG(col)
    self.m_reelEffectOtherBgList[col] = {}
    for i,v in ipairs(self.m_vecReelRow) do
        if i ~= 1 then
            local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. "_bg".."_"..v..".csb")

            reelEffectNode:retain()
            effectAct:retain()

            self:findChild("rell"):addChild(reelEffectNode, 1)
            reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
            
            table.insert( self.m_reelEffectOtherBgList[col],{reelEffectNode, effectAct})

            reelEffectNode:setVisible(false)
        end
    end
    
    return self.m_reelEffectOtherBgList[col]
end

function CodeGameScreenAZTECMachine:getReelEffect(reelAnimalist)
    if self.m_iReelRowNum == 4 then
        return reelAnimalist[1][1],reelAnimalist[1][2]
    elseif self.m_iReelRowNum == 5 then
        return reelAnimalist[2][1],reelAnimalist[2][2]
    elseif self.m_iReelRowNum == 6 then
        return reelAnimalist[3][1],reelAnimalist[3][2]
    else
        return reelAnimalist[1][1],reelAnimalist[1][2]
    end
end


return CodeGameScreenAZTECMachine
