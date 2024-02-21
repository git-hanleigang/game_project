---
-- island li
-- 2019年1月26日
-- CodeGameScreenCandyBingoMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local SlotsSpineAnimNode = require "Levels.SlotsSpineAnimNode"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CodeGameScreenCandyBingoMachine = class("CodeGameScreenCandyBingoMachine", BaseSlotoManiaMachine)

CodeGameScreenCandyBingoMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画
CodeGameScreenCandyBingoMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1 -- 自定义的小块类型
CodeGameScreenCandyBingoMachine.Socre_CandyBingo_Chip = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1

CodeGameScreenCandyBingoMachine.Socre_CandyBingo_Tip_Node = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
CodeGameScreenCandyBingoMachine.Socre_CandyBingo_Special_Scatter = -1

CodeGameScreenCandyBingoMachine.Socre_CandyBingo_Grand = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 101
CodeGameScreenCandyBingoMachine.Socre_CandyBingo_Major = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 102
CodeGameScreenCandyBingoMachine.Socre_CandyBingo_Minor = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 103
CodeGameScreenCandyBingoMachine.Socre_CandyBingo_Mini = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 104

-- CodeGameScreenCandyBingoMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenCandyBingoMachine.Update_Top_Reels_Node = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenCandyBingoMachine.Show_Bonus_View = GameEffect.EFFECT_SELF_EFFECT - 2 -- 自定义动画的标识
CodeGameScreenCandyBingoMachine.Show_Bonus_over_View = GameEffect.EFFECT_SELF_EFFECT - 3 -- 自定义动画的标识

CodeGameScreenCandyBingoMachine.m_betLevel = nil -- betlevel 0 1 2
CodeGameScreenCandyBingoMachine.m_betData = {} -- 存储每一档bet轮盘信息

--topreels轮盘数据
CodeGameScreenCandyBingoMachine.m_bonusReelsData = {} -- 轮盘数据
CodeGameScreenCandyBingoMachine.m_bonusReelsBingoLinesData = {} --如果中了bingo以后,bingo轮盘 中了的所有的线
CodeGameScreenCandyBingoMachine.m_bonusReelsBonusCoinsData = {} --下方大轮盘特殊图标需要显示的分数
CodeGameScreenCandyBingoMachine.m_bonusReelsBingoPositionsData = {} --上方提示可能会中bingo数组

CodeGameScreenCandyBingoMachine.m_bonusReelsNodeList = {}
CodeGameScreenCandyBingoMachine.m_ActionNodeList = {}

CodeGameScreenCandyBingoMachine.m_BonusCollectSumScore = 0
CodeGameScreenCandyBingoMachine.m_labBet = 10 -- 多少倍以上的字体改变

CodeGameScreenCandyBingoMachine.m_outOnlin = nil -- 判断是否是断线重连

CodeGameScreenCandyBingoMachine.m_scatterDownIndex = 1
CodeGameScreenCandyBingoMachine.m_moveIndex = 1

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136

local smallReelsZOrder = {top = 100, mid = 50, down = 1}

-- 构造函数
function CodeGameScreenCandyBingoMachine:ctor()
    BaseSlotoManiaMachine.ctor(self)
    self.m_isFeatureOverBigWinInFree = true

    self.m_moveIndex = 1

    self.m_betLevel = nil

    -- 初始化一份基础轮盘 （0：不显示 大于0：显示对应的分数 -1：是固定的scatter信号）
    self.m_bonusReelsData = {{0, 0, 0, 0, 0}, {0, 0, 0, 0, 0}, {0, 0, -1, 0, 0}, {0, 0, 0, 0, 0}, {0, 0, 0, 0, 0}}

    self.m_bonusReelsBingoLinesData = {} --如果中了bingo以后,bingo轮盘 中了的所有的线
    self.m_bonusReelsBonusCoinsData = {} --下方大轮盘特殊图标需要显示的分数
    self.m_betData = {} -- 存储每一档bet轮盘信息
    self.m_bonusReelsBingoPositionsData = {} --上方提示可能会中bingo数组
    self.m_bonusReelsNodeList = {}
    self.m_BonusCollectSumScore = 0
    self.m_ActionNodeList = {}
    self.m_labBet = 10 -- 多少倍以上的字体改变
    self.m_scatterDownIndex = 1

    --init
    self:initGame()
end

function CodeGameScreenCandyBingoMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("CandyBingoConfig.csv", "LevelCandyBingoConfig.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end
function CodeGameScreenCandyBingoMachine:isTriggerFreespinOrInFreespin()
    local isIn = false

    local features = self.m_runSpinResultData.p_features

    if features then
        for k, v in pairs(features) do
            if v == 1 then
                isIn = true
            end
        end
    end

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        isIn = true
    end

    return isIn
end

function CodeGameScreenCandyBingoMachine:changeViewNodePos()
    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local m_panda = self:findChild("m_panda")
        m_panda:setPositionY(m_panda:getPositionY() - posY)
        local Node_lunpan_2 = self:findChild("Node_lunpan_2")
        Node_lunpan_2:setPositionY(Node_lunpan_2:getPositionY() - posY)
        -- local Node_lunpan_1 = self:findChild("Node_lunpan_1")
        -- Node_lunpan_1:setPositionY(Node_lunpan_1:getPositionY() - posY)
        local freespinbar = self:findChild("freespinbar")
        freespinbar:setPositionY(freespinbar:getPositionY() - posY)
        local bonusWinView = self:findChild("bonusWinView")
        bonusWinView:setPositionY(bonusWinView:getPositionY() - posY)
        local wheel = self:findChild("wheel")
        wheel:setPositionY(wheel:getPositionY() - posY)

        local bonusWheel = self:findChild("bonusWheel")
        bonusWheel:setPositionY(bonusWheel:getPositionY() - posY)

        local nodeJackpot_0 = self:findChild("JACKPOT_1")

        nodeJackpot_0:setPositionY(nodeJackpot_0:getPositionY() - posY)
    elseif display.height < FIT_HEIGHT_MIN then
        local nodeJackpot_0 = self:findChild("JACKPOT_1")
        nodeJackpot_0:setPositionY(nodeJackpot_0:getPositionY() - 5)
    end
end

function CodeGameScreenCandyBingoMachine:scaleMainLayer()
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
        if display.height >= FIT_HEIGHT_MAX then
            mainScale = (FIT_HEIGHT_MAX + 90 - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            -- mainScale = mainScale + 0.05
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            if (display.height / display.width) >= 2 then
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 37)
            else
                self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 20)
            end
        elseif display.height < DESIGN_SIZE.height and display.height >= FIT_HEIGHT_MIN then
            mainScale = (display.height + 10 - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 3)
        else
            mainScale = (display.height + 25 - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 15)
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end

    local bangDownHeight = util_getSaveAreaBottomHeight()
    self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bangDownHeight)
end

function CodeGameScreenCandyBingoMachine:getNetWorkModuleName()
    return "CandyBingoV2"
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenCandyBingoMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "CandyBingo"
end

function CodeGameScreenCandyBingoMachine:getBetLevel()
    return self.m_betLevel
end

function CodeGameScreenCandyBingoMachine:initUI()
    -- self:createWheelView( )

    -- 创建view节点方式
    -- self.m_CandyBingoView = util_createView("CodeCandyBingoSrc.CandyBingoView")
    -- self:findChild("xxxx"):addChild(self.m_CandyBingoView)

    self:findChild("Node_lunpan_1"):setLocalZOrder(1)

    self:runCsbAction("Grand", true)

    self.m_gameBg:runCsbAction("normal", true)

    self:initFreeSpinBar() -- FreeSpinbar
    self.m_CandyBingoFreespinBar = util_createView("CodeCandyBingoSrc.CandyBingoFreespinBar")
    self:findChild("freespinbar"):addChild(self.m_CandyBingoFreespinBar)
    self.m_baseFreeSpinBar = self.m_CandyBingoFreespinBar
    self.m_baseFreeSpinBar:setVisible(false)

    self:findChild("Node_lunpan_1_0"):setVisible(false)

    self.m_CandyBingoReelsMoveBg = util_createView("CodeCandyBingoSrc.CandyBingoReelsMoveBg")
    self:findChild("animationTopBg"):addChild(self.m_CandyBingoReelsMoveBg)
    self:findChild("animationTopBg"):setLocalZOrder(smallReelsZOrder.top)
    self.m_CandyBingoReelsMoveBg:setVisible(false)

    -- self:createWheelView( )

    self.m_CandyBingoBonusWinView = util_createView("CodeCandyBingoSrc.CandyBingoBonusWinView")
    self:findChild("bonusWinView"):addChild(self.m_CandyBingoBonusWinView)
    self.m_CandyBingoBonusWinView:setVisible(false)

    self:findChild("LEFT"):setVisible(false) --grand

    self.m_CandyBingoRIGHTJackPotView = util_createView("CodeCandyBingoSrc.CandyBingoChangeTopJackPOtView")
    self:findChild("RIGHT"):addChild(self.m_CandyBingoRIGHTJackPotView)
    self.m_CandyBingoRIGHTJackPotView:setVisible(false)

    self.m_BigJackPotView = util_createView("CodeCandyBingoSrc.CandyBingoBigJackPotBar")
    self:findChild("RIGHT"):addChild(self.m_BigJackPotView)
    self.m_BigJackPotView:setVisible(false)
    self.m_BigJackPotView:initMachine(self)
    if display.height >= 1470 and display.height < 1500 then
        self.m_BigJackPotView:findChild("Node_scale"):setScale(1.3)
    else
        self.m_BigJackPotView:findChild("Node_scale"):setScale(1.4)
    end

    self.m_CandyBingoJackPotLockView = util_createView("CodeCandyBingoSrc.CandyBingoJackPotLockView")
    self:findChild("Node_Grand"):addChild(self.m_CandyBingoJackPotLockView)
    self.m_CandyBingoJackPotLockView:setVisible(false)

    if display.height >= 1470 then
        self.m_BigJackPotView:setVisible(true)
        self.m_BigJackPotView:setPositionY((display.height - 1470) / 3)
    else
        self.m_CandyBingoRIGHTJackPotView:setVisible(true)
        self:findChild("LEFT"):setVisible(true)
    end

    self.m_CandyBingoGuoChangView = util_createView("CodeCandyBingoSrc.CandyBingoGuoChangView")
    self:addChild(self.m_CandyBingoGuoChangView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_CandyBingoGuoChangView:setPosition(0, 0)
    self.m_CandyBingoGuoChangView:setVisible(false)

    -- self.m_CandyBingoJackPotUnLockView = util_createView("CodeCandyBingoSrc.CandyBingoJackPotUnLockView")
    -- self:findChild("LEFT"):addChild(self.m_CandyBingoJackPotUnLockView)
    -- self.m_CandyBingoJackPotUnLockView:setVisible(false)

    self.bonusStartView = util_createView("CodeCandyBingoSrc.CandyBingoBonusStartView")
    self:findChild("bonusWheel"):addChild(self.bonusStartView)
    self.bonusStartView:setVisible(false)

    self.m_panda_left = util_spineCreateDifferentPath("GameScreenCandyBingo_panda", "GameScreenCandyBingo_panda", true, true)
    self.m_csbOwner["Node_left"]:addChild(self.m_panda_left)
    util_spinePlay(self.m_panda_left, "huxi_left", true)

    self.m_panda_right = util_spineCreateDifferentPath("GameScreenCandyBingo_panda", "GameScreenCandyBingo_panda", true, true)
    self.m_csbOwner["Node_right"]:addChild(self.m_panda_right)
    util_spinePlay(self.m_panda_right, "huxi_right", true)

    self:findChild("zhezhaoSmallReels"):setVisible(false)
    self:findChild("zhezhaoBigReels"):setVisible(false)
    self:findChild("zhezhaoSmallReels"):setLocalZOrder(smallReelsZOrder.mid)
    self:findChild("zhezhaoBigReels"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self:findChild("animationTopBg11"):setLocalZOrder(smallReelsZOrder.mid + 100)
    self:findChild("respin_strip_node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)

    --高低bet选择
    self.m_hightLowbetView = util_createView("CodeCandyBingoSrc.CandyBingoHightLowbetView")
    self:addChild(self.m_hightLowbetView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    -- self.m_hightLowbetView:setPosition(cc.p(display.width/2,display.height/2))
    self.m_hightLowbetView:setVisible(false)

    self.m_LittleBetView = util_createView("CodeCandyBingoSrc.CandyBingoLittleBetView")
    self.m_bottomUI:addChild(self.m_LittleBetView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_LittleBetView:setPosition(-253, 287)
    self.m_LittleBetView:setVisible(false)

    gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
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
            elseif winRate > 3 and winRate <= 6 then
                soundIndex = 3
            elseif winRate > 6 then
                soundIndex = 4
            end

            local soundName = "CandyBingoSounds/music_CandyBingo_win_" .. soundIndex .. ".mp3"
            globalMachineController:playBgmAndResume(soundName, 2, 0.6, 1)
        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenCandyBingoMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.isInBonus then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    end
                end,
                2.5,
                self:getModuleName()
            )
        end,
        0.4,
        self:getModuleName()
    )
end

function CodeGameScreenCandyBingoMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

    self:updateJackpotInfo()

    local second = 0
    local changeindex = 0

    schedule(
        self:findChild("JACKPOT_1"),
        function()
            self:updateJackpotInfo()

            second = second + 0.08

            if second >= 5 then
                second = 0

                changeindex = changeindex + 1
                if changeindex > 3 or changeindex < 1 then
                    changeindex = 1
                end

                local changeName = "animation" .. changeindex
                local idleName = "change" .. changeindex

                self.m_CandyBingoRIGHTJackPotView:runCsbAction(
                    changeName,
                    false,
                    function()
                        self.m_CandyBingoRIGHTJackPotView:runCsbAction(idleName, true)
                    end
                )
            end
        end,
        0.08
    )

    self:upateBetLevel()

    if self:checkShowChooseBetView() then
        self:showHightLowBetView()
    end
end

function CodeGameScreenCandyBingoMachine:addObservers()
    BaseSlotoManiaMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:upateBetLevel()

            self:changeBetStopCollectAnim()

            self:resetTopReelsData()
            -- 更新本地topreelsdata
            self:updateTopSmallReelsData()
            -- 更新本地 topreelsNode
            self:updateTopSmallReelsNode()
            -- 更新本地 topreelsTipNode --将要中奖
            self:updateTopSmallReelsTipNode()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CodeGameScreenCandyBingoMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseSlotoManiaMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    self:removeAllActionNode()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenCandyBingoMachine:MachineRule_GetSelfCCBName(symbolType)
    local a = self:getBetLevel()
    if symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_CandyBingo_10"
    elseif symbolType == self.Socre_CandyBingo_Chip then
        return "Socre_CandyBingo_Chip"
    elseif symbolType == self.Socre_CandyBingo_Tip_Node then
        return "CandyBingo_Tbshanshuo"
    elseif symbolType == self.Socre_CandyBingo_Special_Scatter then
        return "CandyBingo_SPECIAL_1"
    elseif symbolType == self.Socre_CandyBingo_Grand then
        return "Socre_CandyBingo_Chip_Grand"
    elseif symbolType == self.Socre_CandyBingo_Major then
        return "Socre_CandyBingo_Chip_Major"
    elseif symbolType == self.Socre_CandyBingo_Minor then
        return "Socre_CandyBingo_Chip_Minor"
    elseif symbolType == self.Socre_CandyBingo_Mini then
        return "Socre_CandyBingo_Chip_Mini"
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        if self:getBetLevel() == 2 then
            return "Socre_CandyBingo_hg"
        elseif self:getBetLevel() == 1 then
            return "Socre_CandyBingo_Scatter"
        else
            return "Socre_CandyBingo_Scatter_lw"
        end
    end

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenCandyBingoMachine:getPreLoadSlotNodes()
    -- local loadNode = BaseSlotoManiaMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 51},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 51},
        {symbolType = self.SYMBOL_SCORE_10, count = 51},
        {symbolType = self.Socre_CandyBingo_Chip, count = 51},
        {symbolType = self.Socre_CandyBingo_Tip_Node, count = 51},
        {symbolType = self.Socre_CandyBingo_Special_Scatter, count = 2},
        {symbolType = self.Socre_CandyBingo_Grand, count = 2},
        {symbolType = self.Socre_CandyBingo_Major, count = 2},
        {symbolType = self.Socre_CandyBingo_Minor, count = 2},
        {symbolType = self.Socre_CandyBingo_Mini, count = 2}
    }

    return loadNodes
end

function CodeGameScreenCandyBingoMachine:getBonusSymbolScore(synbolIndex)
    local storedIcons = self.m_bonusReelsBonusCoinsData -- 存放的是Bonusn小块的网络数据
    local score = nil
    for k, v in pairs(storedIcons) do
        local index = tonumber(v.pos)
        if index == synbolIndex then
            score = tonumber(v.coins)
            break
        end
    end

    return score
end

-- 给特殊Bonus小块进行赋值
function CodeGameScreenCandyBingoMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    --根据网络数据获取停止滚动时Bonusn小块的分数

    local symbolIndex = nil
    local score = nil
    if iCol and iRow then
        symbolIndex = self:getPosReelIdx(iRow, iCol)
        score = self:getBonusSymbolScore(symbolIndex) --获取分数（网络数据）
    end

    if score == nil then
        score = math.random(5, 10)
        local lineBet = globalData.slotRunData:getCurTotalBet()
        score = score * lineBet
    end

    local nodeCut = score
    score = util_formatCoins(score, 3)

    local scoreNode = symbolNode:getCcbProperty("m_lb_score")

    if scoreNode then
        scoreNode.score = nodeCut
        scoreNode:setString(score)
    end

    local lab10 = symbolNode:getCcbProperty("m_lb_score_10")
    if lab10 then
        lab10.score = nodeCut
        lab10:setString(score)
    end

    if symbolNode then
        symbolNode:runAnim("idleframe")
    end
end

-- 给Scatter小块进行修改
function CodeGameScreenCandyBingoMachine:setScatterNode(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex
    if symbolNode.p_symbolType and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        symbolNode:changeCCBByName(symbolNode.m_ccbName, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
    end
end

function CodeGameScreenCandyBingoMachine:getSlotNodeWithPosAndType(symbolType, row, col, isLastSymbol)
    local reelNode = BaseSlotoManiaMachine.getSlotNodeWithPosAndType(self, symbolType, row, col, isLastSymbol)

    -- --下帧调用 才可能取到 x y值
    -- -- 给 特殊Bonus小块进行赋值
    if symbolType == self.Socre_CandyBingo_Chip then
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {reelNode})
        self:runAction(callFun)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        local callFun = cc.CallFunc:create(handler(self, self.setScatterNode), {reelNode})
        self:runAction(callFun)
    end

    return reelNode
end

----------------------------- 玩法处理 -----------------------------------

-- 初始化上次游戏状态数据
--
function CodeGameScreenCandyBingoMachine:initGameStatusData(gameData)
    if not globalData.userRate then
        local UserRate = require "data.UserRate"
        globalData.userRate = UserRate:create()
    end
    globalData.userRate:enterLevel(self:getModuleName())
    if gameData.gameConfig ~= nil and gameData.gameConfig.isAllLine ~= nil then
        self.m_isAllLineType = gameData.gameConfig.isAllLine
    end

    -- spin
    -- feature
    -- sequenceId
    local operaId = gameData.sequenceId

    self.m_initBetId = (gameData.betId or -1)

    local spin = gameData.spin
    -- spin = nil
    local freeGameCost = gameData.freeGameCost
    local feature = gameData.feature
    local collect = gameData.collect
    local jackpot = gameData.jackpot
    local totalWinCoins = nil
    if gameData.spin then
        totalWinCoins = gameData.spin.freespin.fsWinCoins
    end
    if totalWinCoins == nil then
        totalWinCoins = 0
    end

    self.m_freeSpinStartCoins = globalData.userRunData.coinNum ---gameData.totalWinCoins
    self.m_freeSpinOffSetCoins = 0
    --gameData.totalWinCoins
    self:setLastWinCoin(totalWinCoins)

    if spin ~= nil then
        self.m_runSpinResultData:setAllLine(self.m_isAllLineType)
        self.m_runSpinResultData:parseResultData(spin, self.m_lineDataPool, self.m_symbolCompares, feature)
        self.m_initSpinData = self.m_runSpinResultData
    end
    if feature ~= nil then
        self.m_initFeatureData = SpinFeatureData.new()
        if feature.bonus then
            if feature.bonus then
                if feature.bonus.status == "CLOSED" then
                    local bet = feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1]
                    feature.bonus.content[feature.bonus.choose[#feature.bonus.choose] + 1] = -bet
                end
                feature.choose = feature.bonus.choose
                feature.content = feature.bonus.content
                feature.extra = feature.bonus.extra
                feature.status = feature.bonus.status
            end
        end
        self.m_initFeatureData:parseFeatureData(feature)
    -- self.m_initFeatureData:setAllLine(self.m_isAllLineType)
    end

    if freeGameCost then
        --免费送spin活动数据
        self.m_rewaedFSData = freeGameCost
    end

    if collect and type(collect) == "table" and #collect > 0 then
        for i = 1, #collect do
            self.m_collectDataList[i]:parseCollectData(collect[i])
        end
    end
    if jackpot and type(jackpot) == "table" and #jackpot > 0 then
        self.m_jackpotList = jackpot
    end
    if not self.m_jackpotList then
        self:updateJackpotList()
    end

    if gameData.gameConfig ~= nil and gameData.gameConfig.bonusReels ~= nil then
        self.m_runSpinResultData["p_bonusReels"] = gameData.gameConfig.bonusReels
    end

    if gameData.gameConfig ~= nil then
        self.m_runSpinResultData["p_CandyBingoGameConfig"] = gameData.gameConfig
    end

    self:initMachineGame()
end

function CodeGameScreenCandyBingoMachine:dealTriggerBonusSmallReelsData()
    local reelsData = self.m_runSpinResultData.p_selfMakeData
    if reelsData then
        local bingoData = reelsData.bingo
        if bingoData then
            if bingoData.bingoLines then
                self.m_bonusReelsBingoLinesData = bingoData.bingoLines
            end

            if bingoData.bonusReels then
                self.m_bonusReelsData = bingoData.bonusReels
            end

            if bingoData.bingoPositions then -- 可能会中bingo 的位置数组
                self.m_bonusReelsBingoPositionsData = bingoData.bingoPositions
            end
        end

        if reelsData.bonusCoins then --下方大轮盘特殊图标需要显示的分数
            self.m_bonusReelsBonusCoinsData = reelsData.bonusCoins
        end
    end
end

function CodeGameScreenCandyBingoMachine:isTriggerBonus()
    local selfMakeData = self.m_runSpinResultData.p_selfMakeData

    local isBonus = false
    if selfMakeData.bingo then
        local bingiodata = selfMakeData.bingo
        if bingiodata then
            local bingoLines = bingiodata.bingoLines
            if bingoLines and #bingoLines > 0 then
                isBonus = true
            end
        end
    end

    return isBonus
end

-- 断线重连
function CodeGameScreenCandyBingoMachine:MachineRule_initGame()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        util_spinePlay(self.m_panda_left, "huxi_left", true)
        util_spinePlay(self.m_panda_right, "huxi_right", true)
    end
end

function CodeGameScreenCandyBingoMachine:enterLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect, isPlayGameEffect = self:checkInitSpinWithEnterLevel()

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
        self:initNoneFeature()
    else
        self:initHasFeature()
    end

    self:initTopSmallReelsData()
    -- 初始化上部轮盘
    self:initTopReelsNode()
    -- 更新上部提示
    self:updateTopSmallReelsTipNode()
    -- 初始化下部轮盘
    self:createSmallReels()

    --wild刷光
    self:wildFlash()

    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function CodeGameScreenCandyBingoMachine:initHasFeature()
    self:checkUpateDefaultBet()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

    self:upateBetLevel()
    self:initCloumnSlotNodesByNetData()
end

function CodeGameScreenCandyBingoMachine:initNoneFeature()
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
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    self:upateBetLevel()
    self:initRandomSlotNodes()
end

function CodeGameScreenCandyBingoMachine:wildFlash()
    local smallWild = self:getFixSymbolSmallReels(3, 3)
    if smallWild then
        local lastNode = smallWild.m_lastNode
        if lastNode then
            lastNode:runAnim("idle", true)
        end
    end
    local bigWild = self:getFixSymbol(3, 3, SYMBOL_NODE_TAG)
    if bigWild then
        bigWild:runAnim("idle", true)
    end
end

function CodeGameScreenCandyBingoMachine:getFixSymbolSmallReels(iRow, iCol)
    local node = nil
    if self.m_SmallReelsView then
        for i = 1, #self.m_SmallReelsView.m_respinNodes do
            local respinNode = self.m_SmallReelsView.m_respinNodes[i]
            if respinNode.p_colIndex == iCol then
                if respinNode.p_rowIndex == iRow then
                    return respinNode
                end
            end
        end
    end

    return node
end

--
--单列滚动停止回调
--
function CodeGameScreenCandyBingoMachine:slotLocalOneReelDown(icol)
    -- BaseSlotoManiaMachine.slotOneReelDown(self,reelCol)

    local notPlayChip = true

    -- 播放落地动画
    for irow = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[irow][icol]

        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            -- else
            --     -- self:createOneActionSymbol(node,"idleframe",self:getFixSymbolSmallReels(irow,icol ),true)
            -- end
            local index = 1
            if self.m_scatterDownIndex == 1 then
                index = 1
            elseif self.m_scatterDownIndex == 2 then
                index = 2
            elseif self.m_scatterDownIndex == 3 then
                index = 3
            elseif self.m_scatterDownIndex == 4 then
                index = 3
            elseif self.m_scatterDownIndex == 5 then
                index = 3
            end

            local soundPath = "CandyBingoSounds/sound_CandyBingo_scatter_down_" .. index .. ".mp3"

            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds(icol, soundPath, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
            else
                -- respinbonus落地音效
                gLobalSoundManager:playSound(soundPath)
            end

            self.m_scatterDownIndex = self.m_scatterDownIndex + 1
            -- 播放scatter动画
            local node = self:getReelParent(icol):getChildByTag(self:getNodeTag(icol, irow, SYMBOL_NODE_TAG))
            -- if self:isPlayTipAnima(icol, irow, node) then
            self:createOneActionSymbol(node, "buling", self:getFixSymbolSmallReels(irow, icol), true, nil, nil, "idleframe")
        elseif symbolType == self.Socre_CandyBingo_Chip then
            local node = self:getReelParent(icol):getChildByTag(self:getNodeTag(icol, irow, SYMBOL_NODE_TAG))
            local symbolIndex = self:getPosReelIdx(irow, icol)
            local score = self:getBonusSymbolScore(symbolIndex) --获取分数（网络数据）
            self:createOneChipActionSymbol(node, "buling", self:getFixSymbolSmallReels(irow, icol), false, nil, true, nil, score)
            if notPlayChip then
                notPlayChip = false

                local soundPath = "CandyBingoSounds/sound_CandyBingo_Bonus_down.mp3"

                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds(icol, soundPath)
                else
                    -- respinbonus落地音效
                    gLobalSoundManager:playSound(soundPath)
                end
            end
        end
    end

    -- 一列只播一次
    if self.playReelDownSound then
        self:playReelDownSound(icol, "CandyBingoSounds/music_CandyBingo_reels_stop.mp3")
    else
        gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_reels_stop.mp3")
    end

    if self.playQuickStopBulingSymbolSound then
        self:playQuickStopBulingSymbolSound(icol)
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenCandyBingoMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    self.m_gameBg:runCsbAction(
        "normal_change_freespin",
        false,
        function()
            self.m_gameBg:runCsbAction("freespin", true)
        end
    )
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenCandyBingoMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画

    self.m_gameBg:runCsbAction(
        "freespin_change_normal",
        false,
        function()
            self.m_gameBg:runCsbAction("normal", true)
        end
    )
end
---------------------------------------------------------------------------

-- bonus相关

---
-- 显示bonus 触发的小游戏
-- 不用bonus这种状态了，因为断线后服务器已经把钱加上了，在走一次体验不太好
function CodeGameScreenCandyBingoMachine:showEffect_Bonus(effectData)
    effectData.p_isPlay = true
    self:playGameEffect() -- 播放下一轮

    return true
end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenCandyBingoMachine:showBonusGameAction(effectData)
    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    --显示单独滚轮盘信息，并且隐藏整个滚轮盘
    self:showSingleReelSlotsNodeVisible(false)

    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 先隐藏掉所有提示Node
    self:hideAllTopSmallReelsTipNode()

    self:findChild("zhezhaoSmallReels"):setVisible(true)
    self:findChild("zhezhaoBigReels"):setVisible(true)

    util_spinePlay(self.m_panda_right, "lianxian_right", false)
    util_spinePlay(self.m_panda_left, "lianxian_left", false)

    gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_show_spe_scatter.mp3")

    -- bonus触发动画
    self:showBonusTriggerAction(
        function()
            performWithDelay(
                self,
                function()
                    self:showBonusGameActionView(effectData)
                end,
                1
            )
        end
    )

    -- 播放提示时播放音效
    self:playBonusTipMusicEffect()

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)
end

function CodeGameScreenCandyBingoMachine:showBonusTriggerAction(func)
    local bonusLines = self.m_bonusReelsBingoLinesData or {} -- bonus连线信息
    if #bonusLines == 0 then
        if func then
            func()
        end

        return
    end

    local time = 1

    for k, v in pairs(bonusLines) do
        local oneBingoLine = v
        for kk, vk in pairs(oneBingoLine) do
            local index = tonumber(vk)

            local smallReelsNode = self:getSmallReelsNodeFromIndex(index)
            if smallReelsNode then
                self:showBonusReelsNodeZOrder(index)
                smallReelsNode:runAnim("actionframe")
            end
        end
    end

    performWithDelay(
        self,
        function()
            if func then
                func()
            end
        end,
        time
    )
end

function CodeGameScreenCandyBingoMachine:getbonusLinesSumNum()
    local bonusLines = self.m_bonusReelsBingoLinesData -- bonus连线信息
    local courtNum = 0
    for k, v in pairs(bonusLines) do
        local oneBingoLine = v
        for kk, vk in pairs(v) do
            courtNum = courtNum + 1
        end
    end
    return courtNum
end

function CodeGameScreenCandyBingoMachine:bonusCollectAnimation(func)
    local bonusLines = self.m_bonusReelsBingoLinesData or {} -- bonus连线信息
    local scatterScore = self.m_runSpinResultData.p_selfMakeData.middleCoins or 0
    local dealyTime = 0.7
    local sumTime = self:getbonusLinesSumNum() * dealyTime + dealyTime
    local sumScore = 0
    local courtTimes = 0
    for k, v in pairs(bonusLines) do
        local oneBingoLine = v
        for kk, vk in pairs(oneBingoLine) do
            local index = tonumber(vk)
            local Score = 0
            local smallReelsNode = self:getSmallReelsNodeFromIndex(index)
            if smallReelsNode then
                Score = self.m_bonusReelsData[6 - smallReelsNode.iRow][smallReelsNode.iCol]
                -- scatter 在bingo线上时特殊处理
                if Score == -1 then
                    Score = scatterScore
                end

                sumScore = sumScore + Score

                local nowScore = sumScore

                performWithDelay(
                    self,
                    function()
                        gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_BonusReels_Collect_fly.mp3")

                        local func = function()
                            -- 更新 顶部钱数
                            print("---------- " .. nowScore)
                            local node = self.m_CandyBingoBonusWinView:findChild("m_lb_score")
                            if node then
                                node.score = nowScore
                                node:setString(util_formatCoins(nowScore, 50))

                                gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_Bonus_addCoins.mp3")

                                self.m_CandyBingoBonusWinView:runCsbAction("jiesuan")
                                self.m_CandyBingoBonusWinView:updateLabelSize({label = node, sx = 0.625, sy = 0.625}, 774)
                            end
                        end

                        smallReelsNode:runAnim("jiesuan")

                        -- Node_lunpan_2 存放Bigreels 的节点
                        local startPosWord = self:findChild("Node_1_0"):convertToWorldSpace(cc.p(smallReelsNode:getPosition()))
                        local startPos = cc.p(self.m_root:convertToNodeSpace(startPosWord))
                        -- Node_1_0 存放topreels 的节点
                        local endPos = cc.p(self:findChild("bonusWinView"):getPosition())
                        local time = dealyTime
                        local posCol = smallReelsNode.iCol
                        local posRow = smallReelsNode.iRow
                        self:createCandyBingoFly(startPos, endPos, dealyTime, posCol, posRow, func)
                    end,
                    courtTimes * dealyTime
                )

                courtTimes = courtTimes + 1
            end
        end
    end

    -- self.m_BonusCollectSumScore = sumScore

    performWithDelay(
        self,
        function()
            if func then
                func()
            end
        end,
        sumTime
    )
end

function CodeGameScreenCandyBingoMachine:showBonusGameOverActionView(effectData)
    -- gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_Bonus_TotalWin_view.mp3")

    self.m_CandyBingoBonusWinView:runCsbAction(
        "over",
        false,
        function()
            self.m_CandyBingoBonusWinView:setVisible(false)

            self:setReelSlotsNodeVisible(true)
            self:dealActionNodeVisible(true)

            self:moveTopNodeToTopReels(
                function()
                    local topReelsScatter = self:getSmallReelsNodeFromIndex(12)
                    topReelsScatter:changeCCBByName("CandyBingo_SPECIAL_1", self.Socre_CandyBingo_Special_Scatter)

                    topReelsScatter:runAnim("idle", true)

                    local betValue = self:BaseMania_getLineBet() * self.m_lineCount
                    self:resetTopReelsData(betValue)
                    -- 更新本地topreelsdata
                    self:updateTopSmallReelsData()
                    -- 更新本地 topreelsNode
                    self:updateTopSmallReelsNode()
                    -- 更新本地 topreelsTipNode --将要中奖
                    self:updateTopSmallReelsTipNode()

                    self:hideBonusReelsNodeZOrder()
                    self:findChild("zhezhaoSmallReels"):setVisible(false)
                    self:findChild("zhezhaoBigReels"):setVisible(false)

                    --if self.m_bIsBigWin then
                    self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin - self.m_BonusCollectSumScore
                    --end

                    util_spinePlay(self.m_panda_left, "huxi_left", true)
                    util_spinePlay(self.m_panda_right, "huxi_right", true)

                    self:resetMusicBg()

                    effectData.p_isPlay = true
                    self:playGameEffect() -- 播放下一轮
                end
            )
        end
    )
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenCandyBingoMachine:showBonusGameActionView(effectData)
    self.m_CandyBingoBonusWinView:findChild("m_lb_score"):setString("")

    -- 普通收集
    local normalCollect = function()
        gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_show_wheel_BonusWin_view.mp3")

        self.m_CandyBingoBonusWinView:setVisible(true)
        self.m_CandyBingoBonusWinView:runCsbAction(
            "start",
            false,
            function()
                self:bonusCollectAnimation(
                    function()
                        self:checkFeatureOverTriggerBigWin(self.m_BonusCollectSumScore, GameEffect.EFFECT_SELF_EFFECT, self.Show_Bonus_View)

                        if self.m_bProduceSlots_InFreeSpin then
                            local linesCoins = self.m_serverWinCoins - self.m_BonusCollectSumScore
                            local fsAddCoins = self:getLastWinCoin()

                            local lastWinCoin = globalData.slotRunData.lastWinCoin
                            if linesCoins > 0 then
                                globalData.slotRunData.lastWinCoin = 0
                                fsAddCoins = fsAddCoins - linesCoins
                            else
                                fsAddCoins = self:getLastWinCoin()
                            end

                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {fsAddCoins, false, false})
                            globalData.slotRunData.lastWinCoin = lastWinCoin
                        else
                            local coins = self.m_BonusCollectSumScore
                            local lastWinCoin = globalData.slotRunData.lastWinCoin
                            globalData.slotRunData.lastWinCoin = 0
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
                            globalData.slotRunData.lastWinCoin = lastWinCoin

                            local topcoins = globalData.userRunData.coinNum - (globalData.slotRunData.lastWinCoin - coins)
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, topcoins)
                        end

                        effectData.p_isPlay = true
                        self:playGameEffect() -- 播放下一轮
                    end
                )
            end
        )
    end

    -- 开始bonus 动画逻辑
    local showGameAction = function()
        local wheelData = self.m_runSpinResultData.p_selfMakeData.wheels
        local endIndex = self.m_runSpinResultData.p_selfMakeData.index

        if wheelData then
            local topReelsScatter_1 = self:getSmallReelsNodeFromIndex(12)

            if topReelsScatter_1 then
                gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_show_spe_scatter.mp3")

                topReelsScatter_1:runAnim(
                    "actionframe",
                    false,
                    function()
                        -- performWithDelay(self,function(  )
                        self:createWheelView(
                            function()
                                -- 普通收集
                                normalCollect()
                            end,
                            function()
                                local middleCoins = self.m_runSpinResultData.p_selfMakeData.middleCoins or 0

                                local endtype = self:getSpecialScatterSymbolType() or self.Socre_CandyBingo_Chip
                                local topReelsScatter = self:getSmallReelsNodeFromIndex(12)
                                topReelsScatter:changeCCBByName(self:MachineRule_GetSelfCCBName(endtype), endtype)
                                local lab = topReelsScatter:getCcbProperty("m_lb_score")

                                if lab then
                                    topReelsScatter.score = middleCoins
                                    lab:setString(util_formatCoins(middleCoins, 3))
                                end

                                local lab10 = topReelsScatter:getCcbProperty("m_lb_score_10")

                                if lab10 then
                                    topReelsScatter.score = middleCoins
                                    lab10:setString(util_formatCoins(middleCoins, 3))
                                end
                            end
                        )

                        -- end,0.1)
                    end
                )
            end
        else
            -- 普通收集
            normalCollect()
        end
    end

    -- 显示bonusstart
    self:findChild("zhezhaoSmallReels"):setVisible(true)
    self:findChild("zhezhaoBigReels"):setVisible(true)

    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_trigger_Bonus_view.mp3")
            self:showLocalMadeView(
                "BingoStart",
                function()
                    gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_Bonus_Topreels_trigger.mp3")

                    self.m_CandyBingoReelsMoveBg:setVisible(true)
                    self.m_CandyBingoReelsMoveBg:runCsbAction(
                        "start",
                        false,
                        function()
                            -- self.m_CandyBingoReelsMoveBg:runCsbAction("idle",true)

                            self:moveTopNodeToBigReels(
                                function()
                                    performWithDelay(
                                        self,
                                        function()
                                            showGameAction()
                                        end,
                                        0.5
                                    )
                                end
                            )
                        end,
                        20
                    )
                end,
                true
            )
        end,
        0.1
    )
end

function CodeGameScreenCandyBingoMachine:getSpecialScatterSymbolType()
    local endstr = nil
    local endType = self.Socre_CandyBingo_Chip

    if self.m_runSpinResultData.p_selfMakeData then
        local wheelData = self.m_runSpinResultData.p_selfMakeData.wheels
        local endIndex = self.m_runSpinResultData.p_selfMakeData.index

        if wheelData then
            for k, v in pairs(wheelData) do
                local index = endIndex + 1
                if k == index then
                    endstr = v
                    break
                end
            end
        end

        if endstr then
            if endstr == "Mini" then
                endType = self.Socre_CandyBingo_Mini
            elseif endstr == "Minor" then
                endType = self.Socre_CandyBingo_Minor
            elseif endstr == "Major" then
                endType = self.Socre_CandyBingo_Major
            elseif endstr == "Grand" then
                endType = self.Socre_CandyBingo_Grand
            else
                endType = self.Socre_CandyBingo_Chip
            end
        end
    end

    return endType
end

function CodeGameScreenCandyBingoMachine:showLocalMadeView(name, func, isAuto)
    print("self.bonusStartViewstart")

    self.bonusStartView:setVisible(true)
    self.bonusStartView:runCsbAction(
        "auto",
        false,
        function()
            print("self.bonusStartViewstart over")
            -- self:resetMusicBg(true)
            if func then
                func()
            end

            if self.bonusStartView then
                print("self.bonusStartViewstart hide")
                self.bonusStartView:setVisible(false)
            end
        end
    )
end

---
-- 显示bonus freespin 触发小格子连线提示处理
--
function CodeGameScreenCandyBingoMachine:showBonusAndScatterLineTip(lineValue, callFun)
    local frameNum = lineValue.iLineSymbolNum

    if lineValue.iLineSymbolNum == 0 then
        if lineValue.vecValidMatrixSymPos then
            frameNum = #lineValue.vecValidMatrixSymPos
        end
    end

    local animTime = 0

    local frameNodeList = {}

    -- self:operaBigSymbolMask(true)

    for i = 1, frameNum do
        -- 播放slot node 的动画
        local symPosData = lineValue.vecValidMatrixSymPos[i]
        local parentData = self.m_slotParents[symPosData.iY]
        local slotParent = parentData.slotParent

        local slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + symPosData.iX)

        -- 为了特殊长条触发 bnous 或 freeSpin做的特殊处理
        if self.m_bigSymbolColumnInfo ~= nil and self.m_bigSymbolColumnInfo[symPosData.iY] ~= nil and not slotNode then
            local bigSymbolInfos = self.m_bigSymbolColumnInfo[symPosData.iY]
            for k = 1, #bigSymbolInfos do
                local bigSymbolInfo = bigSymbolInfos[k]

                for changeIndex = 1, #bigSymbolInfo.changeRows do
                    if bigSymbolInfo.changeRows[changeIndex] == symPosData.iX then
                        slotNode = slotParent:getChildByTag(symPosData.iY * SYMBOL_NODE_TAG + bigSymbolInfo.startRowIndex)

                        break
                    end
                end
            end
        end

        if slotNode ~= nil then --这里有空的没有管
            -- slotNode = self:setSlotNodeEffectParent(slotNode)
            -- slotNode:runLineAnim()

            local fixnode = self:getFixSymbolSmallReels(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
            fixnode:setVisible(false)
            local faslotNode = slotNode
            faslotNode:setVisible(false)

            table.insert(frameNodeList, slotNode)

            --self:createOneActionSymbol(faslotNode,"actionframe",fixnode,true,function(  )
            self:createOneActionSymbol(
                faslotNode,
                "actionframe",
                fixnode,
                true,
                function()
                    fixnode:setVisible(true)
                    faslotNode:setVisible(true)
                end,
                nil,
                "idleframe"
            )
            --end,true)

            if animTime == 0 then
                animTime = (util_max(animTime, slotNode:getAniamDurationByName(slotNode:getLineAnimName()))) + 0.5
            end
        end
    end

    -- 延迟回调播放 界面提示 bonus  freespin
    scheduler.performWithDelayGlobal(
        function()
            for k, v in pairs(frameNodeList) do
                local frameNode = v
                if frameNode then
                    frameNode:runIdleAnim()
                end
            end

            if callFun then
                callFun()
            end
        end,
        util_max(2, animTime),
        self:getModuleName()
    )
end

----------- FreeSpin相关
---
-- 显示free spin
function CodeGameScreenCandyBingoMachine:showEffect_FreeSpin(effectData)
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
    self.isInBonus = true

    util_spinePlay(self.m_panda_right, "lianxian_right", false)
    util_spinePlay(self.m_panda_left, "lianxian_left", false)

    if scatterLineValue ~= nil then
        performWithDelay(
            self,
            function()
                self:removeAllActionNode(true)
                self:showBonusAndScatterLineTip(
                    scatterLineValue,
                    function()
                        -- self:visibleMaskLayer(true,true)
                        gLobalSoundManager:stopAllAuido() -- 触发freespin 界面时， 如果有音乐没有播完就停止不要播了。 特别是freespin move
                        self:showFreeSpinView(effectData)
                    end
                )
                scatterLineValue:clean()
                self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = scatterLineValue
                -- 播放提示时播放音效
                self:playScatterTipMusicEffect()
            end,
            1
        )
    else
        self:showFreeSpinView(effectData)
    end
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin, self.m_iOnceSpinLastWin)
    return true
end

function CodeGameScreenCandyBingoMachine:triggerFreeSpinCallFun()
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
        gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
    end
    gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM) -- 向spin按钮发送消息

    if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        -- self:levelFreeSpinEffectChange()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_ON)
    -- self:showFreeSpinBar()
    end

    self:setCurrSpinMode(FREE_SPIN_MODE)
    self.m_bProduceSlots_InFreeSpin = true
    self:resetMusicBg()
end

function CodeGameScreenCandyBingoMachine:getSymbolNum(symType)
    local num = 0
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = self.m_iReelRowNum, 1, -1 do
            local symbolType = self.m_runSpinResultData.p_reels[iRow][iCol]
            if symType == symbolType then
                num = num + 1
            end
        end
    end

    return num
end

function CodeGameScreenCandyBingoMachine:showFreeSpinStart(num, func)
    local freespinTimesList = {{0, 0, 6, 12, 18}, {0, 0, 8, 16, 24}, {0, 0, 10, 20, 30}}

    local betLevel = self:getBetLevel()

    if betLevel == 0 then
        local ownerlist = {}
        ownerlist["m_lb_num"] = num

        local view = self:showDialog("CandyBingo_BetView2", ownerlist, func)
        local coins1 = view:findChild("m_lb_coins_1")
        local coins2 = view:findChild("m_lb_coins_2")
        if coins1 then
            local coinssum1 = self.m_specialBets[2].p_totalBetValue
            coins1:setString(util_formatCoins(coinssum1, 3))
        -- view:updateLabelSize({label=coins1,sx=1,sy=1},83)
        end
        if coins2 then
            local coinssum2 = self.m_specialBets[1].p_totalBetValue
            coins2:setString(util_formatCoins(coinssum2, 3))

        -- view:updateLabelSize({label=coins1,sx=1,sy=1},83)
        end

        local num1 = view:findChild("m_lb_num_1")
        local num2 = view:findChild("m_lb_num_2")
        if num1 then
            num1:setString(freespinTimesList[3][self:getSymbolNum(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)])
        end
        if num2 then
            num2:setString(freespinTimesList[2][self:getSymbolNum(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)])
        end
        -- view:setPosition(display.width/2,display.height/2)

        return view
    elseif betLevel == 1 then
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        local view = self:showDialog("CandyBingo_BetView3", ownerlist, func)

        local coins1 = view:findChild("m_lb_coins_1")
        if coins1 then
            local coinssum1 = self.m_specialBets[2].p_totalBetValue
            coins1:setString(util_formatCoins(coinssum1, 3))
        -- view:updateLabelSize({label=coins1,sx=1,sy=1},83)
        end

        local num1 = view:findChild("m_lb_num_1")
        if num1 then
            num1:setString(freespinTimesList[3][self:getSymbolNum(TAG_SYMBOL_TYPE.SYMBOL_SCATTER)])
        end

        -- view:setPosition(display.width/2,display.height/2)
        return view
    elseif betLevel == 2 then
        local ownerlist = {}
        ownerlist["m_lb_num"] = num
        local view = self:showDialog("FreeSpinStart", ownerlist, func)

        -- view:setPosition(display.width/2,display.height/2)
        return view
    end

    --也可以这样写 self:showDialog("FreeSpinStart",ownerlist,func)
end

-- FreeSpinstart
function CodeGameScreenCandyBingoMachine:showFreeSpinView(effectData)
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_fs.mp3")

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
                local m_lb_num1 = self.m_CandyBingoFreespinBar:findChild("m_lb_num1")
                if m_lb_num1 then
                    m_lb_num1:setString("")
                end
                local m_lb_num2 = self.m_CandyBingoFreespinBar:findChild("m_lb_num2")
                if m_lb_num2 then
                    m_lb_num2:setString("")
                end

                self:showFreeSpinStart(
                    self.m_iFreeSpinTimes,
                    function()
                        gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_click.mp3")

                        gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_fs_guochang.mp3")

                        self.m_CandyBingoGuoChangView:setVisible(true)
                        self.m_CandyBingoGuoChangView:runCsbAction(
                            "guochang",
                            false,
                            function()
                                self.m_CandyBingoGuoChangView:setVisible(false)
                                self:triggerFreeSpinCallFun()
                                effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        )

                        performWithDelay(
                            self,
                            function()
                                util_spinePlay(self.m_panda_left, "huxi_left", true)
                                util_spinePlay(self.m_panda_right, "huxi_right", true)
                                self:levelFreeSpinEffectChange()
                                self:showFreeSpinBar()
                            end,
                            1
                        )
                    end
                )
            end
        end,
        0.5
    )
end

---
-- 显示free spin over 动画
function CodeGameScreenCandyBingoMachine:showEffect_FreeSpinOver()
    if #self.m_reelResultLines == 0 then
        self.m_freeSpinOverCurrentTime = 1
    end

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end

    -- 断线进来的fsover
    if self.m_outOnlin and self.m_runSpinResultData.p_freeSpinsLeftCount then
        if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 then
            self:hideFreeSpinBar()
        end
    end

    if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime > 0 then
        self.m_fsOverHandlerID =
            scheduler.scheduleGlobal(
            function()
                if self.m_freeSpinOverCurrentTime and self.m_freeSpinOverCurrentTime > 0 then
                    self.m_freeSpinOverCurrentTime = self.m_freeSpinOverCurrentTime - 0.1
                else
                    self:showEffect_newFreeSpinOver()
                end
            end,
            0.1
        )
    else
        self:showEffect_newFreeSpinOver()
    end
    return true
end

function CodeGameScreenCandyBingoMachine:showFreeSpinOverView()
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_fs.mp3")

            local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
            local view =
                self:showFreeSpinOver(
                strCoins,
                self.m_runSpinResultData.p_freeSpinsTotalCount,
                function()
                    self:checkQuestDoneGameEffect()
                    gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_click.mp3")

                    gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_fs_guochang.mp3")

                    self.m_CandyBingoGuoChangView:setVisible(true)
                    self.m_CandyBingoGuoChangView:runCsbAction(
                        "guochang",
                        false,
                        function()
                            self.m_CandyBingoGuoChangView:setVisible(false)
                            self:triggerFreeSpinOverCallFun()
                        end
                    )

                    performWithDelay(
                        self,
                        function()
                            self:levelFreeSpinOverChangeEffect()
                            self:hideFreeSpinBar()
                            util_spinePlay(self.m_panda_left, "huxi_left", true)
                            util_spinePlay(self.m_panda_right, "huxi_right", true)
                        end,
                        1
                    )
                end
            )
            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node, sx = 0.56, sy = 0.56}, 692)
        end,
        0.5
    )
end

--检测是否可以增加quest 完成事件
function CodeGameScreenCandyBingoMachine:checkQuestDoneGameEffect()
    -- cxc 2021年07月01日10:23:51 quest需要检查下有没有新手quest
    if self.afreshAddQuestDoneEffectType then
        self:afreshAddQuestDoneEffectType()
        return
    end
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not questConfig then
        return
    end
    local hasQuestEffect = self:checkHasGameEffectType(GameEffect.EFFECT_QUEST_DONE)
    if hasQuestEffect == false then
        local questEffect = GameEffectData:create()
        questEffect.p_effectType = GameEffect.EFFECT_QUEST_DONE --创建属性
        questEffect.p_effectOrder = 999999 --动画播放层级 用于动画播放顺序排序
        self.m_gameEffects[#self.m_gameEffects + 1] = questEffect
    end
end

function CodeGameScreenCandyBingoMachine:triggerFreeSpinOverCallFun()
    local _coins = self.m_runSpinResultData.p_fsWinCoins or 0
    if self.postFreeSpinOverTriggerBigWIn then
        self:postFreeSpinOverTriggerBigWIn(_coins)
    end

    -- 切换滚轮赔率表
    self:changeNormalReelData()

    -- 当freespin 结束时， 有可能最后一次不赢钱， 所以需要手动播放一次 stop
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

    self:setCurrSpinMode(NORMAL_SPIN_MODE)
    if self.m_bProduceSlots_InFreeSpin == true then
        self.m_bProduceSlots_InFreeSpin = false
        print("222self.m_bProduceSlots_InFreeSpin = false")
    end
    globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    -- self:levelFreeSpinOverChangeEffect()
    -- self:hideFreeSpinBar()

    self:resetMusicBg()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GAME_EFFECT_COMPLETE_WITHTYPE, GameEffect.EFFECT_FREE_SPIN_OVER)
    globalData.userRate:pushFreeSpinCoins(self:getLastWinCoin())
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenCandyBingoMachine:MachineRule_SpinBtnCall()
    gLobalSoundManager:setBackgroundMusicVolume(1)

    self.m_outOnlin = false

    --显示单独滚轮盘信息，并且隐藏整个滚轮盘
    self:showSingleReelSlotsNodeVisible(true)

    self:removeAllActionNode()

    self.m_scatterDownIndex = 1

    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenCandyBingoMachine:MachineRule_network_InterveneSymbolMap()
    self:resetTopReelsData()
    --- spin后更新本地BetData
    self:updateLocalBetData()

    self.m_BonusCollectSumScore = 0
    -- 在算线之前更新bonus获得的总钱数
    self:setBonusWinCosin()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理，
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenCandyBingoMachine:MachineRule_afterNetWorkLineLogicCalculate()
end

function CodeGameScreenCandyBingoMachine:getArryNum(array)
    local index = 0

    for k, v in pairs(array) do
        index = index + 1
    end

    return index
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenCandyBingoMachine:addSelfEffect()
    -- 添加topReels更新分数动画
    if self.m_bonusReelsBonusCoinsData and self:getArryNum(self.m_bonusReelsBonusCoinsData) > 0 then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 10
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.Update_Top_Reels_Node -- 动画类型
    end

    -- 如果触发了bonus，添加一个自定义动画，不走bonus的动画
    if self:isTriggerBonus() then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 9
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.Show_Bonus_View -- 动画类型

        -- 自定义动画创建方式
        local selfOverEffect = GameEffectData.new()
        selfOverEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfOverEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT - 8
        self.m_gameEffects[#self.m_gameEffects + 1] = selfOverEffect
        selfOverEffect.p_selfEffectType = self.Show_Bonus_over_View -- 动画类型
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenCandyBingoMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.Update_Top_Reels_Node then
        self:UpdateTopReelsNode(effectData)
    elseif effectData.p_selfEffectType == self.Show_Bonus_View then
        self:showBonusGameAction(effectData)
    elseif effectData.p_selfEffectType == self.Show_Bonus_over_View then
        self:showBonusGameOverActionView(effectData)
    end

    return true
end

function CodeGameScreenCandyBingoMachine:UpdateTopReelsNode(effectData)
    local dealyTime = 0.7

    gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_Bonus_collect.mp3")

    local betCoin = globalData.slotRunData:getCurTotalBet() or 0
    for k, v in pairs(self.m_bonusReelsBonusCoinsData) do
        local index = tonumber(v.pos)
        local score = tonumber(v.coins)
        local smallReelsNode = self:getSmallReelsNodeFromIndex(index)
        if smallReelsNode then
            local sumScore = self.m_bonusReelsData[6 - smallReelsNode.iRow][smallReelsNode.iCol]
            local fixSymbol = self:getFixSymbol(smallReelsNode.iCol, smallReelsNode.iRow, SYMBOL_NODE_TAG)

            local func = function()
                smallReelsNode:setVisible(true)
                if smallReelsNode.p_symbolType and smallReelsNode.p_symbolType == self.Socre_CandyBingo_Chip then
                    local scoreNode = smallReelsNode:getCcbProperty("m_lb_score")
                    if scoreNode then
                        scoreNode.score = sumScore
                        scoreNode:setString(util_formatCoins(sumScore, 3))
                    end

                    local scoreNode10 = smallReelsNode:getCcbProperty("m_lb_score_10")
                    if scoreNode10 then
                        scoreNode10.score = sumScore
                        scoreNode10:setString(util_formatCoins(sumScore, 3))
                    end
                end

                if betCoin then
                    if smallReelsNode.p_symbolType and smallReelsNode.p_symbolType == self.Socre_CandyBingo_Chip then
                        if sumScore >= (betCoin * self.m_labBet) then
                            local lab = smallReelsNode:getCcbProperty("m_lb_score")
                            local lab10 = smallReelsNode:getCcbProperty("m_lb_score_10")
                            lab:setVisible(false)
                            lab10:setVisible(true)
                        else
                            local lab = smallReelsNode:getCcbProperty("m_lb_score")
                            local lab10 = smallReelsNode:getCcbProperty("m_lb_score_10")
                            lab:setVisible(true)
                            lab10:setVisible(false)
                        end
                    end
                end

                if smallReelsNode.p_symbolType and smallReelsNode.p_symbolType == self.Socre_CandyBingo_Chip then
                    smallReelsNode:runAnim("shouji")
                end

                local boom = util_createView("CodeCandyBingoSrc.CandyBingoTopNodeUpdateAction")
                self:findChild("Node_1_0"):addChild(boom, 10000)
                boom:setPosition(cc.p(smallReelsNode:getPosition()))
                boom:runCsbAction(
                    "animation0",
                    false,
                    function()
                        boom:removeFromParent()
                    end
                )
            end

            -- Node_lunpan_2 存放Bigreels 的节点
            local startPosWord = self:findChild("Node_lunpan_2"):convertToWorldSpace(cc.p(self:getBigNodePosByColAndRow(smallReelsNode.iRow, smallReelsNode.iCol)))
            local startPos = cc.p(self.m_root:convertToNodeSpace(startPosWord))
            -- Node_1_0 存放topreels 的节点
            local endPosWord = self:findChild("Node_1_0"):convertToWorldSpace(cc.p(smallReelsNode:getPosition()))
            local endPos = cc.p(self.m_root:convertToNodeSpace(endPosWord))
            local time = dealyTime
            local posCol = smallReelsNode.iCol
            local posRow = smallReelsNode.iRow
            self.m_moveIndex = self.m_moveIndex + 1
            self:createCandyBingoFly(startPos, endPos, dealyTime, posCol, posRow, func)
        end
    end

    if self:isTriggerBonus() then
        self.m_moveIndex = 1

        local tipdata = self.m_bonusReelsBingoPositionsData
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        performWithDelay(
            waitNode,
            function()
                -- 更新上部提示
                self:updateTopSmallReelsTipNode()

                effectData.p_isPlay = true
                self:playGameEffect()
                waitNode:removeFromParent()
            end,
            dealyTime
        )
    else
        self.m_moveIndex = self.m_moveIndex + 1

        local tipdata = clone(self.m_bonusReelsBingoPositionsData)
        local waitNode = cc.Node:create()
        self:addChild(waitNode)
        waitNode:setName("flyCollectWait_" .. self.m_moveIndex)
        performWithDelay(
            waitNode,
            function()
                -- 更新上部提示
                self:updateTopSmallReelsTipNode(tipdata)
                waitNode:removeFromParent()
            end,
            dealyTime
        )

        effectData.p_isPlay = true
        self:playGameEffect()
    end
end

function CodeGameScreenCandyBingoMachine:changeBetStopCollectAnim()
    for i = 1, self.m_moveIndex do
        local node_wait = self:getChildByName("flyCollectWait_" .. i)
        if node_wait then
            node_wait:stopAllActions()
            node_wait:removeFromParent()
        end

        local node_fly = self.m_root:getChildByName("flyCollect_" .. i)
        if node_fly then
            node_fly:stopAllActions()
            node_fly:removeFromParent()
        end
    end

    self.m_moveIndex = 1
end

---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenCandyBingoMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
end

function CodeGameScreenCandyBingoMachine:requestSpinResult()
    local betCoin = globalData.slotRunData:getCurTotalBet()

    local totalCoin = globalData.userRunData.coinNum

    -- 这里已经计算好了， spin后 的等级一级 经验 ， 如果返回失败后 那么会直接刷新游戏不影响数据结果  2018-08-04 12:34:31
    if self.m_spinIsUpgrade == nil then
        self.m_spinIsUpgrade = false
    end
    if self.m_spinNextLevel == nil then
        self.m_spinNextLevel = globalData.userRunData.levelNum
    end
    if self.m_spinNextProVal == nil then
        self.m_spinNextProVal = globalData.userRunData.currLevelExper
    end
    --检测大赢类型

    local httpSendMgr = gLobalSendDataManager:getNetWorkSlots()

    -- 发送spin action
    local moduleName = self:getNetWorkModuleName()

    local isFreeSpin = true
    --小猪银行
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and self:getCurrSpinMode() ~= REWAED_SPIN_MODE and self:getCurrSpinMode() ~= RESPIN_MODE then
        self.m_topUI:updataPiggy(betCoin)
        isFreeSpin = false
    end
    self:updateJackpotList()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_SPIN_PROGRESS, data = self.m_collectDataList, jackpot = self.m_jackpotList, betLevel = self:getBetLevel()}
    -- local operaId =
    httpSendMgr:sendActionData_Spin(betCoin, totalCoin, 0, isFreeSpin, moduleName, self.m_spinIsUpgrade, self.m_spinNextLevel, self.m_spinNextProVal, messageData, false)
end

function CodeGameScreenCandyBingoMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(0, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end

function CodeGameScreenCandyBingoMachine:beginReel()
    self:resetReelDataAfterReel()
    local slotsParents = self.m_slotParents
    for i = 1, #slotsParents do
        local parentData = slotsParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig

        local reelDatas = self:checkUpdateReelDatas(parentData)

        self:checkReelIndexReason(parentData)
        self:resetParentDataReel(parentData)

        -- self:createSlotNextNode(parentData)
        if self.m_configData.p_reelBeginJumpTime > 0 then
            self:addJumoActionAfterReel(slotParent, slotParentBig)
        else
            self:registerReelSchedule()
        end
        -- self:checkChangeClipParent(parentData)
    end
    -- self:checkChangeBaseParent()

    --wild刷光
    self:wildFlash()
end

-- 开始刷帧
function CodeGameScreenCandyBingoMachine:registerReelSchedule()
    self.m_SmallReelsView:startMove()

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:onUpdate(
            function(delayTime)
                self:reelSchedulerHanlder(delayTime)
            end
        )
    end
end

function CodeGameScreenCandyBingoMachine:reelSchedulerHanlder(delayTime)
    if (self:getGameSpinStage() ~= GAME_MODE_ONE_RUN and self:getGameSpinStage() ~= QUICK_RUN) or self:checkGameRunPause() then
        return
    end

    -- 真实网络数据返回
    if self.m_isWaitingNetworkData == false then
        if self.m_reelScheduleDelegate ~= nil then
            self.m_reelScheduleDelegate:unscheduleUpdate()
        end
        print("根据网络数据手动刷新小块")

        for iCol = 1, self.m_iReelColumnNum do
            for iRow = self.m_iReelRowNum, 1, -1 do
                local symbolType = self.m_stcValidSymbolMatrix[iRow][iCol]
                local targSp = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))
                if targSp then
                    targSp:runAnim("idleframe")
                    targSp:changeCCBByName(self:getSymbolCCBNameByType(self, symbolType), symbolType)
                    if symbolType == self.Socre_CandyBingo_Chip then
                        self:setSpecialNodeScore(nil, {targSp})
                    end
                    local order = self:getBounsScatterDataZorder(symbolType) - targSp.p_rowIndex
                    targSp.p_showOrder = order
                    targSp:setLocalZOrder(order)
                end
            end
        end

        self:stopSmallReelsRun()

        self.m_reelDownAddTime = 0
    end
end

function CodeGameScreenCandyBingoMachine:playEffectNotifyNextSpinCall()
    BaseSlotoManiaMachine.playEffectNotifyNextSpinCall(self)

    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

---
-- 老虎机滚动结束调用
function CodeGameScreenCandyBingoMachine:slotReelDown()
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )

    -- self:removeAllActionNode()

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

    -- 还原reel parent 信息
    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local posx, posy = slotParent:getPosition()
        slotParent:setPosition(0, 0) -- 还原位置信息

        local childs = slotParent:getChildren()
        --        printInfo("xcyy  剩余 child count %d", #childs)

        local lastType = nil
        local preRow = 0
        local maxLastNodePosY = nil
        local minLastNodePosY = nil

        parentData:reset()
    end

    -- 判断是否是长条模式，处理长条只显示一部分的遮罩问题
    -- self:operaBigSymbolMask(true)

    self:reelDownNotifyChangeSpinStatus()

    self:delaySlotReelDown()

    self:stopAllActions()

    --wild刷光
    self:wildFlash()

    self:reelDownNotifyPlayGameEffect()

    --显示单独滚轮盘信息，并且隐藏整个滚轮盘
    self:showSingleReelSlotsNodeVisible(false)
end

---
---
-- 点击快速停止reel
--
function CodeGameScreenCandyBingoMachine:quicklyStopReel()
    print("quicklyStopReel  调用了快停")

    self:setGameSpinStage(QUICK_RUN) -- 已经处于快速停止状态了。。

    if self.m_SmallReelsView then
        self.m_SmallReelsView:quicklyStop()
    end
end

----构造小块单独滚 所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function CodeGameScreenCandyBingoMachine:createSmallReelsNodeInfo()
    local smallNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            -- 处理第一次进入轮盘时的情况
            if symbolType == nil then
                if iCol == 3 and iRow == 3 then
                    symbolType = 92
                else
                    symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1)
                end
            end

            -- 不是freespin或者freespin触发的状态 每次进入都随机普通轮盘
            if self:isTriggerFreespinOrInFreespin() == false then
                if iCol == 3 and iRow == 3 then
                    symbolType = 92
                else
                    symbolType = math.random(TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1)
                end
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
            smallNodeInfo[#smallNodeInfo + 1] = symbolNodeInfo

            if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                local node = self:getReelParent(iCol):getChildByTag(self:getNodeTag(iCol, iRow, SYMBOL_NODE_TAG))

                self:createOneActionSymbol(node, "idleframe", nil, true, nil, nil, "idleframe")
            end
        end
    end
    return smallNodeInfo
end

-- 创建单个滚动小块轮盘

function CodeGameScreenCandyBingoMachine:createSmallReels()
    local endTypes = {}
    local randomTypes = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 94, 90}

    self.m_SmallReelsView = util_createView("CodeCandyBingoSrc.CandyBingoRespinView", "CodeCandyBingoSrc.CandyBingoRespinNode", self)
    self.m_SmallReelsView:setMachine(self)
    self.m_SmallReelsView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_SmallReelsView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE - 100)

    --构造盘面数据
    local SmallReelsNodeInfo = self:createSmallReelsNodeInfo()

    self.m_SmallReelsView:setEndSymbolType(endTypes, randomTypes)
    self.m_SmallReelsView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_SmallReelsView:initRespinElement(
        SmallReelsNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            -- self:runNextReSpinReel()
        end
    )

    --显示单独滚轮盘信息，并且隐藏整个滚轮盘
    self:showSingleReelSlotsNodeVisible(true)
end

-- 是否显示单独滚的小块轮盘
function CodeGameScreenCandyBingoMachine:showSingleReelSlotsNodeVisible(states)
    if states then
        --隐藏 盘面信息
        self:setReelSlotsNodeVisible(false)
        self.m_SmallReelsView:setVisible(true)

        self:findChild("respin_strip_node"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    else
        self:setReelSlotsNodeVisible(true)
        self.m_SmallReelsView:setVisible(false)
        self:findChild("respin_strip_node"):setLocalZOrder(1)
    end
end

--接收到数据开始停止滚动
function CodeGameScreenCandyBingoMachine:stopSmallReelsRun()
    local storedNodeInfo = {}
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_SmallReelsView:setRunEndInfo(storedNodeInfo, unStoredReels)
end

---滚轮停止复用respin停止自定义事件
function CodeGameScreenCandyBingoMachine:reSpinReelDown(addNode)
    self:slotReelDown()

    self.m_SmallReelsView:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
end

--------顶部小轮盘模块

-- 断线重连初始化topreels数据
function CodeGameScreenCandyBingoMachine:initTopSmallReelsData()
    -- self.m_bonusReelsData
    local gameCofing = self.m_runSpinResultData.p_CandyBingoGameConfig
    if gameCofing then
        --  先处理轮盘信息的更新
        local betValue = self:BaseMania_getLineBet() * self.m_lineCount
        if gameCofing.bets then
            self.m_betData = gameCofing.bets

            local topReelsData = gameCofing.bets[tostring(toLongNumber(betValue))]
            if topReelsData then
                -- 轮盘
                if topReelsData.bonusReels then
                    self.m_bonusReelsData = topReelsData.bonusReels
                end

                -- 宾果线
                if topReelsData.bingoLines then
                    self.m_bonusReelsBingoLinesData = topReelsData.bingoLines
                end

                if topReelsData.bingoPositions then -- 可能会中bingo 的位置数组
                    self.m_bonusReelsBingoPositionsData = topReelsData.bingoPositions
                end
            end
        end
    end

    if self.m_runSpinResultData.p_selfMakeData then
        local bonusCoins = self.m_runSpinResultData.p_selfMakeData.bonusCoins
        if bonusCoins then
            self.m_bonusReelsBonusCoinsData = bonusCoins
        end
    end
end

-- spin后更新维护本地 betdata
function CodeGameScreenCandyBingoMachine:updateLocalBetData()
    local reelsData = self.m_runSpinResultData.p_selfMakeData

    if self.m_runSpinResultData.p_selfMakeData then
        local bingoData = self.m_runSpinResultData.p_selfMakeData.bingo
        if bingoData then
            -- 更新本地存储表
            local betValue = self:BaseMania_getLineBet() * self.m_lineCount
            self.m_betData[tostring(toLongNumber(betValue))] = bingoData
        end
    end

    -- 更新本地topreelsdata
    self:updateTopSmallReelsData()
end

--------- spin后更新本地topreelsdata
function CodeGameScreenCandyBingoMachine:updateTopSmallReelsData()
    -- 更新本地存储表
    local betValue = self:BaseMania_getLineBet() * self.m_lineCount

    local bingoData = self.m_betData[tostring(toLongNumber(betValue))]
    if bingoData then
        if bingoData.bingoLines then
            self.m_bonusReelsBingoLinesData = bingoData.bingoLines
        end

        if bingoData.bonusReels then
            self.m_bonusReelsData = bingoData.bonusReels
        end

        if bingoData.bingoPositions then -- 可能会中bingo 的位置数组
            self.m_bonusReelsBingoPositionsData = bingoData.bingoPositions
        end
    end

    local reelsData = self.m_runSpinResultData.p_selfMakeData
    if reelsData then
        if reelsData.bonusCoins then --下方大轮盘特殊图标需要显示的分数
            self.m_bonusReelsBonusCoinsData = reelsData.bonusCoins
        end
    end
end

function CodeGameScreenCandyBingoMachine:resetTopReelsData(betValue)
    self.m_bonusReelsData = {{0, 0, 0, 0, 0}, {0, 0, 0, 0, 0}, {0, 0, -1, 0, 0}, {0, 0, 0, 0, 0}, {0, 0, 0, 0, 0}}
    self.m_bonusReelsBingoLinesData = {}
    self.m_bonusReelsBonusCoinsData = {}
    self.m_bonusReelsBingoPositionsData = {}

    if betValue then
        self.m_betData[tostring(toLongNumber(betValue))] = {}
    end
end

-- 获得bonus轮盘信号
function CodeGameScreenCandyBingoMachine:getBonusReelsTypeNameForNetData(score)
    local typename = nil
    local symbolType = nil
    if score == -1 then
        typename = self:MachineRule_GetSelfCCBName(self.Socre_CandyBingo_Special_Scatter)
        symbolType = self.Socre_CandyBingo_Special_Scatter
    else
        typename = self:MachineRule_GetSelfCCBName(self.Socre_CandyBingo_Chip)
        symbolType = self.Socre_CandyBingo_Chip
    end

    return symbolType, typename
end

-- 创建顶部小块
function CodeGameScreenCandyBingoMachine:initTopReelsNode()
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local score = self.m_bonusReelsData[6 - iRow][iCol]
            local symbolType, ccbName = self:getBonusReelsTypeNameForNetData(score)
            local node = SlotsNode:create()
            print("ccbName~ " .. ccbName .. "symbolType " .. symbolType)
            node:initSlotNodeByCCBName(ccbName, symbolType)
            local iconpos = self:getPosReelIdx(iRow, iCol)
            print("self:getPosReelIdx(iRow, iCol)  " .. iconpos)
            node.iconpos = iconpos
            node.score = score
            node.iRow = iRow
            node.iCol = iCol
            self:findChild("Node_1_0"):addChild(node, smallReelsZOrder.down)
            if symbolType == self.Socre_CandyBingo_Special_Scatter then
                node:runAnim("idle", true)
            else
                node:runAnim("idleframe", false)
            end

            if symbolType == self.Socre_CandyBingo_Chip then
                local lab = node:getCcbProperty("m_lb_score")
                if lab then
                    node.score = score
                    lab:setString(util_formatCoins(score, 3))
                end

                local lab10 = node:getCcbProperty("m_lb_score_10")
                if lab10 then
                    lab10.score = score
                    lab10:setString(util_formatCoins(score, 3))
                end
            end

            local betCoin = globalData.slotRunData:getCurTotalBet() or 0
            if betCoin then
                if node.p_symbolType and node.p_symbolType == self.Socre_CandyBingo_Chip then
                    if score >= (betCoin * self.m_labBet) then
                        -- node:runAnim("beishu_x10",true)
                        local lab = node:getCcbProperty("m_lb_score")
                        local lab10 = node:getCcbProperty("m_lb_score_10")
                        lab:setVisible(false)
                        lab10:setVisible(true)
                    else
                        -- node:runAnim("idleframe")
                        local lab = node:getCcbProperty("m_lb_score")
                        local lab10 = node:getCcbProperty("m_lb_score_10")
                        lab:setVisible(true)
                        lab10:setVisible(false)
                    end
                end
            end

            node:setPosition(self:getBigNodePosByColAndRow(iRow, iCol, true))

            if score == 0 then
                node:setVisible(false)
            else
                node:setVisible(true)
            end

            -- 创建提示框
            -- 上部提示框
            local tipNode = SlotsNode:create()
            local tipNodeCcbName = self:MachineRule_GetSelfCCBName(self.Socre_CandyBingo_Tip_Node)
            print("ccbName~ " .. ccbName .. "symbolType " .. symbolType)
            tipNode:initSlotNodeByCCBName(ccbName, self.Socre_CandyBingo_Tip_Node)
            self:findChild("Node_1_0"):addChild(tipNode, smallReelsZOrder.down + 1)
            tipNode:setPosition(self:getBigNodePosByColAndRow(iRow, iCol, true))
            tipNode:setVisible(false)
            node.tipNode = tipNode

            -- 下部提示框

            local tipNodeBig = SlotsNode:create()
            local tipNodeCcbName = self:MachineRule_GetSelfCCBName(self.Socre_CandyBingo_Tip_Node)
            print("ccbName~ " .. ccbName .. "symbolType " .. symbolType)
            tipNodeBig:initSlotNodeByCCBName(ccbName, self.Socre_CandyBingo_Tip_Node)
            self:findChild("Node_lunpan_2"):addChild(tipNodeBig, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE)
            tipNodeBig:setPosition(self:getBigNodePosByColAndRow(iRow, iCol, false))
            tipNodeBig:setVisible(false)
            node.tipNodeBig = tipNodeBig

            table.insert(self.m_bonusReelsNodeList, node)
        end
    end
end

-- 把要中奖的小块移到上方
function CodeGameScreenCandyBingoMachine:showBonusReelsNodeZOrder(nodeindex)
    for k, v in pairs(self.m_bonusReelsNodeList) do
        local node = v
        if node.iconpos == nodeindex then
            node:setLocalZOrder(smallReelsZOrder.top)
        end
    end
end

-- 把所有小块放到遮罩层下
function CodeGameScreenCandyBingoMachine:hideBonusReelsNodeZOrder()
    for k, v in pairs(self.m_bonusReelsNodeList) do
        local node = v
        node:setLocalZOrder(smallReelsZOrder.down)
    end
end

-- 刷新顶部小块
function CodeGameScreenCandyBingoMachine:updateTopSmallReelsNode()
    for k, v in pairs(self.m_bonusReelsNodeList) do
        local node = v
        local netNowScore = self.m_bonusReelsData[6 - node.iRow][node.iCol]
        if netNowScore == 0 then
            node:setVisible(false)
        else
            node:setVisible(true)
        end
        node:runAnim("idleframe", false)

        if node.p_symbolType and node.p_symbolType == self.Socre_CandyBingo_Chip then
            local lab = node:getCcbProperty("m_lb_score")
            if lab then
                node.score = netNowScore
                lab:setString(util_formatCoins(netNowScore, 3))
            end

            local lab10 = node:getCcbProperty("m_lb_score_10")
            if lab10 then
                lab10.score = netNowScore
                lab10:setString(util_formatCoins(netNowScore, 3))
            end
        end

        local betCoin = globalData.slotRunData:getCurTotalBet() or 0

        if betCoin then
            if node.p_symbolType and node.p_symbolType == self.Socre_CandyBingo_Chip then
                local sumScore = node.score
                if node.p_symbolType and node.p_symbolType == self.Socre_CandyBingo_Chip then
                    if sumScore >= (betCoin * self.m_labBet) then
                        -- node:runAnim("beishu_x10",true)
                        local lab = node:getCcbProperty("m_lb_score")
                        local lab10 = node:getCcbProperty("m_lb_score_10")
                        lab:setVisible(false)
                        lab10:setVisible(true)
                    else
                        -- node:runAnim("idleframe")
                        local lab = node:getCcbProperty("m_lb_score")
                        local lab10 = node:getCcbProperty("m_lb_score_10")
                        lab:setVisible(true)
                        lab10:setVisible(false)
                    end
                end
            end
        end
    end
end

function CodeGameScreenCandyBingoMachine:hideAllTopSmallReelsTipNode()
    for k, v in pairs(self.m_bonusReelsNodeList) do
        local node = v
        local tipNode = node.tipNode
        if tipNode then
            --tipNode:runAnim("shanguang",false,function(  )
            tipNode:setVisible(false)
        --end)
        end
        local tipNodeBig = node.tipNodeBig
        if tipNodeBig then
            --tipNodeBig:runAnim("shanguang",false,function(  )
            tipNodeBig:setVisible(false)
        --end)
        end
    end
end

--更新提示框
function CodeGameScreenCandyBingoMachine:updateTopSmallReelsTipNode(_tipPosData)
    self:hideAllTopSmallReelsTipNode()

    local tipPosData = _tipPosData or self.m_bonusReelsBingoPositionsData
    for k, v in pairs(tipPosData) do
        local index = tonumber(v)
        local node = self:getSmallReelsNodeFromIndex(index)
        local tipNode = node.tipNode
        if tipNode then
            if not tipNode:isVisible() then
                tipNode:setVisible(true)
                tipNode:runAnim("actionframe", true)
            end
        end
        local tipNodeBig = node.tipNodeBig
        if tipNodeBig then
            if not tipNodeBig:isVisible() then
                tipNodeBig:setVisible(true)
                tipNodeBig:runAnim("actionframe", true)
            end
        end
    end
end

function CodeGameScreenCandyBingoMachine:getSmallReelsNodeFromIndex(index)
    local SmallReelsNode = nil

    for k, v in pairs(self.m_bonusReelsNodeList) do
        local node = v
        if node.iconpos and node.iconpos == index then
            SmallReelsNode = node

            break
        end
    end

    return SmallReelsNode
end

function CodeGameScreenCandyBingoMachine:getBigNodePosByColAndRow(row, col, smallReels)
    local name = "sp_reel_" --大轮盘
    if smallReels then
        name = "sp_reel_little_" -- 上边的小轮盘
    end
    local reelNode = self:findChild(name .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

------------- 大转盘相关
-- 显示轮盘
-- bigWheel 大转盘逻辑
-- 创建轮盘
function CodeGameScreenCandyBingoMachine:createWheelView(func, func2)
    gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_show_wheel.mp3")

    local triggeRespinOver = func
    local changeSactter = func2

    -- self:resetMusicBg(nil,"CandyBingoSounds/music_CandyBingo_wheel_bg.mp3")
    local wheelData = self.m_runSpinResultData.p_selfMakeData.wheels
    local endIndex = self.m_runSpinResultData.p_selfMakeData.index

    local data = {}
    data.wheel = wheelData or {}
    data.endIndex = endIndex or 0

    self.m_whell = util_createView("CodeCandyBingoSrc.CandyBingoWheelView", data)
    self.m_whell:startAnimation()
    -- self:findChild("wheel"):addChild(self.m_whell )
    self.m_whell.getRotateBackScaleFlag = function()
        return false
    end

    gLobalViewManager:showUI(self.m_whell)
    local callback = function()
        if changeSactter then
            changeSactter()
        end

        self.m_whell:runCsbAction(
            "over",
            false,
            function()
                if triggeRespinOver then
                    triggeRespinOver()
                end

                -- 移除转盘
                self.m_whell:removeFromParent()
                self.m_whell = nil
            end
        )
    end

    self.m_whell:initCallBack(callback)
    self.m_whell:initWheelBg(self)
end

function CodeGameScreenCandyBingoMachine:getJackPotCoins()
    -- jackpot 的钱数相当于scatter将要变成的钱数
    local coins = self.m_runSpinResultData.p_selfMakeData.middleCoins or 0

    return coins
end

function CodeGameScreenCandyBingoMachine:updatJackPotLock(minBet)
    if self.m_betLevel == nil or self.m_betLevel ~= minBet then
        self.m_betLevel = minBet
        self.m_LittleBetView:stopAllActions()
        self.m_LittleBetView:setVisible(true)
        self.m_LittleBetView:updateScatterImg(self.m_betLevel)
        performWithDelay(
            self.m_LittleBetView,
            function()
                self.m_LittleBetView:setVisible(false)
            end,
            2
        )
    end
end

function CodeGameScreenCandyBingoMachine:getMinBet()
    local minBet = 0

    if not self.m_specialBets then
        --只有第一次获取服务器数据
        self.m_specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    end

    local betCoin = globalData.slotRunData:getCurTotalBet()

    for i = #self.m_specialBets, 1, -1 do
        local netBetCoins = self.m_specialBets[i].p_totalBetValue
        if betCoin >= netBetCoins then
            minBet = i
            break
        end
    end

    return minBet
end

--刷新从服务器获取的解锁特殊玩法bet值
function CodeGameScreenCandyBingoMachine:upateBetLevel()
    local minBet = self:getMinBet()

    self:updatJackPotLock(minBet)

    -- self.m_CandyBingoJackPotUnLockView:setVisible(true)
    -- self.m_CandyBingoJackPotUnLockView:runCsbAction("animation0",false,function(  )
    --     self.m_CandyBingoJackPotUnLockView:setVisible(false)
    -- end)
end

--jackpot相关
-- 更新jackpot 数值信息
--
function CodeGameScreenCandyBingoMachine:updateJackpotInfo()
    self:changeNode(self:findChild("Grand_num"), 1, true)

    local mini = self.m_CandyBingoRIGHTJackPotView:findChild("m_lb_mini")
    local minor = self.m_CandyBingoRIGHTJackPotView:findChild("m_lb_minor")
    local major = self.m_CandyBingoRIGHTJackPotView:findChild("m_lb_major")

    self:changeNode(major, 2, true)
    self:changeNode(minor, 3)
    self:changeNode(mini, 4)

    self:updateSize()
end

function CodeGameScreenCandyBingoMachine:updateSize()
    local label1 = self:findChild("Grand_num")
    local mini = self.m_CandyBingoRIGHTJackPotView:findChild("m_lb_mini")
    local minor = self.m_CandyBingoRIGHTJackPotView:findChild("m_lb_minor")
    local major = self.m_CandyBingoRIGHTJackPotView:findChild("m_lb_major")

    local other_scale = 0.8
    local other_length = 300

    local info1 = {label = label1, sx = 1.2, sy = 1.2}

    local info2 = {label = major, sx = other_scale, sy = other_scale}
    local info3 = {label = minor, sx = other_scale, sy = other_scale}
    local info4 = {label = mini, sx = other_scale, sy = other_scale}

    self:updateLabelSize(info1, 461)

    self:updateLabelSize(info2, other_length)
    self:updateLabelSize(info3, other_length)
    self:updateLabelSize(info4, other_length)
end

function CodeGameScreenCandyBingoMachine:changeNode(label, index, isJump)
    local value = self:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 20))
end

-- 连线问题
---
-- 将SlotNode 提升层级到遮罩层以上
--
function CodeGameScreenCandyBingoMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode
end

-- 创建一个reels上层的特殊显示信号信号
function CodeGameScreenCandyBingoMachine:createOneActionSymbol(endNode, actionName, signNode, Spine, callBackFunc, hide, _loopname)
    if not endNode or not endNode.m_ccbName then
        return
    end

    local fatherNode = endNode
    -- endNode:setVisible(true)
    local fathersignNode = signNode

    if fathersignNode then
    -- fathersignNode:setVisible(true)
    end
    local isSpine = Spine
    local ishide = hide
    local LoopName = _loopname
    local node = nil
    local callFunc = callBackFunc

    if isSpine then
        node = util_spineCreate(endNode.m_ccbName, true, true)
    else
        node = util_createAnimation(endNode.m_ccbName .. ".csb")
    end

    local func = function()
        -- if fatherNode then
        --     fatherNode:setVisible(true)
        -- end
        -- if fathersignNode then
        --     fathersignNode:setVisible(true)
        -- end

        print("回调------------------- LoopName   ")
        if LoopName then
            print("回调------------------- LoopName   " .. LoopName)
            if isSpine then
                util_spinePlay(node, LoopName, true)
                print("bofang   " .. LoopName)
            else
                node:playAction(LoopName, true)
            end
        end

        print("回调-------------------   ")

        if callFunc then
            callFunc()
        end
    end

    if isSpine then
        print("回调------------------- isSpine   ")
        util_spinePlay(node, actionName, false)
        local node2 = node

        util_spineEndCallFunc(
            node,
            actionName,
            function()
                if node2 then
                    if ishide then
                        node2:setVisible(false)
                    end
                end

                if func then
                    func()
                end
            end
        )
    else
        node:playAction(actionName, false, func)
    end

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("Node_lunpan_2"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    self:findChild("Node_lunpan_2"):addChild(node, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + endNode.p_rowIndex)
    node:setPosition(pos)
    local data = {}
    data.node = node
    data.fatherNode = fatherNode
    data.fathersignNode = fathersignNode

    table.insert(self.m_ActionNodeList, data)

    return node
end

-- 创建一个reels上层的特殊显示信号信号
function CodeGameScreenCandyBingoMachine:createOneChipActionSymbol(endNode, actionName, signNode, Spine, callBackFunc, hide, _loopname, score)
    if not endNode or not endNode.m_ccbName then
        return
    end

    local fatherNode = endNode
    -- endNode:setVisible(true)
    local fathersignNode = signNode

    if fathersignNode then
    -- fathersignNode:setVisible(true)
    end
    local isSpine = Spine
    local ishide = hide
    local LoopName = _loopname
    local node = nil
    local callFunc = callBackFunc

    if isSpine then
        node = util_spineCreate(endNode.m_ccbName, true, true)
    else
        node = util_createAnimation(endNode.m_ccbName .. ".csb")
    end

    local func = function()
        -- if fatherNode then
        --     fatherNode:setVisible(true)
        -- end
        -- if fathersignNode then
        --     fathersignNode:setVisible(true)
        -- end

        if node then
            node:setVisible(false)
        end

        print("回调------------------- LoopName   ")
        if LoopName then
            print("回调------------------- LoopName   " .. LoopName)
            if isSpine then
                util_spinePlay(node, LoopName, true)
                print("bofang   " .. LoopName)
            else
                node:playAction(LoopName, true)
            end
        end

        print("回调-------------------   ")

        if callFunc then
            callFunc()
        end
    end

    if isSpine then
        print("回调------------------- isSpine   ")
        util_spinePlay(node, actionName, false)
        local node2 = node

        util_spineEndCallFunc(
            node,
            actionName,
            function()
                if node2 then
                    if ishide then
                        node2:setVisible(false)
                    end
                end

                if func then
                    func()
                end
            end
        )
    else
        node:playAction(actionName, false, func)
    end

    if not isSpine then
        if score then
            local lab = node:findChild("m_lb_score")
            if lab then
                lab:setString(util_formatCoins(score, 3))
            end

            local lab10 = node:findChild("m_lb_score_10")
            if lab10 then
                lab10:setString(util_formatCoins(score, 3))
            end
        end
    end

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("Node_lunpan_2"):convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
    self:findChild("Node_lunpan_2"):addChild(node, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + endNode.p_rowIndex - 6)
    node:setPosition(pos)
    local data = {}
    data.node = node
    data.fatherNode = fatherNode
    data.fathersignNode = fathersignNode

    table.insert(self.m_ActionNodeList, data)

    return node
end

function CodeGameScreenCandyBingoMachine:dealActionNodeVisible(isShow)
    for k, v in pairs(self.m_ActionNodeList) do
        local data = v
        if data.node then
            data.node:setVisible(isShow)
        end
    end
end

function CodeGameScreenCandyBingoMachine:removeAllActionNode(hide)
    for k, v in pairs(self.m_ActionNodeList) do
        local data = v
        if data.node then
            if hide then
                data.node:setVisible(false)
            end
            data.node:removeFromParent()
        end
    end

    self.m_ActionNodeList = {}
end

-- 创建飞行粒子
function CodeGameScreenCandyBingoMachine:createCandyBingoFly(startPos, endPos, time, posCol, posRow, func)
    local fly = util_createView("CodeCandyBingoSrc.CandyBingoParticleFly")
    fly:setPosition(startPos)
    self.m_root:addChild(fly, 300000)
    fly:setName("flyCollect_" .. self.m_moveIndex)

    fly:findChild("Particle_1"):setDuration(time)
    fly:findChild("Particle_2"):setDuration(time)

    local animation = {}

    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos))
    animation[#animation + 1] =
        cc.CallFunc:create(
        function()
            if func then
                func()
            end
            performWithDelay(
                fly,
                function()
                    fly:removeFromParent()
                end,
                0.5
            )
        end
    )
    fly:runAction(cc.Sequence:create(animation))
end

-- 中了bonus游戏后需要进行的两次动画效果
function CodeGameScreenCandyBingoMachine:moveTopNodeToBigReels(func)
    gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_BonusReels_goDown.mp3")

    local movetime = 1

    self:findChild("zhezhaoSmallReels"):setVisible(true)
    self:findChild("zhezhaoBigReels"):setVisible(true)

    self:findChild("Node_lunpan_1"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 111)

    for k, v in pairs(self.m_bonusReelsNodeList) do
        local node = v
        local bigNodePos = self:getBigNodePosByColAndRow(node.iRow, node.iCol)
        local endPosWord = self:findChild("Node_lunpan_2"):convertToWorldSpace(cc.p(bigNodePos))
        local endPos = cc.p(self:findChild("Node_1_0"):convertToNodeSpace(endPosWord))

        local animation = {}
        animation[#animation + 1] =
            cc.CallFunc:create(
            function()
                local sacleAnimation = {}
                sacleAnimation[#sacleAnimation + 1] = cc.ScaleTo:create(movetime, 1.54)
                node:runAction(cc.Sequence:create(sacleAnimation))
            end
        )
        animation[#animation + 1] = cc.MoveTo:create(movetime, cc.p(endPos))

        node:runAction(cc.Sequence:create(animation))
    end

    self:findChild("Node_lunpan_1_0"):setVisible(true)
    local bgNodePos = cc.p(self:findChild("Node_lunpan_2"):getPosition())
    local bgendPosWord = self:findChild("Node_lunpan_2"):getParent():convertToWorldSpace(cc.p(bgNodePos))
    local bgendPos = cc.p(self:findChild("Node_1_0"):convertToNodeSpace(bgendPosWord))

    local bgendPos = cc.p(0, -689)

    local bganimation = {}
    bganimation[#bganimation + 1] =
        cc.CallFunc:create(
        function()
            local bgsacleAnimation = {}
            bgsacleAnimation[#bgsacleAnimation + 1] = cc.ScaleTo:create(movetime, 1.54)
            self:findChild("Node_lunpan_1_0"):runAction(cc.Sequence:create(bgsacleAnimation))
        end
    )
    bganimation[#bganimation + 1] = cc.MoveTo:create(movetime, cc.p(bgendPos))
    self:findChild("Node_lunpan_1_0"):runAction(cc.Sequence:create(bganimation))

    local bgendPos2 = cc.p(0, -689)
    local zhezahoanimation = {}
    zhezahoanimation[#zhezahoanimation + 1] =
        cc.CallFunc:create(
        function()
            local zhezhaosacleAnimation = {}
            zhezhaosacleAnimation[#zhezhaosacleAnimation + 1] = cc.ScaleTo:create(movetime, 1.54)
            self:findChild("zhezhaoSmallReels"):runAction(cc.Sequence:create(zhezhaosacleAnimation))
        end
    )
    zhezahoanimation[#zhezahoanimation + 1] = cc.MoveTo:create(movetime, cc.p(bgendPos2))
    self:findChild("zhezhaoSmallReels"):runAction(cc.Sequence:create(zhezahoanimation))

    local bgactanimation = {}
    bgactanimation[#bgactanimation + 1] =
        cc.CallFunc:create(
        function()
            local bgactsacleAnimation = {}
            bgactsacleAnimation[#bgactsacleAnimation + 1] = cc.ScaleTo:create(movetime, 1.54)
            self:findChild("animationTopBg11"):runAction(cc.Sequence:create(bgactsacleAnimation))
        end
    )
    bgactanimation[#bgactanimation + 1] = cc.MoveTo:create(movetime, cc.p(bgendPos))
    self:findChild("animationTopBg11"):runAction(cc.Sequence:create(bgactanimation))

    performWithDelay(
        self,
        function()
            self:setReelSlotsNodeVisible(false)
            self:dealActionNodeVisible(false)

            performWithDelay(
                self,
                function()
                    if func then
                        func()
                    end
                end,
                0.5
            )
        end,
        movetime
    )
end

function CodeGameScreenCandyBingoMachine:fadeOutTopNode(func)
    local movetime = 0.5

    for k, v in pairs(self.m_bonusReelsNodeList) do
        local node = v
        local endPos = self:getBigNodePosByColAndRow(node.iRow, node.iCol, true)

        local hideeAnimation = {}
        hideeAnimation[#hideeAnimation + 1] = cc.FadeOut:create(movetime)
        hideeAnimation[#hideeAnimation + 1] =
            cc.CallFunc:create(
            function()
                -- if node.p_symbolType and node.p_symbolType ~= self.Socre_CandyBingo_Special_Scatter then
                node:setVisible(false)
                -- end

                node:setOpacity(255)
            end
        )
        node:runAction(cc.Sequence:create(hideeAnimation))
    end

    local bghideeAnimation = {}
    bghideeAnimation[#bghideeAnimation + 1] = cc.FadeOut:create(movetime)
    bghideeAnimation[#bghideeAnimation + 1] =
        cc.CallFunc:create(
        function()
            self:findChild("Node_lunpan_1_0"):setOpacity(255)
        end
    )

    self:findChild("Node_lunpan_1_0"):runAction(cc.Sequence:create(bghideeAnimation))

    local zhezhaohideeAnimation = {}
    zhezhaohideeAnimation[#zhezhaohideeAnimation + 1] = cc.FadeOut:create(movetime)
    zhezhaohideeAnimation[#zhezhaohideeAnimation + 1] =
        cc.CallFunc:create(
        function()
            self:findChild("zhezhaoSmallReels"):setOpacity(255)
        end
    )

    self:findChild("zhezhaoSmallReels"):runAction(cc.Sequence:create(zhezhaohideeAnimation))

    performWithDelay(
        self,
        function()
            if func then
                func()
            end
        end,
        movetime + 0.1
    )
end

function CodeGameScreenCandyBingoMachine:moveTopNodeToTopReels(func)
    gLobalSoundManager:playSound("CandyBingoSounds/sound_CandyBingo_Bonus_game_over.mp3")

    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_lunpan_1"), true)

    local movetime = 0.5

    self:findChild("zhezhaoSmallReels"):setVisible(true)
    self:findChild("zhezhaoBigReels"):setVisible(false)

    for k, v in pairs(self.m_bonusReelsNodeList) do
        local node = v
        local endPos = self:getBigNodePosByColAndRow(node.iRow, node.iCol, true)

        local animation = {}
        animation[#animation + 1] =
            cc.CallFunc:create(
            function()
                local sacleAnimation = {}
                sacleAnimation[#sacleAnimation + 1] =
                    cc.CallFunc:create(
                    function()
                        -- local hideeAnimation = {}
                        -- hideeAnimation[#hideeAnimation + 1] = cc.FadeOut:create(movetime)
                        -- hideeAnimation[#hideeAnimation + 1] = cc.CallFunc:create(function(  )
                        --     -- if node.p_symbolType and node.p_symbolType ~= self.Socre_CandyBingo_Special_Scatter then
                        --         node:setVisible(false)
                        --     -- end
                        --     node:setOpacity(255)
                        -- end)
                        -- node:runAction(cc.Sequence:create(hideeAnimation))
                    end
                )
                sacleAnimation[#sacleAnimation + 1] = cc.ScaleTo:create(movetime, 1)
                node:runAction(cc.Sequence:create(sacleAnimation))
            end
        )
        animation[#animation + 1] = cc.MoveTo:create(movetime, cc.p(endPos))
        node:runAction(cc.Sequence:create(animation))
    end

    local bganimation = {}
    bganimation[#bganimation + 1] =
        cc.CallFunc:create(
        function()
            local bgsacleAnimation = {}
            bgsacleAnimation[#bgsacleAnimation + 1] =
                cc.CallFunc:create(
                function()
                    -- local bghideeAnimation = {}
                    -- bghideeAnimation[#bghideeAnimation + 1] = cc.FadeOut:create(movetime)
                    -- bghideeAnimation[#bghideeAnimation + 1] = cc.CallFunc:create(function(  )
                    --     self:findChild("Node_lunpan_1_0"):setOpacity(255)
                    -- end)
                    -- self:findChild("Node_lunpan_1_0"):runAction(cc.Sequence:create(bghideeAnimation))
                end
            )
            bgsacleAnimation[#bgsacleAnimation + 1] = cc.ScaleTo:create(movetime, 1)
            self:findChild("Node_lunpan_1_0"):runAction(cc.Sequence:create(bgsacleAnimation))
        end
    )
    bganimation[#bganimation + 1] = cc.MoveTo:create(movetime, cc.p(0, 0))
    self:findChild("Node_lunpan_1_0"):runAction(cc.Sequence:create(bganimation))

    local zhezahoanimation = {}
    zhezahoanimation[#zhezahoanimation + 1] =
        cc.CallFunc:create(
        function()
            local zhezhaosacleAnimation = {}
            zhezhaosacleAnimation[#zhezhaosacleAnimation + 1] =
                cc.CallFunc:create(
                function()
                    -- local zhezhaohideeAnimation = {}
                    -- zhezhaohideeAnimation[#zhezhaohideeAnimation + 1] = cc.FadeOut:create(movetime)
                    -- zhezhaohideeAnimation[#zhezhaohideeAnimation + 1] = cc.CallFunc:create(function(  )
                    --     self:findChild("zhezhaoSmallReels"):setOpacity(255)
                    -- end)
                    -- self:findChild("zhezhaoSmallReels"):runAction(cc.Sequence:create(zhezhaohideeAnimation))
                end
            )
            zhezhaosacleAnimation[#zhezhaosacleAnimation + 1] = cc.ScaleTo:create(movetime, 1)
            self:findChild("zhezhaoSmallReels"):runAction(cc.Sequence:create(zhezhaosacleAnimation))
        end
    )
    zhezahoanimation[#zhezahoanimation + 1] = cc.MoveTo:create(movetime, cc.p(0, 0))
    self:findChild("zhezhaoSmallReels"):runAction(cc.Sequence:create(zhezahoanimation))

    local bgactanimation = {}
    bgactanimation[#bgactanimation + 1] =
        cc.CallFunc:create(
        function()
            local bgactsacleAnimation = {}
            bgactsacleAnimation[#bgactsacleAnimation + 1] = cc.ScaleTo:create(movetime, 1)
            self:findChild("animationTopBg11"):runAction(cc.Sequence:create(bgactsacleAnimation))
        end
    )
    bgactanimation[#bgactanimation + 1] = cc.MoveTo:create(movetime, cc.p(0, 0))
    self:findChild("animationTopBg11"):runAction(cc.Sequence:create(bgactanimation))

    performWithDelay(
        self,
        function()
            self:findChild("zhezhaoSmallReels"):setVisible(false)
            self:findChild("zhezhaoSmallReels"):setVisible(false)
            self.m_CandyBingoReelsMoveBg:setVisible(false)
            self.m_CandyBingoReelsMoveBg:runCsbAction("over")
            self:findChild("Node_lunpan_1_0"):setVisible(false)
            self:fadeOutTopNode(
                function()
                    self:findChild("Node_lunpan_1"):setLocalZOrder(1)

                    if func then
                        func()
                    end
                end
            )
        end,
        movetime + 0.1
    )
end

function CodeGameScreenCandyBingoMachine:setBonusWinCosin()
    local bonusLines = self.m_bonusReelsBingoLinesData or {} -- bonus连线信息
    local scatterScore = self.m_runSpinResultData.p_selfMakeData.middleCoins or 0

    local sumScore = 0
    local courtTimes = 0
    for k, v in pairs(bonusLines) do
        local oneBingoLine = v
        for kk, vk in pairs(oneBingoLine) do
            local index = tonumber(vk)
            local Score = 0
            local smallReelsNode = self:getSmallReelsNodeFromIndex(index)
            if smallReelsNode then
                Score = self.m_bonusReelsData[6 - smallReelsNode.iRow][smallReelsNode.iCol]
                -- scatter 在bingo线上时特殊处理
                if Score == -1 then
                    Score = scatterScore
                end

                sumScore = sumScore + Score
            end
        end
    end

    self.m_BonusCollectSumScore = sumScore
end

function CodeGameScreenCandyBingoMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end

    local currtCoins = self.m_iOnceSpinLastWin - self.m_BonusCollectSumScore
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if self.m_BonusCollectSumScore > 0 then
        if self.m_bProduceSlots_InFreeSpin then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
        else
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {currtCoins, isNotifyUpdateTop})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        end
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
    end
end

---
-- 增加赢钱后的 效果
function CodeGameScreenCandyBingoMachine:addLastWinSomeEffect() -- add big win or mega win
    if #self.m_vecGetLineInfo == 0 then
        return
    end

    self.m_bIsBigWin = false
    self.m_llBigWinCoinNum = 0

    local currtCoins = self.m_iOnceSpinLastWin - self.m_BonusCollectSumScore

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    self.m_fLastWinBetNumRatio = currtCoins / lTatolBetNum --最后赢得金币总数 除以 压得赌注的总数 的值

    local iBigWinLimit = self.m_BigWinLimitRate
    local iMegaWinLimit = self.m_MegaWinLimitRate
    local iEpicWinLimit = self.m_HugeWinLimitRate
    local iLegendaryLimit = self.m_LegendaryWinLimitRate
    local curWinType = WinType.Normal
    if self.m_fLastWinBetNumRatio >= iLegendaryLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_LEGENDARY)
        self.m_llBigOrMegaNum = self.m_iOnceSpinLastWin
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iEpicWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_EPICWIN)
        self.m_llBigOrMegaNum = currtCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iMegaWinLimit then
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_MEGAWIN) -- 只显示bigwin wuxi  2017-12-22 14:52:19
        self.m_llBigOrMegaNum = currtCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio >= iBigWinLimit then -- 判断是否是 bigwin
        curWinType = WinType.BigWin

        self:addAnimationOrEffectType(GameEffect.EFFECT_BIGWIN)
        self.m_llBigOrMegaNum = currtCoins
        self.m_bIsBigWin = true
    elseif self.m_fLastWinBetNumRatio > 0 and self.m_fLastWinBetNumRatio < iBigWinLimit then -- 判断是否小赢
        self:addAnimationOrEffectType(GameEffect.EFFECT_NORMAL_WIN)
    end
    if self.m_bIsBigWin then
        self.m_llBigOrMegaNum = currtCoins
    end

    --判断当前是否有big win或者 mega win  将five of kind 挪掉
    if self:checkHasEffectType(GameEffect.EFFECT_BIGWIN) == true or self:checkHasEffectType(GameEffect.EFFECT_MEGAWIN) == true or self.m_fLastWinBetNumRatio < 1 then --如果赢取倍数小于等于total bet 的1倍
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
    end
end

--[[
    @desc: bonus 结束后检测是否触发Bonus
    time:2018-11-14 16:18:43
    --@winAmonut: bonus 结束赢取的钱
]]
function CodeGameScreenCandyBingoMachine:checkFeatureOverTriggerBigWin(winAmonut, feature, selfType)
    if winAmonut == nil then
        return
    end

    if self:featureOverTriggerBigWinSpecCheck(feature) then
        return
    end

    local lTatolBetNum = globalData.slotRunData:getCurTotalBet()
    if self.getNewBingWinTotalBet then
        lTatolBetNum = self:getNewBingWinTotalBet()
    end
    local winRatio = winAmonut / lTatolBetNum
    local winEffect = nil
    if winRatio >= self.m_LegendaryWinLimitRate then
        winEffect = GameEffect.EFFECT_LEGENDARY
    elseif winRatio >= self.m_HugeWinLimitRate then
        winEffect = GameEffect.EFFECT_EPICWIN
    elseif winRatio >= self.m_MegaWinLimitRate then
        winEffect = GameEffect.EFFECT_MEGAWIN
    elseif winRatio >= self.m_BigWinLimitRate then
        winEffect = GameEffect.EFFECT_BIGWIN
    end

    if winEffect ~= nil then
        local isAddEffect = false

        if feature and selfType then
            -- 添加这一关的特殊大赢

            for i = 1, #self.m_gameEffects do
                local effectData = self.m_gameEffects[i]
                if effectData.p_selfEffectType and effectData.p_selfEffectType == selfType then
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
        else
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
    end
    self:checkQuestAddDelayBigWin()
    self:addQuestCompleteTipEffect()
    self:checkQuestDoneGameEffect()
end

function CodeGameScreenCandyBingoMachine:checkShowChooseBetView()
    local features = self.m_runSpinResultData.p_features or {}
    local isShow = true

    for k, v in pairs(features) do
        if v == 1 then --触发freespin时
            isShow = false
        elseif v == 3 then -- 触发respin时
            isShow = false
        end
    end

    -- 在freespin玩法中
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        isShow = false
    end

    -- 在respin玩法中
    if self:getCurrSpinMode() == RESPIN_MODE then
        isShow = false
    end

    -- autospin
    if self:getCurrSpinMode() == AUTO_SPIN_MODE then
        isShow = false
    end

    return isShow
end

function CodeGameScreenCandyBingoMachine:showHightLowBetView()
    if self:getBetLevel() ~= 2 then
        self.m_hightLowbetView:setVisible(true)
        self.m_hightLowbetView:initMachine(self)
        self.m_hightLowbetView:initMachineBetDate()
    end
end

function CodeGameScreenCandyBingoMachine:getAnimNodeFromPool(symbolType, ccbName)
    if not symbolType then
        release_print("AnimNodeFromPool error not symbolType!!!    ccbName:" .. ccbName)
        return nil
    end
    if ccbName == nil then
        ccbName = self:getSymbolCCBNameByType(self, symbolType)
    end

    local reelPool = self.m_reelAnimNodePool[symbolType]
    if reelPool == nil then
        reelPool = {}
        self.m_reelAnimNodePool[symbolType] = reelPool
    end

    if #reelPool == 0 then
        -- 扩展支持 spine 的元素
        local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
        local node = nil
        if spineSymbolData ~= nil then
            node = SlotsSpineAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:initSpineInfo(spineSymbolData[1], spineSymbolData[2])
            node:runDefaultAnim()
        else
            node = SlotsAnimNode:create()
            node:retain()
            node:loadCCBNode(ccbName, symbolType)
            node:runDefaultAnim()
        end

        return node
    else
        local node = reelPool[1] -- 存内存池取出来
        table.remove(reelPool, 1)
        node:runDefaultAnim()

        if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            local spineSymbolData = self.m_configData:getSpineSymbol(symbolType)
            if spineSymbolData ~= nil then
                node:removeAllChildren()
                node:loadCCBNode(ccbName, symbolType)
                node:initSpineInfo(spineSymbolData[1], spineSymbolData[2])
                node:runDefaultAnim()
            else
                node:removeAllChildren()
                node = SlotsAnimNode:create()
                node:loadCCBNode(ccbName, symbolType)
                node:runDefaultAnim()
            end
        end

        return node
    end
end
function CodeGameScreenCandyBingoMachine:checkHasBigSymbolWithNetWork()
    local lastNodeIsBigSymbol = false
    local maxDiff = 0
    for i = 1, #self.m_slotParents do
        local columnData = self.m_reelColDatas[i]
        local halfH = columnData.p_showGridH * 0.5

        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local slotParentBig = parentData.slotParentBig
        local moveL = self.m_reelRunInfo[i]:getReelRunLen() * columnData.p_showGridH
        -- print(i .. "列，不考虑补偿计算的移动距离 " ..  moveL)
        local childs = slotParent:getChildren()
        if slotParentBig then
            local newChilds = slotParentBig:getChildren()
            for j = 1, #newChilds do
                childs[#childs + 1] = newChilds[j]
            end
        end
        local preY = 0
        local isLastBigSymbol = false

        -- printInfo(" updateNetWork %d ,, col=%d " , #childs , i)

        for childIndex = 1, #childs do
            local child = childs[childIndex]
            local isVisible = child:isVisible()
            local childY = child:getPositionY()
            local topY = nil
            local nodeH = child.p_slotNodeH or 144
            if self.m_bigSymbolInfos[child.p_symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[child.p_symbolType]
                topY = childY + (symbolCount - 0.5) * self.m_SlotNodeH
                isLastBigSymbol = true
            else
                topY = childY + nodeH * 0.5
                isLastBigSymbol = false
            end

            if topY < preY and isLastBigSymbol == false then
                isLastBigSymbol = false
            end

            preY = util_max(preY, topY)
        end
        if isLastBigSymbol == true then
            lastNodeIsBigSymbol = true
        end
        local parentY = slotParent:getPositionY()
        -- 按照逻辑处理来说， 各列的moveDiff非长条模式是相同的，长条模式需要将剩余的补齐
        local moveDiff = preY + parentY - columnData.p_slotColumnHeight --self.m_fReelHeigth
        if #childs == 0 then -- 表明这一列并未参与滚动， 先这么写吧后续考虑修改
            moveDiff = 0
        end
        moveL = moveL + moveDiff

        parentData.moveDistance = parentY - moveL
        parentData.moveL = moveL
        parentData.moveDiff = moveDiff
        parentData.preY = preY

        maxDiff = util_max(maxDiff, math.abs(moveDiff))

        -- self:createSlotNextNode(parentData)
    end

    return lastNodeIsBigSymbol, maxDiff
end

function CodeGameScreenCandyBingoMachine:dealSmallReelsSpinStates()
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true})
            waitNode:removeFromParent()
        end,
        0
    )
end

function CodeGameScreenCandyBingoMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("gameBg"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)

    self.m_gameBg = gameBg
end

function CodeGameScreenCandyBingoMachine:isShowChooseBetOnEnter()
    return self:getBetLevel() ~= 2
end

return CodeGameScreenCandyBingoMachine
