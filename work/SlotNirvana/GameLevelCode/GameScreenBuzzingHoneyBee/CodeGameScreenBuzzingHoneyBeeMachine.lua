

local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenBuzzingHoneyBeeMachine = class("CodeGameScreenBuzzingHoneyBeeMachine", BaseNewReelMachine)
--fixios0223
CodeGameScreenBuzzingHoneyBeeMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenBuzzingHoneyBeeMachine.SYMBOL_SCORE_11 = 10

CodeGameScreenBuzzingHoneyBeeMachine.SYMBOL_WILD1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 94
CodeGameScreenBuzzingHoneyBeeMachine.SYMBOL_WILD2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2

CodeGameScreenBuzzingHoneyBeeMachine.CHANGETOWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1--锁定框变wild
CodeGameScreenBuzzingHoneyBeeMachine.WIN_GRAND_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2--赢jackpot Grand

CodeGameScreenBuzzingHoneyBeeMachine.PICWHEELDATA = {--图案轮盘数据
    {10,15,12,17,14,19},
    {5,20,12,17,9,24},
    {5,20,6,16,8,18,9,24},
    {5,20,1,21,7,22,3,23,9,24},
    {6,16,12,17,8,18},
    {10,15,1,21,3,23,14,19},
    {5,20,11,7,22,13,9,24},
    {1,6,11,16,21,3,8,13,18,23},
    {5,20,6,11,16,8,13,18,9,24},
    {7,12,17,22},
    {10,15,1,21,12,17,3,23,14,19},
    {5,20,11,12,17,13,9,24},
    {6,16,8,18},
    {10,15,6,11,16,8,13,18,14,19},
    {5,20,7,22,9,24},
    {10,15,7,22,14,19}
}
CodeGameScreenBuzzingHoneyBeeMachine.LockFrameType = {--锁定框类型
    Normal = 1,--一般的锁定框
    Super = 2--super下不删除的锁定框
}
-- 构造函数
function CodeGameScreenBuzzingHoneyBeeMachine:ctor()
    CodeGameScreenBuzzingHoneyBeeMachine.super.ctor(self)
    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_isOnceClipNode = false
    self.m_thisRoundStopBetID = 0--本轮停止时的bet id
    self.m_superWheelIdx = 0--superspin下图案轮盘的下标
    self.m_lockFrameTab = {}--存储锁定框的数组
    self.m_wildNodeTab = {}--存储wild图标的数组
    self.m_isReconnection = false--是否是重连轮
    self.m_isInit = true--是否刚进关轮
    self.m_isUpdateAllLockFrame = false --本轮是否刷新全部的锁定框，刷过的话spin时不再播h1图标变锁定框动画
    self.m_clipScatter = {}--存储提层的scatter图标
    self.m_clipH1 = {}--存储提层的H1图标
    self.m_avgBet = nil --平均bet值
    self.m_addRandLockFrameState = 0--添加随机锁定框动画阶段 0为还没开始，1为飞粒子(或一个一个出锁定框)，2为结束
    self.m_liziNodeTab = {}--存储添加随机锁定框动画飞的粒子
    self.m_changeToLockFrameH1Node = {}--存储要变锁定框的H1图标 
    --init
    self:initGame()
end

function CodeGameScreenBuzzingHoneyBeeMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
function CodeGameScreenBuzzingHoneyBeeMachine:getModuleName()
    return "BuzzingHoneyBee"
end
function CodeGameScreenBuzzingHoneyBeeMachine:getBottomUINode()
    return "CodeBuzzingHoneyBeeSrc.BuzzingHoneyBeeBoottomUiView"
end
--小块
function CodeGameScreenBuzzingHoneyBeeMachine:getBaseReelGridNode()
    return "CodeBuzzingHoneyBeeSrc.BuzzingHoneyBeeSlotNode"
end
function CodeGameScreenBuzzingHoneyBeeMachine:initUI()
    self.m_reelRunSound = "BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_quick_run.mp3"--快滚音效
    
    -- 背景添加向日葵
    local bg_flowerFrame = util_spineCreate("Socre_BuzzingHoneyBee_BGhuaban",true,true)
    self.m_gameBg:findChild("huaban"):addChild(bg_flowerFrame)
    util_spinePlay(bg_flowerFrame,"actionframe",true)
    
    self.m_jackPotBar = util_createView("CodeBuzzingHoneyBeeSrc.BuzzingHoneyBeeJackPotBarView")
    local worldPos = self:findChild("jackpot"):getParent():convertToWorldSpace(cc.p(self:findChild("jackpot"):getPosition()))
    local pos = self:convertToNodeSpace(worldPos)
    self:addChild(self.m_jackPotBar,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_jackPotBar:setPosition(pos)
    self.m_jackPotBar:setScale(self.m_machineRootScale)--适配
    self.m_jackPotBar:initMachine(self)
   
    --添加小蜜蜂
    self.m_bee = util_spineCreate("BuzzingHoneyBee_dajuese",true,true)
    self:beePlayAction("idleframe")
    -- self:findChild("BeeNode"):addChild(self.m_bee)
    local worldPos = self:findChild("BeeNode"):getParent():convertToWorldSpace(cc.p(self:findChild("BeeNode"):getPosition()))
    local pos = self:convertToNodeSpace(worldPos)
    self:addChild(self.m_bee,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    self.m_bee:setPosition(pos)
    self.m_bee:setScale(self.m_machineRootScale)--适配

    self:findChild("BeeNode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    --添加小蜜蜂对话框
    -- self.m_beeDialog = util_spineCreate("BuzzingHoneyBee_wanfa_1",true,true) --util_createAnimation("BuzzingHoneyBee_wanfa_1.csb")
    -- self:findChild("wanfa_1"):addChild(self.m_beeDialog)
    -- -- self.m_beeDialog:playAction("actionframe",true)
    -- util_spinePlay(self.m_beeDialog,"idleframe",true)
    --创建freespin次数收集显示条
    self.m_freespinCollectNumBar = util_createAnimation("BuzzingHoneyBee_wanfa_3.csb")
    self:findChild("wanfa_3"):addChild(self.m_freespinCollectNumBar)
    --添加条上的说明框
    self.m_freespinExplainFrame = util_createAnimation("BuzzingHoneyBee_wanfa_4.csb")
    self.m_freespinCollectNumBar:findChild("tb"):addChild(self.m_freespinExplainFrame)
    self:addClick(self.m_freespinCollectNumBar:findChild("touchRegion"))
    self.m_freespinExplainFrame:setVisible(false)
    --添加条上的向日葵
    self.m_sunflowerNodeTab = {}
    for i = 1,5 do
        local sunflowerNode = util_createAnimation("BuzzingHoneyBee_flower.csb")
        self.m_freespinCollectNumBar:findChild("flower_"..i):addChild(sunflowerNode)
        sunflowerNode:playAction("idleframe")
        sunflowerNode.m_playActionName = "idleframe"
        table.insert(self.m_sunflowerNodeTab,sunflowerNode)
    end
    --设置锁定框层级
    -- self:findChild("LockFrameNode"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    --添加轮盘
    self.m_wheelNode = util_createView("CodeBuzzingHoneyBeeSrc.BuzzingHoneyBeeWheelView")
    self:findChild("wheelNode"):addChild(self.m_wheelNode)
    self.m_wheelNode:setVisible(false)
    --添加轮盘指针中奖框
    self.m_wheelRewardFrame = util_createAnimation("BuzzingHoneyBee_wheel_zhizhen.csb")
    self:findChild("zhizhen"):addChild(self.m_wheelRewardFrame)
    self.m_wheelRewardFrame:setVisible(false)
    
    self.m_maskNodeTab = {}
    self.m_lockFrameParentNodeTab = {}

    for col = 1,self.m_iReelColumnNum do
        --添加半透明遮罩
        local parentData = self.m_slotParents[col]
        local mask = cc.LayerColor:create(cc.c3b(0, 0, 0), parentData.reelWidth - 1 , parentData.reelHeight)
        mask:setOpacity(200)
        mask.p_IsMask = true--不被底层移除的标记
        mask:setPositionX(parentData.reelWidth/2)
        parentData.slotParent:addChild(mask,REEL_SYMBOL_ORDER.REEL_ORDER_1 + 100)
        table.insert(self.m_maskNodeTab,mask)
        mask:setVisible(false)
        --添加锁定框的父节点
        local lockFrameParentNode = cc.Node:create()
        lockFrameParentNode.p_IsMask = true
        parentData.slotParent:addChild(lockFrameParentNode,REEL_SYMBOL_ORDER.REEL_ORDER_1 + 800)
        table.insert(self.m_lockFrameParentNodeTab,lockFrameParentNode)
    end
    

    

    self.m_ReelZorderNode = {"REEL","zhizhen","wanfa_1","wanfa_3","effNode","BeeNode","Jackpotwin"}

    --轮盘边框层级在滚轴上方
    self:findChild("lunpanbiankuang"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)

end
--点击回调
function CodeGameScreenBuzzingHoneyBeeMachine:clickFunc(sender)
    self:showFreespinExplainFrame()
end
--显示说明框
function CodeGameScreenBuzzingHoneyBeeMachine:showFreespinExplainFrame()
    if self.m_freespinExplainFrame:isVisible() == false then
        self.m_freespinExplainFrame:setVisible(true)
        self.m_freespinExplainFrame:playAction("start",false,function ()
            performWithDelay(self.m_freespinExplainFrame,function ()
                self.m_freespinExplainFrame:playAction("over",false,function ()
                    self.m_freespinExplainFrame:setVisible(false)
                end)
            end,1)
        end,60)
    end
end
--适配
function CodeGameScreenBuzzingHoneyBeeMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize() --h 120
    local uiBW, uiBH = self.m_bottomUI:getUISize()  --h 180
    --看资源实际的高度
    uiH = 120
    uiBH = 180

    local mainHeight = display.height - uiH - uiBH

    local winSize = display.size
    local mainScale = 1

    if display.height/display.width == DESIGN_SIZE.height/DESIGN_SIZE.width then
        --设计尺寸屏

    elseif display.height/display.width > DESIGN_SIZE.height/DESIGN_SIZE.width then
        --高屏
        local hScale = mainHeight / (DESIGN_SIZE.height - uiH - uiBH)
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale < wScale then
            mainScale = hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end
    else
        --宽屏
        local topAoH = 40--顶部条凹下去距离 在宽屏中会被用的尺寸
        local bottomMoveH = 35--底部空间尺寸，最后要下移距离
        local hScale1 = (mainHeight + topAoH )/(mainHeight + topAoH - bottomMoveH)--有效区域尺寸改变适配
        local hScale = (mainHeight + topAoH ) / (DESIGN_SIZE.height - uiH - uiBH + topAoH )--有效区域屏幕适配
        local wScale = winSize.width / DESIGN_SIZE.width
        if hScale1 * hScale < wScale then
            mainScale = hScale1 * hScale
        else
            mainScale = wScale
            self.m_isPadScale = true
        end

        local designDis = (DESIGN_SIZE.height/2 - uiBH) * mainScale--设计离下条距离
        local dis = (display.height/2 - uiBH)--实际离下条距离
        local move = designDis - dis
        --宽屏下轮盘跟底部条更接近，实际整体下移了
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + move - bottomMoveH)
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
end
--播放小蜜蜂动画
function CodeGameScreenBuzzingHoneyBeeMachine:beePlayAction(actionName,func)
    self.m_bee:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
    if actionName == "idleframe" then
        self.m_bee:setAnimation(0,"idleframe1",false)
        local randIdx = math.random(2,5)
        self.m_bee:addAnimation(0,"idleframe"..randIdx,false)
        util_spineEndCallFunc(self.m_bee,"idleframe"..randIdx,function ()
            self:beePlayAction("idleframe")
            if func then
                func()
            end
        end)
    elseif actionName == "zhongjiang1" or actionName == "zhongjiang2" then
        -- local randIdx = math.random(1,2)
        -- self.m_bee:setAnimation(0,"zhongjiang"..randIdx,false)
        self.m_bee:setAnimation(0,actionName,false)
        self.m_bee:addAnimation(0,"zhongjiang3",false)
        util_spineEndCallFunc(self.m_bee,"zhongjiang3",function ()
            self:beePlayAction("idleframe")
            if func then
                func()
            end
        end)
    elseif actionName == "tanban1" then
        self.m_bee:setAnimation(0,actionName,false)
        util_spineEndCallFunc(self.m_bee,actionName,function ()
            if func then
                func()
            end
        end)
    else
        self.m_bee:setAnimation(0,actionName,false)
        util_spineEndCallFunc(self.m_bee,actionName,function ()
            self:beePlayAction("idleframe")
            if func then
                func()
            end
        end)
    end
end
function CodeGameScreenBuzzingHoneyBeeMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(function()
      self:playEnterGameSound( "BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_enter.mp3" )
    end,0.4,self:getModuleName())
end
--轮盘滚动显示遮罩
function CodeGameScreenBuzzingHoneyBeeMachine:beginReelShowMask()
    for i,maskNode in ipairs(self.m_maskNodeTab) do
        if maskNode:isVisible() == false then
            maskNode:setVisible(true)
            maskNode:setOpacity(0)
            maskNode:runAction(cc.FadeTo:create(0.5,200))
        end
    end
end
--轮盘停止隐藏遮罩
function CodeGameScreenBuzzingHoneyBeeMachine:reelStopHideMask(actionTime, col)
    local maskNode = self.m_maskNodeTab[col]
    local fadeAct = cc.FadeTo:create(actionTime,0)
    local func = cc.CallFunc:create(function ()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct,func))
end
--轮盘开始滚动
function CodeGameScreenBuzzingHoneyBeeMachine:beginReel()
    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol
    self.m_randomAddLocksSoundId = nil
    self:setSymbolToReel()
    gLobalSoundManager:stopAudio(self.m_winSoundsId)
    
    self:resetReelDataAfterReel()
    local slotsParents = self.m_slotParents
    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

        self:checkReelIndexReason(parentData)
        self:resetParentDataReel(parentData)

        self:createSlotNextNode(parentData)
        if self.m_configData.p_reelBeginJumpTime > 0 then
            self:addJumoActionAfterReel(slotParent,slotParentBig,i)
        else
            self:registerReelSchedule()
        end
        self:checkChangeClipParent(parentData)
    end
    self:checkChangeBaseParent()
    self:beginNewReel()

    self.m_isInit = false
    self.m_isReconnection = false
    self.m_h1AddLocks = nil
    self:removeAllH1ChangeNode()
    self:removeAllWildNode()
    self:removeRunoutLockFrame()
    if self.m_isUpdateAllLockFrame == false then
        self:symbolNodeChangeToLockFrame()
    end
    self.m_isUpdateAllLockFrame = false
    
    self:beginReelShowMask()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_wheelNode:wheelStart()
    else
        self.m_avgBet = nil
    end
    self.m_addRandLockFrameState = 0
    self:removeFlyLizi()
end
--删除所有的wild图标
function CodeGameScreenBuzzingHoneyBeeMachine:removeAllWildNode()
    for i,wildNode in ipairs(self.m_wildNodeTab) do
        wildNode:removeFromParent()
        self:pushSlotNodeToPoolBySymobolType(wildNode.p_symbolType, wildNode)
    end
    self.m_wildNodeTab = {}
end
--删除用完的锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:removeRunoutLockFrame()
    local totalBetID = globalData.slotRunData:getCurTotalBet() 
    if self.m_betLockData and self.m_betLockData[tostring(toLongNumber( totalBetID) )] then
        local dataTab = self.m_betLockData[tostring(toLongNumber( totalBetID))].lockPositions
        local index = 1
        while true do
            print("万一无限调了咋办1")
            if index > #self.m_lockFrameTab then
                break
            end
            local lockFrame = self.m_lockFrameTab[index]
            local isHaveUsed = false
            for i,pos in ipairs(dataTab) do
                local rowcolData = self:getRowAndColByPos(pos)
                if rowcolData.iX == lockFrame.m_row and rowcolData.iY == lockFrame.m_col then
                    isHaveUsed = true
                    break
                end
            end
            if isHaveUsed == false then
                lockFrame:removeFromParent()
                table.remove(self.m_lockFrameTab,index)
            else
                index = index + 1
            end
        end
        self:updateAllLockFrameLRShow()
    else
        self:removeAllLockFrame()
    end
end
function CodeGameScreenBuzzingHoneyBeeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBuzzingHoneyBeeMachine.super.onEnter(self)
    self:addObservers()

    self.m_thisRoundStopBetID = globalData.slotRunData:getCurTotalBet()
    self:updateFreespinCollectNum(false)
    self:updateAllLockFrame()
    if self.m_runSpinResultData.p_freeSpinsLeftCount == nil or self.m_runSpinResultData.p_freeSpinsLeftCount <= 0 then
        self:addEnterGameView()
    end

    if self.m_touchSpinLayer then
        self.m_touchSpinLayer:setPositionY(self.m_touchSpinLayer:getPositionY() - self.m_SlotNodeH / 2 ) 
    end
end
function CodeGameScreenBuzzingHoneyBeeMachine:addEnterGameView()
    local enterView = util_createView("CodeBuzzingHoneyBeeSrc.BuzzingHoneyBeeEnterGameView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        enterView.getRotateBackScaleFlag = function() return false end
    end
    gLobalViewManager:showUI(enterView)
end
--[[
    @desc: 如果触发了 freespin 时，将本次触发的bigwin 和 mega win 去掉
    time:2019-01-22 15:31:18
    @return:
]]
function CodeGameScreenBuzzingHoneyBeeMachine:checkRemoveBigMegaEffect()
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect == true then
        if self.m_bProduceSlots_InFreeSpin == false then
            self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
            self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
            self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
            self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
            self.m_bIsBigWin = false
        end
    end

    -- 如果处于 freespin 中 那么大赢都不触发
    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect == true  then -- or  self.m_bProduceSlots_InFreeSpin == true
        self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
        self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
        self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
        self:removeGameEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_bIsBigWin = false
    end

end
function CodeGameScreenBuzzingHoneyBeeMachine:addObservers()
    CodeGameScreenBuzzingHoneyBeeMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end

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

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        if params then
            local isLevelUp = params.p_isLevelUp
            self:betChangeNotify(isLevelUp) 
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:wheelNumOver()
    end,"CodeGameScreenBuzzingHoneyBeeMachine_wheelNumOver")

    gLobalNoticManager:addObserver(self,function(self,params)
        self:wheelPicOver()
    end,"CodeGameScreenBuzzingHoneyBeeMachine_wheelPicOver")
    
    gLobalNoticManager:addObserver(self,function(self,params)
        self:playWheelRewardFrameAction(params[1],params[2])
    end,"CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction")
end
--播放轮盘指针动画
function CodeGameScreenBuzzingHoneyBeeMachine:playWheelRewardFrameAction(actionName,isloop)
    self.m_wheelRewardFrame:playAction(actionName,isloop)
end

--清除所有锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:removeAllLockFrame()
    for i,lockFrame in ipairs(self.m_lockFrameTab) do
        lockFrame:removeFromParent()
    end
    self.m_lockFrameTab = {}
end
--刷新锁定框的显示
function CodeGameScreenBuzzingHoneyBeeMachine:updateAllLockFrame()
    self.m_isUpdateAllLockFrame = true
    local totalBetID = globalData.slotRunData:getCurTotalBet() 
    if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then--freespin触发轮
        --触发轮调到这里只会是重连，不能切换bet
        local dataTab = self.m_runSpinResultData.p_selfMakeData.lockPositions
        for i,pos in ipairs(dataTab) do
            local rowColData = self:getRowAndColByPos(pos)
            self:addOneLockFrame(rowColData.iY,rowColData.iX,false,self.LockFrameType.Normal)
        end
        self:updateAllLockFrameLRShow()
    else
        if self.m_betLockData and self.m_betLockData[tostring(toLongNumber( totalBetID) )] then
            local dataTab = self.m_betLockData[tostring(toLongNumber( totalBetID))].lockPositions
            for i,pos in ipairs(dataTab) do
                local rowColData = self:getRowAndColByPos(pos)
                self:addOneLockFrame(rowColData.iY,rowColData.iX,false,self.LockFrameType.Normal)
            end
        end
        --在freespin中重连才读super锁定框
        if self.m_runSpinResultData.p_freeSpinsTotalCount and self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.superLocks then
                local resultData = self.m_runSpinResultData.p_fsExtraData.superLocks
                for i,pos in ipairs(resultData) do
                    local rowColData = self:getRowAndColByPos(pos)
                    self:addOneLockFrame(rowColData.iY,rowColData.iX,false,self.LockFrameType.Super)
                end
            end
        end
        self:updateAllLockFrameLRShow()
    end
end
--添加锁定框    frameType对应的资源编号
function CodeGameScreenBuzzingHoneyBeeMachine:addOneLockFrame(col,row,isPlayAction,frameType)
    for i,lockFrame in ipairs(self.m_lockFrameTab) do
        if lockFrame.m_row == row and lockFrame.m_col == col then
            if frameType == self.LockFrameType.Super and lockFrame.m_frameType == self.LockFrameType.Normal then
                --删除这个，换新的
                lockFrame:removeFromParent()
                table.remove(self.m_lockFrameTab,i)
                break
            else
                --这里已经有了，不用再加了
                return
            end
        end
    end

    local lockFrame = util_createAnimation("BuzzingHoneyBee_fengchao_"..frameType..".csb")
    self.m_lockFrameParentNodeTab[col]:addChild(lockFrame)
    -- self:findChild("LockFrameNode"):addChild(lockFrame)
    lockFrame:setLocalZOrder(col * 10 - row)
    
    local worldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(row,col))
    local nodePos = self.m_lockFrameParentNodeTab[col]:convertToNodeSpace(worldPos)
    lockFrame:setPosition(nodePos)

    if isPlayAction then
        lockFrame:playAction("actionframe")
    else
        lockFrame:playAction("idleframe")
    end

    local idleframe = util_createAnimation("BuzzingHoneyBee_fengchao_3.csb")
    lockFrame:findChild("idle"):addChild(idleframe)
    local wuguizexiaxie = math.random(1,4)
    performWithDelay(idleframe,function ()
        idleframe:playAction("actionframe",true,nil,60)
    end,1 + 15 * wuguizexiaxie / 60)

    --记录一些属性
    lockFrame.m_row = row
    lockFrame.m_col = col
    lockFrame.m_frameType = frameType

    table.insert(self.m_lockFrameTab,lockFrame)
end
--更新所有锁定框边缘显示 isReset是不是重置延迟动画，isDelay要不要延迟
function CodeGameScreenBuzzingHoneyBeeMachine:updateAllLockFrameLRShow()
    for i,lockFrame in ipairs(self.m_lockFrameTab) do
        self:updateOneLockFrameLRShow(lockFrame)
    end
end
--更新某一个锁定框边缘显示
function CodeGameScreenBuzzingHoneyBeeMachine:updateOneLockFrameLRShow(lockFrame)
    --锁定框边缘显示初始化
    lockFrame:findChild("greenjiao_lefttop"):setVisible(false)
    lockFrame:findChild("redjiao_lefttop"):setVisible(false)
    lockFrame:findChild("greenjiao_leftup"):setVisible(false)
    lockFrame:findChild("redjiao_leftup"):setVisible(false)
    lockFrame:findChild("greenjiao_leftmidleup"):setVisible(false)
    lockFrame:findChild("redjiao_leftmidleup"):setVisible(false)
    lockFrame:findChild("greenjiao_leftmidledown"):setVisible(false)
    lockFrame:findChild("redjiao_leftmidledown"):setVisible(false)
    lockFrame:findChild("greenjiao_leftdown"):setVisible(false)
    lockFrame:findChild("redjiao_leftdown"):setVisible(false)
    lockFrame:findChild("greenjiao_leftbottom"):setVisible(false)
    lockFrame:findChild("redjiao_leftbottom"):setVisible(false)

    local adjacentLockFrameData = {--左侧相邻锁定框的数据
        leftUp = 0,  --左上的情况  0 没有  1普通锁定框 2 super锁定框
        leftDown = 0  --左下的情况
    }
    if lockFrame.m_col % 2 == 1 and lockFrame.m_col > 1 then--在奇数列
        --检测左边是不是有锁定框
        for i,v in ipairs(self.m_lockFrameTab) do
            if v.m_col == lockFrame.m_col - 1 then
                if v.m_row == lockFrame.m_row + 1 then
                    --左上有锁定框
                    adjacentLockFrameData.leftUp = v.m_frameType
                end
                if v.m_row == lockFrame.m_row then
                    --左下有锁定框
                    adjacentLockFrameData.leftDown = v.m_frameType
                end
            end
        end
    else--在偶数列
        for i,v in ipairs(self.m_lockFrameTab) do
            if v.m_col == lockFrame.m_col - 1 then
                if v.m_row == lockFrame.m_row then
                    --左上有锁定框
                    adjacentLockFrameData.leftUp = v.m_frameType
                end
                if v.m_row == lockFrame.m_row - 1 then
                    --左下有锁定框
                    adjacentLockFrameData.leftDown = v.m_frameType
                end
            end
        end
    end

    if lockFrame.m_frameType == self.LockFrameType.Normal then
        if adjacentLockFrameData.leftUp == 0 then
            lockFrame:findChild("greenjiao_leftup"):setVisible(true)
            if adjacentLockFrameData.leftDown == 0 then
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Normal then
                lockFrame:findChild("greenjiao_leftmidleup"):setVisible(true)
                lockFrame:findChild("greenjiao_leftmidledown"):setVisible(true)
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
                lockFrame:findChild("greenjiao_leftbottom"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Super then
                lockFrame:findChild("greenjiao_leftmidleup"):setVisible(true)
                lockFrame:findChild("greenjiao_leftmidledown"):setVisible(true)
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
                lockFrame:findChild("redjiao_leftbottom"):setVisible(true)
            end
        elseif adjacentLockFrameData.leftUp == self.LockFrameType.Normal then
            lockFrame:findChild("greenjiao_lefttop"):setVisible(true)
            lockFrame:findChild("greenjiao_leftup"):setVisible(true)
            lockFrame:findChild("greenjiao_leftmidleup"):setVisible(true)
            lockFrame:findChild("greenjiao_leftmidledown"):setVisible(true)
            if adjacentLockFrameData.leftDown == 0 then
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Normal then
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
                lockFrame:findChild("greenjiao_leftbottom"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Super then
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
                lockFrame:findChild("redjiao_leftbottom"):setVisible(true)
            end
        elseif adjacentLockFrameData.leftUp == self.LockFrameType.Super then
            lockFrame:findChild("redjiao_lefttop"):setVisible(true)
            lockFrame:findChild("redjiao_leftup"):setVisible(true)
            lockFrame:findChild("greenjiao_leftmidleup"):setVisible(true)
            lockFrame:findChild("greenjiao_leftmidledown"):setVisible(true)
            if adjacentLockFrameData.leftDown == 0 then
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Normal then
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
                lockFrame:findChild("greenjiao_leftbottom"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Super then
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
                lockFrame:findChild("redjiao_leftbottom"):setVisible(true)
            end
        end
    elseif lockFrame.m_frameType == self.LockFrameType.Super then
        if adjacentLockFrameData.leftUp == 0 then
            lockFrame:findChild("redjiao_leftup"):setVisible(true)
            if adjacentLockFrameData.leftDown == 0 then
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Normal then
                lockFrame:findChild("redjiao_leftmidleup"):setVisible(true)
                lockFrame:findChild("redjiao_leftmidledown"):setVisible(true)
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
                lockFrame:findChild("greenjiao_leftbottom"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Super then
                lockFrame:findChild("redjiao_leftmidleup"):setVisible(true)
                lockFrame:findChild("redjiao_leftmidledown"):setVisible(true)
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
                lockFrame:findChild("redjiao_leftbottom"):setVisible(true)
            end
        elseif adjacentLockFrameData.leftUp == self.LockFrameType.Normal then
            lockFrame:findChild("greenjiao_lefttop"):setVisible(true)
            lockFrame:findChild("greenjiao_leftup"):setVisible(true)
            lockFrame:findChild("redjiao_leftmidleup"):setVisible(true)
            lockFrame:findChild("redjiao_leftmidledown"):setVisible(true)
            if adjacentLockFrameData.leftDown == 0 then
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Normal then
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
                lockFrame:findChild("greenjiao_leftbottom"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Super then
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
                lockFrame:findChild("redjiao_leftbottom"):setVisible(true)
            end
        elseif adjacentLockFrameData.leftUp == self.LockFrameType.Super then
            lockFrame:findChild("redjiao_lefttop"):setVisible(true)
            lockFrame:findChild("redjiao_leftup"):setVisible(true)
            lockFrame:findChild("redjiao_leftmidleup"):setVisible(true)
            lockFrame:findChild("redjiao_leftmidledown"):setVisible(true)
            if adjacentLockFrameData.leftDown == 0 then
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Normal then
                lockFrame:findChild("greenjiao_leftdown"):setVisible(true)
                lockFrame:findChild("greenjiao_leftbottom"):setVisible(true)
            elseif adjacentLockFrameData.leftDown == self.LockFrameType.Super then
                lockFrame:findChild("redjiao_leftdown"):setVisible(true)
                lockFrame:findChild("redjiao_leftbottom"):setVisible(true)
            end
        end
    end

end
--图标变为锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:symbolNodeChangeToLockFrame()
    if self.m_thisRoundStopBetID == globalData.slotRunData:getCurTotalBet() then--没有切换bet才能添加锁定框
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.h1AddLocks and #self.m_runSpinResultData.p_selfMakeData.h1AddLocks > 0 then
            self.m_h1AddLocks = clone(self.m_runSpinResultData.p_selfMakeData.h1AddLocks)
            for i,pos in ipairs(self.m_h1AddLocks) do
                local rowColData = self:getRowAndColByPos(pos)
                self:addOneLockFrame(rowColData.iY,rowColData.iX,true,self.LockFrameType.Normal)
            end
            gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_H1ChangeToLockFrame.mp3")
            self:updateAllLockFrameLRShow()
            -- for i,pos in ipairs(self.m_h1AddLocks) do
            --     local rowColData = self:getRowAndColByPos(pos)
            --     if i == #self.m_h1AddLocks then
            --         self:playH1ChangeAction(rowColData.iY,rowColData.iX,function ()
            --             for i,pos in ipairs(self.m_h1AddLocks) do
            --                 local rowColData = self:getRowAndColByPos(pos)
            --                 self:addOneLockFrame(rowColData.iY,rowColData.iX,true,self.LockFrameType.Normal)
            --             end
            --             self:updateAllLockFrameLRShow()
            --         end)
            --     else
            --         self:playH1ChangeAction(rowColData.iY,rowColData.iX)
            --     end
            -- end
        end
    end
end
--播放H1图标变身动画
function CodeGameScreenBuzzingHoneyBeeMachine:playH1ChangeAction(col,row,func)
    local H1Node = util_spineCreate("Socre_BuzzingHoneyBee_9",true,true)
    local position = self:getNodePosByColAndRow(row,col)
    H1Node:setPosition(position)
    self.m_clipParent:addChild(H1Node,self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9) - row + col*10)
    util_spinePlay(H1Node,"actionframe2",false)
    util_spineFrameCallFunc(H1Node,"actionframe2","bianwild",function ()
        if func then
            func()
        end
    end,function ()
        H1Node:setVisible(false)
    end)
    table.insert(self.m_changeToLockFrameH1Node,H1Node)
end
--锁定框变wild
function CodeGameScreenBuzzingHoneyBeeMachine:lockFrameChangeToWild()
    local wildPosData = clone(self.m_runSpinResultData.p_selfMakeData.wildPositions)
    self.m_changeWildDataTab = {}--变wild的位置数据
    --找出变wild的起始点
    local startIndex = 1
    local startPos = {}
    while true do
        print("万一无限调了咋办2")
        if startIndex > #wildPosData then
            break
        end
        local rowcolData = self:getRowAndColByPos(wildPosData[startIndex])
        if self.m_stcValidSymbolMatrix[rowcolData.iX][rowcolData.iY] == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            table.insert(startPos,wildPosData[startIndex])
            table.remove(wildPosData,startIndex)
        else
            startIndex = startIndex + 1
        end
    end
    local startPosTab = {}
    startPosTab["-1"] = startPos
    table.insert(self.m_changeWildDataTab,startPosTab)
    --根据起始点开始计算蔓延位置
    while true do
        print("万一无限调了咋办3")
        if #wildPosData <= 0 then
            break
        end
        local index = 1
        local posTab = {}
        while true do
            print("万一无限调了咋办4")
            if index > #wildPosData then
                break
            end
            local isAdjacent = false
            for startPos,toPosTab in pairs(self.m_changeWildDataTab[#self.m_changeWildDataTab]) do
                for i,centerPos in ipairs(toPosTab) do
                    if self:twoPosIsAdjacent(centerPos,wildPosData[index]) then
                        isAdjacent = true
                        if posTab[""..centerPos] == nil then
                            posTab[""..centerPos] = {}
                        end
                        table.insert(posTab[""..centerPos],wildPosData[index])
                        table.remove(wildPosData,index)
                        break
                    end
                end
                if isAdjacent == true then
                    break
                end
            end
            if isAdjacent == false then
                index = index + 1
            end
        end
        table.insert(self.m_changeWildDataTab,posTab)
    end
    self:startPlayChangeWildAction()
end
--判断两个位置是否相邻(两个参数都为服务器数据的位置值)
function CodeGameScreenBuzzingHoneyBeeMachine:twoPosIsAdjacent(centerPos,testPos)
    local centerRowcolData = self:getRowAndColByPos(centerPos)
    local testRowcolData = self:getRowAndColByPos(testPos)
    if centerRowcolData.iY == testRowcolData.iY then
        if math.abs(testRowcolData.iX - centerRowcolData.iX) == 1 then
            return true
        end
    end
    if math.abs(testRowcolData.iY - centerRowcolData.iY) == 1 then
        if centerRowcolData.iY % 2 == 1 then--在奇数列
            if (centerRowcolData.iX == testRowcolData.iX) or (centerRowcolData.iX + 1 == testRowcolData.iX) then
                return true
            end
        else--在偶数列
            if (centerRowcolData.iX == testRowcolData.iX) or (centerRowcolData.iX - 1 == testRowcolData.iX) then
                return true
            end
        end
    end
    return false
end
--开始播放变wild动画
function CodeGameScreenBuzzingHoneyBeeMachine:startPlayChangeWildAction()
    if #self.m_changeWildDataTab <= 0 then
        --等wild出现的相关动作特效播完
        performWithDelay(self,function ()
            self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.CHANGETOWILD_EFFECT})
        end,55/60)
        return
    end
    local posDataTab = self.m_changeWildDataTab[1]
    table.remove(self.m_changeWildDataTab,1)

    function showWildAction(showPosTab,isCallback)
        for i,pos in ipairs(showPosTab) do
            local rowcolData = self:getRowAndColByPos(pos)
            if isCallback == true then
                isCallback = false
                self:addOneWildSymbol(rowcolData.iY,rowcolData.iX,self:getWildType(pos),function ()
                    self:startPlayChangeWildAction()
                end)
            else
                self:addOneWildSymbol(rowcolData.iY,rowcolData.iX,self:getWildType(pos))
            end
        end
        gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_lockFrameChangeToWild.mp3")
    end

    local effectMoveTime = 0
    local showWildPosTab = {}
    local isPlayChuandiSound = false
    for startPosStr,toPosTab in pairs(posDataTab) do
        --开始 不用飞特效直接出wild
        if startPosStr == "-1" then
            for i,pos in ipairs(toPosTab) do
                table.insert(showWildPosTab,pos)
                local rowcolData = self:getRowAndColByPos(pos)
                self:playH1ChangeAction(rowcolData.iY,rowcolData.iX)
            end
            effectMoveTime = 17/30
        else
            local startPos = tonumber(startPosStr)
            local startRowcolData = self:getRowAndColByPos(startPos)
            local startPosition = self:getNodePosByColAndRow(startRowcolData.iX,startRowcolData.iY)
            --从起点开始飞特效
            for i,pos in ipairs(toPosTab) do
                local effectNode = util_createAnimation("BuzzingHoneyBee_chuandi.csb")
                
                self.m_clipParent:addChild(effectNode,REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 300)
                effectNode:setPosition(startPosition)

                local endRowcolData = self:getRowAndColByPos(pos)
                local endPosition = self:getNodePosByColAndRow(endRowcolData.iX,endRowcolData.iY)
                local degrees = util_getDegreesByPos(startPosition,endPosition)
                effectNode:setRotation(degrees)
                effectNode.pos = pos

                effectNode:playAction("actionframe",false,function ()
                    effectNode:removeFromParent()
                end)
                local tm = 20/30--util_csbGetAnimTimes(effectNode.m_csbAct ,"actionframe",30)
                if effectMoveTime < tm then
                    effectMoveTime = tm
                end
                table.insert(showWildPosTab,pos)
            end
            isPlayChuandiSound = true
        end
    end
    if isPlayChuandiSound then
        performWithDelay(self,function ()
                gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_chuandi.mp3")
            end,15/30)--传递特效的空白帧时间
    end
    performWithDelay(self,function ()
        showWildAction(showWildPosTab,true)
    end,effectMoveTime)
end
--获得一个位置出现wild的类型
function CodeGameScreenBuzzingHoneyBeeMachine:getWildType(pos)
    local wildType = self.SYMBOL_WILD1
    if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.superLocks then
        -- for i,superPos in ipairs(self.m_runSpinResultData.p_fsExtraData.superLocks) do
        --     if pos == superPos then
        --         wildType = self.SYMBOL_WILD2
        --         break
        --     end
        -- end
        if #self.m_runSpinResultData.p_fsExtraData.superLocks > 0 and self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount then
            wildType = self.SYMBOL_WILD2
        end
    end
    return wildType
end
--添加一个wild    wildType是信号块类型
function CodeGameScreenBuzzingHoneyBeeMachine:addOneWildSymbol(col,row,wildType,func)
    local symbolNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
    if symbolNode == nil then
        symbolNode = self:getFixSymbol(col, row, SYMBOL_FIX_NODE_TAG * 10)
    end
    --这个位置如果是scatter，则scatter变身
    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        symbolNode:runAnim("bianwild")
        symbolNode:setLineAnimName("actionframe2")
        symbolNode:setIdleAnimName("idleframe2")

        local linePos = {}
        linePos[#linePos + 1] = {iX = symbolNode.p_rowIndex, iY = symbolNode.p_cloumnIndex }
        symbolNode:setLinePos(linePos)

        local nodePos = self:getNodePosByColAndRow(row,col)

        --添加出现特效
        local effectNode = util_createAnimation("BuzzingHoneyBee_chuandi_wild.csb")
        self.m_clipParent:addChild(effectNode,symbolNode:getLocalZOrder() + 1000)
        effectNode:setPosition(nodePos)
        effectNode:playAction("actionframe",false,function ()
            effectNode:removeFromParent()
        end)
        if func then
            func()
        end
    else
        local wildSymbol = self:getSlotNodeWithPosAndType(wildType, row, col)
        wildSymbol:runAnim("appear")
        self.m_clipParent:addChild(wildSymbol, self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) - row + col*10, SYMBOL_NODE_TAG)
        local nodePos = self:getNodePosByColAndRow(row,col)
        wildSymbol:setPosition(nodePos)
        --添加出现特效
        local effectNode = util_createAnimation("BuzzingHoneyBee_chuandi_wild.csb")
        self.m_clipParent:addChild(effectNode,wildSymbol:getLocalZOrder() + 1000)
        effectNode:setPosition(nodePos)
        effectNode:playAction("actionframe",false,function ()
            effectNode:removeFromParent()
        end)
        --变wild后再把H1图标放下层去
        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            performWithDelay(self,function ()
                for i,H1Node in ipairs(self.m_clipH1) do
                    if H1Node == symbolNode then
                        table.remove(self.m_clipH1,i)
                        break
                    end
                end
                self:oneSymbolToReel(symbolNode)
                -- symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9))
            end,5/30)
        end
        if func then
            func()
        end

        wildSymbol.p_slotNodeH = self.m_SlotNodeH

        wildSymbol.m_symbolTag = SYMBOL_FIX_NODE_TAG
        wildSymbol.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
        wildSymbol.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE

        local linePos = {}
        linePos[#linePos + 1] = {iX = row,iY = col}
        wildSymbol:setLinePos(linePos)
        table.insert(self.m_wildNodeTab,wildSymbol)
    end
end
--[[
    @desc: 获得轮盘的位置
]]
function CodeGameScreenBuzzingHoneyBeeMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX, posY = reelNode:getPosition()
    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH
    return cc.p(posX, posY)
end
function CodeGameScreenBuzzingHoneyBeeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBuzzingHoneyBeeMachine.super.onExit(self)
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
end

-- 返回自定义信号类型对应资源名
-- @param symbolType int 信号类型
function CodeGameScreenBuzzingHoneyBeeMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BuzzingHoneyBee_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_BuzzingHoneyBee_11"
    elseif symbolType == self.SYMBOL_WILD1 then
        return "Socre_BuzzingHoneyBee_Wild_1"
    elseif symbolType == self.SYMBOL_WILD2 then
        return "Socre_BuzzingHoneyBee_Wild_2"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_NIL_TYPE then
        return "Socre_BuzzingHoneyBee_1"
    end
    return nil
end
--进关数据初始化
function CodeGameScreenBuzzingHoneyBeeMachine:initGameStatusData(gameData)
    if gameData.gameConfig and gameData.gameConfig.bets then
        self.m_betLockData = clone(gameData.gameConfig.bets)
    else
        self.m_betLockData = {}
    end
    CodeGameScreenBuzzingHoneyBeeMachine.super.initGameStatusData(self,gameData)
end

function CodeGameScreenBuzzingHoneyBeeMachine:updateNetWorkData()
    self:updateBetLockData()
    self:dealSmallReelsSpinStates()--按钮显示stop，可以快停
    self.m_funcSuperUpdateNetWorkData = function ()
        CodeGameScreenBuzzingHoneyBeeMachine.super.updateNetWorkData(self)
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_runSpinResultData.p_selfMakeData.wheelIndex then
        self.m_wheelNode:setWheelResult(self.m_runSpinResultData.p_selfMakeData.wheelIndex)
    else
        if self.m_runSpinResultData.p_selfMakeData.randomAddLocks and #self.m_runSpinResultData.p_selfMakeData.randomAddLocks > 0 then
            self:randomAddLocks()
        else
            self:playFuncSuperUpdateNetWorkData()
        end
    end
end
function CodeGameScreenBuzzingHoneyBeeMachine:playFuncSuperUpdateNetWorkData()
    if self.m_funcSuperUpdateNetWorkData then
        self.m_funcSuperUpdateNetWorkData()
        self.m_funcSuperUpdateNetWorkData = nil
    end
end
--快停
function CodeGameScreenBuzzingHoneyBeeMachine:operaQuicklyStopReel()
    if self.m_quickStopReelIndex then
        return
    end
    --随机加锁定框和轮盘都直接出现停止，显示最后结果
    self:playFuncSuperUpdateNetWorkData()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:quicklyStopWheelStop()
    self:quicklyStopAddRandomLockFrame()
    self:quicklyStopH1ChangeStop()
    self:allLockFramePlayIdle()

    --有停止并且未回弹的停止快停
    self.m_quickStopReelIndex = nil
    for i=1,#self.m_reels do
        if self.m_reels[i]:isReelDone() then
            self.m_quickStopReelIndex = i
        end
    end
    if not self.m_quickStopReelIndex then
        self:newQuickStopReel(1)
    end
end
function CodeGameScreenBuzzingHoneyBeeMachine:updateBetLockData()
    local totalBetID = globalData.slotRunData:getCurTotalBet()  
    if self.m_betLockData[tostring(toLongNumber( totalBetID))] then
        self.m_betLockData[tostring(toLongNumber( totalBetID))].lockPositions = clone(self.m_runSpinResultData.p_selfMakeData.finalLockPositions)
    else
        self.m_betLockData[tostring(toLongNumber( totalBetID))] = {}
        self.m_betLockData[tostring(toLongNumber( totalBetID))].lockPositions = clone(self.m_runSpinResultData.p_selfMakeData.finalLockPositions)
    end
end
--随机增加锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:randomAddLocks()
    self.m_randomAddLocksSoundId = gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_randomAddLocks.mp3")
    self:beePlayAction("shoujiwild")
    performWithDelay(self,function ()
        if self:getGameSpinStage() == QUICK_RUN then
            return
        end
        self.m_addRandLockFrameState = 1
        self.m_randomLockFramePosData = clone(self.m_runSpinResultData.p_selfMakeData.randomAddLocks)
        self:startAddRandomLockFrame()
    end,28/30)

    -- self:beePlayAction("shoujiwild")
    -- performWithDelay(self,function ()
    --     if self:getGameSpinStage() == QUICK_RUN then
    --         return
    --     end
    --     self.m_addRandLockFrameState = 1
    --     for i,posData in ipairs(self.m_runSpinResultData.p_selfMakeData.randomAddLocks) do
    --         local rowcolData = self:getRowAndColByPos(posData)
    --         --开始飞粒子
    --         local flytime = 0.75
    --         -- 创建粒子
    --         local flyLizi = util_createAnimation("Socre_BuzzingHoneyBee_fly_lizi.csb")
    --         self:addChild(flyLizi,self.m_bee:getLocalZOrder() - 1)
    --         flyLizi:findChild("Particle_1"):setDuration(flytime)
    --         flyLizi:findChild("Particle_1"):setPositionType(0)
    --         flyLizi:setPosition(cc.p(self.m_bee:getPosition()))

    --         local worldPos = self.m_clipParent:convertToWorldSpace(self:getNodePosByColAndRow(rowcolData.iX,rowcolData.iY))
    --         local endPos = self:convertToNodeSpace(worldPos)
    --         table.insert(self.m_liziNodeTab,flyLizi)
    --         self:flySpecialNode(flyLizi,cc.p(self.m_bee:getPosition()),endPos,flytime,function()
    --             if i == 1 then
    --                 self.m_addRandLockFrameState = 2
    --                 self:addRandomLockFrame()
    --             end
    --         end)
    --     end
    -- end,36/30)
end
--node飞行的图片或者粒子,startPos开始坐标,endPos停止坐标,flyTime飞行时间,func结束回调
function CodeGameScreenBuzzingHoneyBeeMachine:flySpecialNode(node,startPos,endPos,flyTime,func)
    if not node then
        return
    end
    if not flyTime then
        flyTime = 1
    end
    local actionList = {}
    local tempPos = cc.p(startPos.x+100+endPos.x*0.1,startPos.y+400+endPos.y*0.1)
    local bez1 = cc.BezierTo:create(flyTime*0.5,{cc.p(startPos.x+500,startPos.y),cc.p(startPos.x+300,tempPos.y),tempPos})
    actionList[#actionList + 1] = bez1
    local bez2 = cc.BezierTo:create(flyTime*0.5,{cc.p(tempPos.x-300,(startPos.y+tempPos.y)*0.5),cc.p(tempPos.x-100,(startPos.y+tempPos.y)*0.5),endPos})
    actionList[#actionList + 1] = bez2
    if func then
        actionList[#actionList + 1] = cc.CallFunc:create(func)
    end
    node:runAction(cc.Sequence:create(actionList))
end
--开始一个个添加随机锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:startAddRandomLockFrame()
    if #self.m_randomLockFramePosData <= 0 then
        self.m_addRandLockFrameState = 2
        self:playFuncSuperUpdateNetWorkData()
        return
    end
    local posData = self.m_randomLockFramePosData[1]
    table.remove(self.m_randomLockFramePosData,1)
    local rowcolData = self:getRowAndColByPos(posData)
    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_H1ChangeToLockFrame.mp3")
    self:addOneLockFrame(rowcolData.iY,rowcolData.iX,true,self.LockFrameType.Normal)
    self:updateAllLockFrameLRShow()
    performWithDelay(self,function ()
        self:startAddRandomLockFrame()
    end,40/60)
end
--添加随机锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:addRandomLockFrame()
    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_H1ChangeToLockFrame.mp3")
    for i,posData in ipairs(self.m_runSpinResultData.p_selfMakeData.randomAddLocks) do
        local rowcolData = self:getRowAndColByPos(posData)
        self:addOneLockFrame(rowcolData.iY,rowcolData.iX,true,self.LockFrameType.Normal)
    end
    self:updateAllLockFrameLRShow()
    
    performWithDelay(self,function ()
        if self:getGameSpinStage() ~= QUICK_RUN then
            self:playFuncSuperUpdateNetWorkData()
        end
    end,40/60)
end
-- 断线重连
function CodeGameScreenBuzzingHoneyBeeMachine:MachineRule_initGame()
    self.m_isReconnection = true
end

--单列滚动停止回调
function CodeGameScreenBuzzingHoneyBeeMachine:slotOneReelDown(reelCol)
    CodeGameScreenBuzzingHoneyBeeMachine.super.slotOneReelDown(self,reelCol)
    local columnData = self.m_reelColDatas[reelCol]
    local isPlayH1BulingSound = false
    for row = 1,columnData.p_showGridCount do
        local symbolNode = self:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)
        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
            self:setSymbolToClip(symbolNode)
            -- symbolNode:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + 800 + 1)--停止后放到锁定框的上层
            if self:isHaveLockFrame(reelCol,row) then
                symbolNode:runAnim("buling")
                isPlayH1BulingSound = true
            end
        end
        if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self:setSymbolToClip(symbolNode)
            local tipSlotNoes = self:addReelDownTipNode({symbolNode})
            if tipSlotNoes ~= nil then
                for i = 1, #tipSlotNoes do
                    --播放提示动画
                    self:playReelDownTipNode(tipSlotNoes[i])
                    isPlayH1BulingSound = false
                end
            end
        end
    end
    if isPlayH1BulingSound then

        local soundPath = "BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_H1buling.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            -- respinbonus落地音效
            gLobalSoundManager:playSound(soundPath)
        end
    end
end
function CodeGameScreenBuzzingHoneyBeeMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        soundPath = "BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_Scatter"..i..".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end
--将图标提到clipParent层
function CodeGameScreenBuzzingHoneyBeeMachine:setSymbolToClip(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX,slotNode.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
    
    self.m_clipParent:addChild(slotNode,self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex*10)
    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        self.m_clipScatter[#self.m_clipScatter + 1] = slotNode
    elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        self.m_clipH1[#self.m_clipH1 + 1] = slotNode

        slotNode:setTag( self:getNodeTag(slotNode.p_cloumnIndex,slotNode.p_rowIndex, SYMBOL_FIX_NODE_TAG * 10) ) -- 设置悬浮小块参与连线
        slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        local linePos = {}
        linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex }
        slotNode:setLinePos(linePos)
    end
end
--将图标恢复到轮盘层
function CodeGameScreenBuzzingHoneyBeeMachine:setSymbolToReel()
    for i,scatterNode in ipairs(self.m_clipScatter) do
        self:oneSymbolToReel(scatterNode)
    end
    self.m_clipScatter = {}
    for i,H1Node in ipairs(self.m_clipH1) do
        self:oneSymbolToReel(H1Node)
    end
    self.m_clipH1 = {}
end
function CodeGameScreenBuzzingHoneyBeeMachine:oneSymbolToReel(slotNode)
    local preParent = slotNode.m_preParent
    if preParent ~= nil then
        slotNode:setTag(self:getNodeTag(slotNode.p_cloumnIndex,slotNode.p_rowIndex , SYMBOL_NODE_TAG))
        slotNode.p_layerTag = slotNode.m_preLayerTag
        slotNode:setLinePos(nil)
        local nZOrder = slotNode.m_showOrder
        util_changeNodeParent(preParent,slotNode,nZOrder)
        slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
        slotNode:runIdleAnim()
    end
end
--刷新小块通知
function CodeGameScreenBuzzingHoneyBeeMachine:updateReelGridNode(symbolNode)
    if self.m_isInit == false then
        symbolNode:addTrailing(self.m_slotParents[symbolNode.p_cloumnIndex].slotParent)
    end
end
--检测当前位置是否有锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:isHaveLockFrame(col,row)
    for i,lockFrame in ipairs(self.m_lockFrameTab) do
        if col == lockFrame.m_col and row == lockFrame.m_row then
            return true
        end
    end
    return false
end

-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBuzzingHoneyBeeMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"free")

    self.m_freespinCollectNumBar:setVisible(false)
    self.m_jackPotBar:setVisible(false)

    self.m_wheelNode:setVisible(true)
    self.m_wheelRewardFrame:setVisible(true)
    self.m_wheelNode:reset()
    if self.m_runSpinResultData.p_selfMakeData.totalFreespinCount == self.m_runSpinResultData.p_selfMakeData.freespinCount then
        self.m_bottomUI:showAverageBet()
        self.m_avgBet = self.m_runSpinResultData.p_fsExtraData.avgBet
        if self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
            self:runCsbAction("narrow")
            self.m_wheelNode:setWheelType(2)
            self.m_wheelNode:setTitle(2)
        else
            self.m_wheelNode:setWheelType(1)
            self.m_wheelNode:setTitle(2)
        end
    else
        self.m_wheelNode:setWheelType(1)
        self.m_wheelNode:setTitle(1)
    end
end

--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBuzzingHoneyBeeMachine:levelFreeSpinOverChangeEffect()
    
end
function CodeGameScreenBuzzingHoneyBeeMachine:levelFreeSpinOverChangeNormal()
    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    self:runCsbAction("idleframe")
    self.m_wheelNode:setVisible(false)
    self.m_wheelRewardFrame:setVisible(false)
    self.m_freespinCollectNumBar:setVisible(true)
    -- self.m_beeDialog:setVisible(true)
    self:updateFreespinCollectNum(false)
    self:superLockFrameChangeToNormal()
    self:updateAllLockFrameLRShow()
    self.m_bottomUI:hideAverageBet()
    self.m_jackPotBar:setVisible(true)
end
function CodeGameScreenBuzzingHoneyBeeMachine:updateFreespinCollectNum(isPlayAction)
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.freespinCount then
        local num = self.m_runSpinResultData.p_selfMakeData.freespinCount
        for i,sunflowerNode in ipairs(self.m_sunflowerNodeTab) do
            if i < num then
                if sunflowerNode.m_playActionName ~= "idleframe2" then
                    sunflowerNode:playAction("idleframe2",true)
                    sunflowerNode.m_playActionName = "idleframe2"
                end
            elseif i == num then
                if isPlayAction then
                    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_freepsinNumAdd.mp3")
                    sunflowerNode.m_playActionName = "actionframe"
                    sunflowerNode:playAction("actionframe",false,function ()
                        sunflowerNode:playAction("idleframe2",true)
                        sunflowerNode.m_playActionName = "idleframe2"
                    end)
                else
                    sunflowerNode:playAction("idleframe2",true)
                    sunflowerNode.m_playActionName = "idleframe2"
                end
            else
                sunflowerNode:playAction("idleframe")
                sunflowerNode.m_playActionName = "idleframe"
            end
        end
        if num == #self.m_sunflowerNodeTab then
            if isPlayAction then
                self.m_freespinCollectNumBar:playAction("actionframe",false,function ()
                    self.m_freespinCollectNumBar:playAction("man")
                end)
            else
                self.m_freespinCollectNumBar:playAction("man")
            end
        else
            self.m_freespinCollectNumBar:playAction("idleframe")
        end
    end
end

function CodeGameScreenBuzzingHoneyBeeMachine:setSlotNodeEffectParent(slotNode)
    local node = CodeGameScreenBuzzingHoneyBeeMachine.super.setSlotNodeEffectParent(self,slotNode)
    node:setLocalZOrder(node:getLocalZOrder() + node.p_cloumnIndex * 10)
    return node
end
----------- FreeSpin相关
-- 显示free spin
function CodeGameScreenBuzzingHoneyBeeMachine:showEffect_FreeSpin(effectData)

    self.m_beInSpecialGameTrigger = true
    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
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
    if scatterLineValue ~= nil then
        --
        self:beePlayAction("zhongjiang1")
        if #self.m_clipScatter > 0 then
            for i,slotNode in ipairs(self.m_clipScatter) do
                slotNode:runAnim(slotNode:getLineAnimName(),false,function ()
                    slotNode:runAnim(slotNode:getIdleAnimName())
                end)
            end
        end
        performWithDelay(self,function ()
            self:showFreeSpinView(effectData)
        end,2.5)
        -- self:showBonusAndScatterLineTip(scatterLineValue,function()
        --     -- self:visibleMaskLayer(true,true)
        --     -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
        --     self:showFreeSpinView(effectData)
        -- end)
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        --
        if self.m_isReconnection then--是重连进来的话把scatter放到上层
            for col = 1,self.m_iReelColumnNum and #self.m_clipScatter == 0 do
                for row = 1,columnData.p_showGridCount do
                    local symbolNode = self:getFixSymbol(reelCol, row, SYMBOL_NODE_TAG)
                    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self:setSymbolToClip(symbolNode)
                    end
                end
            end
            local coins = self.m_runSpinResultData.p_fsWinCoins
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
        end
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
-- FreeSpinstart
function CodeGameScreenBuzzingHoneyBeeMachine:showFreeSpinView(effectData)
    --本关没有freespinmore
    local showFSView = function ()
        self:beePlayAction("tanban1",function ()
            gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_custom_enter_fs.mp3")
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:showGuochang(function ()
                    -- self.m_bottomUI:checkClearWinLabel()
                  
                    self:triggerFreeSpinCallFun()
                end,function ()
                    performWithDelay(self,function ()
                        if self.m_runSpinResultData.p_selfMakeData.totalFreespinCount == self.m_runSpinResultData.p_selfMakeData.freespinCount then
                            self:beginReelShowMask()
                            self.m_wheelNode:wheelStart()
                            self.m_wheelNode:setWheelResult(self:getPicWheelIdx())
                        else
                            self:notifyGameEffectPlayComplete(GameEffect.EFFECT_FREE_SPIN)
                        end
                    end,0.5)
                end)
            end)
        end)
    end

    if self.m_isReconnection == false then
        self:updateFreespinCollectNum(true)
    end
    performWithDelay(self,function()
        showFSView()
    end,1.5)
end
--获得图案轮盘结果id 0开始数
function CodeGameScreenBuzzingHoneyBeeMachine:getPicWheelIdx()
    local resultData = self.m_runSpinResultData.p_fsExtraData.superLocks
    for i,localData in ipairs(self.PICWHEELDATA) do
        if self:twoTab(localData,resultData) == true then
            self.m_superWheelIdx = i
            return i - 1
        end
    end
end
--比较两个tab内容是否一样
function CodeGameScreenBuzzingHoneyBeeMachine:twoTab(tab1,tab2)
    local isSame = true
    if #tab1 == #tab2 then
        for i = 1,#tab1 do
            if tab1[i] ~= tab2[i] then
                isSame = false
                break
            end
        end
    else
        isSame = false
    end
    return isSame
end
function CodeGameScreenBuzzingHoneyBeeMachine:showFreeSpinStart(num,func)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local fileName = "FreeSpinStart"
    if self.m_runSpinResultData.p_selfMakeData.totalFreespinCount == self.m_runSpinResultData.p_selfMakeData.freespinCount then
        fileName = "SuperFreeSpinStart"
    end

    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self,fileName,func,nil,nil,self.m_baseDialogViewFps)
    view:updateOwnerVar(ownerlist)
    view:findChild("Particle_1"):setPositionType(0)
    view:findChild("Particle_1"):resetSystem()
    view:findChild("Particle_2"):setPositionType(0)
    view:findChild("Particle_2"):resetSystem()

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function() return false end
    end

    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    view:findChild("root"):setScale(self.m_machineRootScale)--适配

    view.viewType = 100--一个tag值   ViewType.TYPE_UI
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = view})

    local bee = util_spineCreate("BuzzingHoneyBee_dajuese2",true,true)
    view:findChild("bee"):addChild(bee)
    util_spinePlay(bee,"tanban2",true)
    return view
end
function CodeGameScreenBuzzingHoneyBeeMachine:showFreeSpinOverView()
    local coins = self.m_runSpinResultData.p_fsWinCoins
    self:beePlayAction("tanban1",function ()
        gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_over_fs.mp3")
        local view = self:showFreeSpinOver( coins,
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                self:showGuochang(function ()
                    self:levelFreeSpinOverChangeNormal()
                end,function ()
                    self:triggerFreeSpinOverCallFun()
                end)
            end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx = 0.93,sy = 1},695)
    end)
end
function CodeGameScreenBuzzingHoneyBeeMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)

    local view = util_createView("Levels.BaseDialog")
    view:initViewData(self,"FreeSpinOver",func,nil,nil,self.m_baseDialogViewFps)
    view:updateOwnerVar(ownerlist)
    view:findChild("Particle_1"):setPositionType(0)
    view:findChild("Particle_1"):resetSystem()
    view:findChild("Particle_2"):setPositionType(0)
    view:findChild("Particle_2"):resetSystem()

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function() return false end
    end

    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    view:findChild("root"):setScale(self.m_machineRootScale)--适配

    view.viewType = 100--一个tag值   ViewType.TYPE_UI
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = view})

    local bee = util_spineCreate("BuzzingHoneyBee_dajuese2",true,true)
    view:findChild("bee"):addChild(bee)
    util_spinePlay(bee,"tanban2",true)
    return view
end
---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBuzzingHoneyBeeMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    return false
end

--添加动画
function CodeGameScreenBuzzingHoneyBeeMachine:addSelfEffect()
    if self.m_runSpinResultData.p_selfMakeData.wildPositions and #self.m_runSpinResultData.p_selfMakeData.wildPositions > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.CHANGETOWILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CHANGETOWILD_EFFECT
    end

    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.grandWinCoins then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT+1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.WIN_GRAND_EFFECT
    end
end

-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBuzzingHoneyBeeMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.CHANGETOWILD_EFFECT then
        performWithDelay(self,function ()
            self:lockFrameChangeToWild()
        end,0.5)
    end
    if effectData.p_selfEffectType == self.WIN_GRAND_EFFECT then
        performWithDelay(self,function ()
            self:showJackpotWinEffect()
        end,0.5)
    end
    return true
end
-- 通知某种类型动画播放完毕
function CodeGameScreenBuzzingHoneyBeeMachine:notifyGameEffectPlayComplete(param)
    local effectType
    if type(param) == "table" then
        effectType = param[1]
    else
        effectType = param
    end
    local effectLen = #self.m_gameEffects
    if effectType == nil or effectType == EFFECT_NONE or effectLen == 0 then
        return
    end

    if effectType == GameEffect.EFFECT_QUEST_DONE then
        return
    end

    for i=1,effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == effectType and effectData.p_isPlay == false then
            if effectData.p_effectType == GameEffect.EFFECT_SELF_EFFECT then
                if effectData.p_selfEffectType == param[2] then
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 继续播放动画
                    break
                end
            else
                effectData.p_isPlay = true
                self:playGameEffect() -- 继续播放动画
                break
            end
        end
    end

end
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBuzzingHoneyBeeMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenBuzzingHoneyBeeMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenBuzzingHoneyBeeMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
end

function CodeGameScreenBuzzingHoneyBeeMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    self.m_thisRoundStopBetID = globalData.slotRunData:getCurTotalBet()
    CodeGameScreenBuzzingHoneyBeeMachine.super.slotReelDown(self)

    self.m_addRandLockFrameState = 0
    gLobalNoticManager:postNotification("BuzzingHoneyBeeWheelView_reelStopSetWheel")
end
--添加快滚特效
function CodeGameScreenBuzzingHoneyBeeMachine:createReelEffect(col)
    local fileName = self.m_reelEffectName .. ".csb"
    if col%2 == 1 then
        fileName = "WinFrameBuzzingHoneyBee_run_0.csb"
    end
    local reelEffectNode, effectAct = util_csbCreate(fileName)
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end
function CodeGameScreenBuzzingHoneyBeeMachine:checkOperaSpinSuccess( param )
    -- 触发了玩法 一定概率播特效
    if param[2].result.features[2] ~= nil then
        local rand = math.random(1,10)
        if rand <= 4 then
            self:showTriggerEffect(function ()
                CodeGameScreenBuzzingHoneyBeeMachine.super.checkOperaSpinSuccess(self,param)
            end)
        else
            CodeGameScreenBuzzingHoneyBeeMachine.super.checkOperaSpinSuccess(self,param)
        end
    else
        CodeGameScreenBuzzingHoneyBeeMachine.super.checkOperaSpinSuccess(self,param)
    end
end
--显示玩法触发特效
function CodeGameScreenBuzzingHoneyBeeMachine:showTriggerEffect(func)
    self.m_ScatterShowCol = {}--这里去掉scatter相关数据是为了不快滚，这么写是底层计算复杂很难搞清切入点
    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_showTriggerEffect.mp3")
    self:runCsbAction("yugaochufa",false,function ()
        self:runCsbAction("yugao",true,nil,60)
    end,60)
    for i = 1,12 do
        self:findChild("Particle_"..i):setPositionType(0)
        self:findChild("Particle_"..i):resetSystem()
    end
    
    self:beePlayAction("yugao")

    performWithDelay(self,function ()
        self:hideTriggerEffect(func)
    end,3)
end
function CodeGameScreenBuzzingHoneyBeeMachine:hideTriggerEffect(func)
    self:runCsbAction("over",false,function ()
        self:runCsbAction("idleframe",true,nil,60)
    end,60)
    if func then
        func()
    end
end
--过场
function CodeGameScreenBuzzingHoneyBeeMachine:showGuochang(func1,func2)
    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_guochang.mp3")
    self:beePlayAction("guochang")
    performWithDelay(self,function ()
        if func1 then
            func1()
        end
    end,42/30)

    self:delayCallBack(1.8,func2)
    
end
--向日葵数字转盘转动结束调用
function CodeGameScreenBuzzingHoneyBeeMachine:wheelNumOver()
    --老虎机可以停了
    if self.m_runSpinResultData.p_selfMakeData.randomAddLocks and #self.m_runSpinResultData.p_selfMakeData.randomAddLocks > 0 then
        self:randomAddLocks()
    else
        self:playFuncSuperUpdateNetWorkData()
    end
end
--向日葵图案转盘转动结束调用
function CodeGameScreenBuzzingHoneyBeeMachine:wheelPicOver()
    --添加free下不删除的锁定框
    self:addSuperFreeLockFrame()
end
--添加free下不删除的锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:addSuperFreeLockFrame()
    self.m_superFreeLockFramePosData = clone(self.PICWHEELDATA[self.m_superWheelIdx])
    -- self:startAddSuperFreeLockFrame()
    self:addAllSuperFreeLockFrame()
end
--开始一个个添加锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:startAddSuperFreeLockFrame()
    if #self.m_superFreeLockFramePosData <= 0 then
        self:runCsbAction("enlarge")
        self.m_wheelNode:reset()
        self.m_wheelNode:setWheelType(1,true)
        self:notifyGameEffectPlayComplete(GameEffect.EFFECT_FREE_SPIN)
        return
    end
    local posData = self.m_superFreeLockFramePosData[1]
    table.remove(self.m_superFreeLockFramePosData,1)
    local rowcolData = self:getRowAndColByPos(posData)
    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_H1ChangeToLockFrame.mp3")
    self:addOneLockFrame(rowcolData.iY,rowcolData.iX,true,self.LockFrameType.Super)
    self:updateAllLockFrameLRShow()
    performWithDelay(self,function ()
        self:startAddSuperFreeLockFrame()
    end,12/60)
end
--直接添加所有的super锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:addAllSuperFreeLockFrame()
    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_H1ChangeToLockFrame.mp3")
    for i,posData in ipairs(self.m_superFreeLockFramePosData) do
        local rowcolData = self:getRowAndColByPos(posData)
        self:addOneLockFrame(rowcolData.iY,rowcolData.iX,true,self.LockFrameType.Super)
    end
    self:updateAllLockFrameLRShow()
    performWithDelay(self,function ()
        self:runCsbAction("enlarge")
        self.m_wheelNode:reset()
        self.m_wheelNode:setWheelType(1,true)
        self:notifyGameEffectPlayComplete(GameEffect.EFFECT_FREE_SPIN)
    end,12/60)
end
--将super锁定框换成普通锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:superLockFrameChangeToNormal()
    self:removeAllSuperFreeLockFrame()
    if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.superLocks then
        local resultData = self.m_runSpinResultData.p_fsExtraData.superLocks
        for i,pos in ipairs(resultData) do
            local rowColData = self:getRowAndColByPos(pos)
            self:addOneLockFrame(rowColData.iY,rowColData.iX,false,self.LockFrameType.Normal)
        end
    end
end
--清除所有super下不删除的锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:removeAllSuperFreeLockFrame()
    local index = 1
    while true do
        print("万一无限调了咋办5")
        if index > #self.m_lockFrameTab then
            break
        end
        local lockFrame = self.m_lockFrameTab[index]
        if lockFrame.m_frameType == self.LockFrameType.Super then
            lockFrame:removeFromParent()
            table.remove(self.m_lockFrameTab,index)
        else
            index = index + 1
        end
    end
end

function CodeGameScreenBuzzingHoneyBeeMachine:getinitSlotRowDatatByNetData()
    -- 异形轮子特殊处理,断线回来应该处理全部数据
    local rowCount = #self.m_initSpinData.p_reels
    local rowNum = #self.m_initSpinData.p_reels
    local rowIndex = #self.m_initSpinData.p_reels  -- 返回来的数据1位置是最上面一行。

    return rowCount,rowNum,rowIndex
end
--假滚时调用的  加上层级
function CodeGameScreenBuzzingHoneyBeeMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)
    parentData.symbolType = symbolType
    parentData.order = self:getBounsScatterDataZorder(symbolType)
end
--获取信号块层级
function CodeGameScreenBuzzingHoneyBeeMachine:getBounsScatterDataZorder(symbolType)
    local order = CodeGameScreenBuzzingHoneyBeeMachine.super.getBounsScatterDataZorder(self,symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + 500
    end
    return order
end
-- 开始滚动之前添加向上跳动作
function CodeGameScreenBuzzingHoneyBeeMachine:addJumoActionAfterReel(slotParent,slotParentBig,col)
    local parentData = self.m_slotParents[col]
    local symbolNodeList,start,over = self.m_reels[parentData.cloumnIndex].m_gridList:getList()
    for i = start,over do
        local symbolNode = symbolNodeList[i]
        --添加一个回弹效果
        local action0 =
            cc.JumpTo:create(
            self.m_configData.p_reelBeginJumpTime,
            cc.p(symbolNode:getPositionX(), symbolNode:getPositionY()),
            self.m_configData.p_reelBeginJumpHight,
            1
        )
        if i == over then
            local sequece =
                cc.Sequence:create(
                {
                    action0,
                    cc.CallFunc:create(
                        function()
                            self:registerReelSchedule()
                        end
                    )
                }
            )
            symbolNode:runAction(sequece)
        else
            symbolNode:runAction(action0)
        end
    end
end
--滚轴停止回弹
function CodeGameScreenBuzzingHoneyBeeMachine:reelSchedulerCheckColumnReelDown(parentData)
    local  slotParent = parentData.slotParent
    if parentData.isDone ~= true then
        parentData.isDone = true
        slotParent:stopAllActions()
        
        self:slotOneReelDown(parentData.cloumnIndex)
        
        local quickStopY = -35 --快停回弹距离
        if self.m_quickStopBackDistance then
            quickStopY = -self.m_quickStopBackDistance
        end
        -- local quickStopY = -self.m_configData.p_reelResDis --不读取配置
        local backTotalTotalTime = 0
        local symbolNodeList,start,over = self.m_reels[parentData.cloumnIndex].m_gridList:getList()
        for i = start,over do
            local allActionTime = 0
            local symbolNode = symbolNodeList[i]
            local speedActionTable = {}
            if self.m_isNewReelQuickStop then
                local originalPos = cc.p(symbolNode:getPosition())
                symbolNode:setPositionY(symbolNode:getPositionY() + quickStopY)

                local moveTime = self.m_configData.p_reelResTime
                if self:getGameSpinStage() == QUICK_RUN then
                    moveTime = 0.3
                end
                local back = cc.MoveTo:create(moveTime, originalPos)
                table.insert(speedActionTable,back)
                allActionTime = allActionTime + moveTime
            else
                local originalPos = cc.p(symbolNode:getPosition())
                local dis = self.m_configData.p_reelResDis
                local speedStart = parentData.moveSpeed
                local preSpeed = speedStart / 118
                local timeDown = self.m_configData.p_reelResTime
                if self:getGameSpinStage() ~= QUICK_RUN then
                    for i = 1, 10 do
                        speedStart = speedStart - preSpeed * (11 - i) * 2
                        local moveDis = dis / 10
                        local time = moveDis / speedStart
                        timeDown = timeDown + time
                        local moveBy = cc.MoveBy:create(time, cc.p(slotParent:getPositionX(), -moveDis))
                        table.insert(speedActionTable,moveBy)
                        allActionTime = allActionTime + time
                    end
                end

                local back = cc.MoveTo:create(timeDown, originalPos)
                table.insert(speedActionTable,back)
                allActionTime = allActionTime + timeDown
            end
        
            if i == over then
                local childTab = slotParent:getChildren()
                local tipSlotNoes = nil
                --添加提示节点
                tipSlotNoes = self:addReelDownTipNode(childTab)

                if tipSlotNoes ~= nil then
                    local nodeParent = parentData.slotParent
                    for i = 1, #tipSlotNoes do
                        --播放提示动画
                        self:playReelDownTipNode(tipSlotNoes[i])
                    end
                end
    
                self:playQuickStopBulingSymbolSound(parentData.cloumnIndex)

                local actionFinishCallFunc = cc.CallFunc:create(
                function()
                    parentData.isResActionDone = true
                    if self.m_quickStopReelIndex and self.m_quickStopReelIndex == parentData.cloumnIndex then
                        self:newQuickStopReel(self.m_quickStopReelIndex)
                    end
                    self:slotOneReelDownFinishCallFunc(parentData.cloumnIndex)
                end)

                speedActionTable[#speedActionTable + 1] = actionFinishCallFunc

                symbolNode:runAction(cc.Sequence:create(speedActionTable))
            else
                symbolNode:runAction(cc.Sequence:create(speedActionTable))
            end

            if backTotalTotalTime < allActionTime then
                backTotalTotalTime = allActionTime
            end
        end
        self:reelStopHideMask(backTotalTotalTime,parentData.cloumnIndex)
    end
    return 0.1
end

-- 重置当前背景音乐名称
function CodeGameScreenBuzzingHoneyBeeMachine:resetCurBgMusicName()
    if self.m_enterGameMusicIsComplete == false then
        return nil
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_runSpinResultData.p_fsExtraData and self.m_runSpinResultData.p_fsExtraData.superLocks then
            self.m_currentMusicBgName = "BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_FreespinSuperBG.mp3"
        end
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end
--初始化的 scatter图标变为普通图标
function CodeGameScreenBuzzingHoneyBeeMachine:randomSlotNodesByReel()
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex=1,resultLen do
            
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolType = self:getNormalType()
            end
            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = reelColData.p_showGridH      
            
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) -rowIndex
           
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * reelColData.p_showGridH + halfNodeH )

        end
    end
    self:initGridList()
end

--初始化的 scatter图标变为普通图标
function CodeGameScreenBuzzingHoneyBeeMachine:randomSlotNodes()
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex=1,rowCount do
            local symbolType = self:getRandomReelType(colIndex,reelDatas)
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolType = self:getNormalType()
            end
            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex , reelDatas   )

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex,reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = columnData.p_showGridH      
           
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex
           

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end
            
--            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )

           
        end
    end
    self:initGridList()
end
function CodeGameScreenBuzzingHoneyBeeMachine:getNormalType()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1,
        self.SYMBOL_SCORE_10,
        self.SYMBOL_SCORE_11
    }
    return symbolList[math.random(1,#symbolList)]
end

--新快停逻辑
function CodeGameScreenBuzzingHoneyBeeMachine:newQuickStopReel(index)
    CodeGameScreenBuzzingHoneyBeeMachine.super.newQuickStopReel(self,index)
    --隐藏所有H1图标的拖尾
    for col = 1,self.m_iReelColumnNum do
        local symbolNodeList,start,over = self.m_reels[col].m_gridList:getList()
        for i = start,over do
            local symbolNode = symbolNodeList[i]
            if symbolNode.m_trailingNode then
                symbolNode.m_trailingNode:setVisible(false)
            end
        end
    end
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenBuzzingHoneyBeeMachine:changeToMaskLayerSlotNode(slotNode)

    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    -- if nodeParent == self.m_clipParent then
    --     slotNode.p_showOrder = self:getClipParentChildShowOrder(slotNode)
    -- else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    -- end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX,slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    -- 切换图层
   -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    -- util_changeNodeParent(self.m_clipParent,slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    -- if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
    --     printInfo("xcyy : %s","slotNode p_rowIndex  p_cloumnIndex isnil")
    -- end

    util_changeNodeParent(self.m_clipParent,slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10)

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenBuzzingHoneyBeeMachine:checkFeatureOverTriggerBigWin( winAmonut , feature)
    if winAmonut == nil then
        return
    end

    --插入规避逻辑
    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = self.m_avgBet
    if lTatolBetNum == nil then
        lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    end

    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i=1,#self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert( self.m_gameEffects, i + 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, i + 2, effectData )
                break
            end
        end
        if isAddEffect == false then
            for i=1,#self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut


                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert( self.m_gameEffects, i + 1, delayEffect )

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert( self.m_gameEffects, i + 2, effectData )
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert( self.m_gameEffects, 1, delayEffect )

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert( self.m_gameEffects, 2, effectData )
            end
        end

    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
end
-- 增加赢钱后的 效果
function CodeGameScreenBuzzingHoneyBeeMachine:addLastWinSomeEffect() -- add big win or mega win

    local notAddEffect = self:checkIsAddLastWinSomeEffect( )

    if  notAddEffect then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = self.m_avgBet
    if lTatolBetNum == nil then
        lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    end
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值


    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    local curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢

        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)

    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or
            self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or
            self.m_fLastWinBetNumRatio < 1
    then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

end
--快停时处理随机添加的锁定框
function CodeGameScreenBuzzingHoneyBeeMachine:quicklyStopAddRandomLockFrame()
    --有随机锁定框数据的话开始走逻辑
    if self.m_runSpinResultData.p_selfMakeData.randomAddLocks and #self.m_runSpinResultData.p_selfMakeData.randomAddLocks > 0 then
        --如果已经开始飞粒子，则删掉粒子
        self:removeFlyLizi()
        if self.m_addRandLockFrameState < 2 then
            --直接添加锁定框
            for i,posData in ipairs(self.m_runSpinResultData.p_selfMakeData.randomAddLocks) do
                local rowcolData = self:getRowAndColByPos(posData)
                self:addOneLockFrame(rowcolData.iY,rowcolData.iX,false,self.LockFrameType.Normal)
            end
            self:updateAllLockFrameLRShow()
        end
        --小蜜蜂回到原位去
        self:beePlayAction("idleframe")
        --声音停止
        if self.m_randomAddLocksSoundId then
            gLobalSoundManager:stopAudio(self.m_randomAddLocksSoundId)
            self.m_randomAddLocksSoundId = nil
        end
    end
end
--快停时处理freespin下的转盘
function CodeGameScreenBuzzingHoneyBeeMachine:quicklyStopWheelStop()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalNoticManager:postNotification("BuzzingHoneyBeeWheelView_quicklyStop")
    end
end
--删除出随机锁定框飞行的粒子
function CodeGameScreenBuzzingHoneyBeeMachine:removeFlyLizi()
    if self.m_liziNodeTab and #self.m_liziNodeTab > 0 then
        for i,flyLizi in ipairs(self.m_liziNodeTab) do
            flyLizi:removeFromParent()
        end
        self.m_liziNodeTab = {}
    end
end
--快停时处理H1变锁定框的动画
function CodeGameScreenBuzzingHoneyBeeMachine:quicklyStopH1ChangeStop()
    self:removeAllH1ChangeNode()
    if self.m_h1AddLocks then
        for i,pos in ipairs(self.m_h1AddLocks) do
            local rowColData = self:getRowAndColByPos(pos)
            self:addOneLockFrame(rowColData.iY,rowColData.iX,false,self.LockFrameType.Normal)
        end
        self:updateAllLockFrameLRShow()
    end
end
--删除所有变锁定框的H1动画
function CodeGameScreenBuzzingHoneyBeeMachine:removeAllH1ChangeNode()
    for i,H1Node in ipairs(self.m_changeToLockFrameH1Node) do
        H1Node:removeFromParent()
    end
    self.m_changeToLockFrameH1Node = {}
end
--所有的锁定框播idle动画
function CodeGameScreenBuzzingHoneyBeeMachine:allLockFramePlayIdle()
    for i,lockFrame in ipairs(self.m_lockFrameTab) do
        lockFrame:playAction("idleframe")
    end
end

function CodeGameScreenBuzzingHoneyBeeMachine:compareScatterWinLines(winLines)

    local scatterLines = {}
    local winAmountIndex = -1
    for i=1,#winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.p_iconPos
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        for posIndex=1,#iconsPos do
            local posData = iconsPos[posIndex]
            
            local rowColData = self:getRowAndColByPos(posData)
            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                if winLineData.p_type ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
                end
            end
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break  -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            scatterLines[#scatterLines + 1] = {i,winLineData.p_amount}
            if winLineData.p_amount > 0 then
                winAmountIndex = i
            end
        end
    end


    if #scatterLines > 0 and winAmountIndex > 0 then
        for i=#scatterLines,1,-1 do
            local lineData = scatterLines[i]
            if lineData[2] == 0 then
                table.remove(winLines,lineData[1])
            end
        end
    end


end
--[[
    @desc: 计算单线
    time:2018-08-16 19:35:49
    --@lineData: 
    @return:
]]
function CodeGameScreenBuzzingHoneyBeeMachine:getWinLineSymboltType(winLineData,lineInfo )
    local iconsPos = winLineData.p_iconPos
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex=1,#iconsPos do
        local posData = iconsPos[posIndex]
        
        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData  -- 连线元素的 pos信息
            
        local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            if winLineData.p_type ~= TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
            end
        end
        if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            enumSymbolType = symbolType
        end
    end
    return enumSymbolType
end

function CodeGameScreenBuzzingHoneyBeeMachine:showJackpotWinEffect()
   
    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_wildWin.mp3")
    self:findChild("REEL"):setLocalZOrder(1000)
    self:findChild("Jackpotwin"):setLocalZOrder(800)

    local grandEff = util_createAnimation("BuzzingHoneyBee/GameScreenBuzzingHoneyBee_jackpotwin.csb")
    local worldPos = self:findChild("Jackpotwin"):getParent():convertToWorldSpace(cc.p(self:findChild("Jackpotwin"):getPosition()))
    local pos = self:convertToNodeSpace(worldPos)
    self:addChild(grandEff,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 3)
    grandEff:setPosition(pos)
    grandEff:setScale(self.m_machineRootScale)--适配

    local grandEffPanel = util_createAnimation("BuzzingHoneyBee/GameScreenBuzzingHoneyBee_jackpotwinPanel.csb")
    self:findChild("Jackpotwin"):addChild(grandEffPanel)


    grandEffPanel:runCsbAction("grand",false)
    grandEff:runCsbAction("grand",false,function ()
        grandEff:removeFromParent()
        grandEffPanel:removeFromParent()
        self:beePlayAction("tanban1",function ()
            self:showJackpotWin()
        end)
    end)  
end

function CodeGameScreenBuzzingHoneyBeeMachine:showJackpotWin()
    self:setMinMusicBGVolume()
    gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_jackpot_start.mp3")
    local jackPotWinView = util_createView("CodeBuzzingHoneyBeeSrc.BuzzingHoneyBeeJackPotWin")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end

    local  coins =  0
    if  self.m_runSpinResultData.p_selfMakeData.grandWinCoins then
        coins = self.m_runSpinResultData.p_selfMakeData.grandWinCoins
    end
   
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(self,coins, function()
        self:resetAllZorder()
        self:notifyGameEffectPlayComplete({GameEffect.EFFECT_SELF_EFFECT,self.WIN_GRAND_EFFECT})
        self:beePlayAction("idleframe")
    end)
end

function CodeGameScreenBuzzingHoneyBeeMachine:resetAllZorder()
   for i=1,#self.m_ReelZorderNode do
        local nodeName = self.m_ReelZorderNode[i]
        local node = self:findChild(nodeName)
        node:setLocalZOrder(i*10)
   end 
end

function CodeGameScreenBuzzingHoneyBeeMachine:betChangeNotify( isLevelUp )
    if isLevelUp then
    else
        self:clearWinLineEffect()
        -- 切换bet修改锁定框
        self:removeAllWildNode()
        self:removeAllLockFrame()
        self:updateAllLockFrame()
    end
end

--[[
    延迟回调
]]
function CodeGameScreenBuzzingHoneyBeeMachine:delayCallBack(time, func)
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
return CodeGameScreenBuzzingHoneyBeeMachine