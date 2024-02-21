---
-- island li
-- 2019年1月26日
-- CodeGameScreenJollyFactoryMachine.lua
-- 
-- 玩法：
-- 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "JollyFactoryPublicConfig"
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenJollyFactoryMachine = class("CodeGameScreenJollyFactoryMachine", BaseReelMachine)

CodeGameScreenJollyFactoryMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenJollyFactoryMachine.SYMBOL_FIX_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenJollyFactoryMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenJollyFactoryMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
CodeGameScreenJollyFactoryMachine.SYMBOL_SCORE_12 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 3

-- 自定义动画的标识
CodeGameScreenJollyFactoryMachine.ADD_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --添加wild
CodeGameScreenJollyFactoryMachine.ALL_COL_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --整列wild
CodeGameScreenJollyFactoryMachine.COPY_ROW_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 --复制整列
CodeGameScreenJollyFactoryMachine.LOW_TO_HIGH_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 --L图标变H图标
CodeGameScreenJollyFactoryMachine.GET_COINS_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5 --直接发钱
CodeGameScreenJollyFactoryMachine.SHOW_WILD_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 6 --显示wild
CodeGameScreenJollyFactoryMachine.UPDATE_FREE_MULTI = GameEffect.EFFECT_SELF_EFFECT - 7 --更新free梯子
CodeGameScreenJollyFactoryMachine.LINE_MULTI_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 8 --连线乘倍

-- 构造函数
function CodeGameScreenJollyFactoryMachine:ctor()
    CodeGameScreenJollyFactoryMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeJollyFactorySrc.JollyFactorySymbolExpect",{
        machine = self,
        symbolList = {
            {
                symbolTypeList = {TAG_SYMBOL_TYPE.SYMBOL_SCATTER}, --可触发的信号值
                triggerCount = 3,    --触发所需数量
                expectAni = "idleframe3",     --期待时间线 根据动效时间线调整
                idleAni = "idleframe2"      --根据动效时间线调整
            }
        }
    }) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("JollyFactoryLongRunControl",{
        machine = self,
        symbolList = {
            {
                symbolTypeList = {TAG_SYMBOL_TYPE.SYMBOL_SCATTER}, --可触发的信号值
                triggerCount = 3    --触发所需数量
            }
        }
    }) 

    self.m_wildBonusSymbol = nil
    self.m_isFirstFree = false
    self.m_isAddBigWinLightEffect = true
    self.m_isAddWild = false

    self.m_addWildList = {}
    self.m_dropWildList = {}    --从上方掉落的wild列表
    self.m_flySymbolList = {}
    self.m_copyList = {}    --复制图标列表
    self.m_flyMoney = nil

    self.m_sound_copy_reel = nil
    self.m_sound_change_high_symbol = nil

    self.m_longRunAni = {}

    self.m_skipEffectFunc = nil --跳过时间回调函数
    self.m_isSkip = false


    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    --init
    self:initGame()
end

--[[
    获取totalbet
]]
function CodeGameScreenJollyFactoryMachine:getTotalBet()
    local totalBet = toLongNumber(globalData.slotRunData:getCurTotalBet()) 
    return totalBet
end

function CodeGameScreenJollyFactoryMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenJollyFactoryMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "JollyFactory"  
end


function CodeGameScreenJollyFactoryMachine:getReelNode()
    return "CodeJollyFactorySrc.JollyFactoryReelNode"
end

--[[
    创建压黑层
]]
function CodeGameScreenJollyFactoryMachine:createBlackLayer(size)
    local sp_reel = self.m_csbOwner["sp_reel_0"]
    local startPos = cc.p(sp_reel:getPosition()) 

    local layerSize = cc.size(size.width / self.m_iReelColumnNum,size.height)

    self.m_blackNodes = {}
    for iCol = 1,self.m_iReelColumnNum do
        local blackLayer = ccui.Layout:create()
        blackLayer:setContentSize(layerSize)
        blackLayer:setAnchorPoint(cc.p(0, 0))
        blackLayer:setTouchEnabled(false)
        self.m_clipParent:addChild(blackLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 20 + iCol)
        blackLayer:setPosition(cc.p(startPos.x + layerSize.width * (iCol - 1),startPos.y))
        blackLayer:setBackGroundColor(cc.c3b(0, 0, 0))
        blackLayer:setBackGroundColorOpacity(180)
        blackLayer:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        blackLayer:setVisible(false)
        self.m_blackNodes[iCol] = blackLayer
    end

    --复制图标层
    self.m_copyClipLayer = ccui.Layout:create()
    self.m_copyClipLayer:setContentSize(size)
    self.m_copyClipLayer:setAnchorPoint(cc.p(0, 0))
    self.m_copyClipLayer:setTouchEnabled(false)
    self.m_clipParent:addChild(self.m_copyClipLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self.m_copyClipLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
    self.m_copyClipLayer:setClippingEnabled(true)
end

--[[
    显示压黑层
]]
function CodeGameScreenJollyFactoryMachine:showBlackLayer(colIndex)
    if not colIndex then
        for iCol = 1,self.m_iReelColumnNum do
            local blackLayer = self.m_blackNodes[iCol]
            blackLayer:setVisible(true)
            blackLayer:stopAllActions()
            util_nodeFadeIn(blackLayer,0.2,0,180)
        end
    else
        local blackLayer = self.m_blackNodes[colIndex]
        blackLayer:setVisible(true)
        blackLayer:stopAllActions()
        util_nodeFadeIn(blackLayer,0.2,0,180)
    end
    
end

--[[
    隐藏压黑层
]]
function CodeGameScreenJollyFactoryMachine:hideBlackLayer(colIndex)
    if not colIndex then
        for iCol = 1,self.m_iReelColumnNum do
            local blackLayer = self.m_blackNodes[iCol]
            blackLayer:stopAllActions()
            util_fadeOutNode(blackLayer,0.2,function(  )
                blackLayer:setVisible(false)
            end)
        end
    else
        local blackLayer = self.m_blackNodes[colIndex]
        blackLayer:stopAllActions()
        util_fadeOutNode(blackLayer,0.2,function(  )
            blackLayer:setVisible(false)
        end)
    end
    
end

--[[
    设置跳过按钮是否显示
]]
function CodeGameScreenJollyFactoryMachine:setSkipBtnShow(isShow)
    self.m_skipBtn:setVisible(isShow)
    self.m_bottomUI.m_spinBtn:setVisible(not isShow)
end

function CodeGameScreenJollyFactoryMachine:initUI()
    local spinParent = self.m_bottomUI:findChild("free_spin_new")
    if spinParent then
        self.m_skipBtn = util_createView("CodeJollyFactorySrc.JollyFactorySkipBtn",{machine = self})
        spinParent:addChild(self.m_skipBtn)
        self.m_skipBtn:setVisible(false)
    end

    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)
    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    self.m_humanNode = util_createView("CodeJollyFactorySrc.JollyFactoryHumanNode",{machine = self})
    self:findChild("Node_juese"):addChild(self.m_humanNode)

    self.m_wildBonusSpine_up = util_spineCreate("Socre_JollyFactory_WildBonus",true,true)
    self.m_effectNode:addChild(self.m_wildBonusSpine_up,10000)
    self.m_wildBonusSpine_up:setVisible(false)

    self.m_addCoinsLbl = util_createView("CodeJollyFactorySrc.JollyFactoryAddCoinsView",{machine = self})
    self:findChild("Node_reel"):addChild(self.m_addCoinsLbl)
    self.m_addCoinsLbl:setVisible(false)

    self.m_multiBox = util_createView("CodeJollyFactorySrc.JollyFactoryMultiBox",{machine = self})
    self:findChild("Node_AllWins_multi"):addChild(self.m_multiBox)
    self.m_multiBox:setVisible(false)

    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView() 


    --转盘界面
    self.m_wheelView = util_createView("CodeJollyFactorySrc.JollyFactoryWheelView",{machine = self})
    self:findChild("root"):addChild(self.m_wheelView)
    self.m_wheelView:setPositionY(-480)
    self.m_wheelView:setVisible(false)
    -- 创建view节点方式
    -- self.m_JollyFactoryView = util_createView("CodeJollyFactorySrc.JollyFactoryView")
    -- self:findChild("xxxx"):addChild(self.m_JollyFactoryView)

    local panel = self:findChild("Panel_1")
    local panelSize = panel:getContentSize()
    local height = display.height / 2
    local width = display.width
    if height > panelSize.height then
        panelSize.height = height
    end
    if width > panelSize.width * self.m_machineRootScale then
        panelSize.width = width / self.m_machineRootScale
    end
    panel:setContentSize(panelSize)
   
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenJollyFactoryMachine:initSpineUI()
    self.m_noticeAni = util_createAnimation("JollyFactory_yugao.csb")
    self:findChild("Node_yugao"):addChild(self.m_noticeAni)
    self.m_noticeAni:setVisible(false)

    local spine1 = util_spineCreate("JollyFactory_yugao",true,true)
    self.m_noticeAni:findChild("Node_yugao1"):addChild(spine1)
    self.m_noticeAni.m_spine1 = spine1

    local spine2 = util_spineCreate("JollyFactory_yugao",true,true)
    self.m_noticeAni:findChild("Node_yugao2"):addChild(spine2)
    self.m_noticeAni.m_spine2 = spine2

end


function CodeGameScreenJollyFactoryMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_JollyFactory_enter_level)
    end)
end

function CodeGameScreenJollyFactoryMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_isEnter = true
    CodeGameScreenJollyFactoryMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showFreeUI()
        self:runCsbAction("move_idle")
        self.m_baseFreeSpinBar:setBoxVisible(true)
    end
    self.m_isEnter = false
end

function CodeGameScreenJollyFactoryMachine:addObservers()
    CodeGameScreenJollyFactoryMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --freespin最后一次spin不会播大赢,需单独处理
            local fsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount or 0
            if fsLeftCount <= 0 then
                self.m_bIsBigWin = false
            end
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = toLongNumber(params[1]) 
        
        local lTatolBetNum = toLongNumber(globalData.slotRunData:getCurTotalBet())
        local winRatio = winCoin / lTatolBetNum
        local soundIndex = 1
        local soundTime = 2
        if winRatio > toLongNumber(0) then
            if winRatio <= toLongNumber(1) then
                soundIndex = 1
            elseif winRatio > toLongNumber(1) and winRatio <= toLongNumber(3) then
                soundIndex = 2
            else
                soundIndex = 3
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig.SoundConfig["sound_JollyFactory_winline_"..soundIndex] 
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            soundName = PublicConfig.SoundConfig["sound_JollyFactory_winline_fg_"..soundIndex]
        end
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenJollyFactoryMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_scheduleNode:stopAllActions()
    CodeGameScreenJollyFactoryMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
--设置bonus scatter 层级
function CodeGameScreenJollyFactoryMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  self.SYMBOL_FIX_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
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


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenJollyFactoryMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_FIX_BONUS then
        return "Socre_JollyFactory_WildBonus"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_JollyFactory_10"
    end

    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_JollyFactory_11"
    end

    if symbolType == self.SYMBOL_SCORE_12 then
        return "Socre_JollyFactory_12"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenJollyFactoryMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenJollyFactoryMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenJollyFactoryMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 

end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenJollyFactoryMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenJollyFactoryMachine:beginReel()
    self:resetReelDataAfterReel()
    self:checkChangeBaseParent()

    -- 设置stop 按钮处于不可点击状态
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false, true})
    end

    local endCount = 0
    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        local moveSpeed = self:getMoveSpeedBySpinMode(self:getCurrSpinMode())
        for iCol = 1,#self.m_baseReelNodes do
            local reelNode = self.m_baseReelNodes[iCol]
            local parentData = self.m_slotParents[iCol]
            parentData.moveSpeed = moveSpeed
            reelNode:changeReelMoveSpeed(moveSpeed)
        end
        reelNode:resetReelDatas()
        reelNode:startMove(function()
            endCount = endCount + 1
            if endCount >= #self.m_baseReelNodes then
                if self.m_isFirstFree then
                    local csbAni = util_createAnimation("JollyFactory_Free_tips.csb")
                    self:findChild("Node_Free_tips"):addChild(csbAni)
                    csbAni:runCsbAction("auto",false,function()
                        if not tolua.isnull(csbAni) then
                            csbAni:removeFromParent()
                        end
                        
                        self:requestSpinReusltData()
                    end)
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_multi_tip"])
                    self:delayCallBack(110 / 60 + 0.2,function()
                        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_spin_start"])
                    end)
                else
                    self:requestSpinReusltData()
                end
                
            end
        end)
    end
end

--[[
    @desc: 在开始滚动前重置数据
    time:2020-07-21 18:25:31
    @return:
]]
function CodeGameScreenJollyFactoryMachine:resetReelDataAfterReel()
    self.m_bClickQuickStop = false
    self.m_isAddWild = false
    CodeGameScreenJollyFactoryMachine.super.resetReelDataAfterReel(self)
    self.m_scheduleNode:stopAllActions()
    self:clearCopySymbol()
    self:clearFlySymbol()
    self.m_wildBonusSymbol = nil
    self.m_addWildList = {}
    self.m_addCoinsLbl:resetCoins()
    self.m_addCoinsLbl:setVisible(false)

    
    for iCol = 1,self.m_iReelColumnNum do
        local reelNode = self.m_baseReelNodes[iCol]
        util_setCascadeOpacityEnabledRescursion(reelNode,true)
        reelNode:setOpacity(150)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenJollyFactoryMachine:slotOneReelDown(reelCol)    
    local reelNode = self.m_baseReelNodes[reelCol]
    reelNode:setOpacity(255)
    CodeGameScreenJollyFactoryMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol,self.m_spcial_symbol_list) 

    if self.m_longRunAni[reelCol] then
        local info = self.m_longRunAni[reelCol]
        local longRunAni = info.longRunAni
        local longRunBgAni = info.longRunBgAni
        longRunAni:setVisible(false)
        longRunBgAni:setVisible(false)
    end

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end

    if self.m_reelRunAnimaBG ~= nil then
        local reelEffectNode = self.m_reelRunAnimaBG[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end
end

function CodeGameScreenJollyFactoryMachine:checkChangeFsCount()
    if self:getCurrSpinMode() == FREE_SPIN_MODE and globalData.slotRunData.freeSpinCount ~= nil and globalData.slotRunData.freeSpinCount > 0 then
        -- --减少free spin 次数
        -- globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1
        -- print(" globalData.slotRunData.freeSpinCount = globalData.slotRunData.freeSpinCount - 1")
        -- gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        -- globalData.userRate:pushFreeSpinCount(1)
    end
end

---
--判断改变freespin的状态
function CodeGameScreenJollyFactoryMachine:changeFreeSpinModeStatus()
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
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

--[[
    滚轮停止
]]
function CodeGameScreenJollyFactoryMachine:slotReelDown( )

    self.m_isSkip = false

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_isFirstFree = false


    CodeGameScreenJollyFactoryMachine.super.slotReelDown(self)
end


---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenJollyFactoryMachine:addSelfEffect()

    local longCount = 0
    local reels = self.m_runSpinResultData.p_reels
    for iRow = 1,self.m_iReelRowNum do
        if reels[iRow][1] == self.SYMBOL_FIX_BONUS then
            longCount = longCount + 1
        end
    end
    if longCount > 0 and longCount <= self.m_iReelRowNum then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.SHOW_WILD_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.SHOW_WILD_EFFECT -- 动画类型
        selfEffect.isShowAll = (longCount == self.m_iReelRowNum)
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData  then 
        --直接给钱
        if selfData.wildBonusKind and selfData.wildBonusKind == 1 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.GET_COINS_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.GET_COINS_EFFECT -- 动画类型
        end
        --洒wild
        if selfData.wildBonusKind and (selfData.wildBonusKind == 2 or selfData.wildBonusKind == 3 or selfData.wildBonusKind == 6) then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.ADD_WILD_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.ADD_WILD_EFFECT -- 动画类型
        end
        
        

        --复制图标
        if selfData.wildBonusKind and selfData.wildBonusKind == 4 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.COPY_ROW_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.COPY_ROW_EFFECT -- 动画类型
        end

        --低级图标变高级图标
        if selfData.wildBonusKind and selfData.wildBonusKind == 5 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.LOW_TO_HIGH_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.LOW_TO_HIGH_EFFECT -- 动画类型
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        
        if #self.m_runSpinResultData.p_winLines > 0 and fsExtraData and fsExtraData.freemulit > 1 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME - 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.LINE_MULTI_EFFECT -- 动画类型
            
        end
    end
    
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenJollyFactoryMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.SHOW_WILD_EFFECT then
        self.m_humanNode:changeTouchEnable(false)
        self:showAllWildAni(effectData.isShowAll,function()
            self.m_skipEffectFunc = nil
            self.m_isSkip = false
            self:setSkipBtnShow(false)
            -- 记得完成所有动画后调用这两行
            -- 作用：标识这个动画播放完结，继续播放下一个动画
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.ADD_WILD_EFFECT then --添加wild
        self.m_humanNode:changeTouchEnable(false)
        self.m_isAddWild = true
        self:addWildAni(function()
            self.m_humanNode:changeTouchEnable(true)
            self.m_skipEffectFunc = nil
            self:setSkipBtnShow(false)
            self.m_isSkip = false

            effectData.p_isPlay = true
            self:playGameEffect()
        end)

    elseif effectData.p_selfEffectType == self.COPY_ROW_EFFECT then --整列复制
        self.m_humanNode:changeTouchEnable(false)
        self:runCopyReelAni(function()
            self.m_skipEffectFunc = nil
            self:setSkipBtnShow(false)
            self.m_isSkip = false
            self.m_humanNode:changeTouchEnable(true)
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.LOW_TO_HIGH_EFFECT then --低级图标变高级图标
        self.m_humanNode:changeTouchEnable(false)
        self:lowToHighAni(function()
            self.m_skipEffectFunc = nil
            self:setSkipBtnShow(false)
            self.m_isSkip = false
            self.m_humanNode:changeTouchEnable(true)
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.GET_COINS_EFFECT then --直接给钱
        self.m_humanNode:changeTouchEnable(false)
        self:getCoinsAni(function()
            self.m_humanNode:changeTouchEnable(true)
            self.m_skipEffectFunc = nil
            self:setSkipBtnShow(false)
            self.m_isSkip = false

            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.LINE_MULTI_EFFECT then --连线乘倍
        self:lineMultiAni(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

--[[
    连线乘倍
]]
function CodeGameScreenJollyFactoryMachine:lineMultiAni(func)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    local multi = fsExtraData.freemulit
    self:flyMultiToReelAni(multi,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    刷新free倍数
]]
function CodeGameScreenJollyFactoryMachine:updateFreeMulti(func)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_look_up_tip"])
    local csbAni = util_createAnimation("JollyFactory_Free_lookUp.csb")
    self:findChild("Node_yugao"):addChild(csbAni)
    csbAni:runCsbAction("start",false,function()
        if not tolua.isnull(csbAni) then
            csbAni:runCsbAction("idle",true)
        end
        self.m_baseFreeSpinBar:runJumpAni(fsExtraData.freemulit,function()
            if not tolua.isnull(csbAni) then
                csbAni:runCsbAction("over",false,function()
                    csbAni:removeFromParent()
                end)
            end
            if type(func) == "function" then
                func()
            end
        end)
    end)

    
end



--[[
    直接给钱
]]
function CodeGameScreenJollyFactoryMachine:getCoinsAni(func)
    local endFunc = function()
        self.m_skipEffectFunc = nil
        self:setSkipBtnShow(false)
        if self.m_flyMoney then
            self.m_flyMoney:stopAllActions()
            self.m_flyMoney:removeFromParent()
            self.m_flyMoney = nil
        end

        if not self:checkHasBigWin() then
            local winAmount = self.m_runSpinResultData.p_winAmount
            self:checkFeatureOverTriggerBigWin(winAmount,GameEffect.EFFECT_BONUS)
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_addCoinsLbl.m_addCoins))
            self:checkAddBigWinLight()
            self:sortGameEffects()
        end

        performWithDelay(self.m_waitNode,function()
            if type(func) == "function" then
                func()
            end
        end,0.5)
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or tolua.isnull(self.m_wildBonusSymbol) then
        endFunc()
        return
    end

    local extraCash = selfData.extraCash

    self.m_skipEffectFunc = function()
        local totalMulti = 0
        for index = 1,#extraCash do
            totalMulti  = totalMulti + extraCash[index]
        end
        
        totalMulti = toLongNumber(totalMulti * 100)
        local totalBet = self:getTotalBet()
        local winCoins = totalBet * totalMulti / 100

        self.m_addCoinsLbl:setVisible(true)
        self.m_addCoinsLbl:setCoins(winCoins)
        self.m_addCoinsLbl:runEndIdle(#extraCash)

        if not tolua.isnull(self.m_wildBonusSymbol) then
            self.m_wildBonusSymbol:runAnim("idleframe2",true)
        end

        self.m_humanNode:resumeDizzyAni()
        self:flyCoinsToTotalWin(function()
            endFunc()
        end)
    end

    self:setSkipBtnShow(true)
    if self.m_isSkip then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_wild_trigger"])
    self.m_wildBonusSymbol:runAnim("actionframe_cf",false,function()
        if not tolua.isnull(self.m_wildBonusSymbol) then
            self.m_wildBonusSymbol:runAnim("idleframe2",true)
        end
        if self.m_isSkip then
            return
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_watch_out"])
        --提示文字
        local tip = util_createAnimation("JollyFactory_BanShou_Tips.csb")
        self:findChild("Node_BanShou_Tips"):addChild(tip)
        tip:runCsbAction("auto",false,function()
            tip:removeFromParent()
        end)
        if not tolua.isnull(self.m_wildBonusSymbol) then
            self.m_humanNode:runLookUpAni()
        end

        performWithDelay(self.m_waitNode,function()
            if self.m_isSkip then
                return
            end
            
            self:addNextCoins(extraCash,1,function()
                if self.m_isSkip then
                    return
                end
                endFunc()
            end)
        end,180 / 60)
    end)
end

--[[
    添加下组金币
]]
function CodeGameScreenJollyFactoryMachine:addNextCoins(list,index,func)
    if self.m_isSkip then
        return
    end
    if index > #list then
        self:setSkipBtnShow(false)
        self.m_humanNode:resumeDizzyAni()
        performWithDelay(self.m_waitNode,function()
            self:flyCoinsToTotalWin(function()
                if type(func) == "function" then
                    func()
                end
            end)
        end,0.5)
        return
    end
    local multi = toLongNumber(list[index] * 100)
    local totalBet = self:getTotalBet()
    local winCoins = totalBet * multi / 100
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_get_coins"])

    self.m_humanNode:runHitBackAni(index,function()
        self:addNextCoins(list,index + 1,func)
    end)

    self.m_addCoinsLbl:setVisible(true)
    local aniTime = self.m_addCoinsLbl:runAddCoinsAni(index,winCoins)

    performWithDelay(self.m_waitNode,function()
        
    end,aniTime)
end

--[[
    飞倍数到轮盘
]]
function CodeGameScreenJollyFactoryMachine:flyMultiToReelAni(multi,func)
    local startNode = self.m_multiBox.m_multiLbl:findChild("m_lb_num")
    local endNode = self:findChild("Node_Free_tips")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_fly_multi_to_reel"])
    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    local flyNode = util_createAnimation("JollyFactory_Free_AllWins_multi.csb")
    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local m_lb_num = flyNode:findChild("m_lb_num")

    m_lb_num:setString(multi.."X")
    local info={label = m_lb_num,sx = 1,sy = 1}
    self:updateLabelSize(info,200)

    local actionList = {
        cc.EaseCubicActionOut:create(cc.MoveTo:create(30 / 60,endPos)),
        cc.CallFunc:create(function()
            

            
            if not tolua.isnull(flyNode) then
                flyNode:removeFromParent()
            end
        end)
    }

    local spine = util_spineCreate("JollyFactory_cbdy",true,true)
    self:findChild("Node_yugao"):addChild(spine)
    util_spinePlayAndRemove(spine,"actionframe",function()
        if type(func) == "function" then
            func()
        end
    end)

    flyNode:runAction(cc.Sequence:create(actionList))
    flyNode:runCsbAction("fly",false,function()
        
    end)
end

--[[
    飞倍数
]]
function CodeGameScreenJollyFactoryMachine:flyMultiAni(multi,startNode,func)
    local endNode = self.m_multiBox.m_multiLbl:findChild("m_lb_num")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_fly_multi_to_all_wins"])

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    local flyNode = util_createAnimation("JollyFactory_Free_tizi_xiaoban_fly.csb")
    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    local m_lb_num_1 = flyNode:findChild("m_lb_num_1")
    local m_lb_num_2 = flyNode:findChild("m_lb_num_2")

    m_lb_num_1:setString(multi.."X")
    m_lb_num_2:setString(multi.."X")
    if multi > 8 and multi <= 16 then
        m_lb_num_1:setVisible(false)
    else
        m_lb_num_2:setVisible(false)
    end

    local actionList = {
        cc.EaseCubicActionIn:create(cc.MoveTo:create(35 / 60,endPos)),
        cc.CallFunc:create(function()
            
            self.m_multiBox:runFeedBackAni(multi,function()
                if type(func) == "function" then
                    func()
                end
            end)
            

            if not tolua.isnull(flyNode) then
                flyNode:removeFromParent()
            end
        end)
    }

    flyNode:runAction(cc.Sequence:create(actionList))
    flyNode:runCsbAction("fly")
end

--[[
    金币飞到赢钱区
]]
function CodeGameScreenJollyFactoryMachine:flyCoinsToTotalWin(func)
    local startNode = self.m_addCoinsLbl.m_lblCsb
    local endNode = self.m_bottomUI.coinWinNode

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    local flyNode = util_createAnimation("JollyFactory_Money_Star.csb")
    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)

    self.m_flyMoney = flyNode

    local label = flyNode:findChild("m_lb_coins")
    label:setString(util_formatCoinsLN(self.m_addCoinsLbl.m_addCoins,30))
    local info={label = label,sx = 1,sy = 1}
    self:updateLabelSize(info,540)

    self.m_addCoinsLbl:runOverAni()

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_fly_coins_to_bottom"])

    self.m_addCoinsLbl:setLabelVisible(false)
    local actionList = {
        cc.EaseCubicActionIn:create(cc.MoveTo:create(30 / 60,endPos)),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_fly_coins_to_bottom_feed_back"])
            if not tolua.isnull(flyNode) then
                flyNode:setVisible(false)
            end

            local spine = util_spineCreate("JollyFactory_bigwin",true,true)
            endNode:addChild(spine)
            util_spinePlayAndRemove(spine,"actionframe_totalwin")

            if type(func) == "function" then
                func()
            end
        end)
    }

    flyNode:runAction(cc.Sequence:create(actionList))
    flyNode:runCsbAction("over")
end

--[[
    低级图标变高级图标
]]
function CodeGameScreenJollyFactoryMachine:lowToHighAni(func)

    local endFunc = function()
        self.m_sound_change_high_symbol = nil
        self:clearFlySymbol()
        self.m_skipEffectFunc = nil
        self:setSkipBtnShow(false)
        self:delayCallBack(0.5,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or tolua.isnull(self.m_wildBonusSymbol) then
        endFunc()
        return
    end

    

    local changeIcon = selfData.changeIcon --目标信号值
    local lowIcon = selfData.lowIcon    --低级图标位置

    local curCount = 0
    local totalCout  = #lowIcon

    self.m_skipEffectFunc = function()
        if self.m_sound_change_high_symbol then
            gLobalSoundManager:stopAudio(self.m_sound_change_high_symbol)
        end
        if not tolua.isnull(self.m_wildBonusSymbol) then
            self.m_wildBonusSymbol:runAnim("idleframe2",true)
        end
        self.m_wildBonusSpine_up:setVisible(false)
        for index = 1,totalCout do
            local posIndex = lowIcon[index]
            local symbolNode = self:getSymbolByPosIndex(posIndex)
            if not tolua.isnull(symbolNode) then
                self:changeSymbolType(symbolNode,changeIcon)
                self:putSymbolBackToPreParent(symbolNode)
                symbolNode:setVisible(true)
            end
        end
        self:hideBlackLayer()
        endFunc()
    end

    self:setSkipBtnShow(true)
    if self.m_isSkip then
        return
    end
    self.m_sound_change_high_symbol = gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_change_symbol_to_high"])

    --先把提层的小块放回
    for key,list in pairs(self.m_spcial_symbol_list) do
        if tonumber(key) ~= self.SYMBOL_FIX_BONUS and #list > 0 then
            for index,symbolNode in ipairs(list) do
                if not tolua.isnull(symbolNode) then
                    self:changeSymbolToBaseParent(symbolNode)
                end
            end
        end
    end

    local bindNode = self:getWildBonusBindNode()

    local delayTime = 70 / 30

    if not tolua.isnull(self.m_wildBonusSymbol) then
        local pos = util_convertToNodeSpace(self.m_wildBonusSymbol,self.m_effectNode)
        self.m_wildBonusSpine_up:setPosition(pos)
        self.m_wildBonusSpine_up:setVisible(true)
        self.m_humanNode:runSymbolToHighAni()
        self:showBlackLayer()
        for index = 1,totalCout do
            local posIndex = lowIcon[index]
            local symbolNode = self:getSymbolByPosIndex(posIndex)
            if not tolua.isnull(symbolNode) then
                self:changeSymbolToClipParent(symbolNode)
                symbolNode:runAnim("xuanzhong")
            end
        end
        --低级图标收回来
        util_spinePlay(self.m_wildBonusSpine_up,"cf_shang")
        self.m_wildBonusSymbol:runAnim("cf_di",false,function()
            if self.m_isSkip then
                return
            end
            --放出高级图标
            if not tolua.isnull(self.m_wildBonusSymbol) then
                self.m_wildBonusSymbol:runAnim("over_di",false,function()
                    if not tolua.isnull(self.m_wildBonusSymbol) then
                        self.m_wildBonusSymbol:runAnim("idleframe2",true)
                    end
                end)
            end

            if not tolua.isnull(self.m_wildBonusSpine_up) then
                util_spinePlay(self.m_wildBonusSpine_up,"over_shang")
                util_spineEndCallFunc(self.m_wildBonusSpine_up,"over_shang",function()
                    self.m_wildBonusSpine_up:setVisible(false)
                end)
            end
        end)
    end

    
    local offset = math.floor(totalCout / 3)
    for index = 1,totalCout do --20帧位移，分三次每次中间间隔3帧
        if index  > offset then
            curCount  = curCount + 1
        end
        local posIndex = lowIcon[index]
        performWithDelay(self.m_waitNode,function()
            if self.m_isSkip then
                return
            end
            local symbolNode = self:getSymbolByPosIndex(posIndex)
            if not tolua.isnull(symbolNode) then
                symbolNode:setVisible(false)
            end
            self:flySymbolToTargetPos(symbolNode,symbolNode,bindNode)
        end,(20 + 3 * curCount) / 30)
    end

    performWithDelay(self.m_waitNode,function()
        if self.m_isSkip then
            return
        end
        local flyTime = 15 / 30
        for index = 1,totalCout do
            local posIndex = lowIcon[index]
            local symbolNode = self:getSymbolByPosIndex(posIndex)
            self:changeSymbolType(symbolNode,changeIcon)
            self:putSymbolBackToPreParent(symbolNode)
            self:flySymbolToTargetPos(symbolNode,bindNode,symbolNode,function()
                if not tolua.isnull(symbolNode) then
                    symbolNode:setVisible(true)
                end
            end)
        end

        performWithDelay(self.m_waitNode,function()
            
            self:setSkipBtnShow(false)
            if self.m_isSkip then
                return
            end
            self:hideBlackLayer()
            performWithDelay(self.m_waitNode,function()
                if self.m_isSkip then
                    return
                end
                endFunc()
            end,20 / 30)
        end,flyTime)
    end,delayTime + 30 / 30)
end

--[[
    将小块放到低级图标层
]]
function CodeGameScreenJollyFactoryMachine:changeSymbolToBaseParent(slotNode)
    if tolua.isnull(slotNode)then
        --小块不存在 没有类型 或者没有所在列跳过
        return
    end
    local nZOrder = slotNode.p_showOrder

    local colIndex = slotNode.p_cloumnIndex
    local rowIndex = slotNode.p_rowIndex
    slotNode:setTag(self:getNodeTag(colIndex,rowIndex,SYMBOL_NODE_TAG))
    local reelNode = self.m_baseReelNodes[colIndex]
    local rollNode = reelNode:getRollNodeByRowIndex(rowIndex)
    util_changeNodeParent(rollNode,slotNode)
    
    reelNode:setRollNodeZOrder(rollNode,slotNode.p_rowIndex,nZOrder,false)
    slotNode:setPosition(cc.p(0,0))
end

--[[
    清理飞行的小块
]]
function CodeGameScreenJollyFactoryMachine:clearFlySymbol()
    for index = 1,#self.m_flySymbolList do
        local flyNode = self.m_flySymbolList[index]
        flyNode:removeFromParent()
    end
    self.m_flySymbolList = {}
end

--[[
    获取wildBonus的定位点
]]
function CodeGameScreenJollyFactoryMachine:getWildBonusBindNode()
    local aniNode = self.m_wildBonusSymbol:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and tolua.isnull(spine.m_bindNode) then

        local bindNode = cc.Node:create()
        util_spinePushBindNode(spine,"dingwei",bindNode)
        spine.m_bindNode = bindNode
    end

    return spine.m_bindNode
end

--[[
    飞图标动画
]]
function CodeGameScreenJollyFactoryMachine:flySymbolToTargetPos(symbolNode,startNode,endNode,func)
    if tolua.isnull(symbolNode) then
        if type(func) == "function" then
            func()
        end
        return
    end
    local symbolType = symbolNode.p_symbolType
    local rowIndex = symbolNode.p_rowIndex

    local symbolName = self:getSymbolCCBNameByType(self,symbolType)
    local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
            
    local flyNode = util_createAnimation("JollyFactory_gftb.csb")
    self.m_flySymbolList[#self.m_flySymbolList + 1] = flyNode
    local isSpine = false
    if spineSymbolData then
        isSpine = true
        local spine = util_spineCreate(symbolName,true,true)
        util_spinePlay(spine,"fly",false)
        util_spineEndCallFunc(spine,"fly",function()
            if type(func) == "function" then
                func()
            end
            util_spinePlayAndRemove(spine,"start",function()
                if not tolua.isnull(flyNode) then
                    flyNode:setVisible(false)
                end
            end)
        end)
        flyNode:findChild("Node_tb"):addChild(spine)
    else
        local csbAni = util_createAnimation(symbolName..".csb")
        csbAni:runCsbAction("fly",false,function()
            if type(func) == "function" then
                func()
            end
            if not tolua.isnull(flyNode) then
                flyNode:setVisible(false)
            end
        end)
        flyNode:addChild(csbAni)
    end

    self.m_effectNode:addChild(flyNode)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    flyNode:setPosition(startPos)

    local midNode = self:findChild("Node_weiyidian")
    local midPos = util_convertToNodeSpace(midNode,self.m_effectNode)

    if isSpine then
        local midPosY = endPos.y + self.m_SlotNodeH * (5 - rowIndex)

        midPos = cc.p((startPos.x + endPos.x) / 2,midPosY)

        local actionList = {
            cc.EaseQuadraticActionInOut:create(cc.MoveTo:create(15 / 30,endPos)),
        }
        flyNode:runAction(cc.Sequence:create(actionList))
        flyNode:runCsbAction("fly")
    else
        local actionList = {
            cc.BezierTo:create(27 / 60, {startPos, cc.p(startPos.x, midPos.y), midPos}),
            cc.BezierTo:create(13 / 60, {midPos, cc.p(midPos.x, endPos.y), endPos})
            -- cc.EaseSineOut:create(cc.BezierTo:create(27 / 60, {startPos, cc.p(startPos.x, midPos.y), midPos})),
            -- cc.EaseSineIn:create(cc.BezierTo:create(13 / 60, {midPos, cc.p(midPos.x, endPos.y), endPos}))
        }
        flyNode:runAction(cc.Sequence:create(actionList))
    end
end

--[[
    复制整列
]]
function CodeGameScreenJollyFactoryMachine:runCopyReelAni(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        if type(func) == "function" then
            func()
        end
        return
    end
    local copyColumns = selfData.copyColumns + 1

    --先把提层的小块放回
    for key,list in pairs(self.m_spcial_symbol_list) do
        if #list > 0 then
            for index,symbolNode in ipairs(list) do
                if not tolua.isnull(symbolNode) then
                    self:putSymbolBackToPreParent(symbolNode)
                end
            end
        end
    end

    local copyReelNode = self.m_baseReelNodes[copyColumns]
    local symbolList = copyReelNode.m_netList
    local longInfoList = copyReelNode.m_LongSymbolInfo

    local endFunc = function()
        self.m_sound_copy_reel = nil
        self.m_humanNode:hideLight()
        for iCol = 2,self.m_iReelColumnNum do
            if iCol ~= copyColumns then
                local reelNode = self.m_baseReelNodes[iCol]
                reelNode:reloadSymbolByList(symbolList,longInfoList)
                reelNode:setVisible(true)
                reelNode:resetRollNodePos()
            end
        end
        if type(func) == "function" then
            func()
        end
    end

    self.m_skipEffectFunc = function()
        if self.m_sound_copy_reel then
            gLobalSoundManager:stopAudio(self.m_sound_copy_reel)
        end
        endFunc()
    end
    self:setSkipBtnShow(true)
    if self.m_isSkip then
        return
    end

    self.m_sound_copy_reel = gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_shake_reel"])

    self.m_humanNode:copyReelAni(copyColumns,function()
        if self.m_isSkip then
            return
        end
        endFunc()
    end)

    --图标掉出显示区域
    performWithDelay(self.m_waitNode,function()
        if self.m_isSkip then
            return
        end
        for iCol = 2,self.m_iReelColumnNum do
            if iCol ~= copyColumns then
                local reelNode = self.m_baseReelNodes[iCol]
                reelNode:runSymbolOutAni()
                performWithDelay(self.m_waitNode,function()
                    if self.m_isSkip then
                        return
                    end
                    reelNode:reloadSymbolByList(symbolList,longInfoList)
                    reelNode:setVisible(false)
                end,7 / 30)
            end
        end
    end,13 / 30)

    --往左复制
    performWithDelay(self.m_waitNode,function()
        if self.m_isSkip then
            return
        end
        if copyColumns <= 2 then
            return
        end
        local count = 0
        for iCol = 2,copyColumns - 1 do
            performWithDelay(self.m_waitNode,function()
                if self.m_isSkip then
                    return
                end
                self:copyReelToOther(copyColumns,iCol,copyReelNode,symbolList,function()
                    local reelNode = self.m_baseReelNodes[iCol]
                    reelNode:resetRollNodePos()
                    reelNode:setVisible(true)
                end)
            end,0.1 * count)
            count  = count + 1
        end
        

    end,53 / 30)

    --往右复制
    performWithDelay(self.m_waitNode,function()
        if self.m_isSkip then
            return
        end
        if copyColumns == self.m_iReelColumnNum then
            return
        end
        local count = 0
        for iCol = self.m_iReelColumnNum , copyColumns + 1, -1 do
            performWithDelay(self.m_waitNode,function()
                if self.m_isSkip then
                    return
                end
                self:copyReelToOther(copyColumns,iCol,copyReelNode,symbolList,function()
                    local reelNode = self.m_baseReelNodes[iCol]
                    reelNode:resetRollNodePos()
                    reelNode:setVisible(true)
                end)
            end,0.1 * count)
            count  = count + 1
        end
    end,84 / 30)
end

function CodeGameScreenJollyFactoryMachine:copyReelToOther(copyCol,targetCol,copyReel,symbolList,func)
    if self.m_isSkip then
        return
    end
    local offsetX = 20
    if copyCol < targetCol then
        offsetX = -20
    end

    for iRow = 1,#symbolList do
        local symbolNode = self:getFixSymbol(copyCol,iRow)
        local longInfo
        if not tolua.isnull(symbolNode) then
            longInfo = symbolNode.m_longInfo
        end
        local isInLong = false
        if longInfo and iRow > longInfo.startIndex and iRow <= longInfo.startIndex + longInfo.curCount - 1 then
            isInLong = true
        end
        if not tolua.isnull(symbolNode) and not isInLong then
            local tarReelNode = self.m_baseReelNodes[targetCol]
            local rollNode = tarReelNode:getRollNodeByRowIndex(iRow)

            local startPos = util_convertToNodeSpace(symbolNode,self.m_copyClipLayer)
            local endPos = util_convertToNodeSpace(rollNode,self.m_copyClipLayer)
            endPos.y = startPos.y
            local symbolType = symbolList[iRow]
            local symbolName = self:getSymbolCCBNameByType(self,symbolType)
            local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
            
            local symbolAni
            if spineSymbolData then
                symbolAni = util_spineCreate(symbolName,true,true)
                util_spinePlay(symbolAni,"idleframe")
            else
                symbolAni = util_createAnimation(symbolName..".csb")
                symbolAni:runCsbAction("idleframe")
            end

            local zOrder = self:getBounsScatterDataZorder(symbolType) - iRow + targetCol * 10
            self.m_copyClipLayer:addChild(symbolAni,zOrder)
            self.m_copyList[#self.m_copyList + 1] = symbolAni
            symbolAni:setPosition(startPos)

            local actionList = {
                -- cc.EaseExponentialIn:create(cc.MoveTo:create(5 / 30,endPos)),
                cc.MoveTo:create(5 / 30,endPos),
                cc.EaseSineInOut:create(cc.MoveTo:create(5 / 30,cc.p(endPos.x + offsetX,endPos.y))),
                cc.EaseSineInOut:create(cc.MoveTo:create(5 / 30,endPos)),
                cc.Hide:create()
            }
            symbolAni:runAction(cc.Sequence:create(actionList))
        end
        
    end

    performWithDelay(self.m_waitNode,function()
        if type(func) == "function" then
            func()
        end
    end,15 / 30)
end

--[[
    添加wild
]]
function CodeGameScreenJollyFactoryMachine:addWildAni(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local wildList = {}
    for iRow = 1,self.m_iReelRowNum do
        wildList[iRow] = {0,0,0,0,0}         
    end

    local wildcolPos = selfData.wildcolPos
    if wildcolPos then
        for iCol = 1,#wildcolPos do
            if wildcolPos[iCol] ~= 0 then
                for iRow = 1,self.m_iReelRowNum do
                    wildList[iRow][iCol] = 1
                end
            end
        end
    end
    
    
    local wildIcon = selfData.wildIcon
    if wildIcon then
        for index = 1,#wildIcon do
            local posIndex = wildIcon[index]
            local posData = self:getRowAndColByPos(posIndex)
            local iCol,iRow = posData.iY,posData.iX
            wildList[iRow][iCol] = 1
            -- self:createWildOnSymbol(iCol,iRow)
        end
    end

    local endFunc = function()
        self.m_skipEffectFunc = nil
        self:setSkipBtnShow(false)
        for iRow = 1,#wildList do
            for iCol = 1,self.m_iReelColumnNum do
                if wildList[iRow][iCol] ~= 0 then
                    self:createWildOnSymbol(iCol,iRow)
                end
            end
            
        end
        
        self:delayCallBack(0.5,function()
            for iCol = 1,self.m_iReelColumnNum do
                self:hideBlackLayer(iCol)
            end
            if type(func) == "function" then
                func()
            end
        end)
        

        

        --清空掉落的wild图标
        self:clearDropWild()
    end

    self.m_skipEffectFunc = function()
        self.m_humanNode:runBaseIdle()
        endFunc()
    end
    self:setSkipBtnShow(true)
    if self.m_isSkip then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_wild_trigger"])

    for key,list in pairs(self.m_spcial_symbol_list) do
        if #list > 0 then
            for index,symbolNode in ipairs(list) do
                if not tolua.isnull(symbolNode) then
                    self:putSymbolBackToPreParent(symbolNode)
                end
            end
        end
    end

    if not tolua.isnull(self.m_wildBonusSymbol) then
        for iCol = 1,self.m_iReelColumnNum do
            self:showBlackLayer(iCol)
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_wild_trigger"])
        self.m_wildBonusSymbol:runAnim("actionframe_cf",false,function()
            if not tolua.isnull(self.m_wildBonusSymbol) then
                self.m_wildBonusSymbol:runAnim("idleframe2",true)
            end
            if self.m_isSkip then
                return
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_add_wild"])
            self.m_humanNode:runAddWildAni(function()
                if self.m_isSkip then
                    return
                end
                self:dropWildAni(wildList,function()
                    if self.m_isSkip then
                        return
                    end
                    self.m_humanNode:runAddWildOverAni(function()
                        self.m_humanNode:runBaseIdle()
                    end)
                    endFunc()
                end)
            end)
        end)
    else
        endFunc()
    end
end

--[[
    掉落wild动画
]]
function CodeGameScreenJollyFactoryMachine:dropWildAni(wildList,func)

    local flyTime,delayTime,aniTime = 28 / 30,0,0

    local selfData = self.m_runSpinResultData.p_selfMakeData
    
    local wildcolPos = selfData.wildcolPos or {0,0,0,0,0}
    local downList = {}

    local colList = {}
    for iRow = 1,#wildList do
        for iCol = 1,#wildList[iRow] do
            if wildList[iRow][iCol] == 1 and not table_vIn(colList,iCol) then
                colList[#colList + 1] = iCol
            end
        end
    end
    --打乱数组
    randomShuffle(colList)

    local wildColCount = 0
    for index = 1,#colList do
        local iCol = colList[index]
        local isHaveWild = false
        for iRow = 1,#wildList do
        
            if wildList[iRow][iCol] ~= 0 then
                local time1,time2 = 0,0

                time1 = wildColCount * 0.2

                isHaveWild = true

                local reelNode = self.m_baseReelNodes[iCol]
                local rollNode,bigRollNode = reelNode:getRollNodeByRowIndex(iRow)
                local wildAni = util_spineCreate("Socre_JollyFactory_Wild",true,true)
                local zOrder = iCol * 10 + iRow
                local endPos = util_convertToNodeSpace(rollNode,self.m_effectNode)
                local startPos = cc.p(endPos.x,display.height + self.m_SlotNodeH * iRow)
                self.m_effectNode:addChild(wildAni,zOrder)
                
                wildAni:setPosition(startPos)

                

                if wildcolPos[iCol] == 1 then
                    
                    time2 = 0.1 * (iRow - 1)
                end
                if time1 + time2 > delayTime then
                    delayTime = time1 + time2
                end

                local actionList = {
                    cc.DelayTime:create(time1),
                    cc.CallFunc:create(function()
                        if wildcolPos[iCol] ~= 1 then
                            util_spinePlay(wildAni,"idleframe3",true)
                        else
                            if iRow ~= self.m_iReelRowNum then
                                util_spinePlay(wildAni,"idleframe4",true)
                            else
                                util_spinePlay(wildAni,"idleframe3",true)
                            end
                        end
                    end),
                    cc.EaseCubicActionIn:create(cc.MoveTo:create(flyTime,endPos)),
                    cc.DelayTime:create(time2),
                    cc.CallFunc:create(function()
                        if not tolua.isnull(wildAni) then
                            if wildcolPos[iCol] == 1 then
                                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_add_wild_down"])
                            elseif not downList[iCol] then
                                gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_add_wild_down"])
                            end
                            downList[iCol] = true
                            
                            util_spinePlay(wildAni,"actionframe2")
                        end
                    end)
                }
                aniTime = wildAni:getAnimationDurationTime("actionframe2")
                wildAni:runAction(cc.Sequence:create(actionList))
                self.m_dropWildList[#self.m_dropWildList + 1] = wildAni
                
            end

            
        end

        if isHaveWild then 
            wildColCount  = wildColCount + 1
        end
    end

    performWithDelay(self.m_waitNode,function()
        if type(func) == "function" then
            func()
        end
    end,flyTime + delayTime + aniTime)
end 

--[[
    清空掉落的wild动画
]]
function CodeGameScreenJollyFactoryMachine:clearDropWild()
    for index = 1,#self.m_dropWildList do
        local wildAni = self.m_dropWildList[index]
        wildAni:stopAllActions()
        wildAni:removeFromParent()
    end
    self.m_dropWildList = {}
end

--[[
    清空复制的图标动画
]]
function CodeGameScreenJollyFactoryMachine:clearCopySymbol()
    self.m_copyClipLayer:removeAllChildren()
    self.m_copyList = {}    --复制图标列表
end

--[[
    在对应位置的小块上创建一个wild图标
]]
function CodeGameScreenJollyFactoryMachine:createWildOnSymbol(colIndex,rowIndex)
    local symbolNode = self:getFixSymbol(colIndex,rowIndex)
    if not tolua.isnull(symbolNode) and not symbolNode.m_longInfo then --该位置不是长条信号
        self:changeSymbolType(symbolNode,TAG_SYMBOL_TYPE.SYMBOL_WILD)
        local reelNode = self.m_baseReelNodes[colIndex]
        local rollNode,bigRollNode = reelNode:getRollNodeByRowIndex(rowIndex)
        util_changeNodeParent(bigRollNode,symbolNode)
        self.m_addWildList[#self.m_addWildList + 1] = symbolNode
    else --如果是长条信号则创建一个wild信号盖在上面
        local symbolNode = self:getSlotNodeWithPosAndType(TAG_SYMBOL_TYPE.SYMBOL_WILD,rowIndex,colIndex)
        local reelNode = self.m_baseReelNodes[colIndex]
        local rollNode,bigRollNode = reelNode:getRollNodeByRowIndex(rowIndex)
        bigRollNode:addChild(symbolNode)
        self.m_addWildList[#self.m_addWildList + 1] = symbolNode
    end
end

--[[
    拉伸wild
]]
function CodeGameScreenJollyFactoryMachine:showAllWildAni(isShowAll,func)

    if isShowAll then
        if self.m_bClickQuickStop then
            self:delayCallBack(1,function()
                if type(func) == "function" then
                    func()
                end
            end)
        else
            if type(func) == "function" then
                func()
            end
        end
        
        return 
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_all_wild"])
    

    local isUp = false
    local reels = self.m_runSpinResultData.p_reels
    for iRow = self.m_iReelRowNum,1,-1 do
        if reels[iRow][1] ~= self.SYMBOL_FIX_BONUS then
            break
        elseif iRow == self.m_iReelRowNum then
            isUp = true
        end
    end

    local endFunc = function()
        
        if tolua.isnull(self.m_wildBonusSymbol) then
            if type(func) == "function" then
                func()
            end
            return
        end

        self.m_wildBonusSymbol:stopAllActions()
        
        -- --移除第三列滚动点上的小块
        local reelNode = self.m_baseReelNodes[1]
        if not tolua.isnull(reelNode) then
            local rollNodes = reelNode.m_rollNodes
            local iRow = 1
            self.m_scheduleNode:stopAllActions()
            util_schedule(self.m_scheduleNode,function()
                if iRow > #rollNodes then
                    self.m_scheduleNode:stopAllActions()
                    return
                end
                if iRow <= self.m_iReelRowNum then
                    --如果不是全显示需要拉伸,则需移除原滚动点上的小块
                    reelNode:removeSymbolByRowIndex(iRow)
                else
                    --如果是向下拉伸,上面的滚动点需重新补块
                    if not self.m_wildBonusSymbol.isUp then
                        reelNode:reloadRollNode(rollNodes[iRow],iRow)
                    end
                end
                iRow  = iRow + 1
            end,1 / 60)
        end
        --将wild小块从长条裁切层移到clipParent上
        self:changeSymbolToClipParent(self.m_wildBonusSymbol)
        if self.m_wildBonusSymbol.m_longClipNode then
            self.m_wildBonusSymbol.m_longClipNode:removeFromParent()
            self.m_wildBonusSymbol.m_longClipNode = nil
        end

        if self.m_wildBonusSymbol.m_longInfo then
            self.m_wildBonusSymbol.m_longInfo.startIndex = 1
            self.m_wildBonusSymbol.m_longInfo.curCount = 4
            self.m_wildBonusSymbol.p_rowIndex = 1
        end
        -- self:levelDeviceVibrate(6, "bonus")
        util_shakeNode(self:findChild("root"),3,3,0.3)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_wild_move_down"])
        self.m_wildBonusSymbol:runAnim("actionframe_fk",false,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    end

    self.m_skipEffectFunc = endFunc

    --显示跳过按钮
    self:setSkipBtnShow(true)

    if self.m_isSkip then
        return
    end
    if not tolua.isnull(self.m_wildBonusSymbol) then
        self.m_wildBonusSymbol.m_isUp = isUp
    end

    if not tolua.isnull(self.m_wildBonusSymbol) then 
        --变更wild信号行索引
        self.m_wildBonusSymbol.p_rowIndex = 1

        local aniName = "move_down"
        if isUp then
            aniName = "move_up"
        end

        self.m_wildBonusSymbol:runAnim(aniName,false,function()
            if self.m_isSkip then
                return
            end
            if not tolua.isnull(self.m_wildBonusSymbol) then

                --计算拉伸的最终位置
                local posIndex = self:getPosReelIdx(self.m_wildBonusSymbol.p_rowIndex, self.m_wildBonusSymbol.p_cloumnIndex)
                local pos = util_getOneGameReelsTarSpPos(self, posIndex)
                local worldPos = self.m_clipParent:convertToWorldSpace(pos)
                local nodePos = self.m_wildBonusSymbol:getParent():convertToNodeSpace(worldPos)

                local actionList = {
                    cc.EaseQuarticActionIn:create(cc.MoveTo:create(0.3,nodePos)),
                    cc.CallFunc:create(function()
                        
                        endFunc()
                    end)
                }
                self.m_wildBonusSymbol:runAction(cc.Sequence:create(actionList))
            end
        end)
    else
        
        endFunc()
    end

    
end



function CodeGameScreenJollyFactoryMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenJollyFactoryMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

-- free和freeMore特殊需求
function CodeGameScreenJollyFactoryMachine:playScatterTipMusicEffect()
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
function CodeGameScreenJollyFactoryMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end


function CodeGameScreenJollyFactoryMachine:checkRemoveBigMegaEffect()
    CodeGameScreenJollyFactoryMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenJollyFactoryMachine:getShowLineWaitTime()
    local time = self.super.getShowLineWaitTime(self)
    local winLines = self.m_reelResultLines or {}
    local lineValue = winLines[1] or {}
    if #winLines == 1 and lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        time = 0
    end

    local time = CodeGameScreenJollyFactoryMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------
function CodeGameScreenJollyFactoryMachine:showEffect_Bonus(effectData)
    local endFunc = function(params)
        
        if params.isJackpot then
            
            self.m_runSpinResultData.p_features = {0}
            self:checkFeatureOverTriggerBigWin(params.winCoins,GameEffect.EFFECT_BONUS)
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(params.winCoins))
            self:showJackpotView(params.winCoins,params.rewardType,function()
                self:resetMusicBg()
                self:setMinMusicBGVolume()
                self.m_bottomUI:notifyTopWinCoin()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        elseif params.rewardType == "coins" or params.rewardType == "lu" then

            self.m_runSpinResultData.p_features = {0}
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(params.winCoins))
            self:checkFeatureOverTriggerBigWin(params.winCoins,GameEffect.EFFECT_BONUS)
            self:showWheelWinView(params.winCoins,function()
                self:resetMusicBg()
                self:setMinMusicBGVolume()
                self.m_bottomUI:notifyTopWinCoin()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        elseif params.rewardType == "free" then
            self.m_isFirstFree = true
            if not self:checkHasFreeEffect() then
                -- 添加freespin effect
                local freeSpinEffect = GameEffectData.new()
                freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
                freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
                self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            end
            self:clearCurMusicBg()
            self:changeSceneToFree(function()
                self:showFreeUI()
            end,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)

            
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local wheelContens = selfData.wheelContents
    self.m_wheelView:resetWheel(wheelContens)
    self:delayCallBack(0.5,function()
        self:clearWinLineEffect()
        self:clearCurMusicBg()
        self:runScatterTriggerAni(function()
            self:showWheelStart(function()
                self:resetMusicBg(true,"JollyFactorySounds/music_JollyFactory_wheel.mp3")
                self.m_wheelView:setEndFunc(endFunc)
            end)
        end)
    end)

    return true
end

--[[
    最后一次spin
]]
function CodeGameScreenJollyFactoryMachine:showLastSpinAni(func)
    local spine = util_spineCreate("JollyFactory_Free_liwuhe",true,true)
    self:findChild("root"):addChild(spine)

    -- self.m_baseFreeSpinBar:setBoxVisible(false)
    util_spinePlayAndRemove(spine,"actionframe",function()
        self.m_multiBox:runFeedBackAni(25,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    end)
end

--[[
    过场动画
]]
function CodeGameScreenJollyFactoryMachine:changeSceneToBase(keyFunc,endFunc)
    local spine = util_spineCreate("JollyFactory_juese",true,true)
    self:findChild("root"):addChild(spine)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_change_scene_to_base"])

    util_spinePlayAndRemove(spine,"actionframe_guochang",function()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    self:delayCallBack(40 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)
end

--[[
    过场动画
]]
function CodeGameScreenJollyFactoryMachine:changeSceneToFree(keyFunc,endFunc)

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    self:resetMusicBg()

    local spine = util_spineCreate("JollyFactory_Free_liwuhe",true,true)
    self:findChild("root"):addChild(spine)

    self.m_baseFreeSpinBar:setBoxVisible(false)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_change_scene_to_free"])
    local aniTime = util_spinePlayAndRemove(spine,"actionframe_guochang",function()
        
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_tizi_rise"])
        self.m_baseFreeSpinBar:setBoxVisible(true)
    end)
    self:delayCallBack(aniTime - 0.5,function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_shake_view"])
        util_shakeNode(self:findChild("root"),5,5,0.5)
    end)

    self:delayCallBack(43 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)

    self:delayCallBack(110 / 30,function()
        if not tolua.isnull(spine) then
            util_changeNodeParent(self.m_baseFreeSpinBar:findChild("Node_Free_liwuhe"),spine)
        end
    end)

    
    self:runCsbAction("move",false,function()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

--[[
    显示free相关UI
]]
function CodeGameScreenJollyFactoryMachine:showFreeUI()
    self:showFreeSpinBar()
    self:hideWheelView()
    self.m_jackPotBarView:setVisible(false)
    self.m_humanNode:runHideHumanAni()
    self.m_multiBox:setVisible(true)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    self.m_multiBox:updateMulti(fsExtraData.freemulit)
end

--[[
    隐藏free相关UI
]]
function CodeGameScreenJollyFactoryMachine:hideFreeUI()
    self.m_jackPotBarView:setVisible(true)
    self.m_humanNode:runBaseIdle()
    self:hideFreeSpinBar()
    self.m_multiBox:setVisible(false)
end


function CodeGameScreenJollyFactoryMachine:checkHasFreeEffect()
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_effectType
        if value == GameEffect.EFFECT_FREE_SPIN and not self.m_gameEffects[i].p_isPlay then
            return true
        end
    end

    return false
end

function CodeGameScreenJollyFactoryMachine:showWheelView()
    self.m_wheelView:showView()
    self.m_humanNode.m_mainReelNode:setVisible(false)
    self.m_humanNode:runWheelIdle()
end


function CodeGameScreenJollyFactoryMachine:hideWheelView()
    self.m_wheelView:setVisible(false)
    self.m_jackPotBarView:hideLights()
    self.m_humanNode.m_mainReelNode:setVisible(true)
    self.m_humanNode:runBaseIdle()
    self.m_humanNode:hideMiLu()
end

--[[
    转盘玩法赢钱弹板
]]
function CodeGameScreenJollyFactoryMachine:showWheelWinView(coins,func)
    self:clearCurMusicBg()

    local autoType
    if globalData.slotRunData.m_isAutoSpinAction then
        autoType = BaseDialog.AUTO_TYPE_NOMAL
    end

    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoinsLN(toLongNumber(coins), 30)
    local view = self:showDialog("FreeSpinOver", ownerlist, func,autoType)

    local light = util_createAnimation("JollyFactory_zhuanguang.csb")
    view:findChild("Node_zhuanguang"):addChild(light)
    light:runCsbAction("idle",true)

    local spine = util_spineCreate("JollyFactory_juese",true,true)
    view:findChild("Node_renwu"):addChild(spine)
    util_spinePlay(spine,"tb_idleframe3",true)

    local spine2 = util_spineCreate("Socre_JollyFactory_5",true,true)
    view:findChild("Node_jueseZou"):addChild(spine2)
    util_spinePlay(spine2,"idle2",true)

    local spine3 = util_spineCreate("Socre_JollyFactory_7",true,true)
    view:findChild("Node_jueseYou"):addChild(spine3)
    util_spinePlay(spine3,"idle2",true)

    view:findChild("Node_freeOver"):setVisible(false)

    self:delayCallBack(50 / 60,function()
        self:hideWheelView()
    end)

    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.85,sy=0.85},832)    

    view:findChild("root"):setScale(self.m_machineRootScale)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_wild_over"])
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_btn_click"])
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_hide_wild_over"])
    end)

    return view
end

--[[
    触发动画
]]
function CodeGameScreenJollyFactoryMachine:runScatterTriggerAni(func)
    local waitTime = 0
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_scatter_trigger"])
    for index = 1,self.m_iReelRowNum * self.m_iReelColumnNum do
        local symbolNode = self:getSymbolByPosIndex(index - 1)
        if not tolua.isnull(symbolNode) and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local parent = symbolNode:getParent()
            if parent ~= self.m_clipParent then
                self:changeSymbolToClipParent(symbolNode)
            end
            symbolNode:runAnim("actionframe",false,function()
                symbolNode:runAnim("idleframe2",true)
                self:putSymbolBackToPreParent(symbolNode)
            end)
            local duration = symbolNode:getAniamDurationByName("actionframe")
            waitTime = util_max(waitTime,duration)
        end
    end

    self:delayCallBack(waitTime,func)
end

--[[
    转盘玩法开始弹板
]]
function CodeGameScreenJollyFactoryMachine:showWheelStart(func)
    local ownerlist = {}

    local autoType
    if globalData.slotRunData.m_isAutoSpinAction then
        autoType = BaseDialog.AUTO_TYPE_NOMAL
    end

    local view = self:showDialog("WheelStart", ownerlist, func,autoType)

    local light = util_createAnimation("JollyFactory_zhuanguang_0.csb")
    view:findChild("Node_zhuanguang"):addChild(light)
    light:runCsbAction("idle",true)

    local spine = util_spineCreate("JollyFactory_juese",true,true)
    view:findChild("Node_renwu"):addChild(spine)
    util_spinePlay(spine,"tb_idleframe2",true)

    self:delayCallBack(28 / 60,function()
        self:showWheelView()
    end)

    view:findChild("root"):setScale(self.m_machineRootScale)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_wheel_start"])
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_btn_click"])
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_hide_wheel_start"])
    end)

    return view
    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end


function CodeGameScreenJollyFactoryMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeJollyFactorySrc.JollyFactoryFreeMultiBar",{machine = self})
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_Free_tizi"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenJollyFactoryMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
    local fsExtraData = self.m_runSpinResultData.p_fsExtraData
    self.m_baseFreeSpinBar:resetView(fsExtraData.freemulit)
end

function CodeGameScreenJollyFactoryMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(false)
end

function CodeGameScreenJollyFactoryMachine:showFreeSpinView(effectData)

    local showFSView = function ()
        self:triggerFreeSpinCallFun()
        effectData.p_isPlay = true
        self:playGameEffect() 
    end


    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

function CodeGameScreenJollyFactoryMachine:triggerFreeSpinCallFun()
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
end

function CodeGameScreenJollyFactoryMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("JollyFactorySounds/music_JollyFactory_over_fs.mp3")
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_show_free_over"])
    self:clearCurMusicBg()
    local view = self:showFreeSpinOver(
        toLongNumber(self.m_runSpinResultData.p_fsWinCoins), 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:changeSceneToBase(function()
                self:hideFreeUI()
            end,function()
                self:triggerFreeSpinOverCallFun()
            end)
            
        end
    )

    view:findChild("root"):setScale(self.m_machineRootScale)

    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_btn_click"])
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_hide_free_over"])
    end)
     
end

function CodeGameScreenJollyFactoryMachine:showFreeSpinOver(coins, num, func)

    local autoType
    if globalData.slotRunData.m_isAutoSpinAction then
        autoType = BaseDialog.AUTO_TYPE_NOMAL
    end
    
    local ownerlist = {}
    if coins > toLongNumber(0) then
        ownerlist["m_lb_coins"] = util_formatCoinsLN(coins, 30)
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func,autoType)

        local light = util_createAnimation("JollyFactory_zhuanguang.csb")
        view:findChild("Node_zhuanguang"):addChild(light)
        light:runCsbAction("idle",true)

        local spine = util_spineCreate("JollyFactory_juese",true,true)
        view:findChild("Node_renwu"):addChild(spine)
        util_spinePlay(spine,"tb_idleframe3",true)

        local spine2 = util_spineCreate("Socre_JollyFactory_5",true,true)
        view:findChild("Node_jueseZou"):addChild(spine2)
        util_spinePlay(spine2,"idle2",true)

        local spine3 = util_spineCreate("Socre_JollyFactory_7",true,true)
        view:findChild("Node_jueseYou"):addChild(spine3)
        util_spinePlay(spine3,"idle2",true)

        view:findChild("Node_wheelOver"):setVisible(false)

        local node=view:findChild("m_lb_coins")
        view:updateLabelSize({label=node,sx=0.85,sy=0.85},832) 
        return view  
    else
        local view = self:showDialog("NoWin", ownerlist, func,autoType)
        return view
    end
    
end

function CodeGameScreenJollyFactoryMachine:showEffect_FreeSpin(effectData)
    -- 用服务器给的触发数据播触发动画
    self.m_beInSpecialGameTrigger = true

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:stopLinesWinSound()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    self:showFreeSpinView(effectData)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

---
    -- 逐条线显示 线框和 Node 的actionframe
    --
function CodeGameScreenJollyFactoryMachine:showLineFrameByIndex(winLines,frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        return
    end
    self.super.showLineFrameByIndex(self, winLines, frameIndex)    
end

---
    -- 显示所有的连线框
    --
function CodeGameScreenJollyFactoryMachine:showAllFrame(winLines)
    local tempLineValue = {}
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN then
            table.insert(tempLineValue, lineValue)
        end
    end
    self.super.showAllFrame(self, tempLineValue)    
end

function CodeGameScreenJollyFactoryMachine:getFsTriggerSlotNode(parentData, symPosData)
    return self:getFixSymbol(symPosData.iY, symPosData.iX)    
end

function CodeGameScreenJollyFactoryMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeJollyFactorySrc.JollyFactoryJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_JackpotBar"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenJollyFactoryMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeJollyFactorySrc.JollyFactoryJackpotWinView",{
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

    self:delayCallBack(15 / 60,function()
        self:hideWheelView()
    end)
end

--[[
        播放预告中奖统一接口
    ]]
function CodeGameScreenJollyFactoryMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance(40) then

        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
    elseif self:getCurrSpinMode() == FREE_SPIN_MODE then
        local fsExtraData = self.m_runSpinResultData.p_fsExtraData
        if fsExtraData and fsExtraData.freemulit > self.m_baseFreeSpinBar.m_curIndex then
            self:updateFreeMulti(function()
                if type(_func) == "function" then
                    _func()
                end
            end)
        else
            if type(_func) == "function" then
                _func()
            end
        end
        
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
function CodeGameScreenJollyFactoryMachine:playFeatureNoticeAni(func)
    self.b_gameTipFlag = true
    --动效执行时间
    local aniTime = 0

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_notice_win"])

    self.m_noticeAni:setVisible(true)
    util_spinePlay(self.m_noticeAni.m_spine1,"actionframe_yugao")
    util_spinePlay(self.m_noticeAni.m_spine2,"actionframe_yugao3")
    self.m_noticeAni:runCsbAction("actionframe_yugao")

    for index = 1,4 do
        local particle = self.m_noticeAni:findChild("Particle_"..index)
        if not tolua.isnull(particle) then
            particle:resetSystem()
        end
    end

    util_spineEndCallFunc(self.m_noticeAni.m_spine1,"actionframe_yugao",function()
        for index = 1,4 do
            local particle = self.m_noticeAni:findChild("Particle_"..index)
            if not tolua.isnull(particle) then
                particle:stopSystem()
            end
        end
        self:delayCallBack(1,function()
            self.m_noticeAni:setVisible(false)
        end)
        
    end)

    
    aniTime = self.m_noticeAni.m_spine1:getAnimationDurationTime("actionframe_yugao")

    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown()

    self:delayCallBack(aniTime - delayTime,function()
        
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenJollyFactoryMachine:createWheelView()
    --转盘
    local wheelView = util_createView("CodeJollyFactorySrc.JollyFactoryWheelView",{machine = self})
    self:findChild("xxx"):addChild(wheelView)
    return wheelView    
end

function CodeGameScreenJollyFactoryMachine:setReelRunInfo()
    self.m_longRunControl:checkTriggerLongRun()    
end

--[[
    判断是否为bonus小块(需要在子类重写)
]]
function CodeGameScreenJollyFactoryMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_BONUS then
        return true
    end
    
    return false
end


--[[
    检测播放落地动画
]]
function CodeGameScreenJollyFactoryMachine:checkPlayBulingAni(colIndex)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for iRow = 1,self.m_iReelRowNum do
        local symbolNode = self:getFixSymbol(colIndex,iRow)
        
        if symbolNode and symbolNode.p_symbolType then
            if self:isFixSymbol(symbolNode.p_symbolType) then
                self.m_wildBonusSymbol = symbolNode
                local longInfo = symbolNode.m_longInfo
                
                if symbolNode.p_rowIndex == 1 and longInfo.curCount == longInfo.maxCount then
                    -- self:levelDeviceVibrate(6, "bonus")
                    util_shakeNode(self:findChild("root"),3,3,0.3)
                    self:changeSymbolToClipParent(self.m_wildBonusSymbol)
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_wild_down"])
                    self.m_wildBonusSymbol:runAnim("actionframe_fk",false,function()
                    
                    end)
                end
            end
            local symbolCfg = bulingAnimCfg[symbolNode.p_symbolType]
            if symbolCfg then
                
                self:pushToSpecialSymbolList(symbolNode)
                
                --提层
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

                if self:checkSymbolBulingAnimPlay(symbolNode) then
                    --2.播落地动画
                    symbolNode:runAnim(
                        symbolCfg[2],
                        false,
                        function()
                            self:symbolBulingEndCallBack(symbolNode)
                        end
                    )
                    --bonus落地音效
                    if self:isFixSymbol(symbolNode.p_symbolType) then
                        self:checkPlayBonusDownSound(colIndex)
                    end
                    --scatter落地音效
                    if symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self:checkPlayScatterDownSound(colIndex)
                    end
                end
            end
            
        end
    end
end

--[[
    播放scatter落地音效
]]
function CodeGameScreenJollyFactoryMachine:playScatterDownSound(colIndex)
    local scatterList = self.m_spcial_symbol_list["90"] or {}
    local scatterCount = #scatterList
    if scatterCount >= 3 then
        scatterCount = 3
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_scatter_down_"..scatterCount])
end

function CodeGameScreenJollyFactoryMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)    
end

function CodeGameScreenJollyFactoryMachine:isPlayTipAnima(colIndex, rowIndex, node)
    local symbolType = node.p_symbolType

    local list = self.m_spcial_symbol_list[tostring(symbolType)]

    if colIndex <= 2 then
        return true
    elseif colIndex == 3 and #list >= 2 then
        return true
    elseif colIndex == 4 and #list >= 3 then
        return true
    end
    return false
end

function CodeGameScreenJollyFactoryMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
    if startIndex == nil then
        startIndex = 1
    end
    if endIndex == nil then
        endIndex = #winLines
    end

    if bChangeToMask == nil then
        bChangeToMask = true
    end

    local function checkAddLineSlotNode(slotNode)
        if slotNode ~= nil then
            local isHasNode = false
            for checkIndex = 1, #self.m_lineSlotNodes do
                local checkNode = self.m_lineSlotNodes[checkIndex]
                if checkNode == slotNode then
                    isHasNode = true
                    break
                end
            end
            if isHasNode == false then
                if bChangeToMask == false then
                    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
                else
                    self:changeToMaskLayerSlotNode(slotNode)
                end
            end
        end
    end

    -- 获取所有参与连线的SlotsNode 节点
    for lineIndex = startIndex, endIndex do
        local lineValue = winLines[lineIndex]

        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN and lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_BONUS then
            if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] == nil then
                self.m_eachLineSlotNode[lineIndex] = {}
            end
            local frameNum = lineValue.iLineSymbolNum
            for i = 1, frameNum do
                -- 播放slot node 的动画
                local symPosData = lineValue.vecValidMatrixSymPos[i]

                local slotNode = nil
                local iCol = symPosData.iY
                local iRow = symPosData.iX

                local slotNode

                if iCol == 1 and self.m_wildBonusSymbol then
                    slotNode = self.m_wildBonusSymbol
                end

                --先获取玩法添加的wild图标
                if self.m_addWildList and #self.m_addWildList > 0 then
                    for index = 1,#self.m_addWildList do
                        local symbolNode = self.m_addWildList[index]
                        if not tolua.isnull(symbolNode) and symbolNode.p_cloumnIndex == iCol and symbolNode.p_rowIndex == iRow then
                            slotNode = symbolNode
                        end
                    end
                end

                local reelNode = self.m_baseReelNodes[symPosData.iY]
                local isInLong,longInfo = false,nil
                if reelNode then
                    isInLong,longInfo = reelNode:checkIsInLongByInfo(iRow)
                    if isInLong and longInfo then
                        iRow = longInfo.startIndex
                    end
                end

                if not slotNode then
                    slotNode = self:getSymbolInLineNode(iCol,iRow)
                end
                
                if not slotNode then
                    slotNode = self:getFixSymbol(iCol,iRow)
                end

                checkAddLineSlotNode(slotNode)

                if slotNode and slotNode.p_symbolType then
                    if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                        self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                    end
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end
end

--[[
    获取连线中的小块
]]
function CodeGameScreenJollyFactoryMachine:getSymbolInLineNode(iCol,iRow)

    return  CodeGameScreenJollyFactoryMachine.super.getSymbolInLineNode(self,iCol,iRow)
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenJollyFactoryMachine:showBigWinLight(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JollyFactory_big_win_light"])
    
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    local bigWinLight = util_spineCreate("JollyFactory_bigwin",true,true)
    rootNode:addChild(bigWinLight)
    bigWinLight:setPosition(pos)
    local aniTime = util_spinePlayAndRemove(bigWinLight,"actionframe")

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and not self.m_isAddWild then
        self.m_humanNode:runBigWinAni()
    end
    

    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

---
-- 处理spin 返回消息的数据结构
--
function CodeGameScreenJollyFactoryMachine:operaSpinResultData(param)
    local spinData = param[2]

    self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
    --测试代码
    -- local fileUtil = cc.FileUtils:getInstance()
    -- local fullPath = fileUtil:fullPathForFilename("CodeJollyFactorySrc/resultData.json")
    -- local jsonStr = fileUtil:getStringFromFile(fullPath) 
    -- local result = cjson.decode(jsonStr)
    -- spinData.result = result

    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenJollyFactoryMachine:checkFeatureOverTriggerBigWin(winAmonut, feature)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end


    local lTatolBetNum = toLongNumber(self:getNewBingWinTotalBet(true))
    local winRatio = toLongNumber(winAmonut) / lTatolBetNum
    local winEffect = nil
    if winRatio >= toLongNumber(self.m_LegendaryWinLimitRate) then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= toLongNumber(self.m_HugeWinLimitRate) then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= toLongNumber(self.m_MegaWinLimitRate) then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= toLongNumber(self.m_BigWinLimitRate) then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        self.m_bIsBigWin = true
        local isAddEffect = false
        for i = 1, #self.m_gameEffects do
            local effectData = self.m_gameEffects[i]
            if effectData.p_effectType == feature then
                isAddEffect = true
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                delayEffect.p_effectOrder = feature + 1
                table.insert(self.m_gameEffects, i + 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, i + 2, effectData)
                break
            end
        end
        if isAddEffect == false then
            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_isPlay == false then
                    self.m_llBigOrMegaNum = winAmonut

                    local delayEffect = GameEffectData.new()
                    delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                    delayEffect.p_effectOrder = feature + 1
                    table.insert(self.m_gameEffects, i + 1, delayEffect)

                    local effectData = GameEffectData.new()
                    effectData.p_effectType = winEffect
                    table.insert(self.m_gameEffects, i + 2, effectData)
                    break
                end
            end
            if #self.m_gameEffects == 0 then
                self.m_llBigOrMegaNum = winAmonut

                local delayEffect = GameEffectData.new()
                delayEffect.p_effectType = GameEffect.EFFECT_DELAY_SHOW_BIGWIN
                table.insert(self.m_gameEffects, 1, delayEffect)

                local effectData = GameEffectData.new()
                effectData.p_effectType = winEffect
                table.insert(self.m_gameEffects, 2, effectData)
            end
        end
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()

    if feature == GameEffect.EFFECT_BONUS then
        self:addRewaedFreeSpinStartEffect()
        self:addRewaedFreeSpinOverEffect()
    end
end

function CodeGameScreenJollyFactoryMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local winAmountStr = toLongNumber(self.m_runSpinResultData.p_winAmountStr)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop,true,self.m_addCoinsLbl.m_addCoins})
    end

    
end

-------------快滚框------------------

---
-- 初始化快滚框的信息
--
function CodeGameScreenJollyFactoryMachine:initReelEffect()
    if self.m_reelEffectName == nil then
        self.m_reelEffectName = self.m_defaultEffectName --"ReelEffect"
    -- display.loadPlistFile("Common1.plist")
    end
    -- 初始化滚动金边  TODO
    self.m_reelRunAnima = {}
    self:createReelEffect(4)
end

function CodeGameScreenJollyFactoryMachine:createReelEffect(col)
    local longRunAni = util_spineCreate("WinFrameJollyFactory_run",true,true)
    local longRunBgAni = util_spineCreate("WinFrameJollyFactory_run",true,true)

    self.m_slotEffectLayer:addChild(longRunAni)
    self.m_clipParent:addChild(longRunBgAni,1,1)


    self.m_longRunAni[col] = {
        longRunAni = longRunAni,
        longRunBgAni = longRunBgAni
    }

    local worldPos, reelHeight, reelWidth = self:getReelPos(col)

    local pos1 = self.m_slotEffectLayer:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    local pos2 = self.m_clipParent:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    longRunAni:setPosition(pos1)
    longRunBgAni:setPosition(pos2)

    -- util_spinePlay(longRunAni,"actionframe_run",true)
    -- util_spinePlay(longRunBgAni,"actionframe_run_bg",true)


    longRunAni:setVisible(false)
    longRunBgAni:setVisible(false)

end

---
--添加金边
function CodeGameScreenJollyFactoryMachine:creatReelRunAnimation(col)
    if self.m_longRunAni[col] then
        local info = self.m_longRunAni[col]
        local longRunAni = info.longRunAni
        local longRunBgAni = info.longRunBgAni
        longRunAni:setVisible(true)
        longRunBgAni:setVisible(true)

        util_spinePlay(longRunAni,"actionframe_run",true)
        util_spinePlay(longRunBgAni,"actionframe_run_bg",true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--[[
    跳过回调
]]
function CodeGameScreenJollyFactoryMachine:skipFunc()
    if self.m_isSkip then
        return
    end
    
    self.m_isSkip = true

    self.m_waitNode:stopAllActions()
    self.m_humanNode:stopAllActions()
    self.m_humanNode:runBaseIdle()

    self:setSkipBtnShow(false)

    if type(self.m_skipEffectFunc) == "function" then
        self.m_skipEffectFunc()
    end

end

--新滚动使用
function CodeGameScreenJollyFactoryMachine:updateReelGridNode(symbolNode)
    if tolua.isnull(symbolNode) then
        return
    end

    if symbolNode.p_symbolType == self.SYMBOL_FIX_BONUS then
        symbolNode:runAnim("idleframe2",true)
    end
end

--[[
    @desc: 处理用户的spin赢钱信息
    time:2020-07-10 17:50:08
]]
function CodeGameScreenJollyFactoryMachine:operaWinCoinsWithSpinResult(param)
    local spinData = param[2]
    local userMoneyInfo = param[3]
    self.m_serverWinCoins = spinData.result.winAmount -- 记录下服务器返回赢钱的结果
    --发送测试赢钱数
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_WIN, self.m_serverWinCoins)
    globalData.userRate:pushCoins(self.m_serverWinCoins)

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and spinData.result.freespin.freeSpinsTotalCount == 0 then
        self:setLastWinCoin(spinData.result.winAmount)
    else
        self:setLastWinCoin(spinData.result.freespin.fsWinCoins)
    end
    globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
end

function CodeGameScreenJollyFactoryMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

    local winSize = display.size
    local mainScale = 1
    self.m_bgScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    local winSize = cc.Director:getInstance():getWinSize()
    if ratio < 920 / 768 then  --920以下
        mainScale = 0.6
        mainPosY  = mainPosY + 35

    elseif ratio >=  920 / 768 and ratio < 1152 / 768 then --920
        mainScale = 0.6
        mainPosY  = mainPosY + 35

    elseif ratio >= 1152 / 768 and ratio < 1228 / 768 then --1152
        mainScale = 0.81
        mainPosY  = mainPosY + 25
    elseif ratio >= 1228 / 768 and ratio < 1368 / 768 then --1228
        mainScale = 0.87
        mainPosY  = mainPosY + 20
    else --1370以上
        mainScale = 1
        mainPosY  = mainPosY + 15
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

return CodeGameScreenJollyFactoryMachine






