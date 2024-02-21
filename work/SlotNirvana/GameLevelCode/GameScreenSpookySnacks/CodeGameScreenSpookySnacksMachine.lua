---
-- island li
-- 2019年1月26日
-- CodeGameScreenSpookySnacksMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "SpookySnacksPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenSpookySnacksMachine = class("CodeGameScreenSpookySnacksMachine", BaseNewReelMachine)

CodeGameScreenSpookySnacksMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型

CodeGameScreenSpookySnacksMachine.SYMBOL_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1   --南瓜bonus
CodeGameScreenSpookySnacksMachine.SYMBOL_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2   --转盘bonus
CodeGameScreenSpookySnacksMachine.SYMBOL_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3   --钥匙bonus
CodeGameScreenSpookySnacksMachine.SYMBOL_BONUS4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4   -- 特殊bonus
CodeGameScreenSpookySnacksMachine.SYMBOL_SCORE_BLANK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7  --100
CodeGameScreenSpookySnacksMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1

CodeGameScreenSpookySnacksMachine.COLLECT_SHOP_SCORE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 收集商店金币次数
CodeGameScreenSpookySnacksMachine.COLLECT_ENVELOPE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集 信封打开物品
CodeGameScreenSpookySnacksMachine.SUPER_FREE_BACK_OPENSHOP_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- super free返回需要打开商店

CodeGameScreenSpookySnacksMachine.m_MiNiTotalNum = 3 --mini小轮盘的总个数

CodeGameScreenSpookySnacksMachine.m_chipList = nil
CodeGameScreenSpookySnacksMachine.m_playAnimIndex = 0
CodeGameScreenSpookySnacksMachine.m_lightScore = 0 
CodeGameScreenSpookySnacksMachine.m_vecExpressSound = {false, false, false, false, false}
CodeGameScreenSpookySnacksMachine.m_respinReelStopSound = {false, false, false, false, false}

-- CodeGameScreenSpookySnacksMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE


-- 自定义动画的标识
-- CodeGameScreenSpookySnacksMachine.QUICKHIT_JACKPOT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 
local jackpotName = {
    "grand",
    "major",
    "minor",
    "mini"
}


-- 构造函数
function CodeGameScreenSpookySnacksMachine:ctor()
    CodeGameScreenSpookySnacksMachine.super.ctor(self)
    self.m_chipList = nil
    self.m_betLevel = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0 

    self.m_symbolExpectCtr = util_createView("CodeSpookySnacksSrc.SpookySnacksSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("SpookySnacksLongRunControl",self) 


    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    self.isShakeForRespin = false
    self.isChangeRespinBonus3 = false

    self.m_miniMachine = {}                 -- mini轮盘
    self.m_isShowJiaoBiao = false           --判断是否显示角标 断线进来不显示
    self.m_isCanClickShop = true            --滚动出来 bonus4信封 图标之后 需要判断点击商店的时机
    self.peopleClick = true                 --角色是否可点击
    self.m_isTriggerFreeMore = false        --是否触发了 freemore 用来判断free次数增加显示 动效
    self.m_isSuperFree = false              --是否是superFree
    self.m_bonus3List = {}                  -- 存储respin 滚动出来的bonus3
    self.m_bonus3MiniMachineList = {}       -- 存储respin 滚动出来bonus3 的mini棋盘ID
    self.m_lockWilds = {}
    self.scatterNum = 0
    self.isInitReelSymbol = false

    self.isShowLineSound = true

    self.m_quickBuling = true

    self.respinNewEffectList = {}

    self.clickPeopleIndex = 1
    self.upReelIndex = 1

    self.m_baseLiziPool = {}

    --init
    self:initGame()
end

function CodeGameScreenSpookySnacksMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("SpookySnacksConfig.csv", "LevelSpookySnacksConfig.lua") 


    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenSpookySnacksMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "SpookySnacks"  
end




function CodeGameScreenSpookySnacksMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    -- self.m_effectNode:setScale(self.m_machineRootScale)

    self.m_baseLiziPool = {}
    for i=1,20 do
        self:createLizi()
    end

    self.jveSeNode = cc.Node:create()
    self:findChild("root"):addChild(self.jveSeNode)

    self.m_coinbonus = cc.Node:create()
    self:findChild("root"):addChild(self.m_coinbonus)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    --respinBar
    self.m_respinbar = util_createView("CodeSpookySnacksSrc.SpookySnacksRespinBar",{machine = self.m_machine})
    self:findChild("Node_respin_bar"):setLocalZOrder(200)
    self:findChild("Node_respin_bar"):addChild(self.m_respinbar)
    self.m_respinbar:setVisible(false) 

    self:initJackPotBarView() 

    for MiNiIndex = 1, self.m_MiNiTotalNum do
        --小棋盘
        self.m_miniMachine[MiNiIndex] = util_createView("CodeSpookySnacksSrc.SpookySnacksMiniMachine",{machine = self,index = MiNiIndex})
        self:findChild("Node_respin_qipan"..MiNiIndex):addChild(self.m_miniMachine[MiNiIndex])
        self.m_miniMachine[MiNiIndex]:getParent():setLocalZOrder(4 - MiNiIndex)

        if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
            self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_miniMachine[MiNiIndex].m_touchSpinLayer)
        end

        -- 创建每个小轮盘上面的3个板子
        for i=1,3 do
            self.m_miniMachine[MiNiIndex]["banzi"..i] = util_spineCreate("SpookySnacks_respin_reelsuo",true,true)
            self.m_miniMachine[MiNiIndex]:findChild("Node_suo_"..i):addChild(self.m_miniMachine[MiNiIndex]["banzi"..i])
            util_spinePlay(self.m_miniMachine[MiNiIndex]["banzi"..i],"idle",true)
            
        end
        
        

        -- 创建棋盘集满动画
        self.m_miniMachine[MiNiIndex].qiPanJiManSpine = util_spineCreate("SpookySnacks_bigwin1",true,true)
        self.m_miniMachine[MiNiIndex]:findChild("Node_bigwin"):addChild(self.m_miniMachine[MiNiIndex].qiPanJiManSpine)
        self.m_miniMachine[MiNiIndex].qiPanJiManSpine:setVisible(false)
        
        -- 创建棋盘idle动画
        self.m_miniMachine[MiNiIndex].qiPanEffect = util_createAnimation("SpookySnacks_respin_qipan_jiman.csb")
        self.m_miniMachine[MiNiIndex]:findChild("Node_jiman"):addChild(self.m_miniMachine[MiNiIndex].qiPanEffect)
        self.m_miniMachine[MiNiIndex].qiPanEffect:setVisible(false)

        -- 创建棋盘集满动画(结算时用)
        self.m_miniMachine[MiNiIndex].jiManEffect = util_createAnimation("SpookySnacks_respin_prize.csb")
        self.m_miniMachine[MiNiIndex]:findChild("Node_prize_jiman"):addChild(self.m_miniMachine[MiNiIndex].jiManEffect)
        self.m_miniMachine[MiNiIndex].jiManEffect:setVisible(false)
        self.m_miniMachine[MiNiIndex].jiManEffect.winCoinNode = util_createAnimation("SpookySnacks_respin_prize_coins.csb")
        self.m_miniMachine[MiNiIndex].jiManEffect:findChild("coins"):addChild(self.m_miniMachine[MiNiIndex].jiManEffect.winCoinNode)
        self.m_miniMachine[MiNiIndex].jiManEffect:setVisible(false)

        local newEffect = util_spineCreate("SpookySnacks_bigwin1",true,true)
        local pos = util_convertToNodeSpace(self:findChild("Node_respin_qipan"..MiNiIndex),self:findChild("Node_respin_new"))
        self:findChild("Node_respin_new"):addChild(newEffect)
        newEffect:setPosition(cc.p(pos))
        self.respinNewEffectList[MiNiIndex] = newEffect
        newEffect:setVisible(false)

        self.m_miniMachine[MiNiIndex]:setVisible(false)

    end

    --商店界面
    self.m_shopView = util_createView("CodeSpookySnacksSrc.SpookySnacksShop.SpookySnacksShopView",{machine = self})
    self:findChild("Node_yugao"):addChild(self.m_shopView)
    -- self.m_shopView:setScale(0.9)
    self.m_shopView:setVisible(false)

    --金币收集条
    self.m_coinCollectBar = util_createView("CodeSpookySnacksSrc.SpookySnacksCoinCollectBar",{machine = self})
    self:findChild("Node_shop"):addChild(self.m_coinCollectBar)

    -- 更改 tip的层级
    local node = self.m_coinCollectBar.m_tip
    local pos = util_convertToNodeSpace(node,self:findChild("Node_yugao"))
    util_changeNodeParent(self:findChild("Node_yugao"), self.m_coinCollectBar.m_tip)
    node:setPosition(pos.x, pos.y)

    -- superfree 棋盘遮罩
    self.m_superFreeQiPanDark = util_createAnimation("SpookySnacks_SuperFree_mask.csb")
    self:findChild("Node_superfree"):addChild(self.m_superFreeQiPanDark)
    self.m_superFreeQiPanDark:setVisible(false)
    -- self.m_superFreeQiPanDark:runCsbAction("idle")

    --预告粒子
    self.yuGaoLizi = util_createAnimation("SpookySnacks_yugao_lizi.csb")
    self:findChild("Node_yugao"):addChild(self.yuGaoLizi,2)
    self.yuGaoLizi:setVisible(false)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "SpookySnacks_totalwin.csb")

    -- 折扣信息
    self.m_zheKouOffNode = util_createAnimation("SpookySnacks_base_zhekouquan.csb")
    self:findChild("Node_off"):addChild(self.m_zheKouOffNode)
    self.m_zheKouOffNode:setVisible(false)

    self:changeUiForState(PublicConfig.uiState.base)

    self:addClick(self:findChild("ren_click"))

    self.noClickLayer = util_createAnimation("SpookySnacks/SpookySnacks_noClick.csb")
    self:findChild("Node_noClick"):addChild(self.noClickLayer)
    self.noClickLayer:setVisible(false)

    -- self:findChild("clipLayer"):setLocalZOrder(1000)
    self:findChild("clipLayer"):setVisible(false)

end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenSpookySnacksMachine:initSpineUI()
    --大角色
    self.bigJvse = util_spineCreate("SpookySnacks_juese", true, true)
    self:findChild("Node_ren"):addChild(self.bigJvse)
    self:showJveSeIdle()

    self.respinDark = util_spineCreate("SpookySnacks_bigwin1",true,true)
    self:findChild("Node_dark"):addChild(self.respinDark)
    self.respinDark:getParent():setLocalZOrder(50)
    self.respinDark:setVisible(false)
end


function CodeGameScreenSpookySnacksMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound( "SpookySnacksSounds/music_SpookySnacks_enter.mp3" )
    end)
end

function CodeGameScreenSpookySnacksMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenSpookySnacksMachine.super.onEnter(self)     -- 必须调用不予许删除

    self:addObservers()
    self:upateBetLevel()
    --刷新商店积分
    self:refreshShopScore(true)
    --superFree刷新固定图标
    if self.m_isSuperFree then
        self:refreshLockWild(nil, true)
    end
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] > 0 then
        
    else
        if not self.m_bProduceSlots_InFreeSpin then
            self.m_coinCollectBar:showTip()
        end
        
    end
    
end

function CodeGameScreenSpookySnacksMachine:addObservers()
    CodeGameScreenSpookySnacksMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if not self.isShowLineSound then
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

        local soundName = PublicConfig.SoundConfig["sound_base_winLine_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_free_winLine_"..soundIndex]
            if self.m_isSuperFree then
                soundName = PublicConfig.SoundConfig["sound_superfree_winLine_"..soundIndex]
            end
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self,params)
        if not params.p_isLevelUp then
            self:upateBetLevel()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)
        self:unlockHigherBet()
    end,"SHOW_BONUS_MAP")
end

function CodeGameScreenSpookySnacksMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenSpookySnacksMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    

    scheduler.unschedulesByTargetName(self:getModuleName())
    if self.m_coinCollectBar.m_scheduleId then
        self.m_coinCollectBar:stopAction(self.m_coinCollectBar.m_scheduleId)
        self.m_coinCollectBar.m_scheduleId = nil
    end
    if self.m_timeCutDown then
        self:stopAction(self.m_timeCutDown)
        self.m_timeCutDown = nil
    end
    -- if self.m_coinbonusUpdateAction then
    --     self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
    --     self.m_coinbonusUpdateAction = nil
    -- end

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenSpookySnacksMachine:MachineRule_GetSelfCCBName(symbolType)
    -- 自行配置jackPot信号 csb文件名，不带后缀
    if symbolType == self.SYMBOL_BONUS1 then
        return "Socre_SpookySnacks_Bonus1"
    end

    if symbolType == self.SYMBOL_BONUS2 then
        return "Socre_SpookySnacks_Bonus2"
    end

    if symbolType == self.SYMBOL_BONUS3 then
        return "Socre_SpookySnacks_Bonus3"
    end

    if symbolType == self.SYMBOL_BONUS4 then
        return "Socre_SpookySnacks_Bonus"
    end 

    if symbolType == self.SYMBOL_SCORE_BLANK then
        return "Socre_SpookySnacks_Blank"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_SpookySnacks_10"
    end


    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenSpookySnacksMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenSpookySnacksMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_10,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BLANK,count =  2} 


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenSpookySnacksMachine:MachineRule_initGame()
    local a = self.m_runSpinResultData
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        local features = self.m_runSpinResultData.p_features or {}
        local p_freeSpinNewCount = self.m_runSpinResultData.p_freeSpinNewCount or 0
        if #features >= 2 and features[2] > 0 then
            if p_freeSpinNewCount then
                if self.m_isSuperFree then
                    self:changeUiForState(PublicConfig.uiState.superFree)
                    --平均bet值 展示
                    self.m_bottomUI:showAverageBet()
                else
                    self:changeUiForState(PublicConfig.uiState.free)
                end
            end
        else
            
            if self.m_isSuperFree then
                self:changeUiForState(PublicConfig.uiState.superFree)
                --平均bet值 展示
                self.m_bottomUI:showAverageBet()
            else
                self:changeUiForState(PublicConfig.uiState.free)
            end
        end
        

        -- self:playFreeJiaoSeIdle()
    end 

    

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenSpookySnacksMachine:MachineRule_SpinBtnCall()
    self.scatterNum = 0
    self.isInitReelSymbol = false
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()

    if self.m_coinCollectBar.m_scheduleId then
        self.m_coinCollectBar:hideTip()
    end

    if self:getCurrSpinMode() ~= RESPIN_MODE then
        self.isShowLineSound = true
    end

    --superfree显示固定wild
    if self.m_isSuperFree then
        -- superfree 第一次 需要显示 棋盘遮罩
        if self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
            
        else
            for index, wildNode in ipairs(self.m_lockWilds) do
                wildNode:setVisible(true)
            end
        end
    end

    self.m_isShowJiaoBiao = true

    if self.m_shopView:isVisible() then
        self.m_shopView:hideView()
    end

    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenSpookySnacksMachine:slotOneReelDown(reelCol)    
    CodeGameScreenSpookySnacksMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 

end

--[[
    滚轮停止
]]
function CodeGameScreenSpookySnacksMachine:slotReelDown( )

    if #self.m_lockWilds > 0 then
        for index, wildNode in ipairs(self.m_lockWilds) do
            wildNode:setVisible(false)
        end
    end

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenSpookySnacksMachine.super.slotReelDown(self)
end

-- 重置当前背景音乐名称
function CodeGameScreenSpookySnacksMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.m_isSuperFree then
            self.m_currentMusicBgName = "SpookySnacksSounds/music_SpookySnacks_superFree.mp3"
        else
            self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        end

        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenSpookySnacksMachine:addSelfEffect()

        
    -- 自定义动画创建方式
    --收集 信封打开
    local selfData = self.m_runSpinResultData.p_selfMakeData

    --收集商店积分
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.score then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_SHOP_SCORE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_SHOP_SCORE_EFFECT -- 动画类型
    end

    local specialBonus = selfData.specialBonus or {}

    if #specialBonus > 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_ENVELOPE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_ENVELOPE_EFFECT -- 动画类型
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenSpookySnacksMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_SHOP_SCORE_EFFECT then --收集商店积分

        self:collectShopScoreEffect(effectData)

    elseif effectData.p_selfEffectType == self.COLLECT_ENVELOPE_EFFECT then --收集 信封打开之后 的物品

        self:delayCallBack(15/30,function()
            self:collectEnvelopeResultEffect(effectData)
        end)

    elseif effectData.p_selfEffectType == self.SUPER_FREE_BACK_OPENSHOP_EFFECT then

        local isSuperFreeBack = false
    
        if self.m_shopConfig.firstRound then
            isSuperFreeBack = true
        end

        effectData.p_isPlay = true
        self:playGameEffect()
        self.m_bottomUI.m_changeLabJumpTime = 0.2
        self.m_shopView:showView(isSuperFreeBack)

    end
	return true
    

end



function CodeGameScreenSpookySnacksMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenSpookySnacksMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenSpookySnacksMachine:playScatterTipMusicEffect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        --再触发
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_scatter_triggerMore)
    else
        if self.m_ScatterTipMusicPath ~= nil then
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
        else
            --触发
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_scatter_trigger)
        end
    end

end

-- 不用系统音效
function CodeGameScreenSpookySnacksMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenSpookySnacksMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenSpookySnacksMachine:checkRemoveBigMegaEffect()
    CodeGameScreenSpookySnacksMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenSpookySnacksMachine:getShowLineWaitTime()
    local time = CodeGameScreenSpookySnacksMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------
    -----------------------------respin相关接口------------------------------------------------
-- 继承底层respinView
function CodeGameScreenSpookySnacksMachine:getRespinView()
    return "CodeSpookySnacksSrc.SpookySnacksRespinView"
end
-- 继承底层respinNode
function CodeGameScreenSpookySnacksMachine:getRespinNode()
    return "CodeSpookySnacksSrc.SpookySnacksRespinNode"
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenSpookySnacksMachine:getReSpinSymbolScore(id)
    
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local multi = nil
    local idNode = nil
    local symbolType = nil

    for index = 1, #storedIcons do
        local values = storedIcons[index]
        if values[1] == id then
            multi = values[3]
            symbolType = values[2]
            idNode = values[1]
        end
    end

    if symbolType == self.SYMBOL_BONUS3 then
        multi = 1
    end

    if multi == nil then
        multi = 1
    end

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multi * lineBet

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenSpookySnacksMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local multi = self.m_configData:getFixSymbolPro()
    score = multi * lineBet


    return score
end

--[[
    刷新小块显示
]]
function CodeGameScreenSpookySnacksMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType

    if tolua.isnull(node.m_scoreItem) then
        node.m_scoreItem = nil
    end

    if node.m_scoreItem then
        node.m_scoreItem:setVisible(false)
        node.m_scoreItem.score = 0
    end

    -- 收集金币相关
    if node:isLastSymbol() and self.m_isShowJiaoBiao then
        self:createCollectCoinsByNode(node)
    end

    if symbolType == self.SYMBOL_BONUS1 then
        self:setSpecialNodeScore(self,{node})
    end
    
    if self.isInitReelSymbol and symbolType == self.SYMBOL_BONUS1 then
        node:runAnim("idle",true)
    end


end

function CodeGameScreenSpookySnacksMachine:getJackpotName(score)
    if score == 10 then
        return "mini"
    elseif score == 20 then
        return "minor"
    elseif score == 200 then
        return "major"
    elseif score == 5000 then
        return "grand"
    end
    return "nomal"
end

function CodeGameScreenSpookySnacksMachine:addCCbForBonusSpine(symbolNode,score)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local multi = score/lineBet
    local csbName = "Socre_SpookySnacks_Bonus_zi.csb"

    
    local m_bindCsbNode,spine = self:getLblCsbOnSymbol(symbolNode,csbName,"wenzi")
    if not tolua.isnull(m_bindCsbNode) then
        -- m_bindCsbNode:runCsbAction("actionframe", true)
        local jackpotType = self:getJackpotName(multi)
        if multi >= 10 then      --mini
            m_bindCsbNode:findChild("grand"):setVisible(jackpotType == "grand")
            m_bindCsbNode:findChild("major"):setVisible(jackpotType == "major")
            m_bindCsbNode:findChild("minor"):setVisible(jackpotType == "minor")
            m_bindCsbNode:findChild("mini"):setVisible(jackpotType == "mini")
            m_bindCsbNode:findChild("m_lb_coins"):setVisible(false)
        else
            m_bindCsbNode:findChild("grand"):setVisible(jackpotType == "grand")
            m_bindCsbNode:findChild("major"):setVisible(jackpotType == "major")
            m_bindCsbNode:findChild("minor"):setVisible(jackpotType == "minor")
            m_bindCsbNode:findChild("mini"):setVisible(jackpotType == "mini")
            if m_bindCsbNode:findChild("m_lb_coins") then
                m_bindCsbNode:findChild("m_lb_coins"):setVisible(true)
                m_bindCsbNode:findChild("m_lb_coins"):setString(util_formatCoins(score, 3))
                self:updateLabelSize({label = m_bindCsbNode:findChild("m_lb_coins"),sx = 1,sy = 1}, 121)
            end
        end
    end
end

-- 给respin小块进行赋值
function CodeGameScreenSpookySnacksMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    if tolua.isnull(symbolNode) or not symbolNode.p_symbolType then
        return
    end
    
    local miniIndex = param[2]

    local symbolType = symbolNode.p_symbolType
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    -- local posIndex = self:getPosReelIdx(iRow, iCol)
    local score = 0
    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        if miniIndex then
            score = self.m_miniMachine[miniIndex]:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        end
        local index = 0
        if score ~= nil then
            
            local lineBet = globalData.slotRunData:getCurTotalBet()

            if symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
                self:addCCbForBonusSpine(symbolNode,score)
                -- symbolNode:runAnim("idleframe2", true)
            end
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if miniIndex then
            score = self.m_miniMachine[miniIndex]:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        end

        local lineBet = globalData.slotRunData:getCurTotalBet()
        if symbolNode.p_symbolType == self.SYMBOL_BONUS1 then
            self:addCCbForBonusSpine(symbolNode,score)
        end
    end
end



function CodeGameScreenSpookySnacksMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeSpookySnacksSrc.SpookySnacksFreespinBarView",{machine = self})
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_fgbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenSpookySnacksMachine:showFreeSpinStart(num, func, isAuto)
    local params = {
        featureType = "free",
        machine = self,
        num = num,
        func = func
    }
    local view = util_createView("CodeSpookySnacksSrc.SpookySnacksFeatureStartView",params)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenSpookySnacksMachine:showFreeSpinMore(num, func, isAuto)
    local params = {
        featureType = "freeMore",
        machine = self,
        num = num,
        func = func
    }
    local view = util_createView("CodeSpookySnacksSrc.SpookySnacksFeatureStartView",params)
    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenSpookySnacksMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("SpookySnacksSounds/music_SpookySnacks_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self.m_isTriggerFreeMore = true
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            if  self.m_isSuperFree then
                local view = self:showSuperFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:clearCurMusicBg()
                    self:showGuochang(function ()
                        --平均bet值 展示
                        self.m_bottomUI:showAverageBet()
                        self.m_configData:setFreeType(2)
                        self.m_baseFreeSpinBar:refreshInfo(self.m_isSuperFree)
                        self.m_baseFreeSpinBar:changeFreeSpinByCount()
                        self:changeUiForState(PublicConfig.uiState.superFree)
                    end,function ()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end,false)
                         
                end)
            else
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    self:setCurrSpinMode(FREE_SPIN_MODE)
                    self:resetMusicBg()
                    self:showGuochang(function ()
                        self.m_baseFreeSpinBar:refreshInfo(self.m_isSuperFree)
                        self.m_baseFreeSpinBar:changeFreeSpinByCount()
                        self:changeUiForState(PublicConfig.uiState.free)
                    end,function ()
                        self:triggerFreeSpinCallFun()
                        effectData.p_isPlay = true
                        self:playGameEffect()  
                    end,false)
                         
                end)
            end
            
        end
    end
    local waitTime = 0.5
    if self.m_isSuperFree then
        waitTime = 0
    end
    self:delayCallBack(waitTime,function()
        showFSView()  
    end)    
end

function CodeGameScreenSpookySnacksMachine:triggerFreeSpinCallFun()
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
    if self.m_isSuperFree then
        self:resetMusicBg()
    end
    
end

--无赢钱
function CodeGameScreenSpookySnacksMachine:showNoWinView(func)
    self:clearCurMusicBg()
    local view = self:showDialog("FreeSpinOver_NoWins", nil, func)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenSpookySnacksMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local view = nil
    if self.m_isSuperFree then
        --清理固定图标
        self:clearLockWild()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_superFreeOver_start)
        view = self:showDialog("SuperFreeSpinOver", ownerlist, func)
        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_superFreeOver_over)
        end)
        
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_freeSpinOver_start)
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
        view:setBtnClickFunc(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_freeSpinOver_over)
        end)
    end

    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenSpookySnacksMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("SpookySnacksSounds/music_SpookySnacks_over_fs.mp3")
    local view = nil
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins
    local strCoins = util_formatCoins(freeSpinWinCoin,50)
    -- local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 30)
    if freeSpinWinCoin > 0 then
        local view = self:showFreeSpinOver(
            strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,
            function()
                self:showGuochang(function ()
                    
                    if self.m_isSuperFree then
                        --平均bet值 隐藏
                        self.m_bottomUI:hideAverageBet()
                    end
                    self.m_configData:setFreeType(0)
                    self:changeUiForState(PublicConfig.uiState.base)
                end,function ()
                    if self.m_isSuperFree then
                        -- 添加superfreespin effect back
                        local superfreeSpinEffect = GameEffectData.new()
                        superfreeSpinEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                        superfreeSpinEffect.p_effectOrder = self.SUPER_FREE_BACK_OPENSHOP_EFFECT
                        self.m_gameEffects[#self.m_gameEffects + 1] = superfreeSpinEffect
                        superfreeSpinEffect.p_selfEffectType = self.SUPER_FREE_BACK_OPENSHOP_EFFECT -- 动画类型           
                    end
                    self.m_isSuperFree = false
                    self:triggerFreeSpinOverCallFun()
                end,true)
                
            end
        )
        local light = util_createAnimation("SpookySnacks/FreeSpinOver_glow.csb")
        view:findChild("xzg_tx"):addChild(light)
        -- 修改透明度 不然不会随着根节点变化
        util_setCascadeOpacityEnabledRescursion(view:findChild("xzg_tx"), true)
        util_setCascadeColorEnabledRescursion(view:findChild("xzg_tx"), true)
        light:runCsbAction("idleframe",true)
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},621) 
    else
        local view = self:showNoWinView(function ()
            self:showGuochang(function ()
                if self.m_isSuperFree then
                    --平均bet值 隐藏
                    self.m_bottomUI:hideAverageBet()
                end
                self:changeUiForState(PublicConfig.uiState.base)
            end,function ()
                if self.m_isSuperFree then
                    -- 添加superfreespin effect back
                    local superfreeSpinEffect = GameEffectData.new()
                    superfreeSpinEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    superfreeSpinEffect.p_effectOrder = self.SUPER_FREE_BACK_OPENSHOP_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = superfreeSpinEffect
                    superfreeSpinEffect.p_selfEffectType = self.SUPER_FREE_BACK_OPENSHOP_EFFECT -- 动画类型           
                end
                self.m_isSuperFree = false
                self:triggerFreeSpinOverCallFun()
            end,true)
        end)
    end
       
end

function CodeGameScreenSpookySnacksMachine:showEffect_FreeSpin(effectData)
    local waitTime1 = 0.5
    if self.m_isSuperFree then
        waitTime1 = 0
    end
    self:delayCallBack(waitTime1,function ()
        self.m_beInSpecialGameTrigger = true

        self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

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

        if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
            if not self.m_isSuperFree then
                -- 停掉背景音乐
                self:clearCurMusicBg()
            end
            
            -- freeMore时不播放
            if self.levelDeviceVibrate then
                self:levelDeviceVibrate(6, "free")
            end
        end

        if not self.m_isSuperFree then
            --
            -- 角色动画
            self:showJveSeActionForFeature()

            local waitTime = 0
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                    if slotNode and slotNode.p_symbolType then
                        if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                            
                            local parent = slotNode:getParent()
                            if parent ~= self.m_clipParent then
                                slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                            end
                            slotNode:runAnim("actionframe", false)

                            local duration = slotNode:getAniamDurationByName("actionframe")
                            waitTime = util_max(waitTime,duration)
                        end
                    end
                end
            end

            self:delayCallBack(waitTime,function()
                self:showFreeSpinView(effectData)
            end)

            -- scatterLineValue:clean()
            -- self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue

            self:playScatterTipMusicEffect()
            
        else
            self:showFreeSpinView(effectData)
        end
        gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
        
    end)
    return true    
end

function CodeGameScreenSpookySnacksMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeSpookySnacksSrc.SpookySnacksJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点    

    self.m_respinjackPotBarView = util_createView("CodeSpookySnacksSrc.SpookySnacksRespinJackPotBarView",self)
    self.m_respinjackPotBarView:initMachine(self)
    self:findChild("Node_jackpot"):addChild(self.m_respinjackPotBarView) --修改成自己的节点
    self.m_respinjackPotBarView:setVisible(false)
end

-- --[[
--         显示jackpotWin
--     ]]
function CodeGameScreenSpookySnacksMachine:showRespinJackpotWin(jackpotType,coins,func)
    local view = util_createView("CodeSpookySnacksSrc.SpookySnacksJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        machine = self,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

function CodeGameScreenSpookySnacksMachine:setReelRunInfo()
    -- assert(nil,"自己配置快滚信息")
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["135"] ,["symbolType"] = {90}} )
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {200},["musRunInfos"] = {["startCol"] = 1,["endCol"]=3}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态    
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenSpookySnacksMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenSpookySnacksMachine.super.MachineRule_ResetReelRunData(self)    
end

function CodeGameScreenSpookySnacksMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                -- elseif _slotNode.p_cloumnIndex == self.m_iReelColumnNum and _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                --     self:setScatterSymbolForFiveCol(_slotNode,speedActionTable)
                end
                
            end

            if self:checkSymbolBulingAnimPlay(_slotNode) then
                --2.播落地动画
                self:playBulingAnimFunc(_slotNode,symbolCfg)
            end
        end
    end
end

function CodeGameScreenSpookySnacksMachine:playBulingAnimFunc(_slotNode,_symbolCfg)
    _slotNode:runAnim(
        _symbolCfg[2],
        false,
        function()
            self:symbolBulingEndCallBack(_slotNode)
        end
    )
end

function CodeGameScreenSpookySnacksMachine:symbolBulingEndCallBack(_slotNode)
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

-- 有特殊需求判断的 重写一下
function CodeGameScreenSpookySnacksMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnimaForSpooky(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
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

function CodeGameScreenSpookySnacksMachine:isPlayTipAnimaForSpooky(matrixPosY, matrixPosX, node)
    if matrixPosY == 1 then
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

    if matrixPosY == 3 then
        if scatterNum >= 1 then
            return true
        end
    elseif matrixPosY == 5 then
        if scatterNum >= 2 then
            return true
        end
    end

    return false
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenSpookySnacksMachine:isPlayExpect(reelCol)
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
    播放预告中奖概率
    GD.SLOTO_FEATURE = {
        FEATURE_FREESPIN = 1,
        FEATURE_FREESPIN_FS = 2, -- freespin 中再次触发fs
        FEATURE_RESPIN = 3, -- 触发respin 玩法
        FEATURE_MINI_GAME_COLLECT = 4, -- 收集玩法小游戏
        FEATURE_MINI_GAME_OTHER = 5, -- 其它小游戏
        FEATURE_JACKPOT = 6 -- 触发 jackpot
    }
]]
function CodeGameScreenSpookySnacksMachine:getFeatureGameTipChance(_probability)
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 then
        -- 出现预告动画概率默认为30%
        local probability = 40
        if _probability then
            probability = _probability
        end
        local isNotice = (math.random(1, 100) <= probability) 
        return isNotice
    end
    
    return false
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenSpookySnacksMachine:showFeatureGameTip(_func)
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
function CodeGameScreenSpookySnacksMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = false
    local aniTime = 0

    --获取父节点
    local parentNode = self:findChild("Node_yugao")
    if not parentNode then
        parentNode = self:findChild("root")
    end

    local features = self.m_runSpinResultData.p_features or {}
    --respin
    if #features >= 2 and features[2] == 3 then
        self.yuGaoLizi:setVisible(true)
        local particle1 = self.yuGaoLizi:findChild("Particle_1")
        local particle2 = self.yuGaoLizi:findChild("Particle_2")
        if particle1 and particle2 then
            particle1:resetSystem()
            particle2:resetSystem()
        end
        self:delayCallBack(1.1,function ()
            self.yuGaoLizi:setVisible(false)
        end)
    end
    
    -- --检测是否存在预告中奖资源
    local aniName = self.m_moduleName.."_yugao"

    self.b_gameTipFlag = true
    -- 动效执行时间

    --创建对应格式的spine
    local spineAni = util_spineCreate(aniName,true,true)
    if parentNode and not tolua.isnull(spineAni) then
        parentNode:addChild(spineAni)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_yuGao)
        util_spinePlay(spineAni,"actionframe_yugao")
        local time= 2.1
        self:delayCallBack(time,function ()
            spineAni:removeFromParent()
        end)

        aniTime = 2

    end

    if self.b_gameTipFlag then
        --计算延时,预告中奖播完时需要刚好停轮
        local delayTime = self:getRunTimeBeforeReelDown()

        --预告中奖时间比滚动时间短,直接返回即可
        if aniTime <= delayTime then
            if type(func) == "function" then
                func()
            end
        else
            self:delayCallBack(aniTime,function()
                if type(func) == "function" then
                    func()
                end
            end)
        end 
    else
        if type(func) == "function" then
            func()
        end   
    end

     
end

function CodeGameScreenSpookySnacksMachine:createWheelVerticalOrHorizontalView(effectData)
    self.m_wheelReel = util_createView("CodeSpookySnacksSrc.SpookySnacksWheeVerticalOrHorizontalView", {machine = self, _effectData = effectData})
    self:findChild("root"):addChild(self.m_wheelReel)
    self.m_wheelReel:setPosition(cc.p(-display.width / 2,-display.height / 2))    
end

function CodeGameScreenSpookySnacksMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)
    self:showJveSeActionForFeature()
    if not self.bigWinEffect then
        --大赢
        self.bigWinEffect = util_spineCreate("SpookySnacks_bigwin1", true, true)
        self:findChild("Node_bigWin"):addChild(self.bigWinEffect,1)
        self.bigWinEffect:setVisible(false)
    end
    if not self.bigWinEffect2 then
        self.bigWinEffect2 = util_spineCreate("SpookySnacks_bigwin2", true, true)
        local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
        self:findChild("root"):addChild(self.bigWinEffect2,1000)
        self.bigWinEffect2:setPosition(cc.p(pos.x,pos.y))
        self.bigWinEffect2:setVisible(false)
    end
    self.bigWinEffect:setVisible(true)
    self.bigWinEffect2:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_bigWin_YuGao)
    util_spinePlay(self.bigWinEffect, "actionframe_bigwin")
    util_spinePlay(self.bigWinEffect2, "actionframe_bigwin")

    self:delayCallBack(aniTime,function()
        self.bigWinEffect:setVisible(false)
        self.bigWinEffect2:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenSpookySnacksMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

-- function CodeGameScreenSpookySnacksMachine:beginReel()
--     --superfree显示固定wild
--     if self.m_isSuperFree then
--         -- superfree 第一次 需要显示 棋盘遮罩
--         if self.m_runSpinResultData.p_freeSpinsLeftCount == self.m_runSpinResultData.p_freeSpinsTotalCount then
            
--         else
--             for index, wildNode in ipairs(self.m_lockWilds) do
--                 wildNode:setVisible(true)
--             end
--         end
--         -- self.m_fsReelDataIndex = 1
        
--     end

--     self.m_isShowJiaoBiao = true
--     -- self.m_isQuicklyStop = false
--     -- self.m_isPlayBulingSound = true
--     -- for i=1,5 do
--     --     self.m_isPlayBonus1Buling[i] = true
--     -- end
--     -- self:checkChangeBaseParentForScatter()
--     -- self:clearClipLayer()
--     CodeGameScreenSpookySnacksMachine.super.beginReel(self)
    
-- end

function CodeGameScreenSpookySnacksMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end

    self.m_baseFreeSpinBar:setVisible(true)
    self.m_baseFreeSpinBar:refreshInfo(self.m_isSuperFree)
    -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    -- util_nodeFadeIn(self.m_baseFreeSpinBar, 0.5, 0, 255, nil, function()
    -- end)
    -- gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_free_bar_start)
end

-- function CodeGameScreenSpookySnacksMachine:normalSpinBtnCall( )
--     -- 商店打开的话 点击 spin 关闭商店
--     if self.m_shopView:isVisible() then
--         self.m_shopView:cheakIsCanClick(function()
--             self.m_shopView:hideView()
--             self:delayCallBack(0.5,function ()
--                 CodeGameScreenSpookySnacksMachine.super.normalSpinBtnCall(self)
--                 self:setMaxMusicBGVolume( )
--                 self:removeSoundHandler()
--             end)
--         end)
--     else
--         CodeGameScreenSpookySnacksMachine.super.normalSpinBtnCall(self)
--         self:setMaxMusicBGVolume( )
--         self:removeSoundHandler()
--     end

    
    
-- end

function CodeGameScreenSpookySnacksMachine:scaleMainLayer()
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

function CodeGameScreenSpookySnacksMachine:initNoneFeature()
    self.isInitReelSymbol = true
    CodeGameScreenSpookySnacksMachine.super.initNoneFeature(self)
    
end

-- -----------------------------商店相关
--[[
    刷新商店积分
]]
function CodeGameScreenSpookySnacksMachine:refreshShopScore(_isReConnect)
    local score = 0
    if _isReConnect then
        score = self.m_shopConfig.coins or 0
    elseif self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.coins then
        score = self.m_runSpinResultData.p_selfMakeData.coins or 0
        if score == 0 then
            score = self.m_shopConfig.coins or 0
        else --刷新配置中的积分数量
            self.m_shopConfig.coins = score
        end
    end

    self.m_coinCollectBar:updateCoins(score)
end

---
-- 判断当前是否可点击
-- 商店玩法等滚动过程中不允许点击的接口
-- 返回true,允许点击
function CodeGameScreenSpookySnacksMachine:collectBarClickEnabled()
    local featureDatas = self.m_runSpinResultData.p_features or {0}
    local reSpinCurCount = self.m_runSpinResultData.p_reSpinCurCount
    local reSpinsTotalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    local bonusStates = self.m_runSpinResultData.p_bonusStatus or ""
    --

    if self.m_isWaitingNetworkData then
        return false
    elseif self:getGameSpinStage() ~= IDLE then
        return false
    elseif bonusStates == "OPEN" then
        return false
    elseif self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return false
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        return false
    elseif self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        return false
    elseif reSpinCurCount and reSpinCurCount and reSpinCurCount > 0 and reSpinsTotalCount > 0 then
        return false
    -- elseif self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
    --     return false
    elseif #featureDatas > 1 then
        return false
    elseif self.m_isRunningEffect then
        return false
    end

    return true
end

--显示商店界面
function CodeGameScreenSpookySnacksMachine:showShopView()
    --检测按钮是否可以点击
    if not self:collectBarClickEnabled() then
        return
    end

    if not self.m_isCanClickShop then
        return 
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:setMaxMusicBGVolume()
    self.m_bottomUI.m_changeLabJumpTime = 0.2
    self.m_shopView:showView()
end

-- 收集商店金币的动画
function CodeGameScreenSpookySnacksMachine:collectShopScoreEffect(effectData)
    local score = 0
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.coins then
        score = self.m_runSpinResultData.p_selfMakeData.coins or 0
        if score == 0 then
            score = self.m_shopConfig.coins or 0
        else --刷新配置中的积分数量
            self.m_shopConfig.coins = score
        end
    end
    -- 收集金币的同时有bonus4 开出金币
    -- 先播放的收集金币动画 后播放bonus4动画
    -- 所以收集金币的时候 刷新金币总数 减去bonus4的金币
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local specialBonus = selfData.specialBonus or {}
    if specialBonus[1] and specialBonus[1][2] and specialBonus[1][2] == "coins" then
        if specialBonus[1][3] then
            score = score - specialBonus[1][3]
        end
    end

    -- 收集的同时 还有别的事件的话 等收集完在播其他的
    local isDelayPlay = false
    local effectLen = #self.m_gameEffects
    for i = 1, effectLen, 1 do
        local effectData = self.m_gameEffects[i]
        if effectData.p_effectType == GameEffect.EFFECT_FREE_SPIN or effectData.p_effectType == GameEffect.EFFECT_RESPIN then
            isDelayPlay = true
        end
        if effectData.p_effectType == self.COLLECT_ENVELOPE_EFFECT then
            isDelayPlay = false
            break
        end
    end

    local isFirst = true
    local isFirst2 = true
    local isPlaySound = true
    
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.m_scoreItem and symbolNode.m_scoreItem.score > 0 then
                symbolNode.m_scoreItem:setVisible(false)
                if isFirst2 then
                    isFirst2 = false
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_jiaoBiao_collectToShop)
                end
                self:flyCollectShopScore(symbolNode.m_scoreItem.score,symbolNode.m_scoreItem,self.m_coinCollectBar:findChild("Node_fly"),function()
                    if not tolua.isnull(symbolNode) and not tolua.isnull(symbolNode.m_scoreItem) then
                        symbolNode.m_scoreItem:removeFromParent()
                        symbolNode.m_scoreItem = nil
                    end
                    if isFirst then
                        isFirst = false
                        self.m_coinCollectBar:runCsbAction("actionframe",false,function()
                            self.m_coinCollectBar:runCsbAction("idle",true)
                        end)
                        --刷新商店积分
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_jiaoBiao_collectToShop_fankui)
                        self.m_coinCollectBar:updateCoins(score)

                        if isDelayPlay then
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end
                end,isPlaySound)
                if isPlaySound then
                    isPlaySound = false
                end
            end
        end
    end
    -- --由于第五列的scatter图标不在棋盘上
    -- local childs = self:findChild("clipLayer"):getChildren()
    -- for k,_node in pairs(childs) do
    --     if not tolua.isnull(_node) and _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --         if _node.m_scoreItem and _node.m_scoreItem.score > 0 then
    --             _node.m_scoreItem:setVisible(false)
    --             if isFirst2 then
    --                 isFirst2 = false
    --                 gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_jiaoBiao_collectToShop)
    --             end
    --             self:flyCollectShopScore(_node.m_scoreItem.score,_node.m_scoreItem,self.m_coinCollectBar:findChild("Node_fly"),function()
    --                 if isFirst then
    --                     isFirst = false
    --                     self.m_coinCollectBar:runCsbAction("actionframe",false,function()
    --                         self.m_coinCollectBar:runCsbAction("idle",true)
    --                     end)
    --                     --刷新商店积分
    --                     gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_jiaoBiao_collectToShop_fankui)
    --                     self.m_coinCollectBar:updateCoins(score)

    --                     if isDelayPlay then
    --                         effectData.p_isPlay = true
    --                         self:playGameEffect()
    --                     end
    --                 end
    --             end,isPlaySound)
    --             if isPlaySound then
    --                 isPlaySound = false
    --             end
    --         end
    --     end
    -- end

    if not isDelayPlay then
        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

--[[
    BottomUI接口
]]
function CodeGameScreenSpookySnacksMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--[[
    商店购买之后 赢钱显示在底部
]]
function CodeGameScreenSpookySnacksMachine:playBottomLight(_endCoins, _endCallFunc, isAdd)
    
    self.m_bottomUI:playCoinWinEffectUI(_endCallFunc)
    local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
    
    if not self.bigWinEffect then
        --大赢
        self.bigWinEffect = util_spineCreate("SpookySnacks_bigwin1", true, true)
        self:findChild("Node_bigWin"):addChild(self.bigWinEffect,1)
        self.bigWinEffect:setVisible(false)
    end
    util_changeNodeParent(self:findChild("root"),self.bigWinEffect)
    self.bigWinEffect:setPosition(cc.p(pos.x,pos.y))
    self.bigWinEffect:setVisible(true)
    util_spinePlay(self.bigWinEffect, "actionframe_respin")
    util_spineEndCallFunc(self.bigWinEffect, "actionframe_respin", function ()
        self.bigWinEffect:setVisible(false)
        util_changeNodeParent(self:findChild("Node_bigWin"),self.bigWinEffect)
        self.bigWinEffect:setPosition(cc.p(0,0))
    end)

    if isAdd then
        local bottomWinCoin = self:getCurBottomWinCoins()
        local totalWinCoin = bottomWinCoin + tonumber(_endCoins)
        self:setLastWinCoin(totalWinCoin)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_smallView_moveFanKui)
        self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
    else
        self:setLastWinCoin(tonumber(_endCoins))
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_coinsFly_TotalWin_fankui)
        self:updateBottomUICoins(0, tonumber(_endCoins), true)
    end

end

function CodeGameScreenSpookySnacksMachine:getCurBottomWinCoins()
    local winCoin = 0
    local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
    if "" == sCoins then
        return winCoin
    end
    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local numList = util_string_split(sCoins,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        winCoin = tonumber(numStr) or 0
    elseif nil ~= self.m_bottomUI.m_spinWinCount then
        winCoin = self.m_bottomUI.m_spinWinCount
    end

    return winCoin
end

function CodeGameScreenSpookySnacksMachine:initGameStatusData(gameData)
    if gameData.special then
        gameData.spin.features = gameData.special.features
        gameData.spin.freespin = gameData.special.freespin
        gameData.spin.selfData = gameData.special.selfData
        gameData.spin.lines = gameData.special.lines
    end
    if not self.m_specialBets then
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    CodeGameScreenSpookySnacksMachine.super.initGameStatusData(self, gameData)
    self.m_shopConfig = gameData.gameConfig.extra or {}
    self.m_shopConfig.firstRound = true
    if gameData.spin then
        if gameData.spin.selfData then
            self.m_shopConfig.firstRound = gameData.spin.selfData.firstRound
        end
    end 
    self.m_isSuperFree = self.m_shopConfig.superFree

    -- 收到数据 开始计时
    if self.m_shopConfig and self.m_shopConfig.discountTime and self.m_shopConfig.discountTime > 0 then
        self.m_zheKouOffNode:setVisible(true)
        self.m_zheKouOffNode:runCsbAction("idle",false)
        self:upDataDiscountTime()
    else
        self.m_zheKouOffNode:setVisible(false)
    end
end

-- 刷新倒计时 折扣卷
function CodeGameScreenSpookySnacksMachine:upDataDiscountTime( )
    
    local leftTime = tonumber(self.m_shopConfig.endTime) - (globalData.userRunData.p_serverTime/1000)

    -- 倒计时之前先显示 出来数据
    if leftTime > 0 then
        self:showTimeDown(leftTime, self.m_zheKouOffNode)

        -- 显示商店的倒计时
        self:showTimeDown(leftTime, self.m_shopView.m_discountBar)
    end

    -- 
    if self.m_timeCutDown then
        return
    end

    self.m_timeCutDown =
        schedule(
        self:findChild("Node_yugao"),
        function()
            local leftTime = tonumber(self.m_shopConfig.endTime) - (globalData.userRunData.p_serverTime/1000)

            if leftTime > 0 then
                self:showTimeDown(leftTime, self.m_zheKouOffNode)

                -- 显示商店的倒计时
                self:showTimeDown(leftTime, self.m_shopView.m_discountBar)
            else
                -- 倒计时 结束
                if self.m_timeCutDown then
                    self:stopAction(self.m_timeCutDown)
                    self.m_timeCutDown = nil
                end
                self.m_shopConfig.discountTime = 0
                
                self:showTimeDown(0, self.m_zheKouOffNode)

                self.m_zheKouOffNode:runCsbAction("over",false,function ()
                    self.m_zheKouOffNode:setVisible(false)
                    
                end)
                -- 显示商店的倒计时
                -- self:showTimeDown(0, self.m_shopView.m_discountBar)

                self.m_shopView.m_discountBar:runCsbAction("over",false,function ()
                    --商店里的折扣信息
                    self.m_shopView.m_discountBar:setVisible(false)
                end)
                if self.m_shopView:isVisible() then
                    self.m_shopView.m_isZheKou = false
                    self.m_shopView:refreshView()
                    self.m_shopView:changeCoinNodeParent()
                end
            end
        end,
        1
    )
end

--[[
    通过时间戳 得到 小时 分钟 秒
]]
function CodeGameScreenSpookySnacksMachine:getHourMinuteSecond(_time)
    local hour = math.floor(_time / 3600)
    local minute = math.floor((_time % 3600) / 60)
    local second = math.floor(_time % 60)
    local second = string.format("%02d",second)

    return hour, minute, second
end

--[[
    显示倒计时 时间
]]
function CodeGameScreenSpookySnacksMachine:showTimeDown(_leftTime, _node)
    local hour, minute, second = self:getHourMinuteSecond(_leftTime)
    -- if hour > 0 then
    --     _node:findChild("Node_h"):setVisible(true)
    --     _node:findChild("Node_m"):setVisible(false)

        _node:findChild("Time_H"):setString(hour)
        _node:findChild("Time_M"):setString(minute)
        _node:findChild("Time_S"):setString(second)
    -- else
    --     _node:findChild("Node_h"):setVisible(false)
    --     _node:findChild("Node_m"):setVisible(true)

    --     _node:findChild("m_lb_num2_0_0"):setString(minute)
    --     _node:findChild("m_lb_num2_1_0"):setString(second)
    -- end

    
end

-- -----------------------------角标
--[[
    创建角标
]]
function CodeGameScreenSpookySnacksMachine:createCollectCoinsByNode(_symbolNode)
    local reelsIndex = self:getPosReelIdx(_symbolNode.p_rowIndex, _symbolNode.p_cloumnIndex)
        
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.score then
        local collectScore = selfData.score[reelsIndex + 1]
        if collectScore and collectScore > 0 then
            
            --创建积分角标
            if not _symbolNode.m_scoreItem then
                _symbolNode.m_scoreItem =  util_createAnimation("SpookySnacks_base_smallcoins.csb")
                _symbolNode:addChild(_symbolNode.m_scoreItem,1000)
                if _symbolNode.m_scoreItem:findChild("Particle_1") then
                    _symbolNode.m_scoreItem:findChild("Particle_1"):setVisible(false)
                end
                if _symbolNode.m_scoreItem:findChild("Particle_2") then
                    _symbolNode.m_scoreItem:findChild("Particle_2"):setVisible(false)
                end
                local symbolSize = CCSizeMake(self.m_SlotNodeW,self.m_SlotNodeH)
                local size = _symbolNode.m_scoreItem:findChild("di"):getContentSize()
                local scale = _symbolNode.m_scoreItem:findChild("di"):getScale()
                size.width = size.width * scale
                size.height = size.height * scale
                _symbolNode.m_scoreItem:setPosition(cc.p(symbolSize.width / 2 - size.width / 2,-symbolSize.height / 2 + size.height / 2))
            end
            _symbolNode.m_scoreItem:setVisible(true)
            _symbolNode.m_scoreItem.score = collectScore
            _symbolNode.m_scoreItem:findChild("m_lb_num"):setString(collectScore)
        end
    end
end

--[[
    收集商店积分
]]
function CodeGameScreenSpookySnacksMachine:flyCollectShopScore(_score, _startNode, _endNode, _func, _isPlaySound)

    local lizi = self:getLizi()
    if not tolua.isnull(lizi) then
        lizi:setVisible(true)
    end
    
    local flyNode = util_createAnimation("SpookySnacks_base_smallcoins.csb")
    flyNode:findChild("m_lb_num"):setString(_score)

    local startPos = util_convertToNodeSpace(_startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(_endNode,self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    if not tolua.isnull(lizi) then
        lizi:setPosition(startPos)
        if lizi:findChild("Particle_1") then
            lizi:findChild("Particle_1"):setVisible(false)
            lizi:findChild("Particle_1"):setDuration(1)     --设置拖尾时间(生命周期)
            lizi:findChild("Particle_1"):setPositionType(0)   --设置可以拖尾
        end
        if lizi:findChild("Particle_2") then
            lizi:findChild("Particle_2"):setVisible(false)
            lizi:findChild("Particle_2"):setDuration(1)     --设置拖尾时间(生命周期)
            lizi:findChild("Particle_2"):setPositionType(0)   --设置可以拖尾
        end
    
        local actionList = {
            cc.EaseQuadraticActionIn:create(cc.MoveTo:create(18 / 60,endPos))
        }
        local seq = cc.Sequence:create(actionList)
        lizi:runAction(seq)
    end
    
    

    -- flyNode:runCsbAction("shouji",false)

    -- if _isPlaySound then
    --     gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_jiaobiao_collect)
    -- end
    local actionList = {
        -- cc.DelayTime:create(20 / 60),
        cc.CallFunc:create(function()
            if not tolua.isnull(lizi) then
                if lizi:findChild("Particle_1") then
                    lizi:findChild("Particle_1"):setVisible(true)
                    lizi:findChild("Particle_1"):resetSystem()
                end
                if lizi:findChild("Particle_2") then
                    lizi:findChild("Particle_2"):setVisible(true)
                    lizi:findChild("Particle_2"):resetSystem()
                end
            end
            
        end),
        cc.EaseQuadraticActionIn:create(cc.MoveTo:create(18 / 60,endPos)),
        -- cc.DelayTime:create(18 / 60),
        cc.CallFunc:create(function()
            if not tolua.isnull(lizi) then
                if lizi:findChild("Particle_1") then
                    lizi:findChild("Particle_1"):stopSystem()
                end
                if lizi:findChild("Particle_2") then
                    lizi:findChild("Particle_2"):stopSystem()
                end
            end
            

            if not tolua.isnull(flyNode:findChild("Node_2")) then
                flyNode:findChild("Node_2"):setVisible(false)
            end
            if type(_func) == "function" then
                _func()
            end
            flyNode:removeFromParent()
        end)
        

    }
    local seq = cc.Sequence:create(actionList)
    flyNode:runAction(seq)
    flyNode:runCsbAction("shouji")
    
    self:delayCallBack(1 + 18 / 60,function()
        if not tolua.isnull(lizi) then
            lizi:setVisible(false)
            self:pushBackLizi(lizi)
        end
        
    end)

    -- local seq = cc.Sequence:create({
    --     cc.DelayTime:create(30/60),
    --     cc.CallFunc:create(function()
    --         if flyNode:findChild("Particle_1") then
    --             flyNode:findChild("Particle_1"):setVisible(true)
    --             flyNode:findChild("Particle_1"):resetSystem()
    --         end
    --         if flyNode:findChild("Particle_2") then
    --             flyNode:findChild("Particle_2"):setVisible(true)
    --             flyNode:findChild("Particle_2"):resetSystem()
    --         end
    --         -- self:delayCallBack(14/60, function()
    --         --     if type(_func) == "function" then
    --         --         _func()
    --         --     end
    --         -- end)
    --     end),
    --     cc.EaseCubicActionIn:create(cc.MoveTo:create(0.5,endPos)),
    --     cc.CallFunc:create(function()

    --         -- if _isPlaySound then
    --         --     gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_jiaobiao_fankui)
    --         -- end
    --         if flyNode:findChild("Particle_1") then
    --             flyNode:findChild("Particle_1"):stopSystem()
    --         end
    --         if flyNode:findChild("Particle_2") then
    --             flyNode:findChild("Particle_2"):stopSystem()
    --         end
    --         flyNode:findChild("Node_2"):setVisible(false)
    --         if type(_func) == "function" then
    --             _func()
    --         end
    --         self:delayCallBack(1, function()
    --             flyNode:removeFromParent()
    --         end)
    --     end),
    -- })

    -- flyNode:runAction(seq)
end

-- ---------------------大角色相关
function CodeGameScreenSpookySnacksMachine:showJveSeIdle()
    self.jveSeNode:stopAllActions()
    local actName = self:getJveSeIdleName()
    local actTime = self.bigJvse:getAnimationDurationTime(actName)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.bigJvse,actName,false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(actTime)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:showJveSeIdle()
    end)
    self.jveSeNode:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenSpookySnacksMachine:getJveSeIdleName()
    local random = math.random(1, 100)
    if random < 50 then
        return "idle"
    else 
        return "idle2"
    end
end

function CodeGameScreenSpookySnacksMachine:clickFunc(sender)
    CodeGameScreenSpookySnacksMachine.super.clickFunc(self,sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.peopleClick == false then
        return
    end
    if name == "ren_click" then
        self:showJveSeActionForClick()
    end
end

function CodeGameScreenSpookySnacksMachine:showJveSeActionForClick()
    self.peopleClick = false
    self.jveSeNode:stopAllActions()
    local actTime = self.bigJvse:getAnimationDurationTime("actionframe")
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        local random = math.random(1,10)
        if random <= 3 then
            if self.clickPeopleIndex == 1 then
                self.clickPeopleIndex = 2
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_people_click1)
            else
                self.clickPeopleIndex = 1
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_people_click2)
            end
        end
        util_spinePlay(self.bigJvse,"actionframe",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(actTime)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:showJveSeIdle()
        self.peopleClick = true
    end)
    self.jveSeNode:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenSpookySnacksMachine:showJveSeActionForFeature(_func)
    self.peopleClick = false
    self.jveSeNode:stopAllActions()
    local actTime = self.bigJvse:getAnimationDurationTime("actionframe_bigwin")
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.bigJvse,"actionframe_bigwin",false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(actTime)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        if _func then
            _func()
        end
        self:showJveSeIdle()
        self.peopleClick = true
    end)
    self.jveSeNode:runAction(cc.Sequence:create(actList))
end

-- ---------------------------bet
function CodeGameScreenSpookySnacksMachine:getMinBet( )
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

function CodeGameScreenSpookySnacksMachine:getBetLevel( )

    return self.m_betLevel
end

function CodeGameScreenSpookySnacksMachine:unlockHigherBet()
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

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenSpookySnacksMachine:upateBetLevel()
    local minBet = self:getMinBet( )
    self:updatJackpotLock( minBet ) 
end

function CodeGameScreenSpookySnacksMachine:updatJackpotLock( minBet )

    local betCoin = globalData.slotRunData:getCurTotalBet()
    if betCoin >= minBet  then
        if self.m_betLevel == nil or self.m_betLevel == 0 then
            self.m_betLevel = 1 
            -- 解锁jackpot
            self.m_jackPotBarView:showJackpotUnLock()
            self.m_respinjackPotBarView:showJackpotUnLock()
        end
    else
        if self.m_betLevel == nil or self.m_betLevel == 1 then
            self.m_betLevel = 0  
            -- 锁定jackpot
            self.m_jackPotBarView:showJackpotLock()
            self.m_respinjackPotBarView:showJackpotLock()
        end
        
    end 
end

--- ----------------------------第五列袋子相关
-- 滚动出来 袋子小块之后 的处理
function CodeGameScreenSpookySnacksMachine:collectEnvelopeResultEffect(effectData)
    self.m_isCanClickShop = false

    local score = 0
    local discountTime = 30
    if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.coins then
        score = self.m_runSpinResultData.p_selfMakeData.coins or 0
        if score == 0 then
            score = self.m_shopConfig.coins or 0
        else --刷新配置中的积分数量
            self.m_shopConfig.coins = score
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local specialBonus = selfData.specialBonus or {}

    local isFirst = true
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType == self.SYMBOL_BONUS4 then
                local symbol_node = symbolNode:checkLoadCCbNode()
                local spineNode = symbol_node:getCsbAct()
                local actionName1 = "actionframe"
                local actionName2 = "fly"

                -- -- 折扣卷
                -- if specialBonus[1] and specialBonus[1][2] and specialBonus[1][2] == "time" then
                --     discountTime = specialBonus[1][3]
                --     actionName1 = "actionframe2"
                --     actionName2 = "fly2"
                -- else

                -- end

                local flyNode = util_createAnimation("SpookySnacks_base_Bonus_jiangpin.csb")
                if specialBonus[1] and specialBonus[1][2] and specialBonus[1][2] == "time" then
                    
                    flyNode:findChild("Node_zhekouquan"):setVisible(true)
                    flyNode:findChild("Node_jinbi"):setVisible(false)
                else
                    
                    flyNode:findChild("m_lb_num"):setString(specialBonus[1][3])
                    flyNode:findChild("Node_zhekouquan"):setVisible(false)
                    flyNode:findChild("Node_jinbi"):setVisible(true)
                end

                local startPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                
                self.m_clipParent:addChild(flyNode,self:getBounsScatterDataZorder(97) - symbolNode.p_rowIndex -1)
                flyNode:setPosition(startPos)
                -- end
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_qiandai_open)
                symbolNode:runAnim(actionName1,false,function ()
                    symbolNode:runAnim("idleframe2",true)

                end)
                self:delayCallBack(20/30,function ()
                    flyNode:runCsbAction("start",false,function ()
                        self:flyCollectBonus4Result(flyNode,score, symbolNode, specialBonus, function()
                            if #specialBonus <= 0 then
                                return
                            end
                            if specialBonus[1] and specialBonus[1][2] and specialBonus[1][2] == "time" then
                                local time = 12/60
                                if self.m_zheKouOffNode:isVisible() then
                                    self.m_zheKouOffNode:setVisible(true)
                                    self.m_zheKouOffNode:runCsbAction("actionframe2",false)
                                else
                                    time = 12/60 + 30/60
                                    self.m_zheKouOffNode:findChild("Time_H"):setString(00)
                                    self.m_zheKouOffNode:findChild("Time_M"):setString(00)
                                    self.m_zheKouOffNode:findChild("Time_S"):setString(00)
                                    self.m_zheKouOffNode:setVisible(true)
                                    self.m_zheKouOffNode:runCsbAction("actionframe",false,function ()
                                        self.m_zheKouOffNode:runCsbAction("actionframe2",false)
                                    end)
                                end
                                
                                
                                self:delayCallBack(time,function()
                                    self.m_shopConfig.endTime = selfData.endTime
                                    self.m_shopConfig.discountTime = selfData.discountTime
    
                                    -- 开始倒计时
                                    self:upDataDiscountTime()
                                end)
                            else
                                self.m_coinCollectBar:runCsbAction("actionframe",false,function()
                                    self.m_coinCollectBar:runCsbAction("idle",true)
                                end)
                                --刷新商店积分
                                self.m_coinCollectBar:updateCoins(score)
                            end
                            self.m_isCanClickShop = true
                        end,discountTime)
    
                        if isFirst then
                            isFirst = false
                            effectData.p_isPlay = true
                            self:playGameEffect()
                        end
                    end)
                end)
            end
        end
    end
end

--[[
    飞 收集 bonus4 信封打开之后 的折扣卷 或者 金币
]]
function CodeGameScreenSpookySnacksMachine:flyCollectBonus4Result(flyNode,_score, _startNode, _specialBonus, _func, _discountTime)

    if #_specialBonus <= 0 then
        if type(_func) == "function" then
            _func()
        end
        return
    end
    --BlackFriday_bonus_off
    -- local flyNode = util_createAnimation("SpookySnacks_base_Bonus_jiangpin.csb")
    local endNode = self.m_coinCollectBar:getCollectEndNode()
    local startPos = nil
    local moveTime = 14/30
    local isCoins = false
    --切换父节点
    util_changeNodeParent(self.m_effectNode,flyNode)
    if _specialBonus[1] and _specialBonus[1][2] and _specialBonus[1][2] == "time" then
        endNode = self.m_zheKouOffNode:findChild("Node_baozha")
        startPos = util_convertToNodeSpace(_startNode,self.m_effectNode)
    else
        isCoins = true
        startPos = util_convertToNodeSpace(_startNode,self.m_effectNode)
    end

    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    endPos.y = endPos.y - 125

    flyNode:setPosition(startPos)
    flyNode:runCsbAction("fly",false)
    local particle1 = flyNode:findChild("Particle_1")
    local particle2 = flyNode:findChild("Particle_2")
    local seq = cc.Sequence:create({
        cc.CallFunc:create(function()
            if particle1 and particle2 then
                particle1:setDuration(-1)     --设置拖尾时间(生命周期)
                particle1:setPositionType(0)   --设置可以拖尾
                particle2:setDuration(-1)     --设置拖尾时间(生命周期)
                particle2:setPositionType(0)   --设置可以拖尾
                particle1:resetSystem()
                particle2:resetSystem()
            end
        end),
        cc.CallFunc:create(function()
            if _specialBonus[1] and _specialBonus[1][2] and _specialBonus[1][2] == "time" then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_zhekou_collect)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_fiveCol_coins)
            end
        end),
        cc.EaseCubicActionIn:create(cc.MoveTo:create(moveTime,endPos)),
        cc.CallFunc:create(function()

            if type(_func) == "function" then
                _func()
            end
            if _specialBonus[1] and _specialBonus[1][2] and _specialBonus[1][2] == "time" then
            else
                flyNode:findChild("m_lb_num"):setVisible(false)
            end
            if particle1 and particle2 then
                particle1:stopSystem()
                particle2:stopSystem()
            end
        end),
        cc.DelayTime:create(0.5),
        cc.CallFunc:create(function()
            flyNode:removeFromParent()
        end),
    })

    flyNode:runAction(seq)
end

------------------------ui相关
function CodeGameScreenSpookySnacksMachine:changeUiForState(state)
    self:findChild("Node_1"):setVisible(true)
    self:findChild("Node_2"):setVisible(true)
    self.m_baseFreeSpinBar:setVisible(state == PublicConfig.uiState.free or state == PublicConfig.uiState.superFree)
    
    self.m_coinCollectBar:setVisible(state == PublicConfig.uiState.base)

    self:findChild("Node_off"):setVisible(state == PublicConfig.uiState.base)
    self:findChild("Node_reel"):setVisible(state ~= PublicConfig.uiState.respin)
    self:findChild("Node_3"):setVisible(state == PublicConfig.uiState.base)
    self.m_respinbar:setVisible(state == PublicConfig.uiState.respin)

    self.m_gameBg:findChild("base"):setVisible(state == PublicConfig.uiState.base)
    self.m_gameBg:findChild("fg"):setVisible(state == PublicConfig.uiState.free)
    self.m_gameBg:findChild("respin"):setVisible(state == PublicConfig.uiState.respin)
    self.m_gameBg:findChild("shop"):setVisible(state == PublicConfig.uiState.shop)
    self.m_gameBg:findChild("superfg"):setVisible(state == PublicConfig.uiState.superFree)
    if state == PublicConfig.uiState.base then
        if self.bigJvse then
            self.bigJvse:setVisible(true)
            self:showJveSeIdle()
        end
        
        self:findChild("Node_base_reel"):setVisible(true)
        self:findChild("Node_free_reel"):setVisible(false)
        self:findChild("base_xian"):setVisible(true)
        self:findChild("fg_xian"):setVisible(false)
    elseif state == PublicConfig.uiState.free then
        if self.bigJvse then
            self.bigJvse:setVisible(true)
            self:showJveSeIdle()
        end
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("base_xian"):setVisible(false)
        self:findChild("fg_xian"):setVisible(true)
    elseif state == PublicConfig.uiState.respin then
        self.bigJvse:setVisible(false)
        self.peopleClick = false                 --角色是否可点击
    elseif state == PublicConfig.uiState.shop then
        self.bigJvse:setVisible(false)
        self:findChild("Node_1"):setVisible(false)
        self:findChild("Node_2"):setVisible(false)
    elseif state == PublicConfig.uiState.superFree then
        if self.bigJvse then
            self.bigJvse:setVisible(true)
            self:showJveSeIdle()
        end
        self:findChild("Node_base_reel"):setVisible(false)
        self:findChild("Node_free_reel"):setVisible(true)
        self:findChild("base_xian"):setVisible(false)
        self:findChild("fg_xian"):setVisible(true)
    end
end

function CodeGameScreenSpookySnacksMachine:changeShowJackpotBar(isRespin)
    if isRespin then
        self.m_jackPotBarView:setVisible(false)
        self.m_respinjackPotBarView:setVisible(true)
    else
        self.m_jackPotBarView:setVisible(true)
        self.m_respinjackPotBarView:setVisible(false)
    end
end

---过场
function CodeGameScreenSpookySnacksMachine:showGuochang(func1,func2,isOver)
    if not self.guoChangSpine then
        --过场
        self.guoChangSpine = util_spineCreate("SpookySnacks_guochang",true, true)
        self.guoChangSpine:setScale(self.m_machineRootScale)
        self:addChild(self.guoChangSpine, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
        self.guoChangSpine:setPosition(display.width * 0.5, display.height * 0.5)
        self.guoChangSpine:setVisible(false)
    end
    self.guoChangSpine:setVisible(true)
    local actName = "actionframe_guochang"
    local waitTime = 20/30
    if self.m_isSuperFree then
        actName = "actionframe_guochang2"
    end
    if self.m_isSuperFree then
        if isOver then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_superFreeOver_guochang)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_superFree_guoChang)
        end
        
    else
        if isOver then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_freeSpinOver_guochang)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_freeSpinStart_guochang)
        end
    end
    util_spinePlay(self.guoChangSpine, actName)
    util_spineEndCallFunc(self.guoChangSpine, actName, function ()
        self.guoChangSpine:setVisible(false)
        if type(func2) == "function" then
            func2()
        end
    end)
    self:delayCallBack(20/30,function ()
        if type(func1) == "function" then
            func1()
        end
    end)
end

function CodeGameScreenSpookySnacksMachine:respinGuoChang(_func1,_func2,isStart)
    if isStart then
        if not self.respinStartGuochang then
            --respinStart
            self.respinStartGuochang = util_spineCreate("SpookySnacks_juese", true, true)
            self.respinStartGuochang:setScale(self.m_machineRootScale)
            self:addChild(self.respinStartGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
            self.respinStartGuochang:setPosition(display.width * 0.5, display.height * 0.5)
            self.respinStartGuochang:setVisible(false)
        end
        self.respinStartGuochang:setVisible(true)
        util_spinePlay(self.respinStartGuochang,"guochang_idle",false)

        local idleTime = 162/30

        self:delayCallBack(143/30,function ()
            if _func1 then
                _func1()
            end
        end)
        self:delayCallBack(idleTime,function ()
            self.respinStartGuochang:setVisible(false)
            if _func2 then
                _func2()
            end
        end)
    else
        if not self.respinStartGuochang2 then
            --respinStart
            self.respinStartGuochang2 = util_spineCreate("SpookySnacks_guochang1", true, true)
            self.respinStartGuochang2:setScale(self.m_machineRootScale)
            self:addChild(self.respinStartGuochang2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
            self.respinStartGuochang2:setPosition(display.width * 0.5, display.height * 0.5)
            self.respinStartGuochang2:setVisible(false)
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respinOver_guochang)
        self.respinStartGuochang2:setVisible(true)
        util_spinePlay(self.respinStartGuochang2,"guochang",false)

        local idleTime = 52/30

        self:delayCallBack(18/30,function ()
            if _func1 then
                _func1()
            end
        end)
        self:delayCallBack(idleTime,function ()
            self.respinStartGuochang2:setVisible(false)
            if _func2 then
                _func2()
            end
        end)
    end
    
end

-----------------------------superFree
--[[
    添加freespin
]]
function CodeGameScreenSpookySnacksMachine:addFreeEffect()
    -- 添加freespin effect
    local freeSpinEffect = GameEffectData.new()
    freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
    freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect

    --手动添加freespin次数
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount
end
--[[
    触发superfree
]]
function CodeGameScreenSpookySnacksMachine:triggerSuperFree()
    self.m_isSuperFree = true
    --添加free事件
    self:addFreeEffect()
    
    self:playGameEffect()
end

--[[
    刷新固定图标
]]
function CodeGameScreenSpookySnacksMachine:refreshLockWild(_func, _isDuanXian)
    --已经创建好了,不需要二次创建
    if #self.m_lockWilds > 0 then
        return
    end

    local superFreeType = self.m_runSpinResultData.p_selfMakeData.superFreeType
    if not superFreeType then
        return
    end
    
    local wildConfig = self.m_shopConfig.shopWildConfig[tostring(superFreeType)]
    if not _isDuanXian then
        --创建wild图标
        for i,posIndex in ipairs(wildConfig) do

            local pos = util_getOneGameReelsTarSpPos(self,posIndex ) 
            local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
            local nodePos = self:findChild("Node_yugao"):convertToNodeSpace(worldPos)

            local wildAni = util_spineCreate("Socre_SpookySnacks_Wild",true,true)
            self:findChild("Node_yugao"):addChild(wildAni, -1)
            wildAni:setPosition(nodePos)
            util_spinePlay(wildAni, "idleframe", false)
            wildAni:setVisible(false)
            
            self.m_lockWilds[#self.m_lockWilds + 1] = wildAni
        end
    else
        --创建wild图标
        for i,posIndex in ipairs(wildConfig) do

            local pos = util_getOneGameReelsTarSpPos(self,posIndex ) 
            local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(pos))
            local nodePos = self:findChild("Node_yugao"):convertToNodeSpace(worldPos)

            local wildAni = util_spineCreate("Socre_SpookySnacks_Wild",true,true)
            self:findChild("Node_yugao"):addChild(wildAni, -1)
            wildAni:setPosition(nodePos)
            if _isDuanXian then
                util_spinePlay(wildAni, "idleframe", false)
                wildAni:setVisible(false)
            else
                util_spinePlay(wildAni, "idleframe", false)
            end
            
            self.m_lockWilds[#self.m_lockWilds + 1] = wildAni
        end
    end
    
    if _func then
        self:delayCallBack(1/30,function()
            _func()
        end)
    end
end

--[[
    superfree 第一次 需要显示 棋盘遮罩 和 wild 出现的爆炸
]]
function CodeGameScreenSpookySnacksMachine:superFreeDarkEffect(_func)
    self.m_superFreeQiPanDark:setVisible(true)
    self.m_superFreeQiPanDark:runCsbAction("start",false,function()
        self.m_superFreeQiPanDark:runCsbAction("idle",false)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_superFree_wild_show)
        for index, wildNode in ipairs(self.m_lockWilds) do
            wildNode:setVisible(true)
            util_spinePlay(wildNode, "start", false)
            self:delayCallBack(30/30,function ()
                util_spinePlay(wildNode, "idleframe", false)
            end)
        end
        self:delayCallBack(31/30,function ()
            self.m_superFreeQiPanDark:runCsbAction("over",false,function()
                self.m_superFreeQiPanDark:setVisible(false)
            end)
            if _func then
                _func()
            end
        end)
    end)
end

--[[
    清空固定图标
]]
function CodeGameScreenSpookySnacksMachine:clearLockWild()
    for i,wildAni in ipairs(self.m_lockWilds) do
        wildAni:removeFromParent()
    end
    self.m_lockWilds = {}
end

function CodeGameScreenSpookySnacksMachine:updateNetWorkData()
    self:showFeatureGameTip(
        function()
            gLobalDebugReelTimeManager:recvStartTime()

            local isReSpin = self:updateNetWorkData_ReSpin()
            if isReSpin == true then
                return
            end
            if self.m_bProduceSlots_InFreeSpin then
                local freeNum = self.m_runSpinResultData.p_freeSpinsTotalCount - self.m_runSpinResultData.p_freeSpinsLeftCount 
                if self.m_isSuperFree and freeNum == 1 then
                    self:clearLockWild()
                    --刷新固定图标
                    self:refreshLockWild(function()
                        self:superFreeDarkEffect(function()
                            self:produceSlots()
        
                            local isWaitOpera = self:checkWaitOperaNetWorkData()
                            if isWaitOpera == true then
                                return
                            end
        
                            self.m_isWaitingNetworkData = false
                            self:operaNetWorkData() -- end
                        end)
                    end)
                else
                    self:produceSlots()
        
                    local isWaitOpera = self:checkWaitOperaNetWorkData()
                    if isWaitOpera == true then
                        return
                    end
        
                    self.m_isWaitingNetworkData = false
                    self:operaNetWorkData() -- end
                end
            else
                self:produceSlots()
            
                local isWaitOpera = self:checkWaitOperaNetWorkData()
                if isWaitOpera == true then
                    return
                end
        
                self.m_isWaitingNetworkData = false
                self:operaNetWorkData() -- end
            end
        end
    )
end

function CodeGameScreenSpookySnacksMachine:showSuperFreeSpinStart(num, func, isAuto)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_superFree_start)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local view
    if isAuto then
        view = self:showDialog("SuperFreeSpinStart", ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog("SuperFreeSpinStart", ownerlist, func)
    end
    local superFreeType = selfData.superFreeType or 1
    local smallReel =  util_createAnimation("SpookySnacks_shop_xiaoqipan.csb")
    if superFreeType then
        for index = 1,5 do
            smallReel:findChild("Node_"..index):setVisible(index == (superFreeType + 1))
        end
    end
    local light = util_createAnimation("SpookySnacks/FreeSpinOver_glow.csb")
    view:findChild("xzg_tx"):addChild(light)
    light:runCsbAction("idleframe",true)
    view:findChild("node_xiaoqipan"):addChild(smallReel)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_superFree_over)
    end)
    return view
end

-------------------------respin小棋盘
-- respin 说明弹板
function CodeGameScreenSpookySnacksMachine:showReSpinExplainView(_func)
   
    local explainView = util_createView("CodeSpookySnacksSrc.SpookySnacksReSpinExplainView", {machine = self, callBackFunc = _func})
    if globalData.slotRunData.machineData.p_portraitFlag then
        explainView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respin_tips)
    gLobalViewManager:showUI(explainView, ViewZorder.ZORDER_UI_LOWER)
    explainView:setPosition(display.width * 0.5, display.height * 0.5)
    explainView:setScale(self.m_machineRootScale)
end

--ReSpin开始改变UI状态
function CodeGameScreenSpookySnacksMachine:changeReSpinStartUI(respinCount)
    self.m_respinbar:updateCount(respinCount,false)
    self.m_respinbar:setVisible(true)
 end
 
 --ReSpin刷新数量
 function CodeGameScreenSpookySnacksMachine:changeReSpinUpdateUI(curCount,isInit)
     self.m_respinbar:updateCount(curCount,isInit)
 end
 
 --ReSpin结算改变UI状态
 function CodeGameScreenSpookySnacksMachine:changeReSpinOverUI()
     self.m_respinbar:setVisible(false)
 end
 
 -- 根据本关卡实际小块数量填写
 function CodeGameScreenSpookySnacksMachine:getRespinRandomTypes( )
     local symbolList = {
        self.SYMBOL_BONUS1,
        self.SYMBOL_BONUS2,
        self.SYMBOL_BONUS3,
        self.SYMBOL_SCORE_BLANK
     }
 
     return symbolList
 end
 
 -- 根据本关卡实际锁定小块数量填写
 function CodeGameScreenSpookySnacksMachine:getRespinLockTypes( )
     local symbolList = {
         {type = self.SYMBOL_BONUS1, runEndAnimaName = "buling", bRandom = true},
         {type = self.SYMBOL_BONUS2, runEndAnimaName = "buling", bRandom = false},
         {type = self.SYMBOL_BONUS3, runEndAnimaName = "buling", bRandom = true},
     }
 
     return symbolList
 end
 
function CodeGameScreenSpookySnacksMachine:showReSpinStart(_func)
    if not self.respinStartGuochang then
        --respinStart
        self.respinStartGuochang = util_spineCreate("SpookySnacks_juese", true, true)
        self.respinStartGuochang:setScale(self.m_machineRootScale)
        self:addChild(self.respinStartGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
        self.respinStartGuochang:setPosition(display.width * 0.5, display.height * 0.5)
        self.respinStartGuochang:setVisible(false)
    end
    self.respinStartGuochang:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respin_start)
    util_spinePlay(self.respinStartGuochang,"guochang_start",false)
    local startTime = 44/30

    self:delayCallBack(startTime,function ()
        self.respinStartGuochang:setVisible(false)
        if _func then
            _func()
        end
    end)
end
 
--[[
    respin 相关
]]
function CodeGameScreenSpookySnacksMachine:showRespinView()
    -- 停掉背景音乐
    self:clearCurMusicBg()
    --播放触发动画
    local curBonusList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if node then
                if node.p_symbolType == self.SYMBOL_BONUS1 then
                    local symbolNode = util_setSymbolToClipReel(self,iCol, iRow, node.p_symbolType,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
                    curBonusList[#curBonusList + 1] = node
                end
            end
        end
    end
    self.isChangeRespinBonus3 = false
    for miniIndex = 1, self.m_MiNiTotalNum do
        self.m_miniMachine[miniIndex]:changeBonusType(self.isChangeRespinBonus3)
    end
    local random = math.random(1,2)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respin_trigger)

    -- 角色动画
    self:showJveSeActionForFeature()
    
    -- 播放触发动画
    for bonusIndex, bonusNode in ipairs(curBonusList) do
        bonusNode:runAnim("actionframe",false,function (  )
            bonusNode:runAnim("idleframe",true)
        end)
    end

    self:delayCallBack(2,function()
        self.noClickLayer:setVisible(true)
        local view = self:showReSpinStart(function()
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()

            self:respinGuoChang(function()
                self.m_isReSpin = true
                
                -- self.m_configData:setRespinType(0)
                
                self:changeUiForState(PublicConfig.uiState.respin)
                self:changeShowJackpotBar(true)
                self:setCurrSpinMode(RESPIN_MODE)

                -- 重置一下这个字段 防止刚好升级的时候 触发了respin玩法 报错
                self.m_spinIsUpgrade = false

                self.m_bonus3List = {}
                self.m_bonus3MiniMachineList = {}

                self:showReSpinMiNiBanzi(false)

                self:isNeedShowDangBanTips()

                for miniIndex = 1, self.m_MiNiTotalNum do
                    self.m_miniMachine[miniIndex]:setVisible(true)
                    self.m_miniMachine[miniIndex]:initMiniReelData(self.m_runSpinResultData.p_rsExtraData["reels"..miniIndex])

                    self.m_miniMachine[miniIndex]:showRespinView()

                    util_nodeFadeIn(self.m_miniMachine[miniIndex], 20/60, 0, 255, nil, function()
                    end)
                end
                -- if not self.m_bProduceSlots_InFreeSpin then
                    --清空赢钱
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN) 
                -- end
                

            end,function()
                self.noClickLayer:setVisible(false)
                self.m_respinMiniIndex = 2
                self.m_respinBanZiIndex = 1

                self:playRespinBanZiIdle()
                if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.Row then
                    -- 行数最大为9行 全部挡板打开不在播放扫光
                    if self.m_runSpinResultData.p_rsExtraData.Row >= 9 then
                        self.isChangeRespinBonus3 = true
                        for miniIndex = 1, self.m_MiNiTotalNum do
                            self.m_miniMachine[miniIndex]:changeBonusType(self.isChangeRespinBonus3)
                        end
                    end
                end

                -- 开始jackpot切换
                -- self.m_jackpotRespinBar:playJackpot()

                -- 弹出说明弹板
                self:showReSpinExplainView(function()
                    for miniIndex = 1, self.m_MiNiTotalNum do
                        self.m_miniMachine[miniIndex]:runNextReSpinReel()
                    end
                end)
            end,true)
        end)
    end)
    
end

-- 判断当前respin 挡板上是否需要显示解锁说明
function CodeGameScreenSpookySnacksMachine:isNeedShowDangBanTips( )
    if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.Row then

        if self.m_runSpinResultData.p_rsExtraData.Row > 9 then
            self.m_runSpinResultData.p_rsExtraData.Row = 9
        end

        --显示解锁说明的行数
        local row = self.m_runSpinResultData.p_rsExtraData.Row + 1

        for miniIndex = 1, self.m_MiNiTotalNum do
            for banziIndex = 1, 3 do
                local rowIndex = (miniIndex - 1)*3 + banziIndex
                local banziNode = self.m_miniMachine[miniIndex]["banzi"..banziIndex] 
                if banziNode:isVisible() and rowIndex == row then
                    if not banziNode.m_tips then
                        local dangbanTips = util_createAnimation("SpookySnacks_respin_suodingtips.csb")
                        banziNode:getParent():addChild(dangbanTips,10)
                        dangbanTips:runCsbAction("start",false,function()
                            dangbanTips:runCsbAction("idle",true)
                        end)
                        banziNode.m_tips = dangbanTips
                    end
                    return
                end
            end
        end
    end
end

-- 判断当前respin 挡板上是否需要关闭解锁说明
function CodeGameScreenSpookySnacksMachine:isNeedCloseDangBanTips( )
    for miniIndex = 1, self.m_MiNiTotalNum do
        for banziIndex = 1, 3 do
            local banziNode = self.m_miniMachine[miniIndex]["banzi"..banziIndex] 
            if banziNode:isVisible() and banziNode.m_tips then
                banziNode.m_tips:runCsbAction("over",false,function()
                    banziNode.m_tips:removeFromParent()
                    banziNode.m_tips = nil
                end)
                return
            end
        end
    end
end

-- 显示当前的小轮盘上面的板子
function CodeGameScreenSpookySnacksMachine:showReSpinMiNiBanzi(_isPlayEffect, _func)
    -- 没有滚动出来 bonus3 不需要升行 
    if _isPlayEffect and #self.m_bonus3List <= 0 then
        if _func then
            _func()
        end
        return
    end

    local isFirst = true
    local isFirstPlay = true
    if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.Row then
        local isPlaySound = true
        -- 行数最大为9行 防止 服务器数据大于9 
        if self.m_runSpinResultData.p_rsExtraData.Row > 9 then
            self.m_runSpinResultData.p_rsExtraData.Row = 9
        end
        if self.m_runSpinResultData.p_rsExtraData.Row >= 9 then
            self.isChangeRespinBonus3 = true
            for miniIndex = 1, self.m_MiNiTotalNum do
                self.m_miniMachine[miniIndex]:changeBonusType(self.isChangeRespinBonus3)
            end
        end
        -- 计算属于第几个小轮盘
        local miniIndex = math.floor(self.m_runSpinResultData.p_rsExtraData.Row / self.m_MiNiTotalNum)
        -- 计算属于小轮盘的第几个板子
        local miniBanZiIndex = self.m_runSpinResultData.p_rsExtraData.Row % self.m_MiNiTotalNum

        local dangbanEffectFunc = function(dangBanNode)
            if dangBanNode:isVisible() then
                if _isPlayEffect then
                    if self.m_bonus3List[1] then
                        local bonus3Node = clone(self.m_bonus3List[1])
                        table.remove(self.m_bonus3List, 1)
                        -- local oldZorder = bonus3Node:getLocalZOrder()
                        -- bonus3Node:setLocalZOrder(oldZorder * 10)
                        local tempNode = util_spineCreate("Socre_SpookySnacks_Bonus3",true,true)

                        local startPos = util_convertToNodeSpace(bonus3Node,self:findChild("Node_fly"))

                        self:findChild("Node_fly"):addChild(tempNode,2)
                        tempNode:setPosition(startPos)
                        bonus3Node:setVisible(false)
                        tempNode:setScale(0.75)
                        if isFirstPlay then
                            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_bonus2_trigger)
                        end
                        util_spinePlay(tempNode,"actionframe")
                        local waitTime = 40/30
                        self:delayCallBack(waitTime,function ()
                            bonus3Node:setVisible(true)
                            tempNode:setVisible(false)
                            self:delayCallBack(0.1,function ()
                                tempNode:removeFromParent()
                            end)
                            
                            self:isNeedCloseDangBanTips()

                            self:playBonus3FlyEffect(bonus3Node, dangBanNode, function()
                                dangBanNode.isPlayEffect = true
                                util_spinePlay(dangBanNode,"actionframe")
                                
                                
                                util_spineEndCallFunc(dangBanNode,"actionframe",function ()
                                    dangBanNode:setVisible(false)

                                    if isFirstPlay then
                                        isFirstPlay = false
                                        self:delayCallBack(0.5,function()
                                            self:isNeedShowDangBanTips()
                                        end)
                                    end
                                end)
                            end, function()
                                -- 继续下面 流程
                                if isFirst then
                                    isFirst = false

                                    if _func then
                                        _func()
                                    end
                                end
                            end, isPlaySound)

                            if isPlaySound then
                                isPlaySound = false
                            end
                        end)
                    end
                else
                    dangBanNode:setVisible(false)
                end
            end
        end

        for miniReelIndex = 1, miniIndex do
            for banziIndex=1,3 do
                local dangBanNode = self.m_miniMachine[miniReelIndex]["banzi"..banziIndex]
                dangbanEffectFunc(dangBanNode)
            end
        end

        -- 表示整个的小轮盘板子 都打开了
        if miniBanZiIndex ~= 0 then
            for banziIndex=1,miniBanZiIndex do
                local dangBanNode = self.m_miniMachine[miniIndex+1]["banzi"..banziIndex]
                dangbanEffectFunc(dangBanNode)
            end
        end
    end
end

--[[
    播放respin挡板上面的 idle 
    每隔5帧播一个idle 依次播放 播放一轮后 空80帧 在播一次 以此类推
    self.m_respinMiniIndex = 2
    self.m_respinBanZiIndex = 1
]]
function CodeGameScreenSpookySnacksMachine:playRespinBanZiIdle()
    if not self.m_isReSpin then
        return
    end

    if self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.Row then
        -- 行数最大为9行 全部挡板打开不在播放扫光
        if self.m_runSpinResultData.p_rsExtraData.Row >= 9 then
            return
        end
    end

    local delayTime = 5/30
    local dangBanNode = self.m_miniMachine[self.m_respinMiniIndex]["banzi"..self.m_respinBanZiIndex]

    self.m_respinBanZiIndex = self.m_respinBanZiIndex + 1
    if self.m_respinMiniIndex == 2 and self.m_respinBanZiIndex > 3 then
        self.m_respinMiniIndex = 3
        self.m_respinBanZiIndex = 1
    end
    
    if self.m_respinMiniIndex == 3 and self.m_respinBanZiIndex > 3 then
        self.m_respinMiniIndex = 2
        self.m_respinBanZiIndex = 1
        delayTime = 80/30
    end

    if not dangBanNode:isVisible() or dangBanNode.isPlayEffect then
        self:playRespinBanZiIdle()
        return
    end
    dangBanNode:setVisible(true)
    util_spinePlay(dangBanNode,"idle",true)
    
    self:delayCallBack(delayTime,function()
        self:playRespinBanZiIdle()
    end)
end

--[[
    respin 棋盘滚动出来 bonus3之后 存在列表
    miniMachineIndex 表示mini轮盘的index 1 2 3
]]
function CodeGameScreenSpookySnacksMachine:addBonus3List(_node, _miniMachineIndex)
    
    self.m_bonus3List[#self.m_bonus3List + 1] = _node
    self.m_bonus3MiniMachineList[#self.m_bonus3MiniMachineList + 1] = _miniMachineIndex

end

--[[
    显示小棋盘 集满的棋盘动画
]]
function CodeGameScreenSpookySnacksMachine:showMiniQiPanEffect(_miniMachineIndex,isSound)
    if self.m_miniMachine[_miniMachineIndex].qiPanEffect:isVisible() then
        return false
    end
    if not self.respinDark:isVisible() then
        self.respinDark:setVisible(true)
        util_spinePlay(self.respinDark,"dark",false)
        util_spineEndCallFunc(self.respinDark,"dark",function()
            self.respinDark:setVisible(false)
        end)
    end
    if not isSound then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_mini_jiman)
    end
    
    self:showMiniQiPanTriggerEffect(_miniMachineIndex, function()
        self.m_miniMachine[_miniMachineIndex].qiPanEffect:setVisible(true)
        self.m_miniMachine[_miniMachineIndex].qiPanEffect:runCsbAction("idle",true)
    end)

    return true
end

--[[
    棋盘集满的触发动画
]]
function CodeGameScreenSpookySnacksMachine:showMiniQiPanTriggerEffect(_miniMachineIndex, _func)
    
    self.m_miniMachine[_miniMachineIndex]:getParent():setLocalZOrder(100 - _miniMachineIndex)

    if self.m_respinQiPanJimanPlaySound then
        self.m_respinQiPanJimanPlaySound = false
        -- gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_qipan_jiman)
    end

    if self:checkJiManNum(false) > 1 then
        local effectNode = self.respinNewEffectList[_miniMachineIndex]
        if not tolua.isnull(effectNode) then
            effectNode:setVisible(true)
            util_spinePlay(effectNode,"actionframe2",false)
            util_spineEndCallFunc(effectNode,"actionframe2",function()
                effectNode:setVisible(false)
            end)
        end
    else
        self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine:setVisible(true)

        util_spinePlay(self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine,"actionframe2",false)
        util_spineEndCallFunc(self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine,"actionframe2",function()
            self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine:setVisible(false)
            
        end)
    end
    
    self:delayCallBack(62/30,function()
        self.m_miniMachine[_miniMachineIndex]:getParent():setLocalZOrder(4 - _miniMachineIndex)
        if _func then
            _func()
        end
    end)

end

--[[
    respin 棋盘滚动出来 bonus3之后 的动画
]]
function CodeGameScreenSpookySnacksMachine:playBonus3FlyEffect(_chipBonus3Node, _endNode, _func1, _func2, _isPlaySound)
    

    local flyNode = util_spineCreate("Socre_SpookySnacks_Bonus3",true,true)
    local diNode = util_spineCreate("Socre_SpookySnacks_Bonus3",true,true)

    local startPos = util_convertToNodeSpace(_chipBonus3Node,self:findChild("Node_fly"))
    local endPos = util_convertToNodeSpace(_endNode,self:findChild("Node_fly"))

    self:findChild("Node_fly"):addChild(flyNode,2)
    flyNode:setPosition(startPos)
    self:findChild("Node_fly"):addChild(diNode,1)
    diNode:setPosition(startPos)
    flyNode:setScale(0.75)
    diNode:setScale(0.75)

    util_spinePlay(flyNode,"shouji")
    util_spinePlay(diNode,"over")
    local time= diNode:getAnimationDurationTime("over")
    self:delayCallBack(time,function ()
        diNode:removeFromParent()
    end)
    -- fly 70-164帧
    -- 第100帧的时候 飞， 130帧 结束飞行
    local seq = cc.Sequence:create({
        cc.CallFunc:create(function()
            -- 钥匙飞走之后 bonus3上显示金币数量
            self:showBonus3Coins(_chipBonus3Node)
            if _isPlaySound then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_bonus2_collect)
            end
        end),
        cc.EaseCubicActionIn:create(cc.MoveTo:create(15/30,endPos)),
        cc.DelayTime:create(10/30),
        cc.CallFunc:create(function()
            if _isPlaySound then
                if self.upReelIndex == 1 then
                    self.upReelIndex = 2
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_upReel1)
                else
                    self.upReelIndex = 1
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_upReel2)
                end
            end
            if type(_func1) == "function" then
                _func1()
            end

        end),
        cc.DelayTime:create(0.5),
        cc.CallFunc:create(function()

            if type(_func2) == "function" then
                _func2()
            end

        end),
        cc.CallFunc:create(function()

            flyNode:setVisible(false)

        end),
        cc.DelayTime:create(0.1),
        cc.CallFunc:create(function()

            flyNode:removeFromParent()

        end)
    })

    flyNode:runAction(seq)
    
end
 
 --[[
    钥匙飞走之后 显示金币在 bonus3上
]]
function CodeGameScreenSpookySnacksMachine:showBonus3Coins(_chipBonus3Node)
    self:changeSymbolType(_chipBonus3Node,self.SYMBOL_BONUS1,true)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = 1 * lineBet
    self:addCCbForBonusSpine(_chipBonus3Node,score)
    _chipBonus3Node:runAnim("start",false,function ()
        _chipBonus3Node:runAnim("idleframe2",true)
    end)

end

--[[
    @desc: 计算每条应前线
    time:2020-07-21 20:48:31
    @return:
]]
function CodeGameScreenSpookySnacksMachine:lineLogicWinLines()
    local isFiveOfKind = false
    local winLines = self.m_runSpinResultData.p_winLines
    if self:getCurrSpinMode() == RESPIN_MODE then
        winLines = {}
    -- else
    --     if self.m_runSpinResultData.p_reSpinsTotalCount > 0 and self.m_runSpinResultData.p_reSpinCurCount >= 0 then
    --         winLines = {}
    --     end
    end 
    if #winLines > 0 then
        self:compareScatterWinLines(winLines)

        for i = 1, #winLines do
            local winLineData = winLines[i]
            local iconsPos = winLineData.p_iconPos

            -- 处理连线数据
            local lineInfo = self:getReelLineInfo()
            local enumSymbolType = self:lineLogicEffectType(winLineData, lineInfo, iconsPos)

            lineInfo.enumSymbolType = enumSymbolType
            lineInfo.iLineIdx = winLineData.p_id
            lineInfo.iLineSymbolNum = #iconsPos
            lineInfo.lineSymbolRate = winLineData.p_amount / (self.m_runSpinResultData:getBetValue())

            if lineInfo.iLineSymbolNum >= 5 then
                isFiveOfKind = true
            end

            self.m_vecGetLineInfo[#self.m_vecGetLineInfo + 1] = lineInfo
        end
    end

    return isFiveOfKind
end

--spin结果
function CodeGameScreenSpookySnacksMachine:spinResultCallFun(param)
    CodeGameScreenSpookySnacksMachine.super.spinResultCallFun(self, param)

    if param[1] == true then
        if param[2] and param[2].result then
            local spinData = param[2]
            if spinData.action == "SPIN" then
                if self:getCurrSpinMode() == RESPIN_MODE then

                    if spinData.result.respin and spinData.result.respin.extra and spinData.result.respin.extra.reels1 then
                        local resultDatas = spinData.result.respin.extra

                        for miniIndex = 1, self.m_MiNiTotalNum do

                            local mninReel = self.m_miniMachine[miniIndex]
                            local dataName = "reels".. miniIndex

                            local miniReelsResultDatas = resultDatas[dataName]
                            spinData.result.reels = miniReelsResultDatas.reels
                            spinData.result.storedIcons = miniReelsResultDatas.storedIcons
                            spinData.result.pos = miniReelsResultDatas.pos

                            mninReel:netWorkCallFun(spinData.result)
                        end
                    
                    end
                end

            end
        end
    end
end

--[[
    检测是否所有respinView都已经停止滚动
]]
function CodeGameScreenSpookySnacksMachine:isAllRespinViewDown()
    for index = 1,#self.m_miniMachine do
        if not self.m_miniMachine[index]:isRespinViewDown() then
            return false
        end
    end
    return true
end

---判断结算
function CodeGameScreenSpookySnacksMachine:reSpinSelfReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount}
    self:upDateRespinNums()

    --停轮之后 关闭快滚音效
    -- if self.m_respinQuickRunSound then
    --     gLobalSoundManager:stopAudio(self.m_respinQuickRunSound)
    --     self.m_respinQuickRunSound = nil
    -- end
    
    if self.m_runSpinResultData.p_reSpinCurCount ~= 0 then
        for miniIndex = 1, self.m_MiNiTotalNum do
            self.m_miniMachine[miniIndex].m_respinView:runQuickEffect()
        end
    end

    self:setGameSpinStage(STOP_RUN)
    
    self.m_respinQiPanJimanPlaySound = true

    self:showReSpinMiNiBanzi(true, function()
        -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        -- 每次 滚动需要判断 是否有集满的棋盘
        local needPlayNum = 0
        if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.fullReel then
            local isSound = false
            for miniIndex = 1, self.m_MiNiTotalNum do
                if self.m_runSpinResultData.p_rsExtraData.fullReel[miniIndex] == 1 then
                    self:showMiniQiPanEffect(miniIndex,isSound)
                    if not self.m_miniMachine[miniIndex].qiPanEffect:isVisible() then
                        isSound = true
                    end
                    local isNeedPlay = true
                    if isNeedPlay then
                        needPlayNum = needPlayNum + 1
                    end
                end 
            end
        end
        local delayTime = 0
        if needPlayNum > 0 then
            delayTime = 60/60
        end
        self:delayCallBack(delayTime,function()
            self:updateQuestUI()
            if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                
                self:delayCallBack(0.4,function()
                    self:respinOverJieSuan()
                end)

                return
            end

            self:clearBonus3SymbolInfo()
            self:reSpinSelfReelDownNext()
        end)

    end)
end

-- respin结束之后 开始结算
function CodeGameScreenSpookySnacksMachine:respinOverJieSuan( )
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    for miniIndex = 1, self.m_MiNiTotalNum do
        self.m_miniMachine[miniIndex].m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
    end

    --quest
    self:updateQuestBonusRespinEffectData()

    for miniIndex = 1, self.m_MiNiTotalNum do
        --结束
        self.m_miniMachine[miniIndex]:reSpinEndAction()
        self.m_miniMachine[miniIndex].m_lightEffectNode:removeAllChildren(true)
        self.m_miniMachine[miniIndex].m_respinView.m_single_lights = {}
    end
    --结束
    self:reSpinEndAction()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
    self.m_isWaitingNetworkData = false
end

-- 落地之后 刷新次数respin
function CodeGameScreenSpookySnacksMachine:upDateRespinNums( )
    if self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        if self.m_runSpinResultData.p_reSpinCurCount >= 3 then
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)
        else
            self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,false)
            if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
                -- self.m_RespinBarView:showReSpinBerUI()
            end 
        end
    end
end
--[[
    每次respin 滚动完 下次spin的流程
]]
function CodeGameScreenSpookySnacksMachine:reSpinSelfReelDownNext()
    for miniIndex = 1, self.m_MiNiTotalNum do
        self.m_miniMachine[miniIndex].m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    end

    self.m_bonus3List = {}
    self.m_bonus3MiniMachineList = {}
    self.m_vecExpressSound = {false, false, false, false, false}
    self.m_respinReelStopSound = {false, false, false, false, false}
    self.m_quickBuling = true
    --继续
    for miniIndex = 1, self.m_MiNiTotalNum do
        self.m_miniMachine[miniIndex]:runNextReSpinReel()
    end

    -- 播放respin 快滚音效
    for miniIndex = 1, self.m_MiNiTotalNum do
        local qucikRespinNode = self.m_miniMachine[miniIndex].m_respinView.m_qucikRespinNode
        if qucikRespinNode and #qucikRespinNode > 0 then
            if not self.m_respinQuickRunSound then
                -- self.m_respinQuickRunSound = gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_SpookySnacks_respin_quick_run)
            end
        end
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
end

--结束移除小块调用结算特效
function CodeGameScreenSpookySnacksMachine:reSpinEndAction()    

    self:getReSpinEndWheelChip()

    -- self.m_playWheelIndex = 1 --依次转动wheel 的标识

    self:reSpinMiniWheelEffect(1,function()
        -- 棋盘有集满 先结算 集满
        self:showMiniJiManEffect(function()
            -- 播放全部bonus的 触发动效在 一个一个收集
            self:playBonusTriggerEffect(function()
                self.m_maxIndexMini = 3 --结算顺序为 从上到下 三个小转盘 
                self:playChipCollectAnim(self.m_maxIndexMini)
            end)
        end)
    end)
    
end

--防止钥匙清理不干净 临时加的
function CodeGameScreenSpookySnacksMachine:clearBonus3SymbolInfo( )
    local jieSuoRow = self.m_runSpinResultData.p_rsExtraData.Row 
    for miniReelIndex = 1, 3 do
        for banziIndex=1, 3 do
            local banziRowIndex = (miniReelIndex-1)*3 + banziIndex
            if banziRowIndex <= jieSuoRow then
                local dangBanNode = self.m_miniMachine[miniReelIndex]["banzi"..banziIndex]
                if dangBanNode:isVisible() then
                    dangBanNode:setVisible(false)
                    for i,_chipBonus3Node in ipairs(self.m_bonus3List) do
                        -- 钥匙飞走之后 bonus3上显示金币数量
                        self:showBonus3Coins(_chipBonus3Node)
                    end
                end
            end
        end
    end
end

--结算之前 如果有轮盘 先把wheel查找出来
function CodeGameScreenSpookySnacksMachine:getReSpinEndWheelChip()
    self.m_wheelChipList = {}
    for miniIndex = self.m_MiNiTotalNum, 1, -1 do
        for chipNodeIndex = 1, #self.m_miniMachine[miniIndex].m_chipList do
            local chipNode = self.m_miniMachine[miniIndex].m_chipList[chipNodeIndex]
            if chipNode.p_symbolType == self.SYMBOL_BONUS2 then
                local score = self.m_miniMachine[miniIndex]:getReSpinSymbolScore(self:getPosReelIdx(chipNode.p_rowIndex ,chipNode.p_cloumnIndex))
                chipNode.m_score = score
                table.insert(self.m_wheelChipList, chipNode)
            end
        end
    end
end

--结算之前 如果有轮盘 轮盘需要转动
function CodeGameScreenSpookySnacksMachine:reSpinMiniWheelEffect(playWheelIndex,_func)
    if playWheelIndex > #self.m_wheelChipList then
        if _func then
            _func()
        end

        return 
    end

    local chipWheelNode = self.m_wheelChipList[playWheelIndex]
    local nJackpotType = 0
    if chipWheelNode.m_score == "grand" then
        nJackpotType = 1
    elseif chipWheelNode.m_score == "major" then
        nJackpotType = 2
    elseif chipWheelNode.m_score == "minor" then
        nJackpotType = 3
    elseif chipWheelNode.m_score == "mini" then
        nJackpotType = 4
    end

    self:flyReSpinWheel(chipWheelNode,function()
        self:showZhuanPanWheel(chipWheelNode, function ()

            self:delayCallBack(0.5,function()
                playWheelIndex = playWheelIndex + 1
                self:reSpinMiniWheelEffect(playWheelIndex,_func)   
            end)
             
        end,nJackpotType)
    end)
    
end

--[[
    wheel 出现之前的动画
]]
function CodeGameScreenSpookySnacksMachine:flyReSpinWheel(_startNode,_func)
    --创建一个假的小块播触发动画
    local tempSymbol = util_spineCreate("Socre_SpookySnacks_Bonus2", true, true)
    local pos = util_convertToNodeSpace(_startNode,self:findChild("Node_fly"))
    self:findChild("Node_fly"):addChild(tempSymbol)
    tempSymbol:setScale(0.75)
    tempSymbol:setPosition(pos)
    _startNode:setVisible(false)
    local time = _startNode:getAniamDurationByName("actionframe")
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_bonus1_trigger)
    util_spinePlay(tempSymbol,"actionframe")
    self:delayCallBack(time,function ()
        tempSymbol:setVisible(false)
        self:delayCallBack(0.1,function ()
            tempSymbol:removeFromParent()
        end)
        _startNode:setVisible(true)
        _startNode:runAnim("idleframe3",true)
        if type(_func) == "function" then
            _func()
        end
    end)
    
end

--结算用
function CodeGameScreenSpookySnacksMachine:showMiniQiPanTriggerEffect2(_miniMachineIndex)
    
    self.m_miniMachine[_miniMachineIndex]:getParent():setLocalZOrder(100 - _miniMachineIndex)

    if self.m_respinQiPanJimanPlaySound then
        self.m_respinQiPanJimanPlaySound = false
        -- gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_respin_qipan_jiman)
    end

    if self:checkJiManNum(true) > 1 then
        local effectNode = self.respinNewEffectList[_miniMachineIndex]
        if not tolua.isnull(effectNode) then
            effectNode:setVisible(true)
            util_spinePlay(effectNode,"actionframe2",false)
            util_spineEndCallFunc(effectNode,"actionframe2",function()
                effectNode:setVisible(false)
            end)
        end
    else
        self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine:setVisible(true)
        util_spinePlay(self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine,"actionframe2",false)
        util_spineEndCallFunc(self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine,"actionframe2",function()
            self.m_miniMachine[_miniMachineIndex].qiPanJiManSpine:setVisible(false)
        end)
    end


    self:delayCallBack(60/30,function()
        
        self.m_miniMachine[_miniMachineIndex]:getParent():setLocalZOrder(4 - _miniMachineIndex)
        -- if _func then
        --     _func()
        -- end
    end)

end

--[[
    结算bonus图标之前 有集满的棋盘需要先做动画 
]]
function CodeGameScreenSpookySnacksMachine:showMiniJiManEffect(_func)
    -- 集满的赢钱节点 飞的时候 用
    self.m_jiManWinCoinsNode = {}

    -- self.m_playJiManIndex = 1
    local playJiManIndex = 1
    if self.m_runSpinResultData and self.m_runSpinResultData.p_rsExtraData and self.m_runSpinResultData.p_rsExtraData.fullReel then
        --压黑层显示
        local isShowDark = false
        for miniIndex = self.m_MiNiTotalNum, 1, -1 do
            if self.m_runSpinResultData.p_rsExtraData.fullReel[miniIndex] == 1 then
                isShowDark = true
                break
            end
        end
        if isShowDark then
            self.respinDark:setVisible(true)
            util_spinePlay(self.respinDark,"dark",false)
            util_spineEndCallFunc(self.respinDark,"dark",function()
                self.respinDark:setVisible(false)
                
            end)
        end
        
        local isSound = false
        for miniIndex = self.m_MiNiTotalNum, 1, -1 do
            if self.m_runSpinResultData.p_rsExtraData.fullReel[miniIndex] == 1 then

                self.m_miniMachine[miniIndex].qiPanEffect:setVisible(false)
                
                self:showMiniQiPanTriggerEffect2(miniIndex)
                local coins = self.m_runSpinResultData.p_rsExtraData.fullCoins[miniIndex] or 0
                self.m_miniMachine[miniIndex].jiManEffect.m_coins = coins
                table.insert(self.m_jiManWinCoinsNode, self.m_miniMachine[miniIndex].jiManEffect)

                self.m_miniMachine[miniIndex].jiManEffect.winCoinNode:setVisible(true)
                self.m_miniMachine[miniIndex].jiManEffect.winCoinNode:findChild("m_lb_coins"):setString(util_formatCoins(coins,30))
                self:updateLabelSize({label=self.m_miniMachine[miniIndex].jiManEffect.winCoinNode:findChild("m_lb_coins"),sx=0.67,sy=0.67},569)
                -- self.m_miniMachine[miniIndex].jiManEffect.winCoinNode:runCsbAction("idle",true)
                if not isSound then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respinOver_smallView)
                end
                isSound = true
                self.m_miniMachine[miniIndex].jiManEffect:setVisible(true)
                self.m_miniMachine[miniIndex].jiManEffect:runCsbAction("start",false,function()

                    self.m_miniMachine[miniIndex].jiManEffect:runCsbAction("idle",true)
                end)
            end 
        end
    end

    if #self.m_jiManWinCoinsNode > 0 then
        self:delayCallBack(3,function()
            self.m_jiManWinCoinsNode[playJiManIndex]:runCsbAction("over",false)

            self:flyReSpinCollectWinCois(playJiManIndex,self.m_jiManWinCoinsNode[playJiManIndex].winCoinNode, self.m_jiManWinCoinsNode[playJiManIndex].m_coins, function()
                if _func then
                    _func()
                end
            end)
        end)
    else
        if _func then
            _func()
        end
    end

end

function CodeGameScreenSpookySnacksMachine:checkJiManNum(isOver)
    local num = 0
    if isOver then
        for miniIndex = self.m_MiNiTotalNum, 1, -1 do
            if self.m_runSpinResultData.p_rsExtraData.fullReel[miniIndex] == 1 then
                num = num + 1
            end 
        end
    else
        for miniIndex = self.m_MiNiTotalNum, 1, -1 do
            if self.m_runSpinResultData.p_rsExtraData.fullReel[miniIndex] == 1 and not self.m_miniMachine[miniIndex].qiPanEffect:isVisible() then
                num = num + 1
            end 
        end
    end
    
    return num
end

--[[
    赢钱先飞到 底部赢钱区
]]
function CodeGameScreenSpookySnacksMachine:flyReSpinCollectWinCois(playJiManIndex,_startNode, _coins, _func) 
    _startNode:setVisible(false)
    local flyNode = util_createAnimation("SpookySnacks_respin_prize_coins.csb")

    flyNode:findChild("m_lb_coins"):setString(util_formatCoins(_coins,30))
    self:updateLabelSize({label=flyNode:findChild("m_lb_coins"),sx=0.67,sy=0.67},569)

    local startPos = util_convertToNodeSpace(_startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(self.m_bottomUI.m_normalWinLabel, self.m_effectNode)

    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    -- flyNode:runCsbAction("fly",false)

    -- 飞到底部 
    local seq = cc.Sequence:create({
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respinOver_smallView_move)
        end),
        cc.EaseQuarticActionIn:create(cc.MoveTo:create(30/60,endPos)),
        cc.CallFunc:create(function()

            self.m_lightScore = self.m_lightScore + _coins
            self.m_bottomUI.m_changeLabJumpTime = 0.2
            self:playBottomLight(_coins, function()
                playJiManIndex = playJiManIndex + 1
                if playJiManIndex > #self.m_jiManWinCoinsNode then
                    if _func then
                        _func()
                    end
                else
                    self.m_jiManWinCoinsNode[playJiManIndex]:runCsbAction("over",false)

                    self:flyReSpinCollectWinCois(playJiManIndex,self.m_jiManWinCoinsNode[playJiManIndex].winCoinNode, self.m_jiManWinCoinsNode[playJiManIndex].m_coins, _func)
                end
            end,true)
        end),
        cc.CallFunc:create(function()
            flyNode:removeFromParent()
        end),
    })

    flyNode:runAction(seq)
end

--[[
    结算bonus之前 播放 触发动效
]]
function CodeGameScreenSpookySnacksMachine:playBonusTriggerEffect(_func)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_AllBonus_show)
    for miniIndex = 1, self.m_MiNiTotalNum do
        if self.m_miniMachine[miniIndex].m_chipList and #self.m_miniMachine[miniIndex].m_chipList > 0 then
            for chipNodeIndex = 1, #self.m_miniMachine[miniIndex].m_chipList do
                local chipNode = self.m_miniMachine[miniIndex].m_chipList[chipNodeIndex]
                --播放动画时，切换层级
                local oldParent = chipNode:getParent()
                local oldPosition = cc.p(chipNode:getPosition())
                self.m_miniMachine[miniIndex]:changeActNodeZOrder(chipNode,oldParent,oldPosition,true)
                chipNode:runAnim("actionframe2",false,function ()
                    self.m_miniMachine[miniIndex]:changeActNodeZOrder(chipNode,oldParent,oldPosition,false)
                    if chipNode.p_symbolType == self.SYMBOL_BONUS2 then
                        chipNode:runAnim("idleframe4",true)
                    else
                        chipNode:runAnim("idle",true)
                    end
                end)
            end
        end
    end

    self:delayCallBack(60/30,function()
        if _func then
            _func()
        end
    end)
end

--[[
    结算所有的小块
]]
function CodeGameScreenSpookySnacksMachine:playChipCollectAnim(_indexMini, _isCollectEnd)

    if _isCollectEnd then
        -- 此处跳出迭代
        self:playLightEffectEnd(_indexMini)
        
        return 
    end

    if self.m_miniMachine[_indexMini].m_playAnimIndex > #self.m_miniMachine[_indexMini].m_chipList then
        self.m_maxIndexMini = self.m_maxIndexMini - 1

        -- mini计数小于1 说明结算完毕
        if self.m_maxIndexMini < 1 then
            self:playChipCollectAnim(self.m_maxIndexMini,true)
        else
            self:playChipCollectAnim(self.m_maxIndexMini)
        end
        
        return
    end

    local chipNode = self.m_miniMachine[_indexMini].m_chipList[self.m_miniMachine[_indexMini].m_playAnimIndex]

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    -- 根据网络数据获得当前固定小块的分数
    local score = self.m_miniMachine[_indexMini]:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    
    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    --globalData.slotRunData:getCurTotalBet()
    local lineBet = 1
    local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "grand" then
            --self:BaseMania_getJackpotScore(1)
            jackpotScore = allJackpotCoins["Grand"] or 0
            addScore = jackpotScore + addScore
            nJackpotType = 1
        elseif score == "major" then
            --self:BaseMania_getJackpotScore(2)
            jackpotScore = allJackpotCoins["Major"] or 0
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif score == "minor" then
            --self:BaseMania_getJackpotScore(3)
            jackpotScore =  allJackpotCoins["Minor"] or 0
            addScore =jackpotScore + addScore                  ---self:BaseMania_getJackpotScore(3)
            nJackpotType = 3
        elseif score == "mini" then
            --self:BaseMania_getJackpotScore(4)  
            jackpotScore = allJackpotCoins["Mini"] or 0
            addScore =  jackpotScore + addScore                      ---self:BaseMania_getJackpotScore(4)
            nJackpotType = 4
        end
    end

    -- 如果是钥匙 服务器没给金币数据 自己写成默认1倍
    if chipNode.p_symbolType == self.SYMBOL_BONUS3 then
        if score == nil then
            addScore = 1 * lineBet
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    -- gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus_collect)

    -- gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BlackFriday_bonus_collect_fankui)

    if nJackpotType == 0 then
        --播放动画时，切换层级
        local oldParent = chipNode:getParent()
        local oldPosition = cc.p(chipNode:getPosition())
        -- self.m_miniMachine[_indexMini].m_respinView:changeActNodeZOrder(chipNode,true)
        self.m_miniMachine[_indexMini]:changeActNodeZOrder(chipNode,oldParent,oldPosition,true)
        self:flyCollectCoin(chipNode, function()
            
        end, addScore)
        self:delayCallBack(0.4,function ()
            self.m_miniMachine[_indexMini].m_playAnimIndex = self.m_miniMachine[_indexMini].m_playAnimIndex + 1
            self.m_miniMachine[_indexMini]:changeActNodeZOrder(chipNode,oldParent,oldPosition,false)
            self:playChipCollectAnim(_indexMini) 
        end)
    else
        --播放动画时，切换层级
        local oldParent = chipNode:getParent()
        local oldPosition = cc.p(chipNode:getPosition())
        self.m_miniMachine[_indexMini]:changeActNodeZOrder(chipNode,oldParent,oldPosition,true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_jackpotBonus_trigger)
        chipNode:runAnim("actionframe2",false,function()
            self.m_respinjackPotBarView:showWinningEffect(nJackpotType)
            self:showRespinJackpotWin(nJackpotType, jackpotScore, function()
                self.m_respinjackPotBarView:hideWinningEffect()
                self:flyCollectCoin(nil,function()
                    
                end,jackpotScore)
                self:delayCallBack(0.4,function ()
                    self.m_miniMachine[_indexMini].m_playAnimIndex = self.m_miniMachine[_indexMini].m_playAnimIndex + 1
                    -- self.m_miniMachine[_indexMini].m_respinView:changeActNodeZOrder(chipNode,false)
                    self.m_miniMachine[_indexMini]:changeActNodeZOrder(chipNode,oldParent,oldPosition,false)
                    self:playChipCollectAnim(_indexMini)
                end)
            end)
        end)
    end
end



-- 收集金币
function CodeGameScreenSpookySnacksMachine:flyCollectCoin(_startNode, _func, _addScore)
    local actName = "actionframe2"
    local waitTime = 20/30
    
    if _startNode then
        if _startNode.p_symbolType == self.SYMBOL_BONUS1 then
            actName = "actionframe3"
            waitTime = _startNode:getAniamDurationByName(actName) or 20/30
        end
        _startNode:runAnim(actName,false)
        if _startNode then
            -- if not tolua.isnull(_startNode.m_csbNode) then
            --     _startNode.m_csbNode:runCsbAction("actionframe")
            -- end
            -- local symbolType = _startNode.p_symbolType
            -- if symbolType then
                local aniNode = _startNode:checkLoadCCbNode()     
                local spine = aniNode.m_spineNode
                if spine and not tolua.isnull(spine.m_bindCsbNode) then

                    spine.m_bindCsbNode:runCsbAction("actionframe")
                end
            -- end

            
        end
        self:showCollectBonusCoins(_addScore)
        self.m_bottomUI:playCoinWinEffectUI()
        self.m_bottomUI.m_changeLabJumpTime = waitTime
        
        self:setLastWinCoin(self.m_lightScore)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_EveryBonus_show)
        local params = {_addScore, false, true}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    else
        self.m_bottomUI.m_changeLabJumpTime = waitTime
        self:setLastWinCoin(self.m_lightScore)

        local params = {_addScore, false, true}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
    end

    

    self:delayCallBack(waitTime,function()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenSpookySnacksMachine:showCollectBonusCoins(_addScore)
    -- if self.m_coinbonusUpdateAction then
    --     self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
    --     self.m_coinbonusUpdateAction = nil
    -- end
    local winLabCsb = util_createAnimation("SpookySnacks_coins.csb")
    self.m_bottomUI.coinWinNode:addChild(winLabCsb)
    winLabCsb:findChild("m_lb_coins"):setString(string.format("+%s", util_getFromatMoneyStr(_addScore)) )
    winLabCsb:setScale(0.65)
    winLabCsb:setPositionY(15)
    winLabCsb:runCsbAction("actionframe",false,function()
        if not tolua.isnull(winLabCsb) then
            -- if self.m_coinbonusUpdateAction then
            --     self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
            --     self.m_coinbonusUpdateAction = nil
            -- end
            winLabCsb:removeFromParent()
        end
    end)

    
    

    -- local showTime = 15/60
    -- local coinRiseNum = _addScore / (showTime * 60)  -- 每秒60帧

    -- local str   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    -- coinRiseNum = tonumber(str)
    -- coinRiseNum = math.ceil(coinRiseNum)
    -- local node = winLabCsb:findChild("m_lb_coins")
    -- local m_currShowCoins = 0

    -- self.m_coinbonusUpdateAction = schedule(self.m_coinbonus,function()
    --     m_currShowCoins = m_currShowCoins + coinRiseNum
        
    --     node:setString(string.format("+%s", util_getFromatMoneyStr(m_currShowCoins)) )
    --     if m_currShowCoins >= _addScore then
    --         if self.m_coinbonusUpdateAction then
    --             self.m_coinbonus:stopAction(self.m_coinbonusUpdateAction)
    --             self.m_coinbonusUpdateAction = nil
    --         end
    --     end
    -- end,1/60)
end

-- 结束respin收集
function CodeGameScreenSpookySnacksMachine:playLightEffectEnd(_indexMini)
    self:delayCallBack(0.5, function()
        -- 通知respin结束
        self:respinOver()
    end)
    
end

function CodeGameScreenSpookySnacksMachine:respinOver()
    
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    self:clearCurMusicBg() 
    self.isShowLineSound = false
    self:showRespinOverView()

    self:isNeedCloseDangBanTips()
end

function CodeGameScreenSpookySnacksMachine:showRespinOverView(effectData)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    local strCoins=util_formatCoins(self.m_serverWinCoins,30)
    local view=self:showReSpinOver(strCoins,function()

        self:respinGuoChang(function()
            self.m_bottomUI.m_changeLabJumpTime = nil
            self.m_isReSpin = false
            self.peopleClick = true                 --角色是否可点击

            if self.m_bProduceSlots_InFreeSpin then
                self:changeUiForState(PublicConfig.uiState.free)
            else
                self:changeUiForState(PublicConfig.uiState.base)
            end

            self:changeShowJackpotBar(false)
            for miniIndex = 1, self.m_MiNiTotalNum do

                self.m_miniMachine[miniIndex]:setReelSlotsNodeVisible(true)
                self.m_miniMachine[miniIndex]:removeRespinNode()

                -- 每个小mini 轮盘上的 三个挡板
                for banziIndex=1,3 do
                    self.m_miniMachine[miniIndex]["banzi"..banziIndex]:setVisible(true)
                    util_spinePlay(self.m_miniMachine[miniIndex]["banzi"..banziIndex],"idle",true)
                    self.m_miniMachine[miniIndex]["banzi"..banziIndex].isPlayEffect = false
                end
                self.m_miniMachine[miniIndex].qiPanEffect:setVisible(false)

                self.m_miniMachine[miniIndex].jiManEffect:setVisible(false)

                self.m_miniMachine[miniIndex]:setVisible(false)

            end
    
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
    
        end,function()
            if self.m_bProduceSlots_InFreeSpin then
                self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins)
            end
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self.m_lightScore = 0
            self:resetMusicBg() 

            -- respin 玩法结束 判断是否 需要弹出jackpot tips
            -- self.m_jackpotBar:checkIsNeedOpenTips()
        end,false)
        
    end)
    local light = util_createAnimation("SpookySnacks/FreeSpinOver_glow.csb")
    view:findChild("xzg_tx"):addChild(light)
    util_setCascadeOpacityEnabledRescursion(view:findChild("xzg_tx"), true)
    util_setCascadeColorEnabledRescursion(view:findChild("xzg_tx"), true)
    light:runCsbAction("idleframe",true)
    -- gLobalSoundManager:playSound("WestRangerrSounds/music_WestRangerr_linghtning_over_win.mp3")
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},621)
end

function CodeGameScreenSpookySnacksMachine:showReSpinOver(_coins, _func, _index)

    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(_coins, 30)
    local view = nil
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respinOver_start)
    view = self:showDialog("ReSpinOver", ownerlist, _func, nil, _index)
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_SpookySnacks_respinOver_over)
    end)

    return view
    --也可以这样写 self:showDialog("ReSpinOver",ownerlist,func)
end

function CodeGameScreenSpookySnacksMachine:getSkinName(jackpotType)
    local type = string.lower(jackpotType)
    if type == "grand" then
        return "Grand"
    elseif type == "major" then
        return "Major"
    elseif type == "minor" then
        return "Minor"
    else
        return "Mini"
    end
end

-- 显示转盘
function CodeGameScreenSpookySnacksMachine:showZhuanPanWheel(_chipNode, _func, _nJackpotType)
    local startPos = util_convertToNodeSpace(_chipNode,self:findChild("root"))
    -- 转盘 转完之后 棋盘上的小块 显示成带jackpot的
    local showWheelNodeJackpot = function()
        local symbol_node = _chipNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        local skinName = self:getSkinName(_chipNode.m_score)
        spineNode:setSkin(skinName)
        _chipNode:runAnim("shouji",false,function ()
            _chipNode:runAnim("idleframe4",true)
        end)
        
    end

    --显示转盘
    local view = util_createView("CodeSpookySnacksSrc.SpookySnacksWheel.SpookySnacksWheelView",{machine = self,JackpotType = _nJackpotType,callBack = function()
        if _func then
            _func()
        end
    end, endPos = startPos, changeJackpotCallBack = showWheelNodeJackpot})

    self:findChild("root"):addChild(view, 100)
end

-- 判断哪个小轮盘 没有集满
function CodeGameScreenSpookySnacksMachine:getIndexReelMiniNoJiMan( )
    for miniIndex = 1, self.m_MiNiTotalNum do
        local reelData = self.m_runSpinResultData.p_rsExtraData["reels"..miniIndex]
        for iCol = 1, self.m_iReelColumnNum  do
            for iRow = 1, self.m_iReelRowNum do
                if reelData.reels[iRow][iCol] == self.SYMBOL_SCORE_BLANK then
                    self.m_IndexReelMini = miniIndex
                    return
                end
            end
        end
    end
end

function CodeGameScreenSpookySnacksMachine:changeReelsOtherSymbolType2(col)

    local p_rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}
    local newsingle = p_rsExtraData.newsingle or {}

    local newsingleForType = newsingle[col] or {}
    for i, type in ipairs(newsingleForType) do
            if type == 96 then
                return 96
            end
            if type == 95 then
                return 95
            end
    end
    return 94
end

function CodeGameScreenSpookySnacksMachine:changeReelsOtherSymbolType()

    local p_rsExtraData = self.m_runSpinResultData.p_rsExtraData or {}

    local newsingle = p_rsExtraData.newsingle or {}
    for i, _list in ipairs(newsingle) do
        for j, type in ipairs(_list) do
            if type == 96 then
                return 96
            end
            if type == 95 then
                return 95
            end
        end
    end
    return 94
end
 
 -----------------------------respin相关接口  end------------------------------------------------ 


 function CodeGameScreenSpookySnacksMachine:getSoundPathForScatterNum()
    local path = nil
    if self.scatterNum == 1 then
        path = PublicConfig.SoundConfig.sound_SpookySnacks_scatter_buling_1
    elseif self.scatterNum == 2 then
        path = PublicConfig.SoundConfig.sound_SpookySnacks_scatter_buling_2
    else
        path = PublicConfig.SoundConfig.sound_SpookySnacks_scatter_buling_3
    end
    return path
end

function CodeGameScreenSpookySnacksMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            local iCol = _slotNode.p_cloumnIndex
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self.scatterNum = self.scatterNum + 1
                local soundPath = self:getSoundPathForScatterNum()
                if soundPath then
                    self:playBulingSymbolSounds(iCol, soundPath, symbolType)
                end
            else
                if symbolCfg then
                    
                    local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                    if soundPath then
                        self:playBulingSymbolSounds(iCol, soundPath, nil)
                    end
                end
            end
            
        end
    end
end

function CodeGameScreenSpookySnacksMachine:util_getOneGameReelsTarSpPosForClip(index)
    local getNodePosByColAndRow = function(row, col)
        local clipLayerNode = nil
        if row == 1 then
            clipLayerNode = self:findChild("clipLayerNode_1")
        elseif row == 2 then
            clipLayerNode = self:findChild("clipLayerNode_2")
        else
            clipLayerNode = self:findChild("clipLayerNode_3")
        end
        local posX,posY = nil,nil
        posX = clipLayerNode:getPositionX()
        posY = clipLayerNode:getPositionY()

        return cc.p(posX, posY)
    end

    local fixPos = self:getRowAndColByPos(index)
    local targSpPos = getNodePosByColAndRow(fixPos.iX, fixPos.iY)

    return targSpPos
end



function CodeGameScreenSpookySnacksMachine:setScatterSymbolForFiveCol(_slotNode,speedActionTable)

    --将不需要走底层提层的scatter小块提层
    --不能直接使用提层后的坐标不然没法回弹了
    local curPos = util_convertToNodeSpace(_slotNode, self:findChild("clipLayer"))

    local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
    local pos = self:util_getOneGameReelsTarSpPosForClip(index)

    local showOrder = self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    _slotNode.m_showOrder = showOrder
    _slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    _slotNode:removeSelf(false)
    self:findChild("clipLayer"):addChild(_slotNode, showOrder, _slotNode:getTag())
    
    if self:getGameSpinStage() == QUICK_RUN then
        _slotNode:setPosition(cc.p(pos.x, pos.y - 35))
    else
        _slotNode:setPosition(cc.p(pos.x, pos.y))
    end

    --回弹
    local newSpeedActionTable = {}
    
    for i = 1, #speedActionTable do
        if i == #speedActionTable then
            -- 最后一个动作回弹动作用了 moveTo 不能通用，需要替换为信号自身的 移动动作,保证回弹后回到指定位置
            local resTime = self.m_configData.p_reelResTime
            local index = self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex)
            local tarSpPos = self:util_getOneGameReelsTarSpPosForClip(index)
            newSpeedActionTable[i] = cc.MoveTo:create(resTime, tarSpPos)
        else
            newSpeedActionTable[i] = speedActionTable[i]
        end
    end

    local actSequenceClone = cc.Sequence:create(newSpeedActionTable):clone()
    _slotNode:runAction(actSequenceClone)

end

--将特殊处理的scatter图标放回原来的层上
function CodeGameScreenSpookySnacksMachine:checkChangeBaseParentForScatter()
    -- 处理特殊信号
    local childs = self:findChild("clipLayer"):getChildren()
    for k,_node in pairs(childs) do
        if _node.resetReelStatus ~= nil then
            _node:resetReelStatus()
        end
        if _node.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            --将该节点放在 self.m_clipParent
            local curPos = util_convertToNodeSpace(_node, self.m_clipParent)
            -- util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
            util_changeNodeParent(self.m_clipParent,_node,self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_SCATTER))
            _node:setPosition(curPos)
        end
    end
end

function CodeGameScreenSpookySnacksMachine:clearClipLayer()
    local childs = self:findChild("clipLayer"):getChildren()
    for k,_node in pairs(childs) do
        if not tolua.isnull(_node) then
            _node:removeFromParent()
        end
    end
end

--修改裁切区域
function CodeGameScreenSpookySnacksMachine:changeClipRegion()
    -- for i = 1, self.m_iReelColumnNum, 1 do
    --     local columnData = self.m_reelColDatas[i]
    --     columnData.p_slotColumnHeight = self.m_SlotNodeH * self.m_iReelRowNum
    --     columnData:updateShowColCount(self.m_iReelRowNum)
    --     self.m_fReelHeigth = self.m_SlotNodeH * self.m_iReelRowNum
    -- end

    local rect = self.m_onceClipNode:getClippingRegion()
    --width = 848
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x,
            y = rect.y,
            width = 780,
            height = rect.height
        }
    )
end

function CodeGameScreenSpookySnacksMachine:requestSpinResult()
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
    self.m_iBetLevel = self.m_betLevel or 1
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and 
        self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= REWAED_FREE_SPIN_MODE and
            not self:checkSpecialSpin(  ) then

                self.m_topUI:updataPiggy(betCoin)
                isFreeSpin = false
    end
    
    self:updateJackpotList()
    
    self:setSpecialSpinStates(false )

    -- 拼接 collect 数据， jackpot 数据
    local messageData = {
        msg = MessageDataType.MSG_SPIN_PROGRESS,
        data = self.m_collectDataList,
        jackpot = self.m_jackpotList,
        betLevel = self.m_iBetLevel
    }
    local operaId = httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenSpookySnacksMachine:createLizi()
    local lizi = util_createAnimation("SpookySnacks_base_smallcoins_lizi.csb")
    self.m_effectNode:addChild(lizi,-1)
    lizi:setVisible(false)
    table.insert( self.m_baseLiziPool, lizi )
    return lizi
end

function CodeGameScreenSpookySnacksMachine:getLizi()
    if table_length(self.m_baseLiziPool) <= 0 then
        return self:createLizi()
    else
        local lizi = self.m_baseLiziPool[1]
        table.remove( self.m_baseLiziPool,1)
        return lizi
    end
end

function CodeGameScreenSpookySnacksMachine:pushBackLizi(_lizi)
    table.insert( self.m_baseLiziPool, _lizi )
end


return CodeGameScreenSpookySnacksMachine