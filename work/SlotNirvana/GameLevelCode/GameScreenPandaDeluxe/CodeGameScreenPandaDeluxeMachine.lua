---
-- island li
-- 2019年1月26日
-- CodeGameScreenPandaDeluxeMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SpinResultData_PandaDeluxe = require "CodePandaDeluxeSrc.SpinResultData_PandaDeluxe"

local CodeGameScreenPandaDeluxeMachine = class("CodeGameScreenPandaDeluxeMachine", BaseNewReelMachine)

CodeGameScreenPandaDeluxeMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenPandaDeluxeMachine.SYMBOL_10 = 9
CodeGameScreenPandaDeluxeMachine.SYMBOL_11 = 10
CodeGameScreenPandaDeluxeMachine.SYMBOL_12 = 11
CodeGameScreenPandaDeluxeMachine.SYMBOL_13 = 12
CodeGameScreenPandaDeluxeMachine.SYMBOL_14 = 13
CodeGameScreenPandaDeluxeMachine.SYMBOL_15 = 14

CodeGameScreenPandaDeluxeMachine.JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 30 -- 自定义动画的标识
CodeGameScreenPandaDeluxeMachine.FS_WHEEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 29 
CodeGameScreenPandaDeluxeMachine.BASE_WHEEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 28 

CodeGameScreenPandaDeluxeMachine.m_CollectStates = 0

local betTipsStatus = {
    None = 1,
    Start = 2,
    Idle = 3,
    Over = 4
}
-- 构造函数
function CodeGameScreenPandaDeluxeMachine:ctor()
    BaseNewReelMachine.ctor(self)
    
    self.m_CollectStates = 0

    self.m_iBetLevel = 1
    self.m_isFeatureOverBigWinInFree = true

    self.m_runSpinResultData = SpinResultData_PandaDeluxe.new()
	--init
	self:initGame()
end

function CodeGameScreenPandaDeluxeMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("PandaDeluxeConfig.csv", "LevelPandaDeluxeConfig.lua")
	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenPandaDeluxeMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "PandaDeluxe"  
end


function CodeGameScreenPandaDeluxeMachine:showFreeSpinBar()

    
    -- self.m_DownTip_FsBar:findChild("ShowTip"):setVisible(false)
    -- self.m_DownTip_FsBar:findChild("FsBar"):setVisible(true)

    BaseNewReelMachine.showFreeSpinBar(self)
end

function CodeGameScreenPandaDeluxeMachine:hideFreeSpinBar()

    -- self.m_DownTip_FsBar:findChild("ShowTip"):setVisible(true)
    -- self.m_DownTip_FsBar:findChild("FsBar"):setVisible(false)

    BaseNewReelMachine.hideFreeSpinBar(self)
end

function CodeGameScreenPandaDeluxeMachine:initUI()

    self.m_reelRunSound = "PandaDeluxeSounds/PandaDeluxeSounds_longRun.mp3"
 
    -- local mainNode = {"gamebg","wheel","Node_pandtop","Node_Reel","Node_DownTip","JackPot","Node_ShowView"}
    -- for i=1,#mainNode do
    --     self:findChild(mainNode[i]):setLocalZOrder(i)
    -- end

    self.m_collectAniNode = cc.Node:create()
    self:addChild(self.m_collectAniNode)

    self.m_CollectPanda_bg = util_createAnimation("PandaDeluxe_bet.csb")
    self:findChild("Node_pandtop"):addChild(self.m_CollectPanda_bg)
    self.m_CollectPanda_bg:runCsbAction("idle",true)

    self.m_CollectPanda = util_createAnimation("PandaDeluxe_bet_0.csb")
    self:findChild("Node_pandtop_0"):addChild(self.m_CollectPanda)
    self.m_CollectPanda:runCsbAction("idle",true)
    self:findChild("Node_pandtop_0"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 2)

    self.m_GuoChang = util_createAnimation("PandaDeluxe_zhuanchang.csb")
    self:findChild("Node_ShowView"):addChild(self.m_GuoChang,10000)
    self.m_GuoChang:setVisible(false)


    -- self.m_DownTip_FsBar = util_createView("CodePandaDeluxeSrc.PandaDeluxeFreespinBarView",self) 
    -- self:findChild("Node_DownTip"):addChild(self.m_DownTip_FsBar)
    -- self.m_DownTip_FsBar:runCsbAction("idle1")
    

    self.m_JackPotBar = util_createView("CodePandaDeluxeSrc.PandaDeluxeJackPotBarView")
    self:findChild("JackPot"):addChild(self.m_JackPotBar)
    self.m_JackPotBar:initMachine(self)

    
    self.m_WheelBG = util_createAnimation("PandaDeluxe_freespin_g.csb")
    self:findChild("wheel"):addChild(self.m_WheelBG)
    self.m_WheelBG:setVisible(false)
    self.m_WheelBG:setPositionY(-35)


    self.m_Wheel = util_createView("CodePandaDeluxeSrc.Wheel.PandaDeluxeWheelView")
    self:findChild("wheel"):addChild(self.m_Wheel)
    self.m_Wheel:runCsbAction("base")
    
    self.m_reelFk = util_createAnimation("PandaDeluxe_qipanFK.csb")
    self:findChild("Node_Fk"):addChild(self.m_reelFk)
    self.m_reelFk:setVisible(false)
    self:findChild("Node_Fk"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)

    self:initLevelGoldIcon()

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
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
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 2
        end
        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = "PandaDeluxeSounds/music_PandaDeluxe_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)


    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        if perBetLevel ~= self.m_iBetLevel then

            print("修改bet ...")
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenPandaDeluxeMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    self.m_machineRootPosY = mainPosY

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
        self.m_machineNode:setPositionY(mainPosY  )
        
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

end

function CodeGameScreenPandaDeluxeMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
    
        gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_enter.mp3")
        scheduler.performWithDelayGlobal(function (  )

            self:resetMusicBg()
            self:setMinMusicBGVolume()
        end,1,self:getModuleName())

    end,0.4,self:getModuleName())
end

function CodeGameScreenPandaDeluxeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_CollectStates = selfdata.status or 0

    for i=1,3 do

        local node =  self.m_CollectPanda:findChild("Node_"..i)
        
        if self.m_CollectStates == ( i - 1 ) then
            node:setVisible(true)
            self.m_CollectPanda.m_currStates = self.m_CollectStates
        else
            node:setVisible(false)
        end    
    end

    

    self.m_Wheel:SlowWheelRun( )
    
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false and self.m_bIsReconnectGame ~= true then
        performWithDelay(self, function()
            self:showChooseBetLayer()
        end, 0.3)
    end
    
    self:addObservers()
end

function CodeGameScreenPandaDeluxeMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    -- 切换bet检测黄金图标
    gLobalNoticManager:addObserver(self, function(target, _param)
        self:checkLevelGoldIcon(_param)
    end,"checkLevelGoldIcon")
    gLobalNoticManager:addObserver(self, function(target, _param)
        self:updateLevelGoldIcon(_param)
    end,"UpdateLevelGoldIcon")
end

function CodeGameScreenPandaDeluxeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenPandaDeluxeMachine:MachineRule_GetSelfCCBName(symbolType)
  
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_PandaDeluxe_Scatter"
    elseif symbolType == self.SYMBOL_10 then
        return "Socre_PandaDeluxe_10"
    elseif symbolType == self.SYMBOL_11 then
        return "Socre_PandaDeluxe_11"
    elseif symbolType == self.SYMBOL_12 then
        return "Socre_PandaDeluxe_12"
    elseif symbolType == self.SYMBOL_13 then
        return "Socre_PandaDeluxe_13"
    elseif symbolType == self.SYMBOL_14 then
        return "Socre_PandaDeluxe_14"
    elseif symbolType == self.SYMBOL_15 then
        return "Socre_PandaDeluxe_15"
    end
    
    return nil
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenPandaDeluxeMachine:MachineRule_initGame(  )
    if self.m_bProduceSlots_InFreeSpin == true then
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            self.m_bIsReconnectGame = true
        end
    end
    

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_WheelBG:setVisible(true)
        self.m_WheelBG:runCsbAction("idle",true)
        self:findChild("Node_reelBG"):setVisible(false)
    end

end

--
--单列滚动停止回调
--
function CodeGameScreenPandaDeluxeMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenPandaDeluxeMachine:levelFreeSpinEffectChange()

    self.m_Wheel:runCsbAction("fs")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"fs")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenPandaDeluxeMachine:levelFreeSpinOverChangeEffect()

    self.m_Wheel:runCsbAction("normal")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"base")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关

function CodeGameScreenPandaDeluxeMachine:showFreeSpinStart(num,func)
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func,nil,nil,true)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfdata.freeSpinType or 0

    for i=1,5 do
        local img = view:findChild("Socre_PandaDeluxe_".. i - 1 )
        if img then
            if (i - 1) == freeSpinType then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end

    return view

end

---
-- 显示free spin
function CodeGameScreenPandaDeluxeMachine:showEffect_FreeSpin(effectData)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    
    return BaseNewReelMachine.showEffect_FreeSpin(self,effectData)
end


-- FreeSpinstart
function CodeGameScreenPandaDeluxeMachine:showFreeSpinView(effectData)

    
    
    self.m_Fs_StartId =  gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_Fs_Start.mp3",false,function(  )
        self.m_Fs_StartId = nil
    end)

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()

                if self.m_Fs_StartId then
                    gLobalSoundManager:stopAudio(self.m_Fs_StartId)
                    self.m_Fs_StartId = nil
                end

                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else

            self:showFreeSpinGuoChang("actionframe_freespin",function(  )

                self.m_WheelBG:setVisible(true)
                self.m_WheelBG:runCsbAction("idle",true)
                self.m_Wheel:runCsbAction("bese_freespin")
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"normalToFs")

                
                self:findChild("Node_reelBG"):setVisible(false)

                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                    if self.m_Fs_StartId then
                        gLobalSoundManager:stopAudio(self.m_Fs_StartId)
                        self.m_Fs_StartId = nil
                    end

                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()       
                end) 

                

            end)

        end
    end



    showFSView()    


    

end

function CodeGameScreenPandaDeluxeMachine:showFreeSpinOver(coins,num,func)
    self:clearCurMusicBg()
    local ownerlist={}
    ownerlist["m_lb_num"]=num
    ownerlist["m_lb_coins"]=util_formatCoins(coins, 50)
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER,ownerlist,func,nil,nil,true)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenPandaDeluxeMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_fs_end.mp3")

    performWithDelay(self,function(  )
        self.m_fsOverSoundId =  gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_over_fs.mp3",false,function(  )
            self.m_fsOverSoundId = nil
        end)
    
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
        local view = self:showFreeSpinOver( strCoins,self.m_runSpinResultData.p_freeSpinsTotalCount,function()
    
            if self.m_fsOverSoundId then
                gLobalSoundManager:stopAudio(self.m_fsOverSoundId)
                self.m_fsOverSoundId = nil
            end
    
            self:showFreeSpinGuoChang("freespin_actionframe",function(  )
    
                self.m_WheelBG:setVisible(false)
                self.m_WheelBG:runCsbAction("stop")
    
                self:findChild("Node_reelBG"):setVisible(true)
    
                self.m_Wheel:SlowWheelRun()
                self.m_Wheel:runCsbAction("freespin_bese")
                gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"fsToNormal")
    
                self:triggerFreeSpinOverCallFun()
                    
            end)
            
    
            
        end)
    
    
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},623)
    end,1.5)

   

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenPandaDeluxeMachine:MachineRule_SpinBtnCall()

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:removeSoundHandler() -- 移除监听

    self:setMaxMusicBGVolume()

    self.m_isPlayShouji = false
    
    self.m_bIsReconnectGame = false

    self.m_CollectTime = 0

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfdata.freeSpinType or 0
    self.m_configData:setFreeSpinType( freeSpinType )

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenPandaDeluxeMachine:addSelfEffect()

        

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotWheel = selfdata.jackpotWheel
    if jackpotWheel then
        --自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.JACKPOT_EFFECT -- 动画类型
    end
    

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local normalWheel = selfdata.normalWheel
    if normalWheel then
        if  self:getCurrSpinMode() == FREE_SPIN_MODE  then

            --自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FS_WHEEL_EFFECT -- 动画类型
        else
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.BASE_WHEEL_EFFECT -- 动画类型
        end
        
    end

    
    

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenPandaDeluxeMachine:MachineRule_playSelfEffect(effectData)

    self.m_collectAniNode:stopAllActions()
    

    if effectData.p_selfEffectType == self.JACKPOT_EFFECT then

        local aniNode = cc.Node:create()
        self:addChild(aniNode)

        performWithDelay(aniNode,function(  ) 
            
            self:removeSoundHandler() -- 移除监听

            self:clearCurMusicBg()
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "jackpot")
            end

            self:showJackPotGuoChang("actionframe_jackpot" , function(  )

                self:resetMusicBg(nil,"PandaDeluxeSounds/PandaDeluxeSounds_jackpotGameBG.mp3")

                self.m_CollectPanda_bg:setVisible(false)
                self.m_CollectPanda:setVisible(false)

                local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                    
                local jackpotWheel = selfdata.jackpotWheel or {}
                local jackpotType = jackpotWheel.jackpotType or "A"
                local wheelCoins = jackpotWheel.wheelCoins or 0
                local wheelWinType = jackpotWheel.jackpot
                local Node_Jp_A = self.m_Wheel:findChild("Node_Jp_A")
                Node_Jp_A:setVisible(false)
                local Node_Jp_B = self.m_Wheel:findChild("Node_Jp_B")
                Node_Jp_B:setVisible(false)
    
                local Node_Jp_B_BG = self.m_Wheel:findChild("Node_Jp_B_BG")
                Node_Jp_B_BG:setVisible(false)
                local Node_Jp_A_BG = self.m_Wheel:findChild("Node_Jp_A_BG")
                Node_Jp_A_BG:setVisible(false)
    
    
                
    
                if jackpotType == "A" then
                    Node_Jp_A:setVisible(true)
                    Node_Jp_A_BG:setVisible(true)
                    self.m_Wheel.m_WheelRunType = self.m_Wheel.m_JsWheelGrandRunType
                else
                    Node_Jp_B:setVisible(true)
                    Node_Jp_B_BG:setVisible(true)
                    self.m_Wheel.m_WheelRunType = self.m_Wheel.m_JsWheelMiniRunType
                end
    
                local wheelIndex = jackpotWheel.index + 1
    
                self.m_Wheel:baseToJackPot( function(  )
                    
                    self:wheelRunBegin( wheelIndex, function(  )
    
                        self:updateJackpotLittleCoins( wheelCoins )

                        local index = 4
                        if wheelWinType == "Mini" then
                            index = 4
                        elseif wheelWinType == "Minor" then
                            index = 3
                        elseif wheelWinType == "Major" then
                            index = 2
                        elseif wheelWinType == "Grand" then
                            index = 1
                        end
                        self:showJackpotWinView(index,wheelCoins,function(  )
    
                            self:showFreeSpinGuoChang("freespin_actionframe",function(  )

                                for i=1,3 do

                                    local node =  self.m_CollectPanda:findChild("Node_"..i)
                                    
                                    if self.m_CollectStates == ( i - 1 ) then
                                        node:setVisible(true)
                                        self.m_CollectPanda.m_currStates = self.m_CollectStates
                                    else
                                        node:setVisible(false)
                                    end    
                                end

                                self.m_CollectPanda_bg:setVisible(true)
                                self.m_CollectPanda:setVisible(true)

                                self.m_Wheel:jackPotToBase( function(  )
                    
                                    effectData.p_isPlay = true
                                    self:playGameEffect()
    
                                end)
                                self.m_Wheel:resetView()
                                self.m_Wheel:SlowWheelRun( )

                                self:resetMusicBg()
                
                            end)

                        end)
    
                        
    
                        
                    end )
                end)

            end,nil,function(  )

                    self.m_Wheel:StopSlowWheelRun( )
            end)

            self.m_CollectTime = 0
            aniNode:removeFromParent()
        end,self.m_CollectTime)
    


       

    

    elseif effectData.p_selfEffectType == self.FS_WHEEL_EFFECT then

            local aniNode = cc.Node:create()
            self:addChild(aniNode)
    
            performWithDelay(aniNode,function(  )

                self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
                -- 取消掉赢钱线的显示
                self:clearWinLineEffect()

                self:clearCurMusicBg()
                if self.levelDeviceVibrate then
                    self:levelDeviceVibrate(6, "wheel")
                end

                self:removeSoundHandler() -- 移除监听

                self:TriggerScatter( function(  )

                    self:resetMusicBg(nil,"PandaDeluxeSounds/PandaDeluxeSounds_freeGameWheelBG.mp3")

                    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                    local normalWheel = selfdata.normalWheel or {}
                    local wheelCoins = normalWheel.wheelCoins or 0
                    local wheelIndex = normalWheel.index + 1
            
                    self.m_Wheel.m_WheelRunType = self.m_Wheel.m_FsWheelRunType

                    self.m_Wheel:StopSlowWheelRun( )

                    self:wheelRunBegin( wheelIndex, function(  )
            
                        local wheelRunEnd = function(  )
                            
                            self:resetMusicBg()

                            self:updateLittleCoins( wheelCoins )

                            self.m_Wheel:resetView()
                            self.m_Wheel:SlowWheelRun( )

                            performWithDelay(self,function(  )
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end,0.5)
                            
                            
                        end

                        if normalWheel.wheel[wheelIndex] ~=  "FREE" then
                            local tarNode = self.m_Wheel:findChild("Node_act")

                            gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_showReelFK.mp3")

                            local flyNode = self:runFlyLineAct(tarNode,self:findChild("Node_Fk"),function(  )

                                self:showReelFK( function(  )
                                    wheelRunEnd()
                                end )

                            end)
                            flyNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                        else
                            wheelRunEnd()
                        end
                        
            
                    end,true )
    

                end)
                
                self.m_CollectTime = 0
                aniNode:removeFromParent()
            end,self.m_CollectTime)


        

    elseif effectData.p_selfEffectType == self.BASE_WHEEL_EFFECT then

        local aniNode = cc.Node:create()
        self:addChild(aniNode)

        self:clearCurMusicBg()
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "wheel")
        end

        performWithDelay(aniNode,function(  )

            self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()

            self:removeSoundHandler() -- 移除监听

            self:TriggerScatter( function(  )

                self:resetMusicBg(nil,"PandaDeluxeSounds/PandaDeluxeSounds_baseGameWheelBG.mp3")

                local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                
                local normalWheel = selfdata.normalWheel or {}
                local wheelCoins = normalWheel.wheelCoins or 0
                local wheelIndex = normalWheel.index + 1
                self.m_Wheel.m_WheelRunType = self.m_Wheel.m_baseWheelRunType
                self.m_Wheel:StopSlowWheelRun( )
                self:wheelRunBegin( wheelIndex, function(  )
                       
                    local wheelRunEnd = function(  )

                        self:resetMusicBg()

                        self.m_Wheel:resetView()
                        self.m_Wheel:SlowWheelRun( )

                        self:updateLittleCoins( wheelCoins )


                        if normalWheel.wheel[wheelIndex] ~=  "FREE" then
                            performWithDelay(self,function(  )
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end,0.5)
                        else

                            effectData.p_isPlay = true
                            self:playGameEffect()

                        end


                        
                    end

                    if normalWheel.wheel[wheelIndex] ~=  "FREE" then
                        local tarNode = self.m_Wheel:findChild("Node_act")

                        gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_showReelFK.mp3")

                        local flyNode = self:runFlyLineAct(tarNode,self:findChild("Node_Fk"),function(  )

                            self:showReelFK( function(  )
                                wheelRunEnd()
                            end )
                            
                            
                        end)
                        flyNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
                    else
                        wheelRunEnd()
                    end

                end,true )
            end )


            self.m_CollectTime = 0
            aniNode:removeFromParent()
        end,self.m_CollectTime)

            

        
    end

    
	return true
end

function CodeGameScreenPandaDeluxeMachine:TriggerScatter( func )

    gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_Scatter_Trigger.mp3")

    for iRow  = 1, self.m_iReelRowNum, 1 do
        for iCol = 1, self.m_iReelColumnNum, 1 do
            local tarSp = self:getFixSymbol( iCol , iRow, SYMBOL_NODE_TAG)
            if tarSp  then
                if tarSp.p_symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER 
                    or tarSp.p_symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_WILD then
                        tarSp = self:setSymbolToClipReel(tarSp.p_cloumnIndex, tarSp.p_rowIndex, tarSp.p_symbolType)

                        tarSp:runAnim("fsTrigger")
                end
                
            end
        end
    end
    
    performWithDelay(self,function(  )

        for iRow  = 1, self.m_iReelRowNum, 1 do
            for iCol = 1, self.m_iReelColumnNum, 1 do
                local tarSp = self:getFixSymbol( iCol , iRow, SYMBOL_NODE_TAG)
                if tarSp  then
                    if tarSp.p_symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER 
                        or tarSp.p_symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_WILD then
                            self:runFlyLineAct(tarSp,self:findChild("wheel"))
                    end
                    
                end
            end
        end
        

        performWithDelay(self,function(  )


            local freespin_g = util_createAnimation("PandaDeluxe_freespin_g.csb")
            self:findChild("wheel"):addChild(freespin_g,1)
            freespin_g:setPositionY(-35)
            freespin_g:runCsbAction("actionframe",false,function(  )
                freespin_g:removeFromParent()
            end)

            if func then
                func()
            end


        end,12/30)
        
    end, 60 / 30)
end

function CodeGameScreenPandaDeluxeMachine:createFlyCoins(symbol,func,index,newEndPos)
    
    local icol = symbol.p_cloumnIndex
    local irow = symbol.p_rowIndex

    local startPos = symbol:getParent():convertToWorldSpace(cc.p(symbol:getPosition()))
    local newStartPos = self:convertToNodeSpace(startPos)
    local effectNode = util_createAnimation("Socre_PandaDeluxe_Scatter_shouji.csb") 
    effectNode:runCsbAction("buling",true) 
    effectNode:setScale(1)
    local particle1 =  effectNode:findChild("Particle_1")
    particle1:setDuration(-1)
    particle1:setPositionType(0)
    
    self:addChild(effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    
    
    local cur =  2- index

    local addTime =  0
    local baseTime = 1

    local PosRandom = cur
    if icol == 4 then
        PosRandom = -1
    end
    newStartPos = cc.p(newStartPos.x + PosRandom * math.random(10,15) , newStartPos.y + math.random(40,60) )
    newEndPos = cc.p(newEndPos.x + PosRandom * math.random(10,15) ,newEndPos.y + 48 )


    effectNode:setPosition(newStartPos)

    local conPos1 = newStartPos
    local conPos2 = newEndPos

    if icol == 2 then
        if index == 1 then
            conPos1 = cc.p(  newEndPos.x + 70  , (newEndPos.y + newStartPos.y)/3 )
            conPos2 = cc.p(  newEndPos.x + 25  , (newEndPos.y + newStartPos.y) *2/3 )
        elseif index == 2 then
            conPos1 = cc.p( newStartPos.x + 60 , (newEndPos.y + newStartPos.y)/3 )
            conPos2 = cc.p( newStartPos.x + 15 , (newEndPos.y + newStartPos.y) *2/3 )
        elseif index == 3 then
            conPos1 = cc.p( newStartPos.x - 120 ,(newEndPos.y + newStartPos.y)/3 )
            conPos2 = cc.p( newStartPos.x - 40 ,(newEndPos.y + newStartPos.y) * 3/4)  
        end
       
    elseif icol == 3 then
        if index == 1 then
            conPos1 = cc.p( PosRandom * 140 +  (newEndPos.x + newStartPos.x)/2 ,(newEndPos.y + newStartPos.y)/3 )
            conPos2 = cc.p( PosRandom * 40 +  (newEndPos.x + newStartPos.x)/2 ,(newEndPos.y + newStartPos.y) *2/3 )
        elseif index == 2 then
            conPos1 = cc.p( PosRandom * 1 +  (newEndPos.x + newStartPos.x)/2 ,(newEndPos.y + newStartPos.y)/3 )
            conPos2 = cc.p( PosRandom * 1 +  (newEndPos.x + newStartPos.x)/2 ,(newEndPos.y + newStartPos.y) *2/3 )
        elseif index == 3 then
            conPos1 = cc.p( PosRandom * 140 +  (newEndPos.x + newStartPos.x)/2 ,(newEndPos.y + newStartPos.y)/3 )
            conPos2 = cc.p( PosRandom * 40 +  (newEndPos.x + newStartPos.x)/2 ,(newEndPos.y + newStartPos.y) *2/3 )
        end

    elseif icol == 4 then
        if index == 1 then
            conPos1 = cc.p( newEndPos.x - 70 ,(newEndPos.y + newStartPos.y)/3)
            conPos2 = cc.p( newEndPos.x - 25 ,(newEndPos.y + newStartPos.y) *2/3)
        elseif index == 2 then
            conPos1 = cc.p( newStartPos.x - 60 ,(newEndPos.y + newStartPos.y)/3  )
            conPos2 = cc.p( newStartPos.x -15 ,(newEndPos.y + newStartPos.y) *2/3  )
        elseif index == 3 then
            conPos1 = cc.p( newStartPos.x + 120 ,(newEndPos.y + newStartPos.y)/3 )
            conPos2 = cc.p( newStartPos.x + 40 ,(newEndPos.y + newStartPos.y) * 3/4 ) 
        end
        
    end

    local flyTime = baseTime+ addTime

    if self.m_CollectTime < flyTime then
        self.m_CollectTime = flyTime + 27/30
    end
    
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        
        local actList_1 = {}
        actList_1[#actList_1 + 1] = cc.ScaleTo:create(flyTime * 2/10,2)
        actList_1[#actList_1 + 1] = cc.DelayTime:create(flyTime* 6/10)
        actList_1[#actList_1 + 1] = cc.ScaleTo:create(flyTime* 2/10,0.1)
        effectNode:runAction(cc.Sequence:create(actList_1))

    end)

    actList[#actList + 1] = cc.BezierTo:create(flyTime  ,{conPos1,conPos2,newEndPos})


    actList[#actList + 1] = cc.CallFunc:create(function()
        particle1:stopSystem()

        local aniNode = cc.Node:create()
        self:addChild(aniNode)
        performWithDelay(aniNode, function()
            effectNode:removeFromParent()
            aniNode:removeFromParent()
        end, 0.3)


            
        if func then
            func()
        end
            
    end)

    effectNode:runAction(cc.Sequence:create(actList))

end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenPandaDeluxeMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

-- 高低bet玩法
function CodeGameScreenPandaDeluxeMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    
    local betCoin = globalData.slotRunData:getCurTotalBet()
    
    if self.m_specialBets and #self.m_specialBets > 0 then
        self.m_iBetLevel = #self.m_specialBets + 1
        for i = 1, #self.m_specialBets do
            if betCoin < self.m_specialBets[i].p_totalBetValue then
                self.m_iBetLevel = i
                break
            end
        end
    else
        self.m_iBetLevel = 1
    end
    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 5
    end

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local freeSpinType = selfdata.freeSpinType or 0
    self.m_configData:setFreeSpinType( freeSpinType )

    self.m_configData:setBetLevel( self.m_iBetLevel )

    -- self.m_DownTip_FsBar:runCsbAction("idle" .. self.m_iBetLevel )
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenPandaDeluxeMachine:showDialog(ccbName,ownerlist,func,isAuto,index,isAddRoot)
    local view=util_createView("Levels.BaseDialog")
    view:initViewData(self,ccbName,func,isAuto,index)
    view:updateOwnerVar(ownerlist)
    if isAddRoot then

    
        if globalData.slotRunData.machineData.p_portraitFlag then
            view.getRotateBackScaleFlag = function(  ) return false end
        end

        local worldPos = self:findChild("Node_ShowView"):convertToWorldSpace(cc.p(0,0))
        local pos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        view:setPosition(pos)
        view:setScale(self.m_machineRootScale)


        local touchLayer = util_newMaskLayer()
        touchLayer:setOpacity(0)
        view:addChild(touchLayer, -1000)

        gLobalViewManager.p_ViewLayer:addChild(view)


        
    else
        if globalData.slotRunData.machineData.p_portraitFlag then
            view.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalViewManager:showUI(view)
    end

    return view
end

function CodeGameScreenPandaDeluxeMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gamebg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName,self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end


-- ---- - - - - -- 
-- wheel
function CodeGameScreenPandaDeluxeMachine:wheelRunBegin( wheelIndex, func ,isNormalWheel)


    self.m_Wheel:setRunWheelData(wheelIndex)
    self.m_Wheel:initCallBack(function()

        if func then
            func()
        end

        
    end)

    if isNormalWheel then
        self.m_Wheel:beginWheelAction()
    else
        performWithDelay(self,function()
            self.m_Wheel:beginWheelAction()
        end,1.5)
    end

    
end

--
-- 显示bonus 触发的小游戏
function CodeGameScreenPandaDeluxeMachine:showEffect_Bonus(effectData)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    if  globalData.slotRunData.currLevelEnter == FROM_QUEST  then
        self.m_questView:hideQuestView()
    end

    
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

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

    return true
end

---
-- 检测上次feature 数据
--
function CodeGameScreenPandaDeluxeMachine:checkNetDataFeatures()

    BaseNewReelMachine.checkNetDataFeatures(self)


    local featureDatas = self.m_initSpinData.p_features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        
        if  featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            local winCoin = self.m_runSpinResultData.p_winAmount
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(winCoin))

        end
    end

end


---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenPandaDeluxeMachine:showBonusGameView(effectData)

 
    self:showFsChooseLayer( function(  )

        self:bonusOverAddFreespinEffect( )

        effectData.p_isPlay = true
        self:playGameEffect() -- 播放下一轮
    end )

end

function CodeGameScreenPandaDeluxeMachine:getSymbolTypeForNetData(iCol, iRow, iLen)

    local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]

    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD  then

        return TAG_SYMBOL_TYPE.SYMBOL_SCATTER

    else
        return symbolType
    end
    
end

function CodeGameScreenPandaDeluxeMachine:checkSymbolTypePlayTipAnima( symbolType )

   return false

end


-- function CodeGameScreenPandaDeluxeMachine:showChooseBetLayer()
--     if globalData.slotRunData.isDeluexeClub == true then
--         return
--     end
--     local betList = globalData.slotRunData.machineData:getMachineCurBetList()
--     local lowBet = betList[1].p_totalBetValue
--     local vecBet = {}
--     vecBet[#vecBet + 1] = lowBet
--     for i = 1, #self.m_specialBets, 1 do
--         vecBet[#vecBet + 1] = self.m_specialBets[i].p_totalBetValue
--     end
--     local chooeLayer = util_createView("CodePandaDeluxeSrc.PandaDeluxeChooseBetView", vecBet)
--     if globalData.slotRunData.machineData.p_portraitFlag then
--         chooeLayer.getRotateBackScaleFlag = function(  ) return false end
--     end
--     chooeLayer:findChild("root"):setScale(self.m_machineRootScale)

--     chooeLayer:setPositionY(self.m_machineRootPosY  )

--     gLobalViewManager:showUI(chooeLayer)


 
-- end

function CodeGameScreenPandaDeluxeMachine:showChooseBetLayer()
    local csbPath = "PandaDeluxe/PandaDeluxe_RaiseBetTips.csb"
    -- 热更时可能会存在文件不存在
    if not cc.FileUtils:getInstance():isFileExist(csbPath) then
        local sMsg = string.format("[CodeGameScreenPandaDeluxeMachine:showChooseBetLayer] 文件不存在=(%s)", csbPath)
        print(sMsg)
        release_print(sMsg)
        return
    end

    local showLayer = util_createView("CodePandaDeluxeSrc.PandaDeluxeShowBetView", self) 
    showLayer:findChild("root"):setScale(self.m_machineRootScale)
    if globalData.slotRunData.machineData.p_portraitFlag then
        showLayer.getRotateBackScaleFlag = function(  ) return false end
    end
    showLayer:setPositionY(self.m_machineRootPosY  )

    gLobalViewManager:showUI(showLayer)

end

function CodeGameScreenPandaDeluxeMachine:beginReel()
    CodeGameScreenPandaDeluxeMachine.super.beginReel(self)
    self:playBetTipsOverAnim()
end


--[[
    黄金图标
]]
function CodeGameScreenPandaDeluxeMachine:initLevelGoldIcon()
    local csbPath = "PandaDeluxe_BetTips.csb"
    -- 热更时可能会存在文件不存在
    if not cc.FileUtils:getInstance():isFileExist(csbPath) then
        local sMsg = string.format("[CodeGameScreenPandaDeluxeMachine:initLevelGoldIcon] 文件不存在=(%s)", csbPath)
        print(sMsg)
        release_print(sMsg)
        return
    end

    self.m_showBetTips = util_createAnimation(csbPath)
    self:addChild(self.m_showBetTips, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    local showBetPos = util_convertToNodeSpace(self.m_bottomUI:findChild("node_bet_tips"),  self)
    self.m_showBetTips:setVisible(false)
    self.m_showBetTips:setPosition(showBetPos)
    self.m_showBetTips:setScale(self.m_machineRootScale)
    --一些数据
    self.m_showBetTips.m_tipStatus   = betTipsStatus.None
    self.m_showBetTips.m_tipBetIndex = 0
end
function CodeGameScreenPandaDeluxeMachine:getLevelGoldIconTriggerState(_params)
    if not self.m_showBetTips or not self.m_specialBets then
        return false
    end
    -- 高倍场名称 = 普通关卡名称 + _H
    local levelName = self:getModuleName()
    local levelName_H = string.format("%s%s", levelName, "_H")
    if levelName ~= _params.levelName and levelName_H ~= _params.levelName then
        return false
    end

    return true
end
function CodeGameScreenPandaDeluxeMachine:checkLevelGoldIcon(_params)
    --[[
        _params = {
            levelName = "",
            bTrigger  = false,
        }
    ]]
    local bTrigger = self:getLevelGoldIconTriggerState(_params)
    if not bTrigger then
        return
    end
    -- 触发提示
    _params.bTrigger = true
end
function CodeGameScreenPandaDeluxeMachine:updateLevelGoldIcon(_params)
    --[[
        params = {
            levelName    = "",
            nowBetCoins  = 0,
            newBetCoins  = 0,
            popDefault   = nil, 
        }
    ]]
    local bTrigger = self:getLevelGoldIconTriggerState(_params)
    if not bTrigger then
        return
    end
    -- 刷新提示面板的ui
    local betIndex = #self.m_specialBets + 1
    local curBet      = globalData.slotRunData:getCurTotalBet()
    for _betIndex,_betData in ipairs(self.m_specialBets) do
        if curBet < _betData.p_totalBetValue then
            betIndex = _betIndex
            break
        end
    end
    if globalData.slotRunData.isDeluexeClub == true then
        betIndex = 5
    end
    local fnUpdateLevelGoldIcon = function(_newBetIndex)
        self.m_showBetTips.m_tipBetIndex = _newBetIndex
        for _index=1,4 do
            local nodeIndex = _index - 1
            local lowNode   = self.m_showBetTips:findChild(string.format("icon%d_low", nodeIndex))
            local highNode  = self.m_showBetTips:findChild(string.format("icon%d_high", nodeIndex))
            local bHigh     = _newBetIndex >= (6 - _index) 
            lowNode:setVisible(not bHigh)
            highNode:setVisible(bHigh)
        end
        local textNode = self.m_showBetTips:findChild("text1")
        textNode:setVisible(5 ~= _newBetIndex)
        local labNum   = self.m_showBetTips:findChild("m_lb_num")
        labNum:setString(tostring(_newBetIndex))
    end
    -- 弹板的其中三条时间线
    local fnPlayStartAnim = function(_fnNext)
        self.m_showBetTips.m_tipStatus = betTipsStatus.Start
        self.m_showBetTips:runCsbAction("start", false, nil)
        self.m_showBetTips:setVisible(true)
        performWithDelay(self.m_showBetTips,function()
            _fnNext()
        end, util_csbGetAnimTimes(self.m_showBetTips.m_csbAct, "start"))
    end
    local fnPlayShuaXinAnim = function(_betIndex, _fnNext)
        self.m_showBetTips.m_tipStatus = betTipsStatus.ShuaXin
        self.m_showBetTips:runCsbAction("shuaxin", false, nil)
        if nil ~= _betIndex then 
            fnUpdateLevelGoldIcon(_betIndex)
        end
        -- 第15帧播放粒子刷新图标
        performWithDelay(self.m_showBetTips,function()
            local particle = self.m_showBetTips:findChild("Particle_1")
            particle:setVisible(true)
            particle:setDuration(0.5)
            particle:setPositionType(0)
            particle:stopSystem()
            particle:resetSystem()
        end, 15/60)
        performWithDelay(self.m_showBetTips,function()
            _fnNext()
        end, util_csbGetAnimTimes(self.m_showBetTips.m_csbAct, "shuaxin"))
    end
    local fnPlayIdleAnim = function()
        self.m_showBetTips.m_tipStatus = betTipsStatus.Idle
        self.m_showBetTips:runCsbAction("idle", true)
    end

    -- 弹出提示面板
    local bSame = betIndex == self.m_showBetTips.m_tipBetIndex
    local idleTime = 4
    local curStatus = self.m_showBetTips.m_tipStatus
    -- print("[CodeGameScreenPandaDeluxeMachine:updateLevelGoldIcon]",betIndex,curStatus,bSame)
    if curStatus == betTipsStatus.None or 
        ((curStatus == betTipsStatus.Start or curStatus == betTipsStatus.Over) and not bSame) then
        -- 暂停延时回调
        self.m_showBetTips:stopAllActions()
        fnUpdateLevelGoldIcon(betIndex)
        fnPlayStartAnim(function()
            fnPlayShuaXinAnim(nil, function()
                fnPlayIdleAnim()
                performWithDelay(self.m_showBetTips,function()
                    self:playBetTipsOverAnim()
                end, idleTime)
            end)
        end)
    elseif curStatus == betTipsStatus.ShuaXin then
        if not bSame then 
            -- 暂停延时回调
            self.m_showBetTips:stopAllActions()
            fnPlayShuaXinAnim(betIndex, function()
                fnPlayIdleAnim()
                performWithDelay(self.m_showBetTips,function()
                    self:playBetTipsOverAnim()
                end, idleTime)
            end)
        end
    elseif curStatus == betTipsStatus.Idle then
        -- 暂停延时回调
        self.m_showBetTips:stopAllActions()
        if not bSame then 
            --立刻暂停idle刷新新的图标
            fnPlayShuaXinAnim(betIndex, function()
                fnPlayIdleAnim()
                performWithDelay(self.m_showBetTips,function()
                    self:playBetTipsOverAnim()
                end, idleTime)
            end)
        else
            --不刷新图标 但是要刷新倒计时
            fnPlayIdleAnim()
            performWithDelay(self.m_showBetTips,function()
                self:playBetTipsOverAnim()
            end, idleTime)
        end
    end
end
function CodeGameScreenPandaDeluxeMachine:playBetTipsOverAnim()
    if not self.m_showBetTips or not self.m_specialBets then
        return false
    end
    if not self.m_showBetTips:isVisible() or self.m_showBetTips.m_tipStatus == betTipsStatus.Over or self.m_showBetTips.m_tipStatus == betTipsStatus.None  then
        return
    end
    self.m_showBetTips:stopAllActions()
    self.m_showBetTips.m_tipStatus = betTipsStatus.Over
    self.m_showBetTips:runCsbAction("over", false, nil)
    performWithDelay(self.m_showBetTips,function()
        self.m_showBetTips:setVisible(false)
        self.m_showBetTips.m_tipStatus = betTipsStatus.None
    end, util_csbGetAnimTimes(self.m_showBetTips.m_csbAct, "over"))
end

function CodeGameScreenPandaDeluxeMachine:showFsChooseLayer( func )
    
    self.m_FsChooseLayer = util_createView("CodePandaDeluxeSrc.PandaDeluxeChooseFreespin",self)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_FsChooseLayer.getRotateBackScaleFlag = function(  ) return false end
    end
    self.m_FsChooseLayer:findChild("root"):setScale(self.m_machineRootScale)

    self.m_FsChooseLayer:setPositionY(self.m_machineRootPosY  )

    gLobalViewManager:showUI(self.m_FsChooseLayer)

    self.m_FsChooseLayer:setEndCall(function()
        
        if func then
            func()
        end
        self.m_FsChooseLayer:removeFromParent()
        self.m_FsChooseLayer = nil
    end)

end

-- 更新控制类数据
function CodeGameScreenPandaDeluxeMachine:SpinResultParseResultData( spinData)
    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_CollectStates = selfdata.status or 0
end

function CodeGameScreenPandaDeluxeMachine:showFreeSpinGuoChang(actLineName,func,funcEnd)
    
    gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_FreeSpinGuoChan.mp3")

    self.m_GuoChang:setVisible(true)
    self.m_GuoChang:runCsbAction( actLineName ,false,function(  )
        self.m_GuoChang:setVisible(false)
        if funcEnd then
            funcEnd()
        end
    end)


    performWithDelay(self,function(  )
        if func then
            func()
        end 
    end,1.1)
    


    
end

function CodeGameScreenPandaDeluxeMachine:showJackPotGuoChang(actLineName,func,funcEnd,funcCurr)
    
    gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_JackPotGuoChang.mp3")

    self.m_CollectPanda:runCsbAction("jiman",false,function(  )
        self.m_CollectPanda:runCsbAction("idle",true)
    end)

    performWithDelay(self,function(  )
        self.m_GuoChang:setVisible(true)
        self.m_GuoChang:runCsbAction( actLineName ,false,function(  )
            self.m_GuoChang:setVisible(false)
            if funcEnd then
                funcEnd()
            end
        end)

        

        performWithDelay(self,function(  )
            if func then
                func()
            end
            if funcCurr then
                funcCurr()
            end
        end,0.2)
        
    end,2.9)
    
end

function CodeGameScreenPandaDeluxeMachine:bonusOverAddFreespinEffect( )
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

function CodeGameScreenPandaDeluxeMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
     -- 如果freespin 未结束，不通知左上角玩家钱数量变化
     local isNotifyUpdateTop = true
     if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
         isNotifyUpdateTop = false
     end

    if self:checkWinLinesIsUpdate( ) then

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}

        local littleGameWinCoins , isJackPot = self:getLittleCoins( ) -- 先播放赢钱

        if isNotifyUpdateTop == false then

            
            if littleGameWinCoins then

                local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
                local endCoins = fsWinCoin - (self.m_serverWinCoins - littleGameWinCoins)
                local beiginCoins = nil
                if isJackPot then
                    endCoins = fsWinCoin 
                    beiginCoins = fsWinCoin - (self.m_serverWinCoins - littleGameWinCoins)
                else
                    endCoins = fsWinCoin - littleGameWinCoins
                    beiginCoins = fsWinCoin - self.m_serverWinCoins 
                end
                
                

                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{endCoins,isNotifyUpdateTop,nil,beiginCoins})
                globalData.slotRunData.lastWinCoin = lastWinCoin
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop}) 
            end

        else
            if littleGameWinCoins then

                local endCoins = self.m_serverWinCoins - littleGameWinCoins

                local beiginCoins = nil
                if isJackPot then
                    endCoins = self.m_serverWinCoins 
                    beiginCoins = littleGameWinCoins
                else
                    endCoins = self.m_serverWinCoins - littleGameWinCoins
                end

                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{endCoins,isNotifyUpdateTop,nil,beiginCoins})
                globalData.slotRunData.lastWinCoin = lastWinCoin
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop}) 
            end

        end


    end
    
end

function CodeGameScreenPandaDeluxeMachine:getLittleCoins( )
    
    local coins = nil
    local isJackPot = false

    -- bonus  freespin 不同时触发
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
                
    local jackpotWheel = selfdata.jackpotWheel or {}
    local jackpotType = jackpotWheel.jackpotType or "A"
    local jackpotwheelCoins = jackpotWheel.wheelCoins or 0
    if jackpotwheelCoins and jackpotwheelCoins > 0 then
        coins = jackpotwheelCoins
        isJackPot = true
    end

    

    local normalWheel = selfdata.normalWheel or {}
    local wheelCoins = normalWheel.wheelCoins or 0
    if wheelCoins and wheelCoins > 0 then

        coins =  wheelCoins
    end


    return coins ,isJackPot
end

function CodeGameScreenPandaDeluxeMachine:checkWinLinesIsUpdate( )
    
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

function CodeGameScreenPandaDeluxeMachine:updateJackpotLittleCoins( coins )

    if not self:checkWinLinesIsUpdate( ) then
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        if self:getCurrSpinMode() == FREE_SPIN_MODE then

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,nil,nil,nil,true})

        else
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,nil,nil,nil,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        end
    else

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then 
            local beiginCoins = 0
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,nil,beiginCoins,nil,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin

        else
            local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
            local updateCoins = fsWinCoin - (self.m_serverWinCoins - coins)
            if updateCoins > 0 then
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{updateCoins,false,nil,nil,nil,true})
                globalData.slotRunData.lastWinCoin = lastWinCoin
            end
            
        end

    end
end

function CodeGameScreenPandaDeluxeMachine:updateLittleCoins( coins )

    if not self:checkWinLinesIsUpdate( ) then
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

        if self:getCurrSpinMode() == FREE_SPIN_MODE then

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,nil,nil,nil,true})

        else
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,true,nil,nil,nil,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        end
    else

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then 
            local beiginCoins = self.m_serverWinCoins - coins
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins,true,nil,beiginCoins,nil,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin

        else
            local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
            local updateCoins = fsWinCoin 
            local beiginCoins = fsWinCoin - coins
            if updateCoins > 0 then
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{updateCoins,false,nil,beiginCoins,nil,true})
                globalData.slotRunData.lastWinCoin = lastWinCoin
            end
            
        end

    end
end

function CodeGameScreenPandaDeluxeMachine:checkIsAddLastWinSomeEffect( )
    
     -- 触发特殊玩法后 判断是否大赢
     local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
     local jackpotWheel = selfdata.jackpotWheel
     if #self.m_vecGetLineInfo == 0 then

         if jackpotWheel  then -- jackpot圆盘玩法
     
         else
             
            return true
         end
     end


    return false
end


function CodeGameScreenPandaDeluxeMachine:playCustomSpecialSymbolDownAct( slotNode )

    CodeGameScreenPandaDeluxeMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    if slotNode.p_symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER 
        or slotNode.p_symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_WILD then

            
        if slotNode.p_cloumnIndex == 2 then
            gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_Scatter_Down_2.mp3")
            
        elseif slotNode.p_cloumnIndex == 3 then
            gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_Scatter_Down_3.mp3")
            
        elseif slotNode.p_cloumnIndex == 4 then
            gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_Scatter_Down_4.mp3")
            
        end

        self:collectWild(slotNode)

    end
    
end

function CodeGameScreenPandaDeluxeMachine:collectWild(symbol)

    

    local endPos = self.m_CollectPanda:getParent():convertToWorldSpace(cc.p(self.m_CollectPanda:getPosition()))
    local newEndPos = self:convertToNodeSpace(endPos)

    symbol:runAnim("buling")

    if self.m_CollectStates ~= 0 and self.m_CollectPanda.m_currStates ~= self.m_CollectStates then

        if self.m_CollectPanda.m_currStates == 0 then
            gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_CollectWild_2.mp3")
        elseif self.m_CollectPanda.m_currStates == 1 then
            gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_CollectWild_3.mp3")
        end

    else
        if self.m_CollectPanda.m_currStates == 0 then
            gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_CollectWild.mp3")
        elseif self.m_CollectPanda.m_currStates == 1 then
            gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_CollectWild_2.mp3")
        elseif self.m_CollectPanda.m_currStates == 2 then
            gLobalSoundManager:playSound("PandaDeluxeSounds/music_PandaDeluxe_CollectWild_3.mp3")
        end
    end
    
    
    for index = 1,3 do
        local func = nil
        if index == 3 then
            func = function(  )
                if self.m_isPlayShouji == false then
                    self.m_isPlayShouji = true

                    if self.m_CollectStates ~= 0 and self.m_CollectPanda.m_currStates ~= self.m_CollectStates then

                        local node_1 =  self.m_CollectPanda:findChild("Node_"..1)
                        local node_2 =  self.m_CollectPanda:findChild("Node_"..2)
                        local node_3 =  self.m_CollectPanda:findChild("Node_"..3)

                        if self.m_CollectPanda.m_currStates == 0 then
                            
                            node_1:setVisible(true)
                            node_2:setVisible(true)
                            node_3:setVisible(false)
                            self.m_CollectPanda:runCsbAction("1_2",false,function(  )
                                node_1:setVisible(false)
                                node_2:setVisible(true)
                                node_3:setVisible(false)
                                self.m_CollectPanda:runCsbAction("idle",true)
                            end) 
                        elseif self.m_CollectPanda.m_currStates == 1 then
                            node_1:setVisible(false)
                            node_2:setVisible(true)
                            node_3:setVisible(true)
                            self.m_CollectPanda:runCsbAction("2_3",false,function(  )
                                node_1:setVisible(false)
                                node_2:setVisible(false)
                                node_3:setVisible(true)
                                self.m_CollectPanda:runCsbAction("idle",true)
                            end) 
                        end
                        self.m_CollectPanda.m_currStates = self.m_CollectStates
                    else
                        self.m_CollectPanda:runCsbAction("shouji",false,function(  )
                            self.m_CollectPanda:runCsbAction("idle",true)
                        end) 
                    end

                    

                    
                end

                self.m_collectAniNode:stopAllActions()
                performWithDelay(self.m_collectAniNode,function(  )
                    self.m_isPlayShouji = false
                    
                end,25/30)
                
                
            end 
        end
        self:createFlyCoins(symbol,func,index,newEndPos)
    end

    
    

end

function CodeGameScreenPandaDeluxeMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        self:findChild("Node_Reel"):addChild(reelEffectNode, 1)
        reelEffectNode:setPosition(cc.p(self:findChild("sp_reel_" .. (col - 1)):getPosition()))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end

end

function CodeGameScreenPandaDeluxeMachine:showJackpotWinView(index,coins,func)
    

    self:clearCurMusicBg()
                        
    local jackPotWinView = util_createView("CodePandaDeluxeSrc.PandaDeluxeJackPotWinView", self)
    
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end

    local worldPos = self:findChild("Node_ShowView"):convertToWorldSpace(cc.p(0,0))
    local pos = gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    jackPotWinView:setPosition(pos)
    jackPotWinView:setScale(self.m_machineRootScale)

    local touchLayer = util_newMaskLayer()
    touchLayer:setOpacity(0)
    jackPotWinView:addChild(touchLayer, -1000)

    gLobalViewManager.p_ViewLayer:addChild(jackPotWinView)


    local curCallFunc = function(  )

        self:resetMusicBg()

        if func then
            func()
        end
    end

    jackPotWinView:initViewData(index,coins,curCallFunc)
end


function CodeGameScreenPandaDeluxeMachine:playEffectNotifyNextSpinCall( )


    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )

end

function CodeGameScreenPandaDeluxeMachine:slotReelDown()

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    BaseNewReelMachine.slotReelDown(self)
    
end

function CodeGameScreenPandaDeluxeMachine:updateNetWorkData()

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    self.m_CollectStates = selfdata.status or 0

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

    

    self:showTipView( function(  )
        self.m_isWaitingNetworkData = false
        self:operaNetWorkData()  -- end
    end )

    

end

function CodeGameScreenPandaDeluxeMachine:runFlyLineAct(startNode,endNode,func)

    -- 创建粒子
    local flyNode =  util_createAnimation( "Socre_PandaDeluxe_Scatter_0.csb" )
    self:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    

    local startPos = util_getConvertNodePos(startNode,flyNode)

    flyNode:setPosition(cc.p(startPos))

    local endPos = cc.p(util_getConvertNodePos(endNode,flyNode))

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:findChild("Node_11"):setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:findChild("Node_11"):setScaleX(scaleSize / 538 )

    flyNode:runCsbAction("actionframe",false,function(  )

            

            flyNode:stopAllActions()
            flyNode:removeFromParent()

    end)
    local actNode = cc.Node:create()
    self:addChild(actNode)
    performWithDelay(actNode,function(  )
        actNode:removeFromParent()
        if func then
            func()
        end

    end,0.4)

    return flyNode

end
-- 提高小块层级到self.m_clipParen
function CodeGameScreenPandaDeluxeMachine:setSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 1, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        local linePos = {}
        -- linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = false
        targSp:setLinePos(linePos)
    end
    return targSp
end

function CodeGameScreenPandaDeluxeMachine:showTipView( func )
    
    --预告中奖动画如上。播放条件：
    -- 1、触发jackpot时50%概率播放，
    -- 2、连线时同种图标大于等于8个且赢钱大于等于16倍时50%概率
    local isPlay = false
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local jackpotWheel = selfdata.jackpotWheel
    if jackpotWheel then
        local random = math.random(1,2)
        if random == 1 then
            isPlay = true
        end
    else

        
        local linesWinCoins = 0
        local winLines = self.m_runSpinResultData.p_winLines or {}
        local lineSypeNum = {}
        -- 找到连线的所有位置

        local linesPosList= {}
        for i = 1, #winLines do
            local lines = winLines[i] or {}
            local iconPos = lines.p_iconPos
            local lineAmount = lines.p_amount

            for k = 1, #iconPos do
                table.insert( linesPosList, iconPos[k] )
            end


            if lineAmount then
                linesWinCoins = linesWinCoins + lineAmount
            end

        end

        table.sort( linesPosList )

        for i = #linesPosList,1,-1 do
            
            if i > 1 then
                if linesPosList[i] == linesPosList[i - 1] then
                    table.remove(linesPosList,i)
                end
            end

        end

        for i=1,#linesPosList do
            local fixpos = self:getRowAndColByPos(linesPosList[i])
            local symbolType = self.m_stcValidSymbolMatrix[fixpos.iX][fixpos.iY]

            if symbolType < 5 then -- 金色图标才参与计算
                local linesData = {}
                if lineSypeNum[symbolType] then
                    lineSypeNum[symbolType] = lineSypeNum[symbolType] + 1
                else
                    lineSypeNum[symbolType] = 1
                end
            end
            
        end



        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = linesWinCoins / totalBet

        for i,v in pairs(lineSypeNum) do
            if v >= 6 then
                if winRate >= 5 then

                    local random = math.random(1,2)
                    if random == 1 then
                        isPlay = true
                    end

                    break
                end
                    
            end
        end


    end

    



    if isPlay then

        gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxeSounds_yugaozhongjiang.mp3")

        self.m_TipView = util_createAnimation("Socre_PandaDeluxe_yugaozhongjiang.csb")
        self:findChild("Node_Tip"):addChild(self.m_TipView,100001)
        self.m_TipView:runCsbAction("actionframe",false,function(  )
            self.m_TipView:removeFromParent()
            if func then
                func()
            end
        end)
    else
        if func then
            func()
        end
    end

end

function CodeGameScreenPandaDeluxeMachine:showReelFK( func )
    self.m_reelFk:setVisible(true)
    self.m_reelFk:runCsbAction("actionframe_jackpot",false,function(  )
        self.m_reelFk:setVisible(false)
    end)
    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,0.3)
end

-- free选择合free不再播放震动，改为转盘玩法触发时播放
function CodeGameScreenPandaDeluxeMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if "free" == _sFeature or "bonus" == _sFeature then
        return
    end
    if CodeGameScreenPandaDeluxeMachine.super.levelDeviceVibrate then
        CodeGameScreenPandaDeluxeMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenPandaDeluxeMachine






