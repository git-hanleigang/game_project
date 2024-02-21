---
-- island li
-- 2019年1月26日
-- CodeGameScreenMermaidMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseFastMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")

local CodeGameScreenMermaidMachine = class("CodeGameScreenMermaidMachine", BaseFastMachine)

CodeGameScreenMermaidMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenMermaidMachine.SYMBOL_SMALL_FIX_BONUS = 94
CodeGameScreenMermaidMachine.SYMBOL_SMALL_FIX_GRAND = 98
CodeGameScreenMermaidMachine.SYMBOL_SMALL_FIX_MAJOR = 97
CodeGameScreenMermaidMachine.SYMBOL_SMALL_FIX_MINOR = 96
CodeGameScreenMermaidMachine.SYMBOL_SMALL_FIX_MINI = 95

CodeGameScreenMermaidMachine.SYMBOL_BIG_LONG_WILD = 200

CodeGameScreenMermaidMachine.SYMBOL_BIG_FIX_BONUS = 194
CodeGameScreenMermaidMachine.SYMBOL_BIG_FIX_GRAND = 198
CodeGameScreenMermaidMachine.SYMBOL_BIG_FIX_MAJOR = 197
CodeGameScreenMermaidMachine.SYMBOL_BIG_FIX_MINOR = 196
CodeGameScreenMermaidMachine.SYMBOL_BIG_FIX_MINI = 195

CodeGameScreenMermaidMachine.SYMBOL_BIG_SCATTER = 190
CodeGameScreenMermaidMachine.SYMBOL_BIG_WILD = 192

CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_1 = 108
CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_2 = 107
CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_3 = 106
CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_4 = 105
CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_5 = 104
CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_6 = 103
CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_7 = 102
CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_8 = 101
CodeGameScreenMermaidMachine.SYMBOL_BIG_SCORE_9 = 100

CodeGameScreenMermaidMachine.m_chipList = nil
CodeGameScreenMermaidMachine.m_playAnimIndex = 0
CodeGameScreenMermaidMachine.m_lightScore = 0
CodeGameScreenMermaidMachine.m_respinLittleNodeSize = 2

CodeGameScreenMermaidMachine.m_FsMiniReel = nil
CodeGameScreenMermaidMachine.m_isInCollectBonus = nil

CodeGameScreenMermaidMachine.Fs_Light_AddCoins_Top_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1
CodeGameScreenMermaidMachine.Fs_Light_AddCoins_Down_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenMermaidMachine.Base_Ice_Break_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3
CodeGameScreenMermaidMachine.Fs_AddTimes_Top_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4
CodeGameScreenMermaidMachine.Fs_AddTimes_Down_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 5

CodeGameScreenMermaidMachine.m_lockNodeArray = {}
CodeGameScreenMermaidMachine.m_lockNumArray = {8, 12, 16, 20}

CodeGameScreenMermaidMachine.m_actRsNode = {}

CodeGameScreenMermaidMachine.m_fsLastWinCoins = 0

local RESPIN_ROW_COUNT = 8
local NORMAL_ROW_COUNT = 4

local FIT_HEIGHT_MAX = 1660
local FIT_HEIGHT_MIN = 1054

-- 构造函数
function CodeGameScreenMermaidMachine:ctor()
    BaseFastMachine.ctor(self)

    -- 兼容处理，以免玩家未热更底层代码却下载了最新的关卡代码导致常量值为空
    REWAED_FREE_SPIN_MODE = REWAED_FREE_SPIN_MODE or 6

    self.m_isOpenRewaedFreeSpin = true -- 是否开启免费送spin活动
    self.m_isFeatureOverBigWinInFree = true
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_FsMiniReel = nil
    self.m_isInCollectBonus = false
    self.m_actRsNode = {}
    self.m_lockNodeArray = {}
    self.m_norDownTimes = 0
    self.m_norSlotsDownTimes = 0
    self.m_LocalData_p_winLines = {}
    self.m_fsLastWinCoins = 0
    self.isInBonus = false
    self.m_bCreateResNode = true

    self.m_respinCollectBet = 5
    self.m_showClick = nil
    self.m_hideTip = nil

    self.m_jackpot_status = "Normal"
    self.m_isJackpotEnd = false

	--init
	self:initGame()
end

function CodeGameScreenMermaidMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("MermaidConfig.csv", "LevelMermaidConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenMermaidMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Mermaid"
end

-- 继承底层respinView
function CodeGameScreenMermaidMachine:getRespinView()
    return "CodeMermaidSrc.MermaidRespinView"
end
-- 继承底层respinNode
function CodeGameScreenMermaidMachine:getRespinNode()
    return "CodeMermaidSrc.MermaidRespinNode"
end

function CodeGameScreenMermaidMachine:initFreeSpinBar()

    local node_bar = self.m_bottomUI:findChild("node_bar")

    self.m_Mermaid_Fsbar = util_createView("CodeMermaidSrc.MermaidFreespinBarView")
    node_bar:addChild(self.m_Mermaid_Fsbar)
    self.m_Mermaid_Fsbar:setVisible(false)
    self.m_baseFreeSpinBar = self.m_Mermaid_Fsbar

    local pos = util_convertToNodeSpace(self:findChild("root"),node_bar)
    self.m_Mermaid_Fsbar:setPosition(cc.p(pos.x,100))
end

function CodeGameScreenMermaidMachine:initUI()
    local bottomHeight = util_getSaveAreaBottomHeight()
    local bangHeight = util_getBangScreenHeight()

    if display.height / display.width >= 2 then
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bottomHeight - bangHeight)
    end

    self.m_reelRunSound = "MermaidSounds/Mermaid_longRun.mp3"

    -- 创建view节点方式
    -- self.m_MermaidView = util_createView("CodeMermaidSrc.MermaidView")
    -- self:findChild("xxxx"):addChild(self.m_MermaidView)

    self.m_logo = util_spineCreate("Mermaid_idle", true, true)
    self:findChild("Node_logo"):addChild(self.m_logo)
    util_spinePlay(self.m_logo, "idleframe", true)

    self.m_Mermaid_JpBarView = util_createView("CodeMermaidSrc.MermaidJackPotBarView")
    self:findChild("jackpot_WINNER"):addChild(self.m_Mermaid_JpBarView)
    self.m_Mermaid_JpBarView:initMachine(self)

    self.m_Mermaid_Fe_JpBarView = util_createView("CodeMermaidSrc.MermaidJackPotBar_Feature_View")
    self:findChild("jackpot_WINNER"):addChild(self.m_Mermaid_Fe_JpBarView)
    self.m_Mermaid_Fe_JpBarView:initMachine(self)
    self.m_Mermaid_Fe_JpBarView:setVisible(false)

    self:findChild("jindutiao"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    self.m_Mermaid_loadingbar = util_createView("CodeMermaidSrc.MermaidLoadingBarView")
    self:findChild("jindutiao"):addChild(self.m_Mermaid_loadingbar)
    self.m_Mermaid_loadingbar:initMachine(self)
    self.m_Mermaid_loadingbar:initBarQiPao()

    self.m_Mermaid_Rsbar = util_createView("CodeMermaidSrc.MermaidRsBarView")
    self:findChild("respin_counter"):addChild(self.m_Mermaid_Rsbar)
    self.m_Mermaid_Rsbar:setVisible(false)

    self:initFreeSpinBar() -- FreeSpinbar

    self.m_Mermaid_RsReword = util_createAnimation("Mermaid_WINNER.csb")
    self:findChild("jackpot_WINNER"):addChild(self.m_Mermaid_RsReword)
    self.m_Mermaid_RsReword:setVisible(false)

    self.m_IceMainNode = cc.Node:create()
    self:findChild("reel"):addChild(self.m_IceMainNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER - 100)
    self:initIceSymbol()

    local reelData = {}
    reelData.index = 1
    reelData.parent = self
    self.m_FsMiniReel = util_createView("MiniMachineReel/MermaidMiniMachine", reelData)
    self:findChild("Node_MinIFsReel"):addChild(self.m_FsMiniReel)
    self:findChild("Node_MinIFsReel"):setVisible(false)
    if self.m_bottomUI.m_spinBtn.addTouchLayerClick then
        self.m_bottomUI.m_spinBtn:addTouchLayerClick(self.m_FsMiniReel.m_touchSpinLayer)
    end

    self.m_tipView = util_createAnimation("Mermaid_jackPoTip.csb")
    self:findChild("jackPoTip"):addChild(self.m_tipView)
    self:findChild("jackPoTip"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)
    self.m_tipView:setVisible(false)

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

    self.m_FsGuoChangSpine_1 = util_spineCreate("Mermaid_guochang", true, true)
    self:addChild(self.m_FsGuoChangSpine_1, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    self.m_FsGuoChangSpine_1:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_FsGuoChangSpine_1:setVisible(false)

    self.m_GuoChangView = util_createView("CodeMermaidSrc.MermaidGuoChangView", true)
    self:addChild(self.m_GuoChangView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_GuoChangView:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_GuoChangView:setVisible(false)

    self.m_RunDi = {}
    for i = 1, 5 do
        local longRunDi = util_createAnimation("WinFrameMermaid_run_bg.csb")
        self:findChild("reel"):addChild(longRunDi, 1)
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_" .. (i - 1)):getPosition()))
        table.insert(self.m_RunDi, longRunDi)
        longRunDi:setVisible(false)
    end

    for i = 1, 4 do
        self.m_lockNodeArray[#self.m_lockNodeArray + 1] = util_createView("CodeMermaidSrc.MermaidRespinLockReels")
        local index = 5 - i
        self:findChild("Lock_" .. index):addChild(self.m_lockNodeArray[#self.m_lockNodeArray])
    end
    self:hideAllLockNode()

    self.m_FsGuoChangSpine = util_spineCreate("Mermaid_guochang", true, true)
    self:findChild("Node_Fs_StartGuoChang"):addChild(self.m_FsGuoChangSpine)
    self.m_FsGuoChangSpine:setVisible(false)

    self.m_FsGuoChangQiPao = util_createAnimation("Mermaid_qipao.csb")
    self:findChild("Node_Fs_StartGuoChang"):addChild(self.m_FsGuoChangQiPao, 1)
    self.m_FsGuoChangQiPao:setVisible(false)
    self.m_FsGuoChangQiPao:setPositionX(300)

    self.m_FsGuoChangBg_1 = util_createAnimation("Mermaid_guochang_1.csb")
    self:findChild("Node_fsGuoChangBg_1"):addChild(self.m_FsGuoChangBg_1)
    self.m_FsGuoChangBg_1:setVisible(false)

    self.m_FsGuoChangBg_2 = util_createAnimation("Mermaid_guochang_1.csb")
    self:findChild("Node_fsGuoChangBg_2"):addChild(self.m_FsGuoChangBg_2)
    self.m_FsGuoChangBg_2:setVisible(false)

    self.m_FsGuoChangQiPao_1 = util_createAnimation("Mermaid_guochang_0.csb")
    self:findChild("Node_fsGuoChangQipao_1"):addChild(self.m_FsGuoChangQiPao_1)
    self.m_FsGuoChangQiPao_1:setVisible(false)

    self.m_FsGuoChangQiPao_2 = util_createAnimation("Mermaid_guochang_0.csb")
    self:findChild("Node_fsGuoChangQipao_2"):addChild(self.m_FsGuoChangQiPao_2)
    self.m_FsGuoChangQiPao_2:setVisible(false)

    -- self.m_collectEffect = util_createAnimation("Mermaid_fankui.csb")
    -- self.m_bottomUI:getCoinWinNode():addChild(self.m_collectEffect)
    -- self.m_collectEffect:setVisible(false)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
            local winCoin = params[1]

            local totalBet = globalData.slotRunData:getCurTotalBet()
            local winRate = winCoin / totalBet
            local soundIndex = 2
            local soundTime = 2
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2
                soundTime = 3
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 3
                soundTime = 3
            elseif winRate > 6 then
                soundIndex = 3
                soundTime = 3
            end

            local freeSpinsLeftCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            local freeSpinsTotalCount = self.m_runSpinResultData.p_freeSpinsTotalCount
            if freeSpinsLeftCount == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
                print("freespin最后一次 无论是否大赢都播放赢钱音效")
            else
                if winRate >= self.m_HugeWinLimitRate then
                    return
                elseif winRate >= self.m_MegaWinLimitRate then
                    return
                elseif winRate >= self.m_BigWinLimitRate then
                    return
                end
            end

            local lines = self.m_reelResultLines or {}

            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if lines == nil or #lines == 0 then
                    lines = self:getFreeSpinReelsLines() or {}
                end
            end

            if #lines == 0 then
                return
            end

            local soundName = "MermaidSounds/music_Mermaid_last_win_" .. soundIndex .. ".mp3"
            self.m_winSoundsId = globalMachineController:playBgmAndResume(soundName, soundTime, 0.4, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function CodeGameScreenMermaidMachine:setScatterDownScound()
    for i = 1, 5 do
        local soundPath = nil
        if i == 1 then
            soundPath = "MermaidSounds/Mermaid_scatter_down.mp3"
        elseif i == 2 then
            soundPath = "MermaidSounds/Mermaid_scatter_down2.mp3"
        else
            soundPath = "MermaidSounds/Mermaid_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function CodeGameScreenMermaidMachine:isNormalStates()
    local isNormal = true

    local features = self.m_runSpinResultData.p_features or {}
    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_FREESPIN then
        isNormal = false
    end

    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_RESPIN then
        isNormal = false
    end

    if #features >= 2 and features[2] == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
        if self.m_initFeatureData and self.m_initFeatureData.p_status then
            if self.m_initFeatureData.p_status ~= "CLOSED" then
                isNormal = false
            end
        else
            isNormal = false
        end
    end

    if self.m_runSpinResultData.p_reSpinCurCount and self.m_runSpinResultData.p_reSpinCurCount > 0 then
        isNormal = false
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        isNormal = false
    end

    if self:getCurrSpinMode() == RESPIN_MODE then
        isNormal = false
    end

    if self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        isNormal = false
    end

    if self.m_isInCollectBonus then
        isNormal = false
    end

    return isNormal
end

function CodeGameScreenMermaidMachine:getBottomUINode()
    return "CodeMermaidSrc.MermaidGameBottomNode"
end

function CodeGameScreenMermaidMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            if not self.isInBonus then
                if not self:checkHasGameEffectType(GameEffect.EFFECT_REWARD_FS_START) then
                    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_enter.mp3")
                end
                

                scheduler.performWithDelayGlobal(
                    function()
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    end,
                    2.5,
                    self:getModuleName()
                )
            end
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenMermaidMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    if self:isNormalStates() then
        self.m_tipView:setVisible(true)
        self.m_tipView:runCsbAction(
            "open",
            false,
            function()
                if not self.m_tipView.isSpin then
                    self.m_tipView:runCsbAction("idle", true)

                    performWithDelay(
                        self.m_actNode,
                        function()
                            if not self.m_tipView.isSpin then
                                self.m_tipView.isOverAct = true
                                self.m_tipView:runCsbAction(
                                    "over",
                                    false,
                                    function()
                                        self.m_showClick = true
                                        self.m_tipView:setVisible(false)
                                    end
                                )
                            end
                        end,
                        3
                    )
                end
            end
        )
    end

    self:updateLoadingQiPaoVisible()
    self:updateIceSymbolVisible()
    self.m_Mermaid_JpBarView:updateJackpotInfo()
    self.m_Mermaid_Fe_JpBarView:updateJackpotInfo()

    self:checkUpateDefaultBet()
    self:initTopCommonJackpotBar()
    self:updataJackpotStatus()
    
    
    BaseFastMachine.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    local hasFeature = self:checkHasFeature()
    if self:getCurrSpinMode() == NORMAL_SPIN_MODE and not hasFeature then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_ONENTER)
    end

    -- local fixPos = self:getRowAndColByPos(11)
    -- local targSp = self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
end

function CodeGameScreenMermaidMachine:addObservers()
    BaseFastMachine.addObservers(self)
    gLobalNoticManager:addObserver(self,function(self, params)
        --公共jackpot
        self:updataJackpotStatus(params)
    end,ViewEventType.NOTIFY_BET_CHANGE)

    --公共jackpot活动结束
    gLobalNoticManager:addObserver(self,function(target, params)

        if params.name == ACTIVITY_REF.CommonJackpot then
            self.m_isJackpotEnd = true
            self:updataJackpotStatus()
        end

    end,ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function CodeGameScreenMermaidMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())

    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearTitleNode()
    G_GetMgr(ACTIVITY_REF.CommonJackpot):clearEntryNode()
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenMermaidMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SMALL_FIX_BONUS then
        return "Socre_Mermaid_linghting"
    elseif symbolType == self.SYMBOL_SMALL_FIX_GRAND then
        return "Socre_Mermaid_linghting_Grand"
    elseif symbolType == self.SYMBOL_SMALL_FIX_MAJOR then
        return "Socre_Mermaid_linghting_Major"
    elseif symbolType == self.SYMBOL_SMALL_FIX_MINOR then
        return "Socre_Mermaid_linghting_Minor"
    elseif symbolType == self.SYMBOL_SMALL_FIX_MINI then
        return "Socre_Mermaid_linghting_Mini"
    elseif symbolType == self.SYMBOL_BIG_FIX_BONUS then
        return "Socre_Mermaid_big_linghting"
    elseif symbolType == self.SYMBOL_BIG_FIX_GRAND then
        return "Socre_Mermaid_big_linghting_Grand"
    elseif symbolType == self.SYMBOL_BIG_FIX_MAJOR then
        return "Socre_Mermaid_big_linghting_Major"
    elseif symbolType == self.SYMBOL_BIG_FIX_MINOR then
        return "Socre_Mermaid_big_linghting_Minor"
    elseif symbolType == self.SYMBOL_BIG_FIX_MINI then
        return "Socre_Mermaid_big_linghting_Mini"
    elseif symbolType == self.SYMBOL_BIG_SCORE_1 then
        return "Socre_Mermaid_big_1"
    elseif symbolType == self.SYMBOL_BIG_SCORE_2 then
        return "Socre_Mermaid_big_2"
    elseif symbolType == self.SYMBOL_BIG_SCORE_3 then
        return "Socre_Mermaid_big_3"
    elseif symbolType == self.SYMBOL_BIG_SCORE_4 then
        return "Socre_Mermaid_big_4"
    elseif symbolType == self.SYMBOL_BIG_SCORE_5 then
        return "Socre_Mermaid_big_5"
    elseif symbolType == self.SYMBOL_BIG_SCORE_6 then
        return "Socre_Mermaid_big_6"
    elseif symbolType == self.SYMBOL_BIG_SCORE_7 then
        return "Socre_Mermaid_big_7"
    elseif symbolType == self.SYMBOL_BIG_SCORE_8 then
        return "Socre_Mermaid_big_8"
    elseif symbolType == self.SYMBOL_BIG_SCORE_9 then
        return "Socre_Mermaid_big_9"
    elseif symbolType == self.SYMBOL_BIG_SCATTER then
        return "Socre_Mermaid_big_Scatter"
    elseif symbolType == self.SYMBOL_BIG_WILD then
        return "Socre_Mermaid_big_Wild"
    elseif symbolType == self.SYMBOL_BIG_LONG_WILD then
        return "Socre_Mermaid_Wild_0"
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenMermaidMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_BONUS, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_GRAND, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SMALL_FIX_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_FIX_BONUS, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_FIX_GRAND, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_FIX_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_FIX_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_FIX_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_6, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_7, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_8, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCORE_9, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_SCATTER, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_WILD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_BIG_LONG_WILD, count = 2}

    return loadNode
end

function CodeGameScreenMermaidMachine:checkFreeSpinShowUI(isFreeSpin)
    if isFreeSpin then
        self.m_IceMainNode:setVisible(false)
        self.m_Mermaid_loadingbar:setVisible(false)
        self.m_Mermaid_JpBarView:setVisible(false)
        self.m_Mermaid_Fe_JpBarView:setVisible(true)
        self.m_Mermaid_Fe_JpBarView:runCsbAction("idleframe")

        self:findChild("Node_MinIFsReel"):setVisible(true)
        self:findChild("Node_logo"):setVisible(false)
        self:findChild("jindutiao"):setVisible(false)
    else
        self.m_IceMainNode:setVisible(true)
        self.m_Mermaid_loadingbar:setVisible(true)
        self.m_Mermaid_JpBarView:setVisible(true)
        self.m_Mermaid_Fe_JpBarView:setVisible(false)
        self.m_Mermaid_Fe_JpBarView:runCsbAction("idleframe")
        self:findChild("Node_MinIFsReel"):setVisible(false)
        self:findChild("Node_logo"):setVisible(true)
        self:findChild("jindutiao"):setVisible(true)
    end
end

function CodeGameScreenMermaidMachine:checkReSpinShowUI(respin)
    if respin then
        self:findChild("Node_logo"):setVisible(false)
        self.m_IceMainNode:setVisible(false)
        self.m_Mermaid_loadingbar:setVisible(false)
        self.m_Mermaid_JpBarView:setVisible(false)
        self.m_Mermaid_Fe_JpBarView:setVisible(true)
        self.m_Mermaid_Fe_JpBarView:runCsbAction("idleframe")
    else
        self:findChild("Node_logo"):setVisible(true)
        self.m_IceMainNode:setVisible(true)
        self.m_Mermaid_loadingbar:setVisible(true)
        self.m_Mermaid_JpBarView:setVisible(true)
        self.m_Mermaid_Fe_JpBarView:setVisible(false)
        self.m_Mermaid_Fe_JpBarView:runCsbAction("idleframe")
    end
end

----------------------------- 玩法处理 -----------------------------------

-- 断线重连
function CodeGameScreenMermaidMachine:MachineRule_initGame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_bCreateResNode = false

        self:changeFreeSpinReelData()
        self:checkFreeSpinShowUI(true)
        self:changeReelDataBySpinMode(1)
        self:runCsbAction("idle2")
        self.m_fsLastWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    end

    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) then
        self.m_iReelRowNum = #self.m_runSpinResultData.p_reels
        self:respinChangeReelGridCount(#self.m_runSpinResultData.p_reels)
    end

    if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        self:showAllLockNode()
    end

    self:updateBigSymbolColumnInfo()
end

function CodeGameScreenMermaidMachine:slotReelDown()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setDownTimes(1)
    else
        BaseFastMachine.slotReelDown(self)

        self:checkTriggerOrInSpecialGame(
            function()
                self:reelsDownDelaySetMusicBGVolume()
            end
        )
    end
end

---
--添加金边
function CodeGameScreenMermaidMachine:creatReelRunAnimation(col)
    BaseFastMachine.creatReelRunAnimation(self, col)

    if self.m_RunDi[col] ~= nil then
        local reelEffectNodeBg = self.m_RunDi[col]
        reelEffectNodeBg:setVisible(true)
        reelEffectNodeBg:runCsbAction("animation0", true)
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenMermaidMachine:slotOneReelDown(reelCol)
    if self.m_RunDi[reelCol] ~= nil then
        local reelEffectNodeBg = self.m_RunDi[reelCol]

        if reelEffectNodeBg:isVisible() then
            reelEffectNodeBg:setVisible(false)
            reelEffectNodeBg:runCsbAction("idle")
        end
    end

    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end

    if self.m_reelDownSoundPlayed then
        if self:checkIsPlayReelDownSound(reelCol) then
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if reelCol == 1 or reelCol == 3 or reelCol == 5 then
                    gLobalSoundManager:playSound(self.m_reelDownSound)
                end
            else
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        end
        self:setReelDownSoundId(reelCol, self.m_reelDownSoundPlayed)
    else
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if reelCol == 1 or reelCol == 3 or reelCol == 5 then
                gLobalSoundManager:playSound(self.m_reelDownSound)
            end
        else
            gLobalSoundManager:playSound(self.m_reelDownSound)
        end
    end

    -- if  self:getGameSpinStage() ~= QUICK_RUN  then

    -- end

    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]

        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            -- if  self:getGameSpinStage() == QUICK_RUN  then
            --     gLobalSoundManager:playSound(self.m_reelDownSound)
            -- end
            reelEffectNode[1]:runAction(cc.Hide:create())
        -- if self.m_reelRunInfo[reelCol]:getReelLongRun() == true then
        --     self:reductionReel(reelCol)
        -- end
        end
    end

    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenMermaidMachine:levelFreeSpinEffectChange()
    self.m_bCreateResNode = false

    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "freespin")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenMermaidMachine:levelFreeSpinOverChangeEffect()
    self.m_bCreateResNode = true

    -- 自定义事件修改背景动画
    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
    self.m_baseFreeSpinBar:restFsNumlab()
end
---------------------------------------------------------------------------

----------- FreeSpin相关

function CodeGameScreenMermaidMachine:showFreeSpinStart(num, func)
    performWithDelay(
        self,
        function()
            if func then
                func()
            end
        end,
        0.5
    )

    -- local ownerlist={}

    -- local view =  util_createView("CodeMermaidSrc.MermaidFreeSpinStartView")
    -- self:findChild("fsStartView"):addChild(view)
    -- view:initCallFunc( func )

    -- return view  --self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START,ownerlist,func)
    -- --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

---
-- 显示free spin
function CodeGameScreenMermaidMachine:showEffect_FreeSpin(effectData)
    -- scheduler.performWithDelayGlobal(function()
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)

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

    -- 停掉背景音乐
    self:clearCurMusicBg()

    -- 播放震动
    if globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        -- freeMore时不播放
        if self.levelDeviceVibrate then
            self:levelDeviceVibrate(6, "free")
        end
    end

    if scatterLineValue ~= nil then
        --
        self:showBonusAndScatterLineTip(
            scatterLineValue,
            function()
                -- self:visibleMaskLayer(true,true)
                -- gLobalSoundManager:stopAllAuido()   -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                self:showFreeSpinView(effectData)
            end
        )
        scatterLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
        -- 播放提示时播放音效
        self:playScatterTipMusicEffect()
    else
        --
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    -- end,1.5,self:getModuleName())

    return true
end

-- FreeSpinstart
function CodeGameScreenMermaidMachine:showFreeSpinView(effectData)
    self:findChild("jackPoTip"):setVisible(false)

    -- gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_custom_enter_fs.mp3")

    local showFSView = function(...)
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else
            self:showFsGuoChang(
                function()
                    util_playFadeOutAction(
                        self.m_baseFreeSpinBar,
                        3 / 30,
                        function()
                            util_playFadeInAction(
                                self.m_baseFreeSpinBar,
                                3 / 30,
                                function()
                                end
                            )
                        end
                    )
                    util_playFadeOutAction(
                        self.m_Mermaid_Fe_JpBarView,
                        3 / 30,
                        function()
                            util_playFadeInAction(
                                self.m_Mermaid_Fe_JpBarView,
                                3 / 30,
                                function()
                                end
                            )
                        end
                    )

                    performWithDelay(
                        self,
                        function()
                            self:showFreeSpinBar()
                            self.m_baseFreeSpinBar:changeFreeSpinByCount()
                            self:checkFreeSpinShowUI(true)
                            self:runCsbAction("idle2")
                            self:levelFreeSpinEffectChange()

                            performWithDelay(
                                self,
                                function()
                                    self:showFreeSpinStart(
                                        self.m_iFreeSpinTimes,
                                        function()
                                            self.m_fsLastWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0

                                            -- self:changeReelDataBySpinMode( 1 )
                                            self:triggerFreeSpinCallFun()

                                            effectData.p_isPlay = true
                                            self:playGameEffect()
                                        end
                                    )
                                end,
                                3 / 30
                            )
                        end,
                        3 / 30
                    )
                end,
                function()
                    self:changeReelDataBySpinMode(1)
                    self:changeReelSymbolNode(true)
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
        1
    )
end

function CodeGameScreenMermaidMachine:showFreeSpinOverView()
    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_Freespin_OverView.mp3")

    local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 50)
    local view =
        self:showFreeSpinOver(
        strCoins,
        self.m_runSpinResultData.p_freeSpinsTotalCount,
        function()
            self:showGuoChang(
                function()
                    self:clearWinLineEffect()
                    self.m_FsMiniReel:clearWinLineEffect()

                    self:findChild("jackPoTip"):setVisible(true)

                    self:runCsbAction("idle1")

                    self:featuresOverAddFreespinEffect()

                    self:changeReelDataBySpinMode(2)
                    self:changeReelSymbolNode()

                    self:triggerFreeSpinOverCallFun()

                    self:checkFreeSpinShowUI()
                end
            )
        end
    )
    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.54, sy = 0.54}, 1184)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenMermaidMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    self.m_merFeatureData = nil

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.isInBonus = false

    self.m_fsLastWinCoins = self.m_runSpinResultData.p_fsWinCoins or 0
    self.m_actLastWinCoins = nil -- 用作freespin中 中了jackpot，bonus更新钱用

    self.m_norDownTimes = 0
    self.m_norSlotsDownTimes = 0

    if not self.m_tipView.isOverAct then
        if not self.m_tipView.isSpin then
            self.m_tipView:runCsbAction(
                "over",
                false,
                function()
                    self.m_showClick = true
                    self.m_tipView:setVisible(false)
                end
            )
        end
    end

    self.m_tipView.isSpin = true

    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenMermaidMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenMermaidMachine:MachineRule_afterNetWorkLineLogicCalculate()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
    end

    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenMermaidMachine:addSelfEffect()
    local lines = self.m_LocalData_p_winLines or {}
    local fslines = self.m_FsMiniReel.m_LocalData_p_winLines or {}
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local newCollect = selfdata.newCollect or {}

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self:checkAddFsLightCoins(fslines) then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.Fs_Light_AddCoins_Top_EFFECT -- 动画类型
        end

        if self:checkAddFsLightCoins(lines) then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.Fs_Light_AddCoins_Down_EFFECT -- 动画类型
        end

        if self.m_FsMiniReel:checkAddFsTimes() then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.Fs_AddTimes_Top_EFFECT -- 动画类型
        end

        if self:checkAddFsTimes() then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.Fs_AddTimes_Down_EFFECT -- 动画类型
        end
    else
        --  base玩法
        if #newCollect > 0 then
            -- 自定义动画创建方式
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.Base_Ice_Break_EFFECT -- 动画类型
        end
    end
end

function CodeGameScreenMermaidMachine:beginFsJpCollectAction()
    local baseJp = {}

    for iRow = self.m_iReelRowNum, 1, -1 do
        local fixSymbol = self:getFixSymbol(1, iRow, SYMBOL_NODE_TAG)
        if fixSymbol and self:isFixSymbol(fixSymbol.p_symbolType) then
            table.insert(baseJp, fixSymbol)
        end
    end

    local bigSymbol = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)
    if bigSymbol and self:isBigFixSymbol(bigSymbol.p_symbolType) then
        table.insert(baseJp, bigSymbol)
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        local fixSymbol = self:getFixSymbol(5, iRow, SYMBOL_NODE_TAG)
        if fixSymbol and self:isFixSymbol(fixSymbol.p_symbolType) then
            table.insert(baseJp, fixSymbol)
        end
    end

    return baseJp
end

function CodeGameScreenMermaidMachine:playfsCollectAni(actList, func, manClass)
    self.m_fsCollectChipCallFunc = function()
        if func then
            func()
        end
    end
    self.m_fsCollectPlayAnimIndex = 1
    self.m_fsCollectChipList = actList
    self.m_mainClass = manClass

    self:playFsCollectChipCollectAnim()
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenMermaidMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.Fs_Light_AddCoins_Top_EFFECT then
        local actList = self.m_FsMiniReel:beginFsJpCollectAction()

        self:playfsCollectAni(
            actList,
            function()
                self:restSelfGameEffects(self.m_FsMiniReel, self.Fs_Light_AddCoins_Top_EFFECT)

                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            self.m_FsMiniReel
        )
    elseif effectData.p_selfEffectType == self.Fs_Light_AddCoins_Down_EFFECT then
        local actList = self:beginFsJpCollectAction()

        self:playfsCollectAni(
            actList,
            function()
                self:restSelfGameEffects(self.m_FsMiniReel, self.Fs_Light_AddCoins_Down_EFFECT)

                effectData.p_isPlay = true
                self:playGameEffect()
            end,
            self
        )
    elseif effectData.p_selfEffectType == self.Base_Ice_Break_EFFECT then
        -- end,9/30)
        gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_IceBreak.mp3")

        self:updateLoadingQiPaoVisible(true)
        self:updateIceSymbolVisible(true)
        -- performWithDelay(self,function(  )
        self:createCollectIceAct(
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    elseif effectData.p_selfEffectType == self.Fs_AddTimes_Top_EFFECT then
        local actNode = self.m_FsMiniReel:checkAddFsTimes()

        self:scatterCollectAction(
            actNode,
            function()
                self.m_baseFreeSpinBar:runCsbAction("actionframe")
                self.m_baseFreeSpinBar:findChild("BitmapFontLabel_2_0"):setString(self.m_baseFreeSpinBar.m_totalFreeSpinCount + 3)
                self.m_baseFreeSpinBar.m_totalFreeSpinCount = self.m_baseFreeSpinBar.m_totalFreeSpinCount + 3

                performWithDelay(
                    self,
                    function()
                        self:restSelfGameEffects(self.m_FsMiniReel, self.Fs_AddTimes_Top_EFFECT)
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    1
                )
            end,
            1
        )
    elseif effectData.p_selfEffectType == self.Fs_AddTimes_Down_EFFECT then
        local actNode = self:checkAddFsTimes()

        self:scatterCollectAction(
            actNode,
            function()
                self.m_baseFreeSpinBar:runCsbAction("actionframe")
                self.m_baseFreeSpinBar:findChild("BitmapFontLabel_2_0"):setString(self.m_baseFreeSpinBar.m_totalFreeSpinCount + 3)
                self.m_baseFreeSpinBar.m_totalFreeSpinCount = self.m_baseFreeSpinBar.m_totalFreeSpinCount + 3

                performWithDelay(
                    self,
                    function()
                        self:restSelfGameEffects(self.m_FsMiniReel, self.Fs_AddTimes_Down_EFFECT)
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end,
                    1
                )
            end,
            2
        )
    end

    return true
end

function CodeGameScreenMermaidMachine:checkReelSymbolType(CurrICol, symbolType)
    for iRow = 1, self.m_iReelRowNum do
        local nodeType = self.m_stcValidSymbolMatrix[iRow][CurrICol]
        if nodeType == symbolType then
            return false
        end
    end

    return true
end

function CodeGameScreenMermaidMachine:checkReelHaveBigScatter(CurrICol)
    for iRow = 1, self.m_iReelRowNum do
        local nodeType = self.m_stcValidSymbolMatrix[iRow][CurrICol]
        if nodeType and nodeType == self.SYMBOL_BIG_SCATTER then
            return true
        end
    end

    return false
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenMermaidMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

    for iCol = 1, self.m_iReelColumnNum do
        local isPlay = true
        --某列数据
        local lastColumnSymbol = self.m_reelSlotsList[iCol]
        --某列最后一组数据 应该只有一组数据
        for k, reels in pairs(lastColumnSymbol) do
            if self:isBigFixSymbol(reels.p_symbolType) or self:isFixSymbol(reels.p_symbolType) then
                reels.m_reelDownAnima = "buling"

                if isPlay then
                    isPlay = false

                    if reels.p_symbolType == self.SYMBOL_SMALL_FIX_BONUS or reels.p_symbolType == self.SYMBOL_BIG_FIX_BONUS then
                        reels.m_reelDownAnimaSound = "MermaidSounds/music_Mermaid_FixBonus_down.mp3"
                    else
                        reels.m_reelDownAnimaSound = "MermaidSounds/music_Mermaid_JpBonus_down.mp3"
                    end
                end

                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    if self.m_FsMiniReel:checkReelHaveBigScatter(iCol) then
                        reels.m_reelDownAnimaSound = nil
                    end
                end
            elseif reels.p_symbolType == self.SYMBOL_BIG_SCATTER then
                reels.m_reelDownAnima = "buling"
                reels.m_reelDownAnimaSound = "MermaidSounds/music_Mermaid_Big_Scatter_Down.mp3"
            end
        end
    end
end

-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenMermaidMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    if storedIcons == nil then
        return 0
    end

    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if score == nil then
        return 0
    end

    if idNode and idNode == -1 then
        return score
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_SMALL_FIX_MINI or symbolType == self.SYMBOL_BIG_FIX_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_SMALL_FIX_MINOR or symbolType == self.SYMBOL_BIG_FIX_MINOR then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_SMALL_FIX_MAJOR or symbolType == self.SYMBOL_BIG_FIX_MAJOR then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_SMALL_FIX_GRAND or symbolType == self.SYMBOL_BIG_FIX_GRAND then
        score = "GRAND"
    end

    return score
end

function CodeGameScreenMermaidMachine:randomDownRespinSymbolScore(symbolType, iCol)
    local score = 1

    if symbolType == self.SYMBOL_SMALL_FIX_BONUS then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if iCol == 1 or iCol == 5 then
                score = self.m_configData:getFS_15_FixSymbolPro()
            else
                score = self.m_configData:getFS_234_FixSymbolPro()
            end
        elseif self:getCurrSpinMode() == RESPIN_MODE then
            score = self.m_configData:getRs_FixSymbolPro()
        else
            score = self.m_configData:getFixSymbolPro()
        end
    elseif symbolType == self.SYMBOL_BIG_FIX_BONUS then
        score = self.m_configData:getFS_234_FixSymbolPro()
    end

    return score
end

function CodeGameScreenMermaidMachine:setBigSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.SYMBOL_BIG_FIX_BONUS then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(-1) --获取分数（网络数据）-1 代表的是大信号
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()

            local labRed = symbolNode:getCcbProperty("m_lb_score_0")
            local labBlue = symbolNode:getCcbProperty("m_lb_score")
            if labBlue then
                labBlue:setVisible(false)
            end

            if labRed then
                labRed:setVisible(false)
            end

            if score >= self.m_respinCollectBet then
                if labRed then
                    labRed:setVisible(true)
                end
            else
                if labBlue then
                    labBlue:setVisible(true)
                end
            end

            score = score * lineBet
            score = util_formatCoins(score, 3)

            if labRed then
                labRed:setString(score)
            end

            if labBlue then
                labBlue:setString(score)
            end
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType, symbolNode.p_cloumnIndex) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()
                local labRed = symbolNode:getCcbProperty("m_lb_score_0")
                local labBlue = symbolNode:getCcbProperty("m_lb_score")
                if labBlue then
                    labBlue:setVisible(false)
                end

                if labRed then
                    labRed:setVisible(false)
                end

                if score >= self.m_respinCollectBet then
                    if labRed then
                        labRed:setVisible(true)
                    end
                else
                    if labBlue then
                        labBlue:setVisible(true)
                    end
                end

                score = score * lineBet
                score = util_formatCoins(score, 3)

                if labRed then
                    labRed:setString(score)
                end

                if labBlue then
                    labBlue:setString(score)
                end
            end
        end
    end
end

-- 给respin小块进行赋值
function CodeGameScreenMermaidMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType or symbolNode.p_symbolType ~= self.SYMBOL_SMALL_FIX_BONUS then
        return
    end

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet()

            local labRed = symbolNode:getCcbProperty("m_lb_score_0")
            local labBlue = symbolNode:getCcbProperty("m_lb_score")
            if labBlue then
                labBlue:setVisible(false)
            end

            if labRed then
                labRed:setVisible(false)
            end

            if score >= self.m_respinCollectBet then
                if labRed then
                    labRed:setVisible(true)
                end
            else
                if labBlue then
                    labBlue:setVisible(true)
                end
            end

            score = score * lineBet
            score = util_formatCoins(score, 3)

            if labRed then
                labRed:setString(score)
            end

            if labBlue then
                labBlue:setString(score)
            end
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType, symbolNode.p_cloumnIndex) -- 获取随机分数（本地配置）
        if symbolNode and symbolNode.p_symbolType then
            if score ~= nil then
                local lineBet = globalData.slotRunData:getCurTotalBet()

                local labRed = symbolNode:getCcbProperty("m_lb_score_0")
                local labBlue = symbolNode:getCcbProperty("m_lb_score")
                if labBlue then
                    labBlue:setVisible(false)
                end

                if labRed then
                    labRed:setVisible(false)
                end

                if score >= self.m_respinCollectBet then
                    if labRed then
                        labRed:setVisible(true)
                    end
                else
                    if labBlue then
                        labBlue:setVisible(true)
                    end
                end

                score = score * lineBet
                score = util_formatCoins(score, 3)

                if labRed then
                    labRed:setString(score)
                end

                if labBlue then
                    labBlue:setString(score)
                end
            end
        end
    end
end

function CodeGameScreenMermaidMachine:isBigNormalSymbol(symbolType)
    if symbolType == self.SYMBOL_BIG_WILD then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_9 then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_8 then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_7 then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_6 then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_5 then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_4 then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_3 then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_2 then
        return true
    elseif symbolType == self.SYMBOL_BIG_SCORE_1 then
        return true
    end

    return false
end

function CodeGameScreenMermaidMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseFastMachine.setSlotCacheNodeWithPosAndType(self, node, symbolType, row, col, isLastSymbol)
    self:updateReelGridNode(node)

    if symbolType == self.SYMBOL_SMALL_FIX_BONUS then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {node})
        self:runAction(callFun)
    end

    if symbolType == self.SYMBOL_BIG_FIX_BONUS then
        -- 给respinBonus 大块进行赋值
        local callFun = cc.CallFunc:create(handler(self, self.setBigSpecialNodeScore), {node})
        self:runAction(callFun)
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if self:isBigNormalSymbol(symbolType) then
            -- 给respinBonus 大块进行赋值
            local callFun = cc.CallFunc:create(handler(self, self.setBigNormalNodeData), {node})
            self:runAction(callFun)
        end
    end

    return node
end

function CodeGameScreenMermaidMachine:setBigNormalNodeData(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if not symbolNode.p_symbolType then
        return
    end

    if symbolNode.m_isLastSymbol and symbolNode.m_isLastSymbol == true then
        symbolNode.m_bInLine = true
        local linePos = {}

        for colIndex = 2, 4 do
            for rowIndex = 1, self.m_iReelRowNum do
                linePos[#linePos + 1] = {iX = rowIndex, iY = colIndex}
            end
        end
        symbolNode:setLinePos(linePos)
    end
end

function CodeGameScreenMermaidMachine:isBigFixSymbol(symbolType)
    if
        symbolType == self.SYMBOL_BIG_FIX_BONUS or symbolType == self.SYMBOL_BIG_FIX_GRAND or symbolType == self.SYMBOL_BIG_FIX_MAJOR or symbolType == self.SYMBOL_BIG_FIX_MINOR or
            symbolType == self.SYMBOL_BIG_FIX_MINI
     then
        return true
    end

    return false
end

-- 是不是 respinBonus小块
function CodeGameScreenMermaidMachine:isFixSymbol(symbolType)
    if
        symbolType == self.SYMBOL_SMALL_FIX_BONUS or symbolType == self.SYMBOL_SMALL_FIX_MINI or symbolType == self.SYMBOL_SMALL_FIX_MINOR or symbolType == self.SYMBOL_SMALL_FIX_MAJOR or
            symbolType == self.SYMBOL_SMALL_FIX_GRAND
     then
        return true
    end
    return false
end

function CodeGameScreenMermaidMachine:showRespinJackpot(index,coins,func,notAutoRemove)
    
    
    self.m_jackPotWinView = util_createView("CodeMermaidSrc.MermaidJackPotWinView",{machine = self})
    -- gLobalViewManager:showUI(jackPotWinView)
    self:findChild("Node_JpView"):addChild(self.m_jackPotWinView)
    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end

    self.m_jackPotWinView:initViewData(index, coins, func, notAutoRemove)
end

-- 结束respin收集
function CodeGameScreenMermaidMachine:playLightEffectEnd()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    performWithDelay(
        self,
        function()
            self:showRespinOverView()
        end,
        1
    )
end

function CodeGameScreenMermaidMachine:getJackpotScoreFromNet(netPos)
    local lines = self.m_LocalData_p_winLines or {}
    local coins = 0
    for i = 1, #lines do
        local lineInfo = lines[i]

        if netPos == -1 then
            if lineInfo.p_iconPos and #lineInfo.p_iconPos == 0 then
                if lineInfo.p_amount then
                    coins = lineInfo.p_amount
                end
            end
        else
            if lineInfo.p_iconPos and #lineInfo.p_iconPos == 1 then
                if lineInfo.p_iconPos[1] == netPos then
                    coins = lineInfo.p_amount
                end
            end
        end
    end

    return coins
end

function CodeGameScreenMermaidMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        if #self.m_chipList >= 40 then
            local jackpotScore = self:BaseMania_getJackpotScore(1)
            self.m_lightScore = self.m_lightScore + jackpotScore

            self:showRespinJackpot(
                4,
                jackpotScore,
                function()
                    self:playLightEffectEnd()
                end
            )
        else
            self:playLightEffectEnd()
        end
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(), chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = self:getPosReelIdx(iRow, iCol)

    local score = self:getReSpinSymbolScore(nFixIdx)

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()

    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self:getJackpotScoreFromNet(nFixIdx)
            addScore = jackpotScore + addScore
            nJackpotType = 1
        elseif score == "MAJOR" then
            jackpotScore = self:getJackpotScoreFromNet(nFixIdx)
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif score == "MINOR" then
            jackpotScore = self:getJackpotScoreFromNet(nFixIdx)
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif score == "MINI" then
            jackpotScore = self:getJackpotScoreFromNet(nFixIdx)
            addScore = jackpotScore + addScore
            nJackpotType = 4
        end
    end

    self.m_lightScore = self.m_lightScore + addScore

    local function fishFlyEndJiesuan()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1

            self:playChipCollectAnim()
        else
            self:showRespinJackpot(
                nJackpotType,
                jackpotScore,
                function()
                    self.m_playAnimIndex = self.m_playAnimIndex + 1
                    scheduler.performWithDelayGlobal(
                        function()
                            self:playChipCollectAnim()
                        end,
                        0.1,
                        self:getModuleName()
                    )
                end
            )
        end
    end

    local function fishFly()
        local lab = self.m_Mermaid_RsReword:findChild("m_lb_WINNER")
        if lab then
            lab:setString(util_formatCoins(self.m_lightScore, 30))
            self.m_Mermaid_RsReword:updateLabelSize({label = lab, sx = 1.2, sy = 1.2}, 276)
        end

        fishFlyEndJiesuan()
    end

    -- chipNode:runAnim("actionframe3")
    chipNode:setLocalZOrder(10000 + self.m_playAnimIndex)

    self.m_respinView:createOneActionSymbol(chipNode, "jiesuan")

    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_RsFixBonus_Collect.mp3")

    self.m_Mermaid_RsReword:runCsbAction("actionframe")

    scheduler.performWithDelayGlobal(
        function()
            self.m_Mermaid_RsReword:findChild("Particle_1"):resetSystem()
            fishFly()
        end,
        0.4,
        self:getModuleName()
    )
end

--结束移除小块调用结算特效
function CodeGameScreenMermaidMachine:reSpinEndAction()
    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    self:clearCurMusicBg()

    -- gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_respin_OverShowAction.mp3")

    -- -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()

    -- for i=1,#self.m_chipList do
    --     local chipNode = self.m_chipList[i]
    --     if chipNode then
    --         self.m_respinView:createOneActionSymbol(chipNode,"jiesuan")
    --     end
    -- end

    self.m_Mermaid_Fe_JpBarView:runCsbAction(
        "suo",
        false,
        function()
            performWithDelay(
                self,
                function()
                    self:playChipCollectAnim()
                end,
                15 / 30
            )

            self.m_Mermaid_Rsbar:setVisible(false)
            self.m_Mermaid_RsReword:setVisible(true)
            local lab = self.m_Mermaid_RsReword:findChild("m_lb_WINNER")
            if lab then
                lab:setString("")
            end
        end
    )
end

-- 根据本关卡实际小块数量填写
function CodeGameScreenMermaidMachine:getRespinRandomTypes()
    local symbolList = {
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_2,
        TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    }

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function CodeGameScreenMermaidMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_SMALL_FIX_BONUS, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_SMALL_FIX_MAJOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_SMALL_FIX_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_SMALL_FIX_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_SMALL_FIX_GRAND, runEndAnimaName = "buling", bRandom = false}
    }

    return symbolList
end

---
-- 触发respin 玩法
--
function CodeGameScreenMermaidMachine:showEffect_Respin(effectData)
    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end

    self.isInBonus = true

    return BaseFastMachine.showEffect_Respin(self, effectData)
end

function CodeGameScreenMermaidMachine:showRespinView()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_MACHINE_WIN_RESPIN)
    self:findChild("jackPoTip"):setVisible(false)

    local lockNums = self.m_runSpinResultData.p_rsExtraData.lockNums
    self.m_lockNumArray = lockNums or {8, 12, 16, 20}

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    --先播放动画 再进入respin
    self:clearCurMusicBg()

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()

    gLobalSoundManager:playSound("MermaidSounds/Mermaid_TriggerRespin.mp3")

    -- 播放 respinbonus buling 动画
    local ActionTime = 3
    for icol = 1, self.m_iReelColumnNum do
        for irow = 1, NORMAL_ROW_COUNT do
            local node = self:getReelParent(icol):getChildByTag(self:getNodeTag(icol, irow, SYMBOL_NODE_TAG))

            if node and node.p_symbolType then
                if self:isFixSymbol(node.p_symbolType) then
                    self:createOneActionSymbol(node, "actionframe2")
                end
            end
        end
    end

    performWithDelay(
        self,
        function()
            self.m_FsGuoChangSpine_1:setVisible(true)
            util_spinePlay(self.m_FsGuoChangSpine_1, "guochang3")
            util_spineEndCallFunc(
                self.m_FsGuoChangSpine_1,
                "guochang3",
                function()
                    util_spinePlay(self.m_FsGuoChangSpine_1, "guochang3over")
                    util_spineEndCallFunc(
                        self.m_FsGuoChangSpine_1,
                        "guochang3over",
                        function()
                            self.m_FsGuoChangSpine_1:setVisible(false)
                        end
                    )
                end
            )

            performWithDelay(
                self,
                function()
                    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_Jp_yu_FeiWen.mp3")
                end,
                54 / 30
            )

            self:showGuoChang(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "respin")

                    for i = 1, #self.m_actRsNode do
                        local node = self.m_actRsNode[i]
                        node:removeFromParent()
                    end
                    self.m_actRsNode = {}

                    self:setReelSlotsNodeVisible(false)

                    self.m_bottomUI:checkClearWinLabel()
                    self.m_Mermaid_Rsbar:updataRespinTimes(self.m_runSpinResultData.p_reSpinCurCount, true)

                    self:checkReSpinShowUI(true)

                    -- gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_Rs_reels_Up.mp3")
                end
            )

            performWithDelay(
                self,
                function()
                    self:runCsbAction(
                        "highIdle",
                        false,
                        function()
                            self.m_iReelRowNum = RESPIN_ROW_COUNT
                            self:respinChangeReelGridCount(RESPIN_ROW_COUNT)
                            self:showAllLockNode(
                                function()
                                    -- gLobalSoundManager:playSound("MermaidSounds/sound_Mermaid_showRespin_bar.mp3")
                                    self.m_Mermaid_Rsbar:setVisible(true)
                                end
                            )
                        end
                    )
                end,
                30 / 30
            )

            performWithDelay(
                self,
                function()
                    --构造盘面数据
                    self:triggerReSpinCallFun(endTypes, randomTypes)
                end,
                65 / 30
            )

            performWithDelay(
                self,
                function()
                    self:runNextReSpinReel()
                end,
                75 / 30
            )
        end,
        ActionTime
    )
end

function CodeGameScreenMermaidMachine:showReSpinStart(func)
    if func then
        func()
    end

    -- self:clearCurMusicBg()
    -- self:showDialog(BaseDialog.DIALOG_TYPE_RESPIN_START,nil,func,BaseDialog.AUTO_TYPE_ONLY)
    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

--ReSpin开始改变UI状态
function CodeGameScreenMermaidMachine:changeReSpinStartUI(respinCount)
end

--ReSpin刷新数量
function CodeGameScreenMermaidMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)

    self.m_Mermaid_Rsbar:updataRespinTimes(curCount)
end

--ReSpin结算改变UI状态
function CodeGameScreenMermaidMachine:changeReSpinOverUI()
end

function CodeGameScreenMermaidMachine:showRespinOverView(effectData)
    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_respin_overView.mp3")

    local strCoins = util_formatCoins(self.m_serverWinCoins, 50)
    local view =
        self:showReSpinOver(
        strCoins,
        function()
            self:showGuoChang(
                function()
                    self:findChild("jackPoTip"):setVisible(true)

                    gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG, "normal")
                    self:setReelSlotsNodeVisible(true)

                    self:removeRespinNode()

                    self.m_Mermaid_RsReword:setVisible(false)

                    self:hideAllLockNodelightAction()
                    self:checkReSpinShowUI()
                    self:respinChangeReelGridCount(NORMAL_ROW_COUNT)
                    self.m_iReelRowNum = NORMAL_ROW_COUNT
                    self:runCsbAction("idle1")

                    self:featuresOverAddFreespinEffect()

                    self:triggerReSpinOverCallFun(self.m_lightScore)
                    self.m_lightScore = 0
                    self:resetMusicBg()
                    self.m_isRespinOver = true
                end
            )
        end
    )

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label = node, sx = 0.54, sy = 0.54}, 1184)
end

----
-- 检测处理effect 结束后的逻辑
--
function CodeGameScreenMermaidMachine:operaEffectOver()
    CodeGameScreenMermaidMachine.super.operaEffectOver(self)

    if self.m_isRespinOver then
        self.m_isRespinOver = false
        --公共jackpot
        local midReel = self:findChild("sp_reel_2")
        local size = midReel:getContentSize()
        local worldPos = util_convertToNodeSpace(midReel,self)
        worldPos.x = worldPos.x + size.width / 2
        worldPos.y = worldPos.y + size.height / 2
        if G_GetMgr(ACTIVITY_REF.CommonJackpot) then
            G_GetMgr(ACTIVITY_REF.CommonJackpot):playEntryFlyAction(worldPos,function()

            end)
        end
    end
    
end


-- --重写组织respinData信息
function CodeGameScreenMermaidMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i = 1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

--- ----- - - - ----- -- - - - - - - -- -
-- 固定格子玩法

function CodeGameScreenMermaidMachine:initIceSymbol()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local ice = util_createAnimation("Socre_Mermaid_qipao.csb")
            local index = self:getPosReelIdx(iRow, iCol, NORMAL_ROW_COUNT)
            self.m_IceMainNode:addChild(ice, index, index)
            local pos = cc.p(util_getOneGameReelsTarSpPos(self, index))
            ice:setPosition(pos)
        end
    end
end

function CodeGameScreenMermaidMachine:updateLoadingQiPaoVisible(isAct)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local newCollect = selfdata.newCollect or {}

    if isAct then
        self.m_Mermaid_loadingbar:updateActLoadingQiPao(#newCollect)
    else
        self.m_Mermaid_loadingbar:updateLoadingQiPao(#collectPosition)
    end
end

function CodeGameScreenMermaidMachine:restAllIce()
    local childs = self.m_IceMainNode:getChildren()
    for i = 1, #childs do
        local ice = childs[i]
        if ice then
            ice:setVisible(true)
            ice:runCsbAction("idleframe")
        end
    end
end

function CodeGameScreenMermaidMachine:updateIceSymbolVisible(isAct)
    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local newCollect = selfdata.newCollect or {}

    if isAct then
        for i = 1, #collectPosition do
            local pos = collectPosition[i]
            local ice = self.m_IceMainNode:getChildByTag(pos)
            if ice then
                ice:runCsbAction(
                    "shouji",
                    false,
                    function()
                        ice:setVisible(false)
                    end
                )
            end
        end
    else
        for i = 1, #collectPosition do
            local pos = collectPosition[i]
            local ice = self.m_IceMainNode:getChildByTag(pos)
            if ice then
                ice:setVisible(false)
            end
        end
    end
end

function CodeGameScreenMermaidMachine:createCollectIceAct(func)
    gLobalSoundManager:playSound("MermaidSounds/Mermaid_IceQiPap_Fly.mp3")

    local selfdata = self.m_runSpinResultData.p_selfMakeData or {}
    local collectPosition = selfdata.collectPosition or {}
    local newCollect = selfdata.newCollect or {}
    local barActList = self.m_Mermaid_loadingbar.m_actPos or {}
    local waitTime = 0.5

    local currTable = {}

    for i = 1, #newCollect do
        local index = newCollect[i]

        local fixPos = self:getRowAndColByPos(index)

        if currTable[fixPos.iY] == nil then
            currTable[fixPos.iY] = {}
        end
        table.insert(currTable[fixPos.iY], index)
    end

    local actTable = {}

    for iCol = 1, self.m_iReelColumnNum do
        local data = currTable[iCol]
        if data then
            for iRow = 1, #data do
                table.insert(actTable, data[iRow])
            end
        end
    end

    local actMainNode = cc.Node:create()
    self:findChild("reel"):addChild(actMainNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1)

    for i = 1, #actTable do
        local startIndex = actTable[i]
        local endindex = barActList[i].pos

        local actNdoe = util_createAnimation("Mermaid_Jidutiao_qipao_shouji.csb")
        actNdoe:runCsbAction("actionframe")
        local flyNode = cc.Node:create()
        flyNode:addChild(actNdoe)
        actMainNode:addChild(flyNode)

        local StartPos = cc.p(util_getOneGameReelsTarSpPos(self, startIndex))
        local endPos = cc.p(util_getConvertNodePos(self.m_Mermaid_loadingbar:findChild("jindutiao_qipao_" .. endindex), flyNode))

        flyNode:setPosition(StartPos)

        util_playMoveToAction(
            flyNode,
            waitTime,
            endPos,
            function()
                flyNode:setVisible(false)
            end
        )
    end

    scheduler.performWithDelayGlobal(
        function()
            actMainNode:removeFromParent()

            for i = 1, #self.m_Mermaid_loadingbar.m_actPos do
                local data = self.m_Mermaid_loadingbar.m_actPos[i] or {}
                local node = data.node
                if node then
                    node:runCsbAction("actionframe")
                end
            end
        end,
        waitTime,
        self:getModuleName()
    )

    if self:IsCanClickSpin() then
        scheduler.performWithDelayGlobal(
            function()
                if func ~= nil then
                    func()
                end
            end,
            waitTime,
            self:getModuleName()
        )
    else
        if func ~= nil then
            func()
        end
    end
end

--收集不触发效果可以快点
function CodeGameScreenMermaidMachine:IsCanClickSpin()
    local isHave = true
    for i = 1, #self.m_gameEffects do
        local effectData = self.m_gameEffects[i]
        local effectType = effectData.p_selfEffectType
        if effectType == self.EFFECT_SHOW_BONUS_COLLECT then
            isHave = false
        end
    end
    return isHave
end

-- 处理特殊关卡 遮罩层级
function CodeGameScreenMermaidMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
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
function CodeGameScreenMermaidMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or self:isFixSymbol(symbolType) then
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

function CodeGameScreenMermaidMachine:getClipWidthRatio(colIndex)
    if colIndex == 3 then
        return 1.5
    else
        return self.m_clipWidtRatio or 1
    end
end

function CodeGameScreenMermaidMachine:changeReelDataBySpinMode(spinModeType)
    if spinModeType == 1 then
        local columnData = self.m_reelColDatas[3]
        columnData:updateShowColCount(1)

        columnData = self.m_reelColDatas[2]
        columnData:updateShowColCount(0)

        columnData = self.m_reelColDatas[4]
        columnData:updateShowColCount(0)
        local reelRunDatas = self.m_FsMiniReel.m_configData.p_reelRunDatas
        -- 将第三列设置为行的整倍数，因为每行都是一个占满行的大信号
        local runData = {
            reelRunDatas[1],
            reelRunDatas[2],
            reelRunDatas[3] / self.m_iReelRowNum,
            reelRunDatas[4],
            reelRunDatas[5]
        }
        self:slotsReelRunData(runData, self.m_configData.p_bInclScatter, self.m_configData.p_bInclBonus, self.m_configData.p_bPlayScatterAction, self.m_configData.p_bPlayBonusAction)
    elseif spinModeType == 2 then
        local columnData = self.m_reelColDatas[3]
        columnData:updateShowColCount(self.m_iReelRowNum)

        columnData = self.m_reelColDatas[2]
        columnData:updateShowColCount(self.m_iReelRowNum)

        columnData = self.m_reelColDatas[4]
        columnData:updateShowColCount(self.m_iReelRowNum)

        self:slotsReelRunData(
            self.m_configData.p_reelRunDatas,
            self.m_configData.p_bInclScatter,
            self.m_configData.p_bInclBonus,
            self.m_configData.p_bPlayScatterAction,
            self.m_configData.p_bPlayBonusAction
        )
    end
end

---
-- 轮盘停止时调用
-- 改变轮盘滚动后的数据等
function CodeGameScreenMermaidMachine:MachineRule_stopReelChangeData()
end

function CodeGameScreenMermaidMachine:setCreateResNode()
    if self.m_runSpinResultData.p_freeSpinsLeftCount then
        if self.m_runSpinResultData.p_freeSpinsTotalCount then
            if self.m_runSpinResultData.p_freeSpinsTotalCount > 0 then
                if self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
                    self.m_bCreateResNode = false
                end
            end
        end
    end
end

function CodeGameScreenMermaidMachine:checkGameRunPause()
    if self:checkFsFrist() then
        return false
    end
    if globalData.slotRunData.gameRunPause == true then
        return true
    else
        return false
    end
end

function CodeGameScreenMermaidMachine:checkFsFrist()
    local totalCount = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
    local curCount = self.m_runSpinResultData.p_freeSpinsLeftCount or -1
    if totalCount == 0 then
        return false
    elseif totalCount == curCount then
        return true
    end
end

function CodeGameScreenMermaidMachine:addJumoActionAfterReel(slotParent, slotParentBig, colIndex)
    local icol = colIndex

    --添加一个回弹效果
    local action0 = cc.JumpTo:create(self.m_configData.p_reelBeginJumpTime, cc.p(slotParent:getPositionX(), slotParent:getPositionY()), self.m_configData.p_reelBeginJumpHight, 1)

    local sequece =
        cc.Sequence:create(
        {
            action0,
            cc.CallFunc:create(
                function()
                    self:registerReelSchedule()

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        if icol == 2 or icol == 4 then
                            self.m_slotParents[icol].isReeling = false
                            self.m_slotParents[icol].isResActionDone = true
                        end
                    end
                end
            )
        }
    )

    slotParent:runAction(sequece)
    if slotParentBig then
        slotParentBig:runAction(action0:clone())
    end
end

function CodeGameScreenMermaidMachine:beginReel()
    self:resetReelDataAfterReel()
    local slotsParents = self.m_slotParents
    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

        self:checkReelIndexReason(parentData)
        self:resetParentDataReel(parentData)

        self:createSlotNextNode(parentData)
        if self.m_configData.p_reelBeginJumpTime > 0 then
            self:addJumoActionAfterReel(slotParent, slotParentBig, i)
        else
            self:registerReelSchedule()
            if self:getCurrSpinMode() == FREE_SPIN_MODE then
                if i == 2 or i == 4 then
                    self.m_slotParents[i].isReeling = false
                    self.m_slotParents[i].isResActionDone = true
                end
            end
        end
        --判断tag值 如果父节点有节点tag < xxx 切节点不为轮盘 则将节点放入对应轮盘 轮盘有节点tag 》xx 则将节点放入父节点
        self:foreachSlotParent(
            i,
            function(index, realIndex, child)
                if child.__cname ~= nil and child.__cname == "SlotsNode" then
                    child:resetReelStatus()
                end
                if child.p_layerTag ~= nil and child.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE then
                    --将该节点放在 .m_clipParent
                    child:removeFromParent()
                    local posWorld = slotParent:convertToWorldSpace(cc.p(child:getPositionX(), child:getPositionY()))
                    local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
                    child:setPosition(cc.p(pos.x, pos.y))
                    self.m_clipParent:addChild(child, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + child.m_showOrder)
                end
            end
        )
    end

    -- 处理特殊信号
    local childs = self.m_clipParent:getChildren()
    for i = 1, #childs do
        local child = childs[i]
        if child.__cname ~= nil and child.__cname == "SlotsNode" then
            child:resetReelStatus()
        end
        if child.p_layerTag ~= nil and child.p_layerTag == SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
            --将该节点放在 .m_clipParent
            local showOrder = child.m_showOrder or self:getBounsScatterDataZorder(child.p_symbolType)
            local colIndex = child.p_cloumnIndex
            local childSlotParent = slotsParents[colIndex].slotParent
            local posWorld = self.m_clipParent:convertToWorldSpace(cc.p(child:getPositionX(), child:getPositionY()))
            local pos = childSlotParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))

            child:removeFromParent()
            child:resetReelStatus()
            child:setPosition(cc.p(pos.x, pos.y))
            local slotParentBig = slotsParents[colIndex].slotParentBig
            if slotParentBig and self.m_configData:checkSpecialSymbol(child.p_symbolType) then
                slotParentBig:addChild(child, showOrder - child.p_rowIndex)
            else
                childSlotParent:addChild(child, showOrder - child.p_rowIndex)
            end

            -- 因为本关只有scatter会提层级而且在触发freespin后需要隐藏
            if child and child.p_symbolType == 90 then
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    local ccbNode = child:checkLoadCCbNode()
                    if ccbNode ~= nil then
                        ccbNode:setVisible(false)
                    end

                    if child.p_symbolImage then
                        child.p_symbolImage:setVisible(false)
                    end
                end
            end
        end
    end
    self:setGameSpinStage(GAME_MODE_ONE_RUN)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_FsMiniReel:beginReel()
    end
end

function CodeGameScreenMermaidMachine:randomSlotNodesByReel()
    for colIndex = 1, self.m_iReelColumnNum do
        local reelColData = self.m_reelColDatas[colIndex]
        local resultLen = reelColData.p_resultLen
        local reelData = self.m_currentReelStripData:getReelSymbols(colIndex, resultLen)

        local halfNodeH = reelColData.p_showGridH * 0.5
        local rowCount = reelColData.p_showGridCount
        local parentData = self.m_slotParents[colIndex]

        local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)

        for rowIndex = 1, rowCount do -- 只改了这一行
            local symbolType = reelData.p_reelResultSymbols[resultLen - (rowIndex - 1)]

            while true do
                if self.m_bigSymbolInfos[symbolType] == nil then
                    break
                end
                symbolType = self:getRandomReelType(colIndex, reelDatas)
            end

            local showOrder = self:getBounsScatterDataZorder(symbolType)
            local node = self:getCacheNode(colIndex, symbolType)
            if node == nil then
                node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
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

-- 本地保存一份赢钱线
function CodeGameScreenMermaidMachine:parseLocalWinLines(data)
    self.m_LocalData_p_winLines = {}

    if data.lines ~= nil then
        for i = 1, #data.lines do
            local lineData = data.lines[i]

            -- if self.p_isAllLine == true and lineData.nums ~= nil and  #lineData.nums ~= 0 then
            --     self:parseAllLines(lineData , lineDataPool)
            -- else
            local winLineData = {}
            winLineData.p_id = lineData.id
            winLineData.p_amount = lineData.amount
            winLineData.p_iconPos = lineData.icons
            winLineData.p_type = lineData.type
            winLineData.p_multiple = lineData.multiple
            self.m_LocalData_p_winLines[#self.m_LocalData_p_winLines + 1] = winLineData
            -- end
        end
    end
end

function CodeGameScreenMermaidMachine:removeFsJpPosIndex(param)
    if param[1] == true then
        local spinData = param[2]
        if spinData.action == "SPIN" then
            if spinData.result.lines ~= nil then
                for i = #spinData.result.lines, 1, -1 do
                    local lineData = spinData.result.lines[i]

                    if self:isFixSymbol(lineData.type) or self:isBigFixSymbol(lineData.type) then
                        table.remove(param[2].result.lines, i)
                    end
                end
            end
        end
    end
end

function CodeGameScreenMermaidMachine:spinResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- print(cjson.encode(param[2]))
        if spinData.action == "SPIN" then
            self:parseLocalWinLines(spinData.result)

            self:removeFsJpPosIndex(param)
        end
    end

    self.m_Mermaid_JpBarView:resetCurRefreshTime()
    self.m_Mermaid_Fe_JpBarView:resetCurRefreshTime()

    
    BaseFastMachine.spinResultCallFun(self,param)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if param[1] == true then
            local spinData = param[2]
            print(cjson.encode(param[2]))
            print("消息返回")
            if spinData.result then
                if spinData.result.selfData then
                    if spinData.result.selfData.other then
                        if self.m_FsMiniReel then
                            spinData.result.selfData.other.bet = 0
                            spinData.result.selfData.other.payLineCount = 0

                            self.m_FsMiniReel:netWorkCallFun(spinData.result.selfData.other)
                        end
                    end
                end
            end
        end
    end
    
end

function CodeGameScreenMermaidMachine:getFreeSpinReelsLines()
    local lines = {}

    if self.m_FsMiniReel then
        if not self:checkFsFrist() then
            local miniReelslines = self.m_FsMiniReel:getResultLines()
            if miniReelslines then
                for i = 1, #miniReelslines do
                    table.insert(lines, miniReelslines[i])
                end
            end
        end
    end

    return lines
end

function CodeGameScreenMermaidMachine:playEffectNotifyNextSpinCall()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self:getCurrSpinMode() == REWAED_FREE_SPIN_MODE then
        local delayTime = 0.5
        local lines = self.m_reelResultLines

        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            if lines == nil or #lines == 0 then
                lines = self:getFreeSpinReelsLines()
            end
        end

        delayTime = delayTime + self:getWinCoinTime()

        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                gLobalSoundManager:playSound("res/Sounds/Diamonds_spin.mp3")
                self:normalSpinBtnCall()
            end,
            delayTime,
            self:getModuleName()
        )
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_handerIdAutoSpin =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:normalSpinBtnCall()
            end,
            0.5,
            self:getModuleName()
        )
    end
end

function CodeGameScreenMermaidMachine:checkAddFsTimes()
    local bigSymbol = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if bigSymbol and bigSymbol.p_symbolType == self.SYMBOL_BIG_SCATTER then
            return bigSymbol
        end
    end

    return nil
end

function CodeGameScreenMermaidMachine:checkAddFsLightCoins(lines)
    local isAdd = false

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for i = 1, #lines do
            local lineInfo = lines[i]
            if lineInfo.p_iconPos and #lineInfo.p_iconPos == 1 then
                isAdd = true
                break
            elseif lineInfo.p_iconPos and #lineInfo.p_iconPos == 0 then
                isAdd = true
                break
            end
        end
    end

    return isAdd
end

function CodeGameScreenMermaidMachine:restSelfGameEffects(mainClass, restType)
    if mainClass.m_gameEffects then
        for i = 1, #mainClass.m_gameEffects, 1 do
            local effectData = mainClass.m_gameEffects[i]

            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_selfEffectType

                if effectType == restType then
                    effectData.p_isPlay = true
                    mainClass:playGameEffect()
                    return
                end
            end
        end
    end
end

function CodeGameScreenMermaidMachine:createBonusView( func )

    self:findChild("jackPoTip"):setVisible(false)

    self.m_bottomUI:showAverageBet()

    self.isInBonus = true

    self:resetMusicBg(nil, "MermaidSounds/music_Zeus_BonusCollectBg.mp3")

    self.m_bottomUI:checkClearWinLabel()

    self.m_Mermaid_BonusView = util_createView("CodeMermaidSrc.MermaidBonusView", self)
    self:findChild("BonusView"):addChild(self.m_Mermaid_BonusView)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_Mermaid_BonusView.getRotateBackScaleFlag = function()
            return false
        end
    end

    self.m_Mermaid_BonusView:setOverCallFunc(
        function()
            self:setPickTimes("")

            self:findChild("jackPoTip"):setVisible(true)

            self.m_bottomUI:hideAverageBet()
            if func then
                func()
            end
        end
    )
    self:findChild("reel"):setVisible(false)
    self.m_Mermaid_JpBarView:setVisible(false)
end

----------------------------------
-------- respin特殊处理
function CodeGameScreenMermaidMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(8, 5, TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function CodeGameScreenMermaidMachine:respinChangeReelGridCount(count)
    for i = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end

function CodeGameScreenMermaidMachine:getPosReelIdx(iRow, iCol, maxRow)
    local iReelRow = maxRow or #self.m_runSpinResultData.p_reels
    local index = (iReelRow - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

---构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenMermaidMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = nil
            if #self.m_runSpinResultData.p_reels == NORMAL_ROW_COUNT then
                if iRow <= 4 then
                    symbolType = self:getMatrixPosSymbolType(iRow, iCol)
                else
                    symbolType = self:getOneNorSymbol()
                end
            else
                symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            end

            if symbolType == self.SYMBOL_BIG_LONG_WILD then
                symbolType = self:getOneNorSymbol()
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
function CodeGameScreenMermaidMachine:triggerChangeRespinNodeInfo(respinNodeInfo)
    for k, v in pairs(respinNodeInfo) do
        if v.Type == nil then
            v.Type = math.random(0, 8) -- 随机信号
        end
    end
end

function CodeGameScreenMermaidMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:initMachine(self)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:playRespinViewShowSound()
            self:showReSpinStart(
                function()
                    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
                    -- 更改respin 状态下的背景音乐
                    self:changeReSpinBgMusic()
                    -- self:runNextReSpinReel()
                end
            )
        end
    )

    --隐藏 盘面信息
    -- self:setReelSlotsNodeVisible(false)
end

-- -- -- - - - - -- - - - - - - --
--  respin锁定玩法锁定
function CodeGameScreenMermaidMachine:setLockDataInfo()
    self.m_allLockNodeReelPos = {}
    for i = 1, #self.m_runSpinResultData.p_storedIcons do
        local iconInfo = self.m_runSpinResultData.p_storedIcons[i]
        self.m_allLockNodeReelPos[#self.m_allLockNodeReelPos + 1] = {iconInfo[1], iconInfo[2]}
    end
end

---返回没有锁的行个数
function CodeGameScreenMermaidMachine:getLockNodeShowNum()
    local num = 0
    for k, v in pairs(self.m_lockNodeArray) do
        if v.actionType == 1 then
            num = num + 1
        end
    end
    return num
end

---返回应该锁行个数 断线用 第一次进入respin
function CodeGameScreenMermaidMachine:getShouldLockNodeShowNum()
    self:showLeftLockNum()

    local alllockNum = self:getLockNodeShowNum() + 4 -- 本地已经解锁的个数

    local unlockedLines = self.m_runSpinResultData.p_rsExtraData.unlock -- 服务器已经解锁的个数
    local lockedSymbols = self.m_runSpinResultData.p_rsExtraData.totalRewardSignals -- 服务器已经锁住的信号数

    local shouldUnLockLines = unlockedLines - alllockNum
    if shouldUnLockLines >= 0 and alllockNum ~= 8 then
        self:unlockedNode(shouldUnLockLines)
    end
end

--[[
    @desc: 处理 锁行
    author:{author}
    time:2019-01-08 21:55:18
    @return:
]]
function CodeGameScreenMermaidMachine:hideAllLockNode()
    for k, v in pairs(self.m_lockNodeArray) do
        v:setVisible(false)
        v.actionType = 0
    end
end

function CodeGameScreenMermaidMachine:showAllLockNode(func)
    local unlockedLines = self.m_runSpinResultData.p_rsExtraData.unlock -- 服务器已经解锁的个数
    local num = 0

    for k, v in pairs(self.m_lockNodeArray) do
        v:IdleAction(false)
        v:setVisible(false)
        v:updateLockLeftNum("")
        self.m_lockNodeArray[k].actionType = 1
        local index = k

        if (index + 4) > unlockedLines then
            self.m_lockNodeArray[k].actionType = 0
            num = num + 1
            scheduler.performWithDelayGlobal(
                function()
                    v:setVisible(true)
                    -- gLobalSoundManager:playSound("MermaidSounds/sound_Mermaid_showlock.mp3")
                end,
                0.2 * (num - 1),
                self:getModuleName()
            )
        end
    end

    scheduler.performWithDelayGlobal(
        function()
            self:getShouldLockNodeShowNum(unlockedLines)

            if func then
                func()
            end
        end,
        (8 - unlockedLines) * 0.2,
        self:getModuleName()
    )
end

-- 解锁
function CodeGameScreenMermaidMachine:unlockedNode(shouldUnLockLines)
    for i = 1, shouldUnLockLines do
        for k, v in pairs(self.m_lockNodeArray) do
            if v:isVisible() and v.actionType == 0 then
                v.actionType = 1
                v:unLockAction(
                    false,
                    function()
                        v:setVisible(false)
                    end
                )
                break
            end
        end
    end
end

-- 解锁
function CodeGameScreenMermaidMachine:unlockedOneNode(index)
    local actId = index
    if self.m_lockNodeArray[actId]:isVisible() and self.m_lockNodeArray[actId].actionType ~= 1 then
        self.m_lockNodeArray[actId]:unLockAction(
            false,
            function()
                self.m_lockNodeArray[actId]:setVisible(false)
            end
        )
    end
    self.m_lockNodeArray[actId].actionType = 1
end

-- 显示剩余个数
function CodeGameScreenMermaidMachine:showLeftLockNum()
    local lightnum = 0
    local lockedSymbols = self.m_runSpinResultData.p_rsExtraData.totalRewardSignals -- 服务器已经锁住的信号数

    if not lockedSymbols then
        for i = 1, #self.m_runSpinResultData.p_reelsData do
            local reels = self.m_runSpinResultData.p_reelsData[i]
            for j = 1, #reels do
                local type = reels[j]
                if self:isFixSymbol(type) then
                    lightnum = lightnum + 1
                end
            end
        end
        lockedSymbols = lightnum
    end

    for k, v in pairs(self.m_lockNodeArray) do
        v:updateLockLeftNum(self.m_lockNumArray[k] - lockedSymbols, true)
    end
end

function CodeGameScreenMermaidMachine:hideAllLockNodelightAction()
    for k, v in pairs(self.m_lockNodeArray) do
        self.m_lockNodeArray[k].actionType = 0
        v:setVisible(false)
        v:lightAction(false)
    end
end

---- - - - -- - - - - - -- -- - -
function CodeGameScreenMermaidMachine:createOneActionSymbol(endNode, actionName)
    if not endNode or not endNode.m_ccbName then
        return
    end

    local fatherNode = endNode
    endNode:setVisible(false)

    local node = util_createAnimation(endNode.m_ccbName .. ".csb")
    local func = function()
        if fatherNode then
            fatherNode:setVisible(true)
        end
    end
    node:playAction(actionName, false, func)

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("reel"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    self:findChild("reel"):addChild(node, 100000 + endNode.p_cloumnIndex * 100 - endNode.p_rowIndex)
    node:setPosition(pos)

    local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local symbolIndex = self:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
    local score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
    local index = 0
    if score ~= nil and type(score) ~= "string" then
        local lineBet = globalData.slotRunData:getCurTotalBet()

        local labRed = node:findChild("m_lb_score_0")
        local labBlue = node:findChild("m_lb_score")
        if labBlue then
            labBlue:setVisible(false)
        end

        if labRed then
            labRed:setVisible(false)
        end

        if score >= self.m_respinCollectBet then
            if labRed then
                labRed:setVisible(true)
            end
        else
            if labBlue then
                labBlue:setVisible(true)
            end
        end

        score = score * lineBet
        score = util_formatCoins(score, 3)

        if labRed then
            labRed:setString(score)
        end

        if labBlue then
            labBlue:setString(score)
        end
    end

    table.insert(self.m_actRsNode, node)

    return node
end

--隐藏盘面信息
function CodeGameScreenMermaidMachine:setReelSlotsNodeVisible(status)
    for iCol = 1, self.m_iReelColumnNum do
        local ReelParent = self:getReelParent(iCol)
        if ReelParent then
            ReelParent:setVisible(status)
        end
        local slotParentBig = self:getReelBigParent(iCol)
        if slotParentBig then
            slotParentBig:setVisible(status)
        end
    end

    -- --如果为空则从 clipnode获取
    -- local childs = self.m_clipParent:getChildren()
    -- local childCount = #childs
    -- self.m_clipParent:setVisible(status)
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenMermaidMachine:showBonusAndScatterLineTip(lineValue,callFun)
    local frameNum = lineValue.iLineSymbolNum

    if frameNum == 0 then
        if lineValue.vecValidMatrixSymPos then
            frameNum = #lineValue.vecValidMatrixSymPos
        end
    end

    local animTime = 0

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        if slotNode == nil and slotParentBig then
            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
        end
        if slotNode == nil then
            slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
        end

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                        end
                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            slotNode = self:setSlotNodeEffectParent(slotNode)
            slotNode:runAnim("actionframe")
            animTime = util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))
        end
    end

    self:palyBonusAndScatterLineTipEnd(animTime, callFun)
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenMermaidMachine:showEffect_Bonus(effectData)
    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self.isInBonus = true

    -- performWithDelay(self,function(  )
    -- self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 优先提取出来 触发Bonus 的连线， 将其移除， 并且播放一次Bonus 触发内容
    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i = 1, lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines, i)
            break
        end
    end

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 播放bonus 元素不显示连线
    if bonusLineValue ~= nil then
        self:showBonusAndScatterLineTip(
            bonusLineValue,
            function()
                self:showBonusGameView(effectData)
            end
        )
        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue

        -- 播放提示时播放音效
        self:playBonusTipMusicEffect()
    else
        self:showBonusGameView(effectData)
    end

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
    -- end,self.m_changeLineFrameTime)

    return true
end

function CodeGameScreenMermaidMachine:palyBonusAndScatterLineTipEnd(animTime, callFun)
    -- 延迟回调播放 界面提示 bonus  freespin
    local time = 2
    scheduler.performWithDelayGlobal(
        function()
            self:resetMaskLayerNodes()
            scheduler.performWithDelayGlobal(
                function()
                    callFun()
                end,
                1,
                self:getModuleName()
            )
        end,
        time,
        self:getModuleName()
    )
end

function CodeGameScreenMermaidMachine:resetMaskLayerNodes()
    local nodeLen = #self.m_lineSlotNodes

    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        -- node = lineNode
        if lineNode ~= nil then -- TODO 打的补丁， 临时这样
            local preParent = lineNode.p_preParent
            if preParent ~= nil then
                self.m_lineSlotNodes[lineNodeIndex] = nil
                lineNode:removeFromParent()
                if preParent ~= self.m_clipParent then
                    lineNode.p_layerTag = lineNode.p_preLayerTag
                end
                local nZOrder = lineNode.p_showOrder
                if preParent == self.m_clipParent then
                    nZOrder = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + lineNode.p_showOrder
                end
                preParent:addChild(lineNode, nZOrder)
                lineNode:setPosition(lineNode.p_preX, lineNode.p_preY)

                lineNode:runIdleAnim()
                if lineNode.p_symbolType and lineNode.p_symbolType == 90 then
                    local targSp = self:setSpecialSymbolToClipReel(lineNode.p_cloumnIndex, lineNode.p_rowIndex, lineNode.p_symbolType)

                    if targSp then
                        targSp:runAnim("idleframe1")
                    end
                end
            end
        end
    end
end

function CodeGameScreenMermaidMachine:showBonusGameOverView(coins, func)
    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_BonusOver_view.mp3")

    local bonusOverView = util_createView("CodeMermaidSrc.MermaidBonusOverView")
    if globalData.slotRunData.machineData.p_portraitFlag then
        bonusOverView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(bonusOverView)
    bonusOverView:initViewData(coins, func)
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenMermaidMachine:showBonusGameView(effectData)
    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_TriggerBonus.mp3")

    self.m_Mermaid_loadingbar:runCsbAction(
        "actionframe",
        false,
        function()
            self.m_Mermaid_loadingbar:runCsbAction("idleframe")

            self:showGuoChang(
                function()
                    self.m_bottomUI:checkClearWinLabel()

                    release_print("bonus 正常进入  initFeatureInfo 1 ")

                    self:createBonusView(
                        function()
                            self:resetMusicBg(true)

                            performWithDelay(
                                self,
                                function()
                                    effectData.p_isPlay = true
                                    self:playGameEffect() -- 播放下一轮
                                end,
                                0.5
                            )
                        end
                    )
                    self.m_Mermaid_BonusView:showBonusStartView()
                end
            )
        end
    )
end

function CodeGameScreenMermaidMachine:initFeatureInfo(spinData, featureData)
    local showBonusView = function()
        self:createBonusView(
            function()
                self:resetMusicBg(true)
                performWithDelay(
                    self,
                    function()
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                        self:playGameEffect()
                    end,
                    0.5
                )
            end
        )

        local bonusdata = featureData.p_bonus or {}
        local extra = bonusdata.extra or {}
        local picks = extra.picks or {}

        if #picks > 0 then
            self.m_Mermaid_BonusView:restPaoPaoViewView(spinData, featureData)
        else
            self.m_Mermaid_BonusView:restView(spinData, featureData)
        end

        scheduler.performWithDelayGlobal(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            end,
            0.1,
            self:getModuleName()
        )
    end

    self.m_merFeatureData = featureData

    if featureData.p_status == "CLOSED" then
        local bonusdata = featureData.p_bonus or {}
        local extra = bonusdata.extra or {}
        local picks = extra.picks or {}
        local userDataPickTimes = self:getPickTimes()
        if userDataPickTimes > 0 and #picks > 0 then
            release_print("bonus 断线加载  initFeatureInfo 1 ")
            showBonusView()
        else
            if self.m_runSpinResultData.p_selfMakeData then
                if self.m_runSpinResultData.p_selfMakeData.collectPosition then
                    self.m_runSpinResultData.p_selfMakeData.collectPosition = {}
                end

                if self.m_runSpinResultData.p_selfMakeData.newCollect then
                    self.m_runSpinResultData.p_selfMakeData.newCollect = {}
                end
            end

            self.m_Mermaid_loadingbar:restLoadingQiPao()
            self:restAllIce()
        end

        return
    end

    if featureData.p_status == "OPEN" then
        showBonusView()
    end
end

function CodeGameScreenMermaidMachine:showGuoChang(func, func1)
    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_GuoChang.mp3")

    self.m_GuoChangView:setVisible(true)
    self.m_GuoChangView:runCsbAction(
        "animation0",
        false,
        function()
            if func1 then
                func1()
            end
        end
    )

    scheduler.performWithDelayGlobal(
        function()
            if func then
                func()
            end
        end,
        2,
        self:getModuleName()
    )
end

-- 更新控制类数据
function CodeGameScreenMermaidMachine:SpinResultParseResultData(spinData)
    self.m_runSpinResultData:parseResultData(spinData.result, self.m_lineDataPool)
end

function CodeGameScreenMermaidMachine:featuresOverAddFreespinEffect()
    local featureDatas = self.m_runSpinResultData.p_features
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_FREESPIN then -- 有freespin
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加freespin effect
            local freeSpinEffect = GameEffectData.new()
            freeSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN
            freeSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN
            self.m_gameEffects[#self.m_gameEffects + 1] = freeSpinEffect
            freeSpinEffect.p_BonusTrigger = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

            -- 保留freespin 数量信息
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

            self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

            -- 如果连线内有scatter 元素则播放连线，否则 不播放连线信息了，  因为触发可能由多个信号触发

            --更新fs次数ui 显示
            gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)
        elseif featureId == SLOTO_FEATURE.FEATURE_RESPIN then -- respin 玩法一并通过respinCount 来进行判断处理
            globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount

            local respinEffect = GameEffectData.new()
            respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
            respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN

            self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

            --发送测试特殊玩法
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
        elseif featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)

            -- 添加bonus effect
            local bonusGameEffect = GameEffectData.new()
            bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
            bonusGameEffect.p_effectOrder = GameEffect.EFFECT_BONUS
            self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect

            self.m_isRunningEffect = true

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        end
    end
end

function CodeGameScreenMermaidMachine:MachineRule_checkTriggerFeatures()
    if self.m_runSpinResultData.p_features ~= nil and #self.m_runSpinResultData.p_features > 0 then
        local featureLen = #self.m_runSpinResultData.p_features
        self.m_iFreeSpinTimes = 0
        for i = 1, featureLen do
            local featureID = self.m_runSpinResultData.p_features[i]
            -- 这里之所以要添加这一步的原因是：FreeSpin_More 也是按照freespin的逻辑来触发的，
            -- 逻辑代码中会自动判断再次触发freespin时是否是freeSpin_More的逻辑 2019-04-02 12:31:27
            if featureID == SLOTO_FEATURE.FEATURE_FREESPIN_FS then
                featureID = SLOTO_FEATURE.FEATURE_FREESPIN
            end
            if featureID ~= 0 then
                if featureID == SLOTO_FEATURE.FEATURE_FREESPIN then
                    self:addAnimationOrEffectType(GameEffect.EFFECT_FREE_SPIN)

                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)

                    if self:getCurrSpinMode() == FREE_SPIN_MODE then
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount - globalData.slotRunData.totalFreeSpinCount
                    else
                        -- 默认情况下，freesipn 触发了既获得fs次数，有玩法的继承此函数获得次数
                        globalData.slotRunData.totalFreeSpinCount = 0
                        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount or 0
                    end

                    globalData.slotRunData.freeSpinCount = (globalData.slotRunData.freeSpinCount or 0) + self.m_iFreeSpinTimes
                elseif featureID == SLOTO_FEATURE.FEATURE_RESPIN then -- 触发respin 玩法
                    -- 四合一关卡特殊处理，freespin过程中不触发Respin,respin游戏事件在freespin结束手动添加
                    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                        globalData.slotRunData.iReSpinCount = self.m_runSpinResultData.p_reSpinCurCount
                        if self:getCurrSpinMode() == RESPIN_MODE then
                        else
                            local respinEffect = GameEffectData.new()
                            respinEffect.p_effectType = GameEffect.EFFECT_RESPIN
                            respinEffect.p_effectOrder = GameEffect.EFFECT_RESPIN
                            if globalData.slotRunData.iReSpinCount == 0 and #self.m_runSpinResultData.p_storedIcons == 15 then
                                respinEffect.p_effectType = GameEffect.EFFECT_SPECIAL_RESPIN
                                respinEffect.p_effectOrder = GameEffect.EFFECT_SPECIAL_RESPIN
                            end
                            self.m_gameEffects[#self.m_gameEffects + 1] = respinEffect

                            --发送测试特殊玩法
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                        end
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                    -- 关卡特殊处理，freespin过程中不触发bonus,bonus游戏事件在freespin结束手动添加
                    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                        -- 添加 BonusEffect
                        self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                        --发送测试特殊玩法
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                    end
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end
            end
        end
    end
end

--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenMermaidMachine:checkTriggerINFreeSpin()
    local isPlayGameEff = false

    -- 检测是否处于
    local hasFreepinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
        hasFreepinFeature = true
    end

    local hasReSpinFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
    -- hasReSpinFeature = true
    end

    local hasBonusFeature = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
    -- hasBonusFeature = true
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
        self:changeFreeSpinReelData()

        gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
        self.m_bProduceSlots_InFreeSpin = true
        -- 保留freespin 数量信息
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount

        self.m_iFreeSpinTimes = self.m_runSpinResultData.p_freeSpinsTotalCount

        self:setCurrSpinMode(FREE_SPIN_MODE)

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 then
            local reSpinEffect = GameEffectData.new()
            reSpinEffect.p_effectType = GameEffect.EFFECT_FREE_SPIN_OVER
            reSpinEffect.p_effectOrder = GameEffect.EFFECT_FREE_SPIN_OVER
            self.m_gameEffects[#self.m_gameEffects + 1] = reSpinEffect
        end

        -- 发送事件显示赢钱总数量
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_runSpinResultData.p_fsWinCoins, false, false})
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
        self:levelFreeSpinEffectChange()
        self:showFreeSpinBar()
        -- 模拟当前reelDown结束，执行后续操作
        isPlayGameEff = true
    end

    return isPlayGameEff
end

function CodeGameScreenMermaidMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    local isBonsGame = false
    if self.m_runSpinResultData then
        if self.m_runSpinResultData.p_features then
            if self.m_runSpinResultData.p_features[2] then
                if self.m_runSpinResultData.p_features[2] == 5 then
                    isBonsGame = true
                end
            end
        end
    end

    if isBonsGame then
        self:initRandomSlotNodes()
    else
        self:initCloumnSlotNodesByNetData()
    end
end

function CodeGameScreenMermaidMachine:showAllFrame(winLines)
    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0

    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            -- end
            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
            preNode:removeFromParent()
            self:pushFrameToPool(preNode)
        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index = 1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s", "")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i = 1, frameNum do
            local symPosData = lineValue.vecValidMatrixSymPos[i]

            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then
                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen()

                local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5

                local showGridH = columnData.p_showGridH
                if self:getCurrSpinMode() == FREE_SPIN_MODE then
                    showGridH = self.m_reelColDatas[1].p_showGridH
                end
                local posY = showGridH * symPosData.iX - showGridH * 0.5 + columnData.p_slotColumnPosY

                local node = self:getFrameWithPool(lineValue, symPosData)
                node:setPosition(cc.p(posX, posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
            end
        end
    end
end

function CodeGameScreenMermaidMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    local coins = self.m_actLastWinCoins
    local currCoins = self.m_iOnceSpinLastWin
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        coins = nil
    end
    if coins then
        currCoins = globalData.slotRunData.lastWinCoin - coins
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {currCoins, isNotifyUpdateTop})
end

function CodeGameScreenMermaidMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end
        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local showGridH = columnData.p_showGridH
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            showGridH = self.m_reelColDatas[1].p_showGridH
        end
        local posY = showGridH * symPosData.iX - showGridH * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                end
            end
        end
    end
end

function CodeGameScreenMermaidMachine:showInLineSlotNodeByWinLines(winLines, startIndex, endIndex, bChangeToMask)
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
                local parentData = self.m_slotParents[symPosData.iY]
                local slotParent = parentData.slotParent
                local slotParentBig = parentData.slotParentBig
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                if slotNode == nil and slotParentBig then
                                    slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                                end
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        if slotNode == nil and slotParentBig then
                            slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                        end
                    end
                else
                    slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    if slotNode == nil and slotParentBig then
                        slotNode = slotParentBig:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)
                    end
                end

                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end

                if self:getCurrSpinMode() == FREE_SPIN_MODE then -- 特殊处理
                    if symPosData.iY > 1 and symPosData.iY < 5 then
                        slotNode = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)
                    end
                end

                checkAddLineSlotNode(slotNode)

                -- 存每一条线
                symPosData = lineValue.vecValidMatrixSymPos[i]
                if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil then
                    local isBigSymbol = false
                    local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
                    for k = 1, #bigSymbolInfos do
                        local bigSymbolInfo = bigSymbolInfos[k]

                        for changeIndex = 1, #bigSymbolInfo.changeRows do
                            if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                                slotNode = self:getFixSymbol(symPosData.iY, bigSymbolInfo.startRowIndex, SYMBOL_NODE_TAG)
                                isBigSymbol = true
                                break
                            end
                        end
                    end
                    if isBigSymbol == false then
                        slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                    end
                else
                    slotNode = self:getFixSymbol(symPosData.iY, symPosData.iX, SYMBOL_NODE_TAG)
                end
                -- 自定义特殊块加入连线动画
                local sepcicalNode = self:getSpecialReelNode(symPosData)
                if sepcicalNode ~= nil then
                    slotNode = sepcicalNode
                end

                if self:getCurrSpinMode() == FREE_SPIN_MODE then -- 特殊处理
                    if symPosData.iY > 1 and symPosData.iY < 5 then
                        slotNode = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)
                    end
                end

                if self.m_eachLineSlotNode ~= nil and self.m_eachLineSlotNode[lineIndex] ~= nil then
                    self.m_eachLineSlotNode[lineIndex][#self.m_eachLineSlotNode[lineIndex] + 1] = slotNode
                end

                ---
            end -- end for i = 1 frameNum
        end -- end if freespin bonus
    end

    -- 添加特殊格子。 只适用于覆盖类的长条，例如小财神， 白虎乌鸦人等 ..
    local specialChilds = self:getAllSpecialNode()
    for specialIndex = 1, #specialChilds do
        local specialNode = specialChilds[specialIndex]
        checkAddLineSlotNode(specialNode)
    end
end

function CodeGameScreenMermaidMachine:playEffectNotifyChangeSpinStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:setNormalAllRunDown(1)
    else
        BaseFastMachine.playEffectNotifyChangeSpinStatus(self)
    end
end

function CodeGameScreenMermaidMachine:setNormalAllRunDown(times)
    self.m_norDownTimes = self.m_norDownTimes + times

    print("setNormalAllRunDown   " .. self.m_norDownTimes)
    if self.m_norDownTimes == 2 then
        BaseFastMachine.playEffectNotifyChangeSpinStatus(self)
        self.m_norDownTimes = 0
    end
end

function CodeGameScreenMermaidMachine:setDownTimes(time)
    self.m_norSlotsDownTimes = self.m_norSlotsDownTimes + time
    if self.m_norSlotsDownTimes == 2 then
        BaseFastMachine.slotReelDown(self)

        self:checkTriggerOrInSpecialGame(
            function()
                self:reelsDownDelaySetMusicBGVolume()
            end
        )

        self.m_norSlotsDownTimes = 0
    end
end

function CodeGameScreenMermaidMachine:scatterCollectAction(beginNode, func, actType)
    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_+3_fly.mp3")

    local node = util_createAnimation("Socre_Mermaid_big_Scatter_Collect.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    node:findChild("Particle_1_0"):setPositionType(0)
    node:findChild("Particle_1_0"):setDuration(40 / 30)

    beginNode:runAnim("shouji")

    local startWorldPos = beginNode:convertToWorldSpace(cc.p(beginNode:getCcbProperty("Node_actMove"):getPosition()))
    local startPos = self:convertToNodeSpace(cc.p(startWorldPos))
    node:setPosition(startPos)

    local endWorldPos = self.m_baseFreeSpinBar:convertToWorldSpace(cc.p(self.m_baseFreeSpinBar:findChild("Node_End"):getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))

    local moveTime = 21 / 30
    local topActType = 1
    local downActType = 2

    if actType == topActType then
        moveTime = 15 / 30
        node:runCsbAction("shouji2")
    else
        node:runCsbAction("shouji")
    end

    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(5 / 30)
    actionList[#actionList + 1] = cc.MoveTo:create(moveTime, cc.p(endPos))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            -- node:setVisible(false)

            gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_+3_fly_over.mp3")

            if func then
                func()
            end
        end
    )
    actionList[#actionList + 1] = cc.DelayTime:create(moveTime / 2)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:removeFromParent()
        end
    )

    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenMermaidMachine:fsFixBonusCollectAction(beginNode, time, func)
    local node = util_createAnimation("Mermaid_tuowei_qipao.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    node:findChild("Particle_1"):setPositionType(0)
    node:findChild("Particle_1"):setDuration(time)

    if beginNode.p_cloumnIndex == 1 or beginNode.p_cloumnIndex == 5 then
        node:findChild("Particle_1"):setScale(0.5)
    end

    local startWorldPos = beginNode:convertToWorldSpace(cc.p(beginNode:getCcbProperty("Node_actMove"):getPosition()))
    local startPos = self:convertToNodeSpace(cc.p(startWorldPos))
    node:setPosition(startPos)

    local endWorldPos = self.m_bottomUI:getCoinWinNode():getParent():convertToWorldSpace(cc.p(self.m_bottomUI:getCoinWinNode():getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))

    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(time, cc.p(endPos))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            -- node:setVisible(false)

            if func then
                func()
            end
        end
    )
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:removeFromParent()
        end
    )

    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenMermaidMachine:fsFixBonusCollectJackPotAction(beginNode, time, func)
    local node = util_createAnimation("Mermaid_tuowei_qipao.csb")
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    node:findChild("Particle_1"):setPositionType(0)
    node:findChild("Particle_1"):setDuration(time)

    local startWorldPos = beginNode:getParent():convertToWorldSpace(cc.p(beginNode:getPosition()))
    local startPos = self:convertToNodeSpace(cc.p(startWorldPos))
    node:setPosition(startPos)

    local endWorldPos = self.m_bottomUI:getCoinWinNode():getParent():convertToWorldSpace(cc.p(self.m_bottomUI:getCoinWinNode():getPosition()))
    local endPos = self:convertToNodeSpace(cc.p(endWorldPos))

    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(time, cc.p(endPos))
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            -- node:setVisible(false)

            if func then
                func()
            end
        end
    )
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            node:removeFromParent()
        end
    )

    node:runAction(cc.Sequence:create(actionList))
end

function CodeGameScreenMermaidMachine:playFsCollectChipCollectAnim()
    if self.m_fsCollectPlayAnimIndex > #self.m_fsCollectChipList then
        if self.m_fsCollectChipCallFunc then
            self.m_fsCollectChipCallFunc()
        end

        return
    end

    local chipNode = self.m_fsCollectChipList[self.m_fsCollectPlayAnimIndex]

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = self.m_mainClass:getPosReelIdx(iRow, iCol)

    if self:isBigFixSymbol(chipNode.p_symbolType) then
        nFixIdx = -1
    end

    local score = self.m_mainClass:getReSpinSymbolScore(nFixIdx)

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet()

    if score ~= nil then
        if nFixIdx == -1 then
            if chipNode.p_symbolType == self.SYMBOL_BIG_FIX_GRAND then
                jackpotScore = self.m_mainClass:getJackpotScoreFromNet(nFixIdx)
                addScore = jackpotScore + addScore
                nJackpotType = 1
            elseif chipNode.p_symbolType == self.SYMBOL_BIG_FIX_MAJOR then
                jackpotScore = self.m_mainClass:getJackpotScoreFromNet(nFixIdx)
                addScore = jackpotScore + addScore
                nJackpotType = 2
            elseif chipNode.p_symbolType == self.SYMBOL_BIG_FIX_MINOR then
                jackpotScore = self.m_mainClass:getJackpotScoreFromNet(nFixIdx)
                addScore = jackpotScore + addScore
                nJackpotType = 3
            elseif chipNode.p_symbolType == self.SYMBOL_BIG_FIX_MINI then
                jackpotScore = self.m_mainClass:getJackpotScoreFromNet(nFixIdx)
                addScore = jackpotScore + addScore
                nJackpotType = 4
            else
                addScore = score * lineBet
            end
        else
            if type(score) ~= "string" then
                addScore = score * lineBet
            elseif score == "GRAND" then
                jackpotScore = self.m_mainClass:getJackpotScoreFromNet(nFixIdx)
                addScore = jackpotScore + addScore
                nJackpotType = 1
            elseif score == "MAJOR" then
                jackpotScore = self.m_mainClass:getJackpotScoreFromNet(nFixIdx)
                addScore = jackpotScore + addScore
                nJackpotType = 2
            elseif score == "MINOR" then
                jackpotScore = self.m_mainClass:getJackpotScoreFromNet(nFixIdx)
                addScore = jackpotScore + addScore
                nJackpotType = 3
            elseif score == "MINI" then
                jackpotScore = self.m_mainClass:getJackpotScoreFromNet(nFixIdx)
                addScore = jackpotScore + addScore
                nJackpotType = 4
            end
        end
    end

    local function fishFlyEndJiesuan()
        if nJackpotType == 0 then
            self.m_fsCollectPlayAnimIndex = self.m_fsCollectPlayAnimIndex + 1

            local coins = self.m_fsLastWinCoins + addScore
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
            globalData.slotRunData.lastWinCoin = lastWinCoin

            self.m_fsLastWinCoins = coins
            self.m_actLastWinCoins = coins

            self:playCoinWinEffectUI()

            performWithDelay(
                self,
                function()
                    self:playFsCollectChipCollectAnim()
                end,
                0.5
            )
        else
            gLobalSoundManager:setBackgroundMusicVolume(0.4)

            self:showRespinJackpot(
                nJackpotType,
                jackpotScore,
                function()
                    gLobalSoundManager:setBackgroundMusicVolume(1)

                    local startNode = self.m_jackPotWinView:findChild("Node_FlyNodePos")

                    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_RsFixBonus_Collect.mp3")

                    -- self:fsFixBonusCollectJackPotAction(startNode,0.4 )
                    performWithDelay(
                        self,
                        function()
                            -- gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_+3_fly_over.mp3")

                            self:playCoinWinEffectUI()

                            local coins = self.m_fsLastWinCoins + addScore
                            local lastWinCoin = globalData.slotRunData.lastWinCoin
                            globalData.slotRunData.lastWinCoin = 0
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
                            globalData.slotRunData.lastWinCoin = lastWinCoin

                            self.m_fsLastWinCoins = coins
                            self.m_actLastWinCoins = coins
                            self.m_fsCollectPlayAnimIndex = self.m_fsCollectPlayAnimIndex + 1

                            self.m_jackPotWinView:runCsbAction(
                                "over",
                                false,
                                function()
                                    self.m_jackPotWinView:removeFromParent()
                                    self.m_jackPotWinView = nil
                                    performWithDelay(
                                        self,
                                        function()
                                            self:playFsCollectChipCollectAnim()
                                        end,
                                        0.1
                                    )
                                end
                            )
                        end,
                        0.3
                    )
                end,
                true
            )
        end
    end

    local flyTimes = 0.4

    -- if chipNode.p_rowIndex >4  then
    --     flyTimes = 3
    -- end

    if nJackpotType == 0 then
        -- end, flyTimes , self:getModuleName())
        gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_RsFixBonus_Collect.mp3")

        chipNode:runAnim("jiesuan", false)

        -- self:fsFixBonusCollectAction(chipNode,flyTimes )

        -- scheduler.performWithDelayGlobal(function()
        -- gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_+3_fly_over.mp3")

        fishFlyEndJiesuan()
    else
        gLobalSoundManager:playSound("MermaidSounds/Mermaid_fs_getJap_trigger.mp3")

        chipNode:runAnim(
            "actionframe",
            false,
            function()
                fishFlyEndJiesuan()
            end
        )
    end
end

function CodeGameScreenMermaidMachine:showFsGuoChang(func, func2)
    local oldPos = cc.p(self:findChild("reel"):getPosition())

    local actList = {}
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            -- 开始播放

            gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_FsStart_GuoChang.mp3")

            self.m_FsGuoChangBg_1:runCsbAction(
                "animation0",
                false,
                function()
                    self.m_FsGuoChangBg_1:setVisible(false)
                end
            ) -- 下
            self.m_FsGuoChangBg_2:runCsbAction(
                "animation0",
                false,
                function()
                    self.m_FsGuoChangBg_2:setVisible(false)
                end
            ) -- 上

            self.m_FsGuoChangQiPao_1:runCsbAction(
                "animation0",
                false,
                function()
                    self.m_FsGuoChangQiPao_1:setVisible(false)
                end
            ) -- 下
            self.m_FsGuoChangQiPao_2:runCsbAction(
                "animation0",
                false,
                function()
                    self.m_FsGuoChangQiPao_2:setVisible(false)
                end
            ) -- 上

            self.m_FsGuoChangBg_1:setVisible(false)
            self.m_FsGuoChangBg_2:setVisible(true)
            self.m_FsGuoChangQiPao_1:setVisible(false)
            self.m_FsGuoChangQiPao_2:setVisible(true)

            util_playFadeOutAction(self:findChild("reel"), 8 / 30)
            util_playFadeOutAction(
                self.m_Mermaid_JpBarView,
                8 / 30,
                function()
                    self.m_Mermaid_JpBarView:setVisible(false)
                    util_playFadeInAction(
                        self.m_Mermaid_JpBarView,
                        8 / 30,
                        function()
                        end
                    )
                end
            )
        end
    )
    actList[#actList + 1] = cc.DelayTime:create(9 / 30)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            -- 开始播放

            self:findChild("reel"):setPosition(cc.p(oldPos.x, oldPos.y - display.height / 2 - 930))
            util_playFadeInAction(self:findChild("reel"), 3 / 30)
        end
    )
    actList[#actList + 1] = cc.DelayTime:create(3 / 30)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            -- 开始播放

            self.m_FsGuoChangSpine:setVisible(true)
            self.m_FsGuoChangQiPao:setVisible(true)

            util_spinePlay(self.m_FsGuoChangSpine, "guochang4")

            util_spineFrameCallFunc(
                self.m_FsGuoChangSpine,
                "guochang4",
                "qipao",
                function()
                    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_Jp_yu_FeiWen.mp3")
                end,
                function()
                    self.m_FsGuoChangSpine:setVisible(false)
                end
            )
            self:findChild("reel"):setVisible(true)
        end
    )
    actList[#actList + 1] = cc.DelayTime:create(3 / 30)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            --开始移动

            if func2 then
                func2()
            end

            self:runCsbAction("idle2")
            self.m_FsGuoChangBg_1:setVisible(true)
            self.m_FsGuoChangBg_2:setVisible(false)
            self.m_FsGuoChangQiPao_1:setVisible(true)
            self.m_FsGuoChangQiPao_2:setVisible(false)

            self:findChild("Node_MinIFsReel"):setVisible(true)
            self:findChild("reel"):setVisible(true)
            self:findChild("Node_logo"):setVisible(false)
            self:findChild("jindutiao"):setVisible(false)
            self.m_IceMainNode:setVisible(false)

            if self.m_FsMiniReel.m_runSpinResultData.p_winLines and #self.m_FsMiniReel.m_runSpinResultData.p_winLines > 0 then
                self.m_FsMiniReel.m_runSpinResultData.p_winLines = {}
            end
        end
    )
    actList[#actList + 1] = cc.EaseInOut:create(cc.MoveTo:create(45 / 30, cc.p(oldPos)), 1)
    actList[#actList + 1] = cc.DelayTime:create(12 / 30)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            -- 过场
            if func then
                func()
            end
        end
    )
    actList[#actList + 1] = cc.DelayTime:create(17 / 30)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            -- 消失

            self.m_FsGuoChangQiPao:findChild("Particle_1"):resetSystem()

            gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_FsStart_GuoChang_yuXiaoShi.mp3")
        end
    )
    actList[#actList + 1] = cc.DelayTime:create(60 / 30)
    actList[#actList + 1] =
        cc.CallFunc:create(
        function()
            self.m_FsGuoChangQiPao:setVisible(false)
        end
    )

    self:findChild("reel"):runAction(cc.Sequence:create(actList))

    local oldPos_1 = cc.p(self:findChild("Node_Fs_StartGuoChang"):getPosition())
    self:findChild("Node_Fs_StartGuoChang"):setPosition(cc.p(oldPos_1.x, oldPos_1.y - display.height / 2 - 500))

    local actList_1 = {}
    actList_1[#actList_1 + 1] = cc.DelayTime:create(11 / 30)
    actList_1[#actList_1 + 1] = cc.EaseInOut:create(cc.MoveTo:create(45 / 30, cc.p(oldPos_1)), 1)
    self:findChild("Node_Fs_StartGuoChang"):runAction(cc.Sequence:create(actList_1))
end

function CodeGameScreenMermaidMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("node_bg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end

--绘制多个裁切区域
function CodeGameScreenMermaidMachine:drawReelArea()
    local iColNum = self.m_iReelColumnNum
    self.m_clipParent = self.m_csbOwner["sp_reel_0"]:getParent()
    self.m_slotParents = {}
    local slotW = 0
    local slotH = 0
    local lMax = util_max
    -- 取底边  和 上边
    local prePosX = -1

    self:checkOnceClipNode()
    for i = 1, iColNum, 1 do
        local colNodeName = "sp_reel_" .. (i - 1)
        local reel = self:findChild(colNodeName)
        local reelSize = reel:getContentSize()
        local posX = reel:getPositionX()
        local posY = reel:getPositionY()
        local scaleX = reel:getScaleX()
        local scaleY = reel:getScaleY()

        reelSize.width = reelSize.width * scaleX
        reelSize.height = reelSize.height * scaleY

        local diffW = 0
        if prePosX == -1 then
            slotW = slotW + reelSize.width
        else
            diffW = (posX - prePosX - reelSize.width)
            slotW = slotW + reelSize.width + diffW
        end
        prePosX = posX

        slotH = lMax(slotH, reelSize.height)

        local clipNodeWidth = reelSize.width * 2 * self:getClipWidthRatio(i)
        local clipWidthX = -(clipNodeWidth - reelSize.width * 2) / 2

        local clipNode
        local clipNodeBig
        if self.m_onceClipNode then
            clipNode = cc.Node:create()
            clipNode:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNode.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)

            clipNodeBig = cc.Node:create()
            clipNodeBig:setContentSize(clipNodeWidth, reelSize.height)
            --假函数
            clipNodeBig.getClippingRegion = function()
                return {width = clipNodeWidth, height = reelSize.height}
            end
            self.m_onceClipNode:addChild(clipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000)
        else
            clipNode =
                cc.ClippingRectangleNode:create(
                {
                    x = clipWidthX,
                    y = 0,
                    width = clipNodeWidth,
                    height = reelSize.height
                }
            )
            self.m_clipParent:addChild(clipNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE)
        end

        local slotParentNode = cc.Layer:create() --cc.LayerColor:create(cc.c4f(r,g,b,200))
        slotParentNode:setContentSize(reelSize.width * 2, reelSize.height)
        --slotParentNode:setPositionX(- reelSize.width * 0.5)
        clipNode:addChild(slotParentNode)
        clipNode:setPosition(posX - reelSize.width * 0.5, posY)
        clipNode:setTag(CLIP_NODE_TAG + i)
        -- slotParentNode:setVisible(false)

        local parentData = SlotParentData:new()
        parentData.slotParent = slotParentNode
        parentData.cloumnIndex = i
        parentData.rowNum = self.m_iReelRowNum
        parentData.rowIndex = self.m_iReelRowNum -- 由于出事创建时 默认创建了一组， 所以默认选择最后一行
        parentData.startX = reelSize.width * 0.5
        parentData:reset()

        self.m_slotParents[i] = parentData

        if clipNodeBig then
            local slotParentNodeBig = cc.Layer:create()
            slotParentNodeBig:setContentSize(reelSize.width * 2, reelSize.height)
            clipNodeBig:addChild(slotParentNodeBig)
            clipNodeBig:setPosition(posX - reelSize.width * 0.5, posY)
            parentData.slotParentBig = slotParentNodeBig
        end
    end

    if self.m_clipParent ~= nil then
        self.m_slotEffectLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        -- self.m_slotEffectLayer:setOpacity(55)
        self.m_slotEffectLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotEffectLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotEffectLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))

        self.m_clipParent:addChild(self.m_slotEffectLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER) -- 防止在最上层

        self.m_slotFrameLayer = cc.Layer:create() -- cc.c4f(0,0,0,255),
        -- self.m_slotFrameLayer:setOpacity(55)
        self.m_slotFrameLayer:setContentSize(cc.size(slotW, slotH))
        self.m_slotFrameLayer:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_slotFrameLayer:setPosition(cc.p(-slotW * 0.5, -slotH * 0.5))
        self.m_clipParent:addChild(self.m_slotFrameLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME, 1)

        self.m_touchSpinLayer = ccui.Layout:create()
        self.m_touchSpinLayer:setContentSize(cc.size(slotW, slotH))
        self.m_touchSpinLayer:setAnchorPoint(cc.p(0, 0))
        self.m_touchSpinLayer:setTouchEnabled(true)
        self.m_touchSpinLayer:setSwallowTouches(false)

        self.m_clipParent:addChild(self.m_touchSpinLayer, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME * 2)
        self.m_touchSpinLayer:setPosition(self.m_csbOwner["sp_reel_0"]:getPosition())
        self.m_touchSpinLayer:setName("touchSpin")
    end
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function CodeGameScreenMermaidMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
    if isMustPlayMusic == nil then
        isMustPlayMusic = false
    end
    local preBgMusic = self.m_currentMusicBgName

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self.m_currentMusicBgName = self:getFreeSpinMusicBG()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif self:getCurrSpinMode() == RESPIN_MODE then
        self.m_currentMusicBgName = self:getReSpinMusicBg()
        if self.m_currentMusicBgName == nil then
            self.m_currentMusicBgName = self:getNormalMusicBg()
        end
    elseif selfMakePlayMusicName then
        self.m_currentMusicBgName = selfMakePlayMusicName
    else
        self.m_currentMusicBgName = self:getNormalMusicBg()
    end

    if self.m_currentMusicBgName ~= nil and self.m_currentMusicBgName ~= "" then
        if preBgMusic ~= self.m_currentMusicBgName or isMustPlayMusic == true then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
        if self.m_currentMusicId == nil then
            self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
        end
    else
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
        self.m_currentMusicId = nil
    end
end

function CodeGameScreenMermaidMachine:changeLocalViewNodePos()
end

function CodeGameScreenMermaidMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

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
        if display.height >= DESIGN_SIZE.height then
            mainScale = (DESIGN_SIZE.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 10)
        elseif display.height < DESIGN_SIZE.height and display.height >= 1294 then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 10)
        elseif display.height < 1294 and display.height >= 1224 then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH - 10)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 8)
        elseif display.height < 1224 and display.height >= 1184 then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH - 20)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 3)
        elseif display.height < 1184 and display.height >= 1144 then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH - 30)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY())
        elseif display.height < 1144 and display.height >= 1114 then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH - 40)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 3)
        elseif display.height < 1114 and display.height >= 1084 then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH - 50)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 3)
        elseif display.height < 1084 and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH - 60)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
        else
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH - 70)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 5)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    self:changeLocalViewNodePos()
end

function CodeGameScreenMermaidMachine:setSpecialSymbolToClipReel(_iCol, _iRow, _type)
    local targSp = self:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    if targSp ~= nil then
        local slotParent = targSp:getParent()
        local posWorld = slotParent:convertToWorldSpace(cc.p(targSp:getPositionX(), targSp:getPositionY()))
        local pos = self.m_clipParent:convertToNodeSpace(cc.p(posWorld.x, posWorld.y))
        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
        local showOrder = self:getBounsScatterDataZorder(_type) - _iRow
        targSp.m_showOrder = showOrder
        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        targSp:removeFromParent()
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + _iCol, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
        local linePos = {}
        linePos[#linePos + 1] = {iX = _iRow, iY = _iCol}
        targSp.m_bInLine = true
        targSp:setLinePos(linePos)
    end
    return targSp
end

function CodeGameScreenMermaidMachine:changeReelSymbolNode(isFree)
    if isFree then
        self.m_FsMiniReel:changeReelSymbolNode()

        local colList = {2, 3, 4}

        for index = 1, #colList do
            local iCol = colList[index]
            for iRow = 1, self.m_iReelRowNum do
                local slotNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotNode then
                    local ccbNode = slotNode:checkLoadCCbNode()
                    if ccbNode ~= nil then
                        ccbNode:setVisible(false)
                    end

                    if slotNode.p_symbolImage then
                        slotNode.p_symbolImage:setVisible(false)
                    end
                end
            end
        end

        -- 随机创建一个大图标覆盖在轮子上
        local symbolType = self:getOneBigSymbol()
        local colIndex = 3
        local rowIndex = 1
        local parentData = self.m_slotParents[colIndex]
        local reelColData = self.m_reelColDatas[colIndex]
        local halfNodeH = reelColData.p_showGridH * 0.5

        local showOrder = self:getBounsScatterDataZorder(symbolType)
        local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)
        parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
        node.p_slotNodeH = reelColData.p_showGridH
        node.p_symbolType = symbolType
        node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType)
        node.p_reelDownRunAnima = parentData.reelDownAnima
        node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
        node:setPositionY((rowIndex - 1) * reelColData.p_showGridH + halfNodeH)

        -- 把长条wild变成普通小块
        self:changeLongWildSymbolNode()
    else
        local bigSymbol = self:getFixSymbol(3, 1, SYMBOL_NODE_TAG)
        if bigSymbol then
            local ccbNode = bigSymbol:checkLoadCCbNode()
            if ccbNode ~= nil then
                ccbNode:setVisible(false)
            end

            if bigSymbol.p_symbolImage then
                bigSymbol.p_symbolImage:setVisible(false)
            end
        end

        local colList = {2, 3, 4}

        for index = 1, #colList do
            local colIndex = colList[index]

            for rowIndex = 1, self.m_iReelRowNum do
                local symbolType = self:getOneNorSymbol()
                local parentData = self.m_slotParents[colIndex]
                local reelColData = self.m_reelColDatas[colIndex]
                local halfNodeH = reelColData.p_showGridH * 0.5
                local showOrder = self:getBounsScatterDataZorder(symbolType)
                local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)

                parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
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
end

function CodeGameScreenMermaidMachine:changeLongWildSymbolNode()
    local col_1_5_List = {1, 5}

    for index = 1, #col_1_5_List do
        local colIndex = col_1_5_List[index]
        for rowIndex = 1, self.m_iReelRowNum do
            local slotNode = self:getFixSymbol(colIndex, rowIndex, SYMBOL_NODE_TAG)
            if slotNode and slotNode.p_symbolType == self.SYMBOL_BIG_LONG_WILD then
                local ccbNode = slotNode:checkLoadCCbNode()
                if ccbNode ~= nil then
                    ccbNode:setVisible(false)
                end

                if slotNode.p_symbolImage then
                    slotNode.p_symbolImage:setVisible(false)
                end
            end

            local rowCount = #self.m_runSpinResultData.p_reels

            local SymbolMatrixType = self.m_runSpinResultData.p_reels[rowCount - rowIndex + 1][colIndex]

            if SymbolMatrixType == self.SYMBOL_BIG_LONG_WILD then
                local symbolType = self:getOneNorSymbol()
                local parentData = self.m_slotParents[colIndex]
                local reelColData = self.m_reelColDatas[colIndex]
                local halfNodeH = reelColData.p_showGridH * 0.5
                local showOrder = self:getBounsScatterDataZorder(symbolType)
                local node = self:getSlotNodeWithPosAndType(symbolType, rowIndex, colIndex, false)

                parentData.slotParent:addChild(node, showOrder - rowIndex, colIndex * SYMBOL_NODE_TAG + rowIndex)
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
end

function CodeGameScreenMermaidMachine:getOneBigSymbol()
    local symbolList = {
        self.SYMBOL_BIG_FIX_MAJOR,
        self.SYMBOL_BIG_FIX_MINOR,
        self.SYMBOL_BIG_FIX_MINI,
        self.SYMBOL_BIG_WILD,
        self.SYMBOL_BIG_SCORE_1,
        self.SYMBOL_BIG_SCORE_2,
        self.SYMBOL_BIG_SCORE_3,
        self.SYMBOL_BIG_SCORE_4,
        self.SYMBOL_BIG_SCORE_5,
        self.SYMBOL_BIG_SCORE_6,
        self.SYMBOL_BIG_SCORE_7,
        self.SYMBOL_BIG_SCORE_8,
        self.SYMBOL_BIG_SCORE_9
    }

    return symbolList[math.random(1, #symbolList)]
end

function CodeGameScreenMermaidMachine:getOneNorSymbol()
    local symbolList = {0, 1, 2, 3, 4, 5, 6, 7, 8}

    return symbolList[math.random(1, #symbolList)]
end

local curWinType = 0
---
-- 增加赢钱后的 效果
function CodeGameScreenMermaidMachine:addLastWinSomeEffect() -- add big win or mega win
    local lines = self.m_LocalData_p_winLines -- self.m_reelResultLines

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        if lines == nil or #lines == 0 then
            if self.m_FsMiniReel then
                if not self:checkFsFrist() then
                    lines = self.m_FsMiniReel.m_LocalData_p_winLines
                end
            end
        end
    end

    if #lines == 0 then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = self.m_iOnceSpinLastWin / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

--小块
function CodeGameScreenMermaidMachine:getBaseReelGridNode()
    return "CodeMermaidSrc.MermaidSlotFastNode"
end

--[[
    @desc: 获取滚动停止时上面补充的小块 类型
    time:2019-05-15 18:28:13
    --@parentData:
    @return:
]]
function CodeGameScreenMermaidMachine:getResNodeSymbolType(parentData)
    local reelDatas = nil
    local colIndex = parentData.cloumnIndex
    local symbolType = nil
    local resTopTypes = self.m_runSpinResultData.p_nextReel
    local symbolType = nil
    if resTopTypes == nil or resTopTypes[colIndex] == nil then
        if self:checkHasEffectType(GameEffect.EFFECT_FREE_SPIN) and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            --此时取信号 normalspin
            reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
        elseif globalData.slotRunData.freeSpinCount == 0 and self.m_iFreeSpinTimes == 0 and self:getCurrSpinMode() == FREE_SPIN_MODE then
            --此时取信号 freeSpin
            reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
        else
            --上次信号 + 1
            reelDatas = parentData.reelDatas
        end

        symbolType = self:getReelSymbolType(parentData)
    else
        symbolType = resTopTypes[colIndex]
    end

    return symbolType
end

function CodeGameScreenMermaidMachine:updateNetWorkData()
    self:setCreateResNode()

    BaseFastMachine.updateNetWorkData(self)
end

---
-- 获取界面上的小块
--
function CodeGameScreenMermaidMachine:getReelParentChildNode(iCol, iRow)
    local childNode = nil
    local childTag = self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG)

    self:foreachSlotParent(
        iCol,
        function(index, realIndex, node)
            if node:getTag() == childTag then
                childNode = node
                return true
            end
        end
    )

    if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[iCol] ~= nil and not childNode then
        local bigSymbolInfos = self.m_bigSymbolColumnInfo[iCol]
        for k = 1, #bigSymbolInfos do
            local bigSymbolInfo = bigSymbolInfos[k]

            for changeIndex = 1, #bigSymbolInfo.changeRows do
                if bigSymbolInfo.changeRows[changeIndex] == iRow then
                    local slotParent = self:getReelParent(iCol)
                    local slotParentBig = self:getReelBigParent(iCol)

                    childNode = slotParent:getChildByTag(iCol * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                    if childNode == nil and slotParentBig then
                        childNode = slotParentBig:getChildByTag(iCol * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)
                    end
                    break
                end
            end
        end
    end

    return childNode
end

function CodeGameScreenMermaidMachine:updateBigSymbolColumnInfo()
    local rowCount = #self.m_runSpinResultData.p_reels
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            local symbolType = rowDatas[colIndex]
            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_NIL_TYPE then
                symbolType = nil
            end
            self.m_stcValidSymbolMatrix[rowCount - rowIndex + 1][colIndex] = symbolType
        end
    end

    -- 处理大信号信息
    if self.m_hasBigSymbol == true then
        self.m_bigSymbolColumnInfo = {}
    else
        self.m_bigSymbolColumnInfo = nil
    end

    local iColumn = self.m_iReelColumnNum
    local iRow = self.m_iReelRowNum

    for colIndex = 1, iColumn do
        local rowIndex = 1

        while true do
            if rowIndex > iRow then
                break
            end
            local symbolType = self.m_stcValidSymbolMatrix[rowIndex][colIndex]
            -- 判断是否有大信号内容
            if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil then
                local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG, changeRows = {}}

                local colDatas = self.m_bigSymbolColumnInfo[colIndex]
                if colDatas == nil then
                    colDatas = {}
                    self.m_bigSymbolColumnInfo[colIndex] = colDatas
                end

                colDatas[#colDatas + 1] = bigInfo

                local symbolCount = self.m_bigSymbolInfos[symbolType]

                local hasCount = 1

                bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex

                for checkIndex = rowIndex + 1, iRow do
                    local checkType = self.m_stcValidSymbolMatrix[checkIndex][colIndex]
                    if checkType == symbolType then
                        hasCount = hasCount + 1

                        bigInfo.changeRows[#bigInfo.changeRows + 1] = checkIndex
                    else
                        break
                    end
                    if symbolCount == hasCount then
                        break
                    end
                end

                if symbolCount == hasCount or rowIndex > 1 then -- 表明从对应索引开始的
                    bigInfo.startRowIndex = rowIndex
                else
                    bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
                end

                rowIndex = rowIndex + hasCount - 1 -- 跳过上面有的
            end -- end if ~= nil

            rowIndex = rowIndex + 1
        end
    end
end

function CodeGameScreenMermaidMachine:hideTipView()
    if self.m_tipShow then
        if not self.m_hideTip then
            self.m_hideTip = true
            self.m_tipView:runCsbAction(
                "over",
                false,
                function()
                    self.m_hideTip = false
                    self.m_tipShow = false
                    self.m_tipView:setVisible(false)
                end
            )
        end
    end
end

function CodeGameScreenMermaidMachine:checkShowTipView()
    if self:isNormalStates() then
        if self.m_showClick and not self.m_tipShow then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            self.m_tipShow = true
            self.m_tipView:setVisible(true)
            self.m_tipView:runCsbAction(
                "open",
                false,
                function()
                    self.m_tipView:runCsbAction("idle", true)

                    scheduler.performWithDelayGlobal(
                        function()
                            if not self.m_hideTip then
                                self.m_hideTip = true
                                self.m_tipView:runCsbAction(
                                    "over",
                                    false,
                                    function()
                                        self.m_hideTip = false
                                        self.m_tipShow = false
                                        self.m_tipView:setVisible(false)
                                    end
                                )
                            end
                        end,
                        3,
                        self:getModuleName()
                    )
                end
            )
        end
    end
end

-- 本地存储 MermaidBonusViewPickTimes

function CodeGameScreenMermaidMachine:getPickTimes()
    local pickTimes = gLobalDataManager:getStringByField("MermaidBonusViewPickTimes", "")
    if pickTimes ~= "" then
        return tonumber(pickTimes)
    end
    return 0
end

function CodeGameScreenMermaidMachine:setPickTimes(value)
    gLobalDataManager:setStringByField("MermaidBonusViewPickTimes", value, true)
end

function CodeGameScreenMermaidMachine:createFinalResult(slotParent, slotParentBig, parentPosY, columnData, parentData)
    local childs = slotParent:getChildren()
    if slotParentBig then
        local newChilds = slotParentBig:getChildren()
        for i = 1, #newChilds do
            childs[#childs + 1] = newChilds[i]
        end
    end

    for childIndex = 1, #childs do
        local child = childs[childIndex]
        self:moveDownCallFun(child, parentData.cloumnIndex)
    end

    local index = 1

    while index <= columnData.p_showGridCount do -- 只改了这 为了适应freespin
        self:createSlotNextNode(parentData)
        local symbolType = parentData.symbolType
        local node = self:getCacheNode(parentData.cloumnIndex, symbolType)
        if node == nil then
            node = self:getSlotNodeWithPosAndType(symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
            local slotParentBig = parentData.slotParentBig
            -- 添加到显示列表
            if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                slotParentBig:addChild(node, parentData.order, parentData.tag)
            else
                slotParent:addChild(node, parentData.order, parentData.tag)
            end
        else
            local tmpSymbolType = self:convertSymbolType(symbolType)
            node:setVisible(true)
            node:setLocalZOrder(parentData.order)
            node:setTag(parentData.tag)
            local ccbName = self:getSymbolCCBNameByType(self, tmpSymbolType)
            node:initSlotNodeByCCBName(ccbName, tmpSymbolType)
            self:setSlotCacheNodeWithPosAndType(node, symbolType, parentData.rowIndex, parentData.cloumnIndex, parentData.m_isLastSymbol)
        end

        local posY = columnData.p_showGridH * (parentData.rowIndex - 0.5) - parentPosY

        node:setPosition(parentData.startX + self.m_SlotNodeW * 0.5, posY)

        node.p_cloumnIndex = parentData.cloumnIndex
        node.p_rowIndex = parentData.rowIndex
        node.m_isLastSymbol = parentData.m_isLastSymbol

        node.p_slotNodeH = columnData.p_showGridH
        node.p_symbolType = parentData.symbolType
        node.p_preSymbolType = parentData.preSymbolType
        node.p_showOrder = parentData.order

        node.p_reelDownRunAnima = parentData.reelDownAnima

        node.p_reelDownRunAnimaSound = parentData.reelDownAnimaSound
        node.p_layerTag = parentData.layerTag
        node:setTag(parentData.tag)
        node:setLocalZOrder(parentData.order)

        node:runIdleAnim()
        -- node:setVisible(false)
        if parentData.isLastNode == true then -- 本列最后一个节点移动结束
            -- 执行回弹, 如果不执行回弹判断是否执行
            parentData.isReeling = false
            -- printInfo("xcyy 停下来的parent 位置为 : %d  %f  ", parentData.cloumnIndex,slotParent:getPositionY())
            -- 创建一个假的小块 在回滚停止后移除

            self:createResNode(parentData, node)
        end

        if self.m_bigSymbolInfos[parentData.symbolType] ~= nil then
            local addCount = self.m_bigSymbolInfos[parentData.symbolType]
            index = addCount + node.p_rowIndex
        else
            index = index + 1
        end
    end
end

-- 活动赠送免费spin次数

function CodeGameScreenMermaidMachine:checkAddRewaedStartFSEffect()
    if self.m_merFeatureData and self.m_merFeatureData.p_status == "CLOSED" then
        local bonusdata = self.m_merFeatureData.p_bonus or {}
        local extra = bonusdata.extra or {}
        local picks = extra.picks or {}
        local userDataPickTimes = self:getPickTimes()
        if userDataPickTimes > 0 and #picks > 0 then
            return false
        else
            return true
        end
    end

    return CodeGameScreenMermaidMachine.super.checkAddRewaedStartFSEffect(self)
end

function CodeGameScreenMermaidMachine:initGameStatusData(gameData)
    CodeGameScreenMermaidMachine.super.initGameStatusData(self,gameData)
end

function CodeGameScreenMermaidMachine:updateReelGridNode(symbolNode)
    if symbolNode.p_symbolType == self.SYMBOL_SMALL_FIX_GRAND or symbolNode.p_symbolType == self.SYMBOL_BIG_FIX_GRAND then
        symbolNode:getCcbProperty("node_grand"):setVisible(self.m_jackpot_status == "Normal")
        symbolNode:getCcbProperty("node_mega"):setVisible(self.m_jackpot_status == "Mega")
        symbolNode:getCcbProperty("node_super"):setVisible(self.m_jackpot_status == "Super")
    end
end

-------------------------------------------------公共jackpot-----------------------------------------------------------------------

--[[
    更新公共jackpot状态
]]
function CodeGameScreenMermaidMachine:updataJackpotStatus(params)
    local totalBetID = globalData.slotRunData:getCurTotalBet()

    self.m_jackpot_status = "Normal" -- "Mega" "Super"

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        self:updateJackpotBarMegaShow()
        return
    end

    if self.m_isJackpotEnd then
        self:updateJackpotBarMegaShow()
        return
    end

    if not mgr:isDownloadRes() then
        self:updateJackpotBarMegaShow()
        return
    end
    
    local data = mgr:getRunningData()
    if not data or not next(data) then
        self:updateJackpotBarMegaShow()
        return
    end

    local levelData = data:getLevelDataByBet(totalBetID)
    local levelName = levelData.p_name
    self.m_jackpot_status = levelName
    self:updateJackpotBarMegaShow()
end

function CodeGameScreenMermaidMachine:updateJackpotBarMegaShow()
    self.m_Mermaid_JpBarView:updateMegaShow()
    self.m_Mermaid_Fe_JpBarView:updateMegaShow()
end

function CodeGameScreenMermaidMachine:getCommonJackpotValue(_status, _addTimes)
    _addTimes = math.floor(_addTimes)
    local value     = 0
    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if _status == "Mega" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Mega)
        end
    elseif _status == "Super" then
        if mgr then
            value = mgr:getJackpotValue(CommonJackpotCfg.LEVEL_NAME.Super)
        end
    end

    return value
end

--[[
    新增顶栏和按钮
]]
function CodeGameScreenMermaidMachine:initTopCommonJackpotBar()
    if not ACTIVITY_REF.CommonJackpot then
        return 
    end

    local mgr = G_GetMgr(ACTIVITY_REF.CommonJackpot)
    if not mgr or not mgr:isLevelEffective() then
        return
    end

    local commonJackpotTitle = mgr:createTitleNode()

    if not commonJackpotTitle then
        return
    end
    self.m_commonJackpotTitle = commonJackpotTitle
    self:addChild(self.m_commonJackpotTitle, GAME_LAYER_ORDER.LAYER_ORDER_TOP - 1)
    local titlePos = util_getConvertNodePos(self.m_topUI:findChild("TopUI_down"), self)
    local topSpSize = self.m_commonJackpotTitle:findChild("sp_Jackpot1"):getContentSize()
    titlePos.y = titlePos.y - topSpSize.height*0.25
    self.m_commonJackpotTitle:setPosition(titlePos)
    self.m_commonJackpotTitle:setScale(globalData.topUIScale)
    
end

return CodeGameScreenMermaidMachine
