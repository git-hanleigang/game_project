---
-- island li
-- 2019年1月26日
-- CodeGameScreenReelRocksMachine.lua
-- 
-- 玩法：
-- 

local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseMachine = require "Levels.BaseMachine"
local CodeGameScreenReelRocksMachine = class("CodeGameScreenReelRocksMachine", BaseNewReelMachine)

CodeGameScreenReelRocksMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}


-- 自定义的小块类型
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_BN = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_PICK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_PICKB = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_BOUNS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_BOUNS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_BOUNS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
CodeGameScreenReelRocksMachine.SYMBOL_SCORE_BOUNS4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11


CodeGameScreenReelRocksMachine.COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 6 -- 收集玩法
CodeGameScreenReelRocksMachine.COMPETITION_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 -- 集满比赛玩法
CodeGameScreenReelRocksMachine.CASH_EXPRESS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- 火车玩法

local GrandName = "m_lb_coins_GRAND"
local MajorName = "m_lb_coins_MAJOR"
local MinorName = "m_lb_coins_MINOR"
local MiniName = "m_lb_coins_MINI" 

CodeGameScreenReelRocksMachine.m_competitionCoins = 0

-- 构造函数
function CodeGameScreenReelRocksMachine:ctor()
    BaseNewReelMachine.ctor(self)
    -- self.m_bCreateResNode = false

    
    self.m_spinRestMusicBG = true

    self.m_isChooseRespinFeature = false
    self.lasetCollectPos = {}

    self.m_clipNode = {}--存储提高层级的图标

    self.m_collectBonus = {}--存储bonus图标

    self.m_collectCar = {}

    self.m_collectJinCar = {}

    self.m_collectStone = {}

    self.m_competitionCoins = 0

    self.m_randomSymbolSwitch = true

    self.isBonusChooseRock = false      --是否是三个Sc选择的Rock玩法
    
    self.BonusChooseRockBubbleList = {}     --存储服务器发来的收集列表

    self.m_bInBonus = false

    self.m_isFeatureOverBigWinInFree = true

    --init
    self:initGame()
end

function CodeGameScreenReelRocksMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("ReelRocksConfig.csv", "LevelReelRocksConfig.lua")
    self.m_isOlnyScatter = false
    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenReelRocksMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "ReelRocks"  
end

function CodeGameScreenReelRocksMachine:initUI()

    


    self:runCsbAction("idle",true)
    self.m_gameBg:runCsbAction("idle2",true)

    local colorLayers = util_createReelMaskColorLayers( self , SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 2 ,cc.c3b(0, 0, 0),200,self:findChild("reelNode") ) 

    for i=1,5 do
        self["m_colorLayer_waitNode_"..i] = cc.Node:create()
        self:addChild(self["m_colorLayer_waitNode_"..i])

        self["colorLayer_"..i] = colorLayers[i]
        if i >1 and i<5 then
            local dark = self["colorLayer_"..i]:getChildren()
            if dark  then
                local size = dark[1]:getContentSize()
                dark[1]:setContentSize(size.width + 4, size.height) 
            end
        end
        
        
    end

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_progress = util_createView("CodeReelRocksSrc.collect.ReelRocksCollectProgress")        --收集进度条
    self:findChild("Node_jingdutiao"):addChild(self.m_progress)

    -- self.m_freeSpinTimesBar = util_createView("CodeReelRocksSrc.ReelRocksFreespinBarView")           --fs次数
    -- self:findChild("Node_freegamedi"):addChild(self.m_freeSpinTimesBar)
    -- self.m_freeSpinTimesBar:setVisible(false)

    self.m_kaiCheLayer = util_createView("CodeReelRocksSrc.ReelRocksCashExpressView")               --开车
    self:findChild("Node_kaiche"):addChild(self.m_kaiCheLayer)
    self.m_kaiCheLayer:setVisible(false)

    self.guoChangView = util_createView("CodeReelRocksSrc.ReelRocksGuoChangView")                   --过场
    self:addChild(self.guoChangView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
    self.guoChangView:setPosition(display.width/2,display.height/2)
    self.guoChangView:setVisible(false)
    

    self.kaiCheCollect_1 = util_createView("CodeReelRocksSrc.ReelRocksCollectKaiChe")
    self:findChild("Node_kaiche_1"):addChild(self.kaiCheCollect_1)
    self.kaiCheCollect_1:setVisible(false)

    self.kaiCheCollect_2 = util_createView("CodeReelRocksSrc.ReelRocksCollectKaiCheJin")
    self:findChild("Node_kaiche_1"):addChild(self.kaiCheCollect_2)
    self.kaiCheCollect_2:setVisible(false)

    local node_bar = self.m_bottomUI.coinWinNode
    self.m_jiesuanAct = util_createAnimation("ReelRocks_Totalwin.csb")
    node_bar:addChild(self.m_jiesuanAct)
    self.m_jiesuanAct:setPositionY(-10)
    self.m_jiesuanAct:setVisible(false)

    --收集玩法棋盘上层遮罩
    self.m_BubbleMainNode = cc.Node:create()
    self:findChild("reelNode"):addChild(self.m_BubbleMainNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    self:initBubble()

    --收集玩法棋盘上层遮罩
    self.m_BubbleMainNode_1 = cc.Node:create()
    self:findChild("reelNode"):addChild(self.m_BubbleMainNode_1,SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 100)
   
    self.jackpotNode = cc.Node:create()
    self:findChild("reelNode"):addChild(self.jackpotNode)

    self.collectTipView = util_createView("CodeReelRocksSrc.ReelRocksCollectActView","ReelRocks_jindutiao_tishi")      --提示按钮
    self:findChild("Node_tishi"):addChild(self.collectTipView)
 
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
        elseif winRate > 3 and winRate <= 6 then
            gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_yippee.mp3")
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "ReelRocksSounds/music_ReelRocks_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

-- function CodeGameScreenReelRocksMachine:setScatterDownScound( )
--     for i = 1, 5 do
--         local soundPath = "ReelRocksSounds/ReelRocks_Scatter_down.mp3"
--         self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
--     end
-- end

--压暗层
function CodeGameScreenReelRocksMachine:showColorLayer( )


    for i=1,5 do
        self["m_colorLayer_waitNode_"..i]:stopAllActions()
        local layerNode = self["colorLayer_"..i]
        util_playFadeInAction(layerNode,0.1)
        layerNode:setVisible(true)
    end
end

function CodeGameScreenReelRocksMachine:hideColorLayer( )


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

function CodeGameScreenReelRocksMachine:updateBottomUICoins(beiginCoins,endCoins,isNotifyUpdateTop,isPlayAnim)
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    local params = {endCoins,isNotifyUpdateTop,isPlayAnim,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    globalData.slotRunData.lastWinCoin = lastWinCoin
    --通知顶部ui后清空了底部的钱
    -- if #self.m_reelResultLines > 0 then
        
    -- else
    --     self.m_bottomUI:notifyTopWinCoin()
    -- end
end

--提示
function CodeGameScreenReelRocksMachine:clicTipView( )
    if not self.m_bSlotRunning then
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_tishi.mp3")
        self.collectTipView:stopAllActions()
        self.collectTipView:runCsbAction("auto",false)
    end
end

function CodeGameScreenReelRocksMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end

    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenReelRocksMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end


function CodeGameScreenReelRocksMachine:scaleMainLayer()
    self.super.scaleMainLayer(self)

    if display.width/display.height <= 920/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 1.005)
        self.m_machineRootScale = self.m_machineRootScale * 1.005
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 21)
    elseif display.width/display.height <= 1152/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 1.01)
        self.m_machineRootScale = self.m_machineRootScale * 1.01
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 25)
    elseif display.width/display.height <= 1228/768 then
        util_csbScale(self.m_machineNode, self.m_machineRootScale * 0.99)
        self.m_machineRootScale = self.m_machineRootScale * 0.99
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() )
        self.m_machineNode:setPositionX(self.m_machineNode:getPositionX() + 15)
    end
        
end
---------------------------------------------------------收集玩法start------------------------------------------------------

function CodeGameScreenReelRocksMachine:updateProgressVisible()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local rank = selfdata.rank or nil
    if rank then
        collectPosition = {}
        self.m_progress:resetProgress()
    else
        self.m_progress:initProgress(#collectPosition)
    end
    
end

--棋盘宝石
function CodeGameScreenReelRocksMachine:initBubble( )
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local bubble = util_createAnimation("Socre_ReelRocks_baoshidi.csb")
            local index = self:getPosReelIdx(iRow ,iCol)
            self.m_BubbleMainNode:addChild(bubble,index,index)    
            local pos = cc.p(util_getOneGameReelsTarSpPos(self,index ) )  
            bubble:setPosition(pos)
        end
    end
end

function CodeGameScreenReelRocksMachine:restAllBubble( )
    local childs = self.m_BubbleMainNode:getChildren()
    for i = 1,#childs do
        local bubble = childs[i]
        if bubble then
            bubble:setVisible(true)
            bubble:runCsbAction("idle")
        end
    end
end

function CodeGameScreenReelRocksMachine:hideAllBubble()
    local childs = self.m_BubbleMainNode:getChildren()
    for i = 1,#childs do
        local bubble = childs[i]
        if bubble then
            bubble:setVisible(false)
        end
    end
end

function CodeGameScreenReelRocksMachine:updateBubbleVisible( isAct )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local newCollect = selfdata.newCollect or {}
    local rank = selfdata.rank or nil

    if #collectPosition > 0 then    --选择玩法隐藏遮罩
        if #self.BonusChooseRockBubbleList > 0 then
            self.BonusChooseRockBubbleList = {}
        end
        self.BonusChooseRockBubbleList = collectPosition
    end

    if rank then    --比赛玩法将收集清空
        collectPosition = {}
        self.BonusChooseRockBubbleList = {} 
    end

    for i = 1,#collectPosition do
        local pos = collectPosition[i]
        local bubble = self.m_BubbleMainNode:getChildByTag(pos)
        if bubble then
            bubble:setVisible(false)
        end
    end
    if isAct then
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_baoShi_collect.mp3")
        for i=1,#newCollect do
            local pos = newCollect[i]
            --创建临时遮挡，用来播动画
            local bubbleLin = util_createAnimation("Socre_ReelRocks_baoshidi.csb")
            self.m_BubbleMainNode_1:addChild(bubbleLin) 
            local pos_1 = cc.p(util_getOneGameReelsTarSpPos(self,pos ) )  
            bubbleLin:setPosition(pos_1)
            bubbleLin:runCsbAction("actionframe",false,function(  )
                local bubble = self.m_BubbleMainNode:getChildByTag(pos)
                if bubble then
                    bubble:setVisible(false)
                end
                bubbleLin:removeFromParent()
            end)
        end 
    end
end

function CodeGameScreenReelRocksMachine:updateBubbleVisibleForBonus()
    
    for i = 1,#self.BonusChooseRockBubbleList do
        local pos = self.BonusChooseRockBubbleList[i]
        local bubble = self.m_BubbleMainNode:getChildByTag(pos)
        if bubble then
            bubble:setVisible(false)
        end
    end
end

function CodeGameScreenReelRocksMachine:createCollectBubbleAct( func )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local newCollect = selfdata.newCollect or {}
    local waitTime = 0.3

    local currTable = {}
    
    for i=1,#newCollect do
        local index = newCollect[i]

        local fixPos = self:getRowAndColByPos(index)

        if currTable[fixPos.iY] == nil then
            currTable[fixPos.iY] = {}
        end
        table.insert(currTable[fixPos.iY],index)
    end

    local actTable = {}

    for iCol =1,self.m_iReelColumnNum do
        local data = currTable[iCol]
        if data  then
            for iRow = 1,#data do
                table.insert(actTable,data[iRow])
            end
            
        end
    end

    local actMainNode = cc.Node:create()
    self:findChild("reelNode"):addChild(actMainNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)

    for i=1,#actTable do
        local startIndex = actTable[i]

        local actNdoe = util_createAnimation("ReelRocks_jindutiao_baoshi_shouji.csb")
        local particle1 = actNdoe:findChild("Particle_1")
        actNdoe:runCsbAction("actionframe")
        local flyNode = cc.Node:create()
        flyNode:addChild(actNdoe)
        actMainNode:addChild(flyNode, 1)
        local StartPos = cc.p(util_getOneGameReelsTarSpPos(self,startIndex)) 
        local endPos = cc.p(util_getConvertNodePos(self.m_progress:getEndNode(i),flyNode)) 

        flyNode:setPosition(StartPos)

        local actList = {}
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            particle1:setDuration(-1)     --设置拖尾时间(生命周期)
            particle1:setPositionType(0)   --设置可以拖尾
            particle1:resetSystem()
        end)
        actList[#actList + 1] = cc.BezierTo:create(waitTime,{cc.p(StartPos.x , StartPos.y), cc.p(endPos.x, StartPos.y), endPos})
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            particle1:stopSystem()--移动结束后将拖尾停掉
        end)
        actList[#actList + 1] = cc.DelayTime:create(waitTime + 0.5)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            flyNode:removeFromParent()
        end)
        local sq = cc.Sequence:create(actList)
        flyNode:runAction(sq)
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        scheduler.performWithDelayGlobal(function (  )
    
            self.m_progress:updateProgress(#actTable)
            
            if func then
                if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
                    performWithDelay(self, function()
                        func()
                    end, 1)
                else
                    func()
                end
            end
        end,waitTime,self:getModuleName())
    else
        scheduler.performWithDelayGlobal(function ()
            self.m_progress:updateProgress(#actTable)
            if func then
                if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
                    performWithDelay(self, function()
                        func()
                    end, 1)
                end
            end
        end,waitTime,self:getModuleName())
        if func then
            if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false then
                func()
            end
        end
    end
end

---------------------------------------------------------收集玩法end------------------------------------------------------

---------------------------------------------------------cash express玩法start------------------------------------------------------
--开金色车(金色车先出现框)
function CodeGameScreenReelRocksMachine:showJinCarCollect( effectData)
    self:showColorLayer()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusWinCoins = selfData.bonusWinCoins or 0
    local specialCoins = selfData.specialCoins or {}    --金色火车
    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- self.kaiCheCollect_2:stopAllActions()
    self.kaiCheCollect_2:resetCoins()
    self:showGoldCarAnim(self.SYMBOL_SCORE_PICK,function (  )
        local carNum = #specialCoins
        self.m_kaiCheLayer:setVisible(true)
        self.m_kaiCheLayer:runCsbAction("start",false,function (  )

            self:findChild("reelNode"):setVisible(false)

            self:clearCurMusicBg()
            self:resetMusicBg(nil,"ReelRocksSounds/music_ReelRocks_Car.mp3")
            self:removeSoundHandler()
            self.m_kaiCheLayer:runCsbAction("idle",false)
        end)
        self.m_kaiCheLayer:initTraiNode(specialCoins,self.SYMBOL_SCORE_PICK)
        local tempSpCoins = specialCoins
        self.m_kaiCheLayer:carRunAct()
        schedule(self.m_kaiCheLayer,function (  )
            if carNum == 0 then
                self.m_kaiCheLayer:stopAllActions()
                self.m_kaiCheLayer:removeAllCar()
                self.m_kaiCheLayer:runCsbAction("over",false,function (  )
                    self:findChild("reelNode"):setVisible(true)
                    self.m_kaiCheLayer:setVisible(false)
                end)
                self:collectCoinsByGoldCar(self.kaiCheCollect_2,function (  )      --将板子上的分数显示在车上
                    -- self.kaiCheCollect_2:runCsbAction("over",false)
                    self.kaiCheCollect_2:setVisible(false)
                    self:showBonusToLayer(function (  )
                        self:collectCoins(self.m_bottomUI:findChild("node_bar"),function (  )
                            self:collectCar(self.m_bottomUI:findChild("node_bar"),function (  )     --收集车
                                self:collectGoldCar(self.m_bottomUI:findChild("node_bar"),function (  )     --收集金车
                                    self:showCompetitionOver(bonusWinCoins,function (  )
                                        self.m_bottomUI:notifyTopWinCoin()
                                        self:clearCollectBonusList()
                                        self:clearCollectCarList()
                                        self:clearCollectJinCarList()
                                        self:hideColorLayer()

                                        if self.isBonusChooseRock then
                                            self:restAllBubble()

                                            self:updateBubbleVisibleForBonus()
                                            self.isBonusChooseRock = false
                                        end
                                        
                                        self:resetMusicBg()
                                        self:reelsDownDelaySetMusicBGVolume( ) 
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end)
                                end)
                            end)
                        end)
                    end)
                end)
            else
                local endPos = cc.p(0,0)
                self.m_kaiCheLayer:updataCarPos(function (  )
                    local curNode = self.m_kaiCheLayer:getCurNode()
                    self:runFlyCoins(curNode,endPos,function (  )
                        carNum = carNum - 1
                        self.kaiCheCollect_2:runCsbAction("actionframe3")
                        performWithDelay(self.kaiCheCollect_2,function(  )
                            self.kaiCheCollect_2:runCsbAction("idle2",true)
                        end,0.5)
                        self.kaiCheCollect_2:UpdateWinLabel(tempSpCoins[1],false)
                    end)
                end)
            end
        end,0.05)
    end)
end

function CodeGameScreenReelRocksMachine:showCashExpreeView(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bnCoin = selfData.bnCoins or {}

    local bnCoins = {}
    copyTable(bnCoin,bnCoins)

    local bonusCoins = selfData.bonusCoins or {}
    local specialCoins = selfData.specialCoins or {}    --金色火车
    local bonusWinCoins = selfData.bonusWinCoins or 0
    if self:getListlength(bnCoins) == 0 and self:getListlength(bonusCoins) == 0 then
        effectData.p_isPlay = true
        self:playGameEffect()
    end 
    performWithDelay(self,function (  )
        self:setSymbolToReel()
        if #specialCoins > 0 then   --有金色火车
            if self:getListlength(bnCoins) > 0 then    --前四列是否有火车
                local curCarData = self:carData(bnCoins)
                self:showColorLayer()
                self:nomalCarMove(curCarData,self.SYMBOL_SCORE_PICK,function(  )
                    performWithDelay(self,function (  )
                            --出现框
                        self.kaiCheCollect_2:setVisible(true)
                        self.kaiCheCollect_2:resetCoins()
                        self:collectCoinsByBoard(self.kaiCheCollect_2,function(  )
                            performWithDelay(self,function (  )
                                self.kaiCheCollect_2:changeCoins(specialCoins[1])
                            end,0.16)
                            local zhaSoundId = gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_kaichejin_zha.mp3")
                            -- self.kaiCheCollect_2:runCsbAction("start",false,function (  )
                                self.kaiCheCollect_2:stopAllActions()
                                self.kaiCheCollect_2:runCsbAction("start",false)
                                performWithDelay(self.kaiCheCollect_2,function (  )
                                    self.kaiCheCollect_2:runCsbAction("idle",false,function (  )
                                        if zhaSoundId then
                                            gLobalSoundManager:stopAudio(zhaSoundId)
                                        end
                                        local upSoundId = gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_kaiche2_up.mp3")
                                        self.kaiCheCollect_2:runCsbAction("actionframe2",false,function (  )        --钱数移动至右上角
                                            
                                            performWithDelay(self,function (  )
                                                local coins = specialCoins[1]
                                                self.kaiCheCollect_2:initTop(coins)     --右上角钱数，代表每节车厢的钱数
                                            end,31/60)
                                            if upSoundId then 
                                                gLobalSoundManager:stopAudio(upSoundId)
                                            end
    
                                            gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_kaiche2_za.mp3")
                                            self.kaiCheCollect_2:runCsbAction("actionframe4",false,function (  )    --板子落下
                                                self.kaiCheCollect_2:resetCoins()
                                                self.kaiCheCollect_2:runCsbAction("idle2",false,function (  )
                                                    self:showJinCarCollect(effectData)
                                                end)
                                            end)
                                        end)
                                    end)
                                end,40/60)
                                
                            -- end)
                        end)
                    end,1.5)  
                end)
            else
                --出现框
                self.kaiCheCollect_2:setVisible(true)
                self:collectCoinsByBoard(self.kaiCheCollect_2,function(  )
                    performWithDelay(self,function (  )
                        self.kaiCheCollect_2:changeCoins(specialCoins[1])
                    end,0.16)
                    local zhaSoundId = gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_kaichejin_zha.mp3")
                    -- self.kaiCheCollect_2:runCsbAction("start",false,function (  )
                        self.kaiCheCollect_2:stopAllActions()
                        self.kaiCheCollect_2:runCsbAction("start",false)
                        performWithDelay(self.kaiCheCollect_2,function (  )
                            self.kaiCheCollect_2:runCsbAction("idle",false,function (  )
                                if zhaSoundId then
                                    gLobalSoundManager:stopAudio(zhaSoundId)
                                end
                                local upSoundId = gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_kaiche2_up.mp3")
                                self.kaiCheCollect_2:runCsbAction("actionframe2",false,function (  )        --钱数移动至右上角
                                    
                                    performWithDelay(self,function (  )
                                        local coins = specialCoins[1]
                                        self.kaiCheCollect_2:initTop(coins)     --右上角钱数，代表每节车厢的钱数
                                    end,31/60)
                                    if upSoundId then 
                                        gLobalSoundManager:stopAudio(upSoundId,true)
                                    end
                                    gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_kaiche2_za.mp3")
                                    self.kaiCheCollect_2:runCsbAction("actionframe4",false,function (  )    --板子落下
                                        self.kaiCheCollect_2:resetCoins()
                                        self.kaiCheCollect_2:runCsbAction("idle2",false,function (  )
                                            self:showJinCarCollect(effectData)
                                        end)
                                    end)
                                end)
                            end)
                        end,40/60)
                        
                    -- end)
                end)
            end
        else
            if self:getListlength(bnCoins) > 0 then    --前四列是否有火车
                local curCarData = self:carData(bnCoins)
                self:showColorLayer()
                self:nomalCarMove(curCarData,self.SYMBOL_SCORE_PICKB,function(  )
                    self:clearCurMusicBg()
                    local bnCoinsAll = self:getCollectListCoins(bonusCoins)
                    self:showBonusToLayer(function (  )
                        self:showStoneAndCoinsBnAnim(function (  )
                            self:collectCoins(self.m_bottomUI:findChild("node_bar"),function (  )        --收钱
                                self:collectCar(self.m_bottomUI:findChild("node_bar"),function (  )      --收车
                                    self:showCompetitionOver(bonusWinCoins,function (  )        --结束弹板
                                        self.m_bottomUI:notifyTopWinCoin()
                                        self:clearCollectStoneList()
                                        self:clearCollectBonusList()
                                        self:clearCollectCarList()
                                        self:clearCollectJinCarList()

                                        if self.isBonusChooseRock then
                                            self:restAllBubble()

                                            self:updateBubbleVisibleForBonus()
                                            self.isBonusChooseRock = false
                                        end
                                        
                                        self:hideColorLayer()
                                        self:resetMusicBg()
                                        self:reelsDownDelaySetMusicBGVolume( ) 
                                        effectData.p_isPlay = true
                                        self:playGameEffect()
                                    end)
                                end)
                            end)
                        end)
                    end)
                end)
            else
                --触发动画
                self:showBonusToLayer(function (  )
                    -- 停止播放背景音乐
                    self:clearCurMusicBg()
                    self:showStoneAndCoinsBnAnim(function (  )
                        self:collectCoins(self.m_bottomUI:findChild("node_bar"),function (  )
                            self.m_bottomUI:notifyTopWinCoin()
                            self:clearCollectStoneList()
                            self:clearCollectBonusList()
                            self:clearCollectCarList()
                            self:clearCollectJinCarList()

                            if self.isBonusChooseRock then
                                self:restAllBubble()
                                
                                self:updateBubbleVisibleForBonus()
                                self.isBonusChooseRock = false
                            end
                            
                            self:hideColorLayer()
                            self:resetMusicBg()
                            self:reelsDownDelaySetMusicBGVolume( ) 
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end)
                    end)
                    
                end)
            end
        end
    end,0.3)
    
end

--将服务器给到的字段重新排布（将车按照mini-minor-major-grand顺序排序）
function CodeGameScreenReelRocksMachine:carData(list)
    local tempList = {}
    for k,v in pairs(list) do
        table.insert( tempList,{pos = k,data = v})
    end
    -- table.sort( tempList, function( a,b )
    --     local typeA = self:getCarType(a.pos)
    --     local typeB = self:getCarType(b.pos)
    --     return typeA < typeB
    -- end )
    local sorTab = {}
    for k,v in pairs(tempList) do
        local index = {pos = v.pos,data = v.data}
        local fixPos = self:getRowAndColByPos(index.pos)
        if not sorTab[fixPos.iY] then
            sorTab[fixPos.iY] = {}
        end
        table.insert(sorTab[fixPos.iY],index)
        table.sort( sorTab[fixPos.iY],function ( a,b )
            local posA = a.pos
            local posB = b.pos
            return posA < posB
        end)
    end

    tempList = {}
    for i,v1 in pairs(sorTab) do
        for j,v2 in pairs(v1) do
            table.insert( tempList, v2 )
        end
    end

    -- table.sort( tempList, function ( a,b )
    --     local posA = tonumber(a.pos)
    --     local posB = tonumber(b.pos)
    --     local fixPosA = self:getRowAndColByPos(posA)
    --     local fixPosB = self:getRowAndColByPos(posB)
    --     local posyA = fixPosA.iY
    --     local posyB = fixPosB.iY
    --     return posyA < posyB
    -- end )
    return tempList
end

--递归播开车动画(type是第五列小块类型)
function CodeGameScreenReelRocksMachine:nomalCarMove(bnCoinsList,type,func)
    if #bnCoinsList == 0 then
        if func then
            func()
        end
        return
    end
    --获取车的类型（bnCoinsList[1].pos是前四列车的绝对位置）
    local carType = self:getCarType(bnCoinsList[1].pos)
    self:showColorLayer()
    -- 停止播放背景音乐
    self:clearCurMusicBg()
    --触发动画
    self:showSlotsAnimForCar(bnCoinsList[1].pos,bnCoinsList[1].data,type,function (  )
        local carNum = #(bnCoinsList[1].data)
        --跑普通火车
        self.m_kaiCheLayer:setVisible(true)
        self.m_kaiCheLayer:runCsbAction("start",false,function (  )

            self:findChild("reelNode"):setVisible(false)

            self:clearCurMusicBg()
            self:resetMusicBg(nil,"ReelRocksSounds/music_ReelRocks_Car.mp3")
            self:removeSoundHandler()
            self.m_kaiCheLayer:runCsbAction("idle",false)
        end)
        self.kaiCheCollect_1:setVisible(true)
        self.kaiCheCollect_1:setJackpotShow(carType)
        self.kaiCheCollect_1:resetCoins()
        self.kaiCheCollect_1:stopAllActions()
        self.kaiCheCollect_1:runCsbAction("start")
        performWithDelay(self.kaiCheCollect_1,function(  )
            self.kaiCheCollect_1:runCsbAction("idle",true)
        end,40/60)
        
        if carType == nil then return end
        self.m_kaiCheLayer:initTraiNode(bnCoinsList[1].data,carType)
        local tempCoins = bnCoinsList[1].data
        self.m_kaiCheLayer:carRunAct()
            --进行火车移动，并且向钱数框加钱
        schedule(self.m_kaiCheLayer,function (  )
            if carNum == 0 then
                self.m_kaiCheLayer:stopAllActions()
                self:carCollectAndMove(bnCoinsList,carType,type,func)
            else
                local endPos = cc.p(0,0)
                self.m_kaiCheLayer:updataCarPos(function (  )
                    -- gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_carCollectActionframe.mp3")
                    local curNode = self.m_kaiCheLayer:getCurNode()
                    self:runFlyCoins(curNode,endPos,function (  )
                        carNum = carNum - 1
                        self.kaiCheCollect_1:runCsbAction("actionframe")
                        performWithDelay(self.kaiCheCollect_1,function(  )
                            self.kaiCheCollect_1:runCsbAction("idle",true)
                        end,0.5)
                        self.kaiCheCollect_1:UpdateWinLabel(tempCoins[1])
                        table.remove( tempCoins,1)
                    end)
                end)
            end
        end,0.05)
    end)
end

function CodeGameScreenReelRocksMachine:carCollectAndMove(bnCoinsList,carType,type,func)
    local isHaveJackpot = self.m_kaiCheLayer:getIsHaveJackpot()
    self.m_kaiCheLayer:removeAllCar()
    self:findChild("reelNode"):setVisible(true)
    self.m_kaiCheLayer:runCsbAction("over",false,function (  )
        -- self:clearCurMusicBg()
        -- self:resetMusicBg()
        -- self:reelsDownDelaySetMusicBGVolume( ) 
        self.m_kaiCheLayer:setVisible(false)
    end)
    --判断是否有jackpot
    if isHaveJackpot > 0 then
        self:clearCurMusicBg()
        self:showJackpotWinView(carType,isHaveJackpot,function (  )
            self:resetMusicBg()
            self:reelsDownDelaySetMusicBGVolume( ) 
            self:collectCoinsByCar(bnCoinsList[1],self.kaiCheCollect_1,function (  )
                self.kaiCheCollect_1:setVisible(false)
                table.remove(bnCoinsList,1)
                self.m_kaiCheLayer:setIsHaveJackpot()
                self:nomalCarMove(bnCoinsList,type,func)
            end)
        end)
    else
        self:resetMusicBg()
        self:reelsDownDelaySetMusicBGVolume( ) 
        self:collectCoinsByCar(bnCoinsList[1],self.kaiCheCollect_1,function (  )
            self.kaiCheCollect_1:setVisible(false)
            table.remove(bnCoinsList,1)
            self:nomalCarMove(bnCoinsList,type,func)
        end)
    end
    
end

function CodeGameScreenReelRocksMachine:changeParentNode(node)
    local nodeParent = node:getParent()
    node.m_preX = node:getPositionX()
    node.m_preY = node:getPositionY()
    local pos = nodeParent:convertToWorldSpace(cc.p(node.m_preX, node.m_preY))
    pos = self:findChild("Node_kaiche_1"):convertToNodeSpace(pos)
    util_changeNodeParent(self:findChild("Node_kaiche_1"),node)       --修改父节点
    node:setPosition(pos.x, pos.y)
end

function CodeGameScreenReelRocksMachine:runFlyCoins(curNode,endPos,func)
    local nodeCoins = nil
    if curNode.showJackpot == true then
        nodeCoins = curNode:findChild("ReelRocks_tbmini_10")
    else
        nodeCoins = curNode:findChild("m_lb_coins")
    end

    --改变coins的父节点
    self:changeParentNode(nodeCoins)

    local actList = {}
    actList[#actList + 1]  = cc.MoveTo:create(0.3,endPos)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        nodeCoins:setVisible(false)
    end)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    nodeCoins:runAction(sq)
end

--车触发玩法(车的位置,石头的类型，func)
function CodeGameScreenReelRocksMachine:showSlotsAnimForCar(carPos,carDate,type2,func)
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)     --获取到小块
            if symbol ~= nil then
                if symbol.p_symbolType == type2 then
                    local startPos = util_convertToNodeSpace(symbol,self:findChild("root"))
                    local carPos = tonumber(carPos)
                    local fixPos = self:getRowAndColByPos(carPos)
                    local carSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)     --获取到小块
                    local endPos = util_convertToNodeSpace(carSymbol,self:findChild("root")) 
                    local symbol_type =  self:getSymbolTypeByPos(carPos)  
                    self:flyTrain(startPos,endPos,type2,symbol_type,carDate[1],func)         
                end
            end
        end
    end
end

function CodeGameScreenReelRocksMachine:showStoneAndCoinsBnAnim(func)
    for i=1,#self.m_collectStone do
        local fiveNode = self.m_collectStone[i]
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_baoShi_chuFa.mp3")
        fiveNode:runCsbAction("actionframe",false)
    end
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,110/60)
    
end

function CodeGameScreenReelRocksMachine:showGoldCarAnim(type,func)
    local endPos = util_convertToNodeSpace(self:findChild("Node_car_pos"),self:findChild("root"))
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)     --获取到小块
            if symbol ~= nil then
                if symbol.p_symbolType == type then
                    local startPos = util_convertToNodeSpace(symbol,self:findChild("root"))  
                    self:flyGoldCar(startPos,endPos,type,func)         
                end
            end
        end
    end
end

function CodeGameScreenReelRocksMachine:flyGoldCar(startPos,endPos,type,func)
    -- 停止播放背景音乐
    self:clearCurMusicBg()

    local car = util_createAnimation(self:getTrainCsbName(type)) 
    car:setPosition(startPos)
    self:findChild("root"):addChild(car,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1 )
    
    local actList = {}
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        car:findChild("m_lb_coins"):setVisible(false)
    end)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_car_chuFa.mp3")
        car:runCsbAction("actionframe3",false)
    end)
    actList[#actList + 1]  = cc.DelayTime:create(1)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        --创建小人
        --根据type 拿到需要创建的小人
        local spineName = self:getSpineNameForType(type)
        self.carPeople = util_spineCreate(spineName,true,true)
        car:findChild("juese"):addChild(self.carPeople)
        
        util_spinePlay(self.carPeople,"actionframe",false)
        util_spineEndCallFunc(self.carPeople,"actionframe",function (  )
            util_spinePlay(self.carPeople,"idleframe",true)
        end)
    end)
    actList[#actList + 1]  = cc.DelayTime:create(1)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        car:runCsbAction("actionframe1",false)
    end)
    actList[#actList + 1]  = cc.DelayTime:create(1/6)
    actList[#actList + 1]  = cc.MoveTo:create(3/4,cc.p(endPos))
    actList[#actList + 1]  = cc.DelayTime:create(11/30)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        car.isHead = true
        self.m_kaiCheLayer:insetHeadToList(car)
        if func then
            func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    car:runAction(sq)
end

function CodeGameScreenReelRocksMachine:showBonusToLayer(func)
    self:showColorLayer()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusCoins = selfData.bonusCoins or {}
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)     --获取到小块
            if symbol ~= nil then
                if symbol.p_symbolType == self.SYMBOL_SCORE_BN then
                    local startPos = util_convertToNodeSpace(symbol,self:findChild("root")) 
                    local bonusNode = util_createAnimation(self:createFiveNode(symbol.p_symbolType))
                    local index = self:getPosReelIdx(iRow ,iCol)
                    bonusNode.bnSort = index
                    local score = self:getFlyCoinsPos(symbol.p_symbolType,index)
                    bonusNode:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
                    bonusNode:setPosition(startPos)
                    self:findChild("root"):addChild(bonusNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    table.insert( self.m_collectBonus,bonusNode)
                elseif symbol.p_symbolType == self.SYMBOL_SCORE_BOUNS1 or symbol.p_symbolType == self.SYMBOL_SCORE_BOUNS2 or symbol.p_symbolType == self.SYMBOL_SCORE_BOUNS3 or symbol.p_symbolType == self.SYMBOL_SCORE_BOUNS4 then
                    local startPos = util_convertToNodeSpace(symbol,self:findChild("root")) 
                    local bonusNode = util_createAnimation(self:getTrainCsbName(symbol.p_symbolType))
                    local index = self:getPosReelIdx(iRow ,iCol)
                    local score = self:getFlyCoinsPos(symbol.p_symbolType,index)
                    bonusNode.p_symbolType = symbol.p_symbolType
                    bonusNode.carSort = index
                    bonusNode:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
                    bonusNode:findChild("Node_zi"):setVisible(true)
                    bonusNode:findChild("Node_zi"):setOpacity(255)
                    bonusNode:setPosition(startPos)
                    self:findChild("root"):addChild(bonusNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    table.insert( self.m_collectCar,bonusNode)
                elseif symbol.p_symbolType == self.SYMBOL_SCORE_PICK then
                    local startPos = util_convertToNodeSpace(symbol,self:findChild("root")) 
                    local bonusNode = util_createAnimation(self:getTrainCsbName(symbol.p_symbolType))
                    local index = self:getPosReelIdx(iRow ,iCol)
                    local score = self:getFlyCoinsPos(symbol.p_symbolType,index)
                    bonusNode.p_symbolType = symbol.p_symbolType
                    bonusNode:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
                    bonusNode:findChild("Node_zi"):setVisible(true)
                    bonusNode:findChild("Node_zi"):setOpacity(255)
                    bonusNode:setPosition(startPos)
                    self:findChild("root"):addChild(bonusNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    table.insert( self.m_collectJinCar,bonusNode)
                elseif symbol.p_symbolType == self.SYMBOL_SCORE_PICKB then
                    local startPos = util_convertToNodeSpace(symbol,self:findChild("root")) 
                    local bonusNode = util_createAnimation(self:createFiveNode(symbol.p_symbolType))
                    bonusNode.p_symbolType = symbol.p_symbolType
                    bonusNode:setPosition(startPos)
                    self:findChild("root"):addChild(bonusNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    table.insert( self.m_collectStone,bonusNode)
                end
            end
        end
    end
    if func then
        func()
    end
end

--获取钱数
function CodeGameScreenReelRocksMachine:getFlyCoinsPos(type,index)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusCoins = selfData.bonusCoins or {}
    local bnCoin = selfData.bnCoins or {}
    local specialCoins = selfData.specialCoins or {}    --金色火车
    if type == self.SYMBOL_SCORE_BOUNS1 or type == self.SYMBOL_SCORE_BOUNS2 or type == self.SYMBOL_SCORE_BOUNS3 or type == self.SYMBOL_SCORE_BOUNS4 then
        for k,v in pairs(bnCoin) do
            local pos = tonumber(k)
            if index == pos then
                return self:getListCoins(v)
            end
        end
    elseif type == self.SYMBOL_SCORE_PICK then
        return self:getListCoins(specialCoins)
    elseif type == self.SYMBOL_SCORE_BN then
        for k,v in pairs(bonusCoins) do
            local pos = tonumber(k)
            if index == pos then
                return v
            end
        end
    end
end

function CodeGameScreenReelRocksMachine:createFiveNode(nodeType)
    if nodeType == self.SYMBOL_SCORE_PICKB then
        return "Socre_ReelRocks_Bonus_baoshi.csb"
    elseif nodeType == self.SYMBOL_SCORE_PICK then
        return "Socre_ReelRocks_CAR_5.csb"
    elseif nodeType == self.SYMBOL_SCORE_BN then
        return "Socre_ReelRocks_Bonus_2.csb"
    end
    return nil
end

function CodeGameScreenReelRocksMachine:getSpineNameForType(type)
    if type == 101 then
        return "Socre_ReelRocks_5_2"
    elseif type == 102 then
        return "Socre_ReelRocks_6_2"
    elseif type == 103 then
        return "Socre_ReelRocks_7_2"
    elseif type == 104 then
        return "Socre_ReelRocks_8_2"
    elseif type == 97 then
        return "Socre_ReelRocks_9_2"
    end
end

--车触发并且移动(参数：宝石位置，车位置，宝石类型，车类型)
function CodeGameScreenReelRocksMachine:flyTrain(pos1,pos2,type2,type,firstCarDate,func)
    

    local fiveNode = util_createAnimation(self:createFiveNode(type2))
    local car = util_createAnimation(self:getTrainCsbName(type))
    car:findChild("m_lb_coins"):setVisible(false)
    car:findChild("ReelRocks_tbmini_10"):setVisible(false)
    fiveNode:setPosition(pos1)
    car:setPosition(pos2)
    self:findChild("root"):addChild(fiveNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1 )
    self:findChild("root"):addChild(car,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1 )
    local carMovePos = util_convertToNodeSpace(self:findChild("Node_car_pos"),self:findChild("root"))
    self.m_kaiCheLayer:setHeadCarPosY(carMovePos.y)
    local actList = {}
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        
        fiveNode:runCsbAction("actionframe",false)
    end)
    actList[#actList + 1]  = cc.DelayTime:create(1)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_baoShi_chuFa.mp3")
        self:runFlyLineAct(self.SYMBOL_SCORE_PICKB,pos1,pos2)
    end)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_car_chuFa.mp3")
        car:runCsbAction("actionframe3",false)
    end)
    actList[#actList + 1]  = cc.DelayTime:create(1)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        --创建小人
        --根据type 拿到需要创建的小人
        local spineName = self:getSpineNameForType(type)
        self.carPeople = util_spineCreate(spineName,true,true)
        car:findChild("juese"):addChild(self.carPeople)
        util_spinePlay(self.carPeople,"actionframe",false)
        util_spineEndCallFunc(self.carPeople,"actionframe",function (  )
            util_spinePlay(self.carPeople,"idleframe",true)
        end)
    end)
    actList[#actList + 1]  = cc.DelayTime:create(1)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        car:runCsbAction("actionframe1",false)
    end)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        fiveNode:removeFromParent()
    end)
    actList[#actList + 1]  = cc.DelayTime:create(1/6)
    actList[#actList + 1]  = cc.MoveTo:create(3/4,cc.p(carMovePos))
    actList[#actList + 1]  = cc.DelayTime:create(11/30)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        car.isHead = true
        self.m_kaiCheLayer:insetHeadToList(car)
        if func then
            func()
        end
    end)
    local sq = cc.Sequence:create(actList)
    car:runAction(sq)
end

function CodeGameScreenReelRocksMachine:getTrainCsbName(type)
    if type == 101 then
        return "Socre_ReelRocks_CAR_1.csb"
    elseif type == 102 then
        return "Socre_ReelRocks_CAR_2.csb"
    elseif type == 103 then
        return "Socre_ReelRocks_CAR_3.csb"
    elseif type == 104 then
        return "Socre_ReelRocks_CAR_4.csb"
    elseif type == 97 then
        return "Socre_ReelRocks_CAR_5.csb"
    end
end

--将板子上的钱飞到车上(node为板子)  普通火车
function CodeGameScreenReelRocksMachine:collectCoinsByCar(carData,node,func)
    self:hideColorLayer()
    local startPos = util_convertToNodeSpace(node,self:findChild("root"))     --粒子飞行初始位置
    local pos = tonumber(carData.pos)
    local fixPos = self:getRowAndColByPos(pos)
    local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)     --获取到小块
    local endPos = util_convertToNodeSpace(symbol,self:findChild("Node_kaiche_1"))      --粒子飞行最终位置
    local carType = self:getCarType(carData.pos)
    local coinsList = self:getCollectBnCoins(carData.pos)
    local coinsNum = self:getListCoins(coinsList)

    self.kaiCheCollect_1:stopAllActions()

    self.kaiCheCollect_1:runCsbAction("over",false,function (  )
        self.kaiCheCollect_1:runCsbAction("actionframe2",false)
        self.kaiCheCollect_1:findChild("Node_31"):runAction(cc.MoveTo:create(0.25,endPos))
    end)
    performWithDelay(self,function (  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_qian_za_car.mp3")

        symbol:runAnim("actionframe4",false)
        performWithDelay(self,function (  )
            symbol:getCcbProperty("Node_zi"):setVisible(true)
            symbol:getCcbProperty("Node_zi"):setOpacity(255)
            symbol:getCcbProperty("m_lb_coins"):setString(util_formatCoins(coinsNum, 3))     --将板子上的钱数显示在车上
        end,0.08)

    end,0.75)
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,1.25)
end

--获取第五列火车的小块，用来将钱飞到车上
function CodeGameScreenReelRocksMachine:getFiveSymbol( )
    for iCol=1,self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local tempSymbol = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)     --获取到小块
            if tempSymbol ~= nil and tempSymbol.p_symbolType == self.SYMBOL_SCORE_PICK then
                return tempSymbol
            end
        end
    end
end

function CodeGameScreenReelRocksMachine:collectCoinsByGoldCar(node,func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local specialCoins = selfData.specialCoins or {}    --金色火车
    local coinsNum = self:getListCoins(specialCoins)
    self:hideColorLayer()
    local symbol = self:getFiveSymbol()
    local endPos = util_convertToNodeSpace(symbol,self:findChild("Node_kaiche_1"))

    self.kaiCheCollect_2:stopAllActions()
    self.kaiCheCollect_2:runCsbAction("actionframe5",false)
    performWithDelay(self.kaiCheCollect_2,function (  )
        -- self.kaiCheCollect_2:stopAllActions()
        self.kaiCheCollect_2:runCsbAction("actionframe6",false)
        self.kaiCheCollect_2:findChild("Node_3"):runAction(cc.MoveTo:create(0.25,endPos))
    end,28/60)
    

    performWithDelay(self,function (  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_qian_za_car.mp3")
        symbol:runAnim("actionframe4",false)
        performWithDelay(self,function (  )
            symbol:getCcbProperty("Node_zi"):setVisible(true)
            symbol:getCcbProperty("Node_zi"):setOpacity(255)
            symbol:getCcbProperty("m_lb_coins"):setString(util_formatCoins(coinsNum, 3))     --将板子上的钱数显示在车上
        end,0.08)
    end,0.74)
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,1.25)

end

--将带钱小块的钱飞到金车板子上(node为板子)
function CodeGameScreenReelRocksMachine:collectCoinsByBoard(node,func)
    local tempList = {}     --临时存储小块
    local tempBonusCoinsList = {}       --临时bonusCoins小块
    local tempBnCoinsList = {}       --临时火车小块
    local tempCoinsList = {}        --临时存储小块数据
    local tempRecordIndex = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusCoins = selfData.bonusCoins or {}
    local bnCoin = selfData.bnCoins or {}

    copyTable(bnCoin,tempBnCoinsList)
    copyTable(bonusCoins,tempBonusCoinsList)

    --分别将带钱小块和火车小块存下来
    for k,v in pairs(tempBonusCoinsList) do
        table.insert( tempCoinsList,{pos = k,data = v})
    end

    -- for k,v in pairs(tempCoinsList) do
    --     local pos = v.pos
    --     local fixPos = self:getRowAndColByPos(pos)
    --     local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)     --获取到小块
    --     table.insert(tempList,symbol)
    -- end

    for k,v in pairs(tempBnCoinsList) do
        local tempData = self:getListCoins(v)
        table.insert( tempCoinsList,{pos = k,data = tempData})
    end

    for k,v in pairs(tempCoinsList) do
        local pos = tonumber(v.pos)
        local fixPos = self:getRowAndColByPos(pos)
        local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)     --获取到小块
        table.insert(tempList,symbol)
    end

    local tempNum = self:getListlength(tempList)
    local node_fly = cc.Node:create()
    self:findChild("root"):addChild(node_fly)
    local endPos = util_convertToNodeSpace(node,self:findChild("root"))
    endPos.y = endPos.y - 148
    for k,v in pairs(tempList) do
        local symbol = v
        if symbol then
            local pos = util_convertToNodeSpace(symbol,self:findChild("root"))
            self:runFlyLineAct(self.SYMBOL_SCORE_PICKB,pos,endPos)
        end
    end
    performWithDelay(self,function (  )
        if func then
            func()
        else
            
        end
    end,0.5)
end

--清楚收集
function CodeGameScreenReelRocksMachine:clearCollectBonusList( )
    for k,v in pairs(self.m_collectBonus) do
        v:removeFromParent()
    end
    self.m_collectBonus = {}
end

function CodeGameScreenReelRocksMachine:clearCollectStoneList( )
    for k,v in pairs(self.m_collectStone) do
        v:removeFromParent()
    end
    self.m_collectStone = {}
end

function CodeGameScreenReelRocksMachine:clearCollectCarList( )
    for k,v in pairs(self.m_collectCar) do
        v:removeFromParent()
    end
    self.m_collectCar = {}
end

function CodeGameScreenReelRocksMachine:clearCollectJinCarList( )
    for k,v in pairs(self.m_collectJinCar) do
        v:removeFromParent()
    end
    self.m_collectJinCar = {}
end

--totalWin反馈
function CodeGameScreenReelRocksMachine:showWinJieSuanAct( )
    self.m_jiesuanAct:setVisible(true)
    self.m_jiesuanAct:findChild("Particle_1"):resetSystem()
    self.m_jiesuanAct:findChild("Particle_1_0"):resetSystem()
    self.m_jiesuanAct:runCsbAction("actionframe",false,function (  )
        self.m_jiesuanAct:setVisible(false)
    end)
end

--收集钱到下ui
function CodeGameScreenReelRocksMachine:collectCoins(node,func)
    local coins1 = self.m_competitionCoins
    local coins2 = self.m_competitionCoins
    local tempBonusCoinsList = {}
    local tempCoinsList = {}
    local tempCoinsList1 = {}
    local node_fly = cc.Node:create()
    self:findChild("root"):addChild(node_fly)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusCoins = selfData.bonusCoins or {}
    local specialCoins = selfData.specialCoins or {}    --金色火车

    copyTable(bonusCoins,tempBonusCoinsList)


    for k,v in pairs(tempBonusCoinsList) do
        table.insert( tempCoinsList1,{pos = k,data = v})
    end


    --将钱数排序
    local sorTabCoins = {}
    for k,v in pairs(tempCoinsList1) do
        local index = v.pos
        local fixPos = self:getRowAndColByPos(index)
        if not sorTabCoins[fixPos.iY] then
            sorTabCoins[fixPos.iY] = {}
        end
        table.insert(sorTabCoins[fixPos.iY],v)
        table.sort( sorTabCoins[fixPos.iY],function ( a,b )
            local posA = tonumber(a.pos) 
            local posB = tonumber(b.pos) 
            return posA < posB
        end)
    end

    tempCoinsList = {}

    for i=1,self.m_iReelColumnNum do
        if sorTabCoins[i] then
            for j=1,self.m_iReelRowNum do
                if sorTabCoins[i][j] then
                    table.insert( tempCoinsList, sorTabCoins[i][j].data )
                end
            end
        end
    end



    --将小块排序
    local sorTab = {}
    for k,v in pairs(self.m_collectBonus) do
        local index = v.bnSort
        if index then
            local fixPos = self:getRowAndColByPos(index)
            if not sorTab[fixPos.iY] then
                sorTab[fixPos.iY] = {}
            end
            table.insert(sorTab[fixPos.iY],v)
            table.sort( sorTab[fixPos.iY],function ( a,b )
                local posA = a.bnSort
                local posB = b.bnSort
                return posA < posB
            end)
        end
        
    end

    self.m_collectBonus = {}
    for i=1,self.m_iReelColumnNum do
        if sorTab[i] then
            for j=1,self.m_iReelRowNum do
                if sorTab[i][j] then
                    table.insert( self.m_collectBonus, sorTab[i][j] )
                end
                
            end
        end
    end


    local tempNum = self:getListlength(self.m_collectBonus)
    local tempIndex = 1
    if tempNum == 0 then    --如果没有bn小块
        node_fly:stopAllActions()
        node_fly:removeFromParent()
        if func then
            func()
        end
    else
        local endPos = util_convertToNodeSpace(node,self:findChild("root"))
        schedule(node_fly,function (  )
            if tempNum == 0 then
                node_fly:stopAllActions()
                node_fly:removeFromParent()
                if func then
                    func()
                end
            else
                local symbol = self.m_collectBonus[tempIndex]
                local pos = util_convertToNodeSpace(symbol,self:findChild("root"))
                symbol:runCsbAction("actionframe",false)
                self:runFlyLineAct(self.SYMBOL_SCORE_PICKB,pos,endPos)
                self:showWinJieSuanAct()
                coins2 = coins2 + tempCoinsList[1]
                self:updateBottomUICoins(coins1,coins2,false,false)
                coins1 = coins1 + tempCoinsList[1]
                table.remove(tempCoinsList,1)
                tempIndex = tempIndex + 1
                tempNum = tempNum - 1
            end
        end,0.4)
    end
end

function CodeGameScreenReelRocksMachine:collectCar(node,func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bnCoins = selfData.bnCoins or {}
    local bonusCoins = selfData.bonusCoins or {}
    
    local coins1 = self:getCollectListCoins(bonusCoins) + self.m_competitionCoins
    local coins2 = self:getCollectListCoins(bonusCoins) + self.m_competitionCoins
    local tempBnCoinsList = {}
    local tempCoinsList = {}
    local node_fly = cc.Node:create()
    self:findChild("root"):addChild(node_fly)
    
    copyTable(bnCoins,tempBnCoinsList)

    for k,v in pairs(tempBnCoinsList) do
        local tempCoin = self:getListCoins(v)
        table.insert( tempCoinsList,tempCoin)
    end

    --将小块排序
    local sorTab = {}
    for k,v in pairs(self.m_collectCar) do
        local index = v.carSort
        if index then
            local fixPos = self:getRowAndColByPos(index)
            if not sorTab[fixPos.iY] then
                sorTab[fixPos.iY] = {}
            end
            table.insert(sorTab[fixPos.iY],v)
            table.sort( sorTab[fixPos.iY],function ( a,b )
                local posA = a.carSort
                local posB = b.carSort
                return posA < posB
            end)
        end
    end

    self.m_collectCar = {}
    for i,v1 in pairs(sorTab) do
        for j,v2 in pairs(v1) do
            table.insert( self.m_collectCar, v2 )
        end
    end

    -- table.sort( self.m_collectCar, function ( a,b )
    --     local indexA = a.carSort
    --     local indexB = b.carSort
    --     local fixPosA = self:getRowAndColByPos(indexA)
    --     local fixPosB = self:getRowAndColByPos(indexB)
    --     local posyA = fixPosA.iY
    --     local posyB = fixPosB.iY
    --     return posyA < posyB
    -- end )

    local endPos = util_convertToNodeSpace(node,self:findChild("root"))
    local tempNum = self:getListlength(self.m_collectCar)
    local tempIndex = 1
    if tempNum == 0 then    --如果没有bn小块
        if func then
            func()
        end
    else
        schedule(node_fly,function (  )
            if tempNum == 0 then
                node_fly:stopAllActions()
                node_fly:removeFromParent()
                if func then
                    func()
                end
            else
                local symbol = self.m_collectCar[tempIndex]
                local pos = util_convertToNodeSpace(symbol,self:findChild("root"))
                self:runFlyLineAct(symbol.p_symbolType,pos,endPos)
                self:showWinJieSuanAct()
                coins2 = coins2 + tempCoinsList[1]
                self:updateBottomUICoins(coins1,coins2,false,false)
                coins1 = coins1 + tempCoinsList[1]
                table.remove(tempCoinsList,1)
                -- table.remove(self.m_collectCar,1)
                tempIndex = tempIndex + 1
                tempNum = tempNum - 1
            end
        end,0.4)
    end
end

function CodeGameScreenReelRocksMachine:collectGoldCar(node,func)
    local endPos = util_convertToNodeSpace(node,self:findChild("root"))
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusCoins = selfData.bonusCoins or {}
    local bnCoins = selfData.bnCoins or {}
    local bonusWinCoins = selfData.bonusWinCoins or 0
    local specialCoins = selfData.specialCoins or {}    --金色火车
    local tempCarCoins = self:getAllCarCoins(bnCoins)
    local coins1 = self:getCollectListCoins(bonusCoins) + tempCarCoins  + self.m_competitionCoins
    local coins2 = bonusWinCoins + self.m_competitionCoins

    local tempNum = self:getListlength(self.m_collectJinCar)
    if tempNum == 0 then    --如果没有bn小块
        if func then
            func()
        end
    else
        local symbol = self.m_collectJinCar[1]
        local pos = util_convertToNodeSpace(symbol,self:findChild("root"))
        self:runFlyLineAct(symbol.p_symbolType,pos,endPos)
        self:showWinJieSuanAct()
        self:updateBottomUICoins(coins1,coins2,false,false)
    end

    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,1.5)
end

--判断列表是否为空
function CodeGameScreenReelRocksMachine:getListlength(list)
    local num = 0
    for k,v in pairs(list) do
        num = num + 1
    end
    return num 
end

--总钱数
function CodeGameScreenReelRocksMachine:getCollectListCoins(list)
    local coinsListCoins = 0
    for k,v in pairs(list) do
        coinsListCoins = coinsListCoins + v
    end
    return coinsListCoins
end

function CodeGameScreenReelRocksMachine:getCollectBnCoins(pos)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bnCoins = selfData.bnCoins or {}
    for k,v in pairs(bnCoins) do
        if pos == k then
            return v
        end
    end
end

function CodeGameScreenReelRocksMachine:getAllCarCoins(list)
    local tempCoins = 0
    for k,v in pairs(list) do
        local tempCarCoins = self:getListCoins(v)
        tempCoins = tempCoins + tempCarCoins
    end
    return tempCoins
end

function CodeGameScreenReelRocksMachine:getListCoins(list)
    local coinsNum = 0
    for i,v in ipairs(list) do
        coinsNum = coinsNum + v
    end
    return coinsNum
end

-- function CodeGameScreenReelRocksMachine:showJackpotView(index,coins,func)
--     local jackPotWinView = util_createView("CodeReelRocksSrc.ReelRocksJackPotWinView",index)
--     gLobalViewManager:showUI(jackPotWinView)
--     jackPotWinView:setPosition(display.width/2,display.height/2)
--     jackPotWinView:initViewData(index,coins,func)
--     -- local ownerlist={}
--     -- local path = self:getJackpotPath(index)
--     -- local imgName = nil
--     -- ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
--     -- local view =  self:showDialog(path,ownerlist,func)
--     -- view:setPosition(display.width/2,display.height/2)
-- end



function CodeGameScreenReelRocksMachine:getCarType(k)
    local pos = tonumber(k)
    local fixPos = self:getRowAndColByPos(pos)
    local symbol = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)     --获取到小块
    local type = symbol.p_symbolType or nil
    return type
end


function CodeGameScreenReelRocksMachine:runFlyLineAct(cartype,startPos,endPos,func)
    -- -- 创建粒子
    local flyNode =  util_createAnimation("ReelRocks_car_tuowei.csb")
    self:setLiZiShow(flyNode,cartype)
    self:findChild("root"):addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 10)
    flyNode:setPosition(startPos)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        flyNode:runCsbAction("actionframe",true)
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_fly_liZi.mp3")
    end)
    actList[#actList + 1] = cc.MoveTo:create(0.4,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if func then
            func()
        end
    end)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        flyNode:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    flyNode:runAction(sq)
end

function CodeGameScreenReelRocksMachine:setLiZiShow(node,type)
    if type == self.SYMBOL_SCORE_BOUNS1 then
        node:findChild("3"):setVisible(true)
        node:findChild("3"):resetSystem()
        node:findChild("3"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("3"):setPositionType(0)   --设置可以拖尾
    elseif type == self.SYMBOL_SCORE_BOUNS2 then
        node:findChild("2"):setVisible(true)
        node:findChild("2"):resetSystem()
        node:findChild("2"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("2"):setPositionType(0)   --设置可以拖尾
    elseif type == self.SYMBOL_SCORE_BOUNS3 then
        node:findChild("5"):setVisible(true)
        node:findChild("5"):resetSystem()
        node:findChild("5"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("5"):setPositionType(0)   --设置可以拖尾
    elseif type == self.SYMBOL_SCORE_BOUNS4 then
        node:findChild("1"):setVisible(true)
        node:findChild("1"):resetSystem()
        node:findChild("1"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("1"):setPositionType(0)   --设置可以拖尾
    elseif type == self.SYMBOL_SCORE_PICK or type == self.SYMBOL_SCORE_PICKB then
        node:findChild("4"):setVisible(true)
        node:findChild("4"):resetSystem()
        node:findChild("4"):setDuration(-1)     --设置拖尾时间(生命周期)
        node:findChild("4"):setPositionType(0)   --设置可以拖尾
    end
end
---------------------------------------------------------cash express玩法end------------------------------------------------------

---------------------------------------------------------比赛玩法start-------------------------------------------------------------

function CodeGameScreenReelRocksMachine:showCompetitionStartView(effectData)
    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    
    self.m_progress:completedAnim()     --进度条触发动画
    performWithDelay(self,function (  )
        self.biSaiStart = util_createView("CodeReelRocksSrc.collect.ReelRocksChooseKuangGongView",self.m_runSpinResultData.p_selfMakeData)   --选择车
        self:findChild("root"):addChild(self.biSaiStart)
        self.biSaiStart:setScale(0.8)
        self.biSaiStart:setPosition(display.width/12,display.height/12)

        self.biSaiStart:setVisible(false)
        -- self:updateProgressVisible()
        self:runCsbAction("actionframe",false,function (  )
            self:runCsbAction("idle",true)
            
        end)
        self:showGuoChang(function(  )
            self:clearCurMusicBg()
            self:resetMusicBg(nil,"ReelRocksSounds/music_ReelRocks_biSai.mp3")
            self:removeSoundHandler()
            self.m_bottomUI:showAverageBet()
            self.biSaiStart:setVisible(true)
            
            performWithDelay(self,function(  )
                gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_carEnter.mp3")
            end,11/6)
            -- self.biSaiStart:runCsbAction("idle1",false,function (  )  --移动
                self.biSaiStart:runCsbAction("start",false,function (  )    --开始
                    self:findChild("Node_1"):setVisible(false)
                    self.biSaiStart:setRunAct()
                    self.biSaiStart:runCsbAction("idle",false,function (  )
                        self.biSaiStart:setClick(true)
                    end)
                    self.biSaiStart:setEndCall( function(  )
                        self.carIndex = self.biSaiStart:getClickIndex()
                        -- self.biSaiStart:runCsbAction("over",false)
                        self.ReelRocksCompetitionView = util_createView("CodeReelRocksSrc.collect.ReelRocksCompetitionView",self.m_runSpinResultData.p_selfMakeData)
                        self.ReelRocksCompetitionView:setPlayerChoose(self.carIndex)
                        self:findChild("root"):addChild(self.ReelRocksCompetitionView)
                        self.ReelRocksCompetitionView:setScale(0.8)
                        self.ReelRocksCompetitionView:setPosition(display.width/12,display.height/12)
                        -- self.ReelRocksCompetitionView:setPosition(cc.p(0,0))
                        self.ReelRocksCompetitionView:setVisible(false)

                        
                        self:showGuoChang(function(  )
                            if self.biSaiStart then
                                self.biSaiStart:removeFromParent()
                            end
                            self:showCompetitionView(effectData)
                        end)
                    end)
                end)
            -- end)
        end)
    end,2)
end

function CodeGameScreenReelRocksMachine:showCompetitionView(effectData)
    self.ReelRocksCompetitionView:setVisible(true)
    self.ReelRocksCompetitionView:runCsbAction("actionframe2",false)
    self.ReelRocksCompetitionView:setEndCall( function(  )
        -- self.carIndex = self.biSaiStart:getClickIndex()
        self.ReelRocksCompetitionView:levelBiSaiOverChangeEffect()
        local data = self.ReelRocksCompetitionView:getEndList()
        -- performWithDelay(self,function (  )

        self.ReelRocksCompetitionOverView = util_createView("CodeReelRocksSrc.collect.ReelRocksCompetitionOverView",data,self.m_runSpinResultData.p_selfMakeData,self.carIndex)
        self:findChild("root"):addChild(self.ReelRocksCompetitionOverView)
        self.ReelRocksCompetitionOverView:setScale(0.8)
        -- self.ReelRocksCompetitionOverView:setPosition(cc.p(0,0))
        self.ReelRocksCompetitionOverView:setPosition(display.width/12,display.height/12)
        self.ReelRocksCompetitionOverView:setVisible(false)
        performWithDelay(self,function (  )
            self.ReelRocksCompetitionView:runCsbAction("actionframe3",false)
        end,0.2)
        -- performWithDelay(self,function (  )
            self:showGuoChang(function (  )

                if self.ReelRocksCompetitionView then
                    self.ReelRocksCompetitionView:removeFromParent()
                end
                self:showCompetitionOverView(effectData,data)
            end)
        -- end,0.5)
    end)
end

function CodeGameScreenReelRocksMachine:showCompetitionOverView(effectData,data)
    --将data根据名次排序
    table.sort( data, function( a,b )
        local icolA = a[2]
        local icolB = b[2]
        return icolA < icolB
    end )
    gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_lingJiang.mp3")
    self.ReelRocksCompetitionOverView:setVisible(true)
    self.ReelRocksCompetitionOverView:runCsbAction("actionframe",false)
    self.ReelRocksCompetitionOverView:setEndCall( function(  )

        self:findChild("Node_1"):setVisible(true)

        if self.ReelRocksCompetitionOverView then
            self.ReelRocksCompetitionOverView:removeFromParent()
        end
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local features = self.m_runSpinResultData.p_features
        local isFeatures = false
        if  features and #features == 2 and features[2] == 5 then 
            isFeatures = true
        end
        local collectWinCoins = selfdata.collectWinCoins or 0
        local rank = selfdata.rank or nil
        self:restAllBubble()    --小块遮罩
        self:updateProgressVisible()    --进度调
        self.m_competitionCoins = collectWinCoins
        --结束弹板
        self:showCompetitionOver(collectWinCoins,function (  )
            if rank and collectWinCoins > 0 and isFeatures then     --三种玩法一起出现
                -- self.m_bottomUI:notifyTopWinCoin()
                self.m_bottomUI:hideAverageBet()
                self:updateBottomUICoins(0,collectWinCoins,false,nil)
                self:resetMusicBg()
                self:reelsDownDelaySetMusicBGVolume( ) 
                effectData.p_isPlay = true
                self:playGameEffect()
            elseif rank and collectWinCoins > 0 then
                self.m_bottomUI:hideAverageBet()
                self:updateBottomUICoins(0,collectWinCoins,false,nil)
                self:resetMusicBg()
                self:reelsDownDelaySetMusicBGVolume( ) 
                effectData.p_isPlay = true
                self:playGameEffect()
            else
                self.m_bottomUI:notifyTopWinCoin()
                self.m_bottomUI:hideAverageBet()
                self:updateBottomUICoins(0,collectWinCoins,true,nil)
                self:resetMusicBg()
                self:reelsDownDelaySetMusicBGVolume( ) 
                effectData.p_isPlay = true
                self:playGameEffect()
            end
            
        end)
    end)
end

function CodeGameScreenReelRocksMachine:showCompetitionOver(coins,func )
    
    -- 停止播放背景音乐
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_tanBan.mp3")
    local ownerlist={}
    local path = "BiSaiOver"
    local imgName = nil
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
    local view =  self:showDialog(path,ownerlist,func)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},603)
    view:setPosition(display.width/2,display.height/2)
end

---------------------------------------------------------比赛玩法end-------------------------------------------------------------

--过场
function CodeGameScreenReelRocksMachine:showGuoChang(func,mark)
    gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_guoChang.mp3")
    self.guoChangView:setVisible(true)
    self.guoChangView:runCsbAction("actionframe",false,function (  )
        self.guoChangView:setVisible(false)
    end)
    
    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,1)
end

---------------------------------------------------------选择玩法start-------------------------------------------------------------

function CodeGameScreenReelRocksMachine:showEffect_Bonus( effectData)
    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end

    self.isInBonus = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Scatter 的连线， 将其移除， 并且播放一次Scatter 触发内容
        local lineLen = #self.m_reelResultLines
        self.scatterLineValue = nil
        for i=1,lineLen do
            local lineValue = self.m_reelResultLines[i]
            if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
                self.scatterLineValue = lineValue
                table.remove(self.m_reelResultLines,i)
                break
            end
        end

    

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
        local time = 1
        local changeNum = 1/(time * 60) 
        local curvolume = 1
        self.m_updateBgMusicHandlerID = scheduler.scheduleUpdateGlobal(function()
            curvolume = curvolume - changeNum
            if curvolume <= 0 then

                curvolume = 0

                if self.m_updateBgMusicHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
                    self.m_updateBgMusicHandlerID = nil
                end
            end

            gLobalSoundManager:setBackgroundMusicVolume(curvolume)
        end)

        

        performWithDelay(self,function(  )

            -- 停止播放背景音乐
            self:clearCurMusicBg()
            -- 播放震动
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "bonus")
            end
            -- -- 播放bonus 元素不显示连线
            if self.scatterLineValue ~= nil then
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()
                self:showBonusAndScatterLineTip(self.scatterLineValue,function()              
                        self:showBonusGameView(effectData)
                    end)

                self:playScatterTipMusicEffect()
                self.scatterLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = self.scatterLineValue        
                    
            else
                self:showBonusGameView(effectData)
            end
        end,time)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)
    return true
end

--三个sc触发
function CodeGameScreenReelRocksMachine:showBonusGameView(effectData)
    local features = self.m_runSpinResultData.p_features
    if  features and #features == 2 and features[2] == 5 then      
        local time = 1.5
        performWithDelay(self,function( )
            self.m_bottomUI:checkClearWinLabel()
            self:chooseFeatureView(effectData)
        end,time)
    end
end

function CodeGameScreenReelRocksMachine:callSpinTakeOffBetCoin(betCoin)
    if self.m_isChooseRespinFeature == false then
        BaseMachine.callSpinTakeOffBetCoin(self, betCoin)
    else
        -- 如果本次界面选择了 respin的玩法则不做扣钱处理
    end
    self.m_isChooseRespinFeature = false
end


--选择玩法弹板
function CodeGameScreenReelRocksMachine:chooseFeatureView(effectData)
    gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_chooseGame.mp3")
    local chooseView = util_createView("CodeReelRocksSrc.ReelRocksChooseView",self)
    self:findChild("root"):addChild(chooseView)
    chooseView:setPosition(cc.p(0,0))
    chooseView:showStartAct()   --播放start
    self:hideAllBubble()    --选择玩法隐藏遮罩。。
    chooseView:setEndCall( function(  )
        if chooseView:getChooseIndex() == 1 then
            self:resetMusicBg()
            self:reelsDownDelaySetMusicBGVolume( ) 
            self.m_isChooseRespinFeature = true
            -- self.m_chooseRepin = true
            self.m_bInBonus = true
            self:setCurrSpinMode(REWAED_SPIN_MODE)

            self.isBonusChooseRock = true   
            
            -- self:normalSpinBtnCall()
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        elseif chooseView:getChooseIndex() == 2 then
            self:findChild("dark"):setVisible(false)
            -- self.m_progress:setVisible(false)
            self:findChild("reel_base"):setVisible(false)
            self:findChild("reel_fs"):setVisible(true)
            self:showFreeSpinBar()
            self:hideAllBubble()
            self:levelFreeSpinEffectChange()
            self:bonusOverAddEffect( )
            
            effectData.p_isPlay = true
            self:playGameEffect() -- 播放下一轮
        end
        
        if chooseView then
            chooseView:removeFromParent()
        end
    end)
end

function CodeGameScreenReelRocksMachine:bonusOverAddEffect( )
    local featureDatas = self.m_runSpinResultData.p_features
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            
        end
    end
end

---------------------------------------------------------选择玩法end-------------------------------------------------------------

--选择小车弹板
function CodeGameScreenReelRocksMachine:chooseCarView( )
    local chooseCar = util_createView("CodeReelRocksSrc.collect.ReelRocksChooseView",self)
    self:findChild("viewNode"):addChild(chooseCar)
    --display.width/2,display.height/2
    chooseCar:setPosition(cc.p(0,0))

    chooseCar:setEndCall( function(  )

        effectData.p_isPlay = true
        self:playGameEffect() -- 播放下一轮

        if chooseCar then
            chooseCar:removeFromParent()
        end
    end)
end

--落地之前修改小块
function CodeGameScreenReelRocksMachine:updateReelGridNode(node)
    if node.p_symbolType == self.SYMBOL_SCORE_BN then       --设置小块上的数值
        self:setSpecialNodeScore(self,{node})
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then     --设置wild成倍显示
            self:changeWildShow(self,{node})
        end
    end
end

function CodeGameScreenReelRocksMachine:changeWildShow(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType or symbolNode.p_symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return 
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    symbolNode.wildName = nil

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
    --根据服务器给的类型修改wild的显示
        local symbolIndex = self:getPosReelIdx(iRow, iCol)
        local score = self:getwildSymbolScore(symbolIndex) --获取倍数
        if score > 0 then
            --修改小块静态图片
            if score == 2 then
                symbolNode:changeSymbolImageByName("Socre_ReelRocks_Wild_2")
                symbolNode.wildName = "wild2"
            elseif score == 5 then
                symbolNode:changeSymbolImageByName("Socre_ReelRocks_Wild_3")
                symbolNode.wildName = "wild5"
            end
            
        end
    end
end

function CodeGameScreenReelRocksMachine:getwildSymbolScore(index)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local markWild = selfdata.wildMultiplies or {}
    local score = nil
    for k,v in pairs(markWild) do
        if tonumber(k) == index then
            score = v
        end
    end
    if score == nil then
        return 0
    end
    return score
end

function CodeGameScreenReelRocksMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.SYMBOL_SCORE_BN then
        return 
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时小块的分数
        
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local storedIcons = selfdata.bonusCoins -- 存放的是网络数据
        local symbolIndex = self:getPosReelIdx(iRow, iCol)
        local score = self:getSpinSymbolScore(symbolIndex) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            -- local lineBet = globalData.slotRunData:getCurTotalBet()
            -- score = score * lineBet
            score = util_formatCoins(score, 3)
            symbolNode:getCcbProperty("m_lb_coins"):setString(score)
            self:updateLabelSize({label = symbolNode:getCcbProperty("m_lb_coins"),sx = 0.5,sy = 0.5},213)
        end
    else
        local score = self:randomDownspinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)
                symbolNode:getCcbProperty("m_lb_coins"):setString(score)
                self:updateLabelSize({label = symbolNode:getCcbProperty("m_lb_coins"),sx = 0.5,sy = 0.5},213)
            end
        end
    end
end

function CodeGameScreenReelRocksMachine:getSpinSymbolScore(id)
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local storedIcons = selfdata.bonusCoins
    local score = nil
    for k,v in pairs(storedIcons) do
        if tonumber(k) == id then
            score = v
        end
    end

    if score == nil then
       return 0
    end
    return score
end

function CodeGameScreenReelRocksMachine:randomDownspinSymbolScore(symbolType)
    local score = nil
    if symbolType then
        if math.abs(symbolType) == self.SYMBOL_SCORE_BN then
            -- 根据配置表来获取滚动时 respinBonus小块的分数
            -- 配置在 Cvs_cofing 里面
            score = self.m_configData:getFixSymbolPro()
        end
    end
    return score
end

function CodeGameScreenReelRocksMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound( "ReelRocksSounds/music_ReelRocks_enter.mp3" )
         
    end,0.4,self:getModuleName())
end

function CodeGameScreenReelRocksMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:findChild("reel_base"):setVisible(true)
    self:findChild("reel_fs"):setVisible(false)
    self:addObservers()
    self:updateProgressVisible()
    schedule(self.jackpotNode,function()
        self:updateJackpotInfo()
    end,0.08)


    scheduler.performWithDelayGlobal(function(  )
        
        local userLevel = globalData.userRunData.levelNum or 1
        if userLevel > 5 then
            self.startShow = util_createView("CodeReelRocksSrc.ReelRocksEnterView")
            gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_startShow.mp3")
            if globalData.slotRunData.machineData.p_portraitFlag then
                self.startShow.getRotateBackScaleFlag = function(  ) return false end
            end
            gLobalViewManager:showUI(self.startShow)
        end
        
         
    end,0.4,self:getModuleName())


    
end

function CodeGameScreenReelRocksMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        if self.getCurrSpinMode() == NORMAL_SPIN_MODE then
            self:clicTipView()
        end
    end,"SHOW_BONUS_Tip")
end

function CodeGameScreenReelRocksMachine:onExit()

    if self.m_updateBgMusicHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateBgMusicHandlerID)
        self.m_updateBgMusicHandlerID = nil
    end
    
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    self.jackpotNode:stopAllActions()
    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenReelRocksMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_ReelRocks_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_ReelRocks_11"
    elseif symbolType == self.SYMBOL_SCORE_BN then
        return "Socre_ReelRocks_Bonus_2"
    elseif symbolType == self.SYMBOL_SCORE_PICK then
        return "Socre_ReelRocks_CAR_5"
    elseif symbolType == self.SYMBOL_SCORE_PICKB then
        return "Socre_ReelRocks_Bonus_baoshi"
    elseif symbolType == self.SYMBOL_SCORE_BOUNS1 then
        return "Socre_ReelRocks_CAR_1"
    elseif symbolType == self.SYMBOL_SCORE_BOUNS2 then
        return "Socre_ReelRocks_CAR_2"
    elseif symbolType == self.SYMBOL_SCORE_BOUNS3 then
        return "Socre_ReelRocks_CAR_3"
    elseif symbolType == self.SYMBOL_SCORE_BOUNS4 then
        return "Socre_ReelRocks_CAR_4"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenReelRocksMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BN,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_PICK,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_PICKB,count = 2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BOUNS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BOUNS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BOUNS3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BOUNS4,count =  2}

    return loadNode
end



----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenReelRocksMachine:MachineRule_initGame(  )
    -- local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    -- local bnCoins = selfdata.bnCoins or {}
    -- local bonusCoins = selfdata.bonusCoins or {}
    -- local newCollect = selfdata.newCollect or {}
    -- local specialCoins = selfdata.specialCoins or {}    --金色火车
    -- local bonusWinCoins = selfdata.bonusWinCoins or 0
    -- local rank = selfdata.rank or nil
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:hideAllBubble()
        self:levelFreeSpinEffectChange()
        self:setFsBackGroundMusic(self.m_configData.p_musicFsBg)--fs背景音乐
        self.m_fsReelDataIndex = self.BASE_FS_RUN_STATES
    else
        self:restAllBubble()
        self:updateBubbleVisible()
        self:updateProgressVisible()
    end
    
end

--添加金边
function CodeGameScreenReelRocksMachine:creatReelRunAnimation(col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    reelEffectNode:getParent():setOpacity(255)
    reelEffectNode:setOpacity(255)
    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "actionframe", true)        --此处做了修改

    if self.m_reelBgEffectName ~= nil then   -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "actionframe", true)      --此处做了修改
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end


---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenReelRocksMachine:levelFreeSpinEffectChange()
    self.m_gameBg:runCsbAction("idle1")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenReelRocksMachine:levelFreeSpinOverChangeEffect()
    self.m_gameBg:runCsbAction("idle2")
end



function CodeGameScreenReelRocksMachine:levelBiSaiOverOrChooseChangeEffect( )
    self.m_gameBg:runCsbAction("idle3")
end
---------------------------------------------------------------------------


----------- FreeSpin相关
function CodeGameScreenReelRocksMachine:showEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    self:showFreeSpinView(effectData)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
-- FreeSpinstart
function CodeGameScreenReelRocksMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("ReelRocksSounds/music_ReelRocks_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        -- self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
            self:triggerFreeSpinCallFun()
            effectData.p_isPlay = true
            self:playGameEffect()       
        -- end)
        
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)
end

function CodeGameScreenReelRocksMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_tanBan.mp3")

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            self:clearFrames_Fun()
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            self.m_progress:setVisible(true)
            self:restAllBubble()
            self:updateBubbleVisible()
            self:findChild("dark"):setVisible(true)
            self:triggerFreeSpinOverCallFun()
    end)
    view:setPosition(display.width/2,display.height/2)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},603)
    
end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenReelRocksMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
    self:removeSoundHandler()
    -- self:setMaxMusicBGVolume( )
    self.m_bSlotRunning = true
    self.m_isOlnyScatter = false

    self:setSymbolToReel()



    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenReelRocksMachine:addSelfEffect()
    
    self.m_competitionCoins = 0
    
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local bnCoins = selfdata.bnCoins or {}
        local bonusCoins = selfdata.bonusCoins or {}
        local newCollect = selfdata.newCollect or {}
        local specialCoins = selfdata.specialCoins or {}    --金色火车
        local bonusWinCoins = selfdata.bonusWinCoins or 0
        local rank = selfdata.rank or nil
        -- collect
        if #newCollect > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.COLLECT_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COLLECT_EFFECT -- 动画类型
        end
        -- pickFeature
        if bonusWinCoins > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.CASH_EXPRESS_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.CASH_EXPRESS_EFFECT -- 动画类型
        end
        --比赛
        if rank then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.COMPETITION_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COMPETITION_EFFECT -- 动画类型
        end
        
    else

    end
    if self.m_bInBonus == true then
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        self.m_bInBonus = false
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenReelRocksMachine:MachineRule_playSelfEffect(effectData)


    if effectData.p_selfEffectType == self.COLLECT_EFFECT then
        self:updateBubbleVisible( true )
        performWithDelay(self,function (  )
            self:createCollectBubbleAct( function(  )
                performWithDelay(self,function (  )
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,0.5)
            end )
        end,5/6)
        
    elseif effectData.p_selfEffectType == self.CASH_EXPRESS_EFFECT then
        self:showCashExpreeView(effectData)
    elseif effectData.p_selfEffectType == self.COMPETITION_EFFECT then
        self:showCompetitionStartView(effectData)
    end
    return true
end


function CodeGameScreenReelRocksMachine:slotReelDown( )

    self.m_isChooseRespinFeature = false

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    BaseNewReelMachine.slotReelDown(self)
end

-----------------------------jackpot相关------------------------------
function CodeGameScreenReelRocksMachine:updateJackpotInfo()
    
    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)
    self:updateSize()
end

function CodeGameScreenReelRocksMachine:updateSize()
    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,177)
    self:updateLabelSize(info2,177)
    self:updateLabelSize(info3,177)
    self:updateLabelSize(info4,177)
end

function CodeGameScreenReelRocksMachine:changeNode(label,index,isJump)
    local value=self:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,50,nil,nil,true))
end

--根据车的类型获取jackpot的索引值
function CodeGameScreenReelRocksMachine:getCarIndex(carType)
    if carType == 101 then
        return 4
    elseif carType == 102 then
        return 3
    elseif carType == 103 then
        return 2
    elseif carType == 104 then
        return 1
    end
end

--判断钱数是否是jackpot
function CodeGameScreenReelRocksMachine:isShowJackpot(carType,coins)
    local index = self:getCarIndex(carType)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local bet = coins/totalBet
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    local poolData = jackpotPools[index]
    local configData = poolData.p_configData
    if configData.p_initMin and configData.p_initMax then
        if bet >= configData.p_initMin and bet <= configData.p_initMax then
            return true
        end
    else
        if bet >= configData.p_multiple then
            return true
        end
    end
    
    return false
end

--展示jackpot赢钱
function CodeGameScreenReelRocksMachine:showJackpotWinView(index,coins,func)
    -- index 1- 4 grand - mini
    local jackPotWinView = util_createView("CodeReelRocksSrc.ReelRocksJackPotWinView",index)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalSoundManager:playSound("ReelRocksSounds/ReelRocks_jackpot.mp3")
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:setPosition(display.width/2,display.height/2)
    local curCallFunc = function(  )
        if func then
            func()
        end
    end
    jackPotWinView:initViewData(index,coins,curCallFunc)
end

--随机
function CodeGameScreenReelRocksMachine:randomSlotNodesByReel()
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

function CodeGameScreenReelRocksMachine:randomSlotNodes( )
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex=1,rowCount do
            local symbolType = self:getRandomReelType(colIndex,reelDatas)
            
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

function CodeGameScreenReelRocksMachine:triggerFreeSpinCallFun()

    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local FreeType = fsExtraData.FreeType or ""

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)  -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        -- self:showFreeSpinBar()
    end

    self:setCurrSpinMode( FREE_SPIN_MODE )
    self.m_bProduceSlots_InFreeSpin = true
    self:resetMusicBg()
end

function CodeGameScreenReelRocksMachine:triggerFreeSpinOverCallFun()

    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    if self.postFreeSpinOverTriggerBigWIn then
        self:postFreeSpinOverTriggerBigWIn( _coins) 
    end
    
    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode( NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")

    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    self:levelFreeSpinOverChangeEffect()
    self:findChild("reel_base"):setVisible(true)
    self:findChild("reel_fs"):setVisible(false)
    self:hideFreeSpinBar()

    self:resetMusicBg()
    self:reelsDownDelaySetMusicBGVolume( ) 
    self:setMaxMusicBGVolume()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE,GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

function CodeGameScreenReelRocksMachine:playEffectNotifyNextSpinCall( )

    self.m_bSlotRunning = false

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_SPIN_MODE then

        local delayTime = 0.5
        delayTime = delayTime + self:getWinCoinTime()

        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    -- elseif self.m_chooseRepin then
    --     self.m_chooseRepin = false
    --     self:normalSpinBtnCall()
    end
end

function CodeGameScreenReelRocksMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]

    local freeGameCost = spinData.freeGameCost
    if freeGameCost then
        self.m_rewaedFSData = freeGameCost
    end
    
    if spinData.action == "SPIN" then
        self:operaSpinResultData(param)
        self:operaUserInfoWithSpinResult(param )
        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")
    elseif spinData.action == "FEATURE" then
        if spinData.result.selfData.bonusWinCoins then
            self:operaSpinResultData(param)
            self:operaUserInfoWithSpinResult(param )
            self:updateNetWorkData()
            gLobalNoticManager:postNotification("TopNode_updateRate")
        else
            
        end
    end
end


function CodeGameScreenReelRocksMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]


    local nodeData = reelRunData:getSlotsNodeInfo()

    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true
    and
    (self:getGameSpinStage( ) ~= QUICK_RUN
     or self.m_hasBigSymbol == true
    )
    then
        isTriggerLongRun = true -- 触发了长滚动
        -- if  self:getGameSpinStage() == QUICK_RUN  then
        --     gLobalSoundManager:playSound(self.m_reelDownSound)
        -- end
        for i = reelCol + 1, self.m_iReelColumnNum do
            --添加金边
            if i == reelCol + 1 then
                if self.m_reelRunInfo[i]:getReelLongRun() then
                    self:creatReelRunAnimation(i)
                end
            end
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end
    return isTriggerLongRun
end


-- 每个reel条滚动到底
function CodeGameScreenReelRocksMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage( ) ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then

        self:playReelDownSound(reelCol,self.m_reelDownSound )

    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end
    

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    for i = 1, self.m_iReelRowNum, 1 do

        local symbolType = self.m_stcValidSymbolMatrix[i][reelCol]
        if  symbolType == self.SYMBOL_SCORE_BN then
            local symbolNode = self:getReelParentChildNode(reelCol,i)

            local soundPath = "ReelRocksSounds/ReelRocks_bonus_down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end 

            symbolNode:runAnim("buling",false)
        elseif symbolType == self.SYMBOL_SCORE_PICKB or symbolType == self.SYMBOL_SCORE_PICK or symbolType == self.SYMBOL_SCORE_BOUNS1 or symbolType == self.SYMBOL_SCORE_BOUNS2 or symbolType == self.SYMBOL_SCORE_BOUNS3 or symbolType == self.SYMBOL_SCORE_BOUNS4 then
            local symbolNode = self:getReelParentChildNode(reelCol,i)

            local soundPath = "ReelRocksSounds/ReelRocks_car_down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end 

            symbolNode:runAnim("buling",false)
        elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local symbolNode = self:getReelParentChildNode(reelCol,i)

            local soundPath = "ReelRocksSounds/ReelRocks_Scatter_down.mp3"
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,soundPath )
            else
                gLobalSoundManager:playSound(soundPath)
            end 

            self:setSymbolToClip(symbolNode)
            symbolNode:runAnim("buling",false)
        end
    end

    local upSlot = self:getFixSymbol(reelCol, self.m_iReelRowNum + 1)       --修改棋盘上的小块层级
    if upSlot then
        upSlot:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE - 200)
    end
    
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        self:triggerLongRunChangeBtnStates( ) 
    end

    return isTriggerLongRun
end

function CodeGameScreenReelRocksMachine:playInLineNodes()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local markWild = selfdata.wildMultiplies
    if self.m_lineSlotNodes == nil then
        return
    end
    local animTime = 0
    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then

            if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                print("")
            end
            if markWild then
                if slotsNode.p_symbolType == 92 and slotsNode.wildName and slotsNode.wildName == "wild2" then
                    slotsNode:runAnim("actionframe2",true)
                elseif slotsNode.p_symbolType == 92 and slotsNode.wildName and slotsNode.wildName == "wild5" then
                    slotsNode:runAnim("actionframe3",true)
                else
                    slotsNode:runLineAnim()
                end
            else
                slotsNode:runLineAnim()
            end
            
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()) )
            end
        end

    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenReelRocksMachine:playInLineNodesIdle()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local markWild = selfdata.wildMultiplies
    if self.m_lineSlotNodes == nil then
        return
    end

    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if markWild then
                if slotsNode.wildName and slotsNode.wildName == "wild2" then
                    slotsNode:runAnim("idleframe2",true)
                elseif slotsNode.wildName and slotsNode.wildName == "wild5" then
                    slotsNode:runAnim("idleframe3",true)
                else
                    slotsNode:runIdleAnim()
                end
            else
                slotsNode:runIdleAnim()
            end
            
            
        end
    end
end

function CodeGameScreenReelRocksMachine:resetMaskLayerNodes()
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local markWild = selfdata.wildMultiplies

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
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                util_changeNodeParent(preParent,lineNode,nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)
                if markWild then
                    if lineNode.p_symbolType == 92 and lineNode.wildName and lineNode.wildName == "wild2" then
                        lineNode:runAnim("idleframe2",true)
                    elseif lineNode.p_symbolType == 92 and lineNode.wildName and lineNode.wildName == "wild5" then
                        lineNode:runAnim("idleframe3",true)
                    else
                        lineNode:runIdleAnim()
                    end
                else
                    lineNode:runIdleAnim()
                end
                
            end
        end
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenReelRocksMachine:showLineFrameByIndex(winLines,frameIndex)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local markWild = selfdata.wildMultiplies

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")
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

    for i=1,frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <=  hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue,symPosData)
        end
        node:setPosition(cc.p(posX,posY))

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
            node:runAnim("actionframe",true)
        else
            node:runAnim("actionframe",true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end

    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if markWild then
                        if slotsNode.p_symbolType == 92 and slotsNode.wildName and slotsNode.wildName == "wild2" then
                            slotsNode:runAnim("actionframe2",true)
                        elseif slotsNode.p_symbolType == 92 and slotsNode.wildName and slotsNode.wildName == "wild5" then
                            slotsNode:runAnim("actionframe3",true)
                        else
                            slotsNode:runLineAnim()
                        end
                    else
                        slotsNode:runLineAnim()
                    end
                    
                end
            end
        end
    end
end

function CodeGameScreenReelRocksMachine:MachineRule_ResetReelRunData()
    local i= self.m_reelRunInfo     --中存放轮盘滚动信息  m_bReelLongRun
    local a = self.m_runSpinResultData.p_reels
    local runLen = 0
    for index, runInfo in pairs(self.m_reelRunInfo) do
        if self:getLenNum(self.m_reelRunInfo[5].m_reelRunLen,self.m_reelRunInfo[4].m_reelRunLen) < 100 then
            if index == 4 then
                local pickNum = self:getPickNum()
                if self:getPickNum() >= 1 then
                    runLen = runInfo.m_reelRunLen
                    runInfo:setNextReelLongRun(true)
                end
            elseif index == 5 then
                local pickNum = self:getPickNum()
                if self:getPickNum() >= 1 then
                    runInfo:setReelLongRun(true)
                    runInfo:setNextReelLongRun(true)
                    runInfo.m_reelRunLen = runLen + 100
                    --runInfo.m_bReelLongRun = true  getLongRunLen
                end
            end
        end
        
    end
end


--获取前四列的scatter的个数
function CodeGameScreenReelRocksMachine:getLenNum(len1,len2)
    return len1 - len2
end

function CodeGameScreenReelRocksMachine:getPickNum( )       --获取特殊小块的数量，用作判断第五列是否触发快滚，注：不能用遍历棋盘的方式，因为滚动没有停止
    local pickNum = 0
    local endData = self.m_runSpinResultData.p_reels
    for i,v in ipairs(endData) do
        for i,slotType in ipairs(v) do
            if  slotType == self.SYMBOL_SCORE_BOUNS1 or slotType == self.SYMBOL_SCORE_BOUNS2 or slotType == self.SYMBOL_SCORE_BOUNS3 or slotType == self.SYMBOL_SCORE_BOUNS4 then
                pickNum = pickNum + 1
            end
        end
    end
    return pickNum
end

function CodeGameScreenReelRocksMachine:showBonusAndScatterLineTip(lineValue,callFun)
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
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY ,symPosData.iX)
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

        if slotNode ~= nil then--这里有空的没有管

            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenReelRocksMachine:setSlotNodeEffectParent(slotNode)
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

    self.m_clipParent:addChild(slotNode,self:getSlotNodeEffectZOrder(slotNode))
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            slotNode:runAnim("actionframe",false)
        else
            slotNode:runLineAnim()
        end
    end
    return slotNode
end

function CodeGameScreenReelRocksMachine:setGameEffectOrder()
    if self.m_gameEffects == nil then
        return
    end

    local lenEffect = #self.m_gameEffects
    for i = 1, lenEffect, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType ~= GameEffect.EFFECT_SELF_EFFECT then
            effectData.p_effectOrder = effectData.p_effectType
        end
    end
end

-- --将图标提到clipParent层
function CodeGameScreenReelRocksMachine:setSymbolToClip(slotNode)
    local nodeParent = slotNode:getParent()
    slotNode.m_preParent = nodeParent
    slotNode.m_showOrder = slotNode:getLocalZOrder()
    slotNode.m_preX = slotNode:getPositionX()
    slotNode.m_preY = slotNode:getPositionY()
    slotNode.m_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.m_preX, slotNode.m_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    slotNode:removeFromParent()
    -- 切换图层
    slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE

    self.m_clipParent:addChild(slotNode, self:getBounsScatterDataZorder(slotNode.p_symbolType) - slotNode.p_rowIndex + slotNode.p_cloumnIndex * 10)
    self.m_clipNode[#self.m_clipNode + 1] = slotNode
    
    local linePos = {}
    linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
    slotNode:setLinePos(linePos)
end

-- --将图标恢复到轮盘层
function CodeGameScreenReelRocksMachine:setSymbolToReel()
    for i, slotNode in ipairs(self.m_clipNode) do
        local preParent = slotNode.m_preParent
        if preParent ~= nil then
            slotNode.p_layerTag = slotNode.m_preLayerTag

            local nZOrder = slotNode.m_showOrder
            nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.m_showOrder

            util_changeNodeParent(preParent, slotNode, nZOrder)
            slotNode:setPosition(slotNode.m_preX, slotNode.m_preY)
            slotNode:runIdleAnim()
        end
    end
    self.m_clipNode = {}
end

function CodeGameScreenReelRocksMachine:getSymbolTypeByPos(pos)
    local reels = self.m_runSpinResultData.p_reels or {}
    local row_index = math.floor(pos / self.m_iReelColumnNum) + 1
    local col_index = (pos % self.m_iReelColumnNum) + 1
    return reels[row_index][col_index]
end

function CodeGameScreenReelRocksMachine:checkIsAddLastWinSomeEffect( )
    
    local notAdd  = false

    -- if #self.m_vecGetLineInfo == 0 then
    --     notAdd = true
    -- end

    return notAdd
end

function CodeGameScreenReelRocksMachine:getLineWinCoins( )
    local lines = self.m_runSpinResultData.p_winLines or {}
    local coins = 0
    for i=1,#lines do
        local line = lines[i]
        if line and line.p_amount then
            coins = coins + line.p_amount
        end
    end

    return coins

end

function CodeGameScreenReelRocksMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if isNotifyUpdateTop then
        local linesWinCoins = self:getLineWinCoins( )

        if linesWinCoins > 0 and linesWinCoins < self.m_iOnceSpinLastWin then

            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            local params = {self.m_iOnceSpinLastWin,isNotifyUpdateTop,nil,self.m_iOnceSpinLastWin - linesWinCoins}
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
            globalData.slotRunData.lastWinCoin = lastWinCoin

        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
    end
    
end

function CodeGameScreenReelRocksMachine:operaUserOutCoins( )
    --金币不足
    -- gLobalTriggerManager:triggerShow({viewType=TriggerViewType.Trigger_NotEnoughSpin})
    self.m_bSlotRunning = false
    gLobalPushViewControl:showView(PushViewPosType.NoCoinsToSpin)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NoCoins)
    end
    gLobalPushViewControl:setEndCallBack(function()
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
    end)
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_NEWOVER)
    end
end

return CodeGameScreenReelRocksMachine