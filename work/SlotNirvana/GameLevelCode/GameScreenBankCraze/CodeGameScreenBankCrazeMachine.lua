---
-- island li
-- 2019年1月26日
-- CodeGameScreenBankCrazeMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseSlotoManiaMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseDialog = util_require("Levels.BaseDialog")
local PublicConfig = require "BankCrazePublicConfig"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenBankCrazeMachine = class("CodeGameScreenBankCrazeMachine", BaseSlotoManiaMachine)

CodeGameScreenBankCrazeMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_10 = 9
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_TRIGGER_BONUS_1 = 94  -- 最后一出现，长条bonus--铜色
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_COINS_BONUS = 95  -- 带钱的bonus
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_JACKPOT_CHANGE = 96 -- 假滚专用
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_FREE_BONUS = 97   -- 带free次数的
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_SAVE_BONUS = 98   -- 带save的，用于收集
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_JACKPOT_MINI = 101   -- mini
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_JACKPOT_MINOR = 102   -- minor
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_JACKPOT_MAJOR = 103   -- major
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_JACKPOT_GRAND = 104   -- grand

CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_TRIGGER_BONUS_2 = 105  -- 最后一列出现，长条bonus--银色-本地自定义
CodeGameScreenBankCrazeMachine.SYMBOL_SCORE_TRIGGER_BONUS_3 = 106  -- 最后一列出现，长条bonus--金色-本地自定义

-- 自定义动画的标识
-- Bonus玩法优先顺序为Collect、Credit、Jackpot、Free
CodeGameScreenBankCrazeMachine.EFFECT_BONUS_OVER_PLAY = GameEffect.EFFECT_SELF_EFFECT - 3 -- bonus玩法弹板选完后重置
CodeGameScreenBankCrazeMachine.EFFECT_COLLECT_JACKPOT_PLAY = GameEffect.EFFECT_SELF_EFFECT - 4 -- 收集coinsBonus
CodeGameScreenBankCrazeMachine.EFFECT_COLLECT_COINS_PLAY = GameEffect.EFFECT_SELF_EFFECT - 5 -- 收集coinsBonus
CodeGameScreenBankCrazeMachine.EFFECT_COLLECT_SAVE_PLAY = GameEffect.EFFECT_SELF_EFFECT - 6 -- 收集saveBonus
CodeGameScreenBankCrazeMachine.EFFECT_TRIGGER_ALL_BONUS_PLAY = GameEffect.EFFECT_SELF_EFFECT - 7 -- 所有bonus触发动画

-- 构造函数
function CodeGameScreenBankCrazeMachine:ctor()
    CodeGameScreenBankCrazeMachine.super.ctor(self)

    self.m_spinRestMusicBG = true
    self.m_publicConfig = PublicConfig
    self.m_isFeatureOverBigWinInFree = true

    -- 大赢光效
    self.m_isAddBigWinLightEffect = true

    -- 触发玩法前连线时间
    self.m_delayTime = 0
    -- 当前银行等级
    self.m_curBankLevel = 1
    -- 保存当前触发了几个玩法
    self.m_curTriggerPlayTbl = {}
    --init
    self:initGame()
end

function CodeGameScreenBankCrazeMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("BankCrazeConfig.csv", "LevelBankCrazeConfig.lua")
    self.m_configData.m_machine = self

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBankCrazeMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BankCraze"  
end

function CodeGameScreenBankCrazeMachine:getBottomUINode()
    return "CodeBankCrazeSrc.BankCrazeBottomNode"
end

function CodeGameScreenBankCrazeMachine:initUI()
    --free特效层
    self.m_effectFixdNode = cc.Node:create()
    self.m_clipParent:addChild(self.m_effectFixdNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE - 1)

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar
    self:initJackPotBarView() 

    --上边收集背景栏
    self.m_topBarView = util_createView("CodeBankCrazeCollectSrc.BankCrazeTopBarView", self)
    self:findChild("Node_jindutiao"):addChild(self.m_topBarView, 20)

    -- bonus按钮
    self.m_bonusBtnView = util_createView("CodeBankCrazeBonusSrc.BankCrazeBonusBtnView", self)
    self:findChild("Node_btn_bonus"):addChild(self.m_bonusBtnView)

    -- bonusTips
    self.m_bonusTipsView = util_createView("CodeBankCrazeBonusSrc.BankCrazeBonusTipsView", self)
    self:findChild("Node_btn_bonus"):addChild(self.m_bonusTipsView)
    self.m_bonusTipsView:setVisible(false)

    -- 收集tips
    self.m_collectTipsView = util_createView("CodeBankCrazeCollectSrc.BankCrazeCollectTipsView", self)
    self:findChild("Jindutiao_wenan"):addChild(self.m_collectTipsView)
    self.m_collectTipsView:setVisible(false)

    -- 升降级文案
    self.m_bankTipsView = util_createView("CodeBankCrazeCollectSrc.BankCrazeBankTipsView", self)
    self:findChild("Bank_wenan"):addChild(self.m_bankTipsView)
    self.m_bankTipsView:setVisible(false)

    -- 奖励选择弹板
    self.m_chooseRewardView = util_createView("CodeBankCrazeBonusSrc.BankCrazeChooseRewardView", self)
    self:addChild(self.m_chooseRewardView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_chooseRewardView:setVisible(false)
    self.m_chooseRewardView:scaleMainLayer(self.m_machineRootScale)

    -- reel条
    self.m_reelBg = {}
    self.m_reelBg[1] = self:findChild("base_reel")
    self.m_reelBg[2] = self:findChild("free_reel")

    -- 背景
    self.m_bgType = {}
    self.m_bgType[1] = self.m_gameBg:findChild("Node_baseBg")
    self.m_bgType[2] = self.m_gameBg:findChild("Node_freeBG")

    --触发bonus玩法遮罩
    self.m_maskAni = util_createAnimation("BankCraze_mask.csb")
    self.m_onceClipNode:addChild(self.m_maskAni, 10000)
    self.m_maskAni:setVisible(false)

    self.m_bottomUI:changeCoinWinEffectUI(self:getModuleName(), "BankCraze_totalwin.csb")

    -- 最顶部光效层
    self.m_topEffectNode = self:findChild("Node_topEffect")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:addClick(self:findChild("Panel_click"))

    self:changeBgAndReelBg(1)
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CodeGameScreenBankCrazeMachine:initSpineUI()
    -- 大赢
    local worldPos = util_convertToNodeSpace(self.m_bottomUI:findChild("win_txt"), self)
    self.m_bigWinSpine = util_spineCreate("BankCraze_bigwin",true,true)
    self.m_bigWinSpine:setScale(self.m_machineRootScale)
    self.m_bigWinSpine:setPosition(worldPos)
    self:addChild(self.m_bigWinSpine, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM - 1)
    self.m_bigWinSpine:setVisible(false)

    -- 大赢棋盘下
    self.m_bigWinBottomSpine = util_spineCreate("BankCraze_bigwin",true,true)
    self:findChild("Node_bigwin"):addChild(self.m_bigWinBottomSpine)
    self.m_bigWinBottomSpine:setVisible(false)

    -- 入场动画
    self.m_enterGameSpineTbl = {}
    local enterSpineNameTbl = {"BankCraze_bg", "Socre_BankCraze_9", "Socre_BankCraze_8", "Socre_BankCraze_7"}
    local nodePosX, nodePosY = self:findChild("Node_cutScene"):getPosition()
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(nodePosX, nodePosY))
    for index, spineName in pairs(enterSpineNameTbl) do
        self.m_enterGameSpineTbl[index] = util_spineCreate(spineName,true,true)
        local curZorder = GAME_LAYER_ORDER.LAYER_ORDER_UI + index + 1
        self:addChild(self.m_enterGameSpineTbl[index], curZorder)
        self.m_enterGameSpineTbl[index]:setPosition(worldPos)
        self.m_enterGameSpineTbl[index]:setScale(self.m_machineRootScale)
        self.m_enterGameSpineTbl[index]:setVisible(false)
    end

    -- 入场动画下边遮罩，防止点击穿透
    self.m_topMaskAni = util_createAnimation("BankCraze_TopMask.csb")
    self:addChild(self.m_topMaskAni, GAME_LAYER_ORDER.LAYER_ORDER_UI + 1)
    self.m_topMaskAni:setPosition(worldPos)
    self.m_topMaskAni:setVisible(false)

    -- 上边的银行
    self.m_topBankNodeTbl = {}
    self.m_bankSymbolTypeTbl = {self.SYMBOL_SCORE_TRIGGER_BONUS_1, self.SYMBOL_SCORE_TRIGGER_BONUS_2, self.SYMBOL_SCORE_TRIGGER_BONUS_3}
    for index, symbolType in pairs(self.m_bankSymbolTypeTbl) do
        self.m_topBankNodeTbl[index] = self:createBankCrazeSymbol(symbolType)
        self:findChild("Node_bank"):addChild(self.m_topBankNodeTbl[index])
        self.m_topBankNodeTbl[index]:runAnim("bace_idle", true)
        self.m_topBankNodeTbl[index]:setVisible(false)
    end

    -- more加成提示板(20%银色)
    local silverBankSpine = self.m_topBankNodeTbl[2]:getNodeSpine()
    self.m_moreSilverTipsView = util_createView("CodeBankCrazeBonusSrc.BankCrazeBonusMoreTipsView", self)
    util_spinePushBindNode(silverBankSpine,"bonus5_lou2_paizi",self.m_moreSilverTipsView)
    self.m_moreSilverTipsView:setVisible(false)

    -- more加成提示板(50%金色)
    local goldBankSpine = self.m_topBankNodeTbl[3]:getNodeSpine()
    self.m_moreGoldTipsView = util_createView("CodeBankCrazeBonusSrc.BankCrazeBonusMoreTipsView", self, true)
    util_spinePushBindNode(goldBankSpine,"bonus5_lou3_paizi",self.m_moreGoldTipsView)
    self.m_moreGoldTipsView:setVisible(false)

    -- 预告中奖
    self.m_yuGaoSpine = util_spineCreate("BankCraze_yugao",true,true)
    self:findChild("Node_cutScene"):addChild(self.m_yuGaoSpine, 10)
    self.m_yuGaoSpine:setVisible(false)

    -- base-free过场
    local baseToFreeSpineNameTbl = {"Socre_BankCraze_7", "BankCraze_chaopiao", "BankCraze_bg"}
    self.m_baseToFreeSpineTbl = {}
    for i=1, 3 do
        self.m_baseToFreeSpineTbl[i] = util_spineCreate(baseToFreeSpineNameTbl[i],true,true)
        self:findChild("Node_cutScene"):addChild(self.m_baseToFreeSpineTbl[i], 10-i)
        self.m_baseToFreeSpineTbl[i]:setVisible(false)
    end
    
    -- 收集钱more加成动画
    -- 1:20%--2:50%
    self.m_moreRoleSpineTbl = {}
    local moreRoleSpineNameTbl = {"Socre_BankCraze_8", "Socre_BankCraze_9"}
    for i, spineName in pairs(moreRoleSpineNameTbl) do
        self.m_moreRoleSpineTbl[i] = util_spineCreate(spineName,true,true)
        self:findChild("Node_jindutiao"):addChild(self.m_moreRoleSpineTbl[i], 5)
        self.m_moreRoleSpineTbl[i]:setVisible(false)
    end

    -- 金币
    self.m_moreCoinSpineTbl = {}
    local moreCoinSpineNameTbl = {"BankCraze_jinbi2", "BankCraze_jinbi1"}
    for i, spineName in pairs(moreCoinSpineNameTbl) do
        self.m_moreCoinSpineTbl[i] = util_spineCreate(spineName,true,true)
        self:findChild("Node_light"):addChild(self.m_moreCoinSpineTbl[i])
        self.m_moreCoinSpineTbl[i]:setVisible(false)
    end

    -- 加成more
    self.m_moreMulAni = util_createAnimation("BankCraze_chengbei_bao.csb")
    self:findChild("Node_more"):addChild(self.m_moreMulAni, 15)
    self.m_moreMulAni:setVisible(false)
end

function CodeGameScreenBankCrazeMachine:enterGamePlayMusic() 
    -- 入场动画
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and not self:getCurFeatureIsFree() then
        self:showEnterGameSpine()
    end
    self:delayCallBack(0.4,function()
        globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Enter_Game, 3, 0, 1)
    end)
end

-- 入场动画
function CodeGameScreenBankCrazeMachine:showEnterGameSpine()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})
    local isRunFunc = true
    self.m_topMaskAni:setVisible(true)
    for index, enterSpine in pairs(self.m_enterGameSpineTbl) do
        enterSpine:setVisible(true)
        util_spinePlay(enterSpine, "ruchang", false)
        util_spineEndCallFunc(enterSpine, "ruchang", function()
            if isRunFunc then
                isRunFunc = false
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,true})
            end
            self.m_topMaskAni:setVisible(false)
            enterSpine:setVisible(false)
        end)
    end
end

function CodeGameScreenBankCrazeMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBankCrazeMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()
    self:initGameUI()
end

function CodeGameScreenBankCrazeMachine:initGameUI()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:changeBgAndReelBg(2)
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        self.m_baseFreeSpinBar:setVisible(true)
        self:addFreeFixBigNode()
        self.m_bonusBtnView:setBtnState(false)
    end

    self.m_topBarView:refreshShowType(self:getCurrSpinMode() == FREE_SPIN_MODE)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local collectCount = 0
    -- 是否触发选择奖励弹板
    local triggerFlag = false
    if selfData and selfData.Bank then
        local bankData = selfData.Bank
        self.m_curBankLevel = bankData.BankLevel or 1
        collectCount = bankData.BankCollect

        -- 是否触发选择奖励弹板
        triggerFlag = bankData.TriggerFlag
        if triggerFlag then
            local endCallFunc = function()
                self:playGameEffect() 
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            self:showChooseView(endCallFunc)
        end
    end
    self.m_topBarView:collectSaveBonus(true, self.m_curBankLevel, collectCount)

    self:updateTopBankSpine()
    -- bonus按钮
    self:showBonusBtn()
    -- more加成tips
    self:showBonusMoreTips(true, triggerFlag)
end

-- 刷新显示银行等级
function CodeGameScreenBankCrazeMachine:updateTopBankSpine()
    for index, bankNode in pairs(self.m_topBankNodeTbl) do
        bankNode:setVisible(index == self.m_curBankLevel)
        bankNode:runAnim("bace_idle", true)
    end
end

-- bonus按钮
function CodeGameScreenBankCrazeMachine:showBonusBtn()
    if self.m_curBankLevel > 1 then
        self.m_bonusBtnView:playIdle()
    else
        self.m_bonusBtnView:playOver(true)
    end
end

-- 银行上边的moreTip加成
function CodeGameScreenBankCrazeMachine:showBonusMoreTips(_onEnter, _triggerFlag)
    if _triggerFlag then
        if self.m_curBankLevel == 3 then
            self.m_moreSilverTipsView:showStartMoreType(_onEnter)
        end
    else
        if self.m_curBankLevel == 3 then
            self.m_moreGoldTipsView:showStartMoreType(_onEnter)
        else
            self.m_moreSilverTipsView:showStartMoreType(_onEnter)
        end
    end
end

-- 设置金色和银色加成的状态
function CodeGameScreenBankCrazeMachine:setMoreTipsState(_state)
    self.m_moreSilverTipsView:setVisible(_state)
    self.m_moreGoldTipsView:setVisible(_state)
end

function CodeGameScreenBankCrazeMachine:addObservers()
    CodeGameScreenBankCrazeMachine.super.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        -- if self.m_bIsBigWin then
        --     return
        -- end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        local totalBet = self:getCurSpinStateBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 and winRate <= 6 then
            soundIndex = 3
        elseif winRate > 6 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = ""
        if self.m_bProduceSlots_InFreeSpin then
            soundName = self.m_publicConfig.SoundConfig["sound_BankCraze_free_winLines" .. soundIndex]
        else
            soundName = self.m_publicConfig.SoundConfig["sound_BankCraze_winLines" .. soundIndex]
        end
        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)
    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenBankCrazeMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBankCrazeMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

function CodeGameScreenBankCrazeMachine:scaleMainLayer()
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
                tempPosY = 3
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

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBankCrazeMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_BankCraze_10"
    elseif symbolType == self.SYMBOL_SCORE_TRIGGER_BONUS_1 then
        return "Socre_BankCraze_Bonus_Trigger1"
    elseif symbolType == self.SYMBOL_SCORE_TRIGGER_BONUS_2 then
        return "Socre_BankCraze_Bonus_Trigger2"
    elseif symbolType == self.SYMBOL_SCORE_TRIGGER_BONUS_3 then
        return "Socre_BankCraze_Bonus_Trigger3"
    elseif symbolType == self.SYMBOL_SCORE_COINS_BONUS then
        return "Socre_BankCraze_Bonus_Putong"
    elseif symbolType == self.SYMBOL_SCORE_FREE_BONUS then
        return "Socre_BankCraze_Bonus_Free"
    elseif symbolType == self.SYMBOL_SCORE_SAVE_BONUS then
        return "Socre_BankCraze_Bonus_Save"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MINI then
        return "Socre_BankCraze_Bonus_mini"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR then
        return "Socre_BankCraze_Bonus_minor"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR then
        return "Socre_BankCraze_Bonus_major"
    elseif symbolType == self.SYMBOL_SCORE_JACKPOT_GRAND then
        return "Socre_BankCraze_Bonus_grand"
    end
    
    return nil
end

-- 当前信号是否为长条信号
function CodeGameScreenBankCrazeMachine:getCurSymbolIsBigSymbol(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_TRIGGER_BONUS_1 or
       symbolType == self.SYMBOL_SCORE_TRIGGER_BONUS_2 or
       symbolType == self.SYMBOL_SCORE_TRIGGER_BONUS_3 then
        return true
    end
    return false
end

-- 当前信号是否为jackpot信号
function CodeGameScreenBankCrazeMachine:getCurSymbolIsJackpot(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_JACKPOT_MINI or
       symbolType == self.SYMBOL_SCORE_JACKPOT_MINOR or
       symbolType == self.SYMBOL_SCORE_JACKPOT_MAJOR or
       symbolType == self.SYMBOL_SCORE_JACKPOT_GRAND then
        return true
    end
    return false
end

-- 当前bonus信号是否需要挂插槽
function CodeGameScreenBankCrazeMachine:getCurSymbolIsSlotBonus(_symbolType)
    local symbolType = _symbolType
    if symbolType == self.SYMBOL_SCORE_COINS_BONUS or
       symbolType == self.SYMBOL_SCORE_FREE_BONUS then
        return true
    end
    return false
end

-- 当前快滚需要播待触发的bonus
function CodeGameScreenBankCrazeMachine:getCurIsRunLongBonus(_symbolType)
    local symbolType = _symbolType
    if self:getCurSymbolIsJackpot(symbolType) or
     symbolType == self.SYMBOL_SCORE_COINS_BONUS or
     symbolType == self.SYMBOL_SCORE_FREE_BONUS or
     symbolType == self.SYMBOL_SCORE_SAVE_BONUS then
        return true
     end
     return false
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBankCrazeMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenBankCrazeMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenBankCrazeMachine:MachineRule_initGame()
    --Free玩法同步次数
    if self.m_bProduceSlots_InFreeSpin then
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
    end
end

function CodeGameScreenBankCrazeMachine:initGameStatusData(gameData)
    --收集进度数据
    if gameData.gameConfig and gameData.gameConfig.extra and gameData.gameConfig.extra.Bank then
        self.m_curBankLevel = gameData.gameConfig.extra.Bank.BankLevel or 1
    end

    local specialData = gameData.special
    local spinData = gameData.spin
    if specialData and spinData then
        if specialData.selfData and spinData.selfData.Bank and spinData.selfData and spinData.selfData.Bank then
            spinData.selfData.Bank = specialData.selfData.Bank
        end
    end
    CodeGameScreenBankCrazeMachine.super.initGameStatusData(self,gameData)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBankCrazeMachine:MachineRule_SpinBtnCall()
    self:setMaxMusicBGVolume()
    self:stopLinesWinSound()
    return false -- 用作延时点击spin调用
end

function CodeGameScreenBankCrazeMachine:beginReel()
    self.collectBonus = false
    self.collectJackpotBonus = false
    self.m_curSpinIsRunLong = false
    self.m_curSpinIsHaveBigBonus = false
    self.m_bonusTipsView:spinCloseTips()
    self.m_collectTipsView:spinCloseTips()
    -- 有加成需要把角色消失
    self:closeMoreRoleAct()
    CodeGameScreenBankCrazeMachine.super.beginReel(self)
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        self.m_effectFixdNode:setVisible(false)
    else
        self.m_effectFixdNode:setVisible(true)
        local curBigSymbolNode = self.m_freeBigSymbolNode
        if not tolua.isnull(curBigSymbolNode) and self.m_freeBigSymbolNode.m_curActName ~= "idleframe2" then
            self.m_freeBigSymbolNode.m_curActName = "idleframe2"
            curBigSymbolNode:runAnim("idleframe2", true)
        end
    end
end

-- free下固定第五列大信号
function CodeGameScreenBankCrazeMachine:addFreeFixBigNode()
    self.m_effectFixdNode:removeAllChildren()
    local targetPos = self:getWorldToNodePos(self.m_effectFixdNode, 19)
    --free底
    self.m_freeBigSymbolNodeBg = util_createAnimation("BankCraze_Free_ColBg.csb")
    self.m_effectFixdNode:addChild(self.m_freeBigSymbolNodeBg, 1)
    self.m_freeBigSymbolNodeBg:setPosition(targetPos)

    self.m_freeBigSymbolNode = self:createBankCrazeSymbol(self.m_bankSymbolTypeTbl[self.m_curBankLevel])
    self.m_effectFixdNode:addChild(self.m_freeBigSymbolNode, 10)
    self.m_freeBigSymbolNode:setPosition(targetPos)
    self.m_freeBigSymbolNode:runAnim("idleframe2", true)
    self.m_freeBigSymbolNode.m_curActName = "idleframe2"
end

function CodeGameScreenBankCrazeMachine:closeMoreRoleAct(_onEnter)
    for index, roleSpine in pairs(self.m_moreRoleSpineTbl) do
        if roleSpine:isVisible() then
            if _onEnter then
                roleSpine:setVisible(false)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Close_MoreTips)
                util_spinePlay(roleSpine,"bace_over",false)
                util_spineEndCallFunc(roleSpine, "bace_over", function()
                    roleSpine:setVisible(false)
                end)
            end
        end
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenBankCrazeMachine:slotOneReelDown(reelCol)    
    CodeGameScreenBankCrazeMachine.super.slotOneReelDown(self,reelCol)
    ---本列是否开始长滚
    local isTriggerLongRun = false
    if reelCol == 1 then
        self.isHaveLongRun = false
    end
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true
    end

    if isTriggerLongRun then
        self.isHaveLongRun = true
        self:playBonusSpine("idleframe3", reelCol)
    else
        if reelCol == self.m_iReelColumnNum and self.isHaveLongRun == true then
            --落地
            self:playBonusSpine("idleframe2", reelCol, true)
        end
    end
end

function CodeGameScreenBankCrazeMachine:playBonusSpine(_spineName, _reelCol, isOver)
    performWithDelay(self.m_scWaitNode, function()
        for iCol = 1, _reelCol  do
            for iRow = 1, self.m_iReelRowNum do
                local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if targSp then
                    local symbolType = targSp.p_symbolType
                    if self:getCurIsRunLongBonus(symbolType) then
                        if _spineName == "idleframe3" and targSp.m_currAnimName ~= "idleframe3" then
                            targSp:runAnim(_spineName, true)
                        elseif _spineName == "idleframe2" then
                            -- local symbol_node = targSp:checkLoadCCbNode()
                            -- local curSpine = symbol_node:getCsbAct()
                            -- if curSpine then
                            --     util_spineMix(curSpine, "idleframe2", "idleframe1", 0.1)
                            -- end
                            targSp:runAnim(_spineName, true)
                        end
                    end
                end
            end
        end
    end, 0.1)
end

--[[
    滚轮停止
]]
function CodeGameScreenBankCrazeMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
    CodeGameScreenBankCrazeMachine.super.slotReelDown(self)
end
---------------------------------------------------------------------------

--[[
    检测添加大赢光效
]]
function CodeGameScreenBankCrazeMachine:checkAddBigWinLight()
    if not self.m_isAddBigWinLightEffect then -- 添加控制位
        return
    end
    --检测是否有大赢
    if self:checkHasBigWin() then
        local effectData = GameEffectData.new()
        effectData.p_effectType = GameEffect.EFFECT_BIG_WIN_LIGHT
        effectData.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 5
        table.insert(self.m_gameEffects, #self.m_gameEffects + 1, effectData)
    end
end

-- 根据index转换需要节点坐标系
function CodeGameScreenBankCrazeMachine:getWorldToNodePos(_nodeTaget, _pos)
    local tarSpPos = util_getOneGameReelsTarSpPos(self, _pos)
    local worldPos = self.m_clipParent:convertToWorldSpace(cc.p(tarSpPos))
    local endPos = _nodeTaget:convertToNodeSpace(worldPos)
    return endPos
end

---
-- 根据Bonus Game 每关做的处理
-- 选择free类型
function CodeGameScreenBankCrazeMachine:showChooseView(_callFunc, _isClick)
    local callFunc = _callFunc
    local isClick = _isClick
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local baseCoins = 0
    local bankData = {}
    if selfData and selfData.Bank then
        bankData.baseCoins = selfData.Bank.BankBonuswin
        bankData.minCoins = selfData.Bank.BankMinwin
        bankData.maxCoins = selfData.Bank.BankMaxwin
        bankData.curBankLevel = selfData.Bank.BankLevel
    end
    -- self:clearCurMusicBg()
    self:setMaxMusicBGVolume()
    self.m_chooseRewardView:showRewardChoose(bankData, callFunc, isClick)
end

-- 添加选完bonus后的玩法事件
function CodeGameScreenBankCrazeMachine:addPlayEffect()
    local selfEffect = GameEffectData.new()
    selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
    selfEffect.p_effectOrder = self.EFFECT_BONUS_OVER_PLAY
    self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
    selfEffect.p_selfEffectType = self.EFFECT_BONUS_OVER_PLAY -- 动画类型
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBankCrazeMachine:addSelfEffect()
    self.m_delayTime = 1.0
    self.m_bonusPlayCount = 0
    -- 保存当前触发了几个玩法
    self.m_curTriggerPlayTbl = {}
    if not self.m_runSpinResultData.p_selfMakeData then
        return
    end
        
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 收集save
    local saveIcons = selfData.saveIcons
    -- 收集钱
    local creditIcons = selfData.creditIcons
    -- 收集jackpot
    local jackpotIcons = selfData.jackpotIcons
    local isHaveSave, isHaveCredit, isHaveJackpot, isHaveFree

    -- 触发动画
    if self:getCurIsHaveBigBonus() then
        -- 收集save数据
        if saveIcons and next(saveIcons) then
            isHaveSave = true
            self.m_bonusPlayCount = self.m_bonusPlayCount + 1
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 2
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_COLLECT_SAVE_PLAY -- 动画类型
        end

        -- 收集钱玩法
        if creditIcons and next(creditIcons) then
            isHaveCredit = true
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 3
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_COLLECT_COINS_PLAY -- 动画类型
        else
            if jackpotIcons and next(jackpotIcons) then
                isHaveJackpot = true
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 4
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.EFFECT_COLLECT_JACKPOT_PLAY -- 动画类型
            end
        end

        -- 收集jackpot玩法
        -- if jackpotIcons and next(jackpotIcons) then
        --     isHaveJackpot = true
        --     local selfEffect = GameEffectData.new()
        --     selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        --     selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 4
        --     self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        --     selfEffect.p_selfEffectType = self.EFFECT_COLLECT_JACKPOT_PLAY -- 动画类型
        -- end

        if (creditIcons and next(creditIcons)) or (jackpotIcons and next(jackpotIcons)) then
            self.m_bonusPlayCount = self.m_bonusPlayCount + 1
        end

        -- freeBonus玩法
        local isHaveFree = false
        local freeBonusData = selfData.freeSpinIcons
        if freeBonusData and next(freeBonusData) then
            isHaveFree = true
            self.m_bonusPlayCount = self.m_bonusPlayCount + 1
            isHaveFree = true
        end

        if self.m_bonusPlayCount ~= 1 or not isHaveFree then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_LINE_FRAME + 1
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.EFFECT_TRIGGER_ALL_BONUS_PLAY -- 动画类型
        end
    end

    self.m_curTriggerPlayTbl = {isHaveSave, isHaveCredit, isHaveJackpot, isHaveFree}
    -- 判断当前spin是否有连线
    local winLines = self.m_runSpinResultData.p_winLines or {}
    -- if self:getCurrSpinMode() ~= FREE_SPIN_MODE and #winLines > 0 then
    if #winLines > 0 then
       self.m_delayTime = 1.0
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBankCrazeMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.EFFECT_TRIGGER_ALL_BONUS_PLAY then
        performWithDelay(self.m_scWaitNode, function()
            self:playTriggerAllBonus(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end, self.m_delayTime)
    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_SAVE_PLAY then
        local saveData = self:getSortCollectPlayData(self.SYMBOL_SCORE_SAVE_BONUS)
        self:playCollectSaveBonusStartAct(function()
            self:showMask(false, 1)
            effectData.p_isPlay = true
            self:playGameEffect()
        end, saveData)
    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_COINS_PLAY then
        self:playCollectMoreAct(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.EFFECT_COLLECT_JACKPOT_PLAY then
        local jackpotData = self:getSortCollectPlayData(self.SYMBOL_SCORE_JACKPOT_MINI)
        self:playCollectJackpotBonus(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end, jackpotData, 0)
    elseif effectData.p_selfEffectType == self.EFFECT_BONUS_OVER_PLAY then
        self:playSelectBonusOver(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end
    
    return true
end

-- 排序玩法信息
function CodeGameScreenBankCrazeMachine:getSortCollectPlayData(_curType)
    local curType = _curType
    local tempDataTbl = {}
    if curType == self.SYMBOL_SCORE_SAVE_BONUS then
        local saveIcons = self.m_runSpinResultData.p_selfMakeData.saveIcons or {}
        for k, pos in pairs(saveIcons) do
            local tempTbl = {}
            tempTbl.p_pos = tonumber(pos)
            local fixPos = self:getRowAndColByPos(tonumber(pos))
            local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            tempTbl.p_rowIndex = fixPos.iX
            tempTbl.p_cloumnIndex = fixPos.iY
            tempTbl.p_symbolNode = slotNode
            table.insert(tempDataTbl, tempTbl)
        end
    elseif curType == self.SYMBOL_SCORE_COINS_BONUS then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        local creditIcons = selfData.creditIcons or {}
        local bankMul = selfData.Bank.BankMulti or 1
        local curBet = self:getCurSpinStateBet()
        for k, coinsData in pairs(creditIcons) do
            local tempTbl = {}
            tempTbl.p_pos = coinsData[1]
            local mul = coinsData[2]
            local fixPos = self:getRowAndColByPos(coinsData[1])
            local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            tempTbl.p_rowIndex = fixPos.iX
            tempTbl.p_cloumnIndex = fixPos.iY
            tempTbl.p_rewardCoins = curBet*mul
            tempTbl.p_endRewardCoins = curBet*mul*bankMul
            tempTbl.p_symbolNode = slotNode
            table.insert(tempDataTbl, tempTbl)
        end

        -- 后续修改；把jackpot数据添加到钱bonus数据里去，一块收集
        local jackpotIcons = self.m_runSpinResultData.p_selfMakeData.jackpotIcons or {}
        for k, jackpotData in pairs(jackpotIcons) do
            local tempTbl = {}
            tempTbl.p_pos = jackpotData[1]
            local mul = jackpotData[2]
            local fixPos = self:getRowAndColByPos(jackpotData[1])
            local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            tempTbl.p_rowIndex = fixPos.iX
            tempTbl.p_cloumnIndex = fixPos.iY
            tempTbl.p_jackpotRewardCoins = self:getWinJackpotCoinsAndType(jackpotData[3])
            tempTbl.p_jackpotType = jackpotData[3]
            tempTbl.p_symbolNode = slotNode
            table.insert(tempDataTbl, tempTbl)
        end
    elseif curType == self.SYMBOL_SCORE_JACKPOT_MINI then
        local jackpotIcons = self.m_runSpinResultData.p_selfMakeData.jackpotIcons or {}
        for k, jackpotData in pairs(jackpotIcons) do
            local tempTbl = {}
            tempTbl.p_pos = jackpotData[1]
            local mul = jackpotData[2]
            local fixPos = self:getRowAndColByPos(jackpotData[1])
            local slotNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
            tempTbl.p_rowIndex = fixPos.iX
            tempTbl.p_cloumnIndex = fixPos.iY
            tempTbl.p_rewardCoins = self:getWinJackpotCoinsAndType(jackpotData[3])
            tempTbl.p_jackpotType = jackpotData[3]
            tempTbl.p_symbolNode = slotNode
            table.insert(tempDataTbl, tempTbl)
        end
    end
    
    table.sort(tempDataTbl, function(a, b)
        if a.p_cloumnIndex ~= b.p_cloumnIndex then
            return a.p_cloumnIndex < b.p_cloumnIndex
        end
        if a.p_rowIndex ~= b.p_rowIndex then
            return a.p_rowIndex > b.p_rowIndex
        end
        return false
    end)
    return tempDataTbl
end

-- 触发玩法，所有bonus播触发动画
function CodeGameScreenBankCrazeMachine:playTriggerAllBonus(_callFunc)
    local callFunc = _callFunc
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    self:showMask(true)

    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Bonus_Play_Trigger)
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if self:getCurIsRunLongBonus(slotNode.p_symbolType) then
                    slotNode:runAnim("actionframe", false, function()
                        slotNode:runAnim("idleframe2", true)
                    end)
                elseif self:getCurSymbolIsBigSymbol(slotNode.p_symbolType) then
                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        slotNode = self.m_freeBigSymbolNode
                    end
                    slotNode:runAnim("actionframe2", false, function()
                        if self:getCurrSpinMode() == FREE_SPIN_MODE then
                            self.m_freeBigSymbolNode.m_curActName = "idleframe2"
                        end
                        slotNode:runAnim("idleframe2", true)
                    end)
                end
            end
        end
    end
    
    local delayTime = 60/30+0.5
    performWithDelay(self.m_scWaitNode, function()
        if type(callFunc) == "function" then
            callFunc()
        end
    end, delayTime)
end

function CodeGameScreenBankCrazeMachine:setCurSymbolZorder(_symbolNode, _curZorder)
    _symbolNode:setLocalZOrder(_curZorder)
end

-- 收集bonus收集前播提示
function CodeGameScreenBankCrazeMachine:playCollectSaveBonusStartAct(_callFunc, _saveData)
    local callFunc = _callFunc
    local saveData = _saveData

    local tblActionList = {}
    if self.m_bonusPlayCount > 1 then
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Cur_BonusTrigger)
            for k, v in pairs(saveData) do
                local symbolNode = v.p_symbolNode
                local curSymbolZorder = symbolNode:getLocalZOrder()
                self:setCurSymbolZorder(symbolNode, curSymbolZorder+100)
                symbolNode:runAnim("actionframe2_start", false, function()
                    symbolNode:runAnim("actionframe2_idle", true)
                end)
            end
        end)
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(10/30)
    end
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        self:playCollectSavaBonus(callFunc, saveData)
    end)

    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 收集saveBonus
function CodeGameScreenBankCrazeMachine:playCollectSavaBonus(_callFunc, _saveData)
    local callFunc = _callFunc
    local saveData = _saveData

    local selfData = self.m_runSpinResultData.p_selfMakeData
    local curCollectCount = selfData.Bank.BankCollect or 0
    local curBankLevel = self.m_curBankLevel
    local triggerFlag = selfData.Bank.TriggerFlag
    self.m_curBankLevel = selfData.Bank.BankLevel or 1
    self.m_topEffectNode:removeAllChildren()
    local delayTime = 25/60
    
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Collect_SaveBonus)
    local isPlaySound = true
    -- 所有saveBonus一起飞
    for k, data in pairs(saveData) do
        local oneTblActionList = {}
        local curSymbolNode = data.p_symbolNode
        local curSymbolZorder = curSymbolNode:getLocalZOrder()
        local symbolNodePos = data.p_pos

        -- 飞行的bonus
        local flyNode = self:createBankCrazeSymbol(self.SYMBOL_SCORE_SAVE_BONUS)
        local startPos = self:getWorldToNodePos(self.m_topEffectNode, symbolNodePos)
        local curCollectNode = self.m_topBarView.m_collectView:getCurCollectNode(k)
        -- local endPos = util_convertToNodeSpace(self:findChild("Node_bank"), self.m_topEffectNode)
        local endPos = util_convertToNodeSpace(curCollectNode, self.m_topEffectNode)
        flyNode:setPosition(startPos)
        self.m_topEffectNode:addChild(flyNode)
        flyNode:runAnim("idleframe", true)
        local spineNode = flyNode:getNodeSpine()
        spineNode:setSkin(curBankLevel)
        flyNode:setVisible(false)

        oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
            flyNode:setVisible(true)
            if self.m_bonusPlayCount <= 1 then
                self:setCurSymbolZorder(curSymbolNode, curSymbolZorder+100)
            end
            curSymbolNode:runAnim("actionframe2_over", false, function()
                self:setCurSymbolZorder(curSymbolNode, curSymbolZorder-200)
                curSymbolNode:runAnim("dark", false, function()
                    curSymbolNode:runAnim("dark_idle", true)
                end)
            end)
        end)
        oneTblActionList[#oneTblActionList + 1] = cc.EaseSineInOut:create(cc.MoveTo:create(delayTime, endPos))
        oneTblActionList[#oneTblActionList + 1] = cc.CallFunc:create(function()
            if isPlaySound then
                isPlaySound = false
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Collect_SaveBonus_FeedBack)
            end
            -- if self.m_bonusBtnView:isVisible() then
            --     self.m_bonusBtnView:playFeedBackAct()
            -- end
            -- self.m_topBankNodeTbl[curBankLevel]:runAnim("bace_fankui", false, function()
            --     self.m_topBankNodeTbl[curBankLevel]:runAnim("bace_idle", true)
            -- end)
            self.m_topBarView:collectSaveBonus(false, curBankLevel)
            flyNode:setVisible(false)
        end)
        flyNode:runAction(cc.Sequence:create(oneTblActionList))
    end

    performWithDelay(self.m_scWaitNode, function()
        self:showBankUpLevel(callFunc, triggerFlag, curBankLevel)
    end, delayTime+40/60)
end

-- 银行是否升级
function CodeGameScreenBankCrazeMachine:showBankUpLevel(_callFunc, _triggerFlag, _curBankLevel)
    local callFunc = _callFunc
    local triggerFlag = _triggerFlag
    local curBankLevel = _curBankLevel

    local tblActionList = {}
    -- 收集个数是0，相当于升级
    if triggerFlag and curBankLevel < 3 then
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            self.m_topBarView:playTriggerAct(self.m_curBankLevel)
        end)
        -- BankCraze_Jindutiao.csd的actionframe(0-100)
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(100/60)
        if self.m_curBankLevel < 3 then
            -- 在BankCraze_Jindutiao.csd的actionframe3的第25帧播大银行的的升级动画
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(25/60)
        end
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            if curBankLevel == 1 then
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Bank_LevelUp_ToSilver)
            else
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Bank_LevelUp_ToGold)
            end
            self.m_topBankNodeTbl[curBankLevel]:runAnim("bace_switch", false, function()
                self:updateTopBankSpine()
            end)
        end)
        -- bace_switch（0-37）
        -- 升级完后0.5s 银行刺光出来后 弹弹板
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(37/30+0.5)
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            self.m_bankTipsView:showBankAutoTips(self.m_curBankLevel)
            self.m_topBankNodeTbl[curBankLevel+1]:runAnim("bace_idle2", false, function()
                self:updateTopBankSpine()
            end)
        end)
        -- 银行actionframe(10-100)
        -- bace_idle2（0-60）
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(60/30)
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            self.m_topEffectNode:removeAllChildren()
            self:showChooseView(function()
                performWithDelay(self.m_scWaitNode, function()
                    if type(callFunc) == "function" then
                        callFunc()
                    end
                end, 0.5)
            end)
        end)
    else
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.5)
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            self.m_topEffectNode:removeAllChildren()
            if type(callFunc) == "function" then
                callFunc()
            end
        end)
    end
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 播收集前看是否需要播放加成
function CodeGameScreenBankCrazeMachine:playCollectMoreAct(_callFunc)
    local callFunc = _callFunc
    local selfData = self.m_runSpinResultData.p_selfMakeData
    -- 收集钱的倍数
    local bankMul = selfData.Bank.BankMulti or 1
    local bonusData = self:getSortCollectPlayData(self.SYMBOL_SCORE_COINS_BONUS)

    local tblActionList = {}
    local duration = 0.5
    if bankMul > 1 then
        local moreIndex = 1
        local actName = "actionframe3"
        if bankMul == 1.5 then
            moreIndex = 2
            actName = "actionframe4"
        end
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            self.m_moreRoleSpineTbl[moreIndex]:setVisible(true)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Show_MoreTips)
            util_spinePlay(self.m_moreRoleSpineTbl[moreIndex],"bace_start",false)
            util_spineEndCallFunc(self.m_moreRoleSpineTbl[moreIndex], "bace_start", function()
                util_spinePlay(self.m_moreRoleSpineTbl[moreIndex],"bace_idle", true)
            end)
            -- 金币喷射
            self.m_moreCoinSpineTbl[moreIndex]:setVisible(true)
            util_spinePlay(self.m_moreCoinSpineTbl[moreIndex],"start",false)
            util_spineEndCallFunc(self.m_moreCoinSpineTbl[moreIndex], "start", function()
                util_spinePlay(self.m_moreCoinSpineTbl[moreIndex],"idle",true)
            end)
        end)
        -- bace_start(0-25)
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(25/30)
        -- H1\2角色出现动画结束0.5s后，在播20%、50%砸落在棋盘的动画
        -- tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.5)
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            -- util_spinePlay(self.m_moreRoleSpineTbl[moreIndex],"bace_idle", true)
            self.m_moreMulAni:setVisible(true)
            self.m_moreMulAni:findChild("sp_20"):setVisible(moreIndex==1)
            self.m_moreMulAni:findChild("sp_50"):setVisible(moreIndex==2)
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Show_MoreTips_Down)
            self.m_moreMulAni:runCsbAction("actionframe", false, function()
                self.m_moreMulAni:setVisible(false)
            end)
        end)
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(60/60)
        -- 所有普通Bonus同时播加成动画
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BonusCoins_Jump)
            for k, v in pairs(bonusData) do
                if not v.p_jackpotType then
                    local symbolNode = v.p_symbolNode
                    if symbolNode then
                        symbolNode:runAnim(actName, false)
                    end
                end
            end
        end)
        -- actionframe3-actionframe4 0-20
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(20/30)
        -- 在普通Bonus图标播完20%、50%效果后，0.5s再播结算
        -- tblActionList[#tblActionList + 1] = cc.DelayTime:create(0.5)
        -- 所有普通Bonus同时播加成动画
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            for k, v in pairs(bonusData) do
                if not v.p_jackpotType then
                    local symbolNode = v.p_symbolNode
                    local oldCoins = v.p_rewardCoins
                    local endCoins = v.p_endRewardCoins
                    local nodeScore = self:getLblCsbOnSymbol(symbolNode,"Socre_BankCraze_Bonus_Coins.csb","zi")
                    self:playJumpBonusCoins({_nodeScore = nodeScore, _oldCoins = oldCoins, _endCoins = endCoins, _duration = duration, _mul = bankMul})
                    -- self:setNodeScore(nodeScore, util_formatCoinsLN(endCoins, 3), bankMul)
                end
            end
        end)
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(1.0)
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            self:playCollectBonus(callFunc, bonusData, 0, moreIndex)
        end)
    else
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            self:playCollectBonus(callFunc, bonusData, 0, moreIndex)
        end)
    end
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 收集coinBonus
function CodeGameScreenBankCrazeMachine:playCollectBonus(_callFunc, _bonusData, _curIndex, _moreIndex)
    local callFunc = _callFunc
    local bonusData = _bonusData
    local curIndex = _curIndex + 1
    local moreIndex = _moreIndex

    if curIndex > #bonusData then
        self:showMask(false, 2)
        if not self:checkHasBigWin() then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        end
        util_spinePlay(self.m_moreCoinSpineTbl[moreIndex],"over",false)
            util_spineEndCallFunc(self.m_moreCoinSpineTbl[moreIndex], "over", function()
                self.m_moreCoinSpineTbl[moreIndex]:setVisible(false)
            end)
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    local curSymbolNode = bonusData[curIndex].p_symbolNode
    local symbolNodePos = bonusData[curIndex].p_pos
    if not curSymbolNode then
        local fixPos = self:getRowAndColByPos(symbolNodePos)
        curSymbolNode = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
    end

    local tblActionList = {}
    if curSymbolNode then
        local curSymbolZorder = curSymbolNode:getLocalZOrder()
        local rewardCoins = bonusData[curIndex].p_endRewardCoins
        local jackpotType = bonusData[curIndex].p_jackpotType
        local jackpotRewardCoins = bonusData[curIndex].p_jackpotRewardCoins
        local delayTime = 0.4

        if curIndex == 1 and self.m_bonusPlayCount > 1 then
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Cur_BonusTrigger)
                for k, v in pairs(bonusData) do
                    local symbolNode = v.p_symbolNode
                    symbolNode:runAnim("actionframe2_start", false, function()
                        symbolNode:runAnim("actionframe2_idle", true)
                    end)
                end
            end)
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(10/30)
        end

        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            curSymbolZorder = curSymbolZorder+100
            self:setCurSymbolZorder(curSymbolNode, curSymbolZorder)
            curSymbolNode:runAnim("actionframe2_over", false, function()
                self:setCurSymbolZorder(curSymbolNode, curSymbolZorder-200)
                curSymbolNode:runAnim("dark", false, function()
                    curSymbolNode:runAnim("dark_idle", true)
                end)
            end)
            if jackpotType then
                local params = {
                    overCoins  = jackpotRewardCoins,
                    jumpTime   = 1.5,
                    animName   = "actionframe3",
                }
                self:playBottomBigWinLabAnim(params)
                self:playBottomLight(jackpotRewardCoins, true)
            end
        end)
        -- 18+5
        -- tblActionList[#tblActionList + 1] = cc.DelayTime:create(23/30)
        if jackpotType then
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(18/30)
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                self.m_jackPotBarView:playTriggerJackpot(jackpotType)
                self:showJackpotView(jackpotRewardCoins, jackpotType, function()
                    performWithDelay(self.m_scWaitNode, function()
                        self:playCollectBonus(callFunc, bonusData, curIndex, moreIndex)
                    end, delayTime)
                end)
            end)
        else
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                local params = {
                    overCoins  = rewardCoins,
                    jumpTime   = 1/60,
                    animName   = "actionframe2",
                    isPlayCoins = true,
                }
                self:playBottomBigWinLabAnim(params)
                self:playBottomLight(rewardCoins)
            end)
            -- 上1个Bonus结算动画开始0.4s后播下一个Bonus的结算动画
            tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
            tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
                self:playCollectBonus(callFunc, bonusData, curIndex, moreIndex)
            end)
        end
    else
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            self:playCollectBonus(callFunc, bonusData, curIndex, moreIndex)
        end)
    end
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 收集jackpotBonus
function CodeGameScreenBankCrazeMachine:playCollectJackpotBonus(_callFunc, _jackpotData, _curIndex)
    local callFunc = _callFunc
    local jackpotData = _jackpotData
    local curIndex = _curIndex + 1

    if curIndex > #jackpotData then
        self:showMask(false, 3)
        if not self:checkHasBigWin() then
            --检测大赢
            self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
        end
        if type(callFunc) == "function" then
            callFunc()
        end
        return
    end

    local curSymbolNode = jackpotData[curIndex].p_symbolNode
    local curSymbolZorder = curSymbolNode:getLocalZOrder()
    local symbolNodePos = jackpotData[curIndex].p_pos
    local rewardCoins = jackpotData[curIndex].p_rewardCoins
    local jackpotType = jackpotData[curIndex].p_jackpotType
    local tblActionList = {}
    local delayTime = 0.4

    if curIndex == 1 and self.m_bonusPlayCount > 1 then
        tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_Cur_BonusTrigger)
            for k, v in pairs(jackpotData) do
                local symbolNode = v.p_symbolNode
                symbolNode:runAnim("actionframe2_start", false, function()
                    symbolNode:runAnim("actionframe2_idle", true)
                end)
            end
        end)
        tblActionList[#tblActionList + 1] = cc.DelayTime:create(10/30)
    end

    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        curSymbolZorder = curSymbolZorder+100
        self:setCurSymbolZorder(curSymbolNode, curSymbolZorder)
        curSymbolNode:runAnim("actionframe2_over", false, function()
            self:setCurSymbolZorder(curSymbolNode, curSymbolZorder-200)
            curSymbolNode:runAnim("dark", false, function()
                curSymbolNode:runAnim("dark_idle", true)
            end)
        end)

        local params = {
            overCoins  = rewardCoins,
            jumpTime   = 1.5,
            animName   = "actionframe3",
        }
        self:playBottomBigWinLabAnim(params)
        self:playBottomLight(rewardCoins, true)
    end)
    -- 18+5
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(18/30)
    -- tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        self.m_jackPotBarView:playTriggerJackpot(jackpotType)
        self:showJackpotView(rewardCoins, jackpotType, function()
            performWithDelay(self.m_scWaitNode, function()
                self:playCollectJackpotBonus(callFunc, jackpotData, curIndex)
            end, delayTime)
        end)
    end)
    self.m_scWaitNode:runAction(cc.Sequence:create(tblActionList))
end

-- 数字上涨（收集钱玩法；钱要上涨）
function CodeGameScreenBankCrazeMachine:playJumpBonusCoins(parms)
    local nodeScore = parms._nodeScore
    local oldCoins = parms._oldCoins
    local endCoins = parms._endCoins
    local duration = parms._duration   --持续时间
    local mul = parms._mul
    --每次跳动上涨金币数
    local coinRiseNum =  (endCoins - oldCoins) / (60  * duration)   --1秒跳动60次
    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = oldCoins
    if not tolua.isnull(nodeScore) then
        nodeScore:stopAllActions()

        util_schedule(nodeScore, function()
            curCoins = curCoins + coinRiseNum
            if curCoins >= endCoins then
                self:setNodeScore(nodeScore, util_formatCoinsLN({coins = endCoins, obligate = 3, obligateF = 1}), mul)
                nodeScore:stopAllActions()
            else
                self:setNodeScore(nodeScore, util_formatCoinsLN({coins = curCoins, obligate = 3, obligateF = 1}), mul)
            end
        end, 1/60)
    end
end

-- 显示bonus按钮和tips
function CodeGameScreenBankCrazeMachine:showBonusBtnAndTips()
    if not self.m_bonusBtnView:isVisible() then
        self.m_bonusBtnView:playStart()
    end
    self.m_bonusTipsView:showTips(self.m_curBankLevel)
    if self.m_curBankLevel == 2 then
        if not self.m_moreSilverTipsView:isVisible() then
            self.m_moreSilverTipsView:showStartMoreType()
        end
    elseif self.m_curBankLevel == 3 then
        if not self.m_moreGoldTipsView:isVisible() then
            self.m_moreGoldTipsView:showStartMoreType()
        end
    end
end

-- 重置bonus相关
function CodeGameScreenBankCrazeMachine:playSelectBonusOver(_callFunc)
    local callFunc = _callFunc
    -- 是否为最高档
    local isHeightLevel = self.m_chooseRewardView:getLastBankLevelIsHeight()
    self.m_topBarView:playHeightToLowAct(isHeightLevel)
    self.m_chooseRewardView:setBonusBankLevel(1)
    self.m_moreSilverTipsView:closeBonusMoreTips()
    if not self:checkHasBigWin() then
        --检测大赢
        self:checkFeatureOverTriggerBigWin(self.m_runSpinResultData.p_winAmount, GameEffect.EFFECT_BONUS)
    end

    -- 降级需要判断等级，播放相应的动画
    self.m_bankTipsView:showBankAutoTips(self.m_curBankLevel)
    self.m_topBankNodeTbl[self.m_curBankLevel]:runAnim("bace_idle2", false, function()
        self:updateTopBankSpine()
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end

-- 在选择奖励界面直接切idle
function CodeGameScreenBankCrazeMachine:resetBonusPlay()
    self:setMoreTipsState(false)
    self:closeMoreRoleAct(true)
    self.m_bonusBtnView:playOver()
    self.m_curBankLevel = 1
    self:updateTopBankSpine()
    self.m_topBarView.m_collectView:refreshCollectBank(0, 1, true)
end

--播放
function CodeGameScreenBankCrazeMachine:playBottomBigWinLabAnim(_params)
    --竖屏单独处理缩放
    if globalData.slotRunData.isPortrait then
        self.m_bottomUI.m_bigWinLabCsb:setScale(0.65)
        local posY = 15
        self.m_bottomUI.m_bigWinLabCsb:setPositionY(posY)
    end
    CodeGameScreenBankCrazeMachine.super.playBottomBigWinLabAnim(self, _params)
end

function CodeGameScreenBankCrazeMachine:playBottomLight(_endCoins, _isJackpot)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_BonusCoins_FeedBack)
    if _isJackpot then
        self.collectJackpotBonus = true
    else
        self.collectBonus = true
    end
    self.m_bottomUI:playCoinWinEffectUI()

    local bottomWinCoin = self:getCurBottomWinCoins()
    local totalWinCoin = bottomWinCoin + _endCoins
    --刷新赢钱
    -- self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(totalWinCoin))
    self:setLastWinCoin(totalWinCoin)
    self:updateBottomUICoins(bottomWinCoin, totalWinCoin)
end

--BottomUI接口
function CodeGameScreenBankCrazeMachine:updateBottomUICoins(_beiginCoins,_endCoins,isNotifyUpdateTop,_playWinSound)
    local winCoins = _endCoins - _beiginCoins
    local params = {winCoins,isNotifyUpdateTop, _playWinSound, _beiginCoins}
    params[self.m_stopUpdateCoinsSoundIndex] = not _playWinSound
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
end

function CodeGameScreenBankCrazeMachine:getCurBottomWinCoins()
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

function CodeGameScreenBankCrazeMachine:createBankCrazeSymbol(_symbolType)
    local symbol = util_createView("CodeBankCrazeSrc.BankCrazeSymbol", self)
    symbol:changeSymbolCcb(_symbolType)

    return symbol
end

-- 1. 当棋盘上Bonus1、Jackpot Bonus赢钱总和大于5倍时
-- 2. 当棋盘上落下FreeBonus时
-- 3. 上述两者兼有时
function CodeGameScreenBankCrazeMachine:getCurSpinIsRunLong()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusCoins = selfData.bonus_coins
    local freeBonusData = selfData.freeSpinIcons
    local curBet = self:getCurSpinStateBet()
    local isRunLong = false
    if bonusCoins and (bonusCoins/curBet) > 5 then
        isRunLong = true
    end

    if freeBonusData and next(freeBonusData) then
        isRunLong = true
    end

    return isRunLong
end

-- 是否有玩法
function CodeGameScreenBankCrazeMachine:getCurIsHaveBigBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local bonusTrigger = selfData.BonusTrigger
    if bonusTrigger then
        return true
    end
    return false
end

-- 第五列是否有长条
function CodeGameScreenBankCrazeMachine:getCurBuLingIsHaveBigBonus()
    local reels = self.m_runSpinResultData.p_reels
    local bigSymbolCount = 0
    for iRow = 1, self.m_iReelRowNum do
        local symbolType = reels[iRow][self.m_iReelColumnNum]
        if self:getCurSymbolIsBigSymbol(symbolType) then
            bigSymbolCount = bigSymbolCount + 1
        end
    end
    if bigSymbolCount == 4 then
        return true
    end
    return false
end

--[[
    显示大赢光效(子类重写)
]]
function CodeGameScreenBankCrazeMachine:showBigWinLight(func)
    local rootNode = self:findChild("root")

    local winLbl = self.m_bottomUI:getNormalWinLabel()
    local pos = util_convertToNodeSpace(winLbl,rootNode)

    self.m_bigWinSpine:setVisible(true)
    self.m_bigWinBottomSpine:setVisible(true)
    util_spinePlay(self.m_bigWinBottomSpine, "actionframe2", false)
    util_spinePlay(self.m_bigWinSpine, "actionframe1", false)
    util_spineEndCallFunc(self.m_bigWinBottomSpine, "actionframe2", function()
        self.m_bigWinBottomSpine:setVisible(false)
    end)
    util_spineEndCallFunc(self.m_bigWinSpine, "actionframe1", function()
        if self.m_winSoundsId then
            gLobalSoundManager:stopAudio(self.m_winSoundsId)
            self.m_winSoundsId = nil
        end
        self.m_bigWinSpine:setVisible(false)
    end)

    local aniTime = self.m_bigWinSpine:getAnimationDurationTime("actionframe1")
    util_shakeNode(rootNode,5,10,aniTime)

    self:delayCallBack(aniTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

function CodeGameScreenBankCrazeMachine:showEffect_runBigWinLightAni(effectData)
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Celebrate_Win)
    return CodeGameScreenBankCrazeMachine.super.showEffect_runBigWinLightAni(self,effectData)
end

function CodeGameScreenBankCrazeMachine:playEffectNotifyNextSpinCall()
    CodeGameScreenBankCrazeMachine.super.playEffectNotifyNextSpinCall( self )
    self:checkTriggerOrInSpecialGame(function()
        self:reelsDownDelaySetMusicBGVolume() 
    end)
end

function CodeGameScreenBankCrazeMachine:updateReelGridNode(_symbolNode)

    -- 钱和free需要往插槽上挂字体
    if _symbolNode.p_symbolType == self.SYMBOL_SCORE_COINS_BONUS then
        self:setSpecialNodeScoreBonus(_symbolNode)
    elseif _symbolNode.p_symbolType == self.SYMBOL_SCORE_FREE_BONUS then
        self:setSpecialNodeFreeBonus(_symbolNode)
    end

    self:setSpecialSymbolSkin(_symbolNode)
end

function CodeGameScreenBankCrazeMachine:setSpecialNodeScoreBonus(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType then
        return
    end

    local curBet = self:getCurSpinStateBet()
    local sScore = ""
    local mul
    local nodeScore = self:getLblCsbOnSymbol(symbolNode,"Socre_BankCraze_Bonus_Coins.csb","zi")

    if symbolNode.m_isLastSymbol == true and iRow <= self.m_iReelRowNum then
        mul = self:getBonusScoreData(self:getPosReelIdx(iRow, iCol))
        if mul ~= nil and mul ~= 0 then
            local coins = mul * curBet
            sScore = util_formatCoinsLN({coins = coins, obligate = 3, obligateF = 1})
        end
    else
        -- 获取随机分数（本地配置）
        mul = self:randomDownSymbolScore(symbolNode.p_symbolType)
        local coins = mul * curBet
        sScore = util_formatCoinsLN({coins = coins, obligate = 3, obligateF = 1})
    end
    self:setNodeScore(nodeScore, sScore, mul)
end

function CodeGameScreenBankCrazeMachine:setNodeScore(_nodeScore, _sScore, _mul)
    if _nodeScore then
        local textNode = _nodeScore:findChild("m_lb_num1")
        local textHighNode = _nodeScore:findChild("m_lb_num2")
        textNode:setString(_sScore)
        textHighNode:setString(_sScore)
        if _mul then
            if _mul >= 5 then
                textNode:setVisible(false)
                textHighNode:setVisible(true)
            else
                textNode:setVisible(true)
                textHighNode:setVisible(false)
            end
        end
    end
end

function CodeGameScreenBankCrazeMachine:setSpecialNodeFreeBonus(_symbolNode)
    local symbolNode = _symbolNode
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if not symbolNode.p_symbolType then
        return
    end

    local sScore = ""
    local nodeScore = self:getLblCsbOnSymbol(symbolNode,"Socre_BankCraze_Bonus_FreeTimes.csb","zi")

    if symbolNode.m_isLastSymbol == true and iRow <= self.m_iReelRowNum then
        sScore = self:getBonusFreeTimesData(self:getPosReelIdx(iRow, iCol))
    else
        -- 获取随机分数（本地配置）
        sScore = self:randomDownSymbolFreeTimes(symbolNode.p_symbolType)
    end

    if nodeScore then
        nodeScore:findChild("m_lb_num1"):setString(sScore)
    end
end

--[[
    获取小块真实分数
]]
function CodeGameScreenBankCrazeMachine:getBonusScoreData(id)
    if not self.m_runSpinResultData.p_selfMakeData then
        return 0
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local creditIcons = selfData.creditIcons or {}
    local score = 0

    for i=1, #creditIcons do
        local values = creditIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    return score
end

--[[
    随机bonus分数
]]
function CodeGameScreenBankCrazeMachine:randomDownSymbolScore(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_SCORE_COINS_BONUS then
        score = self.m_configData:getCurBonusTypeReward("coins")
    end

    return score
end

--[[
    获取小块真实free次数
]]
function CodeGameScreenBankCrazeMachine:getBonusFreeTimesData(id)
    if not self.m_runSpinResultData.p_selfMakeData then
        return 0
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local freeSpinIcons = selfData.freeSpinIcons or {}
    local score = 0

    for i=1, #freeSpinIcons do
        local values = freeSpinIcons[i]
        if values[1] == id then
            score = values[2]
        end
    end

    return score
end

--[[
    随机bonus-free次数
]]
function CodeGameScreenBankCrazeMachine:randomDownSymbolFreeTimes(symbolType)
    local score = nil
    
    if symbolType == self.SYMBOL_SCORE_FREE_BONUS then
        score = self.m_configData:getCurBonusTypeReward("free")
    end

    return score
end

-- 根据银行当前状态设置bonus皮肤
function CodeGameScreenBankCrazeMachine:setSpecialSymbolSkin(_symbolNode)
    local symbolNode = _symbolNode
    if not symbolNode.p_symbolType or not self.m_curBankLevel then
        return
    end

    if symbolNode.p_symbolType == self.SYMBOL_SCORE_COINS_BONUS or symbolNode.p_symbolType == self.SYMBOL_SCORE_SAVE_BONUS then
        symbolNode:changeSkin(self.m_curBankLevel)
    end
end

-- 获取当前bet；free里获取平均bet
function CodeGameScreenBankCrazeMachine:getCurSpinStateBet()
    local curBet = globalData.slotRunData:getCurTotalBet()
    return curBet
end

function CodeGameScreenBankCrazeMachine:createSlotNextNode(parentData)
    CodeGameScreenBankCrazeMachine.super.createSlotNextNode(self, parentData)
    if parentData.symbolType == self.SYMBOL_SCORE_JACKPOT_CHANGE then
        parentData.symbolType = self:getBonusJackpotSymbolType()
    elseif parentData.symbolType == self.SYMBOL_SCORE_TRIGGER_BONUS_1 then
        local triggerBonusData = {self.SYMBOL_SCORE_TRIGGER_BONUS_1, self.SYMBOL_SCORE_TRIGGER_BONUS_2, self.SYMBOL_SCORE_TRIGGER_BONUS_3}
        parentData.symbolType = triggerBonusData[self.m_curBankLevel]
    end
end

---
-- 在这里不影响groupIndex 和 rowIndex 等到结果数据来时使用
--
function CodeGameScreenBankCrazeMachine:getReelDataWithWaitingNetWork(parentData)
    CodeGameScreenBankCrazeMachine.super.getReelDataWithWaitingNetWork(self, parentData)
    if parentData.symbolType == self.SYMBOL_SCORE_JACKPOT_CHANGE then
        parentData.symbolType = self:getBonusJackpotSymbolType()
    elseif parentData.symbolType == self.SYMBOL_SCORE_TRIGGER_BONUS_1 then
        local triggerBonusData = {self.SYMBOL_SCORE_TRIGGER_BONUS_1, self.SYMBOL_SCORE_TRIGGER_BONUS_2, self.SYMBOL_SCORE_TRIGGER_BONUS_3}
        parentData.symbolType = triggerBonusData[self.m_curBankLevel]
    end
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenBankCrazeMachine:getResNodeSymbolType(parentData)
    local symbolType = CodeGameScreenBankCrazeMachine.super.getResNodeSymbolType(self, parentData)
    if symbolType == self.SYMBOL_SCORE_JACKPOT_CHANGE then
        symbolType = self:getBonusJackpotSymbolType()
    end
    return symbolType
end

---
-- 获取随机信号，  
-- @param col 列索引
function CodeGameScreenBankCrazeMachine:MachineRule_getRandomSymbol(col)
    local symbolType = CodeGameScreenBankCrazeMachine.super.MachineRule_getRandomSymbol(self, col)
    if symbolType == self.SYMBOL_SCORE_JACKPOT_CHANGE then
        symbolType = self:getBonusJackpotSymbolType()
    end
    return symbolType
end

-- 假滚如果是96信号；需要变信号101-8000；102-5000；103-500；104-50
-- 160 100 10 1
function CodeGameScreenBankCrazeMachine:getBonusJackpotSymbolType()
    local weightTbl = {160, 100, 10, 1}
    local changeSymbolType = {101, 102, 103, 104}
    local totalWetght = 0
    local preValue = 0
    local symbolType = changeSymbolType[1]
    for i=1, #weightTbl do
        totalWetght = totalWetght + weightTbl[i]
    end
    local randomNum = math.random(1, totalWetght)
    for i=1, #weightTbl do
        if randomNum > preValue and randomNum <= preValue + weightTbl[i] then
            symbolType = changeSymbolType[i]
            break
        end
        preValue = preValue + weightTbl[i]
    end
    return symbolType
end

-- free和freeMore特殊需求
function CodeGameScreenBankCrazeMachine:playScatterTipMusicEffect()
    if self.m_ScatterTipMusicPath ~= nil then
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.sound_FreeMoreBonus_Trigger)
        else
            globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.sound_FreeBonus_Trigger, 3, 0, 1)
            self:clearCurMusicBg()
        end
    end
end

-- 不用系统音效
function CodeGameScreenBankCrazeMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end

function CodeGameScreenBankCrazeMachine:checkRemoveBigMegaEffect()
    CodeGameScreenBankCrazeMachine.super.checkRemoveBigMegaEffect(self)
    if self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) and
     self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) and
     self:checkHasGameEffectType(GameEffect.EFFECT_ULTRAWIN) and
     self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) then
        self.m_bIsBigWin = false
    end
end

function CodeGameScreenBankCrazeMachine:getShowLineWaitTime()
    local time = CodeGameScreenBankCrazeMachine.super.getShowLineWaitTime(self)
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

--默认按钮监听回调
function CodeGameScreenBankCrazeMachine:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_click" then
        self.m_bonusTipsView:spinCloseTips()
        self.m_collectTipsView:spinCloseTips()
    end
end

----------------------------新增接口插入位---------------------------------------------

function CodeGameScreenBankCrazeMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeBankCrazeSrc.BankCrazeFreespinBarView")
    self.m_baseFreeSpinBar:setVisible(false)
    self:findChild("FreeBar"):addChild(self.m_baseFreeSpinBar) --修改成自己的节点    
end

function CodeGameScreenBankCrazeMachine:showFreeSpinView(effectData)
    -- gLobalSoundManager:playSound("BankCrazeSounds/music_BankCraze_custom_enter_fs.mp3")
    self:showMask(false, 4)
    local showFSView = function ( ... )
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_More_Auto)
            local roleSpine = util_spineCreate("Socre_BankCraze_7",true,true)
            util_spinePlay(roleSpine, "auto", false)

            local view = self:showFreeSpinMore(self.m_runSpinResultData.p_freeSpinNewCount,function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end,true)

            local lightAni = util_createAnimation("BankCraze_tanban_guang.csb")
            lightAni:runCsbAction("idle", true)

            self:setCurFreeSpinTimesData(view, self.m_runSpinResultData.p_freeSpinNewCount)
            self:setFreeDialogBankShowType(view)
            view:findChild("Node_spine"):addChild(roleSpine)
            view:findChild("Node_guang"):addChild(lightAni)
            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        else
            gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartStart)
            local roleSpine = util_spineCreate("Socre_BankCraze_7",true,true)
            util_spinePlay(roleSpine, "FreeSpinstart_start", false)
            util_spineEndCallFunc(roleSpine, "FreeSpinstart_start", function()
                if not tolua.isnull(roleSpine) then
                    util_spinePlay(roleSpine, "FreeSpinstart_idle", true)
                end
            end)

            local lightAni = util_createAnimation("BankCraze_tanban_guang.csb")
            lightAni:runCsbAction("idle", true)

            local cutSceneFunc = function()
                if not tolua.isnull(roleSpine) then
                    util_spinePlay(roleSpine, "FreeSpinstart_over", false)
                end
                performWithDelay(self.m_scWaitNode, function()
                    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_StartOver)
                end, 5/60)
            end

            local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                self:addFreeFixBigNode()
                self:showBaseToFreeSceneAni(function()
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end, true)  
            end)
            
            self:setCurFreeSpinTimesData(view, self.m_iFreeSpinTimes)
            self:setFreeDialogBankShowType(view)
            view:findChild("Node_spine"):addChild(roleSpine)
            view:findChild("Node_guang"):addChild(lightAni)
            view:setBtnClickFunc(cutSceneFunc)
            view:findChild("root"):setScale(self.m_machineRootScale)
            util_setCascadeOpacityEnabledRescursion(view, true)
        end
    end

    self:delayCallBack(0.5,function()
        showFSView()  
    end)    
end

-- 设置free弹板上银行显示的类型
function CodeGameScreenBankCrazeMachine:setFreeDialogBankShowType(_view)
    _view:findChild("Copper"):setVisible(self.m_curBankLevel == 1)
    _view:findChild("Silver"):setVisible(self.m_curBankLevel == 2)
    _view:findChild("Gold"):setVisible(self.m_curBankLevel == 3)
end

-- 获取当前次数信息
function CodeGameScreenBankCrazeMachine:setCurFreeSpinTimesData(_view, _freeTimes)
    local view = _view
    local freeTimes = _freeTimes
    local curNumTbl = {}
    local len = string.len(freeTimes)
    for index = 1, len do
        curNumTbl[index] = string.sub(freeTimes,index,index)
    end

    for i = 1, 3 do
        view:findChild("Node_num_"..i):setVisible(i == len)
    end

    for i = 1, len do
        view:findChild("m_lb_num"..len.."_"..i):setString(curNumTbl[i])
    end
end

---------------------------------弹版----------------------------------
function CodeGameScreenBankCrazeMachine:showFreeSpinStart(num, func, isAuto)
    local ownerlist = nil

    if isAuto then
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func, BaseDialog.AUTO_TYPE_NOMAL)
    else
        return self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

function CodeGameScreenBankCrazeMachine:showFreeSpinMore(num, func, isAuto)
    local function newFunc()
        self:resetMusicBg(true)
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
function CodeGameScreenBankCrazeMachine:showBaseToFreeSceneAni(_callFunc, _isStart)
    local callFunc = _callFunc
    local isStart = _isStart
    if isStart then
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Base_Fg_CutScene)
        self:resetMusicBg(nil, self.m_publicConfig.SoundConfig.Music_FG_Bg)
    else
        gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_Fg_Base_CutScene)
    end

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

function CodeGameScreenBankCrazeMachine:showFreeSpinOverView(effectData)
    globalMachineController:playBgmAndResume(self.m_publicConfig.SoundConfig.Music_Fg_OverStart, 2, 0, 1)
    local strCoins = util_formatCoinsLN(globalData.slotRunData.lastWinCoin, 30)
    local view = self:showFreeSpinOver(strCoins, self.m_runSpinResultData.p_freeSpinsTotalCount, function()
        self:showBaseToFreeSceneAni(function()
            self:triggerFreeSpinOverCallFun()
        end)
    end)
    local node=view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=0.9,sy=0.9},826)
    view:findChild("root"):setScale(self.m_machineRootScale) 
end

-- 显示free spin
function CodeGameScreenBankCrazeMachine:showEffect_FreeSpin(effectData)
    self.m_beInSpecialGameTrigger = true
    local waitTime = 0
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        self:levelDeviceVibrate(6, "free")
    end
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if slotNode then
                if slotNode.p_symbolType == self.SYMBOL_SCORE_FREE_BONUS then
                    local bonusZorder = 10 - iRow + iCol
                    local parent = slotNode:getParent()
                    if parent ~= self.m_clipParent then
                        slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, self.SYMBOL_SCORE_FREE_BONUS,0)
                    else
                        slotNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 5 + bonusZorder)
                    end
                    slotNode:runAnim("actionframe")
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
function CodeGameScreenBankCrazeMachine:showLineFrameByIndex(winLines,frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
        return
    end
    CodeGameScreenBankCrazeMachine.super.showLineFrameByIndex(self, winLines, frameIndex)    
end

---
    -- 显示所有的连线框
    --
function CodeGameScreenBankCrazeMachine:showAllFrame(winLines)
    local tempLineValue = {}
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue.enumSymbolEffectType ~= GameEffect.EFFECT_FREE_SPIN then
            table.insert(tempLineValue, lineValue)
        end
    end
    CodeGameScreenBankCrazeMachine.super.showAllFrame(self, tempLineValue)    
end

function CodeGameScreenBankCrazeMachine:getFsTriggerSlotNode(parentData, symPosData)
    return self:getFixSymbol(symPosData.iY, symPosData.iX)    
end

function CodeGameScreenBankCrazeMachine:initJackPotBarView()
    self.m_jackPotBarView = util_createView("CodeBankCrazeSrc.BankCrazeJackPotBarView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("JackpotBar"):addChild(self.m_jackPotBarView) --修改成自己的节点    
end

--[[
    显示jackpotWin
]]
function CodeGameScreenBankCrazeMachine:showJackpotView(coins,jackpotType,func)
    self:setMaxMusicBGVolume()
    local view = util_createView("CodeBankCrazeSrc.BankCrazeJackpotWinView",{jackpotType = jackpotType,
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

--[[
    显示钱袋子弹板奖励
]]
function CodeGameScreenBankCrazeMachine:showBonusBagWinView(_parmsTbl)
    local winAmount = self.m_runSpinResultData.p_winAmount
    local hideCallFunc = _parmsTbl.hideCallFunc
    local endCallFunc = _parmsTbl.callFunc
    local view = util_createView("CodeBankCrazeBonusSrc.BankCrazeBonusBagWinView",{
        winCoin = winAmount,
        machine = self,
        isGold = _parmsTbl.isGold,
        hideCallFunc = function()
            if type(hideCallFunc) == "function" then
                hideCallFunc()
            end
        end,
        func = function()
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

--[[
    显示宝箱弹板奖励
]]
function CodeGameScreenBankCrazeMachine:showBonusBoxWinView(_parmsTbl)
    local winAmount = self.m_runSpinResultData.p_winAmount
    local baseCoins = _parmsTbl.baseCoins
    local hideCallFunc = _parmsTbl.hideCallFunc
    local endCallFunc = _parmsTbl.callFunc
    local isManyCoin = false
    if winAmount >= baseCoins then
        isManyCoin = true
    end
    local view = util_createView("CodeBankCrazeBonusSrc.BankCrazeBonusBoxWinView",{
        winCoin = winAmount,
        machine = self,
        isManyCoin = isManyCoin,
        isGold = _parmsTbl.isGold,
        hideCallFunc = function()
            if type(hideCallFunc) == "function" then
                hideCallFunc()
            end
        end,
        func = function()
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

-- 显示选择加成more界面
function CodeGameScreenBankCrazeMachine:showBonusMoreView(_parmsTbl)
    local hideCallFunc = _parmsTbl.hideCallFunc
    local endCallFunc = _parmsTbl.callFunc
    local view = util_createView("CodeBankCrazeBonusSrc.BankCrazeBonusMoreView",{
        machine = self,
        isGold = _parmsTbl.isGold,
        hideCallFunc = function()
            if type(hideCallFunc) == "function" then
                hideCallFunc()
            end
        end,
        func = function()
            if type(endCallFunc) == "function" then
                endCallFunc()
            end
        end
    })

    gLobalViewManager:showUI(view)
    view:findChild("root"):setScale(self.m_machineRootScale)    
end

--设置长滚信息
function CodeGameScreenBankCrazeMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
        
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount

        local columnSlotsList = self.m_reelSlotsList[col]  -- 提取某一列所有内容

        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)

            for checkRunIndex = preRunLen + iRow,1,-1 do
                local checkData = columnSlotsList[checkRunIndex]
                if checkData == nil then
                    break
                end
                columnSlotsList[checkRunIndex] = nil
                columnSlotsList[checkRunIndex + addRun] = checkData
            end
        end
        
        local runLen = reelRunData:getReelRunLen()
        
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)

        if self.m_curSpinIsRunLong and col == self.m_iReelColumnNum-1 and not self.b_gameTipFlag and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --下列长滚
            reelRunData:setNextReelLongRun(true)
            bRunLong = true
        end
    end --end  for col=1,iColumn do
end

--播放预告中奖统一接口
function CodeGameScreenBankCrazeMachine:showFeatureGameTip(_func)
    if self:getFeatureGameTipChance(40) then
        --播放预告中奖动画
        self:playFeatureNoticeAni(function()
            if type(_func) == "function" then
                _func()
            end
        end)
    else
        self.m_curSpinIsRunLong = self:getCurSpinIsRunLong()
        self.m_curSpinIsHaveBigBonus = self:getCurBuLingIsHaveBigBonus()
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
function CodeGameScreenBankCrazeMachine:playFeatureNoticeAni(_func)
    local callFunc = _func
    self.b_gameTipFlag = true
    gLobalSoundManager:playSound(self.m_publicConfig.SoundConfig.Music_YuGao_Sound)
    self.m_yuGaoSpine:setVisible(true)
    util_spinePlay(self.m_yuGaoSpine, "actionframe", false)
    util_spineEndCallFunc(self.m_yuGaoSpine, "actionframe", function()
        self.m_yuGaoSpine:setVisible(false)
        if type(callFunc) == "function" then
            callFunc()
        end
    end) 
end

--[[
    获取jackpot类型及赢得的金币数
]]
function CodeGameScreenBankCrazeMachine:getWinJackpotCoinsAndType(_curJackpotType)
    local jackpotCoins = self.m_runSpinResultData.p_jackpotCoins or {}
    for jackpotType,coins in pairs(jackpotCoins) do
        if string.lower(jackpotType) == _curJackpotType then
            return coins
        end
    end
    return 0    
end

-- 显示遮罩
function CodeGameScreenBankCrazeMachine:showMask(_showState, _index)
    local showState = _showState
    local index = _index
    
    if _showState then
        if not self.m_maskAni:isVisible() then
            self.m_maskAni:setVisible(true)
            self.m_maskAni:runCsbAction("start", false, function()
                self.m_maskAni:runCsbAction("idle", true)
            end)
        end
    else
        self.m_curTriggerPlayTbl[index] = false
        local isOver = true
        for k, v in pairs(self.m_curTriggerPlayTbl) do
            if v then
                isOver = false
                break
            end
        end
        if isOver and self.m_maskAni:isVisible() then
            self.m_maskAni:runCsbAction("over", false, function()
                self.m_maskAni:setVisible(false)
            end)
        end
    end
end

function CodeGameScreenBankCrazeMachine:changeBgAndReelBg(_bgType)
    -- 1.base；2.freespin
    for i=1, 2 do
        if i == _bgType then
            self.m_bgType[i]:setVisible(true)
        else
            self.m_bgType[i]:setVisible(false)
        end
    end
    if _bgType <= 3 then
        local bgType = _bgType
        self:setReelBgState(bgType)
    end
end

function CodeGameScreenBankCrazeMachine:setReelBgState(_bgType)
    for i=1, 2 do
        if i == _bgType then
            self.m_reelBg[i]:setVisible(true)
        else
            self.m_reelBg[i]:setVisible(false)
        end
    end
end

---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenBankCrazeMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()
    if not nodeParent and slotNode.p_cloumnIndex then
        --如果没有父类就放到当前列中
        nodeParent = self:getReelParent(slotNode.p_cloumnIndex)
    end

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = self:getClipParentChildShowOrder(slotNode)
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    -- 切换图层
    local curZorder = slotNode.p_showOrder
    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    if self:getCurrSpinMode() == FREE_SPIN_MODE and self:getCurSymbolIsBigSymbol(slotNode.p_symbolType) then
        curZorder = -100
    end
    util_changeNodeParent(self.m_clipParent, slotNode, self:getMaskLayerSlotNodeZorder(slotNode) + curZorder)
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenBankCrazeMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            if self:getCurrSpinMode() == FREE_SPIN_MODE and self:getCurSymbolIsBigSymbol(slotsNode.p_symbolType) then
                self:setSpecialSpineLine(slotsNode)
            else
                slotsNode:runLineAnim()
            end
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

function CodeGameScreenBankCrazeMachine:showEachLineSlotNodeLineAnim(_frameIndex)
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[_frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    if self:getCurrSpinMode() == FREE_SPIN_MODE and self:getCurSymbolIsBigSymbol(slotsNode.p_symbolType) then
                        self:setSpecialSpineLine(slotsNode)
                    else
                        slotsNode:runLineAnim()
                    end
                end
            end
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenBankCrazeMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil and not tolua.isnull(slotsNode) then
            self:setSpecialSpineIdle(slotsNode)
            slotsNode:runIdleAnim()
        end
    end
end

--播放第五列wild连线动画
function CodeGameScreenBankCrazeMachine:setSpecialSpineLine(_slotsNode)
    local curBigSymbolNode = self.m_freeBigSymbolNode
    if not tolua.isnull(curBigSymbolNode) then
        self.m_freeBigSymbolNode.m_curActName = "actionframe"
        curBigSymbolNode:runAnim("actionframe", true)
    end
end

--播放连线动画后播放idle判断变身后的wild、bigwild、wild字体是否需要播放
function CodeGameScreenBankCrazeMachine:setSpecialSpineIdle(_slotsNode)
    local curBigSymbolNode = self.m_freeBigSymbolNode
    if not tolua.isnull(curBigSymbolNode) then
        self.m_freeBigSymbolNode.m_curActName = "idleframe"
        curBigSymbolNode:runAnim("idleframe", true)
    end
end

function CodeGameScreenBankCrazeMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end

    local lineWinCoins = self:getClientWinCoins()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.lines_coins then
        lineWinCoins = selfData.lines_coins
    end
    local bonusCoins = 0
    if selfData and selfData.bonus_coins then
        bonusCoins = selfData.bonus_coins
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

function CodeGameScreenBankCrazeMachine:bonusBtnIsCanClick()
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

-- 当前是否是free
function CodeGameScreenBankCrazeMachine:getCurFeatureIsFree()
    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        return true
    end

    return false
end

--[[
    @desc: 根据关卡配置执行信号落地的提层、动画、回弹
    time:2021-12-07 14:55:10
    --@slotNodeList:
	--@speedActionTable: 减速回弹动作和 BaseMachine:MachineRule_reelDown 做了绑定，如果对应接口实现逻辑有改动，这个接口可能也需要改动(如: xxBy -> xxTo)
    @return:
]]
function CodeGameScreenBankCrazeMachine:playSymbolBulingAnim(slotNodeList, speedActionTable)
    local bulingAnimCfg = self.m_configData.p_symbolBulingAnimList
    if not bulingAnimCfg then
        return
    end

    for k, _slotNode in pairs(slotNodeList) do
        local symbolCfg = bulingAnimCfg[_slotNode.p_symbolType]
        if symbolCfg then
            -- 是否是最终信号
            local columnData = self.m_reelColDatas[_slotNode.p_cloumnIndex]
            if _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount and not self:getCurSymbolIsBigSymbol(_slotNode.p_symbolType) then
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
                self:playBulingAnimFunc(_slotNode,symbolCfg)
            else
                if self:getCurSymbolIsBigSymbol(_slotNode.p_symbolType) and _slotNode.m_isLastSymbol == true and _slotNode.p_rowIndex <= columnData.p_showGridCount then
                    _slotNode:runAnim("idleframe2", true)
                end
            end
        end
    end
end

function CodeGameScreenBankCrazeMachine:checkSymbolBulingAnimPlay(_slotNode)
    -- 和音效保持一致
    return self:checkSymbolBulingSoundPlay(_slotNode, true)
end

-- 有特殊需求判断的 重写一下
function CodeGameScreenBankCrazeMachine:checkSymbolBulingSoundPlay(_slotNode, _buLing)
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
            elseif self:getCurIsRunLongBonus(_slotNode.p_symbolType) then
                return true
            elseif self:getCurSymbolIsBigSymbol(_slotNode.p_symbolType) then
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    return false
                else
                    if self.m_curSpinIsHaveBigBonus then
                        if _buLing then
                            return true
                        else
                            if self:getCurIsHaveBigBonus() then
                                return true
                            else
                                return false
                            end
                        end
                    else
                        return false
                    end
                end
                -- 不为 scatter 和 bonus 时 不走快滚判断
                return true
            end
        end
    end

    return false
end

-- BG和FG快停时，多个图标同时落地只播一个音效：Trigger Bonus123图标落地＞Free Bonus＞JP Bonus＞Save Bonus＞Bonus1
function CodeGameScreenBankCrazeMachine:playQuickStopBulingSymbolSound(_iCol)
    if self:getGameSpinStage() == QUICK_RUN then
        if _iCol == self.m_iReelColumnNum then
            local soundIds = {}
            local bulingDatas = self.m_symbolQsBulingSoundArray
            local newBulingDatas = {}
            for soundType, soundPaths in pairs(bulingDatas) do
                local soundPath = soundPaths[#soundPaths]

                -- 长条bonus
                if not next(newBulingDatas) then
                    local result = string.match(soundPath, "BonusBig_buling")
                    if result then
                        table.insert(newBulingDatas, soundPath)
                    end
                end

                -- freeBonus
                if not next(newBulingDatas) then
                    local result = string.match(soundPath, "freeBonus_buling")
                    if result then
                        table.insert(newBulingDatas, soundPath)
                    end
                end

                -- jackpotBonus
                if not next(newBulingDatas) then
                    local result = string.match(soundPath, "jackpotBonus_buling")
                    if result then
                        table.insert(newBulingDatas, soundPath)
                    end
                end

                -- saveBonus
                if not next(newBulingDatas) then
                    local result = string.match(soundPath, "saveBonus_buling")
                    if result then
                        table.insert(newBulingDatas, soundPath)
                    end
                end

                -- BonusCoins
                if not next(newBulingDatas) then
                    local result = string.match(soundPath, "BonusCoins_buling")
                    if result then
                        table.insert(newBulingDatas, soundPath)
                    end
                end
            end

            for soundType, soundPath in pairs(newBulingDatas) do
                -- local soundPath = soundPaths[#soundPaths]
                local soundId = gLobalSoundManager:playSound(soundPath)
                table.insert(soundIds, soundId)
            end

            return soundIds
        end
    end
end

-- 一些关卡在buling结束后需要转播idleframe或者其他时间线的话，重写这个回调即可
function CodeGameScreenBankCrazeMachine:symbolBulingEndCallBack(_slotNode)
    if self:getCurIsRunLongBonus(_slotNode.p_symbolType) or self:getCurSymbolIsBigSymbol(_slotNode.p_symbolType) then
        _slotNode:runAnim("idleframe2", true)
    end
end

return CodeGameScreenBankCrazeMachine
