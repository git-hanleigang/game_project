---
-- island li
-- 2019年1月26日
-- CodeGameScreenQuickSpinMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenQuickSpinMachine = class("CodeGameScreenQuickSpinMachine", BaseSlotoManiaMachine)

CodeGameScreenQuickSpinMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenQuickSpinMachine.SYMBOL_SPECIAL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 自定义的小块类型
CodeGameScreenQuickSpinMachine.SYMBOL_SUPER_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 -- 自定义的小块类型

CodeGameScreenQuickSpinMachine.BIG_WHEEL_TRRIER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

CodeGameScreenQuickSpinMachine.m_bIsBgChange = nil
CodeGameScreenQuickSpinMachine.m_rotateWheelOverCall = nil
CodeGameScreenQuickSpinMachine.m_riseCoinCall = nil
CodeGameScreenQuickSpinMachine.m_vecExpressSound = {false, false, false, false, false}

local DESIGN_HEIGHT = 1450
local FIT_HEIGHT_MAX = 1233
local FIT_HEIGHT_MIN = 1136

-- 构造函数
function CodeGameScreenQuickSpinMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function CodeGameScreenQuickSpinMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
    self.m_scatterBulingSoundArry = {}
    self.m_scatterBulingSoundArry["auto"] = "QuickSpinSounds/sound_QuickSpin_scatter_down.mp3"
end

-- function CodeGameScreenQuickSpinMachine:enterLevel()
--     -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
--     local isTriggerEffect,isPlayGameEffect = self:checkInitSpinWithEnterLevel()

--     local hasFeature = self:checkHasFeature()

--     if self.m_initSpinData == nil then
--         self:initNoneFeature()
--     else
--         self:initHasFeature()
--     end
    
--     if isPlayGameEffect or #self.m_gameEffects > 0 then
--         self:sortGameEffects( )
--         self:playGameEffect()
--     end
-- end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenQuickSpinMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "QuickSpin"
end
function CodeGameScreenQuickSpinMachine:getNetWorkModuleName()
    return "QuickSpinV2"
end

function CodeGameScreenQuickSpinMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainPosY = (uiBH - uiH - 30) / 2
    local mainHeight = display.height - uiH - uiBH
    local designHeight = DESIGN_HEIGHT - uiH - uiBH
    local mainScale = 1

    if display.height < FIT_HEIGHT_MAX then
        mainScale = mainHeight / designHeight
        -- mainScale = mainScale
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        local distance = (FIT_HEIGHT_MAX - display.height) * 0.035
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + distance)
    elseif display.height >= FIT_HEIGHT_MAX and display.height <= DESIGN_HEIGHT then
        mainScale = 0.85
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        local distance = mainHeight * (1 - mainScale) * 0.5 - (DESIGN_HEIGHT - display.height) * 0.5
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - distance)
    else
        mainScale = 0.85
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        local distance = designHeight * (1 - mainScale) * 0.5
        if  display.height <= 1500 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - distance)
        end
    end

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
end

function CodeGameScreenQuickSpinMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式

    self.m_QuickSpinWheel = util_createView("CodeQuickSpinSrc.QuickSpinWheelView")
    self:findChild("wheel"):addChild(self.m_QuickSpinWheel)

    self.m_weelStart = util_createView("CodeQuickSpinSrc.QuickSpinWheelStart")
    self:findChild("wheel_start"):addChild(self.m_weelStart)

    self.m_wheelWords = util_createView("CodeQuickSpinSrc.QuickSpinWheelWords")
    self:findChild("wheel_words"):addChild(self.m_wheelWords)

    self.m_respinStart = util_createView("CodeQuickSpinSrc.QuickSpinRespinStart")
    self:findChild("wheel_words"):addChild(self.m_respinStart)

    self.m_jackPot = util_createView("CodeQuickSpinSrc.QuickSpinJackpot")
    self:findChild("Jackpot"):addChild(self.m_jackPot)

    self.m_wheelPoint = util_createView("CodeQuickSpinSrc.QuickSpinWheelPoint")
    self:findChild("jiantou"):addChild(self.m_wheelPoint)

    if display.height > DESIGN_HEIGHT then

        local posY = (display.height - DESIGN_HEIGHT) * 0.5
        if display.height > 1500 then
            posY = (display.height - DESIGN_HEIGHT * self.m_machineRootScale) * 0.5
        end
        local nodeJackpot = self:findChild("Jackpot")
        nodeJackpot:setPositionY(nodeJackpot:getPositionY() - posY)
        local nodeLunpan = self:findChild("QuickSpin_reel")
        nodeLunpan:setPositionY(nodeLunpan:getPositionY() - posY )
        local nodeWords = self:findChild("wheel_words")
        nodeWords:setPositionY(nodeWords:getPositionY() - posY )
        local nodeEffect = self:findChild("effect")
        nodeEffect:setPositionY(nodeEffect:getPositionY() - posY )
        local nodeWheel = self:findChild("wheel")
        nodeWheel:setPositionY(nodeWheel:getPositionY() - posY )
        local nodePoint = self:findChild("jiantou")
        nodePoint:setPositionY(nodePoint:getPositionY()  - posY)

        if display.height > 1500 then
            local scale = (display.height - 1500) * 0.001
            -- local nodeWheel = self:findChild("wheel")
            -- nodeWheel:setScale(1 + scale)

            -- local nodePoint = self:findChild("jiantou")
            -- nodePoint:setScale(1 + scale)
            -- nodePoint:setPositionY(nodePoint:getPositionY() + (display.height - 1500) * 0.5)
            local nodeBottom = self:findChild("bottom")
            nodeBottom:setScale(1 + scale)
            local distance = DESIGN_HEIGHT * scale * 0.5
            nodeBottom:setPositionY(nodeBottom:getPositionY() + distance)

            nodePoint:setScale(1 + scale * 0.5)
            nodeWheel:setScale(1 + scale * 0.5)
            nodePoint:setPositionY(nodePoint:getPositionY() + (display.height - 1500))
            nodeWheel:setPositionY(nodeWheel:getPositionY() + (display.height - 1500))
        end

    end
    -- -- 创建大转盘
    -- -- 轮盘网络数据
    -- local data = self.m_runSpinResultData.p_selfMakeData
    -- local bonusWheel = util_createView("DwarfFairySrc.DwarfFairyWheelView", data)
    -- local callback = function ()

    --         bonusWheel:removeFromParent(true)
    -- end
    -- bonusWheel:setPosition(display.width * 0.5, display.height * 0.5)
    -- bonusWheel:initCallBack(callback)
    -- self:addChild(bonusWheel, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM)

    self:runCsbAction("animation0", true)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 1
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 2
        elseif winRate > 3 then
            soundIndex = 3
            soundTime = 4
        end
        local soundName = "QuickSpinSounds/sound_QuickSpin_last_win_"..soundIndex..".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenQuickSpinMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )

        gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end

        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenQuickSpinMachine:requestSpinResult()
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

function CodeGameScreenQuickSpinMachine:updateBetLevel()
    -- if not self.m_specialBets then
    --     --只有第一次获取服务器数据
    --     self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    -- end
    -- if self.m_specialBets and self.m_specialBets[1] then
    --     self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    -- end
    -- local betCoin = globalData.slotRunData:getCurTotalBet()
    -- if betCoin >= self.m_BetChooseGear then
    --     self.m_iBetLevel = 1
    -- else
    --     self.m_iBetLevel = 0
    -- end
    self.m_iBetLevel = 1
end

function CodeGameScreenQuickSpinMachine:unlockHigherBet()
    if self.m_bProduceSlots_InFreeSpin == true or
    (self:getCurrSpinMode() == NORMAL_SPIN_MODE and
    self:getGameSpinStage() ~= IDLE ) or
    (self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true
     and self:getGameSpinStage() ~= IDLE) or
     self.m_isRunningEffect == true or
    self:getCurrSpinMode() == AUTO_SPIN_MODE
    then
        return
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= self.m_BetChooseGear then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear then
            globalData.slotRunData.iLastBetIdx = betData.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenQuickSpinMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:updateBetLevel()
    if self.m_iBetLevel == 0 then
        self.m_QuickSpinWheel:showLock()
    end
    -- performWithDelay(self, function()
        self.m_QuickSpinWheel:showMultipAction(self.m_iBetLevel)
    -- end, 0.3)
end

function CodeGameScreenQuickSpinMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

--     gLobalNoticManager:addObserver(self,function(self,params)
--         local iBetLevel = self.m_iBetLevel
--         self:updateBetLevel()
--         if iBetLevel ~= self.m_iBetLevel then
--             if self.m_iBetLevel == 1 then
--                 self.m_QuickSpinWheel:hideLock()
--                 gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_lock.mp3")
--             else
--                 self.m_QuickSpinWheel:showLock()
--                 gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_unlock.mp3")
--             end
--         end
--    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
end

function CodeGameScreenQuickSpinMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenQuickSpinMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_SPECIAL_BONUS  then
        return "Socre_QuickSpin_Bonus"
    elseif symbolType == self.SYMBOL_SUPER_BONUS  then
        return "Socre_QuickSpin_SupperBonus"
    end

    return nil
end

function CodeGameScreenQuickSpinMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if iCol ~= nil and symbolNode.m_isLastSymbol == true then
        symbolNode.p_reelDownRunAnima = "buling"
        if self.m_vecExpressSound[iCol] == false  then
            symbolNode.p_reelDownRunAnimaSound = "QuickSpinSounds/sound_QuickSpin_bonus.mp3"
            self.m_vecExpressSound[iCol] = true
        end
    end
end


function CodeGameScreenQuickSpinMachine:getSlotNodeWithPosAndType(symbolType, row, col,isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col,isLastSymbol)

    if symbolType == self.SYMBOL_SPECIAL_BONUS then
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
    elseif symbolType == self.SYMBOL_SUPER_BONUS then
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{reelNode})
        self:runAction(callFun)
    end

    return reelNode
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenQuickSpinMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SPECIAL_BONUS, count =  4}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SUPER_BONUS, count =  3}


    return loadNode
end

---
--添加金边
function CodeGameScreenQuickSpinMachine:createReelEffect(col)

end

function CodeGameScreenQuickSpinMachine:creatReelRunAnimation(col)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenQuickSpinMachine:MachineRule_initGame(  )


end

--
--单列滚动停止回调
--
function CodeGameScreenQuickSpinMachine:slotOneReelDown(reelCol)
    BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)
    -- local isplay= true
    -- if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
    --     local isHaveFixSymbol = false
    --     for k = 1, self.m_iReelRowNum do
    --         if self:isFixSymbol(self.m_stcValidSymbolMatrix[k][reelCol]) then
    --             isHaveFixSymbol = true
    --             break
    --         end
    --     end
    --     if isHaveFixSymbol == true and isplay then
    --         isplay = false
    --         -- respinbonus落地音效
    --         -- gLobalSoundManager:playSound("QuickSpinSounds/music_QuickSpin_fall_" .. reelCol ..".mp3")
    --     end
    -- end
end

function CodeGameScreenQuickSpinMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_SPECIAL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_SUPER_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + 50

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

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenQuickSpinMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    if self.m_bIsBgChange ~= true then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal_freespin")
    else
        self.m_bIsBgChange = false
    end
    self.m_jackPot:changeWords("freespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenQuickSpinMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin_normal")
    self.m_jackPot:changeWords("normal")
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenQuickSpinMachine:showFreeSpinView(effectData)
    gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_custom_enter_fs.mp3")
    -- 取消掉赢钱线的显示
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
                end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()
    end, 0.5)

end

function CodeGameScreenQuickSpinMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_over_fs.mp3")

   local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    local view = self:showFreeSpinOver( strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.01,sy=1.01},560)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenQuickSpinMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    self.m_winSoundsId = nil

    self:resetMaskLayerNodes()
    if self.m_rotateWheelOverCall ~= nil then
        self.m_rotateWheelOverCall()
        self.m_rotateWheelOverCall = nil
    end
    self.m_vecExpressSound = {false, false, false, false, false}
    return false -- 用作延时点击spin调用
end
function CodeGameScreenQuickSpinMachine:slotReelDown()
    CodeGameScreenQuickSpinMachine.super.slotReelDown(self) 
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end
function CodeGameScreenQuickSpinMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenQuickSpinMachine.super.playEffectNotifyNextSpinCall(self)
end
-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenQuickSpinMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenQuickSpinMachine:MachineRule_afterNetWorkLineLogicCalculate()


    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

end




--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenQuickSpinMachine:addSelfEffect()

    if self.m_runSpinResultData.p_selfMakeData.wheel ~= nil then

        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BIG_WHEEL_TRRIER_EFFECT -- 动画类型
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenQuickSpinMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.BIG_WHEEL_TRRIER_EFFECT then

        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:removeGameEffectType(GameEffect.EFFECT_LINE_FRAME)
        self:removeGameEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
        self.m_QuickSpinWheel:setResultIndex(20 - self.m_runSpinResultData.p_selfMakeData.wheel.position)
        self.m_QuickSpinWheel:setMultip(self.m_runSpinResultData.p_selfMakeData.wheel.multiple)
        self.m_QuickSpinWheel:initCallBack(function()
            self:rotateWheelOver(effectData)
        end)

        self:showBonusAnimation()
    end


	return true
end

function CodeGameScreenQuickSpinMachine:showBonusAnimation()

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    if #self.m_reelResultLines == 0 then
        for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
            local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
            local checkEnd = false
            for posIndex = 1 , #lineData.p_iconPos do
                local pos = lineData.p_iconPos[posIndex]

                local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                local colIndex = pos % self.m_iReelColumnNum + 1

                local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                if symbolType == self.SYMBOL_SPECIAL_BONUS or symbolType == self.SYMBOL_SUPER_BONUS then
                    checkEnd = true
                    local lineInfo = self:getReelLineInfo()

                    for addPosIndex = 1 , #lineData.p_iconPos do
                        local posData = lineData.p_iconPos[addPosIndex]
                        local rowColData = self:getRowAndColByPos(posData)
                        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
                    end
                    lineInfo.enumSymbolType = self.SYMBOL_SPECIAL_BONUS
                    lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                    lineInfo.iLineSymbolNum = #lineInfo.vecValidMatrixSymPos
                    self.m_reelResultLines = {}
                    self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                    break
                end
            end
            if checkEnd == true then
                break
            end

        end
    end

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolType == self.SYMBOL_SPECIAL_BONUS or symbolType == self.SYMBOL_SUPER_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end
    local innerFun = function()
        gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_wheel_start.mp3")
        self.m_weelStart:show(function()
            self.m_QuickSpinWheel:hideMask()
            gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_words_point_show.mp3")
            self.m_wheelWords:show()
            self.m_wheelPoint:show()
            performWithDelay(self, function()
                self.m_QuickSpinWheel:clickFunc(self.m_runSpinResultData.p_selfMakeData.wheel.multiple)
            end, 0.8)
        end)
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self.m_bIsBgChange = true
            performWithDelay(self, function()
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal_freespin")
            end, 0.5)
        end
        performWithDelay(self, function()
            self.m_jackPot:changeWords("wheel"..self.m_iBetLevel)
        end, 0.5)
    end
    -- 停掉背景音乐
    self:clearCurMusicBg()
    if bonusLineValue then
        gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_trriger_bonus.mp3", false)
        performWithDelay(self,function (  )
            self.m_currentMusicBgName = "QuickSpinSounds/music_QuickSpin_bonus_bg.mp3"
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end,4)

        self:showBonusAndScatterLineTip(bonusLineValue,function()
            innerFun()
        end)
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
    else
        innerFun()
    end

    -- 播放提示时播放音效
    -- gLobalSoundManager:playSound("QuickSpinSounds/music_QuickSpin_over_fs.mp3")
end

-- -- 处理特殊关卡 遮罩层级
-- function CodeGameScreenQuickSpinMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
--     local maxzorder = 0
--     local zorder = 0
--     for i=1,self.m_iReelRowNum do
--         local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
--         local zorder = self:getBounsScatterDataZorder(symbolType)
--         if zorder >  maxzorder then
--             maxzorder = zorder
--         end
--     end

--     slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
-- end

function CodeGameScreenQuickSpinMachine:setSlotNodeEffectParent(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.p_preParent = nodeParent
    slotNode.p_showOrder = slotNode:getLocalZOrder()
    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层

    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    local zorder = self:getBounsScatterDataZorder(slotNode.p_symbolType)

    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + zorder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runLineAnim()
    end
    return slotNode
end



-- function CodeGameScreenQuickSpinMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
--     -- 延迟回调播放 界面提示 bonus  freespin
--     scheduler.performWithDelayGlobal(function()
--         self:resetMaskLayerNodes()
--         callFun()
--     end,util_max(2,animTime),self:getModuleName())
-- end

function CodeGameScreenQuickSpinMachine:rotateWheelOver(effectData)
    local coins = self.m_runSpinResultData.p_selfMakeData.wheel.winCoins

    -- local effect, act = util_csbCreate("Socre_QuickSpin_Winkuang.csb")
    -- local winBoxNode = self.m_bottomUI:findChild("xuanfeng")
    -- winBoxNode:getParent():addChild(effect)

    -- effect:setPosition(winBoxNode:getPositionX(), winBoxNode:getPositionY())
    -- util_csbPlayForKey(act, "animation0", true)
    -- effect:setVisible(false)

    -- self:playCoinWinEffectUI()

    self.m_rotateWheelOverCall = function()

        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bIsBgChange = false
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin_normal")
        end

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self.m_jackPot:changeWords("normal")
        else
            self.m_jackPot:changeWords("freespin")
        end
        self:resetMusicBg()
        self.m_wheelPoint:hide()
        self.m_QuickSpinWheel:resetWheel()

        -- effect:removeFromParent(true)
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local winRate = self.m_serverWinCoins / totalBet
    local showTime = 2
    local winSound = "QuickSpinSounds/sound_QuickSpin_wheel_coin_2.mp3"
    if winRate <= 1 then
        showTime = 1
        winSound = "QuickSpinSounds/sound_QuickSpin_wheel_coin_1.mp3"
    elseif winRate > 1 and winRate <= 3 then
        showTime = 1.5
    elseif winRate > 3 and winRate <= 6 then
        showTime = 2.5
    elseif winRate > 6 then
        showTime = 4
        winSound = "QuickSpinSounds/sound_QuickSpin_wheel_coin.mp3"
    end

    self.m_bottomUI.m_normalWinLabel:setScale(1.5)
    gLobalSoundManager:playSound(winSound)

    performWithDelay(self, function()
        self.m_bottomUI.m_normalWinLabel:runAction(cc.ScaleTo:create(0.2, 1))
    end, showTime)

    if self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
      or self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) then
        showTime = showTime + 0.8
    end

    performWithDelay(self, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end, showTime)


    self.m_wheelWords:hide()
    gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_words_point_hide.mp3")
    if self.m_bProduceSlots_InFreeSpin == false then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins, true, true})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins, false, true})
    end

    -- 弹框
    -- local view = util_createView("Levels.BaseDialog")
    -- view:initViewData(self, "WheelFeatureOver", clickCallback)
    -- local ownerlist={}
    -- ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    -- view:updateOwnerVar(ownerlist)

    -- local labCoin = view:findChild("m_lb_coins")
    -- view:updateLabelSize({label = labCoin,sx = 1.01, sy = 1.01}, 560)
    -- gLobalViewManager:showUI(view)

    -- performWithDelay(self, function()

    -- end, 0.5)
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenQuickSpinMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

end

-- 继承底层respinView
function CodeGameScreenQuickSpinMachine:getRespinView()
    return "CodeQuickSpinSrc.QuickSpinRespinView"
end
-- 继承底层respinNode
function CodeGameScreenQuickSpinMachine:getRespinNode()
    return "CodeQuickSpinSrc.QuickSpinRespinNode"
end

--结束移除小块调用结算特效
function CodeGameScreenQuickSpinMachine:reSpinEndAction()
    -- self:clearCurMusicBg()
    self:respinOver()
end

function CodeGameScreenQuickSpinMachine:respinOver()
    self:setReelSlotsNodeVisible(true)
    self.m_chipList = self.m_respinView:getAllCleaningNode()
    local nextBonus = false
    if #self.m_chipList >= 6 then
        nextBonus = true
    end
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    self:removeRespinNode()

    self:addSelfEffect()

    self:triggerReSpinOverCallFun(0,nextBonus)
    -- self:resetMusicBg()
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenQuickSpinMachine:getRespinRandomTypes( )
    local symbolList = { TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        self.SYMBOL_SPECIAL_BONUS,
        self.SYMBOL_SUPER_BONUS
    }

    -- symbolList = nil -- 填写好后这行代码可以删除，只是为了报错提示修改

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenQuickSpinMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_SPECIAL_BONUS, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_SUPER_BONUS, runEndAnimaName = "", bRandom = false},
    }

    -- symbolList = nil -- 填写好后这行代码可以删除，只是为了报错提示修改

    return symbolList
end

function CodeGameScreenQuickSpinMachine:showEffect_Respin(effectData)

    -- 停掉背景音乐
    -- self:clearCurMusicBg()
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "respin")
    end
    local removeMaskAndLine = function()
        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        self:resetMaskLayerNodes()

        -- 处理特殊信号
        local childs = self.m_lineSlotNodes
        for i = 1, #childs do
            -- if childs[i].p_layerTag ~= nil and childs[i].p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE then
            --将该节点放在 .m_clipParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(childs[i]:getPositionX(),childs[i]:getPositionY()))
            local pos = self.m_slotParents[childs[i].p_cloumnIndex].slotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
            childs[i]:removeFromParent()
            childs[i]:setPosition(cc.p(pos.x, pos.y))
            self.m_slotParents[childs[i].p_cloumnIndex].slotParent:addChild(childs[i])
            -- end
        end
    end

    if  self:getLastWinCoin() > 0 then  -- 这里什么意思？？ 2018-04-27 18:25:13  问佳宝

        scheduler.performWithDelayGlobal(function()
            removeMaskAndLine()
            self:showRespinView(effectData)
        end,1,self:getModuleName())

    else
        self:showRespinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_ReSpin,self.m_iOnceSpinLastWin)
    return true

end
function CodeGameScreenQuickSpinMachine:showRespinView()

          --先播放动画 再进入respin
        -- self:resetMusicBg()


        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )

        --可随机的特殊信号
        local endTypes = self:getRespinLockTypes()

        --构造盘面数据
        self:triggerReSpinCallFun(endTypes, randomTypes)


end

--ReSpin开始改变UI状态
function CodeGameScreenQuickSpinMachine:changeReSpinStartUI(respinCount)

end

--ReSpin刷新数量
function CodeGameScreenQuickSpinMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)

end

--ReSpin结算改变UI状态
function CodeGameScreenQuickSpinMachine:changeReSpinOverUI()

end

function CodeGameScreenQuickSpinMachine:triggerReSpinOverCallFun(score,nextBonus)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self.m_specialReels = false
    self.m_preReSpinStoredIcons = nil

    if self.m_bProduceSlots_InFreeSpin then
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self:getLastWinCoin(),false,false})
    else
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,false,false})
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    performWithDelay(self,function()

        local coins = nil
        if self.m_bProduceSlots_InFreeSpin then
            coins = self:getLastWinCoin() or 0
        else
            coins = self.m_serverWinCoins or 0
        end
        if self.postReSpinOverTriggerBigWIn then
            self:postReSpinOverTriggerBigWIn( coins)
        end
        
        if not nextBonus then
            self.m_jackPot:playScaleAction("normal")
            -- self.m_jackPot:changeWords("normal")
        else
            self:sortGameEffects( )
        end
        self:playGameEffect()
    end,0.1)
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    -- self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()

    if
        self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or
            self.m_bProduceSlots_InFreeSpin
     then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

-- --重写组织respinData信息
function CodeGameScreenQuickSpinMachine:getRespinSpinData()
    local storedInfo = {}
    return storedInfo
end
function CodeGameScreenQuickSpinMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    local name = self.m_clipParent:getName()
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)
end


function CodeGameScreenQuickSpinMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)--128 116  128  348

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
            performWithDelay(self,function(  )
                gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_words_point_show.mp3")
                self.m_respinStart:show(function()
                    self.m_jackPot:playScaleAction("startRespin")
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    self:runNextReSpinReel()
                end)
            end,1.5)
        end
    )
    self.m_respinView:changeClipRowNode(3,cc.p(0,-1))
    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenQuickSpinMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)

            local addScale = 0

            if display.height > 1500 then
                addScale = (display.height - 1500) * 0.001

            end

            pos.x = pos.x + reelWidth / 2 * (self.m_machineRootScale + addScale)

            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH

            pos.y = pos.y + (iRow - 0.5) * slotNodeH * (self.m_machineRootScale + addScale)

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

return CodeGameScreenQuickSpinMachine






