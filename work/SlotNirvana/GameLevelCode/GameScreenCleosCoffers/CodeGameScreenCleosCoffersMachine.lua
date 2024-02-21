---
-- island li
-- 2019年1月26日
-- CodeGameScreenCleosCoffersMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "CleosCoffersPublicConfig"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenCleosCoffersMachine = class("CodeGameScreenCleosCoffersMachine", BaseNewReelMachine)

CodeGameScreenCleosCoffersMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenCleosCoffersMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenCleosCoffersMachine.SYMBOL_SCORE_11 = 10
CodeGameScreenCleosCoffersMachine.SYMBOL_SCORE_REWARD_BONUS = 94 --bonus1；奖励
CodeGameScreenCleosCoffersMachine.SYMBOL_SCORE_BOOST_BONUS = 95 --bonus2；boost

CodeGameScreenCleosCoffersMachine.EFFECT_JACKPOT_BONUS_PLAY = GameEffect.EFFECT_SELF_EFFECT - 4  --jackpotBonus玩法（多福多彩）
CodeGameScreenCleosCoffersMachine.EFFECT_TURN_BONUS_REWARD = GameEffect.EFFECT_SELF_EFFECT - 5  --普通bonus，先翻一遍（钱、jackpot都翻）；然后翻倍（有特殊bonus）
CodeGameScreenCleosCoffersMachine.EFFECT_TURN_DARK_BONUS_REWARD = GameEffect.EFFECT_SELF_EFFECT - 6  --free下bonus压暗显示钱
CodeGameScreenCleosCoffersMachine.EFFECT_FREE_MOVE_BONUS = GameEffect.EFFECT_SELF_EFFECT - 7  --free下移动bonus

-- 构造函数
function CodeGameScreenCleosCoffersMachine:ctor()
    CodeGameScreenCleosCoffersMachine.super.ctor(self)
    self.m_symbolExpectCtr = util_createView("CodeCleosCoffersSrc.CleosCoffersSymbolExpect", self) 

    -- 引入控制插件
    self.m_longRunControl = util_createView("CodeCleosCoffersSrc.CleosCoffersLongRunControl",self) 

    -- 大赢光效
    self.m_isAddBigWinLightEffect = true

    self.m_iBetLevel = 0 -- bet等级
    -- 当前scatter落地的个数
    self.m_curScatterBulingCount = 0
    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true
    self.m_specialBetMulti = {}

    -- 飞小块（粒子）池子
    self.m_flyNodes = {}
    -- 维护下飘钱的数据
    self.m_floatCoinsData = {}

    self.ENUM_REWARD_TYPE = 
    {
        COINS_REWARD = "normalbonus",
        JACKPOT_REWARD = "jackpotbonus",
        BUFF_REWARD = "mutibonus",
    }

    --init
    self:initGame()
    self:setAddJackptState(false, 1)
end

function CodeGameScreenCleosCoffersMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCleosCoffersMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CleosCoffers"  
end

function CodeGameScreenCleosCoffersMachine:getBottomUINode()
    return "CodeCleosCoffersBetSrc.CleosCoffersBottomNode"
end

function CodeGameScreenCleosCoffersMachine:initUI()
    --特效层
    self.m_effectNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_effectNode, 5000)
    -- self.m_effectNode:setScale(self.m_machineRootScale)

    util_csbScale(self.m_gameBg.m_csbNode, 1)

    -- 收集层光效
    self.m_flyEffectNode = self:findChild("Node_flyEffect")
    
    self:initFreeSpinBar() -- FreeSpinbar
    --多福多彩
    self.m_colorfulGameView = util_createView("CodeCleosCoffersColofulSrc.CleosCoffersColorfulGame",{machine = self})
    self:findChild("Node_colorful"):addChild(self.m_colorfulGameView)
    self.m_colorfulGameView:setVisible(false) 

    self:initJackPotBarView() 
    
    -- 点击高低bet按钮
    self.m_betBtnView = util_createView("CodeCleosCoffersBetSrc.CleosCoffersBtnBetView", {machine = self})
    self:findChild("Node_bet"):addChild(self.m_betBtnView)

    -- 高低bet界面
    self.m_chooseBetView = util_createView("CodeCleosCoffersBetSrc.CleosCoffersChooseBetView", {machine = self})
    self:addChild(self.m_chooseBetView, GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN + 2)
    self.m_chooseBetView:setVisible(false)
    self.m_chooseBetView:findChild("root"):setScale(self.m_machineRootScale)

    -- 选bet框
    self.m_kuangNodeAni = util_createAnimation("CleosCoffers_active_kuang.csb")
    self.m_clipParent:addChild(self.m_kuangNodeAni, 1000)
    self.m_kuangNodeAni:setPosition(util_convertToNodeSpace(self:findChild("Node_active_kuang"), self.m_clipParent))

    -- 选bet框上边的特效
    self.m_topColEffectView = util_createView("CodeCleosCoffersBetSrc.CleosCoffersTopColEffect",{machine = self.m_machine})
    self:findChild("Node_active_kuang"):addChild(self.m_topColEffectView)
    
    self.m_skip_click = self:findChild("Panel_skip_click")
    self.m_skip_click:setVisible(false)
    self:addClick(self.m_skip_click)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scWaitTurnNode = cc.Node:create()
    self:addChild(self.m_scWaitTurnNode)

    -- self.m_colorfulGameView:scaleMainLayer(self.m_pickRootSccale)
    self:changeBgAndReelBg(1)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenCleosCoffersMachine:initSpineUI()
    -- 预告中奖
    self.m_yuGaoSpine = util_spineCreate("CleosCoffers_guochang",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoSpine)
    self.m_yuGaoSpine:setVisible(false)

    -- pick过场
    self.m_pickCutSceneSpine = util_spineCreate("CleosCoffers_guochang",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_pickCutSceneSpine)
    self.m_pickCutSceneSpine:setVisible(false)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "CleosCoffers_totalwin")

    -- 大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("CleosCoffers_bigwin",true,true)
    self.m_bigWinSpine:setScale(self.m_machineRootScale)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 2)
    self.m_bigWinSpine:setVisible(false)
end


function CodeGameScreenCleosCoffersMachine:enterGamePlayMusic(  )
    self:delayCallBack(0.4,function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Enter_Game, 3, 0, 1)
    end)
end

function CodeGameScreenCleosCoffersMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenCleosCoffersMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenCleosCoffersMachine:initGameUI()
    if self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurFeatureIsFree() then
        if self.m_runSpinResultData.p_selfMakeData and self.m_runSpinResultData.p_selfMakeData.betLevel then
            self.m_iBetLevel = self.m_runSpinResultData.p_selfMakeData.betLevel
        end
        self:changeBgAndReelBg(2)
        self:changeBetAndBetBtn()
        self:changeKuangEffect(true)
    else
        self:setSpinTounchType(false)
        self:changeBetAndBetBtn()
        self:changeKuangEffect(true)
        self.m_chooseBetView:showView()
    end
    -- self:showFreeSpinOverView()
end

function CodeGameScreenCleosCoffersMachine:addObservers()
    CodeGameScreenCleosCoffersMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        --if self.m_bIsBigWin then return end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = self:getCurSpinStateBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate <= 3 then
            soundIndex = 2
        else
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_CleosCoffers_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_CleosCoffers_winLines" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)

    gLobalNoticManager:addObserver(self,function(self, params)
        if not params.p_isLevelUp then
            self:updateBetLevel()
        end
    end,ViewEventType.NOTIFY_BET_CHANGE)
end

function CodeGameScreenCleosCoffersMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    self.m_flyEffectNode:removeAllChildren()
    CodeGameScreenCleosCoffersMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCleosCoffersMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_CleosCoffers_10"
    elseif symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_CleosCoffers_11"
    elseif symbolType == self.SYMBOL_SCORE_REWARD_BONUS then
        return "Socre_CleosCoffers_Bonus_1"
    elseif symbolType == self.SYMBOL_SCORE_BOOST_BONUS then
        return "Socre_CleosCoffers_Bonus_2"
    end
    
    return nil
end

function CodeGameScreenCleosCoffersMachine:checkSymbolIsBonus(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_REWARD_BONUS then
        return true
    end
    return false
end

function CodeGameScreenCleosCoffersMachine:getCurSymbolIsBonus(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_REWARD_BONUS or _symbolType == self.SYMBOL_SCORE_BOOST_BONUS then
        return true
    end
    return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCleosCoffersMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenCleosCoffersMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenCleosCoffersMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end 
end

function CodeGameScreenCleosCoffersMachine:initGameStatusData(gameData)
    CodeGameScreenCleosCoffersMachine.super.initGameStatusData(self, gameData)
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.betMulti then
        self.m_specialBetMulti = gameData.gameConfig.extra.betMulti
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCleosCoffersMachine:MachineRule_SpinBtnCall()
    self.m_symbolExpectCtr:MachineSpinBtnCall() 

    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenCleosCoffersMachine:beginReel()
    self.m_collectBonus = false
    self.m_bonusDelayTime = 0
    self.m_floatCoinsData = {}
    CodeGameScreenCleosCoffersMachine.super.beginReel(self)
end

-- 多福多彩设置jackpot加成状态
function CodeGameScreenCleosCoffersMachine:setAddJackptState(_addState)
    self.m_addJackpotState = _addState
end

-- 多福多彩设置jackpot加成状态
function CodeGameScreenCleosCoffersMachine:getAddJackptState()
    return self.m_addJackpotState
end

function CodeGameScreenCleosCoffersMachine:pushAnimNodeToPool(animNode, symbolType)
    if self:checkSymbolIsBonus(symbolType) then
        --bonus1图标不放到池子中,每次都创建，重复播放有问题（目前没查到）
        animNode:clear()
        animNode:removeAllChildren() -- 必须加上这个，否则ccb的节点无法卸载，因为未加入到显示列表
        animNode:release()
        return
    end
    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}

        self.m_reelAnimNodePool[symbolType] = reelPool
    end
    animNode:setScale(1)
    reelPool[#reelPool + 1] = animNode
end

--默认按钮监听回调
function CodeGameScreenCleosCoffersMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_skip_click" then
        self:runSkipCollect()
    end
end

function CodeGameScreenCleosCoffersMachine:getWinCoinTime()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local lastLineWinCoins = self:getClientWinCoins()
    local winRate = lastLineWinCoins / totalBet
    -- local winRate = self.m_iOnceSpinLastWin / totalBet
    local showTime = 0
    if lastLineWinCoins > 0 then
        if winRate <= 1 then
            showTime = 1
        elseif winRate > 1 and winRate <= 3 then
            showTime = 1.5
        elseif winRate > 3 and winRate <= 6 then
            showTime = 2.5
        elseif winRate > 6 then
            showTime = 3
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) or self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            showTime = 1
        end
    end

    return showTime
end

--
--单列滚动停止回调
--
function CodeGameScreenCleosCoffersMachine:slotOneReelDown(reelCol)    
    CodeGameScreenCleosCoffersMachine.super.slotOneReelDown(self,reelCol)
    self.m_symbolExpectCtr:MachineOneReelDownCall(reelCol)
end

--[[
    滚轮停止
]]
function CodeGameScreenCleosCoffersMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
    CodeGameScreenCleosCoffersMachine.super.slotReelDown(self)
    self.m_curScatterBulingCount = 0
end

---------------------------------------------------------------------------


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCleosCoffersMachine:addSelfEffect()
    self.m_delayTime = 0.5
    self.m_isHaveJackpotBonus = false
    self.m_isBonusPlay = false
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 最初翻出来的bonus列表
    local oldBonus = selfData.old_bonus
    --特殊bonus(加倍的)列表
    local mutiList = selfData.mutiList
    --加倍后的倍数列表
    local multiOrderList = selfData.multi_order_list
    -- jackpot（）多福多彩
    local jackpot = selfData.jackpot
    -- 大于bet列不翻转数据
    local noEffectBonus = selfData.no_effect_bonus

    -- free下拖拽bonus
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self:isTriggerFreeBonusMove(selfData.remove_col) then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_FREE_MOVE_BONUS -- 动画类型
    end

    -- 初始的bonus
    if oldBonus and next(oldBonus) then
        self.m_isBonusPlay = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_TURN_BONUS_REWARD -- 动画类型
    else
        -- if self:getCurrSpinMode() == FREE_SPIN_MODE and noEffectBonus and next(noEffectBonus) then
        --     local selfEffect = GameEffectData.new()
        --     selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        --     selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
        --     self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        --     selfEffect.p_selfEffectType = self.EFFECT_TURN_DARK_BONUS_REWARD -- 动画类型
        -- end
    end

    -- jackpot(多福多彩玩法)
    if jackpot and next(jackpot) then
        self.m_isHaveJackpotBonus = true
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 4
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_JACKPOT_BONUS_PLAY -- 动画类型
    end

    -- 判断当前spin是否有连线
    local winLines = self.m_runSpinResultData.p_winLines or {}
    -- if self:getCurrSpinMode() ~= FREE_SPIN_MODE and #winLines > 0 then
    if #winLines > 0 then
       self.m_delayTime = 2.0
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCleosCoffersMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_FREE_MOVE_BONUS then
        local delayTime = self.m_delayTime + self.m_bonusDelayTime
        self.m_delayTime = 0.5
        self:delayCallBack(delayTime, function()
            self:playFreeMoveBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_TURN_BONUS_REWARD then
        self:delayCallBack(self.m_delayTime, function()
            -- if self:getCurrSpinMode() == FREE_SPIN_MODE then
            --     self:playTurnDarkBonus()
            -- end
            self:playTurnBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, self.ENUM_REWARD_TYPE.COINS_REWARD)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_TURN_DARK_BONUS_REWARD then
        self:delayCallBack(self.m_delayTime, function()
            self:playTurnDarkBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end, self.ENUM_REWARD_TYPE.COINS_REWARD)
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_JACKPOT_BONUS_PLAY then
        self:playTurnJackpotBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

-- 当前是否有拖拽bonus
function CodeGameScreenCleosCoffersMachine:isTriggerFreeBonusMove(_moveColData)
    local moveColData = _moveColData
    local moveBonusState = false
    self.m_bonusMoveInfo = {}
    if moveColData and next(moveColData) then
        for iCol, colState in pairs(moveColData) do
            if colState then
                local tb = {}
                for iRow = 1,self.m_iReelRowNum do
                    local symbolType = self:getMatrixPosSymbolType(iRow,iCol)
                    if self:getCurSymbolIsBonus(symbolType) then
                        table.insert(tb, iRow)
                    end
                end

                if #tb ~= 0 then
                    local beginPos = tb[1]
                    local endPos = tb[#tb]
                    if beginPos == 1 and endPos ~= self.m_iReelRowNum then
                        local bonustb = {col = iCol, beginNum = 3 - #tb, direction = "up"}
                        table.insert(self.m_bonusMoveInfo,bonustb)
                    elseif beginPos ~= 1 and endPos == self.m_iReelRowNum then
                        local bonustb = {col = iCol, beginNum = 3 - #tb, direction = "down"}
                        table.insert(self.m_bonusMoveInfo,bonustb)
                    elseif beginPos == 1 and endPos == self.m_iReelRowNum then
                        print("error")
                    else
                        print("error")
                    end
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

-- 本地排序，填充数据
function CodeGameScreenCleosCoffersMachine:getLocalSortData(_BonusIcons)
    local BonusIcons = _BonusIcons
    -- 本地排序
    local clientBonusData = {}
    for k, v in pairs(BonusIcons) do
        local tempTbl = {}
        local bonusPos = v[1]
        local bonusSymbolType = v[2]
        local bonusReardType = v[3]
        local bonusReard = v[4]
        local boostType = v[5]
        local fixPos = self:getRowAndColByPos(bonusPos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        tempTbl.p_bonusSymbolType = bonusSymbolType
        tempTbl.p_bonusPos = bonusPos
        tempTbl.p_bonusReardType = bonusReardType
        tempTbl.p_bonusReard = bonusReard
        tempTbl.p_rowIndex = fixPos.iX
        tempTbl.p_cloumnIndex = fixPos.iY
        tempTbl.p_symbolNode = symbolNode
        tempTbl.p_boostType = boostType
        table.insert(clientBonusData, tempTbl)
    end

    -- 本地排序
    table.sort(clientBonusData, function(a, b)
        if a.p_cloumnIndex ~= b.p_cloumnIndex then
            return a.p_cloumnIndex < b.p_cloumnIndex
        end
        if a.p_rowIndex ~= b.p_rowIndex then
            return a.p_rowIndex > b.p_rowIndex
        end
        return false
    end)

    return clientBonusData
end

-- 获取当前bonus奖励信息
function CodeGameScreenCleosCoffersMachine:getCurBonusRewardInfo(_symbolNodePos)
    local symbolNodePos = _symbolNodePos
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 翻出来压暗的bonus列表
    local noEffectBonus = clone(selfData.no_effect_bonus)
    for k, curBonusData in pairs(noEffectBonus) do
        if symbolNodePos == curBonusData[1] then
            return curBonusData
        end
    end

    return nil
end

-- free下拖拽bonus
function CodeGameScreenCleosCoffersMachine:playFreeMoveBonus(_callFunc)
    local callFunc = _callFunc
    self:clearWinLineEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 新轮盘数据
    local newReels = self.m_runSpinResultData.p_fsExtraData.change_reels or {}

    if #newReels > 0 then
        self.m_runSpinResultData.p_reels = newReels
    end

    -- 播放震动的类型
    local isPlayEffect = true
    local vibrateName = "actionframe1"
    for index, _data in ipairs(self.m_bonusMoveInfo) do
        if _data.direction == "down" then
            vibrateName = "actionframe2"
        end
    end
    
    local allNode = {}
    local hideBonusNode = {} --隐藏的bonus
    local newBonus = {}
    local isPlaySound = true
    local isBonusPlaySound = true
    for index, _data in ipairs(self.m_bonusMoveInfo) do
        local iCol = _data.col
        local reelColData = self.m_reelColDatas[iCol]
        local slotNodeH = reelColData.p_showGridH
        local reelNode = self:findChild("sp_reel_" .. (iCol - 1))
        local reelSize = reelNode:getContentSize()
        local pos = cc.p(util_convertToNodeSpace(reelNode, self.m_effectNode))
        local reelsNode = util_createAnimation("CleosCoffers_reelsMove.csb")
        self.m_effectNode:addChild(reelsNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 10000 + iCol)
        reelsNode:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
        table.insert(allNode, reelsNode)

        for index = 1, 3 do
            local nodeIndex = index
            if index == 1 then
                nodeIndex = 3
            elseif index == 3 then
                nodeIndex = 1
            end
            local symbolType = newReels[index][iCol]
            local curRow = self.m_iReelRowNum - index + 1
            local symbolNodePos = self:getPosReelIdx(curRow, iCol)
            local symbolNodeTemp = self:createCleosCoffersSymbol(symbolType)
            reelsNode:findChild("Node_"..nodeIndex):addChild(symbolNodeTemp, index)
            symbolNodeTemp:runAnim("idleframe", true)
            symbolNodeTemp.p_cloumnIndex = iCol
            symbolNodeTemp.p_rowIndex = index
            symbolNodeTemp.p_symbolNodePos = symbolNodePos
            table.insert(newBonus, symbolNodeTemp)
        end

        if _data.direction == "up" then
            reelsNode:findChild("Node_rootNew"):setPositionY(-slotNodeH * _data.beginNum)
        else
            reelsNode:findChild("Node_rootNew"):setPositionY(slotNodeH * _data.beginNum)
        end

        -- 动画
        local upEffectSpine = util_spineCreate("Socre_CleosCoffers_Bonus_advance", true, true)
        self.m_effectNode:addChild(upEffectSpine, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 9999 + iCol)
        upEffectSpine:setPosition(reelSize.width * 0.5 + pos.x, pos.y + reelSize.height * 0.5)
        table.insert(allNode, upEffectSpine)

        if isPlaySound then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_MoveBonus_Light)
            isPlaySound = false
        end
        -- actionframe(0-60)
        util_spinePlay(upEffectSpine, "actionframe", false)

        -- 隐藏当前列的bonus
        for row = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, row, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType then
                slotNode:setVisible(false)
                table.insert(hideBonusNode, slotNode)
            end
        end

        self:delayCallBack(30/30, function()
            local oneColTbl = {}
            for row = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, row, SYMBOL_NODE_TAG)
                if slotNode and slotNode.p_symbolType then
                    local symbolType = self:getMatrixPosSymbolType(row, iCol)
                    self:changeSymbolType(slotNode, symbolType)
                    if self:getCurSymbolIsBonus(symbolType) then
                        -- if iCol <= (self.m_iBetLevel+1) then
                            table.insert(oneColTbl, slotNode)
                        -- end
                        if iCol <= (self.m_iBetLevel+1) then
                            self:changeSymbolToClipParent(slotNode)
                        end
                    end
                 end
            end

            -- 播放棋盘震动
            if isPlayEffect then
                isPlayEffect = false
                self:runCsbAction(vibrateName, false, function()
                    self:runCsbAction("idle", true)
                end)
            end
            if isBonusPlaySound then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_MoveBonus_Play)
                isBonusPlaySound = false
            end
            reelsNode:findChild("Node_rootNew"):runAction(cc.Sequence:create(
                cc.EaseSineInOut:create(cc.MoveTo:create(12/30, cc.p(0, 0))),
                cc.CallFunc:create(function()
                    for index, symbolNode in ipairs(newBonus) do
                        if symbolNode.p_cloumnIndex <= (self.m_iBetLevel+1) then
                            symbolNode:runAnim("buling2", false, function()
                                symbolNode:runAnim("idleframe1", true)
                            end) 
                        else
                            symbolNode:runAnim("idleframe", true)
                            self:playTurnDarkBonus(symbolNode)
                        end
                    end

                    -- 压暗bonus赋值
                    for k, v in pairs(oneColTbl) do
                        if not tolua.isnull(v) then
                            if v.p_cloumnIndex <= (self.m_iBetLevel+1) then
                                v:runAnim("idleframe1", true)
                            else
                                self:playTurnDarkBonusIdle(v)
                            end
                        end
                    end
                end)
            ))
        end)
    end

    self:delayCallBack(63/30, function()
        for _, _node in ipairs(hideBonusNode) do
            _node:setVisible(true)
        end

        for _, _node in ipairs(allNode) do
            _node:removeFromParent()
        end

        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

-- free下大于bet列拖拽到位置压暗
function CodeGameScreenCleosCoffersMachine:playTurnDarkBonus(_symbolNode)
    local symbolNode = _symbolNode
    local symbolNodePos = symbolNode.p_symbolNodePos
    local curBonusData = self:getCurBonusRewardInfo(symbolNodePos)
    if curBonusData then
        local bonusSymbolType = curBonusData[2]
        local bonusReardType = curBonusData[3]
        local bonusReard = curBonusData[4]
        local boostType = curBonusData[5]

        if self:checkSymbolIsBonus(bonusSymbolType) then
            if bonusReardType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                symbolNode:setSymbolNodeBonusCoins(bonusReard)
                symbolNode:runAnim("Dimming", false, function()
                    symbolNode:runAnim("Dimming2", true)
                end)
            elseif bonusReardType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                symbolNode:runAnim("Dimming3", false, function()
                    symbolNode:runAnim("Dimming4", true)
                end)
            end
        elseif bonusSymbolType == self.SYMBOL_SCORE_BOOST_BONUS then
            local actName = "Dimming3"
            local idleName = "credit_boost2"
            if boostType == "credit" then
                actName = "Dimming3"
                idleName = "credit_boost2"
            elseif boostType == "super_credit" then
                actName = "Dimming4"
                idleName = "super_credit_boost2"
            elseif boostType == "mega_credit" then
                actName = "Dimming5"
                idleName = "mega_credit_boost2"
            end
            symbolNode:runAnim(actName, false, function()
                symbolNode:runAnim(idleName, true)
            end)
        end
    end
end

-- free下大于bet列拖拽到位置压暗（真实小块）
function CodeGameScreenCleosCoffersMachine:playTurnDarkBonusIdle(_symbolNode)
    local symbolNode = _symbolNode
    local symbolNodePos = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
    local curBonusData = self:getCurBonusRewardInfo(symbolNodePos)
    if curBonusData then
        local bonusSymbolType = curBonusData[2]
        local bonusReardType = curBonusData[3]
        local bonusReard = curBonusData[4]
        local boostType = curBonusData[5]

        -- 重新设置bonus层级
        local showOrder = self:getBounsScatterDataZorder(_symbolNode.p_symbolType) -  symbolNode.p_rowIndex
        _symbolNode.m_showOrder = showOrder
        _symbolNode:setLocalZOrder(showOrder)

        if self:checkSymbolIsBonus(bonusSymbolType) then
            if bonusReardType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                local labelCsb = self:getLblCsbNode(symbolNode, true)
                self:setBonusCoins(labelCsb, bonusReard, nil, true)
                symbolNode:runAnim("Dimming2", true)
            elseif bonusReardType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                self:setLblCsbNodeState(symbolNode)
                symbolNode:runAnim("Dimming4", true)
            end
        elseif bonusSymbolType == self.SYMBOL_SCORE_BOOST_BONUS then
            local idleName = "credit_boost2"
            if boostType == "credit" then
                idleName = "credit_boost2"
            elseif boostType == "super_credit" then
                idleName = "super_credit_boost2"
            elseif boostType == "mega_credit" then
                idleName = "mega_credit_boost2"
            end
            symbolNode:runAnim(idleName, true)
        end
    end
end

-- 普通bonus，先翻一遍（带钱的bonus翻转）；然后翻倍（有特殊bonus）
function CodeGameScreenCleosCoffersMachine:playTurnBonus(_callFunc, _curType)
    local callFunc = _callFunc
    self:clearWinLineEffect()
    self.m_scWaitTurnNode:stopAllActions()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 最初翻出来的bonus列表
    local oldBonus = clone(selfData.old_bonus)
    -- 本地排序
    local clientBonusData = self:getLocalSortData(oldBonus)
    -- 当前奖励类型
    local curType = _curType
    if curType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        --特殊bonus(加倍的)列表
        local mutiList = selfData.mutiList
        performWithDelay(self.m_scWaitNode, function()
            if mutiList and next(mutiList) then
                self:playAddBuff(callFunc, 0)
            else
                self:collectAllReward(callFunc, clientBonusData)
            end
        end, 0.2)
        return
    end

    local nextType = self.ENUM_REWARD_TYPE.BUFF_REWARD
    if curType == self.ENUM_REWARD_TYPE.COINS_REWARD then
        nextType = self.ENUM_REWARD_TYPE.JACKPOT_REWARD
    elseif curType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
        nextType = self.ENUM_REWARD_TYPE.BUFF_REWARD
    end

    if curType == self.ENUM_REWARD_TYPE.COINS_REWARD then
        self:setMaxMusicBGVolume()
        self:setSkipData(function()
            self:playTurnBonus(callFunc, nextType)
        end, true)
    end

    local tblActionList = {}
    local delayTime = 0.3
    for k, bonusData in pairs(clientBonusData) do
        local bonusSymbolType = bonusData.p_bonusSymbolType
        local bonusPos = bonusData.p_bonusPos
        local bonusReardType = bonusData.p_bonusReardType
        local bonusReard = bonusData.p_bonusReard
        local symbolNode = bonusData.p_symbolNode
        local boostType = bonusData.p_boostType
        if curType == self.ENUM_REWARD_TYPE.COINS_REWARD then
            if bonusReardType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    local labelCsb = self:getLblCsbNode(symbolNode)
                    self:setBonusCoins(labelCsb, bonusReard, bonusPos, true)
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Turn)
                    symbolNode:runAnim("actionframe", false, function()
                        symbolNode:runAnim("idleframe2", true)
                    end)
                end)
                tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
            elseif bonusReardType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    symbolNode:runAnim("idleframe4", true)
                end)
                -- tblActionList[#tblActionList+1] = cc.DelayTime:create(10/30)
            elseif bonusReardType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                    symbolNode:runAnim("idleframe2", true)
                end)
                -- tblActionList[#tblActionList+1] = cc.DelayTime:create(10/30)
            end
        else
            if bonusReardType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                --[[
                    actionframe:0-30 -- idleframe3
                    actionframe2:0-30 -- idleframe4
                    actionframe3:0-30 -- idleframe5 
                ]]
                local actName = "actionframe"
                local idleName = "idleframe3"
                if boostType == "credit" then
                    actName = "actionframe"
                    idleName = "idleframe3"
                elseif boostType == "super_credit" then
                    actName = "actionframe2"
                    idleName = "idleframe4"
                elseif boostType == "mega_credit" then
                    actName = "actionframe3"
                    idleName = "idleframe5"
                end
                self:setLblCsbNodeState(symbolNode)
                if bonusReardType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Turn)
                        symbolNode:runAnim("actionframe2", false, function()
                            symbolNode:runAnim("idleframe3", true)
                        end)
                    end)
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
                elseif bonusReardType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Turn)
                        symbolNode:runAnim(actName, false, function()
                            symbolNode:runAnim(idleName, true)
                        end)
                    end)
                    tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
                end
            end
        end
    end

    tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:setSkipData(nil, false)
        self:playTurnBonus(callFunc, nextType)
    end)
    self.m_scWaitTurnNode:runAction(cc.Sequence:create(tblActionList))
end

-- 翻倍boost
function CodeGameScreenCleosCoffersMachine:playAddBuff(_callFunc, _curIndex)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 当前boost索引
    local curIndex = _curIndex + 1
    -- 特殊bonus(加倍的)列表
    local mutiList = selfData.mutiList
    -- 加倍后的倍数列表
    local multiOrderList = selfData.multi_order_list
    -- 当前boost数据
    local curBoostData = mutiList[curIndex]
    -- 当前boost奖励数据
    local curBoostRewardData = multiOrderList[curIndex]

    if curBoostData and curBoostRewardData then
        local tblActionList = {}
        local boostBonusPos = curBoostData[1]
        local maxBuffMul = curBoostData[2]
        local boostType = curBoostData[3]
        local fixPos = self:getRowAndColByPos(boostBonusPos)
        local symbolNode = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        local curSymbolZorder = symbolNode:getLocalZOrder()
        --[[
            credit_boost：0-35 -- credit_boost2
            super_credit_boost：0-35 -- super_credit_boost2
            mega_credit_boost：0-35 -- mega_credit_boost2
        ]]
        local actName = "credit_boost"
        local idleName = "credit_boost2"
        if boostType == "credit" then
            actName = "credit_boost"
            idleName = "credit_boost2"
        elseif boostType == "super_credit" then
            actName = "super_credit_boost"
            idleName = "super_credit_boost2"
        elseif boostType == "mega_credit" then
            actName = "mega_credit_boost"
            idleName = "mega_credit_boost2"
        end
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            if symbolNode then
                self:setCurSymbolZorder(symbolNode, curSymbolZorder+300)
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Buff_AddCoins)
                local randomNum = math.random(1, 10)
                if randomNum <= 3 then
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Buff_AddCoinsEffect)
                end
                symbolNode:runAnim(actName, false, function()
                    self:setCurSymbolZorder(symbolNode, curSymbolZorder)
                    symbolNode:runAnim(idleName, true)
                end)
            end
        end)
        -- 第36帧时播放发出加倍的效果
        tblActionList[#tblActionList+1] = cc.DelayTime:create(36/30)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:flyParticleByBuff(callFunc, curBoostRewardData, curIndex, boostType, boostBonusPos)
        end)
        
        self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
    else
        -- 普通bonus
        local BonusIcons = clone(multiOrderList[#multiOrderList])
        -- 本地排序
        local clientBonusData = self:getLocalSortData(BonusIcons)
        self:delayCallBack(0.2, function()
            self:collectAllReward(callFunc, clientBonusData)
        end)
    end
end

-- 中间衔接飞行粒子
function CodeGameScreenCleosCoffersMachine:flyParticleByBuff(_callFunc, _curBoostRewardData, _curIndex, _boostType, _boostBonusPos)
    local callFunc = _callFunc
    -- 当前所有奖励
    local curBoostRewardData = _curBoostRewardData
    local curIndex = _curIndex
    local boostType = _boostType
    local boostBonusPos = _boostBonusPos
    local delayTime = 0.3

    if curBoostRewardData and next(curBoostRewardData) then
        -- 本地排序
        local clientBonusData = self:getLocalSortData(curBoostRewardData)
        for k, bonusData in pairs(clientBonusData) do
            local oneTblActionList = {}
            local bonusPos = bonusData.p_bonusPos
            local flyNode = self:getFlyNodeFromList()
            flyNode:setVisible(true)
            local startPos = self:getWorldToNodePos(self.m_flyEffectNode, boostBonusPos)
            local endPos = self:getWorldToNodePos(self.m_flyEffectNode, bonusPos)
            flyNode:setPosition(startPos)

            --[[
                red_par：mega_credit_boost--Particle_1
                blue_par：credit_boost--Particle_2
                purple_par：super_credit_boost--Particle_3
            ]]
            -- 不同类型播放不同的粒子
            local particleTbl = {}
            for i=1, 3 do
                local particle = flyNode:findChild("Particle_" .. i)
                if not tolua.isnull(particle) then
                    local isShow = false
                    if boostType == "credit" and i == 2 then
                        isShow = true
                    elseif boostType == "super_credit" and i == 3 then
                        isShow = true
                    elseif boostType == "mega_credit" and i == 1 then
                        isShow = true
                    end
                    if isShow then
                        particle:setVisible(true)
                        table.insert(particleTbl, particle)
                        particle:setPositionType(0)
                        particle:setDuration(-1)
                        particle:resetSystem()
                    else
                        particle:setVisible(false)
                    end
                end
            end

            oneTblActionList[#oneTblActionList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
            oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
                for i=1, #particleTbl do
                    if not tolua.isnull(particleTbl[i]) then
                        particleTbl[i]:stopSystem()
                    end
                end
            end)
            flyNode:runAction(cc.Sequence:create(oneTblActionList))
        end
    end
    self:delayCallBack(delayTime+0.1, function()
        self:playAddMulReward(callFunc, curBoostRewardData, curIndex)
    end)
end

-- 翻倍
function CodeGameScreenCleosCoffersMachine:playAddMulReward(_callFunc, _curBoostRewardData, _curIndex)
    local callFunc = _callFunc
    -- 当前所有奖励
    local curBoostRewardData = _curBoostRewardData
    local curIndex = _curIndex
    if curBoostRewardData and next(curBoostRewardData) then
        -- 本地排序
        local clientBonusData = self:getLocalSortData(curBoostRewardData)
        for k, bonusData in pairs(clientBonusData) do
            local bonusSymbolType = bonusData.p_bonusSymbolType
            local bonusPos = bonusData.p_bonusPos
            local bonusReardType = bonusData.p_bonusReardType
            local bonusReard = bonusData.p_bonusReard
            local curSymbolNode = bonusData.p_symbolNode
            local boostType = bonusData.p_boostType

            if curSymbolNode and bonusReardType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                -- 粒子飞到加数字
                local floatCoinsAni = util_createAnimation("CleosCoffers_boost_coins.csb")
                local startPos = self:getWorldToNodePos(self.m_flyEffectNode, bonusPos)
                floatCoinsAni:setPosition(startPos)
                self.m_flyEffectNode:addChild(floatCoinsAni)

                local oldCoins = self:getFloatCoinsData(bonusPos)
                local labelNode = floatCoinsAni:findChild("m_lb_coins")
                local targetCoins = bonusReard - oldCoins
                if labelNode then
                    local sScore = util_formatCoinsLN({coins = targetCoins, obligate = 3, obligateF = 1})
                    labelNode:setString("+"..sScore)
                end
                floatCoinsAni:setVisible(false)
                -- actionframe3：0-20
                local labelCsb = self:getLblCsbNode(curSymbolNode)
                self:delayCallBack(3/30, function()
                    floatCoinsAni:setVisible(true)
                    floatCoinsAni:runCsbAction("shengji", false, function()
                        if not tolua.isnull(floatCoinsAni) then
                            floatCoinsAni:removeFromParent()
                        end
                    end)
                    self:playJumpBonusCoins({_labelCsb = labelCsb, _oldCoins = oldCoins, _endCoins = bonusReard, _duration = 0.5})
                    self:setBonusCoins(labelCsb, bonusReard, bonusPos)
                end)
                curSymbolNode:runAnim("actionframe3", false, function()
                    curSymbolNode:runAnim("idleframe2", true)
                end)
            end
        end

        -- 一个一个加成
        self:delayCallBack(25/30, function()
            self:playAddBuff(callFunc, curIndex)
        end)
    else
        if type(callFunc) == "function" then
            callFunc()
        end
    end
end

function CodeGameScreenCleosCoffersMachine:getFlyNodeFromList()
    if #self.m_flyNodes == 0 then
        local flyNode = util_createAnimation("CleosCoffers_fly.csb")
        self.m_flyEffectNode:addChild(flyNode)
        return flyNode
    end

    local flyNode = self.m_flyNodes[#self.m_flyNodes]
    table.remove(self.m_flyNodes,#self.m_flyNodes)
    return flyNode
end

function CodeGameScreenCleosCoffersMachine:pushFlyNodeToList(flyNode)
    self.m_flyNodes[#self.m_flyNodes + 1] = flyNode
    flyNode:setVisible(false)
end

-- 最后收集奖励（一起收集）
function CodeGameScreenCleosCoffersMachine:collectAllReward(_callFunc, _clientBonusData)
    local callFunc = _callFunc
    -- 当前所有bonus
    local clientBonusData = _clientBonusData

    local totalRewardCoins = 0
    local delayTime = 1.0
    for index, curBonusData in pairs(clientBonusData) do
        local curSymbolNode = curBonusData.p_symbolNode
        local curRewardCoins = curBonusData.p_bonusReard
        local bonusReardType = curBonusData.p_bonusReardType
        if curSymbolNode and bonusReardType == self.ENUM_REWARD_TYPE.COINS_REWARD then
            totalRewardCoins = totalRewardCoins + curRewardCoins
            self.m_collectBonus = true
            -- actionframe4:0-20
            local curSymbolZorder = curSymbolNode:getLocalZOrder()
            self:setCurSymbolZorder(curSymbolNode, curSymbolZorder+300)
            curSymbolNode:runAnim("actionframe4", false, function()
                self:setCurSymbolZorder(curSymbolNode, curSymbolZorder)
                curSymbolNode:runAnim("idleframe2", true)
            end)
        end
    end

    if totalRewardCoins > 0 then
        local params = {
            overCoins  = totalRewardCoins,
            jumpTime   = delayTime,
            animName   = "actionframe3",
        }
        self:playBottomBigWinLabAnim(params)
        self:playBottomLight(totalRewardCoins, true)
    else
        delayTime = 0
    end

    self:delayCallBack(delayTime, function()
         if not self:checkHasBigWin() and not self.m_isHaveJackpotBonus then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        end
        self:delayCallBack(0.5, function()
            if type(callFunc) == "function" then
                callFunc()
            end
        end)
    end)
end

function CodeGameScreenCleosCoffersMachine:setCurSymbolZorder(_symbolNode, _curZorder)
    _symbolNode:setLocalZOrder(_curZorder)
end

-- jackpotBonus翻转+触发
function CodeGameScreenCleosCoffersMachine:playTurnJackpotBonus(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 最初翻出来的bonus列表
    local oldBonus = clone(selfData.old_bonus)
    -- 本地排序
    local clientBonusData = self:getLocalSortData(oldBonus)
    local curSymbolNode = nil
    for k, bonusData in pairs(clientBonusData) do
        local bonusSymbolType = bonusData.p_bonusSymbolType
        local bonusPos = bonusData.p_bonusPos
        local bonusReardType = bonusData.p_bonusReardType
        local bonusReard = bonusData.p_bonusReard
        local symbolNode = bonusData.p_symbolNode
        if bonusReardType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD and symbolNode then
            curSymbolNode = symbolNode
            break
        end
    end
    
    local tblActionList = {}
    if curSymbolNode then
        self:setLblCsbNodeState(curSymbolNode)
        local curSymbolZorder = curSymbolNode:getLocalZOrder()
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            -- actionframe2:0-30
            self:setCurSymbolZorder(curSymbolNode, curSymbolZorder+300)
            curSymbolNode:runAnim("actionframe2", false, function()
                curSymbolNode:runAnim("idleframe3", true)
            end)
        end)
        tblActionList[#tblActionList+1] = cc.DelayTime:create(30/30)
        -- actionframe5:0-60
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Trigger_BonusGame, 2, 0, 1)
            curSymbolNode:runAnim("actionframe5", false, function()
                self:setCurSymbolZorder(curSymbolNode, curSymbolZorder)
                curSymbolNode:runAnim("idleframe3", true)
            end)
        end)
        tblActionList[#tblActionList+1] = cc.DelayTime:create(60/30)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:showPickCutSceneAni(callFunc)
        end)
    else
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:showPickCutSceneAni(callFunc)
        end)
    end
    
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

--[[
    guochang：0-170帧
    时间线第60帧切换场景
    时间线第145帧，控制创建pick选项
    时间线结束后切掉此spine
]]
-- pick过场
function CodeGameScreenCleosCoffersMachine:showPickCutSceneAni(_callFunc)
    local callFunc = _callFunc
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Colorful_CutScene)
    self.m_pickCutSceneSpine:setVisible(true)
    util_spinePlay(self.m_pickCutSceneSpine, "guochang", false)
    util_spineEndCallFunc(self.m_pickCutSceneSpine, "guochang", function()
        self.m_pickCutSceneSpine:setVisible(false)
        -- if type(callFunc) == "function" then
        --     callFunc()
        -- end
    end)
    
    -- 60帧切
    self:delayCallBack(60/30, function()
        self:changeBgAndReelBg(3)
        self:showColorfulView(callFunc)
    end)
end

-- 重置动画
function CodeGameScreenCleosCoffersMachine:resetSlotNodeSpine(_slotNode)
    local ccbNode = _slotNode:checkLoadCCbNode()
    if not tolua.isnull(ccbNode.m_spineNode) then
        ccbNode:resetTimeLine()
    end
end

function CodeGameScreenCleosCoffersMachine:setLblCsbNodeState(_symbolNode)
    local aniNode = _symbolNode:checkLoadCCbNode()     
    local spine = aniNode.m_spineNode
    if spine and not tolua.isnull(spine.m_bindCsbNode) then
        local labelCsb = spine.m_bindCsbNode
        labelCsb:setVisible(false)
    end
end

function CodeGameScreenCleosCoffersMachine:getLblCsbNode(_symbolNode, _isDark)
    local csbName = "Socre_CleosCoffers_Bonus_Coins.csb"
    local bindNode = "shuzi"

    local labelCsb = self:getLblCsbOnSymbol(_symbolNode, csbName, bindNode)
    labelCsb:setVisible(true)
    util_resetCsbAction(labelCsb.m_csbAct)
    if _isDark then
        labelCsb:runCsbAction("over", false)
    else
        labelCsb:runCsbAction("idleframe", true)
    end

    return labelCsb
end

function CodeGameScreenCleosCoffersMachine:setBonusCoins(_csbNode, _bonusReard, _bonusPos, _isShowCoins)
    local csbNode = _csbNode
    local bonusCoins = _bonusReard
    local bonusPos = _bonusPos
    local isShowCoins = _isShowCoins
    if bonusPos then
        self:setFloatCoinsData(bonusPos, bonusCoins)
    end

    if isShowCoins then
        self:setBonusScore(csbNode, bonusCoins)
    end
end

function CodeGameScreenCleosCoffersMachine:setBonusScore(_csbNode, _bonusCoins)
    local csbNode = _csbNode
    local sScore = util_formatCoinsLN({coins = _bonusCoins, obligate = 3, obligateF = 1})
    local labelCoins = csbNode:findChild("m_lb_coins")
    if labelCoins then
        labelCoins:setString(sScore)
        self:updateLabelSize({label=labelCoins,sx=1.0,sy=1.0},142)
    end
end

-- 数字上涨（收集钱玩法；钱要上涨）
function CodeGameScreenCleosCoffersMachine:playJumpBonusCoins(parms)
    local labelCsb = parms._labelCsb
    local oldCoins = parms._oldCoins
    local endCoins = parms._endCoins
    local duration = parms._duration   --持续时间
    local targetCoins = endCoins - oldCoins
    --每次跳动上涨金币数
    local coinRiseNum = targetCoins / (60  * duration)   --1秒跳动60次
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = oldCoins + coinRiseNum
    if not tolua.isnull(labelCsb) then
        self:setBonusScore(labelCsb, curCoins)
        labelCsb:stopAllActions()

        util_schedule(labelCsb, function()
            curCoins = curCoins + coinRiseNum
            if curCoins >= endCoins then
                self:setBonusScore(labelCsb, endCoins)
                labelCsb:stopAllActions()
            else
                self:setBonusScore(labelCsb, curCoins)
            end
        end, 1/60)
    end
end

-- 获取奖励
function CodeGameScreenCleosCoffersMachine:getCurBonusReward(_index, _isBoost)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local rewardType = self.ENUM_REWARD_TYPE.COINS_REWARD
    local rewardCoins = 0
    if selfData and selfData.no_effect_bonus then
        local noEffectBonus = clone(selfData.no_effect_bonus)
        if _isBoost then
            for k, v in pairs(noEffectBonus) do
                if tonumber(v[1]) == _index then
                    rewardType = v[5]
                    rewardCoins = v[4]
                end
            end
        else
            for k, v in pairs(noEffectBonus) do
                if tonumber(v[1]) == _index then
                    rewardType = v[3]
                    rewardCoins = v[4]
                end
            end
        end
    end
    
    return rewardType, rewardCoins
end

-- 获取当前bet；free里获取平均bet
function CodeGameScreenCleosCoffersMachine:getCurSpinStateBet()
    local curBet = globalData.slotRunData:getCurTotalBet()
    return curBet
end

-- 根据index转换需要节点坐标系
function CodeGameScreenCleosCoffersMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

function CodeGameScreenCleosCoffersMachine:createCleosCoffersSymbol(_symbolType)
    local symbol = util_createView("CodeCleosCoffersSrc.CleosCoffersSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

-- bonus翻的时候，在点击的时候跳过移除
function CodeGameScreenCleosCoffersMachine:setSkipData(func, _state)
    self.m_skipFunc = func
    self.m_skip_click:setVisible(_state)
    self.m_bottomUI:setSkipBtnVisible(_state)
end

function CodeGameScreenCleosCoffersMachine:runSkipCollect()
    self.m_skip_click:setVisible(false)
    if type(self.m_skipFunc) == "function" then
        self.m_scWaitTurnNode:stopAllActions()
        self.m_bottomUI:setSkipBtnVisible(false)

        local selfData = self.m_runSpinResultData.p_selfMakeData
        -- 最初翻出来的bonus列表
        local oldBonus = selfData.old_bonus
        --特殊bonus(加倍的)列表
        local mutiList = selfData.mutiList
        --加倍后的倍数列表
        local multiOrderList = selfData.multi_order_list
        -- 本地排序
        local clientBonusData = self:getLocalSortData(oldBonus)
        
        local isPlaySound = true
        local tblActionList = {}
        for k, bonusData in pairs(clientBonusData) do
            local bonusSymbolType = bonusData.p_bonusSymbolType
            local bonusPos = bonusData.p_bonusPos
            local bonusReardType = bonusData.p_bonusReardType
            local bonusReard = bonusData.p_bonusReard
            local symbolNode = bonusData.p_symbolNode

            if bonusReardType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                if symbolNode.m_currAnimName ~= "actionframe" and symbolNode.m_currAnimName ~= "idleframe2" then
                    if isPlaySound then
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bonus_Turn)
                        isPlaySound = false
                    end
                    local labelCsb = self:getLblCsbNode(symbolNode)
                    self:setBonusCoins(labelCsb, bonusReard, bonusPos, true)
                    symbolNode:runAnim("actionframe", false, function()
                        symbolNode:runAnim("idleframe2", true)
                    end)
                end
            elseif bonusReardType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                if symbolNode.m_currAnimName ~= "idleframe4" then
                    symbolNode:runAnim("idleframe4", true)
                end
            elseif bonusReardType == self.ENUM_REWARD_TYPE.BUFF_REWARD then
                if symbolNode.m_currAnimName ~= "idleframe2" then
                    symbolNode:runAnim("idleframe2", true)
                end
            end
        end

        tblActionList[#tblActionList+1] = cc.DelayTime:create(1.0)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_skipFunc()
            self:setSkipData(nil, false)
        end)
        
        self.m_scWaitTurnNode:runAction(cc.Sequence:create(tblActionList))
    end
end

-- 本地维护飘钱的数据（用于当前涨多少钱）
function CodeGameScreenCleosCoffersMachine:setFloatCoinsData(_index, _curCoins)
    local index = _index
    local curCoins = _curCoins
    self.m_floatCoinsData[index] = curCoins
end

function CodeGameScreenCleosCoffersMachine:getFloatCoinsData(_index)
    local index = _index
    local curCoins = 0
    if self.m_floatCoinsData[index] then
        curCoins = self.m_floatCoinsData[index]
    end

    return curCoins
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenCleosCoffersMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    self.m_bigWinSpine:setVisible(true)
    util_spinePlay(self.m_bigWinSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinSpine:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime("actionframe")
    util_shakeNode(rootNode,5,10,aniTime)
end

--[[
    检测添加大赢光效
]]
function CodeGameScreenCleosCoffersMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 8
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

function CodeGameScreenCleosCoffersMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win)
    return CodeGameScreenCleosCoffersMachine.super.showEffect_runBigWinLightAni(self,effectData)
end

function CodeGameScreenCleosCoffersMachine:playEffectNotifyNextSpinCall( )
    CodeGameScreenCleosCoffersMachine.super.playEffectNotifyNextSpinCall(self)
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)
end

-- free和freeMore特殊需求
function CodeGameScreenCleosCoffersMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_FreeMoreBonus_Trigger)
        else
            globalMachineController:playBgmAndResume(self.m_ScatterTipMusicPath, 3, 0, 1)
        end
    end
end

-- 不用系统音效
function CodeGameScreenCleosCoffersMachine:checkSymbolTypePlayTipAnima(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return false
    else
        CodeGameScreenCleosCoffersMachine.super.checkSymbolTypePlayTipAnima(self,symbolType)
    end 

    return false
end


function CodeGameScreenCleosCoffersMachine:checkRemoveBigMegaEffect()
    CodeGameScreenCleosCoffersMachine.super.checkRemoveBigMegaEffect(self)
    if
        self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
            self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN)
     then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenCleosCoffersMachine:getShowLineWaitTime()
    local time = CodeGameScreenCleosCoffersMachine.super.getShowLineWaitTime(self)
    local feautes = self.m_runSpinResultData.p_features or {}
    if #feautes > 1 then
        time = self.m_changeLineFrameTime 
    end
    --insert-getShowLineWaitTime
    local winLines = self.m_reelResultLines or {}
    local lineValue = winLines[1] or {}
    if #winLines == 1 and lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        time = 0
    end 

    return time
end

--21.12.06-播放不影响老关的落地音效逻辑
function CodeGameScreenCleosCoffersMachine:playSymbolBulingSound(slotNodeList)
    local bulingSoundCfg = self.m_configData.p_symbolBulingSoundList
    if not bulingSoundCfg then
        return
    end

    local scatterSoundTbl = self.m_publicConfig.SoundConfig.Music_Scatter_Buling

    local isQuickHaveScatter = false
    -- 检查下前三列是否有scatter（前三列有scatter必然播落地）
    if self:getGameSpinStage() == QUICK_RUN then
        local reels = self.m_runSpinResultData.p_reels
        for iCol = 1, (self.m_iReelColumnNum-2) do
            for iRow = 1, self.m_iReelRowNum do
                local symbolType = reels[iRow][iCol]
                if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    isQuickHaveScatter = true
                    break
                end
            end
        end
    end

    for k, _slotNode in pairs(slotNodeList) do
        if self:checkSymbolBulingSoundPlay(_slotNode, true) then
            local symbolType = _slotNode.p_symbolType
            local symbolCfg = bulingSoundCfg[symbolType]
            if symbolCfg then
                local iCol = _slotNode.p_cloumnIndex
                local soundPath = symbolCfg[iCol] or symbolCfg["auto"]
                if _slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    soundPath = symbolCfg[1]
                end
                if soundPath then
                    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        self.m_curScatterBulingCount = self.m_curScatterBulingCount + 1
                        if self.m_curScatterBulingCount > #symbolCfg then
                            self.m_curScatterBulingCount = #symbolCfg
                        end
                        soundPath = scatterSoundTbl[self.m_curScatterBulingCount]
                        if self:getGameSpinStage() == QUICK_RUN then
                            if self:getCurFeatureIsFree() then
                                soundPath = scatterSoundTbl[3]
                            else
                                soundPath = scatterSoundTbl[1]
                            end
                        end
                    end

                    -- 快停时；有scatter 不播bonus
                    if self:getCurSymbolIsBonus(symbolType)then
                        if not isQuickHaveScatter then
                            self:playBulingSymbolSounds(iCol, soundPath, nil)
                        end
                    else
                        self:playBulingSymbolSounds(iCol, soundPath, nil)
                    end
                end
            end
        end
    end
end
----------------------------新增接口插入位---------------------------------------------


function CodeGameScreenCleosCoffersMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeCleosCoffersSrc.CleosCoffersFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("Node_freebar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenCleosCoffersMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("CleosCoffersSounds/music_CleosCoffers_custom_enter_fs.mp3")

    local showFSView = function ( ... )
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            local autoSpine = util_spineCreate("CleosCoffers_FreeSpinStart",true,true)
            local numAni = util_createAnimation("CleosCoffers/FreeSpinMore_2.csb")
            util_spinePushBindNode(autoSpine,"shuzi1",numAni)
            util_spinePlay(autoSpine, "auto", false)

            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_More_Auto)
            local view = self:showFreeSpinMore(self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)

            view:findChild("Node_spine"):addChild(autoSpine)
            numAni:findChild("m_lb_num"):setString(self.m_runSpinResultData.p_freeSpinNewCount)
            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        else
            local cutSceneSpine = util_spineCreate("CleosCoffers_FreeSpinStart2",true,true)
            cutSceneSpine:setVisible(false)

            local startSpine = util_spineCreate("CleosCoffers_FreeSpinStart",true,true)
            local numAni = util_createAnimation("CleosCoffers/FreeSpinStart_2.csb")
            util_spinePushBindNode(startSpine,"shuzi1",numAni)
            local btnAni = util_createAnimation("CleosCoffers/FreeSpinStart_3.csb")
            util_spinePushBindNode(startSpine,"start",btnAni)
            local btnNode = btnAni:findChild("Button")
            
            util_spinePlay(startSpine, "start", false)
            util_spineEndCallFunc(startSpine, "start", function()
                util_spinePlay(startSpine, "idleframe", true)
            end)
    
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartStart)
            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()       
            end)

            btnNode:setTouchEnabled(false)
            local time = view:getAnimTime("start")
            self:delayCallBack(time, function()
                btnNode:setTouchEnabled(true)
            end)
            btnNode:addTouchEventListener(function(sender, eventType)
                if eventType == ccui.TouchEventType.ended then
                    local endPos = sender:getTouchEndPosition()
                    local name = sender:getName()
                    if name == "Button" then
                        btnNode:setTouchEnabled(false)
                        view:showOver()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Fg_CutScene)
                        if not tolua.isnull(startSpine) then
                            util_spinePlay(startSpine, "actionframe", false)
                        end
                        if not tolua.isnull(cutSceneSpine) then
                            cutSceneSpine:setVisible(true)
                            util_spinePlay(cutSceneSpine, "actionframe", false)
                        end
                    end
                    -- 第95帧时切换棋盘
                    self:delayCallBack(95/30, function()
                        self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_FG_Bg)
                        self:changeBgAndReelBg(2)
                        self.m_baseFreeSpinBar:changeFreeSpinByCount()
                        self.m_baseFreeSpinBar:setVisible(true)
                    end)
                end
            end)

            view:findChild("Node_spine"):addChild(startSpine, 5)
            view:findChild("Node_spine"):addChild(cutSceneSpine)
            numAni:findChild("m_lb_num"):setString(self.m_iFreeSpinTimes)
            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

---------------------------------弹版----------------------------------
function CodeGameScreenCleosCoffersMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = nil

    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenCleosCoffersMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        if func then
            func()
        end
    end

    local ownerlist = nil
    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc, BaseDialog.AUTO_TYPE_ONLY)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_MORE, ownerlist, newFunc)
    end
end

-- base到free过场
function CodeGameScreenCleosCoffersMachine:showBaseToFreeSceneAni(_callFunc, _isStart)
    local callFunc = _callFunc
    local isStart = _isStart

    local isRunFunc = true
    for i=1, 3 do
        self.m_baseToFreeSpineTbl[i]:setVisible(true)
        util_spinePlay(self.m_baseToFreeSpineTbl[i],"guochang",false)
        util_spineEndCallFunc(self.m_baseToFreeSpineTbl[i], "guochang", function()
            self.m_baseToFreeSpineTbl[i]:setVisible(false)
            if isRunFunc then
                isRunFunc = false
                if type(callFunc) == "function" then
                    callFunc()
                end
            end
        end)
    end

    -- 68帧切
    performWithDelay(self.m_scWaitNode, function()
        self:closeMoreRoleAct(true)
        if isStart then
            self.m_effectFixdNode:setVisible(true)
            local curBigSymbolNode = self.m_freeBigSymbolNode
            if not tolua.isnull(curBigSymbolNode) then
                self.m_freeBigSymbolNode.m_curActName = "idleframe2"
                curBigSymbolNode:runAnim("idleframe2", true)
            end
            self.m_topBarView:refreshShowType(true)
            self.m_bonusBtnView:setBtnState(false)
            self:changeBgAndReelBg(2)
        else
            self.m_effectFixdNode:setVisible(false)
            self.m_topBarView:refreshShowType(false)
            self.m_bonusBtnView:setBtnState(true)
            self:changeBgAndReelBg(1)
        end
    end, 68/30)
end

function CodeGameScreenCleosCoffersMachine:showFreeSpinOverView(effectData)
    local strCoins = util_formatCoinsLN(globalData.slotRunData.lastWinCoin, 30)
    if globalData.slotRunData.lastWinCoin > 0 then
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Fg_OverStart, 2, 0, 1)
        local overSpine = util_spineCreate("CleosCoffers_FreeSpinOver",true,true)
        local coinsAni = util_createAnimation("CleosCoffers/FreeSpinOver_2.csb")
        util_spinePushBindNode(overSpine,"shuzi1",coinsAni)
        local numAni = util_createAnimation("CleosCoffers/FreeSpinOver_3.csb")
        util_spinePushBindNode(overSpine,"shuzi2",numAni)
        local btnAni = util_createAnimation("CleosCoffers/FreeSpinOver_4.csb")
        util_spinePushBindNode(overSpine,"collect",btnAni)
        local btnNode = btnAni:findChild("Button")
        
        util_spinePlay(overSpine, "start", false)
        util_spineEndCallFunc(overSpine, "start", function()
            util_spinePlay(overSpine, "idle", true)
        end)

        local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
            self:clearWinLineEffect()
            self:triggerFreeSpinOverCallFun()
        end)

        btnNode:setTouchEnabled(false)
        local time = view:getAnimTime("start")
        self:delayCallBack(time, function()
            btnNode:setTouchEnabled(true)
        end)
        btnNode:addTouchEventListener(function(sender, eventType)
            if eventType == ccui.TouchEventType.ended then
                local endPos = sender:getTouchEndPosition()
                local name = sender:getName()
                if name == "Button" then
                    btnNode:setTouchEnabled(false)
                    view:showOver()
                    self:hideFreeSpinBar()
                    if not tolua.isnull(overSpine) then
                        util_spinePlay(overSpine, "over", false)
                    end
                    performWithDelay(self.m_scWaitNode, function()
                        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
                    end, 5/60)
                end
                self:changeBgAndReelBg(1, true)
            end
        end)

        view:findChild("Node_spine"):addChild(overSpine, 5)
        numAni:findChild("m_lb_num"):setString(self.m_runSpinResultData.p_freeSpinsTotalCount)
        local node=coinsAni:findChild("m_lb_coins")
        node:setString(strCoins)
        view:findChild("root"):setScale(self.m_machineRootScale)
        view:updateLabelSize({label=node,sx=0.95,sy=0.95},1010)
        util_setCascadeOpacityEnabledRescursion(view, true)
    else
        local cutSceneFunc = function()
            performWithDelay(self.m_scWaitNode, function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_OverOver)
            end, 5/60)
        end

        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Over_NoWin)
        local view = self:showFreeSpinOverNoWin(function()
            self:clearWinLineEffect()
            self:triggerFreeSpinOverCallFun()
        end)

        view:setBtnClickFunc(cutSceneFunc)
    end
end

function CodeGameScreenCleosCoffersMachine:showFreeSpinOver(coins, num, func)
    self:clearCurMusicBg()
    local ownerlist = nil
    return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_OVER, ownerlist, func)
    --也可以这样写 self:showDialog("FreeSpinOver",ownerlist,func)
end

function CodeGameScreenCleosCoffersMachine:showFreeSpinOverNoWin(_func)
    local view = self:showDialog("NoWinView",nil,_func)
    return view
end

function CodeGameScreenCleosCoffersMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    local waitTime = 0
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 播放震动
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                    local parent = slotNode:getParent()
                    if parent ~= self.m_clipParent then
                        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, TAG_SYMBOL_TYPE.SYMBOL_SCATTER,0)
                    end
                    slotNode:runAnim("actionframe", false, function()
                        slotNode:runAnim("idleframe2", true)
                    end)
                    local duration = slotNode:getAniamDurationByName("actionframe")
                    waitTime = util_max(waitTime,duration)
                end
            end
        end
    end
    self:playScatterTipMusicEffect()
    
    performWithDelay(self,function()
        self:showFreeSpinView(effectData)
    end,waitTime)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true  
end

---
    -- 逐条线显示 线框和 Node 的actionframe
    --
function CodeGameScreenCleosCoffersMachine:showLineFrameByIndex(winLines,frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        return
    end
    self.super.showLineFrameByIndex(self, winLines, frameIndex)    
end

---
    -- 显示所有的连线框
    --
function CodeGameScreenCleosCoffersMachine:showAllFrame(winLines)
    local tempLineValue = {}
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN then
            table.insert(tempLineValue, lineValue)
        end
    end
    CodeGameScreenCleosCoffersMachine.super.showAllFrame(self, tempLineValue)    
end

function CodeGameScreenCleosCoffersMachine:getFsTriggerSlotNode(parentData, symPosData)
    return self:getFixSymbol(symPosData.iY, symPosData.iX)    
end

function CodeGameScreenCleosCoffersMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeCleosCoffersSrc.CleosCoffersJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpotbar"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
        显示jackpotWin
    ]]
function CodeGameScreenCleosCoffersMachine:showJackpotView(coins,jackpotType,func)
    if not self:checkHasBigWin() then
        --检测大赢
        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
    end
    self:playBottomLight(coins, true)
    local view = util_createView("CodeCleosCoffersSrc.CleosCoffersJackpotWinView",{
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

function CodeGameScreenCleosCoffersMachine:setReelRunInfo()
    local longRunConfigs = {}
    local reels =  self.m_stcValidSymbolMatrix
    self.m_longRunControl:setUsingReels(reels) -- 设置参与快滚计算的reel信息      
    table.insert( longRunConfigs, {["longRunId"] = self.m_longRunControl.Enum_LongRunId["1toMaxCol"] ,["symbolType"] = {90}} )
    self.m_longRunControl:getLongRunStartAndEndCol(longRunConfigs) -- 处理快滚信息
    self.m_longRunControl:setLongRunLenAndStates() -- 设置快滚状态  
end

-- 处理预告中奖和额外的快滚逻辑
function CodeGameScreenCleosCoffersMachine:MachineRule_ResetReelRunData()
    self.m_symbolExpectCtr:MachineResetReelRunDataCall()
    CodeGameScreenCleosCoffersMachine.super.MachineRule_ResetReelRunData(self)    
end

function CodeGameScreenCleosCoffersMachine:symbolBulingEndCallBack(_slotNode)
    self.m_symbolExpectCtr:MachineSymbolBulingEndCall(_slotNode)    
end

-- 若本次Spin触发Fortune Coin Boost且玩家能达到大赢或触发FG/JACKPOT ,40%概率播放
function CodeGameScreenCleosCoffersMachine:getCurSpinIsTriggerColorfulPlay()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 多福多彩
    local jackpotData = selfData.jackpot
    if jackpotData and next(jackpotData) then
        return true
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
function CodeGameScreenCleosCoffersMachine:getFeatureGameTipChance(_probability)
    --free中不播预告中奖
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return false
    end

    local features = self.m_runSpinResultData.p_features or {}

    local isTriggerBonusPlay = self:getCurSpinIsTriggerColorfulPlay()
    
    --是否触发玩法,默认不触发数组长度ID为0,每多一个玩法数组内会多一个玩法ID,若需要只是某个玩法需要预告中奖,单独处理即可
    if #features >= 2 and features[2] > 0 or isTriggerBonusPlay then
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
function CodeGameScreenCleosCoffersMachine:showFeatureGameTip(_func)
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
function CodeGameScreenCleosCoffersMachine:playFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_Sound)

    self.m_yuGaoSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine, "actionframe_yugao", false)
    util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe_yugao", function()
        self.m_yuGaoSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)

    local rootNode = self:findChild("root")
    local aniTime = 75/30
    util_shakeNode(rootNode,5,10,aniTime)
end

-- 当前是否是free
function CodeGameScreenCleosCoffersMachine:getCurFeatureIsFree()
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        return true
    end

    return false
end

--[[
        bonus玩法
    ]]
function CodeGameScreenCleosCoffersMachine:showColorfulView(_callFunc)
    local callFunc = _callFunc

    self:clearCurMusicBg()

    self:clearWinLineEffect()
    self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_Colorful_Bg)

    local jackpotType,winCoins = self:getWinJackpotCoinsAndType()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local jackpotData = clone(selfData.jackpot)

    --重置bonus界面
    self.m_colorfulGameView:resetView(jackpotData,function()
        self:showJackpotView(winCoins, jackpotType, function()
            callFunc()
        end)
    end)

    self.m_colorfulGameView:showView() 
    self:delayCallBack(85/30, function()
        self.m_colorfulGameView:showPickItem()
    end)
end

-- jackpotWin弹板点击按钮回调
function CodeGameScreenCleosCoffersMachine:closeJackpotWinCallFunc()
    self:setAddJackptState(false)
    self:resetMusicBg()
    self:changeBgAndReelBg(1, true)
end

--[[
        获取jackpot类型及赢得的金币数
    ]]
function CodeGameScreenCleosCoffersMachine:getWinJackpotCoinsAndType()
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        return string.lower(jackpotType),coins
    end
    return "",0    
end

function CodeGameScreenCleosCoffersMachine:changeBgAndReelBg(_bgType, _isSwitch)
    if _isSwitch then
        local switchNameTbl = {"free_to_base", "colorful_to_base", "colorful_to_free"}
        local idleNameTbl = {"idle_base", "idle_base", "idle_free"}
        local switchName = switchNameTbl[_bgType]
        local idleName = idleNameTbl[_bgType]
        self.m_gameBg:runCsbAction(switchName, false, function()
            self.m_gameBg:runCsbAction(idleName, true)
        end)
    else
        local idleNameTbl = {"idle_base", "idle_free", "idle_colorful"}
        local idleName = idleNameTbl[_bgType]
        self.m_gameBg:runCsbAction(idleName, true)
    end

    self.m_betBtnView:playIdle()
    -- 设置棋盘状态
    if _bgType == 3 then
        self:runCsbAction("idle2", true)
    else
        self:runCsbAction("idle", true)
        if _bgType == 2 then
            self.m_betBtnView:playDarkEffect()
        end
    end
end

function CodeGameScreenCleosCoffersMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    local lineWinCoins = self:getClientWinCoins()
    local bonusCoins = 0
    if self.m_isBonusPlay then
        bonusCoins = self:getCurBonusWinCoins()
    end

    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setLastWinCoin(self.m_runSpinResultData.p_fsWinCoins-bonusCoins)
    else
        self:setLastWinCoin(self.m_runSpinResultData.p_winAmount-bonusCoins)
    end

    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {lineWinCoins, isNotifyUpdateTop})
end

function CodeGameScreenCleosCoffersMachine:checkIsAddLastWinSomeEffect()
    local notAdd = false

    if #self.m_vecGetLineInfo == 0 and not self.m_isBonusPlay then
        notAdd = true
    end

    return notAdd
end

-- 获取bonus赢钱
function CodeGameScreenCleosCoffersMachine:getCurBonusWinCoins()
    local bonusCoins = 0
    local jackpotType,winCoins = self:getWinJackpotCoinsAndType()
    if winCoins and winCoins > 0 then
        bonusCoins = bonusCoins + winCoins
    end

    -- 普通bonus
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local oldBonus = selfData.old_bonus
    if oldBonus and next(oldBonus) then
        for k, bonusData in pairs(oldBonus) do
            local bonusType = bonusData[3]
            local bonusReard = bonusData[4]
            if bonusType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                bonusCoins = bonusCoins + bonusReard
            end
        end
    end
    return bonusCoins
end

------------------ 高低bet相关 -----------------------------

function CodeGameScreenCleosCoffersMachine:getBetLevelCoins(index)
    local betMulti = 1
    if self.m_specialBetMulti and #self.m_specialBetMulti > 0 then
        betMulti = self.m_specialBetMulti[index]
    end
    local betIndex = globalData.slotRunData:getCurBetIndex()
    local totalBetValue = globalData.slotRunData:getCurBetValueByIndex(betIndex)
    local betValue = totalBetValue * betMulti
    return betValue
end

function CodeGameScreenCleosCoffersMachine:getCurBetLevelMulti()
    local betMulti = 1
    if self.m_specialBetMulti then
        betMulti = self.m_specialBetMulti[self.m_iBetLevel + 1]
    end
    return betMulti or 1
end

--[[
    切换bet
]]
function CodeGameScreenCleosCoffersMachine:updateBetLevel()
    self.m_betBtnView:updateCoins(self.m_iBetLevel)
end

function CodeGameScreenCleosCoffersMachine:chooseBetLevel(_index)
    --是否 选择了不同的 bet
    if not self:judgeCurSameLastChoose(_index) then
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

-- 当前点击是否为之前的选项
function CodeGameScreenCleosCoffersMachine:judgeCurSameLastChoose(_index)
    if _index - 1 == self.m_iBetLevel then
        return true
    end
    return false
end

--[[
    修改bet值 和 按钮显示
]]
function CodeGameScreenCleosCoffersMachine:changeBetAndBetBtn( )
    local curTotalBet = self:getCurSpinStateBet()
    local curBetMulti = self:getCurBetLevelMulti()
    globalData.slotRunData:setCurBetMultiply(curBetMulti)

    local betId = globalData.slotRunData.iLastBetIdx
    self.m_bottomUI:changeBetCoinNum(betId, curTotalBet)

    self.m_betBtnView:updateColItem(self.m_iBetLevel)
    self.m_betBtnView:updateCoins(self.m_iBetLevel)
end

--[[
    选择不同bet 棋盘上的动画
]]
function CodeGameScreenCleosCoffersMachine:showChooseBoardFrame()
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_CutScene_ChooseBet)
    self:setSpinTounchType(false)
    local intervalTime = 3/30
    local delayTime = 36/30 + self.m_iBetLevel*intervalTime
    for index = 1, self.m_iBetLevel+1 do
        local curDelayTime = (index-1)*intervalTime
        local curKuangDelayTime = (index-1)*intervalTime + 15/30
        self:delayCallBack(curDelayTime, function()
            self.m_topColEffectView:showCurColEffect(index)
        end)
        self:delayCallBack(curKuangDelayTime, function()
            self:changeKuangEffect(false, index)
        end)
    end

    -- 当CalacasParade_reel_jinbi 开始播放，同时播放此时间线，时间线结束后切掉
    self.m_yuGaoSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe", function()
        self.m_yuGaoSpine:setVisible(false)
    end)

    -- 第一列此时间线第12帧，播放一次主界面csd内的 actionframe3时间线
    self:delayCallBack(12/30, function()
        self:runCsbAction("actionframe3", false, function()
            self:runCsbAction("idle", true)
        end)
    end)

    self:delayCallBack(delayTime, function()
        self:setSpinTounchType(true)
    end)
end

--[[
    改变棋盘框
]]
function CodeGameScreenCleosCoffersMachine:changeKuangEffect(_isOnEnter, _curIndex)
    local isOnEnter = _isOnEnter
    local curIndex = _curIndex
    self.m_kuangNodeAni:setVisible(true)
    if isOnEnter then
        for index = 1, 5 do
            self.m_kuangNodeAni:findChild("active_"..index):setVisible(index == (self.m_iBetLevel+1))
            self:findChild("Node_effect_reel_"..index):setVisible(index <= (self.m_iBetLevel+1))
        end
    else
        for index = 1, 5 do
            self.m_kuangNodeAni:findChild("active_"..index):setVisible(index == curIndex)
            self:findChild("Node_effect_reel_"..index):setVisible(index <= curIndex)
        end
    end
end

-- 打开选择bet界面
function CodeGameScreenCleosCoffersMachine:openBetChooseView()
    if self:betBtnIsCanClick()then
        self.m_chooseBetView:showView(self.m_iBetLevel)
    end
end

function CodeGameScreenCleosCoffersMachine:betBtnIsCanClick()
    local isFreespin = self.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self:getCurrSpinMode() == NORMAL_SPIN_MODE and self:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_isRunningEffect == true
    local isAutoSpin = self:getCurrSpinMode() == AUTO_SPIN_MODE
    local features = self.m_runSpinResultData.p_features or {}
    local bonusStatus = self.m_runSpinResultData.p_bonusStatus
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin then
        return false
    end

    return true
end

function CodeGameScreenCleosCoffersMachine:setSpinTounchType(_isTouch)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, _isTouch})
end

function CodeGameScreenCleosCoffersMachine:playBottomLight(_endCoins, _isJackpot)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Bottom_AddCoins_Effect)
    self.m_bottomUI:playCoinWinEffectUI()

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenCleosCoffersMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenCleosCoffersMachine:getCurBottomWinCoins()
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

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenCleosCoffersMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
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
                if symbolCfg[1] and self:checkSymbolIsClipParent(_slotNode) then
                    --不能直接使用提层后的坐标不然没法回弹了
                    local curPos = util_convertToNodeSpace(_slotNode, self.m_clipParent)
                    self:changeSymbolToClipParent(_slotNode)
                    -- util_setSymbolToClipReel(self, _slotNode.p_cloumnIndex, _slotNode.p_rowIndex, _slotNode.p_symbolType, 0)
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

-- 判断当前线快是否需要提层
function CodeGameScreenCleosCoffersMachine:checkSymbolIsClipParent(_slotNode)
    if _slotNode then
        local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
        -- 是否是最终信号
        if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
            if self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
                if _slotNode.p_cloumnIndex <= (self.m_iBetLevel+1) then
                    return true
                else
                    return false
                end
            else
                return true
            end
        end
    end

    return false
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenCleosCoffersMachine:checkSymbolBulingSoundPlay(_slotNode, _isSound)
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
            elseif _isSound and self:getCurSymbolIsBonus(_slotNode.p_symbolType) then
                if _slotNode.p_cloumnIndex <= (self.m_iBetLevel+1) then
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

function CodeGameScreenCleosCoffersMachine:playBulingAnimFunc(_slotNode,_symbolCfg)
    if _slotNode.p_cloumnIndex > (self.m_iBetLevel+1) then
        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            if self:checkSymbolIsBonus(_slotNode.p_symbolType) then
                local rewardType, rewardCoins = self:getCurBonusReward(self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex))
                if rewardType == self.ENUM_REWARD_TYPE.COINS_REWARD then
                    local labelCsb = self:getLblCsbNode(_slotNode, true)
                    self:setBonusCoins(labelCsb, rewardCoins, nil, true)
                    -- self:resetSlotNodeSpine(_slotNode)
                    _slotNode:runAnim("Dimming", false, function()
                        _slotNode:runAnim("Dimming2", true)
                    end)
                elseif rewardType == self.ENUM_REWARD_TYPE.JACKPOT_REWARD then
                    self:setLblCsbNodeState(_slotNode)
                    _slotNode:runAnim("Dimming3", false, function()
                        _slotNode:runAnim("Dimming4", true)
                    end)
                end
            elseif _slotNode.p_symbolType == self.SYMBOL_SCORE_BOOST_BONUS then
                local boostType, rewardCoins = self:getCurBonusReward(self:getPosReelIdx(_slotNode.p_rowIndex, _slotNode.p_cloumnIndex), true)
                local actName = "Dimming3"
                local idleName = "credit_boost2"
                if boostType == "credit" then
                    actName = "Dimming3"
                    idleName = "credit_boost2"
                elseif boostType == "super_credit" then
                    actName = "Dimming4"
                    idleName = "super_credit_boost2"
                elseif boostType == "mega_credit" then
                    actName = "Dimming5"
                    idleName = "mega_credit_boost2"
                end
                _slotNode:runAnim(actName, false, function()
                    _slotNode:runAnim(idleName, true)
                end)
            end
        end
    else
        _slotNode:runAnim(_symbolCfg[2], false, function()
            self:symbolBulingEndCallBack(_slotNode)
        end)
    end
end

return CodeGameScreenCleosCoffersMachine
