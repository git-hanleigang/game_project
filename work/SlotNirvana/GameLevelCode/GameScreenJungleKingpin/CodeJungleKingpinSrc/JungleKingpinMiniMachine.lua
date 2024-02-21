---
-- xcyy
-- 2018-12-18
-- JungleKingpinMiniMachine.lua
--
--

local BaseMiniFastMachine = require "Levels.BaseMiniFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local JungleKingpinSlotFastNode = require "CodeJungleKingpinSrc.JungleKingpinSlotFastNode"

local JungleKingpinMiniMachine = class("JungleKingpinMiniMachine", BaseMiniFastMachine)

JungleKingpinMiniMachine.SYMBOL_BLANK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 107
JungleKingpinMiniMachine.SYMBOL_BIG_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 108
JungleKingpinMiniMachine.SYMBOL_BIG_WILD_GOLD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 109

JungleKingpinMiniMachine.EFFECT_DROP_BANANA = GameEffect.EFFECT_SELF_EFFECT - 1 --掉落香蕉
JungleKingpinMiniMachine.EFFECT_SHOW_BONUS_OVER = GameEffect.EFFECT_SELF_EFFECT - 2 --

JungleKingpinMiniMachine.m_machineIndex = nil -- csv 文件模块名字

JungleKingpinMiniMachine.gameResumeFunc = nil
JungleKingpinMiniMachine.gameRunPause = nil

--banana droppin' feature 玩法中的奖励类型
local BONUS_TYPE = {
    BONUS_NORMAL_TYPE = 1, --金币奖励
    BONUS_MINI_TYPE = 2,
    --香蕉最小奖励
    BONUS_MAX_TYPE = 3, --香蕉最大奖励
    BONUS_MINOR_TYPE = 4, --minor
    BONUS_MAJOR_TYPE = 5,
    --major
    BONUS_GRAND_TYPE = 6 --grand
}

-- 构造函数
function JungleKingpinMiniMachine:ctor()
    BaseMiniFastMachine.ctor(self)
end

function JungleKingpinMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_machineIndex = data.index
    self.m_parent = data.parent
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function JungleKingpinMiniMachine:initGame()
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function JungleKingpinMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "JungleKingpin"
end

function JungleKingpinMiniMachine:getlevelConfigName()
    local levelConfigName = "LevelJungleKingpinMiniConfig.lua"

    return levelConfigName
end

function JungleKingpinMiniMachine:getMachineConfigName()
    local str = "Mini"
    return self.m_moduleName .. str .. "Config" .. ".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function JungleKingpinMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil
    if symbolType == self.SYMBOL_BLANK then
        return "Socre_JungleKingpin_Blank"
    elseif symbolType == self.SYMBOL_BIG_WILD then
        return "Socre_JungleKingpin_WildBig"
    elseif symbolType == self.SYMBOL_BIG_WILD_GOLD then
        return "Socre_JungleKingpin_BonusWildBig"
    end
    return ccbName
end

---
-- 读取配置文件数据
--
function JungleKingpinMiniMachine:readCSVConfigData()
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), self:getlevelConfigName())
    end
    globalData.slotRunData.levelConfigData = self.m_configData
end

function JungleKingpinMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("JungleKingpin/GameScreenJungleKingpin2.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function JungleKingpinMiniMachine:initMachine()
    self.m_moduleName = "JungleKingpin" -- self:getModuleName()

    BaseMiniFastMachine.initMachine(self)
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function JungleKingpinMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniFastMachine:getPreLoadSlotNodes()
    -- loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_FIX_SYMBOL, count = 3}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BLANK, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_WILD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_WILD_GOLD, count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

function JungleKingpinMiniMachine:addSelfEffect()
    if self:isTriggerDropBanana() then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_DROP_BANANA
    end

    if self.m_bonusLeftCount <= 0 then
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_SHOW_BONUS_OVER
    end
end

function JungleKingpinMiniMachine:isTriggerDropBanana()
    for i, v in ipairs(self.m_bonusResult) do
        if v.type > 0 then
            return true
        end
    end
    return false
end

function JungleKingpinMiniMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_DROP_BANANA then
        self:playDropBananaEffect(effectData)
    elseif effectData.p_selfEffectType == self.EFFECT_SHOW_BONUS_OVER then
        self:playShowBonusOverEffect(effectData)
    end

    return true
end

function JungleKingpinMiniMachine:playDropBananaEffect(effectData)
    self.m_parent:playDropBananaEffect(
        self.m_bonusResult,
        function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end
    )
end

--获取掉落的终点
function JungleKingpinMiniMachine:getMoveEndPos(_index)
    local node = self:findChild("ReelEnd" .. _index)
    local pos = cc.p(0, 0)
    if node then
        pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    end
    return pos
end

--播放吃香蕉的效果
function JungleKingpinMiniMachine:showEatAnimal(_index)
    local targSp = self:getReelParent(_index):getChildByTag(self:getNodeTag(_index, 1, SYMBOL_NODE_TAG))
    if targSp and targSp.p_symbolType ~= self.SYMBOL_BLANK then
        targSp:runAnim("chixiangjiao", false)
    -- gLobalSoundManager:playSound("PirateSounds/sound_pirate_scatter2.mp3")
    end
end

function JungleKingpinMiniMachine:getEatCoinsPos(_index)
    local node = self:findChild("ReelEnd" .. _index)
    local pos = cc.p(0, 0)
    if node then
        pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    end
    return cc.p(pos.x, pos.y - 80)
end

--播放吃香蕉的效果
function JungleKingpinMiniMachine:getBigWildType(_index)
    local targSp = self:getReelParent(_index):getChildByTag(self:getNodeTag(_index, 1, SYMBOL_NODE_TAG))
    if targSp and targSp.p_symbolType ~= self.SYMBOL_BLANK then
        return targSp.p_symbolType
    end
    return self.SYMBOL_BLANK
end

function JungleKingpinMiniMachine:playShowBonusOverEffect(effectData)
    if self.m_bonusLeftCount <= 0 then
        self.m_parent:showBonusGameOver(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end
end

function JungleKingpinMiniMachine:showJackpot()
end

function JungleKingpinMiniMachine:onEnter()
    BaseMiniFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function JungleKingpinMiniMachine:checkNotifyUpdateWinCoin()
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

---
-- 每个reel条滚动到底
function JungleKingpinMiniMachine:slotOneReelDown(reelCol)
    BaseMiniFastMachine.slotOneReelDown(self, reelCol)
    local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, 1, SYMBOL_NODE_TAG))
    -- if targSp and targSp.p_symbolType ~= self.SYMBOL_BLANK then
    --      gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_bonus_ground.mp3")
    -- end
    if reelCol == 3 then
        scheduler.performWithDelayGlobal(
            function()
                for i = 1, 3 do
                    local targSp = self:getReelParent(i):getChildByTag(self:getNodeTag(i, 1, SYMBOL_NODE_TAG))
                    if targSp and targSp.p_symbolType ~= self.SYMBOL_BLANK then
                        targSp:runAnim(
                            "buling",
                            false,
                            function()
                                targSp:runAnim("idleframe2", true)
                            end
                        )
                    -- gLobalSoundManager:playSound("PirateSounds/sound_pirate_scatter2.mp3")
                    end
                end
            end,
            1,
            self:getModuleName()
        )
    end

    local soundPath = "JungleKingpinSounds/sound_JungleKingpin_reel_stop.mp3"
    if self.playBulingSymbolSounds then
        self:playBulingSymbolSounds( reelCol,soundPath )
    else
        gLobalSoundManager:playSound(soundPath)
    end

end

function JungleKingpinMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function JungleKingpinMiniMachine:playEffectNotifyNextSpinCall()
    local delayTime = 0
    if (self.m_parent.m_iOnceSpinLastWin or 0) > 0 then
        delayTime = 1.5
    end

    if self.m_bonusLeftCount == 8 then
        delayTime = 0.5
    end

    performWithDelay(
        self,
        function()
            self.m_parent:playEffectNotifyNextSpinCall()
        end,
        delayTime
    )
end

function JungleKingpinMiniMachine:onExit()
    BaseMiniFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function JungleKingpinMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)
    self.m_parent:requestSpinReusltData()
end

function JungleKingpinMiniMachine:beginMiniReel()
    BaseMiniFastMachine.beginReel(self)
end

function JungleKingpinMiniMachine:setBonusLeftTimes(times)
    self.m_bonusLeftCount = times
    self:UpdataSpinCount()
end

-- 消息返回更新数据
function JungleKingpinMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)
    -- self.m_bonusLeftCount = spinResult.bonusLeftCount
    self.m_bonusResult = spinResult.selfData.bonusResult
    self:updateNetWorkData()
end
function JungleKingpinMiniMachine:UpdataSpinCount()
    self:findChild("BitmapFontLabel_1"):setString(self.m_bonusLeftCount)
    if self.m_bonusLeftCount == 0 and globalData.slotRunData.currSpinMode == SPECIAL_SPIN_MODE then
        globalData.slotRunData.currSpinMode = NORMAL_SPIN_MODE
    end
end

function JungleKingpinMiniMachine:initHasFeature()
    self:checkUpateDefaultBet()
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self:initCloumnSlotNodesByNetData()
end

function JungleKingpinMiniMachine:initNoneFeature()
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

function JungleKingpinMiniMachine:playEffectNotifyChangeSpinStatus()
    self.m_parent:setNormalAllRunDown()
end

function JungleKingpinMiniMachine:dealSmallReelsSpinStates()
    -- do nothing
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
end

function JungleKingpinMiniMachine:setStoredIcons(storedIcons)
    self.m_runSpinResultData.p_storedIcons = storedIcons
end
function JungleKingpinMiniMachine:initSlotNode(reels)
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
function JungleKingpinMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
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
function JungleKingpinMiniMachine:getBounsScatterDataZorder(symbolType)
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

function JungleKingpinMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function JungleKingpinMiniMachine:checkGameResumeCallFun()
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

function JungleKingpinMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function JungleKingpinMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function JungleKingpinMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

--小块
function JungleKingpinMiniMachine:getBaseReelGridNode()
    return "CodeJungleKingpinSrc.JungleKingpinSlotFastNode"
end

---
-- 清空掉产生的数据
--
function JungleKingpinMiniMachine:clearSlotoData()
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

function JungleKingpinMiniMachine:checkControlerReelType()
    return false
end

return JungleKingpinMiniMachine
