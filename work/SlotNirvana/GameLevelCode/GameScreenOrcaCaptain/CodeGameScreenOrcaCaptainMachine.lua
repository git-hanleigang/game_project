---
-- island li
-- 2019年1月26日
-- CodeGameScreenOrcaCaptainMachine.lua
-- 
-- 玩法：1、进入游戏选择spin的次数，每spin一次对应spin进度条增加一格，集满后wild框变为长wild，参与连线
--      2、收集：滚出bonus后，收集到对应列的位置，若对应列收集为两个时（收集区域收集满），则出现对应出现wild框
--      3、转盘：三个转盘图标（这里信号值给的90，因此叫它scatter）触发，转盘转动出钱或free或jackpot
--      4、free:出现三个框，每次spin变化位置，参与连线，会再触发转盘，若转到free,则增加次数
--      5、jackpot(多福多彩):点击中jackpot（常规多福多彩）
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "OrcaCaptainPublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenOrcaCaptainMachine = class("CodeGameScreenOrcaCaptainMachine", BaseSlotoManiaMachine)

CodeGameScreenOrcaCaptainMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenOrcaCaptainMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1  -- 自定义的小块类型
CodeGameScreenOrcaCaptainMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2  -- 自定义的小块类型
CodeGameScreenOrcaCaptainMachine.SYMBOL_SCORE_12 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3  -- 自定义的小块类型
CodeGameScreenOrcaCaptainMachine.SYMBOL_SCORE_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- 自定义的小块类型


-- 自定义动画的标识
CodeGameScreenOrcaCaptainMachine.SPIN_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1 --收集
CodeGameScreenOrcaCaptainMachine.SPIN_CHANGEWILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 2 --变wild
CodeGameScreenOrcaCaptainMachine.COLORFUL_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 5 --多福多彩
local COLLECT_NUM = 5
local FREE_OVER_REELS = {
    {6,9,8,7},
    {4,4,4,4},
    {1,0,2,2},
    {5,5,5,5},
    {7,10,11,6}
}

-- 构造函数
function CodeGameScreenOrcaCaptainMachine:ctor()
    CodeGameScreenOrcaCaptainMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeOrcaCaptainSrc.OrcaCaptainSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("OrcaCaptainLongRunControl",self) 


    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true

    self.collectItemList = {}
    self.wildKuangList = {}
    self.wildEffectList = {}

    self.wildKuangFreeList = {}
    self.wildKuangEffectFreeList = {}

    self.curSpinNum = 15

    self.curBonusListForBet = {}
    self.initBonusListForBet = {}

    self.wheelRecxData = nil

    self.bigWildForCol = {false,false,false,false,false}
    self.itemCollectNumForCol = {0,0,0,0,0}

    self.m_wheelEffectBeforeCoins = 0

    self.lastBonusSelect = 7

    self.bonusTxList = {}

    self.tempScatter = {}

    self.isResetCollect = false

    self.wildSoundIndex = 0
    --init
    self:initGame()
    
end

--[[
    初始化spine动画
]]
function CodeGameScreenOrcaCaptainMachine:initSpineUI()
    self.bigJvse = util_spineCreate("OrcaCaptain_juese", true, true)
    self:findChild("Node_juese"):addChild(self.bigJvse)
    self:setBigJvseSkin(1)

    -- self.m_bigWin = util_spineCreate("OrcaCaptain_bigwin", true, true)
    -- self:findChild("root"):addChild(self.m_bigWin)
    -- local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
    -- self.m_bigWin:setPosition(pos)
    -- self.m_bigWin:setVisible(false)

    -- self.m_spineGuochang1 = util_spineCreate("OrcaCaptain_guochang_1", true, true)
    -- self.m_spineGuochang1:setScale(self.m_machineRootScale)
    -- self:addChild(self.m_spineGuochang1, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    -- self.m_spineGuochang1:setPosition(display.width * 0.5, display.height * 0.5)
    -- self.m_spineGuochang1:setVisible(false)

    -- self.m_spineGuochang2 = util_spineCreate("OrcaCaptain_guochang_2", true, true)
    -- self.m_spineGuochang2:setScale(self.m_machineRootScale)
    -- self:addChild(self.m_spineGuochang2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
    -- self.m_spineGuochang2:setPosition(display.width * 0.5, display.height * 0.5)
    -- self.m_spineGuochang2:setVisible(false)

    -- self.m_spineGuochang3 = util_spineCreate("OrcaCaptain_guochang_3", true, true)
    -- self.m_spineGuochang3:setScale(self.m_machineRootScale)
    -- self:addChild(self.m_spineGuochang3, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 3)
    -- self.m_spineGuochang3:setPosition(display.width * 0.5, display.height * 0.5)
    -- self.m_spineGuochang3:setVisible(false)

    -- self.m_spineGuochang4 = util_spineCreate("OrcaCaptain_dfdc_guochang", true, true)
    -- self.m_spineGuochang4:setScale(self.m_machineRootScale)
    -- self:addChild(self.m_spineGuochang4, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
    -- self.m_spineGuochang4:setPosition(display.width * 0.5, display.height * 0.5)
    -- self.m_spineGuochang4:setVisible(false)

    -- self.m_jveSeGuoChang = util_spineCreate("OrcaCaptain_juese_2", true, true)
    -- self:findChild("Node_juese_2"):addChild(self.m_jveSeGuoChang)
    -- self.m_jveSeGuoChang:setVisible(false)

end

function CodeGameScreenOrcaCaptainMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenOrcaCaptainMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "OrcaCaptain"  
end

---
-- 返回网络数据关卡名字 普通情况下与 modulename一样
function CodeGameScreenOrcaCaptainMachine:getNetWorkModuleName()
    return "OrcaCaptainV2"
end


function CodeGameScreenOrcaCaptainMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    self.m_effect = cc.Node:create()
    self:findChild("root"):addChild(self.m_effect,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 20)

    self.orcaNode = cc.Node:create()
    self:findChild("root"):addChild(self.orcaNode)

    self.m_wildNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_wildNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    self.m_collectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_collectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_collectItemNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_collectItemNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_collectWildNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_collectWildNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    --多福多彩
    -- self.m_colorfulGameView = util_createView("CodeOrcaCaptainSrc.OrcaCaptainColorfulGame",{machine = self})
    -- self:findChild("Node_dfdc"):addChild(self.m_colorfulGameView)
    -- self.m_colorfulGameView:setVisible(false) 

    self:initJackPotBarView() 
    self:initProgressBar()

    self:showJveSeIdle(false)

    --选择按钮
    self.changeBottom = util_createView("CodeOrcaCaptainSrc.OrcaCaptainButtonView",self)
    self:findChild("Node_anniu"):addChild(self.changeBottom)

    self.m_bgBase = util_spineCreate("GameScreenOrcaCaptainBg2", true, true)
    self.m_gameBg:findChild("base"):addChild(self.m_bgBase)
    self.m_bgBase:setVisible(false)

    -- self.m_bgDfdc = util_spineCreate("GameScreenOrcaCaptainBg2", true, true)
    -- self.m_gameBg:findChild("dfdc"):addChild(self.m_bgDfdc)
    -- self.m_bgDfdc:setVisible(false)

    self:addAllCollectItem()
    -- self:addBonusTxForReels()

    self:createChooseView()

    self:updateShowUI(1)

    self:createBigWildForCol()
    -- self:createBigWildEffect()

    -- self:createWheelView()

    -- self:createWildShowLight()

    -- self:createFreeBigWildEffectForCol()

end

function CodeGameScreenOrcaCaptainMachine:getOrcaIdleName(isFree)
    local random = math.random(1, 90)
    if random < 30 then
        return "idleframe2",66/30
    elseif random <= 60 and random >= 30 then
        if isFree then
            return "idleframe5",63/30
        else
            return "idleframe3",66/30
        end
    else 
        return 0,0
    end
end

function CodeGameScreenOrcaCaptainMachine:showJveSeIdle(isFree)
    self.orcaNode:stopAllActions()
    local orcaName,orcaTime = self:getOrcaIdleName(isFree)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.bigJvse, "idleframe",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(160/30)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        if orcaTime > 0 then
            if orcaName == "idleframe3" then
                -- local isNotice = (math.random(1, 100) <= 30) 
                -- if isNotice then
                --     local isNotice2 = (math.random(1, 100) <= 50) 
                --     if isNotice2 then
                --         gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_aha)
                --     else
                --         gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_Wonderful)
                --     end
                -- end
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_big_jvese_show)
            end
            util_spinePlay(self.bigJvse,orcaName,false)
        end
        
    end)
    actList[#actList + 1] = cc.DelayTime:create(orcaTime)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:showJveSeIdle(isFree)
    end)
    self.orcaNode:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenOrcaCaptainMachine:setBigJvseSkin(index)
    if index == 2 then
        self.bigJvse:setSkin("free")
    else
        self.bigJvse:setSkin("base")
    end
end

-----------刷新显示相关
function CodeGameScreenOrcaCaptainMachine:updateShowUI(index)
    if index == 1 then          --base
        self.m_gameBg:findChild("base"):setVisible(true)
        self.m_gameBg:findChild("FG"):setVisible(false)
        self.m_gameBg:findChild("dfdc"):setVisible(false)
        self.m_bgBase:setVisible(true)
        util_spinePlay(self.m_bgBase, "idleframe",true)
        if self.m_bgDfdc then
            self.m_bgDfdc:setVisible(false)
        end
        
        self:findChild("Node_Base"):setVisible(true)
        self:findChild("Node_FG"):setVisible(false)
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_FG_reel"):setVisible(false)
    elseif index == 2 then      --free
        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("FG"):setVisible(true)
        self.m_gameBg:findChild("dfdc"):setVisible(false)
        self.m_bgBase:setVisible(false)
        if self.m_bgDfdc then
            self.m_bgDfdc:setVisible(false)
        end
        
        self:findChild("Node_Base"):setVisible(false)
        self:findChild("Node_FG"):setVisible(true)
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_FG_reel"):setVisible(true)
    elseif index == 3 then      --转盘
    else                        --多福多彩
        self.m_gameBg:findChild("base"):setVisible(false)
        self.m_gameBg:findChild("FG"):setVisible(false)
        self.m_gameBg:findChild("dfdc"):setVisible(true)
        self.m_bgBase:setVisible(false)
        if not self.m_bgDfdc then
            self.m_bgDfdc = util_spineCreate("GameScreenOrcaCaptainBg2", true, true)
            self.m_gameBg:findChild("dfdc"):addChild(self.m_bgDfdc)
        end
        self.m_bgDfdc:setVisible(true)
        util_spinePlay(self.m_bgDfdc, "idleframe2",true)
        self:findChild("Node_Base"):setVisible(false)
        self:findChild("Node_FG"):setVisible(false)
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_FG_reel"):setVisible(false)
    end
end



function CodeGameScreenOrcaCaptainMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound( "OrcaCaptainSounds/music_OrcaCaptain_enter.mp3" )
    end)
end

function CodeGameScreenOrcaCaptainMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenOrcaCaptainMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:upateBetLevel()
    --选择弹板
    self:showChooseView(false)
end

function CodeGameScreenOrcaCaptainMachine:addObservers()
    CodeGameScreenOrcaCaptainMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        else
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = self.m_publicConfig.SoundConfig["music_OrcaCaptain_last_win_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = self.m_publicConfig.SoundConfig["music_OrcaCaptain_free_win_"..soundIndex] 
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
    gLobalNoticManager:addObserver(self,function(self,params)
        self:upateBetLevel()
        if not params.p_isLevelUp then
            --判断进度条进度
            if self:getProgressShowNum() == 0 then
                self.isResetCollect = true
            else
                self.isResetCollect = false
            end
            self:changeBetForCollect()
            self:updateProgressForBet()
            self:updateCollectItemForBet(false)
        end
        
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,"SHOW_BONUS_MAP")

end

function CodeGameScreenOrcaCaptainMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenOrcaCaptainMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenOrcaCaptainMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_OrcaCaptain_10"
    end
    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_OrcaCaptain_11"
    end
    if symbolType == self.SYMBOL_SCORE_12 then
        return "Socre_OrcaCaptain_12"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS then
        return "Socre_OrcaCaptain_Bonus"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenOrcaCaptainMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenOrcaCaptainMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_11,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_12,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenOrcaCaptainMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:setBigJvseSkin(2)
        self:updateShowUI(2)
        self:showJveSeIdle(true)
        --刷新棋盘wild显示
        self:createFreeBigWildForCol(nil,true)
        self:isShowAllCollectItemForFree(true)
    end 

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenOrcaCaptainMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:stopLinesWinSound()

    self:hideBigWildEffect()
    self.changeBottom:setButtonEnabled(false)
    if self.m_bProduceSlots_InFreeSpin then
        self:showMoveWildIdle()
    else
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local wildLeftCount = selfData.wildLeftCount or 0     --剩余次数
        --wildLeftCount == 0 and
        if self.isResetCollect then       --增加一个条件
            --重置收集
            self.m_progressBarView:updateProgressNum(self.curSpinNum)      --刷新进度条样式
            self.m_progressBarView:resetItemForProgressNum()
            self.m_progressBarView:updateItemForNum(self.curSpinNum,false)       --刷新进度条item显示
            self:updateCollectItemForBet(true)
            self.bigWildForCol = {false,false,false,false,false}
            
        end
        
    end
    self.isResetCollect = false
    return false -- 用作延时点击spin调用
end

function CodeGameScreenOrcaCaptainMachine:operaEffectOver()
    CodeGameScreenOrcaCaptainMachine.super.operaEffectOver(self)
    if self:getCurrSpinMode() ~= AUTO_SPIN_MODE then
        self.changeBottom:setButtonEnabled(true)
    end
    
end

--
--单列滚动停止回调
--
function CodeGameScreenOrcaCaptainMachine:slotOneReelDown(reelCol)    
    CodeGameScreenOrcaCaptainMachine.super.slotOneReelDown(self,reelCol)
    if self:getGameSpinStage( ) == QUICK_RUN then
        
    else
        self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 
    end
    

end

--[[
    滚轮停止
]]
function CodeGameScreenOrcaCaptainMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
    CodeGameScreenOrcaCaptainMachine.super.slotReelDown(self)
    local winLines = self.m_reelResultLines or {}
    if #winLines > 0 then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            for i=1,COLLECT_NUM do
                self:changeFreeWildZorder(i,false)
            end
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local wildLeftCount = selfData.wildLeftCount or 0     --剩余次数
        if wildLeftCount == 1 then
            self.m_progressBarView:nextTriggerChangeBigWild(true)
        end
    end
    
end

---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenOrcaCaptainMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildLeftCount = selfData.wildLeftCount or 0     --剩余次数
    local wbPositions = selfData.wbPositions or {}
        
    if wildLeftCount == 0 then --框变wild
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.SPIN_CHANGEWILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SPIN_CHANGEWILD_EFFECT -- 动画类型
    end
    if table_length(wbPositions) > 0 then     --收集
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.SPIN_COLLECT_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SPIN_COLLECT_EFFECT -- 动画类型
    end
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenOrcaCaptainMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.SPIN_CHANGEWILD_EFFECT then
        self.isResetCollect = true
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:changeWildForCol(function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
    elseif effectData.p_selfEffectType == self.SPIN_COLLECT_EFFECT then
        self:flyBonusToCollectItem(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.COLORFUL_EFFECT then
        --进入多福多彩
        self:playColorfulGameEffect(effectData)
    end

    
    return true
end



function CodeGameScreenOrcaCaptainMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenOrcaCaptainMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenOrcaCaptainMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        else
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenOrcaCaptainMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenOrcaCaptainMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenOrcaCaptainMachine:checkRemoveBigMegaEffect()
    CodeGameScreenOrcaCaptainMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenOrcaCaptainMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeOrcaCaptainSrc.OrcaCaptainFreespinBarView")
    -- self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_FGbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenOrcaCaptainMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    -- self:delayCallBack(0.2,function ()
           gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_free_start_show)    
    -- end)
    local view = nil
    if isAuto then
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, nil, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, nil)
    end

    --底
    local di = util_spineCreate("FreeSpinStart_di", true, true)
    view:findChild("Node_di"):addChild(di)
    util_spinePlay(di, "start")
    performWithDelay(di,function ()
        util_spinePlay(di, "idle",true)
    end,240/30)
    
    --光
    local light = util_createAnimation("JackpotWinView_glow.csb")
    view:findChild("Node_glow"):addChild(light)
    light:runCsbAction("idle",true)

    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setBtnClickFunc(function()
        di:stopAllActions()
        util_spinePlay(di, "over")
        if func then
            func()
        end
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_click)  
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_free_start_hide)  
    end)
    return view
end

function CodeGameScreenOrcaCaptainMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = {}
    local view = nil
    ownerlist["m_lb_num"] = num
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_free_more)  
    if isAuto then
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
    --底
    local di = util_spineCreate("FreeSpinStart_di", true, true)
    view:findChild("Node_di"):addChild(di)
    util_spinePlay(di, "auto")
    --光
    local light = util_createAnimation("JackpotWinView_glow.csb")
    view:findChild("Node_glow"):addChild(light)
    light:runCsbAction("idle",true)

    view:findChild("root"):setScale(self.m_machineRootScale)

    return view
end

function CodeGameScreenOrcaCaptainMachine:triggerFreeSpinCallFun()
    -- 切换滚轮赔率表
    self:changeFreeSpinReelData()

    --做下判断 freespinMore 与 普通触发fs 防止fsmore 断线重连后不显示fs赢钱
    -- if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    -- end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum
    self.m_freeSpinOffSetCoins = 0
    -- 通知任务变化
    -- gLobalTaskManger:triggerTask(TASK_TRIGGER_FREE_SPIN)

    -- 处理free spin 后的回调
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
    -- gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER)  -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    -- self:resetMusicBg()
end

function CodeGameScreenOrcaCaptainMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("OrcaCaptainSounds/music_OrcaCaptain_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:delayCallBack(1,function ()
                --显示棋盘
                self:resetMusicBg()
                self.bigJvse:setVisible(true)
                self:showJveSeIdle(true)
                if self.m_wheelView then
                    self.m_wheelView:setVisible(false)
                end
                
                --刷新wild框显示
                self:isShowAllCollectItemForFree(true)
                self:findChild("Node_qipan"):setVisible(true)
            end)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
            end,true)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:resetMusicBg(nil,"OrcaCaptainSounds/music_OrcaCaptain_free_bg.mp3")
                self.m_baseFreeSpinBar:initTotalTimes(self.m_iFreeSpinTimes)
                self:showWheelToFreeGuoChang(function ()
                    if self.m_wheelView then
                        self.m_wheelView:setVisible(false)
                    end
                    
                    self:changeSymbolForFreeStart()
                    self:findChild("Node_qipan"):setVisible(true)
                    --改变ui显示
                    self:setBigJvseSkin(2)
                    self:updateShowUI(2)
                    self.bigJvse:setVisible(true)
                    self:showJveSeIdle(true)
                    --刷新wild框显示
                    self:isShowAllCollectItemForFree(true)
                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                end,function ()
                    self:triggerFreeSpinCallFun()
                    self:createFreeBigWildForCol(function ()
                        effectData.p_isPlay = true
                        self:playGameEffect() 
                    end,false)
                    
                end)
                      
            end)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenOrcaCaptainMachine:showFreeSpinOver(coins, num, func)

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 50)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_free_over_show)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    view:findChild("root"):setScale(self.m_machineRootScale)
    local jvese = util_spineCreate("OrcaCaptain_juese", true, true)
    view:findChild("Node_juese"):addChild(jvese)
    util_spinePlay(jvese, "idle1_tanban",true)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_click)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_free_over_hide)
    end)
    return view
end

function CodeGameScreenOrcaCaptainMachine:changeSymbolForFreeStart()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(node) and node.p_symbolType then
                local changeType = FREE_OVER_REELS[iCol][iRow] or 1
                self:changeSymbolType(node,changeType)
            else
                if iRow == 1 then
                    node = self:getBigFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if not tolua.isnull(node) and node.p_symbolType then
                        local changeType = FREE_OVER_REELS[iCol][iRow] or 1
                        self:changeSymbolType(node,changeType)
                        self:getSymbolTypeForChange(changeType,iRow,iCol)
                    end
                else
                    local changeType = FREE_OVER_REELS[iCol][iRow] or 1
                    self:getSymbolTypeForChange(changeType,iRow,iCol)
                end
                
            end
        end
    end
end

function CodeGameScreenOrcaCaptainMachine:changeRowAndColForBaseReels()

    local function changeRow(iRow)
        if iRow == 1 then
            return 4
        elseif iRow == 2 then
            return 3
        elseif iRow == 3 then
            return 2
        elseif iRow == 4 then
            return 1
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local baseReels = selfData.baseReels or {}
    local reels = baseReels.reels or {}
    local tempReels = {}
    if table_length(reels) <= 0 then
        return tempReels
    end
    local rowNum = table_length(reels)
    local colNum = table_length(reels[1])
    if rowNum > 0 and colNum > 0 then
        for i=1,colNum do
            tempReels[i] = {}
            for j=1,rowNum do
                local newRow = changeRow(j)
                tempReels[i][j] = reels[newRow][i]
            end
        end
    end
    return tempReels
end

--[[
    模仿initSlotNodes，重新生成一套轮盘显示
]]
function CodeGameScreenOrcaCaptainMachine:changeSymbolForFreeOver()
    
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local baseReels = selfData.baseReels or {}
    local reels = clone(baseReels.reels) or {}
    local newReels = self:changeRowAndColForBaseReels(reels)
    if table_length(newReels) <= 0 then
        return
    end
    self:removeSymbolForFreeOver()
    self.m_initGridNode = true
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local initDatas = newReels[colIndex]
        local parentData = self.m_slotParents[colIndex]
        local startIndex = 1
        --大信号数量
        local bigSymbolCount = 0
        for rowIndex = 1, rowCount do
            local symbolType = initDatas[startIndex]
            startIndex = startIndex + 1
            if startIndex > #initDatas then
                startIndex = 1
            end

            --判断是否是否属于需要隐藏
            local isNeedHide = false
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                bigSymbolCount = bigSymbolCount + 1
                if bigSymbolCount > 1 then
                    isNeedHide = true
                    symbolType = 0
                end

                if bigSymbolCount == self.m_bigSymbolInfos[symbolType] then
                    bigSymbolCount = 0
                end
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex

            if isNeedHide then
                node:setVisible(false)
            end

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
            if (node.p_symbolType == 0) and (rowIndex == 1) and (initDatas[2] ~= 0) then        --向下移动一格，防止盖住第二行小块
                node:setPositionY(halfNodeH - columnData.p_showGridH)
            end
        end
    end
    self:initGridList()
end

function CodeGameScreenOrcaCaptainMachine:removeSymbolForFreeOver()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(node) and node.p_symbolType then
                self:moveDownCallFun(node, node.p_cloumnIndex)      --删除小块（调用这个函数为了回收小块到池中去）
            else
                node = self:getBigFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if not tolua.isnull(node) and node.p_symbolType then
                    self:moveDownCallFun(node, node.p_cloumnIndex)      --删除小块（调用这个函数为了回收小块到池中去）
                end
            end
        end
    end
end


function CodeGameScreenOrcaCaptainMachine:getSymbolTypeForChange(changeType,iRow,iCol)
    local symbolType = changeType
    local parentData = self.m_slotParents[iCol]
    if symbolType then

        local newNode =  self:getSlotNodeWithPosAndType( symbolType , iRow, iCol , false)
        local zorder = self:getBounsScatterDataZorder(symbolType)
        parentData.slotParent:addChild(
            newNode,
            REEL_SYMBOL_ORDER.REEL_ORDER_2,
            self:getNodeTag(iCol,iRow,SYMBOL_NODE_TAG)
        )
        newNode.m_symbolTag = SYMBOL_NODE_TAG
        newNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
        newNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        newNode.m_isLastSymbol = true
        newNode.m_bRunEndTarge = false
        local columnData = self.m_reelColDatas[iCol]
        newNode.p_slotNodeH = columnData.p_showGridH         
        newNode:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
        local halfNodeH = columnData.p_showGridH * 0.5
        newNode:setPositionY(  (iRow - 1) * columnData.p_showGridH + halfNodeH )
    end
end

function CodeGameScreenOrcaCaptainMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("OrcaCaptainSounds/music_OrcaCaptain_over_fs.mp3")
    self:clearCurMusicBg()
    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    local view = self:showFreeSpinOver(
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:showFreeToBaseGuoChang(function ()
                --清理连线框
                self:clearWinLineEffect()
                --改变ui显示
                self:setBigJvseSkin(1)
                self:updateShowUI(1)
                self:showJveSeIdle(false)
                --刷新wild框显示
                self:removeAllWildKuangFree()
                self:hideBigWildEffect()
                self:isShowAllCollectItemForFree(false)
                self:changeSymbolForFreeOver()
            end,function ()
                self:triggerFreeSpinOverCallFun()
            end)
            
        end
    )
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.98,sy=1},659)    
end

function CodeGameScreenOrcaCaptainMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local lineLen = #self.m_reelResultLines
    local scatterLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            scatterLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- 停掉背景音乐
        self:clearCurMusicBg()
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    local waitTime = 0.5

    self:delayCallBack(waitTime,function ()
        self:showFreeSpinView(effectData)
    end)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

function CodeGameScreenOrcaCaptainMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeOrcaCaptainSrc.OrcaCaptainJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView,1) --修改成自己的节点  
    local ratio = display.height / display.width
    if ratio == 1970/768 then
        local jackpotPosY = 120
        self.m_jackPotBarView:setPositionY(jackpotPosY)
    end 
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenOrcaCaptainMachine:showJackpotView(func)
    local jackpotType,coins = self:getWinJackpotCoinsAndType()
    local viewName = "CodeOrcaCaptainSrc.OrcaCaptainJackpotWinView"
    if string.lower(jackpotType)  == "grand" then
        viewName = "CodeOrcaCaptainSrc.OrcaCaptainGrandJackpotWinView"
    end
    local view = util_createView(viewName,{
        jackpotType = jackpotType,
        winCoin = coins,
        machine = self,
        func = function(  )
            local isNotifyUpdateTop = true
            if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
                isNotifyUpdateTop = false
            end
            if self:checkHasBigWin() == false then
                self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins,self.COLORFUL_EFFECT)
            end
            self:updateBottomUICoins(coins,isNotifyUpdateTop,false,true)
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenOrcaCaptainMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if self:checkSymbolBulingAnimPlay(_slotNode) then
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
                
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                self:changeFreeWildZorder(_slotNode.p_cloumnIndex,true)
                --2.播落地动画

                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            end
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenOrcaCaptainMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                --isPlayTipAnima
                --isPlayTipAnimaForOrca
                if self:isPlayTipAnimaForOrca(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif _slotNode.p_symbolType == 94 then
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    return false
                else
                    if self:isShowSymbolBuling(_slotNode.p_cloumnIndex) then
                        return true
                    end
                end
                
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenOrcaCaptainMachine:changeFreeWildZorder(col,zOrder)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        return
    end
    local moveWild = self:getMoveWildForCol(col)
    if not tolua.isnull(moveWild) then
        if zOrder == true then
            util_changeNodeParent(self.m_clipParent, moveWild,100)
            local pos = util_convertToNodeSpace(self:findChild("Node_lock_"..col),self.m_clipParent)
            moveWild:setPosition(pos)
        else
            util_changeNodeParent(self:findChild("Node_wild"), moveWild)
            local pos = util_convertToNodeSpace(self:findChild("Node_lock_"..col),self:findChild("Node_wild"))
            moveWild:setPosition(pos)
        end
    end
end

function CodeGameScreenOrcaCaptainMachine:isPlayTipAnimaForOrca(matrixPosY, matrixPosX, node)
    if matrixPosY == 1 or matrixPosY == 5 then
        return false
    end
    if matrixPosY == 2 then
        return true
    end
    local scatterNum = 0
    for iCol = 1 ,(matrixPosY - 1) do
        for iRow = 1,self.m_iReelRowNum do
            local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        
            if symbolType then
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    scatterNum = scatterNum + 1  
                end
            end
            
        end
        
    end

    if scatterNum >= matrixPosY - 2 then
        return true
    end

    return false
end

function CodeGameScreenOrcaCaptainMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 

    local curLongRunData = self.m_longRunControl:getCurLongRunData() or {}
    local LegitimatePos = curLongRunData.LegitimatePos or {}
    if table_length(LegitimatePos) > 0  then
        for i=1,#LegitimatePos do
            local posInfo = LegitimatePos[i]
            if  table_vIn(posInfo,_slotNode.p_symbolType) and
                    table_vIn(posInfo,_slotNode.p_cloumnIndex) and
                        table_vIn(posInfo,_slotNode.p_rowIndex)  then
                return true
            end
        end
    end
    return false    
end


function CodeGameScreenOrcaCaptainMachine:setReelRunInfo()
    -- assert(nil,"自己配置快滚信息")
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    local longRunConfigs = {}
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["234"] ,["symbolType"] = {90}} )
    -- -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {200},["musRunInfos"] = {["startCol"] = 1,["endCol"]=3}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态    
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenOrcaCaptainMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenOrcaCaptainMachine.super.MachineRule_ResetReelRunData(self)    
end

---
--添加金边
function CodeGameScreenOrcaCaptainMachine:creatReelRunAnimation(col)
    if self:getGameSpinStage( ) == QUICK_RUN then
        return
    end
    self:changeFreeWildZorder(col,true)
    CodeGameScreenOrcaCaptainMachine.super.creatReelRunAnimation(self,col)
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenOrcaCaptainMachine:isPlayExpect(reelCol)
    if reelCol <= self.m_iReelColumnNum then
        local bHaveLongRun = false
        for i = 1, reelCol do
            local reelRunData = self.m_reelRunInfo[i]
            if reelRunData:getNextReelLongRun() == true then
                bHaveLongRun = true
                break
            end
        end
        if bHaveLongRun and self.m_reelRunInfo[reelCol]:getNextReelLongRun() then
            return true
        end
    end
    return false    
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenOrcaCaptainMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance() then

        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
        
    else
        if type(_func) == "function" then
            _func()
        end
    end    
end

--[[
        播放预告中奖动画
        预告中奖通用规范
        命名:关卡名+_yugao
        时间线:actionframe_yugao(当预告中奖时间比滚动时间短时,应调整时间线长度)
        挂点:主轮盘node_yugao节点,若该挂点不存在则直接挂在root上
        下面提供了各种类型动效的使用方式,根据具体需求择取试用的创建方式即可
    ]]
function CodeGameScreenOrcaCaptainMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = false
    --动效执行时间
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("Node_yugao")
    if not parentNode then
        parentNode = self:findChild("root")
    end

    
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_wheel_yuGao)
    --大角色
    self.orcaNode:stopAllActions()
    util_spinePlay(self.bigJvse, "actionframe_yugao")
    util_spineEndCallFunc(self.bigJvse, "actionframe_yugao", function ()
        if self.m_bProduceSlots_InFreeSpin then
            self:showJveSeIdle(true)
        else
            self:showJveSeIdle(false)
        end
        
    end)
    
    --创建对应格式的spine
    local spineAni = util_spineCreate("OrcaCaptain_yugao",true,true)
    if parentNode and not tolua.isnull(spineAni) then
        parentNode:addChild(spineAni)
        util_spinePlay(spineAni,"actionframe_yugao")
        util_spineEndCallFunc(spineAni,"actionframe_yugao",function()
            spineAni:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            self:delayCallBack(0.1,function()
                spineAni:removeFromParent()
            end)
            
        end)
    end
    
    aniTime = spineAni:getAnimationDurationTime("actionframe_yugao")

    if self.b_gameTipFlag then
        --计算延时,预告中奖播完时需要刚好停轮
        local delayTime = self:getRunTimeBeforeReelDown()

        --预告中奖时间比滚动时间短,直接返回即可
        if aniTime <= delayTime then
            if type(func) == "function" then
                func()
            end
        else
            self:delayCallBack(aniTime - delayTime,function()
                if type(func) == "function" then
                    func()
                end
            end)
        end
        return
    end

    if type(func) == "function" then
        func()
    end    
end

function CodeGameScreenOrcaCaptainMachine:beginReel()
    CodeGameScreenOrcaCaptainMachine.super.beginReel(self)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for i=1,COLLECT_NUM do
            self:changeFreeWildZorder(i,false)
        end
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenOrcaCaptainMachine:showEffect_runBigWinLightAni(effectData)

    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local posY = 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    end
    
    
    --通用底部跳字动效
    local winCoins = self.m_runSpinResultData.p_winAmount or 0
    local params = {
        overCoins  = winCoins,
        jumpTime   = 1,
        animName   = "actionframe3",
    }
    self:playBottomBigWinLabAnim(params)
    
    self:showBigWinLight(function()

        effectData.p_isPlay = true
        self:playGameEffect()
    end)

    return true
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenOrcaCaptainMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local aniTime = 3
    util_shakeNode(rootNode,5,10,aniTime)
    self:showBigWinEffect()
    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenOrcaCaptainMachine:showBigWinEffect()
    if not self.m_bigWin then
        self.m_bigWin = util_spineCreate("OrcaCaptain_bigwin", true, true)
        self:findChild("root"):addChild(self.m_bigWin)
        local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
        self.m_bigWin:setPosition(pos)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_big_win_show)
    local isNotice = (math.random(1, 100) <= 30) 
    if isNotice then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_gold_spray)
    end
    self.m_bigWin:setVisible(true)
    util_spinePlay(self.m_bigWin, "actionframe_bigwin")
    util_spineEndCallFunc(self.m_bigWin, "actionframe_bigwin", function ()
        self.m_bigWin:setVisible(false)
    end)
    --大角色
    self.orcaNode:stopAllActions()
    util_spinePlay(self.bigJvse, "actionframe_bigwin")
    util_spineEndCallFunc(self.bigJvse, "actionframe_bigwin", function ()
        if self.m_bProduceSlots_InFreeSpin then
            self:showJveSeIdle(true)
        else
            self:showJveSeIdle(false)
        end
    end)
end

function CodeGameScreenOrcaCaptainMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    local time = self:getShowLineWaitTime()
    

    if time then
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            0.5
        )
    else
        local features = self.m_runSpinResultData.p_features or {}
        local waitTime = 0
        if (#features >= 2 and features[2] > 0) then        --触发玩法
            waitTime = 2
        end
        self:delayCallBack(waitTime,function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
    end


    return true
end

-- function CodeGameScreenOrcaCaptainMachine:changeBaseWildZorder(col,zOrder)
--     local wildKuang = self.wildKuangList[col]
--     if not tolua.isnull(wildKuang) then
--         if zOrder == true then
--             util_changeNodeParent(self.m_clipParent, wildKuang,100)
--             local pos = util_convertToNodeSpace(self:findChild("Node_lock_"..col),self.m_clipParent)
--             wildKuang:setPosition(pos)
--         else
--             util_changeNodeParent(self:findChild("Node_lock_"..col), wildKuang)
--             -- local pos = util_convertToNodeSpace(self:findChild("Node_lock_"..col),self:findChild("Node_wild"))
--             wildKuang:setPosition(cc.p(0,0))
--         end
--     end
-- end

function CodeGameScreenOrcaCaptainMachine:getTempScatterForTrigger(node)
    local iCol = node.p_cloumnIndex
    local iRow = node.p_rowIndex
    local nodeIndex = self:getPosReelIdx(iRow, iCol)
    local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    local newStartPos = self:findChild("effect_node"):convertToNodeSpace(startPos)
    local newBonusSpine = util_spineCreate("Socre_OrcaCaptain_Scatter",true,true)
    self:findChild("effect_node"):addChild(newBonusSpine)
    newBonusSpine:setPosition(newStartPos)
    local zOder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    newBonusSpine:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 + iCol * 10 - iRow)
    return newBonusSpine
end

function CodeGameScreenOrcaCaptainMachine:changeBaseWildAct()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildLeftCount = selfData.wildLeftCount or 0     --剩余次数
    for k,wildKuang in pairs(self.wildKuangList) do
        if not tolua.isnull(wildKuang) and wildLeftCount == 0 then
            wildKuang.m_curAniName = "idleframe2"
            util_spinePlay(wildKuang, "idleframe2",true)
        end
    end
end
--[[
        bonus玩法
    ]]
function CodeGameScreenOrcaCaptainMachine:showEffect_Bonus(effectData)
    -- local tempScatter = {}
    self:clearCurMusicBg()

    --记录转盘前的钱数
    self.m_wheelEffectBeforeCoins = self.m_runSpinResultData.p_winAmount or 0

    self:clearWinLineEffect()
    self:hideBigWildEffect()
    if self.m_bProduceSlots_InFreeSpin then
        self:showMoveWildIdle()
    else
        self:changeBaseWildAct()
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    -- 播放震动
    self:levelDeviceVibrate(6, "bonus")
    --触发动画
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_base_wheel_trigger)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(node) and node.p_symbolType then
                if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    node:setVisible(false)
                    node:changeParentToOtherNode(self.m_clipParent)
                    local newBonusSpine = self:getTempScatterForTrigger(node)
                    self.tempScatter[#self.tempScatter + 1] = newBonusSpine
                    util_spinePlay(newBonusSpine, "actionframe", false)
                end
            end
        end
    end
    --开始弹板
    self:delayCallBack(2,function ()
        
        -- for iCol = 1, self.m_iReelColumnNum do
        --     for iRow = 1, self.m_iReelRowNum do
        --         local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
        --         if not tolua.isnull(node) and node.p_symbolType then
        --             if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        --                 -- if not self.m_bProduceSlots_InFreeSpin then
        --                 --     self:changeBaseWildZorder(node.p_cloumnIndex,true)
        --                 -- end
        --                 node:setVisible(true)
        --                 node:runAnim("idleframe2",true)
        --             end
        --         end
        --     end
        -- end

        self:showWheelViewStart(function ()
            
        end,true)
        self:delayCallBack(140/60 - 0.5,function ()
            self:showWheelView(effectData)
        end)
    end)

    return true    
end

--[[
        获取jackpot类型及赢得的金币数
    ]]
function CodeGameScreenOrcaCaptainMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        return string.lower(jackpotType),coins
    end
    return "",0    
end

--初始化收集的数据（gameConf+ig里存对应bet的收集列表）
function CodeGameScreenOrcaCaptainMachine:initGameStatusData( gameData )
    CodeGameScreenOrcaCaptainMachine.super.initGameStatusData(self,gameData)
    self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local gameConfig = gameData.gameConfig or {}
    local extra = gameConfig.extra or {}
    if extra.initStore then
        self.initBonusListForBet = extra.initStore
    end
    if extra.storeState then
        self.curBonusListForBet = extra.storeState
    end
    if extra.lastBonusSelect then
        self.lastBonusSelect = extra.lastBonusSelect
        self:updateCurSpinNum(self.lastBonusSelect)
    end
end

function CodeGameScreenOrcaCaptainMachine:getMinBet( )
    local minBet = 0
    local maxBet = 0
    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end
    if self.m_specialBets and self.m_specialBets[1] then
        minBet = self.m_specialBets[1].p_totalBetValue
    end

    return minBet
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenOrcaCaptainMachine:upateBetLevel()
    local minBet = self:getMinBet( )
    self:updatProgressLock( minBet ) 
end

function CodeGameScreenOrcaCaptainMachine:unlockHigherBet()
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
    if betCoin >= self:getMinBet() then
        return
    end

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local bets = betList[i]
        if bets.p_totalBetValue >= self:getMinBet() then
            globalData.slotRunData.iLastBetIdx = bets.p_betId
            break
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function CodeGameScreenOrcaCaptainMachine:updatProgressLock( minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1 
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0  
            --弹出弹板
            if self.curSpinNum == 20 then
                self:showChooseView(false)
            end
        end
        
    end 
end

function CodeGameScreenOrcaCaptainMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2
    local tempPosY = 0

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
            local ratio = display.height / display.width
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            if ratio == 1228 / 768 then
                mainScale = mainScale * 1.02
                tempPosY = 5
            elseif ratio >= 1152/768 and ratio < 1228/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            elseif ratio >= 920/768 and ratio < 1152/768 then
                local mul = (1152 / 768 - display.height / display.width) / (1152 / 768 - 920 / 768)
                mainScale = mainScale + 0.05 * mul + 0.03--* 1.16
                tempPosY = 25
            elseif ratio < 1152/768 then
                mainScale = mainScale * 1.05
                tempPosY = 10
            end
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(tempPosY)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end


function CodeGameScreenOrcaCaptainMachine:requestSpinResult()
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
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    
    self:updateJackpotList()
    
    self:setSpecialSpinStates(false )
    if self.m_betLevel then
        self.m_iBetLevel = self.m_betLevel
    end
    
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel,
        bonusSelect = self.curSpinNum
    }
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end


function CodeGameScreenOrcaCaptainMachine:updateNetWorkData()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:wildMoveForData(function ()
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

            self.m_isWaitingNetworkData = false
            self:operaNetWorkData() -- end
        end)
    else
        self:showFeatureGameTip(
            function()
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

                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end
        )
        --刷新curBonusListForBet
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local wildLeftCount = selfData.wildLeftCount or 0     --剩余次数
        local wbPositions = selfData.wbPositions or {}
        local storeState = selfData.storeState or {}
        if table_length(storeState) > 0 then
            self.curBonusListForBet = storeState
        end
        self:updateProgressForSpin()
    end
    
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenOrcaCaptainMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    self:hideBigWildEffect()
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

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            node:runAnim("actionframe", true)
            
            
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if self:isHiteWinFrame2(symPosData.iY) then
                local wildEffect = self.wildEffectList[symPosData.iY]
                if not wildEffect then
                    wildEffect = util_createAnimation("WinFrameOrcaCaptain_2.csb")
                    self:findChild("Node_shouji_"..symPosData.iY):addChild(wildEffect)
                    self.wildEffectList[symPosData.iY] = wildEffect
                end
                wildEffect:setVisible(true)
                wildEffect:runCsbAction("actionframe",true)
            end
        else
            if self:isHiteWinFrame(symPosData.iY) then
                local wildEffect = self.wildEffectList[symPosData.iY]
                if not wildEffect then
                    wildEffect = util_createAnimation("WinFrameOrcaCaptain_2.csb")
                    self:findChild("Node_shouji_"..symPosData.iY):addChild(wildEffect)
                    self.wildEffectList[symPosData.iY] = wildEffect
                end
                wildEffect:setVisible(true)
                wildEffect:runCsbAction("actionframe",true)
            end
        end
        
    end

    self:showEachLineSlotNodeLineAnim(frameIndex)
end

-- ---
-- -- 显示所有的连线框
-- --
function CodeGameScreenOrcaCaptainMachine:showAllFrame(winLines)
    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0

    --大连线框隐藏
    self:hideBigWildEffect()
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            -- end
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen()

                local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
                local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(cc.p(posX, posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    if self:isHiteWinFrame2(symPosData.iY) then
                        local wildEffect = self.wildEffectList[symPosData.iY]
                        if not wildEffect then
                            wildEffect = util_createAnimation("WinFrameOrcaCaptain_2.csb")
                            self:findChild("Node_shouji_"..symPosData.iY):addChild(wildEffect)
                            self.wildEffectList[symPosData.iY] = wildEffect
                        end
                        wildEffect:setVisible(true)
                        wildEffect:runCsbAction("actionframe",true)
                    end
                else
                    if self:isHiteWinFrame(symPosData.iY) then
                        local wildEffect = self.wildEffectList[symPosData.iY]
                        if not wildEffect then
                            wildEffect = util_createAnimation("WinFrameOrcaCaptain_2.csb")
                            self:findChild("Node_shouji_"..symPosData.iY):addChild(wildEffect)
                            self.wildEffectList[symPosData.iY] = wildEffect
                        end
                        wildEffect:setVisible(true)
                        wildEffect:runCsbAction("actionframe",true)
                    end
                end
                
                
            end
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenOrcaCaptainMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            local isWild = self:isHiteWinFrame(slotsNode.p_cloumnIndex)
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                isWild = self:isHiteWinFrame2(slotsNode.p_cloumnIndex)
            end
            if not isWild then
                slotsNode:runLineAnim()
                if self.m_bGetSymbolTime == true then
                    animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
                end
            else
                self:bigWildShowAct(slotsNode.p_cloumnIndex)
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
function CodeGameScreenOrcaCaptainMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            local isWild = self:isHiteWinFrame(slotsNode.p_cloumnIndex)
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                isWild = self:isHiteWinFrame2(slotsNode.p_cloumnIndex)
            end
            if not isWild then
                slotsNode:runIdleAnim()
            else
                self:bigWildIdleAct(slotsNode.p_cloumnIndex)
            end
        end
    end
end

function CodeGameScreenOrcaCaptainMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    local isWild = self:isHiteWinFrame(slotsNode.p_cloumnIndex)
                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        isWild = self:isHiteWinFrame2(slotsNode.p_cloumnIndex)
                    end
                    if not isWild then
                        slotsNode:runLineAnim()
                    else
                        self:bigWildShowAct(slotsNode.p_cloumnIndex)
                    end
                end
            end
        end
    end
end


------------进度条
function CodeGameScreenOrcaCaptainMachine:initProgressBar()
    self.m_progressBarView = util_createView("CodeOrcaCaptainSrc.OrcaCaptainProgressView")
    self:findChild("Node_jindutiao"):addChild(self.m_progressBarView) --修改成自己的节点 
end

function CodeGameScreenOrcaCaptainMachine:updateProgressForBet()
    self.m_progressBarView:updateProgressNum(self.curSpinNum)      --刷新进度条样式
    self.m_progressBarView:resetItemForProgressNum()
    local progressNum = self:getProgressShowNum()
    self.m_progressBarView:updateItemForNum(progressNum,false)       --刷新进度条item显示
end

function CodeGameScreenOrcaCaptainMachine:updateProgressForSpin()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildLeftCount = selfData.wildLeftCount or 0
    self.m_progressBarView:updateItemForNum(wildLeftCount,true)       --刷新进度条item显示
end

--获取进度条显示数量
function CodeGameScreenOrcaCaptainMachine:getProgressShowNum()
    local betCoin = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local betState = self.curBonusListForBet[tostring(betCoin)] or {}
    local index = self:getIndexForSpinNum()
    local betStateForSpin = betState[index] or {}
    if table_length(betStateForSpin) <= 0 then      --从初始化里取
        
        local initprogressNum = self.initBonusListForBet[index][6] or 6
        return initprogressNum
    end
    local progressNum = betStateForSpin[6] or self.curSpinNum
    return progressNum
end

function CodeGameScreenOrcaCaptainMachine:getIndexForSpinNum()
    if self.curSpinNum == 7 then
        return 1
    elseif self.curSpinNum == 10 then
        return 2
    elseif self.curSpinNum == 20 then
        return 4
    else
        return 3
    end
end

-------------过场

--进入、退出转盘过场
function CodeGameScreenOrcaCaptainMachine:showWheelGuoChang(isOver,func)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.orcaNode:stopAllActions()
    if isOver then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_wheel_guoChang_show)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_wheelOver_guoChang_show)
    end
    
    util_spinePlay(self.bigJvse, "actionframe_guochang")
    if not self.m_jveSeGuoChang then
        self.m_jveSeGuoChang = util_spineCreate("OrcaCaptain_juese_2", true, true)
        self:findChild("Node_juese_2"):addChild(self.m_jveSeGuoChang)
    end
    self.m_jveSeGuoChang:setVisible(true)
    util_spinePlay(self.m_jveSeGuoChang, "actionframe_guochang2")
    util_spineEndCallFunc(self.m_jveSeGuoChang, "actionframe_guochang2", function ()
        self.m_jveSeGuoChang:setVisible(false)
    end)
    self:delayCallBack(60/30,function ()
        
        if func then
            func()
        end
    end)
end

--进入free过场
function CodeGameScreenOrcaCaptainMachine:showWheelToFreeGuoChang(func1,func2)
    if not self.m_spineGuochang1 then
        self.m_spineGuochang1 = util_spineCreate("OrcaCaptain_guochang_1", true, true)
        self.m_spineGuochang1:setScale(self.m_machineRootScale)
        self:addChild(self.m_spineGuochang1, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
        self.m_spineGuochang1:setPosition(display.width * 0.5, display.height * 0.5)
    end
    if not self.m_spineGuochang3 then
        self.m_spineGuochang3 = util_spineCreate("OrcaCaptain_guochang_3", true, true)
        self.m_spineGuochang3:setScale(self.m_machineRootScale)
        self:addChild(self.m_spineGuochang3, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 3)
        self.m_spineGuochang3:setPosition(display.width * 0.5, display.height * 0.5)
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_free_guoChang_show)
    self.m_spineGuochang1:setVisible(true)
    self.m_spineGuochang3:setVisible(true)
    util_spinePlay(self.m_spineGuochang1, "actionframe_guochang2")
    util_spineEndCallFunc(self.m_spineGuochang1, "actionframe_guochang2", function ()
        self.m_spineGuochang1:setVisible(false)
    end)
    util_spinePlay(self.m_spineGuochang3, "actionframe_guochang2")
    util_spineEndCallFunc(self.m_spineGuochang3, "actionframe_guochang2", function ()
        self.m_spineGuochang3:setVisible(false)
    end)
    self:delayCallBack(30/30,function ()
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(61/30,function ()
        if func2 then
            func2()
        end
    end)
end

--出free过场
function CodeGameScreenOrcaCaptainMachine:showFreeToBaseGuoChang(func1,func2)
    if not self.m_spineGuochang1 then
        self.m_spineGuochang1 = util_spineCreate("OrcaCaptain_guochang_1", true, true)
        self.m_spineGuochang1:setScale(self.m_machineRootScale)
        self:addChild(self.m_spineGuochang1, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
        self.m_spineGuochang1:setPosition(display.width * 0.5, display.height * 0.5)
    end
    if not self.m_spineGuochang2 then
        self.m_spineGuochang2 = util_spineCreate("OrcaCaptain_guochang_2", true, true)
        self.m_spineGuochang2:setScale(self.m_machineRootScale)
        self:addChild(self.m_spineGuochang2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
        self.m_spineGuochang2:setPosition(display.width * 0.5, display.height * 0.5)
    end
    if not self.m_spineGuochang3 then
        self.m_spineGuochang3 = util_spineCreate("OrcaCaptain_guochang_3", true, true)
        self.m_spineGuochang3:setScale(self.m_machineRootScale)
        self:addChild(self.m_spineGuochang3, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 3)
        self.m_spineGuochang3:setPosition(display.width * 0.5, display.height * 0.5)
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_base_guoChang_show)
    self.m_spineGuochang1:setVisible(true)
    self.m_spineGuochang2:setVisible(true)
    self.m_spineGuochang3:setVisible(true)
    util_spinePlay(self.m_spineGuochang1, "actionframe_guochang")
    util_spineEndCallFunc(self.m_spineGuochang1, "actionframe_guochang", function ()
        self.m_spineGuochang1:setVisible(false)
    end)
    util_spinePlay(self.m_spineGuochang2, "actionframe_guochang")
    util_spineEndCallFunc(self.m_spineGuochang2, "actionframe_guochang", function ()
        self.m_spineGuochang2:setVisible(false)
    end)
    util_spinePlay(self.m_spineGuochang3, "actionframe_guochang")
    util_spineEndCallFunc(self.m_spineGuochang3, "actionframe_guochang", function ()
        self.m_spineGuochang3:setVisible(false)
    end)
    self:delayCallBack(30/30,function ()
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(61/30,function ()
        if func2 then
            func2()
        end
    end)
end

--进入多福多彩过场
function CodeGameScreenOrcaCaptainMachine:showWheelToColorfulGuoChang(isOver,func1,func2)
    if not self.m_spineGuochang4 then
        self.m_spineGuochang4 = util_spineCreate("OrcaCaptain_dfdc_guochang", true, true)
        self.m_spineGuochang4:setScale(self.m_machineRootScale)
        self:addChild(self.m_spineGuochang4, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
        self.m_spineGuochang4:setPosition(display.width * 0.5, display.height * 0.5)
    end
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    if isOver then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_color_guoChang_show)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_colorToBase_guoChang_show)
    end
    
    self.m_spineGuochang4:setVisible(true)
    util_spinePlay(self.m_spineGuochang4, "actionframe_guochang")
    util_spineEndCallFunc(self.m_spineGuochang4, "actionframe_guochang", function ()
        self.m_spineGuochang4:setVisible(false)
    end)
    self:delayCallBack(20/30,function ()
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(52/30,function ()
        if func2 then
            func2()
        end
    end)
end

-------------收集

--切换bet时
function CodeGameScreenOrcaCaptainMachine:changeBetForCollect()
    local collectNodes = self.m_collectNode:getChildren()         --清理临时飞行的bonus
    for k,collectNode in pairs(collectNodes) do
        collectNode:stopAllActions()
        collectNode:removeFromParent()
    end
    self.m_collectItemNode:stopAllActions()
    self.m_collectWildNode:stopAllActions()
    for i=1,COLLECT_NUM do
        local wildItem = self.wildKuangList[i]
        local collectItem = self.collectItemList[i]
        local bonusTxItem = self.bonusTxList[i]
        if not tolua.isnull(wildItem) then
            wildItem:stopAllActions()
            wildItem:setVisible(false)
            wildItem.isShow = false
        end
        if not tolua.isnull(collectItem) then
            collectItem:runCsbAction("idle")
        end
        if not tolua.isnull(bonusTxItem) then
            bonusTxItem:setVisible(false)
        end
    end
end

--飞bonus到收集节点
function CodeGameScreenOrcaCaptainMachine:flyBonusToCollectItem(_func)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wbPositions = selfData.wbPositions or {}
    local wildLeftCount = selfData.wildLeftCount or 0     --剩余次数
    local wbCounts = selfData.wbCounts
    local isShowSound = true
    -- self.m_bottomUI:updateBetEnable(false)
    for i,posIndex in ipairs(wbPositions) do
        local bonusSymbol = self:getSymbolByPosIndex(posIndex)
        if bonusSymbol then
            local startPos = util_convertToNodeSpace(bonusSymbol,self.m_collectNode)
            local endNode = self:getCollectEndNode(posIndex)
            local endPos = util_convertToNodeSpace(endNode,self.m_collectNode)
            --创建临时bonus飞25/60s
            local tempBonus = util_createAnimation("Socre_OrcaCaptain_Bonus.csb")
            local zOder = REEL_SYMBOL_ORDER.REEL_ORDER_2 + bonusSymbol.p_cloumnIndex * 10 - bonusSymbol.p_rowIndex
            self.m_collectNode:addChild(tempBonus,zOder)
            tempBonus:setPosition(startPos)
            local moveAct = cc.EaseIn:create(cc.MoveTo:create(25/60,endPos),1)
            local callFunc1 = cc.CallFunc:create(function(  )
                tempBonus:runCsbAction("shouji")
                self:showBonusTxForCol(bonusSymbol.p_cloumnIndex)
            end)
            local act_move = cc.Spawn:create(moveAct, callFunc1)
            local callFunc2 = cc.CallFunc:create(function(  )
                tempBonus:removeFromParent()
            end)
            if isShowSound then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_fly_bonus)
                isShowSound = false
            end
            tempBonus:runAction(cc.Sequence:create(act_move,callFunc2))
        end
        
    end
    performWithDelay(self.m_collectItemNode,function ()
        self:updateCollectItem(wbCounts)
    end,26/60)

    local time = 0.3    --只收集
    local features = self.m_runSpinResultData.p_features or {}
    
    if self:isUpdateBigWildKuang(wbCounts) then     --生成框
        time = 0.9
    end
    if (self:isChangeBigWild() and wildLeftCount == 0) then     --生成框并且最后一次
        time = 1.5
    end
    if (#features >= 2 and features[2] > 0) then        --触发玩法
        time = 2
    end
    self:delayCallBack(time,function ()
        -- if self.isResetCollect then
        --     self.m_progressBarView:triggerChangeBigWildOver()
        -- end
        if type(_func) == "function" then
            _func()
        end
    end)
    
end

--添加收集节点
function CodeGameScreenOrcaCaptainMachine:addAllCollectItem()
    for i=1,COLLECT_NUM do
        local item = util_createAnimation("OrcaCaptain_shouji.csb")
        self:findChild("Node_shouji_Bonus" .. i):addChild(item)
        self.collectItemList[#self.collectItemList + 1] = item
        item:runCsbAction("idle")
        item.curNum = 0

        local itemEffect = util_createAnimation("OrcaCaptain_shouji_tx.csb")
        item:findChild("Node_tx"):addChild(itemEffect)
        item.itemEffect = itemEffect
    end
end

function CodeGameScreenOrcaCaptainMachine:getCollectActName(curNum,num,isTrigger)
    if isTrigger then
        return "actionframe",true
    end
    if curNum == 0 then
        if num == 1 then
            return "start1",false
        elseif num == 2 then
            return "start3",false
        end
    else
        if num == 2 then
            return "start2",false
        else
            return "idle",true
        end
    end
end

function CodeGameScreenOrcaCaptainMachine:showCollectItemTx(item,actName)
    if tolua.isnull(item.itemEffect) then
        return
    end
    item.itemEffect:runCsbAction("shouji")
    if actName == "start1" then
        item.itemEffect:findChild("Node_1"):setVisible(true)
        item.itemEffect:findChild("Node_2"):setVisible(false)
    elseif actName == "start2" then
        item.itemEffect:findChild("Node_1"):setVisible(false)
        item.itemEffect:findChild("Node_2"):setVisible(true)
    else
        item.itemEffect:findChild("Node_1"):setVisible(true)
        item.itemEffect:findChild("Node_2"):setVisible(true)
    end
    
end

--更新收集
function CodeGameScreenOrcaCaptainMachine:updateCollectItem(wbCounts)
    local updateKuang = false
    local isShowSound = true
    for i,v in ipairs(wbCounts) do
        local item = self.collectItemList[i]
        if not tolua.isnull(item) and item.curNum ~= v and v <= 2 then
            --刷新收集栏
            local actName,isLoop = self:getCollectActName(item.curNum,v,false)
            item.curNum = v
            item:runCsbAction(actName,isLoop)
            if isShowSound then
                isShowSound = false
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_fly_bonusFankui)
            end
            self:showCollectItemTx(item,actName)
            if v == 2 then
                self.bigWildForCol[i] = true
                local wildKuang = self.wildKuangList[i]
                wildKuang:stopAllActions()
                performWithDelay(wildKuang,function ()
                    self:updateBigWildKuang(i)
                end,10/60)
            end
        end
    end
end

--达到收集次数后是否有框变wild
function CodeGameScreenOrcaCaptainMachine:isUpdateBigWildKuang(wbCounts)
    for i,v in ipairs(wbCounts) do
        local item = self.collectItemList[i]
        if not tolua.isnull(item) and item.curNum ~= v and v <= 2 then
            if v == 2 then
                return true
            end
        end
    end
    return false
end

function CodeGameScreenOrcaCaptainMachine:getCollectEndNode(posIndex)
    local posData = self:getRowAndColByPos(posIndex)
    local iCol = posData.iY
    local node = self:findChild("Node_shouji_Bonus"..iCol)
    return node
end

--玩法开始或结束时刷新收集
function CodeGameScreenOrcaCaptainMachine:isShowAllCollectItemForFree(isShow)
    for i,item in ipairs(self.collectItemList) do
        if not tolua.isnull(item) then
            item:setVisible(not isShow)
        end
    end
    if not isShow then
        self:updateCollectItemForBet(false,true)
        self:updateProgressForBet()
    else
        self:hideAllBigWildKuang()
    end
end

--更新收集
function CodeGameScreenOrcaCaptainMachine:updateCollectItemForBet(isInit,isFreeOver)
    function getCollectActNameForInit(num)
        if num == 0 then
            return "idle",true
        elseif num == 1 then
            return "start1",false
        else 
            return "actionframe",true
        end
    end
    --清理所有连线动画相关
    self:clearWinLineEffect()
    self:hideBigWildEffect()

    local collectList = self:getCollectInfoForBet()
    if isInit then
        collectList = {0,0,0,0,0}
    end
    if isFreeOver then
        self:initBigWildKuangForSpinOver(collectList)
    else
        self:initBigWildKuang(collectList)
    end
    
    for i,v in ipairs(collectList) do
        local item = self.collectItemList[i]
        if not tolua.isnull(item) then
            --刷新收集栏
            local actName,isLoop = getCollectActNameForInit(v)
            item.curNum = v
            item:runCsbAction(actName,isLoop)
            if v == 2 then
                self.bigWildForCol[i] = true
            end
        end
    end
end

--free结束后初始化框
function CodeGameScreenOrcaCaptainMachine:initBigWildKuangForSpinOver(collectList)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --selfData.wildLeftCount or 0
    local wildLeftCount = self:getProgressShowNum()
    local isShowWild = false
    if wildLeftCount == 0 then
        isShowWild = true
    end
    for i=1,COLLECT_NUM do
        local collectNum = collectList[i]
        local wildKuang = self.wildKuangList[i]
        if collectNum >= 2 then
            wildKuang.isShow = true
            wildKuang:setVisible(true)
            if isShowWild then
                wildKuang.m_curAniName = "idleframe2"
                util_spinePlay(wildKuang, "idleframe2",true)
            else
                wildKuang.m_curAniName = "idle"
                util_spinePlay(wildKuang, "idle")
            end
            
        else
            wildKuang.m_curAniName = nil
            wildKuang.isShow = false
            wildKuang:setVisible(false)
        end
    end
end

--多福多彩结束初始化框
function CodeGameScreenOrcaCaptainMachine:initBigWildKuangForColorfulOver()
    local collectList = self:getCollectInfoForBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    --selfData.wildLeftCount or 0
    local wildLeftCount = self:getProgressShowNum()
    local isShowWild = false
    if wildLeftCount == 0 then
        isShowWild = true
    end
    for i=1,COLLECT_NUM do
        local collectNum = collectList[i]
        local wildKuang = self.wildKuangList[i]
        if collectNum >= 2 then
            wildKuang.isShow = true
            wildKuang:setVisible(true)
            if isShowWild then
                wildKuang.m_curAniName = "idleframe2"
                util_spinePlay(wildKuang, "idleframe2",true)
            else
                wildKuang.m_curAniName = "idle"
                util_spinePlay(wildKuang, "idle")
            end
            
        else
            wildKuang.m_curAniName = nil
            wildKuang.isShow = false
            wildKuang:setVisible(false)
        end
    end
end

function CodeGameScreenOrcaCaptainMachine:getCollectInfoForBet()
    local betCoin = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local betState = self.curBonusListForBet[tostring(betCoin)] or {}
    local index = self:getIndexForSpinNum()
    local betStateForSpin = betState[index] or {}
    local tempList = {}
    if table_length(betStateForSpin) <= 0 then      --从初始化里取
        for i=1,COLLECT_NUM do
            local initprogressNum = self.initBonusListForBet[index][i] or 0
            tempList[i] = initprogressNum
        end
        
        return tempList
    else
        for i=1,COLLECT_NUM do
            local progressNum = betStateForSpin[i] or 0
            tempList[i] = progressNum
        end
        
        return tempList
    end
end

--添加收集棋盘下效果
function CodeGameScreenOrcaCaptainMachine:addBonusTxForReels()
    for i=1,COLLECT_NUM do
        local item = util_createAnimation("Socre_OrcaCaptain_Bonus2_tx.csb")
        self:findChild("Node_bonus_tx"):addChild(item)
        local pos = util_convertToNodeSpace(self:findChild("Node_shouji_"..i),self:findChild("Node_bonus_tx"))
        item:setPosition(pos)
        self.bonusTxList[i] = item
        item.index = i
        item:setVisible(false)
    end
end

-- 显示收集棋盘下效果
function CodeGameScreenOrcaCaptainMachine:showBonusTxForCol(col)
    local item = self.bonusTxList[col]
    if not item then
        item = util_createAnimation("Socre_OrcaCaptain_Bonus2_tx.csb")
        self:findChild("Node_bonus_tx"):addChild(item)
        local pos = util_convertToNodeSpace(self:findChild("Node_shouji_"..col),self:findChild("Node_bonus_tx"))
        item:setPosition(pos)
        self.bonusTxList[col] = item
        item.index = col
        item:setVisible(false)
    end

    if not tolua.isnull(item) then
        item:stopAllActions()
        item:setVisible(true)
        item:runCsbAction("shouji")
        performWithDelay(item,function ()
            item:setVisible(false)
        end,1)
    end
end

function CodeGameScreenOrcaCaptainMachine:updateCurSpinNum(num)
    self.curSpinNum = num
end

----------------变wild
--ps:展示wild框与收集进度息息相关，每列收集进度为大于等于2时，需要展示当列的wild框

--创建wild框(base)
function CodeGameScreenOrcaCaptainMachine:createBigWildForCol()
    for iCol=1,self.m_iReelColumnNum do
        local wildKuang = util_spineCreate("Socre_OrcaCaptain_Wild", true, true)
        self:findChild("Node_lock_"..iCol):addChild(wildKuang)
        util_spinePlay(wildKuang, "idle")
        wildKuang.m_curAniName = "idle"
        self.wildKuangList[iCol] = wildKuang
        wildKuang.isShow = false
        wildKuang:setVisible(false)
    end
end

function CodeGameScreenOrcaCaptainMachine:createWildShowLight()
    self.wildLight = util_spineCreate("OrcaCaptain_guochang_2", true, true)
    self:findChild("Node_guochang2"):addChild(self.wildLight)
    self.wildLight:setVisible(false)
end

--收集集满两个后展示wild框
function CodeGameScreenOrcaCaptainMachine:updateBigWildKuang(iCol)
    local wildKuang = self.wildKuangList[iCol]
    local item = self.collectItemList[iCol]
    self.bigWildForCol[iCol] = true
    if not tolua.isnull(item) then
        local actName,isloop = self:getCollectActName(item.curNum,nil,true)
        item.curNum = 2
        item:findChild("Particle_1"):setVisible(true)
        item:runCsbAction(actName,isloop,function ()
            item:findChild("Particle_1"):setVisible(false)
        end)
    end
    if not wildKuang.isShow and wildKuang.m_curAniName ~= "idle" then
        wildKuang.isShow = true
        wildKuang:setVisible(true)
        wildKuang.m_curAniName = "start3"
        util_spinePlay(wildKuang, "start3")
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_wild_create)
        performWithDelay(wildKuang,function ()
            wildKuang.m_curAniName = "idle"
            util_spinePlay(wildKuang, "idle")
        end,5/30)
    end
end

--进入游戏、切换bet、切换收集总长度时调用
function CodeGameScreenOrcaCaptainMachine:initBigWildKuang(collectList)
    local aniName = "idle"
    -- local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    -- local wildLeftCount = selfData.wildLeftCount or 0     --剩余次数
    local wildLeftCount = self:getProgressShowNum()
    if wildLeftCount == 0 then
        aniName = "idleframe2"
    end
    for i=1,COLLECT_NUM do
        local collectNum = collectList[i]
        local wildKuang = self.wildKuangList[i]
        if collectNum >= 2 then
            wildKuang.isShow = true
            wildKuang:setVisible(true)
            wildKuang.m_curAniName = aniName
            util_spinePlay(wildKuang, aniName)
        else
            wildKuang.m_curAniName = nil
            wildKuang.isShow = false
            wildKuang:setVisible(false)
        end
    end
end

function CodeGameScreenOrcaCaptainMachine:hideAllBigWildKuang()
    for i,_kuang in ipairs(self.wildKuangList) do
        if not tolua.isnull(_kuang) then
            _kuang.m_curAniName = nil
            _kuang:setVisible(false)
            _kuang.isShow = false
        end
    end
end

--wild大连线框
function CodeGameScreenOrcaCaptainMachine:createBigWildEffect()
    for iCol=1,self.m_iReelColumnNum do
        local wildKuangEffect = util_createAnimation("WinFrameOrcaCaptain_2.csb")
        self:findChild("Node_shouji_"..iCol):addChild(wildKuangEffect)
        self.wildEffectList[iCol] = wildKuangEffect
        wildKuangEffect:setVisible(false)
    end
end

function CodeGameScreenOrcaCaptainMachine:hideBigWildEffect()
    for iCol=1,self.m_iReelColumnNum do
        local wildKuangEffect = self.wildEffectList[iCol]
        if not tolua.isnull(wildKuangEffect) then
            wildKuangEffect:setVisible(false)
        end
        
    end
end

--获取需要变成wild的列
function CodeGameScreenOrcaCaptainMachine:getChangeWildCol()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wbCounts = selfData.wbCounts or {}
    return wbCounts
end

function CodeGameScreenOrcaCaptainMachine:isChangeBigWild()
    local wildList = self:getChangeWildCol()
    for i,bonusNum in ipairs(wildList) do
        if bonusNum >= 2 then
            return true
        end
    end
    return false
end

function CodeGameScreenOrcaCaptainMachine:showJveseAndBgForWild()
    if self.wildSoundIndex == 0 then
        self.wildSoundIndex = 1
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_exciting_time)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_lookout)
        self.wildSoundIndex = 0
    end
    --大角色
    self.orcaNode:stopAllActions()
    util_spinePlay(self.bigJvse, "actionframe")
    util_spineEndCallFunc(self.bigJvse, "actionframe", function ()
        if self.m_bProduceSlots_InFreeSpin then
            self:showJveSeIdle(true)
        else
            self:showJveSeIdle(false)
        end
    end)
    --bg
    if not self.wildLight then
        self.wildLight = util_spineCreate("OrcaCaptain_guochang_2", true, true)
        self:findChild("Node_guochang2"):addChild(self.wildLight)
    end
    self.wildLight:setVisible(true)
    util_spinePlay(self.wildLight, "actionframe")
    util_spineEndCallFunc(self.wildLight, "actionframe", function ()
        self.wildLight:setVisible(false)
    end)
end

--将框变成一个大wild
function CodeGameScreenOrcaCaptainMachine:changeWildForCol(func)
    
    local wildList = self:getChangeWildCol()
    local time = 1
    local isShowSound = true
    local winLines = self.m_reelResultLines or {}
    if self:isChangeBigWild() then
        time = 1.2
    end
    
    if time > 1 and table_length(winLines) > 0 then       --有连线
        self:showJveseAndBgForWild()
    end
    for col, bonusNum in ipairs(wildList) do
        if bonusNum >= 2 then
            if isShowSound then
                isShowSound = false
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_base_wild_create)
            end
            local wildKuang = self.wildKuangList[col]
            local parent = wildKuang:getParent()
            local pos = util_convertToNodeSpace(wildKuang,self:findChild("Node_tempNode"))
            util_changeNodeParent(self:findChild("Node_tempNode"), wildKuang, 12)
            wildKuang:setPosition(pos)
            util_spinePlay(wildKuang, "start")
            wildKuang.m_curAniName = "start"
            util_spineEndCallFunc(wildKuang, "start", function ()
                util_changeNodeParent(self:findChild("Node_lock_"..col),wildKuang)
                wildKuang:setPosition(0,0)
                wildKuang.m_curAniName = "idleframe2"
                util_spinePlay(wildKuang, "idleframe2",true)
            end)
        end
    end
    -- if time > 0 then
        self:delayCallBack(1,function ()
            self.m_progressBarView:triggerChangeBigWildOver()
        end)
    -- else
    --     self.m_progressBarView:triggerChangeBigWildOver()
    -- end
    self:delayCallBack(time,function ()
        if func then
            func()
        end
    end)
end

function CodeGameScreenOrcaCaptainMachine:bigWildShowAct(col)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local moveWild = self:getMoveWildForCol(col)
        if not tolua.isnull(moveWild) and moveWild.m_curAniName ~= "actionframe" then
            util_spinePlay(moveWild, "actionframe",true)
            moveWild.m_curAniName = "actionframe"
        end
    else
        local wildKuang = self.wildKuangList[col]
        if not tolua.isnull(wildKuang) and wildKuang.m_curAniName ~= "actionframe" then
            util_spinePlay(wildKuang, "actionframe",true)
            wildKuang.m_curAniName = "actionframe"
        end
    end
    
end

function CodeGameScreenOrcaCaptainMachine:bigWildIdleAct(col)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local moveWild = self:getMoveWildForCol(col)
        if not tolua.isnull(moveWild) and moveWild.m_curAniName ~= "idleframe2" then
            util_spinePlay(moveWild, "idleframe2",true)
            moveWild.m_curAniName = "idleframe2"
        end
    else
        local wildKuang = self.wildKuangList[col]
        if not tolua.isnull(wildKuang) and wildKuang.m_curAniName ~= "idleframe2" then
            util_spinePlay(wildKuang, "idleframe2",true)
            wildKuang.m_curAniName = "idleframe2"
        end
    end
    
end

function CodeGameScreenOrcaCaptainMachine:isHiteWinFrame(iCol)
    -- self.bigWildForCol
    local betCoin = toLongNumber(globalData.slotRunData:getCurTotalBet())
    local betState = self.curBonusListForBet[tostring(betCoin)] or {}
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildLeftCount = selfData.wildLeftCount or 0     --剩余次数
    local wbCounts = selfData.wbCounts or {}
    if wildLeftCount ~= 0 then
        return false
    end
    for k,v in pairs(wbCounts) do
        if k == iCol and v >= 2 then
            return true
        end
    end
    return false
end

function CodeGameScreenOrcaCaptainMachine:isShowSymbolBuling(iCol)
    local item = self.collectItemList[iCol]
    if item.curNum >= 2 then
        return false
    end
    return true
end

------------------------free中移动框
function CodeGameScreenOrcaCaptainMachine:createFreeBigWildForCol(func,isInit)
    if not isInit then
        self.orcaNode:stopAllActions()
        util_spinePlay(self.bigJvse, "idleframe2",false)
        util_spineEndCallFunc(self.bigJvse, "idleframe2", function ()
            self:showJveSeIdle(true)
        end)
    end
    if not isInit then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_free_addWild)
    end
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildIndex = fsExtraData.wildIndex or {}
    for i,iCol in ipairs(wildIndex) do
        local wildKuang = util_spineCreate("Socre_OrcaCaptain_Wild", true, true)
        self:findChild("Node_wild"):addChild(wildKuang,REEL_SYMBOL_ORDER.REEL_ORDER_MASK)
        local pos = util_convertToNodeSpace(self:findChild("Node_lock_"..iCol),self:findChild("Node_wild"))
        wildKuang:setPosition(pos)
        util_spinePlay(wildKuang, "start2")
        wildKuang.m_curAniName = "start2"
        wildKuang.iCol = iCol
        self.wildKuangFreeList[iCol] = wildKuang
    end
    self:delayCallBack(1,function ()
        if func then
            func()
        end
    end)
end

function CodeGameScreenOrcaCaptainMachine:createFreeBigWildEffectForCol()
    for i=1,COLLECT_NUM do
        local item = util_createAnimation("Socre_OrcaCaptain_Wild_tx.csb")
        self:findChild("Node_shouji_"..i):addChild(item,10)
        self.wildKuangEffectFreeList[i] = item
        item.index = i
        item:setVisible(false)
    end
end

function CodeGameScreenOrcaCaptainMachine:removeAllWildKuangFree()
    for i=1,COLLECT_NUM do
        self:changeFreeWildZorder(i,false)
    end
    local children = self:findChild("Node_wild"):getChildren()
    for k,_node in pairs(children) do
        if not tolua.isnull(_node) then
            _node:removeFromParent()
        end
    end
end

--{{0,1},{2,3},{3,4}}
function CodeGameScreenOrcaCaptainMachine:getwildMoveData()
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData or {}
    local wildChangeLines = fsExtraData.wildChangeLines or {}
    return wildChangeLines
end

function CodeGameScreenOrcaCaptainMachine:getMoveWildForCol(col)
    for k,v in pairs(self.wildKuangFreeList) do
        if v.iCol == col then
            return v
        end
    end
    return nil
end

--
function CodeGameScreenOrcaCaptainMachine:showMoveWildIdle()
    for k,node in pairs(self.wildKuangFreeList) do
        if not tolua.isnull(node) then
            util_spinePlay(node, "idleframe")
            node.m_curAniName = "idleframe"
        end
    end
end

function CodeGameScreenOrcaCaptainMachine:wildMoveForData(func)
    local moveData = self:getwildMoveData()
    local isShowSound = true
    for i,v in ipairs(moveData) do
        local moveDataIndex = moveData[i] or {}
        if table_length(moveDataIndex) > 0 then
            local moveWild = self:getMoveWildForCol(moveDataIndex[1])
            if moveWild then
                local endPos = util_convertToNodeSpace(self:findChild("Node_lock_"..moveDataIndex[2]),self:findChild("Node_wild"))
                local actionList = {
                    cc.CallFunc:create(function()
                        moveWild.m_curAniName = "switch_start"
                        util_spinePlay(moveWild, "switch_start")
                        self:delayCallBack(10/30,function ()
                            moveWild.m_curAniName = "switch_idle"
                            util_spinePlay(moveWild, "switch_idle")
                        end)
                    end),
                    cc.EaseInOut:create(cc.MoveTo:create(2 + 10/30, endPos), 1),
                    cc.CallFunc:create(function()
                        local effectItem = self.wildKuangEffectFreeList[moveDataIndex[2]]
                        if not effectItem then
                            effectItem = util_createAnimation("Socre_OrcaCaptain_Wild_tx.csb")
                            self:findChild("Node_shouji_".. moveDataIndex[2]):addChild(effectItem,10)
                            self.wildKuangEffectFreeList[moveDataIndex[2]] = effectItem
                            effectItem.index = i
                        end
                        if not tolua.isnull(effectItem) then
                            effectItem:setVisible(true)
                            effectItem:runCsbAction("shouji",false,function ()
                                effectItem:setVisible(false)
                            end)
                        end
                        moveWild.iCol = moveDataIndex[2]
                        moveWild.m_curAniName = "switch_over"
                        util_spinePlay(moveWild, "switch_over")
                    end),
                    cc.DelayTime:create(15/30),
                    cc.CallFunc:create(function()
                        moveWild.m_curAniName = "idleframe2"
                        util_spinePlay(moveWild, "idleframe2",true)
                    end)
                }
                moveWild:runAction(cc.Sequence:create(actionList))
                if isShowSound then
                    isShowSound = false
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_free_wild_move)
                end
                
            end
        end
    end
    self:delayCallBack(2+10/30,function ()
        if func then
            func()
        end
    end)
end

function CodeGameScreenOrcaCaptainMachine:isHiteWinFrame2(iCol)
    local moveData = self:getwildMoveData()
    if table_length(moveData) == 0 then
        return false
    end
    for k,col in pairs(moveData) do
        if col[2] then
            if col[2] == iCol then
                return true
            end
        end
        
    end
    return false
end

----------------选择
function CodeGameScreenOrcaCaptainMachine:createChooseView()
    self.m_chooseView = util_createView("CodeOrcaCaptainSrc.OrcaCaptainChooseView",self)
    self:addChild(self.m_chooseView,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1) --修改成自己的节点 
    self.m_chooseView:setPosition(display.center)
    self.m_chooseView:setScale(self.m_machineRootScale)
    self.m_chooseView:setVisible(false)

end

function CodeGameScreenOrcaCaptainMachine:showChooseView(isShowOver)
    if self.m_bProduceSlots_InFreeSpin then
        return
    end
    local selfData = self.m_runSpinResultData
    local features = self.m_runSpinResultData.p_features or {}
    local freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
    if (#features >= 2 and features[2] > 0) or (freeSpinCount ~= 0 ) then
        self:updateProgressForBet()
        self:updateCollectItemForBet(false)
        return 
    end
    self.m_chooseView:setVisible(true)
    self.m_chooseView:showStartAct(isShowOver)
end

-----------------转盘
--测试数据
-- local wheelData = {{500,"coins"},{5,"free"},{5,"free"},{0,"jackpot"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"},{500,"coins"}}
-- 创建大转盘
function CodeGameScreenOrcaCaptainMachine:createWheelView()
    local params = {
        wheel = self.m_wheelData,
        machine = self
    }
    self.m_wheelView = util_createView("CodeOrcaCaptainSrc.OrcaCaptainWheelView", params)
    self:findChild("Node_Wheel"):addChild(self.m_wheelView)
    self.m_wheelView:setVisible(false)
end

--更新转盘数据
function CodeGameScreenOrcaCaptainMachine:updateWheelView(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wheelData = selfData.wheelContents or {}  --所有页签显示
    if not self.m_wheelView then
        self:createWheelView()
    end
    self.m_wheelView:setVisible(true)
    self.m_wheelView:setWheelData(wheelData)
    self.m_wheelView:updateWheelSymbol()
    self.m_wheelView:initCallBack(function ()
        --获得钱：
        if self.wheelRecxData[2] == "jackpot" then--jackpot
            effectData.p_isPlay = true
            self:playGameEffect()
        elseif self.wheelRecxData[2] == "free" then--free
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            self:showWheelGuoChang(false,function ()
                self:resetMusicBg()
                self.bigJvse:setVisible(true)
                
                if self.m_bProduceSlots_InFreeSpin then
                    self:showJveSeIdle(true)
                else
                    self:showJveSeIdle(false)
                end
                self.m_wheelView:setVisible(false)
                self.m_wheelView.wheelJveSe:setVisible(false)
                self:findChild("Node_qipan"):setVisible(true)
                if not self.m_bProduceSlots_InFreeSpin then
                    self:updateCollectItemForBet(false)
                    self:updateProgressForBet()
                end
            end)
            self:delayCallBack(97/30,function ()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end
    end)
end

function CodeGameScreenOrcaCaptainMachine:showWheelView(effectData)
    self:resetMusicBg(true,self.m_publicConfig.SoundConfig.music_OrcaCaptain_wheel_bg)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
    else
        --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
        self.m_bottomUI:resetWinLabel()
        self.m_bottomUI:notifyTopWinCoin()
        self.m_bottomUI:checkClearWinLabel()
    end
    self:showWheelGuoChang(true,function ()
        self.orcaNode:stopAllActions()
        self.bigJvse:setVisible(false)

        for i,v in ipairs(self.tempScatter) do
            if not tolua.isnull(v) then
                v:removeFromParent()
            end
        end
        self.tempScatter = {}
        for iCol = 1, self.m_iReelColumnNum do
            for iRow = 1, self.m_iReelRowNum do
                local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if not tolua.isnull(node) and node.p_symbolType then
                    if node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        -- if not self.m_bProduceSlots_InFreeSpin then
                        --     self:changeBaseWildZorder(node.p_cloumnIndex,true)
                        -- end
                        node:setVisible(true)
                        node:runAnim("idleframe",true)
                    end
                end
            end
        end
        
        self:findChild("Node_qipan"):setVisible(false)
        self:updateWheelView(effectData)
        if self.m_wheelView then
            self.m_wheelView:showWheelStart()
        end
    end)
end

function CodeGameScreenOrcaCaptainMachine:setRecvData(data)
    self.wheelRecxData = data
end

--弹板
function CodeGameScreenOrcaCaptainMachine:showWheelViewStart(func, isAuto)
    local name = "OrcaCaptain_wheeltanban"
    
    local ownerlist = {}
    local view = nil
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_OrcaCaptain_wheel_view_show)
    if isAuto then
        view = self:showDialog(name, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(name, ownerlist, func)
    end
    local spine = util_spineCreate("OrcaCaptain_wheeltanban_2", true, true)
    view:findChild("Node_spine"):addChild(spine)
    util_spinePlay(spine, "auto")
    view:setPosition(display.width * 0.5, display.height * 0.5)
    return view

end


function CodeGameScreenOrcaCaptainMachine:bonusOverAddFreespinEffect(featureData)
    local featureDatas = featureData.features
    if not featureDatas then
        return
    end
    for i=1,#featureDatas do
        local featureId = featureDatas[i]
        local freespin = featureData.freespin
        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            self.m_runSpinResultData.p_freeSpinsTotalCount = freespin.freeSpinsTotalCount   -- fs 总数量
            self.m_runSpinResultData.p_freeSpinsLeftCount  = freespin.freeSpinsLeftCount    -- fs 剩余次数
            self.m_runSpinResultData.p_fsMultiplier        = freespin.fsMultiplier          -- fs 当前轮数的倍数
            self.m_runSpinResultData.p_freeSpinNewCount    = freespin.freeSpinNewCount      -- fs 增加次数
            self.m_runSpinResultData.p_fsWinCoins          = freespin.fsWinCoins            -- fs 累计赢钱数量
            self.m_runSpinResultData.p_newTrigger          = freespin.newTrigger
            self.m_runSpinResultData.p_fsExtraData         = freespin.extra                 -- fs 关卡额外数据
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
            if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true then
                self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
            end
            self:sortGameEffects()
            --更新fs次数ui 显示
            -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        end
    end
end

function CodeGameScreenOrcaCaptainMachine:bonusOverAddColorfulEffect(featureData)
    local selfData = featureData.selfData or {}
    local jackpotProcess = selfData.jackpotProcess or {}
    if table_length(jackpotProcess) <= 0 then
        return
    end
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.COLORFUL_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.COLORFUL_EFFECT -- 动画类型

    -- self.m_runSpinResultData.p_selfMakeData = selfData
    self.m_runSpinResultData.p_jackpotMultiple = featureData.jackpotMultiple
    self.m_runSpinResultData.p_jackpotCoins = featureData.jackpotCoins
    self:sortGameEffects()
end

function CodeGameScreenOrcaCaptainMachine:bonusOverAddCoinsEffect()
    if self.wheelRecxData[2] ~= "coins" then
        return
    end
    local endCoins = self.wheelRecxData[1] or 0
    local newEndCoins = self.m_wheelEffectBeforeCoins + endCoins
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
        local a = globalData.slotRunData.lastWinCoin
    end
    if self:checkHasBigWin() == false then
        self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins,GameEffect.EFFECT_BONUS)
    end
    self:updateBottomUICoins(endCoins,isNotifyUpdateTop,true,true)
end

function CodeGameScreenOrcaCaptainMachine:updateBottomUICoins(_endCoins,isNotifyUpdateTop,_playWinSound,isPlayAnim,beiginCoins)
    local params = {_endCoins,isNotifyUpdateTop,isPlayAnim,beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end


-----------------多福多彩
function CodeGameScreenOrcaCaptainMachine:playColorfulGameEffect(effectData)
    local jackpotType,winCoins = self:getWinJackpotCoinsAndType()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local bonusData = {
        rewardList = selfData.jackpotProcess,    --奖励列表
        winJackpot = selfData.jackpotResult        --获得的jackpot
    }
    self:showWheelToColorfulGuoChang(true,function ()
        self:resetMusicBg(true,self.m_publicConfig.SoundConfig.music_OrcaCaptain_colorful_bg)
        self.bigJvse:setVisible(false)
        self:showJveSeIdle(false)
        if self.m_wheelView then
            self.m_wheelView:setVisible(false)
        end
        
        self:findChild("Node_qipan"):setVisible(true)
        self:findChild("Node_sp_reel"):setVisible(false)
        self:findChild("Node_shouji"):setVisible(false)
        self:findChild("Node_lock"):setVisible(false)
        self:findChild("Node_wild"):setVisible(false)
        self:findChild("Node_shouji_bonus"):setVisible(false)
        self:updateShowUI(4)
        self.m_jackPotBarView:setVisible(false)
        --重置bonus界面
        if not self.m_colorfulGameView then
            self.m_colorfulGameView = util_createView("CodeOrcaCaptainSrc.OrcaCaptainColorfulGame",{machine = self})
            self:findChild("Node_dfdc"):addChild(self.m_colorfulGameView)
            self.m_colorfulGameView:setVisible(false) 
        end
        self.m_colorfulGameView:resetView(bonusData,function()
            self:colorfulGameEffectOver(effectData)
        end)
        self.m_colorfulGameView:setVisible(true)
        self.m_colorfulGameView:showView()
    end,function ()
        
    end)
    
end

function CodeGameScreenOrcaCaptainMachine:colorfulGameEffectOver(effectData)
    self:showWheelToColorfulGuoChang(false,function ()
        self:resetMusicBg()
        self.bigJvse:setVisible(true)
        self:findChild("Node_sp_reel"):setVisible(true)
        self:findChild("Node_shouji"):setVisible(true)
        self:findChild("Node_lock"):setVisible(true)
        self:findChild("Node_wild"):setVisible(true)
        self:findChild("Node_shouji_bonus"):setVisible(true)
        
        self.m_jackPotBarView:setVisible(true)
        if self.m_colorfulGameView then
            self.m_colorfulGameView:setVisible(false)
        end
        
        if self.m_bProduceSlots_InFreeSpin then
            --改变ui显示
            self:setBigJvseSkin(2)
            self:updateShowUI(2)
            self:showJveSeIdle(true)
            --刷新wild框显示
            self:isShowAllCollectItemForFree(true)
        else
            self:initBigWildKuangForColorfulOver()
            self:updateShowUI(1)
        end
    end,function ()
        effectData.p_isPlay = true
        self:playGameEffect()
    end)
    
end



return CodeGameScreenOrcaCaptainMachine