-- AfricaRiseMiniMachine.lua
--
--

local BaseMiniFastMachine = require "Levels.BaseMiniFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local AfricaRiseSlotFastNode = require "CodeAfricaRiseSrc.AfricaRiseSlotsNode"

local AfricaRiseMiniMachine = class("AfricaRiseMiniMachine", BaseMiniFastMachine)

AfricaRiseMiniMachine.SYMBOL_SYMBOL_101 = 101
AfricaRiseMiniMachine.SYMBOL_SYMBOL_102 = 102
AfricaRiseMiniMachine.SYMBOL_SYMBOL_103 = 103
AfricaRiseMiniMachine.SYMBOL_SYMBOL_EXIT = 120
AfricaRiseMiniMachine.SYMBOL_WILD_X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 107
AfricaRiseMiniMachine.SYMBOL_SPIN_ADD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 108

AfricaRiseMiniMachine.EFFECT_CHOOSE_SYMBOL = GameEffect.EFFECT_SELF_EFFECT - 1 --
AfricaRiseMiniMachine.EFFECT_SHOW_BONUS_OVER = GameEffect.EFFECT_SELF_EFFECT - 2 --

local upReelData = {120, 4, 102, 0, 103, 101, 120, 2, 4, 102, 103, 1, 120, 3, 101, 103, 4, 2, 120, 3, 102, 103, 102, 1}

-- AfricaRiseMiniMachine.m_machineIndex = nil -- csv 文件模块名字

AfricaRiseMiniMachine.gameResumeFunc = nil
AfricaRiseMiniMachine.gameRunPause = nil

-- 构造函数
function AfricaRiseMiniMachine:ctor()
    self.m_BonusWinCoin = 0
    BaseMiniFastMachine.ctor(self)
    self.m_bFirstClick = true
    self.m_bFirstWin = true
    self.m_winFramList = {}
    self.m_winLineFrame = {}
    self.m_winLineNum = 0
    self.m_startCoins = 0
    self.m_pauseRef = 0
end

function AfricaRiseMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_parent = data.parent
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function AfricaRiseMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function AfricaRiseMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "AfricaRise"
end

function AfricaRiseMiniMachine:getlevelConfigName()
    local levelConfigName = "LevelAfricaRiseMiniConfig.lua"

    return levelConfigName
end

function AfricaRiseMiniMachine:getMachineConfigName()
    local str = "Mini"
    return self.m_moduleName .. str .. "Config" .. ".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function AfricaRiseMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil
    if symbolType == self.SYMBOL_WILD_X then
        return "Socre_AfricaRise_wild"
    elseif symbolType == self.SYMBOL_SPIN_ADD then
        return "Socre_AfricaRise_SpinAdd"
    elseif symbolType == self.SYMBOL_SYMBOL_101 then
        return "Socre_AfricaRise_hua1"
    elseif symbolType == self.SYMBOL_SYMBOL_102 then
        return "Socre_AfricaRise_hua2"
    elseif symbolType == self.SYMBOL_SYMBOL_103 then
        return "Socre_AfricaRise_hua3"
    elseif symbolType == self.SYMBOL_SYMBOL_EXIT then
        return "AfricaRise_Exit"
    end
    return ccbName
end

---
-- 读取配置文件数据
--
function AfricaRiseMiniMachine:readCSVConfigData()
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), self:getlevelConfigName())
    end
    globalData.slotRunData.levelConfigData = self.m_configData
end

function AfricaRiseMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("AfricaRise/GameScreenAfricaRise_zhuanpan.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function AfricaRiseMiniMachine:initMachine()
    self.m_moduleName = "AfricaRise" -- self:getModuleName()

    BaseMiniFastMachine.initMachine(self)

    self.m_upTip = util_createView("CodeAfricaRiseSrc.AfricaRiseBonusUpTip")
    self:findChild("kuang"):addChild(self.m_upTip)

    self.m_miniBar = util_createView("CodeAfricaRiseSrc.AfricaRiseMiniBar")
    self:findChild("total"):addChild(self.m_miniBar)

    self:runCsbAction("idleframe", false)
    self:InitUpReelView()
    local node = self:findChild("m_lb_coins")
    node:setString(util_formatCoins(0, 50))
    self.m_bUpdataWin = true
    self.m_iStartNum = 1
    self.m_updataTime = 0.04
    self.m_bresult = false
    self:addClick(self:findChild("touch_Panel"))
    self.m_panelTouchFlag = true --可点击区域 可点击
end

--默认按钮监听回调
function AfricaRiseMiniMachine:clickFunc(sender)
    if self.m_panelTouchFlag then
        self.m_parent:normalSpinBtnCall()
    end
    print("AfricaRiseMiniMachine clickFunc ===============111")
end

-- 初始化上边轮盘
function AfricaRiseMiniMachine:InitUpReelView()
    self.m_updataSymbol = {}
    for i = 1, #upReelData do
        local pType = upReelData[i]
        local node = self:findChild("icon_" .. i)
        local pos = cc.p(node:getPosition())
        local symbol = self:getSlotNodeWithPosAndType(pType, 1, 1, true)
        symbol:runAnim("idleframe2", false)
        self:findChild("icon_" .. i):addChild(symbol)
        self.m_updataSymbol[i] = symbol
    end
end

function AfricaRiseMiniMachine:changeReelView()
    for i = 1, #self.m_updataSymbol do
        local node = self.m_updataSymbol[i]
        node:runAnim("idle2", false)
    end
end

--水果机开始滚动 所有的效果重置
function AfricaRiseMiniMachine:startUpdate()
    self.m_bUpdataWin = true
    self.m_updataTime = 0.01
    self.m_bresult = false
    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
        self.m_showLineHandlerID = nil
    end
    self.m_winLineNum = 0
    self.m_upTip:removeChooseEff()
    if self.m_eff then
        self.m_eff:removeFromParent()
        self.m_eff = nil
    end
    if #self.m_winFramList > 0 then
        for i = 1, #self.m_winFramList do
            local eff = self.m_winFramList[i]
            eff:removeFromParent()
        end
        self.m_winFramList = {}
    end
    if #self.m_winLineFrame > 0 then
        for i = 1, #self.m_winLineFrame do
            local eff = self.m_winLineFrame[i]
            eff:removeFromParent()
        end
        self.m_winLineFrame = {}
    end
    self:coinsJumpOver()
    self:beginUpdate()
end

--开始随机
function AfricaRiseMiniMachine:beginUpdate()
    scheduler.performWithDelayGlobal(
        function()
            if self.m_bUpdataWin then
                self:updateWinSymbol()
            end
        end,
        self.m_updataTime,
        "AfricaRiseMini"
    )
end

--播放赢钱
function AfricaRiseMiniMachine:updateWinCoins()
    self:jumpCoins(self.m_BonusWinCoin)
end

--赢钱跳动
function AfricaRiseMiniMachine:jumpCoins(coins)
    local coinRiseNum = (coins - self.m_startCoins) / 60
    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = self.m_startCoins

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curCoins = curCoins + coinRiseNum
            if curCoins >= coins then
                curCoins = coins

                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 0.6, sy = 0.6}, 578)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                    self.m_startCoins = coins
                end
                if self.m_JumpSound then
                -- gLobalSoundManager:stopAudio(self.m_JumpSound)
                -- self.m_JumpSound = nil
                -- self.m_JumpOver = gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_jackpot_over.mp3")
                end
            else
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node, sx = 0.6, sy = 0.6}, 578)
            end
        end
    )
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                self.m_startCoins = coins
                if self.m_JumpSound then
                -- gLobalSoundManager:stopAudio(self.m_JumpSound)
                -- self.m_JumpSound = nil
                -- self.m_JumpOver = gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_jackpot_over.mp3")
                end
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins, 50))
            self:updateLabelSize({label = node, sx = 0.6, sy = 0.6}, 578)
        end,
        3
    )
end

--停止
function AfricaRiseMiniMachine:coinsJumpOver()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
        self.m_startCoins = self.m_BonusWinCoin
        local node = self:findChild("m_lb_coins")
        node:setString(util_formatCoins(self.m_BonusWinCoin, 50))
        self:updateLabelSize({label = node, sx = 0.6, sy = 0.6}, 578)
    end
end

function AfricaRiseMiniMachine:setWinCoins(_winNum)
    if _winNum > 0 then
        self.m_bFirstWin = false
        self:runCsbAction("idleframe2", false)
        local node = self:findChild("m_lb_coins")
        node:setString(util_formatCoins(_winNum, 50))
        self:updateLabelSize({label = node, sx = 0.6, sy = 0.6}, 578)
        self.m_startCoins = _winNum
    end
end

function AfricaRiseMiniMachine:playUpChooseEffect()
    if self.m_iWinTag ~= nil then
        local _type = upReelData[self.m_iWinTag]
        self.m_upTip:playChooseEffect(_type)
        self.m_upTip:setEffectVisible(false)
    end
end

--赢钱线计算及表现
function AfricaRiseMiniMachine:playChooseEffect()
    self:playUpChooseEffect()
    if self.m_iWinTag ~= nil then
        local reelsData = self.m_runSpinResultData.p_reels[1]
        local _type = upReelData[self.m_iWinTag]
        if _type == self.SYMBOL_SYMBOL_EXIT then
            self.m_eff:setVisible(true)
        end
        local isHave = false
        for i = 1, #reelsData do
            if _type == reelsData[i] then
                isHave = true
                local eff = util_createView("CodeAfricaRiseSrc.AfricaRiseBonusWinFrame", 3)
                self:findChild("frame_" .. i):addChild(eff)
                eff:runCsbAction("actionframe0", true)
                table.insert(self.m_winFramList, eff)
                eff:setVisible(false)
            end
        end
        if isHave then
            self.m_winLineNum = self.m_winLineNum + 1
        end
    end
    local winType = self.m_runSpinResultData.p_selfMakeData.rollerIndex
    if winType then
        local startIndex = 1
        local endIndex = 1
        -- print("AfricaRise 中奖线winType类型 ===== " .. winType)
        if winType == "1111" then
            endIndex = 4
            self.m_winLineNum = self.m_winLineNum + 1
        elseif winType == "1110" then
            endIndex = 3
            self.m_winLineNum = self.m_winLineNum + 1
        elseif winType == "1011" then
            startIndex = 2
            endIndex = 4
            self.m_winLineNum = self.m_winLineNum + 1
        else
            return
        end
        for i = startIndex, endIndex do
            local eff = util_createView("CodeAfricaRiseSrc.AfricaRiseBonusWinFrame", 3)
            self:findChild("frame_" .. i):addChild(eff)
            eff:runCsbAction("actionframe0", true)
            table.insert(self.m_winLineFrame, eff)
            eff:setVisible(false)
        end
    end
end

--开始减速
function AfricaRiseMiniMachine:beginEndUpdata()
    scheduler.performWithDelayGlobal(
        function()
            self:updateEndSymbol()
        end,
        self.m_updataTime,
        "AfricaRiseMini"
    )
end

--开始减速滚动
function AfricaRiseMiniMachine:updateEndSymbol()
    local num = self.m_iStartNum - self.m_EndNum
    if num == 0 then
        num = 24
    elseif num < 0 then
        num = 24 + self.m_iStartNum - self.m_EndNum
    end
    self.m_updataSymbol[num]:runAnim("idle2", false)
    self.m_EndNum = self.m_EndNum - 1
    if self.m_EndNum <= 0 then
        -- self:updateNetWorkData()
        self.m_updataTime = 0.1
        self.m_iStartNum = self.m_iStartNum + 1
        if self.m_iStartNum > #self.m_updataSymbol then
            self.m_iStartNum = 1
        end
        self:beginSubSpeedUpdata()
        return
    end
    self:beginEndUpdata()
end

--单个滚动
function AfricaRiseMiniMachine:beginSubSpeedUpdata()
    scheduler.performWithDelayGlobal(
        function()
            self:updateSubSpeedSymbol()
        end,
        self.m_updataTime,
        "AfricaRiseMini"
    )
end

--单个减速滚动及停止
function AfricaRiseMiniMachine:updateSubSpeedSymbol()
    self.m_updataTime = self.m_updataTime + 0.3
    if self.m_iStartNum == self.m_iWinTag then
        local num = self.m_iStartNum - 1
        if num == 0 then
            num = 24
        end
        self.m_updataSymbol[num]:runAnim("idle2", false)
        self.m_updataSymbol[self.m_iStartNum]:runAnim("idleframe2", false)

        self.m_eff = util_createView("CodeAfricaRiseSrc.AfricaRiseBonusWinFrame", 2)
        local node = self:findChild("icon_" .. self.m_iWinTag)
        local pos = cc.p(node:getPosition())
        self.m_eff:setPosition(pos)
        self:findChild("Node_1"):addChild(self.m_eff)
        self.m_eff:runCsbAction("animation0", true)
        self.m_eff:setScale(0.65)
        self:updateNetWorkData()
        gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_pamadeng.mp3")
        return
    end

    local num = self.m_iStartNum - 1
    if num == 0 then
        num = 24
    end
    self.m_updataSymbol[num]:runAnim("idle2", false)
    self.m_updataSymbol[self.m_iStartNum]:runAnim("idleframe2", false)
    self.m_iStartNum = self.m_iStartNum + 1
    if self.m_iStartNum > #self.m_updataSymbol then
        self.m_iStartNum = 1
    end
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_pamadeng.mp3")
    self:beginSubSpeedUpdata()
end

function AfricaRiseMiniMachine:isSlow()
    if self.m_iWinTag == nil then
        return false
    end
    local endNum = self.m_iWinTag - 3
    if endNum == 0 then
        endNum = 24
    elseif endNum < 0 then
        endNum = 24 + self.m_iWinTag - 3
    end
    if self.m_iStartNum == endNum then
        return true
    else
        return false
    end
end

function AfricaRiseMiniMachine:updateWinSymbol()
    if self:isSlow() then
        self.m_EndNum = 5
        self.m_bUpdataWin = false
        self.m_updataSymbol[self.m_iStartNum]:runAnim("idleframe2", false)
        gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_pamadeng.mp3")
        self.m_updataTime = 0.02
        self:beginEndUpdata()
        return
    end
    if self.m_updataTime > 0.04 and self.m_bresult == false then
        self.m_updataTime = self.m_updataTime - 0.01
    end
    local subNum = 0
    for i = 1, 4 do
        local num = self.m_iStartNum - i
        if num == 0 then
            num = 24
            subNum = subNum + 1
        elseif num < 0 then
            num = 24 - subNum
            subNum = subNum + 1
        end
        if i == 4 then
            self.m_updataSymbol[num]:runAnim("idle2", false)
        end
    end
    self.m_updataSymbol[self.m_iStartNum]:runAnim("idleframe2", false)
    self.m_iStartNum = self.m_iStartNum + 1
    if self.m_iStartNum > #self.m_updataSymbol then
        self.m_iStartNum = 1
    end
    self.m_updataSymbol[self.m_iStartNum]:runAnim("idleframe2", false)
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_pamadeng.mp3")
    self:beginUpdate()
end

function AfricaRiseMiniMachine:showLineFrameEffect()
    local frameIndex = 1

    self:showLineFrameByIndex(frameIndex)
    local function showLienFrameByIndex()
        self.m_showLineHandlerID =
            scheduler.scheduleGlobal(
            function()
                if frameIndex > self.m_winLineNum then
                    frameIndex = 1
                    if self.m_showLineHandlerID ~= nil then
                        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                        self.m_showLineHandlerID = nil
                    end
                    showLienFrameByIndex()
                    return
                else
                    self:showLineFrameByIndex(frameIndex)
                    frameIndex = frameIndex + 1
                end
            end,
            2,
            self:getModuleName()
        )
    end
    showLienFrameByIndex()
end

function AfricaRiseMiniMachine:showLineFrameByIndex(frameIndex)
    if frameIndex == 1 then
        if self.m_winLineNum == 1 then
            if #self.m_winFramList > 0 then
                self:showWinLine1(true)
                return
            end
            if #self.m_winLineFrame > 0 then
                self:showWinLine2(true)
            end
        else
            if #self.m_winFramList > 0 then
                self:showWinLine1(true)
            end
            self:showWinLine2(false)
        end
    else
        self:showWinLine1(false)
        self:showWinLine2(true)
    end
end

function AfricaRiseMiniMachine:showWinLine1(_bShow)
    if #self.m_winFramList > 0 then
        for i = 1, #self.m_winFramList do
            local eff = self.m_winFramList[i]
            eff:setVisible(_bShow)
        end
        -- self.m_eff:setVisible(_bShow)
        self.m_upTip:setEffectVisible(_bShow)
        self.m_eff:runCsbAction("animation0", true)
        self.m_upTip:playEff()
    end
end

function AfricaRiseMiniMachine:showWinLine2(_bShow)
    if #self.m_winLineFrame > 0 then
        for i = 1, #self.m_winLineFrame do
            local eff = self.m_winLineFrame[i]
            eff:setVisible(_bShow)
        end
    end
end

function AfricaRiseMiniMachine:setWinSymbol(_endIndex)
    self.m_updataTime = 0.01
    self.m_bresult = true
    self.m_iWinTag = _endIndex + 1
end

function AfricaRiseMiniMachine:setBonusWinCoin(winCoin)
    self.m_BonusWinCoin = winCoin
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function AfricaRiseMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniFastMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_WILD_X, count = 5}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SPIN_ADD, count = 5}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

function AfricaRiseMiniMachine:addSelfEffect()
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.EFFECT_CHOOSE_SYMBOL

    if self.m_bonusLeftCount <= 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SHOW_BONUS_OVER
    end
end

function AfricaRiseMiniMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_SHOW_BONUS_OVER then
        self:playShowBonusOverEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_CHOOSE_SYMBOL then
        if self.m_runSpinResultData.p_selfMakeData then
            local _type = upReelData[self.m_iWinTag]
            if _type == self.SYMBOL_SYMBOL_EXIT then
                self:UpdataSpinCount()
            end
            self:playChooseEffect()
            self:showLineFrameEffect()
            scheduler.performWithDelayGlobal(
                function()
                    if self.m_BonusWinCoin - self.m_startCoins > 0 then
                        if self.m_bFirstWin == true then
                            self.m_bFirstWin = false
                            self:runCsbAction(
                                "actionframe",
                                false,
                                function()
                                    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_bonus_win.mp3")
                                    self:updateWinCoins()
                                end
                            )
                        else
                            gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_bonus_win.mp3")
                            self:updateWinCoins()
                        end
                    end
                    effectData.p_isPlay = true
                    self:playGameEffect()
                    self.m_iWinTag = nil
                end,
                1.5,
                self:getModuleName()
            )
        end
    end

    return true
end

function AfricaRiseMiniMachine:playShowBonusOverEffect(effectData)
    scheduler.performWithDelayGlobal(
        function()
            if self.m_bonusLeftCount <= 0 then
                self.m_parent:showBonusGameOver(
                    function()
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            end
        end,
        2.0,
        self:getModuleName()
    )
end

function AfricaRiseMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function AfricaRiseMiniMachine:checkNotifyUpdateWinCoin()
    -- 这里作为freespin下 连线时通知钱数更新的接口

    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_parent.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

-- ---
-- 每个reel条滚动到底
function AfricaRiseMiniMachine:slotOneReelDown(reelCol)
    BaseMiniFastMachine.slotOneReelDown(self, reelCol)
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_reel_stop.mp3")
end

function AfricaRiseMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function AfricaRiseMiniMachine:playEffectNotifyNextSpinCall()
    local delayTime = 0
    if (self.m_parent.m_iOnceSpinLastWin or 0) > 0 then
        delayTime = 1.5
    end

    performWithDelay(
        self,
        function()
            self.m_parent:playEffectNotifyNextSpinCall()
            self.m_panelTouchFlag = true
        end,
        delayTime
    )
end

function AfricaRiseMiniMachine:addObservers()
    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = self.m_pauseRef + 1
            Target:pauseMachine()
        end,
        ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            self.m_pauseRef = math.max(self.m_pauseRef - 1, 0)
            if self.m_pauseRef <= 0 then
                Target:resumeMachine()
            end
        end,
        ViewEventType.NOTIFY_RESUME_SLOTSMACHINE
    )
end

function AfricaRiseMiniMachine:onExit()
    BaseMiniFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()
    scheduler.unschedulesByTargetName(self:getModuleName())
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function AfricaRiseMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
    self.m_parent:requestSpinReusltData()
end

function AfricaRiseMiniMachine:beginMiniReel()
    self.m_panelTouchFlag = false
    BaseMiniFastMachine.beginReel(self)
    self:startUpdate()
    if self.m_bFirstClick then
        self.m_bFirstClick = false
        self:changeReelView()
    end
end

function AfricaRiseMiniMachine:setBonusLeftTimes(times)
    self.m_bonusLeftCount = times
end

-- 消息返回更新数据
function AfricaRiseMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    self.m_bonusLeftCount = self.m_runSpinResultData.p_selfMakeData.currCell.ext
    self.m_bonusResult = spinResult.selfData.bonusResult
    performWithDelay(
        self,
        function()
            if self.m_runSpinResultData.p_selfMakeData.turntableIndex then
                local endIndex = self.m_runSpinResultData.p_selfMakeData.turntableIndex
                self:setWinSymbol(endIndex)
            -- self.m_effectData = effectData
            end
        end,
        2
    )
end

function AfricaRiseMiniMachine:UpdataSpinCount()
    self.m_miniBar:UpdataSpinCount(self.m_bonusLeftCount)
    if self.m_bonusLeftCount == 0 and globalData.slotRunData.currSpinMode == SPECIAL_SPIN_MODE then
        globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
    end
end

function AfricaRiseMiniMachine:UpdataTotalBetNum(_num)
    self.m_miniBar:UpdataTotalBetNum(_num)
end

function AfricaRiseMiniMachine:initHasFeature()
    self:checkUpateDefaultBet()
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self:initCloumnSlotNodesByNetData()
end

function AfricaRiseMiniMachine:initNoneFeature()
    if globalData.GameConfig:checkSelectBet() then
        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questConfig and questConfig.m_IsQuestLogin then
            --quest进入也使用服务器bet
        else
            if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest()then
                --quest进入也使用服务器bet
            else
                self.m_initBetId = -1
            end
        end
    end
    self:checkUpateDefaultBet()
    -- 直接使用 关卡bet 选择界面的bet 来使用
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    self:initRandomSlotNodes()
end

function AfricaRiseMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_parent:setNormalAllRunDown()
end
function AfricaRiseMiniMachine:dealSmallReelsSpinStates()
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
    -- do nothing
end

function AfricaRiseMiniMachine:setStoredIcons(storedIcons)
    self.m_runSpinResultData.p_storedIcons = storedIcons
end

function AfricaRiseMiniMachine:initSlotNode(reels)
    self.m_runSpinResultData.p_reels = reels
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false

        while rowIndex >= 1 do
            local rowDatas = reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1

            local parentData = self.m_slotParents[colIndex]
            parentData.m_isLastSymbol = true
            if symbolType == -1 then
                -- body
                symbolType = 0
            end
            local node = self:getSlotNodeWithPosAndType(symbolType, changeRowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType)

            parentData.slotParent:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            node.p_symbolType = symbolType
            --            node.p_maxRowIndex = changeRowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((changeRowIndex - 1) * columnData.p_showGridH + halfNodeH)
            node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end
end
-- 处理特殊关卡 遮罩层级
function AfricaRiseMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
    local maxzorder = 0
    local zorder = 0
    for i = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder > maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

---
--设置bonus scatter 层级
function AfricaRiseMiniMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
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

function AfricaRiseMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function AfricaRiseMiniMachine:checkGameResumeCallFun()
    if self:checkGameRunPause() then
        self.gameResumeFunc = function()
            if self.playGameEffect then
                self:playGameEffect()
            end
        end
        return false
    end
    return true
end

function AfricaRiseMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function AfricaRiseMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function AfricaRiseMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

--小块
function AfricaRiseMiniMachine:getBaseReelGridNode()
    return "CodeAfricaRiseSrc.AfricaRiseSlotsNode"
end

---
-- 清空掉产生的数据
--
function AfricaRiseMiniMachine:clearSlotoData()
    -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then
        for i = #self.m_lineDataPool, 1, -1 do
            self.m_lineDataPool[i] = nil
        end
    end
end

function AfricaRiseMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniFastMachine.setSlotCacheNodeWithPosAndType(self, node, symbolType, row, col, isLastSymbol)
    if node:isLastSymbol() then
        node:changeImage()
    end
end

function AfricaRiseMiniMachine:randomSlotNodes()
    for colIndex = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        for rowIndex = 1, rowCount do
            local symbolType = self:getRandomReelType(colIndex, reelDatas)
            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            local slotParentBig = parentData.slotParentBig
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            else
                parentData.slotParent:addChild(node, node.p_showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
            end

            --            node.p_maxRowIndex = rowIndex
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * columnData.p_showGridH + halfNodeH)
        end
    end
end

function AfricaRiseMiniMachine:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        for rowIndex = 1, resultLen do
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]
            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getCacheNode(colIndex, symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, true)
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                local tmpSymbolType = self:convertSymbolType(symbolType)
                node:setVisible(true)
                node:setLocalZOrder(showOrder - rowIndex)
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
                node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
                self:setSlotCacheNodeWithPosAndType(node, symbolType, rowIndex, colIndex, false)
            end
            node.p_slotNodeH = reelColData.p_showGridH

            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)

            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)
        end
    end
end

return AfricaRiseMiniMachine
