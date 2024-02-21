---
-- island li
-- 2019年1月26日
-- CodeGameScreenWestMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenWestMachine = class("CodeGameScreenWestMachine", BaseNewReelMachine)

CodeGameScreenWestMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenWestMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenWestMachine.SYMBOL_TRIGGER_BONUS = 94 -- 超级bonus -- 服务器用的配置信号是101发送给客户端时转为94
CodeGameScreenWestMachine.SYMBOL_TRIGGER_BONUS_WILD = 201 -- 转换后的超级bonus 

CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_COWBOY  = GameEffect.EFFECT_SELF_EFFECT - 8  -- 牛仔 直接触发收集玩法
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_COINS  = GameEffect.EFFECT_SELF_EFFECT - 18 -- 获得钱 
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_COWGIRL  = GameEffect.EFFECT_SELF_EFFECT - 28 -- 女牛仔 整列wild
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_CRIMINAL   = GameEffect.EFFECT_SELF_EFFECT - 38 --  罪犯 随机wild
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_FREESPIN_TIMES   = GameEffect.EFFECT_SELF_EFFECT - 48 -- 获得freespin 次数
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_FREESPIN   = GameEffect.EFFECT_SELF_EFFECT - 48 -- 获得freespin 
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_BOX_GRAND  = GameEffect.EFFECT_SELF_EFFECT - 58 -- jackPot Grand 
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_BOX_MAJOR  = GameEffect.EFFECT_SELF_EFFECT - 68 -- jackPot Major 
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_BOX_MINOR  = GameEffect.EFFECT_SELF_EFFECT - 78 -- jackPot Minor 
CodeGameScreenWestMachine.EFFECT_BONUS_TYPE_BOX_MINI  = GameEffect.EFFECT_SELF_EFFECT - 88 -- jackPot MINI 



-- 顶部火车创建相关
local col1Index = 3
local currPosX = 163
local beginPosX = -71
local trainBoxMaxNum = 12
local reelDataIndex = {4,5,6,7,8}

CodeGameScreenWestMachine.m_TraiNodeList = {}

CodeGameScreenWestMachine.m_TRAIN_COWBOY = 1 -- 牛仔 直接触发收集玩法
CodeGameScreenWestMachine.m_TRAIN_CRIMINAL = 2 -- 罪犯 随机wild
CodeGameScreenWestMachine.m_TRAIN_COWGIRL = 3 -- 女牛仔 整列wild
CodeGameScreenWestMachine.m_TRAIN_COINS = 4 -- 获得钱
CodeGameScreenWestMachine.m_TRAIN_FREESPIN = 5 -- 获得freespin
CodeGameScreenWestMachine.m_TRAIN_BOX_GRAND = 6 --jackPot Grand
CodeGameScreenWestMachine.m_TRAIN_BOX_MAJOR = 7 --jackPot Major
CodeGameScreenWestMachine.m_TRAIN_BOX_MINOR = 8 --jackPot Minor
CodeGameScreenWestMachine.m_TRAIN_BOX_MINI = 9 --jackPot MINI
CodeGameScreenWestMachine.m_TRAIN_FREESPIN_Times = 10 -- freespinGame 获得freespin 次数


CodeGameScreenWestMachine.m_TopLittlReelData = {}
CodeGameScreenWestMachine.m_AllTopLittlReelData = {}
CodeGameScreenWestMachine.m_DefaultTopLittlReelData = {}

CodeGameScreenWestMachine.m_playOverBonusIndex = {} -- 已经播放过喷动画的火车头

local jpTip_OpenStates = 1
local jpTip_CloseStates = 0
local jpTip_IdleStates = 2


CodeGameScreenWestMachine.m_TrainWinCoins = 0 -- 火车玩法累计赢钱
CodeGameScreenWestMachine.m_isHaveTrainWinEffect = false -- 火车赢钱

CodeGameScreenWestMachine.m_RootNodeAddY = 0 
CodeGameScreenWestMachine.m_OutLines = true -- 是否断线进入
-- 构造函数
function CodeGameScreenWestMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_TraiNodeList = {}

    self.m_AllTopLittlReelData = {}
    self.m_DefaultTopLittlReelData = {}
    self.m_TopLittlReelData = {}
    self.m_TrainWinCoins = 0
    self.m_isHaveTrainWinEffect = false -- 火车赢钱
    self.m_playOverBonusIndex = {}
    self.jpTipOverBegin = false
    self.m_RootNodeAddY = 34 
    self.m_randomSymbolSwitch = true
    self.m_OutLines = true -- 是否断线进入
    self.m_isFeatureOverBigWinInFree = true

	--init
	self:initGame()
end

function CodeGameScreenWestMachine:initGame()


    self.m_configData = gLobalResManager:getCSVLevelConfigData("WestConfig.csv", "LevelWestConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)

end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWestMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "West"  
end


function CodeGameScreenWestMachine:initUI()



    self.m_reelRunSound = "WestSounds/WestSounds_longRun.mp3"
   
    self:findChild("reel_zi"):setVisible(true)
    self:findChild("reel_fs"):setVisible(false)
    
    

    self.m_gameBg:findChild("hc_zhenghe"):setPositionY(610)
    self.m_gameBg:findChild("hc_zhenghe"):setPositionX(7.5)

    -- 创建view节点方式
    -- self.m_WestView = util_createView("CodeWestSrc.WestView")
    -- self:findChild("xxxx"):addChild(self.m_WestView)
   
    self.m_JackPotBar = util_createView("CodeWestSrc.WestJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_JackPotBar)
    self.m_JackPotBar:initMachine(self)


    self.m_GuoChang = util_createAnimation("West_freebase_guochang.csb")
    self:addChild(self.m_GuoChang,GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.m_GuoChang:setVisible(true)
    self.m_GuoChang:setPosition(cc.p(display.width/2,display.height/2))
    self.m_GuoChang:setScaleX(display.width/ 1660)
    self.m_GuoChang:setScaleY(display.height/ 768)


    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local isBonusGameCoins = params[6]

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
            soundIndex = 3
        end

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}

        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE  then
            print("freespin最后一次 无论是否大赢都播放赢钱音效")
        else

            if not isBonusGameCoins then
                if winRate >= self.m_HugeWinLimitRate then
                    return
                elseif winRate >= self.m_MegaWinLimitRate then
                    return
                elseif winRate >= self.m_BigWinLimitRate then
                    return
                end
            end
            
        end

        if isBonusGameCoins then

            soundIndex = nil
        end

        if soundIndex then
            gLobalSoundManager:setBackgroundMusicVolume(0.4)
            local soundName = "WestSounds/music_West_last_win_".. soundIndex .. ".mp3"
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

            local actNode = cc.Node:create()
            self:addChild(actNode)
            local showTimes = 1
            if self.m_bottomUI then
                showTimes = self.m_bottomUI:getCoinsShowTimes( winCoin )
            end
            
            performWithDelay(self,function(  )
                gLobalSoundManager:setBackgroundMusicVolume(1)
            end,showTimes)
        end
        
        

        
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenWestMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        if not self.isInBonus then
            gLobalSoundManager:playSound("WestSounds/music_West_enter.mp3")
            scheduler.performWithDelayGlobal(function (  )
                
                self:resetMusicBg()
                self:setMinMusicBGVolume()
            end,2.5,self:getModuleName())
        end

        self.isInBonus = false
       

    end,0.4,self:getModuleName())
end

function CodeGameScreenWestMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_JackPotBar:changeFreeSpinByCount()
end

function CodeGameScreenWestMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            self:initTopLittlReelData( )

            -- 比对如果有不同，刷新副轮子
            -- if not self:ComparTraiNodeTypeWithReelData( ) then
                self:removeAllTraiNode( )
                self:initTraiNode( )
            -- end
        end
        
          
    end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenWestMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    self:removeBonusSoundGlobal( )
    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenWestMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == self.SYMBOL_TRIGGER_BONUS then
        return "Socre_West_Scatter"

    elseif symbolType == self.SYMBOL_TRIGGER_BONUS_WILD then
        return "Socre_West_Scatter_Wild"
    end
    
    return nil
end

function CodeGameScreenWestMachine:scaleMainLayer()
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
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY + self.m_RootNodeAddY )
    end

end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenWestMachine:MachineRule_initGame(  )

end

-- 收集小游戏 断线处理
function CodeGameScreenWestMachine:initFeatureInfo(spinData,featureData)
    if featureData.p_status  then
        if featureData.p_status ~= "CLOSED"  then

            self.isInBonus = true

            performWithDelay(self,function(  )
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
            end,0)

        
            -- 断线进入bonus  用服务器数据初始化
            local data = featureData.p_data or {}
            local selfData = data.selfData or {}
            local bonusData = selfData.bonusData or {}

            self:createWestPKBonusGamView( function(  )
                performWithDelay(self,function(  )
                    self:checkLocalGameNetDataFeatures() -- 添加feature
                    self:playGameEffect() -- 播放下一轮
                end,0.3)
                
            end,bonusData)

        else
            -- local feature = self.m_runSpinResultData.p_features
            -- if feature and #feature == 2 and feature[2] == 5 then
            --     self.m_runSpinResultData.p_features = {0} 
            -- end
            
        end
    
       
    end
    
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenWestMachine:initGameStatusData(gameData)

    

    if gameData then
        if gameData.gameConfig then
            if gameData.gameConfig.extra then
                if gameData.gameConfig.extra.initTopRow then
                    local initTopRow = gameData.gameConfig.extra.initTopRow
                    self.m_DefaultTopLittlReelData = initTopRow

                end
                if gameData.gameConfig.extra.allTopRow then
                    local allTopRow = gameData.gameConfig.extra.allTopRow
                    self.m_AllTopLittlReelData = allTopRow
                end
            end
        end
    end
     
    BaseNewReelMachine.initGameStatusData(self,gameData)

    local feature = gameData.feature
    if feature ~= nil then
        local features = feature.features or {}
        if #features == 2 and features[2] == 1 then
            local spinData = {}
            spinData.result = feature
            self:SpinResultParseResultData( spinData)
            self.m_initSpinData = self.m_runSpinResultData
        end
        
    end


end

function CodeGameScreenWestMachine:initTopLittlReelData( )
    

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then

        local totalBet = globalData.slotRunData:getCurTotalBet()
        local lastBetIdxReelData = self.m_AllTopLittlReelData[tostring(toLongNumber(totalBet) )]
        
        if lastBetIdxReelData then
            self.m_TopLittlReelData = lastBetIdxReelData
        else
            self.m_TopLittlReelData = self:getDefultTopReelData( ) 
        end

    else
        self:updateTopLittlReelDataToFreeSpin( )
    end

    
    
end



function CodeGameScreenWestMachine:enterLevel( )

    BaseNewReelMachine.enterLevel( self )

    self:initTopLittlReelData( )

    self:initTraiNode( )

end

--
--单列滚动停止回调
--
function CodeGameScreenWestMachine:slotOneReelDown(reelCol)    

    BaseNewReelMachine.slotOneReelDown(self,reelCol) 


    local ResNode = self:getFixSymbol(reelCol, 4)  
    if ResNode then
        if ResNode.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
            ResNode:runAnim("idleframe1")
        end
        
    end




    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local endCol = self:getScatterEndCol( )
    
        if endCol > 0 and reelCol == endCol then
             

            if self.m_reelRunSoundTag ~= -1 then
                --停止长滚音效
                -- printInfo("xcyy : m_reelRunSoundTag2 %d",self.m_reelRunSoundTag)
                gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
                self.m_reelRunSoundTag = -1
            end
            
        end
    end

    

end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWestMachine:levelFreeSpinEffectChange()

    self:findChild("reel_zi"):setVisible(false)
    self:findChild("reel_fs"):setVisible(true)

    -- 自定义事件修改背景动画
    self.m_JackPotBar:runCsbAction("idle2")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"freespin")

end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWestMachine:levelFreeSpinOverChangeEffect()

    self:findChild("reel_zi"):setVisible(true)
    self:findChild("reel_fs"):setVisible(false)

    -- 自定义事件修改背景动画
    self.m_JackPotBar:runCsbAction("idle1")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normal")
    
end
---------------------------------------------------------------------------

-- function CodeGameScreenWestMachine:showEffect_FreeSpin(effectData)
    

--     local time = 0

--     local winLines = self.m_reelResultLines
--     if winLines and #winLines > 0 then
--         time = self.m_changeLineFrameTime
--     end
    
--     performWithDelay(self,function(  )
--         BaseNewReelMachine.showEffect_FreeSpin(self,effectData)
--     end,time)

--     return true
-- end

----------- FreeSpin相关

function CodeGameScreenWestMachine:showFreeSpinStart(num,func,index)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func,BaseDialog.AUTO_TYPE_NOMAL,index)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenWestMachine:showEffect_FreeSpin(effectData)

    self.isInBonus = true

    return BaseNewReelMachine.showEffect_FreeSpin(self,effectData)
    
end

-- FreeSpinstart
function CodeGameScreenWestMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("WestSounds/music_West_fs_start_View.mp3")
    
    local createrFreespinView =  function()
        
        local iCol = nil
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local triggerColumn = selfdata.triggerColumn
        if triggerColumn and triggerColumn ~= -1  then
            iCol = triggerColumn + 1
        end

        local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local triggerColumn = selfdata.triggerColumn
            local _iCol = 1
            local _iRow = 1
            if triggerColumn and triggerColumn ~= -1  then
                _iCol = triggerColumn + 1
                local bonusTarSp =  self:getOneColBonusSymbol( _iCol )
                _iRow = bonusTarSp.p_rowIndex
            end
            self:lightAllSymbol(_iCol,_iRow )
            self:lightAllTrain( _iCol,_iRow )
            

            self:showGuoChang( function(  )

                
                local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
                if fsWinCoin ~= 0 then
                    self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(fsWinCoin))
                else
                    self.m_bottomUI:updateWinCount("")
                end
                

                 -- 重新创建顶部小火车为freespin的
                self:updateTopLittlReelDataToFreeSpin( )
                self:removeAllTraiNode( )
                self:initTraiNode( )

                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end )

        end,iCol)

        view:findChild("root"):setScale(self.m_machineRootScale)
    end

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

            createrFreespinView()
        else
            createrFreespinView()
        end
    end


    local showFsStartAct = function(  )
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local triggerColumn = selfdata.triggerColumn
        if triggerColumn and triggerColumn ~= -1  then

            local iCol = triggerColumn + 1
            local bonusTarSp =  self:getOneColBonusSymbol( iCol )
            bonusTarSp:setVisible(false)
            local iRow = bonusTarSp.p_rowIndex
            local bonusTarSpWorldPos = bonusTarSp:getParent():convertToWorldSpace(cc.p(bonusTarSp:getPosition()))
            local bonusTarSpNodePos = self:findChild("reelNode"):convertToNodeSpace(cc.p(bonusTarSpWorldPos))

            local trainBox = self:getReelTrainNodeFromCol(iCol )
            trainBox:setVisible(false)
            local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
            

            self:createActTrainBonus( iCol,iRow,function(  )
                bonusTarSp:setVisible(true)
            end,function(  )
                
                gLobalSoundManager:playSound("WestSounds/music_West_fs_Trigger.mp3")

                self:runActTrainBoxAni( TrainBoxAni,function(  )
                    trainBox:setVisible(true)

                    showFSView()  

                end )

                


            end )

        else

            showFSView()   
            
        end
    end
    
    


    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFsStartAct()
    end,0.5)

    
end

function CodeGameScreenWestMachine:triggerFreeSpinOverCallFun( isWait )

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
    self:hideFreeSpinBar()

    self:resetMusicBg()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)

    if not isWait then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE,GameEffect.EFFECT_FREE_SPIN_OVER)
    end
    

    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end


function CodeGameScreenWestMachine:showFreeSpinOverView()


    

   gLobalSoundManager:playSound("WestSounds/music_West_over_fs_View.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()

        self:checkLocalGameNetDataFeatures() -- 添加feature

        self:showGuoChang( function(  )
            
            
            self:triggerFreeSpinOverCallFun(true)
            -- 重置 顶部小火车为base的
            self:initTopLittlReelData( )
            self:removeAllTraiNode( )
            self:initTraiNode( )   
       end,function(  )

            performWithDelay(self,function(  )
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE,GameEffect.EFFECT_FREE_SPIN_OVER)
            end,0.5)
           

       end )

        

    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.1,sy=1.1},476)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWestMachine:MachineRule_SpinBtnCall()

    self.m_OutLines = false -- 是否断线进入

    self:removeSoundHandler() -- 移除监听

    self:setMaxMusicBGVolume()
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil 
    end


    

    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenWestMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenWestMachine:MachineRule_afterNetWorkLineLogicCalculate()

   
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
    
end

function CodeGameScreenWestMachine:getReelTrainNodeFromCol(col )
    
    local index = reelDataIndex[col]
    local node = self.m_TraiNodeList[index]

    return node
end

function CodeGameScreenWestMachine:getTopLittlReelDataFromCol( col )
    
    local index = reelDataIndex[col]
    local data =  self.m_TopLittlReelData[index]

    return data
end

function CodeGameScreenWestMachine:getBonusEffectType( trainType )
    
    if trainType == self.m_TRAIN_COWBOY then 

        return self.EFFECT_BONUS_TYPE_COWBOY -- 牛仔 直接触发收集玩法

    elseif trainType == self.m_TRAIN_CRIMINAL then 
        return self.EFFECT_BONUS_TYPE_CRIMINAL --  罪犯 随机wild
    elseif trainType == self.m_TRAIN_COWGIRL then 
        return self.EFFECT_BONUS_TYPE_COWGIRL -- 女牛仔 整列wild
    elseif trainType == self.m_TRAIN_COINS then 
        return self.EFFECT_BONUS_TYPE_COINS  -- 获得钱 
    elseif trainType == self.m_TRAIN_FREESPIN then 


        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            return self.EFFECT_BONUS_TYPE_FREESPIN_TIMES -- freespinGame 获得freespin 次数
        end
        -- return self.EFFECT_BONUS_TYPE_FREESPIN  -- 获得freespin 
    elseif trainType == self.m_TRAIN_BOX_GRAND then 
        return self.EFFECT_BONUS_TYPE_BOX_GRAND  -- jackPot Grand
    elseif trainType == self.m_TRAIN_BOX_MAJOR then 
        return self.EFFECT_BONUS_TYPE_BOX_MAJOR  -- jackPot Major 
    elseif trainType == self.m_TRAIN_BOX_MINOR then 
        return self.EFFECT_BONUS_TYPE_BOX_MINOR  -- jackPot Minor 
    elseif trainType == self.m_TRAIN_BOX_MINI then 
        return self.EFFECT_BONUS_TYPE_BOX_MINI  -- jackPot MINI
    end

end

function CodeGameScreenWestMachine:getHitColumnCoinsFromCol( col )
    
    local netCol = col -1

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local hitColumnCoins = selfdata.hitColumnCoins or {}
    local coins = 0
    for k,v in pairs(hitColumnCoins) do
        
        if k == tostring(netCol)  then
            coins = v
        end
    end
    
    return coins

end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWestMachine:addSelfEffect()

    self.m_playOverBonusIndex = {}

    self.m_TrainWinCoins = 0

    self.m_isHaveTrainWinEffect = false

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local hitColumns = selfdata.hitColumns or {}
    local length = table_length(hitColumns)
    -- 添加bonus game的自定义effect
    for k,v in pairs(hitColumns) do
        local hitCol = v + 1
        local hitCoins = self:getHitColumnCoinsFromCol( hitCol )
        local littlereeldata = self:getTopLittlReelDataFromCol( hitCol )
        local trainType = littlereeldata.type
        local bonusEffectType = self:getBonusEffectType( trainType )
        if bonusEffectType then

            if bonusEffectType == self.EFFECT_BONUS_TYPE_COWBOY then
                -- 如果是在游戏过程中触发bonus，移除bonus时间走自定义bonus逻辑
                self:removeEffectByType(GameEffect.EFFECT_BONUS )
                hitCol = nil
            end

            self.m_isHaveTrainWinEffect = true -- 火车赢钱

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = bonusEffectType
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = bonusEffectType
            selfEffect.hitCoins = hitCoins
            selfEffect.iCol = hitCol
        end
        

    end




end

---
-- 排序m_gameEffects 列表，根据 effectOrder
--
function CodeGameScreenWestMachine:sortGameEffects( )
   BaseNewReelMachine.sortGameEffects( self )

    -- 找到最后播放的特殊游戏effect 设置更新赢钱的状态
    if self.m_isHaveTrainWinEffect  then
        for i = #self.m_gameEffects,1,-1 do
            local effectdata = self.m_gameEffects[i]
            if effectdata.iCol then
                self.m_gameEffects[i].last = true

                break 
            end
        end
    end
    
end



---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWestMachine:MachineRule_playSelfEffect(effectData)


    if effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_COWBOY then 
        self:playBonusCowBoyEffect(effectData) -- 牛仔 直接触发收集玩法
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_CRIMINAL then
        
        performWithDelay(self,function(  )
            self:playBonusCriminalEffect(effectData) -- 罪犯 随机wild
        end,0.8)
        
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_COWGIRL then   
        performWithDelay(self,function(  )
            self:playBonusCowGirlEffect(effectData) -- 女牛仔 整列wild
        end,0.8)
        
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_COINS then  

        performWithDelay(self,function(  )
            self:playBonusCoinsEffect(effectData) -- 获得钱 
        end,0.8)
        
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_FREESPIN then   
        self:playBonusFreeSpinEffect(effectData) -- 获得freespin
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_FREESPIN_TIMES then   
        self:playBonusFreeSpinTimesEffect(effectData) -- 获得freespin次数
        
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_BOX_GRAND then 

        performWithDelay(self,function(  )
            self:playBonusJpGrandEffect(effectData) -- jackPot Grand
        end,0.8)
        
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_BOX_MAJOR then   

        performWithDelay(self,function(  )
            self:playBonusJpMajorEffect(effectData) -- jackPot Major
        end,0.5)
        
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_BOX_MINOR then  

        performWithDelay(self,function(  )
            self:playBonusJpMinorEffect(effectData) -- jackPot Minor
        end,0.8)  
        
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_TYPE_BOX_MINI then --  

        performWithDelay(self,function(  )
            self:playBonusJpMiniEffect(effectData) -- jackPot Mini
        end,0.8)
        

    end

      
    
	return true
end


function CodeGameScreenWestMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("Node_bg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg


end



------------------------
------------------
-------------
---------
--- 顶部副轮子玩法

function CodeGameScreenWestMachine:updateNetWorkData()

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

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:updateTopLittlReelData( )
    else
        self:updateTopLittlReelDataToFreeSpin( )
    end
    

    -- 顶部副轮子移动
    self:moveTrainBox( function(  )

        self:netBackReelsStop( )

    end )

    
end

function CodeGameScreenWestMachine:updateTopLittlReelData( )

    local selfdata = self.m_runSpinResultData.p_selfMakeData 
    if selfdata then
        local topRow = selfdata.topRow 
        if topRow then
            self.m_TopLittlReelData = topRow 
        else
            release_print("updateTopLittlReelData   topRow nil " )  
        end
    else
        release_print("updateTopLittlReelData   selfdata是 nil " )  
    end
    self:updateAllTopLittlReelData( )
   
    

end

function CodeGameScreenWestMachine:updateTopLittlReelDataToFreeSpin( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local fsTopRow = selfdata.fsTopRow

    self.m_TopLittlReelData = fsTopRow
end

function CodeGameScreenWestMachine:updateAllTopLittlReelData( )
    
    local totalBet = globalData.slotRunData:getCurTotalBet()
    self.m_AllTopLittlReelData[tostring(toLongNumber(totalBet))] = self.m_TopLittlReelData 

end

function CodeGameScreenWestMachine:netBackReelsStop( )

    
    local endCol = self:getScatterEndCol( )
    
    if endCol > 0 then
        self:shakeRootNode( function(  )
            self.m_isWaitChangeReel=nil
            self.m_isWaitingNetworkData = false
            self:operaNetWorkData()
            self:setColOneLongRunStates(  )
        end )
 
    else
        self.m_isWaitChangeReel=nil
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()
    end
    
    
    

end


function CodeGameScreenWestMachine:ComparTraiNodeTypeWithReelData( )
    local isSame = true

    if self.m_TraiNodeList and #self.m_TraiNodeList > 0 then
        if self.m_TopLittlReelData and #self.m_TopLittlReelData > 0 then
            for i=1,#self.m_TraiNodeList do
                local box = self.m_TraiNodeList[i]
        
                local TrainData = self.m_TopLittlReelData[i]
        
                if box.boxtype ~= TrainData.type then
                    isSame = false
                    break
                end
        
            end
        end
        
    end


    return isSame
end

function CodeGameScreenWestMachine:removeAllTraiNode( )
    
    for i=1,#self.m_TraiNodeList do
        local box = self.m_TraiNodeList[i]
        box:removeFromParent()
    end

    self.m_TraiNodeList = {}
end

-- 顶部火车
function CodeGameScreenWestMachine:initTraiNode( )


    local list = self.m_TopLittlReelData or {1,1,1,3,4,5,6,2,1,1,1,1}

    for i=1,trainBoxMaxNum do
        local TrainData = list[i]
        local TrainBox = self:createOneTrainBox( TrainData,i )

        local posX = beginPosX + (currPosX * ( i - 1)) 
        TrainBox:setPositionX(posX)
        
        table.insert(self.m_TraiNodeList ,TrainBox)

    end
    
end

function CodeGameScreenWestMachine:getTrainManName( boxtype )

        -- 创建小人
        if boxtype == self.m_TRAIN_COWBOY then
            return "West_hc_2","West_hc_chexiang_zhuanguang1"
        elseif boxtype == self.m_TRAIN_CRIMINAL then
            return "West_hc_3","West_hc_chexiang_zhuanguang2"
        elseif boxtype == self.m_TRAIN_COWGIRL then
            
            return "West_hc_4","West_hc_chexiang_zhuanguang2"
        end

end

function CodeGameScreenWestMachine:checkSetLabNum( TrainBox , trainboxbet )

    local lab = TrainBox:findChild("m_lab_coins")
    local totalBet = globalData.slotRunData:getCurTotalBet()
    if lab then
        if TrainBox.boxtype == self.m_TRAIN_COINS then
            if trainboxbet then
                local coins = trainboxbet * totalBet
                lab:setString(util_formatCoins(coins,3) )
            end
            
        end
    end
    

    
end

function CodeGameScreenWestMachine:TrainBoxRunIdleAnim( TrainBox )
    
    local isReelNode = false
    for i=1,#reelDataIndex do
        local reelIndex = reelDataIndex[i]
        if reelIndex ==  TrainBox.index then
            isReelNode = true
            break
        end
    end

    if isReelNode then
        TrainBox:runCsbAction("idle",true)

        if TrainBox.heroBg then
            TrainBox.heroBg:runCsbAction("idle",true)
        end
    else
        TrainBox:runCsbAction("idle")

        if TrainBox.heroBg then
            TrainBox.heroBg:runCsbAction("stop")
        end
    end

    
end

function CodeGameScreenWestMachine:createOneTrainBox( trainData , index , parent )


    local boxtype = trainData.type
    local trainboxbet = trainData.value

    local TrainBox = util_createAnimation(self:getTrainBoxCsbName( boxtype ))
    TrainBox.index = index
    TrainBox.boxtype = boxtype
    if parent then
        parent:addChild(TrainBox)
    else
        self.m_gameBg:findChild("hc_zhenghe"):addChild(TrainBox)
    end
    
    -- 创建车连接线
    TrainBox.TrainBoxLine = util_createAnimation("West_hc_lianjie_node.csb")
    TrainBox.TrainBoxLine:runCsbAction("idleframe")
    TrainBox:findChild("Node_line"):addChild(TrainBox.TrainBoxLine) 

    -- 创建车轱辘
    TrainBox.TrainBoxWheel = util_createAnimation("West_hc_lunzi.csb")
    TrainBox.TrainBoxWheel:runCsbAction("idleframe")
    TrainBox:findChild("Node_LunZi"):addChild(TrainBox.TrainBoxWheel) 
    
    local manName,idleBgName = self:getTrainManName( boxtype )
    if manName then
        TrainBox.hero = util_spineCreate(manName,true,true) 
        TrainBox:addChild(TrainBox.hero) 
        TrainBox.hero:setPositionY(6)
        util_spinePlay(TrainBox.hero,"idleframe")

        local heroBgNode = TrainBox:findChild("Node_zhuanguang")
        if heroBgNode then
            -- 创建英雄idlebg
            TrainBox.heroBg = util_createAnimation(idleBgName .. ".csb")
            
            heroBgNode:addChild(TrainBox.heroBg) 
        end
        
    end
    self:checkSetLabNum( TrainBox ,trainboxbet)

    
    self:TrainBoxRunIdleAnim( TrainBox )

    return TrainBox
end



function CodeGameScreenWestMachine:getTrainBoxCsbName( boxtype )
    
    if boxtype == self.m_TRAIN_BOX_GRAND then
        return "West_hc_1_node.csb"
    elseif boxtype == self.m_TRAIN_BOX_MAJOR then
        return "West_hc_7_node.csb"
    elseif boxtype == self.m_TRAIN_BOX_MINOR then
        return "West_hc_8_node.csb"
    elseif boxtype == self.m_TRAIN_BOX_MINI then
        return "West_hc_9_node.csb"

        
    elseif boxtype == self.m_TRAIN_COWBOY then
        return "West_hc_2_node.csb"
    elseif boxtype == self.m_TRAIN_CRIMINAL then
        return "West_hc_3_node.csb"
    elseif boxtype == self.m_TRAIN_COWGIRL then
        return "West_hc_4_node.csb"
    elseif boxtype == self.m_TRAIN_COINS then
        return "West_hc_5_node.csb"
    elseif boxtype == self.m_TRAIN_FREESPIN then

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            return "West_hc_10_node.csb"
        else
            return "West_hc_6_node.csb"
        end

    end

end

function CodeGameScreenWestMachine:moveTrainBox( func )
    
    gLobalSoundManager:playSound("WestSounds/music_West_moveTrainBox.mp3")

    local removeTrainBox = self.m_TraiNodeList[1]
    table.remove(self.m_TraiNodeList,1)

    release_print("self.m_TopLittlReelData   是 --" .. cjson.encode(self.m_TopLittlReelData) )  

    local addTrainData = self.m_TopLittlReelData[#self.m_TopLittlReelData]
    local addTrainBox = self:createOneTrainBox( addTrainData,trainBoxMaxNum )
    local posX =  beginPosX + (currPosX * trainBoxMaxNum ) 
    addTrainBox:setPositionX(posX)
    table.insert(self.m_TraiNodeList,addTrainBox)

    self:playTrainBoxMoveByAct( removeTrainBox,cc.p(-currPosX,0) , function(  )
        removeTrainBox:removeFromParent()
    end )
    
    for i=1,#self.m_TraiNodeList do
        local box = self.m_TraiNodeList[i]
        box.index = i -- 重新刷新index

        local TrainData = self.m_TopLittlReelData[i]

        if box.boxtype ~= TrainData.type then
            print("出错了！！！！")
        end

        if box.index == reelDataIndex[#reelDataIndex] then
            self:TrainBoxRunIdleAnim( box )
        end
        
        if box.index == reelDataIndex[1] - 1 then
            self:TrainBoxRunIdleAnim( box )
        end

        local callFunc = nil
        if i == #self.m_TraiNodeList then
            callFunc = function(  )

                if func then
                    func()
                end
            end
        end
        self:playTrainBoxMoveByAct( box,cc.p(-currPosX,0) , function(  )
            if callFunc then
                callFunc()
            end
            
        end )
    end


    


end

function CodeGameScreenWestMachine:playTrainBoxMoveByAct( node,moveDis , func )


    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        if node.TrainBoxWheel then
            node.TrainBoxWheel:runCsbAction("actionframe")
        end

    end)
    actList[#actList + 1]  = cc.MoveBy:create(18/30,cc.p(moveDis))
    actList[#actList + 1]  = cc.DelayTime:create(3/30)
    actList[#actList + 1]  = cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)

    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end



------------------------
--------------------
----------------
------pk玩法

function CodeGameScreenWestMachine:showEffect_Bonus( effectData )
    local time = 0

    local winLines = self.m_reelResultLines
    if winLines and #winLines > 0 then
        time = self.m_changeLineFrameTime
    end
    
    performWithDelay(self,function(  )
        BaseNewReelMachine.showEffect_Bonus(self,effectData)
    end,time)

    return true
end

function CodeGameScreenWestMachine:showBonusGameView(effectData)

        
        self.isInBonus = true

        -- 停止播放背景音乐
        self:clearCurMusicBg()

        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()


        if self.m_bProduceSlots_InFreeSpin then
            self:hideFreeSpinBar()
        end

        local triggerBonusFunc = function(  )
            -- 第一次进入bonus  自己初始化维护数据
            local bonusData = {}
            bonusData.cells = {}
            for i=1,18 do
                table.insert( bonusData.cells, "null" )
            end
            bonusData.hp1 = 3 --玩家血量
            bonusData.hp2 = 3 --敌人血量
            bonusData.multiple = 0 --结算时的倍数
            bonusData.phase = 0 --当前阶段 0:PK 1 :送奖
            bonusData.points = 0 -- 点数
            bonusData.lineBet = 1 -- 平均bet
    
    
            self:createWestPKBonusGamView( function(  )
    
                performWithDelay(self,function(  )
                    self:checkLocalGameNetDataFeatures() -- 添加feature
                    effectData.p_isPlay = true
                    self:playGameEffect() -- 播放下一轮
                end,0.3)
                
            end,bonusData)
        end
    
    
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local triggerColumn = selfdata.triggerColumn
        if triggerColumn   then
    
            if triggerColumn == -1 then
                -- 收集触发
                triggerBonusFunc()  
    
            else

                performWithDelay(self,function(  )
                    -- bonus 火车触发
                    local iCol = triggerColumn + 1
                    local bonusTarSp =  self:getOneColBonusSymbol( iCol )
                    bonusTarSp:setVisible(false)
                    local iRow = bonusTarSp.p_rowIndex
                    local bonusTarSpWorldPos = bonusTarSp:getParent():convertToWorldSpace(cc.p(bonusTarSp:getPosition()))
                    local bonusTarSpNodePos = self:findChild("reelNode"):convertToNodeSpace(cc.p(bonusTarSpWorldPos))


                    local trainBox = self:getReelTrainNodeFromCol(iCol )
                    trainBox:setVisible(false)
                    local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
                    
                   

                    self:createActTrainBonus( iCol,iRow,function(  )
                        bonusTarSp:setVisible(true)
            
                        
                    end,function(  )
                        
                        gLobalSoundManager:playSound("WestSounds/music_West_CowBoyTriggerBonus.mp3")
                        
                        self:runActTrainBoxAni( TrainBoxAni,nil,function(  )
                            
                            trainBox:setVisible(true)

                            self:lightAllSymbol(iCol,iRow )
                            self:lightAllTrain( iCol,iRow )

                            performWithDelay(self,function(  )
                                triggerBonusFunc()  
                            end,0.1)
                            

                        end )

            
                    end )
                end,0.5)
                
    
            end
           
    
        else
         
            triggerBonusFunc()    
    
        end

end

function CodeGameScreenWestMachine:createWestPKBonusGamView( func,bonusData)


    self:resetMusicBg(nil,"WestSounds/music_West_bonusgame.mp3")



    if self.m_bProduceSlots_InFreeSpin then
        self:hideFreeSpinBar()
    end

    local data = {}
    data.machine = self
    data.bonusData = bonusData

    local WestPKBonusGameMain = util_createView("CodeWestSrc.PKBonusGame.WestPKBonusGameMainView",data)
    self:addChild(WestPKBonusGameMain,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER )
    self.m_WestPKBonusGameMain = WestPKBonusGameMain
    if display.width <= 1155 then
        WestPKBonusGameMain:setScale(display.width/1307)
    else
        WestPKBonusGameMain:setScale(0.95)
    end
    
    WestPKBonusGameMain:setPosition(cc.p(display.width/2 + 3,display.height/2 + self.m_RootNodeAddY - 13))

    WestPKBonusGameMain:setEndCall( function(  )
        
            self:removeBonusSoundGlobal( )

            if self.m_bProduceSlots_InFreeSpin then
                self:showFreeSpinBar()
            end


            gLobalSoundManager:playSound("WestSounds/music_West_BonusGameOver.mp3")

            self:findChild("reelNode"):setVisible(true)
            
            WestPKBonusGameMain.m_BonusWinView:runCsbAction("animation2")
            WestPKBonusGameMain.m_BonusLoseView:runCsbAction("over")
            WestPKBonusGameMain:runCsbAction("over")
            performWithDelay(self,function(  )

                if  self.m_OutLines  then
                    print("断线不播放连线")
                    self.m_OutLines = false
                else
                    self:bonusOverAddLinesEffect() 
                end
               
                

                self:removeEffectByType(GameEffect.EFFECT_EPICWIN)
                self:removeEffectByType(GameEffect.EFFECT_MEGAWIN)
                self:removeEffectByType(GameEffect.EFFECT_BIGWIN)

                -- 通知bonus 结束， 以及赢钱多少
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{WestPKBonusGameMain.m_serverWinCoins, GameEffect.EFFECT_LINE_FRAME})
                
                -- 更新游戏内每日任务进度条
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
                local isNotifyUpdateTop = true
                if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
                    isNotifyUpdateTop = false

                else
                    -- 刷新赢钱
                    self.m_bottomUI:notifyTopWinCoin()

                end

                
                if WestPKBonusGameMain then
                    WestPKBonusGameMain:removeFromParent()
                    WestPKBonusGameMain = nil
                end
                self.m_WestPKBonusGameMain = nil
            
                self:resetMusicBg(true)

                if func then
                    func()
                end
                
            end,21/30)
            
    end)


    WestPKBonusGameMain:setVisible(true)
    WestPKBonusGameMain:runCsbAction("idle1")
   

    if WestPKBonusGameMain.p_bonusExtra.phase == 1 then -- 当前阶段 0:PK 1 :送奖

        WestPKBonusGameMain:setAllDoorCantClick( )

        self:findChild("reelNode"):setVisible(false)

        WestPKBonusGameMain.m_GamePlayStates = WestPKBonusGameMain.m_GamePlayStates_REWORD
        WestPKBonusGameMain:runCsbAction("idle2",true)
        WestPKBonusGameMain:findChild("root"):setVisible(false)
        if WestPKBonusGameMain.p_bonusExtra.hp1 > 0 then
            self:resetMusicBg(nil,"WestSounds/music_West_bonusgame_Win.mp3")
            -- 赢
            WestPKBonusGameMain.m_BonusWinView:setVisible(true)
        else
            self:resetMusicBg(nil,"WestSounds/music_West_bonusgame_Lose.mp3")
            -- 输
            WestPKBonusGameMain.m_BonusLoseView:setVisible(true)
        end
        WestPKBonusGameMain:startGameCallFunc()
    
    else
        WestPKBonusGameMain.m_GamePlayStates = WestPKBonusGameMain.m_GamePlayStates_PK

        gLobalSoundManager:playSound("WestSounds/music_West_EnterBonusGuochang.mp3")

        WestPKBonusGameMain:runCsbAction("start",false,function(  )

            WestPKBonusGameMain:updateBulingAct( )

            WestPKBonusGameMain:runCsbAction("idle2",true)
            
            self:findChild("reelNode"):setVisible(false)

            WestPKBonusGameMain:startGameCallFunc()
        end)

       
    end

    
       




    
    
end



---
-- 自己添加freespin 或 respin 或 bonus事件
--
function CodeGameScreenWestMachine:checkLocalGameNetDataFeatures()

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

            -- self:sortGameEffects( )
            -- self:playGameEffect()
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            
            -- if self.m_initFeatureData.p_status=="CLOSED" then
            --     return
            -- end

            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- self:sortGameEffects( )
            -- self:playGameEffect()
        end

    end

end





------------------------
------------------
-----------
-- bonusEffect 函数 

-- 牛仔 直接触发收集玩法
function CodeGameScreenWestMachine:playBonusCowBoyEffect( effectData )

    self:showBonusGameView(effectData)

    -- effectData.p_isPlay = true
    -- self:playGameEffect()


end

--  罪犯 随机wild
function CodeGameScreenWestMachine:playBonusCriminalEffect(effectData) 


    local iCol = effectData.iCol
    local bonusTarSp =  self:getOneColBonusSymbol( iCol )
    bonusTarSp:setVisible(false)
    local iRow = bonusTarSp.p_rowIndex

    local trainBox = self:getReelTrainNodeFromCol(iCol )
    local trainBoxWorldPos = trainBox:getParent():convertToWorldSpace(cc.p(trainBox:getPosition()))
    local trainBoxNodePos = self:findChild("reelNode"):convertToNodeSpace(cc.p(trainBoxWorldPos))


    trainBox:setVisible(false)
    local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
    

    self:createActTrainBonus( iCol,iRow,function(  )
        bonusTarSp:setVisible(true)

    end ,function(  )
        
        
        local triggerBonusFunc = function(  )
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local wildPos = selfdata.randomWild or {}
        
            for i=1,#wildPos do
                local reelIndex = wildPos[i]
    
                local actinfo = {}
                actinfo.currPos = trainBoxNodePos
                actinfo.reelIndex = reelIndex
                actinfo.func = nil
                actinfo.moveTime = (i - 1 ) * 0.1
                
                if i == #wildPos then
                    actinfo.func = function(  )

                        self:lightAllSymbol(iCol,iRow )
                        self:lightAllTrain( iCol,iRow )

                        performWithDelay(self,function(  )
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end,0.5)
                        
                    end 
                end
                self:CreateRandomWildActNode( actinfo )
    
            end
        end

        gLobalSoundManager:playSound("WestSounds/music_West_CriminalThrow.mp3")
        self:runActTrainBoxAni( TrainBoxAni,function(  )
            trainBox:setVisible(true)

            triggerBonusFunc()  

        end )


    end)


    
end

-- 女牛仔 整列wild
function CodeGameScreenWestMachine:playBonusCowGirlEffect(effectData) 


    local iCol = effectData.iCol
    local bonusTarSp =  self:getOneColBonusSymbol( iCol )
    bonusTarSp:setVisible(false)
    local iRow = bonusTarSp.p_rowIndex
    local bonusTarSpWorldPos = bonusTarSp:getParent():convertToWorldSpace(cc.p(bonusTarSp:getPosition()))
    local bonusTarSpNodePos = self:findChild("reelNode"):convertToNodeSpace(cc.p(bonusTarSpWorldPos))

    local trainBox = self:getReelTrainNodeFromCol(iCol )
    trainBox:setVisible(false)
    local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
    

    self:createActTrainBonus( iCol,iRow,function(  )
        bonusTarSp:setVisible(true)

    end ,function(  )

        


        local triggerBonusFunc = function(  )
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local columnWild = selfdata.columnWild or {}
        
            gLobalSoundManager:playSound("WestSounds/music_West_CowGrilHit_LongWildShow.mp3")
            
            for i=1,#columnWild do
                local curriCol = columnWild[i] + 1

                local actinfo = {}
                actinfo.iCol = curriCol
                actinfo.func = nil
    
                if i == #columnWild then
                    actinfo.func = function(  )

                        self:lightAllSymbol(iCol,iRow )
                        self:lightAllTrain( iCol,iRow )

                        performWithDelay(self,function(  )
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end,0.5)
                    end 
                end
                self:CreateColWildActNode( actinfo )
        
            end
        end

        gLobalSoundManager:playSound("WestSounds/music_West_CowGrilHit.mp3")

        self:runActTrainBoxAni( TrainBoxAni,function(  )
            trainBox:setVisible(true)

            triggerBonusFunc()  

        end )



        

    end)
    
    
end

-- 获得钱
function CodeGameScreenWestMachine:playBonusCoinsEffect(effectData) 

    local beiginCoins = self.m_TrainWinCoins
    self.m_TrainWinCoins = self.m_TrainWinCoins + effectData.hitCoins
    local isupdateTop = false
    if effectData.last then
        isupdateTop = true
    end

    local iCol = effectData.iCol
    local bonusTarSp =  self:getOneColBonusSymbol( iCol )
    bonusTarSp:setVisible(false)
    local iRow = bonusTarSp.p_rowIndex

    local trainBox = self:getReelTrainNodeFromCol(iCol )
    trainBox:setVisible(false)
    local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
    

    self:createActTrainBonus( iCol,iRow,function(  )
        bonusTarSp:setVisible(true)

    end ,function(  )
        
        gLobalSoundManager:playSound("WestSounds/music_West_CollectCoins.mp3")

        self:runActTrainBoxAni( TrainBoxAni,function(  )
            trainBox:setVisible(true)

            local worldStartPos = trainBox:getParent():convertToWorldSpace(cc.p(trainBox:getPosition()))
            local startPos = self:convertToNodeSpace(worldStartPos)
            local time = 0.5

            self:createBonusPkCoinsFly( startPos ,time,function(  )
                
                self:updateSpecialCoins( self.m_TrainWinCoins , beiginCoins , isupdateTop )

                self:lightAllSymbol(iCol,iRow )
                self:lightAllTrain( iCol,iRow )
    
                performWithDelay(self,function(  )
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,1)

            end )

           

        end )

        

    end )

    
    

end
--freespingame  获得freespin 次数
function CodeGameScreenWestMachine:playBonusFreeSpinTimesEffect( effectData )
    

    effectData.p_isPlay = true
    self:playGameEffect()
end

-- 获得freespin
function CodeGameScreenWestMachine:playBonusFreeSpinEffect(effectData) 
    effectData.p_isPlay = true
    self:playGameEffect()
end

-- jackPot Grand
function CodeGameScreenWestMachine:playBonusJpGrandEffect(effectData) 

    local beiginCoins = self.m_TrainWinCoins
    self.m_TrainWinCoins = self.m_TrainWinCoins + effectData.hitCoins
    local isupdateTop = false
    if effectData.last then
        isupdateTop = true
    end

    local iCol = effectData.iCol
    local bonusTarSp =  self:getOneColBonusSymbol( iCol )
    bonusTarSp:setVisible(false)
    local iRow = bonusTarSp.p_rowIndex

    local trainBox = self:getReelTrainNodeFromCol(iCol )
    trainBox:setVisible(false)
    local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
    

    self:createActTrainBonus( iCol,iRow,function(  )

        bonusTarSp:setVisible(true)

    end ,function(  )
        
        gLobalSoundManager:playSound("WestSounds/music_West_TrainBonus_Trigeer_JackPot_Grand.mp3")

        self:runActTrainBoxAni( TrainBoxAni,function(  )
            trainBox:setVisible(true)

            self:updateSpecialCoins( self.m_TrainWinCoins , beiginCoins , isupdateTop )

            local coins = effectData.hitCoins or 0
            local index = 1
            local currFunc = function(  )

                self:lightAllSymbol(iCol,iRow )
                self:lightAllTrain( iCol,iRow )

                performWithDelay(self,function(  )
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,0.5)
            end
            self:showJackpotWinView(index,coins,currFunc)

        end )



    end )

    

end

-- jackPot Major
function CodeGameScreenWestMachine:playBonusJpMajorEffect(effectData) 

    local beiginCoins = self.m_TrainWinCoins
    self.m_TrainWinCoins = self.m_TrainWinCoins + effectData.hitCoins
    local isupdateTop = false
    if effectData.last then
        isupdateTop = true
    end

    local iCol = effectData.iCol
    local bonusTarSp =  self:getOneColBonusSymbol( iCol )
    bonusTarSp:setVisible(false)
    local iRow = bonusTarSp.p_rowIndex

    local trainBox = self:getReelTrainNodeFromCol(iCol )
    trainBox:setVisible(false)
    local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
    

    self:createActTrainBonus( iCol,iRow,function(  )

        bonusTarSp:setVisible(true)

    end ,function(  )
        
        gLobalSoundManager:playSound("WestSounds/music_West_TrainBonus_Trigeer_JackPot_Major.mp3")

        self:runActTrainBoxAni( TrainBoxAni,function(  )
            trainBox:setVisible(true)

            self:updateSpecialCoins( self.m_TrainWinCoins , beiginCoins , isupdateTop )

            local coins = effectData.hitCoins or 0
            local index = 2
            local currFunc = function(  )

                self:lightAllSymbol(iCol,iRow )
                self:lightAllTrain( iCol,iRow )

                performWithDelay(self,function(  )
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,0.5)
            end
            self:showJackpotWinView(index,coins,currFunc,iCol)

        end )
 

    end )

    
end

-- jackPot Minor
function CodeGameScreenWestMachine:playBonusJpMinorEffect(effectData) 

    local beiginCoins = self.m_TrainWinCoins
    self.m_TrainWinCoins = self.m_TrainWinCoins + effectData.hitCoins
    local isupdateTop = false
    if effectData.last then
        isupdateTop = true
    end

    local iCol = effectData.iCol
    local bonusTarSp =  self:getOneColBonusSymbol( iCol )
    bonusTarSp:setVisible(false)
    local iRow = bonusTarSp.p_rowIndex

    local trainBox = self:getReelTrainNodeFromCol(iCol )
    trainBox:setVisible(false)
    local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
    

    self:createActTrainBonus( iCol,iRow,function(  )

        bonusTarSp:setVisible(true)

    end ,function(  )

        gLobalSoundManager:playSound("WestSounds/music_West_TrainBonus_Trigeer_JackPot_Minor.mp3")

        self:runActTrainBoxAni( TrainBoxAni,function(  )
            trainBox:setVisible(true)

            self:updateSpecialCoins( self.m_TrainWinCoins , beiginCoins , isupdateTop )

            local coins = effectData.hitCoins or 0
            local index = 3
            local currFunc = function(  )

                self:lightAllSymbol(iCol,iRow )
                self:lightAllTrain( iCol,iRow )

                performWithDelay(self,function(  )
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,0.5)
            end
            self:showJackpotWinView(index,coins,currFunc,iCol)

        end )


    end)

   

end


-- jackPot Mini
function CodeGameScreenWestMachine:playBonusJpMiniEffect(effectData) 

    local beiginCoins = self.m_TrainWinCoins
    self.m_TrainWinCoins = self.m_TrainWinCoins + effectData.hitCoins
    local isupdateTop = false
    if effectData.last then
        isupdateTop = true
    end

    

    local iCol = effectData.iCol 
    local bonusTarSp =  self:getOneColBonusSymbol( iCol )
    bonusTarSp:setVisible(false)
    local iRow = bonusTarSp.p_rowIndex

    local trainBox = self:getReelTrainNodeFromCol(iCol )
    trainBox:setVisible(false)
    local TrainBoxAni = self:creatActTrainBoxAni( trainBox)
    

    self:createActTrainBonus( iCol,iRow,function(  )

        bonusTarSp:setVisible(true)

    end ,function(  )

        gLobalSoundManager:playSound("WestSounds/music_West_TrainBonus_Trigeer_JackPot_Mini.mp3")
        self:runActTrainBoxAni( TrainBoxAni,function(  )
            trainBox:setVisible(true)

            self:updateSpecialCoins( self.m_TrainWinCoins , beiginCoins , false )

            local coins = effectData.hitCoins or 0
            local index = 4
            local currFunc = function(  )

                self:lightAllSymbol(iCol,iRow )
                self:lightAllTrain( iCol,iRow )

                performWithDelay(self,function(  )
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,0.5)
            end
        
            self:showJackpotWinView(index,coins,currFunc,iCol)

        end )


    end )

    

end



function CodeGameScreenWestMachine:showJackpotWinView(index,coins,func,col)
    
    local jackPotWinView = util_createView("CodeWestSrc.WestJackPotWinView", self)
    gLobalViewManager:showUI(jackPotWinView)

    jackPotWinView:findChild("root"):setScale(self.m_machineRootScale)

    local curCallFunc = function(  )
        if func then
            func()
        end
    end
    jackPotWinView:initViewData(index,coins,curCallFunc,col)


end

function CodeGameScreenWestMachine:showPKBonusOverView(coins,detailedWin,func)

     gLobalSoundManager:playSound("WestSounds/music_West_BonusGameOverView.mp3")
    
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]= detailedWin
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 30)
    local view = self:showDialog("BonusGameOver",ownerlist,func)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx = 1,sy = 1},643)
    local node1 =view:findChild("m_lb_num")
    view:updateLabelSize({label=node1,sx = 1,sy = 1},572)

    return view
end



----------------
--------------
---------
--特殊玩法更新钱
function CodeGameScreenWestMachine:checkIsHaveLines( )
    
    local winLines = self.m_runSpinResultData.p_winLines or {}
    local isUpdate = false

    for i=1,#winLines do
        local lines = winLines[i]
        if lines.p_iconPos and #lines.p_iconPos > 0 then
            isUpdate = true
            break
        end
    end

    return isUpdate

end

function CodeGameScreenWestMachine:updateSpecialCoins( endCoins , beiginCoins , isNotifyUpdateTop )
    
    self.m_bottomUI.m_changeLabJumpTime = 1 -- 下UI数字滚动一秒

    if self:checkIsHaveLines() then
        isNotifyUpdateTop = false
    end

    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    -- freespin 时
    local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
    local updateCoins = fsWinCoin - self.m_serverWinCoins 
    if updateCoins > 0 then
        beiginCoins = beiginCoins + updateCoins
        endCoins = endCoins + updateCoins
    end

    

    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{endCoins,isNotifyUpdateTop,nil,beiginCoins,nil,true})
    globalData.slotRunData.lastWinCoin = lastWinCoin

    self.m_bottomUI.m_changeLabJumpTime = nil
end


function CodeGameScreenWestMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
     end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local littleGameWinCoins = self:getLittleCoins( )
    if littleGameWinCoins then

        local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
        local beiginCoins = 0
        local endCoins = 0
        if isNotifyUpdateTop then

            beiginCoins = littleGameWinCoins
            endCoins = self.m_serverWinCoins 

        else

            beiginCoins = fsWinCoin - (self.m_serverWinCoins - littleGameWinCoins)
            endCoins = fsWinCoin 
        end
        

        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{endCoins,isNotifyUpdateTop,nil,beiginCoins})
        globalData.slotRunData.lastWinCoin = lastWinCoin
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop}) 
    end



end

function CodeGameScreenWestMachine:getLittleCoins( )
    
    local coins = nil

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local winLinesAmount = selfdata.winLinesAmount or 0

    if self.m_TrainWinCoins > 0 then
        coins = self.m_TrainWinCoins
    elseif winLinesAmount ~= 0 then
        coins = self.m_serverWinCoins - winLinesAmount
    end

    return coins
end

function CodeGameScreenWestMachine:checkIsAddLastWinSomeEffect( )
    
    local notAdd  = false

    if #self.m_vecGetLineInfo == 0 and not self.m_isHaveTrainWinEffect then  -- 火车赢钱 
        notAdd = true
    end

    return notAdd
end

function CodeGameScreenWestMachine:playCustomSpecialSymbolDownAct( slotNode )

    CodeGameScreenWestMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    if slotNode.p_symbolType == self.SYMBOL_TRIGGER_BONUS  then

        local slotNode = self:setSymbolToClipReel(slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_TRIGGER_BONUS)

        slotNode:runAnim("buling",false,function(  )
            slotNode:runAnim("idleframe",true)
        end)

        local soundPath = "WestSounds/WestSounds_TriggerBonusDown.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end


  
        self.m_reelDownAddTime = 21/30
        
    end
end

function CodeGameScreenWestMachine:getOneColBonusSymbol( iCol )
    
    if iCol then
        release_print("iCol   是 --" .. iCol )  
    else
        release_print("iCol   是空的！！！")  
    end
        

    for iRow = 1,self.m_iReelRowNum do
        local tarSp = self:getFixSymbol(iCol, iRow)
        if tarSp then
            if tarSp.p_symbolType then
                release_print("iCol --" .. tarSp.p_cloumnIndex .. "-- row --"..tarSp.p_rowIndex .. "-- tarSp.p_symbolType -- "..tarSp.p_symbolType)  
            end
            
            if tarSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS or tarSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS_WILD then
                return tarSp
            end
        end
    end
end

function CodeGameScreenWestMachine:checkIsInOverBonusList( currIndex)


    for i=1,#self.m_playOverBonusIndex do
        local index = self.m_playOverBonusIndex[i]

        if index ==  currIndex then
            return true
        end
    end
    

    return false
end

-- bonus 喷动画
function CodeGameScreenWestMachine:createActTrainBonus( iCol,iRow,func ,funcTrigger )

    gLobalSoundManager:playSound("WestSounds/music_West_TrainBonus_Trigeer.mp3")

    local index = self:getPosReelIdx(iRow, iCol)
    table.insert(self.m_playOverBonusIndex,index)

    self:deakAllTrain(iCol,iRow )
    self:deakAllSymbol(iCol,iRow )

    local actNode = cc.Node:create()
    self:addChild(actNode)

    performWithDelay(actNode,function(  )
        if funcTrigger then
            funcTrigger()
        end

        actNode:removeFromParent()
    end,30/30)

    local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
    targSp:setVisible(false)
    if targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS_WILD then
        targSp:runAnim("idleframe")
    else
        targSp:runAnim("idleframe1")
    end
    
    local actBonus = util_createAnimation(self:MachineRule_GetSelfCCBName(targSp.p_symbolType).. ".csb")
    self.m_clipParent:addChild(actBonus, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)
    local index = self:getPosReelIdx(iRow, iCol )
    local pos = cc.p(util_getOneGameReelsTarSpPos(self,index))
    actBonus:setPosition(pos)
    local actname = {"actionframe_0","actionframe_1","actionframe_2"}
    actBonus:runCsbAction(actname[4 - iRow],false,function(  )
        targSp:setVisible(true)
        if func then
            func()
        end
        actBonus:removeFromParent()
    end)
    
end--

-- 更新控制类数据
function CodeGameScreenWestMachine:SpinResultParseResultData( spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
    self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
    self.m_TrainWinCoins = 0
end

-- 随机单个wild
function CodeGameScreenWestMachine:CreateRandomWildActNode( actinfo )

    gLobalSoundManager:playSound("WestSounds/music_West_CriminalThrowFly.mp3")

    local data = actinfo

    local nodeParent = cc.Node:create()
    self:findChild("reelNode"):addChild(nodeParent,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER )
    nodeParent:setPosition(cc.p(data.currPos.x,data.currPos.y + 400))

    local BoomNode = util_createAnimation("Socre_West_H3_Wild_zhadanxuanzhuan.csb")
    nodeParent:addChild(BoomNode)
    

    
    local BoomWildNode = util_createAnimation("Socre_West_H3_Wild_baozha.csb")
    nodeParent:addChild(BoomWildNode,1)

    local endPos = cc.p(util_getOneGameReelsTarSpPos(self,data.reelIndex )  )

    local fixpos = self:getRowAndColByPos(data.reelIndex)
    local targSp = self:getFixSymbol(fixpos.iY, fixpos.iX, SYMBOL_NODE_TAG)
    

    local addname = "wild_" .. fixpos.iX
    local targSp = self:getFixSymbol(fixpos.iY, fixpos.iX, SYMBOL_NODE_TAG)

    if targSp then
     
        if targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS or targSp.p_symbolType == self.Socre_West_Scatter_Wild then
            local bonusWild = util_createAnimation("Socre_West_Scatter_Wild.csb") 
            BoomWildNode:findChild("Node_bonusWild"):addChild(bonusWild)
            local currIndex = self:getPosReelIdx(targSp.p_rowIndex, targSp.p_cloumnIndex)
            if not self:checkIsInOverBonusList( currIndex) then
                bonusWild:runCsbAction("idleframe1",true)
            else
                bonusWild:runCsbAction("idleframe")
            end

            BoomWildNode:findChild("Node_Wild"):setVisible(false)
        end

    end
        


    

    -- nodeParent:setVisible(false)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        nodeParent:setVisible(true)

        BoomNode:runCsbAction("actionframe",true)
        
    end)

    actList[#actList + 1] = cc.DelayTime:create(data.moveTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("WestSounds/music_West_CriminalThrow_BoomFlying.mp3")
        
        
    end)
    
    actList[#actList + 1] = cc.JumpTo:create(0.5, cc.p(endPos.x,endPos.y),10, 1)
    actList[#actList + 1] = cc.CallFunc:create(function(  )

        BoomNode:setVisible(false)

        gLobalSoundManager:playSound("WestSounds/music_West_CriminalThrow_BoomFlyEnd.mp3")

        BoomWildNode:runCsbAction("actionframe")
    end)
    actList[#actList + 1] = cc.DelayTime:create(9/30)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        targSp:setVisible(false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(15/30)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        
        
        targSp:setVisible(true)

        if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
            targSp.p_symbolImage:removeFromParent()
        end
        targSp.p_symbolImage = nil
        targSp.m_ccbName = ""
        

        if targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
            targSp:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_TRIGGER_BONUS_WILD),self.SYMBOL_TRIGGER_BONUS_WILD)
            
            local currIndex = self:getPosReelIdx(targSp.p_rowIndex, targSp.p_cloumnIndex)
            if not self:checkIsInOverBonusList( currIndex) then
                targSp:runAnim("idleframe1",true)
            else
                targSp:runAnim("idleframe")
            end
        else
            targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
            targSp:runAnim("idleframe")
        end
        

        local zorder = self:getBounsScatterDataZorder(targSp.p_symbolType)
        targSp.p_showOrder = zorder - targSp.p_rowIndex
        targSp:setLocalZOrder(zorder - targSp.p_rowIndex )


        nodeParent:removeFromParent()

        if data.func then
            data.func()
        end
    end)
    local sq = cc.Sequence:create(actList) 
    nodeParent:runAction(sq)


end

-- 随机整列wild
function CodeGameScreenWestMachine:CreateColWildActNode( actinfo )

    local data = actinfo
    local iCol = actinfo.iCol
    local reelIndex = self:getPosReelIdx(2, iCol)
    local nodeParent = cc.Node:create()
    self:findChild("reelNode"):addChild(nodeParent,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER )
   
    local BoomNode = util_createAnimation("Socre_West_H2_Wild_baozha.csb")
    nodeParent:addChild(BoomNode)

    for iRow = 1,self.m_iReelRowNum do
        local addname = "wild_" .. iRow
        local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

        if targSp then
            local wildAni = util_createAnimation("Socre_West_H3_Wild_baozha_1.csb")
            BoomNode:findChild(addname):addChild(wildAni)
            wildAni:runCsbAction("actionframe")
            if targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS or targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS_WILD then
                local bonusWild = util_createAnimation("Socre_West_Scatter_Wild.csb") 
                wildAni:findChild("Node_bonusWild"):addChild(bonusWild)
                local currIndex = self:getPosReelIdx(targSp.p_rowIndex, targSp.p_cloumnIndex)
                if not self:checkIsInOverBonusList( currIndex) then
                    bonusWild:runCsbAction("idleframe1",true)
                else
                    bonusWild:runCsbAction("idleframe")
                end
                wildAni:findChild("Node_Wild"):setVisible(false)
            end

            
        end
        
    end
    
    local endPos = cc.p(util_getOneGameReelsTarSpPos(self,reelIndex )  )
    nodeParent:setPosition(cc.p(endPos))

    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        
        BoomNode:runCsbAction("actionframe")
    end)
    actList[#actList + 1] = cc.DelayTime:create(6/30)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        
       for iRow = 1,self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)

            if targSp then
                if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                    targSp.p_symbolImage:removeFromParent()
                end
                targSp.p_symbolImage = nil
                targSp.m_ccbName = ""
                
                if targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_TRIGGER_BONUS_WILD),self.SYMBOL_TRIGGER_BONUS_WILD)
                    local currIndex = self:getPosReelIdx(targSp.p_rowIndex, targSp.p_cloumnIndex)
                    if not self:checkIsInOverBonusList( currIndex) then
                        targSp:runAnim("idleframe1",true)
                    else
                        targSp:runAnim("idleframe")
                    end
                    
                    
                else
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                    targSp:runAnim("idleframe")
                end
               

                local zorder = self:getBounsScatterDataZorder(targSp.p_symbolType)
                targSp.p_showOrder = zorder - targSp.p_rowIndex
                targSp:setLocalZOrder(zorder - targSp.p_rowIndex )
            end
            
       end
       
    end)
    actList[#actList + 1] = cc.DelayTime:create(18/30)
    actList[#actList + 1] = cc.CallFunc:create(function(  )

         nodeParent:removeFromParent()
 
         if data.func then
             data.func()
         end
     end)
    local sq = cc.Sequence:create(actList) 
    nodeParent:runAction(sq)


end

function CodeGameScreenWestMachine:playEffectNotifyNextSpinCall( )


    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
    self:getCurrSpinMode() == FREE_SPIN_MODE then

        if not self.m_WestPKBonusGameMain then --玩bonus在freespin中不自动spin
            local delayTime = 0.5
            if self.m_reelResultLines ~= nil and #self.m_reelResultLines > 0 then
                delayTime = math.max(self.m_autoSpinDelayTime, self.m_changeLineFrameTime)
            end

            self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end, delayTime,self:getModuleName())
        end
        

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end

--
--设置bonus scatter 层级
function CodeGameScreenWestMachine:getBounsScatterDataZorder(symbolType )

    local order = BaseNewReelMachine.getBounsScatterDataZorder(self,symbolType )

    if  symbolType ==  self.SYMBOL_TRIGGER_BONUS or symbolType ==  self.SYMBOL_TRIGGER_BONUS_WILD  then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    end
    
    return order

end

function CodeGameScreenWestMachine:showGuoChang( func,funcEnd )


    gLobalSoundManager:playSound("WestSounds/music_West_Guochang.mp3")

    local actNode = cc.Node:create()
    self:addChild(actNode)
    self.m_GuoChang:setVisible(true)
    
    self.m_GuoChang:runCsbAction("actionframe",false)

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(15/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()

        if func then
            func()
        end


    end)
    actionList[#actionList + 1] = cc.DelayTime:create(15/30)
    actionList[#actionList + 1] = cc.CallFunc:create(function ()
        self.m_GuoChang:setVisible(false)
        if funcEnd then
            funcEnd()
        end

        actNode:removeFromParent()
    end)

    local seq = cc.Sequence:create(actionList)
    actNode:runAction(seq)

end

function CodeGameScreenWestMachine:getNextReelSymbolType( )
    
    return self.m_runSpinResultData.p_prevReel

end

function CodeGameScreenWestMachine:updateBonusWinCoins( beiginCoins, endCoins , jumpTime,func )
    

    self.m_bottomUI.m_changeLabJumpTime = jumpTime

    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{endCoins,false,nil,beiginCoins,nil,true})
    globalData.slotRunData.lastWinCoin = lastWinCoin

    self.m_bottomUI.m_changeLabJumpTime = nil

    local node = cc.Node:create()
    self:addChild(node)
    performWithDelay(node,function(  )
        
        if func then
            func()
        end

        node:removeFromParent()
    end,jumpTime)

    
end

-- 创建飞行骷髅 ☠️
function CodeGameScreenWestMachine:createBonusPkSkeletonFly( startPos,endPos ,time,func )

    gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_SkeletonFly.mp3")

    local SkeletonFly = util_createAnimation("West_bonusgame_kuloushouji.csb")
    SkeletonFly:setPosition(startPos)
    self:addChild(SkeletonFly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    SkeletonFly:setScale(self.m_machineRootScale)

    local SkeletonFlyFanKui = util_createAnimation("West_bonusgame_kuloushoujiFK.csb")
    self:addChild(SkeletonFlyFanKui,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    SkeletonFlyFanKui:setPosition(cc.p(endPos))
    SkeletonFlyFanKui:setScale(self.m_machineRootScale)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        -- SkeletonFly:runCsbAction("actionframe")

    end) 
    local bez = cc.BezierTo:create(time, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
    animation[#animation + 1] = bez --cc.MoveTo:create(time, cc.p(endPos))
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeartFlyEnd.mp3")

        SkeletonFlyFanKui:runCsbAction("actionframe_shouji",false,function(  )

            SkeletonFlyFanKui:removeFromParent()
            
            if func then
                func()
            end
        end)

        

        SkeletonFly:removeFromParent() 

    end)

    SkeletonFly:runAction(cc.Sequence:create(animation))



end

-- 创建飞行手枪 🔫
function CodeGameScreenWestMachine:createBonusPkPistolFly( startPos,endPos ,time,func )

    gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_PistolFly.mp3")

    local PistolFly = util_createAnimation("West_bonusgame_qiangshouji.csb")
    PistolFly:setPosition(startPos)
    self:addChild(PistolFly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    PistolFly:setScale(self.m_machineRootScale)

    local PistolFlyFanKui = util_createAnimation("West_bonusgame_qiangshoujiFK.csb")
    self:addChild(PistolFlyFanKui,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    PistolFlyFanKui:setPosition(cc.p(endPos))
    PistolFlyFanKui:setScale(self.m_machineRootScale)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        -- PistolFly:runCsbAction("actionframe")

    end) 
    local bez = cc.BezierTo:create(time, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
    animation[#animation + 1] = bez --cc.MoveTo:create(time, cc.p(endPos))
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeartFlyEnd.mp3")

        PistolFlyFanKui:runCsbAction("actionframe_shouji",false,function(  )

            PistolFlyFanKui:removeFromParent()
            if func then
                func()
            end
        end)

        

        PistolFly:removeFromParent() 

    end)

    PistolFly:runAction(cc.Sequence:create(animation))



end


-- 创建飞行心 ❤
function CodeGameScreenWestMachine:createBonusPkHeartFly( startPos,endPos ,time,func )

    gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeartFly.mp3")

    local heartFly = util_createAnimation("West_bonusgame_xinshouji.csb")
    heartFly:setPosition(startPos)
    self:addChild(heartFly,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    heartFly:setScale(self.m_machineRootScale)

    local heartFlyFanKui = util_createAnimation("West_bonusgame_xinshoujiFK.csb")
    self:addChild(heartFlyFanKui,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    heartFlyFanKui:setPosition(cc.p(endPos))
    heartFlyFanKui:setScale(self.m_machineRootScale)

    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        -- heartFly:runCsbAction("actionframe")

    end) 
    local bez = cc.BezierTo:create(time, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
    animation[#animation + 1] = bez --cc.MoveTo:create(time, cc.p(endPos))
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeartFlyEnd.mp3")

        heartFlyFanKui:runCsbAction("actionframe_shouji",false,function(  )

            heartFlyFanKui:removeFromParent()

        end)

        if func then
            func()
        end

        heartFly:removeFromParent() 

    end)

    heartFly:runAction(cc.Sequence:create(animation))



end

-- 创建飞行粒子
function CodeGameScreenWestMachine:createBonusPkCoinsFly( startPos ,time,func )

    gLobalSoundManager:playSound("WestSounds/music_West_updateWinCoins.mp3")
    
    
    local Particle = util_createAnimation("Socre_West_shouji.csb")
    Particle:setPosition(startPos)
    self:addChild(Particle,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    Particle:setScale(self.m_machineRootScale)
    Particle:findChild("Particle_1"):setDuration(time)
    Particle:findChild("Particle_1"):setPositionType(0)

    local endPos = cc.p(0,0)
    local win_txt = self.m_bottomUI:findChild("win_txt")
    if win_txt then
        local addPosY = 0
        local win_txtPos = cc.p(win_txt:getPosition())
        local worldPos = win_txt:getParent():convertToWorldSpace(cc.p(win_txtPos.x,win_txtPos.y + addPosY ))
        endPos = self:convertToNodeSpace(worldPos)
    end

    local ParticleFanKui = util_createAnimation("Socre_West_shoujifankui.csb")
    ParticleFanKui:setPosition(cc.p(0,80))
    win_txt:getParent():addChild(ParticleFanKui,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    ParticleFanKui:setVisible(false)

    local animation = {}
    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos))
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_HeartFlyEnd.mp3")
        self:playCoinWinEffectUI()

        ParticleFanKui:runCsbAction("actionframe",false,function(  )
            ParticleFanKui:removeFromParent()
        end)

            if func then
                func()
            end

            

    end)
    animation[#animation + 1] = cc.DelayTime:create( 2)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        Particle:removeFromParent()
    end)

    Particle:runAction(cc.Sequence:create(animation))


    return Particle,ParticleFanKui
end

---
--根据关卡玩法重新设置滚动信息
function CodeGameScreenWestMachine:MachineRule_ResetReelRunData()

    local endCol = self:getScatterEndCol( )

    if endCol > 0 then

        for iCol = 1, self.m_iReelColumnNum do
            local reelRunInfo = self.m_reelRunInfo
            local reelRunData = self.m_reelRunInfo[iCol]
            local columnData = self.m_reelColDatas[iCol]

            if self:getCurrSpinMode() == FREE_SPIN_MODE then 
                -- free game中，5列全播
                local iRow = columnData.p_showGridCount
                local reelLongRunTime = 1
                local lastColLens = reelRunInfo[1]:getReelRunLen()
                if iCol ~= 1 then
                    reelLongRunTime = 1
                    lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                end
                local colHeight = columnData.p_slotColumnHeight
                local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
    
                local preRunLen = reelRunData:getReelRunLen()
                reelRunData:setReelRunLen(runLen)
    
                self.m_reelRunInfo[iCol]:setNextReelLongRun(true)
                self.m_reelRunInfo[iCol]:setNextReelLongRun(true)
                self.m_reelRunInfo[iCol]:setReelLongRun(true)
            else
                
    
                local reelLongRunTime = 1

                if iCol <= endCol then
        
                    local iRow = columnData.p_showGridCount
        
                    local lastColLens = reelRunInfo[1]:getReelRunLen()
                    if iCol ~= 1 then
                        lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
                        reelRunInfo[iCol - 1 ]:setNextReelLongRun(true)
                        reelLongRunTime = 1
                    end

                    local colHeight = columnData.p_slotColumnHeight
                    local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
                    local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高
        
                    local preRunLen = reelRunData:getReelRunLen()
                    reelRunData:setReelRunLen(runLen)

                    if endCol ~= iCol then
                        reelRunData:setReelLongRun(true)
                        reelRunData:setNextReelLongRun(true)
                    end
    
                else
                    
                    local lastColLens = reelRunInfo[endCol]:getReelRunLen()     
                    local preRunLen = reelRunInfo[iCol].initInfo.reelRunLen
                    local preEndColRunLen = reelRunInfo[endCol].initInfo.reelRunLen
                    local addRunLen =  preRunLen -  preEndColRunLen
    
                    reelRunData:setReelRunLen(lastColLens + addRunLen)
                    reelRunData:setReelLongRun(false)
                    reelRunData:setNextReelLongRun(false)
    
                end
                
    
    
            end
          
        end

    end
    
end

function CodeGameScreenWestMachine:getScatterEndCol( )
    local endCol = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1 ,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
            if symbolType == self.SYMBOL_TRIGGER_BONUS then

                endCol = iCol
                
            end
        end
    end
    return endCol
end

---
-- 接到消息后 处理第一列为快滚
function CodeGameScreenWestMachine:setColOneLongRunStates(  )

    local endCol = self:getScatterEndCol( )
    
    if endCol > 0 then

        

        for i =  1 , self.m_iReelColumnNum do
            --添加金边
            if i == 1 then
                if self.m_reelRunInfo[1]:getReelLongRun() then
                    self:creatReelRunAnimation(1)
                end
            end
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent
    
            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    
        -- 出发了长滚动则不允许点击快停按钮
    
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
    
    

end

function CodeGameScreenWestMachine:updateReelGridNode(node)
    if node and node.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
        
            node:runAnim("idleframe",true)
        
    end
end

function CodeGameScreenWestMachine:shakeRootNode( func )

    if math.random(1,2) == 1 then -- 百分之50 不抖屏

        if func then
            func()
        end

        return 
    end


    gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_shak.mp3")

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    for i=1,10 do
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
        actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    end
    actionList2[#actionList2+1]=cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(seq2)

end

function CodeGameScreenWestMachine:deakAllSymbol(_iCol,_iRow )
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1 ,self.m_iReelRowNum do

            if iCol == _iCol and iRow == _iRow then
                print("正在播放的位置不处理")
            else
                local tarSp = self:getFixSymbol(iCol, iRow)
            
                if tarSp then
                    local actName = "dark"
                    local currIndex = self:getPosReelIdx(_iRow, _iCol)
                    if not self:checkIsInOverBonusList( currIndex) then
                        if tarSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS_WILD or tarSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
                            actName = "dark1"   
                        end
                        
                    end

                    tarSp:runAnim(actName)
                end
            end

            
        end

        local ResNode = self:getFixSymbol(iCol, 4)  
        if ResNode then
            ResNode:runAnim("dark")
        end
    end

    

end

function CodeGameScreenWestMachine:lightAllSymbol(_iCol,_iRow )
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1 ,self.m_iReelRowNum do

            if iCol == _iCol and iRow == _iRow then
                print("正在播放的位置不处理")
            else
                local tarSp = self:getFixSymbol(iCol, iRow)
                if tarSp then

                    local actName = "darkover"
                    local currIndex = self:getPosReelIdx(_iRow, _iCol)
                    if not self:checkIsInOverBonusList( currIndex) then
                        if tarSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS_WILD or tarSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
                            actName = "darkover1"   
                        end
                        
                    end

                    tarSp:runAnim(actName)
                end
            end

            
        end

        local ResNode = self:getFixSymbol(iCol, 4)  
        if ResNode then
            ResNode:runAnim("darkover")
        end
    end

end

function CodeGameScreenWestMachine:deakAllTrain( _iCol,_iRow )
    
    for i=1,#self.m_TraiNodeList do
        local TrainBox = self.m_TraiNodeList[i]

        local index = TrainBox.index
        local  m_index = reelDataIndex[_iCol]
        if index == m_index then
            print("正在播放的位置不处理")
        else
            
            if TrainBox then
                TrainBox:runCsbAction("dark")
            end
    
            if TrainBox.TrainBoxWheel then
                TrainBox.TrainBoxWheel:runCsbAction("dark")
            end
    
            if TrainBox.hero then
                util_spinePlay(TrainBox.hero,"dark")
            end
    
            if TrainBox.heroBg then
                TrainBox.heroBg:runCsbAction("dark")
            end
        end

        

    end


end

function CodeGameScreenWestMachine:lightAllTrain( _iCol,_iRow )
    

    for i=1,#self.m_TraiNodeList do
        local TrainBox = self.m_TraiNodeList[i]

        local index = TrainBox.index
        local  m_index = reelDataIndex[_iCol]
        if index ~= m_index then

            if TrainBox then
                TrainBox:runCsbAction("darkover",false,function(  )

                    self:TrainBoxRunIdleAnim( TrainBox )

                end)
            end
    
            if TrainBox.TrainBoxWheel then
                TrainBox.TrainBoxWheel:runCsbAction("darkover")
            end
    
            if TrainBox.hero then
                util_spinePlay(TrainBox.hero,"darkover")
            end
    
            if TrainBox.heroBg then
                TrainBox.heroBg:runCsbAction("darkover",false,function(  )
                    self:TrainBoxRunIdleAnim( TrainBox )
                end)
            end

        end
       

    end

end

function CodeGameScreenWestMachine:creatActTrainBoxAni( currNode )
    

    local index = currNode.index
    
    local list = self.m_TopLittlReelData or {1,1,1,3,4,5,6,2,1,1,1,1}

    local TrainData = list[index]
    local TrainBox = self:createOneTrainBox( TrainData,index,self.m_clipParent )
    TrainBox:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 2)

    local currNodeWorldPos = currNode:getParent():convertToWorldSpace(cc.p(currNode:getPosition()))
    local TrainBoxPos = cc.p(TrainBox:getParent():convertToNodeSpace(cc.p(currNodeWorldPos)))

    TrainBox:setPosition(TrainBoxPos)
    
    
    return TrainBox
    

end

function CodeGameScreenWestMachine:runActTrainBoxAni(TrainBox,func,funcEnd )

    if TrainBox.hero then
        TrainBox:runCsbAction("actionframe",false,function(  )

            TrainBox:removeFromParent()

            if funcEnd then
                funcEnd()
            end

            
        end)
        TrainBox.heroBg:runCsbAction("idle",true)
        util_spinePlay(TrainBox.hero,"actionframe") 
        util_spineEndCallFunc(TrainBox.hero,"actionframe",function(  )

            
        end)
        performWithDelay(self,function(  )

            if func then
                func()
            end
        
        end,2)

    else
        TrainBox:runCsbAction("actionframe",false,function(  )

            if func then
                func()
            end

            TrainBox:removeFromParent()
        end)
    end
    
end

function CodeGameScreenWestMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local index = self:getPosReelIdx(_iRow, _iCol)
        local pos = util_getOneGameReelsTarSpPos(self,index )
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end


function CodeGameScreenWestMachine:randomSlotNodesByReel( )
    BaseNewReelMachine.initRandomSlotNodes(self)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1 ,self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
                if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                    targSp.p_symbolImage:removeFromParent()
                end
                targSp.p_symbolImage = nil
                targSp.m_ccbName = ""
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1),TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
            end
        end

        local ResNode = self:getFixSymbol(iCol, 4)  
        if ResNode then
            if ResNode.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
                ResNode:runAnim("idleframe1")
            end
            
        end

    end
end

function CodeGameScreenWestMachine:initRandomSlotNodes()
    
    BaseNewReelMachine.initRandomSlotNodes(self)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1 ,self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS then

                if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                    targSp.p_symbolImage:removeFromParent()
                end
                targSp.p_symbolImage = nil
                targSp.m_ccbName = ""
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_SCORE_1),TAG_SYMBOL_TYPE.SYMBOL_SCORE_1)
            end
        end

        local ResNode = self:getFixSymbol(iCol, 4)  
        if ResNode then
            if ResNode.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
                ResNode:runAnim("idleframe1")
            end
            
        end

    end

    
end

function CodeGameScreenWestMachine:initCloumnSlotNodesByNetData()
    
    BaseNewReelMachine.initCloumnSlotNodesByNetData(self)

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1 ,self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
                local triggerBonus = self:setSymbolToClipReel(iCol, iRow, self.SYMBOL_TRIGGER_BONUS)
                triggerBonus:runAnim("idleframe1")
            end
        end

        local ResNode = self:getFixSymbol(iCol, 4)  
        if ResNode then
            if ResNode.p_symbolType == self.SYMBOL_TRIGGER_BONUS then
                ResNode:runAnim("idleframe1")
            end
            
        end

    end

    
end



function CodeGameScreenWestMachine:triggerLongRunChangeBtnStates( )

end

function CodeGameScreenWestMachine:slotReelDown()

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    BaseNewReelMachine.slotReelDown(self)
    
end


function CodeGameScreenWestMachine:getClipParentChildShowOrder(slotNode )
    
    if slotNode.p_symbolType == self.SYMBOL_TRIGGER_BONUS_WILD then
       
        local zorder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD)
        return zorder - slotNode.p_rowIndex
    else
        return slotNode.p_showOrder
    end

end

---
--得到参与连线的固定小块
function CodeGameScreenWestMachine:getSpecialReelNode(matrixPos)

    local slotLineNode = self:getFixSymbol(matrixPos.iY, matrixPos.iX, SYMBOL_NODE_TAG)
    if slotLineNode then
        return slotLineNode
    end


    BaseNewReelMachine.getSpecialReelNode(self,matrixPos)

end

function CodeGameScreenWestMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        
        self:findChild("reelNode"):addChild(reelEffectNode, 1 )
        reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end

end

function CodeGameScreenWestMachine:bonusOverAddLinesEffect( )
    
    

    local isFiveOfKind = self:lineLogicWinLines()
    if isFiveOfKind then
        self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    end

    -- 组织播放连线信息
    self:insterReelResultLines( )

    --添加连线动画
    self:addLineEffect()

    self:sortGameEffects( )
end

function CodeGameScreenWestMachine:CreateBonusMusicBgSoundGlobal( )

        self:removeBonusSoundGlobal( )

        local volume = gLobalSoundManager:getBackgroundMusicVolume() or 0
        self.m_BonusSoundGlobalId =
            scheduler.scheduleGlobal(
            function()
                --播放广告过程中暂停逻辑
                if gLobalAdsControl ~= nil and gLobalAdsControl.getPlayAdFlag ~= nil and gLobalAdsControl:getPlayAdFlag() then
                   
                    return
                end

                if volume <= 0 then
                    volume = 0
                end

                gLobalSoundManager:setBackgroundMusicVolume(volume)
                if volume <= 0 and self.removeBonusSoundGlobal then
                    self:removeBonusSoundGlobal( )
                end

                volume = volume - 0.04
            end,
            0.1
        )


end

function CodeGameScreenWestMachine:removeBonusSoundGlobal( )

    if self.m_BonusSoundGlobalId ~= nil then
        scheduler.unscheduleGlobal(self.m_BonusSoundGlobalId)
        self.m_BonusSoundGlobalId = nil
    end
end


function CodeGameScreenWestMachine:getDefultTopReelData( )
    
    local typeList = {  [1] =    {8,12,0,11,10,4,13,7,14,5,11,9},			
                        [2] =	{10,13,5,11,7,0,14,9,12,4,11,8},			
                        [3] =	{8,12,4,11,9,5,13,10,14,0,11,7},			
                        [4] =	{10,11,4,12,8,0,14,9,13,5,11,7},			
                        [5] =	{8,11,5,14,7,4,12,10,11,0,13,9},			
                        [6] =	{9,13,0,11,7,5,12,8,11,4,14,10},			
                        [7] =	{7,11,0,14,9,4,13,10,11,6,12,8},			
                        [8] =	{9,14,6,11,10,0,12,7,11,4,13,8},			
                        [9] =	{9,13,4,14,8,6,11,7,12,0,11,10},			
                        [10] =	{10,12,4,14,9,0,11,8,13,6,11,7},			
                        [11] =	{9,14,6,12,10,4,11,8,13,0,11,7},			
                        [12] =	{7,11,0,13,8,6,12,10,14,4,11,9},			
                        [13] =	{9,11,0,13,8,2,11,10,14,6,12,7},			
                        [14] =	{10,13,6,12,7,0,11,8,14,2,11,9},			
                        [15] =	{8,12,2,14,10,6,11,9,13,0,11,7},			
                        [16] =	{7,14,2,11,9,0,13,8,12,6,11,10},			
                        [17] =	{10,14,6,13,9,2,11,7,12,0,11,8},			
                        [18] =	{7,12,0,13,8,6,11,9,14,2,11,10},			
                        [19] =	{8,14,2,12,7,5,11,9,13,6,11,10},			
                        [20] =	{7,11,6,12,10,2,11,9,13,5,14,8},			
                        [21] =	{8,14,5,13,9,6,11,7,12,2,11,10},			
                        [22] =	{7,13,5,14,10,2,11,8,12,6,11,9},			
                        [23] =	{9,13,6,12,7,5,11,10,14,2,11,8},			
                        [24] =	{10,12,2,11,8,6,14,7,13,5,11,9},			
                        [25] =	{7,14,0,12,8,3,11,9,13,6,11,10},			
                        [26] =	{8,11,6,12,7,0,11,9,13,3,14,10},			
                        [27] =	{7,14,3,13,10,6,11,9,12,0,11,8},			
                        [28] =	{8,13,3,14,9,0,11,7,12,6,11,10},			
                        [29] =	{7,13,6,12,10,3,11,8,14,0,11,9} }			


    local typedata = {  [1]  = {signal  ="COINS_1",      type = 4,value = 1},
                        [2]  = {signal  = "COINS_2",     type = 4,value = 2},
                        [3]  = {signal  = "COINS_5",     type = 4,value = 5},
                        [4]  = {signal  = "COINS_6",     type = 4,value = 6}, 
                        [5]  = {signal  = "COINS_10",    type = 4,value = 10}, 
                        [6]  = {signal  = "COINS_15",    type = 4,value = 15},
                        [7]  = {signal  = "COINS_25",    type = 4,value = 25},
                        [8]  = {signal  = "Mini_8",      type = 9,value = 8},
                        [9]  = {signal  = "Minor_20",    type = 8,value = 20},
                        [10] = {signal  = "Major_200",   type = 7,value = 200},
                        [11] = {signal = "Grand_2000",   type = 6,value = 2000}, 
                        [12] = {signal = "FREE",         type = 5,value = 0},
                        [13] = {signal = "EXTRA",        type = 2,value = 0}, 
                        [14] = {signal = "COLUMN",       type = 3,value = 0}, 
                        [15] = {signal  = "BONUS",       type = 1,value = 0}  }

    local runData = {}

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local index = totalBet % 29 
    local list = typeList[index + 1]
    for k=1,#list do
        local dataType = list[k] + 1
        local data = typedata[dataType]
        table.insert( runData, data)
    end
     
    

    return runData 
end

return CodeGameScreenWestMachine






