---
-- xcyy
-- 2018-12-18
-- FairyDragonMiniMachine.lua
--
--

local BaseMiniFastMachine = require "Levels.BaseMiniFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local SlotParentData = require "data.slotsdata.SlotParentData"

local FairyDragonMiniMachine = class("FairyDragonMiniMachine", BaseMiniFastMachine)

FairyDragonMiniMachine.SYMBOL_Blank = 21 --空
FairyDragonMiniMachine.SYMBOL_Symbol_1 = 22 --数字1
FairyDragonMiniMachine.SYMBOL_Symbol_2 = 23 --数字2
FairyDragonMiniMachine.SYMBOL_Symbol_3 = 24 --数字3
FairyDragonMiniMachine.SYMBOL_Symbol_4 = 25 --数字4
FairyDragonMiniMachine.SYMBOL_JackPot_Grand1 = 26 --Grand1段
FairyDragonMiniMachine.SYMBOL_JackPot_Grand2 = 27 --Grand2段
FairyDragonMiniMachine.SYMBOL_JackPot_Grand3 = 28 --Grand3段
FairyDragonMiniMachine.SYMBOL_JackPot_Grand4 = 29 --Grand4段
FairyDragonMiniMachine.SYMBOL_JackPot_Grand5 = 30 --Grand5段

FairyDragonMiniMachine.EFFECT_ADD_WIN_LINES = GameEffect.EFFECT_SELF_EFFECT - 2 --增加中奖线
FairyDragonMiniMachine.EFFECT_SHOW_JACKPOT = GameEffect.EFFECT_SELF_EFFECT - 3 --显示jackpot
FairyDragonMiniMachine.EFFECT_BONUSGAME_OVER = GameEffect.EFFECT_SELF_EFFECT - 1 --玩法结束

FairyDragonMiniMachine.m_runCsvData = nil
FairyDragonMiniMachine.m_machineIndex = nil -- csv 文件模块名字

FairyDragonMiniMachine.gameResumeFunc = nil
FairyDragonMiniMachine.gameRunPause = nil
FairyDragonMiniMachine.m_slotReelDown = nil

FairyDragonMiniMachine.m_GrandContinuities = true

FairyDragonMiniMachine.m_QuickStop = false
-- 构造函数
function FairyDragonMiniMachine:ctor()
    BaseMiniFastMachine.ctor(self)
end



function FairyDragonMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil
    self.m_QuickStop = false
    self.m_machineIndex = data.index
    self.m_parent = data.parent
    --滚动节点缓存列表
    self.cacheNodeMap = {}
    self.m_TypeIndex = 1
    self.m_GrandContinuities = true
    --init
    self:initGame()
end

function FairyDragonMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FairyDragonMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FairyDragon"
end

function FairyDragonMiniMachine:getlevelConfigName()
    local levelConfigName = "LevelFairyDragonMiniConfig.lua"

    return levelConfigName
end

function FairyDragonMiniMachine:getMachineConfigName()
    local str = "Mini"

    return self.m_moduleName .. str .. "Config" .. ".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FairyDragonMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_Blank then
        return "FairyDragon_wanfan_blank"
    elseif symbolType == self.SYMBOL_Symbol_1 then
        return "FairyDragon_wanfan_jinbi1"
    elseif symbolType == self.SYMBOL_Symbol_2 then
        return "FairyDragon_wanfan_jinbi2"
    elseif symbolType == self.SYMBOL_Symbol_3 then
        return "FairyDragon_wanfan_jinbi3"
    elseif symbolType == self.SYMBOL_Symbol_4 then
        return "FairyDragon_wanfan_jinbi4"
    elseif symbolType == self.SYMBOL_JackPot_Grand1 then
        return "FairyDragon_jintiao_grand1"
    elseif symbolType == self.SYMBOL_JackPot_Grand2 then
        return "FairyDragon_jintiao_grand2"
    elseif symbolType == self.SYMBOL_JackPot_Grand3 then
        return "FairyDragon_jintiao_grand3"
    elseif symbolType == self.SYMBOL_JackPot_Grand4 then
        return "FairyDragon_jintiao_grand4"
    elseif symbolType == self.SYMBOL_JackPot_Grand5 then
        return "FairyDragon_jintiao_grand5"
    end

    return nil
end

---
-- 读取配置文件数据
--
function FairyDragonMiniMachine:readCSVConfigData()
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(),"LevelFairyDragonMiniConfig.lua")
    end
    self.m_configData:setBaseMachineBetLevel( self.m_parent.m_iBetLevel )
    globalData.slotRunData.levelConfigData = self.m_configData
end


function FairyDragonMiniMachine:initMachineCSB()
    self:createCsbNode("FairyDragon/GameScreenFairyDragon_game.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
end
--
---
--
function FairyDragonMiniMachine:initMachine()
    self.m_moduleName = "FairyDragon" -- self:getModuleName()
    BaseMiniFastMachine.initMachine(self)
    self:initUI()
end

function FairyDragonMiniMachine:initUI()
    self.m_bgView = util_createView("FairyDragonSrc.FairyDragonMiniBgView",self)
    self:findChild("bgNode"):addChild(self.m_bgView)

    self.m_RespinBarView = util_createView("FairyDragonSrc.FairyDragonRespinBarView")
    self:findChild("spin_cishu"):addChild(self.m_RespinBarView)

    self.m_shoujifankui = util_createAnimation("FairyDragon_wanfan_jinbishouji_fankui.csb")
    self:findChild("Node_shoujifankui"):addChild(self.m_shoujifankui)
    self.m_shoujifankui:setVisible(false)
    self.m_shoujifankui:setScale(2)

end

function FairyDragonMiniMachine:playShowAction()
    self:showTips()

    self:runCsbAction(
        "guochang",
        false,
        function()
            if self.m_TipView then

                self.m_TipViewWaitNode = cc.Node:create()
                self:addChild(self.m_TipViewWaitNode)
                performWithDelay(self.m_TipViewWaitNode,function(  )

                    self.m_TipViewWaitNode:removeFromParent()

                    self.m_TipViewWaitNode = nil

                    if self.m_TipView then
                        self.m_TipView:runCsbAction(
                            "animation2",
                            false,
                            function()
                                if self.m_TipView then
                                    self.m_TipView:removeFromParent()
                                    self.m_TipView = nil
                                end
                            end)
                    end
                   
                end,2)
                
            end
            
        end
    )
end
function FairyDragonMiniMachine:initMiniBgData(data, machine)
    if self.m_bgView then
        self.m_bgView:initLowUI(data)
        self.m_bgView:initMachine(machine)
    end
end
--
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FairyDragonMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniFastMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Symbol_1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Symbol_2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Symbol_3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Symbol_4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Grand1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Grand2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Grand3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Grand4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_JackPot_Grand5, count = 2}
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------
function FairyDragonMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    
end

function FairyDragonMiniMachine:checkNotifyUpdateWinCoin()
    -- 这里作为freespin下 连线时通知钱数更新的接口

    if self.m_parent.m_runSpinResultData.p_winLines and #self.m_parent.m_runSpinResultData.p_winLines > 0 then
    else
        local winLines = self.m_reelResultLines

        if #winLines <= 0 then
            return
        end
        -- 如果freespin 未结束，不通知左上角玩家钱数量变化
        local isNotifyUpdateTop = true
        if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
            isNotifyUpdateTop = false
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_parent.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

function FairyDragonMiniMachine:slotReelDown()
    self.m_slotReelDown = true
    BaseMiniFastMachine.slotReelDown(self)
end

--本列停止 判断下列是否有长滚
function FairyDragonMiniMachine:getNextReelIsLongRun(reelCol)
    if reelCol > self.m_iReelColumnNum then
        return false
    end
    local symbolType1 = self.m_stcValidSymbolMatrix[1][1]
    local symbolType2 = self.m_stcValidSymbolMatrix[1][2]
    local symbolType3 = self.m_stcValidSymbolMatrix[1][3]
    local symbolType4 = self.m_stcValidSymbolMatrix[1][4]
    if
        reelCol >= 4 and symbolType1 == self.SYMBOL_JackPot_Grand1 and symbolType2 == self.SYMBOL_JackPot_Grand2 and symbolType3 == self.SYMBOL_JackPot_Grand3 and
            symbolType4 == self.SYMBOL_JackPot_Grand4
     then
        return true
    end

    return false
end
function FairyDragonMiniMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false
    -- 处理长滚动
    if self:getNextReelIsLongRun(reelCol) == true and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true -- 触发了长滚动
    end
    return isTriggerLongRun
end
-- 每个reel条滚动到底
function FairyDragonMiniMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if reelCol == 4 and self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
        self:setReelDownSoundId(reelCol,self.m_reelDownSoundPlayed )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end
    

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol + 1)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, 1, SYMBOL_NODE_TAG))
    if targSp and targSp.p_symbolType ~= self.SYMBOL_Blank then

        if self:isSymbolNum(targSp.p_symbolType) then
            self.m_GrandContinuities = false 

            local soundPath =  "FairyDragonSounds/music_FairyDragon_SymbolNum_Down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end


        elseif self:isSymbolGrand(targSp.p_symbolType) then
            if self.m_GrandContinuities then
                local soundPath =  "FairyDragonSounds/music_FairyDragon_SymbolGrand_Down_" ..targSp.p_cloumnIndex .. ".mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,"SymbolGrand_Dow" )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

            end
            
        end

        targSp:runAnim(
            "buling",
            false,
            function()
                if targSp and targSp.p_symbolType then
                    targSp:runAnim("idleframe", true)
                end
                
            end
        )
    end
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
    return isTriggerLongRun
end

function FairyDragonMiniMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getReelParent(_iCol):getChildByTag(self:getNodeTag(_iCol, _iRow, SYMBOL_NODE_TAG))
    local clipSp = self.m_clipParent:getChildByTag(self:getNodeTag(_iCol, _iRow, SYMBOL_NODE_TAG))
    if not targSp then
        targSp = clipSp
    end
    if targSp ~= nil then
        targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_JackPot_Symbol), self.SYMBOL_JackPot_Symbol)
        targSp.p_symbolType = _type
    end
    return targSp
end

function FairyDragonMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function FairyDragonMiniMachine:playEffectNotifyChangeSpinStatus()

    self.m_parent:setNormalAllRunDown()

end

function FairyDragonMiniMachine:addObservers()
    BaseMiniFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            local flag = params
            if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
                flag = false
            end
        end,
        "BET_ENABLE"
    )
end

function FairyDragonMiniMachine:quicklyStopReel(colIndex)
    
    if self.m_QuickStop  then
        BaseMiniFastMachine.quicklyStopReel(self, colIndex)
    end

    
    
end

function FairyDragonMiniMachine:onExit()
    BaseMiniFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function FairyDragonMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
    self.m_parent:requestSpinReusltData()
end

function FairyDragonMiniMachine:beginMiniReel()

    self.m_QuickStop = true

    self.m_GrandContinuities = true

    BaseMiniFastMachine.beginReel(self)
    self.m_slotReelDown = false
    if self.m_RespinBarView then
        self.m_RespinBarView:changeRespinCount()
    end
    if self.m_TipView then
        self.m_TipView:runCsbAction(
            "animation2",
            false,
            function()
                self.m_TipView:removeFromParent()
                self.m_TipView = nil
            end
        )
    end
end

-- 消息返回更新数据
function FairyDragonMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self:updateNetWorkData()
end

function FairyDragonMiniMachine:enterLevel()
    BaseMiniFastMachine.enterLevel(self)
end

function FairyDragonMiniMachine:randomSlotNodes()
    local symbolTypeList = {
        self.SYMBOL_JackPot_Grand1,
        self.SYMBOL_JackPot_Grand2,
        self.SYMBOL_JackPot_Grand3,
        self.SYMBOL_JackPot_Grand4,
        self.SYMBOL_JackPot_Grand5
    }
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = symbolTypeList[colIndex] --self:getRandomReelType(colIndex, reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = symbolTypeList[colIndex] --self:getRandomReelType(colIndex, reelDatas)
            end
            local showOrder = self:getBounsScatterDataZorder(symbolType)

            local node = self:getCacheNode(colIndex, symbolType)
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
end
function FairyDragonMiniMachine:enterLevelMiniSelf()
end

function FairyDragonMiniMachine:dealSmallReelsSpinStates()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
end

function FairyDragonMiniMachine:playEffectNotifyNextSpinCall()
    local delayTime = 1

    performWithDelay(
        self,
        function()
            self.m_parent:playEffectNotifyNextSpinCall()
        end,
        delayTime
    )
end

function FairyDragonMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function FairyDragonMiniMachine:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

function FairyDragonMiniMachine:showEffect_LineFrame(effectData)
    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end

--是否播放结束后显示系统弹框
function FairyDragonMiniMachine:isPlayEffectOverShowUI()
    return false
end

function FairyDragonMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function FairyDragonMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

--[[
    @desc: 根据服务器返回的消息， 添加对应的feature 类型
    time:2018-12-04 17:34:04
    @return:
]]
function FairyDragonMiniMachine:netWorklineLogicCalculate()
end

function FairyDragonMiniMachine:addSelfEffect()
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.number then
        if selfdata.number > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_ADD_WIN_LINES
        end
    end

    if selfdata and selfdata.triggerGrand then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SHOW_JACKPOT
    end

    local num = self.m_runSpinResultData.p_reSpinCurCount
    if num == 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT + 5
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BONUSGAME_OVER
    end
end

function FairyDragonMiniMachine:reelDownNotifyChangeSpinStatus()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
end


function FairyDragonMiniMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_BONUSGAME_OVER then
        self:playBonusOverEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_ADD_WIN_LINES then

            self:playAddLinesNumEffect(effectData)

    elseif effectData.p_selfEffectType == self.EFFECT_SHOW_JACKPOT then
        self:showJackpotWinEffect(effectData)
    end
    return true
end

function FairyDragonMiniMachine:playAddLinesNumEffect(effectData)
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    if selfdata and selfdata.number then
        local num = selfdata.number
        if num > 0 then
            self:playFlyEffect()
            performWithDelay(
                self,
                function()
                    self.m_shoujifankui:setVisible(true)
                    self.m_shoujifankui:runCsbAction("shouji",false,function(  )
                        self.m_shoujifankui:setVisible(false)
                    end)

                    self:showAddLineNum(num)
                    self:showAddLineArrow()
                end,
                0.85
            )
            performWithDelay(self,function()
                local allLines = selfdata.counts
                self.m_bgView:setLines(num,allLines,function()
                        local time = 1.5
                        performWithDelay(self,function()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                        end,time)
                end)
            end,3.1)
        end
    end
end

function FairyDragonMiniMachine:setWinLines(_num)
    if self.m_bgView then
        self.m_bgView:showNewLines(_num)
    end
end

function FairyDragonMiniMachine:showJackpotWinEffect(effectData)

    gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_WinGrand.mp3")

    self.m_parent:clearCurMusicBg()

    local greandWin = util_createAnimation("FairyDragon_jintiao_grandWin.csb")
    self:findChild("shuoming"):addChild(greandWin)
    greandWin:runCsbAction("actionframe", true)
    performWithDelay(self,function()
        if self.m_bgView then
            self.m_bgView:playGrandJackpotWinEffect(function()
                    performWithDelay(self,function()
                            greandWin:removeFromParent()

                            gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_GrandVew.mp3")

                            local winCoins = self.m_runSpinResultData.p_selfMakeData.grandWin
                            local jackpotView = util_createView("FairyDragonSrc.FairyDragonRespinJackpotWin")
                            self:findChild("shuoming"):addChild(jackpotView)
                            jackpotView:showWinNum(winCoins,function()

                                -- grang 直接结束
                                local winCoins = self.m_runSpinResultData.p_winAmount
                                self.m_parent:showRespinGrandJackpot(winCoins)
                                                            
                            end)
                    end,3)
            end)
        end
    end,1)
end

function FairyDragonMiniMachine:playBonusOverEffect(effectData)

    self.m_parent:clearCurMusicBg()
    gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_JackPotEnd.mp3")

    local winType = "multiple"
    local isJackpot = false
    local jackpotIndex = 1
    local selfdata = self.m_runSpinResultData.p_selfMakeData
    local winCoins = self.m_runSpinResultData.p_winAmount
    if selfdata.winType == "multiple" then
    else
        if selfdata.winType == "mini" then
            jackpotIndex = 1
        elseif selfdata.winType == "minor" then
            jackpotIndex = 2
        elseif selfdata.winType == "major" then
            jackpotIndex = 3
        elseif selfdata.winType == "grand" then
            jackpotIndex = 4
        end
        isJackpot = true
    end

      
    if isJackpot then
    else

        if self.m_bgView.m_showTag > 0 then
            self.m_bgView.m_coinsTips[self.m_bgView.m_showTag]:runCsbAction("idle3")
        end

    end

    performWithDelay(
        self,
        function()
            
            if isJackpot then

                self.m_parent:showRespinJackpot(
                    jackpotIndex,
                    winCoins,
                    function()
                        -- effectData.p_isPlay = true
                        -- self:playGameEffect()
                    end
                )
           
            else
                self.m_parent:showBonusGameOver(
                    winCoins,
                    function()
                        -- effectData.p_isPlay = true
                        -- self:playGameEffect()
                    end
                )
            end
        end,
        4
    )
end

function FairyDragonMiniMachine:showAddLineNum(_num)
    local numView = util_createView("FairyDragonSrc.FairyDragonAddLineTips")
    self:findChild("addLineNode"):addChild(numView, 100)
    numView:setNum(_num)
    numView:runCsbAction(
        "over",
        false,
        function()
            numView:removeFromParent()
        end
    )
end

function FairyDragonMiniMachine:showAddLineArrow()
    local arrow = util_createView("FairyDragonSrc.FairyDragonAddLineEffect")
    self:findChild("addLineNode"):addChild(arrow, 10)
    arrow:runCsbAction(
        "actionframe",
        false,
        function()
            arrow:removeFromParent()
        end
    )
end

function FairyDragonMiniMachine:showTips()
    self.m_TipView = util_createView("FairyDragonSrc.FairyDragonRespinTipsView")
    self:findChild("shuoming"):addChild(self.m_TipView, 10)
    self.m_TipView:runCsbAction(
        "actionframe1",
        false,
        function()

        end)
end

function FairyDragonMiniMachine:playFlyEffect()
    

    for iCol = 1, self.m_iReelColumnNum do --列
        for iRow = self.m_iReelRowNum, 1, -1 do --行
            local targetNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targetNode and targetNode.p_symbolType <= self.SYMBOL_Symbol_4 and targetNode.p_symbolType > self.SYMBOL_Blank then
                targetNode:runAnim("idleframe",true)

                local node = cc.Node:create()
                self:addChild(node)
                
                performWithDelay(node,function(  )

                    node:removeFromParent()

                    self:runFlyAct(targetNode)
                end,0.5)
                
            end
        end
    end
end

function FairyDragonMiniMachine:runFlyAct(startNode)

    gLobalSoundManager:playSound("FairyDragonSounds/music_FairyDragon_JPgame_Collect.mp3")

    local flyNode = util_createAnimation("FairyDragon_wanfan_jinbishouji.csb")
    self:findChild("Node_30"):addChild(flyNode)

    local index = self:getPosReelIdx(startNode.p_rowIndex, startNode.p_cloumnIndex)
    local pos = util_getOneGameReelsTarSpPos(self,index ) 
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
    local startPos = self:findChild("Node_30"):convertToNodeSpace(worldPos)
    flyNode:setPosition(startPos)

    for i=1,self.m_iReelColumnNum do
        
        local node = flyNode:findChild("Node_"..i)
        if node then
            if startNode.p_cloumnIndex == i then
                node:setVisible(true)
            else
                node:setVisible(false)
            end 
        end

        
        
    end

    flyNode:runCsbAction(
        "shouji",
        false,
        function()
            flyNode:stopAllActions()
            flyNode:removeFromParent()
        end
    )
end
--设置长滚信息
function FairyDragonMiniMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false
    local longRunIndex = 0

    for col = 1, iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col] -- 提取某一列所有内容

        if bRunLong == true and col == 5 then
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
        end

        local runLen = reelRunData:getReelRunLen()
        bRunLong = self:getNextReelIsLongRun(col)
    end
end
function FairyDragonMiniMachine:getLongRunLen(col, index)
    local len = 0

    local lastColLens = self.m_reelRunInfo[col - 1]:getReelRunLen()
    local columnData = self.m_reelColDatas[col]
    local colHeight = columnData.p_slotColumnHeight

    if len == 0 then
        local reelCount = (self.m_configData.p_reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
        len = lastColLens + math.floor(reelCount) * columnData.p_showGridCount --速度x时间 / 列高
    end
    return len
end

function FairyDragonMiniMachine:isSymbolNum(symbolType)
    
    if symbolType == self.SYMBOL_Symbol_1 then
        return true
    elseif symbolType == self.SYMBOL_Symbol_2 then
        return true
    elseif symbolType == self.SYMBOL_Symbol_3 then
        return true
    elseif symbolType == self.SYMBOL_Symbol_4 then
        return true  
    end

end

function FairyDragonMiniMachine:isSymbolGrand(symbolType)
    
    if symbolType == self.SYMBOL_JackPot_Grand1 then
        return true
    elseif symbolType == self.SYMBOL_JackPot_Grand2 then
        return true
    elseif symbolType == self.SYMBOL_JackPot_Grand3 then
        return true
    elseif symbolType == self.SYMBOL_JackPot_Grand4 then
        return true
    elseif symbolType == self.SYMBOL_JackPot_Grand5 then
        return true
        
    end
end

return FairyDragonMiniMachine
