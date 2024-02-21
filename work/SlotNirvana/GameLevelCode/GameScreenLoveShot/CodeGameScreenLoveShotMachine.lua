---
-- island li
-- 2019年1月26日
-- GameScreenLoveShotMachine.lua
-- 
-- 玩法：
-- 
--fixios0223
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CollectData = require "data.slotsdata.CollectData"
local GameScreenLoveShotMachine = class("GameScreenLoveShotMachine", BaseNewReelMachine)

GameScreenLoveShotMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

GameScreenLoveShotMachine.COLLECT_PAIP_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 99
GameScreenLoveShotMachine.CASH_RUSH_RED_7_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 98
GameScreenLoveShotMachine.CASH_RUSH_RED_3_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 97
GameScreenLoveShotMachine.CASH_RUSH_PURPLE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 96
GameScreenLoveShotMachine.CASH_RUSH_GOLD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 95
GameScreenLoveShotMachine.CASH_ADD_RS_TIMES_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 94

GameScreenLoveShotMachine.CASH_RUSH_GOLD_FULL_REEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 93

GameScreenLoveShotMachine.FREE_SPIN_SHOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 50

GameScreenLoveShotMachine.SYMBOL_SCORE_10 = 9 
GameScreenLoveShotMachine.SYMBOL_SCORE_11 = 10 
GameScreenLoveShotMachine.SYMBOL_SHOT_BONUS = 94 
GameScreenLoveShotMachine.SYMBOL_HIT = 95 -- 客户端没用，服务器用的
GameScreenLoveShotMachine.SYMBOL_RAIP_RED = 96 
GameScreenLoveShotMachine.SYMBOL_RAIP_PURPLE = 97 
GameScreenLoveShotMachine.SYMBOL_RAIP_YELLOW = 98 
GameScreenLoveShotMachine.SYMBOL_RESPIN_ADD_TIMES = 100 
GameScreenLoveShotMachine.SYMBOL_RESPIN_BLANK = 101

GameScreenLoveShotMachine.SYMBOL_PURPLE_LAB = 102

GameScreenLoveShotMachine.BASE_STATES = 1 
GameScreenLoveShotMachine.FREE_STATES = 2 
GameScreenLoveShotMachine.BONUS_STATES = 3 
GameScreenLoveShotMachine.ReSpin_STATES = 4 

GameScreenLoveShotMachine.m_bonusPosition = 0 -- 地图位置
GameScreenLoveShotMachine.m_bonusMap = {} -- 地图信息

GameScreenLoveShotMachine.QIUBITE_IDLE_STATES = 0
GameScreenLoveShotMachine.QIUBITE_WIN_LINES_STATES = 1 
GameScreenLoveShotMachine.QIUBITE_YUGAO_STATES = 2 

GameScreenLoveShotMachine.m_purpleBoxNodeList = {} -- 存储紫色box
GameScreenLoveShotMachine.m_purpleBoxClicked = false -- 存储紫色box是否点击完成
GameScreenLoveShotMachine.m_purpleBoxClickedNun = 0 -- 存储紫色box点击个数
GameScreenLoveShotMachine.m_purpleBoxMaxClickedNun = 0 -- 存储紫色box最大点击个数
GameScreenLoveShotMachine.m_currPurpleCashRushNum = 0 -- 存储紫色 cashrush 当前的个数

GameScreenLoveShotMachine.MAIN_ADD_POSY = 43
GameScreenLoveShotMachine.BONUS_VIEW_ADD_POSY = 115
GameScreenLoveShotMachine.JpHeight = 1420
GameScreenLoveShotMachine.scaleMainHeight = 1530
GameScreenLoveShotMachine.m_BonusGameOverCall = nil
GameScreenLoveShotMachine.m_bSlotRunning = nil
GameScreenLoveShotMachine.m_triggerFsShot = nil

GameScreenLoveShotMachine.nodeBgList = {}

GameScreenLoveShotMachine.m_BetChooseGear = 0

GameScreenLoveShotMachine.m_outLine = true
-- 构造函数
function GameScreenLoveShotMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_randomSymbolSwitch = true
    
    self.m_iBetLevel = 0

    self.nodeBgList = {}
    self.m_outLine = true
    self.JpHeight = 1420
    self.scaleMainHeight = 1530

    if display.height < self.scaleMainHeight then
        if display.height > 1324 then
            self.MAIN_ADD_POSY = self.MAIN_ADD_POSY - ((display.height - 1024 ) / 100) * 6
        else
            self.MAIN_ADD_POSY = self.MAIN_ADD_POSY - ((display.height - 1024 ) / 100) * 18
        end
        
    end
    

    self.m_spinRestMusicBG = true
    self.m_slotsAnimNodeFps = 60 -- 小块动画的fps
    self.m_lineFrameNodeFps = 60 -- 连线框动画的fps
    self.m_baseDialogViewFps = 60 -- baseDialog 弹板fps

    self.m_purpleBoxNodeList = {} -- 存储紫色box
    self.m_purpleBoxClicked = false -- 存储紫色box是否点击完成
    self.m_purpleBoxClickedNun = 0 -- 存储紫色box点击个数
    self.m_purpleBoxMaxClickedNun = 0 -- 存储紫色box最大点击个数
    self.m_currPurpleCashRushNum = 0 -- 存储紫色 cashrush 当前的个数
    self.m_bonusPosition = 0 -- 地图位置
    self.m_bonusMap = {} -- 地图信息
    self.m_BonusGameOverCall = nil
    self.m_triggerFsShot = false -- 本次是否触发丘比特射箭
    self.m_isFeatureOverBigWinInFree = true

    --init
    self:initGame()
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function GameScreenLoveShotMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath =  "LoveShotSounds/LoveShot_scatter_down1.mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function GameScreenLoveShotMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("LoveShotConfig.csv", "LevelLoveShotConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function GameScreenLoveShotMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "LoveShot"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function GameScreenLoveShotMachine:getNetWorkModuleName()
    return "LoveShotV2"  
end

function GameScreenLoveShotMachine:changeMainUI( _states )

    
    
    self.m_baseLoadingBar:setVisible(false)
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_pickGameBar:setVisible(false)
    self.m_rsGameBar:setVisible(false)

    if _states == self.ReSpin_STATES then

        self.m_rsGameBar:setVisible(true)

    else
        
        self:findChild("reel_Base"):setVisible(false)
        self:findChild("reel_FreeSpin"):setVisible(false)
    
        self.m_gameBg:findChild("Bg_FreeSpin"):setVisible(false)
        self.m_gameBg:findChild("Bg_Base"):setVisible(false)

        if _states == self.BASE_STATES then
            self.m_gameBg:runCsbAction("normal")
            self:findChild("qiubite"):setPositionY(60)
            self:findChild("reel_Base"):setVisible(true)
            self.m_gameBg:findChild("Bg_Base"):setVisible(true)
            self.m_baseLoadingBar:setVisible(true)
        elseif _states == self.FREE_STATES then
            
            self.m_gameBg:runCsbAction("freespin")
            self:findChild("qiubite"):setPositionY(60)
    
            self.m_baseFreeSpinBar:setVisible(true)
            self:findChild("reel_FreeSpin"):setVisible(true)
            self.m_gameBg:findChild("Bg_FreeSpin"):setVisible(true)
        elseif _states == self.BONUS_STATES then
    
            self:findChild("qiubite"):setPositionY(60)
    
        end

    end

    
    
end


function GameScreenLoveShotMachine:initFreeSpinBar()

    
    local node_bar = self:findChild("Node_TimesBar")
    self.m_baseFreeSpinBar = util_createView("CodeLoveShotSrc.LoveShotTimeBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_baseFreeSpinBar:setViewStates(self.m_baseFreeSpinBar.FREESPIN )


end

function GameScreenLoveShotMachine:initMachineUI( )
    
    BaseNewReelMachine.initMachineUI( self )
    self:initReelMask()
end

function GameScreenLoveShotMachine:initUI()

    self.m_reelRunSound = "LoveShotSounds/LoveShotSounds_longRun.mp3"
    
    local birld = util_spineCreate("LoveShot_Bgeffect_niao",true,true)
    self.m_gameBg:findChild("Node_LoveShot_Bgeffect"):addChild(birld)
    util_spinePlay(birld,"idle",true)

    local light = util_createAnimation("LoveShot_Bgeffect.csb")
    self.m_gameBg:findChild("Node_LoveShot_Bgeffect_Fs"):addChild(light)
    light:runCsbAction("idle",true)
    

    
    for i=1,5 do
        self["m_colorLayer_waitNode_"..i] = cc.Node:create()
        self:addChild(self["m_colorLayer_waitNode_"..i])
    end
    
    self:hideColorLayer( )

    self:initFreeSpinBar() 

    self.m_jackPotBar = util_createView("CodeLoveShotSrc.LoveShotJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackPotBar)
    self.m_jackPotBar:initMachine(self)

    if display.height >= self.JpHeight  then
        self.m_jackPotBar:runCsbAction("big")
    else
        self.m_jackPotBar:runCsbAction("small")
    end

    self.m_qiuBiTeMan = util_spineCreate("LoveShot_qiubite",true,true)
    self:findChild("qiubite"):addChild(self.m_qiuBiTeMan)
    self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
    util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)

    self.m_baseLoadingBar = util_createView("CodeLoveShotSrc.LoveShotBaseLoadingBarView")
    self:findChild("jindutiao"):addChild(self.m_baseLoadingBar)
    self.m_baseLoadingBar:setMachine( self )
   
    self.m_MapView = util_createView("CodeLoveShotSrc.Map.LoveShotMapMainView",self)
    self:addChild(self.m_MapView,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 2)
    self.m_MapView:setVisible(false)
    self.m_MapView:findChild("root"):setScale(self.m_machineRootScale - 0.02)
    self.m_MapView:findChild("root"):setPositionY(self.m_MapView:findChild("root"):getPositionY() + self.MAIN_ADD_POSY + self.BONUS_VIEW_ADD_POSY )

    self.m_BonusClickView = util_createView("CodeLoveShotSrc.Map.LoveShotBonusClickMainView",self)
    self:addChild(self.m_BonusClickView,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 2)
    self.m_BonusClickView:setVisible(false)
    self.m_BonusClickView:findChild("root"):setScale(self.m_machineRootScale - 0.02)
    self.m_BonusClickView:findChild("root"):setPositionY(self.m_BonusClickView:findChild("root"):getPositionY() + self.MAIN_ADD_POSY + self.BONUS_VIEW_ADD_POSY - 150 )

    self.m_bonusClickGuoChang = util_spineCreate("LoveShot_guochang",true,true)
    self:addChild(self.m_bonusClickGuoChang,GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    self.m_bonusClickGuoChang:setVisible(false)
    self.m_bonusClickGuoChang:setScale(self.m_machineRootScale)
    self.m_bonusClickGuoChang:setPosition(display.width/2,display.height/2)
    self.m_bonusClickGuoChang:setPositionY(self.m_bonusClickGuoChang:getPositionY() + self.MAIN_ADD_POSY + self.BONUS_VIEW_ADD_POSY )


    self.m_bonusMapGuoChang = util_createAnimation("LoveShot_jindutiao_guochang.csb")
    self:addChild(self.m_bonusMapGuoChang,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_bonusMapGuoChang:setVisible(false)
    self.m_bonusMapGuoChang:setScale(self.m_machineRootScale)
    self.m_bonusMapGuoChang:setPosition(display.width/2,display.height/2)
    self.m_bonusMapGuoChang:setPositionY(self.m_bonusMapGuoChang:getPositionY() + self.MAIN_ADD_POSY + self.BONUS_VIEW_ADD_POSY )


    self.m_purpleGame_YuGao = util_createAnimation("LoveShot_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_purpleGame_YuGao)
    self.m_purpleGame_YuGao:setVisible(false)

    self.m_purpleGame_YuGaoBg = util_createAnimation("LoveShot_yugao_bg.csb")
    self.m_onceClipNode:addChild(self.m_purpleGame_YuGaoBg,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1 )
    self.m_purpleGame_YuGaoBg:setVisible(false)
    local worldPos = self:findChild("Node_yugao"):getParent():convertToWorldSpace(cc.p(self:findChild("Node_yugao"):getPosition()))
    local nodePos = self.m_onceClipNode:convertToNodeSpace(cc.p(worldPos))
    self.m_purpleGame_YuGaoBg:setPosition(cc.p(nodePos))
    


    self.m_pickGameBar = util_createView("CodeLoveShotSrc.LoveShotTimeBarView")
    self:findChild("Node_TimesBar"):addChild(self.m_pickGameBar)
    self.m_pickGameBar:setVisible(false)
    self.m_pickGameBar:setViewStates(self.m_pickGameBar.PICKGAME )

    self.m_rsGameBar = util_createView("CodeLoveShotSrc.LoveShotTimeBarView")
    self:findChild("Node_TimesBar"):addChild(self.m_rsGameBar)
    self.m_rsGameBar:setVisible(false)
    self.m_rsGameBar:setViewStates(self.m_rsGameBar.RESPIN )
     
    self:findChild("Node_TimesBar"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 1)
    self:findChild("jindutiao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 1)
    self:findChild("qiubite"):setLocalZOrder( - 2)
    self:findChild("bg"):setLocalZOrder( - 200)
    

    self:findChild("Node_yugao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE - 10)
    self:findChild("pickbonusstart"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 11)
    self:findChild("goldrushstart"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 12)
    
    
    self.m_purpleWaitNode = cc.Node:create()
    self:addChild(self.m_purpleWaitNode)

    self.m_RsLockRushNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_RsLockRushNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1) -- 此node只允许add respin锁定的CashRush


    self.m_fsShotRunEffect = util_createAnimation("WinFrameLoveShot_run.csb")
    self.m_clipParent:addChild(self.m_fsShotRunEffect,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 500) 
    self.m_fsShotRunEffect:setPosition(cc.p(self:findChild("sp_reel_4"):getPosition()))
    self.m_fsShotRunEffect:setVisible(false)


    self:changeMainUI( self.BASE_STATES )

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
                
            gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_QiuBitAni_coins3mul.mp3")
            self.m_qiuBiTeMan.m_manStates = self.QIUBITE_WIN_LINES_STATES
            util_spinePlay(self.m_qiuBiTeMan,"actionframe")
            util_spineEndCallFunc(self.m_qiuBiTeMan,"actionframe",function(  )
                self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
                util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
            end)
            
        end

        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio( self.m_winSoundsId)
            self.m_winSoundsId = nil
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "LoveShotSounds/music_LoveShot_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end


function GameScreenLoveShotMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "LoveShotSounds/music_LoveShot_enter.mp3" )

    end,0.4,self:getModuleName())
end

function GameScreenLoveShotMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除

    local percent = self:getBaseBarPercent()
    self.m_baseLoadingBar:setBarPercent(percent)

    local perBetLevel = self.m_iBetLevel
    self:updateBetLevel()
    self:updateLockUi(perBetLevel )

    self:addObservers()
end

function GameScreenLoveShotMachine:addObservers()

    BaseNewReelMachine.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        local flag = params

        self.m_baseLoadingBar:findChild("btn_i"):setVisible(flag)

        local btn = self.m_baseLoadingBar.m_btn_i:findChild("Button_1")
        if btn then
            btn:setEnabled(flag)
        end

        local btnUnLock = self.m_baseLoadingBar:findChild("LoveShot_suoding")
        if btnUnLock then
            btnUnLock:setTouchEnabled(flag)
        end


    end,"BET_ENABLE")

    gLobalNoticManager:addObserver(self,function(self,params)
        
        self:unlockHigherBet()

    end,ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)

    gLobalNoticManager:addObserver(self,function(self,params)
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        self:updateLockUi(perBetLevel )
        
   end,ViewEventType.NOTIFY_BET_CHANGE)
end

function GameScreenLoveShotMachine:updateLockUi( perBetLevel )
    
    if perBetLevel > self.m_iBetLevel then
        -- 锁住
        local btnUnLock = self.m_baseLoadingBar:findChild("LoveShot_suoding")
        btnUnLock:stopAllActions()
        if btnUnLock then
            self.m_baseLoadingBar.m_lockUI:runCsbAction("idle",true)
            btnUnLock:setVisible(true)
        end
    elseif perBetLevel < self.m_iBetLevel then
        -- 解锁
        local btnUnLock = self.m_baseLoadingBar:findChild("LoveShot_suoding")
        if btnUnLock then
            
            gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_jindutiao_unLock.mp3")
            self.m_baseLoadingBar.m_lockUI:runCsbAction("actionframe")
            performWithDelay(btnUnLock,function(  )
                btnUnLock:setVisible(false)
            end,45/60)
            
        end
    end
end

function GameScreenLoveShotMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    -- 移除掉nodebg定时器
    for i=1,#self.nodeBgList do
        local actNodeBg = self.nodeBgList[i]
        if actNodeBg.m_updateCoinHandlerID then
            scheduler.unscheduleGlobal(actNodeBg.m_updateCoinHandlerID)
        end
    end

    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function GameScreenLoveShotMachine:MachineRule_GetSelfCCBName( _symbolType)

    if _symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_LoveShot_10"
    elseif _symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_LoveShot_11"
    elseif _symbolType == self.SYMBOL_SHOT_BONUS then
        return "Socre_LoveShot_Qiubite"
    elseif _symbolType == self.SYMBOL_RAIP_RED then
        return "Socre_LoveShot_CashRush_1"
    elseif _symbolType == self.SYMBOL_RAIP_PURPLE then
        return "Socre_LoveShot_CashRush_0"
    elseif _symbolType == self.SYMBOL_RAIP_YELLOW then
        return "Socre_LoveShot_CashRush_3"
    elseif _symbolType == self.SYMBOL_RESPIN_ADD_TIMES then
        return "Socre_LoveShot_CashRush_2"
    elseif _symbolType == self.SYMBOL_RESPIN_BLANK then
        return "Socre_LoveShot_10"
    elseif _symbolType == self.SYMBOL_PURPLE_LAB then
        return "Socre_LoveShot_Shuzi"
    end

    return nil
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function GameScreenLoveShotMachine:MachineRule_initGame(  )

    
    -- 这里需要处理 在respin结束或者free结束时 需要用下次的数据 

    self:setNextSimulationRollingType()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeMainUI( self.FREE_STATES )
    end

    
end

--
--单列滚动停止回调
--
function GameScreenLoveShotMachine:slotOneReelDown(reelCol)  

    BaseNewReelMachine.slotOneReelDown(self,reelCol) 

    self:showShotRunEffect( reelCol  )

   
end

function GameScreenLoveShotMachine:playCustomSpecialSymbolDownAct( slotNode )

    GameScreenLoveShotMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )

    local soundPath = nil
    if slotNode.p_symbolType == self.SYMBOL_SHOT_BONUS then

        for i=1,#self.nodeBgList do
            local actNodeBg = self.nodeBgList[i]
            if actNodeBg.m_isMoveDown == false  then
                util_playFadeOutAction(actNodeBg,0.5)
            end
            
        end

        soundPath = "LoveShotSounds/music_LoveShot_cashRush_down.mp3"
        slotNode:runAnim("buling")

    elseif slotNode.p_symbolType == self.SYMBOL_RAIP_RED then
        soundPath = "LoveShotSounds/music_LoveShot_cashRush_down.mp3"
        slotNode:runAnim("buling")
    elseif slotNode.p_symbolType == self.SYMBOL_RAIP_PURPLE then
        soundPath = "LoveShotSounds/music_LoveShot_cashRush_down.mp3"
        slotNode:runAnim("buling")
    elseif slotNode.p_symbolType == self.SYMBOL_RAIP_YELLOW then
        
        local posIndex = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
        if not self:checkSymbolPosIsLocked(posIndex ) then
            soundPath = "LoveShotSounds/music_LoveShot_cashRush_down.mp3"
            slotNode:runAnim("buling")
        end
        
    elseif slotNode.p_symbolType == self.SYMBOL_RESPIN_ADD_TIMES then
        -- slotNode:runAnim("buling")

    end

    
    if soundPath then
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( slotNode.p_cloumnIndex,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end
    end
    

end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function GameScreenLoveShotMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function GameScreenLoveShotMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function GameScreenLoveShotMachine:showFreeSpinView(effectData)

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_fs_start_View.mp3")

    local showFreeSpinView = function ( ... )
        if self:getCurrSpinMode() == FREE_SPIN_MODE then

            local view = self:showFreeSpinMoreAutoNomal( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)

            local chibang = util_spineCreate("LoveShot_tb_chibang",true,true)
            view:findChild("Node_chiabang"):addChild(chibang)
            util_spinePlay(chibang,"start") 
            performWithDelay(chibang,function(  )
                util_spinePlay(chibang,"idleframe",true) 
            end,45/60)

            view:setOverAniRunFunc(function()
                
                util_spinePlay(chibang,"over") 

            end)

            performWithDelay(view,function(  )
                local Particle_1 = view:findChild("Particle_1")
                if Particle_1 then
                    Particle_1:resetSystem()
                end
                local Particle_3 = view:findChild("Particle_3")
                if Particle_3 then
                    Particle_3:resetSystem()
                end
            end,25/60)

            local tanban_L = view:findChild("LoveShot_tanban_L")
            if tanban_L then
                local lightBg = util_createAnimation("LoveShot_tanban_L.csb")
                tanban_L:addChild(lightBg)
                lightBg:runCsbAction("actionframe",true)
            end

            
            util_setCascadeOpacityEnabledRescursion(view,true)

        else

            self.m_baseFreeSpinBar:updateFreespinCount( "","" )

            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()

                self:showBonusClickGameGuoChang(function(  )

                    

                    self:changeMainUI( self.FREE_STATES )

                end,function( )

                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                    
                end )

                     
            end)

            local chibang = util_spineCreate("LoveShot_tb_chibang",true,true)
            view:findChild("Node_chiabang"):addChild(chibang)
            util_spinePlay(chibang,"start") 
            performWithDelay(chibang,function(  )
                util_spinePlay(chibang,"idleframe",true) 
            end,45/60)

            view:setOverAniRunFunc(function()
                
                util_spinePlay(chibang,"over") 

            end)

            performWithDelay(view,function(  )
                local Particle_1 = view:findChild("Particle_1")
                if Particle_1 then
                    Particle_1:resetSystem()
                end
                local Particle_3 = view:findChild("Particle_3")
                if Particle_3 then
                    Particle_3:resetSystem()
                end
            end,25/60)

            local tanban_L = view:findChild("LoveShot_tanban_L")
            if tanban_L then
                local lightBg = util_createAnimation("LoveShot_tanban_L.csb")
                tanban_L:addChild(lightBg)
                lightBg:runCsbAction("actionframe",true)
            end

            
            util_setCascadeOpacityEnabledRescursion(view,true)

        end
    end

    showFreeSpinView()  

end

function GameScreenLoveShotMachine:showFreeSpinOverView()

   gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
   local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0

    local view = self:showFreeSpinOver( strCoins, freeSpinsTotalCount ,function()

            self:changeMainUI( self.BASE_STATES )
            self:triggerFreeSpinOverCallFun()

    end)

    util_spinePlay(self.m_qiuBiTeMan,"over")
    view:setOverAniRunFunc(function(  )
        util_spinePlay(self.m_qiuBiTeMan,"show")
        util_spineEndCallFunc(self.m_qiuBiTeMan,"show",function(  )
            self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
            util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
        end)

    end)
    
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1.2,sy=1.2},475)

    local tanban_L = view:findChild("LoveShot_tanban_L")
    if tanban_L then
        local lightBg = util_createAnimation("LoveShot_tanban_L.csb")
        tanban_L:addChild(lightBg)
        lightBg:runCsbAction("actionframe",true)
    end

    local Node_QiuBiTe = view:findChild("Node_QiuBiTe")
    if Node_QiuBiTe then
        local qiuBiTeMan = util_spineCreate("LoveShot_qiubite",true,true)
        Node_QiuBiTe:addChild(qiuBiTeMan)
        util_spinePlay(qiuBiTeMan,"idleframe1",true)
    end

    util_setCascadeOpacityEnabledRescursion(view,true)
end

function GameScreenLoveShotMachine:setNextSimulationRollingType( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local clientReel = selfdata.clientReel
    self.m_configData:setRunType( clientReel )

end


function GameScreenLoveShotMachine:updateNetWorkData()

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

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusPositions = selfdata.bonusPositions or {}
    local replacePositions = selfdata.replacePositions or {}
    
    
    if #bonusPositions > 0 and #replacePositions > 0 then
        self.m_triggerFsShot = true
    end
    

    local isShowYuGao = false
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rushWin = selfdata.rushWin or "0" -- cashRush赢钱大于零才有可能触发
    local points = selfdata.points or {} -- cashRush 紫色才有值
    local features = self.m_runSpinResultData.p_features or {}

    -- 紫色点击玩法显示预告
    if  rushWin ~= "0" then
       if #points > 0 then
            isShowYuGao = true
       end
    end

    -- respin触发时显示预告
    if features and #features >= 2 and features[2] == 3 then
        isShowYuGao = true
    end

    local node = cc.Node:create()
    self:addChild(node) 
    performWithDelay(node,function(  )

        self:setNextSimulationRollingType()

        self:netBackUpdateReelDatas( )

        if isShowYuGao then
            self:showYuGaoView(function(  )
                self:netBackReelsStop()
            end )
        else
            self:netBackReelsStop()
        end

        node:removeFromParent()
    end,0)
    
    
    

end

function GameScreenLoveShotMachine:netBackReelsStop( )


    if self:getCurrSpinMode() == RESPIN_MODE then
        local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
        local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount

        if reSpinCurCount and reSpinsTotalCount then
            if reSpinsTotalCount > 0 then
                if reSpinCurCount <= 0 then
                    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_Respin_LastTime.mp3")
                end
            end
            
        end
        
    end

    self.m_isWaitingNetworkData = false
    self:operaNetWorkData()  -- end

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function GameScreenLoveShotMachine:MachineRule_SpinBtnCall()
    
    self.m_outLine = false

    self:removeSoundHandler() -- 移除监听

    if self.m_MapView:isVisible() then
        
        self:clearCurMusicBg()
        self:resetMusicBg(true) 
        self.m_MapView:closeUi(  )
    end
   
    

    for i=1,#self.nodeBgList do
        local actNodeBg = self.nodeBgList[i]

        if not actNodeBg.m_isMoveDown  then
            util_playFadeInAction(actNodeBg,0.1)
        end
        
    end
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio( self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    
    self.m_triggerFsShot = false 

    self.m_bSlotRunning = true

    if self:getCurrSpinMode() == RESPIN_MODE then
        local reSpinCurCount =  self.m_runSpinResultData.p_reSpinCurCount or 0
        self:changeReSpinUpdateUI(reSpinCurCount - 1)
    end
   
    self.m_BonusGameOverCall = nil

    self:setNextSimulationRollingType( )

    self:setMaxMusicBGVolume( )

    self.m_purpleWaitNode:stopAllActions()

    if self.m_qiuBiTeMan.m_manStates ~= self.QIUBITE_IDLE_STATES then
        util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
        self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
    end
    
    self:removeAllPurpleBox( )


    return false -- 用作延时点击spin调用
end

---
--设置bonus scatter 层级
function GameScreenLoveShotMachine:getBounsScatterDataZorder(symbolType )

    local order = BaseNewReelMachine.getBounsScatterDataZorder(self,symbolType )

    if symbolType == self.SYMBOL_SHOT_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 - 1

    elseif symbolType == self.SYMBOL_RAIP_RED then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1

    elseif symbolType == self.SYMBOL_RAIP_PURPLE then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + 1

    elseif symbolType == self.SYMBOL_RAIP_YELLOW then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + 2
        
    elseif symbolType == self.SYMBOL_RESPIN_ADD_TIMES then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 - 1
    end

    return order

end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function GameScreenLoveShotMachine:addSelfEffect()

        
    self.m_collectList = {}
    
    self:updateCollectList( )

    if self.m_collectList and #self.m_collectList > 0 then

        
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_PAIP_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_PAIP_EFFECT

        --是否触发收集小游戏
        if self:BaseMania_isTriggerCollectBonus() then -- true or
            self.m_triggerBonus = true
        end
    end

    self.m_cashRushList={}

    self:updateCashRushCollectList()

    if self.m_cashRushList and #self.m_cashRushList > 0 then

        if self:getCurrSpinMode() ~= RESPIN_MODE  then

            local rushNode = self.m_cashRushList[1]
            if rushNode.p_symbolType == self.SYMBOL_RAIP_RED then
                if #self.m_cashRushList >= 3  then
                    if #self.m_cashRushList >= 7 then
                        if #self.m_cashRushList >= 7 then
                            self.m_collectGameWait = true
                        end
                        
                        local selfEffect = GameEffectData.new()
                        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1 -- 播放连线之后 触发
                        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                        selfEffect.p_selfEffectType = self.CASH_RUSH_RED_7_EFFECT
                    else
                        local selfEffect = GameEffectData.new()
                        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                        selfEffect.p_effectOrder = self.CASH_RUSH_RED_3_EFFECT 
                        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                        selfEffect.p_selfEffectType = self.CASH_RUSH_RED_3_EFFECT
                    end
  
                end
               
    
            elseif rushNode.p_symbolType == self.SYMBOL_RAIP_PURPLE then
    
                if #self.m_cashRushList >= 3 then

                    self.m_collectGameWait = true
                
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2 -- 播放连线之后 触发
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.CASH_RUSH_PURPLE_EFFECT
                end
                
    
            end

        end
    
        
    end

    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusPositions = selfdata.bonusPositions or {}
    local replacePositions = selfdata.replacePositions or {}
    
    
    if #bonusPositions > 0 and #replacePositions > 0 then

        self.m_collectGameWait = true

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.FREE_SPIN_SHOT_EFFECT 
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FREE_SPIN_SHOT_EFFECT
    end
        


    if self:getCurrSpinMode() == RESPIN_MODE then

        if self:checkAddRespinLock( )then

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.CASH_RUSH_GOLD_EFFECT 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.CASH_RUSH_GOLD_EFFECT
        end


        local rsAddTimes = self:getSymbolCountWithReelResult(self.SYMBOL_RESPIN_ADD_TIMES)
        if rsAddTimes > 0 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.CASH_ADD_RS_TIMES_EFFECT 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.CASH_ADD_RS_TIMES_EFFECT
        end

    else

        if self:checkAddGoldFullReelEffect( )then

            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.CASH_RUSH_GOLD_FULL_REEL_EFFECT 
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.CASH_RUSH_GOLD_FULL_REEL_EFFECT
        end

        
        
    end
    
    
end
function GameScreenLoveShotMachine:checkAddGoldFullReelEffect( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local clientReel = selfdata.clientReel or ""
    local rushPositions = selfdata.rushPositions or {}
    local features = self.m_runSpinResultData.p_features or {}

    if clientReel == "gold"  then

        if #rushPositions == 15 then
            if features[2] then
                if features[2] ~= RESPIN_MODE then
                    return true
                end
            else
    
                return true
            end
        end

    end

    return false
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function GameScreenLoveShotMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_PAIP_EFFECT then
        
        self:playCollectRaipEffect(effectData)

    elseif effectData.p_selfEffectType == self.CASH_RUSH_RED_7_EFFECT then

        self:playRedCashRush_7_Effect(effectData)

    elseif effectData.p_selfEffectType == self.CASH_RUSH_RED_3_EFFECT then 
        self:playRedCashRush_3_Effect(effectData)

    elseif effectData.p_selfEffectType == self.CASH_RUSH_PURPLE_EFFECT then

        self:playPurpleCashRushEffect(effectData)

    elseif effectData.p_selfEffectType == self.FREE_SPIN_SHOT_EFFECT then 

        self:playFreeSpinShotEffect(effectData)

    elseif effectData.p_selfEffectType == self.CASH_RUSH_GOLD_EFFECT then  

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  )

            self:playRespinLockRushEffect(effectData)

            waitNode:removeFromParent()
        end,0.5)
        

    elseif effectData.p_selfEffectType == self.CASH_ADD_RS_TIMES_EFFECT then  

        self:playAddRespinTimesEffect(effectData)

    elseif effectData.p_selfEffectType == self.CASH_RUSH_GOLD_FULL_REEL_EFFECT then   
        self:playGoldFullReelEffect( effectData )
    end

    
    return true
end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function GameScreenLoveShotMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function GameScreenLoveShotMachine:playEffectNotifyNextSpinCall( )
    self.m_bSlotRunning = false

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )

   

end

function GameScreenLoveShotMachine:slotReelDown( )

    self:hideYuGaoView( )


    self:hideShotRunEffect( )

    BaseNewReelMachine.slotReelDown(self)
end

function GameScreenLoveShotMachine:scaleMainLayer()
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
        self.m_machineNode:setPositionY(mainPosY + self.MAIN_ADD_POSY )

        
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

end

-- 更新控制类数据
function GameScreenLoveShotMachine:SpinResultParseResultData( spinData)

    self.m_runSpinResultData:parseResultData(spinData.result,self.m_lineDataPool)
    self.m_serverWinCoins = spinData.result.winAmount
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusPosition = selfdata.bonusPosition 
    self:updateMapDataInfo(bonusPosition)

end

function GameScreenLoveShotMachine:updateMapDataInfo(_mappos,_mapdata )
    if _mappos then
        self.m_bonusPosition = _mappos
    end
    if _mapdata then
        self.m_bonusMap = _mapdata
    end
    
end

function GameScreenLoveShotMachine:initGameStatusData(gameData)
    if gameData and gameData.gameConfig and  gameData.gameConfig.extra ~= nil then

        self:updateMapDataInfo(gameData.gameConfig.extra.bonusPosition,gameData.gameConfig.extra.bonusMap )

    end
    BaseNewReelMachine.initGameStatusData(self, gameData)
end

--[[
    +++++++++++++
    收集玩法
]]


--更新收集数据 addCount增加的数量  addCoins增加的奖金
function GameScreenLoveShotMachine:BaseMania_updateCollect(addCount,index,totalCount)
    if not index then
        index=1
    end
    if self.m_collectDataList[index] and type(self.m_collectDataList[index])=="table" then
        self.m_collectDataList[index].p_collectLeftCount = addCount
        self.m_collectDataList[index].p_collectTotalCount = totalCount
    end
end

function GameScreenLoveShotMachine:MachineRule_afterNetWorkLineLogicCalculate()

    -- 更新收集金币
    if self.m_runSpinResultData.p_collectNetData[1] then
        local addCount = self.m_runSpinResultData.p_collectNetData[1].collectLeftCount
        local totalCount = self.m_runSpinResultData.p_collectNetData[1].collectTotalCount 
        self:BaseMania_updateCollect(addCount,1,totalCount)
    end

end
--第一次进入本关卡初始化本关收集数据 如果数据格式不同子类重写这个方法
function GameScreenLoveShotMachine:BaseMania_initCollectDataList()
    --收集数组
    self.m_collectDataList={}
    --默认总数
    
    self.m_collectDataList[1] = CollectData.new()
    self.m_collectDataList[1].p_collectTotalCount = 100
    self.m_collectDataList[1].p_collectLeftCount = 100
    self.m_collectDataList[1].p_collectCoinsPool = 0
    self.m_collectDataList[1].p_collectChangeCount = 0
    
end

function GameScreenLoveShotMachine:getBaseBarPercent()

    local collectData =  self:BaseMania_getCollectData()

    local collectTotalCount = collectData.p_collectTotalCount
    local collectCount = nil

    if collectTotalCount ~= nil then
        collectCount = collectData.p_collectTotalCount - collectData.p_collectLeftCount
    else
        collectTotalCount = collectData.p_collectTotalCount
        collectCount = collectData.p_collectTotalCount - collectData.p_collectLeftCount
    end

    local percent = (collectCount / collectTotalCount) * 100

    return percent
end

function GameScreenLoveShotMachine:checkCashSymbol( _symbolType )


    if _symbolType == self.SYMBOL_RAIP_RED  then
        return true
    elseif _symbolType == self.SYMBOL_RAIP_PURPLE  then
        return true
    elseif _symbolType == self.SYMBOL_RAIP_YELLOW  then
        return true
    end

    return false
end

function GameScreenLoveShotMachine:updateCollectList( )
    

    if self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE and self.m_iBetLevel == 1   then

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node then
                    if self:checkCashSymbol(node.p_symbolType) then
                        self.m_collectList[#self.m_collectList + 1] = node
                    end
                end
            end
        end    

    end


    

end

function GameScreenLoveShotMachine:BaseMania_isTriggerCollectBonus(index)
    if not index then
        index=1
    end
    if self.m_collectDataList[index].p_collectLeftCount <= 0 then
        return true
    end
end



function GameScreenLoveShotMachine:playCollectRaipEffect(effectData)

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_rush_Collect_and_fankui.mp3")

    local endNode = self.m_baseLoadingBar:findChild("Node_actPos")
    local endPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))

    local pecent = self:getBaseBarPercent()

    for i = #self.m_collectList, 1, -1 do
        local node = self.m_collectList[i]
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local flyParticle = util_createAnimation("LoveShot_collecttrail.csb") 

        local Particle_1 = flyParticle:findChild("Particle_1")
        if Particle_1 then
            Particle_1:setDuration(-1)
            Particle_1:setPositionType(0) 
        end

        local Particle_2 = flyParticle:findChild("Particle_2")
        if Particle_2 then
            Particle_2:setDuration(-1)
            Particle_2:setPositionType(0) 
        end

        if i == 1 then
            flyParticle.m_isLastSymbol = true
        end
        self:addChild(flyParticle, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
        flyParticle:setPosition(newStartPos)

        local actLsit = {}
        actLsit[#actLsit + 1] = cc.MoveTo:create(0.5,endPos) 
        actLsit[#actLsit + 1] = cc.CallFunc:create( function()
            if Particle_1 then
                Particle_1:stopSystem()
            end
            
            if Particle_2 then
                Particle_2:stopSystem()
            end


            if flyParticle.m_isLastSymbol == true then

                self.m_baseLoadingBar:updatePercent(pecent)

            end
        

        end)
        actLsit[#actLsit + 1] = cc.DelayTime:create(1)
        actLsit[#actLsit + 1] = cc.CallFunc:create( function()

            flyParticle:removeFromParent()
        end)

        flyParticle:runAction(cc.Sequence:create(actLsit ))


        table.remove(self.m_collectList, i)
    end


    local delayTime = 0
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true or 
        self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true or
            self.m_collectGameWait == true then

        delayTime = 0.5 + 0.7
    end

    if self.m_triggerBonus == true  then
        delayTime = 0.5 + 0.7
    end
    
    performWithDelay(self, function()
        effectData.p_isPlay = true
        self:playGameEffect()
        self.m_collectGameWait = false
        self.m_triggerBonus = false
    end, delayTime )
end

function GameScreenLoveShotMachine:updateReelGridNode( _node )
    
    if not self.m_outLine  then
        self:addSymbolCorner( _node )
        _node:createTrailingNode( _node.p_symbolType,_node.p_cloumnIndex,_node.p_rowIndex,_node.m_isLastSymbol ) 

    end

    
    
end

--[[
    +++++++++++++
    丘比特拖尾
]]
---
-- 根据类型获取对应节点
--
function GameScreenLoveShotMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = BaseNewReelMachine.getSlotNodeBySymbolType(self,symbolType)
    reelNode:initMachine(self )
    return reelNode
end

--小块
function GameScreenLoveShotMachine:getBaseReelGridNode()
    return "CodeLoveShotSrc.LoveShotSlotsNode"
end


--[[
    +++++++++++++
    角标玩法
]]

function GameScreenLoveShotMachine:checkAddSymbolCorner( _posIndex )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local replacePositions = selfdata.replacePositions or {}

    for i=1,#replacePositions do
        local index = replacePositions[i]
        if index == _posIndex then
            return true
        end
    end


    return false
    
end

function GameScreenLoveShotMachine:addSymbolCorner( symbolNode )

    local purpleLock = symbolNode:getChildByName("purpleLock")
    if purpleLock then
        purpleLock:removeFromParent()
    end

    local symbolCorner = symbolNode:getChildByName("symbolCorner")
    if symbolCorner then
        symbolCorner:removeFromParent()
    end

    if symbolNode.p_rowIndex and symbolNode.p_cloumnIndex then
        local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)

        if self:checkAddSymbolCorner( posIndex ) then
            local symbolCorner = util_createAnimation("Socre_LoveShot_Heart.csb")
            symbolNode:addChild(symbolCorner,100)
            symbolCorner:setName("symbolCorner")
            symbolCorner:setPosition(cc.p(25,-25))
            symbolCorner:runCsbAction("idleframe",true)
       end
    
    end
   
end

--[[
    +++++++++++++
    cash rush 玩法
]]

function GameScreenLoveShotMachine:updateCashRushCollectList( )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rushWin = selfdata.rushWin or "0" -- cashRush赢钱大于零才有可能触发

    if rushWin ~= "0" then
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if node then
                    -- 每次spin只会出现一种 cashRush 图标
                    if self:checkCashSymbol(node.p_symbolType) then
                        self.m_cashRushList[#self.m_cashRushList + 1] = node
                    end
                end
            end
        end
    end

    

end

function GameScreenLoveShotMachine:hideYuGaoViewBg( )
    if self.m_purpleGame_YuGaoBg:isVisible() then

        self.m_purpleGame_YuGaoBg:runCsbAction("over",false,function(  )
            self.m_purpleGame_YuGaoBg:setVisible(false)
        end,60)

    end
end

function GameScreenLoveShotMachine:showYuGaoViewBg( )
    self.m_purpleGame_YuGaoBg:setVisible(true)
    self.m_purpleGame_YuGaoBg:runCsbAction("actionframe")
end

function GameScreenLoveShotMachine:hideYuGaoView(_func )

    if self.m_purpleGame_YuGao:isVisible() then

        self.m_purpleGame_YuGao:runCsbAction("over",false,function(  )
        
            if _func then
                _func()
            end
            self.m_purpleGame_YuGao:setVisible(false)
        end,60)

    end

    
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        self:hideYuGaoViewBg( )
    end
    
    
end

function GameScreenLoveShotMachine:showYuGaoView(_func )
    
    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_YuGao.mp3")

    self:findChild("qiubite"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    
    self.m_qiuBiTeMan.m_manStates = self.QIUBITE_YUGAO_STATES
    util_spinePlay(self.m_qiuBiTeMan,"actionframe1")
    util_spineEndCallFunc(self.m_qiuBiTeMan,"actionframe1",function(  )
        self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
        util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        self:findChild("qiubite"):setLocalZOrder( - 2)

        for i=1,8 do
            local Particle = self.m_purpleGame_YuGao:findChild("Particle_"..i)
            if Particle then
                Particle:resetSystem()
            end
        end

        self:showYuGaoViewBg( )

        self.m_purpleGame_YuGao:setVisible(true)
        self.m_purpleGame_YuGao:runCsbAction("actionframe",false,function(  )
            
            if _func then
                _func()
            end
    
        end,60)

        waitNode:removeFromParent()
    end,51/30)

 

end

function GameScreenLoveShotMachine:purpleBoxClickFunc(_sender )

    if self.m_purpleBoxClicked  then
        return
    end

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_purpleBox_click.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local lineBetcoins = selfdata.lineBetcoins or 1

    local isPurpleCashRush = false

    self.m_purpleBoxClicked = true
    self.m_purpleBoxClickedNun = self.m_purpleBoxClickedNun + 1
    
    _sender:setVisible(false)
    local posIndex = tonumber(_sender:getTag())   
    local point = tonumber(_sender:getName())  

    local fixPos = self:getRowAndColByPos(posIndex)
    local targSp =  self:getFixSymbol(fixPos.iY,fixPos.iX, SYMBOL_NODE_TAG)

    local changeType = self.SYMBOL_RAIP_PURPLE
    if point and point > 0 then
        changeType = self.SYMBOL_PURPLE_LAB

    else
        isPurpleCashRush = true
        self.m_currPurpleCashRushNum = self.m_currPurpleCashRushNum + 1
    end
    
    if targSp then
        if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
            targSp.p_symbolImage:removeFromParent()
        end
        targSp.p_symbolImage = nil
        targSp.m_ccbName = ""
    
        targSp:changeCCBByName(self:getSymbolCCBNameByType(self, changeType), changeType)
        targSp:setLocalZOrder( self:getBounsScatterDataZorder(targSp.p_symbolType ) - targSp.p_rowIndex )
        
        if changeType == self.SYMBOL_PURPLE_LAB then
            targSp:getCcbProperty("m_lb_coins"):setString(util_formatCoins(point * lineBetcoins, 3) )
        end
    end

    local purpleBox = self:getOnePurpleBox(posIndex )
    if purpleBox then
        purpleBox:runCsbAction("over")
    end

    if not (self.m_purpleBoxClickedNun >= self.m_purpleBoxMaxClickedNun)  then
        self.m_purpleBoxClicked = false   
    end

    local ClickedNun = self.m_purpleBoxClickedNun
    
    local waitNdoe = cc.Node:create()
    self:addChild(waitNdoe)
    performWithDelay(waitNdoe,function(  )

        local aniName = "actionframe"
        if not (point and point > 0) then

            gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_QiuBitAni_PurpleGame_addCash.mp3")

            self.m_purpleWaitNode:stopAllActions()
            util_spinePlay(self.m_qiuBiTeMan,"actionframe2")
            performWithDelay(self.m_purpleWaitNode,function(  )
                self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
                util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
            end,90/30)
            if self.m_currPurpleCashRushNum >= 7 then
                self.m_jackPotBar:showJpAct(   - (self.m_currPurpleCashRushNum - 15) + 1 )
            end
            aniName = "actionframe1"
        end

        if isPurpleCashRush then
            self.m_pickGameBar:updateCashRushNum( self.m_currPurpleCashRushNum )
        end
        
        local targSp_1 = targSp

        targSp_1:runAnim(aniName)

        
        local ClickedNun_1 = ClickedNun

        local waitNdoe_1 = cc.Node:create()
        self:addChild(waitNdoe_1)
        performWithDelay(waitNdoe_1,function(  )

            if targSp_1.p_symbolType == self.SYMBOL_RAIP_PURPLE then
                targSp_1:runAnim("idleframe2",true)
            end
            
            
            if ClickedNun_1 >= self.m_purpleBoxMaxClickedNun then
                -- 最后一次点击结束玩法    
                if self.m_purpleBoxClickedOverFunc then
                    self.m_purpleBoxClickedOverFunc()
                end
            end
            
            waitNdoe_1:removeFromParent()
        end,15/60)

        waitNdoe:removeFromParent()
    end,30/60)
    

end

function GameScreenLoveShotMachine:purpleBoxClick(_sender,_eventType )
    if _eventType == ccui.TouchEventType.ended then

        local beginPos = _sender:getTouchBeganPosition()
        local endPos = _sender:getTouchEndPosition()
        local offx=math.abs(endPos.x-beginPos.x)
        if offx<50 and globalData.slotRunData.changeFlag == nil then
            self:purpleBoxClickFunc(_sender )
        end
   
    end
end

function GameScreenLoveShotMachine:getOnePurpleBox(_posIndex )
    for i=1,#self.m_purpleBoxNodeList do
        local box = self.m_purpleBoxNodeList[i]
        if box then
            local boxPosIndex = tonumber(box:getName()) 
            if boxPosIndex == _posIndex then

                return box

            end
             
        end
    end
end

function GameScreenLoveShotMachine:removeAllPurpleBox( )
    
    for i=1,#self.m_purpleBoxNodeList do
        local box = self.m_purpleBoxNodeList[i]
        if box then
            box:removeFromParent()
        end
    end
    self.m_purpleBoxNodeList = {}
end

function GameScreenLoveShotMachine:runAllPurpleBoxAni( _aniName,_loop)
    
    for i=1,#self.m_purpleBoxNodeList do
        local box = self.m_purpleBoxNodeList[i]
        if box then
            box:runCsbAction(_aniName,_loop)
        end
    end

    
end

function GameScreenLoveShotMachine:createPurpleBox( _points,targSp )
    
    -- 创建紫色点击盒子
    local posIndex = self:getPosReelIdx(targSp.p_rowIndex, targSp.p_cloumnIndex)
    local PurpleBox = util_createAnimation("Socre_LoveShot_Box.csb")
    PurpleBox:findChild("click"):addTouchEventListener(handler(self, self.purpleBoxClick))
    self.m_clipParent:addChild(PurpleBox,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)
    local pos = util_getOneGameReelsTarSpPos(self,posIndex)
    PurpleBox:setPosition(pos)
    PurpleBox:findChild("click"):setTag( posIndex )
    PurpleBox:findChild("click"):setName( _points[posIndex + 1] ) -- 数组是从1开始的
    PurpleBox:setName( posIndex )
    table.insert(self.m_purpleBoxNodeList,PurpleBox)

end

function GameScreenLoveShotMachine:createCashRushLockNode( targSp  )
    
    -- 在紫色cashRush图标位置创建锁
    local purpleLock = util_createAnimation("Socre_LoveShot_Suo.csb")
    targSp:addChild(purpleLock,100)
    purpleLock:setName("purpleLock")
    purpleLock:setPosition(cc.p(0,0))
    purpleLock:runCsbAction("actionframe")

    return purpleLock
                

end

function GameScreenLoveShotMachine:createPurpleGameUI( _points )
    
    
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then
                if targSp.p_symbolType == self.SYMBOL_RAIP_PURPLE then
                    -- 在紫色cashRush图标位置创建锁
                    self:createCashRushLockNode( targSp  )

                else
                    -- 创建紫色点击盒子
                    self:createPurpleBox( _points,targSp )
                end

            end
        end
    end


end

-- 紫色玩法
function GameScreenLoveShotMachine:playPurpleCashRushEffect( effectData )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rushWin = selfdata.rushWin or "0" -- cashRush赢钱大于零才有可能触发
    local rushPositions = selfdata.rushPositions or {} -- 紫色需要变成盒子的位置 
    local points = selfdata.points or {} --对应点数倍数
    local pointsWin = selfdata.pointsWin or "0" --对应点数赢钱
    local lineBetcoins = selfdata.lineBetcoins or 1



    self.m_purpleBoxNodeList = {}
    self.m_purpleBoxClicked = true -- 先不能点击
    self.m_purpleBoxClickedNun = 0
    self.m_purpleBoxMaxClickedNun = (self.m_iReelColumnNum * self.m_iReelRowNum) - #self.m_cashRushList
    self.m_currPurpleCashRushNum = #self.m_cashRushList
    self.m_purpleBoxClickedOverFunc = function(  )


        local showPickOverView = function(  )
            
            

            local jpCoins = util_formatMoneyStr(rushWin,50)  -- 需要服务器传这两个值
            local pickCoins = util_formatMoneyStr(pointsWin,50) 
            self:showPickBonusOverView(self.m_currPurpleCashRushNum,jpCoins,pickCoins,function(  )

                    self.m_pickGameBar:setVisible(false)

                    local winCoins =  0
                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self.m_baseFreeSpinBar:setVisible(true)
                        winCoins = self.m_runSpinResultData.p_fsWinCoins or 0
                    else
                        self:findChild("qiubite"):setPositionY(60)
                        self.m_baseLoadingBar:setVisible(true)
                        winCoins = self.m_serverWinCoins
                    end

                    local currCoins = tonumber(rushWin) + tonumber(pointsWin)
                    local beiginCoins = winCoins - currCoins
                    self:updateBottomUICoins( beiginCoins,currCoins,true )

                    self.m_jackPotBar:hideJpAct( )
                    self.m_jackPotBar:setCashRushVisibleStates( self.m_jackPotBar.JP_RED )

                    self:resetMusicBg(true)

                    effectData.p_isPlay = true
                    self:playGameEffect()
                    
 

            end)

        end
        -- 显示


        self:clearCurMusicBg()
        
        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Trigger.mp3")

        -- 如果 大于7 显示赢jackpot 最多 15 
        self.m_jackPotBar:showJpAct(   - (#rushPositions - 15) + 1 )

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
                if symbolNode then
                    if symbolNode.p_symbolType == self.SYMBOL_RAIP_PURPLE then
                        symbolNode:runAnim("actionframe",true) 
                    end
                end
            end
        end

        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(waitNode,function(  ) 
            

            if showPickOverView then
                showPickOverView() 
            end

            waitNode:removeFromParent()

        end , 90/30)
            

    end
    

    if self.m_purpleBoxMaxClickedNun <= 0 then
        
        -- 全部都是锁定的紫色格子 直接结算   
        if self.m_purpleBoxClickedOverFunc then
            self.m_purpleBoxClickedOverFunc()
        end

        return
    end


    local showLinesTime = 0
    local winLines = self.m_reelResultLines
    if #winLines > 0  then
        showLinesTime = globalData.slotRunData.levelConfigData:getShowLinesTime() or 0
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )


        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()
        self:clearCurMusicBg()

        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Trigger.mp3")

        for i=1,#self.m_cashRushList do
            local cashRush = self.m_cashRushList[i]
            cashRush:runAnim("actionframe")
        end
        
        performWithDelay(self,function(  )
            
        
            self:findChild("qiubite"):setPositionY(60)

            self.m_pickGameBar:setVisible(true)
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                self.m_baseFreeSpinBar:setVisible(false)
            else
                self.m_baseLoadingBar:setVisible(false)
            end
            
            self.m_pickGameBar:updateCashRushNum( self.m_currPurpleCashRushNum )

            self.m_jackPotBar:changeCashRushAct(self.m_jackPotBar.JP_PURPLE)

            self:showPickBonusStartView( function(  )
                

                if self.m_currPurpleCashRushNum >= 7 then
                    self.m_jackPotBar:showJpAct(   - (self.m_currPurpleCashRushNum - 15) + 1 )
                end
                -- 创建紫色盒子、锁定已有的紫色cashRush图标
                self:createPurpleGameUI( points )

                gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Lock.mp3")
                self:runAllPurpleBoxAni( "actionframe")

                -- 播放完紫色盒子动画 70/60,锁定动画 90/30
                performWithDelay(self,function(  )

                    self:resetMusicBg(nil,"LoveShotSounds/music_LoveShot_Purple_CashRushGame_Bg.mp3")

                    self:runAllPurpleBoxAni( "idleframe",true)

                    if self.m_purpleBoxMaxClickedNun <= 0 then
                        -- 全部都是锁定的紫色格子 直接结算   
                        if self.m_purpleBoxClickedOverFunc then
                            self.m_purpleBoxClickedOverFunc()
                        end
                    else
                        self.m_purpleBoxClicked = false -- 播放完触发动画后可以点击
                    end

                    
                end,90/30)
            end )

        

            
            
        end,90/30)

        waitNode:removeFromParent()
    end,showLinesTime)

    
    
end

-- 红色玩法

function GameScreenLoveShotMachine:playRedCashRush_3_Effect( effectData )
    for i=1,#self.m_cashRushList do
        local cashRush = self.m_cashRushList[i]
        cashRush:runAnim("actionframe",true)
    end

    local winLines = self.m_reelResultLines

    local isUpdata = false

    if #winLines <= 0 then
        isUpdata = true
    end

    for i = 1, #self.m_reelResultLines do
        local lineValue = self.m_reelResultLines[i]
        if
            (lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS or
                lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN) and
                #self.m_reelResultLines == 1 and
                lineValue.lineSymbolRate == 0
         then
            -- 如果只有bonus 和 freespin 连线 那么，直接更新
            isUpdata = true
        end
    end

    if  isUpdata  then

        local winCoins =  0
        local beginCoins = 0
        
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local fsWinCoins =  self.m_runSpinResultData.p_fsWinCoins or 0
            beginCoins = fsWinCoins - self.m_iOnceSpinLastWin
            winCoins = fsWinCoins - beginCoins
        else
            winCoins = self.m_serverWinCoins
        end

        self:updateBottomUICoins( beginCoins,winCoins,true )
    end

    -- 普通多赢了钱直接更新
    effectData.p_isPlay = true
    self:playGameEffect()

end

function GameScreenLoveShotMachine:playRedCashRush_7_Effect( effectData )

    local showLinesTime = 0
    local winLines = self.m_reelResultLines
    if #winLines > 0  then
        showLinesTime = globalData.slotRunData.levelConfigData:getShowLinesTime() or 0
    end

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Trigger.mp3")

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
        -- 取消掉赢钱线的显示
        self:clearWinLineEffect()


        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local rushWin = selfdata.rushWin or "0" -- cashRush赢钱大于零才有可能触发


        for i=1,#self.m_cashRushList do
            local cashRush = self.m_cashRushList[i]
            cashRush:runAnim("actionframe",true)
        end

        performWithDelay(self,function(  )
            if #self.m_cashRushList >= 7 then
                
                self:clearCurMusicBg()
                
                -- 如果 大于7 显示赢jackpot 最多 15 
                self.m_jackPotBar:showJpAct(   - (#self.m_cashRushList - 15) + 1 )

                performWithDelay(self,function(  )

                    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_over_fs.mp3")

                    

                    local view = self:showJpOverView( #self.m_cashRushList, util_formatMoneyStr(rushWin) , function(  )



                            self.m_jackPotBar:hideJpAct( )
                            self.m_jackPotBar:setCashRushVisibleStates( self.m_jackPotBar.JP_RED )
                            
                            local winCoins =  0
                            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                                winCoins = self.m_runSpinResultData.p_fsWinCoins or 0
                            else
                                winCoins = self.m_serverWinCoins
                            end
                            local currCoins = tonumber(rushWin)
                            local beiginCoins = winCoins - currCoins
                            self:updateBottomUICoins( beiginCoins,currCoins,true )

                            self:resetMusicBg(true)

                            effectData.p_isPlay = true
                            self:playGameEffect()


                    end)

                    view:findChild("cashrush_1"):setVisible(false)
                    view:findChild("cashrush_0"):setVisible(true)
   

                end,2)
                

            end
            

        end,72/60)

        waitNode:removeFromParent()

    end,showLinesTime)

    
    
end

function GameScreenLoveShotMachine:showJpOverView( _num, _coins, _func)
    
    

    local ownerlist={}
    ownerlist["m_lb_num"] = _num
    ownerlist["m_lb_coins"] = _coins
    local view = self:showDialog("JackpotOver",ownerlist,_func)

    util_spinePlay(self.m_qiuBiTeMan,"over")
    view:setOverAniRunFunc(function(  )
        util_spinePlay(self.m_qiuBiTeMan,"show")
        util_spineEndCallFunc(self.m_qiuBiTeMan,"show",function(  )
            self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
            util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
        end)

    end)
    
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({ label = node , sx = 1.2 , sy = 1.2}, 457)

    local Node_QiuBiTe = view:findChild("Node_QiuBiTe")
    if Node_QiuBiTe then
        local qiuBiTeMan = util_spineCreate("LoveShot_qiubite",true,true)
        Node_QiuBiTe:addChild(qiuBiTeMan)
        util_spinePlay(qiuBiTeMan,"idleframe1",true)
    end

    local tanban_L = view:findChild("LoveShot_tanban_L")
    if tanban_L then
        local lightBg = util_createAnimation("LoveShot_tanban_L.csb")
        tanban_L:addChild(lightBg)
        lightBg:runCsbAction("actionframe",true)
    end

    util_setCascadeOpacityEnabledRescursion(view,true)

    return view
end

function GameScreenLoveShotMachine:showBonusOverView(_coins,_func)

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_PickBonusOverView.mp3")

    local ownerlist={}
    ownerlist["m_lb_coins"] = _coins
    local view = self:showDialog("BonusOverView",ownerlist,_func)

    util_spinePlay(self.m_qiuBiTeMan,"over")
    view:setOverAniRunFunc(function(  )
        util_spinePlay(self.m_qiuBiTeMan,"show")
        util_spineEndCallFunc(self.m_qiuBiTeMan,"show",function(  )
            self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
            util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
        end)

    end)

    local node_1 =view:findChild("m_lb_coins")
    view:updateLabelSize({ label = node_1 , sx = 1.25 , sy = 1.25}, 420)

    local Node_QiuBiTe = view:findChild("Node_QiuBiTe")
    if Node_QiuBiTe then
        local qiuBiTeMan = util_spineCreate("LoveShot_qiubite",true,true)
        Node_QiuBiTe:addChild(qiuBiTeMan)
        util_spinePlay(qiuBiTeMan,"idleframe1",true)
    end
    

    local tanban_L = view:findChild("LoveShot_tanban_L")
    if tanban_L then
        local lightBg = util_createAnimation("LoveShot_tanban_L.csb")
        tanban_L:addChild(lightBg)
        lightBg:runCsbAction("actionframe",true)
    end
    
    util_setCascadeOpacityEnabledRescursion(view,true)

    return view
end

function GameScreenLoveShotMachine:showPickBonusOverView(_rushNum,_jpCoins,_pickCoins,_func)

    

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_PickBonusOverView.mp3")

    local ownerlist={}
    ownerlist["m_lb_coins_0"] = _jpCoins
    ownerlist["m_lb_coins_1"] = _pickCoins
    ownerlist["m_lb_num"] = _rushNum
    local view = self:showDialog("PickBonusOver",ownerlist,_func)

    util_spinePlay(self.m_qiuBiTeMan,"over")
    view:setOverAniRunFunc(function(  )
        util_spinePlay(self.m_qiuBiTeMan,"show")
        util_spineEndCallFunc(self.m_qiuBiTeMan,"show",function(  )
            self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
            util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
        end)

    end)

    local node_1 =view:findChild("m_lb_coins_0")
    view:updateLabelSize({ label = node_1 , sx = 1.2 , sy = 1.2}, 482)

    local node_2 =view:findChild("m_lb_coins_1")
    view:updateLabelSize({ label = node_2 , sx = 1.2 , sy = 1.2}, 482)

    local Node_QiuBiTe = view:findChild("Node_QiuBiTe")
    if Node_QiuBiTe then
        local qiuBiTeMan = util_spineCreate("LoveShot_qiubite",true,true)
        Node_QiuBiTe:addChild(qiuBiTeMan)
        util_spinePlay(qiuBiTeMan,"idleframe1",true)
    end
    

    local tanban_L = view:findChild("LoveShot_tanban_L")
    if tanban_L then
        local lightBg = util_createAnimation("LoveShot_tanban_L.csb")
        tanban_L:addChild(lightBg)
        lightBg:runCsbAction("actionframe",true)
    end
    
    util_setCascadeOpacityEnabledRescursion(view,true)

    return view
end

function GameScreenLoveShotMachine:showPickBonusStartView( _func )

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_show_PickBonus_view.mp3")
    
    local starView = util_createAnimation("LoveShot/PickBonusStart.csb")
    self:findChild("pickbonusstart"):addChild(starView)

    local tanban_L = starView:findChild("LoveShot_tanban_L")
    if tanban_L then
        local lightBg = util_createAnimation("LoveShot_tanban_L.csb")
        tanban_L:addChild(lightBg)
        lightBg:runCsbAction("actionframe",true)
    end
    
    util_setCascadeOpacityEnabledRescursion(starView,true)

    starView:runCsbAction("actionframe",false,function(  )
        if _func then
            _func()
        end
        starView:removeFromParent()
    end,60)

end


--[[
    +++++++++++++
    respin 玩法
]]

-- 创建飞行粒子
function GameScreenLoveShotMachine:createParticleFly(_time,_symbolNode,func)

    local fly =  util_createAnimation("Socre_LoveShot_CashRush_Lizi.csb")
    self.m_clipParent:addChild(fly,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 1)

    fly:findChild("Particle_1"):setDuration(-1)
    fly:findChild("Particle_1"):setPositionType(0)

    fly:findChild("Particle_2"):setDuration(-1)
    fly:findChild("Particle_2"):setPositionType(0)

    local flyNode =  util_createAnimation("Socre_LoveShot_CashRush_2.csb")
    fly:addChild(flyNode,100)
    flyNode:runCsbAction("fly")
    
    local index =  self:getPosReelIdx(_symbolNode.p_rowIndex, _symbolNode.p_cloumnIndex)

    fly:setPosition(cc.p(util_getOneGameReelsTarSpPos(self,index )))

    local endPos = util_getConvertNodePos(self.m_rsGameBar:findChild("Node_respinCollect") ,fly)

    local animation = {}
    animation[#animation + 1] = cc.MoveTo:create(_time, cc.p(endPos.x,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:findChild("Particle_1"):stopSystem()
        fly:findChild("Particle_2"):stopSystem()
        flyNode:setVisible(false)

        if func then
            func()
        end


    end)
    animation[#animation + 1] = cc.DelayTime:create(1)
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:removeFromParent()

    end)

    fly:runAction(cc.Sequence:create(animation))

    
    
end


function GameScreenLoveShotMachine:playGoldFullReelEffect( effectData )
    performWithDelay(self,function(  )
        self:clearCurMusicBg()

        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_rs_over_view.mp3")

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local rushPositions = selfdata.rushPositions or {}
        local rushNum = #rushPositions
        local strCoins=util_formatCoins(self.m_serverWinCoins,50)

        local view=self:showJpOverView(rushNum,strCoins,function()
    
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins ,true,true})
            globalData.slotRunData.lastWinCoin = lastWinCoin

            if effectData then
                effectData.p_isPlay = true
                self:playGameEffect()
            end
            
            self:resetMusicBg() 

        end)
        view:findChild("cashrush_1"):setVisible(true)
        view:findChild("cashrush_0"):setVisible(false)
    
    end,0.5)

end

function GameScreenLoveShotMachine:playAddRespinTimesEffect(effectData )

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_rs_addTime_fly.mp3")

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolNode = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if symbolNode then
                if symbolNode.p_symbolType == self.SYMBOL_RESPIN_ADD_TIMES then
                    symbolNode:runAnim("actionframe")

                    local symbolWaitNode = cc.Node:create()
                    self:addChild(symbolWaitNode)
                    performWithDelay(symbolWaitNode,function(  )
        
                        self:createParticleFly(0.5,symbolNode)

                        symbolWaitNode:removeFromParent()
                    end,30/60)

                    
                end
            end
        end
    end

    local addTimesWaitNode = cc.Node:create()
    self:addChild(addTimesWaitNode)
    performWithDelay(addTimesWaitNode,function(  )
        
        self.m_rsGameBar:runCsbAction("addspin")
        local reSpinCurCount =  self.m_runSpinResultData.p_reSpinCurCount or 0
        self:changeReSpinUpdateUI(reSpinCurCount)

        effectData.p_isPlay = true
        self:playGameEffect()

        addTimesWaitNode:removeFromParent()
    end,60/60)
    

end

function GameScreenLoveShotMachine:checkSymbolPosIsLocked(_posIndex )
    local lockNode = self.m_RsLockRushNode:getChildByTag(_posIndex)
    if lockNode then
        return true
    end

    return false

end

function GameScreenLoveShotMachine:checkAddRespinLock( )
    
    local isAdd = false
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rushPositions = selfdata.rushPositions or {}

    for i=1,#rushPositions do
        local pos = rushPositions[i]
        local lockNode = self.m_RsLockRushNode:getChildByTag(pos)
        if not lockNode then
            isAdd = true
            break
        end
    end

    
    return isAdd

end

function GameScreenLoveShotMachine:playRespinLockRushEffect(effectData )
    
    
    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Lock.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rushPositions = selfdata.rushPositions or {}
    local addList = {}
    for i=1,#rushPositions do

        local pos = rushPositions[i]

        local lockNode = self.m_RsLockRushNode:getChildByTag(pos)
        if not lockNode then

            self:createOneReSpinLockNode(pos )

            lockNode = self.m_RsLockRushNode:getChildByTag(pos)
            util_spinePlay(lockNode,"idleframe")
            local suo = lockNode:getChildByName("purpleLock")
            if suo then
                suo:setVisible(true)
                suo:runCsbAction("actionframe") --锁定动画 90/60
            end
        end

    end

    performWithDelay(self,function(  )

    
        self:setRsGameBarCashRushNum( )

        effectData.p_isPlay = true
        self:playGameEffect()

    end,93/60)
    
    
end

function GameScreenLoveShotMachine:showGoldRushStartView( _func )
    

    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount or 0
    if reSpinsTotalCount > 3 then
        -- 如果大于3，那么
        if _func then
            _func()
        end

        return 
    end

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_show_PickBonus_view.mp3")

    local moreView = util_createAnimation("LoveShot/GoldRushStart.csb")
    self:findChild("goldrushstart"):addChild(moreView)

    moreView:runCsbAction("actionframe",false,function(  )
        if _func then
            _func()
        end
        moreView:removeFromParent()
    end,60)


    local tanban_L = moreView:findChild("LoveShot_tanban_L")
    if tanban_L then
        local lightBg = util_createAnimation("LoveShot_tanban_L.csb")
        tanban_L:addChild(lightBg)
        lightBg:runCsbAction("actionframe",true)
    end

    
    util_setCascadeOpacityEnabledRescursion(moreView,true)

end

function GameScreenLoveShotMachine:createOneReSpinLockNode(_posIndex )

    local wildSpr = util_spineCreate("Socre_LoveShot_CashRush_3",true,true)
    self.m_RsLockRushNode:addChild(wildSpr)
    wildSpr:setPosition(util_getOneGameReelsTarSpPos(self,_posIndex))
    wildSpr:setTag(_posIndex)
    util_spinePlay(wildSpr,"actionframe")
    local LockNode = self:createCashRushLockNode( wildSpr  ) 
    LockNode:runCsbAction("idleframe")
    LockNode:setVisible(false)

end

function GameScreenLoveShotMachine:initReSpinLockNode(  )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rushPositions = selfdata.rushPositions or {}

    for i=1,#rushPositions do
        local pos = rushPositions[i]
        self:createOneReSpinLockNode(pos )
    end

end

function GameScreenLoveShotMachine:setRsGameBarCashRushNum( )
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rushPositions = selfdata.rushPositions or {}
    local rushNum = #rushPositions
    self.m_rsGameBar:updateCashRushNum( rushNum )
    self.m_rsGameBar:runCsbAction("respingameollect")
    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_zuanShi_num_Update.mp3")
    if rushNum >= 7 then
        self.m_jackPotBar:showJpAct(   - (rushNum - 15) + 1 )
    end
    

end

------------  respin 代码 这个respin就是不是单个小格滚动的那种 

function GameScreenLoveShotMachine:showRespinView(effectData)
    

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Trigger.mp3")

    --触发respin
    --先播放动画 再进入respin

    self:clearCurMusicBg()
     
    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = false

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    self:changeReSpinStartUI()

    -- 创建固定住的块
    self:initReSpinLockNode(  )

    self:setAllCashSymbolVisible( false )

    self:setRsGameBarCashRushNum( )
    
    performWithDelay(self,function(  )
       
        self:changeMainUI( self.ReSpin_STATES )

        self:showYuGaoViewBg( )

        self.m_jackPotBar:changeCashRushAct(self.m_jackPotBar.JP_GOLD)

        self:showGoldRushStartView( function(  )
            
            
            local allLockRushs = self.m_RsLockRushNode:getChildren()

            gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Lock.mp3")

            for i=1,#allLockRushs do
                local node = allLockRushs[i]
                if node then
                    local suo = node:getChildByName("purpleLock")
                    if suo then
                        suo:setVisible(true)
                        suo:runCsbAction("actionframe") --锁定动画 90/30
                    end
                end
            end

            
            performWithDelay(self,function(  )

                self:resetMusicBg(true)

                self:setAllCashSymbolVisible( true )

                effectData.p_isPlay = true
                self:playGameEffect()
            end,90/30)

        end  )

       
        
    end,90/30)

    

end



--接收到数据开始停止滚动
function GameScreenLoveShotMachine:stopRespinRun()
    print("已经得到了数据")
end

--ReSpin开始改变UI状态
function GameScreenLoveShotMachine:changeReSpinStartUI(respinCount)

    local respinCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_rsGameBar:updateRespinCount( respinCount,reSpinsTotalCount )

end

--ReSpin刷新数量
function GameScreenLoveShotMachine:changeReSpinUpdateUI(_reSpinCurCount)

    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_rsGameBar:updateRespinCount( _reSpinCurCount,reSpinsTotalCount )

end

--ReSpin结算改变UI状态
function GameScreenLoveShotMachine:changeReSpinOverUI()

end

function GameScreenLoveShotMachine:setAllCashSymbolVisible( _states )

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local node = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG) 
            if node then
                if self:checkCashSymbol(node.p_symbolType) then
                    node:setVisible(_states)
                end
            end
        end
    end
end

function GameScreenLoveShotMachine:showRespinOverCollectAni(_func )
    local childs = self.m_RsLockRushNode:getChildren()

    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_CashRush_Trigger.mp3")

    for i=1,#childs do
        local lockNode = childs[i]
        util_spinePlay(lockNode,"actionframe")
    end
    
    self:setAllCashSymbolVisible( false )

    performWithDelay(self,function(  )

        if #childs >= 7 then
            -- 如果 大于7 显示赢jackpot 最多 15 
            self.m_jackPotBar:showJpAct(   - (#childs - 15) + 1 )

            performWithDelay(self,function(  ) 

                if _func then
                    _func()
                end

            end , 2)
        else
            if _func then
                _func()
            end
        end
        
        
    end,72/60)
end

function GameScreenLoveShotMachine:showRespinOverView(effectData)

    
    performWithDelay(self,function(  )
        self:clearCurMusicBg()

        self:showRespinOverCollectAni(function(  )
    
            gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_rs_over_view.mp3")
    
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            local rushPositions = selfdata.rushPositions or {}
            local rushNum = #rushPositions
            local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    
            local view=self:showJpOverView(rushNum,strCoins,function()
        
    
                    self:hideYuGaoViewBg( )
    
                    self:setAllCashSymbolVisible( true )
    
                    self.m_jackPotBar:hideJpAct( )
                    self.m_jackPotBar:setCashRushVisibleStates( self.m_jackPotBar.JP_RED )
    
                    if self.m_bProduceSlots_InFreeSpin then
                        self:changeMainUI( self.FREE_STATES )
    
                    else
                        self:changeMainUI( self.BASE_STATES )
                    end
    
                    self.m_RsLockRushNode:removeAllChildren()
    
                    if effectData then
                        effectData.p_isPlay = true
                    end
                   
    
                    self:resetMusicBg() 
    
                    self:triggerReSpinOverCallFun(0)
                    
    
                
            end)
            view:findChild("cashrush_1"):setVisible(true)
            view:findChild("cashrush_0"):setVisible(false)
    
        end )
    
    end,0.5)

   

   
end




function GameScreenLoveShotMachine:MachineRule_respinTouchSpinBntCallBack()
    
    if globalData.slotRunData.gameSpinStage == IDLE and self:getCurrSpinMode()== RESPIN_MODE then 
        -- 处于等待中， 并且free spin 那么提前结束倒计时开始执行spin

        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
        release_print("btnTouchEnd 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
    else
        if self.m_bIsAuto == false then
            gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
            release_print("btnTouchEnd m_bIsAuto == false 触发了 spin touch " .. xcyy.SlotsUtil:getMilliSeconds())
        end
    end 

    if globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN  then  -- 表明滚动了起来。。
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_QUICK_STOP)
    end
end

--[[
    +++++++++++++
    地图 玩法
]]

function GameScreenLoveShotMachine:checkShopShouldClick( )

    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    -- 返回true 不允许点击

    if self.m_isWaitingNetworkData  then
        return true

    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return true

    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return true

    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return true

    elseif reSpinCurCount and reSpinCurCount and reSpinCurCount > 0 and reSpinsTotalCount > 0 then

        return true

    elseif #featureDatas > 1 then
        return true

    elseif self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return true

    elseif self.m_MapView:isVisible() then
        return true

    elseif self.m_BonusClickView:isVisible() then
        return true

    elseif self.m_bSlotRunning == true then

        return

    end

    
    return false
end


--[[
    +++++++++++++
    freespin 丘比特bonus 射箭
]]

function GameScreenLoveShotMachine:createBonusTrail(_bonusIndex,_replaceIndex ,_func)
    
    local startPos = util_getOneGameReelsTarSpPos(self,_bonusIndex )
    local endPos = util_getOneGameReelsTarSpPos(self,_replaceIndex )
    endPos = cc.p(endPos.x + 25,endPos.y - 25)
    local trail = util_createAnimation("LoveShot_Bonus_trail.csb") 
    self.m_clipParent:addChild(trail,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)
    trail:setPosition(cc.p(startPos))

    local angle = util_getAngleByPos(startPos,endPos) 
    trail:findChild("Node_24"):setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    trail:findChild("Node_24"):setScaleX(scaleSize / 500 )

    trail:runCsbAction("actionframe",false,function(  )
        trail:stopAllActions()
        trail:removeFromParent()

    end,60)

    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        if _func then
            _func()
        end

    end,0.5)
    

   
end

function GameScreenLoveShotMachine:changeReelNode(_symbolNode,_replaceSignal,_replaceIndex,_changefunc  )

    local endPos = util_getOneGameReelsTarSpPos(self,_replaceIndex )

    local changeSymbol = _symbolNode

    local Heart_L2 = util_createAnimation("Socre_LoveShot_Heart_L2_switch.csb") 
    self.m_clipParent:addChild(Heart_L2,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)
    Heart_L2:setPosition(cc.p(endPos))
    Heart_L2:runCsbAction("actionframe",false,function(  )
        Heart_L2:removeFromParent()
    end,60)

    local Heart_L1 = util_createAnimation("Socre_LoveShot_Heart_L1.csb") 
    self.m_clipParent:addChild(Heart_L1,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 2)
    Heart_L1:setPosition(cc.p(endPos.x + 25,endPos.y - 25))
    Heart_L1:runCsbAction("actionframe",false,function(  )
        Heart_L1:removeFromParent()
    end,60)
    local waitNode_changeReelNode = cc.Node:create()
    self:addChild(waitNode_changeReelNode)
    performWithDelay(waitNode_changeReelNode,function(  )

        if changeSymbol.p_symbolImage ~= nil and changeSymbol.p_symbolImage:getParent() ~= nil then
            changeSymbol.p_symbolImage:removeFromParent()
        end
        changeSymbol.p_symbolImage = nil
        changeSymbol.m_ccbName = ""

        changeSymbol:changeCCBByName(self:getSymbolCCBNameByType(self, _replaceSignal), _replaceSignal)

        local symbolCorner = changeSymbol:getChildByName("symbolCorner")
        if symbolCorner then
            symbolCorner:removeFromParent()
        end
        
        if _changefunc then
            _changefunc()
        end

        waitNode_changeReelNode:removeFromParent()
    end,0.25)


end

function GameScreenLoveShotMachine:playFreeSpinShotEffect( effectData )

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusPositions = selfdata.bonusPositions or   {}
    local replacePositions = selfdata.replacePositions  or  {}
    local replaceSignal = selfdata.replaceSignal or 1

    if #bonusPositions > 0  then

        gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_QiuBiTe_SheJian_Fs.mp3")

        self:showColorLayer()

        local fixPos = self:getRowAndColByPos(bonusPositions[1])

        local targSp =  self:getFixSymbol(fixPos.iY,fixPos.iX, SYMBOL_NODE_TAG)
        
        targSp = util_setSymbolToClipReel(self,fixPos.iY, fixPos.iX, targSp.p_symbolType,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
        targSp:setTag( self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_FIX_NODE_TAG) ) -- 设置悬浮小块参与连线
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        local linePos = {}
        linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
        targSp:setLinePos(linePos)
        local symbolCornerAniTime = 30/60
        local waitNode_1 = cc.Node:create()
        self:addChild(waitNode_1)
        performWithDelay(self,function(  )
            targSp:runAnim("actionframe")
        end,symbolCornerAniTime) 
        
        
        for i=1,#replacePositions do

            local replaceIndex = replacePositions[i]

            local replaceFixPos = self:getRowAndColByPos(replaceIndex)

            local replaceTargSp =  self:getFixSymbol(replaceFixPos.iY,replaceFixPos.iX, SYMBOL_NODE_TAG)
            replaceTargSp = util_setSymbolToClipReel(self,replaceFixPos.iY, replaceFixPos.iX, replaceTargSp.p_symbolType,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1 )
            replaceTargSp:setTag(self:getNodeTag(fixPos.iY, fixPos.iX, SYMBOL_FIX_NODE_TAG)) -- 设置悬浮小块参与连线
            replaceTargSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            local linePos = {}
            linePos[#linePos + 1] = {iX = replaceFixPos.iX, iY = replaceFixPos.iY}
            replaceTargSp:setLinePos(linePos)
            self:addSymbolCorner( replaceTargSp )
        
            local symbolCorner = replaceTargSp:getChildByName("symbolCorner")
            if symbolCorner then
                symbolCorner:runCsbAction("actionframe") -- 播放时间 90 fps 60
            end


            local waitNode = cc.Node:create()
            self:addChild(waitNode) 
            performWithDelay(waitNode,function(  )  

                local createBonusAni = nil

                if i == #replacePositions then
                    
                    createBonusAni = function(  )

                        -- bonus本身 的效果
                        self:createBonusTrail(bonusPositions[1],bonusPositions[1] ,function(  )

                            self:changeReelNode(targSp,replaceSignal,bonusPositions[1] ,function(  )
                                self:hideColorLayer()

                                local waitNode_shotOver = cc.Node:create()
                                self:addChild(waitNode_shotOver)
                                performWithDelay(waitNode_shotOver,function(  )

                                    if effectData then
                                        effectData.p_isPlay = true
                                        self:playGameEffect() 
                                    end

                                    waitNode_shotOver:removeFromParent()
                                end,1)
                            end )

                        end ) 
                            
                    end
                    
                end


                local replaceTargSp_1 = replaceTargSp
                self:createBonusTrail(bonusPositions[1],replaceIndex ,function(  )

                    self:changeReelNode(replaceTargSp_1,replaceSignal,replaceIndex)

                end ) 


                if createBonusAni then
                    createBonusAni()
                end



            end,(27/30) + symbolCornerAniTime)

        end
        
    end
   
end

--[[
    +++++++++++++
    bonusGame 地图玩法

]]

function GameScreenLoveShotMachine:showMapGuoChang(_func )
    
    self.m_bonusMapGuoChang:setVisible(true)
    self.m_bonusMapGuoChang:runCsbAction("actionframe",false,function(  )

        self.m_bonusMapGuoChang:setVisible(false)


    end,60)

    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )

        if _func then
            _func()
        end

        waitNode:removeFromParent()

    end,1)
    

end

function GameScreenLoveShotMachine:showMapFromBarClick( )
    if self.m_bonusPosition then
        self.m_MapView:updateLittleUINodeAct( self.m_bonusPosition)

        self:clearCurMusicBg()
        self:resetMusicBg(nil,"LoveShotSounds/music_LoveShot_mapGameBG.mp3")

        self.m_MapView:findChild("back"):setEnabled(true)
        self.m_MapView:showMap( )
    end
end

---
-- 显示bonus 触发的小游戏
function GameScreenLoveShotMachine:showEffect_Bonus(effectData)
    local time = self:getWinCoinTime()
    performWithDelay(self,function()
        BaseNewReelMachine.showEffect_Bonus(self,effectData)
    end,time)
    
    return true
end

function GameScreenLoveShotMachine:showBonusGameView(effectData)


    self.m_baseLoadingBar:runCsbAction("actionframe2",false,function(  )
        self.m_baseLoadingBar:runCsbAction("idleframe",true)
    end,60)
    self.m_baseLoadingBar.m_heart:runCsbAction("actionframe",false,function(  )
        self.m_baseLoadingBar.m_heart:runCsbAction("idleframe",true)
    end,60)
    
    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_rush_CollectGame_Trigger.mp3")

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        self:showMapGuoChang(function(  )

            

            self.m_bottomUI:showAverageBet()

            self.m_MapView:updateLittleUINodeAct(self.m_bonusPosition)
            self.m_MapView:findChild("back"):setEnabled(false)

            self:clearCurMusicBg()
            self:resetMusicBg(nil,"LoveShotSounds/music_LoveShot_mapGameBG.mp3")

            self.m_MapView:showMap( true)
    
        end )
    
        
        self.m_BonusGameOverCall = function(  )
    
    
            self.m_baseLoadingBar:resetProgress() 

            self:showBonusOverView(util_formatCoins( self.m_serverWinCoins , 50),function(  )
                
                self.m_bottomUI:hideAverageBet()
                 -- 更新游戏内每日任务进度条
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_serverWinCoins ,true,true})
                globalData.slotRunData.lastWinCoin = lastWinCoin

                -- 通知bonus 结束， 以及赢钱多少
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_serverWinCoins, GameEffect.EFFECT_BONUS})
        
                
                effectData.p_isPlay = true
                self:playGameEffect()
        
                self.m_BonusGameOverCall = nil

            end)

            
        end

        waitNode:removeFromParent()
    end,0.5)

    



    

end

--[[
    ***************
    收集 宫殿点击玩法
--]]
function GameScreenLoveShotMachine:triggerBonusClickGame( )

    

    self.m_BonusClickView:showBonusClickMainView(  function(  )

        

        if self.m_BonusGameOverCall then
            self.m_BonusGameOverCall()
        end
        
    end )

    

   
end


function GameScreenLoveShotMachine:showBonusClickGameGuoChang(_func,_funcEnd ,_funcEnd2)
    
    gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_qiQiu_guochang.mp3")


    util_spinePlay(self.m_qiuBiTeMan,"over")
    util_spineEndCallFunc(self.m_qiuBiTeMan,"over",function(  )
       
        self.m_bonusClickGuoChang:setVisible(true)
        util_spinePlay(self.m_bonusClickGuoChang,"actionframe",false)
        util_spineEndCallFunc(self.m_bonusClickGuoChang,"actionframe",function(  )

            if _funcEnd then
                _funcEnd()
            end
            util_spinePlay(self.m_qiuBiTeMan,"show")
            util_spineEndCallFunc(self.m_qiuBiTeMan,"show",function(  )

                if _funcEnd2 then
                    _funcEnd2()
                end

                self.m_qiuBiTeMan.m_manStates = self.QIUBITE_IDLE_STATES
                util_spinePlay(self.m_qiuBiTeMan,"idleframe",true)
            end)

            self.m_bonusClickGuoChang:setVisible(false)
        end)


        local waitNode_1 = cc.Node:create()
        self:addChild(waitNode_1)
        performWithDelay(waitNode_1,function(  )


            if _func then
                _func()
            end

            waitNode_1:removeFromParent()

        end,30/30)

    end)

    

end


--[[
    ***************    
    处理特殊游戏赢钱
--]]

function GameScreenLoveShotMachine:getRushWinCoins( )
    
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local rushWin = selfdata.rushWin or "0" -- cashRush赢钱大于零才有可能触发
    local pointsWin = selfdata.pointsWin or "0" --紫色盒子对应点数赢钱
    local coins = 0
    if rushWin ~= "0" then
        if self.m_cashRushList and #self.m_cashRushList > 0 then
            local rushNode = self.m_cashRushList[1]
            if rushNode.p_symbolType == self.SYMBOL_RAIP_RED then
                if #self.m_cashRushList >= 3 then
                    if  #self.m_cashRushList >= 7 then
                        coins = tonumber(rushWin)
                    else
                        coins = 0
                    end
                end

            elseif rushNode.p_symbolType == self.SYMBOL_RAIP_PURPLE then
                   
                if #self.m_cashRushList >= 3 then
                    coins = tonumber(rushWin) + tonumber(pointsWin)
                end

            else
                coins = tonumber(rushWin)
            end
        end

    end

    return coins
end



function GameScreenLoveShotMachine:checkIsAddLastWinSomeEffect( )
    
    local notAdd  = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end


    
    if self.m_cashRushList and #self.m_cashRushList > 0 then
        local rushNode = self.m_cashRushList[1]
        if rushNode.p_symbolType == self.SYMBOL_RAIP_RED then
            if #self.m_cashRushList >= 3 then
                notAdd = false
            end
    
        elseif rushNode.p_symbolType == self.SYMBOL_RAIP_PURPLE then
            if #self.m_cashRushList >= 3 then
                notAdd = false
            end
        end

    end
    
    if self:getCurrSpinMode() ~= RESPIN_MODE then

        if self:checkAddGoldFullReelEffect( )then

            notAdd = false
            
        end

    end

    return notAdd
end

function GameScreenLoveShotMachine:updateBottomUICoins( beiginCoins,currCoins,isNotifyUpdateTop )

    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local endCoins = beiginCoins + currCoins
    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{endCoins,isNotifyUpdateTop,nil,beiginCoins})
    globalData.slotRunData.lastWinCoin = lastWinCoin
    
    
end

function GameScreenLoveShotMachine:checkNotifyUpdateWinCoin( )

    
    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
    local specialCoins = 0
    local coins = 0
    local beiginCoins = nil

    if isNotifyUpdateTop then

        beiginCoins =  nil
        specialCoins =  self:getRushWinCoins()
        coins =  self.m_iOnceSpinLastWin - specialCoins
        
        if specialCoins > 0 then
            -- bonus在更新左上
            isNotifyUpdateTop = false
        end
        
    else

        specialCoins =  self:getRushWinCoins()
        coins =  fsWinCoin - specialCoins
        beiginCoins = fsWinCoin - self.m_iOnceSpinLastWin
    end


    local lastWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,isNotifyUpdateTop,nil,beiginCoins})
    globalData.slotRunData.lastWinCoin = lastWinCoin
end

--[[
    *********************
    滚动轮遮罩   

--]]

function GameScreenLoveShotMachine:showColorLayer( )
    for i=1,5 do

        self["m_colorLayer_waitNode_"..i]:stopAllActions()

        local layerNode = self["colorLayer_"..i]

        util_playFadeInAction(layerNode,0.1)
        layerNode:setVisible(true)
    end
end

function GameScreenLoveShotMachine:hideColorLayer( )
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

function GameScreenLoveShotMachine:initReelMask( )
    
    local slotW = 0
    local slotH = 0
    local lMax = util_max


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
        
        slotH = lMax(slotH, reelSize.height)

        local node = cc.Node:create()
        parentData.slotParentBig:getParent():addChild(node,1) -- 高于 clipNodeBig zorder

        local slotParentNode_1 = cc.LayerColor:create(cc.c3b(0, 0, 0)) 
        slotParentNode_1:setOpacity(200)
        slotParentNode_1:setContentSize(reelSize.width, reelSize.height+ 5)
        if i < self.m_iReelColumnNum then
            slotParentNode_1:setContentSize(reelSize.width + 5, reelSize.height+ 5)
        end
        slotParentNode_1:setPositionX(reelSize.width * 0.5)
        node:addChild(slotParentNode_1)

        self["colorLayer_"..i] = node
        node:setVisible(false)

    end

end

function GameScreenLoveShotMachine:hideShotRunEffect( )
    self.m_fsShotRunEffect:setVisible(false)
    
    if self.m_triggerBonusSoundId  then
        gLobalSoundManager:stopAudio(self.m_triggerBonusSoundId)
        self.m_triggerBonusSoundId = nil
    end
end

---
--  处理第5列显示快滚特效
function GameScreenLoveShotMachine:showShotRunEffect( reelCol  )

    if self.m_triggerFsShot == true then

        self.m_triggerFsShot = false

        if  self:getGameSpinStage() ~= QUICK_RUN  then
            if reelCol == 1 then

                if self.m_triggerBonusSoundId  then
                    gLobalSoundManager:stopAudio(self.m_triggerBonusSoundId)
                    self.m_triggerBonusSoundId = nil
                end

                self.m_triggerBonusSoundId = gLobalSoundManager:playSound("LoveShotSounds/LoveShotSounds_longRun.mp3")

                self.m_fsShotRunEffect:setVisible(true)
                self.m_fsShotRunEffect:runCsbAction("run",true)
    
            end
        end
    end
    
end

function GameScreenLoveShotMachine:changeReelNodeFromData( reelData )

    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp =  self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp  then

                local symbolType = reelData[iCol][iRow]
                if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                    targSp.p_symbolImage:removeFromParent()
                end
                targSp.p_symbolImage = nil
                targSp.m_ccbName = ""
            
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                targSp:setLocalZOrder( self:getBounsScatterDataZorder( symbolType ) - targSp.p_rowIndex )

            end
        end
    end

end

function GameScreenLoveShotMachine:getWinCoinTime()

    local showTime = BaseNewReelMachine.getWinCoinTime(self)
    
    if showTime > 0 then

        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local bonusPositions = selfdata.bonusPositions or {}
        local replacePositions = selfdata.replacePositions or {}
        
        
        if #bonusPositions > 0 and #replacePositions > 0 then

            showTime = globalData.slotRunData.levelConfigData:getShowLinesTime()
            
        end

        
    end
    

    return showTime
end

-- 高低bet玩法

function GameScreenLoveShotMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        self.m_BetChooseGear = self.m_specialBets[1].p_totalBetValue
    end
    local betCoin = globalData.slotRunData:getCurTotalBet()
    if  betCoin == nil or betCoin >= self.m_BetChooseGear then
        self.m_iBetLevel = 1
    else
        self.m_iBetLevel = 0
    end

    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 1
    end
end

function GameScreenLoveShotMachine:unlockHigherBet()
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
    -- gLobalSoundManager:playSound("LoveShotSounds/LoveShot_JinDuTiao_unlock.mp3")

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function GameScreenLoveShotMachine:netBackUpdateReelDatas( )

    local slotsParents = self.m_slotParents

    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

    end
end

function GameScreenLoveShotMachine:notifyClearBottomWinCoin()
    if not self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    else
        local isClearWin = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN,isClearWin)
    end
        -- 不在区分是不是在 freespin下了 2019-05-08 20:56:44


end


---
--判断改变freespin的状态
function GameScreenLoveShotMachine:changeFreeSpinModeStatus()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then

        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                local features = self.m_runSpinResultData.p_features or {}

                if #features == 2 and features[2] == RESPIN_MODE then
                    print("freespinn最后一次触发respin，先不添加freespinover游戏事件")
                else
                    self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER 
                end

                
            end
        end

    end

    -- freespinn最后一次触发respin，添加freespinover游戏事件
    if self:getCurrSpinMode() == RESPIN_MODE then

        if self.m_bProduceSlots_InFreeSpin then
            local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
            local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount or 0            
            local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount or 0
            if freeSpinsTotalCount > 0 then
                if freeSpinsLeftCount == 0 then
                    if reSpinsTotalCount > 0 then
                        if reSpinCurCount == 0 then
                            self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER 
                        end
                    end
                   
                end
                
            end
        end
    end
    

    --判断是否进入fs
    local bHasFsEffect = self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN)

    --如果有fs
    if bHasFsEffect then
        if self.m_bProduceSlots_InFreeSpin == false then
            self.m_bProduceSlots_InFreeSpin = true
        end
    end

end

function GameScreenLoveShotMachine:checkTriggerFsOver( )
    
    if self.m_initSpinData.p_freeSpinsLeftCount == 0 then

        local reSpinCurCount = self.m_initSpinData.p_reSpinCurCount or 0
        local reSpinsTotalCount = self.m_initSpinData.p_reSpinsTotalCount or 0

        if reSpinsTotalCount > 0 then

            return false

        end

        return true

    end

    return false
end

function GameScreenLoveShotMachine:initSlotNodesExcludeOneSymbolType( symbolType ,colIndex,reelDatas  )
    
    
    if symbolType == self.SYMBOL_RESPIN_ADD_TIMES then
        symbolType = self.SYMBOL_SCORE_10
    end
   

    return symbolType
end

return GameScreenLoveShotMachine






