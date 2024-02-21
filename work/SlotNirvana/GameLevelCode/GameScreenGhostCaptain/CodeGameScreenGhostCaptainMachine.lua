---
-- island li
-- 2019年1月26日
-- CodeGameScreenGhostCaptainMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local PublicConfig = require "GhostCaptainPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenGhostCaptainMachine = class("CodeGameScreenGhostCaptainMachine", BaseNewReelMachine)

CodeGameScreenGhostCaptainMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

--自定义的小块类型
CodeGameScreenGhostCaptainMachine.SYMBOL_10 = 9
CodeGameScreenGhostCaptainMachine.SYMBOL_11 = 10
CodeGameScreenGhostCaptainMachine.SYMBOL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
CodeGameScreenGhostCaptainMachine.SYMBOL_WHEEL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenGhostCaptainMachine.SYMBOL_WHEELSUPER_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3

-- 自定义动画的标识
CodeGameScreenGhostCaptainMachine.COLLECT_BONUS_COINS = GameEffect.EFFECT_SELF_EFFECT + 2 -- 结算Bonus的钱
CodeGameScreenGhostCaptainMachine.FREE_BONUS_MOVE = GameEffect.EFFECT_SELF_EFFECT + 1 -- 结算Bonus的钱

-- 构造函数
function CodeGameScreenGhostCaptainMachine:ctor()
    CodeGameScreenGhostCaptainMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("GhostCaptainSrc.GhostCaptainSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("GhostCaptainLongRunControl",self) 

    self.m_iBetLevel = 0 -- bet等级
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_isAddBigWinLightEffect = true
    self.m_specialBetMulti = {}
    self.m_langEffectNodeList = {}
    self.m_hasfeature = false
    self.m_freeDuanXian = false -- free玩法断线
    self.m_isInitSlotNode = false -- 刚进入关卡是否显示初始棋盘
    self.m_isInitSlotNodeNums = 0
    self.m_scatterNums = 0 -- scatter落地的个数
    self.m_isPlayScatterQuick = true
    self.m_isPlayBonusQuick = true
    self.m_isPlayBonusBulingCol = {true, true, true, true, true}
    self.m_isPlayWheelBonusQuick = true
    self.m_isPlayWheelBonusBulingCol = {true, true, true, true, true}
    --init
    self:initGame()
end

function CodeGameScreenGhostCaptainMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("GhostCaptainConfig.csv", "LevelGhostCaptainConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  
---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGhostCaptainMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "GhostCaptain"  
end

function CodeGameScreenGhostCaptainMachine:getBottomUINode( )
    return "GhostCaptainSrc.GhostCaptainBoottomUIView"
end

function CodeGameScreenGhostCaptainMachine:initUI()
    -- 特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("Node_reel"):addChild(self.m_effectNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView() 
    self:createReelsKuang()

    -- 左右的灯 
    local leftDengNode = util_createAnimation("GhostCaptain_deng.csb")
    self:findChild("zd"):addChild(leftDengNode)
    leftDengNode:runCsbAction("idle", true)
    local rightDengNode = util_createAnimation("GhostCaptain_deng.csb")
    self:findChild("yd"):addChild(rightDengNode)
    rightDengNode:runCsbAction("idle", true)

    -- 点击高低bet按钮
    self.m_controlBetView = util_createView("GhostCaptainSrc.GhostCaptainControlBetView", {machine = self})
    self:findChild("Node_base_collect"):addChild(self.m_controlBetView)

    -- 高低bet界面
    self.m_chooseBetView = util_createView("GhostCaptainSrc.GhostCaptainChooseBetView", {machine = self})
    self:addChild(self.m_chooseBetView, GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN + 2)
    self.m_chooseBetView:setVisible(false)
    self.m_chooseBetView:findChild("root"):setScale(self.m_machineRootScale)

    -- 棋盘压暗
    self.m_reelsDarkNode = util_createAnimation("GhostCaptain_yaan.csb")
    self.m_clipParent:addChild(self.m_reelsDarkNode, REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 30)
    self.m_reelsDarkNode:setVisible(false)
    self.m_reelsDarkNode:setPosition(util_convertToNodeSpace(self:findChild("Node_yugao"), self.m_clipParent))

    -- 5列浪花 效果
    for index = 1, 5 do
        local langNode = util_createAnimation("GhostCaptain_lang.csb")
        self:findChild("Node_lang_"..(index-1)):addChild(langNode)
        langNode:setVisible(false)
        self.m_langEffectNodeList[index] = langNode
    end

    self.m_reelSuoAnimTouch = {}
    for index = 1, 4 do
        local pos = util_convertToNodeSpace(self:findChild("sp_reel_" .. index),  self.m_clipParent)
        self.m_reelSuoAnimTouch[index] = ccui.Layout:create()
        self.m_reelSuoAnimTouch[index]:setContentSize(cc.size(208, 486))
        self.m_reelSuoAnimTouch[index]:setAnchorPoint(cc.p(0, 0))
        self.m_reelSuoAnimTouch[index]:setTouchEnabled(true)
        self.m_reelSuoAnimTouch[index]:setSwallowTouches(true)
        self.m_clipParent:addChild(self.m_reelSuoAnimTouch[index], SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2 + 1)
        self.m_reelSuoAnimTouch[index]:setPosition(cc.p(pos.x, pos.y))
        self.m_reelSuoAnimTouch[index]:setName("Panel_Click" .. index)
        -- 临时不要这个功能了
        -- self:addClick(self.m_reelSuoAnimTouch[index])
        self.m_reelSuoAnimTouch[index]:setVisible(false)
    end

    self:setReelBg(1)
    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "GhostCaptain_yqqFK")
end

--[[
    棋盘框
]]
function CodeGameScreenGhostCaptainMachine:createReelsKuang( )
    -- 棋盘框
    self.m_kuangOldNode = util_createAnimation("GhostCaptain_base_choicekuang.csb")
    self.m_onceClipNode:addChild(self.m_kuangOldNode, 10000)
    self.m_kuangOldNode:setPosition(util_convertToNodeSpace(self:findChild("Node_choicekuang"), self.m_onceClipNode))

    self.m_kuangNewNode = util_createAnimation("GhostCaptain_base_choicekuang.csb")
    self.m_onceClipNode:addChild(self.m_kuangNewNode, 10001)
    self.m_kuangNewNode:setPosition(util_convertToNodeSpace(self:findChild("Node_choicekuang"), self.m_onceClipNode))

    self.m_kuangOldNode1 = util_createAnimation("GhostCaptain_base_choicekuang_0.csb")
    self:findChild("Node_choicekuang"):addChild(self.m_kuangOldNode1, 1)

    self.m_kuangNewNode1 = util_createAnimation("GhostCaptain_base_choicekuang_0.csb")
    self:findChild("Node_choicekuang"):addChild(self.m_kuangNewNode1, 2)
end

--[[
    设置点击区域 是否显示
]]
function CodeGameScreenGhostCaptainMachine:setReelsTouch(_isShow)
    -- for _, _clickNode in ipairs(self.m_reelSuoAnimTouch) do
    --     _clickNode:setVisible(_isShow)
    -- end
end

function CodeGameScreenGhostCaptainMachine:initMachineBg()
    CodeGameScreenGhostCaptainMachine.super.initMachineBg(self)
    self.m_gameBgSpine = util_spineCreate("GhostCaptain_bg", true, true)
    self.m_gameBg:findChild("bg"):addChild(self.m_gameBgSpine)
    util_spinePlay(self.m_gameBgSpine, "idle_base", true)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenGhostCaptainMachine:initSpineUI()
    -- 大赢前 预告动画
    self.m_bigWinEffect1 = util_spineCreate("GhostCaptain_bigwin", true, true)
    self:findChild("Node_bigwin2"):addChild(self.m_bigWinEffect1)
    self.m_bigWinEffect1:setVisible(false)
    self.m_bigWinEffect2 = util_spineCreate("GhostCaptain_bigwin_jinbi", true, true)
    self:findChild("Node_bigwin1"):addChild(self.m_bigWinEffect2)
    self.m_bigWinEffect2:setVisible(false)

    -- 预告动画
    self.m_yugaoSpineEffect1 = util_spineCreate("GhostCaptain_yugao", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect1, 1)
    self.m_yugaoSpineEffect1:setVisible(false)
    self.m_yugaoSpineEffect2 = util_spineCreate("GhostCaptain_jinbi", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect2, 2)
    self.m_yugaoSpineEffect2:setVisible(false)
    self.m_yugaoSpineEffect3 = util_spineCreate("GhostCaptain_jinbi2", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect3, 3)
    self.m_yugaoSpineEffect3:setVisible(false)
    self.m_yugaoSpineEffect4 = util_spineCreate("GhostCaptain_yugao2", true, true)
    self:findChild("Node_yugao"):addChild(self.m_yugaoSpineEffect4, 4)
    self.m_yugaoSpineEffect4:setVisible(false)

    -- 进入关卡
    self.m_enterGameSpineEffect = util_spineCreate("GhostCaptain_ruchang", true, true)
    self:addChild(self.m_enterGameSpineEffect, GAME_LAYER_ORDER.LAYER_ORDER_UI + 1)
    self.m_enterGameSpineEffect:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_enterGameSpineEffect:setVisible(false)

    -- free过场动画
    self.m_guochangFreeEffect = util_spineCreate("GhostCaptain_guochang",true,true)
    self:findChild("Node_yugao"):addChild(self.m_guochangFreeEffect)
    self.m_guochangFreeEffect:setVisible(false)

    -- freeOver过场动画
    self.m_guochangFreeOverEffect = util_spineCreate("GhostCaptain_bg",true,true)
    self:findChild("Node_yugao"):addChild(self.m_guochangFreeOverEffect)
    self.m_guochangFreeOverEffect:setVisible(false)

    -- 转盘相关
    self.m_bonusBgSpine = util_spineCreate("GhostCaptain_bg",true,true)
    self:findChild("Node_bonusGame"):addChild(self.m_bonusBgSpine, 1)
    self.m_bonusBgSpine:setVisible(false)
    
    self.m_bonusDarkNode = util_createAnimation("GhostCaptain_ya.csb")
    self:findChild("Node_bonusGame"):addChild(self.m_bonusDarkNode, REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 9999)
    self.m_bonusDarkNode:setVisible(false)

    self.m_bonusWheel = util_createView("GhostCaptainSrc.GhostCaptainWheelView", {machine = self})
    self.m_guochangBonusEffect1 = util_spineCreate("GhostCaptain_guochang",true,true)
    self:findChild("Node_bonusGame"):addChild(self.m_guochangBonusEffect1, 3)
    self.m_guochangBonusEffect1:setVisible(false)
    util_spinePushBindNode(self.m_guochangBonusEffect1, "zp", self.m_bonusWheel)
    self.m_bonusWheel:setVisible(false)

    self.m_guochangBonusEffect2 = util_spineCreate("GhostCaptain_guochang",true,true)
    self:findChild("Node_bonusGame"):addChild(self.m_guochangBonusEffect2, 2)
    self.m_guochangBonusEffect2:setVisible(false)

    -- bonus玩法结束过场
    self.m_bonusOverGuoChangSpine = util_spineCreate("GhostCaptain_bg",true,true)
    self:findChild("Node_bonusGuochang"):addChild(self.m_bonusOverGuoChangSpine, 10)
    self.m_bonusOverGuoChangSpine:setVisible(false)
end

--[[
    --设置棋盘的背景
    -- _BgIndex 1bace 2free
]]
function CodeGameScreenGhostCaptainMachine:setReelBg(_BgIndex)
    self.m_gameBg:runCsbAction("idle1")
    if _BgIndex == 1 then
        util_spinePlay(self.m_gameBgSpine, "idle_base", true)
    elseif _BgIndex == 2 then
        util_spinePlay(self.m_gameBgSpine, "idle_fg", true)
    end
    self:findChild("base_guang_1"):setVisible(_BgIndex == 1)
    self:findChild("base_guang_2"):setVisible(_BgIndex == 1)
    self:findChild("free_guang_1"):setVisible(_BgIndex == 2)
    self:findChild("free_guang_2"):setVisible(_BgIndex == 2)
    self:findChild("Node_base_reel"):setVisible(_BgIndex == 1)
    self:findChild("Node_free_reel"):setVisible(_BgIndex == 2)
end

function CodeGameScreenGhostCaptainMachine:enterGamePlayMusic()
    self.m_enterGameSpineEffect:setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_enter)
    util_spinePlay(self.m_enterGameSpineEffect, "actionframe_ruchang", false)
    util_spineEndCallFunc(self.m_enterGameSpineEffect, "actionframe_ruchang", function ()
        self.m_enterGameSpineEffect:setVisible(false)
    end)

    self:delayCallBack(0.4,function()
        self:playEnterGameSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_enter_game)
    end)
end

function CodeGameScreenGhostCaptainMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenGhostCaptainMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    if not self.m_hasfeature then
        self:setSpinTounchType(false)
        self:changeBetAndBetBtn()
        self:changeKuangEffect(true)
        self.m_chooseBetView:showView()
    else
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.betLevel then
            self.m_iBetLevel = self.m_runSpinResultData.p_selfMakeData.betLevel
        end
        self:changeBetAndBetBtn()
        self:changeKuangEffect(true)
        if not self.m_bProduceSlots_InFreeSpin then
            self:setReelsClickEnter()
        end

        for iCol = 1,self.m_iReelColumnNum do
            for row = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, row, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType then
                    if slotNode.p_symbolType == self.SYMBOL_BONUS or slotNode.p_symbolType == self.SYMBOL_WHEEL_BONUS or slotNode.p_symbolType == self.SYMBOL_WHEELSUPER_BONUS then
                        if iCol > (self.m_iBetLevel+1) then
                            slotNode:runAnim("idleframe3")
                        end
                    end
                end
            end
        end
    end
end

--[[
    进入关卡设置 reel条点击
]]
function CodeGameScreenGhostCaptainMachine:setReelsClickEnter( )
    -- for index = 1, 4 do
    --     if index <= self.m_iBetLevel then
    --         self.m_reelSuoAnimTouch[index]:setVisible(false)
    --     else
    --         self.m_reelSuoAnimTouch[index]:setVisible(true)
    --     end
    -- end
end

function CodeGameScreenGhostCaptainMachine:addObservers()
    CodeGameScreenGhostCaptainMachine.super.addObservers(self)
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
        end

        local soundTime = soundIndex
        if self.m_bottomUI then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_GhostCaptain_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_GhostCaptain_winLines" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    -- 打开选择bet界面
    gLobalNoticManager:addObserver(self,function(self,params)
        if self:isNormalStates() and self.m_bottomUI.m_spinBtn.m_spinBtn:isVisible() and
            self.m_bottomUI.m_spinBtn.m_spinBtn:isTouchEnabled() then
            self.m_chooseBetView:showView(self.m_iBetLevel)
        end
    end, "OPEN_CHOOSEVIEW")

    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:upateBetLevel()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenGhostCaptainMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    globalData.slotRunData.m_curBetMultiply = 1 -- 恢复初始倍率
    CodeGameScreenGhostCaptainMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

end

function CodeGameScreenGhostCaptainMachine:initGameStatusData(gameData)
    CodeGameScreenGhostCaptainMachine.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.betMulti then
        self.m_specialBetMulti = gameData.gameConfig.extra.betMulti
    end
end

--默认按钮监听回调
function CodeGameScreenGhostCaptainMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if string.find(name, "Panel_Click") ~= nil then
        if self:isNormalStates() and string.len(name) == 12 and self.m_bottomUI.m_spinBtn.m_spinBtn:isVisible() and
            self.m_bottomUI.m_spinBtn.m_spinBtn:isTouchEnabled() then
            local num = tonumber(string.sub(name, 12, string.len(name)))
            self:chooseBetLevel(num+1)
        end
    end
end

function CodeGameScreenGhostCaptainMachine:isNormalStates( )
    local featureLen = self.m_runSpinResultData.p_features or {}
    if #featureLen >= 2 and self.m_initFeatureData == nil then
        return false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == AUTO_SPIN_MODE then
        return false
    end

    if  self:getGameSpinStage() ~= IDLE and not self.m_isRunningEffect then
        return false
    end

    if  globalData.slotRunData.gameEffStage == GAME_START_REQUEST_STATE then
        return false
    end

    return true
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGhostCaptainMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_10 then
        return "Socre_GhostCaptain_10"
    elseif symbolType == self.SYMBOL_11 then
            return "Socre_GhostCaptain_11"
    elseif symbolType == self.SYMBOL_BONUS then
        return "Socre_GhostCaptain_Bonus"
    elseif symbolType == self.SYMBOL_WHEEL_BONUS then
        return "Socre_GhostCaptain_WheelBonus"
    elseif symbolType == self.SYMBOL_WHEELSUPER_BONUS then
        return "Socre_GhostCaptain_SuperWheelBonus"
    end 

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGhostCaptainMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenGhostCaptainMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_10,count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BONUS,count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WHEEL_BONUS,count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WHEELSUPER_BONUS,count = 2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenGhostCaptainMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_runSpinResultData.p_freeSpinsLeftCount ~= self.m_runSpinResultData.p_freeSpinsTotalCount then
            self.m_freeDuanXian = true
        end
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        self:setReelBg(2)
        self.m_controlBetView:playDarkEffect()
        self:setReelsTouch(false)
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenGhostCaptainMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

--
--单列滚动停止回调
--
function CodeGameScreenGhostCaptainMachine:slotOneReelDown(reelCol)    
    CodeGameScreenGhostCaptainMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol) 

end

--[[
    滚轮停止
]]
function CodeGameScreenGhostCaptainMachine:slotReelDown( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    CodeGameScreenGhostCaptainMachine.super.slotReelDown(self)

    if self.m_isInitSlotNode then
        self.m_isInitSlotNode = false
    end
end

---------------------------------------------------------------------------
--[[
    判断是否触发base下收集
]]
function CodeGameScreenGhostCaptainMachine:isTriggerBaseCollect()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local isTrigger = false
        local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
        if selfMakeData and selfMakeData.betLevel then
            for iCol = 1, selfMakeData.betLevel+1 do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    if selfMakeData.expandReels then
                        local symbolType = selfMakeData.expandReels[iRow][iCol] 
                        if symbolType == self.SYMBOL_BONUS then
                            isTrigger = true
                            break
                        end
                    end
                end
            end
        end
        if isTrigger then
            return true
        end
    else
        if self.m_runSpinResultData.p_selfMakeData.coinBonus and self.m_runSpinResultData.p_selfMakeData.coinPosition and 
            table.nums(self.m_runSpinResultData.p_selfMakeData.coinBonus) > 0 and table.nums(self.m_runSpinResultData.p_selfMakeData.coinPosition) > 0 then
            return true
        end
    end
    return false
end

--[[
    判断是否触发base下收集
]]
function CodeGameScreenGhostCaptainMachine:isTriggerFreeBonusMove()
    self.m_bonusMoveInfo = {}
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.reelPosition then
        for iCol = 1,self.m_iReelColumnNum do
            local tb = {}
            for iRow = 1,self.m_iReelRowNum do
                local symbolType = self:getMatrixPosSymbolType(iRow,iCol)
                if self:checkSymbolIsBonus(symbolType) then
                    table.insert(tb, iRow)
                end
            end

            if #tb ~= 0 then
                if self:checkBonusListIsContinuity(tb) then
                    release_print("error zhao shuzi !!!!!!!!这里不可能在中间，那么就要找数值")
                end
                local beginPos = tb[1]
                local endPos = tb[#tb]
                if beginPos == 1 and endPos ~= self.m_iReelRowNum then
                    local bonustb = {col = iCol, beginNum = 3 - #tb, direction = "up"}
                    table.insert(self.m_bonusMoveInfo,bonustb)
                elseif beginPos ~= 1 and endPos == self.m_iReelRowNum then
                    local bonustb = {col = iCol, beginNum = 3 - #tb, direction = "down"}
                    table.insert(self.m_bonusMoveInfo,bonustb)
                elseif beginPos == 1 and endPos == self.m_iReelRowNum then
                    --中间 不处理 写下来方便输出错误日志
                else
                    release_print("error zhao shuzi !!!!!!!!这里不可能在中间，那么就要找数值")
                end
            end
        end
        if #self.m_bonusMoveInfo > 0 then
            return true
        end
        return false
    end
    return false
end

function CodeGameScreenGhostCaptainMachine:checkSymbolIsBonus(_symbolType)
    if _symbolType == self.SYMBOL_BONUS or _symbolType == self.SYMBOL_WHEEL_BONUS or _symbolType == self.SYMBOL_WHEELSUPER_BONUS then
        return true
    end
    return false
end

function CodeGameScreenGhostCaptainMachine:checkBonusListIsContinuity(_bonusList)
    --如果只有一个，且在中间 rowIndex = 2
    if #_bonusList == 1 then
        if _bonusList[1] and _bonusList[1] == 2 then
            return true
        end
    end
    return false
end

--[[
    添加free
]]
function CodeGameScreenGhostCaptainMachine:addFreeSpinEffect( )
    -- 添加freespin effect
    local freeSpinEffect = GameEffectData.new()
    freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
    freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
    self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
end
--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGhostCaptainMachine:addSelfEffect()
    if self:isTriggerBaseCollect() then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.COLLECT_BONUS_COINS -- 动画类型
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE and self:isTriggerFreeBonusMove() then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FREE_BONUS_MOVE -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGhostCaptainMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.FREE_BONUS_MOVE then
        self:delayCallBack(0.3, function()
            self:playEffect_freeBonusMovetEffect(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.COLLECT_BONUS_COINS then
        local delayTime = 0.6
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            delayTime = 0.3
        end
        self:delayCallBack(delayTime, function()
            self:playEffect_baseCollectEffect(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    end
    return true
end

--[[
    base玩法 收集bonus钱
]]
function CodeGameScreenGhostCaptainMachine:playEffect_baseCollectEffect(_func)
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local coinPosition = self.m_runSpinResultData.p_selfMakeData.coinPosition or {}
    local coinBonus = self.m_runSpinResultData.p_selfMakeData.coinBonus or {}
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    if self:getCurrSpinMode() == FREE_SPIN_MODE then --free玩法 重新处理有效赢钱数据
        coinPosition = {}
        if selfMakeData and selfMakeData.betLevel then
            for iCol = 1, selfMakeData.betLevel+1 do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    if selfMakeData.expandReels then
                        local symbolType = selfMakeData.expandReels[iRow][iCol] 
                        if symbolType == self.SYMBOL_BONUS then
                            if iRow == 1 then
                                iRow = 3
                            elseif iRow == 3 then
                                iRow = 1
                            end
                            local pos = self:getPosReelIdx(iRow, iCol)
                            table.insert(coinPosition, pos)
                        end
                    end
                end
            end
        end
    end

    local allCoins = 0
    for _, _pos in ipairs(coinPosition) do
        local pos = self:getRowAndColByPos(_pos)
        local symbolNode = self:getFixSymbol(pos.iY, pos.iX)
        if symbolNode and symbolNode.p_symbolType then
            if symbolNode.p_symbolType == self.SYMBOL_BONUS then
                allCoins = allCoins + coinBonus[tostring(_pos)]
                symbolNode.m_oldZOrder = symbolNode:getZOrder()
                symbolNode:setZOrder(symbolNode.m_oldZOrder + 10000 + pos.iY)
                symbolNode:runAnim("actionframe", false, function()
                    symbolNode:setZOrder(symbolNode.m_oldZOrder)
                    symbolNode:runAnim("idleframe2", true)
                end)
            end
        end
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_bonus_jiesuan)

    --通用底部跳字动效
    self:delayCallBack(5/30, function()
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local params = {
            overCoins  = allCoins,
            jumpTime   = 1,
            animName   = "actionframe3",
        }
        self:playBottomBigWinLabAnim(params)
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            self:playWinCoinsBottom(allCoins, false)
        else
            local feautes = self.m_runSpinResultData.p_features or {}
            if #feautes > 1 and feautes[2] == 5 then
                self:playWinCoinsBottom(allCoins, false)
            else
                self:playWinCoinsBottom(allCoins, true)
            end
        end
    end)
    
    local delayCallBack = 40/30
    if self:checkHasBigWin() then
        delayCallBack = 40/30 + 0.5
    end
    self:delayCallBack(delayCallBack, function()
        if _func then
            _func()
        end
    end)
end

--[[
    显示赢钱区的钱
]]
function CodeGameScreenGhostCaptainMachine:playWinCoinsBottom(_addCoins, _isNotifyUpdateTop)
    self:playCoinWinEffectUI()
    -- 刷新底栏
    local bottomWinCoin = self:getCurBottomWinCoins()
    self:setLastWinCoin(bottomWinCoin + _addCoins)
    self.m_bottomUI.m_changeLabJumpTime = 0.5
    self:updateBottomUICoins(0, _addCoins, _isNotifyUpdateTop, true, false)
    self.m_bottomUI.m_changeLabJumpTime = nil
end

--获取底栏金币
function CodeGameScreenGhostCaptainMachine:getCurBottomWinCoins()
    local winCoin = 0

    if nil == self.m_bottomUI.m_updateCoinHandlerID then
        local sCoins = self.m_bottomUI.m_normalWinLabel:getString()
        if "" == sCoins then
            return winCoin
        end
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

--更新底栏金币
function CodeGameScreenGhostCaptainMachine:updateBottomUICoins(_beiginCoins,_endCoins, isNotifyUpdateTop, _bJump, _playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins, isNotifyUpdateTop, _bJump, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

--[[
    获得bonus的赢钱
]]
function CodeGameScreenGhostCaptainMachine:getBonusWinCoins( )
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData or {}
    local coinPosition = self.m_runSpinResultData.p_selfMakeData.coinPosition or {}
    local coinBonus = self.m_runSpinResultData.p_selfMakeData.coinBonus or {}
    if self:getCurrSpinMode() == FREE_SPIN_MODE then --free玩法 重新处理有效赢钱数据
        coinPosition = {}
        if selfMakeData and selfMakeData.expandCoinBonus and table.nums(selfMakeData.expandCoinBonus) > 0 then
            coinBonus = selfMakeData.expandCoinBonus
        end
        if selfMakeData and selfMakeData.betLevel then
            for iCol = 1, selfMakeData.betLevel+1 do
                for iRow = self.m_iReelRowNum, 1, -1 do
                    if selfMakeData.expandReels then
                        local symbolType = selfMakeData.expandReels[iRow][iCol] 
                        if symbolType == self.SYMBOL_BONUS then
                            local pos = self:getPosReelIdx(iRow, iCol)
                            table.insert(coinPosition, pos)
                        end
                    end
                end
            end
        end
    end

    local allCoins = 0
    for _, _pos in ipairs(coinPosition) do
        if coinBonus and coinBonus[tostring(_pos)] then
            allCoins = allCoins + coinBonus[tostring(_pos)]
        end
    end

    return allCoins
end

function CodeGameScreenGhostCaptainMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 then
        notAdd = true
        if self:isTriggerBaseCollect() then
            notAdd = false
        end
    end

    return notAdd
end

function CodeGameScreenGhostCaptainMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
        self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin - self:getBonusWinCoins()
        if self:getBonusWinCoins() > 0 then
            self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins - self:getBonusWinCoins())
        end
    else
        -- base下 有bonus收集 重新计算
        local coinPosition = self.m_runSpinResultData.p_selfMakeData.coinPosition or {}
        if #coinPosition > 0 then
            isNotifyUpdateTop = false
        end
        self.m_iOnceSpinLastWin = self.m_iOnceSpinLastWin - self:getBonusWinCoins()
        self:setLastWinCoin(self.m_iOnceSpinLastWin)
    end
    
    local params = {self.m_iOnceSpinLastWin, isNotifyUpdateTop}
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
end

--[[
    free 玩法 bonus移动
]] 
function CodeGameScreenGhostCaptainMachine:playEffect_freeBonusMovetEffect(_func)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local newReels = self.m_runSpinResultData.p_selfMakeData.expandReels or {}
    if #newReels > 0 then
        self.m_runSpinResultData.p_reels = newReels
        if selfData and selfData.expandCoinBonus and table.nums(selfData.expandCoinBonus) > 0 then
            if self.m_runSpinResultData.p_selfMakeData.coinBonus then
                self.m_runSpinResultData.p_selfMakeData.coinBonus = selfData.expandCoinBonus
            else
                self.m_runSpinResultData.p_selfMakeData.coinBonus = {}
                self.m_runSpinResultData.p_selfMakeData.coinBonus = selfData.expandCoinBonus
            end
        end
        if selfData and selfData.expandCoinBonusStr and table.nums(selfData.expandCoinBonusStr) > 0 then
            if self.m_runSpinResultData.p_selfMakeData.coinBonusStr then
                self.m_runSpinResultData.p_selfMakeData.coinBonusStr = selfData.expandCoinBonusStr
            else
                self.m_runSpinResultData.p_selfMakeData.coinBonusStr = {}
                self.m_runSpinResultData.p_selfMakeData.coinBonusStr = selfData.expandCoinBonusStr
            end
        end
    end

    local isShake = false
    local allNode = {}
    local hideBonusNode = {} --隐藏的bonus
    local newBonus = {}
    for _, _data in ipairs(self.m_bonusMoveInfo) do
        local iCol = _data.col
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))
        local reelSize = reelNode:getContentSize()
        local pos = cc.p(util_convertToNodeSpace(reelNode, self.m_effectNode))
        local reelsNode = util_createAnimation("GhostCaptain_reelsMove.csb")
        self.m_effectNode:addChild(reelsNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10000 + iCol)
        reelsNode:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
        table.insert(allNode, reelsNode)
        if iCol <= (self.m_iBetLevel+1) then
            isShake = true
        end

        for index = 1, 3 do
            local nodeIndex = index
            if index == 1 then
                nodeIndex = 3
            elseif index == 3 then
                nodeIndex = 1
            end
            local sysmbol = newReels[index][iCol]
            local symbolNode = util_spineCreate(self:getSymbolCCBNameByType(self, sysmbol), true, true)
            reelsNode:findChild("Node_"..nodeIndex):addChild(symbolNode, index)
            util_spinePlay(symbolNode, "idleframe", false)
            symbolNode.iCol = iCol
            if sysmbol == self.SYMBOL_BONUS then
                self:showReelsBonusCoins(symbolNode, nodeIndex, iCol)
            end
            table.insert(newBonus, symbolNode)
        end

        if _data.direction == "up" then
            reelsNode:findChild("Node_rootNew"):setPositionY(-162 * _data.beginNum)
        else
            reelsNode:findChild("Node_rootNew"):setPositionY(162 * _data.beginNum)
        end

        -- 动画
        local downEffectSpine = util_spineCreate("GhostCaptain_bg", true, true)
        self.m_effectNode:addChild(downEffectSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 9999 + iCol)
        downEffectSpine:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
        local upEffectSpine = util_spineCreate("GhostCaptain_bg", true, true)
        self.m_effectNode:addChild(upEffectSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10001 + iCol)
        upEffectSpine:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
        table.insert(allNode, downEffectSpine)
        table.insert(allNode, upEffectSpine)

        -- 隐藏当前列的bonus
        for row = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, row, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType and self.SYMBOL_BONUS then
                slotNode:setVisible(false)
                table.insert(hideBonusNode, slotNode)
            end
        end

        util_spinePlay(downEffectSpine, "actionframe_down", false)
        util_spinePlay(upEffectSpine, "actionframe_up", false)

        self:delayCallBack(1, function()
            reelsNode:findChild("Node_rootNew"):runAction(cc.Sequence:create(
                cc.EaseSineInOut:create(cc.MoveTo:create(12/30, cc.p(0, 0))),
                cc.CallFunc:create(function(  )
                    for _, _nodeSpine in ipairs(newBonus) do
                        if _nodeSpine.iCol <= (self.m_iBetLevel+1) then
                            util_spinePlay(_nodeSpine, "buling", false)
                        else
                            util_spinePlay(_nodeSpine, "idleframe3", false)
                        end
                    end
                end)
            ))

            for row = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, row, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType then
                    local symbolType = self:getMatrixPosSymbolType(row, iCol)
                    self:changeSymbolType(slotNode, symbolType)
                    if symbolType == self.SYMBOL_BONUS then
                        self:setSpecialNodeScore(slotNode)
                        if iCol <= (self.m_iBetLevel+1) then
                            slotNode:runAnim("idleframe")
                        else
                            slotNode:runAnim("idleframe3")
                        end
                    elseif slotNode.p_symbolType == self.SYMBOL_WHEEL_BONUS or slotNode.p_symbolType == self.SYMBOL_WHEELSUPER_BONUS then
                        if iCol <= (self.m_iBetLevel+1) then
                            slotNode:runAnim("idleframe")
                        else
                            slotNode:runAnim("idleframe3")
                        end
                    end
                    util_setSymbolToClipReel(self, slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, 0)
                end
            end
        end)
    end
    if isShake then
        util_shakeNode(self:findChild("root"), 5, 10, 18/30)
    end
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_free_bonus_move)
    if math.random(1, 100) <= 50 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_free_bonus_move_say)
    end

    self:delayCallBack(63/30, function()
        for _, _node in ipairs(hideBonusNode) do
            _node:setVisible(true)
        end

        for _, _node in ipairs(allNode) do
            _node:removeFromParent()
        end

        if _func then
            _func()
        end
    end)
end

--[[
    reel上的移动的bonus 显示数值
]]
function CodeGameScreenGhostCaptainMachine:showReelsBonusCoins(_symbolNode, _iRow, _iCol)
    local coinsView = util_createAnimation("Socre_GhostCaptain_BounsCoins.csb")
    util_spinePushBindNode(_symbolNode, "shuzi", coinsView)

    local score, type = self:getReSpinSymbolScore(self:getPosReelIdx(_iRow, _iCol))
    self:showBonusJackpotOrCoins(coinsView, score, type)
end

function CodeGameScreenGhostCaptainMachine:playEffectNotifyNextSpinCall( )
    if self.m_freeDuanXian and self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:delayCallBack(1, function()
            CodeGameScreenGhostCaptainMachine.super.playEffectNotifyNextSpinCall(self)

            self:checkTriggerOrInSpecialGame(function(  )
                self:reelsDownDelaySetMusicBGVolume( ) 
            end)
        end)
        return
    end
    CodeGameScreenGhostCaptainMachine.super.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

function CodeGameScreenGhostCaptainMachine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
    else
        if not self.m_autoChooseRepin and globalData.slotRunData.m_isAutoSpinAction and self:getCurrSpinMode() == NORMAL_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Auto, true})
            globalData.slotRunData.currSpinMode = AUTO_SPIN_MODE
            if self.m_handerIdAutoSpin == nil then
                self.m_handerIdAutoSpin =
                    scheduler.performWithDelayGlobal(
                    function(delay)
                        self:normalSpinBtnCall()
                    end,
                    0.5,
                    self:getModuleName()
                )
            end
        else
            if self.m_freeDuanXian and self:getCurrSpinMode() == FREE_SPIN_MODE then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            else
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
        end
    end
end

function CodeGameScreenGhostCaptainMachine:showEffect_LineFrame(effectData)
    if globalData.GameConfig:checkNormalReel() == false then
        self.m_showLineFrameTime = xcyy.SlotsUtil:getMilliSeconds()
    end

    self:showLineFrame()

    local delayTime = 0
    if self:checkHasSelfGameEffectType(self.COLLECT_BONUS_COINS) or self:checkHasSelfGameEffectType(self.FREE_BONUS_MOVE) then
        delayTime = 1
    end
    local time = self:getShowLineWaitTime()
    if time then
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            0.5+delayTime
        )
    else
        performWithDelay(
            self,
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            delayTime
        )
    end

    return true
end

---
--检测m_gameEffects播放effect表中是否有该类型
function CodeGameScreenGhostCaptainMachine:checkHasSelfGameEffectType(effectType)
    if self.m_gameEffects == nil then
        return false
    end
    local effectLen = #self.m_gameEffects
    if effectLen == 0 then
        return false
    end

    for i = 1, effectLen, 1 do
        local value = self.m_gameEffects[i].p_selfEffectType
        if value == effectType then
            return true
        end
    end

    return false
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenGhostCaptainMachine:checkSymbolBulingSoundPlay(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            -- self:checkSymbolTypePlayTipAnima(_slotNode.p_symbolType) 关卡使用新增的落地配置时，这个接口会重写屏蔽掉原有的落地逻辑，还是把判断逻辑拿出来直接用吧
            if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                -- 使用了 scatter 和 bonus 的快滚检测判断。有特殊需求 可以重写跳过这层判断
                if self:isPlayTipAnima(_slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode) == true then
                    return true
                end
            else
                -- 不为 scatter 和 bonus 时 不走快滚判断
                if _slotNode.p_symbolType == self.SYMBOL_BONUS or _slotNode.p_symbolType == self.SYMBOL_WHEEL_BONUS or _slotNode.p_symbolType == self.SYMBOL_WHEELSUPER_BONUS then
                    if _slotNode.p_cloumnIndex <= (self.m_iBetLevel+1) then
                        return true
                    else
                        return false
                    end
                end
                return true
            end
        end
    end

    return false
end

---
--设置bonus scatter 层级
function CodeGameScreenGhostCaptainMachine:getBounsScatterDataZorder(symbolType )
    local order = CodeGameScreenGhostCaptainMachine.super.getBounsScatterDataZorder(self, symbolType)
    if symbolType == self.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_WHEEL_BONUS or symbolType == self.SYMBOL_WHEELSUPER_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100
    end
    return order
end

-- free和freeMore特殊需求
function CodeGameScreenGhostCaptainMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_freeMore_scatter_trigger)
        else
            gLobalSoundManager:playSound(self.m_ScatterTipMusicPath)
            -- globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenGhostCaptainMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenGhostCaptainMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenGhostCaptainMachine:checkRemoveBigMegaEffect()
    CodeGameScreenGhostCaptainMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenGhostCaptainMachine:getShowLineWaitTime()
    local time = CodeGameScreenGhostCaptainMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    return time
end

----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenGhostCaptainMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("GhostCaptainSrc.GhostCaptainFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self.m_effectNode:addChild(self.m_baseFreeSpinBar, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 20000)
    self.m_baseFreeSpinBar:setPosition(util_convertToNodeSpace(self:findChild("Node_free_bar"), self.m_effectNode))
end

function CodeGameScreenGhostCaptainMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
        
        if func then
            func()
        end
    end

    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

function CodeGameScreenGhostCaptainMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("GhostCaptainSounds/music_GhostCaptain_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_freeMoreView)
            local view = self:showFreeSpinMore( self.m_runSpinResultData.p_freeSpinNewCount,function()
                self.m_baseFreeSpinBar:playAddNumsEffect(function()
                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                end)
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)
            local guangNode = util_createAnimation("Socre_GhostCaptain_tb_guang.csb")
            view:findChild("Node_guang"):addChild(guangNode)
            guangNode:runCsbAction("idleframe", true)

            local saoguangSpine = util_spineCreate("GhostCaptain_tb_sg",true,true)
            view:findChild("Node_zi_sg"):addChild(saoguangSpine)
            util_spinePlay(saoguangSpine, "idle3", true)
            view:findChild("root"):setScale(self.m_machineRootScale)
        else
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:playFreeGuoChangEffect(function()
                    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
                    self.m_baseFreeSpinBar:setVisible(true)
                    self:setReelBg(2)
                    self:setReelsTouch(false)
                    if self.m_wheelToFree then
                        self:setLastWinCoin(0)
                        --清空赢钱
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
                    end
                end, function()
                    self.m_controlBetView:playDarkEffect()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()  
                end)
            end)
            self:createFreeSpinStartView(view)
            view:findChild("root"):setScale(self.m_machineRootScale)

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_freeStartView_start)
            view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_GhostCaptain_click
            
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

--[[
    freestart 界面相关
]]
function CodeGameScreenGhostCaptainMachine:createFreeSpinStartView(_view)
    local viewBgSpine = util_spineCreate("GhostCaptain_tb_7",true,true)
    _view:findChild("Node_spine"):addChild(viewBgSpine)
    util_spinePlay(viewBgSpine, "7_start", false)
    
    _view:setBtnClickFunc(function(  )
        util_spinePlay(viewBgSpine, "7_over", false)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_freeStartView_over)
    end)

    -- 光
    local guangNode = util_createAnimation("Socre_GhostCaptain_tb_guang2.csb")
    _view:findChild("Node_guang"):addChild(guangNode)
    util_setCascadeOpacityEnabledRescursion(_view:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(_view:findChild("Node_guang"), true)

    -- 按钮扫光
    local btnGuangSpine = util_spineCreate("GhostCaptain_tb_sg",true,true)
    _view:findChild("Node_sg"):addChild(btnGuangSpine)

    util_spineEndCallFunc(viewBgSpine, "7_start", function ()
        util_spinePlay(viewBgSpine, "7_idle", true)
        guangNode:runCsbAction("idleframe", true)
        util_spinePlay(btnGuangSpine, "idle2", true)
    end)
end

function CodeGameScreenGhostCaptainMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = {}
    if coins == "0" then
        return self:showDialog("NoWin", ownerlist, func)
    else
        ownerlist["m_lb_num"] = num
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    end
end

function CodeGameScreenGhostCaptainMachine:showFreeSpinOverView(effectData)
    -- gLobalSoundManager:playSound("GhostCaptainSounds/music_GhostCaptain_over_fs.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view = self:showFreeSpinOver(
        strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:playFreeOverGuoChangEffect(function()
                self.m_baseFreeSpinBar:setVisible(false)
                self:setReelBg(1)
                self.m_wheelToFree = false
                self:setReelsClickEnter()
            end, function()
                self.m_controlBetView:playUnDarkEffect()
                self:triggerFreeSpinOverCallFun()
            end)
        end
    )
    if strCoins ~= "0" then
        self:createFreeSpinOverView(view, strCoins)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_freeOverView_start)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_GhostCaptain_click
    else
        self:createFreeSpinOverNoWinView(view)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_nowin_start)
        view.m_btnTouchSound = self.m_publicConfig.SoundConfig.sound_GhostCaptain_click
    end
    view:findChild("root"):setScale(self.m_machineRootScale)
    
end

--[[
    freeover 界面相关
]]
function CodeGameScreenGhostCaptainMachine:createFreeSpinOverView(_view, _strCoins)
    local viewBgSpine = util_spineCreate("GhostCaptain_tb_6",true,true)
    _view:findChild("Node_spine"):addChild(viewBgSpine)
    util_spinePlay(viewBgSpine, "6_start", false)

    _view:setBtnClickFunc(function(  )
        util_spinePlay(viewBgSpine, "6_over", false)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_freeOverView_over)
    end)

    -- 赢钱
    local coinsNode = util_createAnimation("Socre_FreeSpinOver_shuzi.csb")
    util_spinePushBindNode(viewBgSpine, "shuzi", coinsNode)
    local node = coinsNode:findChild("m_lb_coins")
    node:setString(_strCoins)
    self:updateLabelSize({label=node,sx=0.85,sy=0.85},764)  

    -- 按钮扫光
    local btnGuangSpine = util_spineCreate("GhostCaptain_tb_sg",true,true)
    _view:findChild("Node_sg"):addChild(btnGuangSpine)
    util_spinePlay(btnGuangSpine, "idle2", true)

    -- 背景烟雾
    local yanwuSpine = util_spineCreate("GhostCaptain_tb_6_yan",true,true)
    _view:findChild("Node_yan"):addChild(yanwuSpine)
    util_spinePlay(yanwuSpine, "6_yan_idle", true)
    util_setCascadeOpacityEnabledRescursion(_view:findChild("Node_yan"), true)
    util_setCascadeColorEnabledRescursion(_view:findChild("Node_yan"), true)

    util_spineEndCallFunc(viewBgSpine, "6_start", function ()
        util_spinePlay(viewBgSpine, "6_idle", true)
    end)
end

--[[
    freeover 不赢钱 界面相关
]]
function CodeGameScreenGhostCaptainMachine:createFreeSpinOverNoWinView(_view)
    local viewBgSpine = util_spineCreate("GhostCaptain_tb_1",true,true)
    _view:findChild("Node_spine"):addChild(viewBgSpine)
    util_spinePlay(viewBgSpine, "1_start", false)

    _view:setBtnClickFunc(function(  )
        util_spinePlay(viewBgSpine, "1_over", false)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_nowin_over)
    end)

    -- 按钮扫光
    local btnGuangSpine = util_spineCreate("GhostCaptain_tb_sg",true,true)
    _view:findChild("Node_sg"):addChild(btnGuangSpine)
    util_spinePlay(btnGuangSpine, "idle1", true)

    util_spineEndCallFunc(viewBgSpine, "1_start", function ()
        util_spinePlay(viewBgSpine, "1_idle", true)
    end)
end

function CodeGameScreenGhostCaptainMachine:showEffect_FreeSpin(effectData)
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
    if scatterLineValue ~= nil then
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
        local frameNum = scatterLineValue.iLineSymbolNum
        for i=1, frameNum do
            local symPosData = scatterLineValue.vecValidMatrixSymPos[i]
            local slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
            if slotNode then
                local parent = slotNode:getParent()
                if parent ~= self.m_clipParent then
                    slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, scatterLineValue.enumSymbolType, 0)
                end
                slotNode.m_oldZOrder = slotNode:getZOrder()
                slotNode:setZOrder(slotNode.m_oldZOrder + 10000 + symPosData.iY)
                local curAnimName = slotNode.m_currAnimName
                
                slotNode:runAnim("actionframe", false, function()
                    slotNode:setZOrder(slotNode.m_oldZOrder)
                end)
                local duration = slotNode:getAniamDurationByName("actionframe")
                waitTime = util_max(waitTime,duration)
            end
        end
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
    else
        waitTime = 0.5
    end
    performWithDelay(self,function(  )
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true    
end

function CodeGameScreenGhostCaptainMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("GhostCaptainSrc.GhostCaptainJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_base_jackpotbar"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
    显示jackpotWin
]]
function CodeGameScreenGhostCaptainMachine:showJackpotView(coins,jackpotType,wheelType,func)
    local view = util_createView("GhostCaptainSrc.GhostCaptainJackpotWinView",{
        jackpotType = jackpotType,
        winCoin = coins,
        wheelType = wheelType,
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

--[[
    bonus 转盘图标触发动画
]]
function CodeGameScreenGhostCaptainMachine:showBonusTrigger(_func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_wheelBonus_trigger)

    for col = 1, self.m_iBetLevel+1 do
        for row = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(col, row, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType then
                if slotNode.p_symbolType == self.SYMBOL_WHEEL_BONUS or slotNode.p_symbolType == self.SYMBOL_WHEELSUPER_BONUS then
                    slotNode.m_oldZOrder = slotNode:getZOrder()
                    slotNode:setZOrder(slotNode.m_oldZOrder + 10000 + col)
                    slotNode:runAnim("actionframe", false, function()
                        slotNode:setZOrder(slotNode.m_oldZOrder)
                        slotNode:runAnim("idleframe2", true)
                    end)
                elseif slotNode.p_symbolType == self.SYMBOL_BONUS or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    util_setClipReelSymbolToBaseParent(self, slotNode)
                end
            end
        end
    end

    self.m_reelsDarkNode:setVisible(true)
    self.m_reelsDarkNode:runCsbAction("start", false, function()
        self.m_reelsDarkNode:runCsbAction("idle", true)
    end)

    self:delayCallBack(2, function()
        if _func then
            _func()
        end
    end)
end

function CodeGameScreenGhostCaptainMachine:showBonusGameView(_effectData)
    self:stopLinesWinSound()
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    if self.m_isReconnectBonusGame then
        self:createWheelGameView(_effectData)
    else
        self:showBonusTrigger(function()
            self.m_isReconnectBonusGame = false
            self:createWheelGameView(_effectData)
        end)
    end
end

function CodeGameScreenGhostCaptainMachine:createWheelGameView(_effectData)
    self.m_bonusWheel:setVisible(true)
    self:findChild("Node_bonusGame"):setVisible(true)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_qipan_move)
    self:runCsbAction("actionframe_guochang1", false, function()
        self:findChild("allz"):setVisible(false)
    end)
    self:delayCallBack(80/60, function()
        self.m_reelsDarkNode:setVisible(false)
        -- 隐藏下条目
        self.m_bottomUI:setVisible(false)

        self.m_bonusWheel:updateWheelSymbol()
        self.m_guochangBonusEffect1:setVisible(true)
        self.m_guochangBonusEffect2:setVisible(true)
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_zhanpan_start)

        util_spinePlay(self.m_guochangBonusEffect1, "actionframe_guochang1_up", false)
        util_spinePlay(self.m_guochangBonusEffect2, "actionframe_guochang1_down", false)
        self:delayCallBack(37/30, function()
            self.m_bonusBgSpine:setVisible(true)
            util_spinePlay(self.m_bonusBgSpine, "actionframe_guochang1", false)
            util_spineEndCallFunc(self.m_bonusBgSpine, "actionframe_guochang1", function ()
                self.m_bonusBgSpine:setVisible(false)
            end)
        end)

        self:delayCallBack(40/30, function()
            self.m_bonusDarkNode:setVisible(true)
            self.m_bonusDarkNode:runCsbAction("actionframe", false, function()
                self.m_bonusDarkNode:setVisible(false)
            end)
            self:delayCallBack(10/60, function()
                self.m_runSpinResultData.p_features = {0}
                self:resetMusicBg(nil,"GhostCaptainSounds/music_GhostCaptain_wheel.mp3")
                self.m_bonusWheel:wheelStart()
            end)
        end)

        self:delayCallBack(78/30, function()
            self.m_bonusWheel:beginWheel()
        end)
    end)
    
    local callback = function (_func)
        self:delayCallBack(0.5, function()
            self:playBonusOverGuoChangEffect(function()
                self.m_guochangBonusEffect1:setVisible(false)
                self.m_guochangBonusEffect2:setVisible(false)
                self.m_bonusWheel:setVisible(false)
                self:findChild("Node_bonusGame"):setVisible(false)
                self.m_bonusWheel.m_winCoinsKuangNode:setVisible(false)
                self.m_bonusWheel.m_wheelNumsKuangNode:setVisible(false)
                self.m_bonusWheel.m_wheelSuperNumsKuangNode:setVisible(false)
                self.m_bonusWheel.m_spinAgainNode:setVisible(false)
                self:findChild("allz"):setVisible(true)
                self:runCsbAction("idleframe", false)

                -- 显示下条目
                self.m_bottomUI:setVisible(true)
            end, function()
                if _func then
                    _func()
                end
                _effectData.p_isPlay = true
                self:playGameEffect()
                self:resetMusicBg()
                self:checkTriggerOrInSpecialGame(function(  )
                    self:reelsDownDelaySetMusicBGVolume( ) 
                end)
            end)
        end)
    end
    self.m_bonusWheel:initCallBack(callback)    
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenGhostCaptainMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                --2.播落地动画
                _slotNode:runAnim(
                    symbolCfg[2],
                    false,
                    function()
                        self:symbolBulingEndCallBack(_slotNode)
                    end
                )
            else
                if not self.m_bProduceSlots_InFreeSpin then
                    self:playBonusEffectByStopReels(_slotNode)
                else
                    local isPlayEffect = true
                    for _, _data in ipairs(self.m_bonusMoveInfo) do
                        if _data.col == _slotNode.p_cloumnIndex then
                            isPlayEffect = false
                        end
                    end
                    if isPlayEffect then
                        self:playBonusEffectByStopReels(_slotNode)
                    end
                end
            end
        end
    end
end

function CodeGameScreenGhostCaptainMachine:getIsHaveSymbol()
    local reels = self.m_runSpinResultData.p_reels
    local isHaveCallBack = function(_symbolType)
        for row = 1, 3 do
            for col = 1, 5 do
                if reels[row] and reels[row][col] and reels[row][col] == _symbolType then
                    return true
                end
            end
        end
        return false
    end
    
    local isHaveScatter = isHaveCallBack(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    local isHaveWheel1 = isHaveCallBack(self.SYMBOL_WHEEL_BONUS)
    local isHaveWheel2 = isHaveCallBack(self.SYMBOL_WHEELSUPER_BONUS)
    local isHaveBonus = isHaveCallBack(self.SYMBOL_BONUS)
    if isHaveScatter then
        return 1
    else
        if isHaveWheel1 or isHaveWheel2 then
            return 2
        else
            return 3
        end
    end
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenGhostCaptainMachine:playSymbolBulingSound(slotNodeList)
    local playSoundId = self:getIsHaveSymbol()
    
    local features = self.m_runSpinResultData.p_features or {}
    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode) then
            local symbolType = _slotNode.p_symbolType
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                self.m_scatterNums = self.m_scatterNums + 1
                if self:getGameSpinStage() == QUICK_RUN then
                    if self.m_isPlayScatterQuick and playSoundId == 1 then
                        self.m_isPlayScatterQuick = false
                        if #features > 1 and features[2] == 1 then
                            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_scatter_buling3)
                        else
                            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_scatter_buling1)
                        end
                    end
                else
                    if self.m_scatterNums >= 3 then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_scatter_buling3)
                    else
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig["sound_GhostCaptain_scatter_buling"..self.m_scatterNums])
                    end
                end
            elseif symbolType == self.SYMBOL_BONUS then
                if self:getGameSpinStage() == QUICK_RUN then
                    if self.m_isPlayBonusQuick and playSoundId == 3 then
                        self.m_isPlayBonusQuick = false
                        if _slotNode.p_cloumnIndex <= (self.m_iBetLevel+1) then
                            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_bonus_buling)
                        end
                    end
                else
                    if _slotNode.p_cloumnIndex <= (self.m_iBetLevel+1) and self.m_isPlayBonusBulingCol[_slotNode.p_cloumnIndex] then
                        self.m_isPlayBonusBulingCol[_slotNode.p_cloumnIndex] = false
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_bonus_buling)
                    end
                end
            elseif symbolType == self.SYMBOL_WHEEL_BONUS or symbolType == self.SYMBOL_WHEELSUPER_BONUS then
                if self:getGameSpinStage() == QUICK_RUN and self.m_isPlayWheelBonusQuick and playSoundId == 2 then
                    self.m_isPlayWheelBonusQuick = false
                    if _slotNode.p_cloumnIndex <= (self.m_iBetLevel+1) then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_bonus_buling)
                    end
                else
                    if _slotNode.p_cloumnIndex <= (self.m_iBetLevel+1) and self.m_isPlayWheelBonusBulingCol[_slotNode.p_cloumnIndex] then
                        self.m_isPlayWheelBonusBulingCol[_slotNode.p_cloumnIndex] = false
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_bonus_buling)
                    end
                end
            end
        end
    end
end

--[[
    bonus落地之后 的动画
]]
function CodeGameScreenGhostCaptainMachine:playBonusEffectByStopReels(_slotNode)
    if _slotNode.p_symbolType == self.SYMBOL_BONUS or _slotNode.p_symbolType == self.SYMBOL_WHEEL_BONUS or _slotNode.p_symbolType == self.SYMBOL_WHEELSUPER_BONUS then
        if _slotNode.p_cloumnIndex <= (self.m_iBetLevel+1) then
            _slotNode:runAnim("idleframe2", true)
        else
            if _slotNode.p_symbolType == self.SYMBOL_BONUS then
                _slotNode:runAnim("idleframe3", false, function()
                    _slotNode:runAnim("darkidle", true)
                end)
            else
                _slotNode:runAnim("idleframe3", false)
            end
        end
    end
end

function CodeGameScreenGhostCaptainMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode) 

    self:playBonusEffectByStopReels(_slotNode)

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

function CodeGameScreenGhostCaptainMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息
    table.insert(longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态    
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenGhostCaptainMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenGhostCaptainMachine.super.MachineRule_ResetReelRunData(self)    
end

--[[
    是否播放期待动画
]]
function CodeGameScreenGhostCaptainMachine:isPlayExpect(reelCol)
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
function CodeGameScreenGhostCaptainMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance(40) then

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
function CodeGameScreenGhostCaptainMachine:playFeatureNoticeAni(func)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_yugao)
    self.b_gameTipFlag = true
    self.m_yugaoSpineEffect1:setVisible(true)
    self.m_yugaoSpineEffect2:setVisible(true)
    self.m_yugaoSpineEffect3:setVisible(true)
    self.m_yugaoSpineEffect4:setVisible(true)
    util_spinePlay(self.m_yugaoSpineEffect1,"actionframe_yugao",false)
    util_spinePlay(self.m_yugaoSpineEffect2,"actionframe_yugao",false)
    util_spinePlay(self.m_yugaoSpineEffect3,"actionframe_yugao",false)
    util_spinePlay(self.m_yugaoSpineEffect4,"actionframe_yugao",false)
    util_spineEndCallFunc(self.m_yugaoSpineEffect1, "actionframe_yugao" ,function ()
        self.m_yugaoSpineEffect1:setVisible(false)
        self.m_yugaoSpineEffect2:setVisible(false)
        self.m_yugaoSpineEffect3:setVisible(false)
        self.m_yugaoSpineEffect4:setVisible(false)
    end) 

    --动效执行时间
    local aniTime = 115/30
    --计算延时,预告中奖播完时需要刚好停轮
    local delayTime = self:getRunTimeBeforeReelDown(5)

    self:delayCallBack(aniTime - delayTime,function()
        if type(func) == "function" then
            func()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        end
    end)
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenGhostCaptainMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 10
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

--[[
    显示大赢光效事件
]]
function CodeGameScreenGhostCaptainMachine:showEffect_runBigWinLightAni(effectData)
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
    else
        self.m_bottomUI.m_bigWinLabCsb:setScale(1)
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
function CodeGameScreenGhostCaptainMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local aniTime = 2
    util_shakeNode(rootNode,5,10,aniTime)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_bigWin_yugao)

    self.m_bigWinEffect1:setVisible(true)
    self.m_bigWinEffect2:setVisible(true)
    util_spinePlay(self.m_bigWinEffect1, "actionframe_bigwin")
    util_spinePlay(self.m_bigWinEffect2, "actionframe_bigwin")
    util_spineEndCallFunc(self.m_bigWinEffect1, "actionframe_bigwin", function()
        self.m_bigWinEffect1:setVisible(false)
        self.m_bigWinEffect2:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenGhostCaptainMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if symbolType == self.SYMBOL_BONUS then
        self:setSpecialNodeScore(node)
    end    
end

--[[
    给bonus小块进行赋值
]]
function CodeGameScreenGhostCaptainMachine:setSpecialNodeScore(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    
    if symbolNode.p_symbolType == self.SYMBOL_BONUS then
        -- 展示
        local symbol_node = symbolNode:checkLoadCCbNode()
        local spineNode = symbol_node:getCsbAct()
        local coinsView
        if not spineNode.m_coinsNode then
            coinsView = util_createAnimation("Socre_GhostCaptain_BounsCoins.csb")
            util_spinePushBindNode(spineNode,"shuzi",coinsView)
            spineNode.m_coinsNode = coinsView
        else
            spineNode.m_coinsNode:setVisible(true)
            coinsView = spineNode.m_coinsNode
        end

        local score = 0
        local type = nil
        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            score, type = self:getReSpinSymbolScore(self:getPosReelIdx(iRow,iCol))
        else
            score, type = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
        end
        self:showBonusJackpotOrCoins(coinsView, score, type)
    end
end

--[[
    根据网络数据获得Bonus小块的分数
]]
function CodeGameScreenGhostCaptainMachine:getReSpinSymbolScore(_pos)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local coinBonusStr = self.m_runSpinResultData.p_selfMakeData.coinBonusStr or {}
    local coinBonus = self.m_runSpinResultData.p_selfMakeData.coinBonus or {}
    local scores = nil
    local type = "bonus"
    for pos, _type in pairs(coinBonusStr) do
        if tonumber(pos) == _pos then
            if _type == "grand" or _type == "major" or _type == "minor" or _type == "mini" then
                type = _type
            end
        end
    end

    for pos, _score in pairs(coinBonus) do
        if tonumber(pos) == _pos then
            scores = _score
        end
    end

    return scores, type
end

function CodeGameScreenGhostCaptainMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    local type = nil
    if symbolType == self.SYMBOL_BONUS then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
        if score == "Mini" then
            score = 0
            type = "mini"
        elseif score == "Minor" then
            score = 0
            type = "minor"
        elseif score == "Major" then
            score = 0
            type = "major"
        elseif score == "Grand" then
            score = 0
            type = "grand"
        else
            score = score * globalData.slotRunData:getCurTotalBet()
            type = "bonus"
        end
    end
    return score,type
end

--[[
    显示bonus上的信息
]]
function CodeGameScreenGhostCaptainMachine:showBonusJackpotOrCoins(coinsView, score, type)
    if coinsView then
        coinsView:findChild("m_lb_coins"):setVisible(false)
        coinsView:findChild("Node_jackpot"):setVisible(false)
        if type == "bonus" then
            coinsView:findChild("m_lb_coins"):setVisible(true)
            local labCoins = coinsView:findChild("m_lb_coins")
            labCoins:setString(util_formatCoins(score, 3, false, true, true))
            self:updateLabelSize({label = labCoins,sx = 0.9,sy = 0.95}, 157)
        else  
            coinsView:findChild("Node_jackpot"):setVisible(true)
            coinsView:findChild("grand"):setVisible(type == "grand")
            coinsView:findChild("major"):setVisible(type == "major")
            coinsView:findChild("minor"):setVisible(type == "minor")
            coinsView:findChild("mini"):setVisible(type == "mini")
        end
    end
end

------------------ 高低bet相关 -----------------------------

function CodeGameScreenGhostCaptainMachine:getBetLevelCoins(index)
    local betMulti = 1
    if self.m_specialBetMulti and #self.m_specialBetMulti > 0 then
        betMulti = self.m_specialBetMulti[index]
    end
    local betIndex = globalData.slotRunData:getCurBetIndex()
    local totalBetValue = globalData.slotRunData:getCurBetValueByIndex(betIndex)
    local betValue = totalBetValue * betMulti
    return betValue
end

function CodeGameScreenGhostCaptainMachine:getCurBetLevelMulti()
    local betMulti = 1
    if self.m_specialBetMulti then
        betMulti = self.m_specialBetMulti[self.m_iBetLevel + 1]
    end
    return betMulti or 1
end

--[[
    切换bet
]]
function CodeGameScreenGhostCaptainMachine:upateBetLevel()
    self.m_controlBetView:updateCoins(self.m_iBetLevel)
end

function CodeGameScreenGhostCaptainMachine:chooseBetLevel(_index)
    --是否 选择了不同的 bet
    if _index - 1 ~= self.m_iBetLevel then
        self.m_oldBetLevel = clone(self.m_iBetLevel)
        --修改 betCotrolvIew
        self.m_iBetLevel = _index - 1
        self:changeBetAndBetBtn()

        --显示框
        self:showChooseBoardFrame()
    else
        self:setSpinTounchType(true)
    end
end

--[[
    修改bet值 和 按钮显示
]]
function CodeGameScreenGhostCaptainMachine:changeBetAndBetBtn( )
    local curTotalBet = globalData.slotRunData:getCurTotalBet()
    local curBetMulti = self:getCurBetLevelMulti()
    globalData.slotRunData.m_curBetMultiply = curBetMulti

    local betId = globalData.slotRunData.iLastBetIdx
    self.m_bottomUI:changeBetCoinNum(betId, curTotalBet)

    self.m_controlBetView:updateColItem(self.m_iBetLevel)
    self.m_controlBetView:updateCoins(self.m_iBetLevel)
end

--[[
    选择不同bet 棋盘上的动画
]]
function CodeGameScreenGhostCaptainMachine:showChooseBoardFrame()
    self:setSpinTounchType(false)
    self:setReelsTouch(false)
    local isFirst = true
    for index = 1, self.m_iBetLevel+1 do
        self.m_langEffectNodeList[index]:setVisible(true)
        self.m_langEffectNodeList[index]:runCsbAction("actionframe", false, function()
            self.m_langEffectNodeList[index]:setVisible(false)
            if isFirst then
                isFirst = false
                self:setSpinTounchType(true)
                self:setReelsClickEnter()
            end
        end)
    end

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_lang_reels_start)
    if self.m_iBetLevel+1 == 5 then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_betChange_five)
    end

    self:delayCallBack(25/60, function()
        self:changeKuangEffect()
    end)
end

--[[
    改变棋盘框
]]
function CodeGameScreenGhostCaptainMachine:changeKuangEffect(_isEnter)
    if _isEnter then
        self.m_kuangOldNode:setVisible(false)
        self.m_kuangOldNode1:setVisible(false)
        for index = 1, 5 do
            self.m_kuangNewNode:findChild("Node_"..index):setVisible(index == (self.m_iBetLevel+1))
            self.m_kuangNewNode1:findChild("Node_"..index):setVisible(index == (self.m_iBetLevel+1))
        end
        self.m_kuangNewNode:runCsbAction("idle", false)
        self.m_kuangNewNode1:runCsbAction("idle", false)
    else
        self.m_kuangOldNode:setVisible(true)
        self.m_kuangOldNode1:setVisible(true)
        for index = 1, 5 do
            self.m_kuangOldNode:findChild("Node_"..index):setVisible(index == (self.m_oldBetLevel+1))
            self.m_kuangOldNode1:findChild("Node_"..index):setVisible(index == (self.m_oldBetLevel+1))
        end
        self.m_kuangOldNode:runCsbAction("over", false, function()
            self.m_kuangOldNode:setVisible(false)
        end)
        self.m_kuangOldNode1:runCsbAction("over", false, function()
            self.m_kuangOldNode1:setVisible(false)
        end)
        for index = 1, 5 do
            self.m_kuangNewNode:findChild("Node_"..index):setVisible(index == (self.m_iBetLevel+1))
            self.m_kuangNewNode1:findChild("Node_"..index):setVisible(index == (self.m_iBetLevel+1))
        end
        self.m_kuangNewNode:runCsbAction("idle", false)
        self.m_kuangNewNode1:runCsbAction("idle", false)
    end
end

function CodeGameScreenGhostCaptainMachine:setSpinTounchType(_isTouch)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, _isTouch})
end

------------------ 高低bet相关end -----------------------------
---

--[[
    过场动画
]]

function CodeGameScreenGhostCaptainMachine:playFreeGuoChangEffect(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_guoChang_baseToFree)

    self.m_guochangFreeEffect:setVisible(true)
    util_spinePlay(self.m_guochangFreeEffect, "actionframe_guochang2", false)

    -- 切换 30帧
    self:delayCallBack(30/30, function()
        if _func1 then
            _func1()
        end
    end)

    -- 结束 80帧
    self:delayCallBack(80/30, function()
        if _func2 then
            _func2()
        end
        self.m_guochangFreeEffect:setVisible(false)
    end)
end

--[[
    过场动画
]]

function CodeGameScreenGhostCaptainMachine:playFreeOverGuoChangEffect(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_guochang_freeToBase)
    self.m_guochangFreeOverEffect:setVisible(true)
    util_spinePlay(self.m_guochangFreeOverEffect, "actionframe_guochang3", false)

    -- 切换 27帧
    self:delayCallBack(27/30, function()
        if _func1 then
            _func1()
        end
    end)

    -- 结束 80帧
    self:delayCallBack(100/30, function()
        if _func2 then
            _func2()
        end
        self.m_guochangFreeOverEffect:setVisible(false)
    end)
end

function CodeGameScreenGhostCaptainMachine:playBonusOverGuoChangEffect(_func1, _func2)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_GhostCaptain_wheel_guochang)

    self.m_bonusOverGuoChangSpine:setVisible(true)
    util_spinePlay(self.m_bonusOverGuoChangSpine, "actionframe_guochang3", false)
    -- 27帧切换
    self:delayCallBack(27/30, function()
        if _func1 then
            _func1()
        end
    end)

    -- 100帧结束
    self:delayCallBack(100/30, function()
        if _func2 then
            _func2()
        end
        self.m_bonusOverGuoChangSpine:setVisible(false)
    end)
end

function CodeGameScreenGhostCaptainMachine:checkHasFeature()
    local hasfeature = CodeGameScreenGhostCaptainMachine.super.checkHasFeature(self)
    if hasfeature then
        self.m_hasfeature = true
    end
    return hasfeature
end

function CodeGameScreenGhostCaptainMachine:initFeatureInfo(_spinData,_featureData)
    if _featureData.p_status == "CLOSED" then
        self:playGameEffect()
        return
    else
        self.m_hasfeature = true
        self.m_isReconnectBonusGame = true
        local bonusExtra = _featureData.p_bonus.extra
        self.m_runSpinResultData.p_bonusExtra = bonusExtra
        local bonusGameEffect = GameEffectData.new()
        bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
        bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
        self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
        local triggerCoins = _spinData.p_winAmount or 0
        if triggerCoins and triggerCoins ~= 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{triggerCoins,false,false})
        end
    end
end

function CodeGameScreenGhostCaptainMachine:beginReel()
    CodeGameScreenGhostCaptainMachine.super.beginReel(self)
    self.m_freeDuanXian = false 
    self.m_isReconnectBonusGame = false
    self.m_scatterNums = 0
    self.m_isPlayScatterQuick = true
    self.m_isPlayBonusQuick = true
    self.m_isPlayBonusBulingCol = {true, true, true, true, true}
    self.m_isPlayWheelBonusQuick = true
    self.m_isPlayWheelBonusBulingCol = {true, true, true, true, true}
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发

    断线重连的时候 重新判断是否进入free玩法 bonus玩法没结束的时候 不进free玩法
]]
function CodeGameScreenGhostCaptainMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

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
        if self.m_initFeatureData and self.m_initFeatureData.p_status then
            self.m_initSpinData.p_bonusStatus = self.m_initFeatureData.p_status
        end
        if self.m_initSpinData.p_bonusStatus and self.m_initSpinData.p_bonusStatus == "OPEN" and self.m_initSpinData.p_freeSpinsTotalCount == 
        self.m_initSpinData.p_freeSpinsLeftCount then
            isInFs = false
        else
            isInFs = true
        end
    end

    if isInFs == true then
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:setCurrSpinMode(FREE_SPIN_MODE)

        if self:checkTriggerFsOver() then
            local fsOverEffect = GameEffectData.new()
            fsOverEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            fsOverEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = fsOverEffect
        end

        -- 发送事件显示赢钱总数量
        local params = {self.m_runSpinResultData.p_fsWinCoins, false, false}
        params[self.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenGhostCaptainMachine:scaleMainLayer()
    CodeGameScreenGhostCaptainMachine.super.scaleMainLayer(self)
    self.m_machineNode:setPositionY(0)
end

--[[
    根据配置初始轮盘
]]
function CodeGameScreenGhostCaptainMachine:initSlotNodes()
    self.m_isInitSlotNode = true
    CodeGameScreenGhostCaptainMachine.super.initSlotNodes(self)
end

---
-- 在这里不影响groupIndex 和 rowIndex 等到结果数据来时使用
--
function CodeGameScreenGhostCaptainMachine:getReelDataWithWaitingNetWork(parentData)
    local symbolType = self:getReelSymbolType(parentData)
    if self.m_isInitSlotNode then
        self.m_isInitSlotNodeNums = self.m_isInitSlotNodeNums + 1
        if self.m_isInitSlotNodeNums > self.m_iReelColumnNum * 3 and self.m_isInitSlotNodeNums <= self.m_iReelColumnNum * 6 then
            symbolType = 94
        end
    end
    parentData.symbolType = symbolType
end

function CodeGameScreenGhostCaptainMachine:resumeMachine()
    CodeGameScreenGhostCaptainMachine.super.resumeMachine(self)
    if self.m_bonusWheel:isVisible() then
        -- 隐藏下条目
        self.m_bottomUI:setVisible(false)
    end
end

-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
function CodeGameScreenGhostCaptainMachine:initCloumnSlotNodesByNetData()
    if self.m_bProduceSlots_InFreeSpin then
        if self.m_initSpinData and self.m_initSpinData.p_selfMakeData and self.m_initSpinData.p_selfMakeData.expandReels and #self.m_initSpinData.p_selfMakeData.expandReels > 0 then
            self.m_initSpinData.p_reels = self.m_initSpinData.p_selfMakeData.expandReels
            if self.m_initSpinData.p_selfMakeData.expandCoinBonus and table.nums(self.m_initSpinData.p_selfMakeData.expandCoinBonus) > 0 then
                if self.m_initSpinData.p_selfMakeData.coinBonus then
                    self.m_initSpinData.p_selfMakeData.coinBonus = self.m_initSpinData.p_selfMakeData.expandCoinBonus
                else
                    self.m_initSpinData.p_selfMakeData.coinBonus = {}
                    self.m_initSpinData.p_selfMakeData.coinBonus = self.m_initSpinData.p_selfMakeData.expandCoinBonus
                end
            end

            if self.m_initSpinData.p_selfMakeData.expandCoinBonusStr and table.nums(self.m_initSpinData.p_selfMakeData.expandCoinBonusStr) > 0 then
                if self.m_initSpinData.p_selfMakeData.coinBonusStr then
                    self.m_initSpinData.p_selfMakeData.coinBonusStr = self.m_initSpinData.p_selfMakeData.expandCoinBonusStr
                else
                    self.m_initSpinData.p_selfMakeData.coinBonusStr = {}
                    self.m_initSpinData.p_selfMakeData.coinBonusStr = self.m_initSpinData.p_selfMakeData.expandCoinBonusStr
                end
            end
        end
    end 
    CodeGameScreenGhostCaptainMachine.super.initCloumnSlotNodesByNetData(self)
end

function CodeGameScreenGhostCaptainMachine:operaUserLevelUpInfo()
    CodeGameScreenGhostCaptainMachine.super.operaUserLevelUpInfo(self)
    self:isTriggerFreeBonusMove()
end

return CodeGameScreenGhostCaptainMachine






