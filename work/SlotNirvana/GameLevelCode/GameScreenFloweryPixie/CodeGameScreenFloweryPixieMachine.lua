---
-- island li
-- 2019年1月26日
-- CodeGameScreenFloweryPixieMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local FloweryPixieSlotFastNode = require "CodeFloweryPixieSrc.FloweryPixieSlotFastNode"

local CodeGameScreenFloweryPixieMachine = class("CodeGameScreenFloweryPixieMachine", BaseFastMachine)

CodeGameScreenFloweryPixieMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenFloweryPixieMachine.BONUS_FS_WILD_LOCK_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 12 -- 自定义动画的标识

CodeGameScreenFloweryPixieMachine.SYMBOL_SCATTER_GLOD = 97  -- 金色Scatter
CodeGameScreenFloweryPixieMachine.SYMBOL_MYSTER_ONE = 105  
CodeGameScreenFloweryPixieMachine.SYMBOL_MYSTER_TWO = 106  
CodeGameScreenFloweryPixieMachine.SYMBOL_SCORE_10 = 9 
CodeGameScreenFloweryPixieMachine.SYMBOL_SCATTER_WILD = 98  -- Scatter变成的wild

-- CodeGameScreenFloweryPixieMachine.m_betLevel = nil -- betlevel 0 1 2 3

CodeGameScreenFloweryPixieMachine.m_ReelDownMaxCount = 2

CodeGameScreenFloweryPixieMachine.m_FSLittleReelsDownIndex = 0 -- FS停止计数
CodeGameScreenFloweryPixieMachine.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数

CodeGameScreenFloweryPixieMachine.m_miniFsReelTop = nil -- freespin 小轮子
CodeGameScreenFloweryPixieMachine.m_miniFsReelDown = nil -- freespin 小轮子

function CodeGameScreenFloweryPixieMachine:getBaseReelGridNode()
    return "CodeFloweryPixieSrc.FloweryPixieSlotFastNode"
end
-- 构造函数
function CodeGameScreenFloweryPixieMachine:ctor()
    BaseFastMachine.ctor(self)

    -- 替换假滚时 FloweryPixieConfig 是base的
    -- 替换假滚时 FloweryPixieMiniConfig 是Freespin的
    self.SYMBOL_MYSTER_ONE_GEAR = {5,15,5,15,5,15,5,15,5,10,5}  -- 假滚 mystery1 权重
    self.SYMBOL_MYSTER_TWO_GEAR = {5,5,15,5,15,5,15,5,10,5,15}	  -- 假滚 mystery2 权重
    self.SYMBOL_MYSTER_NAME =   { 92,0,1,2,3,4,5,6,7,8,9}
    self.m_bProduceSlots_RunSymbol_1 = self.SYMBOL_MYSTER_NAME[math.random( 1, #self.SYMBOL_MYSTER_NAME)]
    self.m_bProduceSlots_RunSymbol_2 = self.SYMBOL_MYSTER_NAME[math.random( 1, #self.SYMBOL_MYSTER_NAME)]

    self.m_FSLittleReelsDownIndex = 0 -- FS停止计数
    self.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数

    self.m_ReelDownMaxCount = 2
    self.m_rewordTotalCoins = 0
    self.m_rewordTotalTimes = 0
    self.m_rewordCurrTimes = 0
    self.m_isFeatureOverBigWinInFree = true

    -- self.m_betLevel = nil -- 0,1,2,3

	--init
	self:initGame()
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenFloweryPixieMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "FloweryPixieSounds/FloweryPixie_scatter_down1.mp3"
        elseif i == 2 then
            soundPath = "FloweryPixieSounds/FloweryPixie_scatter_down2.mp3"
        else
            soundPath = "FloweryPixieSounds/FloweryPixie_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenFloweryPixieMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("FloweryPixieConfig.csv", "LevelFloweryPixieConfig.lua")

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取关卡名字getModuleName

-- 这个字段和csv中的level_idx对应
function CodeGameScreenFloweryPixieMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FloweryPixie"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenFloweryPixieMachine:getNetWorkModuleName()
    return "FloweryPixieV2"  
end


function CodeGameScreenFloweryPixieMachine:initNodeZOrder( )
    
    local nodeList = {"gameBg","huaxianzi","BaseReel","FsReel","Button_1"}

    for i=1,#nodeList do
        local node = self:findChild(nodeList[i])
        if node then
            node:setLocalZOrder(i)
        end
    end

end

function CodeGameScreenFloweryPixieMachine:getBottomUINode( )
    return "CodeFloweryPixieSrc.FloweryPixieGameBottomNode"
end


function CodeGameScreenFloweryPixieMachine:initUI()


    self:createLocalAnimation( )

    self:addClick(self:findChild("Button_1"))
    self.m_Bonus1ActNode = cc.Node:create()
    self:findChild("BaseReel"):addChild(self.m_Bonus1ActNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self:runCsbAction("BaseReel")
    self.m_reelRunSound = "FloweryPixieSounds/music_FloweryPixie_LongRun.mp3"

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_FlowerGirl =  util_spineCreate("FloweryPixie_Girl",true,true)
    self:findChild("huaxianzi"):addChild(self.m_FlowerGirl)
    util_spinePlay(self.m_FlowerGirl,"idleframe",true)


    self.m_freespinSpinbar = util_createView("CodeFloweryPixieSrc.FloweryPixieFreespinBarView")
    self:findChild("title"):addChild(self.m_freespinSpinbar)
    self.m_freespinSpinbar:setVisible(false)
    self.m_baseFreeSpinBar = self.m_freespinSpinbar
   
    self.m_miniFsReelTop = self:createrOneReel( 2,"fs_2" )
    self.m_miniFsReelDown = self:createrOneReel( 1,"fs_1" )
    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniFsReelTop.m_touchSpinLayer)
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniFsReelDown.m_touchSpinLayer)
    end

    self:findChild("FsReel"):setVisible(false)


    self:findChild("Particle_1"):setVisible(false) 
    self:findChild("Particle_1"):stopSystem()

    self.m_nodeLogo = util_spineCreate("FloweryPixie_bt", true, true)
    self:findChild("hua"):addChild(self.m_nodeLogo)
    util_spinePlay(self.m_nodeLogo, "idleframe", true)
    
    self:initNodeZOrder( )

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        local isAnim = params[5]
        if isAnim then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        local soundTime = 2
        if winRate <= 1 then
            soundIndex = 1
            soundTime = 3
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
            soundTime = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
            soundTime = 3
        elseif winRate > 6 then
            soundIndex = 3
            soundTime = 3
        end


        local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            print("freespin最后一次 无论是否大赢都播放赢钱音效")
        else
            if winRate >= self.m_HugeWinLimitRate then
                return
            elseif winRate >= self.m_MegaWinLimitRate then
                return
            elseif winRate >= self.m_BigWinLimitRate then
                return
            end
        end
        local soundName = "FloweryPixieSounds/music_FloweryPixie_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function CodeGameScreenFloweryPixieMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if not self.isInBonus then
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
            end
            
        end,2.5,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenFloweryPixieMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self:upateBetLevel()



end

function CodeGameScreenFloweryPixieMachine:addObservers()
    BaseFastMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
   end,ViewEventType.NOTIFY_BET_CHANGE)

end

function CodeGameScreenFloweryPixieMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end
--
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenFloweryPixieMachine:MachineRule_GetSelfCCBName(symbolType)

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER  then

        return "Socre_FloweryPixie_scatter"

    elseif symbolType == self.SYMBOL_SCATTER_GLOD  then

        return "Socre_FloweryPixie_scatter"

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then

        return "Socre_FloweryPixie_wild"

    elseif symbolType == self.SYMBOL_SCATTER_WILD  then

        return "Socre_FloweryPixie_wild"    

    elseif symbolType == self.SYMBOL_MYSTER_ONE  then

        return "Socre_FloweryPixie_1"

    elseif symbolType == self.SYMBOL_MYSTER_TWO  then

        return "Socre_FloweryPixie_2"

    elseif symbolType == self.SYMBOL_SCORE_10 then

        return "Socre_FloweryPixie_10"

    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenFloweryPixieMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_GLOD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MYSTER_ONE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_MYSTER_TWO,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCATTER_WILD,count =  2}
    
    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenFloweryPixieMachine:MachineRule_initGame(  )

    self:changeFreeReelVisible( )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        self:runCsbAction("FsReel")

        self.m_gameBg:runCsbAction("idle2") -- FS 

        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local lockPosList = selfData.lockWild or {}

        if self.m_miniFsReelTop then
            self.m_miniFsReelTop:initFsLockWild(lockPosList)
        end
        if self.m_miniFsReelDown then
            self.m_miniFsReelDown:initFsLockWild(lockPosList)
        end
    end
    
end

--
--单列滚动停止回调
--
function CodeGameScreenFloweryPixieMachine:slotOneReelDown(reelCol)    
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage( ) ~= QUICK_RUN or self.m_hasBigSymbol == true ) then
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
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:setVisible(false)
            -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
            --     self:reductionReel(reelCol)
            -- end
        end
    end

    if  reelCol > self:getMaxContinuityBonusCol() then
        if self.m_reelRunSoundTag ~= -1 then
            --停止长滚音效
            -- printInfo("xcyy : m_reelRunSoundTag2 %d",self.m_reelRunSoundTag)
            gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
            self.m_reelRunSoundTag = -1
        end
    end
    
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end

end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenFloweryPixieMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenFloweryPixieMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


function CodeGameScreenFloweryPixieMachine:showFreeSpinMoveView(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    return self:showDialog("MoreFreeSpin",ownerlist,func,BaseDialog.AUTO_TYPE_NOMAL)
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
    
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenFloweryPixieMachine:showFreeSpinView(effectData)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then

                self:LockWildTurnAct( function(  )
                    gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_FreespinStart_view.mp3")
                    self:showFreeSpinMoveView(self.m_runSpinResultData.p_freeSpinNewCount,function()  
                        
                        self.m_freespinSpinbar:updateFreespinCount( self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinsLeftCount,self.m_runSpinResultData.p_freeSpinsTotalCount )
                        
                        self:resetMusicBg()

                        self.m_miniFsReelDown:restSelfGameEffects( self.BONUS_FS_WILD_LOCK_EFFECT  )
                        self.m_miniFsReelTop:restSelfGameEffects( self.BONUS_FS_WILD_LOCK_EFFECT  )

                        effectData.p_isPlay = true
                        self:playGameEffect()

                         -- 更新钱
                        local winLines = {}
                        local reelsList = {self.m_miniFsReelTop,self.m_miniFsReelDown}
                        for i=1,#reelsList do
                            local reel = reelsList[i]
                            
                            if reel.m_reelResultLines and #reel.m_reelResultLines > 0 then
                                winLines = reel.m_reelResultLines
                            end
                        end

                        if #winLines > 0  then
                            self:checkNotifyManagerUpdateWinCoin( )
                        end

                    end)
                end )
        else

            gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_FreespinStart_view.mp3")
            self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                self.m_miniFsReelTop:ChangeScatterNode( )
                self.m_miniFsReelDown:CreateSlotNodeByData()
                self.m_freespinSpinbar:setVisible(true)
                self.m_freespinSpinbar:updateFreespinCount( self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinsLeftCount,self.m_runSpinResultData.p_freeSpinsTotalCount )
                self:showGuoChang( function(  )
                    
                    performWithDelay(self,function(  )
                       
                    
                            self:LockWildTurnAct( function(  )
                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end )
    
                                   
                        
                    end,0.5)
                    

                end ,true )
            end)

            
                

                
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

---
-- 显示free spin
function CodeGameScreenFloweryPixieMachine:showEffect_FreeSpin(effectData)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        effectData.p_isPlay = true
        self:playGameEffect()

        return true
    else
        if self.m_winSoundsId ~= nil then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
    
        self.isInBonus = true
    
        return BaseFastMachine.showEffect_FreeSpin(self,effectData)
    end
    
end

---
-- 显示free spin over 动画
function CodeGameScreenFloweryPixieMachine:showEffect_FreeSpinOver()

    globalFireBaseManager:sendFireBaseLog("freespin_", "appearing")

    local lines = self:getFreeSpinReelsLines()


    if #lines == 0 then
        self.m_freeSpinOverCurrentTime = 1
    end

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
        self.m_fsOverHandlerID =scheduler.scheduleGlobal(function()
            if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime>0 then
                self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
            else
                self:showEffect_newFreeSpinOver()
            end
        end,0.1)
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function CodeGameScreenFloweryPixieMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_FreespinEnd.mp3")

    performWithDelay(self,function(  )
        gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_FreespinOver_view.mp3")

        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
         local view = self:showFreeSpinOver( strCoins, 
             self.m_runSpinResultData.p_freeSpinsTotalCount,function()
                 self.m_FlowerGirl:setVisible(false)
                 performWithDelay(self,function( )
                     self.m_FlowerGirl:setVisible(true)
                 end,0.3)
                 
                 self:showGuoChang(function(  )
                     self:triggerFreeSpinOverCallFun()
                     self:RemoveAndCreateRuningFsReelSlotsNode( )
                 end)
             
         end)
         local node=view:findChild("m_lb_coins")
         view:updateLabelSize({label=node,sx=0.96,sy=0.96},613)
    end,2.5)
  

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenFloweryPixieMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)
   
    -- self:closeTipView( )

    self.m_FSLittleReelsDownIndex = 0 -- FS停止计数
    self.m_FSLittleReelsShowSpinIndex = 0 -- FS显示计数
    self.m_rewordTotalCoins = 0
    self.m_rewordTotalTimes = 0
    self.m_rewordCurrTimes = 0

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:randomMyster( )

    -- self.m_HuaNodeView:updateBigFlowers( self ,true )

    return false -- 用作延时点击spin调用
end


-- --------------网络数据处理处理 
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenFloweryPixieMachine:MachineRule_network_InterveneSymbolMap()

end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenFloweryPixieMachine:MachineRule_afterNetWorkLineLogicCalculate()

    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表

end


function CodeGameScreenFloweryPixieMachine:getTableNum( array )
    local num = 0

    if array then
        
        for k,v in pairs(array) do
            num = num + 1
        end
    end

    return num
end

function CodeGameScreenFloweryPixieMachine:isTriggerIColEffect( iCol , array )
    
    local isTrigger = false

    if array then
        
        for k,v in pairs(array) do
            local index = tonumber(k)

            local fixPos = self:getRowAndColByPos(index)

            if iCol == fixPos.iY then
                isTrigger = true

                return isTrigger
            end
            
        end
    end

    return isTrigger

end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenFloweryPixieMachine:addSelfEffect()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local feature = self.m_runSpinResultData.p_features
        if feature and #feature > 1 and feature[2] == 1 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 7
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BONUS_FS_WILD_LOCK_EFFECT -- 动画类型
            
        end
    end 
        

end

--
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenFloweryPixieMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.BONUS_FS_WILD_LOCK_EFFECT then 

        self:showSelfEffect_FreeSpin(effectData)

    end

	return true
end

---
-- 显示free spin
function CodeGameScreenFloweryPixieMachine:showSelfEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 停掉背景音乐
    self:clearCurMusicBg()

    local topScatterLineValue = self.m_miniFsReelTop:getScatterLineValue( )
    local downScatterLineValue = self.m_miniFsReelDown:getScatterLineValue( )

    -- 播放提示时播放音效
    self:playScatterTipMusicEffect()

    if topScatterLineValue and downScatterLineValue then

        self.m_miniFsReelTop:showSelfEffect_FreeSpin(function(  )
        end)

        self.m_miniFsReelDown:showSelfEffect_FreeSpin(function(  )
            self:showFreeSpinView(effectData)
        end)
    else
        if topScatterLineValue then
            self.m_miniFsReelTop:showSelfEffect_FreeSpin(function(  )
                self:showFreeSpinView(effectData)
            end)
        elseif downScatterLineValue then
            self.m_miniFsReelDown:showSelfEffect_FreeSpin(function(  )
                self:showFreeSpinView(effectData)
            end)
        end
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)

end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenFloweryPixieMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end


-- ---- Myster 处理
function CodeGameScreenFloweryPixieMachine:randomMyster( )

    local index =  self:getProMysterIndex(self.SYMBOL_MYSTER_ONE_GEAR)
    local index2 =  self:getProMysterIndex(self.SYMBOL_MYSTER_TWO_GEAR)


    self.m_bProduceSlots_RunSymbol_1 = self.SYMBOL_MYSTER_NAME[index]
    self.m_bProduceSlots_RunSymbol_2 = self.SYMBOL_MYSTER_NAME[index2]

    self.m_configData:setMysterSymbol( self.m_bProduceSlots_RunSymbol_1,self.m_bProduceSlots_RunSymbol_2 )



end

function CodeGameScreenFloweryPixieMachine:getProMysterIndex( array )

    local index = 1
    local Gear = 0
    local tableGear = {}
    for k,v in pairs(array) do
        Gear = Gear + v
        table.insert( tableGear, Gear )
    end

    local randomNum = math.random( 1,Gear )

    for kk,vv in pairs(tableGear) do
        if randomNum <= vv then
            return kk
        end

    end

    return index

end


---
--设置bonus scatter 层级
function CodeGameScreenFloweryPixieMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    if symbolType == self.SYMBOL_MYSTER_ONE  then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    elseif symbolType == self.SYMBOL_MYSTER_TWO  then
        symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2
    end


    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GLOD  then

        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_SCATTER_WILD then

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

function CodeGameScreenFloweryPixieMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg

    local norBgIdle = util_spineCreate("FloweryPixie_BG",true,true)
    self.m_gameBg:findChild("Node_1"):addChild(norBgIdle)
    util_spinePlay(norBgIdle,"idleframe",true)

end

---
-- 根据类型获取对应节点
--
function CodeGameScreenFloweryPixieMachine:getSlotNodeBySymbolType(symbolType)
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
    reelNode:setMachine(self )
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

-- ------ ------ ------ ------ ------ ------ ------ ------ ------ ----
-- betLevel 高低bet玩法

function CodeGameScreenFloweryPixieMachine:getBetLevel( )
    return 1
end


function CodeGameScreenFloweryPixieMachine:requestSpinResult()
    

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
    local messageData={msg=MessageDataType.MSG_SPIN_PROGRESS,data=self.m_collectDataList,jackpot = self.m_jackpotList,betLevel = self:getBetLevel( ) }
    -- local operaId = 
    httpSendMgr:sendActionData_Spin(betCoin,totalCoin,0 ,isFreeSpin,moduleName, 
        self.m_spinIsUpgrade,self.m_spinNextLevel,self.m_spinNextProVal,messageData,false)
        

end


function CodeGameScreenFloweryPixieMachine:updatJackPotLock( minBet )

    -- if self.m_betLevel == nil or self.m_betLevel ~= minBet then
    --     self.m_betLevel = minBet
        
    --     -- self.m_HuaNodeView:updateBigFlowers( self )
    -- end
end

function CodeGameScreenFloweryPixieMachine:getMinBet( )
    local minBet = 0

    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()

    for i=#self.m_specialBets,1,-1 do
        local netBetCoins = self.m_specialBets[i].p_totalBetValue
        if  betCoin >= netBetCoins  then
            minBet = i 
            break
        end
    end
    
    if globalData.slotRunData.isDeluexeClub == true then
        minBet = 3 -- 设置为最高betlevel
    end


    return minBet
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenFloweryPixieMachine:upateBetLevel()
    
    local minBet = self:getMinBet( )

    self:updatJackPotLock( minBet ) 
end

function CodeGameScreenFloweryPixieMachine:createrOneReel( reelId,addNodeName  )
    
    local className = "CodeFloweryPixieSrc.MiniReels.FloweryPixieMiniMachine"

    local reelData= {}
    reelData.index = reelId
    reelData.maxReelIndex = self.m_ReelDownMaxCount
    reelData.parent = self
    local miniReel = util_createView(className,reelData)
    self:findChild(addNodeName):addChild(miniReel) 

    return miniReel
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
-- freespin中多个轮子处理
function CodeGameScreenFloweryPixieMachine:FSReelShowSpinNotify(maxCount )
    self.m_FSLittleReelsShowSpinIndex = self.m_FSLittleReelsShowSpinIndex + 1

    if self.m_FSLittleReelsShowSpinIndex == maxCount then

        
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
                BaseMachineGameEffect.playEffectNotifyChangeSpinStatus(self )
            end 
            
        end
        

        self.m_FSLittleReelsShowSpinIndex = 0
    end
end



function CodeGameScreenFloweryPixieMachine:getFreeSpinReelsLines( )

    local lines = {}



    if self.m_miniFsReelTop then

        local miniReelslines = self.m_miniFsReelTop:getResultLines()
        if miniReelslines then
            for i=1,#miniReelslines do
                table.insert( lines,miniReelslines[i] )
            end
        end
    end

    if self.m_miniFsReelDown then

        local miniReelslines = self.m_miniFsReelDown:getResultLines()
        if miniReelslines then
            for i=1,#miniReelslines do
                table.insert( lines,miniReelslines[i] )
            end
        end
    end


    return lines
end

function CodeGameScreenFloweryPixieMachine:playEffectNotifyNextSpinCall( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


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
        delayTime = delayTime + self:getWinCoinTime()

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            
            local lines = self:getFreeSpinReelsLines( )
            

            if lines ~= nil and #lines > 0 then
                

                delayTime = 3

                
            end

            if self.m_runSpinResultData.p_features 
                and #self.m_runSpinResultData.p_features == 2 
                    and  self.m_runSpinResultData.p_features[2] == 1 then
                
                    delayTime = 0.5
                
            end

        end

        


        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
            self:normalSpinBtnCall()
        end, delayTime,self:getModuleName())

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin = scheduler.performWithDelayGlobal(function(delay)
            self:normalSpinBtnCall()
        end, 0.5,self:getModuleName())
    end

end

local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenFloweryPixieMachine:addLastWinSomeEffect() -- add big win or mega win

    
    local lines = {}
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local lines = self:getFreeSpinReelsLines( )
        if #lines == 0 then
            return
        end

    else
        if #self.m_vecGetLineInfo == 0 then
            return
        end
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值


    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    curWinType = WinType.Normal
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

function CodeGameScreenFloweryPixieMachine:RemoveAndCreateRuningFsReelSlotsNode( )

        self.m_miniFsReelTop:removeAllReelsNode()
        self.m_miniFsReelDown:removeAllReelsNode()
end
---
-- 老虎机滚动结束调用
function CodeGameScreenFloweryPixieMachine:slotReelDown()

    

    BaseFastMachine.slotReelDown(self) 

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

--freespin下主轮调用父类停止函数
function CodeGameScreenFloweryPixieMachine:slotReelDownInLittleBaseReels( )
    self:setGameSpinStage( STOP_RUN )
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]
            
            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end



    print("滚动结束了....")
    self:reelDownNotifyChangeSpinStatus()
    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect( )
end

function CodeGameScreenFloweryPixieMachine:FSReelDownNotify( maxCount )
    
    self.m_FSLittleReelsDownIndex = self.m_FSLittleReelsDownIndex + 1

    if self.m_FSLittleReelsDownIndex == maxCount then

        self.m_FSLittleReelsDownIndex = 0

        self.m_miniFsReelTop:playGameEffect()
        self.m_miniFsReelDown:playGameEffect()

        self:slotReelDownInLittleBaseReels( )


        local feature = self.m_runSpinResultData.p_features
        if feature and #feature > 1 and feature[2] == 1 then

        else

            -- 更新钱
            local winLines = {}
            local reelsList = {self.m_miniFsReelTop,self.m_miniFsReelDown}
            for i=1,#reelsList do
                local reel = reelsList[i]
                
                if reel.m_reelResultLines and #reel.m_reelResultLines > 0 then
                    winLines = reel.m_reelResultLines
                end
            end

            if #winLines > 0  then
                self:checkNotifyManagerUpdateWinCoin( )
            end
        end


        

  
    end

end


function CodeGameScreenFloweryPixieMachine:checkNotifyManagerUpdateWinCoin( )


    -- 这里作为连线时通知钱数更新的 唯一接口
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end 

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,isNotifyUpdateTop})

end

---
-- 处理spin 返回结果
function CodeGameScreenFloweryPixieMachine:spinResultCallFun(param)


    BaseFastMachine.spinResultCallFun(self,param)

    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then


        if param[1] == true then
            local spinData = param[2]
            if spinData.result then
                if spinData.result.selfData then
                    if spinData.result.selfData.spinResults and #spinData.result.selfData.spinResults > 0 then
                     
                        spinData.result.selfData.spinResults[1].bet = spinData.result.bet
                        spinData.result.selfData.spinResults[2].bet = spinData.result.bet
                        self.m_miniFsReelDown:netWorkCallFun(spinData.result.selfData.spinResults[1])
                        self.m_miniFsReelTop:netWorkCallFun(spinData.result.selfData.spinResults[2])

                    end
                    
                end
            end
        end

    else

    end
    
 
end

function CodeGameScreenFloweryPixieMachine:beginReel()


    self.m_addSounds = {}

    if  self:getCurrSpinMode() == FREE_SPIN_MODE then

        self.m_waitChangeReelTime = 0
        release_print("beginReel ... ")
    
        self:stopAllActions()
        self:requestSpinReusltData()   -- 临时注释掉
    
        -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
        self.m_nScatterNumInOneSpin = 0
        self.m_nBonusNumInOneSpin = 0
    
        --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager.p_ViewLayer })
        local effectLen = #self.m_gameEffects
        for i = 1, effectLen, 1 do
            self.m_gameEffects[i] = nil
        end
    
        self:clearWinLineEffect()
        
        self.m_miniFsReelTop:beginMiniReel()
        self.m_miniFsReelDown:beginMiniReel()


        self:setGameSpinStage(GAME_MODE_ONE_RUN)
    else

        BaseFastMachine.beginReel(self)
        
    end

    
end



-- 滚动数据 处理
--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData: 
    @return:
]]
function CodeGameScreenFloweryPixieMachine:getResNodeSymbolType( parentData )
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_prevReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif
            globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE
            then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end
        local reelIndex = parentData.beginReelIndex
        symbolType = reelDatas[reelIndex]
        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType

end


function CodeGameScreenFloweryPixieMachine:changeFreeReelVisible( )
    
    if self:getCurrSpinMode() == FREE_SPIN_MODE   then
        self:findChild("BaseReel"):setVisible(false)
        self.m_FlowerGirl:setVisible(false)
        self:findChild("FsReel"):setVisible(true)
    else

        self:findChild("BaseReel"):setVisible(true)
        self.m_FlowerGirl:setVisible(true)
        self:findChild("FsReel"):setVisible(false)

    end

end


function CodeGameScreenFloweryPixieMachine:showGuoChang( func ,isFsStart )
    
    -- performWithDelay(self:findChild("huaxianzi"),function(  )

        
    -- end,1)
    
    if isFsStart then
        gLobalSoundManager:playSound("FloweryPixieSounds/FloweryPixie_Guochang.mp3")
        util_spinePlay(self.m_FlowerGirl,"actionframe")
    else
        util_spinePlay(self.m_FlowerGirl,"actionframe5")
    end
   

    if not isFsStart then
        self:findChild("huaxianzi"):setVisible(false)
    end

    performWithDelay(self:findChild("huaxianzi"),function(  )

        gLobalSoundManager:playSound("FloweryPixieSounds/FloweryPixie_Guochang2.mp3")

        self:findChild("huaxianzi"):setVisible(true)
        self:findChild("huaxianzi"):setLocalZOrder(5)
        performWithDelay(self:findChild("huaxianzi"),function(  )

            if isFsStart then

                self.m_gameBg:runCsbAction("actionframe1") -- nor To FS
    
                self:findChild("FsReel"):setVisible(true)
                util_playFadeOutAction(self:findChild("BaseReel"),10/30,function(  )
                    self:findChild("BaseReel"):setVisible(false)
                end)
                util_playFadeOutAction(self:findChild("FsReel"),1/30,function(  )
                    util_playFadeInAction(self:findChild("FsReel"),9/30)
                end)
                
                gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_Reel_UP.mp3")
                
                self:runCsbAction("actionframe",false,function(  )
                    self:findChild("Particle_1"):setVisible(false) 
                end)   --帧 102
                -- scheduler.performWithDelayGlobal(function (  )

                    self:findChild("Particle_1"):setVisible(true) 
                    self:findChild("Particle_1"):resetSystem()
                    
                -- end,20/30,self:getModuleName())

                scheduler.performWithDelayGlobal(function (  )
                    
                    
                    self:findChild("Particle_1"):stopSystem()
                    
                end,60/30,self:getModuleName())
                
                

                performWithDelay(self:findChild("huaxianzi"),function(  )

                    performWithDelay(self:findChild("huaxianzi"),function(  )

                        performWithDelay(self:findChild("huaxianzi"),function(  )
                            if func then
                                func()
                            end
                          
                        end,(102 - 10 - 20)/30)

                        self:findChild("huaxianzi"):setLocalZOrder(2)
                        
                        self.m_FlowerGirl:setVisible(false)
                      
                    end,20/30)
                end,10/30)

            else 
                self.m_gameBg:runCsbAction("actionframe2") -- FS to Nor
                self:findChild("BaseReel"):setVisible(true)
                util_playFadeOutAction(self:findChild("FsReel"),10/30,function(  )
                    self:findChild("FsReel"):setVisible(false)
                end)
                util_playFadeOutAction(self:findChild("BaseReel"),1/30,function(  )
                    util_playFadeInAction(self:findChild("BaseReel"),9/30)
                end)

                performWithDelay(self:findChild("huaxianzi"),function(  )

                    performWithDelay(self:findChild("huaxianzi"),function(  )
                        self:findChild("huaxianzi"):setLocalZOrder(2)

                        if isFsStart then
                            util_spinePlay(self.m_FlowerGirl,"actionframe4")
                        else
                            util_spinePlay(self.m_FlowerGirl,"actionframe6")
                        end

                        performWithDelay(self,function() 

                            if func then
                                func()
                            end

                            util_spinePlay(self.m_FlowerGirl,"idleframe",true)
                        end,80/30)
                        if isFsStart then
                            self.m_FlowerGirl:setVisible(false)
                        else
                            self.m_FlowerGirl:setVisible(true)
                        end
                    end,20/30)
                end,10/30)
                
            end
            
        end,7/30)
    end,43/30)


end

 --  --- -- -- -- --  --  --- -- -- -- -- --  --- -- -- -- -- --  --- -- -- -- -- --  --- -- -- -- --
--增加提示节点
function CodeGameScreenFloweryPixieMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            
            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_SCATTER_GLOD or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex,slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            end
        end
    end -- end for i=1,#nodes
    return tipSlotNoes
end
-- 特殊信号下落时播放的音效
function CodeGameScreenFloweryPixieMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil

        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_SCATTER_GLOD then
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end
            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath = self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_scatterBulingSoundArry["auto"]
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath = self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath = self.m_bonusBulingSoundArry["auto"]
            end
        end
        if soundPath then
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( iCol,soundPath,slotNode.p_symbolType )
            else
                gLobalSoundManager:playSound(soundPath)
            end
            
        end
    end
end

function CodeGameScreenFloweryPixieMachine:checkIsInLongRun(col, symbolType)
    local scatterShowCol = self.m_ScatterShowCol

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GLOD then
        if scatterShowCol ~= nil then
            if self:getInScatterShowCol(col) then
                return true
            else 
                return false
            end
        end
    end

    return true
end

---
-- 检测上次feature 数据
--
function CodeGameScreenFloweryPixieMachine:checkNetDataFeatures()

    local featureDatas = self.m_initSpinData.p_features
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

            if self.checkControlerReelType and self:checkControlerReelType( ) then
                globalMachineController.m_isEffectPlaying = true
            end

            self.m_isRunningEffect = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1 , #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex] 

                    local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GLOD then
                        checkEnd = true
                        local lineInfo = self:getReelLineInfo()
                        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER

                        for addPosIndex = 1 , #lineData.p_iconPos do

                            local posData = lineData.p_iconPos[addPosIndex]
                            local rowColData = self:getRowAndColByPos(posData)
                            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                        end

                        lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN
                        self.m_reelResultLines = {}
                        self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                        break
                    end
                end
                if checkEnd == true then
                    break
                end

            end
            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_runSpinResultData.p_fsWinCoins,false,false})

            -- self:sortGameEffects( )
            -- self:playGameEffect()

        elseif featureId == SLOTO_FEATURE.FEATURE_FREESPIN_FS then -- 有freespin_freespin  -- 放到次数检测那里
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then  -- respin 玩法一并通过respinCount 来进行判断处理
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

            if self.checkControlerReelType and self:checkControlerReelType( ) then
                globalMachineController.m_isEffectPlaying = true
            end
            
            self.m_isRunningEffect = true
            
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
                {SpinBtn_Type.BtnType_Spin,false})


            for lineIndex = 1, #self.m_initSpinData.p_winLines do
                local lineData = self.m_initSpinData.p_winLines[lineIndex]
                local checkEnd = false
                for posIndex = 1 , #lineData.p_iconPos do
                    local pos = lineData.p_iconPos[posIndex] 

                    local rowIndex =  math.floor(pos / self.m_iReelColumnNum) + 1
                    local colIndex = pos % self.m_iReelColumnNum + 1

                    local symbolType = self.m_initSpinData.p_reels[rowIndex][colIndex]
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                        checkEnd = true
                        local lineInfo = self:getReelLineInfo()
                        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_BONUS

                        for addPosIndex = 1 , #lineData.p_iconPos do

                            local posData = lineData.p_iconPos[addPosIndex]
                            local rowColData = self:getRowAndColByPos(posData)
                            lineInfo.vecValidMatrixSymPos[#lineInfo.vecValidMatrixSymPos + 1] = rowColData

                        end

                        lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
                        self.m_reelResultLines = {}
                        self.m_reelResultLines[#self.m_reelResultLines + 1] = lineInfo
                        break
                    end
                end
                if checkEnd == true then
                    break
                end

            end

            -- self:sortGameEffects( )
            -- self:playGameEffect()


        end
    end

end

function CodeGameScreenFloweryPixieMachine:lineLogicEffectType(winLineData, lineInfo,iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData,lineInfo)
            
    if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or enumSymbolType == self.SYMBOL_SCATTER_GLOD then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
            
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end
--[[
    @desc: 对比 winline 里面的所有线， 将相同的线 进行合并，
    这个主要用来处理， winLines 里面会存在两条一样的触发 fs的线，其中一条线winAmount为0，另一条
    有值， 这中情况主要使用与
    time:2018-08-16 19:30:23
    @return:  只保留一份 scatter 赢钱的线，如果存在允许scatter 赢钱的话
]]
function CodeGameScreenFloweryPixieMachine:compareScatterWinLines(winLines)

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
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break  -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or enumSymbolType == self.SYMBOL_SCATTER_GLOD then
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

-- ------ ------ ------ ------ ------ ------ ------ ------ ------ ----
-- ---- 快滚相关 修改
function CodeGameScreenFloweryPixieMachine:getMaxContinuityBonusCol( )
    local maxColIndex = 0

    local isContinuity = true

    for iCol = 1, self.m_iReelColumnNum do
        local bonusNum = 0

        for iRow = 1, self.m_iReelRowNum do

            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]


            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or symbolType == self.SYMBOL_SCATTER_GLOD then
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
--改变下落音效
function CodeGameScreenFloweryPixieMachine:changeReelDownAnima(parentData)
    if parentData.symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or parentData.symbolType == self.SYMBOL_SCATTER_GLOD then
        if not self.m_addSounds then
            self.m_addSounds = {}
        end
        if self:getMaxContinuityBonusCol() >= parentData.cloumnIndex  then
            local soundIndex = 1
            if parentData.cloumnIndex == 1 then
                soundIndex = 1
            elseif parentData.cloumnIndex > 1 and parentData.cloumnIndex < self:getMaxContinuityBonusCol() then
                soundIndex = 2
            else
                soundIndex = 3
            end
            parentData.reelDownAnima = "buling"
            if not self.m_addSounds[parentData.cloumnIndex] then
                self.m_addSounds[parentData.cloumnIndex] = true
                parentData.reelDownAnimaSound = self.m_scatterBulingSoundArry[soundIndex] -- "FloweryPixieSounds/FloweryPixie_scatter_down.mp3"
            end
            if parentData.symbolType == self.SYMBOL_SCATTER_GLOD then
                parentData.reelDownAnima = "buling2"
            end
        end
        parentData.order = REEL_SYMBOL_ORDER.REEL_ORDER_3 + (( self.m_iReelRowNum - parentData.rowIndex )*10 + parentData.cloumnIndex)
    end
end

-- --设置滚动状态
local runStatus =
{
    DUANG = 1,
    NORUN = 2,
}

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenFloweryPixieMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i=1,self.m_iReelColumnNum do
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
        if nodeNum <= 2  then
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
function CodeGameScreenFloweryPixieMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column] -- 快滚信息
    local runLen = reelRunData:getReelRunLen() -- 本列滚动长度
    local allSpecicalSymbolNum = specialSymbolNum -- bonus或者scatter的数量（上一轮，判断后得到的）
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType) -- 获得是否进行长滚逻辑和播放长滚动画（true为进行或播放）

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
        if targetSymbolType == symbolType or targetSymbolType == self.SYMBOL_SCATTER_GLOD then

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

--设置长滚信息
function CodeGameScreenFloweryPixieMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0

    local addLens = false

    for col=1,iColumn do
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
                self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col-1]:getReelRunLen() + 10)
                self:setLastReelSymbolList()
            end
        end

        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        -- bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
        local maxCol =  self:getMaxContinuityBonusCol()
        if  col > maxCol then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
        elseif maxCol == col  then
            if bRunLong then
                addLens = true
            end
        end

    end --end  for col=1,iColumn do
end

-- -- -- -- -- -- -- -- --- -- -- -- -- -- -- -- --- -- -- -- -- -- -- -- --- -- -- -- -- -- -- -- -
-- 金色scatter 固定玩法

function CodeGameScreenFloweryPixieMachine:checkIsTriggerWildTurn( )
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local lockPosList = selfData.newLockWild or {}

    local triggerNum = 0
    local triggerindex = nil
    for i,v in ipairs(lockPosList) do
        local List = v
        if List and #List > 0 then
            triggerindex = i
            triggerNum = triggerNum + 1
        end
    end

    return triggerNum,triggerindex 

end
-- 金色信号改变
function CodeGameScreenFloweryPixieMachine:LockWildTurnAct( func )
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local lockPosList = selfData.newLockWild or {}

    local triggerNum,triggerindex  =  self:checkIsTriggerWildTurn( )

    if triggerNum > 0  then

        if triggerNum == 2 then

            
            -- 第一轮
            self.m_miniFsReelDown:GoldScatterTurnLockWild( lockPosList[1] ,function(  )
                        
                self:lockWildFlyAction( self.m_miniFsReelDown,self.m_miniFsReelTop, lockPosList[1 ] ,function(  )
                    
                    self.m_miniFsReelTop:GoldScatterTurnLockWild( lockPosList[1] ,function(  )
                     
                        -- 第二轮
                        self.m_miniFsReelTop:GoldScatterTurnLockWild( lockPosList[2] ,function(  )
                        
                            self:lockWildFlyAction( self.m_miniFsReelTop,self.m_miniFsReelDown, lockPosList[2 ]  ,function(  )
                                
                                self.m_miniFsReelDown:GoldScatterTurnLockWild( lockPosList[2] ,function(  )
                                 
                                    if func then
                                        func()
                                    end
    
                                end,"buling" )
                            end )
                        end,"switch" )

                    end,"buling" )
                    
                end )
            end,"switch" )


        else

            if triggerindex == 1 then
            
                self.m_miniFsReelDown:GoldScatterTurnLockWild( lockPosList[triggerindex] ,function(  )
                    
                    self:lockWildFlyAction( self.m_miniFsReelDown,self.m_miniFsReelTop, lockPosList[triggerindex ] ,function(  )
                        
                        self.m_miniFsReelTop:GoldScatterTurnLockWild( lockPosList[triggerindex] ,function(  )
                            
                                if func then
                                    func()
                                end

                        end ,"buling")
                        
                    end )
                end,"switch" )

            else
                self.m_miniFsReelTop:GoldScatterTurnLockWild( lockPosList[triggerindex] ,function(  )
                    
                    self:lockWildFlyAction( self.m_miniFsReelTop,self.m_miniFsReelDown, lockPosList[triggerindex ]  ,function(  )
                        
                        self.m_miniFsReelDown:GoldScatterTurnLockWild( lockPosList[triggerindex] ,function(  )
                            
                            if func then
                                func()
                            end

                        end,"buling" )
                    end )
                end,"switch" )
                
            end


            
            
        end

        

    else
        
        if func then
            func()
        end
    end


end
function CodeGameScreenFloweryPixieMachine:runFlyLiZiSymbolAction(flyNode,endNode,time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node = flyNode
    -- node:setVisible(false)

    node:setPosition(startPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        local actionList_1 = {}
        actionList_1[#actionList_1 + 1] = cc.ScaleTo:create((flyTime)/2,2.1)
        actionList_1[#actionList_1 + 1] = cc.ScaleTo:create((flyTime)/2,1)
        node:runAction(cc.Sequence:create(actionList_1))
    end) 
    local bez=cc.BezierTo:create(flyTime ,{cc.p(startPos.x-(startPos.x-endPos.x)*0.3,startPos.y-100),
    cc.p(startPos.x-(startPos.x-endPos.x)*0.6,startPos.y+50),endPos})
    actionList[#actionList + 1] = bez
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        if callback then
            callback()
        end
    end)
    actionList[#actionList + 1] = cc.DelayTime:create(flyTime)
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        if node then
            node:removeFromParent()
        end
    end)
    
    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenFloweryPixieMachine:runFlySymbolAction(flyNode,endNode,time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node = flyNode
    -- node:setVisible(false)

    node:setPosition(startPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        local actionList_1 = {}
        actionList_1[#actionList_1 + 1] = cc.ScaleTo:create((flyTime)/2,2.1)
        actionList_1[#actionList_1 + 1] = cc.ScaleTo:create((flyTime)/2,1)
        node:runAction(cc.Sequence:create(actionList_1))
    end) 
    local bez=cc.BezierTo:create(flyTime ,{cc.p(startPos.x-(startPos.x-endPos.x)*0.3,startPos.y-100),
    cc.p(startPos.x-(startPos.x-endPos.x)*0.6,startPos.y+50),endPos})
    actionList[#actionList + 1] = bez
    actionList[#actionList + 1] = cc.CallFunc:create(function()

        if callback then
            callback()
        end

        if node then
            node:removeFromParent()
        end
    end)
    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenFloweryPixieMachine:lockWildOneFly( flyTimes,node,over,callfunc )
    local actNode = node
    
    local actList = {}
    actList[#actList + 1] = cc.MoveTo:create(flyTimes ,over)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if callfunc then
            callfunc()
        end

        if actNode then
            actNode:removeFromParent()
        end
        
    end)

    local sq = cc.Sequence:create(actList)
    actNode:runAction(sq)

end

function CodeGameScreenFloweryPixieMachine:lockWildFlyAction( manclass1,manclass2, lockList  ,func )
    
    gLobalSoundManager:playSound("FloweryPixieSounds/FloweryPixie_reel_WIld_copy.mp3")

    local flyTimes = 15/30
    local waitTimes = 0
    local num = 0
    for k,v in pairs(lockList) do

        performWithDelay(self,function(  )
            local index = tonumber(v)
            local fixPos = manclass1:getRowAndColByPos(index)
            local targSp = manclass1:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

            local overNode = manclass2:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)

            local node = util_spineCreate("Socre_FloweryPixie_wild",true,true)
            util_spinePlay(node,"idleframe2")

            self:findChild("root"):addChild(node,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100 + v)
            local beginPos = util_getConvertNodePos(targSp,node)
            node:setPosition(cc.p(beginPos))
            local endPos =  util_getConvertNodePos(overNode,node)

            local Particle = util_createAnimation("Socre_FloweryPixie_shouji3.csb")
            Particle:setPosition(cc.p(beginPos))
            self:findChild("root"):addChild(Particle,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER  + v )
            Particle:findChild("Particle_2"):setDuration(flyTimes)
            Particle:findChild("Particle_2"):setPositionType(0)

            self:runFlyLiZiSymbolAction(Particle,overNode,0,flyTimes,cc.p(beginPos),cc.p(endPos))

            self:runFlySymbolAction(node,overNode,0,flyTimes,cc.p(beginPos),cc.p(endPos))

            -- self:lockWildOneFly(flyTimes,node,cc.p(endPos),function(  )
                
            -- end )

            
        end,waitTimes * num)
        
        num = num + 1

    end


    local allActTimes = (waitTimes * (num - 1)) + flyTimes
    performWithDelay(self,function(  )

            gLobalSoundManager:playSound("FloweryPixieSounds/FloweryPixie_WIld_Copy_down.mp3")
            if func then
                func()
            end

    end, allActTimes )
end

---
--添加金边
function CodeGameScreenFloweryPixieMachine:creatReelRunAnimation(col)
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
    reelEffectNode:setOpacity(255)
    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--绘制多个裁切区域
function CodeGameScreenFloweryPixieMachine:drawReelArea()
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

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNode.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth,reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion= function() return {width = clipNodeWidth,height = reelSize.height} end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1000000)
        else
            clipNode = cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
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

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        -- self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        -- self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)
        
        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)
        
        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")


        
    end
end

function CodeGameScreenFloweryPixieMachine:getSlotNodeChildsTopY(colIndex)
    local maxTopY = 0
    self:foreachSlotParent(
        colIndex,
        function(index, realIndex, child)
            local childY = child:getPositionY()
            local topY = nil
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
            else
                if child.p_slotNodeH == nil then -- 打个补丁
                    child.p_slotNodeH = self.m_SlotNodeH
                end
                topY = childY + child.p_slotNodeH * 0.5
            end
            maxTopY = util_max(maxTopY, topY)
        end
    )
    return maxTopY
end

function CodeGameScreenFloweryPixieMachine:quicklyStopReel(colIndex)
    
    

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        BaseFastMachine.quicklyStopReel(self, colIndex) 
    end
    
end

function CodeGameScreenFloweryPixieMachine:setSlotNodeEffectParent(slotNode)
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



    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runAnim("actionframe")
    end
    return slotNode
end

function CodeGameScreenFloweryPixieMachine:palyBonusAndScatterLineTipEnd(animTime,callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(function()

        -- local nodeLen = #self.m_lineSlotNodes
        -- for lineNodeIndex = nodeLen, 1, -1 do
        --     local lineNode = self.m_lineSlotNodes[lineNodeIndex]
        --     -- node = lineNode
        --     if lineNode ~= nil then -- TODO 打的补丁， 临时这样
        --         local preParent = lineNode.p_preParent
        --         if preParent ~= nil then
        --             lineNode:runIdleAnim()
        --         end
        --     end
        -- end

        performWithDelay(self,function(  )
            self:resetMaskLayerNodes()
        end,1)

        callFun()
    end,util_max(67/30,animTime),self:getModuleName())
end

function CodeGameScreenFloweryPixieMachine:specialSymbolActionTreatment( node )
    if node.p_symbolType and (node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or node.p_symbolType == self.SYMBOL_SCATTER_GLOD ) then
        node:runAnim("buling",false,function(  )
            -- node:runAnim("idleframe",true)
        end)
    end
end


function CodeGameScreenFloweryPixieMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:"..ccbName)
        return nil
    end
    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node.m_defaultAnimLoop = true
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:initSpineInfo(spineSymbolData[1],spineSymbolData[2])
            node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node.m_defaultAnimLoop = true
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        node.m_defaultAnimLoop = true
        node:runDefaultAnim()

        -- print("从尺子里面拿 SlotsAnimNode")

        return node
    end
end



function CodeGameScreenFloweryPixieMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if self.m_rewordTotalCoins > 0 then
        print("dadadadada")
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin - self.m_rewordTotalCoins,isNotifyUpdateTop,nil,self.m_rewordTotalCoins})
end

function CodeGameScreenFloweryPixieMachine:getTwoFsReelsSameCol( )

    local col_1 = self.m_miniFsReelTop:getMaxContinuityBonusCol( ) 
    local col_2 = self.m_miniFsReelDown:getMaxContinuityBonusCol( )

    if col_1 > col_2 then

        return col_2 
    else
        return col_1 
    end
    
end

function CodeGameScreenFloweryPixieMachine:createLocalAnimation( )
    local pos = cc.p(self.m_bottomUI.m_normalWinLabel:getPosition()) 
    
    self.m_respinEndActiom =  util_createAnimation("FloweryPixie_jiesuan.csb") 
    self.m_bottomUI.m_normalWinLabel:getParent():addChild(self.m_respinEndActiom,99999)
    self.m_respinEndActiom:setPosition(cc.p(pos.x - 8,pos.y))

    self.m_respinEndActiom:setVisible(false)
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenFloweryPixieMachine:showLineFrameByIndex(winLines,frameIndex)

    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s","")

        return
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
                end
            end
        end
    end

end

return CodeGameScreenFloweryPixieMachine






