---
-- island li
-- 2019年1月26日
-- CodeGameScreenManicMonsterMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenManicMonsterMachine = class("CodeGameScreenManicMonsterMachine", BaseNewReelMachine)

CodeGameScreenManicMonsterMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenManicMonsterMachine.SYMBOL_BONUS_NORMAL = 94 -- bonus
CodeGameScreenManicMonsterMachine.SYMBOL_BONUS_JACKPOT = 95 -- bonusJackPot
CodeGameScreenManicMonsterMachine.SYMBOL_SCATTER_ADDTIMES = 96 -- scatter + 1

CodeGameScreenManicMonsterMachine.SPREAD_ACTION_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50 -- wild扩散玩法
CodeGameScreenManicMonsterMachine.ADD_FREE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 90 -- 添加freespin次数
CodeGameScreenManicMonsterMachine.DEALT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 99 -- 等待事件第一个执行

CodeGameScreenManicMonsterMachine.m_BubbleNodeList = {} -- 存储所有泡泡node
CodeGameScreenManicMonsterMachine.m_smallLockType = 0 -- 小泡泡
CodeGameScreenManicMonsterMachine.m_bigLockType = 1 -- 大泡泡
CodeGameScreenManicMonsterMachine.m_spreadSmallLockType = 3 -- 扩散的小泡泡

CodeGameScreenManicMonsterMachine.m_BubblelineSlotNodes = {} -- 参与连线的泡泡
CodeGameScreenManicMonsterMachine.m_localBubbleEffectList = {} -- 存储的泡泡动画事件
CodeGameScreenManicMonsterMachine.m_playedBubbleEffectIndex = 0 -- 当前已播放的泡泡动画事件数量
CodeGameScreenManicMonsterMachine.TOP_CREATE_BUBBLE_EFFECT = 1 -- 随机创建气泡（轮盘）
CodeGameScreenManicMonsterMachine.BOTTOM_CREATE_BUBBLE_EFFECT = 2 -- 底部创建气泡（底部）

CodeGameScreenManicMonsterMachine.m_BubbleNodeMoveEnd = false -- 泡泡移动是否结束
CodeGameScreenManicMonsterMachine.PLAY_BUBBLE_END_EFFECT = 100 -- 播放泡泡动画事件结束

CodeGameScreenManicMonsterMachine.m_baseWildData = {} -- 存储的所有bet的数据


-- 构造函数
function CodeGameScreenManicMonsterMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_slotsAnimNodeFps = 30
    self.m_lineFrameNodeFps = 60 
    self.m_baseDialogViewFps = 60


    self.m_BubbleNodeList = {}
    self.m_BubblelineSlotNodes = {} -- 参与连线的泡泡

    self.m_ManicMonsterLayer = nil

    self.m_spinRestMusicBG = true

    self.m_baseWildData = {} -- 存储的所有bet的数据

    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenManicMonsterMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenManicMonsterMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ManicMonster"  
end


function CodeGameScreenManicMonsterMachine:showColorLayer( )
    for i=1,5 do

        self["m_colorLayer_waitNode_"..i]:stopAllActions()

        local layerNode = self["colorLayer_"..i]

        util_playFadeInAction(layerNode,0.1)
        layerNode:setVisible(true)
    end
end

function CodeGameScreenManicMonsterMachine:hideColorLayer( )
    for i=1,5 do
        self["m_colorLayer_waitNode_"..i]:stopAllActions()

        local layerNode = self["colorLayer_"..i]
        util_playFadeOutAction(layerNode,0.1)
        layerNode:setVisible(true)
        performWithDelay(self["m_colorLayer_waitNode_"..i] ,function(  )
            layerNode:setVisible(false)
        end,0.1)
    end
end

function CodeGameScreenManicMonsterMachine:initMachineUI( )
    
    BaseNewReelMachine.initMachineUI( self )

    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for i =1 ,#self.m_slotParents do
        local parentData = self.m_slotParents[i]
        
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

        local node = cc.Node:create()
        parentData.slotParent:getParent():addChild(node,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)

        local slotParentNode_1 = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
        slotParentNode_1:setOpacity(200)
        slotParentNode_1:setContentSize(reelSize.width, reelSize.height)
        slotParentNode_1:setPositionX(reelSize.width * 0.5)
        node:addChild(slotParentNode_1,REEL_SYMBOL_ORDER.REEL_ORDER_4 + 100)

        self["colorLayer_"..i] = node
        node:setVisible(false)

    end

    self.m_ManicMonsterLayer = cc.Layer:create() 
    self.m_ManicMonsterLayer:setContentSize(cc.size(slotW, slotH))
    self.m_ManicMonsterLayer:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_ManicMonsterLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
    self.m_clipParent:addChild(self.m_ManicMonsterLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + REEL_SYMBOL_ORDER.REEL_ORDER_3 + 9) -- 在气泡的下一层


end

function CodeGameScreenManicMonsterMachine:initUI()

    self.m_reelRunSound = "ManicMonsterSounds/ManicMonsterSounds_longRun.mp3"

    self:findChild("Node_mask"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + REEL_SYMBOL_ORDER.REEL_ORDER_3 + 11)

    self:runCsbAction("idle")

   
    for i=1,5 do
        self["m_colorLayer_waitNode_"..i] = cc.Node:create()
        self:addChild(self["m_colorLayer_waitNode_"..i])
    end
    

    self:hideColorLayer( )

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_gameBg:findChild("FreespinBG"):setVisible(false)
    self.m_gameBg:findChild("NormalBG"):setVisible(true)

    

    self:findChild("Node_Bubble"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + REEL_SYMBOL_ORDER.REEL_ORDER_3 + 10)
    self:findChild("ManicMonster_FreeSpins_biaoti"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + REEL_SYMBOL_ORDER.REEL_ORDER_3 + 11)

    --添加jackpot条
    self.m_jackpotBar = util_createView("CodeManicMonsterSrc.ManicMonsterJackPotBarView")
    self:findChild("ManicMonster_jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)

    self.m_normalMan = util_spineCreate("ManicMonster_juese",true,true)
    self:findChild("ManicMonster_base"):addChild(self.m_normalMan)
    self.m_normalMan:setPositionY(-200)
    util_spinePlay(self.m_normalMan,"idleframe",true)
    

    self.m_freeSpinMan = util_spineCreate("ManicMonster_Freespin_juese",true,true)
    self:findChild("ManicMonster_free"):addChild(self.m_freeSpinMan)
    self.m_freeSpinMan:setPositionY(-100)
    
    self.m_freeSpinMan:setVisible(false)

 
    self.m_jackpotGameView = util_createView("CodeManicMonsterSrc.ManicMonsterJackpotGameMainView",self) 
    self:findChild("Node_Bonus"):addChild(self.m_jackpotGameView)
    self.m_jackpotGameView:setPosition(-display.width/2,-display.height / 2 )
    self.m_jackpotGameView:setVisible(false)

    for i=1,5 do
        self["m_fasheqi_"..i] = util_createAnimation("ManicMonster_fasheqi.csb") 
        self:findChild("ManicMonster_fasheqi_"..i):addChild(self["m_fasheqi_"..i])
        self["m_fasheqi_"..i]:runCsbAction("idleframe2",true)

    end



    self.m_GuoChang = util_createAnimation("ManicMonster_GuoChang.csb") 
    self:addChild(self.m_GuoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_GuoChang:setPosition(display.width/2,display.height/2 + 45)
    self.m_GuoChang:setVisible(false)
    self.m_GuoChang:setScale(self.m_machineRootScale)



    -- 创建view节点方式
    -- self.m_ManicMonsterView = util_createView("CodeManicMonsterSrc.ManicMonsterView")
    -- self:findChild("xxxx"):addChild(self.m_ManicMonsterView)
   
 
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end


        if self.m_bIsBigWin then
            return
        end

        self:stopLinesWinSound( )

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 4
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "ManicMonsterSounds/music_ManicMonster_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

 

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenManicMonsterMachine:showFreeSpinBarBuling( func )
    

    self.m_baseFreeSpinBar.m_act:setVisible(true)
    self.m_baseFreeSpinBar.m_actBg:setVisible(true)

    self.m_baseFreeSpinBar.m_act:runCsbAction("animation0",false)
    self.m_baseFreeSpinBar.m_actBg:runCsbAction("animation0",false)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        self.m_baseFreeSpinBar.m_act:setVisible(false)
        self.m_baseFreeSpinBar.m_actBg:setVisible(false)
        if func then
            func()
        end
    end,0.8)
end

function CodeGameScreenManicMonsterMachine:initFreeSpinBar()
    local node_bar = self.m_bottomUI:findChild("node_bar")
    self.m_baseFreeSpinBar = util_createView("Levels.FreeSpinBar")
    node_bar:addChild(self.m_baseFreeSpinBar)
    local pos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,node_bar)
    self.m_baseFreeSpinBar:setPosition(cc.p(pos.x,73))
    self.m_baseFreeSpinBar:setScale(0.8)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)

    self.m_baseFreeSpinBar.m_actBg = util_createAnimation("ManicMonster_freespin_bgL.csb")
    self.m_baseFreeSpinBar:findChild("m_lb_num"):getParent():addChild(self.m_baseFreeSpinBar.m_actBg,-1)
    self.m_baseFreeSpinBar.m_actBg:setPosition(0, 40)
    self.m_baseFreeSpinBar.m_actBg:setVisible(false)

    self.m_baseFreeSpinBar.m_act = util_createAnimation("ManicMonster_freespin_dian.csb")
    self.m_baseFreeSpinBar:findChild("m_lb_num"):getParent():addChild(self.m_baseFreeSpinBar.m_act,10)
    self.m_baseFreeSpinBar.m_act:setPosition(0, 40)
    self.m_baseFreeSpinBar.m_act:setVisible(false)


   
   
end

function CodeGameScreenManicMonsterMachine:scaleMainLayer()
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

        mainScale = display.height / (self:getReelHeight() + uiH + uiBH)
        if display.height > DESIGN_SIZE.height then
            mainScale = DESIGN_SIZE.height / (self:getReelHeight() + uiH + uiBH)
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + 45 )
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

end

function CodeGameScreenManicMonsterMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound( "ManicMonsterSounds/music_ManicMonster_enter.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenManicMonsterMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    
    self:addObservers()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local lockedBubble = selfdata.wildPos  -- base已经固定的泡泡
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        lockedBubble = selfdata.freeWildPos  -- Free已经固定的泡泡

        util_spinePlay(self.m_freeSpinMan,"idleframe",true)

    else
        local currTotalBet = globalData.slotRunData:getCurTotalBet()
        lockedBubble = self.m_baseWildData[tostring(currTotalBet)]  -- base已经固定的泡泡
    end

    self:createBaseAllBubbleNode(lockedBubble)

    self:changefaSheQIStates()
end

function CodeGameScreenManicMonsterMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
   
        self:changeBetCreateBubbleNode( )

    end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenManicMonsterMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


function CodeGameScreenManicMonsterMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)
    gameBg:setPosition(-display.width/2,-display.height / 2)

    self.m_gameBg = gameBg

    self.m_gameBg.m_GuoDao = util_createAnimation("ManicMonster_guandao.csb")
    gameBg:findChild("beijin_guandao"):addChild(self.m_gameBg.m_GuoDao)
    self.m_gameBg.m_GuoDao:runCsbAction("animation0",true)
    

    
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenManicMonsterMachine:MachineRule_GetSelfCCBName(symbolType)



    if symbolType == self.SYMBOL_BONUS_NORMAL then
        return "Socre_ManicMonster_Bonus"
    elseif symbolType == self.SYMBOL_BONUS_JACKPOT then
        return "Socre_ManicMonster_Jackpot"
    elseif symbolType == self.SYMBOL_SCATTER_ADDTIMES then
        return "Socre_ManicMonster_Scatter_1"
    end
    
    return nil
end


----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenManicMonsterMachine:checkInitSpinWithEnterLevel( )

    if self.m_initFeatureData then
        if self.m_initFeatureData.p_status == "CLOSED" then
            self.m_initFeatureData = nil
        end
    end
    

    local isTriggerEffect,isPlayGameEffect = BaseNewReelMachine.checkInitSpinWithEnterLevel( self)

    return isTriggerEffect,isPlayGameEffect
end

-- 断线重连 
function CodeGameScreenManicMonsterMachine:MachineRule_initGame(  )
    --Free模式
    if self.m_bProduceSlots_InFreeSpin then
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
    end
end

function CodeGameScreenManicMonsterMachine:slotReelDown( )

    
    self:setLowScatterBonusJpZOrder()

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    BaseNewReelMachine.slotReelDown(self)
end

--
--单列滚动停止回调
--
function CodeGameScreenManicMonsterMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
    
    if reelCol == 2 then
        self:hideColorLayer( )
    end
    
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenManicMonsterMachine:levelFreeSpinEffectChange()

    self.m_normalMan:setVisible(false)
    self.m_freeSpinMan:setVisible(true)
    self.m_gameBg:runCsbAction("idle3",true)
    self.m_gameBg:findChild("FreespinBG"):setVisible(true)
    self.m_gameBg:findChild("NormalBG"):setVisible(false)

end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenManicMonsterMachine:levelFreeSpinOverChangeEffect()
    
    self.m_normalMan:setVisible(true)
    self.m_freeSpinMan:setVisible(false)
    
    self.m_gameBg:runCsbAction("idle")
    self.m_gameBg:findChild("FreespinBG"):setVisible(false)
    self.m_gameBg:findChild("NormalBG"):setVisible(true)

end
---------------------------------------------------------------------------


----------- FreeSpin相关

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenManicMonsterMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode==nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        if slotNode==nil then
            slotNode = self:getFixSymbol(symPosData.iY , symPosData.iX, SYMBOL_NODE_TAG)
        end
        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and
            self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then

            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do

                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex=1,#bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then

                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode==nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end

            end
        end


        if slotNode == nil  then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
        end
        

        if slotNode ~= nil then--这里有空的没有管
            slotNode = self:setSymbolToClipReel(slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)

            slotNode:runAnim("actionframe")

            animTime = 2
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenManicMonsterMachine:showEffect_FreeSpin(effectData)
    self:removeAllSpreadBubbleNode()
    
    gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_FreeSpinBegin_GuoChangt.mp3")
    
    
    return BaseNewReelMachine.showEffect_FreeSpin(self,effectData)
end
-- FreeSpinstart
function CodeGameScreenManicMonsterMachine:showFreeSpinView(effectData)


    local showFSView = function ( ... )

        

        self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()       
        end)

    end


    self:fsStartBaseGuoChang(function(  )


        local fsWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
        self.m_bottomUI:resetWinLabel()
        if fsWinCoins > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoins))
        else
            self.m_bottomUI:updateWinCount("")
        end

        

        -- 清除所有泡泡
        self:removeAllBubbleNode(  )
        -- 创建 FreeSpin 泡泡
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local lockedBubble = selfdata.freeWildPos  -- Freespin已经固定的泡泡
        self:createBaseAllBubbleNode(lockedBubble)

        self:levelFreeSpinEffectChange()

        self:changefaSheQIStates()
        
        self:freeOverRestBonusNormal()
        

        self:freeSpinStartFsGuoChang( function(  )
            showFSView()  
        end  )

        
       

    end)


    

end

function CodeGameScreenManicMonsterMachine:freeOverRestBonusNormal( )
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local symbolType =  targSp.p_symbolType
            if symbolType == self.SYMBOL_BONUS_NORMAL then
                targSp:runAnim("idleframe",true)
               
            end
        end

    end
end

function CodeGameScreenManicMonsterMachine:showFreeSpinOverView()


    gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_FreeSpinEnd.mp3")

    performWithDelay(self,function(  )
        
        self:freeSpinOverGuoChang( function(  )

            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_FreeSpinOver_View.mp3")
            
            local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
            local view = self:showFreeSpinOver( strCoins,
                self.m_runSpinResultData.p_freeSpinsTotalCount,function()
    
                    self:showGuoChang( function(  )
       
                        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
                        -- 取消掉赢钱线的显示
                        self:clearWinLineEffect()
                        -- 清除所有泡泡
                        self:removeAllBubbleNode(  )
                        -- 还原 base 泡泡
                        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                        local lockedBubble = selfdata.wildPos  -- base已经固定的泡泡
                        self:createBaseAllBubbleNode(lockedBubble)
                
                        self:levelFreeSpinOverChangeEffect()
                        self:hideFreeSpinBar()
                
                        self:changefaSheQIStates()
            
                        util_spinePlay(self.m_normalMan,"idleframe",true)
                        self:runCsbAction("idle")
            
                        self:freeOverRestBonusNormal()
                
                    end,function(  )
                      
                        self:triggerFreeSpinOverCallFun()
            
                    end )
    
            end)
            local node=view:findChild("m_lb_coins")
            view:updateLabelSize({label=node,sx=0.8,sy=0.8},1155)
    
        end )
    end,2)


    

    

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenManicMonsterMachine:MachineRule_SpinBtnCall()


    self:stopLinesWinSound( )
    
    self:setMaxMusicBGVolume()
   
    

    self:removeAllExceedBubbleNode(  )
    self:removeAllSpreadBubbleNode( )
    self:restAllBubbleNodeZorder( )
    self:compareNetData( )

    self.m_BubbleNodeMoveEnd = false


    return false -- 用作延时点击spin调用
end

function CodeGameScreenManicMonsterMachine:beginReel()
    self:showColorLayer( )
    CodeGameScreenManicMonsterMachine.super.beginReel(self)
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenManicMonsterMachine:addSelfEffect()

        
    -- 加的等待事件
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.DEALT_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.DEALT_EFFECT -- 动画类型

    -- 泡泡扩散
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusWilds = selfdata.bonusWilds or {} -- Bonus位置 
    local extendPos = selfdata.extendPos or {} -- Spread扩散位置
    if #bonusWilds > 0 then
        
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.SPREAD_ACTION_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SPREAD_ACTION_EFFECT -- 动画类型
    end
    
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        -- 添加freeSpin次数
        local tarzanCount = self:getSymbolCountWithReelResult(self.SYMBOL_SCATTER_ADDTIMES)
        if tarzanCount > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.ADD_FREE_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.ADD_FREE_EFFECT
        end
    end


end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenManicMonsterMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.DEALT_EFFECT then

        if self.m_BubbleNodeMoveEnd then
            self:changeEffectToPlayed(self.DEALT_EFFECT )
        end
    elseif effectData.p_selfEffectType == self.SPREAD_ACTION_EFFECT then

        self:createBonusSpreadAction()

    elseif  effectData.p_selfEffectType == self.ADD_FREE_EFFECT then 
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )


            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_fs_Scatter_Trigger.mp3")

            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    local symbolType =  targSp.p_symbolType
                    if symbolType == self.SYMBOL_SCATTER_ADDTIMES then
                        targSp:runAnim("actionframe")
                        targSp:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + REEL_SYMBOL_ORDER.REEL_ORDER_3 + 100 - targSp.p_rowIndex)
                        local endNode = self.m_baseFreeSpinBar:findChild("m_lb_num")
                        local flyNode = self:runCollectTopBubbleNode(1.5,0,targSp,endNode)
                        flyNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                        
                    end
                end

            end

            performWithDelay(waitNode,function( )
                
                self:showFreeSpinBarBuling( )

                performWithDelay(waitNode,function(  )

                    for iCol = 1, self.m_iReelColumnNum do
                        for iRow = 1, self.m_iReelRowNum do
                            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                            local symbolType =  targSp.p_symbolType
                            if symbolType == self.SYMBOL_SCATTER_ADDTIMES then
                                targSp:setLocalZOrder(targSp.m_showOrder)
                            end
                        end
                
                    end
                    
                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    
                    performWithDelay(waitNode,function(  )
                        waitNode:removeFromParent()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,1)
    
                end,0.1)

            end,1.5)
            

           

        end,1)

                
               

    end

    
	return true
end

function CodeGameScreenManicMonsterMachine:changeEffectToPlayed(selfEffectType )
    for i=1,#self.m_gameEffects do
        local  effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType == selfEffectType then
            if effectData.p_isPlay == false then
                effectData.p_isPlay = true
                self:playGameEffect()
                break
            end
            
            
        end
    end
end

function CodeGameScreenManicMonsterMachine:showBonusOverView( coins, jpType ,func )
    
    gLobalSoundManager:playSound("ManicMonsterSounds/sound_ManicMonster_JackpotView.mp3")

    local jackPotWinView = util_createView("CodeManicMonsterSrc.ManicMonsterJackpotWinView", self)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)

    local curCallFunc = function(  )

        if func then
            func()
        end

    end

    jackPotWinView:initViewData(jpType,coins,curCallFunc)

   
    
end

-- 更新控制类数据
function CodeGameScreenManicMonsterMachine:SpinResultParseResultData( spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)

    self:updateAllTopWildData()
end

---
--设置bonus scatter 层级
function CodeGameScreenManicMonsterMachine:getBounsScatterDataZorder(symbolType )

    if symbolType == self.SYMBOL_BONUS_NORMAL then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == self.SYMBOL_BONUS_JACKPOT then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + 1

    elseif symbolType == self.SYMBOL_SCATTER_ADDTIMES then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_2 
    end

   return BaseNewReelMachine.getBounsScatterDataZorder(self,symbolType )

end

---
-- 根据Bonus Game 每关做的处理
--
---
-- 显示bonus 触发的小游戏
function CodeGameScreenManicMonsterMachine:showEffect_Bonus(effectData)



    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    local waitTime = 0
    local winLines = self.m_runSpinResultData.p_winLines or {}
    if #winLines > 0 then
        waitTime = self.m_changeLineFrameTime
    end


    -- 这里只删除freespin的线 ，因为bonus没有线，这里删除是为了处理bonusfreespin同时触发的问题
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            -- bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        waitNode:removeFromParent()

        self:stopLinesWinSound( )

        self:removeAllSpreadBubbleNode()

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
    
        
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
    
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    end,waitTime)


    return true
end

function CodeGameScreenManicMonsterMachine:showJackpotGameView( func )
    self.m_gameBg:runCsbAction("idle2",true)

    self.m_jackpotGameView.m_startAction = true

    self:showGuoChang( function(  )

        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:updateWinCount("")
        
        self.m_jackpotBar:hidAllJpDian( )
        self.m_jackpotBar:hidAllJpBan( )
        self.m_jackpotBar:runCsbAction("idle1")

        self:findChild("Node_Normal"):setVisible(false)
    
        self.m_jackpotGameView:setVisible(true)
        self.m_jackpotGameView:restJackpotGameShowUI(  )
    
        self.m_jackpotGameView:setEndCall( function(  )

           
            self:showGuoChang( function(  )

                self.m_gameBg:runCsbAction("idle")
                self.m_jackpotGameView:setVisible(false)
                self:findChild("Node_Normal"):setVisible(true)
                self.m_jackpotBar:runCsbAction("idle2")

                if self:getCurrSpinMode() == FREE_SPIN_MODE then

                    util_spinePlay(self.m_freeSpinMan,"idleframe",true)
                    self:runCsbAction("idle3")
                else
                    util_spinePlay(self.m_normalMan,"idleframe",true)
                    self:runCsbAction("idle")
                end
                
                if func then
                    func()
                end
               
            end)

        end)
    end,function(  )
        self.m_gameBg:runCsbAction("idle3",true)

        self:resetMusicBg(nil,"ManicMonsterSounds/music_ManicMonster_jP_bg.mp3")

        gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_JpGame_startView.mp3")

        

        self.m_jackpotGameView:showBonusStartView(function(  )

            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_Bonus_StartAction.mp3")

            self.m_jackpotGameView:showStartAction()


        end )
        
        self.m_jackpotGameView.m_action = self.m_jackpotGameView.ACTION_NONE
        self.m_jackpotGameView:sendStartGame()

    end )
end

function CodeGameScreenManicMonsterMachine:isInLockedBubble( index , isLines )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local lockedBubble = selfdata.wildPos  -- base已经固定的泡泡
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        lockedBubble =  selfdata.freeWildPos -- Free已经固定的泡泡
    end
    local bonusWilds = selfdata.bonusWilds or {} -- Bonus位置 
    local extendPos = selfdata.extendPos or {}  -- Spread扩散位置

    local currTable = nil

    if isLines then
        -- 如果是连线的话需要优先考虑Spread扩散位置
        for i=1,#extendPos do
            local BubblePos = extendPos[i]
            
            for j = 1,#BubblePos do
                
                if BubblePos[j] == index then

                    currTable = {}
                    table.insert( currTable, BubblePos[j]) -- Spread扩散位置都是小泡泡

                    return true , currTable
                end
            end
    
        end

    end

    

    for i=1,#lockedBubble do
        local BubblePos = lockedBubble[i]
        currTable = BubblePos
        for j = 1,#BubblePos do
            
            if BubblePos[j] == index then
                return true , currTable
            end
        end

    end

    

    return false
end

function CodeGameScreenManicMonsterMachine:getCurrBonusAndBubbleNode( )
   
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local symbolType =  targSp.p_symbolType
            if symbolType == self.SYMBOL_BONUS_JACKPOT then
                local index = self:getPosReelIdx(iRow , iCol)
                local isin , posList = self:isInLockedBubble(index) 
                if isin then
                    
                    local currIndex = nil
                    if #posList > 1  then

                        table.sort( posList)
                        
                        if #posList == 2 then
                            currIndex = posList[1]
                        else
                            currIndex = posList[3] -- 大泡泡参考点为左下位置
                        end
                        
                    else
                        currIndex = posList[1]
                    end
                    local tarBubble = self:getOneBubbleNode( currIndex )

                    return targSp , tarBubble

                end

                
            end
        end
    end
    
end

function CodeGameScreenManicMonsterMachine:fsStartBaseGuoChang( func ,funcEnd )
    self:runCsbAction("idle2start",false,function(  )
        self:runCsbAction("idle2",true)
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        waitNode:removeFromParent()

        util_spinePlay(self.m_normalMan,"actionframe")
        util_spineFrameCallFunc(self.m_normalMan,"actionframe","Show",function(  )

            self.m_gameBg:runCsbAction("idle2",true)

            self:showFsStartGuoChang( function(  )
   
                self.m_gameBg:runCsbAction("idle")

                util_spinePlay(self.m_normalMan,"idleframe",true)
                self:runCsbAction("idle")

                if func then
                    func()
                end
        
            end,function(  )

                if funcEnd then
                    funcEnd()
                end
            end )

        end)

    end,0.8)

end

function CodeGameScreenManicMonsterMachine:freeSpinStartFsGuoChang( func  )

    self:runCsbAction("idle")

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        waitNode:removeFromParent()

        gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_fs_Start_View.mp3")

        util_spinePlay(self.m_freeSpinMan,"actionframe")
        util_spineFrameCallFunc(self.m_freeSpinMan,"actionframe","Show",function(  )

            self:shakeRootNode( )

            if func then
                func()
            end
            
                
        end,function(  )

            performWithDelay(self,function(  )

                util_spinePlay(self.m_freeSpinMan,"idleframe",true)
            end,0)
        end)

    end,0.8)

end

function CodeGameScreenManicMonsterMachine:freeSpinOverGuoChang( func ,funcEnd )
 
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        waitNode:removeFromParent()

        gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_fs_Over_View.mp3")


        util_spinePlay(self.m_freeSpinMan,"actionframe")
        util_spineFrameCallFunc(self.m_freeSpinMan,"actionframe","Show",function(  )

            self:shakeRootNode( )
            self:runCsbAction("idle")
            self.m_gameBg:runCsbAction("idle")

            if func then
                func()
            end

        end)

    end,0.8)

end

function CodeGameScreenManicMonsterMachine:createOneActBubbleNode(pos,index,bubbleType,notInster )
    local Bubble = {}
    Bubble.BubbleNode = util_spineCreate("Socre_ManicMonster_Wild",true,true)
    Bubble.BubbleNode:setPosition(pos)


    Bubble.posIndex = index
    Bubble.bubbleType = bubbleType
    
    if bubbleType == self.m_smallLockType  then
        util_spinePlay(Bubble.BubbleNode,"idleframe",true)
    elseif  bubbleType == self.m_spreadSmallLockType  then

        util_spinePlay(Bubble.BubbleNode,"idleframe",true)
    else
        util_spinePlay(Bubble.BubbleNode,"idleframe2",true)
    end

    return Bubble
end

function CodeGameScreenManicMonsterMachine:showBonusGameView(effectData)

    gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_Trigger_Bonus.mp3")

    self:findChild("Node_mask"):setVisible(true)

    self:runCsbAction("idle2start",false,function(  )
        self:runCsbAction("idle2",true)
    end)

    local tarSymbol,tarBubble = self:getCurrBonusAndBubbleNode( )

    if tarBubble then
        tarBubble.BubbleNode:setVisible(false)
        -- 创建一个用作动画的的wild泡泡
        local createPos_act = self:getTarSpPos( tarBubble.posIndex )
        local Bubble_act = nil
        

        if tarBubble.bubbleType == self.m_bigLockType then


            
            local tarSymbolIndex = self:getPosReelIdx(tarSymbol.p_rowIndex , tarSymbol.p_cloumnIndex)  

            Bubble_act = self:createOneActBubbleNode(createPos_act, tarBubble.posIndex  ,self.m_bigLockType )
            self:findChild("Node_mask"):addChild(Bubble_act.BubbleNode,2)

            -- 因为大泡泡参考坐标是 左下
            if (tarBubble.posIndex - 5) == tarSymbolIndex then
                -- 左上
                util_spinePlay(Bubble_act.BubbleNode,"actionframe9")
                util_spinePlay(tarBubble.BubbleNode,"actionframe7")
            elseif (tarBubble.posIndex - 4) == tarSymbolIndex then
                -- 右上
                util_spinePlay(Bubble_act.BubbleNode,"actionframe8")
                util_spinePlay(tarBubble.BubbleNode,"actionframe7")
            elseif tarBubble.posIndex  == tarSymbolIndex then
                -- 左下
                util_spinePlay(Bubble_act.BubbleNode,"actionframe6")
                util_spinePlay(tarBubble.BubbleNode,"actionframe7")
            elseif (tarBubble.posIndex + 1)  == tarSymbolIndex then
                -- 右下
                util_spinePlay(Bubble_act.BubbleNode,"actionframe7")
                util_spinePlay(tarBubble.BubbleNode,"actionframe7")
            end


        else
            

            Bubble_act = self:createOneActBubbleNode(createPos_act, tarBubble.posIndex  ,self.m_smallLockType )
            self:findChild("Node_mask"):addChild(Bubble_act.BubbleNode,2)

            util_spinePlay(Bubble_act.BubbleNode,"actionframe5")
            
            util_spinePlay(tarBubble.BubbleNode,"actionframe5")

        end

        Bubble_act.BubbleNode:setPosition(cc.p(util_getConvertNodePos(tarBubble.BubbleNode,Bubble_act.BubbleNode)))

        tarSymbol:setVisible(false)
        tarSymbol:runAnim("actionframe")

        local tarSymbol_Act = util_spineCreate("Socre_ManicMonster_Jackpot",true,true)
        self:findChild("Node_mask"):addChild(tarSymbol_Act,1)
        util_spinePlay(tarSymbol_Act,"actionframe")
        tarSymbol_Act:setPosition(cc.p(util_getConvertNodePos(tarSymbol,tarSymbol_Act)))

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            waitNode:removeFromParent()

            self:findChild("Node_mask"):setVisible(false)

            Bubble_act.BubbleNode:removeFromParent()
            tarBubble.BubbleNode:setVisible(true)


            tarSymbol:setVisible(true)
            tarSymbol_Act:removeFromParent()

            local showJackpotGameViewFunc  =function(  )
                self:showJackpotGameView(function(  )

                    -- 同时触发时添加freespin游戏事件
                    self:checkLocalGameNetDataFeatures()

                    self:resetMusicBg()

                    effectData.p_isPlay = true
                    self:playGameEffect() -- 播放下一轮

                    
                end )
            end

            if self:getCurrSpinMode() == FREE_SPIN_MODE then


                util_spinePlay(self.m_freeSpinMan,"actionframe")
                util_spineFrameCallFunc(self.m_freeSpinMan,"actionframe","Show",function(  )

                    self:shakeRootNode( )

                    showJackpotGameViewFunc()
                end)

            else
                util_spinePlay(self.m_normalMan,"actionframe")
                util_spineFrameCallFunc(self.m_normalMan,"actionframe","Show",function(  )

                    showJackpotGameViewFunc()
                end)

            end
        end,2.5)
    else
        local showJackpotGameViewFunc  =function(  )
            self:showJackpotGameView(function(  )

                -- 同时触发时添加freespin游戏事件
                self:checkLocalGameNetDataFeatures()

                self:resetMusicBg()

                effectData.p_isPlay = true
                self:playGameEffect() -- 播放下一轮

                
            end )
        end

        if self:getCurrSpinMode() == FREE_SPIN_MODE then


            util_spinePlay(self.m_freeSpinMan,"actionframe")
            util_spineFrameCallFunc(self.m_freeSpinMan,"actionframe","Show",function(  )

                self:shakeRootNode( )

                showJackpotGameViewFunc()
            end)

        else
            util_spinePlay(self.m_normalMan,"actionframe")
            util_spineFrameCallFunc(self.m_normalMan,"actionframe","Show",function(  )

                showJackpotGameViewFunc()
            end)
        end
    end
end


function CodeGameScreenManicMonsterMachine:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex,reelDatas  )
    
    
    local changedSymbolType = 0

    if colIndex and reelDatas  then

        if self.m_m_initNodeIndex == nil then
            self.m_m_initNodeIndex = math.random(1,#reelDatas) 
        end

        self.m_m_initNodeIndex = self.m_m_initNodeIndex + 1
        if self.m_m_initNodeIndex > #reelDatas then
            self.m_m_initNodeIndex = 1
        end

        changedSymbolType = reelDatas[self.m_m_initNodeIndex]

    else
        changedSymbolType = symbolType
    end
    

    return changedSymbolType
end

function CodeGameScreenManicMonsterMachine:updateNetWorkData()

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

    self.m_localBubbleEffectList = {}
    self.m_playedBubbleEffectIndex = 0
    self.m_playedBubbleEffectEndCall = nil

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local addBottomSWildPos = selfdata.addBottomSWildPos or {}
    local addBottomBWildPos = selfdata.addBottomBWildPos or {}
    local addTopSWildPos = selfdata.addTopSWildPos or {}
    local addTopBWildPos = selfdata.addTopBWildPos or {}

    -- 组织泡泡动画序列 （顺序播放）
    if #addTopSWildPos > 0 or #addTopBWildPos > 0  then
        self.m_localBubbleEffectList[#self.m_localBubbleEffectList + 1] = self.TOP_CREATE_BUBBLE_EFFECT -- 随机创建小气泡（轮盘）
    end
    if #addBottomSWildPos > 0  or #addBottomBWildPos > 0  then
        self.m_localBubbleEffectList[#self.m_localBubbleEffectList + 1] = self.BOTTOM_CREATE_BUBBLE_EFFECT -- 底部创建小气泡（底部）
    end
    self.m_localBubbleEffectList[#self.m_localBubbleEffectList + 1] = self.PLAY_BUBBLE_END_EFFECT -- 播放泡泡动画事件结束
    

    self:playBubbleEffect( )
    

    self:updateAllTopWildData()

end

function CodeGameScreenManicMonsterMachine:playBubbleEffect( )
    self.m_playedBubbleEffectIndex = self.m_playedBubbleEffectIndex + 1

    if self.m_playedBubbleEffectIndex > #self.m_localBubbleEffectList then
        
        return
    end

    local BubbleEffectType = self.m_localBubbleEffectList[self.m_playedBubbleEffectIndex]

    if BubbleEffectType == self.TOP_CREATE_BUBBLE_EFFECT then

        self:createTopBubbleNode()

    elseif BubbleEffectType == self.BOTTOM_CREATE_BUBBLE_EFFECT then

        self:createBottomBubbleNode()

    elseif BubbleEffectType == self.PLAY_BUBBLE_END_EFFECT then
       
        self:runAllBubbleNodeAct()
        self:netBackReelsStop( )
   end

end

function CodeGameScreenManicMonsterMachine:netBackReelsStop( )


    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()  

end

-----------------------
----------------
----------
-- 泡泡玩法相关
----------
-- 底部创建泡泡
function CodeGameScreenManicMonsterMachine:createBottomBubbleNode( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local addBottomSWildPos = selfdata.addBottomSWildPos or {}
    local addBottomBWildPos = selfdata.addBottomBWildPos or {}

    for i=1,#addBottomSWildPos do
        local nodeSPos = addBottomSWildPos[i] + 5 -- 需要向下多移动一格
        local fixPos = self:getRowAndColByPos( nodeSPos )
        local fasheqiNode = self["m_fasheqi_"..fixPos.iY]

        local createPos =  self:getTarSpPos( nodeSPos )
        local Bubble = self:createMoveBubbleNodeForPos(createPos, nodeSPos  ,self.m_smallLockType ) 
        Bubble.BubbleNode:setVisible(false)
        
        fasheqiNode:runCsbAction("idleframe3",true)

        gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_bubbleShow_small.mp3")

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )
            waitNode:removeFromParent()

            local fasheqiNode_1 = fasheqiNode
            local Bubble_1 = Bubble
            fasheqiNode_1:runCsbAction("actionframe",false,function(  )

                fasheqiNode_1:runCsbAction("idleframe3",true)

                Bubble_1.BubbleNode:setVisible(true)
                local Bubble_2 = Bubble_1 
                util_spinePlay(Bubble_1.BubbleNode,"actionframe10")
                util_spineEndCallFunc(Bubble_1.BubbleNode,"actionframe10",function(  )
                    util_spinePlay(Bubble_2.BubbleNode,"idleframe",true)
                end)
    
                
    
            end)

        end,1)

        
        
    end

    for i=1,#addBottomBWildPos do
        local posList = addBottomBWildPos[i]
   
        table.sort( posList)
        local index = nil
        if #posList == 2 then
            index = posList[1] + 5 -- 需要向下多移动一格
        else
            index = posList[3] + 5 -- 需要向下多移动一格 -- 大泡泡参考点为左下位置
        end
        local createPos =  self:getBigTarSpPos(index )
        local Bubble = self:createMoveBubbleNodeForPos(createPos, index ,self.m_bigLockType )
        Bubble.BubbleNode:setVisible(false)

        local fixPos = self:getRowAndColByPos( index )
        local fasheqiNode_left = self["m_fasheqi_"..fixPos.iY]
        local fasheqiNode_Right = self["m_fasheqi_"..fixPos.iY + 1]

        fasheqiNode_left:runCsbAction("idleframe3",true)
        local waitNode_left = cc.Node:create()
        self:addChild(waitNode_left)
        performWithDelay(waitNode_left,function(  )
            waitNode_left:removeFromParent()

            local fasheqiNode_left_1 = fasheqiNode_left
            fasheqiNode_left:runCsbAction("actionframe2",false,function(  )
                fasheqiNode_left_1:runCsbAction("idleframe3",true)
         
            end)
        end,1)
        

        gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_bubbleShow_Big.mp3")

        fasheqiNode_Right:runCsbAction("idleframe3",true)
        local waitNode_right = cc.Node:create()
        self:addChild(waitNode_right)
        performWithDelay(waitNode_right,function(  )
            waitNode_right:removeFromParent()

            

            local fasheqiNode_Right_1 = fasheqiNode_Right
            local Bubble_1 = Bubble
            fasheqiNode_Right:runCsbAction("actionframe3",false,function(  )

                fasheqiNode_Right_1:runCsbAction("idleframe3",true)

                

                Bubble_1.BubbleNode:setVisible(true)
                local Bubble_2 = Bubble_1
                util_spinePlay(Bubble_1.BubbleNode,"actionframe11")
                util_spineEndCallFunc(Bubble_1.BubbleNode,"actionframe11",function(  )
                    util_spinePlay(Bubble_2.BubbleNode,"idleframe2",true)
                end)
            end)
    
        end,1)

    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        waitNode:removeFromParent()

        self:playBubbleEffect( )

    end,2.8)

end


function CodeGameScreenManicMonsterMachine:runCollectTopBubbleNode(waitTime,flyTime,startNode,endNode,func,bubbleType,isEndPos)


    -- 创建粒子
    local flyNode =  util_createAnimation( "ManicMonster_shouji.csb")
    self:addChild(flyNode, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)

    local startPos = util_getConvertNodePos(startNode,flyNode)


    local endPos = cc.p(util_getConvertNodePos(endNode,flyNode))

    
    if bubbleType == self.m_bigLockType then
        if isEndPos then
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(cc.p(endNode:getPosition()).x + 130 / 2,cc.p(endNode:getPosition()).y + 100 /2 )) -- 小块长宽的一半
            endPos = flyNode:getParent():convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        else
            local worldPos = startNode:getParent():convertToWorldSpace(cc.p(cc.p(startNode:getPosition()).x + 130 /2,cc.p(startNode:getPosition()).y + 100 / 2)) -- 小块长宽的一半
            startPos = flyNode:getParent():convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
            flyNode:setPosition(cc.p(startPos.x , startPos.y ))
        end

    end

    

    flyNode:setPosition(cc.p(startPos))

    local angle = util_getAngleByPos(startPos,endPos)
    flyNode:findChild("Node_1"):setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:findChild("Node_1"):setScaleX(scaleSize / 240)

    flyNode:setVisible(false)

    local actList = {}
    
    actList[#actList + 1] = cc.DelayTime:create(waitTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:setVisible(true)
        flyNode:runCsbAction("actionframe",true)
    end)
    actList[#actList + 1] = cc.DelayTime:create(flyTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )

            if func then
                func()
            end

    end)
    actList[#actList + 1] = cc.DelayTime:create(0.5)
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        flyNode:stopAllActions()
        flyNode:removeFromParent()

    end)
    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)

    return flyNode

end

-- 轮盘随机创建泡泡
function CodeGameScreenManicMonsterMachine:createTopBubbleNode( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {} 
    local addTopSWildPos = selfdata.addTopSWildPos or {}
    local addTopBWildPos = selfdata.addTopBWildPos or {}
    local bottomWildList = {}
    for i=1,#addTopSWildPos do
        local wildPos = {}
        table.insert( wildPos, addTopSWildPos[i])
        table.insert( bottomWildList, wildPos)
    end

    for i=1,#addTopBWildPos do
        table.insert( bottomWildList, math.random(1,#addTopBWildPos) , addTopBWildPos[i] )
    end
    


    local createRandomfunc = function(  )
        self:runCsbAction("actionframe_wild",false,function(  )
            self:runCsbAction("idle",false) 
        end)

        local waitNode_1 = cc.Node:create()
        self:addChild(waitNode_1)
        performWithDelay(waitNode_1,function(  )

            waitNode_1:removeFromParent()


            for i=1,5 do
                local waitTime = 0.2 * ( 2 -  math.abs(i - 3) )
                local fasheqi = self["m_fasheqi_"..i]
                performWithDelay(fasheqi,function(  )
                    local fasheqi_1 = fasheqi
                    fasheqi_1:runCsbAction("idleframe3",true)
                end,waitTime)
                 
            end

            local waitNode = cc.Node:create()
            self:addChild(waitNode)
            performWithDelay(waitNode,function(  )

                waitNode:removeFromParent()

                -- 开始发射闪电
                for i=1,#bottomWildList do
                    local Bubble = nil
                    local posList = bottomWildList[i]
                    if #posList > 1  then
                        table.sort( posList)
                        local index = nil
                        if #posList == 2 then
                            index = posList[1] + 5 -- 需要向下多移动一格
                        else
                            index = posList[3] + 5 -- 需要向下多移动一格-- 大泡泡参考点为左下位置
                        end
                        local createPos =  self:getBigTarSpPos(index )
                        Bubble = self:createMoveBubbleNodeForPos(createPos, index ,self.m_bigLockType )
                    else
                        local index = posList[1] + 5 -- 需要向下多移动一格
                        local createPos =  self:getTarSpPos( index )
                        Bubble = self:createMoveBubbleNodeForPos(createPos, index  ,self.m_smallLockType )  
                    end
                    

                    local randomIndex = 3
                    local startNode = self["m_fasheqi_"..randomIndex]
                    local endNode = Bubble.BubbleNode
                    endNode:setVisible(false)
                    local palyIndex = i
                    self:runCollectTopBubbleNode(0.2  ,0,startNode,endNode,function(  )
                        endNode:setVisible(true)
                        local endNode_1 = endNode
                        if Bubble.bubbleType == self.m_smallLockType or Bubble.bubbleType == self.m_spreadSmallLockType then
                            
                            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_RadomBubbleShow.mp3")

                            util_spinePlay(endNode_1,"actionframe10")
                            util_spineEndCallFunc(endNode_1,"actionframe10",function(  )
                                util_spinePlay(endNode_1,"idleframe",true)
                            end)
                        else
                            gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_RadomBubbleShow.mp3")
                            util_spinePlay(endNode_1,"actionframe11")
                            util_spineEndCallFunc(endNode_1,"actionframe11",function(  )
                                util_spinePlay(endNode_1,"idleframe2",true)
                            end)
                        end
                        
                        if palyIndex == #bottomWildList then
                            -- 最后一个播放完 

                           self:changefaSheQIStates()
                            
                            local waitNode_2 = cc.Node:create()
                            self:addChild(waitNode_2)
                            performWithDelay(waitNode_2,function(  )
                                waitNode_2:removeFromParent()

                                self:playBubbleEffect( )

                            end,1.1)

                        end
                        

                    end,Bubble.bubbleType,true)


                end
                


            end,0.7)

        end,0.2)
    end
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then



        gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_Fs_RandomWild.mp3")
        util_spinePlay(self.m_freeSpinMan,"actionframe")
        util_spineFrameCallFunc(self.m_freeSpinMan,"actionframe","Show",function(  )

            self:shakeRootNode( )

            createRandomfunc()
        end,function(  )
            
            util_spinePlay(self.m_freeSpinMan,"idleframe",true)
        end)

    else

        gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_base_RandomWild.mp3")

        util_spinePlay(self.m_normalMan,"actionframe2")
        util_spineFrameCallFunc(self.m_normalMan,"actionframe2","Show2",function(  )
            createRandomfunc()
        end,function(  )
            util_spinePlay(self.m_normalMan,"idleframe",true)
        end)
    end

    

end


-- 创建泡泡
function CodeGameScreenManicMonsterMachine:createBaseAllBubbleNode(lockedBubble)


    if lockedBubble then
        for k,v in pairs(lockedBubble) do
                local posList = v

                if #posList > 1  then
                    table.sort( posList)
                    local index = nil
                    if #posList == 2 then
                        index = posList[1]
                    else
                        index = posList[3] -- 大泡泡参考点为左下位置
                    end
                    local createPos =  self:getBigTarSpPos(index )
                    self:createMoveBubbleNodeForPos(createPos, index ,self.m_bigLockType )
                else
                    local index = posList[1]
                    local createPos =  self:getTarSpPos( index )
                    self:createMoveBubbleNodeForPos(createPos, index  ,self.m_smallLockType )  
                end


        end
    end
      
end

function CodeGameScreenManicMonsterMachine:getTarSpPos(index )


    local targSpPos =  util_getOneGameReelsTarSpPos(self ,index )
    
    return targSpPos
end

function CodeGameScreenManicMonsterMachine:getBigTarSpPos(index )
    
    local pos = cc.p(util_getOneGameReelsTarSpPos(self ,index ))

    return cc.p(pos.x ,pos.y)
end

function CodeGameScreenManicMonsterMachine:compareNetData( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local currTotalBet = globalData.slotRunData:getCurTotalBet()
    local lockedBubble = self.m_baseWildData[tostring(currTotalBet)] or {} -- base已经固定的泡泡

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        lockedBubble =  selfdata.freeWildPos -- Free已经固定的泡泡
    end
    if lockedBubble then
        local num = #lockedBubble
        local numB = 0
        for i = #self.m_BubbleNodeList,1,-1 do
            local Bubble = self.m_BubbleNodeList[i]
            if not Bubble.BubbleNode:isVisible() then
                __G__TRACKBACK__("出错了！！有气泡隐藏了 -----")
            end
            if Bubble.posIndex  then
                for k = 1,#lockedBubble do
                    local posList = lockedBubble[k]
                    local index = nil
                    if #posList > 1  then

                        table.sort( posList)
                        
                        if #posList == 2 then
                            index = posList[1]
                        else
                            index = posList[3] -- 大泡泡参考点为左下位置
                        end
            
                    else
                        index = posList[1]
                    end

                    if index == Bubble.posIndex then
                        numB = numB + 1

                        break
                    end
                    
                end
                
            end
        end


        if numB ~= num then

            __G__TRACKBACK__("出错了！！服务器与本地数据不符合 -----")
            print("出错了 服务器有重复值了 -----")
        end
    end
    
end

function CodeGameScreenManicMonsterMachine:getOneBubbleNode( index ,isLines )

    if isLines then
        -- 连线的时候 有可能 多个泡泡覆盖 优先 扩散的小泡泡
        local BubbleData = {}
        for i = #self.m_BubbleNodeList,1,-1 do
            local Bubble = self.m_BubbleNodeList[i]
            if Bubble.posIndex == index then
                
                table.insert( BubbleData, Bubble)
            end
        end
        local zorderList = {}

        --如果有扩散小块 优先
        for i=1,#BubbleData do
            if BubbleData[i].bubbleType == self.m_spreadSmallLockType then
                if not BubbleData[i].isCover then
                    return BubbleData[i]
                end
                
            end
        end

        -- 没有扩散小块 返回首个不是扩散小块的 气泡
        for i=1,#BubbleData do
            if BubbleData[i].bubbleType ~= self.m_spreadSmallLockType then

                return BubbleData[i]

            end
        end
        

    else
        for i = #self.m_BubbleNodeList,1,-1 do
            local Bubble = self.m_BubbleNodeList[i]
            if Bubble.bubbleType ~= self.m_spreadSmallLockType  then
                if Bubble.posIndex == index then
                
                    return Bubble
                end
            end
            
        end
    end

    
end

function CodeGameScreenManicMonsterMachine:checkBubbleInCol( col )
    
    for i = #self.m_BubbleNodeList,1,-1 do
        local Bubble = self.m_BubbleNodeList[i]
        if Bubble.posIndex >= 0 then
            if Bubble.bubbleType == self.m_smallLockType then
                local fixPos = self:getRowAndColByPos(  Bubble.posIndex )
                if fixPos.iY == col then
                    return true
                end
                
    
            elseif Bubble.bubbleType == self.m_bigLockType then
                local fixPos = self:getRowAndColByPos(  Bubble.posIndex )
                if fixPos.iY == col then
                    return true
                end
                if (fixPos.iY + 1) == col then
                    return true
                end
            end
        end
       
        
    end


    return false
end

function CodeGameScreenManicMonsterMachine:getOneSpreadBubbleNode( index )
    
    for i = #self.m_BubbleNodeList,1,-1 do
        local Bubble = self.m_BubbleNodeList[i]
        if Bubble.bubbleType == self.m_spreadSmallLockType then
            if Bubble.posIndex == index then
                return true
            end
            
        end
        
    end

    
end

function CodeGameScreenManicMonsterMachine:removeAllCoverSpreadBubbleNode( )
    for i = #self.m_BubbleNodeList,1,-1 do
        local Bubble = self.m_BubbleNodeList[i]
        if Bubble.bubbleType == self.m_spreadSmallLockType then
            if Bubble.isCover then
                Bubble.BubbleNode:setVisible(false)
            end
            
        end
        
    end
end

function CodeGameScreenManicMonsterMachine:restAllBubbleNodeZorder( )
    for i = #self.m_BubbleNodeList,1,-1 do
        local Bubble = self.m_BubbleNodeList[i]
        if Bubble.BubbleNode then
            
            Bubble.BubbleNode:setLocalZOrder(Bubble.posIndex)
        end
        
    end
end

function CodeGameScreenManicMonsterMachine:removeAllSpreadBubbleNode( )
    for i = #self.m_BubbleNodeList,1,-1 do
        local Bubble = self.m_BubbleNodeList[i]
        if Bubble.bubbleType == self.m_spreadSmallLockType then
            Bubble.BubbleNode:removeFromParent()
            table.remove( self.m_BubbleNodeList,i)
        end
        
    end
end



function CodeGameScreenManicMonsterMachine:removeAllExceedBubbleNode(  )

    for i = #self.m_BubbleNodeList,1,-1 do
        local Bubble = self.m_BubbleNodeList[i]
        if Bubble.posIndex < 0 then
            Bubble.BubbleNode:removeFromParent()
            table.remove( self.m_BubbleNodeList,i) 
        end
        
    end

end

function CodeGameScreenManicMonsterMachine:showAllRunBubbleNode( )
    for i = #self.m_BubbleNodeList,1,-1 do
        local Bubble = self.m_BubbleNodeList[i]
        if Bubble.bubbleType ~= self.m_spreadSmallLockType then
            if Bubble.bubbleType == self.m_bigLockType then
                util_spinePlay(Bubble.BubbleNode,"idleframe2",true)
            else
                util_spinePlay(Bubble.BubbleNode,"idleframe",true) 
            end
            
        end
    end
end

function CodeGameScreenManicMonsterMachine:removeAllBubbleNode(  )

    for i = #self.m_BubbleNodeList,1,-1 do
        local Bubble = self.m_BubbleNodeList[i]
        Bubble.BubbleNode:removeFromParent()
        table.remove( self.m_BubbleNodeList,i)
    end

end

--泡泡 创建
function CodeGameScreenManicMonsterMachine:createMoveBubbleNodeForPos( pos,index,bubbleType,notInster)
    
    local Bubble = {}
    Bubble.BubbleNode = util_spineCreate("Socre_ManicMonster_Wild",true,true)
    Bubble.BubbleNode:setPosition(pos)

    self:findChild("Node_Bubble"):addChild(Bubble.BubbleNode,index)

    Bubble.posIndex = index
    Bubble.bubbleType = bubbleType
    
    if  Bubble.bubbleType == self.m_smallLockType  then
        util_spinePlay(Bubble.BubbleNode,"idleframe",true)
    elseif   Bubble.bubbleType == self.m_spreadSmallLockType  then
        local ishave = self:getOneSpreadBubbleNode( index )
        ishave = ishave or self:getOneBubbleNode(index)
        if ishave then
            Bubble.isCover = true
        end
        util_spinePlay(Bubble.BubbleNode,"idleframe",true)
    else
        util_spinePlay(Bubble.BubbleNode,"idleframe2",true)
    end

    if not notInster then
        table.insert( self.m_BubbleNodeList, Bubble )
    end
    

    return Bubble

end



function CodeGameScreenManicMonsterMachine:quicklyStopReel(colIndex )

    self:quickStopCreateBubble( )
    
    BaseNewReelMachine.quicklyStopReel(self,colIndex )

end

function CodeGameScreenManicMonsterMachine:quickStopCreateBubble( )

    

    if not self.m_BubbleNodeMoveEnd then
        self.m_BubbleNodeMoveEnd = true


        -- 清除所有泡泡
        self:removeAllBubbleNode(  )
        -- 创建 base 泡泡
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local lockedBubble = selfdata.wildPos  -- wild已经固定的泡泡
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            lockedBubble = selfdata.freeWildPos  -- Free已经固定的泡泡
        end
        self:createBaseAllBubbleNode(lockedBubble)

        self:changefaSheQIStates()
    end
    

end

function CodeGameScreenManicMonsterMachine:runAllBubbleNodeAct( )

    self.m_BubbleNodeMoveEnd = true
    if #self.m_BubbleNodeList > 0 then
        self.m_BubbleNodeMoveEnd = false
    end
    for i=1,#self.m_BubbleNodeList do
        local Bubble = self.m_BubbleNodeList[i]

        local Pos = cc.p(0,0)  

        local fixPos = self:getRowAndColByPos( Bubble.posIndex )
        local index = self:getPosReelIdx(fixPos.iX + 1 , fixPos.iY)
        Bubble.posIndex = index
        Bubble.BubbleNode:setLocalZOrder(index )
        if Bubble.bubbleType == self.m_smallLockType or Bubble.bubbleType == self.m_spreadSmallLockType  then
            Pos = self:getTarSpPos(index )
        else
            Pos = self:getBigTarSpPos(index)
        end
        local func = nil
        if i == #self.m_BubbleNodeList then
            func = function(  )
                self:changefaSheQIStates()
                self.m_BubbleNodeMoveEnd = true
                self:changeEffectToPlayed(self.DEALT_EFFECT )

            end
        end
         

        self:runMoveAct(Bubble.BubbleNode,Pos,Bubble.posIndex,func)
    end

    
end

function CodeGameScreenManicMonsterMachine:runMoveAct( node,endPos,posIndex,func )
    
    local actionList = {}
    local startPos = cc.p(node:getPosition())
    local ndoePosIndex = posIndex
    local time = 1
    if ndoePosIndex < 0 then
        time = 0.5
        -- endPos.y = endPos.y 
    end
    actionList[#actionList+1] = cc.CallFunc:create(function()
        
        if ndoePosIndex < 0 then
            util_playFadeOutAction(node,1)
        end
        
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(1,cc.p( endPos.x ,endPos.y))
    actionList[#actionList+1] = cc.CallFunc:create(function()
        if func then
            func()
        end
        
    end)
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)
end


-- 泡泡wild bonus扩散相关
function CodeGameScreenManicMonsterMachine:createBonusSpreadAction( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusWilds = selfdata.bonusWilds or {} -- Bonus位置 
    local extendPos = selfdata.extendPos or {}  -- Spread扩散位置

    -- 找到所有的bonus
    for i=1,#bonusWilds do
        local posList = bonusWilds[i]
        local index = nil
        
        local currBonus = nil
        local isBig = false
        if #posList > 1  then
            isBig = true
            table.sort( posList)
            
            if #posList == 2 then
                index = posList[1]
            else
                index = posList[3] -- 大泡泡参考点为左下位置
            end

            for i=1,#posList do
                local fixPos =  self:getRowAndColByPos( posList[i] )

                local tarSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                if tarSp.p_symbolType == self.SYMBOL_BONUS_NORMAL then

                    currBonus = tarSp
                    break
                end

            end
            
        else

            local fixPos =  self:getRowAndColByPos(  posList[1] )
            currBonus = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            index = posList[1]
        end

        local bonusPosBubbleNode = self:getOneBubbleNode(index)

        
        

        if bonusPosBubbleNode then

            if bonusPosBubbleNode == nil then
                local str = "出错了！！bonusPosBubbleNode 是空 是little index -----" .. index
                if condition then
                    str = "出错了！！bonusPosBubbleNode 是空是 big index --" .. index 
                end
                __G__TRACKBACK__(str)
            end
    

            bonusPosBubbleNode.BubbleNode:setLocalZOrder(index + 300 + 200 ) -- 扩散出来的更高

            -- 开始创建移动变化的泡泡
            local SpreadBubbleList = {}
            local currExtendPos = extendPos[i]
            for k = 1,#currExtendPos do
                local wildMovePos= currExtendPos[k]

                -- 创建扩散的wild泡泡
                local createPos = self:getTarSpPos( wildMovePos )
                local Bubble = self:createMoveBubbleNodeForPos(createPos, wildMovePos  ,self.m_spreadSmallLockType )
                Bubble.BubbleNode:setLocalZOrder(wildMovePos + 300 + 1) -- 扩散出来的更高
                Bubble.BubbleNode:setVisible(false)
                table.insert( SpreadBubbleList, Bubble)
                
            end

            
            local createSpreadBubblefunc = function(currBubbleNode )

                local actBubbleNode = currBubbleNode
                for i=1,#SpreadBubbleList do

                    local Bubble = SpreadBubbleList[i]
                    Bubble.BubbleNode:setVisible(true)

                    local actBubbleNode_1 = actBubbleNode
                    util_spinePlay(Bubble.BubbleNode,"actionframe10")
                    util_spineEndCallFunc(Bubble.BubbleNode,"actionframe10",function(  )
                        util_spinePlay(Bubble.BubbleNode,"idleframe",true)
                        actBubbleNode_1.BubbleNode:setLocalZOrder( actBubbleNode_1.posIndex )
                    end)

                    
                    self:runCollectTopBubbleNode(0,0,currBubbleNode.BubbleNode,Bubble.BubbleNode,function(  )

                    end,currBubbleNode.bubbleType)

                end


            end
            
            
            
            if isBig then

                gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_bigbubble_Cover_Bonus.mp3")
                
                if currBonus then
                    if currBonus.p_symbolType == self.SYMBOL_BONUS_NORMAL then
                        currBonus:runAnim("actionframe4")
                    end
                else
                    release_print("big -- index"..index)
                end
                print("big -- index"..index)
                
                util_spinePlay(bonusPosBubbleNode.BubbleNode,"actionframe4",false)
                util_spineFrameCallFunc(bonusPosBubbleNode.BubbleNode,"actionframe4","Boom2",function(  )

                    local currBubbleNode = bonusPosBubbleNode
                    createSpreadBubblefunc(currBubbleNode)

                    -- 创建一个用作动画大的wild泡泡
                    local createPos_act = self:getTarSpPos( currBubbleNode.posIndex )
                    local Bubble_act = self:createMoveBubbleNodeForPos(createPos_act, currBubbleNode.posIndex  ,self.m_bigLockType ,true)
                    Bubble_act.BubbleNode:setLocalZOrder(currBubbleNode.posIndex + 300 + 101 ) 
                    
                    util_spinePlay(Bubble_act.BubbleNode,"actionframe11")
                    
                    local Bubble_act_1 = Bubble_act
                    local currBubbleNode_1 = currBubbleNode
                    local actNode_wait_1 = cc.Node:create()
                    self:addChild(actNode_wait_1)
                    currBubbleNode_1.BubbleNode:setVisible(false)
                    performWithDelay(actNode_wait_1,function(  )
                        currBubbleNode_1.BubbleNode:setVisible(true)
                        actNode_wait_1:removeFromParent()
                        util_spinePlay(currBubbleNode_1.BubbleNode,"idleframe2",true)
                        Bubble_act_1.BubbleNode:removeFromParent()
                    end,1)

                end) 

                
            else

                gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_smallbubble_Cover_Bonus.mp3")

                if currBonus then
                    if currBonus.p_symbolType == self.SYMBOL_BONUS_NORMAL then
                        currBonus:runAnim("actionframe3") 
                    end
                else
                    release_print("small -- index"..index)
                end
                print("small -- index"..index)

                util_spinePlay(bonusPosBubbleNode.BubbleNode,"actionframe3",false)
                util_spineFrameCallFunc(bonusPosBubbleNode.BubbleNode,"actionframe3","Boom3",function(  )
                    local currBubbleNode = bonusPosBubbleNode
                    createSpreadBubblefunc(currBubbleNode)

                    -- 创建一个用作动画的小的wild泡泡
                    local createPos_act = self:getTarSpPos( currBubbleNode.posIndex )
                    local Bubble_act = self:createMoveBubbleNodeForPos(createPos_act, currBubbleNode.posIndex  ,self.m_smallLockType ,true)
                    Bubble_act.BubbleNode:setLocalZOrder(currBubbleNode.posIndex + 300 + 101 ) 
                    
                    util_spinePlay(Bubble_act.BubbleNode,"actionframe10")
                    
                    local Bubble_act_1 = Bubble_act
                    local currBubbleNode_1 = currBubbleNode
                    local actNode_wait_1 = cc.Node:create()
                    self:addChild(actNode_wait_1)
                    currBubbleNode_1.BubbleNode:setVisible(false)
                    performWithDelay(actNode_wait_1,function(  )
                        currBubbleNode_1.BubbleNode:setVisible(true)
                        actNode_wait_1:removeFromParent()
                        util_spinePlay(currBubbleNode_1.BubbleNode,"idleframe",true)
                        Bubble_act_1.BubbleNode:removeFromParent()
                    end,1)

                end,function(  )
                    
                    util_spinePlay(bonusPosBubbleNode.BubbleNode,"idleframe",true)
                end)
            end

        else
           
            release_print("bonusPosBubbleNode nil")
        end
        


    end
    
    

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        self:freeOverRestBonusNormal()

        self:removeAllCoverSpreadBubbleNode( ) -- 移除所有 Spread扩散位置 又覆盖一层的地方

        waitNode:removeFromParent()

        self:changeEffectToPlayed(self.SPREAD_ACTION_EFFECT )
    end,3.1)


end

function CodeGameScreenManicMonsterMachine:showFsStartGuoChang( func,funcEnd )

    gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_GuoChangToBase.mp3")

    self.m_gameBg:runCsbAction("guochang")

    self.m_GuoChang:setVisible(true)
    self.m_GuoChang:runCsbAction("animation1",false,function(  )
        self.m_GuoChang:setVisible(false)
        if funcEnd then
            funcEnd()
        end
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

       

        waitNode:removeFromParent()

        
        if func then
            func()
        end

        self:showAllRunBubbleNode( )


    end,2.3)

end

function CodeGameScreenManicMonsterMachine:showGuoChang( func,funcEnd )

    gLobalSoundManager:playSound("ManicMonsterSounds/music_ManicMonster_GuoChangToBase.mp3")

    self.m_gameBg:runCsbAction("guochang")

    self.m_GuoChang:setVisible(true)
    self.m_GuoChang:runCsbAction("animation0",false,function(  )
        self.m_GuoChang:setVisible(false)
        if funcEnd then
            funcEnd()
        end
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

       

        waitNode:removeFromParent()

        
        if func then
            func()
        end

        self:showAllRunBubbleNode( )


    end,0.8)

end

function CodeGameScreenManicMonsterMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "ManicMonsterSounds/ManicMonsterSounds_scatterDown.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenManicMonsterMachine:updateReelGridNode(node)
    if node.p_symbolType == self.SYMBOL_BONUS_NORMAL then
        node:runAnim("idleframe",true)
    end
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function CodeGameScreenManicMonsterMachine:specialSymbolActionTreatment( slotNode)
    -- print("dada")

    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

        slotNode = self:setSymbolToClipReel(slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
        slotNode:runAnim("buling")
        self.m_reelDownAddTime = 24/30
    end
end

function CodeGameScreenManicMonsterMachine:playCustomSpecialSymbolDownAct( slotNode )
    CodeGameScreenManicMonsterMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )


    if slotNode.p_symbolType == self.SYMBOL_BONUS_NORMAL  then

        -- slotNode:runAnim("buling")

        -- gLobalSoundManager:playSound("ManicMonsterSounds/ManicMonsterSounds_TriggerBonusDown.mp3")
        
        -- self.m_reelDownAddTime = 24/30

    elseif slotNode.p_symbolType == self.SYMBOL_BONUS_JACKPOT  then

        local soundPath = "ManicMonsterSounds/ManicMonsterSounds_jPBonusDown.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end


        slotNode = self:setSymbolToClipReel(slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_BONUS_JACKPOT)

        slotNode:runAnim("buling")

        self.m_reelDownAddTime = 24/30

    elseif slotNode.p_symbolType == self.SYMBOL_SCATTER_ADDTIMES  then

        local soundPath = "ManicMonsterSounds/ManicMonsterSounds_scatterDown.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end


        slotNode = self:setSymbolToClipReel(slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_SCATTER_ADDTIMES)
        slotNode:runAnim("buling")
        self.m_reelDownAddTime = 24/30
    end
end

---
--得到参与连线的固定小块
function CodeGameScreenManicMonsterMachine:getSpecialReelNode(matrixPos)
    local slotNode = BaseNewReelMachine.getSpecialReelNode(self,matrixPos)
    if slotNode == nil then
        slotNode = self:getFixSymbol(matrixPos.iY, matrixPos.iX, SYMBOL_NODE_TAG)
    end

    return slotNode
end

function CodeGameScreenManicMonsterMachine:showLineFrame( )
   
    self:setLowScatterBonusJpZOrder()

    BaseNewReelMachine.showLineFrame( self)

    -- 把所有参与连线的泡泡位置都记录下来
    self.m_BubblelineSlotNodes = {}

    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then

            local index = self:getPosReelIdx(slotsNode.p_rowIndex , slotsNode.p_cloumnIndex)  
            local isin , posList = self:isInLockedBubble(index,true) 
            if isin then
                table.insert( self.m_BubblelineSlotNodes, index )
            end
        end
    end

    

end


-- 连线相关修改
---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenManicMonsterMachine:playInLineNodes()

    

    BaseNewReelMachine.playInLineNodes(self)

    
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            local currAnimTime = 0
            -- 把新覆盖的wild添加到连线动画里
            local index = self:getPosReelIdx(slotsNode.p_rowIndex , slotsNode.p_cloumnIndex)  
            local isin , posList = self:isInLockedBubble(index,true) 
            if isin then
                currAnimTime = 2
                local currIndex = nil
                if #posList > 1  then

                    table.sort( posList)
                    
                    if #posList == 2 then
                        currIndex = posList[1]
                    else
                        currIndex = posList[3] -- 大泡泡参考点为左下位置
                    end
                    
                else
                    currIndex = posList[1]
                end
                local tarBubble = self:getOneBubbleNode( currIndex ,true)
                if tarBubble then
                    if tarBubble.bubbleType ~= self.m_spreadSmallLockType then
                        tarBubble.BubbleNode:setLocalZOrder((tarBubble.posIndex))
                    end
                    if tarBubble.bubbleType == self.m_bigLockType then
                        util_spinePlay(tarBubble.BubbleNode,"actionframe2",true)
                    else
                        util_spinePlay(tarBubble.BubbleNode,"actionframe",true)
                    end
                end
                
                slotsNode:runIdleAnim()
            else
                
                slotsNode:runLineAnim()
                currAnimTime = slotsNode:getAniamDurationByName(slotsNode:getLineAnimName())
            end


            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, currAnimTime )
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenManicMonsterMachine:showLineFrameByIndex(winLines,frameIndex)

    BaseNewReelMachine.showLineFrameByIndex(self,winLines,frameIndex)

    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then

                    -- 把新覆盖的wild添加到连线动画里
                    local index = self:getPosReelIdx(slotsNode.p_rowIndex , slotsNode.p_cloumnIndex)  
                    local isin , posList = self:isInLockedBubble(index,true) 
                    if isin then
                        local currIndex = nil
                        if #posList > 1  then

                            table.sort( posList)
                            
                            if #posList == 2 then
                                currIndex = posList[1]
                            else
                                currIndex = posList[3] -- 大泡泡参考点为左下位置
                            end
                            
                        else
                            currIndex = posList[1]
                        end
                        local tarBubble = self:getOneBubbleNode( currIndex,true )
                        if tarBubble then

                            if tarBubble.bubbleType ~= self.m_spreadSmallLockType then
                                tarBubble.BubbleNode:setLocalZOrder((tarBubble.posIndex))
                            end

                            if tarBubble.bubbleType == self.m_bigLockType then
                                util_spinePlay(tarBubble.BubbleNode,"actionframe2",true)
                            else
                                util_spinePlay(tarBubble.BubbleNode,"actionframe",true)
                            end 
                        end
                        
                        slotsNode:runIdleAnim()

                    else

                        slotsNode:runLineAnim()
                    end

                end
            end
        end
    end
end



function CodeGameScreenManicMonsterMachine:palyAllBubblelineSlotNodesIdle( )
    
    for i=1,#self.m_BubblelineSlotNodes do
        local index = self.m_BubblelineSlotNodes[i]
        local isin , posList = self:isInLockedBubble(index,true) 
        if isin then
            local currIndex = nil
            if #posList > 1  then

                table.sort( posList)
                
                if #posList == 2 then
                    currIndex = posList[1]
                else
                    currIndex = posList[3] -- 大泡泡参考点为左下位置
                end
                
            else
                currIndex = posList[1]
            end
            local tarBubble = self:getOneBubbleNode( currIndex,true )
            if tarBubble then
                if tarBubble.bubbleType == self.m_bigLockType then
                    util_spinePlay(tarBubble.BubbleNode,"idleframe2",true)
                else
                    util_spinePlay(tarBubble.BubbleNode,"idleframe",true)
                end
            end
            
            
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenManicMonsterMachine:playInLineNodesIdle()

   self:palyAllBubblelineSlotNodesIdle()

    BaseNewReelMachine.playInLineNodesIdle(self)

    

end


---
-- 取消掉赢钱线的效果
function CodeGameScreenManicMonsterMachine:clearWinLineEffect()
    self:palyAllBubblelineSlotNodesIdle()

    BaseNewReelMachine.clearWinLineEffect(self)

end

--服务端网络数据返回成功后处理
function CodeGameScreenManicMonsterMachine:MachineRule_afterNetWorkLineLogicCalculate()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end
    

end

function CodeGameScreenManicMonsterMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = self:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(self,index )
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        --设置scatterZOrder高于wild泡泡
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + REEL_SYMBOL_ORDER.REEL_ORDER_3 + 100 - _iRow , targSp:getTag()) 
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

--
-- 自己添加freespin 事件
--
function CodeGameScreenManicMonsterMachine:checkLocalGameNetDataFeatures()

    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

            for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                local checkEnd = false
                if lineData.p_iconPos ~= nil then
                    for posIndex = 1 , #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex] 
    
                        local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
    
                        local symbolType = lineData.p_type or self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            checkEnd = true
                            local lineInfo = self:getReelLineInfo()
                            local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
    
                            for addPosIndex = 1 , #lineData.p_iconPos do
    
                                local posData = lineData.p_iconPos[addPosIndex]
                                local rowColData = self:getRowAndColByPos(posData)
                                lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData
    
                            end
    
                            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                            lineInfo.iLineSymbolNum = #lineInfo.vecValidMatrixSymPos
                            self.m_reelResultLines = {}
                            self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                            break
                        end
                    end
                end
                if checkEnd == true then
                    break
                end

            end


        end

    end

end

function CodeGameScreenManicMonsterMachine:getNextReelSymbolType( )
    
    return self.m_runSpinResultData.p_prevReel
end

function CodeGameScreenManicMonsterMachine:shakeRootNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)

end

function CodeGameScreenManicMonsterMachine:changefaSheQIStates( )
    for i=1,5 do
        local fasheqi = self["m_fasheqi_"..i]
        
        if self:checkBubbleInCol(i) then
            fasheqi:runCsbAction("idleframe2",true) 
        else
            fasheqi:runCsbAction("idleframe2",true) 
        end
        
    end
end

function CodeGameScreenManicMonsterMachine:playEffectNotifyNextSpinCall( )

    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenManicMonsterMachine:setLowScatterBonusJpZOrder( )

    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            local symbolType =  targSp.p_symbolType
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_BONUS_JACKPOT then
                targSp:setLocalZOrder( self:getBounsScatterDataZorder(symbolType)  - iRow )
            end
        end

    end
     
end

function CodeGameScreenManicMonsterMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_ManicMonsterLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

--[[
    @desc: 对比 winline 里面的所有线， 将相同的线 进行合并，
    这个主要用来处理， winLines 里面会存在两条一样的触发 fs的线，其中一条线winAmount为0，另一条
    有值， 这中情况主要使用与
    time:2018-08-16 19:30:23
    @return:  只保留一份 scatter 赢钱的线，如果存在允许scatter 赢钱的话
]]
function CodeGameScreenManicMonsterMachine:compareScatterWinLines(winLines)

    local scatterLines = {}
    local winAmountIndex = -1
    for i=1,#winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.p_iconPos
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD

        for posIndex=1,#iconsPos do
            local posData = iconsPos[posIndex]
            
            local rowColData = self:getRowAndColByPos(posData)
            print("rowColData.iX ===" .. rowColData.iX  .. ",rowColData.iY == " ..rowColData.iY )
            local symbolType = winLineData.p_type or self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]

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
function CodeGameScreenManicMonsterMachine:getWinLineSymboltType(winLineData,lineInfo )
    local iconsPos = winLineData.p_iconPos
    local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
    for posIndex=1,#iconsPos do
        local posData = iconsPos[posIndex]
        
        local rowColData = self:getRowAndColByPos(posData)

        lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData  -- 连线元素的 pos信息
            
        local symbolType = winLineData.p_type or self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
        if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
            enumSymbolType = symbolType
        end
    end
    return enumSymbolType
end

function CodeGameScreenManicMonsterMachine:updateAllTopWildData()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local lockedBubble = selfdata.wildPos  -- base已经固定的泡泡
    
    if lockedBubble then
        local currTotalBet = globalData.slotRunData:getCurTotalBet()
        self.m_baseWildData[tostring(currTotalBet)] = lockedBubble

    end
end

function CodeGameScreenManicMonsterMachine:changeBetCreateBubbleNode( )

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local currTotalBet = globalData.slotRunData:getCurTotalBet()
        local lockedBubble = self.m_baseWildData[tostring(currTotalBet)]  -- base已经固定的泡泡

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()

        -- 清除所有泡泡
        self:removeAllBubbleNode(  )
        -- 创建 base 泡泡 
        self:createBaseAllBubbleNode(lockedBubble)
    end
    
end

--进关数据初始化
function CodeGameScreenManicMonsterMachine:initGameStatusData(gameData)
    if gameData then
        if gameData.spin then
            if gameData.spin.selfData then
                if gameData.spin.selfData.wildInit then
                    self.m_baseWildData = clone(gameData.spin.selfData.wildInit)
                end
            end
        end
    end

    BaseNewReelMachine.initGameStatusData(self,gameData)
end

return CodeGameScreenManicMonsterMachine






