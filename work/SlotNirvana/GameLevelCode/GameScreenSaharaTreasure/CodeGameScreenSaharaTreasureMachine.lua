---
-- island li
-- 2019年1月26日
-- CodeGameScreenSaharaTreasureMachine.lua
-- 
-- 玩法：
-- 

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenSaharaTreasureMachine = class("CodeGameScreenSaharaTreasureMachine", BaseNewReelMachine)

CodeGameScreenSaharaTreasureMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenSaharaTreasureMachine.SYMBOL_CASH_RUSH = 101  -- 自定义的小块类型
CodeGameScreenSaharaTreasureMachine.SYMBOL_SCORE_10 = 9  -- 自定义的小块类型
CodeGameScreenSaharaTreasureMachine.SYMBOL_SCORE_11 = 10  -- 自定义的小块类型

CodeGameScreenSaharaTreasureMachine.CASH_RUSH_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识

CodeGameScreenSaharaTreasureMachine.m_nomalRowNum = 3
CodeGameScreenSaharaTreasureMachine.m_riseReelFlag = nil
CodeGameScreenSaharaTreasureMachine.m_netDataCallFlag = nil

local FREESPIN_REEL_ROWS = 
{
    {4, 3, 4, 3, 4},
    {4, 4, 5, 4, 4},
    {5, 5, 5, 4, 5},
    {6, 4, 6, 4, 6},
    {5, 6, 6, 6, 5},
    {6, 6, 5, 6, 6}
}

-- 构造函数
function CodeGameScreenSaharaTreasureMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    
	--init
	self:initGame()
end

function CodeGameScreenSaharaTreasureMachine:initGame()

	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenSaharaTreasureMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "SaharaTreasure"  
end




function CodeGameScreenSaharaTreasureMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar

    -- 创建view节点方式
    -- self.m_SaharaTreasureView = util_createView("CodeSaharaTreasureSrc.SaharaTreasureView")
    -- self:findChild("xxxx"):addChild(self.m_SaharaTreasureView)

    self.m_jackpotBar = util_createView("CodeSaharaTreasureSrc.SaharaTreasureJackPotBarView")
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:initMachine(self)

    local logo = util_createAnimation("SaharaTreasure_logo.csb")
    self:findChild("logo"):addChild(logo)
    logo:playAction("idle", true)
 
    self.m_vecShades = {}
    for i = 1, self.m_iReelColumnNum, 1 do
        local shade = util_createAnimation("SaharaTreasure_reel_zhezhao.csb")
        local parent = self:findChild("shade_"..i)
        local pos = parent:getParent():convertToWorldSpace(cc.p(parent:getPosition()))
        pos = self.m_slotEffectLayer:convertToNodeSpace(pos)

        self.m_slotEffectLayer:addChild(shade, 1)
        shade:setPosition(pos)
        shade:playAction("actionframe", true)
        self.m_vecShades[i] = shade
    end

    self.m_nodeTitle = util_createAnimation("SaharaTreasure_FS_wenzi.csb")
    self:findChild("fs_cishu_wenzi"):addChild(self.m_nodeTitle)
    self.m_nodeTitle:playAction("idleframe", true)
    -- self.m_nodeTitle:setScale(0.8)
    -- self.m_nodeTitle:setPositionY(13)

    self.m_freeSpinBar = util_createView("CodeSaharaTreasureSrc.SaharaTreasureFreespinBarView")
    self:findChild("fs_cishu_wenzi"):addChild(self.m_freeSpinBar)
    self.m_freeSpinBar:setVisible(false)

    self.m_vecUpEffect = {}
    local vecPos = {-265, -133, 0, 133, 265}
    for i = 1, self.m_iReelColumnNum, 1 do
        local effect = util_createAnimation("SaharaTreasure/GameScreenSaharaTreasure_up.csb")
        self:findChild("up"):addChild(effect)
        self:findChild("up"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        effect:setPositionX(vecPos[i])
        effect:setVisible(false)
        self.m_vecUpEffect[i] = effect
    end
    

    util_csbScale(self.m_gameBg.m_csbNode, self.m_machineRootScale)

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
        elseif winRate > 3  then
            soundIndex = 3
        end

        gLobalSoundManager:setBackgroundMusicVolume(0.4)
        local soundName = "SaharaTreasureSounds/sound_SaharaTreasure_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId =gLobalSoundManager:playSound(soundName,false, function(  )
            -- gLobalSoundManager:setBackgroundMusicVolume(1)
        end)
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    self:runCsbAction("idle1")

    self:setReelRunSound("SaharaTreasureSounds/sound_SaharaTreasure_quick_run.mp3")
    
end

function CodeGameScreenSaharaTreasureMachine:setScatterDownScound( )
    for i = 1, 3 do
        local soundPath = "SaharaTreasureSounds/sound_SaharaTreasure_scatter_down_"..i..".mp3"
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenSaharaTreasureMachine:enterGamePlayMusic(  )
    if not self.isInBonus then
        scheduler.performWithDelayGlobal(function(  )
            
            gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_enter_game.mp3")
            scheduler.performWithDelayGlobal(function (  )
                
                self:resetMusicBg()
                self:setMinMusicBGVolume( )
                
            end,2.5,self:getModuleName())

        end,0.4,self:getModuleName())
    end
end

function CodeGameScreenSaharaTreasureMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenSaharaTreasureMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

end

function CodeGameScreenSaharaTreasureMachine:onExit()
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
function CodeGameScreenSaharaTreasureMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_CASH_RUSH then
        return "Socre_SaharaTreasure_CASHRUSH"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_SaharaTreasure_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_SaharaTreasure_11"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenSaharaTreasureMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenSaharaTreasureMachine:MachineRule_initGame(  )
    if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
        self.isInBonus = true
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenSaharaTreasureMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol) 
    
    local vecRows = self.m_runSpinResultData.p_selfMakeData.showRows
    
    for iRow = 1, self.m_iReelRowNum, 1 do
        if iRow <= vecRows[reelCol] and self.m_stcValidSymbolMatrix[iRow][reelCol] == self.SYMBOL_CASH_RUSH then
            local cash = self:getFixSymbol(reelCol, iRow)
            -- self:changeToMaskLayerSlotNode(cash)
            cash:runAnim("buling2")

            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( reelCol,"SaharaTreasureSounds/sound_SaharaTreasure_rapid.mp3" )
            else
                gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_rapid.mp3")
            end

        else
            local node = self:getFixSymbol(reelCol, iRow)
            node:runAnim("idleframe")
        end
    end
    
end

function CodeGameScreenSaharaTreasureMachine:slotReelDown()
    BaseNewReelMachine.slotReelDown(self)

    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end

function CodeGameScreenSaharaTreasureMachine:playEffectNotifyNextSpinCall()
    BaseNewReelMachine.playEffectNotifyNextSpinCall(self) 

    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end

function CodeGameScreenSaharaTreasureMachine:initFsUI()
    self.m_freeSpinBar:setVisible(true)
    self.m_nodeTitle:setVisible(false)
    self.m_freeSpinBar:changeFreeSpinByCount()

    local vecRows = self.m_runSpinResultData.p_selfMakeData.showRows
    if self.m_runSpinResultData.p_selfMakeData.choose ~= nil and self.m_runSpinResultData.p_selfMakeData.choose.freeType ~= nil then
        local result = tonumber(self.m_runSpinResultData.p_selfMakeData.choose.freeType)
        vecRows = FREESPIN_REEL_ROWS[result]
    end
    
    for i = 1, self.m_iReelColumnNum, 1 do
        local row = vecRows[i]
        local shade = self.m_vecShades[i]
        if row > self.m_nomalRowNum then
            self.m_riseReelFlag = true
            local distance = row - self.m_nomalRowNum
            shade:playAction("idle"..distance, true)
        else
            shade:playAction("actionframe", true)
        end
    end

    self:runCsbAction("idle2")
    self.m_jackpotBar:runCsbAction("idle2")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"actionframe")
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenSaharaTreasureMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    
    self:initFsUI()    
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenSaharaTreasureMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.m_freeSpinBar:setVisible(false)
    self.m_nodeTitle:setVisible(true)
    self:runCsbAction("idle1")
    self.m_jackpotBar:runCsbAction("idle1")
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle1")
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenSaharaTreasureMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("SaharaTreasureSounds/music_SaharaTreasure_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_fs_more.mp3")
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local data = self.m_runSpinResultData.p_selfMakeData.choose
            data.func = function()
                gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_fs_window.mp3")
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()       
                end)
                performWithDelay(self, function()
                    self:initFsUI()
                end, 0.5)
            end
            local chooseView = util_createView("CodeSaharaTreasureSrc.SaharaTreasureChooseView", data)
            local high = display.height
            if high < display.width then
                high = display.width
            end
            if high < 1200 then
                local scale = display.height / 1200
                util_csbScale(chooseView.m_csbNode, scale)
            end
            
            self:addChild(chooseView, GAME_LAYER_ORDER.LAYER_ORDER_EFFECT)
            if globalData.slotRunData.machineData.p_portraitFlag then
                chooseView.getRotateBackScaleFlag = function(  ) return false end
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = chooseView})
            gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"idle2")
        end
    end
    
    -- 
    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenSaharaTreasureMachine:showEffect_newFreeSpinOver()
    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end
    self:checkFeatureOverTriggerBigWin( globalData.slotRunData.lastWinCoin, GameEffect.EFFECT_FREE_SPIN_OVER)
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- self:clearFrames_Fun()
    -- 重置连线信息
    -- self:resetMaskLayerNodes()
    self:clearCurMusicBg()
    self:showFreeSpinOverView()
end

function CodeGameScreenSaharaTreasureMachine:showFreeSpinOverView()

    gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_fs_over.mp3")
    performWithDelay(self, function()
        gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_fs_window.mp3")
    
        local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,30)
        local view = self:showFreeSpinOver( strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,function()
            self:triggerFreeSpinOverCallFun()
        end)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},550)
    end, 2)
    
end


function CodeGameScreenSaharaTreasureMachine:showJackpotView(index,coins,func)
    gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_jackpot_window.mp3")
    local jackPotWinView = util_createView("CodeSaharaTreasureSrc.SaharaTreasureJackpotView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView)
    jackPotWinView:initViewData(index,coins,function()
        -- gLobalSoundManager:stopAudio(soundID)
        -- soundID = nil
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
        if func ~= nil then 
            func()
        end
    end)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenSaharaTreasureMachine:MachineRule_SpinBtnCall()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)
   
    if self.m_riseReelFlag == true and self.m_bProduceSlots_InFreeSpin ~= true then
        local vecShowRows = self.m_runSpinResultData.p_selfMakeData.showRows
        for i = 1, self.m_iReelColumnNum, 1 do
            local row = vecShowRows[i]
            if row > self.m_nomalRowNum then
                local distance = row - self.m_nomalRowNum
                local shade = self.m_vecShades[i]
                shade:playAction("down"..distance, false, function()
                    self.m_riseReelFlag = false
                    shade:playAction("actionframe", true)
                end)
            end
        end
        gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_shade.mp3")
        scheduler.performWithDelayGlobal(function (  )
            if self.m_netDataCallFlag == true then
                self.m_netDataCallFlag = false
                self:updateNetWorkData()
            end
        end, 0.75, self:getModuleName())
    end
    if self.m_runSpinResultData.p_selfMakeData ~= nil and self.m_runSpinResultData.p_selfMakeData.rapidCount ~= nil then
        self.m_jackpotBar:hideWinEffect()
    end

    self:setMaxMusicBGVolume()
    self:removeSoundHandler()

    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenSaharaTreasureMachine:addSelfEffect()

    if self.m_runSpinResultData.p_selfMakeData.rapidCount ~= nil then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.CASH_RUSH_EFFECT -- 动画类型
    end
    
        -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.QUICKHIT_JACKPOT_EFFECT -- 动画类型

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenSaharaTreasureMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.CASH_RUSH_EFFECT then
        self:cashRushAnimtion(effectData)
    end

    
	return true
end

function CodeGameScreenSaharaTreasureMachine:cashRushAnimtion(effectData)
    local rapidCount = self.m_runSpinResultData.p_selfMakeData.rapidCount
    self:showDarkSymbol()
    if rapidCount < 5 then
        effectData.p_isPlay = true
        self:playGameEffect()
        
        if self.m_runSpinResultData.p_winAmount == self.m_runSpinResultData.p_selfMakeData.rapidWin then
            local isNotifyUpdateTop = true
            if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
                isNotifyUpdateTop = false
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
        end
    else
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_jackpot.mp3")
        self.m_jackpotBar:shwoWinEffect(rapidCount)
        performWithDelay(self, function()
            self:showJackpotView(rapidCount, self.m_runSpinResultData.p_selfMakeData.rapidWin, function()

                if self.m_runSpinResultData.p_winAmount == self.m_runSpinResultData.p_selfMakeData.rapidWin then
                    local isNotifyUpdateTop = true
                    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
                        isNotifyUpdateTop = false
                    end

                    if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN)
                        or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) 
                        or (self.m_bProduceSlots_InFreeSpin == true and self.m_runSpinResultData.p_freeSpinsLeftCount == 0) then

                    else
                        self:checkFeatureOverTriggerBigWin(self.m_iOnceSpinLastWin, GameEffect.EFFECT_SELF_EFFECT)
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop})
                end
                effectData.p_isPlay = true
                self:playGameEffect()
                self:resetMusicBg()
            end)
        end, 3)
    end

    local vecRows = self.m_runSpinResultData.p_selfMakeData.showRows
    for iCol = 1, self.m_iReelColumnNum, 1 do
        for iRow = 1, vecRows[iCol], 1 do
            if self.m_stcValidSymbolMatrix[iRow][iCol] == self.SYMBOL_CASH_RUSH then
                local cash = self:getFixSymbol(iCol, iRow)
                self:changeToMaskLayerSlotNode(cash)
                cash:runAnim("actionframe3", true)
            end
        end
    end
    -- changeToMaskLayerSlotNode
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenSaharaTreasureMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenSaharaTreasureMachine:updateNetWorkData()
    if self.m_bProduceSlots_InFreeSpin == true then
        BaseNewReelMachine.updateNetWorkData(self)
        return
    end
    if self.m_riseReelFlag == true then
        self.m_netDataCallFlag = true
        return
    end

    local vecShowRows = self.m_runSpinResultData.p_selfMakeData.showRows
    local delayTime = 0
    local upNum = 0
    for i = 1, self.m_iReelColumnNum, 1 do
        local row = vecShowRows[i]
        upNum = upNum + row - self.m_nomalRowNum
    end

    local upAnim = function()
        for i = 1, self.m_iReelColumnNum, 1 do
            local row = vecShowRows[i]
            if row > self.m_nomalRowNum then
                self.m_riseReelFlag = true
                local distance = row - self.m_nomalRowNum
                local shade = self.m_vecShades[i]
                shade:playAction("up"..distance, false, function()
                    shade:playAction("idle"..distance, true)
                end)
            end
        end
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    local winRatio = self.m_runSpinResultData.p_winAmount / lTatolBetNum
    
    if upNum > 0 and winRatio > 0 then
        for i = 1, self.m_iReelColumnNum, 1 do
            local row = vecShowRows[i]
            if row > self.m_nomalRowNum then
                self.m_vecUpEffect[i]:setVisible(true)
                self.m_vecUpEffect[i]:playAction("actionframe", false, function ()
                    self.m_vecUpEffect[i]:setVisible(false)
                end)
            end
        end
        performWithDelay(self, function()
            upAnim()
        end, 1)
        delayTime = 1
    elseif upNum > 0 then
        upAnim()
        delayTime = 0.5
    end

    if delayTime ~= 0 then
        gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_shade.mp3")
    end

    performWithDelay(self, function()
        BaseNewReelMachine.updateNetWorkData(self)
    end, delayTime)
end

--播放提示动画
function CodeGameScreenSaharaTreasureMachine:playReelDownTipNode(slotNode)
    local row = self.m_runSpinResultData.p_selfMakeData.showRows[slotNode.p_cloumnIndex]
    if slotNode.p_rowIndex <= row then
        -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_SPECIAL_BONUS)
        self:playScatterBonusSound(slotNode)
        slotNode:runAnim("buling")
        -- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
        self:specialSymbolActionTreatment( slotNode)
    end
end

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}
--设置bonus scatter 信息
function CodeGameScreenSaharaTreasureMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = self.m_runSpinResultData.p_selfMakeData.showRows[column]

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
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

function CodeGameScreenSaharaTreasureMachine:setSlotNodeEffectParent(slotNode)
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

    self.m_clipParent:addChild(slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + slotNode.p_showOrder)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode


    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    if slotNode ~= nil then
        slotNode:runLineAnim()
    end
    return slotNode
end

function CodeGameScreenSaharaTreasureMachine:randomSlotNodes( )
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        local symbolID = math.random(1, #reelDatas)
        for rowIndex=1,rowCount do
            symbolID = symbolID - 1
            if symbolID == 0 then
                symbolID = #reelDatas
            end
            local symbolType = reelDatas[symbolID]

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
            node:runAnim("idleframe")
           
        end
    end
    self:initGridList()
end

-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
function CodeGameScreenSaharaTreasureMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()
    for colIndex=self.m_iReelColumnNum,  1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels
        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum  -- 返回来的数据1位置是最上面一行。
        while rowIndex >= 1 do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]

            symbolType = self:initSlotNodesExcludeOneSymbolType( symbolType  )

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH
            node.p_showOrder = self:getBounsScatterDataZorder(symbolType) - changeRowIndex
            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                else
                    parentData.slotParent:addChild(node,
                        REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + changeRowIndex)
                node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_1 + node.p_showOrder)
                node:setVisible(true)
            end
            node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima
            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:runAnim("idleframe")
            rowIndex = rowIndex - 1
        end  -- end while
    end
    self:initGridList()
end

function CodeGameScreenSaharaTreasureMachine:showEffect_LineFrame(effectData)

    self:showDarkSymbol()
    
    return BaseNewReelMachine.showEffect_LineFrame(self, effectData)

end

function CodeGameScreenSaharaTreasureMachine:showDarkSymbol()
    for iCol = 1, self.m_iReelColumnNum, 1 do
        for iRow = 1, self.m_iReelRowNum, 1 do
            local node = self:getFixSymbol(iCol, iRow)
            if self.m_runSpinResultData.p_selfMakeData.rapidCount == nil then
                node:runAnim("dark")
            elseif self.m_stcValidSymbolMatrix[iRow][iCol] ~= self.SYMBOL_CASH_RUSH then
                node:runAnim("dark")
            end
        end
    end
end

return CodeGameScreenSaharaTreasureMachine






