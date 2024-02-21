---
-- island li
-- 2019年1月26日
-- CodeGameScreenCoinConiferMachine.lua
-- 
-- 玩法：1:scatter收集，概率触发superFree(三种buff结合)
    --  2:触发free后三选一
    --  3:buff1:棋盘升行至6行，每次连线会有成倍，奖励6次free
    --  4:buff2:掉落bonus，可翻出四档jackpot碎片或金额，奖励12次free
    --  5:buff3:去除所有低级图标，bonus可翻出free次数或金额，奖励6次free
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 

--三种free：0：升行和成倍；1：jackpot（收集中jackpot）；2：去除低级图标；3：super
local PublicConfig = require "CoinConiferPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCoinConiferMachine = class("CodeGameScreenCoinConiferMachine", BaseNewReelMachine)

CodeGameScreenCoinConiferMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenCoinConiferMachine.SYMBOL_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1       --钱和次数
CodeGameScreenCoinConiferMachine.SYMBOL_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2       --jackpot


-- 自定义动画的标识
-- CodeGameScreenCoinConiferMachine.COLLECT_SCATTER_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1     --收集scatter
CodeGameScreenCoinConiferMachine.NO_SPIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 1
CodeGameScreenCoinConiferMachine.COLLECT_BONUS_EFFECT = GameEffect.EFFECT_SELF_EFFECT + 2        --收集bonus获得jackpot、bonus钱数或free次数

CodeGameScreenCoinConiferMachine.m_iReelMinRowNum = 4

CodeGameScreenCoinConiferMachine.moveLayerName = "Panel_move"
CodeGameScreenCoinConiferMachine.moveTop1Name = "Node_top1"
CodeGameScreenCoinConiferMachine.moveTop2Name = "Node_top2"


-- 构造函数
function CodeGameScreenCoinConiferMachine:ctor()
    CodeGameScreenCoinConiferMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CoinConiferSrc.CoinConiferSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("CoinConiferLongRunControl",self) 


    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true

    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效

    self.curTreeLevel = 1

    self.freeType = 0

    self.buff3Coins = 0

    self.isClickQuickStop2 = false
    self.isClickQuickStop1 = false

    self.collectBonusEffect = nil

    self.buffTwoOrThreeIndex1 = 0
    self.buffTwoOrThreeIndex2 = 0
    self.stopBtnIndex = 0

    -- self.treeLevelForBet = {}

    self.scatterNum = 0

    self.isHaveJackpot = {false,false,false,false}

    self.isQuickStop = false
    self.isShowBulingForSc = false

    self.isShowYuGao = false


    self.curScatterBulingNum = 0
    self.totalScatterBulingNum = 0
    --init
    self:initGame()
end

function CodeGameScreenCoinConiferMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("CoinConiferConfig.csv", "LevelCoinConiferConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCoinConiferMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CoinConifer"  
end

function CodeGameScreenCoinConiferMachine:getBottomUINode()
    return "CoinConiferSrc.CoinConiferBottomNode"
end

function CodeGameScreenCoinConiferMachine:initUI()

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    self.m_collectEffectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_collectEffectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_collectEffectNode:setPosition(cc.p(0,0))

    self.treeNode = cc.Node:create()
    self:findChild("root"):addChild(self.treeNode)

    self.m_collect1Node = cc.Node:create()
    self:addChild(self.m_collect1Node,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)

    self.scheduleNode = cc.Node:create()
    self:addChild(self.scheduleNode)

    self.bonusCollectNode = cc.Node:create()
    self:addChild(self.bonusCollectNode)

    self.bonusFanNode = cc.Node:create()
    self:addChild(self.bonusFanNode)

    self.changeLevelNode = cc.Node:create()
    self:addChild(self.changeLevelNode)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView() 
    self:initJackPotBarForFreeView()
    self:initJackPotBarForSuperFreeView()
    self:addChooseView()
    self:addDarkView()


    --成倍栏五倍光
    self.superFreeMulFive = util_createAnimation("CoinConifer_chengbei_xuli.csb")
    self:findChild("Node_super_multbar_ef"):addChild(self.superFreeMulFive)
    self.superFreeMulFive:setVisible(false)

    --成倍栏
    self.superFreeMul = util_createView("CoinConiferSrc.CoinConifermultSuperBarView",self)
    self:findChild("Node_super_multbar"):addChild(self.superFreeMul)
    self.superFreeMul:setVisible(false)

    self.tree = util_createView("CoinConiferSrc.CoinConiferBigTreeView",self)
    self:findChild("Node_tree"):addChild(self.tree)
    self:showBigTreeIdle()

    self:changeUiState(PublicConfig.uiState.base)

    self.m_qipan_size = self:findChild("Panel_move"):getContentSize()
    self.m_ui_qipan_topY = self:findChild("Node_top1"):getPositionY()
    self.lineKuangDiffer = self:findChild("Node_lineLeft2"):getPositionY() - self:findChild("Node_lineLeft1"):getPositionY()

    self:initReelRowAndOnceClip(self.m_iReelMinRowNum)

    self.m_skip_click1 = self:findChild("Panel_kuaiting4x5")
    self.m_skip_click1:setVisible(false)
    self:addClick(self.m_skip_click1)
    self.m_skip_click2 = self:findChild("Panel_kuaiting6x5")
    self.m_skip_click2:setVisible(false)
    self:addClick(self.m_skip_click2)

    self.fanBonusNode = cc.Node:create()
    self:addChild(self.fanBonusNode)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenCoinConiferMachine:initSpineUI()

    self.bottomEffect = util_spineCreate("CoinConifer_totalwin", true, true)
    self.m_bottomUI.coinWinNode:addChild(self.bottomEffect)
    self.bottomEffect:setVisible(false)
end


function CodeGameScreenCoinConiferMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound( "CoinConiferSounds/music_CoinConifer_enter.mp3" )
    end)
end

function CodeGameScreenCoinConiferMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCoinConiferMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local collectLevel = self:getTreeLevelForBet()
    self.curTreeLevel = 1
    if collectLevel then
        self.curTreeLevel = collectLevel
    end
    self:showBigTreeIdle()
end

function CodeGameScreenCoinConiferMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self:initCloumnSlotNodesByNetData()
    self:showFlipOpenForDisconnection()
end

function CodeGameScreenCoinConiferMachine:addObservers()
    CodeGameScreenCoinConiferMachine.super.addObservers(self)
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
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            local soundTime = soundIndex
            if self.m_bottomUI  then
                soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
            end
        end
        
        local soundName = PublicConfig.SoundConfig["sound_CoinConifer_base_winLine"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_CoinConifer_free_winLine"..soundIndex]
            if self.freeType == 3 then
                soundName = PublicConfig.SoundConfig["sound_CoinConifer_superfree_winLine"..soundIndex]
            end
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenCoinConiferMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCoinConiferMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    self.scheduleNode:stopAllActions()
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCoinConiferMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_CoinConifer_Bonus1"
    end

    if symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_CoinConifer_Bonus2"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCoinConiferMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCoinConiferMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_BONUS_2,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCoinConiferMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self.m_baseFreeSpinBar:initTotalCount()
        self.m_baseFreeSpinBar:changeFreeSpinTotalCount()
        local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
        local freeType = freespinExtra.freeType
        self.freeType = freeType
        if self.freeType ~= 0 then
            self.m_bottomUI.m_changeLabJumpTime = 0.2
        end

    end 
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or -1
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE and freeSpinsLeftCount ~= freeSpinsTotalCount then
        if self.freeType == 1 or self.freeType == 2 then
            self:initReelRowAndOnceClip(self.m_iReelMinRowNum)
            -- self:runCsbAction("idle1",true)
        else
            self:initReelRowAndOnceClip(self.m_iReelRowNum)
            -- self:runCsbAction("idle2",true)
        end
        if self.freeType == 0 then
            self:showTwoDragon(false)
            self:changeUiState(PublicConfig.uiState.buffFree1)
        elseif self.freeType == 1 then
            self:changeUiState(PublicConfig.uiState.buffFree2)
            self.m_jackPotBarFreeView:resetView(true)
        elseif self.freeType == 2 then
            self:changeUiState(PublicConfig.uiState.buffFree3)
        elseif self.freeType == 3 then
            self:showMultbarForSuper(false)
            self:changeUiState(PublicConfig.uiState.superFree)
            self.m_jackPotBarSuperFreeView:resetView(true)
        end
        
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCoinConiferMachine:MachineRule_SpinBtnCall()
    self.scatterNum = 0
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()

    self.buff3Coins = 0

    self.collectBonusEffect = nil
    
    self.buffTwoOrThreeIndex1 = 0
    self.buffTwoOrThreeIndex2 = 0
    self.stopBtnIndex = 0

    self.isHaveJackpot = {false,false,false,false}

    self.isClickQuickStop2 = false
    self.isClickQuickStop1 = false

    self.isQuickStop = false
    self.isShowBulingForSc = false

    self.curScatterBulingNum = 0
    self.totalScatterBulingNum = 0

    self.isShowYuGao = false

    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenCoinConiferMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCoinConiferMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 
    local scList = self:setScatterListForCol(reelCol)
    local collectLevel = self:getTreeLevelForBet()
    if table_length(scList) > 0 then
        self:showCollectScaterForCol(scList,collectLevel)
    end
end

--[[
    滚轮停止
]]
function CodeGameScreenCoinConiferMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenCoinConiferMachine.super.slotReelDown(self)
    -- if self:getGameSpinStage() == QUICK_RUN then
    --     self:changeTreeLevelForSlotDown()
    -- end
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCoinConiferMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local SCposition = selfData.SCposition or {}

    -- if table_length(SCposition) > 0 then
        
    --     -- 自定义动画创建方式
    --     local selfEffect = GameEffectData.new()
    --     selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    --     selfEffect.p_effectOrder = self.COLLECT_SCATTER_EFFECT
    --     self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    --     selfEffect.p_selfEffectType = self.COLLECT_SCATTER_EFFECT -- 动画类型
    -- end
    
    local feautes = self.m_runSpinResultData.p_features or {}
    local collectLevel = self:getTreeLevelForBet()
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        --table_length(SCposition) > 0
        if #feautes > 1 or collectLevel == 4 or collectLevel ~= self.curTreeLevel then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.NO_SPIN_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.NO_SPIN_EFFECT -- 动画类型
        end
    end

    local bonusList = self:checkBonusListForBonusIconAndMysteryIcon()
    if table_length(bonusList) > 0 and self.m_bProduceSlots_InFreeSpin then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
    end

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCoinConiferMachine:MachineRule_playSelfEffect(effectData)

    -- if effectData.p_selfEffectType == self.COLLECT_SCATTER_EFFECT then
    --     -- 记得完成所有动画后调用这两行
    --     -- 作用：标识这个动画播放完结，继续播放下一个动画
    --     --是否快停并且有落地
    --     local time = 0.2
    --     if self.isQuickStop and self.isShowBulingForSc then
    --         time = 0.5
    --     end
    --     self:delayCallBack(time,function ()
    --         self:showCollectScaterEffect(function ()
    --             effectData.p_isPlay = true
    --             self:playGameEffect()
    --         end)
    --     end)
    -- end


    if effectData.p_selfEffectType == self.NO_SPIN_EFFECT then
        
        self:showNoSpinEffect(function ()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then
        
        self:delayCallBack(0.5,function ()
            self.collectBonusEffect = effectData
            self:flippingBonusForBuffTwoAndThree2(function ()
                self:nextEffectShow()
            end)
        end)
        
    end
    
    return true
end



function CodeGameScreenCoinConiferMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenCoinConiferMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenCoinConiferMachine:playScatterTipMusicEffect()
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
function CodeGameScreenCoinConiferMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenCoinConiferMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenCoinConiferMachine:checkRemoveBigMegaEffect()
    CodeGameScreenCoinConiferMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenCoinConiferMachine:getShowLineWaitTime()
    local time = CodeGameScreenCoinConiferMachine.super.getShowLineWaitTime(self)
    local winLines = self.m_reelResultLines or {}
    local lineValue = winLines[1] or {}
    if #winLines == 1 and lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        time = 0
    end

    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

function CodeGameScreenCoinConiferMachine:scaleMainLayer()
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

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenCoinConiferMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CoinConiferSrc.CoinConiferFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenCoinConiferMachine:showFreeSpinStart(num, func, isAuto)
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local freeType = freespinExtra.freeType
    -- self.freeType = freeType
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    local view = nil
    if freeType == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_superStart_show)
        view = self:showDialog("SuperFreeSpinStart", ownerlist, func)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_freeStart_show)
        if isAuto then
            view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
        else
            view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
        end
        view:findChild("mult"):setVisible(freeType == 0) 
        view:findChild("jackpot"):setVisible(freeType == 1)  
        view:findChild("renewal"):setVisible(freeType == 2) 
        
        
    end
    -- local viewTree = util_spineCreate("CoinConifer_jackpot", true, true)
    -- view:findChild("Node_spine"):addChild(viewTree)
    -- util_spinePlay(viewTree,"idle_tanban",true)

    local lighting = util_createAnimation("CoinConifer/FreeSpinStart_light.csb")
    if view:findChild("Node_light") then
        view:findChild("Node_light"):addChild(lighting)
        lighting:runCsbAction("idle",true)
    end
    view:setBtnClickFunc(function()
        self.m_darkView:showOverView(function ()
            self.m_darkView:setVisible(false)
        end)
        if freeType == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_superStart_hide)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_freeStart_hide)
        end
        
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_click)
        -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_in_guoChange)
    end)
    
    view:findChild("root"):setScale(self.m_machineRootScale)
    return view
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenCoinConiferMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("CoinConiferSounds/music_CoinConifer_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
            effectData.p_isPlay = true
            self:playGameEffect()
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                if self.freeType == 3 then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_enterSuper_guochang)
                else
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_enterFree_guochang)
                end
                
                self:showToFreeGuoChang(function ()
                    if self.freeType ~= 0 then
                        self.m_bottomUI.m_changeLabJumpTime = 0.2
                    end
                    
                    self.m_baseFreeSpinBar:initTotalCount()
                    self.m_baseFreeSpinBar:changeFreeSpinTotalCount()
                    --修改ui
                    if self.freeType == 0 then
                        self:changeUiState(PublicConfig.uiState.buffFree1)
                    elseif self.freeType == 1 then
                        self:changeUiState(PublicConfig.uiState.buffFree2)
                        self.m_jackPotBarFreeView:resetView()
                    elseif self.freeType == 2 then
                        self:changeUiState(PublicConfig.uiState.buffFree3)
                    elseif self.freeType == 3 then
                        self:changeUiState(PublicConfig.uiState.superFree)
                        self.m_jackPotBarSuperFreeView:resetView()
                    end
                    
                    --先停止刷钱调度器，更新顶部的钱，然后清理底栏的钱数
                    self.m_bottomUI:resetWinLabel()
                    self.m_bottomUI:notifyTopWinCoin()
                    self.m_bottomUI:checkClearWinLabel()
                end,function ()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()  
                end,true)
                     
            end)
        end
    end

    -- self:delayCallBack(0.5,function()
        showFSView()  
    -- end)    
end

function CodeGameScreenCoinConiferMachine:triggerFreeSpinCallFun()
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

function CodeGameScreenCoinConiferMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    if self.freeType == 3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_superOver_show)
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_freeOver_show)
    end
    
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_coins"] = util_formatCoinsLN(coins, 30)
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    util_setCascadeOpacityEnabledRescursion(view:findChild("Node_light"), true)
    util_setCascadeColorEnabledRescursion(view:findChild("Node_light"), true)
    local lighting = util_createAnimation("CoinConifer/FreeSpinStart_light.csb")
    if view:findChild("Node_light") then
        view:findChild("Node_light"):addChild(lighting)
        lighting:runCsbAction("idle",true)
    end
    view:findChild("root"):setScale(self.m_machineRootScale)
    view:setBtnClickFunc(function()
        if self.freeType == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_superOver_hide)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_freeOver_hide)
        end
        
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_click)
        -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_freeGame_in_guoChange)
    end)
    return view
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenCoinConiferMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("CoinConiferSounds/music_CoinConifer_over_fs.mp3")
    self:clearWinLineEffect()
    self:checkChangeBaseParent()
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0
    local strCoins = util_formatCoinsLN(freeSpinWinCoin, 30)
    local view = self:showFreeSpinOver(
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            if self.freeType == 3 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_superOver_guochang)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_exitFree_guochang)
            end
            
            self:showToFreeGuoChang(function ()
                if self.freeType == 3 then
                    self.curTreeLevel = 1
                    self:resetTreeLevel()
                end
                if self.freeType == 0 then
                    --双龙隐藏
                    if not tolua.isnull(self.dragon1) then
                        self.dragon1:setVisible(false)
                    end
                    if not tolua.isnull(self.dragon2) then
                        self.dragon2:setVisible(false)
                    end
                    if not tolua.isnull(self.dragon3) then
                        self.dragon3:setVisible(false)
                    end
                    if not tolua.isnull(self.dragon4) then
                        self.dragon4:setVisible(false)
                    end
                    if not tolua.isnull(self.dragon5) then
                        self.dragon5:setVisible(false)
                    end
                    if not tolua.isnull(self.dragon6) then
                        self.dragon6:setVisible(false)
                    end
                    --六行变为四行
                    self:initReelRowAndOnceClip(self.m_iReelMinRowNum)
                    self.superFreeMul:setVisible(false)
                    
                elseif self.freeType == 3 then
                    --六行变为四行
                    self:initReelRowAndOnceClip(self.m_iReelMinRowNum)
                    self.superFreeMul:setVisible(false)
                end
                self:changeUiState(PublicConfig.uiState.base)
                local collectLevel = self:getTreeLevelForBet()
                if collectLevel then
                    self.curTreeLevel = collectLevel
                end
                self:showBigTreeIdle()
            end,function ()
                self:triggerFreeSpinOverCallFun()
                self.freeType = 5
            end,false)
            
            
        end
    )
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},641)  
    view:findChild("mult"):setVisible(self.freeType == 0)  
    view:findChild("jackpot"):setVisible(self.freeType == 1)  
    view:findChild("renewal"):setVisible(self.freeType == 2)  
    view:findChild("super"):setVisible(self.freeType == 3)  
    
end

function CodeGameScreenCoinConiferMachine:showEffect_FreeSpin(effectData)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
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
        local waitTime = 0
        -- 播放提示时播放音效
        if self.freeType ~=3 then
            self:playScatterTipMusicEffect()
            for iCol = 1, self.m_iReelColumnNum do
                for iRow = 1, self.m_iReelRowNum do
                    if iRow ~= 1 or iRow ~= 2 then
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
            end
        end
        -- self:setCurrSpinMode(FREE_SPIN_MODE)
        self:delayCallBack(waitTime,function ()
            -- self.m_chooseFSView:setVisible(true)
            self.m_darkView:setVisible(true)
            self.m_darkView:showIdleForReset()
            self.m_darkView:showBigTreeActForChoose()
            if self.freeType == 3 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_enter_choose)
                self:showToFreeGuoChang2(function ()
                    
                    self:delayCallBack(3,function ()
                        self:showChooseView(function ()
                            self:showFreeSpinView(effectData)
                        end)
                    end)
                end,function ()
                    
                end)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_enter_choose)
                self:showToFreeGuoChang(function ()
                    self:delayCallBack(3,function ()
                        self:showChooseView(function ()
                            self:showFreeSpinView(effectData)
                        end)
                    end)
                end,function ()
                    
                end,false)
            end
            
            
            
        end)
        
    
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

---
    -- 逐条线显示 线框和 Node 的actionframe
    --
function CodeGameScreenCoinConiferMachine:showLineFrameByIndex(winLines,frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        return
    end
    self.super.showLineFrameByIndex(self, winLines, frameIndex)    
end

---
    -- 显示所有的连线框
    --
function CodeGameScreenCoinConiferMachine:showAllFrame(winLines)
    local tempLineValue = {}
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN then
            table.insert(tempLineValue, lineValue)
        end
    end
    self.super.showAllFrame(self, tempLineValue)    
    if self.m_bProduceSlots_InFreeSpin and #winLines > 0 then
        if self.freeType == 0 or self.freeType == 3 then
            self.superFreeMul:showMulForWinLine()
        end
    end
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenCoinConiferMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local freeType = self.freeType
        if not freeType then
            freeType = 0
        end
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(freeType, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas
    if parentData.beginReelIndex > #reelDatas then
        parentData.beginReelIndex = nil
    end

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function CodeGameScreenCoinConiferMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)

    parentData.symbolType = symbolType

    parentData.order = self:getBounsScatterDataZorder(parentData.symbolType)
    parentData.order = parentData.order - parentData.beginReelIndex
end

function CodeGameScreenCoinConiferMachine:getFsTriggerSlotNode(parentData, symPosData)
    return self:getFixSymbol(symPosData.iY, symPosData.iX)    
end

--普通jackpot
function CodeGameScreenCoinConiferMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CoinConiferSrc.CoinConiferJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_base_jackpotbar"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--jackpotFree
function CodeGameScreenCoinConiferMachine:initJackPotBarForFreeView()
    self.m_jackPotBarFreeView = util_createView("CoinConiferSrc.CoinConiferColofulJackPotBar")
    self.m_jackPotBarFreeView:initMachine(self)
    self:findChild("Node_jackpot_jackpotbar"):addChild(self.m_jackPotBarFreeView) --修改成自己的节点
    self.m_jackPotBarFreeView:setVisible(false)   
end

--superFree
function CodeGameScreenCoinConiferMachine:initJackPotBarForSuperFreeView()
    self.m_jackPotBarSuperFreeView = util_createView("CoinConiferSrc.CoinConiferSuperColofulJackPotBar")
    self.m_jackPotBarSuperFreeView:initMachine(self)
    self:findChild("Node_super_jackpotbar"):addChild(self.m_jackPotBarSuperFreeView) --修改成自己的节点
    self.m_jackPotBarSuperFreeView:setVisible(false)   
end

function CodeGameScreenCoinConiferMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["135"] ,["symbolType"] = {90}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态    
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenCoinConiferMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenCoinConiferMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenCoinConiferMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if symbolCfg[1] and self:checkSymbolBulingAnimPlay(_slotNode) then
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
                --2.播落地动画
                self:playBulingAnimFunc(_slotNode,symbolCfg)
            end
        end
    end
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenCoinConiferMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                --isPlayTipAnima
                if self:isPlayTipAnimaForCoinConifer(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    self.isShowBulingForSc = true
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

function CodeGameScreenCoinConiferMachine:isPlayTipAnimaForCoinConifer(matrixPosY, matrixPosX, node)
    -- if matrixPosY == 1 then
        return true
    -- end
    -- local scatterNum = 0
    -- for iCol = 1 ,(matrixPosY - 1) do
    --     for iRow = 1,self.m_iReelRowNum do
    --         local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
    --         if not (iRow == 5 or iRow == 6) then
    --             if symbolType then
    --                 if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
    --                     scatterNum = scatterNum + 1  
    --                 end
    --             end
    --         end
            
            
    --     end
        
    -- end

    -- if matrixPosY == 3 then
    --     if scatterNum >= 1 then
    --         return true
    --     end
    -- elseif matrixPosY == 5 then
    --     if scatterNum >= 2 then
    --         return true
    --     end
    -- end

    -- return false
end

function CodeGameScreenCoinConiferMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)    
end

function CodeGameScreenCoinConiferMachine:getSoundPathForScatterNum()
    local path = nil
    if self.scatterNum == 1 then
        path = PublicConfig.SoundConfig.sound_CoinConifer_scatter_buling1
    elseif self.scatterNum == 2 then
        path = PublicConfig.SoundConfig.sound_CoinConifer_scatter_buling2
    else
        path = PublicConfig.SoundConfig.sound_CoinConifer_scatter_buling3
    end
    return path
end

function CodeGameScreenCoinConiferMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            local iCol = _slotNode.p_cloumnIndex
            local iRow = _slotNode.p_rowIndex
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and (iRow ~= 1 or iRow ~= 2) then
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

function CodeGameScreenCoinConiferMachine:playQuickStopBulingSymbolSound(_iCol)
    if self:getGameSpinStage() == QUICK_RUN then
        if _iCol == self.m_iReelColumnNum then
            local soundIds = {}
            local bulingDatas = self.m_symbolQsBulingSoundArray
            for soundType, soundPaths in pairs(bulingDatas) do
                local soundPath = soundPaths[#soundPaths]
                if self.scatterNum < 3 then
                    soundPath = PublicConfig.SoundConfig.sound_CoinConifer_scatter_buling1
                end
                local soundId = gLobalSoundManager:playSound(soundPath)
                table.insert(soundIds, soundId)
            end

            return soundIds
        end
    end
end

function CodeGameScreenCoinConiferMachine:quicklyStopReel(colIndex)
    CodeGameScreenCoinConiferMachine.super.quicklyStopReel(self,colIndex)
    self.isQuickStop = true
end

--[[
        是否播放期待动画
    ]]
function CodeGameScreenCoinConiferMachine:isPlayExpect(reelCol)
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
function CodeGameScreenCoinConiferMachine:showFeatureGameTip(_func)
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
function CodeGameScreenCoinConiferMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = false
    --动效执行时间
    local aniTime = 3
    --树播预告
    self:showTreeForYugao()
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
    end

    if type(func) == "function" then
        func()
    end    
end

function CodeGameScreenCoinConiferMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines
    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if isNotifyUpdateTop then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    else
        local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
        local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0      --fs总赢钱
        local bonusCoin = freespinExtra.bonusCoin or 0      --收集钱bonus总赢钱
        local selfData = self.m_runSpinResultData.p_selfMakeData or {}
        local linewin = selfData.linewin or 0       --连线钱
        if linewin > 0 then
            self:setLastWinCoin(freeSpinWinCoin)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {linewin, isNotifyUpdateTop})
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
        end
    end
end

---
-- 初始化上次游戏状态数据
--
function CodeGameScreenCoinConiferMachine:initGameStatusData(gameData)
    CodeGameScreenCoinConiferMachine.super.initGameStatusData(self, gameData)
    local gameConfig = gameData.gameConfig or {}
    local extra = gameConfig.extra or {}
end

function CodeGameScreenCoinConiferMachine:getTreeLevelForBet()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local collectLevel = selfData.collectLevel or 1
    return collectLevel
end

function CodeGameScreenCoinConiferMachine:requestSpinResult()
    local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or -1
    local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    if self:getCurrSpinMode() == FREE_SPIN_MODE and freeSpinsLeftCount == freeSpinsTotalCount then
        self:showUpReelEffect(function ()
            CodeGameScreenCoinConiferMachine.super.requestSpinResult(self)
        end)
    else
        CodeGameScreenCoinConiferMachine.super.requestSpinResult(self)
    end
end

function CodeGameScreenCoinConiferMachine:updateNetWorkData()
    local p_features = self.m_runSpinResultData.p_features or {}
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local freeType = freespinExtra.freeType
    
    if #p_features > 1 and p_features[2] == 1 then
        self.freeType = freeType
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE and (self.freeType == 0 or self.freeType == 3) then
        --成倍变化
        self:changeChengBeiForBuff1(function ()
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
    end
    self:setNewCollectNum()
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenCoinConiferMachine:showEffect_runBigWinLightAni2(winCoin)

    --不该播该光效
    if not self.m_isAddBigWinLightEffect then
        return 
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
    
    self:showBigWinLight()

end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenCoinConiferMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)
    self:showBigWinAct()
    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

-- 重置当前背景音乐名称
function CodeGameScreenCoinConiferMachine:resetCurBgMusicName(musicName)
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
        if self.freeType == 3 then
            self.m_currentMusicBgName = "CoinConiferSounds/music_CoinConifer_superFree_bg.mp3"
        end
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end
end


function CodeGameScreenCoinConiferMachine:changeReelData(rowNum)
    self.m_stcValidSymbolMatrix = self:getValidSymbolMatrixArray()
    for i = 1, self.m_iReelColumnNum do
        --变更每列小块的数量
        self:changeReelRowNum(i,rowNum,true)
        local columnData = self.m_reelColDatas[i]
        columnData.p_slotColumnHeight = self.m_SlotNodeH * rowNum
        columnData:updateShowColCount(rowNum)
    end
    self.m_fReelHeigth = self.m_SlotNodeH * rowNum  
end

--[[
        @desc: 静态变更滚轮行数
        --@rowNum:当前显示的行数
        @return:nil
    ]]
function CodeGameScreenCoinConiferMachine:initReelRowAndOnceClip(rowNum)

    local addHeights = (rowNum - self.m_iReelMinRowNum) * self.m_SlotNodeH
    self:findChild("Panel_move"):setContentSize(cc.size(self.m_qipan_size.width, self.m_qipan_size.height + addHeights))
    self:findChild("Node_top1"):setPositionY(self.m_ui_qipan_topY + addHeights)
    self:findChild("CoinConifer_line_you_30"):setVisible(rowNum == self.m_iReelMinRowNum)
    self:findChild("CoinConifer_line_you_60"):setVisible(rowNum == self.m_iReelRowNum)
    self:findChild("CoinConifer_line_zuo_30"):setVisible(rowNum == self.m_iReelMinRowNum)
    self:findChild("CoinConifer_line_zuo_60"):setVisible(rowNum == self.m_iReelRowNum)
    if rowNum == self.m_iReelMinRowNum then
        local lineLeftPosY = self:findChild("Node_lineLeft1"):getPositionY()
        local lineRighrPosY = self:findChild("Node_lineRight1"):getPositionY()
        self:findChild("CoinConifer_line_you"):setPositionY(lineRighrPosY)
        self:findChild("CoinConifer_line_zuo"):setPositionY(lineRighrPosY)
    elseif rowNum == self.m_iReelRowNum then
        local lineLeftPosY = self:findChild("Node_lineLeft2"):getPositionY()
        local lineRighrPosY = self:findChild("Node_lineRight2"):getPositionY()
        self:findChild("CoinConifer_line_you"):setPositionY(lineRighrPosY)
        self:findChild("CoinConifer_line_zuo"):setPositionY(lineRighrPosY)
    end

    self:changeReelData(self.m_iReelRowNum)
    local slotHeight = self.m_SlotNodeH * rowNum
    --变更裁切层高度
    local rect = self.m_onceClipNode:getClippingRegion()
    self.m_onceClipNode:setClippingRegion(
        {
            x = rect.x, 
            y = rect.y, 
            width = rect.width, 
            height = slotHeight
        }
    )   
    self:changeTouchSpinLayerSizeForCoinConifer(rowNum) 
end

--[[
        @desc:修改棋盘的显示区域
        --@addHeights:上涨高度
        @return:nil
    ]]
function CodeGameScreenCoinConiferMachine:addReelOnceClipNode(addHeights,time)
    local lineKuangSpeed = self.lineKuangDiffer/(60  * 0.5)
    local qipan_size = self:findChild("Panel_move"):getContentSize()
    self:findChild("Panel_move"):setContentSize(cc.size(qipan_size.width, qipan_size.height + addHeights))
    self:findChild("Node_top1"):setPositionY(self:findChild("Node_top1"):getPositionY() + addHeights)
    self:findChild("CoinConifer_line_you"):setPositionY(self:findChild("CoinConifer_line_you"):getPositionY() + lineKuangSpeed)
    self:findChild("CoinConifer_line_zuo"):setPositionY(self:findChild("CoinConifer_line_zuo"):getPositionY() + lineKuangSpeed)
    self:findChild("CoinConifer_line_you_30"):setVisible(time <= 15)
    self:findChild("CoinConifer_line_you_60"):setVisible(time > 15)
    self:findChild("CoinConifer_line_zuo_30"):setVisible(time <= 15)
    self:findChild("CoinConifer_line_zuo_60"):setVisible(time > 15)

    --变更裁切层高度
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

--轮盘动态上涨时每一帧都会调用改方法
function CodeGameScreenCoinConiferMachine:addReelUIHeightByOnceClip(stepAddHeights,time)
    self:addReelOnceClipNode(stepAddHeights,time)    
end

--[[
        @desc: 动态变更滚轮行数
        --@rowNum:行数
        --@speed:上涨速度
        --@endFunc:结束回调
        @return:nil
    ]]
function CodeGameScreenCoinConiferMachine:changeReelRowCountWithDynamicByOnceClip(rowNum,speed,endFunc)
    if self.m_iReelRowNum == rowNum then
        return
    end

    self.scheduleNode:stopAllActions()
    local curClipHeight = self.m_SlotNodeH * self.m_iReelMinRowNum
    local slotHeight = self.m_SlotNodeH * self.m_iReelRowNum

    self:changeReelData(self.m_iReelRowNum)

    --升行还是降行(1是升行,-1是降行)
    local direction = curClipHeight > slotHeight and -1 or 1
    -- local stepAddHeights = 0
    local differHeight = slotHeight - curClipHeight
    --升行速度
    --differHeight / (60  * 0.5)
    --8.33
    speed = differHeight / (60  * 0.5)

    local time = 0

    util_schedule(self.scheduleNode,function()
        local stepAddHeights = speed
        local isEnd = false
        if stepAddHeights > math.abs(slotHeight - curClipHeight) then
            stepAddHeights = math.abs(slotHeight - curClipHeight)
            isEnd = true
        end
        stepAddHeights = stepAddHeights * direction
        curClipHeight = curClipHeight + stepAddHeights
        time = time + 1
        self:addReelUIHeightByOnceClip(stepAddHeights,time)
        if isEnd then
            --停止定时器
            self:changeTouchSpinLayerSizeForCoinConifer(self.m_iReelRowNum)
            self.scheduleNode:stopAllActions()
            if type(endFunc) == "function" then
                endFunc()
            end
        end
        

    end,1 / 60) 
end

--[[
    变更点击区域大小
]]
function CodeGameScreenCoinConiferMachine:changeTouchSpinLayerSizeForCoinConifer(rowNum)
    if self.m_SlotNodeH and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH * rowNum))
    end
end


--修改bonus小块显示
function CodeGameScreenCoinConiferMachine:updateReelGridNode(node)
    CodeGameScreenCoinConiferMachine.super.updateReelGridNode(self,node)
    local symbolType = node.p_symbolType
    if symbolType and symbolType == self.SYMBOL_BONUS_1 then
        
        self:setSpecialNodeScore(node)
    elseif symbolType and symbolType == self.SYMBOL_BONUS_2 then
        self:setSpecialNodeScoreForJackpot(node)
    end

    if symbolType == self.SYMBOL_BONUS_2 or symbolType == self.SYMBOL_BONUS_1 then
        print("p_rowIndex = "..node.p_rowIndex)
    end

    if symbolType and symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then      
        if not node:isLastSymbol() then
            node:runAnim("tuowei",true)
        end
    end
end

-- 钱数、free赋值相关
function CodeGameScreenCoinConiferMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local posIndex = nil
    if iCol and iRow then
        posIndex = self:getPosReelIdx(iRow, iCol)
    end
    
    if posIndex then
        self:addCCbForBonus1Spine(posIndex,symbolNode)
    end
end

--[[
    处理bonus上的数字 判断是否需要保留一位小数
]]
function CodeGameScreenCoinConiferMachine:setBonusCoins(_nScore, _score)
    local unitList = "KMBT"
    local lnscore = tostring(_nScore)
    local lscore = tostring(_score)
    local nstrLen = string.len(lnscore)
    local str = string.sub(lscore, 2, 2)
    if string.find(unitList, string.sub(lnscore, 2, 2)) and str ~= "0" then
        return string.sub(lnscore, 1, 1).."."..str ..string.sub(lnscore, 2, nstrLen) 
    end
    return _nScore
end

function CodeGameScreenCoinConiferMachine:addCCbForBonus1Spine(posIndex,symbolNode)
    --self.SYMBOL_BONUS_1
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local iconType,iconNum = self:getBonus1CoinsOrFreeNum(posIndex)
    if iconType then
        if iconType == 94 then      --钱
            --lineBet * 
            local score = toLongNumber(iconNum)
            local csbName = "CoinConifer_Bonus_zi.csb"
            local m_bindCsbNode,spine = self:getLblCsbOnSymbol(symbolNode,csbName,"zi")
            if m_bindCsbNode then
                m_bindCsbNode:runCsbAction("idleframe",true)
                if m_bindCsbNode:findChild("qian") then
                    m_bindCsbNode:findChild("qian"):setVisible(true)
                end
                if m_bindCsbNode:findChild("free") then
                    m_bindCsbNode:findChild("free"):setVisible(false)
                end
                if m_bindCsbNode:findChild("m_lb_coins") then
                    m_bindCsbNode:findChild("m_lb_coins"):setVisible(true)
                    local nScore = self:setBonusCoins(util_formatCoinsLN(score, 3), score)
                    m_bindCsbNode:findChild("m_lb_coins"):setString(nScore)
                    self:updateLabelSize({label = m_bindCsbNode:findChild("m_lb_coins"),sx = 1,sy = 1}, 152)
                end
            end
            
        elseif iconType == 96 then  --free
            local csbName = "CoinConifer_Bonus_zi.csb"
            local m_bindCsbNode,spine = self:getLblCsbOnSymbol(symbolNode,csbName,"zi")
            if m_bindCsbNode then
                m_bindCsbNode:runCsbAction("idleframe",true)
                if m_bindCsbNode:findChild("qian") then
                    m_bindCsbNode:findChild("qian"):setVisible(false)
                end
                if m_bindCsbNode:findChild("free") then
                    m_bindCsbNode:findChild("free"):setVisible(true)
                end
                if m_bindCsbNode:findChild("m_lb_num") then
                    m_bindCsbNode:findChild("m_lb_num"):setVisible(true)
                    m_bindCsbNode:findChild("m_lb_num"):setString(iconNum)
                end
            end
            
        end
    end
end

function CodeGameScreenCoinConiferMachine:getBonus1CoinsOrFreeNum(posIndex)
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local bonusIcon = freespinExtra.bonusIcon or {}
    local iconType = nil
    local iconNum = 0
    for index = 1, #bonusIcon do
        local values = bonusIcon[index]
        if tonumber(values[1]) == posIndex then
            iconNum = values[3]
            iconType = values[2]
        end
    end
    return iconType,iconNum
end

--jackpotBonus赋值相关
function CodeGameScreenCoinConiferMachine:setSpecialNodeScoreForJackpot(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    local posIndex = nil
    if iCol and iRow then
        posIndex = self:getPosReelIdx(iRow, iCol)
    end
    
    if posIndex then
        local jackpotType = self:getBonus2Jackpot(posIndex)
        self:addCCbForBonus2Spine(jackpotType,symbolNode)
    end
end

function CodeGameScreenCoinConiferMachine:getBonus2Jackpot(posIndex)
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local mysteryIcon = clone(freespinExtra.mysteryIcon) or {}
    local iconType = nil
    
    for index = 1, #mysteryIcon do
        local values = mysteryIcon[index]
        if values[1] == posIndex then
            iconType = values[2]
        end
    end
    local jackpotType = self:getJackpotTypeForBuff2(iconType)
    return jackpotType
end

function CodeGameScreenCoinConiferMachine:getSkinName(jackpotType)
    local jackpotType = string.lower(jackpotType) 
    if jackpotType == "mini" then
        return "G"
    elseif jackpotType == "minor" then
        return "B"
    elseif jackpotType == "major" then
        return "P"
    elseif jackpotType == "grand" then
        return "R"
    end
    return "G"
end

function CodeGameScreenCoinConiferMachine:addCCbForBonus2Spine(jackpotType,symbolNode)
    -- self.SYMBOL_BONUS_2
    --根据jackpot修改symbol显示
    local skinName = self:getSkinName(jackpotType)
    local ccbNode = symbolNode:getCCBNode()
    if not ccbNode then
        symbolNode:checkLoadCCbNode()
    end
    ccbNode = symbolNode:getCCBNode()
    if ccbNode and ccbNode.m_spineNode then
        ccbNode.m_spineNode:setSkin(skinName)
    end
    local csbName = "CoinConifer_Bonus_yuanbao.csb"
    local m_bindCsbNode,spine = self:getLblCsbOnSymbol(symbolNode,csbName,"guadian")
    if m_bindCsbNode then
        m_bindCsbNode:runCsbAction("idleframe",true)
    end
end

--------------------------------ui相关
function CodeGameScreenCoinConiferMachine:changeUiState(state)
    self.m_gameBg:findChild("base"):setVisible(state == PublicConfig.uiState.base)
    self.m_gameBg:findChild("mult"):setVisible(state == PublicConfig.uiState.buffFree1)
    self.m_gameBg:findChild("jackpot"):setVisible(state == PublicConfig.uiState.buffFree2)
    self.m_gameBg:findChild("renewal"):setVisible(state == PublicConfig.uiState.buffFree3)
    self.m_gameBg:findChild("super"):setVisible(state == PublicConfig.uiState.superFree)
    self.m_gameBg:findChild("pick"):setVisible(false)

    self.m_jackPotBarView:setVisible(state == PublicConfig.uiState.base or state == PublicConfig.uiState.buffFree3)
    self.m_jackPotBarFreeView:setVisible(state == PublicConfig.uiState.buffFree2)
    self.m_jackPotBarSuperFreeView:setVisible(state == PublicConfig.uiState.superFree)
    self:findChild("Node_free"):setVisible(state == PublicConfig.uiState.superFree or state == PublicConfig.uiState.buffFree2 or state == PublicConfig.uiState.buffFree1 or state == PublicConfig.uiState.buffFree3)
    self:findChild("Node_base_reel"):setVisible(state == PublicConfig.uiState.base)
    self.m_baseFreeSpinBar:setVisible(state ~= PublicConfig.uiState.base)

    if self.tree then
        self.tree:setVisible(state == PublicConfig.uiState.base)
    end
    
    if state == PublicConfig.uiState.base then
        -- self:runCsbAction("idle1")
    end
end

function CodeGameScreenCoinConiferMachine:getBigTreeActNameOrTime()
    if self.curTreeLevel == 4 then
        return "idleframe3",90/30
    elseif self.curTreeLevel == 3 then
        return "idleframe3",90/30
    elseif self.curTreeLevel == 2 then
        return "idleframe2",120/30
    else
        return "idleframe1",120/30
    end
end

--大树idle相关
function CodeGameScreenCoinConiferMachine:showBigTreeIdle()
    self.treeNode:stopAllActions()
    local actName,actTime = self:getBigTreeActNameOrTime()
    local random = math.random(1,100)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self.tree:showBigTreeAct(actName,false)
    end)
    actList[#actList + 1] = cc.DelayTime:create(actTime)
    if self.curTreeLevel == 3 and random <= 10 then
        actList[#actList + 1] = cc.CallFunc:create(function ()
            self.tree:showBigTreeAct("idleframe3_2",false)
        end)
        actList[#actList + 1] = cc.DelayTime:create(90/30)
    end
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:showBigTreeIdle()
    end)
    self.treeNode:runAction(cc.Sequence:create(actList))
end

function CodeGameScreenCoinConiferMachine:showTreeForYugao()
    self.treeNode:stopAllActions()
    local actName = "actionframe_yugao1"
    if self.curTreeLevel == 3 then
        actName = "actionframe_yugao3"
    elseif self.curTreeLevel == 2 then
        actName = "actionframe_yugao2"
    end
    self.isShowYuGao = true
    self.tree:showBigTreeAct(actName,false,function ()
        self.isShowYuGao = false
        self:showBigTreeIdle()
    end)
end

function CodeGameScreenCoinConiferMachine:showBigWinAct()
    if not self.bigWinEffect then
        self.bigWinEffect = util_spineCreate("CoinConifer_Bigwin", true, true)
        self:findChild("bigWinNode"):addChild(self.bigWinEffect)
        self.bigWinEffect:setVisible(false)
    end
    self.bigWinEffect:setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bigWin_yugao)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self.freeType == 0 or self.freeType == 3 then
            util_spinePlay(self.bigWinEffect,"actionframe_free",false)
            util_spineEndCallFunc(self.bigWinEffect,"actionframe_free",function()
                self.bigWinEffect:setVisible(false)
            end)
        else
            util_spinePlay(self.bigWinEffect,"actionframe_base",false)
            util_spineEndCallFunc(self.bigWinEffect,"actionframe_base",function()
                self.bigWinEffect:setVisible(false)
            end)
        end
        
    else
        util_spinePlay(self.bigWinEffect,"actionframe_base",false)
        util_spineEndCallFunc(self.bigWinEffect,"actionframe_base",function()
            self.bigWinEffect:setVisible(false)
        end)
    end
end

function CodeGameScreenCoinConiferMachine:showToFreeGuoChang(func1,func2,isStart)
    if not self.guoChang1 then
        self.guoChang1 = util_spineCreate("CoinConifer_guochang", true, true)
        self.guoChang1:setScale(self.m_machineRootScale)
        self:addChild(self.guoChang1, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
        self.guoChang1:setPosition(display.width * 0.5, display.height * 0.5)
        self.guoChang1:setVisible(false)
    end
    self.guoChang1:setVisible(true)
    util_spinePlay(self.guoChang1, "actionframe_guochang")
    util_spineEndCallFunc(self.guoChang1, "actionframe_guochang", function ()
        self.guoChang1:setVisible(false)
        
    end)
    util_spineFrameCallFunc(self.guoChang1,"actionframe_guochang","switch", function()
        if type(func1) == "function" then
            func1()
        end
    end)
    if isStart then
        self:delayCallBack(35/30,function ()
            if type(func2) == "function" then
                func2()
            end
        end)
    else
        self:delayCallBack(60/30,function ()
            if type(func2) == "function" then
                func2()
            end
        end)
    end
    
    
end

function CodeGameScreenCoinConiferMachine:showToFreeGuoChang2(func1,func2)
    if not self.guoChang1 then
        self.guoChang1 = util_spineCreate("CoinConifer_guochang", true, true)
        self.guoChang1:setScale(self.m_machineRootScale)
        self:addChild(self.guoChang1, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 1)
        self.guoChang1:setPosition(display.width * 0.5, display.height * 0.5)
        self.guoChang1:setVisible(false)
    end
    self.guoChang1:setVisible(true)
    util_spinePlay(self.guoChang1, "actionframe_guochang2")
    util_spineEndCallFunc(self.guoChang1, "actionframe_guochang2", function ()
        self.guoChang1:setVisible(false)
        if type(func2) == "function" then
            func2()
        end
    end)
    util_spineFrameCallFunc(self.guoChang1,"actionframe_guochang2","switch", function()
        if type(func1) == "function" then
            func1()
        end
    end)
end

--------------------------------收集

function CodeGameScreenCoinConiferMachine:showCollectScaterEffect(func)
    local time = 0.2
    --是否触发玩法
    local feautes = self.m_runSpinResultData.p_features or {}
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local freeType = freespinExtra.freeType or 0
    local collectLevel = self:getTreeLevelForBet()
    if #feautes > 1 then
        if freeType == 3 then           --superFree
            if self.curTreeLevel <  collectLevel then
                time = 60/30 + 3 + 0.65     --先升级到最高级
            else
                time = 25/30 + 3 + 0.65     --收集
            end
            
        else
            if self.curTreeLevel <  collectLevel then
                time = 60/30 + 0.65     --先升级
            else
                time = 25/30 + 0.65    --收集
            end
           
        end
    else
        if self.curTreeLevel <  collectLevel then
            time = 60/30 + 0.65
        end
    end
    self:collectAllScatter()
    
    self:delayCallBack(0.65,function ()

        self:changeTreeLevel()
        
    end)
    
    self:delayCallBack(time,function ()
        if func then
            func()
        end
    end)
end

function CodeGameScreenCoinConiferMachine:collectAllScatter()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local SCposition = selfData.SCposition or {}
    local endPos = util_convertToNodeSpace(self:findChild("Node_tree"),self.m_collectEffectNode)
    endPos = cc.p(endPos.x,endPos.y + 300)
    if #SCposition > 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collect)
    end
    for i, v in ipairs(SCposition) do
        local posIndex = v
        local slotNode = self:getSymbolByPosIndex(posIndex)
        if slotNode then
            --类似于buling的提层
            local curPos = util_convertToNodeSpace(slotNode, self.m_clipParent)
            util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
            slotNode:setPositionY(curPos.y)
            slotNode:runAnim("shouji",false,function ()
                slotNode:runAnim("idleframe2",true)
            end)
            local startPos = util_convertToNodeSpace(slotNode,self.m_collectEffectNode)
            local delayTime = 0.08
            for j = 1, 8, 1 do
                local coins = util_createAnimation("CoinConifer_Scatter_shouji.csb")
                self.m_collectEffectNode:addChild(coins,j)
                local xPow = math.random(1, 2)
                local yPow = math.random(1, 2)
                local newStartPos = cc.pAdd(startPos, cc.p(math.random(0, 40) * math.pow(-1, xPow), 30 + math.random(0, 40) * math.pow(-1, yPow)))
                coins:setPosition(newStartPos)
                
                coins:runCsbAction("shouji")
                coins:setScale(0)
                coins:setRotation(math.random(0, 360))
                local delayAction = cc.DelayTime:create((j - 1) * delayTime)
                local scale = 0.4 + math.random(0, 2) * 0.1
                local scaleTo = cc.ScaleTo:create(0.15, scale)
                local bez =
                cc.BezierTo:create(
                0.65,
                {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x + (endPos.x - startPos.x) * 0.5, startPos.y), endPos})

                coins:runAction(cc.Sequence:create(delayAction, scaleTo, cc.EaseOut:create(bez, 1), cc.CallFunc:create(function()
                    coins:removeFromParent()
                end)))
            end
        end
    end
end

function CodeGameScreenCoinConiferMachine:changeTreeLevel(collectLevel)
    self.treeNode:stopAllActions()
    self.changeLevelNode:stopAllActions()
    if self.collectScSoundId then
        gLobalSoundManager:stopAudio(self.collectScSoundId)
        self.collectScSoundId = nil
    end
    local time = 0
    -- local collectLevel = self:getTreeLevelForBet()
    if self.curTreeLevel == 1 then
        if collectLevel == 1 then
            self.collectScSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collectFanKui)
            self.tree:showBigTreeAct("shouji1",false)
            time = 25/30
        elseif collectLevel == 2 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_tree_oneToTwo)
            self.tree:showBigTreeAct("1to2",false)
            time = 60/30
        elseif collectLevel == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_tree_change_gold)
            self.tree:showBigTreeAct("1to3",false)
            time = 60/30
        elseif collectLevel == 4 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_tree_change_gold)
            self.tree:showBigTreeAct("1to3",false)
            self:delayCallBack(60/30,function ()
                self:triggerTreeAct()
            end)
            time = 25/30 + 3
        end
    elseif self.curTreeLevel == 2 then
        if collectLevel == 2 then
            self.collectScSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collectFanKui)
            self.tree:showBigTreeAct("shouji2",false)
            time = 25/30
        elseif collectLevel == 3 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_tree_change_gold)
            self.tree:showBigTreeAct("2to3",false)
            time = 60/30
        elseif collectLevel == 4 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_tree_change_gold)
            self.tree:showBigTreeAct("2to3",false)
            self:delayCallBack(60/30,function ()
                self:triggerTreeAct()
            end)
            time = 25/30 + 3
        end
    elseif self.curTreeLevel == 3 then
        if collectLevel == 3 then
            self.collectScSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collectFanKui)
            self.tree:showBigTreeAct("shouji3",false)
            time = 25/30
        elseif collectLevel == 4 then 
            self.collectScSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collectFanKui)
            self.tree:showBigTreeAct("shouji3",false)
            self:delayCallBack(25/30,function ()
                self:triggerTreeAct()
            end)
            time = 25/30 + 3
        end
    end
    if collectLevel ~= 4 then
        performWithDelay(self.changeLevelNode,function ()
            self:showBigTreeIdle()
        end,time)
    end
    return time
end

function CodeGameScreenCoinConiferMachine:triggerTreeAct()
    self:clearCurMusicBg()
    if not self.treeEffect then
        self.treeEffect = util_spineCreate("CoinConifer_jackpot", true, true)
        self:findChild("Node_tree2"):addChild(self.treeEffect)
        self.treeEffect:setVisible(false)
    end
    if not tolua.isnull(self.treeEffect) then
        self.treeEffect:setVisible(true)
        util_spinePlay(self.treeEffect,"actionframe2",false)
        util_spineEndCallFunc(self.treeEffect,"actionframe2",function()
            self.treeEffect:setVisible(false)
        end)
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_tree_collect_trigger)
    self.tree:showBigTreeAct("actionframe",false)
end

function CodeGameScreenCoinConiferMachine:resetTreeLevel()
    self.treeNode:stopAllActions()
    -- local totalBet = globalData.slotRunData:getCurTotalBet( ) 
    -- self.treeLevelForBet[tostring(toLongNumber(totalBet))] = 1
    self.curTreeLevel = 1
    self:showBigTreeIdle()
end

------------------------------收集新

function CodeGameScreenCoinConiferMachine:setScatterListForCol(reelCol)
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local SCposition = selfData.SCposition or {}
    local newPosition = clone(SCposition)
    local tempList = {}
    for i, posIndex in ipairs(newPosition) do
        local slotNode = self:getSymbolByPosIndex(posIndex)
        if slotNode and slotNode.p_symbolType and slotNode.p_cloumnIndex and slotNode.p_rowIndex then
            if slotNode.p_symbolType == 90 and slotNode.p_cloumnIndex == reelCol and (slotNode.p_rowIndex ~= 1 or slotNode.p_rowIndex ~= 2 ) then
                if i == table_length(newPosition) then
                    tempList[#tempList + 1] = {posIndex,true}
                else
                    tempList[#tempList + 1] = {posIndex,false}
                end
                
            end
        end
    end
    return tempList
end

function CodeGameScreenCoinConiferMachine:showCollectScaterForCol(list,collectLevel)
    local endPos = util_convertToNodeSpace(self:findChild("Node_tree"),self.m_collectEffectNode)
    endPos = cc.p(endPos.x,endPos.y + 300)
    if table_length(list) > 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collect)
    end
    for i, v in ipairs(list) do
        local posIndex = v[1]
        local slotNode = self:getSymbolByPosIndex(posIndex)
        if slotNode then
            
            -- --类似于buling的提层
            -- local curPos = util_convertToNodeSpace(slotNode, self.m_clipParent)
            -- util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
            -- slotNode:setPositionY(curPos.y)
            -- slotNode:runAnim("shouji",false,function ()
            --     slotNode:runAnim("idleframe2",true)
            -- end)
            local startPos = util_convertToNodeSpace(slotNode,self.m_collectEffectNode)
            local delayTime = 0.08
            for j = 1, 8, 1 do
                local coins = util_createAnimation("CoinConifer_Scatter_shouji.csb")
                self.m_collectEffectNode:addChild(coins,j)
                local xPow = math.random(1, 2)
                local yPow = math.random(1, 2)
                local newStartPos = cc.pAdd(startPos, cc.p(math.random(0, 40) * math.pow(-1, xPow), 30 + math.random(0, 40) * math.pow(-1, yPow)))
                coins:setPosition(newStartPos)
                
                coins:runCsbAction("shouji")
                coins:setScale(0)
                coins:setRotation(math.random(0, 360))
                local delayAction = cc.DelayTime:create((j - 1) * delayTime)
                local scale = 0.4 + math.random(0, 2) * 0.1
                local scaleTo = cc.ScaleTo:create(0.15, scale)
                local bez =
                cc.BezierTo:create(
                0.65,
                {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x + (endPos.x - startPos.x) * 0.5, startPos.y), endPos})

                coins:runAction(cc.Sequence:create(delayAction, scaleTo, cc.EaseOut:create(bez, 1), cc.CallFunc:create(function()
                    if j == 1 then
                        -- self.curScatterBulingNum = self.curScatterBulingNum + 1
                        --收集反馈 self.curScatterBulingNum >= self.totalScatterBulingNum
                        -- if self:getGameSpinStage() ~= QUICK_RUN then
                            if not self.isShowYuGao then
                                if v[2] then
                                    --收集且升级
                                    self:changeTreeLevel(collectLevel)
                                else
                                    --只收集不升级
                                    self:changeTreeLevel2(collectLevel)
                                end
                            end
                        -- end
                    end
                    coins:removeFromParent()
                end)))
            end
            -- self:delayCallBack(0.65,function ()
                
            -- end)
        end
    end
end

function CodeGameScreenCoinConiferMachine:changeTreeLevelForSlotDown()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local SCposition = selfData.SCposition or {}
    if table_length(SCposition) then
        self:delayCallBack(0.65,function ()
            self:changeTreeLevel()
        end)
    end
    
end

function CodeGameScreenCoinConiferMachine:changeTreeLevel2(collectLevel)
    self.treeNode:stopAllActions()
    self.changeLevelNode:stopAllActions()
    if self.collectScSoundId then
        gLobalSoundManager:stopAudio(self.collectScSoundId)
        self.collectScSoundId = nil
    end
    local time = 0
    if self.curTreeLevel == 1 then
        self.collectScSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collectFanKui)
        self.tree:showBigTreeAct("shouji1",false)
        time = 25/30
    elseif self.curTreeLevel == 2 then
        self.collectScSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collectFanKui)
        self.tree:showBigTreeAct("shouji2",false)
        time = 25/30
    elseif self.curTreeLevel == 3 then
        self.collectScSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_scatter_collectFanKui)
        self.tree:showBigTreeAct("shouji3",false)
        time = 25/30
    end
    
    return time
end

function CodeGameScreenCoinConiferMachine:setNewCollectNum()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local SCposition = selfData.SCposition or {}
    if table_length(SCposition) > 0 then
        self.totalScatterBulingNum = table_length(SCposition)
    end
end

--[[
    @desc: 卡住spin
    author:{author}
    time:2023-12-28 10:19:53
    @return:
]]

function CodeGameScreenCoinConiferMachine:showNoSpinEffect(func)
    local feautes = self.m_runSpinResultData.p_features or {}
    local collectLevel = self:getTreeLevelForBet()
    local time = 0
    if #feautes > 1 then        --触发free
        if collectLevel == 4 then       --superFree
            time = 25/30 + 3            --收集之后还要走触发
        else
            if collectLevel ~= self.curTreeLevel then   --树升级
                time = 2
            else
                time = 25/30
            end
        end
    else
        if collectLevel ~= self.curTreeLevel then       --没触发free仅升级
            time = 2
        end    
    end
    
    self:delayCallBack(time,function ()
        self.curTreeLevel = collectLevel
        if func then
            func()
        end
    end)
end

--------------------------------选择
function CodeGameScreenCoinConiferMachine:addChooseView()
    self.m_chooseFSView = util_createView("CoinConiferSrc.CoinConiferChooseView",{machine = self})
    self:addChild(self.m_chooseFSView, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 2)
    self.m_chooseFSView:findChild("root"):setScale(self.m_machineRootScale)  
    self.m_chooseFSView:setVisible(false)
end

function CodeGameScreenCoinConiferMachine:addDarkView()
    self.m_darkView = util_createView("CoinConiferSrc.CoinConiferDarkView",{machine = self})
    --:findChild("Node_Freespin_beijing")
    self:addChild(self.m_darkView, GAME_LAYER_ORDER.LAYER_ORDER_SEPCIAL_LAYER - 3)
    self.m_darkView:setPosition(display.center)
    self.m_darkView:findChild("Node_beijing"):setScale(self.m_machineRootScale)  
    self.m_darkView:setVisible(false)
end

function CodeGameScreenCoinConiferMachine:showChooseView(_func)
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local freeType = freespinExtra.freeType or 0
    
    self.m_chooseFSView:resetViewInfo({
        index = freeType + 1,
        func = _func
    })
    
    if self.freeType == 3 then
        self:resetMusicBg(nil,"CoinConiferSounds/music_CoinConifer_superFree_bg.mp3")
    else
        self:resetMusicBg(nil,"CoinConiferSounds/music_CoinConifer_free_bg.mp3")
    end
    self.m_chooseFSView:setVisible(true)
    self.m_chooseFSView:showView()
    self.m_darkView:showStartView()   
end

function CodeGameScreenCoinConiferMachine:collectAddFreeNum()
    
end

--------------------------------BUFF1
--开始滚动之前，棋盘升高
function CodeGameScreenCoinConiferMachine:showUpReelEffect(func)
    if self.freeType == 1 or self.freeType == 2 then
        if type(func) == "function" then
            func()
        end
        return
    end
    
    self:changeReelRowCountWithDynamicByOnceClip(self.m_iReelMinRowNum,nil,function ()
    end)
    if self.freeType == 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_shenghang)
        --双龙现
        self:showTwoDragon(true)
        self:delayCallBack(3,function ()
            if type(func) == "function" then
                func()
            end
        end)
    elseif self.freeType == 3 then          --super
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_super_shenghang)
        self:showMultbarForSuper(true)
        self:delayCallBack(50/60,function ()
            if type(func) == "function" then
                func()
            end
        end)
    end
end


function CodeGameScreenCoinConiferMachine:showTwoDragon(isShow)
    local startName = "start"
    local idleName = "idle"
    if isShow then
        self:delayCallBack(80/60,function ()
            self.superFreeMul:setVisible(true)
            self.superFreeMul:initMulShow()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_show_allWin)
            self.superFreeMul:runCsbAction(startName,false,function ()
                self.superFreeMul:runCsbAction(idleName,true)
            end)
        end)
        
        if tolua.isnull(self.dragon1) then
            self.dragon1 = util_spineCreate("CoinConifer_long", true, true)
            self:findChild("juese1"):addChild(self.dragon1)
            self.dragon1:setVisible(false)
        end
        if tolua.isnull(self.dragon2) then
            self.dragon2 = util_spineCreate("CoinConifer_long", true, true)
            self:findChild("juese2"):addChild(self.dragon2)
            self.dragon2:setVisible(false)
        end
        if tolua.isnull(self.dragon3) then
            self.dragon3 = util_spineCreate("CoinConifer_long", true, true)
            self:findChild("juese3"):addChild(self.dragon3)
            self.dragon3:setVisible(false)
        end
        if tolua.isnull(self.dragon4) then
            self.dragon4 = util_spineCreate("CoinConifer_long", true, true)
            self:findChild("juese4"):addChild(self.dragon4)
            self.dragon4:setVisible(false)
        end
        if tolua.isnull(self.dragon5) then
            self.dragon5 = util_spineCreate("CoinConifer_long_qian", true, true)
            self:findChild("juese5"):addChild(self.dragon5)
            self.dragon5:setVisible(false)
        end
        if tolua.isnull(self.dragon6) then
            self.dragon6 = util_spineCreate("CoinConifer_long_qian", true, true)
            self:findChild("juese6"):addChild(self.dragon6)
            self.dragon6:setVisible(false)
        end
        self.dragon1:setVisible(true)
        self.dragon2:setVisible(true)
        self.dragon3:setVisible(true)
        self.dragon4:setVisible(true)
        self.dragon5:setVisible(true)
        self.dragon6:setVisible(true)
        util_spinePlay(self.dragon1,"start1",false)
        util_spineEndCallFunc(self.dragon1,"start1",function()
            self.dragon1:setVisible(false)
        end)
        util_spinePlay(self.dragon2,"start1",false)
        util_spineEndCallFunc(self.dragon2,"start1",function()
            self.dragon2:setVisible(false)
        end)
        util_spinePlay(self.dragon3,"start2",false)
        util_spineEndCallFunc(self.dragon3,"start2",function()
            util_spinePlay(self.dragon3,"idle",true)
        end)
        util_spinePlay(self.dragon4,"start2",false)
        util_spineEndCallFunc(self.dragon4,"start2",function()
            util_spinePlay(self.dragon4,"idle",true)
        end)
        util_spinePlay(self.dragon5,"start2",false)
        util_spineEndCallFunc(self.dragon5,"start2",function()
            util_spinePlay(self.dragon5,"idle",true)
        end)
        util_spinePlay(self.dragon6,"start2",false)
        util_spineEndCallFunc(self.dragon6,"start2",function()
            util_spinePlay(self.dragon6,"idle",true)
        end)
    else
        self.superFreeMul:setVisible(true)
        self.superFreeMul:initMulShow()
        self.superFreeMul:runCsbAction(idleName,true)
        if tolua.isnull(self.dragon3) then
            self.dragon3 = util_spineCreate("CoinConifer_long", true, true)
            self:findChild("juese3"):addChild(self.dragon3)
            self.dragon3:setVisible(false)
        end
        if tolua.isnull(self.dragon4) then
            self.dragon4 = util_spineCreate("CoinConifer_long", true, true)
            self:findChild("juese4"):addChild(self.dragon4)
            self.dragon4:setVisible(false)
        end
        if tolua.isnull(self.dragon5) then
            self.dragon5 = util_spineCreate("CoinConifer_long_qian", true, true)
            self:findChild("juese5"):addChild(self.dragon5)
            self.dragon5:setVisible(false)
        end
        if tolua.isnull(self.dragon6) then
            self.dragon6 = util_spineCreate("CoinConifer_long_qian", true, true)
            self:findChild("juese6"):addChild(self.dragon6)
            self.dragon6:setVisible(false)
        end
        self.dragon3:setVisible(true)
        self.dragon4:setVisible(true)
        self.dragon5:setVisible(true)
        self.dragon6:setVisible(true)
        util_spinePlay(self.dragon3,"idle",true)
        util_spinePlay(self.dragon4,"idle",true)
        util_spinePlay(self.dragon5,"idle",true)
        util_spinePlay(self.dragon6,"idle",true)
    end
end

function CodeGameScreenCoinConiferMachine:showDragonFire()
    if tolua.isnull(self.dragon3) then
        self.dragon3 = util_spineCreate("CoinConifer_long", true, true)
        self:findChild("juese3"):addChild(self.dragon3)
        self.dragon3:setVisible(false)
    end
    if tolua.isnull(self.dragon4) then
        self.dragon4 = util_spineCreate("CoinConifer_long", true, true)
        self:findChild("juese4"):addChild(self.dragon4)
        self.dragon4:setVisible(false)
    end
    if tolua.isnull(self.dragon5) then
        self.dragon5 = util_spineCreate("CoinConifer_long_qian", true, true)
        self:findChild("juese5"):addChild(self.dragon5)
        self.dragon5:setVisible(false)
    end
    if tolua.isnull(self.dragon6) then
        self.dragon6 = util_spineCreate("CoinConifer_long_qian", true, true)
        self:findChild("juese6"):addChild(self.dragon6)
        self.dragon6:setVisible(false)
    end
    self.dragon3:setVisible(true)
    self.dragon4:setVisible(true)
    self.dragon5:setVisible(true)
    self.dragon6:setVisible(true)
    util_spinePlay(self.dragon3,"pen",false)
    util_spinePlay(self.dragon4,"pen",false)
    util_spinePlay(self.dragon5,"pen",false)
    util_spinePlay(self.dragon6,"pen",false)
    util_spineEndCallFunc(self.dragon3,"pen",function()
        util_spinePlay(self.dragon3,"idle",true)
    end)
    util_spineEndCallFunc(self.dragon4,"pen",function()
        util_spinePlay(self.dragon4,"idle",true)
    end)
    util_spineEndCallFunc(self.dragon5,"pen",function()
        util_spinePlay(self.dragon5,"idle",true)
    end)
    util_spineEndCallFunc(self.dragon6,"pen",function()
        util_spinePlay(self.dragon6,"idle",true)
    end)
end

--变化成倍
function CodeGameScreenCoinConiferMachine:changeChengBeiForBuff1(func)
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local freeType = freespinExtra.freeType or nil
    --
    local linewinmulit = freespinExtra.linewinmulit or 2
    if freeType and (freeType == 0) then
        --龙喷火
        self:showDragonFire()
        
        local time = 30/30
        local newTime  = time + 40/60
        if linewinmulit == 5 then
            newTime = time + 40/60 + 40/60
        end
        if self.superFreeMul.isInit then
            if linewinmulit == 5 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_free_showFive)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_show_chengbei)
            end
        else
            if linewinmulit == 5 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_free_changeFive)
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_change_chengbei)
            end
        end
        -- self:delayCallBack(0.5,function ()
        --     if not self.superFreeMul.isInit then
        --         self.superFreeMul:showMulForOver()
        --     end
        -- end)
        self:delayCallBack(time,function ()
            if not self.superFreeMul.isInit then
                self.superFreeMul:showMulForOver(function ()
                    self.superFreeMul:changeMulShow(false)
                end)
            else
                self.superFreeMul:changeMulShow(false)
            end
        end)
        self:delayCallBack(newTime,function ()
            if type(func) == "function" then
                func()
            end
        end)
    elseif freeType and freeType == 3 then      --super
        if not self.superFreeMul.isInit then
            self.superFreeMul:showMulForOver(function ()
                self.superFreeMul:changeMulShow(true)
            end)
        else
            self.superFreeMul:changeMulShow(true)
        end
        
        
        local newTime  = 40/60
        if linewinmulit == 5 then
            newTime = 40/60 + 40/60
        end
        self:delayCallBack(newTime,function ()
            if type(func) == "function" then
                func()
            end
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
    
    
    
end

----------------------------------BUFF2和BUFF3
--将所有可能会出现的bonus放在同一个表中
function CodeGameScreenCoinConiferMachine:checkBonusListForBonusIconAndMysteryIcon()
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local mysteryIcon = clone(freespinExtra.mysteryIcon) or {}
    local bonusIcon = clone(freespinExtra.bonusIcon) or {}
    local bonusList = {}

    if table_length(mysteryIcon) > 0 then       --jackpotBonus
        --从左到右 从上到下 排序
        table.sort( mysteryIcon, function(a, b)
            local rowColDataA = self:getRowAndColByPos(tonumber(a[1]))
            local rowColDataB = self:getRowAndColByPos(tonumber(b[1]))
            if rowColDataA.iY == rowColDataB.iY then
                return rowColDataA.iX > rowColDataB.iX
            end

            return rowColDataA.iY < rowColDataB.iY
            
        end )
        for i, v in ipairs(mysteryIcon) do
            bonusList[#bonusList + 1] = v
        end
    end

    if table_length(bonusIcon) > 0 then         --free次数和钱数Bonus
        --将bonusIcon进行排序（先free后钱）,然后从左到右 从上到下 排序
        local tempList1 = {}
        local tempList2 = {}
        for i, v in ipairs(bonusIcon) do
            local values = bonusIcon[i]
            if values[2] == 96 then
                tempList1[#tempList1 + 1] = v
            end
            if values[2] == 94 then
                tempList2[#tempList2 + 1] = v
            end
        end

        table.sort( tempList1, function(a, b)
            local rowColDataA = self:getRowAndColByPos(a[1])
            local rowColDataB = self:getRowAndColByPos(b[1])
            if rowColDataA.iY == rowColDataB.iY then
                return rowColDataA.iX > rowColDataB.iX
            end

            return rowColDataA.iY < rowColDataB.iY
            
        end )
        --从左到右 从上到下 排序
        table.sort( tempList2, function(a, b)
            local rowColDataA = self:getRowAndColByPos(a[1])
            local rowColDataB = self:getRowAndColByPos(b[1])
            if rowColDataA.iY == rowColDataB.iY then
                return rowColDataA.iX > rowColDataB.iX
            end

            return rowColDataA.iY < rowColDataB.iY
            
        end )

        for i, v in ipairs(tempList1) do
            bonusList[#bonusList + 1] = v
        end

        for i, v in ipairs(tempList2) do
            bonusList[#bonusList + 1] = v
        end
    end

    return bonusList
end

--Bonus逐一翻开前，先排序
function CodeGameScreenCoinConiferMachine:flippingBonusForBuffTwoAndThree2(func)
    self:clearWinLineEffect()
    -- self:checkChangeBaseParent()
    local bonusInfoList = self:checkBonusListForBonusIconAndMysteryIcon() or {}
    local bonusList2 = clone(bonusInfoList or {})
    --从左到右 从上到下 排序
    table.sort( bonusList2, function(a, b)
        local rowColDataA = self:getRowAndColByPos(tonumber(a[1]))
        local rowColDataB = self:getRowAndColByPos(tonumber(b[1]))
        if rowColDataA.iY == rowColDataB.iY then
            return rowColDataA.iX > rowColDataB.iX
        end

        return rowColDataA.iY < rowColDataB.iY
        
    end )
    if table_length(bonusInfoList) > 0 then
        --逐个翻开
        self.stopBtnIndex = 1       --翻开
        -- self.m_bottomUI:setSkipBtnVisible(true)
        self:setSkipBtnOrLayerVisible(true)
        self:flippingBonusForBuffTwoAndThree3(1,bonusList2,function ()
            self.stopBtnIndex = 2       --收集
            -- self.m_bottomUI:setSkipBtnVisible(true)
            self:setSkipBtnOrLayerVisible(true)
            self:flippingBonusEveryOne(1,bonusInfoList,func)
        end)
    else
        if func then
            func()
        end
    end
end

--Bonus逐一翻开
function CodeGameScreenCoinConiferMachine:flippingBonusForBuffTwoAndThree3(index,bonusInfoList,func)
    if index > table_length(bonusInfoList) then
        self:delayCallBack(18/30,function ()
            -- self.m_bottomUI:setSkipBtnVisible(false)
            self:setSkipBtnOrLayerVisible(false)
            if func then
                func()
            end
        end)
        
        return
    end
    if self.isClickQuickStop1 then
        return
    end
    self.buffTwoOrThreeIndex1 = index
    self.bonusFanNode:stopAllActions()
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        if index == table_length(bonusInfoList) then
            -- self.m_bottomUI:setSkipBtnVisible(false)
            self:setSkipBtnOrLayerVisible(false)
        end
        local values = bonusInfoList[index]
        if values then
            local rowColData = self:getRowAndColByPos((tonumber(values[1]) or 0))
            local symbolNode = self:getFixSymbol(rowColData.iY,rowColData.iX,SYMBOL_NODE_TAG)
            if symbolNode then
                if symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
                    --翻开时间线
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_fan_jackpot) 
                else
                    --翻开时间线
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_show)  
                end
                symbolNode.isClooectName = "switch"
                symbolNode:runAnim("switch")
            end
        end
    end)
    actList[#actList + 1] = cc.DelayTime:create(0.3)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        index = index + 1
        self:flippingBonusForBuffTwoAndThree3(index,bonusInfoList,func)
    end)
    self.bonusFanNode:runAction(cc.Sequence:create(actList))
end

--jackpot、free、钱逐一收集
function CodeGameScreenCoinConiferMachine:flippingBonusEveryOne(index,bonusInfoList,func)
    if index > table_length(bonusInfoList) then
        -- self.m_bottomUI:setSkipBtnVisible(false)
        self:setSkipBtnOrLayerVisible(false)
        if func then
            func()
        end
        return
    end
    if self.isClickQuickStop2 then
        return
    end
    self.fanBonusNode:stopAllActions()
    self.bonusCollectNode:stopAllActions()
    local values = bonusInfoList[index]
    self.buffTwoOrThreeIndex2 = index
    local rowColData = nil
    local symbolNode = nil
    local startPos = nil
    
    if values[1] then
        rowColData = self:getRowAndColByPos(tonumber(values[1]))
        symbolNode = self:getFixSymbol(rowColData.iY,rowColData.iX,SYMBOL_NODE_TAG)
    end
    if symbolNode then
        startPos = util_convertToNodeSpace(symbolNode,self.m_collect1Node)
    end
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        if index == table_length(bonusInfoList) then
            -- self.m_bottomUI:setSkipBtnVisible(false)
            self:setSkipBtnOrLayerVisible(false)
        end
        self:collectOneSymbol(symbolNode,values,startPos)
    end)
    actList[#actList + 1] = cc.DelayTime:create(0.5)
    actList[#actList + 1] = cc.CallFunc:create(function ()
        if values[2] and values[2] > 200 then
            if not self.isClickQuickStop2 then
                --检测进度是否集满
                -- self.m_bottomUI:setSkipBtnVisible(false)
                self:setSkipBtnOrLayerVisible(false)
                --有jackpot弹弹板后继续收集
                self:collectForJackpot(values,function ()
                    -- self.m_bottomUI:setSkipBtnVisible(true)
                    self:setSkipBtnOrLayerVisible(true)
                    index = index + 1
                    self:flippingBonusEveryOne(index,bonusInfoList,func)
                end)
            end
        else
            index = index + 1
            self:flippingBonusEveryOne(index,bonusInfoList,func)
        end
        
    end)
    self.bonusCollectNode:runAction(cc.Sequence:create(actList))
end

--每个bonus飞行到对应为止
function CodeGameScreenCoinConiferMachine:collectOneSymbol(symbolNode,values,startPos)
    local flyNode = nil
    if symbolNode and values then
        if values[2] == 94 then         --钱
            local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("font_last_win_value"),self.m_collect1Node)
            flyNode = util_createAnimation("CoinConifer_Bonus_zi.csb")
            self.m_collect1Node:addChild(flyNode)
            flyNode:setPosition(startPos)
            if flyNode:findChild("qian") then
                flyNode:findChild("qian"):setVisible(true)
            end
            if flyNode:findChild("free") then
                flyNode:findChild("free"):setVisible(false)
            end
            if flyNode:findChild("m_lb_coins") then
                flyNode:findChild("m_lb_coins"):setVisible(true)
                local nScore = self:setBonusCoins(util_formatCoinsLN(toLongNumber(values[3]), 3), toLongNumber(values[3]))
                flyNode:findChild("m_lb_coins"):setString(nScore)
                self:updateLabelSize({label = flyNode:findChild("m_lb_coins"),sx = 1,sy = 1}, 152)
            end
            
            local action0 = cc.CallFunc:create(function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_collect)
            end)
            local action1 = cc.EaseIn:create(cc.MoveTo:create(0.5, endPos),2)
            local action2 = cc.CallFunc:create(function ()
                flyNode:removeFromParent()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_collectFanKui)
                self:playBottomLight(tonumber(values[3]),true,true,true)
            end)
            local actList = {action0,action1,action2}
            flyNode:runAction(cc.Sequence:create(actList))
            symbolNode:runAnim("shouji")
            local aniTime = 30/30
            self:delayCallBack(aniTime,function ()
                symbolNode:runAnim("dark",false,function ()
                    symbolNode:runAnim("dark_idle")
                end)
            end)
        elseif values[2] == 96 then         --free次数
            local endPos = util_convertToNodeSpace(self.m_baseFreeSpinBar:findChild("m_lb_num_2"),self.m_collect1Node)
            flyNode = util_createAnimation("CoinConifer_Bonus_zi.csb")
            self.m_collect1Node:addChild(flyNode)
            flyNode:setPosition(startPos)
            if flyNode:findChild("qian") then
                flyNode:findChild("qian"):setVisible(false)
            end
            if flyNode:findChild("free") then
                flyNode:findChild("free"):setVisible(true)
            end
            if flyNode:findChild("m_lb_num") then
                flyNode:findChild("m_lb_num"):setVisible(true)
                flyNode:findChild("m_lb_num"):setString(tonumber(values[3]))
            end
            
            local action0 = cc.CallFunc:create(function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_freeNum_add)
            end)
            local action1 = cc.EaseIn:create(cc.MoveTo:create(0.5, endPos),2)
            local action2 = cc.CallFunc:create(function ()
                flyNode:removeFromParent()
                --收集到freeBar
                local p_freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or globalData.slotRunData.totalFreeSpinCount
                globalData.slotRunData.totalFreeSpinCount = p_freeSpinsTotalCount
                self.m_baseFreeSpinBar:changeFreeSpinTotalCount()
            end)
            local actList = {action0,action1,action2}
            flyNode:runAction(cc.Sequence:create(actList))
            symbolNode:runAnim("shouji")
            local aniTime = 30/30
            self:delayCallBack(aniTime,function ()
                symbolNode:runAnim("dark",false,function ()
                    symbolNode:runAnim("dark_idle")
                end)
            end)
        elseif values[2] > 200 then
            if symbolNode.isClooectName and symbolNode.isClooectName == "shouji" then
                return
            end
            local jackpotBar = self.m_jackPotBarFreeView
            if self.freeType == 3 then
                jackpotBar = self.m_jackPotBarSuperFreeView
            end
            local rewardType = self:getJackpotTypeForBuff2(values[2])
            local process = jackpotBar:getProcessByType(rewardType)
            local pointNode = jackpotBar:getFeedBackPoint(rewardType,process)
            local endPos = util_convertToNodeSpace(pointNode,self.m_collect1Node)
            flyNode = util_createAnimation("CoinConifer_Bonus_yuanbao.csb")
            self.m_collect1Node:addChild(flyNode)
            flyNode:setPosition(startPos)
            flyNode:runCsbAction("shouji")
            symbolNode.isClooectName = "shouji"
            symbolNode:runAnim("shouji")
            local actionList = {
                cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_jackpot_collect)
                end),
                cc.EaseIn:create(cc.MoveTo:create(0.5, endPos),2),
                cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_jackpot_collectFanKui)
                    jackpotBar:collectFeedBackAni(rewardType,pointNode)
                end),
                cc.RemoveSelf:create()
            }
            flyNode:runAction(cc.Sequence:create(actionList))
        end
    end
end


function CodeGameScreenCoinConiferMachine:getJackpotTypeForBuff2(iconType)
    local jackpotType = nil
    if iconType == 204 then
        jackpotType = "grand"
    elseif iconType == 203 then
        jackpotType = "major"
    elseif iconType == 202 then 
        jackpotType = "minor"   
    else  
        jackpotType = "mini"
    end
    return jackpotType
end



function CodeGameScreenCoinConiferMachine:collectForJackpot(values,func)
    local jackpotBar = self.m_jackPotBarFreeView
    if self.freeType == 3 then
        jackpotBar = self.m_jackPotBarSuperFreeView
    end
    local rewardType = self:getJackpotTypeForBuff2(values[2])
    local process = jackpotBar:getProcessByType2(rewardType)
    local num = 5
    if rewardType == "mini" then
        num = 4
    end
    local jackpotIndex = self:getJackpotIndexForType(rewardType)
    local tempCoins = 0
    local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    if jackpotIndex == 1 then
        tempCoins = allJackpotCoins["Grand"] or 0
    elseif jackpotIndex == 2 then
        tempCoins = allJackpotCoins["Major"] or 0
    elseif jackpotIndex == 3 then
        tempCoins = allJackpotCoins["Minor"] or 0
    elseif jackpotIndex == 4 then
        tempCoins = allJackpotCoins["Mini"] or 0    
    end
    if process == num and tempCoins > 0 then
        
        --弹板
        self:setJackpotShow(jackpotIndex)
        local coins = self:getjackpotCoinsForType(jackpotIndex)
        if self.freeType == 1 then
            self.m_jackPotBarFreeView:showHitLight(rewardType)
        else
            self.m_jackPotBarSuperFreeView:showHitLight(rewardType)
        end
        self:delayCallBack(0.5,function ()
            self:showJackpotView(coins,rewardType,function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_jackpotWin_fankui)
                self:playBottomLight(tonumber(coins),true,true,true)
                if self.freeType == 1 then
                    self.m_jackPotBarFreeView:resetViewForJackpot(rewardType)
                else
                    self.m_jackPotBarSuperFreeView:resetViewForJackpot(rewardType)
                end
                if func then
                    func()
                end
            end)
        end)
    else
        if func then
            func()
        end
    end
end

function CodeGameScreenCoinConiferMachine:setJackpotShow(jackpotIndex)
    self.isHaveJackpot[jackpotIndex] = true
end

function CodeGameScreenCoinConiferMachine:getJackpotShow(jackpotIndex)
    local isSHow = true
    if not self.isHaveJackpot[jackpotIndex] then
        isSHow = self.isHaveJackpot[jackpotIndex]
    end
    return isSHow
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenCoinConiferMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CoinConiferSrc.CoinConiferJackpotWinView",{
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

--------------------------------superFree

function CodeGameScreenCoinConiferMachine:showMultbarForSuper(isShow)
    local startName = "start2"
    local idleName = "idle2"
    if isShow then
        self:delayCallBack(80/60,function ()
            self.superFreeMul:setVisible(true)
            -- self.superFreeMul:initMulShow()
            self.superFreeMul:runCsbAction(startName,false,function ()
                self.superFreeMul:runCsbAction(idleName,true)
            end)
        end)
        
    else
        self.superFreeMul:setVisible(true)
        self.superFreeMul:initMulShow()
        self.superFreeMul:runCsbAction(idleName,true)
    end
end

function CodeGameScreenCoinConiferMachine:showFlipOpenForDisconnection()
    local bonusList = self:checkBonusListForBonusIconAndMysteryIcon()
    for i, values in ipairs(bonusList) do
        if values then
            local rowColData = self:getRowAndColByPos((tonumber(values[1]) or 0))
            local symbolNode = self:getFixSymbol(rowColData.iY,rowColData.iX,SYMBOL_NODE_TAG)
            if symbolNode then
                if values[2] == 94 then
                    symbolNode:runAnim("dark_idle")
                elseif values[2] == 96 then         --free次数
                    symbolNode:runAnim("dark_idle")
                elseif values[2] > 200 then
                    symbolNode:runAnim("shouji")
                end
            end
            
        end
        
    end
end

---------------------------------quickStop

--默认按钮监听回调
function CodeGameScreenCoinConiferMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_kuaiting4x5" then
        if self.stopBtnIndex == 2 then
            self.isClickQuickStop2 = true
            self:showQuickStopEffect()
        elseif self.stopBtnIndex == 1 then
            self.isClickQuickStop1 = true
            self:showQuickStopEffectForFan()
        end
    elseif name == "Panel_kuaiting6x5" then
        if self.stopBtnIndex == 2 then
            self.isClickQuickStop2 = true
            self:showQuickStopEffect()
        elseif self.stopBtnIndex == 1 then
            self.isClickQuickStop1 = true
            self:showQuickStopEffectForFan()
        end
    end
end

function CodeGameScreenCoinConiferMachine:setSkipBtnOrLayerVisible(isVisible)
    self.m_bottomUI:setSkipBtnVisible(isVisible)
    
    if isVisible then
        self.m_skip_click1:setVisible(self.freeType == 1 or self.freeType == 2)
        self.m_skip_click2:setVisible(self.freeType == 0 or self.freeType == 3)
    else
        self.m_skip_click1:setVisible(isVisible)
    self.m_skip_click2:setVisible(isVisible)
    end
end

function CodeGameScreenCoinConiferMachine:setClickLayer()
    self.m_skip_click1:setVisible(self.freeType == 1 or self.freeType == 2)
    self.m_skip_click2:setVisible(self.freeType == 0 or self.freeType == 3)
end

function CodeGameScreenCoinConiferMachine:showQuickStopEffect()
    -- self.bonusCollectNode:stopAllActions()
    --跳过按钮隐藏
    -- self.m_bottomUI:setSkipBtnVisible(false)
    self:setSkipBtnOrLayerVisible(false)
    local bonusList = self:checkBonusListForBonusIconAndMysteryIcon()
    
    --将剩余的bonus收集到目标为止
    local bonusResidueList = self:getResidueList(bonusList,self.buffTwoOrThreeIndex2)
    local isCoinsFanKuiSound = false
    local isFreeFanKuiSound = false
    local isjackpotFanKuiSound = false
    for i, values in ipairs(bonusResidueList) do
        if values then
            local flyNode = nil
            local startPos = nil
            local rowColData = self:getRowAndColByPos((tonumber(values[1]) or 0))
            local symbolNode = self:getFixSymbol(rowColData.iY,rowColData.iX,SYMBOL_NODE_TAG)
            if symbolNode then
                startPos = util_convertToNodeSpace(symbolNode,self.m_collect1Node)
            end
            if values[2] == 94 then         --钱
                local endPos = util_convertToNodeSpace(self.m_bottomUI:findChild("font_last_win_value"),self.m_collect1Node)
                flyNode = util_createAnimation("CoinConifer_Bonus_zi.csb")
                self.m_collect1Node:addChild(flyNode)
                flyNode:setPosition(startPos)
                if flyNode:findChild("qian") then
                    flyNode:findChild("qian"):setVisible(true)
                end
                if flyNode:findChild("free") then
                    flyNode:findChild("free"):setVisible(false)
                end
                if flyNode:findChild("m_lb_coins") then
                    flyNode:findChild("m_lb_coins"):setVisible(true)
                    local nScore = self:setBonusCoins(util_formatCoinsLN(tonumber(values[3]), 3), tonumber(values[3]))
                    flyNode:findChild("m_lb_coins"):setString(nScore)
                    self:updateLabelSize({label = flyNode:findChild("m_lb_coins"),sx = 1,sy = 1}, 152)
                end
                local action0 = cc.CallFunc:create(function ()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_collect)
                end)
                local action1 = cc.EaseIn:create(cc.MoveTo:create(0.5, endPos),2)
                local action2 = cc.CallFunc:create(function ()
                    flyNode:removeFromParent()
                    local isPlayWin = false
                    if i == table_length(bonusResidueList) then
                        isPlayWin = true
                    end

                    if not isCoinsFanKuiSound then
                        isCoinsFanKuiSound = true
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_collectFanKui)
                    end
                    
                    self:playBottomLight(tonumber(values[3]),true,false,isPlayWin)
                end)
                local actList = {action0,action1,action2}
                flyNode:runAction(cc.Sequence:create(actList))
                symbolNode:runAnim("shouji")
                local aniTime = 30/30
                self:delayCallBack(aniTime,function ()
                    symbolNode:runAnim("dark",false,function ()
                        symbolNode:runAnim("dark_idle")
                    end)
                end)
            elseif values[2] == 96 then         --free次数
                local endPos = util_convertToNodeSpace(self.m_baseFreeSpinBar:findChild("m_lb_num_2"),self.m_collect1Node)
                flyNode = util_createAnimation("CoinConifer_Bonus_zi.csb")
                self.m_collect1Node:addChild(flyNode)
                flyNode:setPosition(startPos)
                if flyNode:findChild("qian") then
                    flyNode:findChild("qian"):setVisible(false)
                end
                if flyNode:findChild("free") then
                    flyNode:findChild("free"):setVisible(true)
                end
                if flyNode:findChild("m_lb_num") then
                    flyNode:findChild("m_lb_num"):setVisible(true)
                    flyNode:findChild("m_lb_num"):setString(tonumber(values[3]))
                end
                local action0 = cc.CallFunc:create(function ()
                    if not isFreeFanKuiSound then
                        isFreeFanKuiSound = true
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_freeNum_add)
                    end
                    
                end)
                local action1 = cc.EaseIn:create(cc.MoveTo:create(0.5, endPos),2)
                local action2 = cc.CallFunc:create(function ()
                    flyNode:removeFromParent()
                    --收集到freeBar
                    local p_freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or globalData.slotRunData.totalFreeSpinCount
                    globalData.slotRunData.totalFreeSpinCount = p_freeSpinsTotalCount
                    self.m_baseFreeSpinBar:changeFreeSpinTotalCount()
                end)
                local actList = {action0,action1,action2}
                flyNode:runAction(cc.Sequence:create(actList))
                symbolNode:runAnim("shouji")
                local aniTime = 30/30
                self:delayCallBack(aniTime,function ()
                    symbolNode:runAnim("dark",false,function ()
                        symbolNode:runAnim("dark_idle")
                    end)
                end)
            elseif values[2] > 200 then
                if symbolNode.isClooectName and symbolNode.isClooectName == "shouji" then
                    return
                end
                local jackpotBar = self.m_jackPotBarFreeView
                if self.freeType == 3 then
                    jackpotBar = self.m_jackPotBarSuperFreeView
                end
                local rewardType = self:getJackpotTypeForBuff2(values[2])
                local process = jackpotBar:getProcessByType(rewardType)
                local pointNode = jackpotBar:getFeedBackPoint(rewardType,process)
                local endPos = util_convertToNodeSpace(pointNode,self.m_collect1Node)
                flyNode = util_createAnimation("CoinConifer_Bonus_yuanbao.csb")
                self.m_collect1Node:addChild(flyNode)
                flyNode:setPosition(startPos)
                flyNode:runCsbAction("shouji")
                symbolNode.isClooectName = "shouji"
                symbolNode:runAnim("shouji")
                local actionList = {
                    cc.EaseIn:create(cc.MoveTo:create(0.5, endPos),2),
                    cc.CallFunc:create(function()
                        if pointNode then
                            if not isjackpotFanKuiSound then
                                isjackpotFanKuiSound = true
                                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_jackpot_collectFanKui)
                            end
                            
                        end
                        jackpotBar:collectFeedBackAni(rewardType,pointNode)
                    end),
                    cc.RemoveSelf:create()
                }
                flyNode:runAction(cc.Sequence:create(actionList))
            end
        end
    end

    self:delayCallBack(0.5,function ()
        --是否有jackpotView需要弹
        self:showJackpotViewEffect(function ()
            self:nextEffectShow()
        end)
    end)
end

function CodeGameScreenCoinConiferMachine:showJackpotViewEffect(func)
    local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    local jackpotList = self:isHaveJackpotWin()
    if table_length(jackpotList) <= 0 then
        if func then
            func()
        end
        return
    end
    self:showJackpotViewEffectEveryOne(1,jackpotList,func)
end

function CodeGameScreenCoinConiferMachine:showJackpotViewEffectEveryOne(index,jackpotList,func)
    if index > table_length(jackpotList) then
        if func then
            func()
        end
        return
    end
    local jackpotIndex = jackpotList[index]
    if jackpotIndex then
        local coins = 0
        local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
        if jackpotIndex == 1 then
            coins = allJackpotCoins["Grand"] or 0
        elseif jackpotIndex == 2 then
            coins = allJackpotCoins["Major"] or 0
        elseif jackpotIndex == 3 then
            coins = allJackpotCoins["Minor"] or 0
        elseif jackpotIndex == 4 then
            coins = allJackpotCoins["Mini"] or 0    
        end
        local jackpotType = self:getJackpotTypeForIndex(jackpotIndex)
        
        
        if not self:getJackpotShow(jackpotIndex) then
            self:setJackpotShow(jackpotIndex)
            if self.freeType == 1 then
                self.m_jackPotBarFreeView:showHitLight(jackpotType)
            else
                self.m_jackPotBarSuperFreeView:showHitLight(jackpotType)
            end
            self:delayCallBack(0.5,function ()
                self:showJackpotView(coins,jackpotType,function ()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_jackpotWin_fankui)
                    self:playBottomLight(tonumber(coins),true,true,true)
                    if self.freeType == 1 then
                        self.m_jackPotBarFreeView:resetViewForJackpot(jackpotType)
                    else
                        self.m_jackPotBarSuperFreeView:resetViewForJackpot(jackpotType)
                    end
                    index = index + 1
                    self:showJackpotViewEffectEveryOne(index,jackpotList,func)
                end)
            end)
            
        else
            index = index + 1
            self:showJackpotViewEffectEveryOne(index,jackpotList,func)
        end
        
    end
end

--是否有jackpot集满
function CodeGameScreenCoinConiferMachine:isHaveJackpotWin()
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local jackpotnum = freespinExtra.jackpotnum or {}
    local list = {}
    if jackpotnum["grand"] and jackpotnum["grand"] >= 5 then
        list[#list + 1] = 1
    end
    if jackpotnum["major"] and jackpotnum["major"] >= 5 then
        list[#list + 1] = 2  
    end
    if jackpotnum["minor"] and jackpotnum["minor"] >= 5 then
        list[#list + 1] = 3  
    end
    if jackpotnum["mini"] and jackpotnum["mini"] >= 4 then
        list[#list + 1] = 4  
    end
    return list
end

--获取jackpot总钱数
function CodeGameScreenCoinConiferMachine:getAlljackpotCoins()
    local jackpotList = self:isHaveJackpotWin()
    local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    local coins = 0

    for i, jackpotIndex in ipairs(jackpotList) do
        if jackpotIndex == 1 then
            coins = coins + (allJackpotCoins["Grand"] or 0)
        elseif jackpotIndex == 2 then
            coins = coins + (allJackpotCoins["Major"] or 0)
        elseif jackpotIndex == 3 then
            coins = coins + (allJackpotCoins["Minor"] or 0)
        elseif jackpotIndex == 4 then
            coins = coins + (allJackpotCoins["Mini"] or 0)    
        end
    end
    return coins
end

--根据jackpotIndex获取jackpot钱
function CodeGameScreenCoinConiferMachine:getjackpotCoinsForType(jackpotIndex)
    local coins = 0
        local allJackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
        if jackpotIndex == 1 then
            coins = allJackpotCoins["Grand"] or 0
        elseif jackpotIndex == 2 then
            coins = allJackpotCoins["Major"] or 0
        elseif jackpotIndex == 3 then
            coins = allJackpotCoins["Minor"] or 0
        elseif jackpotIndex == 4 then
            coins = allJackpotCoins["Mini"] or 0    
        end
    return coins
end

--获取jackpotType
function CodeGameScreenCoinConiferMachine:getJackpotTypeForIndex(index)
    if index == 1 then
        return "grand"
    elseif index == 2 then
        return "major"
    elseif index == 3 then
        return "minor"
    elseif index == 4 then
        return "mini"    
    end
end

--获取jackpotIndex
function CodeGameScreenCoinConiferMachine:getJackpotIndexForType(type)
    if type == "grand" then
        return 1
    elseif type == "major" then
        return 2
    elseif type == "minor" then
        return 3
    else
        return 4  
    end
end

function CodeGameScreenCoinConiferMachine:showQuickStopEffectForFan()
    -- self.bonusFanNode:stopAllActions()
    --跳过按钮隐藏
    -- self.m_bottomUI:setSkipBtnVisible(false)
    self:setSkipBtnOrLayerVisible(false)
    local bonusInfoList = self:checkBonusListForBonusIconAndMysteryIcon() or {}
    local bonusList2 = clone(bonusInfoList or {})
    --从左到右 从上到下 排序
    table.sort( bonusList2, function(a, b)
        local rowColDataA = self:getRowAndColByPos(tonumber(a[1]))
        local rowColDataB = self:getRowAndColByPos(tonumber(b[1]))
        if rowColDataA.iY == rowColDataB.iY then
            return rowColDataA.iX > rowColDataB.iX
        end

        return rowColDataA.iY < rowColDataB.iY
        
    end )
    local bonusResidueList = self:getResidueList(bonusList2,self.buffTwoOrThreeIndex1)
    if #bonusResidueList > 0 then
        if self:isHaveJackpotForSwitch(bonusResidueList) then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_fan_jackpot) 
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_show)
        end
        
    end
    for i, values in ipairs(bonusResidueList) do
        if values then
            local rowColData = self:getRowAndColByPos((tonumber(values[1]) or 0))
            local symbolNode = self:getFixSymbol(rowColData.iY,rowColData.iX,SYMBOL_NODE_TAG)
            if symbolNode then
                --翻开时间线
                if values[2] > 200 then
                    symbolNode.isClooectName = "switch"
                end
                symbolNode:runAnim("switch")
            end
        end
    end
    performWithDelay(self.fanBonusNode,function ()
        self.stopBtnIndex = 2       --收集
        -- self.m_bottomUI:setSkipBtnVisible(true)
        self:setSkipBtnOrLayerVisible(true)
        self:flippingBonusEveryOne(1,bonusInfoList,function ()
            self:nextEffectShow()
        end)
    end,18/30)
    -- self:delayCallBack(18/30,function ()
    --     self.stopBtnIndex = 2       --收集
    --     -- self.m_bottomUI:setSkipBtnVisible(true)
    --     self:setSkipBtnOrLayerVisible(true)
    --     self:flippingBonusEveryOne(1,bonusInfoList,function ()
    --         self:nextEffectShow()
    --     end)
    -- end)
end

function CodeGameScreenCoinConiferMachine:isHaveJackpotForSwitch(bonusResidueList)
    local isHave = false
    for i, values in ipairs(bonusResidueList) do
        if values then
            local rowColData = self:getRowAndColByPos((tonumber(values[1]) or 0))
            local symbolNode = self:getFixSymbol(rowColData.iY,rowColData.iX,SYMBOL_NODE_TAG)
            if symbolNode.p_symbolType == self.SYMBOL_BONUS_2 then
                isHave = true
            end
        end
    end
    return isHave
end

--获取剩余列表
function CodeGameScreenCoinConiferMachine:getResidueList(list,index)
    local residueList = {}
    for i, v in ipairs(list) do
        if i > index then
            residueList[#residueList + 1] = v
        end
    end
    return residueList
end

function CodeGameScreenCoinConiferMachine:nextEffectShow()
    if self.collectBonusEffect then
        local collectBonusEffect = self.collectBonusEffect
        self.collectBonusEffect = nil
        --没有大赢并且没有连线
        local jackpotList = self:isHaveJackpotWin()
        if not self:checkHasBigWin() and #self.m_runSpinResultData.p_winLines == 0 then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, self.COLLECT_BONUS_EFFECT)
        end
        --手动刷新freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        if globalData.slotRunData.freeSpinCount ~= 0 then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) --检测删除freeover Effect
        end
        local time = 0.5
        self:delayCallBack(time,function ()
            --没有连线播大赢也增加一个大赢动效
            if self:checkHasBigWin() and #self.m_runSpinResultData.p_winLines == 0 then
                self:showEffect_runBigWinLightAni2()
                self:delayCallBack(2,function ()
                    collectBonusEffect.p_isPlay = true
                    self:playGameEffect()
                end)
            else
                collectBonusEffect.p_isPlay = true
                self:playGameEffect()
            end
            
            
        end)
    end
    
end

--------------------------------刷钱
--[[
    BottomUI接口
]]
function CodeGameScreenCoinConiferMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenCoinConiferMachine:getWinLineCoins()
    
end

--收集钱数
function CodeGameScreenCoinConiferMachine:playBottomLight(_endCoins, isAdd,isPlayAnim,isPlayWin)
    local freespinExtra = self.m_runSpinResultData.p_fsExtraData or {}
    local freeSpinWinCoin = self.m_runSpinResultData.p_fsWinCoins or 0      --fs总赢钱
    local bonusCoin = freespinExtra.bonusCoin or 0      --收集钱bonus总赢钱
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local linewin = selfData.linewin or 0       --连线钱
    local allJackpotCoins = self:getAlljackpotCoins() or 0
    
    if isPlayWin then
        self:playCoinWinEffectUIForCoinConifer()
    end
    
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    local bottomWinCoin = self.buff3Coins
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
        if bottomWinCoin == 0 then
            bottomWinCoin = freeSpinWinCoin - bonusCoin - allJackpotCoins - linewin
        end  
    end
    if isAdd then
        local totalWinCoin = bottomWinCoin + tonumber(_endCoins)
        self.buff3Coins = totalWinCoin
        self:setLastWinCoin(totalWinCoin)
        self:updateBottomUICoins(bottomWinCoin, totalWinCoin,isNotifyUpdateTop,isPlayAnim)
    else
        self:setLastWinCoin(tonumber(_endCoins))
        self:updateBottomUICoins(0, tonumber(_endCoins),isNotifyUpdateTop, isPlayAnim)
    end

end

function CodeGameScreenCoinConiferMachine:playCoinWinEffectUIForCoinConifer()
    -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CoinConifer_bonus_collect)
    self.bottomEffect:setVisible(true)
    util_spinePlay(self.bottomEffect,"actionframe",false)
end


return CodeGameScreenCoinConiferMachine