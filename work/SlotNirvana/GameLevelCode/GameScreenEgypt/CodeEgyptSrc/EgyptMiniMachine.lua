---
-- xcyy
-- 2018-12-18
-- EgyptMiniMachine.lua
--
--

local BaseMiniFastMachine = require "Levels.BaseMiniFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local SlotParentData = require "data.slotsdata.SlotParentData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local EgyptMiniSlotsNode = require "CodeEgyptSrc.EgyptMiniSlotsNode"
local EgyptMiniMachine = class("EgyptMiniMachine", BaseMiniFastMachine)

EgyptMiniMachine.SYMBOL_CLASSIC_BONUS1 = 110 -- 自定义的小块类型
EgyptMiniMachine.SYMBOL_CLASSIC_BONUS2 = 111
EgyptMiniMachine.SYMBOL_CLASSIC_BONUS3 = 112
EgyptMiniMachine.SYMBOL_CLASSIC_BONUS4 = 113
EgyptMiniMachine.SYMBOL_CLASSIC_BONUS5 = 114
EgyptMiniMachine.SYMBOL_COIN = 1001
EgyptMiniMachine.SYMBOL_Blank = 1002
EgyptMiniMachine.SYMBOL_2X = 1010
EgyptMiniMachine.SYMBOL_4X = 1011
EgyptMiniMachine.SYMBOL_8X = 1014
EgyptMiniMachine.SYMBOL_10X = 1015
EgyptMiniMachine.SYMBOL_FIRE = 97


EgyptMiniMachine.EFFECT_TYPE_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 1
EgyptMiniMachine.EFFECT_TYPE_TEN_COLLECT = GameEffect.EFFECT_SELF_EFFECT - 2
EgyptMiniMachine.EFFECT_TYPE_FAST_WIN = GameEffect.EFFECT_SELF_EFFECT - 3


EgyptMiniMachine.m_machineIndex = nil -- csv 文件模块名字

EgyptMiniMachine.gameResumeFunc = nil
EgyptMiniMachine.gameRunPause = nil
EgyptMiniMachine.m_slotReelDown = nil

EgyptMiniMachine.m_longRunFlag = nil
EgyptMiniMachine.m_totalWeight = nil

EgyptMiniMachine.m_levelGetAnimNodeCallFun = nil
EgyptMiniMachine.m_levelPushAnimNodeCallFun = nil

local COINS_MULTIPLE = {1, 2, 3, 4, 6, 8, 10, 15, 30, 50}
local COINS_WEIGHT = {44689, 30000, 20000, 5000, 200, 100, 5, 3, 2, 1}

local Three_Five_Reels = 1
local Four_Five_Reels = 2
-- 构造函数
function EgyptMiniMachine:ctor()
    BaseMiniFastMachine.ctor(self)
end

function EgyptMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent
    self.m_vecCollect = data.vecCollect
    --滚动节点缓存列表
    self.cacheNodeMap = {}
    --init
    self:initGame()
end

function EgyptMiniMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

    self.m_totalWeight = 0
    for i = 1, #COINS_WEIGHT, 1 do
        self.m_totalWeight = self.m_totalWeight + COINS_WEIGHT[i]
    end
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function EgyptMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Egypt"
end

function EgyptMiniMachine:getlevelConfigName()
    local levelConfigName = "LevelEgyptMiniConfig.lua"

    return levelConfigName
end

function EgyptMiniMachine:getMachineConfigName()
    local str = "Mini"

    return self.m_moduleName .. str .. "Config" .. ".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function EgyptMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if symbolType == self.SYMBOL_Blank then
        return "Egypt_FastLuck_blank"
    elseif symbolType == self.SYMBOL_COIN then
        return "Socre_Egypt_coins"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS1 then
        return "Socre_Egypt_bonus1"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS2 then
        return "Socre_Egypt_bonus2"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS3 then
        return "Socre_Egypt_bonus3"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS4 then
        return "Socre_Egypt_bonus4"
    elseif symbolType == self.SYMBOL_CLASSIC_BONUS5 then
        return "Socre_Egypt_bonus5"
    elseif symbolType == self.SYMBOL_2X then
        return "Egypt_FastLuck_2x"
    elseif symbolType == self.SYMBOL_4X then
        return "Egypt_FastLuck_4x"
    elseif symbolType == self.SYMBOL_5X then
        return "Egypt_FastLuck_5x"
    elseif symbolType == self.SYMBOL_6X then
        return "Egypt_FastLuck_6x"
    elseif symbolType == self.SYMBOL_8X then
        return "Egypt_FastLuck_8x"
    elseif symbolType == self.SYMBOL_10X then
        return "Egypt_FastLuck_10x"
    elseif symbolType == self.SYMBOL_FIRE then
        return "Socre_Egypt_rapid1"
    end
    return ccbName
end


---
-- 读取配置文件数据
--
function EgyptMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), self:getlevelConfigName())
    end
end

function EgyptMiniMachine:initMachineCSB( )
    self:createCsbNode("Egypt_FastLuckReel.csb")
    
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
end

--
---
--
function EgyptMiniMachine:initMachine()
    self.m_moduleName = "Egypt" -- self:getModuleName()

    BaseMiniFastMachine.initMachine(self)

    self:initMiniReelsUi()
    self:showIdle()
end

function EgyptMiniMachine:showIdle()
    self.m_fastLongRun = false
    self:runCsbAction("idle1",true)
end

function EgyptMiniMachine:initUI()  

end
--默认按钮监听回调
function EgyptMiniMachine:clickFunc(sender)
    -- local name = sender:getName()
    -- local tag = sender:getTag()
    -- if name == "click" then
    --     if self.m_parent then
    --         self.m_parent:changeBetToUnlock()
    --     end
    -- end
end

function EgyptMiniMachine:initMiniReelsUi()
    -- self.m_fastLucyLogo = util_createView("CodeEgyptSrc.EgyptMiniReelsLogoView")
    local logo, act = util_csbCreate("Egypt_FastLuckReelLogo.csb")
    self:findChild("logo"):addChild(logo)
    util_csbPlayForKey(act, "idle1", true)
    -- self:findChild("Panel_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    -- self:findChild("Egypt_right_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2)
    -- self:findChild("logo"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 3)
    -- self:findChild("Sprite_28"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 4)
end

function EgyptMiniMachine:initMachineData()
    self:BaseMania_initCollectDataList()

    self.m_spinResultName = self.m_moduleName .. "_Datas"

    

    self.m_stcValidSymbolMatrix = table_createTwoArr(self.m_iReelRowNum,self.m_iReelColumnNum,
    self.SYMBOL_Blank)

        -- 配置全局信息，供外部使用
        self.m_levelGetAnimNodeCallFun = function(symbolType,ccbName)
            return self:getAnimNodeFromPool(symbolType,ccbName)
        end
    self.m_levelPushAnimNodeCallFun = function(animNode,symbolType)
            self:pushAnimNodeToPool(animNode,symbolType)
        end

    self:checkHasBigSymbol()
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function EgyptMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniFastMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Blank, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_BONUS1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_BONUS2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_BONUS3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_BONUS4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_CLASSIC_BONUS5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_2X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_4X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_5X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_6X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_8X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_10X, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIRE, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_COIN, count = 2} 
    
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------


function EgyptMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function EgyptMiniMachine:checkNotifyUpdateWinCoin()
    -- 这里作为freespin下 连线时通知钱数更新的接口
    if self.m_parent.m_runSpinResultData.p_selfMakeData.fastCashWinCoins ~= nil
     and self.m_parent.m_runSpinResultData.p_winAmount == self.m_parent.m_runSpinResultData.p_selfMakeData.fastCashWinCoins then
        local isNotifyUpdateTop = true
        if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
            isNotifyUpdateTop = false
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_parent.m_runSpinResultData.p_winAmount, isNotifyUpdateTop})
    end
end

function EgyptMiniMachine:slotReelDown()
    BaseMiniFastMachine.slotReelDown(self) 

    if self.m_parent  then
        self.m_parent:fastReelsWinslotReelDown()
    end

    
end

function EgyptMiniMachine:stopLineAction()
    self.m_stopAllLine = true
    self:resetBonusParent()
    self:showIdle()
end

---
-- 每个reel条滚动到底
function EgyptMiniMachine:slotOneReelDown(reelCol)
    BaseMiniFastMachine.slotOneReelDown(self, reelCol)
    
    self.m_slotReelDown = true
    local targSp = self:getLineNode()

    if targSp and targSp.p_symbolType ~= self.SYMBOL_Blank then
        
    else
        self:showIdle()
    end

    if targSp and targSp.p_symbolType == self.SYMBOL_COIN then
        -- self:runCsbAction("win", false, function()
        --     if self.m_slotReelDown == true then
        --         self:runCsbAction("huoyanidle", true)
        --     end
        -- end)

        local soundPath =  "EgyptSounds/sound_Egypt_coin_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

        -- targSp:runAnim("buling",false,function( )
            self:changeBonusParent(targSp)
            local spine = targSp:getCcbProperty("Coin")
            util_spinePlay(spine, "buling")
            targSp:runAnim("buling", false, function()
                if self.m_stopAllLine ~= true and self.m_slotReelDown == true then
                    targSp:runAnim("actionframe", true)
                    util_spinePlay(spine, "actionframe", true)
                end
            end)
            
        -- end)
        self:showIdle()
    end

    if targSp and targSp.p_symbolType == self.SYMBOL_FIRE then
        if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.fastFire ~= nil then 
            targSp:runAnim("buling")

            local soundPath =  "EgyptSounds/sound_Egypt_6_reel_down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end

            if self.m_parent.m_totalRapidNum >= 5 then
                self:reelAnimation()
            else
                self:showIdle()
            end
        else
            self:showIdle()
        end
    end

    if targSp and targSp.p_symbolType >= self.SYMBOL_CLASSIC_BONUS1 and targSp.p_symbolType <= self.SYMBOL_CLASSIC_BONUS5 then
        if self.m_parent.m_triggerRespin == true then 
            self:reelAnimation()

            local soundPath =  "EgyptSounds/sound_Egypt_6_reel_down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end

            targSp:runAnim("buling")
            local index = targSp.p_symbolType - self.SYMBOL_CLASSIC_BONUS1 + 1
            self:updateBonusSymbol(targSp, index)
            local spine = targSp:getCcbProperty("Classic")
            util_spinePlay(spine, "buling")
        else
            self:showIdle()
        end
    end

    if targSp and targSp.p_symbolType >= self.SYMBOL_2X and targSp.p_symbolType <= self.SYMBOL_10X then
        if self.m_parent.m_runSpinResultData.p_winAmount > 0 and self.m_parent.m_runSpinResultData.p_winAmount ~= self.m_parent.m_runSpinResultData.p_selfMakeData.fireWinCoins then
        

            local soundPath =  "EgyptSounds/sound_Egypt_multip_down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end


            targSp:runAnim("buling")
            self:showIdle()
        else
            self:showIdle()
        end
    end
end

function EgyptMiniMachine:reelAnimation()
    self:runCsbAction("win", false, function()
        if self.m_stopAllLine ~= true and self.m_slotReelDown == true then
            self:runCsbAction("huoyanidle", true)
        else
            self:showIdle()
        end
    end)
end

function EgyptMiniMachine:rapidAnimation()
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.fastFire ~= nil then
        local rapidNode = self:getLineNode()
        if self.m_stopAllLine ~= true then
            self:changeBonusParent(rapidNode)
            rapidNode:runAnim("actionframe", true)
        end
    end
end

function EgyptMiniMachine:multipAnimation(func)
    local multipNode = self:getLineNode()
    self:changeBonusParent(multipNode)
    multipNode:runAnim("actionframe", false, function()
        self:resetBonusParent()
        func()
    end)
end

function EgyptMiniMachine:classicBonusAnimation(func)
    local classicNode = self:getLineNode()
    self:changeBonusParent(classicNode)
    
    classicNode:runAnim("actionframe", false, function()
        performWithDelay(self, function()
            self:resetBonusParent()
        end, 0.2)
        func()
    end)
    local col = classicNode.p_symbolType - self.SYMBOL_CLASSIC_BONUS1 + 1
    self:updateBonusSymbol(classicNode, col)
    local spine = classicNode:getCcbProperty("Classic")
    util_spinePlay(spine, "actionframe")
end

function EgyptMiniMachine:changeBonusParent(slotNode)
    if self.m_slotReelDown == false then
        return
    end

    local nodeParent = slotNode:getParent()

    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_parent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    release_print("changeBonusParent1,  "..slotNode.p_symbolType)
    slotNode:removeFromParent()
    slotNode:setScale(self.m_parent.m_machineRootScale)
    -- 切换图层

   -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
   self.m_animationNode = slotNode

   self.m_parent:addChild(slotNode,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
   release_print("changeBonusParent2,  "..slotNode.p_symbolType)
end

function EgyptMiniMachine:resetBonusParent()

    if self.m_animationNode == nil then
        return
    end
    local preParent = self.m_animationNode.p_preParent
    if preParent ~= nil then
        local pos = self.m_animationNode:getParent():convertToWorldSpace(cc.p(self.m_animationNode:getPosition()))
        pos = preParent:convertToNodeSpace(pos)
        release_print("resetBonusParent1,  "..self.m_animationNode.p_symbolType)
        self.m_animationNode:removeFromParent()
        self.m_animationNode.p_layerTag = self.m_animationNode.p_preLayerTag
        local nZOrder = self.m_animationNode.p_showOrder
        preParent:addChild(self.m_animationNode, nZOrder)
        release_print("resetBonusParent2,  "..self.m_animationNode.p_symbolType)
        self.m_animationNode:setScale(1)
        self.m_animationNode:setPosition(pos)
        self.m_animationNode:runIdleAnim()
        self.m_animationNode = nil
    end
end

function EgyptMiniMachine:collectBonus(iCol, isEffect)
    local classicNode = self:getLineNode()
    local endPos = self.m_vecCollect[iCol]:getParent():convertToWorldSpace(cc.p(self.m_vecCollect[iCol]:getPosition()))
    local newEndPos = self.m_slotEffectLayer:convertToNodeSpace(endPos)

    local startPos = classicNode:getParent():convertToWorldSpace(cc.p(classicNode:getPosition()))
    local newStartPos = self.m_slotEffectLayer:convertToNodeSpace(startPos)
    local particle = cc.ParticleSystemQuad:create("partical/bonus_tuowei.plist")
    particle:setAutoRemoveOnFinish(true)
    self.m_slotEffectLayer:addChild(particle,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    particle:setPosition(newStartPos)
    local moveTo = cc.MoveTo:create(0.4, newEndPos)
    local callback = cc.CallFunc:create(function()
        particle:stopSystem()
        if isEffect == true then
            self.m_parent.m_collectBar:addEffect(iCol, self.m_parent.m_runSpinResultData.p_selfMakeData.classCounts[iCol])
        end
    end)
    particle:runAction(cc.Sequence:create(moveTo, callback))
    
    
end

function EgyptMiniMachine:playWinEffect()
    if self.m_slotReelDown ~= true then
        self:changeReelRunSpeed()
        self:runCsbAction("run", true)
    end
end

function EgyptMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end


function EgyptMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_parent:setNormalAllRunDown(1)
end

function EgyptMiniMachine:addObservers()
    BaseMiniFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            local flag = params
            if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
                flag = false
            end

            -- self:findChild("click"):setVisible(flag)
        end,
        "BET_ENABLE"
    )
end

function EgyptMiniMachine:quicklyStopReel(colIndex)
    if self.m_longRunFlag == true then
        return
    end
    if self:isVisible() and self.m_slotReelDown ~= true then 
        self:showIdle()
        BaseMiniFastMachine.quicklyStopReel(self, colIndex)
        -- if self.m_parent:getBetLevel() ~= 0 then
        --     BaseMiniFastMachine.quicklyStopReel(self)
        -- end
    end
end

function EgyptMiniMachine:onExit()
    BaseMiniFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end


function EgyptMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
end

function EgyptMiniMachine:beginMiniReel()
    self:resetBonusParent()
    BaseMiniFastMachine.beginReel(self)
    self.m_slotReelDown = false
    self.m_stopAllLine = false
    self.m_longRunFlag = false
    self:setWaitChangeReelTime(0)
end

function EgyptMiniMachine:setLongRunFlag(flag)
    self.m_longRunFlag = true
end
-- 消息返回更新数据
function EgyptMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    if self.m_longRunFlag == true then
        self:setWaitChangeReelTime(2)
    end
    self:updateNetWorkData()
end

function EgyptMiniMachine:dealSmallReelsSpinStates( )
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    -- do nothing
end


-- 轮盘停止回调(自己实现)
function EgyptMiniMachine:setDownCallFunc(func)
    self.m_reelDownCallback = func
end

function EgyptMiniMachine:playEffectNotifyNextSpinCall()
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end

---
--设置bonus scatter 层级
function EgyptMiniMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order
end

function EgyptMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function EgyptMiniMachine:checkGameResumeCallFun( )
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


function EgyptMiniMachine:showEffect_LineFrame(effectData)

    self:checkNotifyUpdateWinCoin()
    
    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
     or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
        performWithDelay(self, function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, 0.5)
    else
        effectData.p_isPlay = true
        self:playGameEffect()
    end

    return true

end

function EgyptMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function EgyptMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function EgyptMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

-- -------clasicc 轮盘处理
--绘制多个裁切区域
function EgyptMiniMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)
        -- reelSize.height = reelSize.height

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        else
            clipNode =
                cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() -- cc.LayerColor:create(cc.c4f(r,g,b,200))  --

        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)

        -- slotParentNode:setVisible(false)

        local parentData = SlotParentData:new()

        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)
    end
end

---
-- 获取最高的那一列
--
function EgyptMiniMachine:updateReelInfoWithMaxColumn()
    local fReelMaxHeight = 0

    local iColNum = self.m_iReelColumnNum
    --    local maxHeightColumnIndex = iColNum
    for iCol = 1, iColNum, 1 do
        -- local colNodeName = "reel_unit"..(iCol - 1)
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))

        local reelSize = reelNode:getContentSize()
        local unitPos = cc.p(reelNode:getPositionX(), reelNode:getPositionY())
        unitPos = reelNode:getParent():convertToWorldSpace(unitPos)

        local pos = self.m_slotEffectLayer:convertToNodeSpace(unitPos)

        self.m_reelColDatas[iCol].p_slotColumnPosX = pos.x
        self.m_reelColDatas[iCol].p_slotColumnPosY = pos.y
        self.m_reelColDatas[iCol].p_slotColumnWidth = reelSize.width
        self.m_reelColDatas[iCol].p_slotColumnHeight = reelSize.height

        if reelSize.height > fReelMaxHeight then
            fReelMaxHeight = reelSize.height
            self.m_fReelWidth = reelSize.width
        end
    end

    self.m_fReelHeigth = fReelMaxHeight
    self.m_SlotNodeW = self.m_fReelWidth
    self.m_SlotNodeH = self.m_fReelHeigth / self.m_iReelRowNum

    -- 计算每列的行数
    local isSpecialReel = false
    for i = 1, #self.m_reelColDatas do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridH = self.m_SlotNodeH
        columnData.p_showGridCount = self.m_iReelRowNum -- 对对应列进行四舍五入
        if columnData.p_showGridCount ~= self.m_iReelRowNum then
            isSpecialReel = true
        end
    end
    if isSpecialReel == true then
        self.m_isSpecialReel = isSpecialReel
    end
end

function EgyptMiniMachine:checkRestSlotNodePos()
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

        local moveDis = nil
        for nodeIndex = 1, #childs do
            local childNode = childs[nodeIndex]
            if childNode.m_isLastSymbol == true then
                local childPosY = childNode:getPositionY()
                if maxLastNodePosY == nil then
                    maxLastNodePosY = childPosY
                elseif maxLastNodePosY < childPosY then
                    maxLastNodePosY = childPosY
                end

                if minLastNodePosY == nil then
                    minLastNodePosY = childPosY
                elseif minLastNodePosY > childPosY then
                    minLastNodePosY = childPosY
                end
                local columnData = self.m_reelColDatas[childNode.p_cloumnIndex]
                local nodeH = columnData.p_showGridH

                childNode:setPositionY((nodeH * childNode.p_rowIndex - nodeH * 0.5))

                if moveDis == nil then
                    moveDis = childPosY - childNode:getPositionY()
                end
            else
                --do nothing
            end

            childNode.m_isLastSymbol = false
        end

        --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
        local childs = slotParent:getChildren()
        for i = 1, #childs do
            local childNode = childs[i]
            if childNode.m_isLastSymbol == true then
                if childNode:getTag() < SYMBOL_NODE_TAG + BIG_SYMBOL_NODE_DIFF_TAG then
                    --将该节点放在 .m_clipParent
                    release_print("checkRestSlotNodePos1,  "..childNode.p_symbolType)
                    childNode:removeFromParent()
                    local posWorld = slotParent:convertToWorldSpace(cc.p(childNode:getPositionX(), childNode:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    childNode:setPosition(cc.p(pos.x, pos.y))
                    self.m_clipParent:addChild(childNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
                    release_print("checkRestSlotNodePos2,  "..childNode.p_symbolType)
                end
            end
        end

        -- printInfo(" xcyy %d  %d  ", parentData.cloumnIndex,parentData.symbolType)
        parentData:reset()
    end
end

---
-- 根据类型获取对应节点
--
function EgyptMiniMachine:getSlotNodeBySymbolType(symbolType)
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
    reelNode.p_levelPushAnimNodeCallFun = self.m_levelPushAnimNodeCallFun
    reelNode.p_levelGetAnimNodeCallFun = self.m_levelGetAnimNodeCallFun
    reelNode.p_levelConfigData = self.m_configData

    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode

end

--小块
function EgyptMiniMachine:getBaseReelGridNode()
    return "CodeEgyptSrc.EgyptMiniSlotsNode"
end

function EgyptMiniMachine:updateBonusSymbol(node, index)
    node:getCcbProperty("node_win"):setVisible(false)
    local spineNode = node:getCcbProperty("Spine")
    if spineNode:getChildByName("Classic") == nil then
        local animationNode = util_spineCreate("Socre_Egypt_bonus"..index, true, true)--util_spineCreateDifferentPath("Socre_Egypt_bonus"..index, "Socre_Egypt_bonus", true, true)
        animationNode:setName("Classic")
        spineNode:addChild(animationNode)
    end
    local spine = node:getCcbProperty("Classic")
    spine:resetAnimation()
end

function EgyptMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniFastMachine.setSlotCacheNodeWithPosAndType(self, node, symbolType, row, col, isLastSymbol)

    if symbolType == self.SYMBOL_CLASSIC_BONUS1
     or symbolType == self.SYMBOL_CLASSIC_BONUS2
     or symbolType == self.SYMBOL_CLASSIC_BONUS3
     or symbolType == self.SYMBOL_CLASSIC_BONUS4
     or symbolType == self.SYMBOL_CLASSIC_BONUS5 then
        -- node:getCcbProperty("node_win"):setVisible(false)
        -- local spineNode = node:getCcbProperty("Spine")
        -- if spineNode:getChildByName("Classic") == nil then
        --     local index = symbolType - self.SYMBOL_CLASSIC_BONUS1 + 1
        --     local animationNode = util_spineCreate("Socre_Egypt_bonus"..index, true, true)
        --     animationNode:setName("Classic")
        --     spineNode:addChild(animationNode)
        -- end
    elseif symbolType == self.SYMBOL_COIN then
        local spineNode = node:getCcbProperty("Spine")
        if spineNode:getChildByName("Coin") == nil then
            local animationNode = util_spineCreate("Socre_Egypt_coins", true, true)
            animationNode:setName("Coin")
            spineNode:addChild(animationNode)
        end
        local spine = node:getCcbProperty("Coin")
        util_spinePlay(spine, "idleframe")
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end
end

function EgyptMiniMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local randomScore = function()
        local rand = math.random(1, self.m_totalWeight)
        local index = nil
        local flagWeight = 0
        for i = 1, #COINS_WEIGHT, 1 do
            flagWeight = flagWeight + COINS_WEIGHT[i]
            if rand <= flagWeight then
                index = i
                break
            end
        end
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local score = COINS_MULTIPLE[index] * lineBet
        return score -- 获取随机分数（本地配置）
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        local score = self.m_parent.m_runSpinResultData.p_selfMakeData.fastCashWinCoins --获取分数（网络数据）
        if score == nil then
            score =  randomScore()
        end
        score = util_formatCoins(score, 3,nil,nil)
        local lab = symbolNode:getCcbProperty("m_lb_coin")
        if lab ~= nil then
            lab:setString(score)
        end
    elseif symbolNode.p_symbolType ~= nil then
        local score =  randomScore()
        if score ~= nil  then
            score = util_formatCoins(score, 3,nil,nil)
            local lab = symbolNode:getCcbProperty("m_lb_coin")
            if lab ~= nil then
                lab:setString(score)
            end
            -- symbolNode:runAnim("idleframe",true)
        end
    end
end

function EgyptMiniMachine:initReelsNodesByNetData(reels)
    
    for colIndex=self.m_iReelColumnNum,  1, -1 do

        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum  -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false 

        while rowIndex >= 1 do

            local rowDatas = reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            
            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType)
            
            if parentData.slotParent:getChildByTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex) ~= nil then
                local child = parentData.slotParent:getChildByTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                release_print("initReelsNodesByNetData,  "..child.p_symbolType)
                child:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(child.p_symbolType, child)
            end
            parentData.slotParent:addChild(node,
                    REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
            
            node.p_symbolType = symbolType
--            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (changeRowIndex - 1) * columnData.p_showGridH + halfNodeH )
            node:runIdleAnim()      
            rowIndex = rowIndex - stepCount
        end  -- end while

    end

end

function EgyptMiniMachine:getLineNode()
    return self:getFixSymbol(1, 2, SYMBOL_NODE_TAG)
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function EgyptMiniMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_resTopTypes
    local symbolType = self.m_runSpinResultData.p_prevReel[colIndex]
    
    self:getReelSymbolType(parentData)

    return symbolType

end

function EgyptMiniMachine:changeReelRunSpeed()
   
    local parentData = self.m_slotParents[1]
    local slotParent = parentData.slotParent
    parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed

end

return EgyptMiniMachine
