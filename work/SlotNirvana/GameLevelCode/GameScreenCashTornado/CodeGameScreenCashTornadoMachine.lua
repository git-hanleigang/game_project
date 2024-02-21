---
-- island li
-- 2019年1月26日
-- CodeGameScreenCashTornadoMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "CashTornadoPublicConfig"
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local CodeGameScreenCashTornadoMachine = class("CodeGameScreenCashTornadoMachine", BaseReelMachine)

CodeGameScreenCashTornadoMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
-- CodeGameScreenCashTornadoMachine.SYMBOL_BONUS_BG_1 = 100
-- CodeGameScreenCashTornadoMachine.SYMBOL_BONUS_BG_2 = 101

CodeGameScreenCashTornadoMachine.SYMBOL_SCORE_BONUS1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3      --第五列锤子
CodeGameScreenCashTornadoMachine.SYMBOL_SCORE_BONUS2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1      --猪bonus（钱）
CodeGameScreenCashTornadoMachine.SYMBOL_SCORE_BONUS3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5      --猪bonus（jackpot）
CodeGameScreenCashTornadoMachine.SYMBOL_SCORE_BONUS4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4      --有龙卷风bonus
CodeGameScreenCashTornadoMachine.SYMBOL_SCORE_BONUS5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2      --第一列锤子


-- 自定义动画的标识
CodeGameScreenCashTornadoMachine.PICK_GAME_EFFECT = GameEffect.EFFECT_LINE_FRAME + 3
CodeGameScreenCashTornadoMachine.POWER_STRIKE_EFFECT = GameEffect.EFFECT_LINE_FRAME + 2
CodeGameScreenCashTornadoMachine.ENTER_SPECIAL_BASE_GAME_EFFECT = GameEffect.EFFECT_BIGWIN + 1  
CodeGameScreenCashTornadoMachine.CLOSE_SPECIAL_BASE_GAME_EFFECT = GameEffect.EFFECT_BIGWIN + 2


-- 构造函数
function CodeGameScreenCashTornadoMachine:ctor()
    CodeGameScreenCashTornadoMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeCashTornadoSrc.CashTornadoSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("CashTornadoLongRunControl",self) 


    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    --大赢光效
    self.m_isAddBigWinLightEffect = true

    self.yuGaoActList = {}

    self.isSpecialBase = false

    self.isPickGame = false

    self.isInitReelSymbol = false

    self.power_Strike_state = 1

    self.specialBaseData = {}

    self.isInGameEffect = false         --是否在自定义effect中

    self.isRunSpin = false

    self.isOverSpecialBase = false      --客户端倒计时是否结束(若在自定义玩法中，玩法结束时发消息；反之直接发消息)

    self.m_scatterCount = 0 --scatter数量

    self.jueSeIndex = 1

    self.jueSeIndexForFree = 1

    self.initSymbolIndex = 1

    self.isShowFree = false         --触发时无法进行bonusSpecial交互，所以自定义一个，收到0 1时改完true

    self.countDownshow = false

    self.specialFeng = nil

    self.isAddEnterBase = false

    self.powerStrikeCoins = 0

    self.isQuickStopSound = true
    --init
    self:initGame()
end

function CodeGameScreenCashTornadoMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("CashTornadoConfig.csv", "LevelCashTornadoConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCashTornadoMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CashTornado"  
end

function CodeGameScreenCashTornadoMachine:getReelNode()
    return "CodeCashTornadoSrc.CashTornadoReelNode"
end


function CodeGameScreenCashTornadoMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)
    --特效层2
    self.m_effectNode2 = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode2,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    -- self.m_effectNode2:setScale(self.m_machineRootScale)

    self.m_JveSeNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_JveSeNode)

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_bg = util_spineCreate("GameScreenCashTornadoBg", true, true)
    self.m_gameBg:findChild("Node_1"):addChild(self.m_bg)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self:initJackPotBarView() 

    --pick界面
    self.m_pickGameView = util_createView("CodeCashTornadoSrc.CashTornadoPickGame",{machine = self})
    self:findChild("Node_pick"):addChild(self.m_pickGameView)
    self.m_pickGameView:setVisible(false)

    --倒计时
    self.countDown = util_createView("CodeCashTornadoSrc.CashTornadoCountDownView",{machine = self})
    self:findChild("Node_daojishi"):addChild(self.countDown)
    self.countDown:setVisible(false)

    self.darkLayer = util_createAnimation("CashTornado_dark.csb")
    self:findChild("Node_dark"):addChild(self.darkLayer)
    self.darkLayer:setVisible(false)

    self.wenan = util_createAnimation("CashTornado_Base_wenan.csb")
    self:findChild("Node_wenan"):addChild(self.wenan)
    self.wenan:runCsbAction("idle",true)
    self.wenan:setVisible(false)

    
    

    self:changeUiForState(PublicConfig.uiState.base)
    

    self:findChild("yaan"):setVisible(false)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "CashTornado_totalwin.csb")

    self.fiveColKuang = util_createAnimation("CashTornado_kuang.csb")
    self:findChild("Node_fiveKuang"):addChild(self.fiveColKuang,1)
    self.fiveColKuang:setVisible(false)

    self.fiveColKuang2 = util_createAnimation("CashTornado_kuang.csb")
    self:findChild("Node_kuang2"):addChild(self.fiveColKuang2,1)
    self.fiveColKuang2:setVisible(false)

    self.noClickLayer = util_createAnimation("CashTornadoNoClickLayer.csb")
    self:addChild(self.noClickLayer, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER + 1)
    self.noClickLayer:setPosition(display.width * 0.5, display.height * 0.5)
    self.noClickLayer:setVisible(false)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenCashTornadoMachine:initSpineUI()
    self.jvese = util_spineCreate("CashTornado_juese", true, true)
    self:findChild("Node_juese"):addChild(self.jvese)
    self:showJveSeIdleAct(false)

    self.jvese2 = util_spineCreate("CashTornado_base_feng", true, true)
    self:findChild("Node_jvese2"):addChild(self.jvese2)
    self.jvese2:setVisible(false)

    self.fiveColEffect = util_spineCreate("CashTornado_Bonus4_tx", true, true)
    self:findChild("Node_fiveKuang2"):addChild(self.fiveColEffect)
    self.fiveColEffect:setVisible(false)

    self.tishi = util_spineCreate("CashTornado_Pick_tishi", true, true)
    self:findChild("Node_tishi"):addChild(self.tishi)
    self.tishi:setVisible(false)

end


function CodeGameScreenCashTornadoMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_enter_game_music)
    end)
end

function CodeGameScreenCashTornadoMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCashTornadoMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    --Free玩法同步次数
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == 1 then
        
    else
        if not self.m_bProduceSlots_InFreeSpin then
            if self.isSpecialBase then
                self:updateSpecialTimeForInfo()
                self:updataSpecialBaseTime()
                self:changeUiForState(PublicConfig.uiState.base2)
            else
                self:updataSpecialBaseTime2()
                self:changeUiForState(PublicConfig.uiState.base)
            end   
        end 
    end
    -- if self.isSpecialBase then
    --     self:updateSpecialTimeForInfo()
    --     self:updataSpecialBaseTime()
    --     self:changeUiForState(PublicConfig.uiState.base2)
    -- else
    --     self:updataSpecialBaseTime2()
    --     self:changeUiForState(PublicConfig.uiState.base)
    -- end
    -- if self.m_bProduceSlots_InFreeSpin then
    --     self:changeUiForState(PublicConfig.uiState.free)
    -- end 
end

function CodeGameScreenCashTornadoMachine:addObservers()
    CodeGameScreenCashTornadoMachine.super.addObservers(self)
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
        else
            if self.isSpecialBase then
                soundName = PublicConfig.SoundConfig["sound_specialBase_winLine_"..soundIndex] 
            end
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenCashTornadoMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCashTornadoMachine.super.onExit(self)      -- 必须调用不予许删除
    if globalMachineController.setIgnorePopCorEnabled then
        globalMachineController:setIgnorePopCorEnabled(false)
    end
    self:removeObservers()
    self:clearAllTempBonus()
    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCashTornadoMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS2 then
        return "Socre_CashTornado_Bonus2"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS5 then
        return "Socre_CashTornado_Bonus5"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS1 then
        return "Socre_CashTornado_Bonus1"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS4 then
        return "Socre_CashTornado_Bonus4"
    end
    if symbolType == self.SYMBOL_SCORE_BONUS3 then
        return "Socre_CashTornado_Bonus3"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCashTornadoMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCashTornadoMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_BONUS5,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCashTornadoMachine:MachineRule_initGame()
    --Free玩法同步次数
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == 1 then
        self.isShowFree = true
    else
        if self.m_bProduceSlots_InFreeSpin then
            self.isShowFree = true
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            self.m_baseFreeSpinBar:setVisible(true)
            self:changeUiForState(PublicConfig.uiState.free)
            self:showJveSeIdleAct(true)  
        end 
    end
    

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCashTornadoMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    self.isInitReelSymbol = false
    self.m_scatterCount = 0 --scatter数量
    self.isInGameEffect = true
    self.powerStrikeCoins = 0
    self.isQuickStopSound = true
    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenCashTornadoMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCashTornadoMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 

end

--[[
    滚轮停止
]]
function CodeGameScreenCashTornadoMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.isRunSpin = false
    CodeGameScreenCashTornadoMachine.super.slotReelDown(self)
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCashTornadoMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_left_win = selfData.bonus_left_win or 0
    local bonus_right_win = selfData.bonus_right_win or 0
    local pick_list = selfData.pick_list or {}
    if bonus_left_win > 0 or bonus_right_win > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.POWER_STRIKE_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.POWER_STRIKE_EFFECT -- 动画类型
    end
    if table_length(pick_list) > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.PICK_GAME_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.PICK_GAME_EFFECT -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCashTornadoMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.ENTER_SPECIAL_BASE_GAME_EFFECT then
        self:enterSpecialBase(function ()
            
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end 
    if effectData.p_selfEffectType == self.POWER_STRIKE_EFFECT then
        self:delayCallBack(0.1,function ()
            self:showPowerStrikeEffect(function ()
                -- 记得完成所有动画后调用这两行
                -- 作用：标识这个动画播放完结，继续播放下一个动画
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end
    if effectData.p_selfEffectType == self.PICK_GAME_EFFECT then
        --pickGame
        self:delayCallBack(0.5,function ()
            self:showPickEffectView(function ()
                self:delayCallBack(0.5,function ()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
                
            end)
        end)
    end 
    if effectData.p_selfEffectType == self.CLOSE_SPECIAL_BASE_GAME_EFFECT then
        self:closeSpecialBase(function ()
            
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end 
    return true
end



function CodeGameScreenCashTornadoMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenCashTornadoMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenCashTornadoMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_scatter_trigger)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_scatter_trigger)
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenCashTornadoMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenCashTornadoMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenCashTornadoMachine:checkRemoveBigMegaEffect()
    CodeGameScreenCashTornadoMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenCashTornadoMachine:getShowLineWaitTime()
    local time = CodeGameScreenCashTornadoMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenCashTornadoMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeCashTornadoSrc.CashTornadoFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_FGbar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenCashTornadoMachine:showFreeSpinStart(num,func1,func2,isAuto)
    self:clearCurMusicBg()
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_start_show)
    local view = nil
    if isAuto then
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func2, BaseDialog.AUTO_TYPE_NOMAL)
    else
        view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func2)
    end
    view:findChild("Panel_click"):setVisible(true)
    --光
    local light = util_spineCreate("FreeSpinStart_feng",true,true)
    view:findChild("Node_feng"):addChild(light)
    util_spinePlay(light,"start")
    util_spineEndCallFunc(light,"start",function()
        util_spinePlay(light,"idle",true)
        
    end)
    self:delayCallBack(1,function ()
        view:findChild("Panel_click"):setVisible(false)
        if func1 then
            func1()
        end
    end)
    

    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setBtnClickFunc(function()
        if not tolua.isnull(light) then
            util_spinePlay(light,"over")
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_start_hide)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_click) 
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_in_guoChange)
    end)
    return view
end

function CodeGameScreenCashTornadoMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("CashTornadoSounds/music_CashTornado_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function ()
                --先刷新一次次数框
                self.m_baseFreeSpinBar:initFreeSpinCount(self.m_iFreeSpinTimes)
                self.m_baseFreeSpinBar:setVisible(true)
                --切换free相关ui
                self:changeUiForState(PublicConfig.uiState.free)
                self:showJveSeIdleAct(true)
            end,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenCashTornadoMachine:showFreeSpinOver(coins, num, func)

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoinsLN(coins, 30)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_over_show)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func,BaseDialog.AUTO_TYPE_NOMAL)
    view:findChild("root"):setScale(self.m_machineRootScale)

    local light = util_createAnimation("CashTornado/JackpotWinView_g.csb")
    view:findChild("Node_g"):addChild(light)
    light:runCsbAction("idle",true)
    util_setCascadeOpacityEnabledRescursion(light, true)
    util_setCascadeColorEnabledRescursion(light, true)

    local jveSe = util_spineCreate("CashTornado_juese",true,true)
    view:findChild("Node_spine"):addChild(jveSe)
    util_spinePlay(jveSe,"idleframe_tanban2",true)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_over_hide)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_click)
    end)
    return view
end

--无赢钱
function CodeGameScreenCashTornadoMachine:showNoWinView(func)
    local view = self:showDialog("FeatureOver", nil, func,BaseDialog.AUTO_TYPE_ONLY)
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
end

function CodeGameScreenCashTornadoMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("CashTornadoSounds/music_CashTornado_over_fs.mp3")
    self:clearCurMusicBg()
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
    
    if freeSpinWinCoin > 0 then
        local strCoins = util_formatCoinsLN(freeSpinWinCoin,30)
        local view = self:showFreeSpinOver(
            strCoins, 
            self.m_runSpinResultData.p_freeSpinsTotalCount,
            function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_out_guoChang)
                self:showGuochang(function ()
                    self.m_baseFreeSpinBar:setVisible(false)
                    --刷新base ui
                    if self.isSpecialBase then
                        self:changeUiForState(PublicConfig.uiState.base2)
                    else
                        self:changeUiForState(PublicConfig.uiState.base)
                    end
                    self:showJveSeIdleAct(false)
                end,function ()
                    self:triggerFreeSpinOverCallFun()
                    self.isShowFree = false
                    if self.specialFeng then
                        gLobalSoundManager:stopAudio(self.specialFeng)
                        self.specialFeng = nil
                    end
                    if self.isSpecialBase then
                        self.specialFeng = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_special_feng,true)
                    end
                    --倒计时发消息
                    self.countDown:sendData(3)
                end)
                
            end
        )
        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=1,sy=1},661) 
    else
        local view = self:showNoWinView(function ()

            self:showGuochang(function ()
                --刷新base ui
                if self.isSpecialBase then
                    self:changeUiForState(PublicConfig.uiState.base2)
                else
                    self:changeUiForState(PublicConfig.uiState.base)
                end
                self:showJveSeIdleAct(false)
            end,function ()
                self:triggerFreeSpinOverCallFun()
                self.isShowFree = false
                --倒计时发消息
                self.countDown:sendData(3)
            end)
        end)
    end 
end

function CodeGameScreenCashTornadoMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    if self.specialFeng then
        gLobalSoundManager:stopAudio(self.specialFeng)
        self.specialFeng = nil
    end

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
    -- if scatterLineValue ~= nil then
        self:showJveSeFreeTrigger()
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

        self:delayCallBack(waitTime + 0.1,function()
            self:showFreeSpinView(effectData)
        end)
        -- scatterLineValue:clean()
        -- self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue

        self:playScatterTipMusicEffect()
    -- else
    --     self:showFreeSpinView(effectData)
    -- end
    
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end



function CodeGameScreenCashTornadoMachine:setReelRunInfo()
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    local longRunConfigs = {}
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["135"] ,["symbolType"] = {90}} )
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["15"] ,["symbolType"] = {94,95}} )
    -- table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["mustRun"] ,["symbolType"] = {200},["musRunInfos"] = {["startCol"] = 1,["endCol"]=3}})
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态    

    if self.b_gameTipFlag then
        return
    end
    for col=1,self.m_iReelColumnNum do
        local reelRunData = self.m_reelRunInfo[col]
        local runLen = reelRunData:getReelRunLen()

        local reelNode = self.m_baseReelNodes[col]
        reelNode:setRunLen(runLen)
    end
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenCashTornadoMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenCashTornadoMachine.super.MachineRule_ResetReelRunData(self)    
    -- if self:checkTriggerAddBonusLongRun() then
    --     self.m_isTrigerRespinRun = true
    --     for iCol = self.LONGRUN_COL_ADD_BONUS, self.m_iReelColumnNum do
    --         local reelRunInfo = self.m_reelRunInfo
    --         local reelRunData = self.m_reelRunInfo[iCol]
    --         local columnData = self.m_reelColDatas[iCol]

    --         reelRunData:setReelLongRun(true)
    --         reelRunData:setNextReelLongRun(true)

    --         local reelLongRunTime = 2.5
    --         if iCol > self.m_iReelColumnNum then
    --             reelLongRunTime = 2.5
    --             reelRunData:setReelLongRun(false)
    --             reelRunData:setNextReelLongRun(false)
    --         end

    --         local iRow = columnData.p_showGridCount
    --         local lastColLens = reelRunInfo[1]:getReelRunLen()
    --         if iCol ~= 1 then
    --             lastColLens = reelRunInfo[iCol - 1]:getReelRunLen()
    --             reelRunInfo[iCol - 1 ]:setNextReelLongRun(true)
    --         end

    --         local colHeight = columnData.p_slotColumnHeight
    --         local reelCount = (reelLongRunTime * self.m_configData.p_reelLongRunSpeed) / colHeight --self.m_fReelHeigth
    --         local runLen = lastColLens + math.floor( reelCount ) * columnData.p_showGridCount    --速度x时间 / 列高

    --         local preRunLen = reelRunData:getReelRunLen()
    --         reelRunData:setReelRunLen(runLen)

    --     end
    -- end
end

-- function CodeGameScreenCashTornadoMachine:checkTriggerAddBonusLongRun( )
--     local bonusNum = 0
--     for iCol = 1 ,(self.m_iReelColumnNum - 1) do
--         for iRow = 1,self.m_iReelRowNum do
--             local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
        
--             if self:isFixSymbol(symbolType) then
--                 bonusNum = bonusNum + 1  
--             end
--         end
        
--     end

--     if bonusNum >= self.BONUS_RUN_NUM then
--         self:setLongRunCol()
--         return true
--     end

--     return false
-- end

function CodeGameScreenCashTornadoMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)    
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenCashTornadoMachine:isPlayExpect(reelCol)
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

function CodeGameScreenCashTornadoMachine:getFeatureGameTipChance(_probability)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_left_win = selfData.bonus_left_win or 0
    local bonus_right_win = selfData.bonus_right_win or 0
    local p_winAmount = self.m_runSpinResultData.p_winAmount or 0
    if self.isSpecialBase then
        return false
    end

    if bonus_left_win > 0 or bonus_right_win > 0 then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local mul = p_winAmount/lineBet
        if mul >= 10 then
            -- 出现预告动画概率默认为30%
            local probability = 30
            if _probability then
                probability = _probability
            end
            local isNotice = (math.random(1, 100) <= probability) 
            return isNotice
        end
        
    end
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}
    

    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 then
        -- 出现预告动画概率默认为30%
        local probability = 30
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
function CodeGameScreenCashTornadoMachine:showFeatureGameTip(_func)
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
function CodeGameScreenCashTornadoMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = false
    --动效执行时间
    local aniTime = 0

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_left_win = selfData.bonus_left_win or 0
    local bonus_right_win = selfData.bonus_right_win or 0
    if bonus_left_win > 0 or bonus_right_win > 0 then
        aniTime = self:showPowerStrikeYuGao()
    else
        aniTime = self:showNomarlBaseToFreeYuGao()
    end

    self.b_gameTipFlag = true
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
    else
        if type(func) == "function" then
            func()
        end   
    end

     
end


--[[
        bonus断线重连
    ]]
function CodeGameScreenCashTornadoMachine:initFeatureInfo(spinData,featureData)
    --若服务器返回数据中没有status字段必须要求服务器加上,触发时可不返回
    -- if featureData.p_bonus and featureData.p_bonus.status == "OPEN" then
    --     self:addBonusEffect()
    -- end    
end

--[[
        添加bonus事件
    ]]
function CodeGameScreenCashTornadoMachine:addBonusEffect()
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})    
end

function CodeGameScreenCashTornadoMachine:scaleMainLayer()
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

--[[
    检测播放落地动画
]]
function CodeGameScreenCashTornadoMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                
                self:pushToSpecialSymbolList(symbolNode)
                
                --提层
                -- if self:checkSymbolBulingAnimPlay(symbolNode) then
                    if symbolCfg[1] then
                        local curPos = util_convertToNodeSpace(symbolNode, self.m_clipParent)
                        util_setSymbolToClipReel(self, symbolNode.p_cloumnIndex, symbolNode.p_rowIndex, symbolNode.p_symbolType, 0)
                        symbolNode:setPositionY(curPos.y)
    
                        --回弹
                        local actList = {}
                        local moveTime = self.m_configData.p_reelResTime
                        local dis = self.m_configData.p_reelResDis
                        local pos = cc.p(curPos)
                        local action1 = cc.EaseBackOut:create(cc.MoveTo:create(moveTime / 2, cc.p(pos.x,pos.y - dis)))
                        local action2 = cc.MoveTo:create(moveTime / 2,pos)
                        actList = {action1,action2}
                        symbolNode:runAction(cc.Sequence:create(actList))
                    end
                -- end
                

                if self:checkSymbolBulingAnimPlay(symbolNode) then
                    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS4 then
                        -- local pos = util_convertToNodeSpace(symbolNode,self:findChild("Node_fiveKuang2"))
                        -- self.fiveColEffect:setPosition(pos)
                        self.fiveColEffect:setVisible(true)
                        util_spinePlay(self.fiveColEffect,"buling1")
                        util_spineEndCallFunc(self.fiveColEffect,"buling1",function()
                            self.fiveColEffect:setVisible(false)
                        end)
                    end
                    --2.播落地动画
                    symbolNode:runAnim(
                        symbolCfg[2],
                        false,
                        function()
                            self:symbolBulingEndCallBack(symbolNode)
                        end
                    )
                    self:showBonusOrScatterBulingSound(colIndex,symbolNode)
                end
            end
            
        end
    end
end

--[[
    判断是否为bonus小块(需要在子类重写)
]]
function CodeGameScreenCashTornadoMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_SCORE_BONUS2 or 
            symbolType == self.SYMBOL_SCORE_BONUS3 then
        return true
    end
    
    return false
end

function CodeGameScreenCashTornadoMachine:getBonusState()
    local bonus15List = 0
    local bonus23List = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            if iCol ~= 1 or iCol ~= 5 then
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType then
                    if slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 or slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS5 then
                        bonus15List = bonus15List + 1
                    end
                    if self:isFixSymbol(slotNode.p_symbolType) then
                        bonus23List = bonus23List + 1
                    end
                end
            end
        end
    end
    if bonus15List > 0 then
        return 2
    end
    if bonus23List > 0 then
        return 1
    end
    return 0
end

function CodeGameScreenCashTornadoMachine:showBonusOrScatterBulingSound(colIndex,symbolNode)
    --bonus落地音效
    if self:getGameSpinStage() == QUICK_RUN then
        if self.isQuickStopSound then
            self.isQuickStopSound = false
            local bonusState = self:getBonusState()
            if bonusState == 1 then
                self:checkPlayBonusDownSound(colIndex)
            elseif bonusState == 2 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus2_buling)
            end
        end
    else
        if self:isFixSymbol(symbolNode.p_symbolType) then
            self:checkPlayBonusDownSound(colIndex)
        end
        if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 or symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS5 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus2_buling)
        end
        
    end
    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS4 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_wow)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_bonus_buling)
    end
    --scatter落地音效
    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        self:checkPlayScatterDownSound(colIndex)
    end
end

--[[
    检测播放bonus落地音效
]]
function CodeGameScreenCashTornadoMachine:checkPlayBonusDownSound(colIndex)
    if not self.m_bonus_down[colIndex] then
        --播放bonus
        self:playBonusDownSound(colIndex)
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_bonus_down[iCol] = true
        end
    else
        self.m_bonus_down[colIndex] = true
    end
end

--[[
    播放bonus落地音效
]]
function CodeGameScreenCashTornadoMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus1_buling)
end

--[[
    检测播放scatter落地音效
]]
function CodeGameScreenCashTornadoMachine:checkPlayScatterDownSound(colIndex)
    self.m_scatterCount  = self.m_scatterCount + 1
    if self.m_scatterCount > 3 then
        self.m_scatterCount = 3
    end
    
    if self:getGameSpinStage() == QUICK_RUN and not self.m_scatter_down[colIndex] then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_scatter_down[iCol] = true
        end
        if self.m_scatterCount == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_scatter_buling_3"])
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_scatter_buling_1"])
        end
        
    else
        
        if not self.m_scatter_down[colIndex] then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_scatter_buling_"..self.m_scatterCount])
        end
        self.m_scatter_down[colIndex] = true
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenCashTornadoMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        if _slotNode.p_rowIndex == 1 or _slotNode.p_rowIndex == 5 then
            return false
        end
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnimaForCashTornado(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            elseif _slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 then
                if self:isHavePigBonus() then
                    return true
                else
                    return false
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

function CodeGameScreenCashTornadoMachine:isHavePigBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_array = selfData.bonus_array or {}          --位置和倍数
    if table_length(bonus_array) > 0 then
        return true
    end
    return false
end

function CodeGameScreenCashTornadoMachine:isPlayTipAnimaForCashTornado(matrixPosY, matrixPosX, node)
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


function CodeGameScreenCashTornadoMachine:updateNetWorkData()
    CodeGameScreenCashTornadoMachine.super.updateNetWorkData(self)
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == 1 then
        self.isShowFree = true
    end
    
    self:setDataTimeExtraForSpin()
end


function CodeGameScreenCashTornadoMachine:requestSpinResult()
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or -1
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE and freeSpinsLeftCount == freeSpinsTotalCount then
        if not self.m_kaichang then
            self.m_kaichang = util_spineCreate("Socre_CashTornado_Bonus1",true,true)
            self:findChild("Node_kaichang"):addChild(self.m_kaichang)
            self.m_kaichang:setVisible(false)
        end
        self.m_kaichang:setVisible(true)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus1_looksAwesome)
        self:showJveSeFreeKaiChang()
        util_spinePlay(self.m_kaichang,"actionframe_kaichang")
        util_spineEndCallFunc(self.m_kaichang,"actionframe_kaichang",function()
            self.m_kaichang:setVisible(false)
            CodeGameScreenCashTornadoMachine.super.requestSpinResult(self)
            
        end)
    else
        CodeGameScreenCashTornadoMachine.super.requestSpinResult(self)
    end
end

--新滚动使用
function CodeGameScreenCashTornadoMachine:updateReelGridNode(symbolNode)
    CodeGameScreenCashTornadoMachine.super.updateReelGridNode(self, symbolNode)
    if tolua.isnull(symbolNode) or not symbolNode.p_symbolType then
        return
    end
    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 or symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS5 then
        if not symbolNode:isLastSymbol() then
            if not self.isInitReelSymbol then
                symbolNode:runAnim("idleframe2",true)
            end
        end
    end
    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS4 then
        if not self.isInitReelSymbol then
            symbolNode:runAnim("idleframe2",true)
        end
    end

    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS2 or symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS3 then
        self:setSpecialNodeScore(self,{symbolNode})
    end
    
end

-- 给respin小块进行赋值
function CodeGameScreenCashTornadoMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local score = 0
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）

    else
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）

    end
    if symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS2 then
        self:addLevelBonusSpine(symbolNode,score)
    elseif symbolNode.p_symbolType == self.SYMBOL_SCORE_BONUS3 then
        self:addLevelBonusSpineForJackpot(symbolNode,score)
    end
    
end

--spine小块挂钱
function CodeGameScreenCashTornadoMachine:addLevelBonusSpine(_symbol,score)
    local lab,labSpine = self:getLblCsbOnSymbol(_symbol,"CashTornado_Bonus2_coins.csb","gd")
    if lab then
        if lab:findChild("m_lb_coins") then
            lab:findChild("m_lb_coins"):setString(util_formatCoinsLN(score, 3))
            self:updateLabelSize({label=lab:findChild("m_lb_coins"),sx=1,sy=1}, 139)
        end
        if lab:findChild("m_lb_coins2") then
            lab:findChild("m_lb_coins2"):setString(util_formatCoinsLN(score, 3))
            self:updateLabelSize({label=lab:findChild("m_lb_coins2"),sx=1,sy=1}, 139)
        end
        lab:runCsbAction("idleframe",true)
        lab:findChild("Node_1"):setVisible(true)
        lab:findChild("Node_2"):setVisible(false)
    end
    
end

function CodeGameScreenCashTornadoMachine:addLevelBonusSpineForJackpot(_symbol,score)
    local lab,labSpine = self:getLblCsbOnSymbol(_symbol,"CashTornado_Bonus3_Jackpot.csb","gd2")
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local mul = score/lineBet
    if self.isInitReelSymbol then
        if self.initSymbolIndex == 1 then
            mul = 100
        elseif self.initSymbolIndex == 2 then
            mul = 500
        elseif self.initSymbolIndex == 3 then 
            mul = 50   
        end
        self.initSymbolIndex = self.initSymbolIndex + 1
    end
    if lab then
        lab:findChild("Node_grand"):setVisible(mul == 500)
        lab:findChild("Node_mega"):setVisible(mul == 100)
        lab:findChild("Node_major"):setVisible(mul == 50)
        lab:findChild("Node_minor"):setVisible(mul == 20)
        lab:findChild("Node_mini"):setVisible(mul == 10)

        lab:findChild("X2_grand"):setVisible(false)
        lab:findChild("X2_mega"):setVisible(false)
        lab:findChild("X2_major"):setVisible(false)
        lab:findChild("X2_minor"):setVisible(false)
        lab:findChild("X2_mini"):setVisible(false)
        lab:runCsbAction("idleframe",true)
    end
    
end

--有成倍
function CodeGameScreenCashTornadoMachine:updateAddLevelBonusSpine(_symbol,score)
    local lab,labSpine = self:getLblCsbOnSymbol(_symbol,"CashTornado_Bonus2_coins.csb","gd")
    if lab then
        if lab:findChild("m_lb_coins") then
            --score * 2
            lab:findChild("m_lb_coins"):setString(util_formatCoinsLN(score, 3))
            self:updateLabelSize({label=lab:findChild("m_lb_coins"),sx=1,sy=1}, 139)
        end
        if lab:findChild("m_lb_coins2") then
            lab:findChild("m_lb_coins2"):setString(util_formatCoinsLN(score * 2, 3))
            self:updateLabelSize({label=lab:findChild("m_lb_coins2"),sx=1,sy=1}, 139)
        end
        if lab:findChild("Node_1") then
            lab:findChild("Node_1"):setVisible(false)
        end
        if lab:findChild("Node_2") then
            lab:findChild("Node_2"):setVisible(true)
        end
        
    end
    
end

function CodeGameScreenCashTornadoMachine:updateAddLevelBonusSpineForJackpot(_symbol,score)
    local lab,labSpine = self:getLblCsbOnSymbol(_symbol,"CashTornado_Bonus3_Jackpot.csb","gd2")
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local mul = score/lineBet
    if lab then
        lab:findChild("X2_grand"):setVisible(true)
        lab:findChild("X2_mega"):setVisible(true)
        lab:findChild("X2_major"):setVisible(true)
        lab:findChild("X2_minor"):setVisible(true)
        lab:findChild("X2_mini"):setVisible(true)
        lab:findChild("Node_grand"):setVisible(mul == 500)
        lab:findChild("Node_mega"):setVisible(mul == 100)
        lab:findChild("Node_major"):setVisible(mul == 50)
        lab:findChild("Node_minor"):setVisible(mul == 20)
        lab:findChild("Node_mini"):setVisible(mul == 10)  
    end
    
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenCashTornadoMachine:getReSpinSymbolScore(id)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_array = selfData.bonus_array or {}          --位置和倍数
    local multi = nil

    for i=1, #bonus_array do
        local values = bonus_array[i]
        if values[1] == id then
            multi = values[2]
            break
        end
    end

    if multi == nil then
       return 0
    end

    multi = tonumber(multi)

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multi * lineBet

    return score
end

function CodeGameScreenCashTornadoMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    
    if symbolType == self.SYMBOL_SCORE_BONUS2 then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    elseif symbolType == self.SYMBOL_SCORE_BONUS3 then
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro2()
    end
    local lineBet = globalData.slotRunData:getCurTotalBet()
    score = score * lineBet
    return score
end

function CodeGameScreenCashTornadoMachine:getReelPosForCashTornado(col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY() + 140
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

function CodeGameScreenCashTornadoMachine:setLongAnimaInfo(reelEffectNode, col)
    local worldPos, reelHeight, reelWidth = self:getReelPosForCashTornado(col)

    local pos = self.m_slotEffectLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    reelEffectNode:setPosition(cc.p(pos.x, pos.y))
end

function CodeGameScreenCashTornadoMachine:createReelEffectBG(col)
    if self.m_reelBgEffectName ~= nil then
        local csbName = self.m_reelBgEffectName .. ".csb"
        local reelEffectNode, effectAct = util_csbCreate(csbName)

        reelEffectNode:retain()
        effectAct:retain()

        self.m_clipParent:addChild(reelEffectNode, -1,SYMBOL_NODE_TAG * 100)
        local reel = self:findChild("sp_reel_" .. (col - 1))
        local reelType = tolua.type(reel)
        if reelType == "ccui.Layout" then
            reelEffectNode:setLocalZOrder(0)
        end
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        reelEffectNode:setPosition(cc.p(posX,(posY + 140)))
        self.m_reelRunAnimaBG[col] = {reelEffectNode, effectAct}

        reelEffectNode:setVisible(false)

        return reelEffectNode, effectAct
    end
end

--添加金边
function CodeGameScreenCashTornadoMachine:creatReelRunAnimation(col)
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

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
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
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

-- 重置当前背景音乐名称
function CodeGameScreenCashTornadoMachine:resetCurBgMusicName(musicName)
    if musicName then
        self.m_currentMusicBgName = musicName
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()

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
    if self.isSpecialBase then
        self.m_currentMusicBgName = "CashTornadoSounds/music_CashTornado_base2.mp3"
    end
    -- if self.isPickGame then
    --     self.m_currentMusicBgName = "CashTornadoSounds/music_CashTornado_pick.mp3"
    -- end
end

function CodeGameScreenCashTornadoMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_left_win = selfData.bonus_left_win or 0
    local bonus_right_win = selfData.bonus_right_win or 0
    local pick_win = selfData.pick_win or 0
    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if bonus_left_win > 0 or bonus_right_win > 0 then       --有砸猪玩法
        local LinesCoins = self.m_iOnceSpinLastWin
        if bonus_left_win > 0 and globalData.slotRunData.lastWinCoin > bonus_left_win then
            globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - bonus_left_win
            LinesCoins = LinesCoins - bonus_left_win
            self.powerStrikeCoins = LinesCoins
        end
        if bonus_right_win > 0 and globalData.slotRunData.lastWinCoin > bonus_right_win then
            globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - bonus_right_win
            LinesCoins = LinesCoins - bonus_right_win
            self.powerStrikeCoins = LinesCoins
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {LinesCoins, isNotifyUpdateTop})
    elseif pick_win > 0 and globalData.slotRunData.lastWinCoin > pick_win then      --有pick玩法
        local LinesCoins = self.m_iOnceSpinLastWin
        globalData.slotRunData.lastWinCoin = globalData.slotRunData.lastWinCoin - pick_win
        LinesCoins = LinesCoins - pick_win
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {LinesCoins, isNotifyUpdateTop})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenCashTornadoMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end
    
    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function CodeGameScreenCashTornadoMachine:initGameStatusData(gameData)
    
    CodeGameScreenCashTornadoMachine.super.initGameStatusData(self,gameData)
    local gameConfig = gameData.gameConfig or {}
    local extra = gameConfig.extra or {}
    local start_time = extra.start_time         --一阶段开始时间戳
    local middle_time = extra.middle_time       --一阶段结束时间戳/二阶段开始时间戳
    local end_time = extra.end_time             --二阶段结束时间戳
    local time_now = extra.time_now             --服务器当前时间戳
    local base_status = extra.base_status or 1

    
    
    
    self.specialBaseData = {}
    self:updateSpecialBaseData(extra)
    if base_status == 1 then
        if globalMachineController.setIgnorePopCorEnabled then
            globalMachineController:setIgnorePopCorEnabled(false)
        end
        self.isSpecialBase = false
        self.m_configData:setBaseIndex(1)
    else
        if globalMachineController.setIgnorePopCorEnabled then
            globalMachineController:setIgnorePopCorEnabled(true)
        end
        self.m_configData:setBaseIndex(2)
        self.isSpecialBase = true
    end
end



function CodeGameScreenCashTornadoMachine:initNoneFeature()
    self.isInitReelSymbol = true
    CodeGameScreenCashTornadoMachine.super.initNoneFeature(self)
    
end

-- -------------------------------------------ui、角色、过场相关
function CodeGameScreenCashTornadoMachine:changeUiForState(state,isStart)
    self:findChild("Node_qipan"):setVisible(state ~= PublicConfig.uiState.pick)
    self:findChild("Node_pick"):setVisible(state == PublicConfig.uiState.pick)
    self:findChild("Node_base_reel"):setVisible(state == PublicConfig.uiState.base or state == PublicConfig.uiState.base2)
    self:findChild("Node_FG_reel"):setVisible(state == PublicConfig.uiState.free)
    
    if self.fiveColKuang then
        self.fiveColKuang:setVisible(state == PublicConfig.uiState.base2)
        if state == PublicConfig.uiState.base2 then
            self.fiveColKuang:runCsbAction("idle",true)
        end
    end
    if self.fiveColKuang2 then
        self.fiveColKuang2:setVisible(state == PublicConfig.uiState.base2)
        if state == PublicConfig.uiState.base2 then
            self.fiveColKuang2:runCsbAction("idle",true)
        end
    end

    if self.wenan then
        self.wenan:setVisible(state == PublicConfig.uiState.base2)
    end
    self:findChild("Node_reel_5"):setVisible(state == PublicConfig.uiState.base2)
    -- self.m_baseFreeSpinBar:setVisible(state == PublicConfig.uiState.free)
    
    --背景
    if state == PublicConfig.uiState.base then
        util_spinePlay(self.m_bg,"base1",true)
        self.m_gameBg:runCsbAction("base",true)
        if self.jvese then
            self.jvese:setVisible(true)
        end
        if self.jvese2 then
            self.jvese2:setVisible(false)
        end
    elseif state == PublicConfig.uiState.base2 then
        util_spinePlay(self.m_bg,"base2",true)
        self.m_gameBg:runCsbAction("base",true)
        if self.jvese then
            self.jvese:setVisible(false)
        end
        if isStart then
            
        else
            if self.jvese2 then
                self.jvese2:setVisible(true)
                util_spinePlay(self.jvese2,"base2",true)
            end
        end
        
    elseif state == PublicConfig.uiState.free then
        util_spinePlay(self.m_bg,"free",true)
        self.m_gameBg:runCsbAction("free",true)
        if self.jvese then
            self.jvese:setVisible(true)
        end
        if self.jvese2 then
            self.jvese2:setVisible(false)
        end
    elseif state == PublicConfig.uiState.pick then
        util_spinePlay(self.m_bg,"pick",true)
        self.m_gameBg:runCsbAction("pick_start",false,function ()
            self.m_gameBg:runCsbAction("pick",true)
        end)
    end
end

function CodeGameScreenCashTornadoMachine:showJueseBigWin()
    if self.m_bProduceSlots_InFreeSpin then
        self.m_JveSeNode:stopAllActions()
        util_spinePlay(self.jvese,"jackpot_idleframe2")
        util_spineEndCallFunc(self.jvese,"jackpot_idleframe2",function()
            if self.m_bProduceSlots_InFreeSpin then
                self:showJveSeIdleAct(true)
            else
                self:showJveSeIdleAct(false)
            end 
            
        end)
    else
        self.m_JveSeNode:stopAllActions()
        util_spinePlay(self.jvese,"idleframe3")
        util_spineEndCallFunc(self.jvese,"idleframe3",function()
            if self.m_bProduceSlots_InFreeSpin then
                self:showJveSeIdleAct(true)
            else
                self:showJveSeIdleAct(false)
            end 
            
        end)
    end
    
end

function CodeGameScreenCashTornadoMachine:showJveSePowerStrikeYuGao()
    local actName = "actionframe_yugao"
    if self.m_bProduceSlots_InFreeSpin then
        actName = "actionframe_yugao2"
    end
    self.m_JveSeNode:stopAllActions()
    util_spinePlay(self.jvese,actName)
    util_spineEndCallFunc(self.jvese,actName,function()
        if self.m_bProduceSlots_InFreeSpin then
            self:showJveSeIdleAct(true)
        else
            self:showJveSeIdleAct(false)
            
        end 
        
    end)
end

function CodeGameScreenCashTornadoMachine:showJueSeWinLineOrBonus()
    if self.m_bProduceSlots_InFreeSpin then
        self.m_JveSeNode:stopAllActions()
        util_spinePlay(self.jvese,"jackpot_idleframe1")
        util_spineEndCallFunc(self.jvese,"jackpot_idleframe1",function()
            if self.m_bProduceSlots_InFreeSpin then
                self:showJveSeIdleAct(true)
            else
                self:showJveSeIdleAct(false)
            end 
            
        end)
    end
    
end

function CodeGameScreenCashTornadoMachine:showJveSeFreeTrigger()
    if not self.isSpecialBase and not self.m_bProduceSlots_InFreeSpin then
        self.m_JveSeNode:stopAllActions()
        util_spinePlay(self.jvese,"idleframe4")
        util_spineEndCallFunc(self.jvese,"idleframe4",function()
            if self.m_bProduceSlots_InFreeSpin then
                self:showJveSeIdleAct(true)
            else
                self:showJveSeIdleAct(false)
            end 
        end)
    end
    
end

function CodeGameScreenCashTornadoMachine:showJveSeFreeYuGao()
    self.m_JveSeNode:stopAllActions()
    util_spinePlay(self.jvese,"actionframe_free1")
    util_spineEndCallFunc(self.jvese,"actionframe_free1",function()
        if self.m_bProduceSlots_InFreeSpin then
            self:showJveSeIdleAct(true)
        else
            self:showJveSeIdleAct(false)
        end 
    end)
end

function CodeGameScreenCashTornadoMachine:showJveSeFreeKaiChang()
    self.m_JveSeNode:stopAllActions()
    util_spinePlay(self.jvese,"actionframe_kaichang")
    util_spineEndCallFunc(self.jvese,"actionframe_kaichang",function()
        if self.m_bProduceSlots_InFreeSpin then
            self:showJveSeIdleAct(true)
        else
            self:showJveSeIdleAct(false)
        end 
    end)
end

function CodeGameScreenCashTornadoMachine:showJveSeEnterSpecialBase(func)
    self.m_JveSeNode:stopAllActions()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_base_show)
    util_spinePlay(self.jvese,"idleframe5")
    self:delayCallBack(30/30,function ()
        if func then
            func()
        end
    end)
end

function CodeGameScreenCashTornadoMachine:getJveSeIdleInfo(isFree)
    local time1 = 0
    local time2 = 0
    local time3 = 0
    local actName1 = nil 
    local actName2 = nil 
    local actName3 = nil 
    local info = {}
    if isFree == true then
        time1 = self.jvese:getAnimationDurationTime("jackpot_idleframe")
        time2 = self.jvese:getAnimationDurationTime("jackpot_idleframe")
        time3 = self.jvese:getAnimationDurationTime("jackpot_idleframe")
        actName1 = "jackpot_idleframe" 
        actName2 = "jackpot_idleframe" 
        actName3 = "jackpot_idleframe" 
    else
        time1 = self.jvese:getAnimationDurationTime("idleframe")
        time2 = self.jvese:getAnimationDurationTime("idleframe")
        time3 = self.jvese:getAnimationDurationTime("idleframe")
        actName1 = "idleframe" 
        actName2 = "idleframe" 
        actName3 = "idleframe" 
    end
    info[#info + 1] = {time1,actName1}
    info[#info + 1] = {time2,actName2}
    info[#info + 1] = {time3,actName3}
    return info
end

function CodeGameScreenCashTornadoMachine:showJveSeIdleAct(isFree)
    self.m_JveSeNode:stopAllActions()
    local idleInfo = self:getJveSeIdleInfo(isFree)
    local baseNextTime = 0
    local baseNextAct = "idleframe1"
    local baseNextTimeForFree = 0
    local baseNextActForFree = "jackpot_idleframe3"
    if not isFree then
        if self.jueSeIndex == 1 then
            self.jueSeIndex = 2
            baseNextTime = self.jvese:getAnimationDurationTime("idleframe1")
            baseNextAct = "idleframe1" 
        else
            self.jueSeIndex = 1
            baseNextTime = self.jvese:getAnimationDurationTime("idleframe2")
            baseNextAct = "idleframe2" 
        end
    else
        if self.jueSeIndexForFree == 1 then
            self.jueSeIndexForFree = 2
            baseNextTimeForFree = self.jvese:getAnimationDurationTime("jackpot_idleframe3")
            baseNextActForFree = "jackpot_idleframe3" 
        else
            self.jueSeIndexForFree = 1
            baseNextTimeForFree = self.jvese:getAnimationDurationTime("jackpot_idleframe4")
            baseNextActForFree = "jackpot_idleframe4" 
        end
    end
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, idleInfo[1][2],false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(idleInfo[1][1])
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, idleInfo[2][2],false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(idleInfo[2][1])
    actList[#actList + 1] = cc.CallFunc:create(function ()
        util_spinePlay(self.jvese, idleInfo[3][2],false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(idleInfo[3][1])
    if not isFree and baseNextTime > 0 then
        actList[#actList + 1] = cc.CallFunc:create(function ()
            util_spinePlay(self.jvese,baseNextAct,false)
        end)
        actList[#actList + 1] = cc.DelayTime:create(baseNextTime)
    elseif isFree and baseNextTimeForFree > 00 then
        actList[#actList + 1] = cc.CallFunc:create(function ()
            util_spinePlay(self.jvese,baseNextActForFree,false)
        end)
        actList[#actList + 1] = cc.DelayTime:create(baseNextTimeForFree)
    end
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:showJveSeIdleAct(isFree)
    end)
    self.m_JveSeNode:runAction(cc.Sequence:create(actList))
end

--PowerStrike预告
function CodeGameScreenCashTornadoMachine:showPowerStrikeYuGao()
    local aniTime = 4
    local yuGao3 = nil
    local yuGao2 = nil
    local yuGao1 = nil

    --获取父节点
    local parentNode = self:findChild("Node_yugao")
    if not parentNode then
        parentNode = self:findChild("root")
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_PowerStrike_yuGao)
    if #self.yuGaoActList == 0 then
        yuGao3 = util_spineCreate("CashTornado_pidk_chaopiao",true,true)
        yuGao2 = util_spineCreate("CashTornado_zhu",true,true)
        yuGao1 = util_spineCreate("CashTornado_chaopiao2",true,true)
        parentNode:addChild(yuGao3,3)
        parentNode:addChild(yuGao2,2)
        parentNode:addChild(yuGao1,1)
        self.yuGaoActList[#self.yuGaoActList + 1] = yuGao1
        self.yuGaoActList[#self.yuGaoActList + 1] = yuGao2
        self.yuGaoActList[#self.yuGaoActList + 1] = yuGao3
    else
        yuGao3 = self.yuGaoActList[3]
        yuGao2 = self.yuGaoActList[2]
        yuGao1 = self.yuGaoActList[1]
    end

    if not tolua.isnull(yuGao3) then
        yuGao3:setVisible(true)
        util_spinePlay(yuGao3,"actionframe_yugao")
        util_spineEndCallFunc(yuGao3,"actionframe_yugao",function()
            yuGao3:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            -- self:delayCallBack(0.1,function()
            --     yuGao3:removeFromParent()
            -- end)
            
        end)
    end
    if not tolua.isnull(yuGao2) then
        yuGao2:setVisible(true)
        util_spinePlay(yuGao2,"actionframe_yugao")
        util_spineEndCallFunc(yuGao2,"actionframe_yugao",function()
            yuGao2:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            -- self:delayCallBack(0.1,function()
            --     yuGao3:removeFromParent()
            -- end)
            
        end)
    end
    if not tolua.isnull(yuGao1) then
        yuGao1:setVisible(true)
        util_spinePlay(yuGao1,"actionframe_yugao")
        util_spineEndCallFunc(yuGao1,"actionframe_yugao",function()
            yuGao1:setVisible(false)
            --延时0.1s移除spine,直接移除会导致闪退
            -- self:delayCallBack(0.1,function()
            --     yuGao3:removeFromParent()
            -- end)
            
        end)
    end
    self:showJveSePowerStrikeYuGao()
    return aniTime
end

--普通base下free预告
function CodeGameScreenCashTornadoMachine:showNomarlBaseToFreeYuGao()
    local aniTime = 4
    if not self.m_freeYuGao then
        self.m_freeYuGao = util_spineCreate("CashTornado_juese",true,true)
        self:findChild("Node_yugao"):addChild(self.m_freeYuGao,4)
    end
    self.m_freeYuGao:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_yuGao)
    util_spinePlay(self.m_freeYuGao,"actionframe_free2")
    util_spineEndCallFunc(self.m_freeYuGao,"actionframe_free2",function()
        self.m_freeYuGao:setVisible(false)
    end)
    self:showJveSeFreeYuGao()
    return aniTime
end

--大赢动画
function CodeGameScreenCashTornadoMachine:showBigWinForSpine()
    if not self.m_bigWinEff then
        self.m_bigWinEff =  util_spineCreate("CashTornado_bigwin",true,true)
        local pos = util_convertToNodeSpace(self.m_bottomUI:getNormalWinLabel(), self:findChild("root"))
        self:findChild("root"):addChild(self.m_bigWinEff)
        self.m_bigWinEff:setPosition(cc.p((pos.x + 15),(pos.y - 25)))
        self.m_bigWinEff:setVisible(false)
    end
    self.m_bigWinEff:setVisible(true)
    -- local random = math.random(1,100)
    -- if random <= 30 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_stronger_winds)
    -- end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bugWin_yuGao)
    util_spinePlay(self.m_bigWinEff,"actionframe_bigwin")
    util_spineEndCallFunc(self.m_bigWinEff,"actionframe_bigwin",function()
        self.m_bigWinEff:setVisible(false)
    end)
end

--大赢背景动画
function CodeGameScreenCashTornadoMachine:showBigWinForBg()
    if self.m_bg and not self.isSpecialBase then
        if self.m_bProduceSlots_InFreeSpin then
            util_spinePlay(self.m_bg,"actionframe_bigwin2")
            util_spineEndCallFunc(self.m_bg,"actionframe_bigwin2",function()
                util_spinePlay(self.m_bg,"free",true)
            end)
        else
            util_spinePlay(self.m_bg,"actionframe_bigwin")
            util_spineEndCallFunc(self.m_bg,"actionframe_bigwin",function()
                if self.isSpecialBase then
                    util_spinePlay(self.m_bg,"base2",true)
                else
                    util_spinePlay(self.m_bg,"base1",true)
                end
                
            end)
        end
    end
end

function CodeGameScreenCashTornadoMachine:showGuochang(func1,func2)
    if not self.m_spineGuochang then
        self.m_spineGuochang = util_spineCreate("FreeSpinStart_feng", true, true)
        self.m_spineGuochang:setScale(self.m_machineRootScale)
        self:addChild(self.m_spineGuochang, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
        self.m_spineGuochang:setPosition(display.width * 0.5, display.height * 0.5)
    end
    self.noClickLayer:setVisible(true)
    self.m_spineGuochang:setVisible(true)
    util_spinePlay(self.m_spineGuochang, "actionframe_guochang")
    util_spineEndCallFunc(self.m_spineGuochang, "actionframe_guochang", function ()
        self.m_spineGuochang:setVisible(false)
        self.noClickLayer:setVisible(false)
    end)
    self:delayCallBack(39/30,function ()
        if func1 then
            func1()
        end
    end)
    self:delayCallBack(60/30,function ()
        if func2 then
            func2()
        end
    end)
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenCashTornadoMachine:showEffect_runBigWinLightAni(effectData)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_left_win = selfData.bonus_left_win or 0
    local bonus_right_win = selfData.bonus_right_win or 0
    local pick_win = selfData.pick_win or 0
    if self.isSpecialBase then      --限时base不播大赢
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    if bonus_left_win > 0 or bonus_right_win > 0 then
        effectData.p_isPlay = true
        self:playGameEffect()
        return true
    end
    if pick_win > 0 then
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
function CodeGameScreenCashTornadoMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local aniTime = 3
    util_shakeNode(rootNode,5,10,aniTime)
    self:showBigWinForSpine()
    self:showBigWinForBg()
    self:showJueseBigWin()
    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenCashTornadoMachine:showBigWinLightForPower(func)
    if self.isSpecialBase then
        if type(func) == "function" then
            func()
        end
        return
    end
    local rootNode = self:findChild("root")
    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)
    self:showBigWinForSpine()
    self:showBigWinForBg()
    self:showJueseBigWin()
    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

-- 绘制多个裁切区域
function CodeGameScreenCashTornadoMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    
    self.m_slotParents = {}
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    for iCol = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (iCol - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        --
        --420
        -- reelSize.height = (reelSize.height - 140) * scaleY
        reelSize.height = (reelSize.height) * scaleY
        

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(iCol)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local parentData = SlotParentData:new()
        parentData.cloumnIndex = iCol
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum
        parentData.startX = reelSize.width * 0.5
        parentData.reelWidth = reelSize.width
        parentData.reelHeight = reelSize.height
        parentData.slotNodeW = self.m_SlotNodeW
        parentData.slotNodeH = self.m_SlotNodeH
        parentData:reset()
        self.m_slotParents[iCol] = parentData

        local clipNode  
        clipNode = util_require(self:getReelNode()):create({
            parentData = parentData,      --列数据
            configData = self.m_configData,      --列配置数据
            doneFunc = handler(self,self.slotOneReelDown),        --列停止回调
            createSymbolFunc = handler(self,self.getSlotNodeWithPosAndType),--创建小块
            pushSlotNodeToPoolFunc = handler(self,self.pushSlotNodeToPoolBySymobolType),--小块放回缓存池
            updateGridFunc = handler(self,self.updateReelGridNode),  --小块数据刷新回调
            checkAddSignFunc = handler(self,self.checkAddSignOnSymbol), --小块添加角标回调
            direction = 0,      --0纵向 1横向 默认纵向
            colIndex = iCol,
            bigReelNode = self.m_bigReelNodeLayer,
            machine = self      --必传参数
        })
        self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        self.m_baseReelNodes[iCol] = clipNode
        clipNode:setPosition(cc.p(posX,posY))
    end
    
    --等裁切层加在父节点上之后再刷新大信号位置,否则坐标无法转化
    self:refreshBigRollNodePos()
end

------------------------------------------------PowerStrike玩法相关

function CodeGameScreenCashTornadoMachine:showPowerStrikeEffect(func)
    self:clearWinLineEffect()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    -- if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
    --     --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
    --     self.m_bottomUI:resetWinLabel()
    --     self.m_bottomUI:notifyTopWinCoin()
    --     self.m_bottomUI:checkClearWinLabel()
    -- end
    

    local createBonus1List = {}
    local createBonus2or3List = {}
    --展示压黑
    self.darkLayer:setVisible(true)
    self.darkLayer:runCsbAction("start",false,function ()
        self.darkLayer:runCsbAction("idle",true)
    end)
    --创建假的用做播动画
    createBonus1List,createBonus2or3List = self:createAllBonusForDarkLayer()
    self:delayCallBack(15/60,function ()
        --排序
        self.power_Strike_state = 1
        self:showEveryBonusEffect(1,createBonus1List,createBonus2or3List,func)
    end)
    
end

function CodeGameScreenCashTornadoMachine:getReelSymbolNodeForType(type1,type2)
    local bonusInfoList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            if iRow ~= 1 or iRow ~= 5 then
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType then
                    if slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS1 or slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS5 then
                        bonusInfoList[#bonusInfoList + 1] = {y = iCol,x = iRow}
                    end
                end
            end
            
        end
    end
    return bonusInfoList
end

function CodeGameScreenCashTornadoMachine:createAllBonusForDarkLayer()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_left_win = selfData.bonus_left_win or 0
    local bonus_right_win = selfData.bonus_right_win or 0
    local bonus_array = selfData.bonus_array or {}          --位置和倍数

    local bonus1List = selfData.bonus1List or {}
    local bonus2or3List = selfData.bonus2or3List or {}
    local createBonus1List =  {}        -- 一种或两种锤子
    local createBonus2or3List = {}      -- 一种或两种小猪

    local chuiZiInfo = self:getReelSymbolNodeForType()

    for i, info in ipairs(chuiZiInfo) do
        if info.y and info.x then
            local realSymbol = self:getFixSymbol(info.y, info.x)
            if realSymbol and realSymbol.p_symbolType then
                local bonus1 = util_spineCreate("Socre_CashTornado_Bonus1", true, true)
                if realSymbol.p_symbolType == self.SYMBOL_SCORE_BONUS5 then
                    bonus1 = util_spineCreate("Socre_CashTornado_Bonus5", true, true)
                end
                util_spinePlay(bonus1, "idleframe1",true)
                local symbolIndex = self:getPosReelIdx(info.x, info.y)
                local pos = util_convertToNodeSpace(realSymbol,self.m_effectNode2)
                self.m_effectNode2:addChild(bonus1,10000)
                bonus1:setPosition(pos)
                bonus1.symbolIndex = symbolIndex
                bonus1.symbolType = realSymbol.p_symbolType
                createBonus1List[#createBonus1List + 1] = bonus1
                realSymbol:setVisible(false)
            end
            
        end
        
    end

    --从左到右 从上到下 排序
    table.sort( bonus_array, function(a, b)
        local rowColDataA = self:getRowAndColByPos(a[1])
        local rowColDataB = self:getRowAndColByPos(b[1])

        if rowColDataA.iY == rowColDataB.iY then
            return rowColDataA.iX > rowColDataB.iX
        end

        return rowColDataA.iY < rowColDataB.iY
    end )

    for i, info in ipairs(bonus_array) do
        local symbolIndex = info[1]
        local fixPos = self:getRowAndColByPos(symbolIndex)
        local realSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
        if realSymbol and realSymbol.p_symbolType then
            local bonus2 = util_spineCreate("Socre_CashTornado_Bonus2", true, true)
            if realSymbol.p_symbolType == self.SYMBOL_SCORE_BONUS3 then
                bonus2 = util_spineCreate("Socre_CashTornado_Bonus3", true, true)
            end
            util_spinePlay(bonus2, "idleframe1",true)
            local pos = util_convertToNodeSpace(realSymbol,self.m_effectNode2)
            self.m_effectNode2:addChild(bonus2,self:getBounsScatterDataZorder(realSymbol.p_symbolType) + fixPos.iY * 10 - fixPos.iX)
            bonus2:setPosition(pos) 
            bonus2.symbolIndex = symbolIndex
            bonus2.symbolType = realSymbol.p_symbolType
            local mul = self:getBonusCoinsMul(bonus2)
            local lineBet = globalData.slotRunData:getCurTotalBet()
            local coins = mul * lineBet
            if realSymbol.p_symbolType == self.SYMBOL_SCORE_BONUS3 then
                local jackpotIndex = self:getJackpotBonusState(symbolIndex)
                local jackpotType = self:getJackpotTypeForIndex(jackpotIndex)
                self:updateBonus3Coins(bonus2,jackpotType,false)
            else
                self:updateBonus2Coins(bonus2,coins,false)
            end
            
            createBonus2or3List[#createBonus2or3List + 1] = bonus2
            realSymbol:setVisible(false)
        end
        
    end
    return createBonus1List,createBonus2or3List
end

--移除所有tempBonus
function CodeGameScreenCashTornadoMachine:clearAllTempBonus()
    local children = self.m_effectNode2:getChildren()
    for k,node in pairs(children) do
        if not tolua.isnull(node) then
            node:stopAllActions()
            if not tolua.isnull(node.m_bindCsbNode) then
                local actNode = node.m_bindCsbNode:findChild("act_Node")
                if actNode then
                    actNode:stopAllActions()
                end
            end
            node:removeFromParent()
        end
    end
end

--显示隐藏的图标
function CodeGameScreenCashTornadoMachine:showReelSymbolForPowerStrike()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local node = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if not tolua.isnull(node) and node.p_symbolType then
                node:setVisible(true)
            end
        end
    end
end

function CodeGameScreenCashTornadoMachine:showEveryBonusEffect(bonusIndex,createBonus1List,createBonus2or3List,func)
    if bonusIndex > #createBonus1List then
        --播结算动画
        self:delayCallBack(0.1,function ()
            self:showPowerStrikeJiesuan(1,createBonus2or3List,function ()
                if func then
                    func()
                end
            end)
        end)
        
        
        return
    end
    self.power_Strike_state = bonusIndex
    local bonusSpine = createBonus1List[bonusIndex]
    local fixPos = self:getRowAndColByPos(bonusSpine.symbolIndex)
    local waitTime = 2
    local actName = "actionframe"
    if #createBonus1List == 1 and bonusSpine.symbolType then
        if bonusSpine.symbolType == self.SYMBOL_SCORE_BONUS1 then
            actName = "actionframe2"
        end
    else
        if bonusSpine.symbolType and bonusSpine.symbolType == self.SYMBOL_SCORE_BONUS1 then
            waitTime = 1
        end
    end
    if bonusIndex == 1 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_first_chuizi)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_za_pig)
    end
    
    util_spinePlay(bonusSpine,actName)
    util_spineEndCallFunc(bonusSpine,actName, function ()
        util_spinePlay(bonusSpine, "idleframe",true)
        local realSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
        if realSymbol then
            realSymbol:runAnim("idleframe")
        end
    end)
    local pigWaitTime = 0
    if bonusIndex > 1 then
        pigWaitTime = 1
    end
    --真实小块也播对应时间线
    --砸开小猪后刷新小猪显示
    -- self:delayCallBack(pigWaitTime,function ()
        if bonusIndex == 1 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus1_trigger)
        end
        
        self:setReelSymbolNodeAct(createBonus2or3List,bonusIndex)
    -- end)
    
    self:delayCallBack(waitTime,function ()
        --其他bonus砸开显示
        bonusIndex = bonusIndex + 1
        
        self:showEveryBonusEffect(bonusIndex,createBonus1List,createBonus2or3List,func)
    end)
    
    
end

function CodeGameScreenCashTornadoMachine:setReelSymbolNodeAct(createBonus2or3List,bonusIndex)
    --临时创建的小猪播对应动画
    --真实小猪播对应的idle动画
    if bonusIndex == 1 then
        local random = math.random(1,100)
        if random <= 30 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_cool)
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus1_trigger_2)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus1_coins_chengBei)
    end
    
    for i, bonusSpine in ipairs(createBonus2or3List) do
        local actNameList = self:getActNameForTempPig(bonusSpine,bonusIndex)
        local mul = self:getBonusCoinsMul(bonusSpine)
        local lineBet = globalData.slotRunData:getCurTotalBet()
        local coins = mul * lineBet
        if bonusSpine.symbolType == self.SYMBOL_SCORE_BONUS2 then
            
            if bonusIndex == 1 then
                self:updateBonus2Coins(bonusSpine,coins,false)
            else
                self:delayCallBack(11/30,function ()
                    self:updateBonus2Coins(bonusSpine,coins,true)
                end)
                
            end
             
        else
            local jackpotIndex = self:getJackpotBonusState(bonusSpine.symbolIndex)
            local jackpotType = self:getJackpotTypeForIndex(jackpotIndex)
            if bonusIndex == 1 then
                self:updateBonus3Coins(bonusSpine,jackpotType,false)
            else
                self:delayCallBack(11/30,function ()
                    self:updateBonus3Coins(bonusSpine,jackpotType,true)
                end)
                
            end
        end
        --播对应动画
        util_spinePlay(bonusSpine, actNameList[1])
        util_spineEndCallFunc(bonusSpine, actNameList[1], function ()
            util_spinePlay(bonusSpine, actNameList[2])
        end)
        local fixPos = self:getRowAndColByPos(bonusSpine.symbolIndex)
        local realSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
        if realSymbol then
            realSymbol:runAnim(actNameList[2])
            --真实小块的钱数刷新显示
            if bonusIndex > 1 then
                if bonusSpine.symbolType == self.SYMBOL_SCORE_BONUS2 then
                    self:updateAddLevelBonusSpine(realSymbol,coins)
                else
                    self:updateAddLevelBonusSpineForJackpot(realSymbol,coins)
                end
            else
                    
            end
        end
    end
    
end

function CodeGameScreenCashTornadoMachine:getActNameForTempPig(bonusSpine,state)
    --顺序：触发、idle、结算
    local actList = {           
            "actionframe",
            "idleframe2",
            "jiesuan1"
        }      
    if bonusSpine.symbolType then
        if bonusSpine.symbolType == self.SYMBOL_SCORE_BONUS2 then
            if state == 1 then  --第一阶段
                actList = {
                    "actionframe",
                    "idleframe2",
                    "jiesuan1"
                }
            else                --第二阶段
                actList = {
                    "actionframe_xbei",
                    "idleframe3",
                    "jiesuan2"
                }
            end
            
        elseif bonusSpine.symbolType == self.SYMBOL_SCORE_BONUS3 then
            --一共五种状态：分别对应五种jackpot
            local jackpotIndex = self:getJackpotBonusState(bonusSpine.symbolIndex)
            if jackpotIndex > 0 then
                if state == 1 then  --第一阶段
                    actList = {
                        "actionframe"..jackpotIndex,
                        "idleframe2_"..jackpotIndex,
                        "jiesuan1_"..jackpotIndex
                    }
                else                --第二阶段
                    actList = {
                        "actionframe_xbei"..jackpotIndex,
                        "idleframe3_"..jackpotIndex,
                        "jiesuan2_"..jackpotIndex
                    }
                end
            end
        end
    end
    return actList
end

function CodeGameScreenCashTornadoMachine:getJackpotBonusState(symbolIndex)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_array = selfData.bonus_array or {}          --位置和倍数
    if symbolIndex and table_length(bonus_array) > 0 then
        local score = nil
        local idNode = nil
        for i,v in ipairs(bonus_array) do
            local values = bonus_array[i]
            if values[1] == symbolIndex then
                score = values[2]
            end
        end
        if score then
            if score == 10 then
                return 5
            elseif score == 20 then
                return 4
            elseif score == 50 then
                return 3
            elseif score == 100 then
                return 2
            elseif score == 500 then
                return 1
            end
            
        end
    end
    return 0
end

function CodeGameScreenCashTornadoMachine:getJackpotTypeForIndex(index)
    if index == 1 then
        return "grand"
    elseif index == 2 then
        return "mega"
    elseif index == 3 then
        return "major"
    elseif index == 4 then
        return "minor"
    elseif index == 5 then
        return "mini"    
    end
end

function CodeGameScreenCashTornadoMachine:getBonusCoinsMul(bonusSpine)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonus_array = selfData.bonus_array or {}          --位置和倍数
    local score = 1
    if bonusSpine.symbolIndex and table_length(bonus_array) > 0 then
        
        local idNode = nil
        for i,v in ipairs(bonus_array) do
            local values = bonus_array[i]
            if values[1] == bonusSpine.symbolIndex then
                score = values[2]
            end
        end
    end
    return score
end


function CodeGameScreenCashTornadoMachine:updateBonus2Coins(spineNode,coins,isChengBei)
    --获取绑定的cocos
    local function getCsbForSpine(spine,csbName,bindNodeName)
        if spine and tolua.isnull(spine.m_bindCsbNode) then

            local label = util_createAnimation(csbName)
            util_spinePushBindNode(spine,bindNodeName,label)
            spine.m_bindCsbNode = label
        end
        return spine.m_bindCsbNode
    end
    local csbName = "CashTornado_Bonus2_coins.csb"
    local bindNodeName = "gd"

    local labelCsb = getCsbForSpine(spineNode,csbName,bindNodeName)
    labelCsb:findChild("Node_2"):setVisible(isChengBei == true)
    labelCsb:findChild("Node_1"):setVisible(isChengBei == false)
    if not tolua.isnull(labelCsb) then
        labelCsb:findChild("m_lb_coins"):setString(util_formatCoinsLN(coins, 3))
        self:updateLabelSize({label=labelCsb:findChild("m_lb_coins"),sx=1,sy=1}, 139)
        labelCsb:findChild("m_lb_coins2"):setString(util_formatCoinsLN(coins, 3))
        self:updateLabelSize({label=labelCsb:findChild("m_lb_coins2"),sx=1,sy=1}, 139)
        if isChengBei then
            labelCsb:runCsbAction("actionframe",false,function ()
                labelCsb:runCsbAction("idleframe")
            end)
            --钱数滚动
            if labelCsb:findChild("act_Node") then
                self:jumpCoins(labelCsb:findChild("act_Node"),labelCsb:findChild("m_lb_coins2"),coins,function(  )
                    labelCsb:findChild("m_lb_coins2"):setString(util_formatCoinsLN(coins * 2, 3))
                    self:updateLabelSize({label=labelCsb:findChild("m_lb_coins2"),sx=1,sy=1}, 139)
                end)
            end
        end
        
    end
    
    
end

--[[
    跳动金币
]]
function CodeGameScreenCashTornadoMachine:jumpCoins(node,nodeGold,startCoins,func)
    nodeGold:setString(util_formatCoinsLN(startCoins,3))
    self:updateLabelSize({label=nodeGold,sx=1,sy=1}, 139)
    local showTime = 1
    local coinRiseNum = startCoins * 2 / (showTime * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 3 ))
    coinRiseNum = tonumber(str)

    local curCoins = startCoins
    node:stopAllActions()
    
    util_schedule(node,function()

        curCoins = curCoins + coinRiseNum
        curCoins = math.ceil(curCoins)
        if curCoins >= startCoins * 2 then

            curCoins = startCoins * 2
            nodeGold:setString(util_formatCoinsLN(curCoins,3))
            self:updateLabelSize({label=nodeGold,sx=1,sy=1}, 139)

            node:stopAllActions()
            if type(func) == "function" then
                func()
            end
        else
            nodeGold:setString(util_formatCoinsLN(curCoins,3))
            self:updateLabelSize({label=nodeGold,sx=1,sy=1}, 139)
        end
    end,1 / 60)
end

function CodeGameScreenCashTornadoMachine:updateBonus3Coins(spineNode,jackpotType,isChengBei)
    --获取绑定的cocos
    local function getCsbForSpine(spine,csbName,bindNodeName)
        if spine and tolua.isnull(spine.m_bindCsbNode) then

            local label = util_createAnimation(csbName)
            util_spinePushBindNode(spine,bindNodeName,label)
            spine.m_bindCsbNode = label
        end
        return spine.m_bindCsbNode
    end
    local csbName = "CashTornado_Bonus3_Jackpot.csb"
    local bindNodeName = "gd2"

    local labelCsb = getCsbForSpine(spineNode,csbName,bindNodeName)
    labelCsb:findChild("Node_grand"):setVisible(jackpotType == "grand")
    labelCsb:findChild("Node_mega"):setVisible(jackpotType == "mega")
    labelCsb:findChild("Node_major"):setVisible(jackpotType == "major")
    labelCsb:findChild("Node_minor"):setVisible(jackpotType == "minor")
    labelCsb:findChild("Node_mini"):setVisible(jackpotType == "mini")
    if labelCsb:findChild("X2_"..jackpotType) then
        labelCsb:findChild("X2_"..jackpotType):setVisible(isChengBei)
    end
    

end

function CodeGameScreenCashTornadoMachine:showPowerStrikeJiesuan(overIndex,createBonus2or3List,func)
    if overIndex > #createBonus2or3List then
        -- self:delayCallBack(0.7,function ()
            if not self:checkHasBigWin() then
                --检测大赢
                self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, self.POWER_STRIKE_EFFECT)
            end
            self.darkLayer:runCsbAction("over",false,function ()
                if not self.m_bProduceSlots_InFreeSpin then
                    self.m_bottomUI:notifyTopWinCoin()
                end
                self.darkLayer:setVisible(false)
                self:clearAllTempBonus()
                self:showReelSymbolForPowerStrike()
                if self:checkHasBigWin() then
                    self:showBigWinLightForPower()
                end
                self.power_Strike_state = 1
                if func then
                    func()
                end
            end)
        -- end)
        
        
        return
    end
    local bonusSpine = createBonus2or3List[overIndex]
    local m_bindCsbNode = bonusSpine.m_bindCsbNode

    local actNameList = self:getActNameForTempPig(bonusSpine,self.power_Strike_state)
    local mul = self:getBonusCoinsMul(bonusSpine)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local coins = mul * lineBet
    if overIndex == 1 then
        self:showJueSeWinLineOrBonus()
    end
    --是否是jackpot
    if mul >= 10 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus2_trigger)
        util_spinePlay(bonusSpine, actNameList[3])
        if m_bindCsbNode then
            m_bindCsbNode:runCsbAction("actionframe2",false,function ()
                m_bindCsbNode:runCsbAction("idleframe2",true)
            end)
        end
        local fixPos = self:getRowAndColByPos(bonusSpine.symbolIndex)
        local realSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
        if realSymbol then
            local lab,labSpine = self:getLblCsbOnSymbol(realSymbol,"CashTornado_Bonus3_Jackpot.csb","gd2")
            if lab then
                lab:runCsbAction("idleframe2",true)
            end
        end
        self:delayCallBack(19/30,function ()
            local jackpotIndex = self:getJackpotBonusState(bonusSpine.symbolIndex)
        
            local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
            --展示JackpotWin
            local mul = false
            if self.power_Strike_state > 1 then
                mul = true
            end
            if jackpotIndex == 1 then
                coins = allJackpotCoins["Grand"] or 0
            elseif jackpotIndex == 2 then
                coins = allJackpotCoins["Mega"] or 0
            elseif jackpotIndex == 3 then
                coins = allJackpotCoins["Major"] or 0
            elseif jackpotIndex == 4 then
                coins = allJackpotCoins["Minor"] or 0
            elseif jackpotIndex == 5 then
                coins = allJackpotCoins["Mini"] or 0    
            end
            self.m_bottomUI.m_changeLabJumpTime = 0.2
            local jackpotType = self:getJackpotTypeForIndex(jackpotIndex)
            self:showJackpotView(mul,coins,jackpotType,function ()
                --刷新钱
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_jackpotView_coins_collect) 
                self:playBottomLight(true,coins,true,true)
                self:delayCallBack(0.2,function ()
                    overIndex = overIndex + 1
                    self:showPowerStrikeJiesuan(overIndex,createBonus2or3List,func)
                end)
                
            end)
        end)
        
    else
        -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus1_coins_collect)
        util_spinePlay(bonusSpine, actNameList[3])
        if m_bindCsbNode then
            m_bindCsbNode:runCsbAction("actionframe2",false,function ()
                m_bindCsbNode:runCsbAction("idleframe2",true)
            end)
        end
        local fixPos = self:getRowAndColByPos(bonusSpine.symbolIndex)
        local realSymbol = self:getFixSymbol(fixPos.iY, fixPos.iX)
        if realSymbol then
            local lab,labSpine = self:getLblCsbOnSymbol(realSymbol,"CashTornado_Bonus2_coins.csb","gd")
            if lab then
                lab:runCsbAction("idleframe2",true)
            end
            
        end
        --飞粒子
        self.m_bottomUI.m_changeLabJumpTime = 0.2
        --刷新钱
        self:playBottomLight(false,coins,true,true)
        -- self:showParticleFly(0.3,bonusSpine,coins,function ()
            --actNameList[3],17帧
        self:delayCallBack(0.3,function ()
            overIndex = overIndex + 1
            self:showPowerStrikeJiesuan(overIndex,createBonus2or3List,func)
        end)
            
        -- end)
    end
end

-- 创建飞行粒子
function CodeGameScreenCashTornadoMachine:showParticleFly(time,currNode,coins,func)
    --
    local fly = util_createAnimation("CashTornado_tw_lizi.csb")

    self.m_effectNode:addChild(fly)

    local flyPos = util_convertToNodeSpace(currNode,self.m_effectNode)
    fly:setPosition(flyPos)
    local coinLab = self.m_bottomUI:getNormalWinLabel()
    local endNode = self.m_bottomUI:findChild("font_last_win_value")
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    local particle1 = fly:findChild("Particle_1")
    local particle2 = fly:findChild("Particle_2")
    local animation = {}
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        -- currNode:findChild("m_lb_coins"):setString("")
    end)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        if particle1 then
            particle1:setDuration(-1)     --设置拖尾时间(生命周期)
            particle1:setPositionType(0)   --设置可以拖尾
            particle1:resetSystem()
        end
        if particle2 then
            particle2:setDuration(-1)     --设置拖尾时间(生命周期)
            particle2:setPositionType(0)   --设置可以拖尾
            particle2:resetSystem()
        end
    end)
    animation[#animation + 1] = cc.MoveTo:create(time,endPos)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        if particle1 then
            particle1:stopSystem()--移动结束后将拖尾停掉
        end
        if particle2 then
            particle2:stopSystem()--移动结束后将拖尾停掉
        end
        --刷新钱
        self:playBottomLight(coins,true,true)
        -- fly:setVisible(false)
        
    end)
    animation[#animation + 1] = cc.DelayTime:create(0.3)
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        if func then
            func()
        end
    end)
    animation[#animation + 1] = cc.DelayTime:create(0.5)
    
    animation[#animation + 1] = cc.CallFunc:create(function(  )
        
        fly:removeFromParent()

    end)

    fly:runAction(cc.Sequence:create(animation))

end

-- --------------------------------------------倒计时相关、

function CodeGameScreenCashTornadoMachine:enterSpecialBase(func)
    self:clearCurMusicBg()
    --spin按钮状态
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    --当前角色播动画
    self:showJveSeEnterSpecialBase(function ()
        if tolua.isnull(self.base2StartView) then
            self.base2StartView = util_spineCreate("BaseStart", true, true)
            self.base2StartView:setScale(self.m_machineRootScale)
            self:addChild(self.base2StartView, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
            self.base2StartView:setPosition(display.width * 0.5, display.height * 0.5)
        end
        if tolua.isnull(self.base2StartView2) then
            self.base2StartView2 = util_createAnimation("CashTornado/BaseStart.csb")
            self.base2StartView2:setScale(self.m_machineRootScale)
            self:addChild(self.base2StartView2, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
            self.base2StartView2:setPosition(display.width * 0.5, display.height * 0.5)
        end
        if self.specialBaseData.base_status == 1 then
            if globalMachineController.setIgnorePopCorEnabled then
                globalMachineController:setIgnorePopCorEnabled(false)
            end
            self.isSpecialBase = false
            -- self.m_configData:setBaseIndex(1)
        else
            if globalMachineController.setIgnorePopCorEnabled then
                globalMachineController:setIgnorePopCorEnabled(true)
            end
            self.isSpecialBase = true
            -- self.m_configData:setBaseIndex(2)
        end
        self.noClickLayer:setVisible(true)
        self.base2StartView:setVisible(true)
        self.base2StartView2:setVisible(true)
        
        self:delayCallBack(76/30,function ()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_base_guoChang)
        end)
        self.base2StartView2:runCsbAction("auto",false,function ()
            self.base2StartView2:setVisible(false)
        end)
        util_spinePlay(self.base2StartView, "auto")
        util_spineEndCallFunc(self.base2StartView, "auto", function ()
            self.base2StartView:setVisible(false)
            self.noClickLayer:setVisible(false)
        end)
    
        self:delayCallBack(106/30,function ()
            --切换ui
            self:changeUiForState(PublicConfig.uiState.base2,true)
            --刷新倒计时
            self:updataSpecialBaseTime()
        end)
        self:delayCallBack(130/30,function ()
            --出现风
            if self.jvese2 then
                self.jvese2:setVisible(true)
                util_spinePlay(self.jvese2,"base_start",false)
                util_spineEndCallFunc(self.jvese2, "base_start", function ()
                    util_spinePlay(self.jvese2,"base2",true)
                    if self.specialFeng then
                        gLobalSoundManager:stopAudio(self.specialFeng)
                        self.specialFeng = nil
                    end
                    self.specialFeng = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_special_feng,true)
                    if func then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                        func()
                    end
                    self.isAddEnterBase = false
                    self:resetMusicBg() 
                end)
            end
        end)
    end)
    
end

-- ---
-- --检测m_gameEffects播放effect表中是否有该类型
-- function CodeGameScreenCashTornadoMachine:checkHasGameEffectTypeForCash(effectType)
--     if self.m_gameEffects == nil then
--         return false
--     end
--     local effectLen = #self.m_gameEffects
--     if effectLen == 0 then
--         return false
--     end

--     for i = 1, effectLen, 1 do
--         local value = self.m_gameEffects[i].p_effectOrder
--         if value and value == effectType then
--             return true
--         end
--     end

--     return false
-- end


--添加进入effect
function CodeGameScreenCashTornadoMachine:checkAddSpecialEffect1()
    -- if not self:checkHasGameEffectTypeForCash(self.ENTER_SPECIAL_BASE_GAME_EFFECT) then
        if self.isAddEnterBase == false then
            self.isAddEnterBase = true
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.ENTER_SPECIAL_BASE_GAME_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.ENTER_SPECIAL_BASE_GAME_EFFECT -- 动画类型

            self:sortGameEffects()
            if not self.isInGameEffect then
                self:playGameEffect()
            end
        end
        
    -- end
end

--添加关闭effect
function CodeGameScreenCashTornadoMachine:checkAddSpecialEffect()
    if self.isOverSpecialBase then
        self.isOverSpecialBase = false
        -- if not self:checkHasGameEffectTypeForCash(self.CLOSE_SPECIAL_BASE_GAME_EFFECT) then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.CLOSE_SPECIAL_BASE_GAME_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.CLOSE_SPECIAL_BASE_GAME_EFFECT -- 动画类型
    
            self:sortGameEffects()
            if not self.isInGameEffect then
                self:playGameEffect()
            end
        -- end
    end
    
    
end

-- function CodeGameScreenCashTornadoMachine:removeOverSpecialEffect()
--     if #self.m_gameEffects <= 0 then
--         return
--     end
--     for i, v in ipairs(self.m_gameEffects) do
--         local selfEffect = v
--         if selfEffect then
--             if selfEffect.p_selfEffectType == self.CLOSE_SPECIAL_BASE_GAME_EFFECT then
--                 table.remove(self.m_gameEffects, i)
--             end
--         end
--     end
-- end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenCashTornadoMachine:operaEffectOver()
    CodeGameScreenCashTornadoMachine.super.operaEffectOver(self)
    self.isInGameEffect = false
    
end

function CodeGameScreenCashTornadoMachine:closeSpecialBase(func)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
    self:clearCurMusicBg()
    if self.specialBaseData.base_status == 1 then
        if globalMachineController.setIgnorePopCorEnabled then
            globalMachineController:setIgnorePopCorEnabled(false)
        end
        self.isSpecialBase = false
        -- self.m_configData:setBaseIndex(1)
    else
        if globalMachineController.setIgnorePopCorEnabled then
            globalMachineController:setIgnorePopCorEnabled(true)
        end
        self.isSpecialBase = true
        -- self.m_configData:setBaseIndex(2)
    end
    
    --消失风
    local time = 0
    if not self.m_bProduceSlots_InFreeSpin then
        if self.jvese2 then
            if self.specialFeng then
                gLobalSoundManager:stopAudio(self.specialFeng)
                self.specialFeng = nil
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_base_hide)
            util_spinePlay(self.jvese2,"base_over",false)
            util_spineEndCallFunc(self.jvese2, "base_over", function ()
                self.jvese2:setVisible(false)
            end)
        end
        time = 12/30
    end
    
    self:delayCallBack(time,function ()
        if tolua.isnull(self.pickStartView) then
            self.pickStartView = util_spineCreate("PickStart", true, true)
            self.pickStartView:setScale(self.m_machineRootScale)
            self:addChild(self.pickStartView, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
            self.pickStartView:setPosition(display.width * 0.5, display.height * 0.5)
        end
        self.noClickLayer:setVisible(true)
        self.pickStartView:setVisible(true)
        
        util_spinePlay(self.pickStartView, "actionframe_guochang")
        util_spineEndCallFunc(self.pickStartView, "actionframe_guochang", function ()
            self.pickStartView:setVisible(false)
            self.noClickLayer:setVisible(false)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            if func then
                func()
            end
        end)
        self:delayCallBack(33/30,function ()
            self.countDown:setVisible(false)
            -- self:updataSpecialBaseTime2()
            self:changeUiForState(PublicConfig.uiState.base)
            if self.m_bProduceSlots_InFreeSpin then
                self:showJveSeIdleAct(true)
            else
                self:showJveSeIdleAct(false)
            end 
            self:resetMusicBg() 
        end)
    end)
end

function CodeGameScreenCashTornadoMachine:setDataTimeExtraForSpin()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local start_time = selfData.start_time or nil         --一阶段开始时间戳
    local middle_time = selfData.middle_time or nil      --一阶段结束时间戳/二阶段开始时间戳
    local end_time = selfData.end_time or nil            --二阶段结束时间戳
    local time_now = selfData.time_now or nil           --服务器当前时间戳
    local base_status = selfData.base_status or 1       --当前base状态
    local extra = {start_time = start_time,middle_time = middle_time,end_time = end_time,time_now = time_now,base_status = base_status}
    self:updateSpecialBaseData(extra)
    if self.isSpecialBase then
        self:updateSpecialTimeForInfo()
        self:updataSpecialBaseTime()
    else
        self:updataSpecialBaseTime2()
    end
    
end

function CodeGameScreenCashTornadoMachine:updateSpecialBaseData(extra)
    local start_time = extra.start_time         --一阶段开始时间戳
    local middle_time = extra.middle_time       --一阶段结束时间戳/二阶段开始时间戳
    local end_time = extra.end_time             --二阶段结束时间戳
    local time_now = extra.time_now             --服务器当前时间戳
    local base_status = extra.base_status or 1       --当前base状态

    if start_time then
        self.specialBaseData.start_time = start_time
    end
    if middle_time then
        self.specialBaseData.middle_time = middle_time
    end
    if end_time then
        self.specialBaseData.end_time = end_time
    end
    if time_now then
        self.specialBaseData.time_now = time_now
    end
    if base_status then
        self.specialBaseData.base_status = base_status
    end
end

function CodeGameScreenCashTornadoMachine:updataSpecialBaseTime()
    --当前是特殊base
    if self.specialBaseData.end_time and self.isSpecialBase then
        --显示倒计时
        self.countDown:setVisible(true)
        if not self.countDownshow then
            self.countDownshow = true
            self.countDown:showIdleAct()
        end 
    end
end


function CodeGameScreenCashTornadoMachine:updataSpecialBaseTime2()

        if self.specialBaseData.time_now then
            local leftTime = self.specialBaseData.middle_time / 1000 - self.specialBaseData.time_now / 1000
            if self.specialBaseData.base_status == 2 then
                self.countDown:sendData(1)
                return
            end
            self.m_configData:setBaseIndex(1)
            self.countDownshow = false
            self.countDown:upDataDiscountTime1(leftTime)
        else
            self.m_configData:setBaseIndex(1)
            local leftTime = self.specialBaseData.middle_time / 1000 - util_getCurrnetTime()
            self.countDown:upDataDiscountTime1(leftTime)
        end
        
end

function CodeGameScreenCashTornadoMachine:updateSpecialTimeForInfo()
    if self.specialBaseData.time_now then
        local leftTime = self.specialBaseData.end_time / 1000 - self.specialBaseData.time_now / 1000
        print("剩余秒数:"..leftTime)
        if self.specialBaseData.base_status == 1 then
            self.isOverSpecialBase = true
            self.countDown:sendData(2)
            return
        end
        self.m_configData:setBaseIndex(2)
        self.countDown:upDataDiscountTime(leftTime)
        self.m_pickGameView:upDataDiscountTime(leftTime)
    else
        self.m_configData:setBaseIndex(2)
        local leftTime = self.specialBaseData.end_time / 1000 - util_getCurrnetTime()
        self.m_pickGameView:upDataDiscountTime(leftTime)
        self.countDown:upDataDiscountTime(leftTime)
    end
end

-- ---------------------------------------pick

function CodeGameScreenCashTornadoMachine:showPickStart(func)
    if tolua.isnull(self.pickStartView) then
        self.pickStartView = util_spineCreate("PickStart", true, true)
        self.pickStartView:setScale(self.m_machineRootScale)
        self:addChild(self.pickStartView, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
        self.pickStartView:setPosition(display.width * 0.5, display.height * 0.5)
    end
    self.noClickLayer:setVisible(true)
    self.pickStartView:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_start)
    self:delayCallBack(0.3,function ()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_guoChang)
    end)
    util_spinePlay(self.pickStartView, "actionframe_guochang2")
    util_spineEndCallFunc(self.pickStartView, "actionframe_guochang2", function ()
        self.pickStartView:setVisible(false)
        self.noClickLayer:setVisible(false)
    end)

    self:delayCallBack(33/30,function ()
        --切换ui
        self:changeUiForState(PublicConfig.uiState.pick)
    end)
    self:delayCallBack(60/30,function ()
        if func then
            func()
        end
    end)
end

function CodeGameScreenCashTornadoMachine:triggerBonus4Effect()
    local waitTime = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType then
                if slotNode.p_symbolType == self.SYMBOL_SCORE_BONUS4 then
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                    --创建一个新的播触发
                    local pos = util_convertToNodeSpace(slotNode,self.m_effectNode)
                    local tempBonus = util_spineCreate("Socre_CashTornado_Bonus4", true, true)
                    self.m_effectNode:addChild(tempBonus)
                    tempBonus:setPosition(pos)
                    slotNode:setVisible(false)
                    util_spinePlay(tempBonus, "actionframe")
                    util_spineEndCallFunc(tempBonus, "actionframe", function ()
                        tempBonus:setVisible(false)
                        self:delayCallBack(0.1,function ()
                            tempBonus:removeFromParent()
                        end)
                    end)
                    self:delayCallBack(waitTime - 0.1,function ()
                        slotNode:setVisible(true)
                        slotNode:runAnim("idleframe", false)
                    end)
                end
            end
        end
    end
    return waitTime
end

function CodeGameScreenCashTornadoMachine:showPickEffectView(func)
    self.m_bottomUI.m_changeLabJumpTime = 0.4
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local pick_left_time_list = selfData.pick_left_time_list or {}      --次数
    local pick_list = selfData.pick_list or {}
    if table_length(pick_list) == 0 then
        if func then
            func()
        end
        return
    end
    self:clearCurMusicBg()
    self:clearWinLineEffect()
    local pickData = {pick_left_time_list = pick_left_time_list,pick_list = pick_list}
    self.isPickGame = true
    --触发动画
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_special_pick_trigger)
    local waitTime = self:triggerBonus4Effect()
    self:delayCallBack(waitTime,function ()
        self:showPickStart(function ()
            self:removeSoundHandler()
            self:resetMusicBg(nil,"CashTornadoSounds/music_CashTornado_pick.mp3")
            if self.specialFeng then
                gLobalSoundManager:stopAudio(self.specialFeng)
                self.specialFeng = nil
            end
            -- self.specialFeng = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_special_feng,true)
            self.m_pickGameView:setResultDataAry(pickData)
            self.m_pickGameView:showView(function ()
                self:changeJackpotBarParent(false)
                self:changejackpotBarShow(true)
                self:showPickOver()
                self.m_bottomUI.m_changeLabJumpTime = nil
                if not self:checkHasBigWin() then
                    --检测大赢
                    self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, self.PICK_GAME_EFFECT)
                end
                self:delayCallBack(0.5,function ()
                    self:resetMusicBg()
                    if self.specialFeng then
                        gLobalSoundManager:stopAudio(self.specialFeng)
                        self.specialFeng = nil
                    end
                    self.specialFeng = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CashTornado_special_feng,true)
                    if self.isOverSpecialBase then
                        self.countDown:sendData(2)
                    end
                    if not self.m_bProduceSlots_InFreeSpin then
                        self.m_bottomUI:notifyTopWinCoin()
                    end
                    if func then
                        func()
                    end
                end)
                
            end)
        end)
    end)
    
    
end

function CodeGameScreenCashTornadoMachine:showPickOver(func)
    --刷新base ui
    if self.isSpecialBase then
        self:changeUiForState(PublicConfig.uiState.base2)
    else
        self:changeUiForState(PublicConfig.uiState.base)
    end
end

function CodeGameScreenCashTornadoMachine:changeParentForPick(node,isChange)
    if isChange then
        
    else
        
    end
    util_changeNodeParent(self:findChild("Node_feng2"),node)
    self:delayCallBack(40/30,function ()
        util_changeNodeParent(self.m_pickGameView:findChild("bg"),node)
        node:setVisible(false)
    end)
end

-- ----------------------------------jackpot

function CodeGameScreenCashTornadoMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeCashTornadoSrc.CashTornadoJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_Jackpot"):addChild(self.m_jackPotBarView) --修改成自己的节点  
    local ratio = display.height / display.width
    if ratio == 1228 / 768 then  
        self.m_jackPotBarView:setPositionY(5)
    elseif ratio == 1530 / 768 then
        self.m_jackPotBarView:setPositionY(65)
    elseif ratio == 1970 / 768 then
        self.m_jackPotBarView:setPositionY(105)
    end
end

function CodeGameScreenCashTornadoMachine:getJackpotCoinsForType(jackpotType)
    local curReward = 0
    local jackpotReward = self.m_runSpinResultData.p_jackpotCoins
    if jackpotType == "grand" then
        curReward = jackpotReward["Grand"]
    elseif jackpotType == "mega" then
        curReward = jackpotReward["Mega"]
    elseif jackpotType == "major" then
        curReward = jackpotReward["Major"]
    end
    return curReward
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenCashTornadoMachine:showJackpotView(mul,coins,jackpotType,func)
    local view = util_createView("CodeCashTornadoSrc.CashTornadoJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        machine = self,
        mul = mul,
        func = function(  )
            if type(func) == "function" then
                func()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

function CodeGameScreenCashTornadoMachine:changejackpotBarShow(isShow)
    self.m_jackPotBarView:hideShowNode(isShow)
end

function CodeGameScreenCashTornadoMachine:changeJackpotBarParent(isChange)
    if isChange then
        util_changeNodeParent(self.m_pickGameView:findChild("Node_Jackpot"),self.m_jackPotBarView)
        self.m_jackPotBarView:setPosition(cc.p(0,0))
        local ratio = display.height / display.width
        if ratio == 1530 / 768 then
            self.m_jackPotBarView:setPositionY(65)
        elseif ratio == 1970 / 768 then
            self.m_jackPotBarView:setPositionY(295)
        end
        self.m_jackPotBarView:showIdleAct()
    else
        util_changeNodeParent(self:findChild("Node_Jackpot"),self.m_jackPotBarView)
        self.m_jackPotBarView:setPosition(cc.p(0,0))
        local ratio = display.height / display.width
        if ratio == 1228 / 768 then  
            self.m_jackPotBarView:setPositionY(5)
        elseif ratio == 1530 / 768 then
            self.m_jackPotBarView:setPositionY(65)
        elseif ratio == 1970 / 768 then
            self.m_jackPotBarView:setPositionY(105)
        end
        self.m_jackPotBarView:showIdleAct()
    end
end

--[[
    BottomUI接口
]]
function CodeGameScreenCashTornadoMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenCashTornadoMachine:getCurBottomWinCoins()
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

function CodeGameScreenCashTornadoMachine:playBottomLight(isJackpot,_endCoins, isAdd,isShowAct)
    
    if isShowAct then
        if not isJackpot then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_bonus1_coins_collect_fankui)
        end
        
        self.m_bottomUI:playCoinWinEffectUI()
    end
    
    if self.power_Strike_state > 1 then
        _endCoins = _endCoins * 2
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    local bottomWinCoin = self.powerStrikeCoins
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
        if bottomWinCoin == 0 then
            local selfData = self.m_runSpinResultData.p_selfMakeData or {}
            local bonus_left_win = selfData.bonus_left_win or 0
            local bonus_right_win = selfData.bonus_right_win or 0
            local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
            bottomWinCoin = freeSpinWinCoin - bonus_left_win - bonus_right_win
        end  
    end
    if isAdd then
        --self:getCurBottomWinCoins()
        
        local totalWinCoin = bottomWinCoin + tonumber(_endCoins)
        self.powerStrikeCoins = totalWinCoin
        self:setLastWinCoin(totalWinCoin)
        self:updateBottomUICoins(bottomWinCoin, totalWinCoin,isNotifyUpdateTop,true)
    else
        self:setLastWinCoin(tonumber(_endCoins))
        self:updateBottomUICoins(0, tonumber(_endCoins),isNotifyUpdateTop, true)
    end

end

function CodeGameScreenCashTornadoMachine:netWorklineLogicCalculate()
    self:resetDataWithLineLogic()

    local isFiveOfKind = self:lineLogicWinLines()

    -- if isFiveOfKind then
    --     self:addAnimationOrEffectType(GameEffect.EFFECT_FIVE_OF_KIND)
    -- end

    -- 根据features 添加具体玩法
    self:MachineRule_checkTriggerFeatures()
    self:staticsQuestEffect()
end

--[[
    获取小块spine槽点上绑定的csb节点
    csbName csb文件名称
    bindNodeName 槽点名称
]]
function CodeGameScreenCashTornadoMachine:getLblCsbOnSymbol(symbolNode,csbName,bindNodeName)
    if tolua.isnull(symbolNode) then
        return
    end
    
    local symbolType = symbolNode.p_symbolType
    if not symbolType then
        return
    end

    local aniNode = symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and tolua.isnull(spine.m_bindCsbNode) then

        local label = util_createAnimation(csbName)
        util_spinePushBindNode(spine,bindNodeName,label)
        spine.m_bindCsbNode = label
    end

    if not spine then
        return nil,nil
    end

    return spine.m_bindCsbNode,spine
end

return CodeGameScreenCashTornadoMachine