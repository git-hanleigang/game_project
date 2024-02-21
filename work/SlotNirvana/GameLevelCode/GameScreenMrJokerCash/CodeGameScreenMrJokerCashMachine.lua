---
-- island li
-- 2019年1月26日
-- CodeGameScreenMrJokerCashMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenMrJokerCashMachine = class("CodeGameScreenMrJokerCashMachine", BaseNewReelMachine)

CodeGameScreenMrJokerCashMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenMrJokerCashMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenMrJokerCashMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenMrJokerCashMachine.SYMBOL_MRJOKERCASH_SCATTER_GOLD = 91
CodeGameScreenMrJokerCashMachine.SYMBOL_MRJOKERCASH_STICKY_WILD = 97
CodeGameScreenMrJokerCashMachine.m_longRun = false
-- 构造函数
function CodeGameScreenMrJokerCashMachine:ctor()
    CodeGameScreenMrJokerCashMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_videoPokeMgr = util_require("LevelVideoPokerCode.VideoPokeManager"):getInstance()
    if self:checkControlerReelType() then
        self.m_videoPokeMgr:initData( self )
    end
    self.m_spinRestMusicBG = true
    self.m_longRun = false
 
    --init
    self:initGame()
end

function CodeGameScreenMrJokerCashMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取游戏区域reel height 这些都是在ccb中配置的 custom properties 属性， 但是目前无法从ccb读取，
-- cocos2dx 未开放接口
--
function CodeGameScreenMrJokerCashMachine:getReelHeight()
    if display.width / display.height >= 1370 / 768 then
        return 560
    else
        return self.m_reelHeight
    end
    
end

function CodeGameScreenMrJokerCashMachine:getReelWidth()
    if display.width / display.height >= 1370 / 768 then
        return 1300
    elseif display.width / display.height >= 1200 / 768 then
        return 1430
    elseif display.width / display.height >= 1060 / 768 then
        return 1450
    else
        return self.m_reelWidth 
    end
    
end

function CodeGameScreenMrJokerCashMachine:scaleMainLayer()
    CodeGameScreenMrJokerCashMachine.super.scaleMainLayer(self)

    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)

end
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMrJokerCashMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MrJokerCash"  
end

function CodeGameScreenMrJokerCashMachine:initFreeSpinBar()
    if globalData.slotRunData.isPortrait == false then
        local node_bar = self.m_bottomUI:findChild("node_bar")
        self.m_baseFreeSpinBar = util_createView("CodeMrJokerCashSrc.MrJokerCashFreespinBarView")
        node_bar:addChild(self.m_baseFreeSpinBar)
        self.m_baseFreeSpinBar:setPositionY(self.m_baseFreeSpinBar:getPositionY()+40)
        util_setCsbVisible(self.m_baseFreeSpinBar, false)
    end
end



function CodeGameScreenMrJokerCashMachine:initUI()

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)
    util_csbScale(self.m_gameBg.m_csbNode, 1)
    self.m_gameBg:runCsbAction("base",true)
    
    self:changeMainUI( )

    self.m_guoChang = util_spineCreate("VideoPoker_guochang",true,true)
    self:findChild("Node_GuoChang"):addChild(self.m_guoChang)
    self.m_guoChang:setVisible(false)

    self:initFreeSpinBar()
 
  

end


function CodeGameScreenMrJokerCashMachine:enterGamePlayMusic(  )

    performWithDelay(self,function(  )
        self:playEnterGameSound( "MrJokerCashSounds/music_MrJokerCash_enter.mp3" )
    end,0.3)
      

end

function CodeGameScreenMrJokerCashMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMrJokerCashMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    -- videoPoker添加ui
    self:addVideoPokerUI( )
    
    self:videoPoker_initGame()
    
    
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_gameBg:runCsbAction("free",true)
        self:changeMainUI( true)
        self:checkChangeFsCount()
    end
end

function CodeGameScreenMrJokerCashMachine:addObservers()
    CodeGameScreenMrJokerCashMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
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

        local soundName = "MrJokerCashSounds/music_MrJokerCash_last_win_".. soundIndex .. ".mp3"
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = "MrJokerCashSounds/music_MrJokerCash_FS_last_win_".. soundIndex .. ".mp3"
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenMrJokerCashMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenMrJokerCashMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMrJokerCashMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil
    if symbolType == self.SYMBOL_SCORE_10 then
        ccbName = "Socre_MrJokerCash_10"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        ccbName = "Socre_MrJokerCash_Scatter2"
    elseif symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
        ccbName = "Socre_MrJokerCash_Scatter1"
    elseif symbolType == self.SYMBOL_MRJOKERCASH_STICKY_WILD then 
        ccbName = "Socre_MrJokerCash_Wild2"
    
    end
    
    return ccbName
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMrJokerCashMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenMrJokerCashMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenMrJokerCashMachine:MachineRule_initGame(spinData)

    
end

function CodeGameScreenMrJokerCashMachine:slotOneReelDownFinishCallFunc(reelCol)

    local maxCol = self:getMaxContinuityBonusCol()
    if maxCol == self.m_iReelColumnNum then
        maxCol = self.m_iReelColumnNum + 1
    end
    if reelCol > maxCol then
        for iCol=1,self.m_iReelColumnNum do
            for iRow=1,self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG) 
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
                   if slotNode.m_currAnimName == "idle2" then
                        slotNode:runIdleAnim()
                   end
                end
            end
        end
    end

   

end

--
--单列滚动停止回调
--
function CodeGameScreenMrJokerCashMachine:slotOneReelDown(_reelCol)    
    CodeGameScreenMrJokerCashMachine.super.slotOneReelDown(self,_reelCol) 

    local maxCol = self:getMaxContinuityBonusCol()
    if _reelCol > maxCol then
        if self.m_reelRunSoundTag ~= -1 then
            --停止长滚音效
            -- printInfo("xcyy : m_reelRunSoundTag2 %d",self.m_reelRunSoundTag)
            gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
            self.m_reelRunSoundTag = -1
        end
    end
    
end

---
-- 显示五个元素在同一条线效果
function CodeGameScreenMrJokerCashMachine:showEffect_FiveOfKind(effectData)
    -- local fiveAnim = FiveOfKindAnima:create()  -- 不在播放five of kind 动画 2017-12-08 11:54:46
    effectData.p_isPlay = true
    self:playGameEffect()
    return true
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMrJokerCashMachine:levelFreeSpinEffectChange()


end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMrJokerCashMachine:levelFreeSpinOverChangeEffect()

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node and node.updateLayerTag then
                node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            end
        end
    end
end
---------------------------------------------------------------------------


----------- FreeSpin相关

-- 重写此函数 一点要调用 BaseMachine.reelDownNotifyPlayGameEffect(self) 而不是 self:playGameEffect()
function CodeGameScreenMrJokerCashMachine:reelDownNotifyPlayGameEffect()
    local time = 0
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and  features[2] ==  SLOTO_FEATURE.FEATURE_FREESPIN then
        time = 18/60
    end
    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function()
        CodeGameScreenMrJokerCashMachine.super.reelDownNotifyPlayGameEffect(self)
        node:removeFromParent()
    end,time)
    
end

---
-- 显示free spin
function CodeGameScreenMrJokerCashMachine:showEffect_FreeSpin(effectData)
    
    self:setMaxMusicBGVolume( )
    
    self.m_ScatterTipMusicPath = "MrJokerCashSounds/music_MrJokerCash_TriggerFs_".. math.random(1,3) ..".mp3"

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if  lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            self.m_reelResultLines[i].enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
            break
        end
    end

    return CodeGameScreenMrJokerCashMachine.super.showEffect_FreeSpin(self,effectData)
end

function CodeGameScreenMrJokerCashMachine:setSlotNodeEffectParent(slotNode)
   local  slotNode = CodeGameScreenMrJokerCashMachine.super.setSlotNodeEffectParent(self,slotNode)
   slotNode:runAnim("actionframe")
    return slotNode
end


function CodeGameScreenMrJokerCashMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )
        self:resetMaskLayerNodes()
        callFun()
        node:removeFromParent()
    end,66/30) -- scatter actionframe 65帧
end
-- FreeSpinstart
function CodeGameScreenMrJokerCashMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("MrJokerCashSounds/music_MrJokerCash_fsStartView.mp3")

    local showFSView = function ( ... )
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                self:changeStickWild(
                        function()
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    )
            end,true)
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:showGuoChang(function(  )
                    self:changeMainUI( true)
                    self.m_gameBg:runCsbAction("base_free",false,function(  )
                        self.m_gameBg:runCsbAction("free",true)
                    end)
                end,function(  )
                    self:changeStickWild(function()
                        self:triggerFreeSpinCallFun()

                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end) 
                end)
                    
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenMrJokerCashMachine:getFsTriggerSlotNode(parentData, symPosData)

    local slotNode = CodeGameScreenMrJokerCashMachine.super.getFsTriggerSlotNode(self,parentData, symPosData)
  
    if slotNode == nil then
        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
    end

    return slotNode
end

function CodeGameScreenMrJokerCashMachine:changeStickWild(func)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self.m_clipParent:getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
            if node and node.updateLayerTag then
                if node.p_symbolType ~= self.SYMBOL_MRJOKERCASH_STICKY_WILD then
                    node:updateLayerTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                end
            end
        end
    end

    local isChange = false
    local callFunc = func
    local stickWildPos = self.m_runSpinResultData.p_fsExtraData.stickWild
    
    for i=1,#stickWildPos do
        local count = i
        local pos = tonumber(stickWildPos[count])
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if targSp then
            if targSp.p_symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
                isChange = true
                targSp:runAnim("actionframe2",false,function(  )
                    local order = targSp:getLocalZOrder()
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_MRJOKERCASH_STICKY_WILD), self.SYMBOL_MRJOKERCASH_STICKY_WILD)
                    targSp:spriteChangeImage(targSp.p_symbolImage, "Symbol/Socre_MrJokerCash_wild_2.png")
                    targSp:setIdleAnimName( "idleframe" )
                    targSp.p_idleIsLoop = false
                    targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                    targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - fixPos.iX
                    targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                    targSp.m_bInLine = true
                    targSp:setLinePos(linePos) 
                    if count == #stickWildPos then
                        if callFunc then
                            callFunc()
                        end
                    end
                end)
                
            end
        end
    end

    if not isChange then
        if func then
            func()
        end
    else
        gLobalSoundManager:playSound("MrJokerCashSounds/music_MrJokerCash_WIldLock.mp3")
    end
end

function CodeGameScreenMrJokerCashMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = lineNode.p_showOrder
                end
                util_changeNodeParent(preParent, lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                lineNode:runIdleAnim()
            end
        end
    end
end

function CodeGameScreenMrJokerCashMachine:getMaskLayerSlotNodeZorder( _slotNode)
    return SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE
end

function CodeGameScreenMrJokerCashMachine:initSuperWildSlotNodesByNetData()
    if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
        return
    end

    local stickWildPos = self.m_runSpinResultData.p_fsExtraData.stickWild
    for k, v in pairs(stickWildPos) do
        local pos = tonumber(v)
        local fixPos = self:getRowAndColByPos(pos)
        local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
        if targSp then
            targSp:changeCCBByName(self:getSymbolCCBNameByType(self, self.SYMBOL_MRJOKERCASH_STICKY_WILD), self.SYMBOL_MRJOKERCASH_STICKY_WILD)
            targSp:spriteChangeImage(targSp.p_symbolImage, "#Symbol/Socre_MrJokerCash_wild_2.png")
            targSp:setIdleAnimName( "idleframe" )
            targSp.p_idleIsLoop = false
            targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
            targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - fixPos.iX
            targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
            local linePos = {}
            linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
            targSp.m_bInLine = true
            targSp:setLinePos(linePos)
        end
    end
end
---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function CodeGameScreenMrJokerCashMachine:initCloumnSlotNodesByNetData()
    CodeGameScreenMrJokerCashMachine.super.initCloumnSlotNodesByNetData(self)

    self:initSuperWildSlotNodesByNetData()
end

function CodeGameScreenMrJokerCashMachine:changeMainUI(_isFree )
    if _isFree then
        self:findChild("Node_reel_base"):setVisible(false)
        self:findChild("Node_reel_free"):setVisible(true)
    else
        self:findChild("Node_reel_base"):setVisible(true)
        self:findChild("Node_reel_free"):setVisible(false)
    end
    
    
end

function CodeGameScreenMrJokerCashMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("MrJokerCashSounds/music_MrJokerCash_over_fs"..math.random(1,2) .. ".mp3")

   

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
   local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    local view = self:showFreeSpinOver( strCoins,freeSpinsTotalCount,function()

        util_setCsbVisible(self.m_baseFreeSpinBar, false)

        self:showGuoChang(function(  )
            self:changeMainUI( )
            self.m_gameBg:runCsbAction("free_base",false,function(  )
                self.m_gameBg:runCsbAction("base",true)
            end)
        end ,function(  )
            self:triggerFreeSpinOverCallFun()
        end)

    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.5,sy=1.5},518)

    local node=view:findChild("m_lb_num")
    view:updateLabelSize({label=node,sx=0.9,sy=0.9},78)
    
end


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMrJokerCashMachine:MachineRule_SpinBtnCall()
    self.m_longRun = false
    self.m_waitNode:stopAllActions()
    self:setMaxMusicBGVolume( )
    self.m_longRunScReset = false
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMrJokerCashMachine:addSelfEffect()



end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMrJokerCashMachine:MachineRule_playSelfEffect(effectData)


    return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMrJokerCashMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenMrJokerCashMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenMrJokerCashMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenMrJokerCashMachine:slotReelDown( )


    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenMrJokerCashMachine.super.slotReelDown(self)
end

function CodeGameScreenMrJokerCashMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end


function CodeGameScreenMrJokerCashMachine:getMaxContinuityBonusCol()
    local maxColIndex = 0

    local isContinuity = true

    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0

        for iRow = 1, self.m_iReelRowNum do
            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
                bonusNum = bonusNum + 1
                if isContinuity then
                    maxColIndex = iCol
                end
            end
        end
        if bonusNum == 0 then
            isContinuity = false
            break
        end
    end

    return maxColIndex
end

function CodeGameScreenMrJokerCashMachine:checkHaveLongRun( )

    local isTriggerLongRun = false

    for iCol=1,self.m_iReelColumnNum do
        --长滚效果
        local reelRunData = self.m_reelRunInfo[iCol]
        local nodeData = reelRunData:getSlotsNodeInfo()
        -- 处理长滚动
        if reelRunData:getNextReelLongRun() == true and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
            isTriggerLongRun = true -- 触发了长滚动
        end
    end
    
    return isTriggerLongRun
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenMrJokerCashMachine:symbolBulingEndCallBack(_slotNode)

    print("-- 快滚时播放scatter为快滚的期待动画，停止快滚时还原为弱idle")
    local maxCol = self:getMaxContinuityBonusCol()
    if _slotNode.p_cloumnIndex <= maxCol then
        if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
            if self.m_isNewReelQuickStop or not self:checkHaveLongRun( ) then
                _slotNode:runIdleAnim()
            else
                _slotNode:runAnim("idle2",true)
            end
        end
    end
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenMrJokerCashMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local nodeList = {}
    for k,_slotNode in pairs(slotNodeList) do
        if _slotNode.p_symbolType then
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
                if _slotNode.p_cloumnIndex <= self:getMaxContinuityBonusCol() then
                    table.insert( nodeList, _slotNode)
                end
            end
        end
        
    end
    CodeGameScreenMrJokerCashMachine.super.playSymbolBulingAnim(self,nodeList, speedActionTable)


--[[
   固定的wild加回弹
--]]
    -- local cloumnIndex = nil
    -- for i=1,#slotNodeList do
    --     local slotNode = slotNodeList[i]
    --     if slotNode.p_cloumnIndex then
    --         cloumnIndex = slotNode.p_cloumnIndex
    --         break
    --     end
    -- end
    -- if cloumnIndex then
    --     print("播放这一列的固定wild回弹")
    --     for iRow=1,self.m_iReelRowNum do
    --         local fixSp = self.m_clipParent:getChildByTag(self:getNodeTag(cloumnIndex, iRow, SYMBOL_NODE_TAG))
    --         if fixSp and fixSp.p_symbolType == self.SYMBOL_MRJOKERCASH_STICKY_WILD then
    --                 --回弹
    --                 local newSpeedActionTable = {}
    --                 for i=1,#speedActionTable do
    --                     if i == #speedActionTable then
    --                         -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
    --                         local resTime = self.m_configData.p_reelResTime
    --                         local index = self:getPosReelIdx(fixSp.p_rowIndex, fixSp.p_cloumnIndex)
    --                         local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
    --                         newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
    --                     else
    --                         newSpeedActionTable[i] = speedActionTable[i]
    --                     end
    --                 end

    --                 local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
    --                 fixSp:runAction(actSequenceClone)
    --         end
    --     end
        
    -- end

end

-- 有特殊需求判断的 重写一下
function CodeGameScreenMrJokerCashMachine:checkSymbolBulingSoundPlay(_slotNode)

    return true
end
-- 两种scatter落地动画
function CodeGameScreenMrJokerCashMachine:playCustomSpecialSymbolDownAct( slotNode )

    CodeGameScreenMrJokerCashMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
        if self:getMaxContinuityBonusCol() >= slotNode.p_cloumnIndex  then
            local soundPath = "MrJokerCashSounds/music_MrJokerCash_ScatterDown.mp3"
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
        end
      
    end

end

-- --设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenMrJokerCashMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i = 1, self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum >= 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 2 then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[1] then
        if nodeNum >= 3 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum > 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

--设置bonus scatter 信息
function CodeGameScreenMrJokerCashMachine:setBonusScatterInfo(symbolType, column, specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column] -- 快滚信息
    local runLen = reelRunData:getReelRunLen() -- 本列滚动长度
    local allSpecicalSymbolNum = specialSymbolNum -- bonus或者scatter的数量（上一轮，判断后得到的）
    local bRun, bPlayAni = reelRunData:getSpeicalSybolRunInfo(symbolType) -- 获得是否进行长滚逻辑和播放长滚动画（true为进行或播放）

    local soundType = runStatus.DUANG
    local nextReelLong = false

    -- scatter 列数限制 self.m_ScatterShowCol 为空则默认为 五列全参与长滚 在：getRunStatus判断
    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
    end

    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    -- for 这里的代码块只是为了添加scatter或者bonus快滚停止时 的音效和动画
    for row = 1, iRow do
        local targetSymbolType = self:getSymbolTypeForNetData(column,row,runLen)
        if targetSymbolType == symbolType or targetSymbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then

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


function CodeGameScreenMrJokerCashMachine:setReelRunInfo( )
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

        if bRunLong == true then --如果上一列长滚
            longRunIndex = longRunIndex + 1 -- 长滚统计加1

            local runLen = self:getLongRunLen(col, longRunIndex) -- 获得本列的长滚动长度
            local preRunLen = reelRunData:getReelRunLen() -- 获得本列普通滚动长度
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen) -- 设置本列滚动长度为快滚长度
        else
            if addLens == true then
                self.m_reelRunInfo[col]:setReelLongRun(false)
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 6)
                self:setLastReelSymbolList()
            end
        end

        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)
        local maxCol = self:getMaxContinuityBonusCol()
        if  col > maxCol then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
        elseif maxCol == col  then
            if bRunLong then
                addLens = true
            end
        end



    end 
end

function CodeGameScreenMrJokerCashMachine:showGuoChang(_currFunc,_endFunc )

    gLobalSoundManager:playSound("MrJokerCashSounds/music_MrJokerCash_GuoChang.mp3")

    self.m_guoChang:setVisible(true)
    util_spinePlay(self.m_guoChang,"actionframe")
    util_spineEndCallFunc(self.m_guoChang,"actionframe",function(  )
        self.m_guoChang:setVisible(false)
        if _endFunc then
            _endFunc()
        end
    end)
    performWithDelay(self,function(  )
        if _currFunc then
            _currFunc()
        end
    end,35/30)
end

---
--设置bonus scatter 层级
function CodeGameScreenMrJokerCashMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    if symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
        return REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    end
    
    return CodeGameScreenMrJokerCashMachine.super.getBounsScatterDataZorder(self,symbolType)
end
function CodeGameScreenMrJokerCashMachine:getClipParentChildShowOrder(slotNode)
    return REEL_SYMBOL_ORDER.REEL_ORDER_2 - slotNode.p_rowIndex 
end
--获取播放连线动画时的层级
function CodeGameScreenMrJokerCashMachine:getSlotNodeEffectZOrder(slotNode)
    return SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - slotNode.p_rowIndex 
end
------------------------------------------------------------
-- videoPoker 相关
------------------------------------------------------
---
-- 处理spin 返回结果
function CodeGameScreenMrJokerCashMachine:spinResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]

        if spinData.action == "SPECIAL" then
             -- 处理bonus消息返回
            self:videoPokerResultCallFun(param)
        else
            CodeGameScreenMrJokerCashMachine.super.spinResultCallFun(self,param)
        end
    else
        -- 处理消息请求错误情况
        gLobalViewManager:showReConnect(true)
    end
end

function CodeGameScreenMrJokerCashMachine:videoPokerResultCallFun(param)

    if param[1] == true then
        local spinData = param[2]
        local userMoneyInfo = param[3]

        if spinData.action == "SPECIAL" then
            gLobalViewManager:removeLoadingAnima()
            local serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_BonusWinCoins = serverWinCoins
            globalData.userRate:pushCoins(serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            -- 更新本地数据
            self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
            -- 更新VideoPoker数据
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            self.m_videoPokeMgr.m_runData:parseData( selfdata )
            local bonus = spinData.result.bonus or {}
            self.m_videoPokeMgr.m_runData:parseData( bonus )
            local extra = bonus.extra or {}
            self.m_videoPokeMgr.m_runData:parseData( extra )

            self.m_videoPokeMgr:handleVideoPokerResult( )
        end

       
    else
        -- 处理消息请求错误情况
        gLobalViewManager:showReConnect(true)
    end
end

function CodeGameScreenMrJokerCashMachine:addVideoPokerUI( )

    self.m_videoPokerGuoChang =  self.m_videoPokeMgr:createVideoPokerGuoChang()
    self:addChild(self.m_videoPokerGuoChang ,self.m_videoPokeMgr.p_Config.UIZORDER.GUOCAHNG)
    self.m_videoPokerGuoChang:setVisible(false)
    self.m_videoPokerGuoChang:setPosition(display.center)
    
    self.m_videoPokerMain =  self.m_videoPokeMgr:createVideoPokerBaseMain()
    self:addChild(self.m_videoPokerMain ,self.m_videoPokeMgr.p_Config.UIZORDER.MAINUI)
    self.m_videoPokerMain:setVisible(false)

    self.m_videoPokerBetChoose =  self.m_videoPokeMgr:createVideoPokerBetChooseView()
    self:addChild(self.m_videoPokerBetChoose ,self.m_videoPokeMgr.p_Config.UIZORDER.BETCHOSEUI)
    self.m_videoPokerBetChoose:setVisible(false)
    if not self.m_videoPokeMgr:checkEntranceCanClick( ) then
        self.m_videoPokeMgr:showVideoPokeChooseBetViewView()
    end

    self.m_entrance = self.m_videoPokeMgr:ceateVideoPokerEntrance( )
    self:findChild("Node_CasinoEntrance"):addChild(self.m_entrance)
end

--[[
    刷新小块
]]
function CodeGameScreenMrJokerCashMachine:updateReelGridNode(_slotNode)
    if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_MRJOKERCASH_SCATTER_GOLD then
        _slotNode:setIdleAnimName( "idle" )
        _slotNode.p_idleIsLoop = true
        _slotNode:runIdleAnim()
    else
        _slotNode:setIdleAnimName( "idleframe" )
        _slotNode.p_idleIsLoop = false
    end
    -- videoPoker收集添加角标
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local iconLocs = selfdata.iconLocs or {}
    self.m_videoPokeMgr:createVideoPokerIcon(_slotNode,self,iconLocs )
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenMrJokerCashMachine:initGameStatusData(gameData)
    -- 数据合并
    local spin = gameData.spin
    local special = gameData.special
    if spin ~= nil then
        if special ~= nil then
            local bonus = special.bonus
            if bonus then
                if bonus.status then
                    gameData.spin.selfData = clone(gameData.special.selfData)
                    gameData.spin.bonus    = clone(gameData.special.bonus)
                end
                self.m_videoPokeMgr.m_runData:parseData( bonus )
                local extra = bonus.extra or {}
                self.m_videoPokeMgr.m_runData:parseData( extra )
            end
            
        end
    else
        gameData.spin = clone(special)
        spin = gameData.spin
    end
    
    CodeGameScreenMrJokerCashMachine.super.initGameStatusData(self,gameData)

    if spin ~= nil then
        local bonus = spin.bonus or {}
        self.m_videoPokeMgr.m_runData:parseData( bonus )
        local extra = bonus.extra or {}
        self.m_videoPokeMgr.m_runData:parseData( extra )
    end
    
end

--[[
   videoPoke断线重连
]]
function CodeGameScreenMrJokerCashMachine:videoPoker_initGame()
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus or ""
    if bonusStatus == "OPEN" then
        local requestType = self.m_videoPokeMgr.m_runData:getRequestType( )
        if requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP then
            -- 消耗筹码开始
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP ) 
            self.m_videoPokerMain:postChipRequestCallFun()
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.HOLDPOKER then
            -- 选择牌型
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.POSTCHIP ) 
            self.m_videoPokerMain:holdPokeRequestCallFun( )
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.COLLECTDOUBLE_START then
            -- double直接结束选择赢钱
            print("直接结束不处理任何逻辑,实际上这块逻辑就不会走进来")
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.COLLECTDOUBLE_MAIN then
            -- double直接结束选择赢钱
            print("直接结束不处理任何逻辑,实际上这块逻辑就不会走进来")
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_MAIN then
            -- doubleMain选择继续翻倍
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_MAIN ) 
            gLobalNoticManager:postNotification(self.m_videoPokeMgr.p_Config.EventType.NOTIFY_REC_SHOW_DOUBLEGAME_MAINVIEW)
            self.m_videoPokerMain:doubleUpMainRequestCallFun( )
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_START then
            -- doubeStart选择继续翻倍
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLEUP_START ) 
            gLobalNoticManager:postNotification(self.m_videoPokeMgr.p_Config.EventType.NOTIFY_SHOW_DOUBLEGAME_MAINVIEW)
        elseif requestType == self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLECLICKPOS then
            -- 发送在double里选择选择牌的位置
            self.m_videoPokeMgr:recVideoPokerBaseMainView()
            self.m_videoPokerMain.m_clicked = true
            self.m_videoPokeMgr:setRequestType(self.m_videoPokeMgr.p_Config.REQUESTTYPR.DOUBLECLICKPOS )
            self.m_videoPokerMain:recDoubleClickPosRequestCallFun( )
        end
        
    end
    
   
end


function CodeGameScreenMrJokerCashMachine:normalSpinBtnCall()
    if ((not tolua.isnull(self.m_videoPokerGuoChang)) and self.m_videoPokerGuoChang:isVisible()) or ((not tolua.isnull(self.m_videoPokerMain)) and self.m_videoPokerMain:isVisible()) then
        return
    end
    
    CodeGameScreenMrJokerCashMachine.super.normalSpinBtnCall(self)
end

return CodeGameScreenMrJokerCashMachine






