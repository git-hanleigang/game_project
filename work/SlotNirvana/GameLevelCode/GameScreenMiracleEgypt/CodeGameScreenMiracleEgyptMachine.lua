---
-- xcyy
-- 2018年5月11日
-- CodeGameScreenMiracleEgyptMachine.lua
--
-- 玩法： 埃及气泡关卡
--

local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local LineTypeTag = require "data.levelcsv.LineTypeTag"
local BaseMachine = require "Levels.BaseMachine"
local SlotParentData = require "data.slotsdata.SlotParentData"

local CodeGameScreenMiracleEgyptMachine = class("CodeGameScreenMiracleEgyptMachine", BaseSlotoManiaMachine)

CodeGameScreenMiracleEgyptMachine.SYMBOL_H1_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

-- CodeGameScreenMiracleEgyptMachine.m_featureEffect = GameEffect.EFFECT_SELF_EFFECT + 1

CodeGameScreenMiracleEgyptMachine.m_GuoChangeView = nil
CodeGameScreenMiracleEgyptMachine.m_BubbleNodeList = nil

CodeGameScreenMiracleEgyptMachine.m_BubbleNodeList = nil
CodeGameScreenMiracleEgyptMachine.m_H1NodeList = nil

CodeGameScreenMiracleEgyptMachine.m_CatOpen = 0 -- 猫睁眼
CodeGameScreenMiracleEgyptMachine.m_CatClose = 1 -- 猫闭眼
CodeGameScreenMiracleEgyptMachine.m_CatTrigger = 2 -- 猫飞球
CodeGameScreenMiracleEgyptMachine.m_BetActionType = nil

CodeGameScreenMiracleEgyptMachine.m_RunLockType = 0 -- 锁住泡泡
CodeGameScreenMiracleEgyptMachine.m_RunConchtype = 1 -- 猫飞出来泡泡

CodeGameScreenMiracleEgyptMachine.m_ConchBubblesWaitTime = 0 -- 猫飞泡泡需要等待的时间
CodeGameScreenMiracleEgyptMachine.m_newBubblesCutPosY = 150 -- 在最后一行时需要向下移动的距离
CodeGameScreenMiracleEgyptMachine.m_BubblesSwingX = 40 -- 气泡左右摆动距离

CodeGameScreenMiracleEgyptMachine.m_isFirstIn = true -- 是不是第一次进
CodeGameScreenMiracleEgyptMachine.m_BetChooseGear = 1000000 -- 这个bet来确定是否开启小猫吐泡泡

CodeGameScreenMiracleEgyptMachine.m_reelAddLenNum = {9, 9, 9, 9, 9} 


CodeGameScreenMiracleEgyptMachine.m_isOnEnter = true -- 是不是刚刚从大厅进入关卡

CodeGameScreenMiracleEgyptMachine.m_ScatterMskNodeList = {}

CodeGameScreenMiracleEgyptMachine.m_oldBetID = 1 -- 关卡存的betId 

CodeGameScreenMiracleEgyptMachine.m_unlockFeature = nil --关卡解锁特殊玩法

CodeGameScreenMiracleEgyptMachine.m_specialBets = nil

CodeGameScreenMiracleEgyptMachine.m_LevelsViewZorder = {
    top = 10000,
    medium = 1000,
    down = 100
}


-- 构造函数
function CodeGameScreenMiracleEgyptMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)

    self.m_BubbleNodeList = {}
    self.m_ScatterMskNodeList = {}
    self.m_H1NodeList = {}

    self.m_betPaopaoPos = {}--各个bet下对应的泡泡位置
    self.m_norChangeWildNode = {}--保存每一轮图标变的wild图标，切bet时删除
    self.m_isFeatureOverBigWinInFree = true
    
    --init
    self:initGame()
end

function CodeGameScreenMiracleEgyptMachine:initGame()



    self.m_REEL_ResTime = 0.2
    self.m_BetChooseGear = 1000000 -- 这个bet来确定是否开启小猫吐泡泡
    

    self.m_BonusMusicPath = "MiracleEgyptSounds/sound_MiracleEgypt_Bonus_bg.mp3"


    self.m_configData = gLobalResManager:getCSVLevelConfigData("MiracleEgyptConfig.csv", "LevelMiracleEgyptConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)



    self:runCsbAction("normal")

    self.m_hasBigSymbol = false
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenMiracleEgyptMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = "MiracleEgyptSounds/MiracleEgypt_scatter.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenMiracleEgyptMachine:getReelHeight()
    return 591
end

function CodeGameScreenMiracleEgyptMachine:getReelWidth()
    return 1136
end

function CodeGameScreenMiracleEgyptMachine:scaleMainLayer()
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
            mainScale = (display.height - uiH - uiBH)/ (DESIGN_SIZE.height- uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        local posChange = 11
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale

        self.m_machineNode:setPositionY(mainPosY + posChange)
    end
end

function CodeGameScreenMiracleEgyptMachine:initUI(data)

    self:initFreeSpinBar()

    self:findChild("MaskPanel"):setVisible(false)

    self.m_GuoChangeView = util_createView("CodeMiracleEgyptSrc.MiracleEgyptGuoChang")
    self:addChild(self.m_GuoChangeView,GAME_LAYER_ORDER.LAYER_ORDER_TOP + 10) -- ,self.m_LevelsViewZorder.top
    self.m_GuoChangeView:setVisible(false) 
    -- self.m_GuoChangeView:runCsbAction("actionframe",true)
    self.m_GuoChangeView:setPosition(cc.p(self.m_root:getPosition()))

    self.m_BetChoseView = util_createView("CodeMiracleEgyptSrc.MiracleEgyptBetChose")
    self.m_root:addChild(self.m_BetChoseView,self.m_LevelsViewZorder.top - 110)
    self.m_BetChoseView:setPosition(- DESIGN_SIZE.width /2 ,- DESIGN_SIZE.height/2)
    self.m_BetChoseView:setVisible(false)

    -- self.m_LeaveGameTip = util_createView("CodeMiracleEgyptSrc.MiracleEgyptLeaveGameTip")
    -- self.m_root:addChild(self.m_LeaveGameTip,self.m_LevelsViewZorder.top - 110)
    -- self.m_LeaveGameTip:setPosition(- display.width /2  ,- display.height/2)
    -- self.m_LeaveGameTip:setVisible(false)
    
    

    self:findChild("Node_cat"):setLocalZOrder(self.m_LevelsViewZorder.medium - 100)
    self.m_catSpNode = util_spineCreate("Socre_MiracleEgypt_BlackCat", true,true)
    self:findChild("Node_cat"):addChild(self.m_catSpNode)
    self.m_catSpNode:setPosition(-30,-83)
    -- self:findChild("Node_cat"):setScale(0.8)
    self:findChild("Node_cat"):setPositionY(cc.p(self:findChild("Node_cat"):getPosition()).y + 25 )
    self:findChild("Node_cat"):setPositionX(cc.p(self:findChild("Node_cat"):getPosition()).x + 25 )

    self.m_ClickCat = util_createView("CodeMiracleEgyptSrc.MiracleEgypClickCat",self)
    self:findChild("Node_cat"):addChild(self.m_ClickCat,-1)
    self.m_ClickCat:setScale(1)




    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        if self.m_bIsBigWin then
            return
        end

        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet() -- (globalData.vecLineBetnum)[globalData.iLastBetIdx] * globalData.runCsvData.line_num
        local winRate = winCoin / totalBet
        local showTime = 2
        local soundTime = 2
        if winRate <= 1 then
            showTime = 1
        elseif winRate > 1 and winRate <= 3 then
            showTime = 2
            soundTime = 3
        elseif winRate > 3 then
            showTime = 3
            soundTime = 3
        end
        local soundName = "MiracleEgyptSounds/music_MiracleEgypt_last_win_".. showTime ..  ".mp3"
        globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)


    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    
end



function CodeGameScreenMiracleEgyptMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_goin.mp3")
            
            scheduler.performWithDelayGlobal(
                function()
                    self:resetMusicBg()
                    self:setMinMusicBGVolume()
                end,
                4,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenMiracleEgyptMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

end


function CodeGameScreenMiracleEgyptMachine:onExit()
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenMiracleEgyptMachine:removeObservers()
    BaseSlotoManiaMachine.removeObservers(self)

    -- 自定义的事件监听，也在这里移除掉
end

function CodeGameScreenMiracleEgyptMachine:onEnter()
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除

    self:addObservers()
    -- 更新猫Bet
    self:updateBetInfo()
    
    self:createAllBubbleNodeForBrokenLine()
end


-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMiracleEgyptMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "MiracleEgypt"
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样  
function CodeGameScreenMiracleEgyptMachine:getNetWorkModuleName()
    return "MiracleEgyptV2"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMiracleEgyptMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if symbolType == self.SYMBOL_H1_WILD then
        ccbName = "MiracleEgypt_H1_wild"

    end

    return ccbName
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMiracleEgyptMachine:getPreLoadSlotNodes()
    local loadNode = BaseSlotoManiaMachine:getPreLoadSlotNodes()
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_H1_WILD, count = 2}
    return loadNode
end

------------------------------------------------------------------------

----------------------------- 玩法处理 -----------------------------------

function CodeGameScreenMiracleEgyptMachine:initTopUI()
    local topNode = util_createView("CodeMiracleEgyptSrc.MiracleEgyptGameTopNode",self)
    self:addChild(topNode, GAME_LAYER_ORDER.LAYER_ORDER_TOP)
    if globalData.slotRunData.isPortrait == false then
        topNode:setScaleForResolution(true)
    end
    topNode:setPositionX(display.cx)
    topNode:setPositionY(display.height)

    self.m_topUI = topNode

    local coin_dollar_10 = self.m_topUI:findChild("coin_dollar_10")
    local endPos = coin_dollar_10:getParent():convertToWorldSpace(cc.p(coin_dollar_10:getPosition()))
    globalData.flyCoinsEndPos = clone(endPos)

    local lobbyHomeBtn = self.m_topUI:findChild("btn_layout_home")
    local endPos = lobbyHomeBtn:getParent():convertToWorldSpace(cc.p(lobbyHomeBtn:getPosition()))
    globalData.gameLobbyHomeNodePos = endPos
    -- topNode:setVisible(false)
end

function CodeGameScreenMiracleEgyptMachine:getBottomUINode( )
    return "CodeMiracleEgyptSrc.MiracleEgyptGameBottomNode"
end

---
-- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMiracleEgyptMachine:MachineRule_SpinBtnCall()

    gLobalSoundManager:setBackgroundMusicVolume(1)

    self.m_norChangeWildNode = {}
    -- 显示上一轮的泡泡
    self:showAllMoveBubbleNode()


    return false
end


---
-- 播放freespin动画触发
-- 改变背景动画等
function CodeGameScreenMiracleEgyptMachine:levelFreeSpinEffectChange()
    
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")

end

---
--播放freespinover 动画触发
--改变背景动画等
function CodeGameScreenMiracleEgyptMachine:levelFreeSpinOverChangeEffect(content)
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
end

---
--添加金边
function CodeGameScreenMiracleEgyptMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
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

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)

    local actionList={}
    reelEffectNode:setOpacity(0) 
    actionList[#actionList+1]=cc.FadeIn:create(0.3)
    local seq=cc.Sequence:create(actionList)  
    reelEffectNode:runAction(seq)  

    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

---
-- 每个reel条滚动到底
function CodeGameScreenMiracleEgyptMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) 
    and 
    (self:getGameSpinStage( ) ~= QUICK_RUN 
    or self.m_hasBigSymbol == true
    )
    then
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
            local actionList={}
            actionList[#actionList+1]=cc.FadeOut:create(0.3)
            actionList[#actionList+1]=cc.CallFunc:create(function(  )
                reelEffectNode[1]:runAction(cc.Hide:create())
                reelEffectNode[1]:setOpacity(100)   
                

            end)

            local seq=cc.Sequence:create(actionList)  
            reelEffectNode[1]:runAction(seq)  
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

    self:slotOneReelDownOver(reelCol)
end

-- 滚动结束调用
function CodeGameScreenMiracleEgyptMachine:slotOneReelDownOver(reelCol)    


    if self:getNextReelIsLongRun(reelCol + 1) 
        and (self:getGameSpinStage( ) ~= QUICK_RUN 
            or self.m_hasBigSymbol == true) then

                self:findChild("MaskPanel"):setVisible(true)
                
                local longRunIndex = reelCol + 1
                for k,v in pairs(self.m_slotParents) do
                    
                    if k == longRunIndex then
                        -- self.m_clipParent:getChildByTag(CLIP_NODE_TAG + k):setLocalZOrder( 6100 )
                        self:getClipNodeForTage(CLIP_NODE_TAG + k):setLocalZOrder( 6100 )
                    else
                        -- self.m_clipParent:getChildByTag(CLIP_NODE_TAG + k):setLocalZOrder( 6000 )
                        self:getClipNodeForTage(CLIP_NODE_TAG + k):setLocalZOrder( 6000 )
                    end
                    -- local ZOrder =  self.m_clipParent:getChildByTag(CLIP_NODE_TAG + k):getLocalZOrder()
                    local ZOrder =  self:getClipNodeForTage(CLIP_NODE_TAG + k):getLocalZOrder()
                    if k == longRunIndex then
                        self:findChild("MaskPanel"):setLocalZOrder(ZOrder- 1)
                    end
                end

    end
  
    if reelCol < self.m_iReelColumnNum then

        if self:findChild("MaskPanel"):isVisible() then
            for iCol = 1,self.m_iReelColumnNum do
                if iCol <= reelCol then
                    for iRow = self.m_iReelRowNum, 1, -1 do
                        -- local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                        local node = self:getReelParentChildNode(iCol,iRow)
                        if node and node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            if not self:checkIsCreate( iCol) then
                                local isplay = false
                                if iCol == reelCol then
                                    isplay = true
                                end
                                self:createOneActionSymbol(node,"buling",isplay)
                            end
                        end
                    end
                end
                
            end
            
       end

    elseif reelCol == self.m_iReelColumnNum then

        self:findChild("MaskPanel"):setVisible(false)

        for k,v in pairs(self.m_slotParents) do
            -- self.m_clipParent:getChildByTag(CLIP_NODE_TAG + k):setLocalZOrder( SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
            self:getClipNodeForTage(CLIP_NODE_TAG + k):setLocalZOrder( SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        for _,v in pairs(self.m_ScatterMskNodeList) do
            v:removeFromParent()
        end
        self.m_ScatterMskNodeList= {}
    end
    
    

end


---
-- 老虎机滚动结束调用
function CodeGameScreenMiracleEgyptMachine:slotReelDown()

    

    --performWithDelay(self,function() 

        
             -- 某个移动到h1上
            local dealyTime = self:createH1Action()
            performWithDelay(self,function() 

                if self.m_BetActionType == self.m_CatTrigger then
                    self.m_BetActionType = nil
                    self:updateBetInfo(true)
                    
                end
                
                self:HidAllMoveBubbleNode()

                -- 移除H1动画小块
                self:removeH1ActionNode()

                -- 改变对应小块为Wild
                local bulingTime = self:changNorSymbolToWild()
                --如果有扩散且bigwin 则震动
                self:startShake()

                performWithDelay(self,function() 
                    BaseSlotoManiaMachine.slotReelDown(self)   
                end, bulingTime)    
    
            end, dealyTime)  

           
    --end, self.m_ConchBubblesWaitTime)
    
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
    
end
function CodeGameScreenMiracleEgyptMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume()
    end)
    CodeGameScreenMiracleEgyptMachine.super.playEffectNotifyNextSpinCall(self)
end
function CodeGameScreenMiracleEgyptMachine:initGameStatusData(gameData)
    CodeGameScreenMiracleEgyptMachine.super.initGameStatusData(self,gameData)
    if gameData.gameConfig and gameData.gameConfig.extra then
        --进关初始化bet泡泡数据
        local existBubbles = gameData.gameConfig.extra.existBubbles
        for betString,posTab in pairs(existBubbles) do
            local betPos = {}
            for i,pos in ipairs(posTab) do
                table.insert(betPos,pos[2])
            end
            self.m_betPaopaoPos[betString] = betPos
        end
    end
end
-- 断线重连
function CodeGameScreenMiracleEgyptMachine:MachineRule_initGame(initSpinData)
    -- self:createAllBubbleNodeForBrokenLine()
    
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self.m_BetChoseView:setVisible(false)
    end
    
    
end

function CodeGameScreenMiracleEgyptMachine:playScatterTipMusicEffect()
    
    self.m_BetChoseView:setVisible(false)

    if self.m_ScatterTipMusicPath ~= nil then
        gLobalSoundManager:playSound(self.m_ScatterTipMusicPath) 
    end
end

function CodeGameScreenMiracleEgyptMachine:showFreeSpinView(effectData)
   -- gLobalSoundManager:playSound("ChineseStyleSounds/music_ChineseStyle_custom_enter_fs.mp3")


   local triggerFreeSpin = function(  )

        gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_View_Open.mp3")

        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinStart(self.m_runSpinResultData.p_freeSpinNewCount,function()
                gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_GuoChang.mp3")

                self.m_GuoChangeView:setVisible(true) 
                self.m_GuoChangeView:showAction(function(  )
                    self.m_GuoChangeView:setVisible(false) 
                end)
                performWithDelay(self,function() 

                    if self.m_currentMusicId then
                        gLobalSoundManager:stopAudio(self.m_currentMusicId)
                        self.m_currentMusicId = nil
                    end
                    


                    self.m_CollectView:removeFromParent()
                    self.m_CollectView = nil

                    self.m_topUI:setVisible(true)
                    self.m_bottomUI:setVisible(true)
                    self:findChild("Node_cat"):setVisible(true)

                    self:resetMusicBg()

                    self.m_clipParent:setVisible(true)
                    effectData.p_isPlay = true
                    self:playGameEffect()     
                end, 1.7)   
            end)
            
        else
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_GuoChang.mp3")
                self.m_GuoChangeView:setVisible(true) 
                self.m_GuoChangeView:showAction(function(  )
                    self.m_GuoChangeView:setVisible(false) 
                end)
                performWithDelay(self,function() 

                    if self.m_currentMusicId then
                        gLobalSoundManager:stopAudio(self.m_currentMusicId)
                        self.m_currentMusicId = nil
                    end

                    self.m_CollectView:removeFromParent()
                    self.m_CollectView = nil

                    self.m_topUI:setVisible(true)
                    self.m_bottomUI:setVisible(true)
                    self:findChild("Node_cat"):setVisible(true)
                    self.m_clipParent:setVisible(true)
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()     
                end, 1.7)
                
                  
            end)
        end
   end

   self.m_BetChoseView:setVisible(false)
   
   gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_GuoChang.mp3")
   self.m_GuoChangeView:setVisible(true) 
    self.m_GuoChangeView:showAction(function(  )
        self.m_GuoChangeView:setVisible(false) 
    end)
   performWithDelay(self,function() 
        self:removeAllMoveBubbleNode()
        self.m_clipParent:setVisible(false)

        self.m_topUI:setVisible(false)
        self.m_bottomUI:setVisible(false)
        self:findChild("Node_cat"):setVisible(false)

        --self.m_currentMusicId = gLobalSoundManager:playBgMusic( "MiracleEgyptSounds/sound_MiracleEgypt_Bonus_bg.mp3")

        self:resetMusicBg(nil,"MiracleEgyptSounds/sound_MiracleEgypt_Bonus_bg.mp3")

        local picks = self.m_runSpinResultData.p_selfMakeData.picks -- FreeSpin时点击的数据 -- 大于100 是单纯增加点击收集次数
        self.m_CollectView = util_createView("CodeMiracleEgyptSrc.MiracleEgyptCollectView",picks)
        self.m_root:addChild(self.m_CollectView,self.m_LevelsViewZorder.medium)
        self.m_CollectView:setPosition(cc.p(- DESIGN_SIZE.width/2,-DESIGN_SIZE.height/2))
        self.m_CollectView:setCallFunc(function(  )
                triggerFreeSpin()
        end,self)   
    end, 1.7)
    

   

    
end

function CodeGameScreenMiracleEgyptMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_View_Open.mp3")
    print("showFreeSpinOverView")

    local view =
        self:showFreeSpinOver(
        globalData.slotRunData.lastWinCoin,
        globalData.slotRunData.totalFreeSpinCount,
        function()
            gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_GuoChang.mp3")
            self.m_GuoChangeView:setVisible(true) 
            self.m_GuoChangeView:showAction(function(  )
                self.m_GuoChangeView:setVisible(false) 
            end)
            performWithDelay(self,function() 
                self:removeAllMoveBubbleNode()
                self:triggerFreeSpinOverCallFun()
                self:betChangeUpdateBubbleNode()
            end, 1.7)
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node}, 630)
end


---------------------------------------------------------------------------

----------------------------- 游戏逻辑 -----------------------------------

function CodeGameScreenMiracleEgyptMachine:getBetCpins( )
    local betCoin = globalData.slotRunData:getCurTotalBet() -- (globalData.vecLineBetnum)[globalData.iLastBetIdx]* self:getRunCsvData().line_num
    return betCoin
end
--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenMiracleEgyptMachine:updateChooseGear()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear=self.m_specialBets[1].p_totalBetValue
    end
end
-- 修改bet更新盘面上的泡泡
function CodeGameScreenMiracleEgyptMachine:betChangeUpdateBubbleNode()
    if self.m_isOnEnter == false then
        -- 移除泡泡
        self:removeAllMoveBubbleNode()
        self:removeH1ActionNode()
        self:removeAllPaopaoWild()
        --停止连线动画
        self:clearWinLineEffect()
        --创建更改bet后对应的泡泡
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local posTab = self.m_betPaopaoPos[""..totalBet]
        if posTab then
            for i,pos in ipairs(posTab) do
                local createPosition = self:getTarSpPos(pos)
                self:createMoveBubbleNodeForPos(createPosition, pos ,self.m_RunLockType )
            end
        end
    end
end

-- 更新猫Bet开启状态
function CodeGameScreenMiracleEgyptMachine:updateBetInfo(notPlay )
    local betCoin = self:getBetCpins( )
    self:updateChooseGear()
    if betCoin >= self.m_BetChooseGear then
        self.m_unlockFeature = true
        if not self.m_BetActionType or self.m_BetActionType ~= self.m_CatOpen then
            if self.m_BetActionType ~= self.m_CatTrigger then
                util_spinePlay(self.m_catSpNode, "idle_zhengyan", true)
                if self.m_isOnEnter == false then
                    if not notPlay then
                        -- gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BlackCat_OpenEyes.mp3")
                    end
                    
                end
                self.m_BetActionType = self.m_CatOpen
            end
            
        end
    else
        self.m_unlockFeature = false
        if not self.m_BetActionType or self.m_BetActionType ~= self.m_CatClose then
            if self.m_BetActionType ~= self.m_CatTrigger then
                util_spinePlay(self.m_catSpNode, "idle_biyan", true)
                if self.m_isOnEnter == false then
                    if not notPlay then
                       -- gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BlackCat_CloseEyes.mp3")
                    end
                    
                end
                self.m_BetActionType = self.m_CatClose
            end
            
        end
        
    end

    self.m_isOnEnter = false

end
-- 更新m_betPaopaoPos数据
function CodeGameScreenMiracleEgyptMachine:updateBetPaopaoPosData()
    if self.m_runSpinResultData.p_selfMakeData then
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local allBubbles = self.m_runSpinResultData.p_selfMakeData.allBubbles
        local betPos = {}
        for i,posTab in ipairs(allBubbles) do
            table.insert(betPos,posTab[2])
        end
        self.m_betPaopaoPos[""..totalBet] = betPos
    end
end


-- 断线创建泡泡
function CodeGameScreenMiracleEgyptMachine:createAllBubbleNodeForBrokenLine()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local posTab = self.m_betPaopaoPos[""..totalBet]
    if posTab then
        for i,pos in ipairs(posTab) do
            local createPosition = self:getTarSpPos(pos)
            self:createMoveBubbleNodeForPos(createPosition, pos ,self.m_RunLockType )
        end
    end

    -- local lockedBubble = self.m_runSpinResultData.p_selfMakeData.bubbles -- 已经固定的泡泡
    -- if lockedBubble then
    --     for k,v in pairs(lockedBubble) do
    --         if v[2] and v[2] ~= -1 then
    --             local oldindex = v[2]
    --             local newindex = v[2]
    --             local createPos =  self:getTarSpPos(oldindex )
    --             self:createMoveBubbleNodeForPos(createPos, newindex ,self.m_RunLockType )
    --         end
            
    --     end
    -- end
      

    -- local bottomBubble = self.m_runSpinResultData.p_selfMakeData.bottomBubble -- 新出来的泡泡
    -- if bottomBubble then
    --     for k,v in pairs(bottomBubble) do
    --         local newindex = v
    --         local targSpPos = self:getTarSpPos(newindex )
    --         local createPos = cc.p(targSpPos.x,targSpPos.y ) 
    --         self:createMoveBubbleNodeForPos(createPos, newindex,self.m_RunLockType )
    --     end
    -- end

    -- local conchBubble = self.m_runSpinResultData.p_selfMakeData.conchBubble -- 沙盘吹出来的泡泡
    -- if conchBubble then
    --     for k,v in pairs(conchBubble) do
    --         local newindex = v
    --         local targSpPos = self:getTarSpPos(newindex )
    --         local createPos = cc.p(targSpPos.x,targSpPos.y ) 
    --         self:createMoveBubbleNodeForPos(createPos, newindex,self.m_RunConchtype )
    --     end
    -- end

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenMiracleEgyptMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData.p_reels
    --更新当前bet下的泡泡数据
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        self:updateBetPaopaoPosData()
    end
    -- 移除泡泡
    self:removeAllMoveBubbleNode()
    -- 创建泡泡
    self:createAllBubbleNode()

    -- 猫飞泡泡
    if self.m_ConchBubblesWaitTime > 0 then
        self:runAllConchBubbleNodeAct()
    end

    performWithDelay(self,function()           
         -- 移动泡泡
        self:runAllBubbleNodeAct()
    end, self.m_ConchBubblesWaitTime)   
    
end
--创建泡泡
function CodeGameScreenMiracleEgyptMachine:createAllBubbleNode( )
    
    -- local lockedBubble = self.m_runSpinResultData.p_selfMakeData.bubbles -- 已经固定的泡泡
    -- local newBubble = self.m_runSpinResultData.p_selfMakeData.bottomBubble -- 新出来的泡泡
    -- local allWildsPos = self.m_runSpinResultData.p_selfMakeData.wilds -- 所有变成Wild的位置
    -- local H1ToWildPos = self.m_runSpinResultData.p_selfMakeData.wildPosition -- 移动到H1上方时扩散变成Wild的位置
    -- local ConchBubble = self.m_runSpinResultData.p_selfMakeData.conchBubble -- 沙盘吹出来的泡泡
    -- local picks = self.m_runSpinResultData.p_selfMakeData.picks -- FreeSpin时点击的数据 -- 大于100 是单纯增加点击收集次数

    
    self:createConchBubbles()
    self:createNewBubbles( )
    self:createLockedBubbles()  
 

end

function CodeGameScreenMiracleEgyptMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

function CodeGameScreenMiracleEgyptMachine:getTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end
function CodeGameScreenMiracleEgyptMachine:createConchBubbles( )
    self.m_ConchBubblesWaitTime = 0
    local conchBubble = self.m_runSpinResultData.p_selfMakeData.conchBubble -- 沙盘吹出来的泡泡
    if conchBubble then
        if #conchBubble > 0 then
            util_spinePlay(self.m_catSpNode, "idle_chufa", true)

            gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BlackCat_Trigger_Bubble.mp3")

            self.m_BetActionType = self.m_CatTrigger
            self.m_ConchBubblesWaitTime = 1.5
        end
        for k,v in pairs(conchBubble) do
            local newindex = v
            local Pos = cc.p(self:findChild("Node_cat"):getPosition()) 
            local createPos = cc.p(Pos.x - 30,Pos.y)
            self:createMoveBubbleNodeForPos(createPos, newindex,self.m_RunConchtype )
        end
    else
        release_print("self.m_runSpinResultData.p_selfMakeData.conchBubble  是 nil or false")
    end

end
function CodeGameScreenMiracleEgyptMachine:createNewBubbles( )

    local bottomBubble = self.m_runSpinResultData.p_selfMakeData.bottomBubble -- 新出来的泡泡
    if bottomBubble then

        for k,v in pairs(bottomBubble) do
            local newindex = v
            local targSpPos = self:getTarSpPos(newindex )
            local createPos = cc.p(targSpPos.x,targSpPos.y - 150  ) 
            self:createMoveBubbleNodeForPos(createPos, newindex,self.m_RunLockType )
        end
    else
        release_print("self.m_runSpinResultData.p_selfMakeData.bottomBubble  是 nil or false")
    end

end
-- 创建已经固定的信号
function CodeGameScreenMiracleEgyptMachine:createLockedBubbles( )
    local lockedBubble = self.m_runSpinResultData.p_selfMakeData.bubbles -- 已经固定的泡泡
    if lockedBubble then
        for k,v in pairs(lockedBubble) do
            local oldindex = v[1]
            local newindex = v[2]
            local createPos =  self:getTarSpPos(oldindex )
            self:createMoveBubbleNodeForPos(createPos, newindex ,self.m_RunLockType )
        end
    else
        release_print("self.m_runSpinResultData.p_selfMakeData.bubbles  是 nil or false")
    end
    
end
-- 创建
function CodeGameScreenMiracleEgyptMachine:createMoveBubbleNodeForPos( pos,index,runtype)
    
    local Bubble = {}

    Bubble.BubbleNode = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaqiu")
    Bubble.BubbleNode:setPosition(pos)
    self.m_root:addChild(Bubble.BubbleNode,self.m_LevelsViewZorder.down )

    Bubble.BubbleNodeBoom = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaqiuBao")
    Bubble.BubbleNodeBoom:setPosition(pos)
    self.m_root:addChild(Bubble.BubbleNodeBoom,self.m_LevelsViewZorder.down )
    Bubble.BubbleNodeBoom:setVisible(false)

    Bubble.index = index
    Bubble.runtype = runtype
    
    table.insert( self.m_BubbleNodeList, Bubble )

end
function CodeGameScreenMiracleEgyptMachine:runAllBubbleNodeAct( )

    for k,v in pairs(self.m_BubbleNodeList) do
        local Bubble = v

        
        local Pos =  self:getTarSpPos(Bubble.index )
        local func = function(  )
            if Bubble.index == -1 then
                Bubble.BubbleNode:setVisible(false)
                Bubble.BubbleNodeBoom:setPosition(Pos)
                Bubble.BubbleNodeBoom:setVisible(false)
            end
            
        end

        if Bubble.index == -1 then
           local newPos = cc.p(Bubble.BubbleNode:getPosition())  -- self:getTarSpPos(Bubble.index )
           Pos = cc.p(newPos.x,newPos.y + 250)
        end

        self:runMoveAct(Bubble.BubbleNode,Pos,func)

    end
    
end
function CodeGameScreenMiracleEgyptMachine:runAllConchBubbleNodeAct( )

    for k,v in pairs(self.m_BubbleNodeList) do
        local Bubble = v

        local Pos =  self:getTarSpPos(Bubble.index + 5 )
        if Bubble.index > 14 and Bubble.index < 20 then -- 轮盘的最后一行
            local targSpPos  = self:getTarSpPos(Bubble.index  )
            Pos = cc.p(targSpPos.x,targSpPos.y - self.m_newBubblesCutPosY ) 
        end
        local func = function(  )
            
        end

        if Bubble.runtype == self.m_RunConchtype then
            self:runConchAct(Bubble.BubbleNode,Pos,func)
            self.m_BubbleNodeList[k].runtype = self.m_RunLockType
        end

    end
    
end
function CodeGameScreenMiracleEgyptMachine:runConchAct(node,endPos,func )
    node:findChild("MiracleEgypt_shaqiu_1"):setOpacity(0)
    node:findChild("MiracleEgypt_shaqiu_idle_01_7"):setOpacity(0)
    node:setScale(0.1)

    local time = self.m_ConchBubblesWaitTime - 0.3
    local actionList = {}
    local startPos = cc.p(node:getPosition())

    actionList[#actionList+1] = cc.CallFunc:create(function()
        

        local actionList2 = {}
        actionList2[#actionList2 + 1] = cc.FadeIn:create(time)
        local seq2 = cc.Sequence:create(actionList2)
        node:findChild("MiracleEgypt_shaqiu_1"):runAction(seq2)

        local actionList3 = {}
        actionList3[#actionList3 + 1] = cc.FadeIn:create(time)
        local seq3 = cc.Sequence:create(actionList3)
        node:findChild("MiracleEgypt_shaqiu_idle_01_7"):runAction(seq3)

        local actionList1 = {}
        actionList1[#actionList1 + 1] = cc.ScaleTo:create(time,1)
        local seq1 = cc.Sequence:create(actionList1)
        node:runAction(seq1)
    end)

    local bezier1 = {        
        cc.p(startPos.x  + self.m_BubblesSwingX ,(startPos.y + endPos.y) /2), -- * 1/4
        cc.p(startPos.x - self.m_BubblesSwingX  ,(startPos.y + endPos.y) /2), -- * 3/4        
        cc.p( endPos.x ,endPos.y)
    }

    actionList[#actionList + 1] =  cc.BezierTo:create(time,bezier1) -- cc.JumpTo:create(time,cc.p(endPos),20, 1) --

    -- actionList[#actionList+1] = cc.DelayTime:create(time)
    actionList[#actionList+1] = cc.CallFunc:create(function()
        if func then
            func()
        end
        
    end)
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)

    
end

function CodeGameScreenMiracleEgyptMachine:runMoveAct( node,endPos,func )
    local time = 1
    local actionList = {}
    local startPos = cc.p(node:getPosition())
    local bezier1 = {        
        cc.p(startPos.x  + self.m_BubblesSwingX ,(startPos.y + endPos.y) /2), -- * 1/4
        cc.p(startPos.x - self.m_BubblesSwingX  ,(startPos.y + endPos.y) /2), -- * 3/4        
        cc.p( endPos.x ,endPos.y)
    }

    actionList[#actionList + 1] = cc.BezierTo:create(time,bezier1)

    -- actionList[#actionList+1] = cc.DelayTime:create(time)
    actionList[#actionList+1] = cc.CallFunc:create(function()
        if func then
            func()
        end
        
    end)
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)
end
function CodeGameScreenMiracleEgyptMachine:removeOneMoveBubbleNodeForPos( pos )
   for k,Bubble in pairs(self.m_BubbleNodeList) do
       if Bubble.pos == pos then
            Bubble.BubbleNode:removeFromParent()
            Bubble.BubbleNodeBoom:removeFromParent()

            table.remove( self.m_BubbleNodeList,k)
       end
   end
end
function CodeGameScreenMiracleEgyptMachine:HidOneMoveBubbleNodeForIndex( index )
    for k,Bubble in pairs(self.m_BubbleNodeList) do
        if Bubble.index == index then
            Bubble.BubbleNode:setVisible(false)
            Bubble.BubbleNodeBoom:setVisible(false)
        end
        
    end
end
function CodeGameScreenMiracleEgyptMachine:HidAllMoveBubbleNode(  )
    for k,Bubble in pairs(self.m_BubbleNodeList) do

        -- 渐隐效果
        local actionList={}
        actionList[#actionList+1]=cc.FadeOut:create(0.06)
        actionList[#actionList+1]=cc.CallFunc:create(function(  )     
            Bubble.BubbleNode:setOpacity(100)  
            Bubble.BubbleNode:setVisible(false)
        end)
        local seq=cc.Sequence:create(actionList)  
        Bubble.BubbleNode:runAction(seq)  


        Bubble.BubbleNodeBoom:setVisible(false)

        
    end
end
function CodeGameScreenMiracleEgyptMachine:showAllMoveBubbleNode(  )
    for k,Bubble in pairs(self.m_BubbleNodeList) do
        Bubble.BubbleNode:setVisible(true)
        Bubble.BubbleNodeBoom:setVisible(false)
    end
end
function CodeGameScreenMiracleEgyptMachine:removeAllMoveBubbleNode(  )
    for k,Bubble in pairs(self.m_BubbleNodeList) do
        Bubble.BubbleNode:removeFromParent()
        Bubble.BubbleNodeBoom:removeFromParent()
        self.m_BubbleNodeList[k] = nil
    end
    self.m_BubbleNodeList = {}
end
--移除所有泡泡变的wild
function CodeGameScreenMiracleEgyptMachine:removeAllPaopaoWild()
    while true do
        if #self.m_norChangeWildNode <= 0 then
            break
        end
        self:moveDownCallFun(self.m_norChangeWildNode[1])
        table.remove(self.m_norChangeWildNode,1)
    end
    self.m_norChangeWildNode = {}

    if self.m_runSpinResultData.p_selfMakeData then
        local allWildsPos = self.m_runSpinResultData.p_selfMakeData.wilds -- 所有变成Wild的位置
        
        for k,v in pairs(allWildsPos) do
            local index = v
            local fixPos = self:getRowAndColByPos(index)
            local targSp =  self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG) -- self:getReelParentChildNode(fixPos.iY,fixPos.iX)
            if targSp then
                if targSp.p_symbolType  == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    targSp:runAnim("idleframe")
                elseif targSp.p_symbolType == self.SYMBOL_H1_WILD then
                    --原图标可能是wild  也可能是H1图标
                    --如果是扩散的中心点，则是H1图标
                    -- if true then
                        targSp:changeCCBByName("Socre_MiracleEgypt_9",TAG_SYMBOL_TYPE.SYMBOL_SCORE_9)
                        targSp:runAnim("idleframe")
                    -- else
                    --     targSp:changeCCBByName("Socre_MiracleEgypt_Wild",TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    --     targSp:runAnim("idleframe")
                    -- end
                end
            end
        end
    end
end
function CodeGameScreenMiracleEgyptMachine:changScatterSymbolToWild( )

    local waitTime = 0

    local allWildsPos = self.m_runSpinResultData.p_selfMakeData.wilds -- 所有变成Wild的位置
    
    for kk,vv in pairs(allWildsPos) do
        local index = vv
        local fixPos = self:getRowAndColByPos(index)
        -- local targSp =self:getReelParent(fixPos.iY):getChildByTag(self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG))
        local targSp = self:getReelParentChildNode(fixPos.iY,fixPos.iX)
        if targSp  then

                if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    targSp:runAnim("actionframe2")
                    self:HidOneMoveBubbleNodeForIndex( index )
                    waitTime =  1
                end
        end
    end

    if waitTime ~= 0 then
        gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BlackCat_FalaoH1_TO_Wild.mp3")
    end

    return  waitTime
end
function CodeGameScreenMiracleEgyptMachine:changNorSymbolToWild( )

    local waitTime = 0

    local allWildsPos = self.m_runSpinResultData.p_selfMakeData.wilds -- 所有变成Wild的位置
    
    for k,v in pairs(allWildsPos) do
        waitTime = 1

        local index = v
        local fixPos = self:getRowAndColByPos(index)
        -- local targSp =self:getReelParent(fixPos.iY):getChildByTag(self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG))
        local targSp = self:getReelParentChildNode(fixPos.iY,fixPos.iX)
        if targSp   then

                if targSp.p_symbolType  == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    targSp:runAnim("actionframe3")

                elseif targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or targSp.p_symbolType ==  self.SYMBOL_H1_WILD  then

                    targSp:changeCCBByName("MiracleEgypt_H1_wild",self.SYMBOL_H1_WILD)
                    targSp:runAnim("actionframe")
                else

                    local node = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD, fixPos.iX, fixPos.iY)
                    local posX, posY = targSp:getPosition()
                    local worldPos = targSp:getParent():convertToWorldSpace(cc.p(posX, posY))
                    local nodePos = self:getReelParent(targSp.p_cloumnIndex):convertToNodeSpace(worldPos)
                    
                    local slotParentBig = self:getReelBigParent(targSp.p_cloumnIndex)
                    -- 添加到显示列表
                    if slotParentBig and self.m_configData:checkSpecialSymbol(TAG_SYMBOL_TYPE.SYMBOL_WILD) then
                        slotParentBig:addChild(node, self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD), targSp:getTag())
                    else
                        self:getReelParent(targSp.p_cloumnIndex):addChild(
                        node,
                        self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD),targSp:getTag())
                    end
                    
                    node.m_symbolTag = targSp.m_symbolTag
                    node.m_showOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD) --targSp.m_showOrder
                    node.p_layerTag = targSp.p_layerTag
                    node.m_isLastSymbol = true
                    node.m_bRunEndTarge = false
                    local columnData = self.m_reelColDatas[targSp.p_cloumnIndex]
                    node.p_slotNodeH = columnData.p_showGridH         
                    node:setPosition(nodePos)
                    node:runAnim("actionframe2")
            
                    local linePos = {}
                    linePos[#linePos + 1] =  {iX = fixPos.iX, iY = fixPos.iY}
                    node:setLinePos(linePos)
                    table.insert(self.m_norChangeWildNode,node)
                end
        end
    end

    if waitTime ~= 0 then
        gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BlackCat_Bubble_TO_Wild.mp3")
    end
    

    return  waitTime
end
function CodeGameScreenMiracleEgyptMachine:startShake()
    if self.m_runSpinResultData.p_selfMakeData.wildPosition then
        local num = table.nums(self.m_runSpinResultData.p_selfMakeData.wildPosition)
        if num > 0 then
            if self:isHaveBigWinMegawin() then
                self:shakeOneNodeForever()
            end
        end
    end
end
--判断是不是触发bigwin megawin什么的（调这里的时候还没有计算bigwin megawin效果，只能自己先判断了）
function CodeGameScreenMiracleEgyptMachine:isHaveBigWinMegawin()
    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local fLastWinBetNumRatio = self.m_runSpinResultData.p_winAmount / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    if fLastWinBetNumRatio >= iBigWinLimit then
        return true
    else
        return false
    end
end

function CodeGameScreenMiracleEgyptMachine:shakeOneNodeForever()
    local oldPos = cc.p(self:getPosition())
    local changePosY = math.random( 1, 3)
    local changePosX = math.random( 1, 3)
    local actionList2={}
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x - changePosX,oldPos.y - changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(0.05,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    local seq2=cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    self:runAction(action)

    performWithDelay(self,function()
        self:stopAction(action)
        self:setPosition(oldPos)
    end,2)
end
-- h1扩散相关
function CodeGameScreenMiracleEgyptMachine:createH1Action( )
    local H1ToWildPos = self.m_runSpinResultData.p_selfMakeData.wildPosition -- 移动到H1上方时扩散变成Wild的位置
    local time = 0

    for k,v in pairs(H1ToWildPos) do
        local h1Indx = tonumber(k)
        local h1Pos = self:getTarSpPos(h1Indx) 
        local fixPos = self:getRowAndColByPos(h1Indx)
        local changeList = v
        for i,index in pairs(changeList) do
            local BubbleNode = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaqiu")
            BubbleNode:setPosition(h1Pos)
            self.m_root:addChild(BubbleNode,self.m_LevelsViewZorder.down + 10)
            BubbleNode.index = index
            table.insert( self.m_H1NodeList,BubbleNode  ) 
        end

        local node = self:getSlotNodeWithPosAndType(self.SYMBOL_H1_WILD, fixPos.iX, fixPos.iY)
        node:setPosition(h1Pos)
        node.index = -1
        node.spindex = h1Indx
        self.m_root:addChild(node,self.m_LevelsViewZorder.down + 10)
        table.insert( self.m_H1NodeList,node  ) 
        node:setVisible(false)
        self:HidOneMoveBubbleNodeForIndex( h1Indx )

    end

    time = self:runH1Action()

    -- 改变scatter为wild
    local ChangeTime =  self:changScatterSymbolToWild()

    if time == 0 then
        time = ChangeTime
    end

    return time
end
function CodeGameScreenMiracleEgyptMachine:runH1Action( )
    
    local time = 0.5

    for k,v in pairs(self.m_H1NodeList) do
        local h1ActionNode = v

        if h1ActionNode.index == -1 then
            h1ActionNode:runAnim("actionframe1")

            local fixPos = self:getRowAndColByPos(h1ActionNode.spindex)
            -- local targSp =self:getReelParent(fixPos.iY):getChildByTag(self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG))
            local targSp = self:getReelParentChildNode(fixPos.iY,fixPos.iX)
            targSp:changeCCBByName("MiracleEgypt_H1_wild",self.SYMBOL_H1_WILD)

            targSp:runAnim("idleframe")
        else

            local endPos =  self:getTarSpPos(h1ActionNode.index )
            local func = function(  )
                
            end
            local actionList = {}
            actionList[#actionList+1] = cc.MoveTo:create(time,cc.p(endPos))
            -- actionList[#actionList+1] = cc.DelayTime:create(time)
            actionList[#actionList+1] = cc.CallFunc:create(function()
                func()
            end)
            local seq = cc.Sequence:create(actionList)
            h1ActionNode:runAction(seq)
        end
        
    end

    if self.m_H1NodeList == nil or #self.m_H1NodeList == 0 then
        time = 0
    end

    if time ~= 0 then
        gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BlackCat_FalaoH1_TO_Wild.mp3")
    end
    

    return time
   
end
function CodeGameScreenMiracleEgyptMachine:removeH1ActionNode( )
    for k,v in pairs(self.m_H1NodeList) do

        local h1ActionNode = v
        if h1ActionNode.index == -1 then
            self:moveDownCallFun(h1ActionNode)
        else
            h1ActionNode:removeFromParent()
        end
        self.m_H1NodeList[k] = nil
    end

    self.m_H1NodeList = {}
end

function CodeGameScreenMiracleEgyptMachine:updateNetWorkData()
    -- self:closeCheckTimeOut()
    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    -- 增加小猪银行存储钱数量  #TODO 小猪银行 稍后处理 2018-06-12 12:18:47
--    self.m_piggyBank:addCollectCoin((globalData.vecLineBetnum)[globalData.iLastBetIdx] * 
--                                    self:getRunCsvData().line_num)
    
    self:produceSlots()

    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end

    -- 猫吐泡泡时不让点spin
    performWithDelay(self,function()           
        self.m_isWaitingNetworkData = false

        self:operaNetWorkData()
    end, self.m_ConchBubblesWaitTime)   
end

-- betChooseView 逻辑
--
function CodeGameScreenMiracleEgyptMachine:handleBetChoseView(actType,func )
    -- actType --1 catView
    -- actType --2 betview

    self.m_BetChoseView:setBetChoseInfo( actType,func,self )
    self.m_BetChoseView:showAction( 1,false)
    self.m_BetChoseView:setVisible(true)
    
    -- local betstr = self.m_BetChooseGear
    -- local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    -- for i=1,#betList do
    --     local betData = betList[i]
    --     if betData.p_totalBetValue >= self.m_BetChooseGear  then

    --         betstr = betData.p_totalBetValue

    --         break
    --     end
    -- end
    self.m_BetChoseView:setMinBetStr( util_formatCoins(self.m_BetChooseGear, 30) )

end
-- 转化为玩家刚选的Bet
function CodeGameScreenMiracleEgyptMachine:changeFirstBet( )
    
    local a = globalData.slotRunData.iLastBetIdx
    local b = self.m_oldBetID

    -- 设置bet index
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

        
        
end


-- 强制转换为 猫吐泡泡的bet
function CodeGameScreenMiracleEgyptMachine:changeBetToCatOpen( )

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if betData.p_totalBetValue >= self.m_BetChooseGear  then

            globalData.slotRunData.iLastBetIdx =   betData.p_betId

            break
        end
    end
       
    -- 设置bet index
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

        
        
end

function CodeGameScreenMiracleEgyptMachine:getIsHaveBubble( )
    local isHaveBubbleNode = false
    if self.m_BubbleNodeList and #self.m_BubbleNodeList > 0 then
        isHaveBubbleNode = true
    end
    return isHaveBubbleNode
end


function CodeGameScreenMiracleEgyptMachine:firstInChangeBetTip( )
    local isHaveBubbleNode = false
    if self.m_BubbleNodeList and #self.m_BubbleNodeList > 0 then
        isHaveBubbleNode = true
    end
    return self.m_isFirstIn and isHaveBubbleNode
end-- b

-- 处理特殊关卡 遮罩层级
function CodeGameScreenMiracleEgyptMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    
    -- slotParent:getParent():setLocalZOrder(zOrder + MainClass.m_longRunAddZorder[parentData.cloumnIndex])
end


---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenMiracleEgyptMachine:playInLineNodes()
    
    if self.m_lineSlotNodes == nil then
        return
    end
    
    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                slotsNode:runAnim("actionframe3",true)
            else
                slotsNode:runLineAnim()
            end
            
        end
    end

end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenMiracleEgyptMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()

    end

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end

function CodeGameScreenMiracleEgyptMachine:checkIsCreate( iCol)
    local isCreate= false

    for i,v in ipairs(self.m_ScatterMskNodeList) do
        if iCol == v.p_cloumnIndex then
            isCreate= true
            break
        end
    end

    return isCreate
end

function CodeGameScreenMiracleEgyptMachine:createOneActionSymbol(endNode,actionName,isplay)
    if not endNode or not endNode.m_ccbName  then
          return
    end
    
    local fatherNode = endNode
    --endNode:setVisible(false)
    
    local node= util_createAnimation(fatherNode.m_ccbName..".csb")
    node.p_cloumnIndex = fatherNode.p_cloumnIndex

    if isplay then
        node:playAction(actionName)  
    end
    

    local targSpPos =  self:getNodePosByColAndRow(fatherNode.p_rowIndex, fatherNode.p_cloumnIndex)

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(targSpPos))
    local pos =  targSpPos -- self.m_root:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self.m_root:addChild(node , self.m_LevelsViewZorder.down - fatherNode.p_rowIndex)
    node:setPosition(pos)

    table.insert( self.m_ScatterMskNodeList, node )

    node:setVisible(false)
    --performWithDelay(self,function()           
        if #self.m_ScatterMskNodeList > 0 then
            node:setVisible(true)
        end
    --end, self.m_REEL_ResTime) 
    

    return node
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenMiracleEgyptMachine:showBonusAndScatterLineTip(lineValue,callFun)
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
        if slotNode == nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
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
    
                        break
                    end
                end
                
            end
        end

        if slotNode ~= nil then--这里有空的没有管
           
            slotNode = self:setSlotNodeEffectParent(slotNode)

            animTime = util_max(animTime,self:getNodeAnimTime(slotNode,slotNode:getLineAnimName())  ) --slotNode:getAniamDurationByName(slotNode:getLineAnimName())
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenMiracleEgyptMachine:getNodeAnimTime( node,animaName)
    local ccbNode = node:getCCBNode()
    if ccbNode == nil then
        return 0
    end

    return self:getSlotsNodeAnimTime(ccbNode,animaName)
end

function CodeGameScreenMiracleEgyptMachine:getSlotsNodeAnimTime(node,animName )
    if animName == nil then
        return 0
    end
    printInfo("获取时间名字 %s",animName)
    local time=util_csbGetAnimTimes(node:getCsbAct(),animName,20)
    return time
end

function CodeGameScreenMiracleEgyptMachine:requestSpinResult()
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
                        data=self.m_collectDataList,jackpot = self.m_jackpotList,unlockFeature= self.m_unlockFeature}
    -- local operaId = 
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName, 
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
end


---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenMiracleEgyptMachine:playInLineNodesIdle()

    if self.m_lineSlotNodes == nil then
        return
    end

    for i=1,#self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            slotsNode:runIdleAnim()
            if slotsNode.p_symbolType  then

                if  slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                    slotsNode:runAnim("idleframe2")
                end
                
            end
        end
    end

end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenMiracleEgyptMachine:showLineFrameByIndex(winLines,frameIndex)

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

                    slotsNode:runLineAnim()

                    if slotsNode.p_symbolType  then

                        if  slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then

                            slotsNode:runAnim("actionframe3",true)
                        end
                        
                    end
                    
                end
            end
        end
    end
end

return CodeGameScreenMiracleEgyptMachine
