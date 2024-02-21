---
-- island li
-- 2019年1月26日
-- CodeGameScreenRocketPupMachine.lua  外星牛
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseSlotoManiaMachine
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local PublicConfig = require "RocketPupPublicConfig"

local CodeGameScreenRocketPupMachine = class("CodeGameScreenRocketPupMachine", BaseSlotoManiaMachine)

CodeGameScreenRocketPupMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenRocketPupMachine.m_vecMiniWheel = {}

CodeGameScreenRocketPupMachine.PLAYSCENELOBBY_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1

function CodeGameScreenRocketPupMachine:initGameStatusData(gameData)
    if gameData and gameData.spin and gameData.spin.selfData and gameData.spin.selfData.bet then
        globalData.slotRunData:setDIYBet(gameData.spin.selfData.bet)
    end
    CodeGameScreenRocketPupMachine.super.initGameStatusData(self, gameData)
end

-- 构造函数
function CodeGameScreenRocketPupMachine:ctor()
    CodeGameScreenRocketPupMachine.super.ctor(self)
    globalData.slotRunData:setIsDTY(true)
    self.m_spinRocketPupState = "init"
    self.m_FsDownTimes = 0
    self.m_spinStatesTimes = 0
    self.m_isAddBigWinLightEffect = true
    self.m_publicConfig = PublicConfig

    --init
    self:initGame()
end

function CodeGameScreenRocketPupMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenRocketPupMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RocketPup"
end

function CodeGameScreenRocketPupMachine:initCloumnSlotNodesByNetData()
    if true or self.m_initSpinData.p_reels == nil then
        self:initRandomSlotNodes()
    else
        CodeGameScreenRocketPupMachine.super.initCloumnSlotNodesByNetData(self)
    end
end

function CodeGameScreenRocketPupMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar
    self.m_bigwinEffect = util_spineCreate("RocketPup_bigwin", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffect)
    self.m_bigwinEffect1 = util_spineCreate("RocketPup_bigwin_2", true, true)
    self:findChild("Node_bigwin"):addChild(self.m_bigwinEffect1)
    self.m_bigwinEffect:setVisible(false)
    self.m_bigwinEffect1:setVisible(false)
end

function CodeGameScreenRocketPupMachine:initFreeSpinBar()
    local node_bar = self:findChild("Node_freebar")
    self.m_baseFreeSpinBar = util_createView("RocketPupSrc.RocketPupFreespinBarView")
    if node_bar and self.m_baseFreeSpinBar then
        node_bar:addChild(self.m_baseFreeSpinBar)
        self.m_baseFreeSpinBar:setPositionY(20)
    end
end

function CodeGameScreenRocketPupMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    --globalData.slotRunData:setIsRocketPup(true)
    self:addObservers()

    self.m_vecMiniWheel = {}
    if self:checkTriggerOnEnterINFreeSpin() then
        print(">>>>>>>>>>>>>>>>>>>>>>>> freeSpin = ")
        local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
        local reel = self.m_runSpinResultData.p_selfMakeData.reels
        self:initFsMiniReels(#reel)
    end
    CodeGameScreenRocketPupMachine.super.onEnter(self) -- 必须调用不予许删除
    --小轮盘赋值
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for i = 1, #self.m_vecMiniWheel do
            local miniMachine = self.m_vecMiniWheel[i]
            miniMachine:enterLevelMiniSelf()
            miniMachine:MachineRule_newInitGame()
        end
    end
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    if not selfdata.buffs then
        return
    end
    self:sortBuffs(selfdata.buffs)
    self:upDataBuffInfo(#selfdata.reels)
end

function CodeGameScreenRocketPupMachine:sortBuffs(_buffData)
    self.m_buffData = {}
    for i,v in ipairs(_buffData) do
        if v.buffType == "SLOT1_WILD" then
            self.m_buffData[1] = v
        elseif v.buffType == "SLOT1_WHEEL" then
            self.m_buffData[2] = v
        elseif v.buffType == "SLOT1_SYMBOL" then
            self.m_buffData[3] = v
        end
    end
end

function CodeGameScreenRocketPupMachine:upDataBuffInfo(reelNum)
    if #self.m_buffData <= 0 then
        return
    end
    self.m_buffS = {}
    local infx = reelNum
    if reelNum > 1 then
        self:findChild("Node_buff"):setVisible(false)
    end
    if reelNum == 4 then
        infx = 3
    end
    for i=1,3 do
        local item = {}
        local data = self.m_buffData[i]
        if reelNum == 1 then
            local node = self:findChild("buff"..i.."_di")
            local spine = util_spineCreate("Socre_RocketPup_" .. (i+6), true, true)
            spine:setPosition(102,43)
            node:addChild(spine)
            util_spinePlay(spine, "idle", true)
            item.spine = spine
        end
        

        local wenannode = self:findChild("buff"..i.."_wenan_"..infx)
        local wenan, act = util_csbCreate("RocketPup_buffwenan.csb")
        wenannode:addChild(wenan)
        item.wenan = wenan
        local rootNode = wenan:getChildByName("root")
        local rot = rootNode:getChildByName("Node_buff"..i)
        rot:setVisible(true)
        if i == 3 then
            for j=1,4 do
                local spX = rot:getChildByName("sp_x_"..j)
                if spX then
                    spX:setVisible(j <= tonumber(data.value))
                end
            end
        else
            local vaule = rot:getChildByName("m_lb_num_"..i)
            vaule:setString(data.value)
            if i == 2 then
                local lva = tonumber(data.value)
                if lva > 0 then
                    lva = lva - 1
                end
                vaule:setString(lva)
            end
        end

        local lvnode = rot:getChildByName("lv"..i)
        local lv, act1 = util_csbCreate("RocketPup_buff_level.csb")
        lvnode:addChild(lv)
        local lvroot = lv:getChildByName("root")
        local lb_lv = lvroot:getChildByName("m_lb_num")
        lb_lv:setString(data.level)
        item.lv = lv
        table.insert(self.m_buffS,item)
    end
end

function CodeGameScreenRocketPupMachine:checkTriggerOnEnterINFreeSpin()
    local isPlayGameEff = false

    if self.m_initSpinData then
        -- 检测是否处于
        local hasFreepinFeature = false
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            hasFreepinFeature = true
        end

        local hasReSpinFeature = false
        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            hasReSpinFeature = true
        end

        local hasBonusFeature = false
        if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
            hasBonusFeature = true
        end

        local isInFs = false
        if
            hasFreepinFeature == false and self.m_initSpinData.p_freeSpinsTotalCount ~= nil and self.m_initSpinData.p_freeSpinsTotalCount > 0 and
                (self.m_initSpinData.p_freeSpinsLeftCount > 0 or (hasReSpinFeature == true or hasBonusFeature == true))
         then
            -- fs 总数量 ， 以及 剩余数量都> 0 表明处于fs中
            isInFs = true
        end

        if isInFs == true then
            -- lxy 这我注释掉的可能有用
            if self.m_initSpinData.p_freeSpinsTotalCount ~= self.m_initSpinData.p_freeSpinsLeftCount then
                isPlayGameEff = true
            end
        end
    end

    return isPlayGameEff
end

function CodeGameScreenRocketPupMachine:addObservers()
    CodeGameScreenRocketPupMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            if self.m_spinRocketPupState == "init" then
                return
            end
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

            local soundName = "RocketPupSounds/music_RocketPup_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )

    gLobalNoticManager:addObserver(self, self.slotReelDownInFS, "RocketPupMiniDownInFS")
end

function CodeGameScreenRocketPupMachine:showEffect_NewWin(effectData, winType)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    CodeGameScreenRocketPupMachine.super.showEffect_NewWin(self, effectData, winType)
end

function CodeGameScreenRocketPupMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRocketPupMachine.super.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
    globalData.slotRunData:setIsDTY(false)
end

-- 插入棋盘
function CodeGameScreenRocketPupMachine:initFsMiniReels(reel, _switchOver)
    self.m_reelNum = reel
    for i = 1, reel do
        -- 创建轮子
        
        local addNode = nil
        if i == 1 then
            local name = "Node_qipanshu1"
            addNode = self.m_csbOwner[name]
        else
            local name = "Node_qipanshu"..reel
            local p_node = self.m_csbOwner[name]
            addNode = p_node:getChildByName("Node_"..i)
        end

        if addNode then
            local data = {}
            data.index = 3
            data.parent = self
            data.reelId = i
            data.unlock = i <= reel
            data.weelNum = self.m_reelNum
            data.csbPath = "RocketPup_qipan"
            local miniMachine = util_createView("RocketPupSrc.RocketPupMiniMachine", data)
            local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
            miniMachine:setBuffDatas(selfdata.buffs)

            addNode:addChild(miniMachine)
            if data.unlock then
                self.m_bottomUI.m_spinBtn:addTouchLayerClick(miniMachine.m_touchSpinLayer)
            end
            table.insert(self.m_vecMiniWheel, miniMachine)
        end
    end
    -- 重新赋值一下
    globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
    globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    self:updateScaleMainLayer()
end

function CodeGameScreenRocketPupMachine:playSwitch(_over)
    local function switchOver()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_RocketPup_wheel)
        self:runCsbAction("idle"..self.m_reelNum,true)
        self:playMiniWheelAddWild(_over)
    end
    if self.m_reelNum > 1 then
        self:runCsbAction("switch" .. self.m_reelNum, false, switchOver)
    else
        self:runCsbAction("idle", true)
        if switchOver then
            switchOver()
        end
    end
end

function CodeGameScreenRocketPupMachine:playMiniWheelAddWild(_over)
    local addWildBuffData = self:getBuffData("SLOT1_WILD")
    if addWildBuffData == nil or tonumber(addWildBuffData.value) == 0 then
        if _over then
            _over()
        end
        return
    end
    local value = addWildBuffData.value
    local level = addWildBuffData.level
    if self.m_vecMiniWheel and #self.m_vecMiniWheel > 0 then
        local wheelNum = #self.m_vecMiniWheel
        for i=1,wheelNum do
            local mWheel = self.m_vecMiniWheel[i]
            if not tolua.isnull(mWheel) then
                mWheel:playAddWild(level, value, i ,function()
                    if i == wheelNum and _over then
                        _over()
                    end
                end)
            end
        end
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_RocketPup_addwild)
end

function CodeGameScreenRocketPupMachine:getBuffData(_buffType)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local buffDatas = selfdata.buffs
    if buffDatas and #buffDatas > 0 then
        for i=1,#buffDatas do
            if buffDatas[i].buffType == _buffType then
                return buffDatas[i]
            end
        end
    end
    return nil
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenRocketPupMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return "Socre_RocketPup_Wild"
    end
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenRocketPupMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenRocketPupMachine.super.getPreLoadSlotNodes(self)
    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenRocketPupMachine:MachineRule_initGame()
    --self:resetMusicBg()
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenRocketPupMachine:showBigWinLight(_func)
    self.m_bigwinEffect:setVisible(true)
    self.m_bigwinEffect1:setVisible(true)

    util_spinePlay(self.m_bigwinEffect,"actionframe_bigwin",false)
    util_spinePlay(self.m_bigwinEffect1,"actionframe_totalwin",false)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_RocketPup_show_big_win_light)
    util_spineEndCallFunc(self.m_bigwinEffect1,"actionframe_totalwin",function()
        self.m_bigwinEffect:setVisible(false)
        self.m_bigwinEffect1:setVisible(false)
        
        if _func then
            _func()
        end
    end)
end

--
--单列滚动停止回调
--
function CodeGameScreenRocketPupMachine:slotOneReelDown(reelCol)
    CodeGameScreenRocketPupMachine.super.slotOneReelDown(self, reelCol)
end

--freespin下主轮调用父类停止函数
function CodeGameScreenRocketPupMachine:slotReelDownInFS()
    self.m_isReconnection = false
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    self:setGameSpinStage(STOP_RUN)
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex

    -- 清理之前数据
    local slotsList = self.m_reelSlotsList
    local listLen = #slotsList
    for i = 1, listLen do
        local columnDatas = slotsList[i]

        for dataIndex = #columnDatas, 1, -1 do
            local reelData = columnDatas[dataIndex]

            if reelData == nil or tolua.type(reelData) == "number" then
                -- do nothing
            else
                reelData:clear()
                self.m_reelSlotDataPool[#self.m_reelSlotDataPool + 1] = reelData
            end

            columnDatas[dataIndex] = nil
        end
    end -- end for i = 1,listLen

    if self.m_reelResultLines and #self.m_reelResultLines > 0 then
        for i = #self.m_reelResultLines, 1, -1 do
            local value = self.m_reelResultLines[i]

            value:clean()
            self.m_reelResultLines[i] = nil

            self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = value
        end
    elseif self.m_reelResultLines == nil then
        self.m_reelResultLines = {}
    end

    self:reelDownNotifyChangeSpinStatus()
    self:delaySlotReelDown()
    self:stopAllActions()
    self:reelDownNotifyPlayGameEffect()
    self:checkNotifyUpdateWinCoin()
end

----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenRocketPupMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("RocketPupSounds/music_RocketPup_custom_enter_fs.mp3")
    if self.m_iFreeSpinTimes == 0 then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsLeftCount
    end
    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            local callback = function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
            self:showFreeSpinStart(function()
                if not tolua.isnull(self) then
                    self:playSwitch(callback)
                end
            end)
        else
            self:createLittleReels(
                function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end
            )
        end
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        0.1
    )
end

function CodeGameScreenRocketPupMachine:createLittleReels(func)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local reels = selfdata.reels or {}
    self:initFsMiniReels(#reels)
    --小轮盘赋值
    for i = 1, #self.m_vecMiniWheel do
        local miniMachine = self.m_vecMiniWheel[i]
        miniMachine:enterLevelMiniSelf()
    end

    self:showFreeSpinStart(function()
        if not tolua.isnull(self) then
            self:playSwitch(func)
        end
    end)
end

function CodeGameScreenRocketPupMachine:showFreeSpinStart(func)
    -- local selfData = self.m_runSpinResultData.p_selfMakeData
    -- local rowCount = tonumber(selfData.reelsMode) 
    local ownerlist = {}
    ownerlist["m_lb_coins"] = globalData.slotRunData.freeSpinCount
    ownerlist["buffs"] = self.m_buffData

    local view = util_createView("RocketPupSrc.RocketPupFreeStartView",{
        machine = self,
        ownerlist = ownerlist,
        scale = self.m_machineRootScale,
        func = func,
    })
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_RocketPup_show_freestart)
    --view:setBtnClickFunc(self.m_publicConfig.SoundConfig.sound_RocketPup_click)
    self:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    -- view:setPosition(display.center)

    return view
end


function CodeGameScreenRocketPupMachine:showFreeSpinOverView()
    self:clearCurMusicBg()
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_RocketPup_show_jiesuan)

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:triggerFreeSpinOverCallFun()
        end
    )
    view:findChild("Button_1"):setTouchEnabled(false)
    performWithDelay(view,function()
        view:findChild("Button_1"):setTouchEnabled(true)
    end,20/30)
    view:setBtnClickFunc(function()
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_RocketPup_click)
    end)
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.8, sy = 0.8}, 1010)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenRocketPupMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    return false -- 用作延时点击spin调用
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenRocketPupMachine:addSelfEffect()
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
function CodeGameScreenRocketPupMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.PLAYSCENELOBBY_EFFECT then
        local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
        local totolWinNum = self.m_runSpinResultData.p_fsWinCoins
        local winRatio = totolWinNum / lTatolBetNum
        local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("DIYWin", "DIYWin_" .. winRatio)
        if view then
            view:setOverFunc(function()
                self:playSceneLobby()
            end)
        else
            self:playSceneLobby()
        end
    end
    return true
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenRocketPupMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenRocketPupMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenRocketPupMachine.super.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

function CodeGameScreenRocketPupMachine:slotReelDown()
    print("滚动结束了....CodeGameScreenRocketPupMachine")
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    CodeGameScreenRocketPupMachine.super.slotReelDown(self)
end

function CodeGameScreenRocketPupMachine:beginReel()
    self.m_isReconnection = false
    self.m_isQuicklyStopReel = false

    self.m_spinRocketPupState = "spin"
    if self.m_bProduceSlots_InFreeSpin == true then
        if not globalData.slotRunData.freeSpinCount or globalData.slotRunData.freeSpinCount <= 0 then
            return
        end
        self.m_waitChangeReelTime = 0
        release_print("beginReel ... ")

        self:stopAllActions()
        self:requestSpinReusltData() -- 临时注释掉

        -- 记录 本次spin 中共产生的 scatter和bonus 数量，播放音效使用
        self.m_nScatterNumInOneSpin = 0
        self.m_nBonusNumInOneSpin = 0
        --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SET_SPIN_BTN_ORDER,{false,gLobalViewManager.p_ViewLayer })
        local effectLen = #self.m_gameEffects
        for i = 1, effectLen, 1 do
            self.m_gameEffects[i] = nil
        end
        self:clearWinLineEffect()
        for i = 1, #self.m_vecMiniWheel do
            local mninReel = self.m_vecMiniWheel[i]
            if mninReel then
                mninReel:beginMiniReel()
            end
        end
    end
end

function CodeGameScreenRocketPupMachine:dealSmallReelsSpinStates()

end

function CodeGameScreenRocketPupMachine:spinResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "SPIN" then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if not spinData.result.selfData and not spinData.result.reels then
                    return
                end
            end
        end
    end
    self.m_FsDownTimes = 0
    self.m_spinStatesTimes = 0
    self:createSpinResultData(param)
    CodeGameScreenRocketPupMachine.super.spinResultCallFun(self, param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "SPIN" then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if spinData.result.freespin and spinData.result.selfData then
                    local resultDatas = spinData.result.selfData.reels
                    local SLOT1_SYMBOL = spinData.result.selfData.SLOT1_SYMBOL
                    for i = 1, #self.m_vecMiniWheel do
                        local mninReel = self.m_vecMiniWheel[i]
                        local miniReelsResultDatas = resultDatas[i]
                        if i == 1 then
                            mninReel.m_serverWinCoins = spinData.result.winAmount
                        end
                        -- if miniReelsResultDatas.selfData then
                        --     if miniReelsResultDatas.selfData.SLOT1_SYMBOL and #miniReelsResultDatas.selfData.SLOT1_SYMBOL > 0 then
                        --         for j=1,#miniReelsResultDatas.selfData.SLOT1_SYMBOL do
                        --             local posIndex = miniReelsResultDatas.selfData.SLOT1_SYMBOL[j][1]
                        --             local tarSymbolType = miniReelsResultDatas.selfData.SLOT1_SYMBOL[j][2]
                        --             local fixPos = self:getRowAndColByPos(posIndex)
                        --             local iRow,iCol = fixPos.iX,fixPos.iY
                        --             print("iRow,iCol=", iRow,iCol)
                        --             miniReelsResultDatas.reels[iRow][iCol] = tarSymbolType
                        --         end
                        --     end
                        -- end                        
                        if miniReelsResultDatas then
                            miniReelsResultDatas.bet = spinData.result.bet
                            miniReelsResultDatas.action = spinData.result.action
                            miniReelsResultDatas.freespin = spinData.result.freespin
                            miniReelsResultDatas.freespin.freeSpinsTotalCount = 0
                            miniReelsResultDatas.freespin.freeSpinsLeftCount = 0
                            miniReelsResultDatas.payLineCount = spinData.result.payLineCount
                            mninReel:netWorkCallFun(miniReelsResultDatas)
                        end
                        print("miniReelsResultDatas")
                    end
                end
            end
        end
    end
end

function CodeGameScreenRocketPupMachine:createSpinResultData(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "SPIN" then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if spinData.result.freespin and spinData.result.selfData then
                    local resultDatas = spinData.result.selfData.reels
                    for i = 1, 4 do
                        local miniReelsResultDatas = resultDatas[i]
                        if miniReelsResultDatas ~= nil then
                            if i == 1 then
                                spinData.result.lines = miniReelsResultDatas.lines
                                spinData.result.nextReel = miniReelsResultDatas.nextReel
                                spinData.result.prevReel = miniReelsResultDatas.prevReel
                                spinData.result.reels = miniReelsResultDatas.reels
                            end
                            -- self.m_isPlayMoveWild = miniReelsResultDatas.specialSignals
                            -- if miniReelsResultDatas.specialSignals then
                            --     self.m_wildMoveTime = 1.4
                            --     self.m_isPlayMoveWildReelId = i
                            -- end
                        end
                    end
                end
            end
        end
    end
end


function CodeGameScreenRocketPupMachine:updateResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
end

function CodeGameScreenRocketPupMachine:playEffectNotifyChangeSpinStatus()
    CodeGameScreenRocketPupMachine.super.playEffectNotifyChangeSpinStatus(self)
   
end

function CodeGameScreenRocketPupMachine:setFsAllRunDown(times)
    self.m_FsDownTimes =  self.m_FsDownTimes + times
    if self.m_FsDownTimes >= self.m_reelNum then
        gLobalNoticManager:postNotification("RocketPupMiniDownInFS")
    end
end

-----------------------------------关闭左侧活动----------------------------

function CodeGameScreenRocketPupMachine:triggerFreeSpinOverCallFun()
    self:createSceneLobby()
    CodeGameScreenRocketPupMachine.super.triggerFreeSpinOverCallFun(self)
end

function CodeGameScreenRocketPupMachine:createSceneLobby()
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.PLAYSCENELOBBY_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.PLAYSCENELOBBY_EFFECT -- 动画类型
end

function CodeGameScreenRocketPupMachine:playSceneLobby()
    local diy = G_GetMgr(ACTIVITY_REF.DiyFeature)
    if diy and diy:getRunningData() then
        local levelInfo = diy:getGameLevel()
        if levelInfo then
            --gLobalViewManager:gotoSlotsScene(levelInfo)
            diy:setWillShowMainLayer(true)
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        else
            diy:setWillShowMainLayer(true)
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
        end
    else
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    end
end

function CodeGameScreenRocketPupMachine:getBottomUINode()
    return "RocketPupSrc.RocketPupGameBottomNode"
end

-- 显示paytableview 界面
-- function CodeGameScreenRocketPupMachine:showPaytableView()
-- end

function CodeGameScreenRocketPupMachine:updateScaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()
    local size = cc.size(1082, 600)
    local winSize = display.size
    if self.m_reelNum > 1 then
        size = cc.size(1190, 292)
    end
    local node_bar = self:findChild("Node_freebar")
    local wis = winSize.width / winSize.height
    local py = -250
    if wis >= 1970/768 then
        py = -210
        size = cc.size(1350, 292)
        if self.m_reelNum ~= 2 then
            size = cc.size(1750, 292)
            py = -290
        end
    elseif wis >= 2340/1080 then
        if self.m_reelNum ~= 2 then
            size = cc.size(1700, 292)
            py = -270
        else
            size = cc.size(1400, 292)
            py = -230
        end 
    elseif winSize.width / winSize.height >= 1660/768 then
        if self.m_reelNum ~= 2 then
            size = cc.size(1600, 292)
            py = -280
        else
            size = cc.size(1400, 292)
            py = -230
        end 
    elseif wis >= 1530/768 then
        if self.m_reelNum ~= 2 then
            size = cc.size(1500, 292)
            py = -275
        else
            py = -240
        end
    elseif wis >= 1370/768 then
        --size = cc.size(1190, 292)
        if self.m_reelNum >= 3 then
            size = cc.size(1280, 292)
            py = -290
        elseif self.m_reelNum == 1 then
            py = -290
        end
    elseif wis >= 1920/1080 then
        size = cc.size(1300, 292)
        if self.m_reelNum == 1 then
            py = -290
        end
    elseif wis >= 920/768 then
        py = -290
    end
    local node_bar = self:findChild("Node_freebar")
    if wis >= 920/768 then
        local poy = node_bar:getPositionY()
        node_bar:setPositionY(py)
    end
    size.width = size.width * 1.15
    -- size.height = size.height * 1.1
    local height = winSize.height - uiBH - uiH
    local width = winSize.width
    local scale1 = width / size.width
    local scale2 = height / size.height
    local scale = math.min(scale1, scale2)
    scale = scale / self.m_machineRootScale
    self.m_scale = scale
    self:findChild("qp"):setScale(scale)
end

function CodeGameScreenRocketPupMachine:getMachineScale()
    return self.m_scale or 1
end

function CodeGameScreenRocketPupMachine:checkNotifyUpdateWinCoin()
    local isNotPlay = true
    for i = 1, #self.m_vecMiniWheel do
        local miniMachine = self.m_vecMiniWheel[i]
        local _winLines = miniMachine.m_reelResultLines
        if _winLines and #_winLines > 0 then
            isNotPlay = false
            break
        end
    end
    if isNotPlay then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    local freeWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    globalData.slotRunData.lastWinCoin = freeWinCoins
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenRocketPupMachine:setFsAllSpinStates(times)

    self.m_spinStatesTimes =  self.m_spinStatesTimes + times
    if self.m_spinStatesTimes >= self.m_reelNum then
        self.m_isPlayMoveWild = nil
        CodeGameScreenRocketPupMachine.super.dealSmallReelsSpinStates(self)
    end
end

return CodeGameScreenRocketPupMachine
