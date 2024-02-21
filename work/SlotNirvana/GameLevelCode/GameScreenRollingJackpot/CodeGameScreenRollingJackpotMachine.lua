---
-- island li
-- 2019年1月26日
-- CodeGameScreenRollingJackpotMachine.lua
-- 
-- 玩法：
-- ID:10140
-- ！！！！！注意继承 有长条用 JmsBaseSlotoManiaMachine  无长条用 JmsBaseNewReelMachine
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local SlotParentData = require "data.slotsdata.SlotParentData"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local ConfigInstance  = require("RollingJackpotPublicConfig"):getInstance()
local SoundConfig = ConfigInstance.SoundConfig
local CodeGameScreenRollingJackpotMachine = class("CodeGameScreenRollingJackpotMachine", BaseNewReelMachine)

CodeGameScreenRollingJackpotMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenRollingJackpotMachine.SYMBOL_FIX_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- 自定义的小块类型
CodeGameScreenRollingJackpotMachine.SYMBOL_FIX_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenRollingJackpotMachine.BASE_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 自定义动画的标识
CodeGameScreenRollingJackpotMachine.FREE_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenRollingJackpotMachine.FREE_UPREEL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenRollingJackpotMachine.FREE_JACKPOTOVER_EFFECT = GameEffect.EFFECT_LINE_FRAME + 1  -- 自定义动画的标识
local ITMETYPE = {
    NORMAL = 1,  --普通的
    NEXT = 2,    --下次的
    CURRENT = 3  --当前的
}
local qipan_scale = {1, 1, 1, 1, 1, 0.9, 0.85, 0.8, 0.75, 0.7}
-- 构造函数
function CodeGameScreenRollingJackpotMachine:ctor()
    CodeGameScreenRollingJackpotMachine.super.ctor(self)
    self.m_spinRestMusicBG = true
    self.m_isFeatureOverBigWinInFree = true
    self.m_rollShadeFlag = true  -- 滚动中轮盘是否压暗 true 是压暗 调用函数 rollShadeFadein rollShadeFadeout
	--init
	self:initGame()
end

function CodeGameScreenRollingJackpotMachine:initGame()

    
	--初始化基本数据
	self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
    self.m_reelRunCol          = 0                               --图标开始播放期待动画的列,棋盘开始快滚的前1列
    self.m_reelRunSymbolType   = TAG_SYMBOL_TYPE.SYMBOL_SCATTER  --棋盘开始快滚的图标类型
    self.m_idleSymbolTypeList  = {                               --循环idle类型的图标列表
        TAG_SYMBOL_TYPE.SYMBOL_SCATTER,
        self.SYMBOL_FIX_BONUS1,
        self.SYMBOL_FIX_BONUS2
    }

    self.m_isShowBigWinLabel = true  --是否显示bigwin的lable
    self.m_isMustShosBigWinLable = false --是否必须显示bigwin的lable
    self.m_isSHowUpAni = false
    self.m_baseRow = 3
    self.m_maxFreeLevel = 9
    self.m_lineWinCoins = 0       --本次的连线赢钱
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenRollingJackpotMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RollingJackpot"  
end




function CodeGameScreenRollingJackpotMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar
    self.m_reel_pos = cc.p(self:findChild("qipan"):getPosition())
    --jackpot
    self.m_baseJackpotBar = util_createView("RollingJackpotSrc.RollingJackpotJackPotBarView", true)
    self:findChild("base_jackpot"):addChild(self.m_baseJackpotBar)
    self.m_baseJackpotBar:initMachine(self)

    --动作节点
    self.m_actionNode = cc.Node:create()
    self:addChild(self.m_actionNode)

    self:changeReelAndBg("base")
    self:createBigWinEffect()
    self:createFreeJackpot()
    self:addColorLayer()
    self:changeJackpot("base")

    self.m_playLin = util_createAnimation("RollingJackpot_payline.csb")
    self:findChild("payline"):addChild(self.m_playLin)
    self:initPlayLine()
    self.m_playLin:playAction("idle")
    self.m_qipan_size = self:findChild("ui_qipan"):getContentSize()
    self.m_upAni_size = self:findChild("ui_upAni"):getContentSize()
    self.m_ui_qipan_topY = self:findChild("ui_qipan_top"):getPositionY()
    self.m_Node_shangL1Y = self:findChild("Node_shangL1"):getPositionY()
    self.m_Node_shangL2Y = self:findChild("Node_shangL2"):getPositionY()
    self.m_Node_shangY = self:findChild("Node_shangY"):getPositionY()
    self.m_ui_tbY = self:findChild("ui_tb"):getPositionY()

    self:runCsbAction("idle", true)

end


function CodeGameScreenRollingJackpotMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_enterLevel)

    end,0.4,self:getModuleName())
end

function CodeGameScreenRollingJackpotMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRollingJackpotMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:updateBetLevel()
    self.m_baseJackpotBar:updateBetLevelUI(self.m_iBetLevel, true)
    if self.m_rollShadeLayer then
        self.m_rollShadeLayer:_setLocalZOrder(100000000)
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:resetReelRunInfo()
        self:initFreeJackpotData()
    end
    self:addObservers()
end

function CodeGameScreenRollingJackpotMachine:addObservers()
    CodeGameScreenRollingJackpotMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        -- local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        -- if not (freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE) then
        --     if self.m_bIsBigWin then
        --         return 
        --     end
        -- end 
        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
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

        local soundName = ""
        local key = string.format("sound_base_winLine_%d", soundIndex)
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            key = string.format("sound_free_winLine_%d", soundIndex)
        end
        soundName = SoundConfig[key]
        if soundName then
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        end
        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    --检测bet切换
    gLobalNoticManager:addObserver(self,function(self,params)
        local betCoin = globalData.slotRunData:getCurTotalBet()
        local perBetLevel = self.m_iBetLevel
        self:updateBetLevel()
        if perBetLevel ~= self.m_iBetLevel then
            self.m_baseJackpotBar:updateBetLevelUI(self.m_iBetLevel)
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function CodeGameScreenRollingJackpotMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRollingJackpotMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
end


function CodeGameScreenRollingJackpotMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil
    if symbolType == self.SYMBOL_FIX_BONUS1 then
        ccbName = "Socre_RollingJackpot_Bonus2"
    elseif symbolType == self.SYMBOL_FIX_BONUS2 then
        ccbName = "Socre_RollingJackpot_Bonus1"
    end
    return ccbName
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenRollingJackpotMachine:getPreLoadSlotNodes()
    local loadNode = self.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_FIX_BONUS2,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenRollingJackpotMachine:MachineRule_initGame(  )
    
end

--
--单列滚动停止回调
--
function CodeGameScreenRollingJackpotMachine:slotOneReelDown(reelCol)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:reelStopHideMask(reelCol)    
    end
    CodeGameScreenRollingJackpotMachine.super.slotOneReelDown(self,reelCol) 
   
    -- 落地音效播放函数-- 保证第二个参数的唯一性，防止多个小块或者快停落地音效重复播放
    -- self:playBulingSound(reelCol, "scatter", "RollingJackpotSounds/sound_RollingJackpot_scatter_down.mp3")
    self:MachineOneReelDownCall(reelCol)
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenRollingJackpotMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self:changeReelAndBg("free")
    self:changeJackpot("free")
    self:initFreeJackpotData()
    self:initUIReel()
    self.m_curJackpotItem:setPosition(cc.p(0, 0))
    self.m_nextJackpotItem:setPosition(cc.p(0, 0))
    self:findChild("qipan"):setPosition(cc.p(self.m_reel_pos.x, self.m_reel_pos.y + 57))
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenRollingJackpotMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    self.m_isShowBigWinLabel = false
    self.m_iReelRowNum = self.m_baseRow
    self:clearWinLineEffect()
    self:putBackSoltToPreParent()
    self:changeReelAndBg("base")
    self:changeJackpot("base")
    self:initUIReel()
    self:findChild("qipan"):setPosition(cc.p(self.m_reel_pos.x, self.m_reel_pos.y))
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenRollingJackpotMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("RollingJackpotSounds/music_RollingJackpot_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local start_sound = SoundConfig.sound_freeStart_show
            local end_sound = SoundConfig.sound_freeStart_over
            gLobalSoundManager:playSound(start_sound)
            local view = self:showFreeSpinStart(5,function()
                gLobalSoundManager:playSound(SoundConfig.sound_baseToFree_change)
                self:showChangeScence(function()
                    self:triggerFreeSpinCallFun()
                end, function()
                    effectData.p_isPlay = true
                    self:playGameEffect() 
                end)
            end)
            view:setBtnClickFunc(function()
                gLobalSoundManager:playSound(end_sound)
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        showFSView()    
    end,0.5)

    

end

function CodeGameScreenRollingJackpotMachine:showFreeSpinOverView()
    local fsWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
    local jackpotWinCoin = self.m_runSpinResultData.p_fsExtraData.jackpotWinAmount or 0
    local freeOverView = util_createView("RollingJackpotSrc.RollingJackpotFreeOverView")
    freeOverView:initViewData(fsWinCoin,jackpotWinCoin)
    freeOverView:setOverAniRunFunc(function()
        gLobalSoundManager:playSound(SoundConfig.sound_freeToBase_change)
        self:showChangeScence(function()
            self:levelFreeSpinOverChangeEffect()
        end, function()
            self:triggerFreeSpinOverCallFun()
        end)
    end)
    if freeOverView:findChild("ui_root") then
        freeOverView:findChild("ui_root"):setScale(self.m_machineRootScale)
    end
    gLobalViewManager:showUI(freeOverView)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenRollingJackpotMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume( )

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    --每次spin重置数据
    self.m_reelRunCol = 0
    self.m_isShowBigWinLabel = true

    return false -- 用作延时点击spin调用
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenRollingJackpotMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local rapidTimes = selfData.rapidTimes or 0
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and rapidTimes > 4 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.BASE_JACKPOT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.BASE_JACKPOT_EFFECT -- 动画类型
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        local oldeCollect = ConfigInstance:getGameData("curCollectCount")
        local curCollectCount = selfData.currentCollectCount
        local upCollect = selfData.upCollect
        self:saveJackpotData()
        if oldeCollect ~= curCollectCount then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FREE_JACKPOT_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FREE_JACKPOT_EFFECT -- 动画类型
        end
        if upCollect then
            if self.m_runSpinResultData.p_freeSpinsLeftCount ~= 0 then
                self:removeEffectByType(GameEffect.EFFECT_FREE_SPIN_OVER)
            end
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FREE_UPREEL_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FREE_UPREEL_EFFECT -- 动画类型
        end
        
        if self.m_runSpinResultData.p_freeSpinsLeftCount and self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            local jackpotWinCoin = self.m_runSpinResultData.p_fsExtraData.jackpotWinAmount or 0
            self.m_lineWinCoins = self.m_lineWinCoins - jackpotWinCoin
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FREE_JACKPOTOVER_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FREE_JACKPOTOVER_EFFECT -- 动画类型
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenRollingJackpotMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.BASE_JACKPOT_EFFECT then
        self:waitWithDelay(1, function()
            self:showEffect_BaseRaid(effectData)
        end)
    elseif effectData.p_selfEffectType == self.FREE_JACKPOT_EFFECT then
        self:waitWithDelay(1, function()
            self:showEffect_FreeRaid(effectData)
        end)
    elseif effectData.p_selfEffectType == self.FREE_UPREEL_EFFECT then
        self:showEffect_collectFull(effectData)
    elseif effectData.p_selfEffectType == self.FREE_JACKPOTOVER_EFFECT then
        local winLines = self.m_reelResultLines
        local delayTime = #winLines <= 0 and 0 or 2 
        self:waitWithDelay(delayTime, function()
            self:showEffect_freeJackpot(effectData)
        end)
    end
	return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenRollingJackpotMachine:MachineRule_ResetReelRunData()
    CodeGameScreenRollingJackpotMachine.super.MachineRule_ResetReelRunData( self )
    --计算本次快滚图标类型
    self.m_reelRunSymbolType  = TAG_SYMBOL_TYPE.SYMBOL_SCATTER
end

function CodeGameScreenRollingJackpotMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenRollingJackpotMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenRollingJackpotMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_isSHowUpAni = false
    CodeGameScreenRollingJackpotMachine.super.slotReelDown(self)
end

function CodeGameScreenRollingJackpotMachine:checkRemoveBigMegaEffect()
    CodeGameScreenRollingJackpotMachine.super.checkRemoveBigMegaEffect( self )
    local hasFsEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN)
    if hasFsEffect then
        if not self.m_bProduceSlots_InFreeSpin then
            self.m_bIsBigWin = false
        end
    end

    local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
    if hasFsOverEffect then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenRollingJackpotMachine:updateBetLevel()
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
        if  self.m_specialBets and self.m_specialBets[1] then
            self.m_baseJackpotBar:setCriticalValue(self.m_specialBets[1].p_totalBetValue)
        end
    end
    
    if globalData.slotRunData.isDeluexeClub == true then
        self.m_iBetLevel = 1
    else
        local betCoin = globalData.slotRunData:getCurTotalBet()
        if self.m_specialBets and #self.m_specialBets > 0 then
            self.m_iBetLevel = #self.m_specialBets
            for i = 1, #self.m_specialBets do
                if betCoin < self.m_specialBets[i].p_totalBetValue then
                    self.m_iBetLevel = i - 1
                    break
                end
            end
        else
            self.m_iBetLevel = 0
        end
    end
end

----------------------------预告中奖----------------------------------------

function CodeGameScreenRollingJackpotMachine:getFeatureGameTipChance()
    local features = self.m_runSpinResultData.p_features or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local rapidTimes = selfData.rapidTimes or 0
    if (#features >= 2 and features[2] > 0) or rapidTimes > 4 then
        local randNum = util_random(1, 100)
        -- 出现预告动画概率30%
        return randNum <= 30
    end
    return false
end

-- 播放预告中奖统一接口
function CodeGameScreenRollingJackpotMachine:showFeatureGameTip(_func)
    local isNotice = self:getFeatureGameTipChance()
    if isNotice then
        local features = self.m_runSpinResultData.p_features or {}
        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end, #features >= 2)
    else
        if type(_func) == "function" then
            local delay_time = self.m_isSHowUpAni and 1 or 0
            self:waitWithDelay(delay_time, function()
                _func()
            end)
        end
    end
end

--[[
    播放预告中奖动画
    预告中奖通用规范
    命名:关卡名+_yugao
    时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
    挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
]]
function CodeGameScreenRollingJackpotMachine:playFeatureNoticeAni(func, isFeature)
    self.b_gameTipFlag = true
    --获取父节点
    local parentNode = self:findChild("Node_yugao")
    --检测是否存在预告中奖资源
    local aniName = "RollingJackpot_yugao.csb"
    local soundName = "sound_RollingJackpot_notice_3"
    if isFeature then
        soundName = "sound_RollingJackpot_notice_1"
        aniName = "RollingJackpot_yugao2.csb"
    end
    gLobalSoundManager:playSound(SoundConfig[soundName])

    --动效执行时间
    local aniTime = 0

    local csbAni = util_createAnimation(aniName)
        
    if parentNode and not tolua.isnull(csbAni) then
        parentNode:addChild(csbAni)
        csbAni:runCsbAction("actionframe_yugao",false,function()
            csbAni:removeFromParent()
        end)
        aniTime = util_csbGetAnimTimes(csbAni.m_csbAct,"actionframe_yugao")
    end
    if func and type(func) == "function" then
        --计算延时,预告中奖播完时需要刚好停轮
        local delayTime = self:getRunTimeBeforeReelDown()
        --预告中奖时间比滚动时间短,直接返回即可
        if aniTime <= delayTime then
            func()
        else
            self:waitWithDelay(aniTime - delayTime,function()
                func()
            end)
        end
    end

end

function CodeGameScreenRollingJackpotMachine:isReelRunSymbolType(_symbolType)
    return _symbolType == self.m_reelRunSymbolType
end

function CodeGameScreenRollingJackpotMachine:MachineOneReelDownCall(_iCol)
    if self:getNextReelLongRunState(_iCol) then
        if self.m_reelRunCol == 0 then
            self.m_reelRunCol = _iCol
        end
    end
    if _iCol == self.m_iReelColumnNum and 0 ~= self.m_reelRunCol then
        --停止所有期待
        self.m_reelRunCol = 0
        self:stopExpectAnim()
    else
        --循环idle图标
        local maxRow = self.m_iReelRowNum
        for iRow=1,maxRow do
            local slotsNode = self:getFixSymbol(_iCol, iRow, SYMBOL_NODE_TAG)
            if self:isLoopIdleSymbol(slotsNode.p_symbolType) and not self:checkSymbolBulingAnimPlay(slotsNode) then
                self:playSymbolIdleAnim(slotsNode)
            end
        end
    end
end
--快滚检测 和 BaseMachine:slotOneReelDown 保持一致
function CodeGameScreenRollingJackpotMachine:getNextReelLongRunState(_iCol)
    if self:getNextReelIsLongRun(_iCol + 1) and 
        (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        
        return true 
    end
    return false
end
--循环idle图标检测
function CodeGameScreenRollingJackpotMachine:isLoopIdleSymbol(_symbolType)
    for i,_idleSymbolType in ipairs(self.m_idleSymbolTypeList) do
        if _idleSymbolType == _symbolType then
            return true
        end
    end
    return false
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenRollingJackpotMachine:symbolBulingEndCallBack(_slotNode)
    if 0 ~= self.m_reelRunCol then
        local iCol = _slotNode.p_cloumnIndex
        if iCol == self.m_reelRunCol then
            self:playExpectAnim(iCol, nil)
        elseif iCol > self.m_reelRunCol and iCol < self.m_iReelColumnNum then
            local iRow = _slotNode.p_rowIndex
            self:playExpectAnim(iCol, iRow)
        --循环idle图标和最后一列的期待类型图标 直接转播循环idle  
        elseif self:isLoopIdleSymbol(_slotNode.p_symbolType) then
            self:playSymbolIdleAnim(_slotNode)
        end
    else
        if self:isLoopIdleSymbol(_slotNode.p_symbolType) then
            self:playSymbolIdleAnim(_slotNode)
        end
    end
end

--播放期待动画 
function CodeGameScreenRollingJackpotMachine:playExpectAnim(_iCol, _iRow)
    --一个关卡有多个期待图标时让动效统一命名时间线即可
    local animName = "idleframe3"
    if not _iRow then
        local maxRow = self.m_iReelRowNum
        for iCol=1,_iCol do
            for iRow=1,maxRow do
                local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                    if not slotsNode.m_slotAnimaLoop or animName ~= slotsNode.m_currAnimName then
                        slotsNode:runAnim(animName, true)
                    end
                end
            end
        end
    else
        local slotsNode = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
        slotsNode:runAnim(animName, true)
    end 
end
--停止期待动画 
function CodeGameScreenRollingJackpotMachine:stopExpectAnim()
    local maxCol = self.m_iReelColumnNum
    local maxRow = self.m_iReelRowNum
    for iCol=1,maxCol do
        for iRow=1,maxRow do
            local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if self:isReelRunSymbolType(slotsNode.p_symbolType) then 
                self:playSymbolIdleAnim(slotsNode)
            end
        end
    end
end
--播放循环idle
function CodeGameScreenRollingJackpotMachine:playSymbolIdleAnim(_slotsNode)
    --一个关卡有多个循环idle图标时让动效统一命名时间线即可
    local loopIdleName = "idleframe2"
    if "" ~= loopIdleName then
        _slotsNode:runAnim(loopIdleName, true)
    else
        _slotsNode:runIdleAnim()
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenRollingJackpotMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == self.SYMBOL_FIX_BONUS2 then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenRollingJackpotMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                --1.提层-不论播不播落地动画先处理提层
                if symbolCfg[1] then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
                    _slotNode:setPositionY(curPos.y)

                    --连线坐标
                    local linePos = {}
                    linePos[#linePos + 1] = {iX = _slotNode.p_rowIndex, iY = _slotNode.p_cloumnIndex}
                    _slotNode.m_bInLine = true
                    _slotNode:setLinePos(linePos)

                    --回弹
                    local newSpeedActionTable = {}
                    for i = 1, #speedActionTable do
                        if i == #speedActionTable then
                            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
                            local resTime = self.m_configData.p_reelResTime
                            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
                            local tarSpPos = util_getOneGameReelsTarSpPos(self, index)
                            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
                        else
                            newSpeedActionTable[i] = speedActionTable[i]
                        end
                    end

                    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
                    _slotNode:runAction(actSequenceClone)
                end
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                self:symbolBulingStartCallBack(_slotNode)
                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            elseif _slotNode.p_symbolType == self.SYMBOL_FIX_BONUS2 or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                _slotNode:runAnim("idleframe2", true)
            end
        end
    end
end

function CodeGameScreenRollingJackpotMachine:getMinBet( )
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
        if  self.m_specialBets and self.m_specialBets[1] then
            self.m_baseJackpotBar:setCriticalValue(self.m_specialBets[1].p_totalBetValue)
        end
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

function CodeGameScreenRollingJackpotMachine:unlockHigherBet()
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
    local minBet = self:getMinBet()
    if betCoin >= minBet then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local bets = betList[i]
        if bets.p_totalBetValue >= minBet then
            globalData.slotRunData.iLastBetIdx = bets.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenRollingJackpotMachine:showRapidJackpotView(rapidNums,coins, func)
    local index = 13 - rapidNums
    local jackPotWinView = util_createView("RollingJackpotSrc.RollingJackpotJackPotWinView")
    jackPotWinView:initViewData(index,rapidNums,coins)
    jackPotWinView:setOverAniRunFunc(func)
    if jackPotWinView:findChild("ui_root") then
        jackPotWinView:findChild("ui_root"):setScale(self.m_machineRootScale)
    end
    gLobalViewManager:showUI(jackPotWinView)
end

function CodeGameScreenRollingJackpotMachine:showEffect_BaseRaid(effectData)
    self.m_isMustShosBigWinLable = true
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local rapidTimes = selfData.rapidTimes or 0
    local rapidAmount = selfData.rapidAmount or 0
    local winLines = self.m_reelResultLines
    self.m_baseJackpotBar:showJackpotWin(rapidTimes)
    self.m_lineWinCoins = self.m_lineWinCoins - rapidAmount
    gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_23)
    
    self:playSlotsTriggerAni(self.SYMBOL_FIX_BONUS2,nil, #winLines <= 0,  function()
        self:showRapidJackpotView(rapidTimes, rapidAmount, function()
            self:notifyUpdateWinCoin(rapidAmount, #winLines <= 0 and globalData.slotRunData.freeSpinCount <= 0, nil, true)
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end)
end

function CodeGameScreenRollingJackpotMachine:showEffect_FreeRaid(effectData)
    local freeRaidNum  = 0
    local freeRaidTab = {}
    for iCol=1,self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotsNode and slotsNode.p_symbolType and 
               slotsNode.p_symbolType == self.SYMBOL_FIX_BONUS1 then 
                freeRaidNum = freeRaidNum + 1
                table.insert(freeRaidTab, slotsNode)
            end
        end
    end

    local reRadiNum = self.m_nextJackpotItem.m_residueNum or 0
    local colleNum = math.min(reRadiNum, freeRaidNum)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local upCollect = selfData.upCollect
    local delayTime = 0
    for index = 1,freeRaidNum do
        local isLast = index == colleNum
        local tempSlotsNode = freeRaidTab[index]
        if index <= colleNum then
            self:waitWithDelay(delayTime, function()
                local aniStr = "shouji"
                local soundStr = "sound_RollingJackpot_21"
                if isLast and upCollect then
                    aniStr = "shouji2"
                    soundStr = "sound_RollingJackpot_15"
                end
                gLobalSoundManager:playSound(SoundConfig[soundStr])
                -- tempSlotsNode:runAnimFrame(aniStr, false, "shouji", function()
                --     self.m_nextJackpotItem:showCollectAni()
                -- end)
                tempSlotsNode:runAnimFrame(aniStr, false)
                self.m_nextJackpotItem:showCollectAni()
            end)
            delayTime  = delayTime + 0.75
        else
            self:waitWithDelay(delayTime, function()
                local ideleStr = tempSlotsNode:getIdleAnimName()
                tempSlotsNode:runMixAni(ideleStr, false)
            end)
        end
    end
    if upCollect then
        delayTime = delayTime + 1
    end
    self:waitWithDelay(delayTime, function()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)
end

--[[
    @desc: 棋盘上面的某类小块统一播放某条时间线(没有循环播放的处理)，如：触发动画等
    --@symbolType: 小块的类型
	--@callBack: 回调函数
    --@triggerAniName:时间线的名称，默认名称是 actionframe
]]

function CodeGameScreenRollingJackpotMachine:playSlotsTriggerAni(symbolType, triggerAniName, isLoop, callBack)
    local _triggerAniName = triggerAniName or "actionframe"
    local aniTime = nil
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local slotsNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotsNode and slotsNode.p_symbolType and 
               slotsNode.p_symbolType == symbolType then 
                slotsNode:runAnim(_triggerAniName, isLoop)
                if not aniTime then
                    aniTime = slotsNode:getAniamDurationByName(_triggerAniName)
                end
            end
        end
    end
    if callBack and type(callBack) == "function" and aniTime then
        self:waitWithDelay(aniTime, function()
            callBack()
        end)
    end
end

--创建大赢效果
function CodeGameScreenRollingJackpotMachine:createBigWinEffect()
    local pos = util_convertToNodeSpace(self.m_bottomUI.coinWinNode,self)
    self.m_bigWinSpin = util_spineCreate("RollingJackpot_bigwin", false, true)
    self:addChild(self.m_bigWinSpin, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_bigWinSpin:setScale(self.m_machineRootScale)
    self.m_bigWinSpin:setPosition(pos)
    self.m_bigWinSpin:setVisible(false)
    self:changeBottomBigWinLabUi("RollingJackpot_bigwin_shuzi.csb")
end

--大赢
function CodeGameScreenRollingJackpotMachine:showEffect_NewWin(effectData,winType)
    self.m_bigWinSpin:setVisible(true)
    local aniStr = "actionframe"
    util_spinePlay(self.m_bigWinSpin, aniStr)
    util_spineEndCallFunc(self.m_bigWinSpin, aniStr, function()
        self.m_bigWinSpin:setVisible(false)
    end)


    util_shakeNode(self:findChild("ui_root"), 18, 6, 2)
    local winLines = self.m_runSpinResultData.p_winLines or {}
    if self.m_isMustShosBigWinLable or (self.m_isShowBigWinLabel and not (self.m_bProduceSlots_InFreeSpin ~= true and #winLines <= 0)) then
        self.m_isMustShosBigWinLable = false
        gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_notice_2)
        local info = {
            overCoins = self.m_llBigOrMegaNum,
            animName = "actionframe",
            jumpTime = 1.3
        }
        self:playBottomBigWinLabAnim(info)
    else
        gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_notice_2)
    end

    self:waitWithDelay(2, function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.super.showEffect_NewWin(self,effectData,winType)
    end)
end

--
function CodeGameScreenRollingJackpotMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    self:notifyUpdateWinCoin(self.m_lineWinCoins, isNotifyUpdateTop)

end

function CodeGameScreenRollingJackpotMachine:notifyUpdateWinCoin(winCoins, isNotifyUpdateTop, isPlayAni, isNotPlayLineSound)
    local lastWinCoins = globalData.slotRunData.lastWinCoin
    lastWinCoins = lastWinCoins + winCoins
    globalData.slotRunData.lastWinCoin = lastWinCoins
    local params = {}
    params[1] = winCoins                --本次增加的赢钱
    params[2] = isNotifyUpdateTop       --是否刷新顶栏
    if isPlayAni ~= nil then
        params[3] = isPlayAni           --是否以跳动的方式刷新底栏
    end
    if isNotPlayLineSound ~= nil then
        params[self.m_stopUpdateCoinsSoundIndex] = isNotPlayLineSound  --是否不播放连线赢钱音效
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--[[
    @desc: 处理用户的spin赢钱信息
    time:2020-07-10 17:50:08
]]
function CodeGameScreenRollingJackpotMachine:operaWinCoinsWithSpinResult( param )
    local spinData = param[2]
    local userMoneyInfo = param[3]
    self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
    --发送测试赢钱数
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN,self.m_serverWinCoins)
    globalData.userRate:pushCoins(self.m_serverWinCoins)
    self.m_lineWinCoins = spinData.result.winAmount
    if spinData.result.freespin.freeSpinsTotalCount == 0 then
        self:setLastWinCoin(0)
    else
        local lasetWin = spinData.result.freespin.fsWinCoins - spinData.result.winAmount
        self:setLastWinCoin(lasetWin)
    end
    globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
end

function CodeGameScreenRollingJackpotMachine:checkIsAddLastWinSomeEffect( )

    local notAdd  = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local rapidAmount = selfData.rapidAmount or 0
    if rapidAmount > 0 then
        notAdd = false
    end

    return notAdd
end

function CodeGameScreenRollingJackpotMachine:changeReelAndBg(uiType)
    self:findChild("base_reel"):setVisible("base" == uiType)
    self:findChild("free_reel"):setVisible("free" == uiType)
    self.m_gameBg:findChild("RollingJackpot_Bg_Base_1"):setVisible("base" == uiType)
    self.m_gameBg:findChild("RollingJackpot_Bg_Free_2"):setVisible("free" == uiType)
end

function CodeGameScreenRollingJackpotMachine:showChangeScence(callBack1, callBack2)
    local respin_change = util_spineCreate("RollingJackpot_guochang", false, true)
    self:addChild(respin_change, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER)
    util_spinePlay(respin_change, "actionframe_guochang")
    respin_change:setPosition(display.center)
    self:waitWithDelay(2, function()
        if type(callBack1) == "function" then
            callBack1()
        end
    end)
    self:waitWithDelay(87/30, function()
        if type(callBack2) == "function" then
            callBack2()
        end
        respin_change:removeFromParent()
    end)
end

function CodeGameScreenRollingJackpotMachine:createFreeJackpot()
    self.m_curJackpotItem = util_createView("RollingJackpotSrc.RollingJackpotFreeJackpotItemShell", 1)
    self:findChild("free_dacheng"):addChild(self.m_curJackpotItem)
    self.m_curJackpotItem:initItemType(ITMETYPE.CURRENT)

    self.m_nextJackpotItem = util_createView("RollingJackpotSrc.RollingJackpotFreeJackpotItemShell", 2)
    self:findChild("free_mubiaolan"):addChild(self.m_nextJackpotItem)
    self.m_nextJackpotItem:initItemType(ITMETYPE.NEXT)

    self.m_freeJackpotBar = util_createView("RollingJackpotSrc.RollingJackpotFreeJackpotBar")
    self:findChild("free_jackpot"):addChild(self.m_freeJackpotBar)
end

function CodeGameScreenRollingJackpotMachine:changeReelData(rowNum)
    self.m_iReelRowNum = rowNum
    for i = self.m_iReelRowNum , 1, - 1 do
        if self.m_stcValidSymbolMatrix[i] == nil then
            self.m_stcValidSymbolMatrix[i] = {92, 92, 92, 92, 92}
        end
    end
    for i = 1, self.m_iReelColumnNum do
        self:changeReelRowNum(i,self.m_iReelRowNum,true)
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
        columnData:updateShowColCount(self.m_iReelRowNum)
        self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum
    end
end

function CodeGameScreenRollingJackpotMachine:initFreeClipNode()
    local columnData = self.m_reelColDatas[1]
    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x, 
            y = rect.y, 
            width = rect.width, 
            height = columnData.p_slotColumnHeight
        }
    )
end

function CodeGameScreenRollingJackpotMachine:upReelAni()
    self.m_playLin:playAction("over", false, function()
        self:initPlayLine()
    end)
    self.m_nextJackpotItem:setCurFreeRow(self.m_iReelRowNum)
    local oldReelRowNum = self.m_iReelRowNum - 1
    self:runCsbAction("start", false, function()
        self:runCsbAction("actionframe", true)
    end)
    if self.m_rollShadeLayer then
        local rollSize = self.m_rollShadeLayer:getContentSize()
        self.m_rollShadeLayer:setContentSize(rollSize.width, self.m_iReelRowNum * self.m_SlotNodeH)
    end
    local oldeScale = qipan_scale[oldReelRowNum]
    local targetScale = qipan_scale[self.m_iReelRowNum]
    self:waitWithDelay(0.25, function()
        gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_7)
        local stepAddHeights = self.m_SlotNodeH / 20
        local curAddHeights = stepAddHeights
        self:addReelUIHeight(stepAddHeights)
        util_schedule(self.m_actionNode, function()
            curAddHeights  = curAddHeights + stepAddHeights
            self:addReelUIHeight(stepAddHeights)
            if curAddHeights >= self.m_SlotNodeH then
                self.m_actionNode:stopAllActions()
                self.m_playLin:playAction("start")
                self:runCsbAction("over", false, function()
                    self:runCsbAction("idle", true)
                end)
            end
        end, 0.05)
        self.m_freeJackpotBar:upReelAni(oldReelRowNum, self.m_iReelRowNum)
        self.m_nextJackpotItem:upReelAni(self.m_iReelRowNum)
        if targetScale ~= oldeScale then
            self:findChild("qipan"):runAction(cc.ScaleTo:create(1, targetScale))
        end
    end)
end

--设置棋牌ui高度，升降棋牌用
function CodeGameScreenRollingJackpotMachine:addReelUIHeight(addHeights)
    local qipan_size = self:findChild("ui_qipan"):getContentSize()
    self:findChild("ui_qipan"):setContentSize(cc.size(qipan_size.width, qipan_size.height + addHeights))

    local upAni_size = self:findChild("ui_upAni"):getContentSize()
    self:findChild("ui_upAni"):setContentSize(cc.size(upAni_size.width, upAni_size.height + addHeights))

    self:findChild("ui_qipan_top"):setPositionY(self:findChild("ui_qipan_top"):getPositionY() + addHeights)

    self:findChild("Node_shangL1"):setPositionY(self:findChild("Node_shangL1"):getPositionY() + addHeights)

    self:findChild("Node_shangL2"):setPositionY(self:findChild("Node_shangL2"):getPositionY() + addHeights)

    self:findChild("Node_shangY"):setPositionY(self:findChild("Node_shangY"):getPositionY() + addHeights)

    self:findChild("ui_tb"):setPositionY(self:findChild("ui_tb"):getPositionY() + addHeights/2)
    self:findChild("payline"):setPositionY(self:findChild("ui_tb"):getPositionY() + addHeights/2)

    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x, 
            y = rect.y, 
            width = rect.width, 
            height = rect.height + addHeights
        }
    )
end

function CodeGameScreenRollingJackpotMachine:addColorLayer()
    self.m_colorLayers = {}
    for i = 1, self.m_iReelColumnNum do
        local parentData = self.m_slotParents[i]
        local mask = cc.LayerColor:create(cc.c3b(0,0,0), parentData.reelWidth, 1450):hide()
        mask:setOpacity(200)
        mask:setPositionX(parentData.reelWidth / 2)
        parentData.slotParent:addChild(mask, GD.REEL_SYMBOL_ORDER.REEL_ORDER_MASK)
        self.m_colorLayers[i] = mask
    end
end
function CodeGameScreenRollingJackpotMachine:showColorLayer(bfade)
    for i,v in ipairs(self.m_colorLayers) do
        v:show()
        if bfade then
            v:setOpacity(0)
            v:runAction(cc.FadeTo:create(0.3, 200))
        else
            v:setOpacity(200)
        end
    end
end

function CodeGameScreenRollingJackpotMachine:hideColorLayer(bfade)
    for i,v in ipairs(self.m_colorLayers) do
        if bfade then
            v:runAction(cc.Sequence:create(cc.FadeTo:create(0.3,0),cc.CallFunc:create(function(p)
                p:hide()
            end)))
        else
            v:setOpacity(0)
            v:hide()
        end
    end
end

function CodeGameScreenRollingJackpotMachine:reelStopHideMask(col)
    local maskNode = self.m_colorLayers[col]
    local fadeAct = cc.FadeTo:create(self.m_configData.p_reelResTime, 0)
    local func = cc.CallFunc:create( function()
        maskNode:setVisible(false)
    end)
    maskNode:runAction(cc.Sequence:create(fadeAct, func))
end

function CodeGameScreenRollingJackpotMachine:showEffect_collectFull(effectData)
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    self.m_nextJackpotItem:showCollectFullEffect()
    self:putBackSoltToPreParent()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local curIndex = selfData.currentIndex 
    if curIndex == self.m_maxFreeLevel then
        effectData.p_isPlay = true
        self:playGameEffect()
        return
    end
    self:waitWithDelay(1, function()
        self:showFreeSpinUpView(function()
            gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_11)
            self.m_nextJackpotItem:hide()
            local nextJackpotItem = self:copyNextJackpot()
            nextJackpotItem:changeCurTypeAction()
            self.m_curJackpotItem:hideTarget()
            local pos1 = util_convertToNodeSpace(self:findChild("ui_tb"), self:findChild("free_dacheng_zi"))
            local pos2 = util_convertToNodeSpace(self:findChild("free_dacheng"), self:findChild("free_dacheng_zi"))
            local actionList = {}
            actionList[#actionList + 1] = cc.MoveTo:create(1/3, pos1)
            actionList[#actionList + 1] = cc.DelayTime:create(5/6)
            actionList[#actionList + 1] = cc.CallFunc:create(function()
                self.m_curJackpotItem:hide()
            end)
            actionList[#actionList + 1] = cc.EaseBackIn:create(cc.MoveTo:create(1/3, pos2)) 
            actionList[#actionList + 1] = cc.DelayTime:create(1/3)
            actionList[#actionList + 1] = cc.Hide:create()
            actionList[#actionList + 1] = cc.CallFunc:create(function()
                self.m_curJackpotItem:resetCurLevelInfo()
                self.m_curJackpotItem:playTargetObjAni("idle3")
                self.m_curJackpotItem:show()
                self.m_curJackpotItem:playTargetObjAni("switch4", false, function()
                    self.m_curJackpotItem:playTargetObjAni("idle4")
                end)
                local baodian = util_createAnimation("RollingJackpot_bao.csb")
                self:findChild("free_dacheng"):addChild(baodian)
                baodian:playAction("actionframe", false, function()
                    baodian:removeFromParent()
                end)
            end)
            actionList[#actionList + 1] = cc.DelayTime:create(2/3)
            actionList[#actionList + 1] = cc.CallFunc:create(function()
                local info = ConfigInstance:getCurLevelInfo() --这个时候数据已经刷新
                local bonusTimes = info.bonusTimes
                self:showNewFreeMore(bonusTimes, function()
                    self:rollShadeFadeout()
                    self:waitWithDelay(0.5, function()
                        self:playNewnextFreeLevel()
                    end)
                end)
            end)
            actionList[#actionList + 1] = cc.RemoveSelf:create()
            nextJackpotItem:runAction(cc.Sequence:create(actionList))
        end)
    end)
end

function CodeGameScreenRollingJackpotMachine:copyNextJackpot()
    local info = ConfigInstance:getCurLevelInfo() --这个时候数据已经刷新
    local index = info.index
    local nextJackpotItem = util_createView("RollingJackpotSrc.RollingJackpotFreeJackpotItemShell", index)
    nextJackpotItem:initItemType(ITMETYPE.NEXT)
    nextJackpotItem:initInfo(info)
    nextJackpotItem:setFullEffect()
    local pos = util_convertToNodeSpace(self:findChild("free_mubiaolan"), self:findChild("free_dacheng_zi"))
    nextJackpotItem:setPosition(pos)
    self:findChild("free_dacheng_zi"):addChild(nextJackpotItem)
    return nextJackpotItem
end

--scale 是 nextJackpotItem里面的item的缩放
function CodeGameScreenRollingJackpotMachine:copyFreeJackpotBarItem(info, pos, scale)
    local index = info.index
    local nextJackpotItem = util_createView("RollingJackpotSrc.RollingJackpotFreeJackpotItemShell", index)
    nextJackpotItem:initItemType(ITMETYPE.NEXT)
    nextJackpotItem:initInfo(info)
    nextJackpotItem:setPosition(pos)
    nextJackpotItem:hideFreeBarAndTarget()
    nextJackpotItem:setItemScale(scale)
    nextJackpotItem.m_item:runCsbAction("idle3")
    self:findChild("free_dacheng_zi"):addChild(nextJackpotItem)
    return nextJackpotItem
end

function CodeGameScreenRollingJackpotMachine:playNewnextFreeLevel()
    local next_index = ConfigInstance:getGameData("currentIndex") + 1
    local info = ConfigInstance:getnextLevelInfo()
    local item = self.m_freeJackpotBar:getItemByIndex(next_index)
    if item then
        --计算缩放值
        local parent1 = item:getParent() 
        local scale1 = string.format("%.2f",parent1:getScale() + 0.0001) 
        local scale2 = string.format("%.2f",self.m_freeJackpotBar:findChild("Node_1"):getScale() + 0.0001) 
        local scale3 = string.format("%.2f",self:findChild("qipan"):getScale() + 0.0001)
        local targetScale = scale1 * scale2
        targetScale = targetScale / scale3
        item:hide()
        local pos = util_convertToNodeSpace(item, self:findChild("free_dacheng_zi"))
        local nextJackpotItem = self:copyFreeJackpotBarItem(info, pos, targetScale)
        local pos2 = util_convertToNodeSpace(self:findChild("free_mubiaolan"), self:findChild("free_dacheng_zi"))
        if self.m_iReelRowNum > 5 then
            pos2 = cc.pSub(pos2, cc.p(0, 5))
        end
        local actionList = {}
        actionList[#actionList + 1] = cc.DelayTime:create(1/3)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            self.m_nextJackpotItem:resetNextLevelInfo()
            self.m_nextJackpotItem:hideFreeBarAndTarget()
            local scale4 = string.format("%.2f",self.m_nextJackpotItem:findChild("item"):getScale() + 0.0001)
            nextJackpotItem:setItemScaleTo(scale4)
            gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_29)
        end)
        actionList[#actionList + 1] = cc.EaseBackOut:create(cc.MoveTo:create(1/3, pos2))
        actionList[#actionList + 1] = cc.DelayTime:create(1/3)
        actionList[#actionList + 1] = cc.CallFunc:create(function()
            self.m_nextJackpotItem:showNextEffect()
            nextJackpotItem:hide()
            self:waitWithDelay(1, function()
                self:playNextEffectBySelfEffectType(self.FREE_UPREEL_EFFECT)
            end)
        end)
        --actionList[#actionList + 1] = cc.RemoveSelf:create()
        nextJackpotItem:runAction(cc.Sequence:create(actionList))
    end
end

function CodeGameScreenRollingJackpotMachine:showFreeSpinUpView(newFunc)
    self:rollShadeFadein()
    gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_22)
    local view = self:showDialog("FreeSpinUp",nil,newFunc,BaseDialog.AUTO_TYPE_ONLY)
    util_setCascadeOpacityEnabledRescursion(view,true)
    util_changeNodeParent(self:findChild("ui_tb"),view)
    local guang = util_createAnimation("RollingJackpot_tanban_guang.csb")
    view:findChild("Node_guang"):addChild(guang)
    guang:playAction("idle",true)

    local size = view:findChild("Panel_1"):getContentSize()
    local addHeights = (self.m_iReelRowNum - 3) * self.m_SlotNodeH
    view:findChild("Panel_1"):setContentSize(size.width, size.height + addHeights)
    view:findChild("root"):setPositionY((size.height + addHeights)/2)
    --提前处理下升行需要的数据
    -- self.m_iReelRowNum = self.m_iReelRowNum + 1
    -- self:changeReelData(self.m_iReelRowNum)
    self.m_isSHowUpAni = true     --下次滚动播放生轮动画
end

function CodeGameScreenRollingJackpotMachine:operaEffectOver()
    if self.m_isSHowUpAni then
        --提前处理下升行需要的数据
        self.m_iReelRowNum = self.m_iReelRowNum + 1
        self:changeReelData(self.m_iReelRowNum)
    end
    CodeGameScreenRollingJackpotMachine.super.operaEffectOver(self)
end

function CodeGameScreenRollingJackpotMachine:dealSmallReelsSpinStates( )
    if not (self.b_gameTipFlag or self.m_isSHowUpAni)  then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
        {SpinBtn_Type.BtnType_Stop,true})
    end
end

function CodeGameScreenRollingJackpotMachine:showNewFreeMore(count,newfunc)
    gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_10)
    self:showFreeSpinMore(count,newfunc,true)
end

function CodeGameScreenRollingJackpotMachine:beginReel()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showColorLayer(true)    
        if self.m_isSHowUpAni then
            self:upReelAni()
        end
    end
    self.super.beginReel(self)
end

function CodeGameScreenRollingJackpotMachine:changeJackpot(showType)
    self.m_baseJackpotBar:setVisible("base" == showType)
    self.m_nextJackpotItem:setVisible("free" == showType)
    self.m_curJackpotItem:setVisible("free" == showType)
    self.m_freeJackpotBar:setVisible("free" == showType)
end

function CodeGameScreenRollingJackpotMachine:initFreeJackpotData()
    self:saveJackpotData()
    local info = ConfigInstance:getCurLevelInfo()
    self.m_iReelRowNum = info.rows
    self.m_nextJackpotItem:setCurFreeRow(self.m_iReelRowNum)
    self.m_freeJackpotBar:initJackpotInfos(self.m_iReelRowNum)
    self.m_curJackpotItem:resetCurLevelInfo()
    self.m_nextJackpotItem:resetNextLevelInfo()
    self.m_curJackpotItem:show()
    self.m_nextJackpotItem:show()
end

function CodeGameScreenRollingJackpotMachine:saveJackpotData()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local upCollect = selfData.upCollect
    local freeCollect = selfData.freeCollect
    if freeCollect then
        --freeJackpot 数据
        ConfigInstance:setGameData("freeCollect", freeCollect)
    end
    --当前的index
    local curIndex = selfData.currentIndex 
    ConfigInstance:setGameData("currentIndex", curIndex)
    --当前收集的数量
    local curCollectCount = selfData.currentCollectCount
    if upCollect then
        ConfigInstance:setGameData("curCollectCount", 0)
    else
        ConfigInstance:setGameData("curCollectCount", curCollectCount)
    end
    --当前free剩余的数量
    local leftFreeCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    ConfigInstance:setGameData("leftFreeCount", leftFreeCount)
end

function CodeGameScreenRollingJackpotMachine:playNextEffectBySelfEffectType(effectType)
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen do
        local effectData = self.m_gameEffects[i]
        if effectData.p_selfEffectType and  effectData.p_selfEffectType == effectType then
            effectData.p_isPlay = true
            break
        end
    end
    self:playGameEffect()
end

function CodeGameScreenRollingJackpotMachine:changeFreeSpinByCount()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self.m_nextJackpotItem then
        self.m_nextJackpotItem:changeFreeSpinByCount()
    end
end

function CodeGameScreenRollingJackpotMachine:initUIReel()
    self:changeReelData(self.m_iReelRowNum)
    self:initFreeClipNode()
    local addHeights = (self.m_iReelRowNum - 3) * self.m_SlotNodeH
    self:findChild("ui_qipan"):setContentSize(cc.size(self.m_qipan_size.width, self.m_qipan_size.height + addHeights))
    self:findChild("ui_upAni"):setContentSize(cc.size(self.m_upAni_size.width, self.m_upAni_size.height + addHeights))
    self:findChild("ui_qipan_top"):setPositionY(self.m_ui_qipan_topY + addHeights)
    self:findChild("Node_shangL1"):setPositionY(self.m_Node_shangL1Y + addHeights)
    self:findChild("Node_shangL2"):setPositionY(self.m_Node_shangL2Y + addHeights)
    self:findChild("Node_shangY"):setPositionY( self.m_Node_shangY + addHeights)
    self:findChild("ui_tb"):setPositionY(self.m_ui_tbY + addHeights/2)
    self:findChild("payline"):setPositionY(self.m_ui_tbY + addHeights/2)
    local targetScale = qipan_scale[self.m_iReelRowNum]
    self:findChild("qipan"):setScale(targetScale)
    if self.m_rollShadeLayer then
        local rollSize = self.m_rollShadeLayer:getContentSize()
        self.m_rollShadeLayer:setContentSize(rollSize.width, self.m_iReelRowNum * self.m_SlotNodeH)
    end
    self:initPlayLine()
end

function CodeGameScreenRollingJackpotMachine:initPlayLine()
    for i=3,10 do
        self.m_playLin:findChild("row"..i):setVisible(i == self.m_iReelRowNum)
    end
end

---- lighting 断线重连时，随机转盘数据
function CodeGameScreenRollingJackpotMachine:respinModeChangeSymbolType( )
    if self.m_initSpinData.p_freeSpinsLeftCount and self.m_initSpinData.p_freeSpinsLeftCount > 0 then
        if #self.m_initSpinData.p_reels ~= self.m_iReelRowNum then
            for iRow = 1, self.m_iReelRowNum do
                if not self.m_initSpinData.p_reels[iRow] then
                    self.m_initSpinData.p_reels[iRow] = {}
                    local rowInfo = self.m_initSpinData.p_reels[iRow]
                    for iCol = 1, self.m_iReelColumnNum do
                        rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % 7
                    end
                end
            end
        end
    end
end

function CodeGameScreenRollingJackpotMachine:putBackSoltToPreParent()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType and targSp.p_symbolType == self.SYMBOL_FIX_BONUS1 then
                targSp:putBackToPreParent()
            end
        end
    end
end

function CodeGameScreenRollingJackpotMachine:showEffect_freeJackpot(effectData)
    self:clearWinLineEffect()
    self:putBackSoltToPreParent()
    local jackpotWinCoin = self.m_runSpinResultData.p_fsExtraData.jackpotWinAmount or 0
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local curIndex = selfData.currentIndex 
    self:rollShadeFadein()
    gLobalSoundManager:playSound(SoundConfig.sound_RollingJackpot_20)
    if curIndex == self.m_maxFreeLevel then
        local pos = util_convertToNodeSpace(self:findChild("ui_tb"), self:findChild("free_dacheng_zi"))
        self.m_curJackpotItem:hideSelf()
        self.m_nextJackpotItem:hide()
        local nextJackpotItem = self:copyNextJackpot()
        nextJackpotItem:showWinJackpot(function()
            self:notifyUpdateWinCoin(jackpotWinCoin, false, nil, true)
            self:rollShadeFadeout()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        local actionList={}
        actionList[#actionList+1]=cc.MoveTo:create(0.25,pos)
        actionList[#actionList+1]=cc.DelayTime:create(3)
        actionList[#actionList+1]=cc.RemoveSelf:create()
        local seq=cc.Sequence:create(actionList)
        nextJackpotItem:runAction(seq)
    else
        local pos2 = util_convertToNodeSpace(self:findChild("ui_tb"), self:findChild("free_dacheng"))
        self.m_curJackpotItem:showWinJackpot(function()
            self:notifyUpdateWinCoin(jackpotWinCoin, false, nil, true)
            self:rollShadeFadeout()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        util_playMoveToAction(self.m_curJackpotItem, 0.25, pos2)
    end
end

--
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenRollingJackpotMachine:showBonusAndScatterLineTip(lineValue,callFun)
    globalPlatformManager:deviceVibrate(6)
    local frameNum = lineValue.iLineSymbolNum

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i=1,frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
        if slotNode ~= nil then--这里有空的没有管
            --SLOT_LINE_NODE
            local parent = slotNode:getParent()
            if parent ~= self.m_clipParent then
                slotNode:changeParentToOtherNode(self.m_clipParent)
            end
            slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
            slotNode:runAnim("actionframe")
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()) )
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime,callFun)

end

function CodeGameScreenRollingJackpotMachine:symbolBulingStartCallBack(slotNode)
    if slotNode.p_symbolType == self.SYMBOL_FIX_BONUS2 then
        local bullingEffect = util_createAnimation("RollingJackpot_Rapid_buling.csb")
        local pos = util_convertToNodeSpace(slotNode, self.m_clipParent)
        bullingEffect:setPosition(pos)
        self.m_clipParent:addChild(bullingEffect)
        local bulling_str = string.format("actionframe%d", slotNode.p_rowIndex)
        bullingEffect:playAction(bulling_str, false, function()
            bullingEffect:removeSelf()
        end)
    end
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线  
--TO:就该了一个点击音效
function CodeGameScreenRollingJackpotMachine:showDialog(ccbName,ownerlist,func,isAuto,index)
    local view = self.super.showDialog(self,ccbName,ownerlist,func,isAuto,index)
    view.m_btnTouchSound = SoundConfig.sound_base_dialog
    return view
end

--free 展示freeEffect 
function CodeGameScreenRollingJackpotMachine:playEffect_FreeSpin(effectData)
    self:waitWithDelay(1, function()
        self.super.playEffect_FreeSpin(self, effectData)
    end)
    return true
end

function CodeGameScreenRollingJackpotMachine:setScatterDownScound()
    self.m_scatterBulingSoundArry["auto"] = "RollingJackpotSounds/sound_RollingJackpot_Scatter_buling.mp3"
end

---
-- 显示所有的连线框
--
function CodeGameScreenRollingJackpotMachine:showAllFrame(winLines)

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
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s","")
        end
        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN then
            local frameNum = lineValue.iLineSymbolNum
            for i=1,frameNum do
                local symPosData = lineValue.vecValidMatrixSymPos[i]
                if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
    
                    addFrames[symPosData.iX * 1000 + symPosData.iY] = true
    
                    local columnData = self.m_reelColDatas[symPosData.iY]
    
                    local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen( )
    
                    local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
                    local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
    
                    local node = self:getFrameWithPool(lineValue,symPosData)
                    node:setPosition(cc.p(posX,posY))
    
                    checkIndex = checkIndex + 1
                    self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
    
                end
    
            end
        end
    end

end

---
-- 干预最终生成的信号,本关在这里重置下free的次数
--
function CodeGameScreenRollingJackpotMachine:MachineRule_InterveneReelList()
    local iColumn = self.m_iReelColumnNum
    local bouns_num = 0
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        for row = 1, iRow do
            local symbolType = self.m_stcValidSymbolMatrix[row][col]
            if self.SYMBOL_FIX_BONUS2 == symbolType then
                bouns_num  = bouns_num + 1
                if col < iColumn then
                    reelRunData:addPos(row, col, true, nil)
                end
            end
        end
    end

    if bouns_num >= 3 then
        local reelRunData = self.m_reelRunInfo[iColumn]
        local columnData = self.m_reelColDatas[iColumn]
        local temp_iRow = columnData.p_showGridCount
        for tempRow = 1, temp_iRow do
            local symbolType = self.m_stcValidSymbolMatrix[tempRow][iColumn]
            if self.SYMBOL_FIX_BONUS2 == symbolType then
                reelRunData:addPos(tempRow, iColumn, true, nil)
            end
        end
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end
end

function CodeGameScreenRollingJackpotMachine:scaleMainLayer()
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
            if display.height / display.width == 1024 / 768 then
                mainScale = 0.68
                self.m_machineNode:setPositionY(10)
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    end

end

function CodeGameScreenRollingJackpotMachine:drawReelArea()
    CodeGameScreenRollingJackpotMachine.super.drawReelArea(self)
    if self.m_onceClipNode and self.m_rollShadeFlag == true then
        self.m_rollShadeLayer = cc.LayerColor:create(cc.c4f(0,0,0,180))-- --  -- cc.c4f(0,0,0,255),
        self.m_rollShadeLayer:setContentSize(cc.size(slotW, slotH))
        self.m_rollShadeLayer:setAnchorPoint(cc.p(0, 0))
        self.m_rollShadeLayer:setVisible(false)
        local worldPos = self:getReelPos(1)
        local nodePos = self.m_onceClipNode:convertToNodeSpace(worldPos)
        self.m_rollShadeLayer:setPosition(nodePos)
        self.m_onceClipNode:addChild(self.m_rollShadeLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1)
    end
end

function CodeGameScreenRollingJackpotMachine:rollShadeFadein(_opacity)
    self.m_rollShadeLayer:stopAllActions()
    self.m_rollShadeLayer:setVisible(true)
    local fadeIn = cc.FadeTo:create(0.3, _opacity or 180)
    self.m_rollShadeLayer:runAction(fadeIn)
end

function CodeGameScreenRollingJackpotMachine:rollShadeFadeout()
    self.m_rollShadeLayer:stopAllActions()
    local fadeOut = cc.FadeTo:create(0.3, 0)
    self.m_rollShadeLayer:runAction(cc.Sequence:create(fadeOut, cc.CallFunc:create(function()
        self.m_rollShadeLayer:setVisible(false)
    end)))
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenRollingJackpotMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local aniTime = 3
    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenRollingJackpotMachine:waitWithDelay(time, endFunc)
    if time <= 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

return CodeGameScreenRollingJackpotMachine
