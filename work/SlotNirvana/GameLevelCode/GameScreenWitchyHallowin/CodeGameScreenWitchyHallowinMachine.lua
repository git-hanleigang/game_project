---
-- island li
-- 2019年1月26日
-- CodeGameScreenWitchyHallowinMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "WitchyHallowinPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseReelMachine = util_require("Levels.BaseReel.BaseReelMachine")
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenWitchyHallowinMachine = class("CodeGameScreenWitchyHallowinMachine", BaseReelMachine)

CodeGameScreenWitchyHallowinMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenWitchyHallowinMachine.SYMBOL_SCORE_10         = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenWitchyHallowinMachine.SYMBOL_EMPTY            = 999   -- 空信号
CodeGameScreenWitchyHallowinMachine.SYMBOL_BONUS            = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1   -- 普通bonus
CodeGameScreenWitchyHallowinMachine.SYMBOL_BONUS_MINI       = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2   -- mini
CodeGameScreenWitchyHallowinMachine.SYMBOL_BONUS_MINOR      = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3   -- minor
CodeGameScreenWitchyHallowinMachine.SYMBOL_BONUS_MAJOR      = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4   -- major
CodeGameScreenWitchyHallowinMachine.SYMBOL_BONUS_PURPLE     = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8   -- 紫色bonus
CodeGameScreenWitchyHallowinMachine.SYMBOL_BONUS_RED        = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9   -- 红色bonus
CodeGameScreenWitchyHallowinMachine.SYMBOL_BONUS_BLUE       = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10  -- 蓝色bonus

CodeGameScreenWitchyHallowinMachine.COLLECT_BONUS_EFFECT    = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集事件



-- 构造函数
function CodeGameScreenWitchyHallowinMachine:ctor()
    CodeGameScreenWitchyHallowinMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isCanClick = false
    self.m_isShowQuickRun = false
    self.m_isAddCoinsSoundPlayed = false

    self.m_respinReelDownSound = {}
    self.m_quickLastRunNodes = {}
    self.m_quickRunNodes = {}
    self.m_isAddBigWinLightEffect = true  --是否需要添加大赢光效
 
    --init
    self:initGame()
end

function CodeGameScreenWitchyHallowinMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("WitchyHallowinConfig.csv", "LevelWitchyHallowinConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenWitchyHallowinMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "WitchyHallowin"  
end

-- 继承底层respinView
function CodeGameScreenWitchyHallowinMachine:getRespinView()
    return "CodeWitchyHallowinSrc.WitchyHallowinRespinView"
end
-- 继承底层respinNode
function CodeGameScreenWitchyHallowinMachine:getRespinNode()
    return "CodeWitchyHallowinSrc.WitchyHallowinRespinNode"
end

function CodeGameScreenWitchyHallowinMachine:getBottomUINode()
    return "CodeWitchyHallowinSrc.WitchyHallowinBottomNode"
end

function CodeGameScreenWitchyHallowinMachine:initReSpinBar()
    local node_bar = self:findChild("Node_Respinbar")
    self.m_respinBar = util_createView("CodeWitchyHallowinSrc.WitchyHallowinRespinBar",{machine = self})
    node_bar:addChild(self.m_respinBar)
    self.m_respinBar:setVisible(false)
end

--[[
    刷新当前respin剩余次数
]]
function CodeGameScreenWitchyHallowinMachine:changeReSpinUpdateUI(curCount,isInit)
    local totalCount = self.m_runSpinResultData.p_reSpinsTotalCount
    self.m_respinBar:updateRespinCount(curCount,totalCount,isInit)
end

--[[
    设置respinbar是否显示
]]
function CodeGameScreenWitchyHallowinMachine:setRespinBarShow(isShow)
    self.m_respinBar:setVisible(isShow)
    if self.m_isDoubleReels then
        self.m_miniMachine:setRespinBarShow(isShow)
    end
    
    if isShow then
        self.m_respinBar:showThreeNumAni()
    end
    
    
end

--[[
    初始化背景
]]
function CodeGameScreenWitchyHallowinMachine:initMachineBg()
    local gameBg = util_spineCreate("WitchyHallowin_bg",true,true)--util_createView("views.gameviews.GameMachineBG")
    local bgNode = self:findChild("bg")
    if bgNode then
        bgNode:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    else
        self:addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    end

    self.m_gameBg = gameBg

    self:changeBgAni("base")
end

--[[
    变更背景动画
]]
function CodeGameScreenWitchyHallowinMachine:changeBgAni(bgType)
    if bgType == "base" then
        util_spinePlay(self.m_gameBg,"base_idle",true)
    elseif bgType == "respin" then
        util_spinePlay(self.m_gameBg,"free_idle",true)
    elseif bgType == "base_to_respin" then
        util_spinePlay(self.m_gameBg,"base_free",false)
        util_spineEndCallFunc(self.m_gameBg,"base_free",function(  )
            self:changeBgAni("respin")
        end)
    elseif bgType == "respin_to_base" then
        util_spinePlay(self.m_gameBg,"free_base",false)
        util_spineEndCallFunc(self.m_gameBg,"free_base",function(  )
            self:changeBgAni("base")
        end)
    end
end

--[[
    创建压黑层
]]
function CodeGameScreenWitchyHallowinMachine:createBlackLayer(size)

    self.m_blackLayers = {}
    for iCol = 1,self.m_iReelColumnNum do
        local blackNode = util_createAnimation("WitchyHallowin_reelyaan.csb")
        self.m_blackLayers[iCol] = blackNode
        self.m_clipParent:addChild(blackNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 20 + iCol)
        blackNode:setPosition(self.m_csbOwner["sp_reel_"..(iCol - 1)]:getPosition())
        util_setCascadeOpacityEnabledRescursion(blackNode,true)

        if iCol == self.m_iReelColumnNum then
            local layout = blackNode:findChild("yaan_0")
            local size = layout:getContentSize()
            layout:setContentSize(CCSizeMake(size.width - 4,size.height))
        end
        blackNode:setVisible(false)
    end
end

--[[
    显示压黑层
]]
function CodeGameScreenWitchyHallowinMachine:showBlackLayer()
    for iCol = 1,self.m_iReelColumnNum do
        local blackNode = self.m_blackLayers[iCol]
        blackNode:setVisible(true)
        util_nodeFadeIn(blackNode,0.2,0,255)
    end
end

--[[
    隐藏压黑层
]]
function CodeGameScreenWitchyHallowinMachine:hideBlackLayer(colIndex)
    util_fadeOutNode(self.m_blackLayers[colIndex],0.2,function(  )
        self.m_blackLayers[colIndex]:setVisible(false)
    end)
end


--[[
    设置收集条是否显示
]]
function CodeGameScreenWitchyHallowinMachine:setCollectBarShow(isShow)
    self.m_collectBar:setVisible(isShow)
end

function CodeGameScreenWitchyHallowinMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 3)
    self.m_effectNode:setScale(self.m_machineRootScale)
    
    self:initReSpinBar() -- reSpinbar

    --jackpot
    self.m_jackpotBar = util_createView("CodeWitchyHallowinSrc.WitchyHallowinJackPotBarView",{machine = self})
    self:findChild("Node_Jackpot"):addChild(self.m_jackpotBar)

    --收集条
    self.m_collectBar = util_createView("CodeWitchyHallowinSrc.WitchyHallowinCollectBar",{machine = self})
    self:findChild("Node_Respintitle"):addChild(self.m_collectBar)

    --mini轮
    self.m_miniMachine = util_createView("CodeWitchyHallowinSrc.WitchyHallowinMiniMachine",{parent = self})
    self:findChild("qipan"):addChild(self.m_miniMachine)
    self:setMiniMachineShow(false)

    --女巫spine
    self.m_spine_sorceress = util_spineCreate("WitchyHallowin_nvwu",true,true)
    self:findChild("Node_juese"):addChild(self.m_spine_sorceress)

    local startNode_single = cc.Node:create()
    util_spinePushBindNode(self.m_spine_sorceress,"node_1",startNode_single)
    self.m_spine_sorceress.m_startNode_single = startNode_single

    local startNode_double = cc.Node:create()
    util_spinePushBindNode(self.m_spine_sorceress,"node2_1",startNode_double)
    self.m_spine_sorceress.m_startNode_double = startNode_double

    --女巫idle
    self:runSorceressIdleAni()

    self:findChild("Node_kuang_respin"):setVisible(false)
end

--[[
    女巫待机idle
]]
function CodeGameScreenWitchyHallowinMachine:runSorceressIdleAni()
    local randIndex = math.random(1,3)
    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_spine_sorceress,   --执行动画节点  必传参数
        actionName = "idleframe", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_spine_sorceress,   --执行动画节点  必传参数
        actionName = "idleframe", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_spine_sorceress,   --执行动画节点  必传参数
        actionName = "idleframe", --动作名称  动画必传参数,单延时动作可不传
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_spine_sorceress,   --执行动画节点  必传参数
        soundFile = (randIndex == 3) and PublicConfig.SoundConfig.sound_WitchyHallowin_show_pumpkin or nil,  --播放音效 执行动作同时播放 可选参数
        actionName = "idleframe"..randIndex, --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            self:runSorceressIdleAni()
        end
    }
    util_runAnimations(params)
end

--[[
    设置mini轮是否显示
]]
function CodeGameScreenWitchyHallowinMachine:setMiniMachineShow(isShow)
    self.m_miniMachine:setVisible(isShow)
end

--[[
    显示mini轮动画
]]
function CodeGameScreenWitchyHallowinMachine:showMiniMachineAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_respin_add_machine"])
    util_spinePlay(self.m_spine_sorceress,"actionframe2")
    util_spineEndCallFunc(self.m_spine_sorceress,"actionframe2",function(  )
        util_spinePlay(self.m_spine_sorceress,"actionframe_jinchang_idle",true)
    end)

    for index = 1,8 do
        local particle = self:findChild("Particle_2_"..index)
        if particle then
            particle:setVisible(true)
            particle:resetSystem()
        end
    end

    self:delayCallBack(35 / 30,function(  )
        self:setMiniMachineShow(true)
        self:runCsbAction("switch",false,function(  )
            if type(func) == "function" then
                func()
            end
        end)

        self:delayCallBack(40 / 60,function(  )
            for index = 1,3 do
                local particle = self:findChild("Particle_1_"..index)
                if particle then
                    particle:setVisible(true)
                    particle:resetSystem()
                end
            end
        end)
    end)
    
end

function CodeGameScreenWitchyHallowinMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
        self:playEnterGameSound(PublicConfig.SoundConfig.sound_WitchyHallowin_enter_game)

    end,0.4,self:getModuleName())
end

--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function CodeGameScreenWitchyHallowinMachine:checkTriggerInReSpin()
    local isPlayGameEff = false
    self.m_isDoubleReels = self:isTriggerDoubleReels()
    if not self:isRespinEnd() then
        --手动添加freespin次数
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

        local reSpinEffect = GameEffectData.new()
        reSpinEffect.p_effectType = GameEffect.EFFECT_RESPIN
        reSpinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
        self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect

        self.m_isRunningEffect = true

        if self.checkControlerReelType and self:checkControlerReelType() then
            globalMachineController.m_isEffectPlaying = true
        end

        -- BtnType_Auto  BtnType_Stop  BtnType_Spin
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    else
        self.m_isDoubleReels = false
    end

    return isPlayGameEff
end

function CodeGameScreenWitchyHallowinMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWitchyHallowinMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    

    for index = 1,8 do
        local particle = self:findChild("Particle_2_"..index)
        if particle then
            particle:setVisible(false)
        end
    end

    for index = 1,3 do
        local particle = self:findChild("Particle_1_"..index)
        if particle then
            particle:setVisible(false)
        end
    end
end

---
-- 进入关卡
--
function CodeGameScreenWitchyHallowinMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        if hasFeature then
            local reels = self.m_runSpinResultData.p_reels
            local lastList = {}
            for iRow = 1,#reels do
                table.insert(lastList,1,reels[iRow][iCol])
            end
            reelNode:setSymbolList(lastList)
        end
        reelNode:initSymbolNode(hasFeature)
    end

    self:addRewaedFreeSpinStartEffect()
    self:addRewaedFreeSpinOverEffect()

    self:updateCollectBar()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function CodeGameScreenWitchyHallowinMachine:addObservers()
    CodeGameScreenWitchyHallowinMachine.super.addObservers(self)

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
        
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local winRatio = winCoin / lTatolBetNum
        local soundIndex = 1
        local soundTime = 2
        if winRatio > 0 then
            if winRatio <= 1 then
                soundIndex = 1
            elseif winRatio > 1 and winRatio <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = PublicConfig.SoundConfig["sound_WitchyHallowin_winline_"..soundIndex] 
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

end

function CodeGameScreenWitchyHallowinMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenWitchyHallowinMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

---
--设置bonus scatter 层级
function CodeGameScreenWitchyHallowinMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if self:isFixSymbol(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
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
function CodeGameScreenWitchyHallowinMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_EMPTY then
        return "Socre_WitchyHallowin_Empty"
    end

    if symbolType == self.SYMBOL_BONUS or symbolType == self.SYMBOL_BONUS_MINI or symbolType == self.SYMBOL_BONUS_MINOR or symbolType == self.SYMBOL_BONUS_MAJOR then
        return "Socre_WitchyHallowin_Bonus1"
    end

    if symbolType == self.SYMBOL_BONUS_PURPLE then
        return "Socre_WitchyHallowin_Bonus3"
    end

    if symbolType == self.SYMBOL_BONUS_RED then
        return "Socre_WitchyHallowin_Bonus2"
    end

    if symbolType == self.SYMBOL_BONUS_BLUE then
        return "Socre_WitchyHallowin_Bonus4"
    end

    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_WitchyHallowin_10"
    end
    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenWitchyHallowinMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenWitchyHallowinMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenWitchyHallowinMachine:MachineRule_initGame(  )

    
end

--
--单列滚动停止回调
--
function CodeGameScreenWitchyHallowinMachine:slotOneReelDown(reelCol)    
    self:hideBlackLayer(reelCol)
    CodeGameScreenWitchyHallowinMachine.super.slotOneReelDown(self,reelCol) 
   
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenWitchyHallowinMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self:isFixSymbol(_slotNode.p_symbolType) then
                return true
            end
        end
    end

    return false
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenWitchyHallowinMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenWitchyHallowinMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

function CodeGameScreenWitchyHallowinMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()
    
    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    self.m_isWaitingNetworkData = false

    

    self:produceSlots()
    
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] > 0 then

        -- 出现预告动画概率30%
        self.m_isNotice = (math.random(1, 100) <= 30) 
        --触发两种以上玩法概率70%
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local triggerCount = 0
        if selfData and selfData.trigger then
            for i,isTrigger in ipairs(selfData.trigger) do
                if isTrigger ~= 0 then
                    triggerCount = triggerCount + 1
                end
                
            end
        end
        if triggerCount >= 2 then
            self.m_isNotice = (math.random(1, 100) <= 70) 
        end
       
        if self.m_isNotice then
            self:playNoticeAni()
            self:delayCallBack(1.5,function()
                self:operaNetWorkData() -- end
            end)
        else
            self:operaNetWorkData() -- end
        end
        
    else
        self:operaNetWorkData() -- end
    end
    
end

function CodeGameScreenWitchyHallowinMachine:operaNetWorkData()
    local reels = self.m_runSpinResultData.p_reels

    for iCol,reelNode in ipairs(self.m_baseReelNodes) do
        reelNode:setIsWaitNetBack(false)
        local lastList = {}
        for iRow = 1,#reels do
            table.insert(lastList,1,reels[iRow][iCol])
        end
        reelNode:setSymbolList(lastList)
    end

    if not self.m_isNotice then
        self:dealSmallReelsSpinStates()
    end
    

    self:setGameSpinStage(GAME_MODE_ONE_RUN)
end

--[[
    预告中奖
]]
function CodeGameScreenWitchyHallowinMachine:playNoticeAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_notice_win)
    util_spinePlay(self.m_spine_sorceress,"actionframe_yugao")
    util_spineEndCallFunc(self.m_spine_sorceress,"actionframe_yugao",function(  )
        self:runSorceressIdleAni()
    end)

    local noticeAni = util_createAnimation("WitchyHallowin_yugao.csb")
    self.m_effectNode:addChild(noticeAni)
    noticeAni:runCsbAction("actionframe",false,function(  )
        noticeAni:removeFromParent()

        if type(func) == "function" then
            func()
        end
    end)
    noticeAni:setPosition(util_convertToNodeSpace(self:findChild("Panel_1"),self.m_effectNode))
end


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenWitchyHallowinMachine:showFreeSpinView(effectData)

    -- gLobalSoundManager:playSound("WitchyHallowinSounds/music_WitchyHallowin_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
        else
                self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
            showFreeSpinView()    
    end,0.5)

    

end

function CodeGameScreenWitchyHallowinMachine:showFreeSpinOverView()

   -- gLobalSoundManager:playSound("WitchyHallowinSounds/music_WitchyHallowin_over_fs.mp3")

   local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,11)
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.8,sy=0.8},1010)

end




---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenWitchyHallowinMachine:MachineRule_SpinBtnCall()
    
    self:setMaxMusicBGVolume( )
   

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

function CodeGameScreenWitchyHallowinMachine:beginReel()
    CodeGameScreenWitchyHallowinMachine.super.beginReel(self)
    --显示压黑层
    self:showBlackLayer()
end

function CodeGameScreenWitchyHallowinMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    effectData.p_isPlay = true
    self:playGameEffect()

    return true
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenWitchyHallowinMachine:addSelfEffect()
    if self:getCurrSpinMode() ~= RESPIN_MODE then
        local reels = self.m_runSpinResultData.p_reels
        for iCol = 1,self.m_iReelColumnNum do
            for iRow = 1,self.m_iReelRowNum do
                if reels[iRow][iCol] >= self.SYMBOL_BONUS_PURPLE then
                    local selfEffect = GameEffectData.new()
                    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                    selfEffect.p_effectOrder = self.COLLECT_BONUS_EFFECT
                    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                    selfEffect.p_selfEffectType = self.COLLECT_BONUS_EFFECT -- 动画类型
                    return 
                end
            end
        end
    end
        
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenWitchyHallowinMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.COLLECT_BONUS_EFFECT then --收集bonus图标
        self:collectBonus(function(  )
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

--[[
    收集bonus
]]
function CodeGameScreenWitchyHallowinMachine:collectBonus(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData or not selfData.collect_num then
        if type(func) == "function" then
            func()
        end
        return
    end
    self.m_collect_num = selfData.collect_num
    local needCollect = {}

    local features = self.m_runSpinResultData.p_features
    local isTrigger = #features > 1

    local collectTargetIndex = {1,1,1}

    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(iCol,iRow)
            if symbolNode and symbolNode.p_symbolType then
                local isCollect,collectIndex = self:isCollectSymbol(symbolNode.p_symbolType)
                if isCollect then
                    needCollect[collectIndex] = true
                    local targetIndex = collectTargetIndex[collectIndex]
                    collectTargetIndex[collectIndex] = collectTargetIndex[collectIndex] + 1
                    if collectTargetIndex[collectIndex] > 3 then
                        collectTargetIndex[collectIndex] = 1
                    end
                    local endNode = self.m_collectBar:getCollectEndNodeByIndex(collectIndex,targetIndex)
                    --收集动画
                    self:flyBonusAni(symbolNode.p_symbolType,symbolNode,endNode)
                end
            end
        end
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_bonus_collect)
    self:delayCallBack(27 / 30,function()
        local time = 0
        for collectIndex,canCollect in pairs(needCollect) do
            time = self.m_collectBar:feedBackAni(collectIndex,self.m_collect_num,self.m_show_level,isTrigger)
        end
        
        if isTrigger then
            self:delayCallBack(time,func)
        end
    end)

    self:delayCallBack(9 / 30,function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_bonus_collect_feed_back)
    end)

    

    if not isTrigger then
        if type(func) == "function" then
            func()
        end
    end
    
end

--[[
    收集bonus动画
]]
function CodeGameScreenWitchyHallowinMachine:flyBonusAni(symbolType,startNode,endNode,func)
    local aniName = self:getSymbolCCBNameByType(self,symbolType)
    local flyNode = util_spineCreate(aniName,true,true)

    self.m_effectNode:addChild(flyNode)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.BezierTo:create(9 / 30,{startPos, cc.p(startPos.x, endPos.y), endPos}),
        cc.CallFunc:create(function(  )
            if type(func) == "function" then
                func()
            end
        end)
    })

    flyNode:runAction(seq)
    util_spinePlay(flyNode,"shouji")
    util_spineEndCallFunc(flyNode,"shouji",function(  )
        flyNode:setVisible(false)
        self:delayCallBack(0.1,function(  )
            flyNode:removeFromParent()
        end)
    end)
end

--[[
    收集bonus金币数动画
]]
function CodeGameScreenWitchyHallowinMachine:flyBonusCoinsAni(startNode,endNode,func)
    local flyNode = util_createAnimation("WitchyHallowin_jiesuan_twlizi.csb")
    self.m_effectNode:addChild(flyNode)

    for index = 1,2 do
        local particle = flyNode:findChild("Particle_"..index)
        if particle then
            particle:setPositionType(0)
        end
    end

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)

    flyNode:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.MoveTo:create(0.4,endPos),
        cc.CallFunc:create(function(  )
            for index = 1,2 do
                local particle = flyNode:findChild("Particle_"..index)
                if particle then
                    particle:stopSystem()
                end
            end

            local feedBackAni = util_createAnimation("WitchyHallowin_jiesuan_bd.csb")
            endNode:addChild(feedBackAni)
            feedBackAni:runCsbAction("actionframe",false,function(  )
                feedBackAni:removeFromParent()
            end)

            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create(true)
    })

    flyNode:runAction(seq)
end

--[[
    刷新收集进度
]]
function CodeGameScreenWitchyHallowinMachine:updateCollectBar( )
    self.m_collectBar:initCollectLevel(self.m_collect_num,self.m_show_level)
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenWitchyHallowinMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenWitchyHallowinMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenWitchyHallowinMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenWitchyHallowinMachine:slotReelDown( )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    self.m_isNotice = false

    CodeGameScreenWitchyHallowinMachine.super.slotReelDown(self)
end

function CodeGameScreenWitchyHallowinMachine:getNextReelSymbolType()
    return self.m_runSpinResultData.p_prevReel
end

--[[
    刷新小块
]]
function CodeGameScreenWitchyHallowinMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isFixSymbol(symbolType) then
        self:setSpecialNodeScore(node)
    end
end

--[[
    判断是否为收集小块
]]
function CodeGameScreenWitchyHallowinMachine:isCollectSymbol(symbolType)
    local bonusAry = {
        self.SYMBOL_BONUS_PURPLE,
        self.SYMBOL_BONUS_RED,
        self.SYMBOL_BONUS_BLUE,
    }
    for index,bonusType in pairs(bonusAry) do
        if symbolType == bonusType then
            return true,index
        end
    end

    return false,-1
end

--[[
    判断是否为bonus小块
]]
function CodeGameScreenWitchyHallowinMachine:isFixSymbol(symbolType)
    local bonusAry = {
        self.SYMBOL_BONUS,
        self.SYMBOL_BONUS_MINI,
        self.SYMBOL_BONUS_MINOR,
        self.SYMBOL_BONUS_MAJOR,
        self.SYMBOL_BONUS_PURPLE,
        self.SYMBOL_BONUS_RED,
        self.SYMBOL_BONUS_BLUE,
    }

    for k,bonusType in pairs(bonusAry) do
        if symbolType == bonusType then
            return true
        end
    end
    
    return false
end

-- 给respin小块进行赋值
function CodeGameScreenWitchyHallowinMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if not  symbolNode.p_symbolType then
        return
    end
    

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    local score = 0
    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
        --根据网络数据获取停止滚动时respin小块的分数
        score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol),true) --获取分数（网络数据）
    else
        score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
    end

    if symbolNode and symbolNode.p_symbolType then
        symbolNode.m_score = score
        local symbolType = symbolNode.p_symbolType

        local csbNode = self:getLblOnBonusSymbol(symbolNode)
        --普通信号
        if symbolType == self.SYMBOL_BONUS or symbolType == self.SYMBOL_BONUS_BLUE or symbolType == self.SYMBOL_BONUS_PURPLE or symbolType == self.SYMBOL_BONUS_RED then
            csbNode:findChild("jackpot"):setVisible(false)
            csbNode:findChild("m_lb_coins"):setVisible(true)
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                local multi = score / lineBet
                score = util_formatCoins(score, 3)
                local label = csbNode:findChild("m_lb_coins")
                label:setString(score)

                local labelGold = csbNode:findChild("m_lb_coins_0")
                labelGold:setString(score)
                if multi >= 5 then
                    csbNode:findChild("m_lb_coins"):setVisible(false)
                    csbNode:findChild("m_lb_coins_0"):setVisible(true)
                else
                    csbNode:findChild("m_lb_coins"):setVisible(true)
                    csbNode:findChild("m_lb_coins_0"):setVisible(false)
                end
            end
            
        else
            csbNode:findChild("m_lb_coins"):setVisible(false)
            csbNode:findChild("m_lb_coins_0"):setVisible(false)
            csbNode:findChild("jackpot"):setVisible(true)
            csbNode:findChild("major"):setVisible(symbolType == self.SYMBOL_BONUS_MAJOR)
            csbNode:findChild("minor"):setVisible(symbolType == self.SYMBOL_BONUS_MINOR)
            csbNode:findChild("mini"):setVisible(symbolType == self.SYMBOL_BONUS_MINI)
        end

        if symbolType == self.SYMBOL_BONUS_BLUE or symbolType == self.SYMBOL_BONUS_PURPLE or symbolType == self.SYMBOL_BONUS_RED then
            if self:getGameSpinStage( ) > IDLE and self:getGameSpinStage() ~= QUICK_RUN then
                symbolNode:runAnim("idleframe2",true)
            end
        end
    end

end

--[[
    获取bonus小块上的label
]]
function CodeGameScreenWitchyHallowinMachine:getLblOnBonusSymbol(symbolNode)
    local aniNode = symbolNode:checkLoadCCbNode()
    local symbolType = symbolNode.p_symbolType
    local lblName = "Socre_WitchyHallowin_Bonus.csb"
    local spine = aniNode.m_spineNode
    if spine and not spine.m_lbl_score then
        local label = util_createAnimation(lblName)
        util_spinePushBindNode(spine,"shuzi",label)
        spine.m_lbl_score = label
    end

    return spine.m_lbl_score
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenWitchyHallowinMachine:getReSpinSymbolScore(id,isNotTotal)
    
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if self:getCurrSpinMode() == RESPIN_MODE and isNotTotal then
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.show_storedIcons then
            storedIcons = self.m_runSpinResultData.p_selfMakeData.show_storedIcons
        end
    end
    local multi = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            multi = values[2]
        end
    end

    if multi == nil then
       return 0
    end

    local lineBet = globalData.slotRunData:getCurTotalBet()
    local score = multi * lineBet

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenWitchyHallowinMachine:randomDownRespinSymbolScore(symbolType)
    local score = 0
    
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local multi = self.m_configData:getFixSymbolPro()
    score = multi * lineBet


    return score
end

function CodeGameScreenWitchyHallowinMachine:initGameStatusData(gameData)
    CodeGameScreenWitchyHallowinMachine.super.initGameStatusData(self, gameData)

    self.m_collect_num = gameData.gameConfig.extra.collect_num
    self.m_show_level = gameData.gameConfig.extra.show_level
end

function CodeGameScreenWitchyHallowinMachine:changeTouchSpinLayerSize(_trigger)
    if self.m_SlotNodeH and self.m_iReelRowNum and self.m_touchSpinLayer then
        local size = self.m_touchSpinLayer:getContentSize()
        if self:getCurrSpinMode() == RESPIN_MODE then
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH * (self.m_iReelRowNum * 2 + 0.5 )))
        else
            self.m_touchSpinLayer:setContentSize(cc.size(size.width, self.m_SlotNodeH *self.m_iReelRowNum))
        end
       
    end
end

function CodeGameScreenWitchyHallowinMachine:showRespinView()
    self.m_triggerRespin = false

    self.m_curAddBonusSoundIndex = 1
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self.m_lightScore = 0
    
    local trigger = self.m_runSpinResultData.p_selfMakeData.trigger
    local aniName = "idleframe4_1"
    if trigger[2] == 1 then
        aniName = "idleframe4_2"
    elseif trigger[3] == 1 then
        aniName = "idleframe4_3"
    end
    --罐子喷出女巫受到惊吓
    util_spinePlay(self.m_spine_sorceress,aniName)
    util_spineEndCallFunc(self.m_spine_sorceress,aniName,function(  )
        self:showReSpinStart(trigger,function()
            self.m_isDoubleReels = self:isTriggerDoubleReels()
            --可随机的普通信息
            local randomTypes = self:getRespinRandomTypes( )
            --可随机的特殊信号 
            local endTypes = self:getRespinLockTypes()
            if self.m_isDoubleReels then
                self.m_miniMachine:setSpinResultData(self.m_runSpinResultData,true)
                self.m_miniMachine:triggerReSpinCallFun(endTypes, randomTypes)
            end

            --过场动画
            self:changeSceneToRespin(function(  )
                -- --构造盘面数据
                self:triggerReSpinCallFun(endTypes, randomTypes)

            end,function(  )
                self:sorceressComeInAni(function(  )
                    self:showTriggerTypeAni(3,function(  )
                        self:sorceressFlyOutAni(function(  )
                            
                            self:runNextReSpinReel()
                        end)
                        
                    end)
                    
                end)
            end)
        end)
    end)

    local randIndex = math.random(1,2)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_respin_trigger_"..randIndex])
    self.m_collectBar:runTriggerAni(trigger,function(  )
        
    end)
end

--[[
    女巫飞走动画
]]
function CodeGameScreenWitchyHallowinMachine:sorceressFlyOutAni(func)
    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self.m_spine_sorceress,   --执行动画节点  必传参数
        soundFile = PublicConfig.SoundConfig.sound_WitchyHallowin_respin_fly_out,  --播放音效 执行动作同时播放 可选参数
        actionName = "actionframe_feizou", --动作名称  动画必传参数,单延时动作可不传
        callBack = function(  )
            util_changeNodeParent(self:findChild("Node_juese"),self.m_spine_sorceress)
            self.m_spine_sorceress:setPosition(cc.p(0,0))
            util_spinePlay(self.m_spine_sorceress,"idleframe6",true)
            if self.m_isDoubleReels then
                self.m_spine_sorceress:setVisible(false)
                if type(func) == "function" then
                    func()
                end
            else
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_sorceress_fly_to_bg)
            end
        end,   --回调函数 可选参数
    }
    if not self.m_isDoubleReels then
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_sorceress,   --执行动画节点  必传参数
            actionName = "actionframe_jinchang_2", --动作名称  动画必传参数,单延时动作可不传
            -- callBack,   --回调函数 可选参数
            callBack = function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_magic_book)
            end
        }
        params[#params + 1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self.m_spine_sorceress,   --执行动画节点  必传参数
            actionName = "idleframe5", --动作名称  动画必传参数,单延时动作可不传
            callBack = function(  )
                
                util_spinePlay(self.m_spine_sorceress,"idleframe6",true)
                if type(func) == "function" then
                    func()
                end
            end,   --回调函数 可选参数
        }
    end
    
    util_runAnimations(params)
end

--[[
    显示触发的玩法动画
]]
function CodeGameScreenWitchyHallowinMachine:showTriggerTypeAni(triggerIndex,func)
    if triggerIndex <= 1 then
        if type(func) == "function" then
            func()
        end
        return
    end
    local trigger = self.m_runSpinResultData.p_selfMakeData.trigger
    if triggerIndex == 3 then
        if trigger[triggerIndex] == 1 then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_respin_add_max_times"])
            util_spinePlay(self.m_spine_sorceress,"actionframe1")
            util_spineFrameCallFunc(self.m_spine_sorceress,"actionframe1","spin_baodian",function(  )
                self.m_respinBar:showFourNumAni(function(  )
                    self:showTriggerTypeAni(triggerIndex - 1,func)
                end)
            end,function(  )
                util_spinePlay(self.m_spine_sorceress,"actionframe_jinchang_idle",true)
                
            end)
        else
            self:showTriggerTypeAni(triggerIndex - 1,func)
        end
    elseif triggerIndex == 2 and trigger[triggerIndex] == 1 then
        self:showMiniMachineAni(function(  )
            self:showTriggerTypeAni(triggerIndex - 1,func)
        end)
    else
        self:showTriggerTypeAni(triggerIndex - 1,func)
    end
end



--触发respin
function CodeGameScreenWitchyHallowinMachine:triggerReSpinCallFun(endTypes, randomTypes)

    
    self.m_specialReels = true

    self:changeTouchSpinLayerSize()

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setMachine(self)
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    self:initRespinView(endTypes, randomTypes)

    self:setCurrSpinMode(RESPIN_MODE)
end

--[[
    是否触发双轮盘玩法
]]
function CodeGameScreenWitchyHallowinMachine:isTriggerDoubleReels( )
    local selfData = self.m_runSpinResultData.p_selfMakeData
    --是否触发双轮盘
    if selfData and selfData.trigger and selfData.trigger[2] and selfData.trigger[2] ~= 0 then
        return true
    end
    return false
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenWitchyHallowinMachine:getRespinRandomTypes( )
    local symbolList = {
        self.SYMBOL_EMPTY,
        self.SYMBOL_BONUS,
        self.SYMBOL_BONUS_MINI,
        self.SYMBOL_BONUS_MINOR,
        self.SYMBOL_BONUS_MAJOR
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenWitchyHallowinMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_BONUS, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_BONUS_MINI, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_BONUS_MINOR, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_BONUS_MAJOR, runEndAnimaName = "buling", bRandom = false},
    }

    return symbolList
end

--ReSpin开始改变UI状态
function CodeGameScreenWitchyHallowinMachine:changeReSpinStartUI(respinCount)
    self:setRespinBarShow(true)
    self:setCollectBarShow(false)
    self.m_collectBar:hideAllItems()
    
    if self.m_isDoubleReels then
        self.m_jackpotBar:switchToSpecial()
    end
    
    self.m_respinBar:setComplete(false)
    self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount,true)

    self:findChild("Node_kuang_respin"):setVisible(true)
    self:changeBgAni("base_to_respin")
end

--ReSpin结算改变UI状态
function CodeGameScreenWitchyHallowinMachine:changeReSpinOverUI()
    self:setRespinBarShow(false)
    self:setCollectBarShow(true)
    self:setMiniMachineShow(false)
    self:runCsbAction("idleframe")
    self.m_jackpotBar:switchToNormal()
    self.m_collectBar:resetCollectItems()
    self.m_collectBar:initCollectLevel(self.m_collect_num,self.m_show_level)
    self.m_spine_sorceress:setVisible(true)
    self:findChild("Node_kuang_respin"):setVisible(false)
    self:changeBgAni("respin_to_base")

    self:setReelSlotsNodeVisible(true)
    self:removeRespinNode()
    if self.m_isDoubleReels then
        self.m_miniMachine:respinOver()
    end
end

function CodeGameScreenWitchyHallowinMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--[[
    女巫进场动画
]]
function CodeGameScreenWitchyHallowinMachine:sorceressComeInAni(func)
    util_spinePlay(self.m_spine_sorceress,"actionframe_jinchang")
    util_spineEndCallFunc(self.m_spine_sorceress,"actionframe_jinchang",function(  )
        util_spinePlay(self.m_spine_sorceress,"idleframe4",true)
        if type(func) == "function" then
            func()
        end
    end)

    self:runCsbAction("idleframe")
    local spine = util_spineCreate("WitchyHallowin_guanzi",true,true)
    self:findChild("Node_guo"):addChild(spine)

    local trigger = self.m_runSpinResultData.p_selfMakeData.trigger
    

    
    --计算触发玩法的数量
    local triggerCount = 0
    for index = 1,#trigger do
        if trigger[index] == 1 then
            triggerCount = triggerCount + 1
        end
    end

    local endFunc = function(  )
        
        spine:setVisible(false)
        self.m_collectBar:changeItemsParentByTrigger(trigger)
        self:delayCallBack(0.1,function(  )
            spine:removeFromParent()
        end)
    end

    if triggerCount == 1 then
        if trigger[1] == 1 then
            util_spinePlay(spine,"actionframe_jinchangx1_zi")
            util_spineEndCallFunc(spine,"actionframe_jinchangx1_zi",endFunc)
        elseif trigger[2] == 1 then
            util_spinePlay(spine,"actionframe_jinchangx1_hong")
            util_spineEndCallFunc(spine,"actionframe_jinchangx1_hong",endFunc)
        else
            util_spinePlay(spine,"actionframe_jinchangx1_lan")
            util_spineEndCallFunc(spine,"actionframe_jinchangx1_lan",endFunc)
        end
    elseif triggerCount == 2 then
        if trigger[1] == 1 and trigger[2] == 1 then
            util_spinePlay(spine,"actionframe_jinchangx2_zihong")
            util_spineEndCallFunc(spine,"actionframe_jinchangx2_zihong",endFunc)
        elseif trigger[2] == 1 and trigger[3] == 1 then
            util_spinePlay(spine,"actionframe_jinchangx2_honglan")
            util_spineEndCallFunc(spine,"actionframe_jinchangx2_honglan",endFunc)
        else
            util_spinePlay(spine,"actionframe_jinchangx2_zilan")
            util_spineEndCallFunc(spine,"actionframe_jinchangx2_zilan",endFunc)
        end
    else
        util_spinePlay(spine,"actionframe_jinchangx3_zihonglan")
        util_spineEndCallFunc(spine,"actionframe_jinchangx3_zihonglan",endFunc)
    end
end

function CodeGameScreenWitchyHallowinMachine:showReSpinStart(trigger,func)
    self:clearCurMusicBg()
    util_spinePlay(self.m_spine_sorceress,"actionframe_tanban_start")
    util_spineEndCallFunc(self.m_spine_sorceress,"actionframe_tanban_start",function(  )
        -- self:runSorceressIdleAni()
        util_spinePlay(self.m_spine_sorceress,"actionframe_tanban_start_idle",true)
    end)

    --计算触发玩法的数量
    local triggerCount = 0
    for index = 1,#trigger do
        if trigger[index] == 1 then
            triggerCount = triggerCount + 1
        end
    end
    self:delayCallBack(30 / 30,function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_respin_start)
        local view = self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START, nil, func)

        view:setBtnClickFunc(function(  )
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_click)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_respin_start_over)
        end)
        
        view:findChild("Node_one"):setVisible(triggerCount == 1)
        view:findChild("Node_two"):setVisible(triggerCount == 2)
        view:findChild("Node_three"):setVisible(triggerCount == 3)

        local curCount = 1
        for index = 1,#trigger do
            if trigger[index] == 1 then
                local csbNode = util_createAnimation('WitchyHallowin_Respintitle_'..index..".csb")
                view:findChild("Node_"..triggerCount.."_"..curCount):addChild(csbNode)
                curCount = curCount + 1
            end
        end
        util_setCascadeOpacityEnabledRescursion(view,true)
        view:findChild("root"):setScale(self.m_machineRootScale)
    end)
end

--[[
    过场动画
]]
function CodeGameScreenWitchyHallowinMachine:changeSceneToRespin(func,overFunc)
    self:changeReSpinBgMusic()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_change_scene_to_respin)
    local spine = util_spineCreate("WitchyHallowin_guanzi",true,true)
    self:findChild("Node_guo"):addChild(spine)
    

    local trigger = self.m_runSpinResultData.p_selfMakeData.trigger
    self.m_collectBar:hideItemsByTrigger(trigger)

    
    --计算触发玩法的数量
    local triggerCount = 0
    for index = 1,#trigger do
        if trigger[index] == 1 then
            triggerCount = triggerCount + 1
        end
    end

    local endFunc = function(  )
        spine:setVisible(false)
        self:delayCallBack(0.1,function(  )
            spine:removeFromParent()
        end)
    end

    local eventFunc = function(  )
        
        local pos = util_convertToNodeSpace(self:findChild("Node_guo"),self.m_effectNode)
        util_changeNodeParent(self.m_effectNode,spine,100)
        spine:setPosition(pos)
    end

    if triggerCount == 1 then
        if trigger[1] == 1 then
            util_spinePlay(spine,"actionframe_guochangx1_zi")
            util_spineFrameCallFunc(spine,"actionframe_guochangx1_zi","guanzi_feichu",eventFunc,endFunc)
        elseif trigger[2] == 1 then
            util_spinePlay(spine,"actionframe_guochangx1_hong")
            util_spineFrameCallFunc(spine,"actionframe_guochangx1_hong","guanzi_feichu",eventFunc,endFunc)
        else
            util_spinePlay(spine,"actionframe_guochangx1_lan")
            util_spineFrameCallFunc(spine,"actionframe_guochangx1_lan","guanzi_feichu",eventFunc,endFunc)
        end
    elseif triggerCount == 2 then
        if trigger[1] == 1 and trigger[2] == 1 then
            util_spinePlay(spine,"actionframe_guochangx2_zihong")
            util_spineFrameCallFunc(spine,"actionframe_guochangx2_zihong","guanzi_feichu",eventFunc,endFunc)
        elseif trigger[2] == 1 and trigger[3] == 1 then
            util_spinePlay(spine,"actionframe_guochangx2_honglan")
            util_spineFrameCallFunc(spine,"actionframe_guochangx2_honglan","guanzi_feichu",eventFunc,endFunc)
        else
            util_spinePlay(spine,"actionframe_guochangx2_zilan")
            util_spineFrameCallFunc(spine,"actionframe_guochangx2_zilan","guanzi_feichu",eventFunc,endFunc)
        end
    else
        util_spinePlay(spine,"actionframe_guochangx3_zihonglan")
        util_spineFrameCallFunc(spine,"actionframe_guochangx3_zihonglan","guanzi_feichu",eventFunc,endFunc)
    end

    
    util_spinePlay(self.m_spine_sorceress,"actionframe_guochang")
    util_spineEndCallFunc(self.m_spine_sorceress,"actionframe_guochang",function(  )
        
        if type(overFunc) == "function" then
            overFunc()
        end
    end)
    self:delayCallBack(75 / 30,function(  )
        self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)

        if type(func) == "function" then
            func()
        end
    end)

    
    self:delayCallBack(83 / 30,function(  )

        local darkAni = util_createAnimation("WitchyHallowin_nvwu_zhezhao.csb")
        self.m_effectNode:addChild(darkAni,45)
        darkAni:setPosition(display.center)
        util_setCascadeOpacityEnabledRescursion(darkAni,true)
        darkAni:runCsbAction("guochang",false,function(  )
            darkAni:removeFromParent()
        end)

        local pos_spine = util_convertToNodeSpace(self.m_spine_sorceress,self.m_effectNode)
        util_changeNodeParent(self.m_effectNode,self.m_spine_sorceress,50)
        self.m_spine_sorceress:setPosition(pos_spine)
    end)
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenWitchyHallowinMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            if not self:isFixSymbol(symbolType) then
                symbolType = self.SYMBOL_EMPTY
            elseif symbolType == self.SYMBOL_BONUS_PURPLE or symbolType == self.SYMBOL_BONUS_RED or symbolType == self.SYMBOL_BONUS_BLUE then
                symbolType = self.SYMBOL_BONUS
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * self.m_machineRootScale
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * self.m_machineRootScale

            local symbolNodeInfo = {
                status = RESPIN_NODE_STATUS.IDLE,
                bCleaning = true,
                isVisible = true,
                Type = symbolType,
                Zorder = zorder,
                Tag = tag,
                Pos = pos,
                ArrayPos = arrayPos
            }
            respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo
        end
    end
    return respinNodeInfo
end

function CodeGameScreenWitchyHallowinMachine:reSpinEndAction()
    
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local grandWin = 0
    if selfData.fullGrand then
        grandWin = selfData.fullGrand[2] or 0
    end
    self.m_collect_num = selfData.collect_num
    -- 获得所有固定的respinBonus小块
    local downChipList = self.m_respinView:getAllCleaningNode()    
    local upChipList = {}
    if self.m_isDoubleReels then
        upChipList = self.m_miniMachine.m_respinView:getAllCleaningNode()   
    end
    local chipList = {} 
    local extraData = self.m_runSpinResultData.p_rsExtraData
    local grand = extraData.grand
    if self.m_isDoubleReels then
        for i,symbolNode in ipairs(upChipList) do
            chipList[#chipList + 1] = symbolNode
            symbolNode.m_isUpReel = true
        end

        for i,symbolNode in ipairs(downChipList) do
            chipList[#chipList + 1] = symbolNode
            symbolNode.m_isUpReel = false
        end
    else
        chipList = downChipList
    end

    self:playChipCollectAnim(1,chipList,function(  )
        self:respinOver()
    end)
end

--[[
    收集bonus赢钱
]]
function CodeGameScreenWitchyHallowinMachine:playChipCollectAnim(curIndex,symbolList,func)
    if curIndex > #symbolList then
        self:delayCallBack(1,function()
            if type(func) == "function" then
                func()
            end
        end)
        return
    end

    local symbolNode = symbolList[curIndex]
    if symbolNode then
        local extraData = self.m_runSpinResultData.p_rsExtraData
        local upStoredIcons = extraData.addstoredIcons
        local downStoreIcons = extraData.reSpinStoredIcons
        
        local posIndex = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
        local score,jackpotType = 0,""
        if symbolNode.m_isUpReel then
            score,jackpotType = self:getScoreByPosIndex(upStoredIcons,posIndex)
        else
            score,jackpotType = self:getScoreByPosIndex(downStoreIcons,posIndex)
        end
        

        local aniName = "jiesuan"
        local delayTime = 0.4
        if jackpotType and jackpotType ~= "" then
            aniName = "jiesuan2"
            delayTime = 2
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_collect_jp_bonus)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_collect_bonus)
        end

        local endNode = self.m_bottomUI.coinWinNode
        self:flyBonusCoinsAni(symbolNode,endNode,function(  )
            self.m_lightScore = self.m_lightScore + score
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_collect_bonus_feed_back)
            --底部赢钱光效
            self:playCoinWinEffectUI() 
            --刷新赢钱
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
        end)
        
        symbolNode:runAnim(aniName,false,function()
            
        end)
        self:delayCallBack(delayTime,function(  )
            if jackpotType and jackpotType ~= "" then
                self:showJackpotView(score,jackpotType,function(  )
                    self:playChipCollectAnim(curIndex + 1,symbolList,func)
                end)
            else
                self:playChipCollectAnim(curIndex + 1,symbolList,func)
            end
            
        end)
        
    else
        self:playChipCollectAnim(curIndex + 1,symbolList,func)
    end
end

--[[
    显示grand动画
]]
function CodeGameScreenWitchyHallowinMachine:showGrandAni(rewardData,func)
    local symbolList = rewardData.symbolList
    local isUpReel = rewardData.isUpReel
    local winCoins = rewardData.winCoins

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_bonus_trigger"])
    for k,symbolNode in pairs(symbolList) do
        symbolNode:runAnim("actionframe")
    end
    self:delayCallBack(60 / 30,function(  )
        local parentNode = self:findChild("Panel_1")
        if isUpReel then
            parentNode = self.m_miniMachine:findChild("root")
        end

        local pos = util_convertToNodeSpace(parentNode,self.m_effectNode)
        local ani = util_createAnimation("WitchyHallowin_grand_tishi.csb")
        self.m_effectNode:addChild(ani)
        ani:setPosition(pos)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_show_grand_tip_label"])
        ani:runCsbAction("actionframe",false,function(  )
            ani:removeFromParent()
        end)
        self:delayCallBack(130 / 60,function(  )
            self:showJackpotView(winCoins,"grand",func)
        end)
    end)
end

--[[
    显示jackpot弹板
]]
function CodeGameScreenWitchyHallowinMachine:showJackpotView(coins,jackpotType,func)
    local view = util_createView("CodeWitchyHallowinSrc.WitchyHallowinJackpotWinView",{
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

function CodeGameScreenWitchyHallowinMachine:getScoreByPosIndex(storeIcons,posIndex)
    for i,data in ipairs(storeIcons) do
        if data[1] == posIndex then
            return data[3],data[4]
        end
    end

    return 0,""
end

--[[
    过场到base
]]
function CodeGameScreenWitchyHallowinMachine:changeSceneToBase(func)

    local function callFunc()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_change_scene_to_base)
        local pos_spine = util_convertToNodeSpace(self:findChild("Node_juese"),self.m_effectNode)
        local spine = util_spineCreate("WitchyHallowin_nvwu",true,true)
        self.m_effectNode:addChild(spine,50)
        self.m_spine_sorceress:setVisible(false)
        spine:setPosition(pos_spine)
        util_spinePlay(spine,"actionframe_guochang2")
        util_spineFrameCallFunc(spine,"actionframe_guochang2","changjingqiehuan",function()
            if type(func) == "function" then
                func()
            end
            
        end,function(  )
            util_changeNodeParent(self:findChild("Node_juese"),self.m_spine_sorceress)
            self.m_spine_sorceress:setPosition(cc.p(0,0))
            self:runSorceressIdleAni()
            self.m_spine_sorceress:setVisible(true)
            spine:setVisible(false)
            self:delayCallBack(0.1,function(  )
                spine:removeFromParent()
            end)
        end)
    end

    
    if not self.m_isDoubleReels then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_sorceress_move_to_front"])
        util_spinePlay(self.m_spine_sorceress,"actionframe_feizou2")
        util_spineEndCallFunc(self.m_spine_sorceress,"actionframe_feizou2",function(  )
            callFunc()
        end)
    else
        callFunc()
    end
end

function CodeGameScreenWitchyHallowinMachine:showRespinOverView(effectData)

    local strCoins=util_formatCoins(self.m_serverWinCoins,50)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_show_respin_over)
    local view=self:showReSpinOver(strCoins,function()
        
        
        self:changeSceneToBase(function(  )
            self:triggerReSpinOverCallFun(self.m_lightScore)
            self:resetMusicBg() 
            self.m_lightScore = 0
        end)
        
    end)

    view:setBtnClickFunc(function(  )
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_click)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_hide_respin_over)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},680)
    view:findChild("root"):setScale(self.m_machineRootScale)
end

function CodeGameScreenWitchyHallowinMachine:triggerReSpinOverCallFun(score)
    

    self.m_specialReels = false
    self.m_iReSpinScore = score
    self.m_preReSpinStoredIcons = nil

    if self.m_serverWinCoins ~= score then
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== respin  server=" .. self.m_serverWinCoins .. "    client=" .. score .. " ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
        print("================== 服务器计算结果与客户端不一致 ====================")
    end

    local coins = nil
    if self.m_bProduceSlots_InFreeSpin then
        coins = self:getLastWinCoin() or 0
        local addCoin = self.m_serverWinCoins
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        coins = self.m_serverWinCoins or 0

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    self:postReSpinOverTriggerBigWIn(coins)
    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    self:changeTouchSpinLayerSize()

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--[[
    respin停止滚动判断结算
]]
function CodeGameScreenWitchyHallowinMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    -- if self.m_isDoubleReels then
    --     self.m_miniMachine:reSpinReelDown()
    -- end
    self:setGameSpinStage(STOP_RUN)

    self:oneRespinDown()
end

--[[
    检测是否获取grand
]]
function CodeGameScreenWitchyHallowinMachine:checkGetGrand(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local grandWin = 0
    if selfData.fullGrand then
        grandWin = selfData.fullGrand[2] or 0
    end
    local extraData = self.m_runSpinResultData.p_rsExtraData
    local grand = extraData.grand

    local downChipList = self.m_respinView:getAllCleaningNode()    
    local upChipList = {}
    if self.m_isDoubleReels then
        upChipList = self.m_miniMachine.m_respinView:getAllCleaningNode()   
    end

    if grand and grandWin > 0 then
        local params = {}
        if self.m_isDoubleReels then
            --上轮盘获得grand
            if grand and grand[2] then
                params[#params + 1] = {rewardType = "grand",symbolList = upChipList,isUpReel = true,winCoins = grandWin}
            end
            if grand and grand[1] then --下轮盘获得grand
                params[#params + 1] = {rewardType = "grand",symbolList = downChipList,isUpReel = false,winCoins = grandWin}
            end
        else
            params[#params + 1] = {rewardType = "grand",symbolList = downChipList,isUpReel = false,winCoins = grandWin}
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_show_grand_tip"])
        self.m_jackpotBar:showHitLightAni()
        self:showNextGrandAni(params,1,function(  )
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


function CodeGameScreenWitchyHallowinMachine:showNextGrandAni(params,index,func)
    if index > #params then
        self.m_jackpotBar:hideHitLightAni()
        if type(func) == "function" then
            func()
        end
        return
    end
    
    --显示grand奖励
    self.m_lightScore = self.m_lightScore + params[index].winCoins
    self:showGrandAni(params[index],function(  )
        --底部赢钱光效
        self:playCoinWinEffectUI()
        --刷新赢钱
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(self.m_lightScore))
        if not self:isRespinEnd() then
            self.m_bottomUI:notifyTopWinCoin()
        end

        --刷新赢钱
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {
        --     self.m_lightScore, true, false,0
        -- })
        
        self:showNextGrandAni(params,index + 1,func)
    end)
end
--[[
    检测玩法1添加bonus分数
]]
function CodeGameScreenWitchyHallowinMachine:checkAddBonusSymbolScore(func)
    local count = 0
    local function endFunc(  )
        local maxCount = self.m_isDoubleReels and 2 or 1
        count = count + 1
        if count < maxCount then
            return
        end

        --检测获取grand
        self:checkGetGrand(function(  )
            if type(func) == "function" then
                func()
            end
        end)
        
    end
    
    local aniName = "actionframe"
    if self.m_isDoubleReels then
        aniName = "actionframe3"
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local randomcredit = selfData.randomcredit
    local addRandomcredit = selfData.addrandomcredit
    if randomcredit or addRandomcredit then
        self.m_spine_sorceress:setVisible(true)
        --双轮盘需要提到前面来
        if self.m_isDoubleReels then
            local pos_spine = util_convertToNodeSpace(self.m_spine_sorceress,self.m_effectNode)
            util_changeNodeParent(self.m_effectNode,self.m_spine_sorceress,50)
            self.m_spine_sorceress:setPosition(pos_spine)
        end
        

        --显示加钱提示框
        if randomcredit then
            for index, data in ipairs(randomcredit) do
                local pos = self:getRowAndColByPos(data[1])
                local iCol,iRow = pos.iY,pos.iX
                local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol,iRow)
                if respinNode then
                    respinNode:showChangeMoneyTipAni()
                end
            end
        end
        if addRandomcredit then
            for index, data in ipairs(addRandomcredit) do
                local pos = self:getRowAndColByPos(data[1])
                local iCol,iRow = pos.iY,pos.iX
                local respinNode = self.m_miniMachine.m_respinView:getRespinNodeByRowAndCol(iCol,iRow)
                if respinNode then
                    respinNode:showChangeMoneyTipAni()
                end
            end
        end
        
        --播放女巫施法音效
        local randIndex = math.random(1,10)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_add_bonus_ani"])
        local soundFunc = function(  )
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_add_bonus_score_"..self.m_curAddBonusSoundIndex])
                
            self.m_curAddBonusSoundIndex = self.m_curAddBonusSoundIndex + 1
            if self.m_curAddBonusSoundIndex > 2 then
                self.m_curAddBonusSoundIndex = 1
            end
        end
        if self.m_isDoubleReels then
            if randIndex <= 3 then
                soundFunc()
            end
        else
            if randIndex <= 2 then
                soundFunc()
            end
        end

        --女巫播放施法动作
        util_spinePlay(self.m_spine_sorceress,aniName)
        util_spineFrameCallFunc(self.m_spine_sorceress,aniName,"shifa",function()
            
            if randomcredit then
                for index, data in ipairs(randomcredit) do
                    self:updateScoreOnSymbol(data[1],data[2])
                end
            end

            self:delayCallBack(17 / 60,function(  )
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_add_bonus_score_feed_back)
            end)

            if self.m_isDoubleReels then
                self.m_miniMachine:checkAddBonusSymbolScore(endFunc)
            end
        
            
        end,function(  )
            if self.m_isDoubleReels then
                -- util_changeNodeParent(self:findChild("Node_juese"),self.m_spine_sorceress)
                -- self.m_spine_sorceress:setPosition(cc.p(0,0))
            else
                util_spinePlay(self.m_spine_sorceress,"idleframe6",true)
            end
            

            self:delayCallBack(40 / 60,function(  )
                endFunc()
            end)
        end)
        self.m_RESPIN_RUN_TIME = 0.4
    else

        self.m_RESPIN_RUN_TIME = 1.2
        endFunc()
        if self.m_isDoubleReels then
            self.m_miniMachine:checkAddBonusSymbolScore(endFunc)
        end
    end
end

--[[
   刷新小块分数
]]
function CodeGameScreenWitchyHallowinMachine:updateScoreOnSymbol(posIndex,addMul,func)
    local pos = self:getRowAndColByPos(posIndex)
    local iCol,iRow = pos.iY,pos.iX
    local respinNode = self.m_respinView:getRespinNodeByRowAndCol(iCol,iRow)
    local symbolNode = respinNode.m_baseFirstNode

    local lineBet = globalData.slotRunData:getCurTotalBet()
    if symbolNode and symbolNode.p_symbolType and symbolNode.p_symbolType == self.SYMBOL_BONUS then

        local startNode = self.m_spine_sorceress.m_startNode_single
        if self.m_isDoubleReels then
            startNode = self.m_spine_sorceress.m_startNode_double
        end
        self:runFlyLineAct(startNode,symbolNode,function(  )
            local score = self:getReSpinSymbolScore(posIndex,false) --获取分数（网络数据）
            if score ~= nil then
                local csbNode = self:getLblOnBonusSymbol(symbolNode)
                local label = csbNode:findChild("m_lb_coins")
                local labelGold = csbNode:findChild("m_lb_coins_0")
                
                local addScore = addMul * lineBet
                self:jumpCoins(label,labelGold,symbolNode.m_score,score,function(  )
                    score = util_formatCoins(score, 3)
                    label:setString(score)
                    labelGold:setString(score)
                end)
                symbolNode:runAnim("shouji",false,function(  )
                    symbolNode:runAnim("idleframe2",true)
                end)
                --加钱动画
                local addAni = util_createAnimation("WitchyHallowin_Moneychange.csb")
                self.m_effectNode:addChild(addAni)
                addAni:setPosition(util_convertToNodeSpace(csbNode:findChild("Node_Moneychange"),self.m_effectNode))
                self:playAddCoinsSound()
                addAni:runCsbAction("actionframe",false,function(  )
                    addAni:removeFromParent()
                    respinNode:hideChangeMoneyTipAni()
                end)

                local str = util_formatCoins(addScore, 3)
                addAni:findChild("BitmapFontLabel_1"):setString("+"..str)
                
                symbolNode.m_score = score
                
            end
        end)
    end
end

--[[
    播放加金币音效
]]
function CodeGameScreenWitchyHallowinMachine:playAddCoinsSound( )
    if self.m_isAddCoinsSoundPlayed then
        return
    end
    self.m_isAddCoinsSoundPlayed = true
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_show_add_coins"])
end

function CodeGameScreenWitchyHallowinMachine:oneRespinDown()
    
    self.m_downReelCount = self.m_downReelCount + 1
    local maxCount = self.m_isDoubleReels and 2 or 1

    if self.m_quickRunSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_quickRunSoundId)
        self.m_quickRunSoundId = nil
    end

    --显示下一个快滚节点
    if self.m_isShowQuickRun then
        self:showNextQuickNode()
    elseif #self.m_quickRunNodes > 0 then
        table.remove(self.m_quickRunNodes,1)
        self:playQuickSound()
    end

    if self.m_downReelCount < maxCount then
        return
    end

    self:setGameSpinStage(IDLE)
    self:updateQuestUI()

    local isRespinEnd = self:isRespinEnd()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    local function callFunc(  )
        self:checkAddBonusSymbolScore(function(  )
            if not isRespinEnd then
                self:runNextReSpinReel()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            else
                self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
    
                --quest
                self:updateQuestBonusRespinEffectData()
    
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    
                self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins, GameEffect.EFFECT_RESPIN_OVER)
                self.m_isWaitingNetworkData = false
    
                --结算前加0.5s延时
                self:delayCallBack(0.5,function(  )
                    --结束
                    self:reSpinEndAction()
                end)
                
            end
            
        end)
    end

    if self.m_isShowQuickRun then
        self:delayCallBack(0.8,function(  )
            callFunc()
        end)
    else
        callFunc()
    end

    

    if self.m_runSpinResultData.p_reSpinCurCount > 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount)
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
    else
        self.m_respinBar:completeAni()
    end
end

--[[
    respin是否结束
]]
function CodeGameScreenWitchyHallowinMachine:isRespinEnd( )
    local isRespinEnd = false
    local extraCount = 0
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.add_reSpinCurCount then
        extraCount = selfData.add_reSpinCurCount
    end
    if not self.m_isDoubleReels and self.m_runSpinResultData.p_reSpinCurCount == 0 then
        isRespinEnd = true
    elseif self.m_isDoubleReels and self.m_runSpinResultData.p_reSpinCurCount == 0 and extraCount == 0 then
        isRespinEnd = true
    end
    return isRespinEnd
end

--开始下次ReSpin
function CodeGameScreenWitchyHallowinMachine:runNextReSpinReel()
    if self:checkGameRunPause() == true then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end
    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if globalData.slotRunData.gameSpinStage == IDLE then
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
end


--开始滚动
function CodeGameScreenWitchyHallowinMachine:startReSpinRun()
    self.m_respinReelDownSound = {}
    self.m_bonus_down = {}
    self.m_isAddCoinsSoundPlayed = false
    if self.m_runSpinResultData.p_reSpinCurCount == 0 then
        self.m_respinBar:completeAni()
    end
    if self:isRespinEnd() then
        return
    end

    self.m_isShowQuickRun = false

    --清空赢钱
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    self.m_lightScore = 0

    self.m_downReelCount = 0
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)
    self:requestSpinReusltData()

    globalData.slotRunData.gameSpinStage = GAME_MODE_ONE_RUN
    --mini轮开始滚动
    if self.m_isDoubleReels then
        self.m_miniMachine:startReSpinRun()
    end

    --下面的轮盘停了但是上面还没停
    if self.m_runSpinResultData.p_reSpinCurCount <= 0 then
        self:reSpinReelDown()

        --计算快滚的节点
        self:getQuickNode()
        --拉伸镜头显示快滚的节点
        if #self.m_quickLastRunNodes > 0 then
            self:showNextQuickNode()
        elseif #self.m_quickRunNodes > 0 then
            table.remove(self.m_quickRunNodes,1)
            self:playQuickSound()
        end

        
        return
    end

    

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    else
        self.m_startSpinTime = nil
    end

    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_respinView:startMove()

    --计算快滚的节点
    self:getQuickNode()
    --拉伸镜头显示快滚的节点
    if #self.m_quickLastRunNodes > 0 then
        self:showNextQuickNode()
    elseif #self.m_quickRunNodes > 0 then
        table.remove(self.m_quickRunNodes,1)
        self:playQuickSound()
    end
end

---
-- 检测处理respin  和 special reel的逻辑
--
function CodeGameScreenWitchyHallowinMachine:checkOpearReSpinAndSpecialReels(param)
    -- self:closeCheckTimeOut()
    if self:getCurrSpinMode() == RESPIN_MODE and self.m_specialReels then
        if param[1] == true then
            local spinData = param[2]
            -- print("respin"..cjson.encode(param[2]))
            if spinData.action == "SPIN" then
                self:operaWinCoinsWithSpinResult(param)

                self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
                self:getRandomList()
                if self.m_isDoubleReels then
                    self.m_miniMachine:setSpinResultData(self.m_runSpinResultData,false)
                end

                self:stopRespinRun()

                self:setGameSpinStage(GAME_MODE_ONE_RUN)

                if not self.m_isShowQuickRun then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
                end
            end
        else
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect()
        end
        return true
    end
    return false
end

--接收到数据开始停止滚动
function CodeGameScreenWitchyHallowinMachine:stopRespinRun()
    local storedNodeInfo = self:getRespinSpinData()
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)
    

    if self.m_isDoubleReels then
        self.m_miniMachine:stopRespinRun()
    end
end

function CodeGameScreenWitchyHallowinMachine:MachineRule_respinTouchSpinBntCallBack()
    if globalData.slotRunData.gameSpinStage == IDLE and globalData.slotRunData.currSpinMode == RESPIN_MODE then 
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self:startReSpinRun()
        
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)
        
    elseif globalData.slotRunData.gameSpinStage == GAME_MODE_ONE_RUN then
        self:quicklyStop()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end 
end

--- respin 快停
function CodeGameScreenWitchyHallowinMachine:quicklyStop()
    self.m_respinView:quicklyStop()
    if self.m_isDoubleReels then
        self.m_miniMachine:quicklyStop()
    end
end

function CodeGameScreenWitchyHallowinMachine:respinOver()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    self:showRespinOverView()
end

--respin结束 把respin小块放回对应滚轴位置
function CodeGameScreenWitchyHallowinMachine:checkChangeRespinFixNode(node)
    node.p_showOrder = 0

    local startReel = self.m_runSpinResultData.p_rsExtraData.start_reel

    if startReel then
        local symbolType
        local rowData =  startReel[self.m_iReelRowNum - node.p_rowIndex + 1]
        if rowData then
            symbolType = rowData[node.p_cloumnIndex]
        end
        if symbolType then
            self:changeSymbolType(node,symbolType)
            self:updateReelGridNode(node)
        else
            local randType = math.random(0,self.SYMBOL_SCORE_10)
            self:changeSymbolType(node,randType)
        end
    else
        if node.p_symbolType == self.SYMBOL_EMPTY then
            local randType = math.random(0,self.SYMBOL_SCORE_10)
            self:changeSymbolType(node,randType)
        else
            node:runAnim("idleframe2",true)
        end
    end

    --将小块放回原层级
    self:changeBaseParent(node)
end

--[[
    跳动金币
]]
function CodeGameScreenWitchyHallowinMachine:jumpCoins(node,nodeGold,startCoins,coins,func)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local multi = startCoins/lineBet
    node:setString(util_formatCoins(startCoins,3))
    nodeGold:setString(util_formatCoins(startCoins,3))
    if multi >= 5 then
        node:setVisible(false)
        nodeGold:setVisible(true)
    else
        node:setVisible(true)
        nodeGold:setVisible(false)
    end

    local coinRiseNum =  (coins - startCoins) / 5

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 3 ))
    coinRiseNum = tonumber(str)

    local curCoins = startCoins
    node:stopAllActions()
    
    util_schedule(node,function()

        curCoins = curCoins + coinRiseNum
        curCoins = math.ceil(curCoins)

        local multi = curCoins/lineBet
        if multi >= 5 then
            node:setVisible(false)
            nodeGold:setVisible(true)
        else
            node:setVisible(true)
            nodeGold:setVisible(false)
        end

        if curCoins >= coins then

            curCoins = coins

            node:setString(util_formatCoins(curCoins,3))
            nodeGold:setString(util_formatCoins(curCoins,3))
            -- self:updateLabelSize({label=node,sx=1,sy=1},775)

            node:stopAllActions()
            if type(func) == "function" then
                func()
            end
        else
            node:setString(util_formatCoins(curCoins,3))
            nodeGold:setString(util_formatCoins(curCoins,3))
            -- self:updateLabelSize({label=node,sx=1,sy=1},775)
        end
    end,1 / 60)
end

--[[
    加钱拖尾动画
]]
function CodeGameScreenWitchyHallowinMachine:runFlyLineAct(startNode,endNode,endFunc)

    -- 创建粒子
    local csbName = "WitchyHallowin_tw.csb"
    local width = 620
    if self.m_isDoubleReels then
        csbName = "WitchyHallowin_tw2.csb"
        width = 300
    end
    local flyNode =  util_createAnimation(csbName)
    self.m_effectNode:addChild(flyNode,120)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    
    flyNode:setPosition(startPos)

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / width)
    flyNode:runCsbAction("actionframe",false,function()
        flyNode:removeFromParent()
    end)
    self:delayCallBack(17 / 60,function(  )
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
    return flyNode

end

--[[
    震动root点
]]
function CodeGameScreenWitchyHallowinMachine:shakeRootNode( )

    local changePosY = 10
    local changePosX = 5
    local actionList2={}
    local oldPos = cc.p(self:findChild("root"):getPosition())
    
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x - changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x + changePosX ,oldPos.y + changePosY))
    actionList2[#actionList2+1]=cc.MoveTo:create(1/30,cc.p(oldPos.x,oldPos.y))
    local seq2=cc.Sequence:create(actionList2)
    self:findChild("root"):runAction(cc.RepeatForever:create(seq2))

end

--[[
    重置root点位置
]]
function CodeGameScreenWitchyHallowinMachine:resetRootPos()
    local rootNode = self:findChild("root")
    rootNode:stopAllActions()
    rootNode:setPosition(display.center)
end


function CodeGameScreenWitchyHallowinMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

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
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)

    local ratio = display.height / display.width
    if ratio <= 1024 / 768 then
        mainScale = 0.69
        mainPosY = mainPosY + 28
    elseif ratio > 1024 / 768 and ratio <= 960 / 640 then
        mainScale = 0.81
        mainPosY = mainPosY + 25
    elseif ratio > 960 / 640 and ratio <= 1228 / 768 then
        mainScale = 0.87
        mainPosY = mainPosY + 18
    elseif ratio > 1228 / 768 and ratio < 1368 / 768 then
        mainScale = 0.87
        mainPosY = mainPosY + 18
    elseif ratio >= 1368 / 768 and ratio < 1560 / 768 then
        mainScale = 1
        mainPosY = mainPosY + 15
    else
        mainScale = 1
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

--[[
    获取快滚节点
]]
function CodeGameScreenWitchyHallowinMachine:getQuickNode()
    
    --快滚的node
    local targetNodes = {}

    local quickRunNodes = {}

    if self.m_isDoubleReels then
        if self.m_miniMachine.m_respinView.m_isLastSpin and self.m_miniMachine.m_respinView.m_quickRunNode then
            targetNodes[#targetNodes + 1] = self.m_miniMachine.m_respinView.m_quickRunNode
            self.m_miniMachine.m_respinView.m_quickRunNode.m_isMainMachine = false
        elseif self.m_miniMachine.m_respinView.m_quickRunNode then
            quickRunNodes[#quickRunNodes + 1] = self.m_miniMachine.m_respinView.m_quickRunNode
            self.m_miniMachine.m_respinView.m_quickRunNode.m_isMainMachine = false
        end
    end

    if self.m_respinView.m_isLastSpin and self.m_respinView.m_quickRunNode then
        targetNodes[#targetNodes + 1] = self.m_respinView.m_quickRunNode
        self.m_respinView.m_quickRunNode.m_isMainMachine = true
    elseif self.m_respinView.m_quickRunNode then
        quickRunNodes[#quickRunNodes + 1] = self.m_respinView.m_quickRunNode
        self.m_respinView.m_quickRunNode.m_isMainMachine = false
    end

    self.m_quickLastRunNodes = targetNodes
    self.m_quickRunNodes = quickRunNodes
end

--[[
    显示下一个快滚节点(拉伸镜头效果)
]]
function CodeGameScreenWitchyHallowinMachine:showNextQuickNode()
    if #self.m_quickLastRunNodes == 0 then
        self:resetMoveNodeStatus()
        return 
    end

    self.m_isShowQuickRun = true

    local moveNode = self:findChild("Node_1")
    local parentNode = moveNode:getParent()

    local targetNode = self.m_quickLastRunNodes[1]
    table.remove(self.m_quickLastRunNodes,1)

    if targetNode.m_isMainMachine then
        self.m_respinView:showExpectAni()
    else
        self.m_miniMachine:showExpectAni()
    end

    local params = {
        moveNode = moveNode,--要移动节点
        targetNode = targetNode,--目标位置节点
        parentNode = parentNode,--移动节点的父节点
        time = 2.8,--移动时间
        actionType = 3,
        scale = 2,--缩放倍数
    }

    local randIndex = math.random(1,3)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_WitchyHallowin_sorceress_sound_"..randIndex])

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_scale_root_node)
    self:playQuickSound( )

    util_moveRootNodeAction(params)
end

--[[
    播放快滚音效
]]
function CodeGameScreenWitchyHallowinMachine:playQuickSound( )
    if self.m_quickRunSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_quickRunSoundId)
        self.m_quickRunSoundId = nil
    end
    self.m_quickRunSoundId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_quick_run_single)
end

--[[
    重置移动节点状态
]]
function CodeGameScreenWitchyHallowinMachine:resetMoveNodeStatus()
    if self.m_quickRunSoundId ~= nil then
        gLobalSoundManager:stopAudio(self.m_quickRunSoundId)
        self.m_quickRunSoundId = nil
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_reset_move_node)
    local moveNode = self:findChild("Node_1")
    --恢复移动节点状态
    local spawn = cc.Spawn:create({
        cc.MoveTo:create(0.5,cc.p(0,0)),
        cc.ScaleTo:create(0.5,1)
    })
    moveNode:stopAllActions()
    moveNode:runAction(cc.EaseSineInOut:create(spawn))
end

--[[
    播放bonus落地音效
]]
function CodeGameScreenWitchyHallowinMachine:playBonusDownSound(colIndex)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_bonus_down)
end

--[[
    respin单列停止
]]
function CodeGameScreenWitchyHallowinMachine:respinOneReelDown(colIndex,isQuickStop)
    if not self.m_respinReelDownSound[colIndex] then
        if not isQuickStop then
            gLobalSoundManager:playSound("WitchyHallowinSounds/sound_WitchyHallowin_reel_down.mp3")
        else
            gLobalSoundManager:playSound("WitchyHallowinSounds/sound_WitchyHallowin_down_quick.mp3")
        end
    end

    self.m_respinReelDownSound[colIndex] = true
    if isQuickStop then
        for iCol = 1,self.m_iReelColumnNum do
            self.m_respinReelDownSound[iCol] = true
        end
    end
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenWitchyHallowinMachine:showBigWinLight(_func)
    local spine_light = util_spineCreate("WitchyHallowin_bigwin",true,true)

    local parentNode = self:findChild("Node_light")
    parentNode:addChild(spine_light)

    local csbLight = util_createAnimation("WitchyHallowin_bigwin.csb")
    parentNode:addChild(csbLight)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WitchyHallowin_big_win)

    util_spinePlay(spine_light,"actionframe")
    util_spineEndCallFunc(spine_light,"actionframe",function(  )
        spine_light:setVisible(false)
        self:delayCallBack(0.1,function(  )
            spine_light:removeFromParent()
            csbLight:removeFromParent()
        end)
    end)
    
    util_spinePlay(self.m_spine_sorceress,"actionframe_bigwin")
    util_spineEndCallFunc(self.m_spine_sorceress,"actionframe_bigwin",function(  )
        self:runSorceressIdleAni()
        self:resetRootPos()
        if type(_func) == "function" then
            _func()
        end
    end)

    self:shakeRootNode()
end

return CodeGameScreenWitchyHallowinMachine






