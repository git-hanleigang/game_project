---
-- island li
-- 2019年1月26日
-- CodeGameScreenDragonsMachine.lua
--
-- 玩法：
--

local SlotParentData = require "data.slotsdata.SlotParentData"
local BaseFastMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"

local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SlotsNode = require "Levels.SlotsNode"
local BaseDialog = util_require("Levels.BaseDialog")
local BaseMachine = require "Levels.BaseMachine"

local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local CodeGameScreenDragonsMachine = class("CodeGameScreenDragonsMachine", BaseFastMachine)
CodeGameScreenDragonsMachine.freespinData = {{10, 15, 30}, {8, 10, 15}, {5, 8, 10}, {3, 5, 8}, {2, 3, 5}, {2, 3, 5, 8, 10, 15, 30}}
CodeGameScreenDragonsMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenDragonsMachine.SYMBOL_SCORE_10 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 1
CodeGameScreenDragonsMachine.SYMBOL_SCORE_11 = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 + 2
--wild 1
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD1101 = 1101
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD1102 = 1102
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD1103 = 1103
--wild 2
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD2101 = 2101
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD2102 = 2102
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD2103 = 2103
--wild 3
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD3101 = 3101
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD3102 = 3102
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD3103 = 3103
--wild 4
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD4101 = 4101
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD4102 = 4102
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD4103 = 4103
--wild 5
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD5101 = 5101
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD5102 = 5102
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD5103 = 5103
--wild 6
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD6101 = 6101
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD6102 = 6102
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD6103 = 6103
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD6104 = 6104
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD6105 = 6105
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD6106 = 6106
CodeGameScreenDragonsMachine.SYMBOL_SCORE_WILD6107 = 6107

-- CodeGameScreenDragonsMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenDragonsMachine.CHOOSE_FREESPIN_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识
CodeGameScreenDragonsMachine.ADD_FREESPIN_NUM_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2
CodeGameScreenDragonsMachine.PLAY_DRAGONS_BALL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3

local FIT_HEIGHT_MAX = 1250
local FIT_HEIGHT_MIN = 1136

-- 构造函数
function CodeGameScreenDragonsMachine:ctor()
    BaseFastMachine.ctor(self)
    self.m_playDragonsEffect = false
    self.m_isOnceClipNode = false --是否只绘制一个矩形裁切 --小矮仙 袋鼠等不规则或者可变高度设置成false
    self.m_isFeatureOverBigWinInFree = true

    --init
    self:initGame()
end

function CodeGameScreenDragonsMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("DragonsConfig.csv", "LevelDragonsConfig.lua")
    self.m_configData:initMachine(self)
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenDragonsMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "Dragons"
end

function CodeGameScreenDragonsMachine:initUI()
    self:initFreeSpinBar() -- FreeSpinbar

    --jackpot
    self.m_jackPotBar = util_createView("CodeDragonsSrc.DragonsJackPotBarView", self)
    self:findChild("jackpot"):addChild(self.m_jackPotBar)

    --龙头
    self.m_dragonsHead = util_spineCreate("Dragons_longtou", true, true)
    self:findChild("longtou"):addChild(self.m_dragonsHead)
    util_spinePlay(self.m_dragonsHead, "idle", true)
    --龙珠背景
    self.m_dragonsBallBg = util_createView("CodeDragonsSrc.DragonsBallBgView")
    self:findChild("longzhuBg"):addChild(self.m_dragonsBallBg)
    self.m_dragonsBallBg:setVisible(false)
    --龙珠
    self.m_dragonsBall = util_spineCreate("Dragons_longzhu", true, true)
    self:findChild("longzhu"):addChild(self.m_dragonsBall, 1)
    util_spinePlay(self.m_dragonsBall, "idle", true)
    self.m_dragonsBall:setVisible(false)
    --龙珠字
    self.m_dragonsBallLab = util_createView("CodeDragonsSrc.DragonsBallWildLabView")
    self:findChild("longzhu"):addChild(self.m_dragonsBallLab, 2)
    self.m_dragonsBallLab:setVisible(false)

    -- DragonsBallBgView
    -- self:createDragonsWheelView()
    -- -- 创建大转盘
    self.m_guochang = util_spineCreate("Dragons_guochang", true, true)
    self:addChild(self.m_guochang, ViewZorder.ZORDER_UI - 1)
    self.m_guochang:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochang:setVisible(false)

    self.m_guochang2 = util_spineCreate("Dragons_guochang2", true, true)
    self:addChild(self.m_guochang2, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT - 2)
    self.m_guochang2:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochang2:setVisible(false)

    self.m_guochang3 = util_spineCreate("Dragons_guochang3", true, true)
    self:addChild(self.m_guochang3, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT - 2)
    self.m_guochang3:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_guochang3:setVisible(false)
    -- util_spinePlay(self.m_guochang2, "actionframe", true)
    self:runCsbAction("idle1")
    self:changeNormalAndFreespinReel(6)
    self.m_RunDi = {}
    for i = 1, 5 do
        local longRunDi
        if i == 1 or i == 5 then
            longRunDi = util_createAnimation("WinFrameDragons_run1_bg.csb")
        else
            longRunDi = util_createAnimation("WinFrameDragons_run2_bg.csb")
        end
        self:findChild("Node_reel"):addChild(longRunDi, 1)
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_" .. (i - 1)):getPosition()))
        longRunDi:setVisible(false)
        table.insert(self.m_RunDi, longRunDi)
    end

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
            local soundIndex = 1
            local soundTime = 1
            if winRate < 1 then
                soundIndex = 1
                soundTime = 2
            elseif winRate >= 1 and winRate < 3 then
                soundIndex = 2
                soundTime = 2
            else
                soundIndex = 3
                soundTime = 3
            end
            local soundName = "DragonsSounds/sound_Dragons_last_win" .. soundIndex .. ".mp3"
            self.m_winSoundsId =globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        end,
        ViewEventType.NOTIFY_UPDATE_WINCOIN
    )
end

function CodeGameScreenDragonsMachine:updateJackpot()
    self.m_jackPotBar:updateJackpotInfo()
end

--初始freespin tips
function CodeGameScreenDragonsMachine:initFreeSpinBar()
    local node_bar = self:findChild("juanzhou")
    self.m_baseFreeSpinBar = util_createView("CodeDragonsSrc.DragonsFreespinBarView")
    node_bar:addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
    self.m_baseFreeSpinBar:setPosition(0, 0)
end

function CodeGameScreenDragonsMachine:showFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    self.m_baseFreeSpinBar:setVisible(true)
end

function CodeGameScreenDragonsMachine:hideFreeSpinBar()
    if not self.m_baseFreeSpinBar then
        return
    end
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end

function CodeGameScreenDragonsMachine:enterGamePlayMusic()
    scheduler.performWithDelayGlobal(
        function()
            gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_enter.mp3")
            scheduler.performWithDelayGlobal(
                function()
                    if not self.m_bIsInBonusGame then
                        self:resetMusicBg()
                        self:setMinMusicBGVolume()
                    else
                        self.m_currentMusicBgName = "DragonsSounds/music_Dragons_wheel.mp3"
                        self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
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

function CodeGameScreenDragonsMachine:stopMusicBg()
    self:clearCurMusicBg()
end

function CodeGameScreenDragonsMachine:playWheelBg()
    self.m_currentMusicBgName = "DragonsSounds/music_Dragons_wheel.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

function CodeGameScreenDragonsMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function CodeGameScreenDragonsMachine:addObservers()
    BaseFastMachine.addObservers(self)
end

function CodeGameScreenDragonsMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseFastMachine.onExit(self) -- 必须调用不予许删除
    self:removeObservers()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenDragonsMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_SCORE_11 then
        return "Socre_Dragons_11"
    elseif symbolType == self.SYMBOL_SCORE_10 then
        return "Socre_Dragons_10"
    elseif symbolType == -1000 then
        return "Socre_Dragons_1"
    elseif symbolType == self.SYMBOL_SCORE_WILD1101 or symbolType == self.SYMBOL_SCORE_WILD1102 or symbolType == self.SYMBOL_SCORE_WILD1103 then
        return "Socre_Dragons_Wild_5"
    elseif symbolType == self.SYMBOL_SCORE_WILD2101 or symbolType == self.SYMBOL_SCORE_WILD2102 or symbolType == self.SYMBOL_SCORE_WILD2103 then
        return "Socre_Dragons_Wild_4"
    elseif symbolType == self.SYMBOL_SCORE_WILD3101 or symbolType == self.SYMBOL_SCORE_WILD3102 or symbolType == self.SYMBOL_SCORE_WILD3103 then
        return "Socre_Dragons_Wild_3"
    elseif symbolType == self.SYMBOL_SCORE_WILD4101 or symbolType == self.SYMBOL_SCORE_WILD4102 or symbolType == self.SYMBOL_SCORE_WILD4103 then
        return "Socre_Dragons_Wild_2"
    elseif symbolType == self.SYMBOL_SCORE_WILD5101 or symbolType == self.SYMBOL_SCORE_WILD5102 or symbolType == self.SYMBOL_SCORE_WILD5103 then
        return "Socre_Dragons_Wild_1"
    elseif
        symbolType == self.SYMBOL_SCORE_WILD6101 or symbolType == self.SYMBOL_SCORE_WILD6102 or symbolType == self.SYMBOL_SCORE_WILD6103 or symbolType == self.SYMBOL_SCORE_WILD6104 or
            symbolType == self.SYMBOL_SCORE_WILD6105 or
            symbolType == self.SYMBOL_SCORE_WILD6106 or
            symbolType == self.SYMBOL_SCORE_WILD6107
     then
        return "Socre_Dragons_Wild_6"
    end

    return nil
end

--小块
function CodeGameScreenDragonsMachine:getBaseReelGridNode()
    return "CodeDragonsSrc.DragonsSlotsNode"
end


function CodeGameScreenDragonsMachine:scaleMainLayer()
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
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
    if display.width / display.height >= 768 / 1024 then
        local mainScale = 0.67
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self:findChild("chooseNode"):setPositionY(self:findChild("chooseNode"):getPositionY() - 45)
    end

    if display.height > 1024 and  display.height <= 1034 then
        local mainScale = self.m_machineRootScale + 0.02
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
    end

    if globalData.slotRunData.isPortrait then
        local bangHeight = util_getBangScreenHeight()
        local bottomHeight = util_getSaveAreaBottomHeight()
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + bottomHeight - bangHeight)
    end
end

function CodeGameScreenDragonsMachine:changeViewNodePos()
    local headPosHeight = 0
    if display.height > FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro > 2 and pro < 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 120)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 170)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 170)
            headPosHeight = 90
        elseif pro >= 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 140)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 220)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 240)
            headPosHeight = 120
        elseif pro < 2 and pro > 1.867 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 75)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 140)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 140)
            headPosHeight = 70
        elseif pro <= 1.867 and pro > 1.6 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 10)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 10)
            self:findChild("chooseNode"):setPositionY(self:findChild("chooseNode"):getPositionY() - 15)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 10)
        else
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY())
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 30)
            self:findChild("chooseNode"):setPositionY(self:findChild("chooseNode"):getPositionY() - 15)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 40)
            headPosHeight = 15
        end
    elseif display.height >= FIT_HEIGHT_MIN and display.height < FIT_HEIGHT_MAX then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro > 2 and pro < 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 120)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 120)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 180)
            headPosHeight = 50
        elseif pro >= 2.2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 140)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 200)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 240)
            headPosHeight = 100
        elseif pro == 2 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - posY + 75)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 140)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 140)
            headPosHeight = 70
        elseif pro <= 1.867 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 10)
            self:findChild("jackpot"):setPositionY(self:findChild("jackpot"):getPositionY() + 10)
            self:findChild("wheelNode"):setPositionY(self:findChild("wheelNode"):getPositionY() + 40)
            headPosHeight = 5
        end
    elseif display.height < FIT_HEIGHT_MIN then
        local posY = (display.height - FIT_HEIGHT_MAX) * 0.5
        local pro = display.height / display.width
        if pro < 1.5 then
            self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() - 10)
            headPosHeight = 10
        end
        self.m_machineNode:setPositionY(self.m_machineNode:getPositionY() + 40)
    end
    local pro = display.height / display.width
    if pro > 1.95 then
        self:findChild("wheelNode"):setScale(0.93)
    elseif pro <= 1.867 then
        self:findChild("wheelNode"):setScale(0.88)
    elseif pro > 1.867 then
        self:findChild("wheelNode"):setScale(0.85)
    end
    self:setHeadPos(headPosHeight)
end

function CodeGameScreenDragonsMachine:initMachineBg()
    local gameBg = util_createView("views.gameviews.GameMachineBG")
    self:findChild("BgNode"):addChild(gameBg, GAME_LAYER_ORDER.LAYER_ORDER_BG)
    gameBg:initBgByModuleName(self.m_moduleName, self.m_isMachineBGPlayLoop)
    self.m_gameBg = gameBg
end

function CodeGameScreenDragonsMachine:setHeadPos(_height)
    local node = self:findChild("longtou")
    node:setPositionY(node:getPositionY() + _height)
end
---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenDragonsMachine:getPreLoadSlotNodes()
    local loadNode = BaseFastMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,
    local loadNodes = {
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_9, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_8, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_7, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_6, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_5, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_4, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_3, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_2, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCORE_1, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_SCATTER, count = 15},
        {symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD, count = 15}
    }
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_10, count = 15}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_SCORE_11, count = 5}

    return loadNode
end
---
--设置bonus scatter 层级
function CodeGameScreenDragonsMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == self.SYMBOL_FIX_SYMBOL then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif
        symbolType == self.SYMBOL_SCORE_WILD1101 or symbolType == self.SYMBOL_SCORE_WILD1102 or symbolType == self.SYMBOL_SCORE_WILD1103 or --wild 2
            symbolType == self.SYMBOL_SCORE_WILD2101 or
            symbolType == self.SYMBOL_SCORE_WILD2102 or
            symbolType == self.SYMBOL_SCORE_WILD2103 or --wild 3
            symbolType == self.SYMBOL_SCORE_WILD3101 or
            symbolType == self.SYMBOL_SCORE_WILD3102 or
            symbolType == self.SYMBOL_SCORE_WILD3103 or --wild 4
            symbolType == self.SYMBOL_SCORE_WILD4101 or
            symbolType == self.SYMBOL_SCORE_WILD4102 or
            symbolType == self.SYMBOL_SCORE_WILD4103 or --wild 5
            symbolType == self.SYMBOL_SCORE_WILD5101 or
            symbolType == self.SYMBOL_SCORE_WILD5102 or
            symbolType == self.SYMBOL_SCORE_WILD5103 or
            symbolType == self.SYMBOL_SCORE_WILD6101 or --wild 6
            symbolType == self.SYMBOL_SCORE_WILD6102 or
            symbolType == self.SYMBOL_SCORE_WILD6103 or
            symbolType == self.SYMBOL_SCORE_WILD6104 or
            symbolType == self.SYMBOL_SCORE_WILD6105 or
            symbolType == self.SYMBOL_SCORE_WILD6106 or
            symbolType == self.SYMBOL_SCORE_WILD6107
     then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
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

----------------------------- 玩法处理 -----------------------------------
--[[
    @desc: 检测是否切换到处于fs 状态
    处于fs中有两种情况
    1 totalCount 不为0 ，并且有剩余次数 leftCount > 0
    2 处于 fs最后一次，但是这次触发了Bonus 或者 repin玩法 那么仍然恢复到fs状态
    time:2019-01-04 17:56:46
    @return: 是否触发
]]
function CodeGameScreenDragonsMachine:checkTriggerINFreeSpin()
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

        if self.m_initSpinData.p_freeSpinsLeftCount == 0 and hasBonusFeature == false then
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

---
--判断改变freespin的状态
function CodeGameScreenDragonsMachine:changeFreeSpinModeStatus()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local hasBonusFeature = false
        if self:checkHasEffectType(GameEffect.EFFECT_BONUS) == true then
            hasBonusFeature = true
        end
        if globalData.slotRunData.freeSpinCount == 0 then -- free spin 模式结束
            if hasBonusFeature == true then
                -- self:setCurrSpinMode(NORMAL_SPIN_MODE)
            else
                if self.m_iFreeSpinTimes == 0 then -- 下次没有fs才播放fsover动画
                    self.m_vecSymbolEffectType[#self.m_vecSymbolEffectType + 1] = GameEffect.EFFECT_FREE_SPIN_OVER
                end
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

-- 断线重连
function CodeGameScreenDragonsMachine:MachineRule_initGame(spinData)
    if self.m_bProduceSlots_InFreeSpin == true then
        self:showFreeSpinReconnect()
        if self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount == self.m_runSpinResultData.p_freeSpinsLeftCount then
            globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
            globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        else
        end
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
    elseif self.m_bIsInBonusGame ~= true and self.m_runSpinResultData.p_freeSpinsLeftCount > 0 and self.m_runSpinResultData.p_freeSpinsTotalCount > self.m_runSpinResultData.p_freeSpinsLeftCount then
        globalData.slotRunData.freeSpinCount = self.m_runSpinResultData.p_freeSpinsLeftCount
        globalData.slotRunData.totalFreeSpinCount = self.m_runSpinResultData.p_freeSpinsTotalCount
        self.m_normalFreeSpinTimes = globalData.slotRunData.totalFreeSpinCount
        self:showFreeSpinReconnect()
        self:triggerFreeSpinCallFun()
    end
    if self.m_runSpinResultData and self.m_runSpinResultData.p_selfMakeData then
        self.m_baseReelSymbolType = self.m_runSpinResultData.p_selfMakeData.nextBaseChageSignal
    end
end

function CodeGameScreenDragonsMachine:showFreeSpinReconnect()
    self.m_dragonsHead:setVisible(false)
    self:runCsbAction("idle")
    self.m_dragonsBall:setVisible(true)
    self.m_dragonsBallLab:setVisible(true)
    self.m_dragonsBallBg:setVisible(true)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.select then
        local selectType = selfData.select
        self:changeNormalAndFreespinReel(selectType)
    end
    self:createGiftPackage()
    local num = self.m_runSpinResultData.p_selfMakeData.freespinCount
    local isTrigger = self.m_runSpinResultData.p_selfMakeData.freespinTrigger
    if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 and isTrigger == 1 then
        num = num + 1
    end
    if num and num > 0 then
        self.m_giftPackageBar:showFreespinCount(num)
    end
end

function CodeGameScreenDragonsMachine:AddBonusEffect(spinData)
    local featureDatas = spinData.p_features
    local isAddFs = false
    if not featureDatas then
        return
    end
    for i = 1, #featureDatas do
        local featureId = featureDatas[i]

        if featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT or featureId == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            isAddFs = true

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

    return isAddFs
end

function CodeGameScreenDragonsMachine:initFeatureInfo(spinData, featureData)
    if featureData.p_status == "CLOSED" and self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == false and self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == false then
        self:playGameEffect()
        self:AddBonusEffect(spinData)
        return
    end

    if featureData.p_status == "OPEN" then
        self:findChild("Node_reel"):setVisible(false)
        globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_bonusWinCoins
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {0, false, true})
        self:createDragonsWheelView(
            function()
                local selfData = self.m_runSpinResultData.p_selfMakeData
                local curStage = selfData.bonusResult
                if curStage == "jackpot" then
                    local jackpotOver = selfData.jackpotOver
                    if jackpotOver == 1 then
                        self:playTransitionEffect(
                            function()
                                self.m_wheelView:removeFromParent()
                                self.m_wheelView = nil
                                self:findChild("Node_reel"):setVisible(true)
                                self:resetMusicBg()
                            end,
                            function()
                                local winCoins = self.m_runSpinResultData.p_bonusWinCoins
                                if self.m_effectData ~= nil then
                                    self.m_effectData.p_isPlay = true
                                end
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                                self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)
                                self:playGameEffect()
                            end
                        )
                        return
                    end
                end

                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.CHOOSE_FREESPIN_EFFECT -- 动画类型
                if self.m_effectData ~= nil then
                    self.m_effectData.p_isPlay = true
                end
                self:playGameEffect()
            end
        )
        if self.m_bProduceSlots_InFreeSpin ~= true then
            self.m_bottomUI:checkClearWinLabel()
        else
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(spinData.p_fsWinCoins))
        end
        if self.m_runSpinResultData.p_freeSpinsLeftCount > 0 then
            self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(spinData.p_fsWinCoins))
        end
        performWithDelay(
            self,
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
            end,
            0.1
        )
        self.m_bIsInBonusGame = true
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
        local featureID = spinData.p_features[#spinData.p_features]

        if featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER then
            table.remove(self.m_runSpinResultData.p_features, #self.m_runSpinResultData.p_features)
        end

        if self:checkHasGameEffectType(GameEffect.EFFECT_RESPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_RESPIN)
        end
        if self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN) == true then
            self:removeGameEffectType(GameEffect.EFFECT_FREE_SPIN)
        end
    end

    if featureData.p_data ~= nil and featureData.p_data.freespin ~= nil then
        self.m_runSpinResultData.p_freeSpinsLeftCount = featureData.p_data.freespin.freeSpinsLeftCount
        self.m_runSpinResultData.p_freeSpinsTotalCount = featureData.p_data.freespin.freeSpinsTotalCount
    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenDragonsMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenDragonsMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end
---------------------------------------------------------------------------
---
-- 显示free spin
function CodeGameScreenDragonsMachine:showEffect_FreeSpin(effectData)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    local lineLen = #self.m_reelResultLines
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN then
            table.remove(self.m_reelResultLines,i)
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

    self:showFreeSpinView(effectData)
    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_FreeSpin,self.m_iOnceSpinLastWin)
    return true
end
----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenDragonsMachine:showFreeSpinView(effectData)
    local showFSView = function(...)
        self:clearCurMusicBg()
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_tip.mp3")
        self:showFreeSpinStart(
            self.m_iFreeSpinTimes,
            function()
                self:triggerFreeSpinCallFun()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(
        self,
        function()
            showFSView()
        end,
        1.5
    )
end

function CodeGameScreenDragonsMachine:showFreeSpinStart(num, func)
    local extraData = self.m_runSpinResultData.p_selfMakeData
    local pos = extraData.freespinType + 1
    local data = self.freespinData[pos]
    local freeSpinType = extraData.select
    local ownerlist = {}
    ownerlist["m_lb_num"] = num
    ownerlist["m_lb_num_1"] = "x" .. data[1]
    ownerlist["m_lb_num_2"] = "x" .. data[2]
    ownerlist["m_lb_num_3"] = "x" .. data[3]
    local view = self:showDialog(BaseDialog.DIALOG_TYPE_FREESPIN_START, ownerlist, func)
    if freeSpinType == 0 then
        view:findChild("Node_6"):setVisible(true)
        view:findChild("Node_7"):setVisible(false)
        view:findChild("Node_8"):setVisible(false)
        view:findChild("Node_9"):setVisible(false)
        view:findChild("Node_10"):setVisible(false)
        view:findChild("Node_11"):setVisible(false)
    elseif freeSpinType == 1 then
        view:findChild("Node_6"):setVisible(false)
        view:findChild("Node_7"):setVisible(true)
        view:findChild("Node_8"):setVisible(false)
        view:findChild("Node_9"):setVisible(false)
        view:findChild("Node_10"):setVisible(false)
        view:findChild("Node_11"):setVisible(false)
    elseif freeSpinType == 2 then
        view:findChild("Node_6"):setVisible(false)
        view:findChild("Node_7"):setVisible(false)
        view:findChild("Node_8"):setVisible(true)
        view:findChild("Node_9"):setVisible(false)
        view:findChild("Node_10"):setVisible(false)
        view:findChild("Node_11"):setVisible(false)
    elseif freeSpinType == 3 then
        view:findChild("Node_6"):setVisible(false)
        view:findChild("Node_7"):setVisible(false)
        view:findChild("Node_8"):setVisible(false)
        view:findChild("Node_9"):setVisible(true)
        view:findChild("Node_10"):setVisible(false)
        view:findChild("Node_11"):setVisible(false)
    elseif freeSpinType == 4 then
        view:findChild("Node_6"):setVisible(false)
        view:findChild("Node_7"):setVisible(false)
        view:findChild("Node_8"):setVisible(false)
        view:findChild("Node_9"):setVisible(false)
        view:findChild("Node_10"):setVisible(true)
        view:findChild("Node_11"):setVisible(false)
    elseif freeSpinType == 5 then
        view:findChild("Node_6"):setVisible(false)
        view:findChild("Node_7"):setVisible(false)
        view:findChild("Node_8"):setVisible(false)
        view:findChild("Node_9"):setVisible(false)
        view:findChild("Node_10"):setVisible(false)
        view:findChild("Node_11"):setVisible(true)
    end
    return view
end

function CodeGameScreenDragonsMachine:showFreeSpinOverView()
    self:clearCurMusicBg()
    gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_freespin_over.mp3")
    local totalFreespinCount = self.m_runSpinResultData.p_selfMakeData.totalFreespinCount
    performWithDelay(
        self,
        function()
            gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_tip.mp3")
            local strCoins = util_formatCoins(globalData.slotRunData.lastWinCoin, 11)
            local view =
                self:showFreeSpinOver(
                strCoins,
                totalFreespinCount,
                function()
                    performWithDelay(
                        self,
                        function()
                            local isAddFs = self:AddBonusEffect(self.m_runSpinResultData)
                            if isAddFs == true then
                                self:playTransitionEffect3()
                                self:triggerFreeSpinOverCallFun()
                                self:changeNormalAndFreespinReel(6)
                                -- 如果处于 freespin 中 那么大赢都不触发
                                local hasFsOverEffect = self:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER)
                                if hasFsOverEffect == true then -- or  self.m_bProduceSlots_InFreeSpin == true
                                    self:removeGameEffectType(GameEffect.EFFECT_BIGWIN)
                                    self:removeGameEffectType(GameEffect.EFFECT_MEGAWIN)
                                    self:removeGameEffectType(GameEffect.EFFECT_EPICWIN)
                                end
                            else
                                self:playTransitionEffect(
                                    function()
                                        if self.m_giftPackageBar then
                                            self.m_giftPackageBar:removeFromParent()
                                            self.m_giftPackageBar = nil
                                        end
                                        self:runCsbAction("idle1")
                                        self.m_dragonsHead:setVisible(true)
                                        self.m_dragonsBall:setVisible(false)
                                        self.m_dragonsBallLab:setVisible(false)
                                        self.m_dragonsBallBg:setVisible(false)
                                        self:changeNormalAndFreespinReel(6)
                                    end,
                                    function()
                                        self:triggerFreeSpinOverCallFun()
                                    end
                                   
                                )
                            end
                        end,
                        0.5
                    )
                end
            )
            local node = view:findChild("m_lb_coins")
            view:updateLabelSize({label = node, sx = 1, sy = 1}, 628)
        end,
        3
    )
end

function CodeGameScreenDragonsMachine:createDragonsWheelView(_func)
    self.m_currentMusicBgName = "DragonsSounds/music_Dragons_wheel.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)

    self.m_wheelView = util_createView("CodeDragonsSrc.DragonsWheelViewBg", self)
    self:findChild("wheelNode"):addChild(self.m_wheelView)

    if globalData.slotRunData.machineData.p_portraitFlag then
        self.m_wheelView.getRotateBackScaleFlag = function(  ) return false end
    end


    self.m_wheelView:initMachine(self)
    if _func then
        self.m_wheelView:setCallFun(_func)
    end
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenDragonsMachine:MachineRule_SpinBtnCall()
    -- gLobalSoundManager:setBackgroundMusicVolume(1)
    self.m_scatterNum = 0
    self.m_collectList = {}
    if self.m_playDragonsEffect == true and self.m_dragonsBallLab then
        self.m_dragonsBallLab:playBallLabOveeEffect()
        self.m_playDragonsEffect = false
    end
    return false -- 用作延时点击spin调用
end

-- --------------网络数据处理处理
--[[
    @desc: 在特殊格子干预完成后， 根据特定关卡自定义来 干预盘面
           网络消息返回后干预， 如果使用本地计算数据，则不处理这个函数
    time:2018-11-29 17:56:53
    @return:
]]
function CodeGameScreenDragonsMachine:MachineRule_network_InterveneSymbolMap()
end

--[[
    @desc: 连线基本逻辑处理完毕后的处理
           网络消息回来后的处理， 
    time:2018-11-29 18:01:48
    @return:
]]
function CodeGameScreenDragonsMachine:MachineRule_afterNetWorkLineLogicCalculate()
    -- self.m_runSpinResultData 可以从这个里边取网络数据，基本上所有的网络数据都在这个列表
end

--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenDragonsMachine:addSelfEffect()
    -- -- 自定义动画创建方式

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        local isTrigger = 0
        local selfData = self.m_runSpinResultData.p_selfMakeData
        if selfData and selfData.freespinTrigger then
            isTrigger = selfData.freespinTrigger
        end
        if isTrigger == 1 then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.ADD_FREESPIN_NUM_EFFECT
        end
        local isHave, num = self:checkIsLinesHaveSymbolWild()
        if isHave then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.PLAY_DRAGONS_BALL_EFFECT
        end
    end
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenDragonsMachine:MachineRule_playSelfEffect(effectData)
    if effectData.p_selfEffectType == self.CHOOSE_FREESPIN_EFFECT then
        -- 记得完成所有动画后调用这两行
        -- 作用：标识这个动画播放完结，继续播放下一个动画
        self:playTransitionEffect2(
            function()
                if self.m_wheelView then
                    self.m_wheelView:removeFromParent()
                    self.m_wheelView = nil
                end
                self:showFreespinChooseView(effectData)
            end,
            nil
        )
    elseif effectData.p_selfEffectType == self.ADD_FREESPIN_NUM_EFFECT then
        self:playAddFreeSpinNumEffect(effectData)
    elseif effectData.p_selfEffectType == self.PLAY_DRAGONS_BALL_EFFECT then
        local isHave, num = self:checkIsLinesHaveSymbolWild()

        local extraData = self.m_runSpinResultData.p_selfMakeData
        local selectType = extraData.select
        local pos = extraData.freespinType + 1
        local _num = 2
        if selectType == 5 then
            local data = self.freespinData[6]
            _num = data[num]
        else
            local data = self.freespinData[pos]
            _num = data[num]
        end
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_ball_multi.mp3")
        self.m_dragonsBallLab:playBallLabWildEffect(_num)
        self.m_playDragonsEffect = true
        util_spinePlay(self.m_dragonsBall, "actionframe", false)
        util_spineFrameEvent(
            self.m_dragonsBall,
            "actionframe",
            "show",
            function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end
        )
        util_spineEndCallFunc(
            self.m_dragonsBall,
            "actionframe",
            function()
                util_spinePlay(self.m_dragonsBall, "idle", true)
            end
        )
    end

    return true
end

function CodeGameScreenDragonsMachine:createFlyPart()
    local par = cc.ParticleSystemQuad:create("partical/qiandai_tuowei.plist")
    return par
end

function CodeGameScreenDragonsMachine:flyScatter(list, func)
    local endNode = self:findChild("qiandai")
    local endPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    local bezTime = 1
    local isShowCollect = false
    gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_collect.mp3")
    for _, node in pairs(list) do
        local startPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local newStartPos = self:convertToNodeSpace(startPos)
        local par = self:createFlyPart()
        par:setPosition(newStartPos)
        self:addChild(par, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
        -- local bez1 = cc.BezierTo:create(0.5, {cc.p(startPos.x + (startPos.x - endPos.x) * 0.5, startPos.y), cc.p(endPos.x, startPos.y), endPos})
        local moveTo = cc.MoveTo:create(0.5, endPos)
        local scale1 = cc.ScaleTo:create(0.5, 0.6)
        local spw1 = cc.Spawn:create(moveTo, scale1)
        par:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.5),
                spw1,
                cc.DelayTime:create(0.2),
                cc.CallFunc:create(
                    function()
                        par:stopSystem()
                        par:removeFromParent()
                    end
                )
            )
        )
    end

    scheduler.performWithDelayGlobal(
        function()
            if func ~= nil then
                func()
            end
        end,
        1.2,
        self:getModuleName()
    )
end

function CodeGameScreenDragonsMachine:playAddFreeSpinNumEffect(effectData)
    for i, v in ipairs(self.m_collectList) do
        local targSp = v
        if targSp then
            targSp:runAnim(
                "actionframe",
                false,
                function()
                    targSp:resetReelStatus()
                end
            )
        end
    end
    local delayTime = 0
    if self.m_giftPackageBar == nil then
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_gift_show.mp3")
        self:createGiftPackage()
        delayTime = 2
    end
    scheduler.performWithDelayGlobal(
        function()
            if self.m_collectList and #self.m_collectList > 0 then
                self:flyScatter(
                    self.m_collectList,
                    function()
                        if self.m_giftPackageBar then
                            local num = self.m_runSpinResultData.p_selfMakeData.freespinCount
                            local isTrigger = self.m_runSpinResultData.p_selfMakeData.freespinTrigger
                            if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 and isTrigger == 1 then
                                num = num + 1
                            end
                            if num == 1 then
                                self.m_giftPackageBar:showFreespinCount(num)
                            else
                                self.m_giftPackageBar:updateFreespinCount(num)
                            end
                        end
                        effectData.p_isPlay = true
                        self:playGameEffect()
                    end
                )
            end
        end,
        delayTime,
        self:getModuleName()
    )
end

--礼包显示
function CodeGameScreenDragonsMachine:createGiftPackage()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local isTrigger = selfData.freespinTrigger
    --最后一次freespin 再次触发 freespin 累加数
    if self.m_runSpinResultData.p_freeSpinsLeftCount == 0 and isTrigger == 1 then
        local node_bar = self:findChild("qiandai")
        local num = selfData.freespinCount
        local data = {}
        data.num = num
        self.m_giftPackageBar = util_createView("CodeDragonsSrc.DragonsFreespinGiftPackageView", data)
        node_bar:addChild(self.m_giftPackageBar)
        self.m_giftPackageBar:setPosition(0, 0)
        return
    end

    if selfData and selfData.freespinCount and selfData.freespinCount > 0 then
        local node_bar = self:findChild("qiandai")
        local num = selfData.freespinCount
        local data = {}
        data.num = num
        self.m_giftPackageBar = util_createView("CodeDragonsSrc.DragonsFreespinGiftPackageView", data)
        node_bar:addChild(self.m_giftPackageBar)
        self.m_giftPackageBar:setPosition(0, 0)
    end
end

--当前阶段
function CodeGameScreenDragonsMachine:getCurStage()
    if self.m_runSpinResultData ~= nil then
        if self.m_runSpinResultData.p_selfMakeData then
            local selfData = self.m_runSpinResultData.p_selfMakeData
            local curStage = selfData.bonusType
            if curStage then
                return curStage
            end
        end
    end
end

function CodeGameScreenDragonsMachine:showEffect_Bonus(effectData)
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end

    self.m_effectData = effectData
    local bonusGame = function()
        if self:getCurStage() == "freespin" or self:getCurStage() == "free" then
            gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_freespin_over.mp3")
            performWithDelay(
                self,
                function()
                    self:playTransitionEffect3(
                        function()
                            local selfData = self.m_runSpinResultData.p_selfMakeData
                            local num = selfData.freespinCount
                            if self.m_giftPackageBar then
                                if num == 0 then
                                    self.m_giftPackageBar:removeFromParent()
                                    self.m_giftPackageBar = nil
                                else
                                    self.m_giftPackageBar:changeFreespinCount(num)
                                end
                            end
                            if self.m_playDragonsEffect == true and self.m_dragonsBallLab then
                                self.m_dragonsBallLab:playBallLabOveeEffect()
                                self.m_playDragonsEffect = false
                            end
                            self:changeNormalAndFreespinReel(6)
                            self:findChild("Node_reel"):setVisible(false)
                            self:showFreespinChooseView(effectData)
                        end,
                        nil
                    )
                end,
                2
            )
        elseif self:getCurStage() == "wheel" then
            self:playTransitionEffect(
                function()
                    self:changeNormalAndFreespinReel(6)
                    self:findChild("Node_reel"):setVisible(false)
                    globalData.slotRunData.lastWinCoin = self.m_runSpinResultData.p_bonusWinCoins
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {0, false, true})
                    self:createDragonsWheelView(
                        function()
                            if self.m_effectData ~= nil then
                                local selfData = self.m_runSpinResultData.p_selfMakeData
                                local curStage = selfData.bonusResult
                                if curStage == "jackpot" then
                                    local jackpotOver = selfData.jackpotOver
                                    if jackpotOver == 1 then
                                        self:playTransitionEffect(
                                            function()
                                                -- self.m_effectData.p_isPlay = true
                                                -- self:playGameEffect()
                                                self.m_wheelView:removeFromParent()
                                                self.m_wheelView = nil
                                                self:findChild("Node_reel"):setVisible(true)
                                                self:resetMusicBg()
                                            end,
                                            function()
                                                local winCoins = self.m_runSpinResultData.p_bonusWinCoins
                                                self.m_effectData.p_isPlay = true
                                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                                                self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)
                                                self:playGameEffect()
                                            end
                                        )
                                        return
                                    end
                                end

                                local selfEffect = GameEffectData.new()
                                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                                selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
                                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                                selfEffect.p_selfEffectType = self.CHOOSE_FREESPIN_EFFECT -- 动画类型

                                self.m_effectData.p_isPlay = true
                                self:playGameEffect()
                            end
                        end
                    )
                end,
                nil
            )
        end
    end
    local delayTime = 0.5
    if self:getCurStage() == "freespin" or self:getCurStage() == "free" then
        delayTime = 0.1
    elseif self:getCurStage() == "wheel" then
        delayTime = 4.5
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_scatter_start.mp3")
        if self.m_collectList then
            for i, v in ipairs(self.m_collectList) do
                local targSp = v
                if targSp then
                    targSp:runAnim(
                        "actionframe",
                        false,
                        function()
                            targSp:resetReelStatus()
                        end
                    )
                end
            end
        end
    end

    performWithDelay(
        self,
        function()
            bonusGame()
        end,
        delayTime
    )

    return true
end

function CodeGameScreenDragonsMachine:bonusOverAddFreespinEffect()
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
        end
    end
end

function CodeGameScreenDragonsMachine:normalSpinBtnCall()
    BaseSlotoManiaMachine.normalSpinBtnCall(self)

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self:setMaxMusicBGVolume()
    self:removeSoundHandler()
end

function CodeGameScreenDragonsMachine:slotReelDown()
    BaseMachine.slotReelDown(self)
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end
--添加金边
function CodeGameScreenDragonsMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    reelEffectNode:setScaleX(1)
    reelEffectNode:setScaleY(1)

    if self.m_reelEffectName == self.m_defaultEffectName then
        local reelRunAnimaWidth = 200
        local reelRunAnimaHeight = 603

        local worldPos, reelHeight, reelWidth = self:getReelPos(col)

        local scaleY = reelHeight / reelRunAnimaHeight
        local scaleX = reelWidth / reelRunAnimaWidth

        reelEffectNode:setScaleY(scaleY)
        reelEffectNode:setScaleX(scaleX)
    end

    self:setLongAnimaInfo(reelEffectNode, col)

    if col > 2 then
        local rundi = self.m_RunDi[col]
        if rundi then
            rundi:setVisible(true)
        -- rundi:playAction("run")
        end
    end
    reelEffectNode:setVisible(true)
    util_setCascadeOpacityEnabledRescursion(reelEffectNode, true)
    reelEffectNode:setOpacity(0)
    util_playFadeInAction(reelEffectNode, 0.1)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

function CodeGameScreenDragonsMachine:createReelEffect(col)
    local reelEffectNode, effectAct
    if col == 1 or col == 5 then
        reelEffectNode, effectAct = util_csbCreate("WinFrameDragons_run1.csb")
    else
        reelEffectNode, effectAct = util_csbCreate("WinFrameDragons_run2.csb")
    end

    reelEffectNode:retain()
    effectAct:retain()

    self.m_slotEffectLayer:addChild(reelEffectNode)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

function CodeGameScreenDragonsMachine:slotOneReelDown(reelCol)
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false

    --Scatter  play "buling" animation
    for iRow = 1, self.m_iReelRowNum do
        local targSp = self:getReelParent(reelCol):getChildByTag(self:getNodeTag(reelCol, iRow, SYMBOL_NODE_TAG))
        if targSp and targSp.m_isLastSymbol and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            self.m_scatterNum = self.m_scatterNum + 1
            if reelCol == self.m_scatterNum then
                targSp = self:setSymbolToClipReel(reelCol, iRow, TAG_SYMBOL_TYPE.SYMBOL_SCATTER)
                if targSp then
                    table.insert(self.m_collectList, targSp)
                    targSp:runAnim(
                        "buling",
                        false,
                        function()
                            targSp:resetReelStatus()
                        end
                    )
                end
                local soundIndex = 1
                if self.m_scatterNum == 1 then
                    soundIndex = 1
                elseif self.m_scatterNum == 2 then
                    soundIndex = 2
                elseif self.m_scatterNum == 3 then
                    soundIndex = 3
                elseif self.m_scatterNum == 4 then
                    soundIndex = 4
                elseif self.m_scatterNum == 5 then
                    soundIndex = 5
                end

                local soundPath =  "DragonsSounds/sound_Dragons_scatter" .. soundIndex .. ".mp3"
                if self.playBulingSymbolSounds then
                    self:playBulingSymbolSounds( reelCol,soundPath,TAG_SYMBOL_TYPE.SYMBOL_SCATTER )
                else
                    gLobalSoundManager:playSound(soundPath)
                end

            end
        end
    end

    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimation(reelCol + 1)
    end
    
    if self.playReelDownSound then
        self:playReelDownSound(reelCol,self.m_reelDownSound)
    else
        gLobalSoundManager:playSound(self.m_reelDownSound)
    end
    
    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        local reelEffectNode = self.m_reelRunAnima[reelCol]
        if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
            reelEffectNode[1]:runAction(cc.Hide:create())
        end
    end
    if reelCol > 2 then
        local rundi = self.m_RunDi[reelCol]
        if rundi:isVisible() then
            rundi:setVisible(false)
        end
    end
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

--设置长滚信息  快滚什么的都在这里处理
function CodeGameScreenDragonsMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum

    local bRunLong = false

    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    local addLens = false

    for col = 1, iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1

            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen

            reelRunData:setReelRunLen(runLen)
        else
            if addLens == true then
                if col == 3 or col == 4 or col == 5 then
                    local addNum = self.m_reelRunInfo[col]:getInitReelRunLen() - self.m_reelRunInfo[col - 1]:getInitReelRunLen()
                    self.m_reelRunInfo[col]:setReelLongRun(false)
                    self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + addNum)
                    self:setLastReelSymbolList()
                end
            end
        end

        local runLen = reelRunData:getReelRunLen()

        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, col, scatterNum, bRunLong)

        if col == scatterNum and scatterNum >= 2 then
            addLens = true
        end
        if col ~= scatterNum and scatterNum >= 2 then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
            addLens = true
        end
    end
end

--设置滚动状态
local runStatus = {
    DUANG = 1,
    NORUN = 2
}

function CodeGameScreenDragonsMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then
        showColTemp = showCol
    else
        for i = 1, self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end

    if col == nodeNum then
        if nodeNum <= 1 then
            return runStatus.DUANG, false
        elseif nodeNum >= 2 then
            return runStatus.DUANG, true
        end
    else
        return runStatus.NORUN, false
    end
end

function CodeGameScreenDragonsMachine:setSymbolToClipReel(_iCol, _iRow, _type)
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
        self.m_clipParent:addChild(targSp, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + showOrder, targSp:getTag())
        targSp:setPosition(cc.p(pos.x, pos.y))
    end
    return targSp
end

function CodeGameScreenDragonsMachine:changeToMaskLayerSlotNode(slotNode)
    self.m_lineSlotNodes[#self.m_lineSlotNodes + 1] = slotNode

    local nodeParent = slotNode:getParent()

    slotNode.p_preParent = nodeParent
    if nodeParent == self.m_clipParent then
        slotNode.p_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3 - slotNode.p_rowIndex
    else
        slotNode.p_showOrder = slotNode:getLocalZOrder()
    end

    slotNode.p_preX = slotNode:getPositionX()
    slotNode.p_preY = slotNode:getPositionY()
    slotNode.p_preLayerTag = slotNode.p_layerTag

    local pos = nodeParent:convertToWorldSpace(cc.p(slotNode.p_preX, slotNode.p_preY))
    pos = self.m_clipParent:convertToNodeSpace(pos)
    slotNode:setPosition(pos.x, pos.y)
    -- slotNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE  (这个这样写干嘛用的)
    
    local symbolType = slotNode.p_symbolType
    if symbolType and symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType > 1000 then
        util_changeNodeParent(self.m_clipParent,slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + slotNode.p_showOrder)
    else
        util_changeNodeParent(self.m_clipParent,slotNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_LINE_NODE + slotNode.p_showOrder)
    end
    if slotNode.p_rowIndex == nil or slotNode.p_cloumnIndex == nil then
        printInfo("xcyy : %s", "slotNode p_rowIndex  p_cloumnIndex isnil")
    end

    if self.m_bigSymbolInfos[slotNode.p_symbolType] ~= nil then
        self:operaBigSymbolShowMask(slotNode)
    end

    --    printInfo("changeToMaskLayerSlotNode 添加的格子行列位置 %d  , %d",slotNode.p_rowIndex,slotNode.p_cloumnIndex)
end

function CodeGameScreenDragonsMachine:changeNormalAndFreespinReel(_type)
    if _type == 6 then
        self.m_gameBg:runCsbAction("idl1_zi", false)
    elseif _type == 3 then
        self.m_gameBg:runCsbAction("idl5_huang", false)
    elseif _type == 1 then
        self.m_gameBg:runCsbAction("idl4_lan", false)
    elseif _type == 2 then
        self.m_gameBg:runCsbAction("idl3_fen", false)
    elseif _type == 4 then
        self.m_gameBg:runCsbAction("idl2_yin", false)
    elseif _type == 0 then
        self.m_gameBg:runCsbAction("idl6_lv", false)
    elseif _type == 5 then
        self.m_gameBg:runCsbAction("idl7_hei", false)
    end
end

function CodeGameScreenDragonsMachine:showExtraFreeSpinView()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local num = selfData.extraSpinTimes
    if selfData.extraSpinTimes and selfData.extraSpinTimes > 0 then
        local data = {}
        data._num = num
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_extra_tip_show.mp3")
        self.m_extraFreespinView = util_createView("CodeDragonsSrc.DragonsExtraFreeSpinView", data)
        self:addChild(self.m_extraFreespinView, GAME_LAYER_ORDER.LAYER_ORDER_TOURNAMENT - 1)
        if globalData.slotRunData.machineData.p_portraitFlag then
            self.m_extraFreespinView.getRotateBackScaleFlag = function(  ) return false end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOW_UI,{node = self.m_extraFreespinView})

        local node = self:findChild("chooseNode")
        local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
        local pos = self:convertToNodeSpace(worldPos)

        -- local pos = cc.p(self:findChild("ExtraNode"):getPosition())
        self.m_extraFreespinView:setPosition(pos)
        local root = self.m_machineNode:getChildByName("root")
        if root then
            local scale = root:getScale()
            self.m_extraFreespinView:setScale(scale)
        end
    -- self:findChild("ExtraNode"):addChild(self.m_extraFreespinView)
    end
end

-- 额外次数弹框 跳动随次数的增长
function CodeGameScreenDragonsMachine:playExtraFreeSpinEffect()
    if self.m_extraFreespinView then
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_extra_add.mp3")
        self.m_extraFreespinView:runCsbAction("zengjia", false)
    end
end

--over 动画删掉 额外次数弹框
function CodeGameScreenDragonsMachine:removeExtraFreeSpinEffect()
    if self.m_extraFreespinView then
        self.m_extraFreespinView:runCsbAction(
            "over",
            false,
            function()
                self.m_extraFreespinView:removeFromParent()
                self.m_extraFreespinView = nil
            end
        )
    end
end

function CodeGameScreenDragonsMachine:playChooseMusicBg()
    self.m_currentMusicBgName = "DragonsSounds/music_Dragons_chooseBg.mp3"
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(self.m_currentMusicBgName)
end

function CodeGameScreenDragonsMachine:showFreespinChooseView(effectData)
    self:clearCurMusicBg()

    local chooseFreespinView = util_createView("CodeDragonsSrc.DragonsChooseFreespinView")
    chooseFreespinView:setMachine(self)

    self:findChild("chooseNode"):addChild(chooseFreespinView)

    if globalData.slotRunData.machineData.p_portraitFlag then
        chooseFreespinView.getRotateBackScaleFlag = function(  ) return false end
    end


    if self.m_extraFreespinView then
        gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_extra_tip_move.mp3")
        self.m_extraFreespinView:runCsbAction(
            "yidong",
            false,
            function()
                performWithDelay(
                    self,
                    function()
                        chooseFreespinView:playAddExtraEffect()
                    end,
                    0.5
                )
            end
        )
    else
        chooseFreespinView:showFreespinView()
    end
    chooseFreespinView:setChooseFreespinCall(
        function()
            self:playTransitionEffect2(
                function()
                    chooseFreespinView:removeFromParent()
                    local selfData = self.m_runSpinResultData.p_selfMakeData
                    if selfData then
                        local selectType = selfData.select
                        self:changeNormalAndFreespinReel(selectType)
                    end
                    self.m_dragonsHead:setVisible(false)
                    self.m_dragonsBall:setVisible(true)
                    self:showFreeSpinBar()
                    self.m_dragonsBallLab:setVisible(true)
                    self.m_dragonsBallBg:setVisible(true)
                    self:runCsbAction("idle")
                    self:findChild("Node_reel"):setVisible(true)
                end,
                nil
            )
            effectData.p_isPlay = true
            self:bonusOverAddFreespinEffect()
            self:playGameEffect()
        end
    )
end

function CodeGameScreenDragonsMachine:showJackpotWin(index, coins, func)
    local jackPotWinView = util_createView("CodeDragonsSrc.DragonsJackPotWinView")
    jackPotWinView:initViewData(index, coins, func)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jackPotWinView, ViewZorder.ZORDER_UI)
end

--过场动画
function CodeGameScreenDragonsMachine:playTransitionEffect(funcFrame, funcEnd)
    self.m_guochang:setVisible(true)
    gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_guochang1.mp3")
    util_spinePlay(self.m_guochang, "Dragons_guochang1", false)
    -- 动画帧事件
    util_spineFrameEvent(
        self.m_guochang,
        "Dragons_guochang1",
        "show",
        function()
            if funcFrame then
                funcFrame()
            end
        end
    )
    -- 动画结束
    util_spineEndCallFunc(
        self.m_guochang,
        "Dragons_guochang1",
        function()
            self.m_guochang:setVisible(false)
            if funcEnd then
                funcEnd()
            end
        end
    )
end

--过场动画2
function CodeGameScreenDragonsMachine:playTransitionEffect2(funcFrame, funcEnd)
    self.m_guochang2:setVisible(true)
    gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_guochang2.mp3")
    util_spinePlay(self.m_guochang2, "actionframe", false)
    -- 动画帧事件
    util_spineFrameEvent(
        self.m_guochang2,
        "actionframe",
        "show",
        function()
            if funcFrame then
                funcFrame()
            end
        end
    )
    -- 动画结束
    util_spineEndCallFunc(
        self.m_guochang2,
        "actionframe",
        function()
            self.m_guochang2:setVisible(false)
            if funcEnd then
                funcEnd()
            end
        end
    )
end

function CodeGameScreenDragonsMachine:playTransitionEffect3(funcFrame, funcEnd)
    self.m_guochang3:setVisible(true)
    gLobalSoundManager:playSound("DragonsSounds/sound_Dragons_guochang3.mp3")
    util_spinePlay(self.m_guochang3, "actionframe", false)
    -- 动画帧事件
    util_spineFrameEvent(
        self.m_guochang3,
        "actionframe",
        "show",
        function()
            if funcFrame then
                funcFrame()
            end
        end
    )
    -- 动画结束
    util_spineEndCallFunc(
        self.m_guochang3,
        "actionframe",
        function()
            self.m_guochang3:setVisible(false)
            if funcEnd then
                funcEnd()
            end
        end
    )
end

function CodeGameScreenDragonsMachine:MachineRule_checkTriggerFeatures()
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
                elseif featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_OTHER or featureID == SLOTO_FEATURE.FEATURE_MINI_GAME_COLLECT then -- 其他小游戏
                    -- 添加 BonusEffect
                    self:addAnimationOrEffectType(GameEffect.EFFECT_BONUS)
                    --发送测试特殊玩法
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DEBUG_SPECIAL)
                elseif featureID == SLOTO_FEATURE.FEATURE_JACKPOT then
                end
            end
        end
    end
end

function CodeGameScreenDragonsMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue then
        -- 关卡特殊处理 不显示scatter赢钱线动画
        if lineValue.enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            -- print("scatter")
        else
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
                local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
                -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

                local node = nil
                if i <= hasCount then
                    node = inLineFrames[#inLineFrames]
                    inLineFrames[#inLineFrames] = nil
                else
                    node = self:getFrameWithPool(lineValue, symPosData)
                end
                node:setPosition(cc.p(posX, posY))
                node:setVisible(true)
                if node:getParent() == nil then
                    if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                        self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
                    else
                        self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
                    end
                    node:runAnim("actionframe", true)
                else
                    node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
                end
                if self:IsLinesHaveSymbolWild(symPosData.iY, symPosData.iX) then
                    node:setVisible(false)
                else
                    node:setVisible(true)
                end
            end
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

function CodeGameScreenDragonsMachine:showAllFrame(winLines)

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

            -- if checkIndex <= frameNum then
            --     inLineFrames[#inLineFrames + 1] = preNode
            -- else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            -- end

        else
            break
        end
    end

    local addFrames = {}
    local checkIndex = 0
    for index=1, #winLines do
        local lineValue = winLines[index]
        if lineValue == nil then
            printInfo("xcyy : %s","")
        end
        local frameNum = lineValue.iLineSymbolNum

        for i=1,frameNum do

            local symPosData = lineValue.vecValidMatrixSymPos[i]


            if addFrames[symPosData.iX * 1000 + symPosData.iY] == nil then

                addFrames[symPosData.iX * 1000 + symPosData.iY] = true

                local columnData = self.m_reelColDatas[symPosData.iY]

                local showLineGridH = columnData.p_slotColumnHeight / columnData:getLinePosLen( )

                local posX =  columnData.p_slotColumnPosX +  self.m_SlotNodeW * 0.5
                local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY

                local node = self:getFrameWithPool(lineValue,symPosData)
                node:setPosition(cc.p(posX,posY))

                checkIndex = checkIndex + 1
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
                if self:IsLinesHaveSymbolWild(symPosData.iY, symPosData.iX) then
                    node:setVisible(false)
                else
                    node:setVisible(true)
                end
            end

        end
    end

end

--中奖线 上是否有信号wild
function CodeGameScreenDragonsMachine:checkIsLinesHaveSymbolWild()
    --接下来判断连线上是否有信号块wild
    local winLines = self.m_runSpinResultData.p_winLines
    if winLines and #winLines > 0 then
        for i = 1, #winLines do
            local lineData = winLines[i]
            if lineData.p_iconPos and #lineData.p_iconPos > 0 then
                for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                    local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                    local checkEnd = false
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]
                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
                        local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                        if symbolType > 1000 then
                            local num = symbolType % 100
                            return true, num
                        end
                    end
                end
            end
        end
    end

    return false, 0
end

function CodeGameScreenDragonsMachine:IsLinesHaveSymbolWild(_col, _row)
    local winLines = self.m_runSpinResultData.p_winLines
    if winLines and #winLines > 0 then
        for i = 1, #winLines do
            local lineData = winLines[i]
            if lineData.p_iconPos and #lineData.p_iconPos > 0 then
                for lineIndex = 1, #self.m_runSpinResultData.p_winLines do
                    local lineData = self.m_runSpinResultData.p_winLines[lineIndex]
                    local checkEnd = false
                    for posIndex = 1, #lineData.p_iconPos do
                        local pos = lineData.p_iconPos[posIndex]
                        local rowIndex = math.floor(pos / self.m_iReelColumnNum) + 1
                        local colIndex = pos % self.m_iReelColumnNum + 1
                        local tempRow = 5 - math.floor(pos / self.m_iReelColumnNum)
                        if _col == colIndex and tempRow == _row then
                            local symbolType = self.m_runSpinResultData.p_reels[rowIndex][colIndex]
                            if symbolType > 1000 or symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

function CodeGameScreenDragonsMachine:playEffectNotifyNextSpinCall()
    if self.m_bQuestComplete and self:getCurrSpinMode() ~= RESPIN_MODE and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
        if self:getCurrSpinMode() == AUTO_SPIN_MODE then
            gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_OVER) -- 取消auto spin 模式
        end
        self:showQuestCompleteTip()
        return
    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE then
        local delayTime = 0.5
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
    self:checkTriggerOrInSpecialGame(
        function()
            self:reelsDownDelaySetMusicBGVolume()
        end
    )
end

--获得服务器bet的jackpot累计值
function CodeGameScreenDragonsMachine:getWheelJackpotList()
    local jackpotList = {}
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if jackpotPools ~= nil and #jackpotPools > 0 then
        for index, poolData in pairs(jackpotPools) do
            local totalScore, baseScore = globalData.jackpotRunData:refreshJackpotPool(poolData, false, totalBet)
            jackpotList[index] = totalScore - baseScore
        end
    end
    return jackpotList
end

function CodeGameScreenDragonsMachine:getFreeSpinSecletType()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.select then
        local selectType = selfData.select + 1
        return selectType
    end
    return 0
end

function CodeGameScreenDragonsMachine:checkNotifyUpdateWinCoin()
    local winLines = self.m_reelResultLines

    if #winLines <= 0 then
        return
    end
    local isTriggerBonus = false
    if self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == true then
        isTriggerBonus = true
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end
    if isTriggerBonus == true then
        isNotifyUpdateTop = false
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_iOnceSpinLastWin, isNotifyUpdateTop})
end

function CodeGameScreenDragonsMachine:levelDeviceVibrate(_vibrateType, _sFeature)
    if "free" == _sFeature then
        return
    end
    if CodeGameScreenDragonsMachine.super.levelDeviceVibrate then
        CodeGameScreenDragonsMachine.super.levelDeviceVibrate(self, _vibrateType, _sFeature)
    end
end

return CodeGameScreenDragonsMachine
