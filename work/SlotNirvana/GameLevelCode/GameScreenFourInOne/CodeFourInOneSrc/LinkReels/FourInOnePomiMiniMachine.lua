---
-- xcyy
-- 2018-12-18
-- FourInOnePomiMiniMachine.lua
--
--

-- local BaseMiniMachine = require "Levels.BaseMiniMachine"
local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local FourInOneSlotsReelRunData = require "CodeFourInOneSrc.FourInOneSlotsReelRunData"

local BaseDialog = util_require("Levels.BaseDialog")

local FourInOnePomiMiniMachine = class("FourInOnePomiMiniMachine", BaseMiniMachine)

FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_A1 = 100
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_A2 = 101
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_A3 = 102
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_A4 = 103
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_A5 = 104
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_B1 = 105
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_B2 = 106
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_B3 = 107
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_B4 = 108
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_B5 = 109
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_SC = 190
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_WILD = 192
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_BONUS = 194
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_ALL = 1105
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_GRAND = 1104
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_MAJOR = 1103
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_MINOR = 1102
FourInOnePomiMiniMachine.SYMBOL_ChilliFiesta_MINI = 1101

FourInOnePomiMiniMachine.SYMBOL_Charms_P1 = 200
FourInOnePomiMiniMachine.SYMBOL_Charms_P2 = 201
FourInOnePomiMiniMachine.SYMBOL_Charms_P3 = 202
FourInOnePomiMiniMachine.SYMBOL_Charms_P4 = 203
FourInOnePomiMiniMachine.SYMBOL_Charms_P5 = 204
FourInOnePomiMiniMachine.SYMBOL_Charms_Ace = 205
FourInOnePomiMiniMachine.SYMBOL_Charms_King = 206
FourInOnePomiMiniMachine.SYMBOL_Charms_Queen = 207
FourInOnePomiMiniMachine.SYMBOL_Charms_Jack = 208
FourInOnePomiMiniMachine.SYMBOL_Charms_Scatter = 290
FourInOnePomiMiniMachine.SYMBOL_Charms_Wild = 292
FourInOnePomiMiniMachine.SYMBOL_Charms_bonus = 294

FourInOnePomiMiniMachine.SYMBOL_Charms_MINOR = 2104
FourInOnePomiMiniMachine.SYMBOL_Charms_MINI = 2103
FourInOnePomiMiniMachine.SYMBOL_Charms_SYMBOL_DOUBLE = 2105
FourInOnePomiMiniMachine.SYMBOL_Charms_SYMBOL_BOOM = 2109
FourInOnePomiMiniMachine.SYMBOL_Charms_MINOR_DOUBLE = 2106
FourInOnePomiMiniMachine.SYMBOL_Charms_SYMBOL_NULL = 2107
FourInOnePomiMiniMachine.SYMBOL_Charms_SYMBOL_BOOM_RUN = 2108
FourInOnePomiMiniMachine.SYMBOL_Charms_UNLOCK_SYMBOL = -2 -- 解锁状态的轮盘,这个是服务器给的解锁信号
FourInOnePomiMiniMachine.SYMBOL_Charms_NULL_LOCK_SYMBOL = -1 -- 未解锁状态的轮盘,这个是服务器给的空轮盘的信号

FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_Wild = 392
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_H1 = 300
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_H2 = 301
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_H3 = 302
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_L1 = 303
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_L2 = 304
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_L3 = 305
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_L4 = 306
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_L5 = 307
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_L6 = 308
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_SC = 390
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_Bonus = 394
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_MINI = 3102
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_MINOR = 3103
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_MAJOR = 3104
FourInOnePomiMiniMachine.SYMBOL_HowlingMoon_GRAND = 3105

FourInOnePomiMiniMachine.SYMBOL_Pomi_Scatter = 490
FourInOnePomiMiniMachine.SYMBOL_Pomi_H1 = 400
FourInOnePomiMiniMachine.SYMBOL_Pomi_H2 = 401
FourInOnePomiMiniMachine.SYMBOL_Pomi_H3 = 402
FourInOnePomiMiniMachine.SYMBOL_Pomi_H4 = 403
FourInOnePomiMiniMachine.SYMBOL_Pomi_L1 = 404
FourInOnePomiMiniMachine.SYMBOL_Pomi_L2 = 405
FourInOnePomiMiniMachine.SYMBOL_Pomi_L3 = 406
FourInOnePomiMiniMachine.SYMBOL_Pomi_L4 = 407
FourInOnePomiMiniMachine.SYMBOL_Pomi_L5 = 408
FourInOnePomiMiniMachine.SYMBOL_Pomi_Wild = 492
FourInOnePomiMiniMachine.SYMBOL_Pomi_Bonus = 494
FourInOnePomiMiniMachine.SYMBOL_Pomi_GRAND = 4104
FourInOnePomiMiniMachine.SYMBOL_Pomi_MAJOR = 4103
FourInOnePomiMiniMachine.SYMBOL_Pomi_MINOR = 4102
FourInOnePomiMiniMachine.SYMBOL_Pomi_MINI = 4101
FourInOnePomiMiniMachine.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
FourInOnePomiMiniMachine.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

FourInOnePomiMiniMachine.m_runCsvData = nil
FourInOnePomiMiniMachine.m_machineIndex = nil

FourInOnePomiMiniMachine.gameResumeFunc = nil
FourInOnePomiMiniMachine.gameRunPause = nil

FourInOnePomiMiniMachine.m_respinLittleNodeSize = 2

FourInOnePomiMiniMachine.m_respinEffectList = {}
FourInOnePomiMiniMachine.m_runNextRespinFunc = nil
FourInOnePomiMiniMachine.m_respinReelsShowRow = 3

FourInOnePomiMiniMachine.m_chipList = nil
FourInOnePomiMiniMachine.m_playAnimIndex = 0
FourInOnePomiMiniMachine.m_lightScore = 0

local parentScale = 1.66

local RESPIN_ROW_COUNT = 6
local NORMAL_ROW_COUNT = 3

local HowlingMoon_Reels = "HowlingMoon"
local Pomi_Reels = "Pomi"
local ChilliFiesta_Reels = "ChilliFiesta"
local Charms_Reels = "Charms"

-- 构造函数
function FourInOnePomiMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0

    self.m_bIsRespinOver = false
    self.m_bRespinNodeAnimation = false
end

function FourInOnePomiMiniMachine:initData_(data)
    self.gameResumeFunc = nil
    self.gameRunPause = nil

    self.m_reelType = data.reelType
    self.m_machineIndex = data.reelId
    self.m_parent = data.parent

    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function FourInOnePomiMiniMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FourInOne_Link_" .. self.m_reelType .. "Config.csv", "LevelFourInOne_Link_Pomi_Config.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)
end

-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FourInOnePomiMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FourInOne"
end

function FourInOnePomiMiniMachine:getMachineConfigName()
    local str = ""

    if self.m_reelType then
        str = "_Link_" .. self.m_reelType
    end

    return self.m_moduleName .. str .. "Config" .. ".csv"
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FourInOnePomiMiniMachine:MachineRule_GetSelfCCBName(symbolType)
    local ccbName = nil

    if self.SYMBOL_ChilliFiesta_A1 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_9"
    elseif self.SYMBOL_ChilliFiesta_A2 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_8"
    elseif self.SYMBOL_ChilliFiesta_A3 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_7"
    elseif self.SYMBOL_ChilliFiesta_A4 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_6"
    elseif self.SYMBOL_ChilliFiesta_A5 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_5"
    elseif self.SYMBOL_ChilliFiesta_B1 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_4"
    elseif self.SYMBOL_ChilliFiesta_B2 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_3"
    elseif self.SYMBOL_ChilliFiesta_B3 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_2"
    elseif self.SYMBOL_ChilliFiesta_B4 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_1"
    elseif self.SYMBOL_ChilliFiesta_B5 == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_10"
    elseif self.SYMBOL_ChilliFiesta_SC == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Scatter"
    elseif self.SYMBOL_ChilliFiesta_WILD == symbolType then
        return "4in1_Socre_ChilliFiesta_Wild"
    elseif self.SYMBOL_ChilliFiesta_BONUS == symbolType then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus"
    elseif symbolType == self.SYMBOL_ChilliFiesta_GRAND then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_2"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MAJOR then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_3"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MINOR then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_5"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MINI then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_4"
    elseif symbolType == self.SYMBOL_ChilliFiesta_ALL then
        return "LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_6"
    elseif self.SYMBOL_Charms_P1 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_9"
    elseif self.SYMBOL_Charms_P2 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_8"
    elseif self.SYMBOL_Charms_P3 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_7"
    elseif self.SYMBOL_Charms_P4 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_6"
    elseif self.SYMBOL_Charms_P5 == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_5"
    elseif self.SYMBOL_Charms_Ace == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_4"
    elseif self.SYMBOL_Charms_King == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_3"
    elseif self.SYMBOL_Charms_Queen == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_2"
    elseif self.SYMBOL_Charms_Jack == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_1"
    elseif self.SYMBOL_Charms_Scatter == symbolType then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Scatter"
    elseif self.SYMBOL_Charms_Wild == symbolType then
        return "4in1_Socre_Charms_Wild"
    elseif self.SYMBOL_Charms_bonus == math.abs(symbolType) then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_2"
    elseif symbolType == self.SYMBOL_Charms_UNLOCK_SYMBOL then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_" .. math.random(1, 4)
    elseif symbolType == self.SYMBOL_Charms_NULL_LOCK_SYMBOL then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_" .. math.random(1, 4)
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_DOUBLE then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_3"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_MINOR then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_minor"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_MINOR_DOUBLE then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_minor"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_MINI then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_mini"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_BOOM then
        return "4in1_Socre_Charms_Boom1"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_NULL then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_NULL"
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_BOOM_RUN then
        return "4in1_Socre_Charms_Boom1"
    elseif self.SYMBOL_HowlingMoon_Wild == symbolType then
        return "4in1_Socre_HowlingMoon_Wild"
    elseif self.SYMBOL_HowlingMoon_H1 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_9"
    elseif self.SYMBOL_HowlingMoon_H2 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_8"
    elseif self.SYMBOL_HowlingMoon_H3 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_7"
    elseif self.SYMBOL_HowlingMoon_L1 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_6"
    elseif self.SYMBOL_HowlingMoon_L2 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_5"
    elseif self.SYMBOL_HowlingMoon_L3 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_4"
    elseif self.SYMBOL_HowlingMoon_L4 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_3"
    elseif self.SYMBOL_HowlingMoon_L5 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_2"
    elseif self.SYMBOL_HowlingMoon_L6 == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_1"
    elseif self.SYMBOL_HowlingMoon_SC == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Scatter"
    elseif self.SYMBOL_HowlingMoon_Bonus == symbolType then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_light"
    elseif symbolType == self.SYMBOL_HowlingMoon_MINI then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Bonus_mini"
    elseif symbolType == self.SYMBOL_HowlingMoon_MINOR then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Bonus_minor"
    elseif symbolType == self.SYMBOL_HowlingMoon_MAJOR then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Bonus_major"
    elseif symbolType == self.SYMBOL_HowlingMoon_GRAND then
        return "LinkReels/HowlingMoonLink/4in1_Socre_HowlingMoon_Bonus_grand"
    elseif self.SYMBOL_Pomi_Scatter == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Scatter"
    elseif self.SYMBOL_Pomi_H1 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_9"
    elseif self.SYMBOL_Pomi_H2 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_8"
    elseif self.SYMBOL_Pomi_H3 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_7"
    elseif self.SYMBOL_Pomi_H4 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_6"
    elseif self.SYMBOL_Pomi_L1 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_5"
    elseif self.SYMBOL_Pomi_L2 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_4"
    elseif self.SYMBOL_Pomi_L3 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_3"
    elseif self.SYMBOL_Pomi_L4 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_2"
    elseif self.SYMBOL_Pomi_L5 == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_1"
    elseif self.SYMBOL_Pomi_Wild == symbolType then
        return "4in1_Socre_Pomi_Wild"
    elseif self.SYMBOL_Pomi_Bonus == symbolType then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Num"
    elseif symbolType == self.SYMBOL_Pomi_GRAND then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Grand"
    elseif symbolType == self.SYMBOL_Pomi_MAJOR then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Major"
    elseif symbolType == self.SYMBOL_Pomi_MINOR then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Minor"
    elseif symbolType == self.SYMBOL_Pomi_MINI then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_Bonus_Mini"
    elseif symbolType == self.SYMBOL_Pomi_Reel_Up then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_reel_up"
    elseif symbolType == self.SYMBOL_Pomi_Double_bet then
        return "LinkReels/PomiLink/4in1_Socre_Pomi_DoubleBet"
    end

    return ccbName
end

---
-- 读取配置文件数据
--
function FourInOnePomiMiniMachine:readCSVConfigData()
    --读取csv配置
    -- if self.m_configData == nil then
    --     self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelFourInOne_Link_Pomi_Config.lua")
    -- end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function FourInOnePomiMiniMachine:initMachineCSB()
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("LinkReels/" .. self.m_reelType .. "Link/" .. "4in1_" .. self.m_reelType .. "_link_reel.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function FourInOnePomiMiniMachine:initMachine()
    self.m_moduleName = "FourInOne" -- self:getModuleName()

    BaseMiniMachine.initMachine(self)

    self:initMachineBg()
    self:initSelfUI()
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FourInOnePomiMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_A1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_A2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_A3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_A4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_A5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_B1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_B2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_B3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_B4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_B5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_SC, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_WILD, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_BONUS, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_ALL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_GRAND, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_ChilliFiesta_MINI, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_P1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_P2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_P3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_P4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_P5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_Ace, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_King, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_Queen, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_Jack, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_Scatter, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_Wild, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_bonus, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = -self.SYMBOL_Charms_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = -self.SYMBOL_Charms_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_MINOR_DOUBLE, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_SYMBOL_DOUBLE, count = 2}
    loadNode[#loadNode + 1] = {symbolType = -self.SYMBOL_Charms_MINOR_DOUBLE, count = 2}
    loadNode[#loadNode + 1] = {symbolType = -self.SYMBOL_Charms_SYMBOL_DOUBLE, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_SYMBOL_BOOM, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_SYMBOL_NULL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_SYMBOL_BOOM_RUN, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_UNLOCK_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_NULL_LOCK_SYMBOL, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_Wild, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_H1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_H2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_H3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_L1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_L2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_L3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_L4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_L5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_L6, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_SC, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_Bonus, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_HowlingMoon_GRAND, count = 2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_Scatter, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_H1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_H2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_H3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_H4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_L1, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_L2, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_L3, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_L4, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_L5, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_Wild, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_Bonus, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_GRAND, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_MAJOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_MINOR, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_MINI, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_Reel_Up, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Pomi_Double_bet, count = 2}

    return loadNode
end

----------------------------- 玩法处理 -----------------------------------

function FourInOnePomiMiniMachine:addSelfEffect()
end

function FourInOnePomiMiniMachine:MachineRule_playSelfEffect(effectData)
    return true
end

function FourInOnePomiMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function FourInOnePomiMiniMachine:checkNotifyUpdateWinCoin()
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

function FourInOnePomiMiniMachine:getVecGetLineInfo()
    return self.m_vecGetLineInfo
end

function FourInOnePomiMiniMachine:addObservers()
    BaseMiniMachine.addObservers(self)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:reSpinReelDown()
        end,
        ViewEventType.NOTIFY_RESPIN_RUN_STOP
    )

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            Target:MachineRule_respinTouchSpinBntCallBack()
        end,
        ViewEventType.RESPIN_TOUCH_SPIN_BTN
    )
end

function FourInOnePomiMiniMachine:beginMiniReel()
    BaseMiniMachine.beginReel(self)
end

-- 消息返回更新数据
function FourInOnePomiMiniMachine:netWorkCallFun(spinResult)
    self.m_runSpinResultData:parseResultData(spinResult, self.m_lineDataPool)

    self:updateNetWorkData()
end

function FourInOnePomiMiniMachine:enterLevel()
    -- BaseMiniMachine.enterLevel(self)
end

function FourInOnePomiMiniMachine:enterSelfLevel()
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传

    self.m_initSpinData = self.m_runSpinResultData

    self:MachineRule_initGame(self.m_initSpinData)

    if self.m_jackpotList ~= nil then
        self:initJackpotInfo(self.m_jackpotList, self.m_initBetId)
    end

    self:initCloumnSlotNodesByNetData()

    if #self.m_gameEffects > 0 then
        self:sortGameEffects()
        self:playGameEffect()
    end
end

function FourInOnePomiMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage(GAME_MODE_ONE_RUN)
    self:perpareStopReel()
end

-- 处理特殊关卡 遮罩层级
function FourInOnePomiMiniMachine:changeSlotsParentZOrder(zOrder, parentData, slotParent)
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

function FourInOnePomiMiniMachine:getResultLines()
    return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end

function FourInOnePomiMiniMachine:checkGameResumeCallFun()
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

function FourInOnePomiMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FourInOnePomiMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
    self.gameRunPause = true
    -- end
end

function FourInOnePomiMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

-- *********** respin赋值相关

function FourInOnePomiMiniMachine:isScoreFixSymbol(symbolType)
    if symbolType == self.SYMBOL_ChilliFiesta_BONUS then
        return true
    elseif math.abs(symbolType) == self.SYMBOL_Charms_bonus then
        return true
    elseif symbolType == self.SYMBOL_HowlingMoon_Bonus then
        return true
    elseif symbolType == self.SYMBOL_Pomi_Bonus then
        return true
    end

    return false
end

function FourInOnePomiMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isScoreFixSymbol(symbolType) then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
        self:setSpecialNodeScore(self, {node})
    end
    if symbolType == self.SYMBOL_Pomi_Double_bet then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeBet),{node})
        -- self:runAction(callFun)
        self:setSpecialNodeBet(self, {node})
    end
end

function FourInOnePomiMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniMachine.setSlotCacheNodeWithPosAndType(self, node, symbolType, row, col, isLastSymbol)

    if self:isScoreFixSymbol(symbolType) then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeScore), {node})
        self:runAction(callFun)
    end

    if symbolType == self.SYMBOL_Pomi_Double_bet then
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self, self.setSpecialNodeBet), {node})
        self:runAction(callFun)
    end
end

-- ***********  小块层级相关

function FourInOnePomiMiniMachine:getScatterSymbolType()
    return self.SYMBOL_Pomi_Scatter
end

function FourInOnePomiMiniMachine:isScatterSymbolType(symbolType)
    local scatterList = {
        self.SYMBOL_ChilliFiesta_SC,
        self.SYMBOL_Charms_Scatter,
        self.SYMBOL_HowlingMoon_SC,
        self.SYMBOL_Pomi_Scatter
    }

    for i = 1, #scatterList do
        local scatterType = scatterList[i]
        if symbolType == scatterType then
            return true
        end
    end

    return false
end

function FourInOnePomiMiniMachine:isBonusSymbolType(symbolType)
    local bonusList = {
        self.SYMBOL_ChilliFiesta_BONUS,
        self.SYMBOL_ChilliFiesta_ALL,
        self.SYMBOL_ChilliFiesta_GRAND,
        self.SYMBOL_ChilliFiesta_MAJOR,
        self.SYMBOL_ChilliFiesta_MINOR,
        self.SYMBOL_ChilliFiesta_MINI,
        self.SYMBOL_Charms_bonus,
        self.SYMBOL_Charms_MINOR,
        self.SYMBOL_Charms_MINI,
        self.SYMBOL_Charms_SYMBOL_DOUBLE,
        self.SYMBOL_Charms_SYMBOL_BOOM,
        self.SYMBOL_Charms_MINOR_DOUBLE,
        self.SYMBOL_Charms_SYMBOL_NULL,
        self.SYMBOL_Charms_SYMBOL_BOOM_RUN,
        self.SYMBOL_HowlingMoon_Bonus,
        self.SYMBOL_HowlingMoon_MINI,
        self.SYMBOL_HowlingMoon_MINOR,
        self.SYMBOL_HowlingMoon_MAJOR,
        self.SYMBOL_HowlingMoon_GRAND,
        self.SYMBOL_Pomi_Bonus,
        self.SYMBOL_Pomi_GRAND,
        self.SYMBOL_Pomi_MAJOR,
        self.SYMBOL_Pomi_MINOR,
        self.SYMBOL_Pomi_MINI,
        self.SYMBOL_Pomi_Reel_Up,
        self.SYMBOL_Pomi_Double_bet
    }

    for i = 1, #bonusList do
        local bonusType = bonusList[i]
        if math.abs(symbolType) == bonusType then
            return true
        end
    end

    return false
end

function FourInOnePomiMiniMachine:isWildSymbolType(symbolType)
    local wildList = {
        self.SYMBOL_ChilliFiesta_WILD,
        self.SYMBOL_Charms_Wild,
        self.SYMBOL_HowlingMoon_Wild,
        self.SYMBOL_Pomi_Wild
    }

    for i = 1, #wildList do
        local wildType = wildList[i]
        if symbolType == wildType then
            return true
        end
    end

    return false
end

---
--设置bonus scatter 层级
function FourInOnePomiMiniMachine:getBounsScatterDataZorder(symbolType)
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1

    local order = 0
    if self:isScatterSymbolType(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    elseif self:isBonusSymbolType(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif self:isWildSymbolType(symbolType) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else
        if symbolType < self:getScatterSymbolType() then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (self:getScatterSymbolType() - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order
end

---
-- 根据类型获取对应节点
--
function FourInOnePomiMiniMachine:getSlotNodeBySymbolType(symbolType)
    local reelNode = nil
    if #self.m_reelNodePool == 0 then
        -- print("创建 SlotNode")
        local node = require(self:getBaseReelGridNode()):create()
        node:retain() -- 由于还会放到内存池 所以retain保留， 退出时卸载
        reelNode = node
    else
        local node = self.m_reelNodePool[1] -- 存内存池取出来
        table.remove(self.m_reelNodePool, 1)
        reelNode = node
    end
    reelNode:setMachine(self)
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

--小块
function FourInOnePomiMiniMachine:getBaseReelGridNode()
    return "CodeFourInOneSrc.FourInOneSlotFastNode"
end

-- respin 玩法处理
function FourInOnePomiMiniMachine:createLocalAnimation()
    local pos = cc.p(self.m_parent.m_bottomUI.m_normalWinLabel:getPosition())

    -- self.m_respinEndActiom =  util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiViewWinCoinsAction")
    -- self.m_parent.m_bottomUI.m_normalWinLabel:getParent():addChild(self.m_respinEndActiom,99999)
    -- self.m_respinEndActiom:setPosition(cc.p(pos.x ,pos.y - 8))

    -- self.m_respinEndActiom:setVisible(false)
end

-- 继承底层respinView
function FourInOnePomiMiniMachine:getRespinView()
    return "CodeFourInOneSrc.LinkReels.PomiSrc.PomiRespinView"
end
-- 继承底层respinNode
function FourInOnePomiMiniMachine:getRespinNode()
    return "CodeFourInOneSrc.LinkReels.PomiSrc.PomiRespinNode"
end
-- 根据网络数据获得respinBonus小块的分数
function FourInOnePomiMiniMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

    for i = 1, #storedIcons do
        local values = storedIcons[i]
        if values[1] == id then
            score = values[2]
            idNode = values[1]
        end
    end

    if idNode then
        local pos = self:getRowAndColByPos(idNode)
        local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        if symbolType == self.SYMBOL_Pomi_MINI then
            score = "MINI"
        elseif symbolType == self.SYMBOL_Pomi_MINOR then
            score = "MINOR"
        elseif symbolType == self.SYMBOL_Pomi_MAJOR then
            score = "MAJOR"
        elseif symbolType == self.SYMBOL_Pomi_GRAND then
            score = "GRAND"
        end

        if type(score) == "number" and score < 0 then
            -- 安全保护
            score = nil
        end
    end

    return score
end

function FourInOnePomiMiniMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_Pomi_Bonus then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

function FourInOnePomiMiniMachine:getSpecialNodeBetNum(iCol, iRow)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local index = self:getPosReelIdx(iRow, iCol)
    local bet = nil
    if rsExtraData then
        local multiple = rsExtraData.multiple

        if multiple then
            for k, v in pairs(multiple) do
                local posIndex = v.position
                if index == posIndex then
                    if v.mult then
                        bet = v.mult

                        return bet
                    end
                end
            end
        end
    end

    return bet
end

-- 给respin小块进行赋值
function FourInOnePomiMiniMachine:setSpecialNodeBet(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    if symbolNode and symbolNode.p_symbolType then
        local bet = math.random(1, 3)
        if iCol and iRow then
            bet = self:getSpecialNodeBetNum(iCol, iRow) or math.random(1, 3)
        end

    --    local lab =  symbolNode:getCcbProperty("m_lb_bet")
    --    if lab then
    --         lab:setString("X"..bet)
    --    end
    end
end

function FourInOnePomiMiniMachine:changeFixSocreForDoubleBetGame(posIndex, score)
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local backScore = score
    if rsExtraData then
        local multiple = rsExtraData.multiple
        if multiple then
            for k, v in pairs(multiple) do
                local multipleData = v
                local bet = multipleData.mult
                local multPositionList = multipleData.multPosition
                if multPositionList then
                    for kk, netpos in pairs(multPositionList) do
                        if netpos == posIndex then
                            backScore = score / bet
                        end
                    end
                end
            end
        end
    end

    return backScore
end

-- 给respin小块进行赋值
function FourInOnePomiMiniMachine:setSpecialNodeScore(sender, param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local posIndex = self:getPosReelIdx(iRow, iCol)
        local score = self:getReSpinSymbolScore(posIndex) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            score = score * lineBet
            if score < 0 then
                print("1212121")
            end

            local lb = symbolNode:getCcbProperty("m_lb_score")
            local lb1 = symbolNode:getCcbProperty("m_lb_score1")

            score = self:changeFixSocreForDoubleBetGame(posIndex, score)

            if lb then
                if (score / lineBet) >= 8 then
                    lb:setVisible(false)
                    lb1:setVisible(true)
                else
                    lb:setVisible(true)
                    lb1:setVisible(false)
                end

                score = util_formatCoins(score, 3)

                lb:setString(score)
                lb1:setString(score)
            end
        end
    else
        local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            if score == nil then
                score = 1
            end

            score = score * lineBet
            local lb = symbolNode:getCcbProperty("m_lb_score")
            local lb1 = symbolNode:getCcbProperty("m_lb_score1")

            if lb then
                if (score / lineBet) >= 8 then
                    lb:setVisible(false)
                    lb1:setVisible(true)
                else
                    lb:setVisible(true)
                    lb1:setVisible(false)
                end

                score = util_formatCoins(score, 3)

                lb:setString(score)
                lb1:setString(score)
            end
        end
    end
end

-- 是不是 respinBonus小块
function FourInOnePomiMiniMachine:isFixSymbol(symbolType)
    if
        symbolType == self.SYMBOL_Pomi_Bonus or symbolType == self.SYMBOL_Pomi_MINI or symbolType == self.SYMBOL_Pomi_MINOR or symbolType == self.SYMBOL_Pomi_MAJOR or
            symbolType == self.SYMBOL_Pomi_GRAND or
            symbolType == self.SYMBOL_Pomi_Reel_Up or
            symbolType == self.SYMBOL_Pomi_Double_bet
     then
        return true
    end
    return false
end

function FourInOnePomiMiniMachine:showRespinJackpot(index, coins, func)
    -- gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_common_viewOpen.mp3")

    self.m_parent:showJackpotView(index, coins, func)
end

-- 结束respin收集
function FourInOnePomiMiniMachine:playLightEffectEnd()
    self:showRespinOverView()
end

function FourInOnePomiMiniMachine:getEndChip()
    return self.m_chipList
end

function FourInOnePomiMiniMachine:playChipCollectAnim()
    local m_chipList = self:getEndChip()

    if self.m_playAnimIndex > #m_chipList then --- 这里待确认  是否中了grand 其他小块就不赢钱
        scheduler.performWithDelayGlobal(
            function()
                self:playLightEffectEnd()
            end,
            0.1,
            self:getModuleName()
        )

        return
    end

    local chipNode = m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(), chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol

    -- 根据网络数据获得当前固定小块的分数
    local scoreIndx = self:getPosReelIdx(iRow, iCol)
    local score = self:getReSpinSymbolScore(scoreIndx)

    local addScore = 0
    local isJackpot = 0
    local jackpotScore = 0
    local nJackpotType = 0

    local lineBet = globalData.slotRunData:getCurTotalBet() / 4

    if score ~= nil then
        if type(score) ~= "string" then
            addScore = score * lineBet
        elseif score == "GRAND" then
            jackpotScore = self.m_parent:BaseMania_getJackpotScore(1)
            addScore = jackpotScore + addScore
            nJackpotType = 1
        elseif score == "MAJOR" then
            jackpotScore = self.m_parent:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 2
        elseif score == "MINOR" then
            jackpotScore = self.m_parent:BaseMania_getJackpotScore(3)
            addScore = jackpotScore + addScore
            nJackpotType = 3
        elseif score == "MINI" then
            jackpotScore = self.m_parent:BaseMania_getJackpotScore(4)
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
                    self:playChipCollectAnim()
                end
            )
        end
    end

    -- 添加鱼飞行轨迹
    local function fishFly()
        gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_Bonus_collect_coins.mp3")

        chipNode:runAnim(
            "jiesuan",
            false,
            function()
                chipNode:runAnim("idle", true)
            end
        )
        local noverAnimTime = chipNode:getAniamDurationByName("jiesuan")

        self.m_parent:playCoinWinEffectUI()

        if self.m_bProduceSlots_InFreeSpin then
            local coins = self.m_lightScore
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        else
            local coins = self.m_lightScore
            local lastWinCoin = globalData.slotRunData.lastWinCoin
            globalData.slotRunData.lastWinCoin = 0
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {coins, false, false})
            globalData.slotRunData.lastWinCoin = lastWinCoin
        end

        scheduler.performWithDelayGlobal(
            function()
                fishFlyEndJiesuan()
            end,
            0.4,
            self:getModuleName()
        )
    end

    fishFly()
end

--结束移除小块调用结算特效
function FourInOnePomiMiniMachine:reSpinEndAction()
    self.m_parent:clearCurMusicBg()

    gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_respin_end.mp3")

    self.m_bIsRespinOver = true

    self.m_parent.m_respinOverRunning = true

    performWithDelay(
        self,
        function()
            -- 播放收集动画效果
            self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
            self.m_playAnimIndex = 1

            -- 获得所有固定的respinBonus小块
            self.m_chipList = self.m_respinView:getAllCleaningNode()

            self.m_PomiRespinBarView:setVisible(false)

            self:playChipCollectAnim()
        end,
        3
    )
end

-- 根据本关卡实际小块数量填写
function FourInOnePomiMiniMachine:getRespinRandomTypes()
    local symbolList = {
        self.SYMBOL_Pomi_H1,
        self.SYMBOL_Pomi_H2,
        self.SYMBOL_Pomi_H3,
        self.SYMBOL_Pomi_H4,
        self.SYMBOL_Pomi_L1,
        self.SYMBOL_Pomi_L2,
        self.SYMBOL_Pomi_L3,
        self.SYMBOL_Pomi_L4,
        self.SYMBOL_Pomi_L5
    }

    return symbolList
end

function FourInOnePomiMiniMachine:showReSpinStart()
    self.isInBonus = true

    -- 更改respin 状态下的背景音乐
    self:runNextReSpinReel()
    if self.m_respinReelsShowRow >= RESPIN_ROW_COUNT then
        self.m_respinView:changeNodeRunningData()
    end
end

-- 根据本关卡实际锁定小块数量填写
function FourInOnePomiMiniMachine:getRespinLockTypes()
    local symbolList = {
        {type = self.SYMBOL_Pomi_GRAND, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_Pomi_Bonus, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_Pomi_MAJOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_Pomi_MINI, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_Pomi_MINOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_Pomi_Reel_Up, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_Pomi_Double_bet, runEndAnimaName = "", bRandom = true}
    }

    return symbolList
end

function FourInOnePomiMiniMachine:showRespinView()
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes()

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()

    self.m_iReelRowNum = RESPIN_ROW_COUNT
    self:respinChangeReelGridCount(RESPIN_ROW_COUNT)

    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)
end

function FourInOnePomiMiniMachine:chnangeRespinBg()
    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    if rsExtraData then
        local minRow = rsExtraData.rows
        if minRow then
            self:changeReelsBg(minRow)
            self:changeRespinLines(minRow)
            self.m_PomiRespinLinesView:setVisible(true)
            self.m_respinReelsShowRow = minRow
        end
    end
end

--ReSpin开始改变UI状态
function FourInOnePomiMiniMachine:changeReSpinStartUI(respinCount)
    self.m_PomiRespinBarView:setVisible(true)
    self.m_PomiRespinBarView:updateRespinLeftTimnes(respinCount, false)

    self:chnangeRespinBg()
    -- local Node_Mini = self.m_jackPorBar:findChild("Node_Mini")
    -- local Node_Minior =  self.m_jackPorBar:findChild("Node_Minior")
    -- Node_Mini:setVisible(false)
    -- Node_Minior:setVisible(false)
end

--ReSpin刷新数量
function FourInOnePomiMiniMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_PomiRespinBarView:setVisible(true)
    self.m_PomiRespinBarView:updateRespinLeftTimnes(curCount, true)
end

--ReSpin结算改变UI状态
function FourInOnePomiMiniMachine:changeReSpinOverUI()
    self.m_PomiRespinBarView:setVisible(false)
    self:changeReelsBg(3)
    if self.m_PomiRespinLinesView then
        self.m_PomiRespinLinesView = nil
    end

    self.m_respinReelsShowRow = 3

    -- local Node_Mini = self.m_jackPorBar:findChild("Node_Mini")
    -- local Node_Minior =  self.m_jackPorBar:findChild("Node_Minior")
    -- Node_Mini:setVisible(true)
    -- Node_Minior:setVisible(true)
end

function FourInOnePomiMiniMachine:triggerReSpinOverCallFun(score)
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

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
        local addCoin = self.m_serverWinCoins
        coins = self:getLastWinCoin() or 0
        -- self:updateNotifyFsTopCoins(self.m_serverWinCoins)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self:getLastWinCoin(), false, false})
    else
        coins = self.m_serverWinCoins or 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, {self.m_serverWinCoins, false, false})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
    end

    if self.postReSpinOverTriggerBigWIn then
        self:postReSpinOverTriggerBigWIn(coins)
    end

    --播放下轮动画
    self:triggerRespinComplete()
    self:resetReSpinMode()
    self:playGameEffect()
    --  gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount,false})
    self:resetMusicBg(true)
    -- self:setLastWinCoin( self:getLastWinCoin() + self.m_iReSpinScore )
    -- self:changeReSpinOverUI()
    self.m_iReSpinScore = 0

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or self:getCurrSpinMode() == FREE_SPIN_MODE or self.m_bProduceSlots_InFreeSpin then
        --不做处理
    else
        --停掉屏幕长亮
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.KEEP_SCREEN_OFF)
    end
end

--播放respin放回滚轴后播放的提示动画
function FourInOnePomiMiniMachine:checkRespinChangeOverTip(node, endAnimaName, loop)
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    end
    if node.p_symbolType and self:isFixSymbol(node.p_symbolType) then
        node:runAnim("over", true)
    else
        node:runAnim("idleframe")
    end
end

function FourInOnePomiMiniMachine:showRespinOverView(effectData)
    self.m_bIsRespinOver = false
    self.m_bRespinNodeAnimation = true
    gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_common_viewOpen.mp3")

    -- self.m_respinEndActiom:removeFromParent()

    local strCoins = self.m_lightScore

    self.m_parent:showRespinOverView(strCoins)
end

--接收到数据开始停止滚动
function FourInOnePomiMiniMachine:checkSpecialSymbolType(iCol, iRow)
    local SymbolType = nil

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    if rsExtraData then
        local addSignalPosition = rsExtraData.addSignalPosition

        if addSignalPosition then
            for k, v in pairs(addSignalPosition) do
                local posIndex = v
                local fixPos = self:getRowAndColByPos(posIndex)
                if (fixPos.iX == iRow) and (fixPos.iY == iCol) then
                    -- 升行图标本地转换
                    SymbolType = self.SYMBOL_Pomi_Reel_Up
                    return SymbolType
                end
            end
        end

        local multiple = rsExtraData.multiple
        if multiple then
            for k, v in pairs(multiple) do
                local posIndex = v.position
                local fixPos = self:getRowAndColByPos(posIndex)
                if (fixPos.iX == iRow) and (fixPos.iY == iCol) then
                    -- 翻倍图标本地转换
                    SymbolType = self.SYMBOL_Pomi_Double_bet
                    return SymbolType
                end
            end
        end
    end

    return SymbolType
end

function FourInOnePomiMiniMachine:getRespinReelsButStored(storedInfo)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            local type = self:getMatrixPosSymbolType(iRow, iCol)
            local a = self:getPosReelIdx(iRow, iCol)
            local specialType = self:checkSpecialSymbolType(iCol, iRow)
            if specialType then
                type = specialType
            end

            if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
            end
        end
    end
    return reelData
end

-- --重写组织respinData信息
function FourInOnePomiMiniMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}

    for i = 1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)
        local specialType = self:checkSpecialSymbolType(pos.iY, pos.iX)
        if specialType then
            type = specialType
        end

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function FourInOnePomiMiniMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do
            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            if self:isScatterSymbolType(symbolType) then
                symbolType = self.SYMBOL_Pomi_H1
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 10 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth / 2 * (self.m_parent.m_machineRootScale * parentScale)
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * (self.m_parent.m_machineRootScale * parentScale)

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

function FourInOnePomiMiniMachine:getPosReelIdx(iRow, iCol)
    local iReelRow = #self.m_runSpinResultData.p_reels

    local index = (iReelRow - iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

function FourInOnePomiMiniMachine:respinChangeReelGridCount(count)
    for i = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end

---- lighting 断线重连时，随机转盘数据
function FourInOnePomiMiniMachine:respinModeChangeSymbolType()
    if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
        if self.m_runSpinResultData.p_reSpinCurCount > 0 then
            self.m_iReelRowNum = RESPIN_ROW_COUNT
            self:respinChangeReelGridCount(RESPIN_ROW_COUNT)
        end
    end
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node
--
function FourInOnePomiMiniMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    self:respinModeChangeSymbolType()
    for colIndex = self.m_iReelColumnNum, 1, -1 do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount
        local rowIndex = rowNum -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false
        local beginIndex = 1
        if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
            if self.m_runSpinResultData.p_reSpinCurCount > 0 then
                beginIndex = 4 --  断线的时候respin  只从 后三行数据读取，初始化轮盘
            end
        end

        while rowIndex >= beginIndex do
            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            -- 检测是否为长条模式
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP = true
                end
                for checkRowIndex = changeRowIndex + 1, rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if checkIndex == rowNum then
                                -- body
                                isUP = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break
                    end
                end -- end for check
                stepCount = sameCount
                if isUP then
                    -- body
                    changeRowIndex = sameCount - symbolCount + 1
                end
            end -- end self.m_bigSymbol

            -- grid.m_reelBottom

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
            -- node:runIdleAnim()
            rowIndex = rowIndex - stepCount
        end -- end while
    end
    self:initGridList()
end

function FourInOnePomiMiniMachine:getRespinAddNum()
    local num = 0
    if self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        num = 3
        return num
    end
    return num
end

--- respin下 6行的情况
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function FourInOnePomiMiniMachine:getRowAndColByPosForSixRow(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = RESPIN_ROW_COUNT - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex, iY = colIndex}
end

function FourInOnePomiMiniMachine:initRespinView(endTypes, randomTypes)
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
    self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
    self.m_parent.m_bottomUI:updateWinCount("")
    self.m_respinView:setVisible(true)
end

--触发respin
function FourInOnePomiMiniMachine:triggerReSpinCallFun(endTypes, randomTypes)
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    self:setCurrSpinMode(RESPIN_MODE)
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType, iRow, iCol, isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType, iRow, iCol, isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)
    self.m_respinView:initMachine(self)

    self.m_PomiRespinLinesView = util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiRespinLinesView")
    self.m_PomiRespinLinesView:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 1)
    self.m_respinView:addChild(self.m_PomiRespinLinesView, 101)
    self.m_PomiRespinLinesView:setVisible(false)
    self.m_PomiRespinLinesView:setPosition(cc.p(self:findChild("respinLines"):getPosition()))

    self:initRespinView(endTypes, randomTypes)
end

function FourInOnePomiMiniMachine:checkTriggerRespin()
    local features = self.m_runSpinResultData.p_features

    for k, v in pairs(features) do
        if v == 3 then
            return true
        end
    end

    return false
end

function FourInOnePomiMiniMachine:getValidSymbolMatrixArray()
    return table_createTwoArr(6, 5, TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

--开始下次ReSpin
function FourInOnePomiMiniMachine:runNextReSpinReel(_isDownStates)
    if globalData.slotRunData.gameRunPause then
        globalData.slotRunData.gameResumeFunc = function()
            if self.runNextReSpinReel then
                self:runNextReSpinReel()
            end
        end
        return
    end

    self.m_respinView:updateShowSlotsRespinNode()

    self.m_beginStartRunHandlerID =
        scheduler.performWithDelayGlobal(
        function()
            if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
                self:startReSpinRun()
            end
            self.m_beginStartRunHandlerID = nil
        end,
        self.m_RESPIN_RUN_TIME,
        self:getModuleName()
    )
    if _isDownStates then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
    end
end

function FourInOnePomiMiniMachine:startReSpinRun()
    FourInOnePomiMiniMachine.super.startReSpinRun(self)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_parent.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_parent.m_startSpinTime = nil
        end
    end
end

function FourInOnePomiMiniMachine:changeRespinLines(minRow)
    if self.m_PomiRespinLinesView then
        for i = 6, 1, -1 do
            local name = "Panel_" .. i
            local line = self.m_PomiRespinLinesView:findChild(name)
            if line then
                if i <= minRow then
                    line:setVisible(true)
                else
                    line:setVisible(false)
                end
            end
        end
    end
end

function FourInOnePomiMiniMachine:changeReelsBgAct(minRow, time, changeY)
    if minRow < 3 then
        minRow = 3
    end

    local addSizeY = math.ceil(changeY / (time * 100))
    local addNowY = 0
    local lastSizeY = (minRow - 1) * changeY

    self.m_ReelsBgActHandlerID =
        scheduler.scheduleGlobal(
        function(delayTime)
            addNowY = addNowY + addSizeY

            if addNowY > changeY then
                addNowY = changeY
            end

            for i = 1, 5 do
                local nodeName = "reel_bg_" .. i - 1
                local bg_Y = self:findChild(nodeName):getContentSize()
                self:findChild(nodeName):setContentSize(66, bg_Y.height + addSizeY)
            end

            self:findChild("Panel_2"):setContentSize(344, self:findChild("Panel_2"):getContentSize().height + addSizeY)
            self:findChild("respinbar"):setPositionY(self:findChild("respinbar"):getPositionY() + addSizeY)

            if addNowY >= changeY then
                self:changeReelsBg(minRow)
                self:changeRespinLines(minRow)
                if self.m_respinReelsShowRow >= RESPIN_ROW_COUNT then
                    self.m_respinView:changeNodeRunningData()
                end
                if self.m_ReelsBgActHandlerID then
                    scheduler.unscheduleGlobal(self.m_ReelsBgActHandlerID)
                    self.m_ReelsBgActHandlerID = nil
                end
            end
        end,
        0.01
    )
end

function FourInOnePomiMiniMachine:changeReelsBg(minRow)
    if minRow < 3 then
        minRow = 3
    end

    local baseY = 180
    local addY = (baseY / 3) * (minRow - 3)
    local newY = baseY + addY
    local panelY = 186 + addY

    for i = 1, 5 do
        local nodeName = "reel_bg_" .. i - 1
        self:findChild(nodeName):setContentSize(66, newY)
    end

    self:findChild("Panel_2"):setContentSize(344, panelY)

    local basePosY = self.m_respinBarPosY or -293.00
    local addPosY = basePosY + addY
    self:findChild("respinbar"):setPositionY(addPosY)
end

---判断结算
function FourInOnePomiMiniMachine:reSpinReelDown(addNode)
    -- respin所有滚动结束
    self.m_runNextRespinFunc = function()
        self.m_parent:reSpinSelfReelDown(addNode)
    end

    self:addRespinGameEffect()

    performWithDelay(
        self,
        function()
            self:playRespinEffect()
        end,
        1.3
    )
end

function FourInOnePomiMiniMachine:addRespinGameEffect()
    -- 全部停止播放升行或者翻倍动画
    -- 先升行在翻倍
    -- 存储上respin动画序列
    self.m_respinEffectList = {}

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData

    if rsExtraData then
        local addSignalPosition = rsExtraData.addSignalPosition

        if addSignalPosition then
            for k, v in pairs(addSignalPosition) do
                local effectData = {}
                effectData.m_isplay = false
                effectData.m_playType = self.SYMBOL_Pomi_Reel_Up
                effectData.m_index = k
                table.insert(self.m_respinEffectList, effectData)
            end
        end

        local multiple = rsExtraData.multiple
        if multiple then
            for k, v in pairs(multiple) do
                local effectData = {}
                effectData.m_isplay = false
                effectData.m_playType = self.SYMBOL_Pomi_Double_bet
                effectData.m_index = k
                table.insert(self.m_respinEffectList, effectData)
            end
        end
    end
end

function FourInOnePomiMiniMachine:playRespinEffect()
    if self.m_respinEffectList == nil or #self.m_respinEffectList == 0 then
        if self.m_runNextRespinFunc then
            self.m_runNextRespinFunc()
        end
        return
    end

    for k, v in pairs(self.m_respinEffectList) do
        local effectData = v

        if effectData.m_isplay == false then
            if effectData.m_playType == self.SYMBOL_Pomi_Reel_Up then
                self:respinEffect_ReelUp(effectData)
            elseif effectData.m_playType == self.SYMBOL_Pomi_Double_bet then
                self:respinEffect_DoubleBset(effectData)
            end

            break
        end

        -- 所有动画时间已经全部播放完毕
        if k == #self.m_respinEffectList and effectData.m_isplay == true then
            if self.m_runNextRespinFunc then
                self.m_runNextRespinFunc()
            end

            return
        end
    end
end

function FourInOnePomiMiniMachine:getCleaningRespinFixSymbol(index)
    local nodeList = self.m_respinView:getAllCleaningNode()
    local node = nil
    for k, v in pairs(nodeList) do
        local node = v

        local nodeIndex = self:getPosReelIdx(node.p_rowIndex, node.p_cloumnIndex)
        if index == nodeIndex then
            node = v
            return node
        end
    end
    return node
end

function FourInOnePomiMiniMachine:getRespinFixSymbol(index)
    local nodeList = self.m_respinView.m_respinNodes
    local node = nil
    for k, v in pairs(nodeList) do
        local node = v

        local nodeIndex = self:getPosReelIdx(node.p_rowIndex, node.p_colIndex)
        if index == nodeIndex then
            node = v
            return node
        end
    end
    return node
end

function FourInOnePomiMiniMachine:respinEffect_ReelUp(effectData)
    effectData.m_isplay = true

    self.m_respinReelsShowRow = self.m_respinReelsShowRow + 1

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local waitTime = 0
    if rsExtraData then
        local addSignalPosition = rsExtraData.addSignalPosition

        if addSignalPosition then
            for k, v in pairs(addSignalPosition) do
                if k == effectData.m_index then
                    local posIndex = v
                    local fixPos = self:getRowAndColByPos(posIndex)
                    local tarSp = self:getRespinFixSymbol(posIndex) -- self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    if tarSp and tarSp.m_lastNode then
                        gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_reelsUP_Trigger.mp3")

                        tarSp.m_lastNode:runAnim(
                            "actionframe",
                            false,
                            function()
                                tarSp.m_lastNode:runAnim("idle", true)
                            end
                        )
                        waitTime = 2 + 1.4 + 1

                        performWithDelay(
                            self,
                            function()
                                gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_ReelsUp_action.mp3")

                                local oldPos = cc.p(self:getPosition())

                                local actid = self:beginShake()

                                self.m_bgChangeAct:setVisible(true)
                                self.m_bgChangeAct:showOneActImg(self.m_respinReelsShowRow)
                                self.m_bgChangeAct:runCsbAction(
                                    "start",
                                    false,
                                    function()
                                        self.m_bgChangeAct:runCsbAction("idle", true)
                                    end,
                                    30
                                )

                                local time = 1

                                if self.m_respinReelsShowRow == 4 then
                                    time = 0.6
                                elseif self.m_respinReelsShowRow == 5 then
                                    time = 0.6
                                elseif self.m_respinReelsShowRow == 6 then
                                    time = 0.6
                                end

                                performWithDelay(
                                    self,
                                    function()
                                        self:changeReelsBgAct(self.m_respinReelsShowRow, 0.16, 60)
                                    end,
                                    time
                                )

                                self.m_gameBg:runCsbAction(
                                    "actionframe",
                                    false,
                                    function()
                                        self.m_gameBg:runCsbAction("idleframe", true)
                                    end
                                )

                                performWithDelay(
                                    self,
                                    function()
                                        self.m_respinView:updateShowSlotsRespinNodeForRow(self.m_respinReelsShowRow)
                                    end,
                                    1.8
                                )

                                performWithDelay(
                                    self,
                                    function()
                                        self:stopAction(actid)
                                        self:setPosition(oldPos)
                                    end,
                                    2
                                )

                                performWithDelay(
                                    self,
                                    function()
                                        local lab = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                        local lab1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                        local score = self:getReSpinSymbolScore(posIndex)
                                        local changeSymbolType = self.SYMBOL_Pomi_Bonus

                                        if lab then
                                            local lineBet = globalData.slotRunData:getCurTotalBet() / 4

                                            if score and type(score) == "number" then
                                                self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 5)

                                                score = self:changeFixSocreForDoubleBetGame(posIndex, score)
                                                local labtxt = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                                local labtxt1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                                if score >= 8 then
                                                    labtxt:setVisible(false)
                                                    labtxt1:setVisible(true)
                                                else
                                                    labtxt:setVisible(true)
                                                    labtxt1:setVisible(false)
                                                end
                                                score = score * lineBet
                                                labtxt:setString(util_formatCoins(score, 3))
                                                labtxt1:setString(util_formatCoins(score, 3))
                                            elseif score and type(score) == "string" then
                                                if score == "MINI" then
                                                    changeSymbolType = self.SYMBOL_Pomi_MINI
                                                    self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 4)
                                                elseif score == "MINOR" then
                                                    changeSymbolType = self.SYMBOL_Pomi_MINOR
                                                    self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 3)
                                                elseif score == "MAJOR" then
                                                    changeSymbolType = self.SYMBOL_Pomi_MAJOR
                                                    self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 2)
                                                elseif score == "GRAND" then
                                                    changeSymbolType = self.SYMBOL_Pomi_GRAND
                                                    self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 1)
                                                end
                                            end
                                        end

                                        gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_specialToBonus.mp3")

                                        tarSp.m_lastNode:runAnim("qiehuan", false)

                                        performWithDelay(
                                            self,
                                            function()
                                                tarSp.m_lastNode:changeCCBByName(self:getSymbolCCBNameByType(self, changeSymbolType), changeSymbolType)
                                                local changedlab = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                                local changedlab1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                                local lineBet = globalData.slotRunData:getCurTotalBet() / 4

                                                if changedlab then
                                                    if (score / lineBet) >= 8 then
                                                        changedlab:setVisible(false)
                                                        changedlab1:setVisible(true)
                                                    else
                                                        changedlab:setVisible(true)
                                                        changedlab1:setVisible(false)
                                                    end
                                                    changedlab:setString(util_formatCoins(score, 3))
                                                    changedlab1:setString(util_formatCoins(score, 3))
                                                end

                                                tarSp.m_lastNode:runAnim("idle", true)
                                            end,
                                            1.4
                                        )
                                    end,
                                    2 + 1.4 + 0.5
                                )
                            end,
                            1
                        )
                    end

                    break
                end
            end
        end
    end

    performWithDelay(
        self,
        function()
            self.m_bgChangeAct:runCsbAction(
                "over",
                false,
                function()
                    self.m_bgChangeAct:setVisible(false)
                end,
                30
            )
        end,
        waitTime
    )

    performWithDelay(
        self,
        function()
            self:playRespinEffect()
        end,
        0.5 + waitTime + 1.4 + 0.5
    )
end

function FourInOnePomiMiniMachine:showSpecialSymbolNodeImg(Node, index)
    local nameList = {"Pomi_grand", "Pomi_major", "Pomi_minor", "Pomi_mini", "m_lb_score", "m_lb_score1"}
    for k, v in pairs(nameList) do
        local symbolimg = Node:getCcbProperty(v)
        if k == index then
            if symbolimg then
                symbolimg:setVisible(true)
            end
        else
            if symbolimg then
                symbolimg:setVisible(false)
            end
        end
    end

    local lab = Node:getCcbProperty("m_lb_score1")
    if index == 5 then
        if lab then
            lab:setVisible(true)
        end
    else
        if lab then
            lab:setVisible(false)
        end
    end
end

function FourInOnePomiMiniMachine:respinEffect_DoubleBset(effectData)
    effectData.m_isplay = true

    local rsExtraData = self.m_runSpinResultData.p_rsExtraData
    local waitTime = 0
    if rsExtraData then
        local multiple = rsExtraData.multiple

        if multiple then
            for k, v in pairs(multiple) do
                if k == effectData.m_index then
                    local posIndex = v.position
                    local multiplePosList = v.multPosition

                    local fixPos = self:getRowAndColByPos(posIndex)
                    local tarSp = self:getRespinFixSymbol(posIndex) -- self:getFixSymbol(fixPos.iY, fixPos.iX, SYMBOL_NODE_TAG)
                    if tarSp and tarSp.m_lastNode then
                        local oldPos = nil
                        local actid = nil
                        waitTime = 1.1 + 1.3 + 2 + 1.5
                        local multipleTime = 0
                        if multiplePosList and #multiplePosList > 0 then
                            multipleTime = (#multiplePosList * 0.2 + 0.7)
                            waitTime = waitTime + (#multiplePosList * 0.2 + 0.7)
                        end
                        table.sort(multiplePosList)

                        gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_DoubleBet_Trigger.mp3")

                        local DoubleBetFir = util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiDoubleBetActView", posIndex, multiplePosList)
                        self.m_root:addChild(DoubleBetFir, 99998)
                        DoubleBetFir:runCsbAction(
                            "show",
                            false,
                            function()
                                DoubleBetFir:runCsbAction("idle", true)
                            end
                        )

                        DoubleBetFir:setPosition(util_getConvertNodePos(tarSp.m_lastNode, DoubleBetFir))

                        tarSp.m_lastNode:runAnim(
                            "actionframe",
                            false,
                            function()
                                tarSp.m_lastNode:runAnim("idle", true)
                                oldPos = cc.p(self:getPosition())

                                actid = self:beginShake()
                            end
                        )

                        performWithDelay(
                            self,
                            function()
                                gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_DoubleBet_shake.mp3")

                                self.m_gameBg:runCsbAction(
                                    "actionframe",
                                    false,
                                    function()
                                        self.m_gameBg:runCsbAction("idleframe", true)
                                    end
                                )
                                performWithDelay(
                                    self,
                                    function()
                                        if multiplePosList and #multiplePosList > 0 then
                                            self:CreatFireBall(multiplePosList, 0.7)
                                        end
                                    end,
                                    1.1
                                )

                                performWithDelay(
                                    self,
                                    function()
                                        performWithDelay(
                                            self,
                                            function()
                                                if multiplePosList then
                                                    local index = 0
                                                    for k, v in pairs(multiplePosList) do
                                                        local addBetposIndex = v
                                                        local addBetFixPos = self:getRowAndColByPos(addBetposIndex)
                                                        local addBetTarSp = self:getCleaningRespinFixSymbol(addBetposIndex)

                                                        if addBetTarSp and addBetTarSp then
                                                            performWithDelay(
                                                                self,
                                                                function()
                                                                    local firBall = util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiFireBallView")
                                                                    self.m_root:addChild(firBall, 99999)
                                                                    local pos = util_getConvertNodePos(addBetTarSp, firBall)
                                                                    firBall:setPosition(cc.p(pos))
                                                                    firBall:runCsbAction(
                                                                        "animation0",
                                                                        false,
                                                                        function()
                                                                            firBall:removeFromParent()
                                                                            firBall = nil
                                                                        end
                                                                    )
                                                                    performWithDelay(
                                                                        self,
                                                                        function()
                                                                            gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_DoubleBet_action.mp3")

                                                                            addBetTarSp:runAnim(
                                                                                "change",
                                                                                false,
                                                                                function()
                                                                                    addBetTarSp:runAnim("idle", true)
                                                                                end
                                                                            )
                                                                            local addBetlab = addBetTarSp:getCcbProperty("m_lb_score")

                                                                            local addBetlab1 = addBetTarSp:getCcbProperty("m_lb_score1")

                                                                            local addBetscore = self:getReSpinSymbolScore(addBetposIndex)
                                                                            if addBetlab then
                                                                                local addBetlineBet = globalData.slotRunData:getCurTotalBet() / 4

                                                                                if addBetscore and type(addBetscore) == "number" then
                                                                                    addBetscore = addBetscore * addBetlineBet

                                                                                    if (addBetscore / addBetlineBet) >= 8 then
                                                                                        addBetlab:setVisible(false)
                                                                                        addBetlab1:setVisible(true)
                                                                                    else
                                                                                        addBetlab:setVisible(true)
                                                                                        addBetlab1:setVisible(false)
                                                                                    end

                                                                                    performWithDelay(
                                                                                        self,
                                                                                        function()
                                                                                            addBetlab:setString(util_formatCoins(addBetscore, 3))
                                                                                            addBetlab1:setString(util_formatCoins(addBetscore, 3))
                                                                                        end,
                                                                                        0.25
                                                                                    )
                                                                                end
                                                                            end
                                                                        end,
                                                                        0.3
                                                                    )
                                                                end,
                                                                0.2 * index
                                                            )
                                                        end

                                                        index = index + 1
                                                    end
                                                end
                                            end,
                                            0.3
                                        )
                                    end,
                                    1.5
                                )
                            end,
                            2
                        )

                        performWithDelay(
                            self,
                            function()
                                DoubleBetFir:runCsbAction(
                                    "over",
                                    false,
                                    function()
                                        DoubleBetFir:removeFromParent()
                                    end
                                )

                                self.m_GuoChangView:stopParticle()
                                -- self.m_GuoChangView:setVisible(false)

                                if actid then
                                    self:stopAction(actid)
                                end

                                if oldPos then
                                    self:setPosition(oldPos)
                                end
                            end,
                            1.1 + 2 + 1.5 + multipleTime
                        )

                        performWithDelay(
                            self,
                            function()
                                local lab = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                local lab1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                local score = self:getReSpinSymbolScore(posIndex)
                                local changeSymbolType = self.SYMBOL_Pomi_Bonus
                                if lab then
                                    local lineBet = globalData.slotRunData:getCurTotalBet() / 4
                                    lab:setString("")
                                    lab1:setString("")
                                    if score and type(score) == "number" then
                                        self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 5)

                                        score = self:changeFixSocreForDoubleBetGame(posIndex, score)

                                        score = score * lineBet

                                        if (score / lineBet) >= 8 then
                                            lab:setVisible(false)
                                            lab1:setVisible(true)
                                        else
                                            lab:setVisible(true)
                                            lab1:setVisible(false)
                                        end

                                        lab:setString(util_formatCoins(score, 3))
                                        lab1:setString(util_formatCoins(score, 3))
                                    elseif score and type(score) == "string" then
                                        if score == "MINI" then
                                            changeSymbolType = self.SYMBOL_Pomi_MINI
                                            self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 4)
                                        elseif score == "MINOR" then
                                            changeSymbolType = self.SYMBOL_Pomi_MINOR
                                            self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 3)
                                        elseif score == "MAJOR" then
                                            changeSymbolType = self.SYMBOL_Pomi_MAJOR
                                            self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 2)
                                        elseif score == "GRAND" then
                                            changeSymbolType = self.SYMBOL_Pomi_GRAND
                                            self:showSpecialSymbolNodeImg(tarSp.m_lastNode, 1)
                                        end
                                    end
                                end

                                gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_specialToBonus.mp3")

                                tarSp.m_lastNode:runAnim(
                                    "qiehuan",
                                    false,
                                    function()
                                        tarSp.m_lastNode:changeCCBByName(self:getSymbolCCBNameByType(self, changeSymbolType), changeSymbolType)
                                        local changedlab = tarSp.m_lastNode:getCcbProperty("m_lb_score")
                                        local changedlab1 = tarSp.m_lastNode:getCcbProperty("m_lb_score1")
                                        local lineBet = globalData.slotRunData:getCurTotalBet() / 4

                                        if changedlab then
                                            if (score / lineBet) >= 8 then
                                                changedlab:setVisible(false)
                                                changedlab1:setVisible(true)
                                            else
                                                changedlab:setVisible(true)
                                                changedlab1:setVisible(false)
                                            end
                                            changedlab:setString(util_formatCoins(score, 3))
                                            changedlab1:setString(util_formatCoins(score, 3))
                                        end

                                        tarSp.m_lastNode:runAnim("idle", true)
                                    end
                                )
                            end,
                            0.5 + waitTime
                        )
                    end
                end

                break
            end
        end
    end

    performWithDelay(
        self,
        function()
            self:playRespinEffect()
        end,
        1 + waitTime
    )
end

function FourInOnePomiMiniMachine:beginShake()
    local oldPos = cc.p(self:getPosition())

    local action =
        self:shakeOneNodeForever(
        oldPos,
        self,
        function()
        end
    )

    return action
end

function FourInOnePomiMiniMachine:shakeOneNodeForever(oldPos, node, func)
    local changePosY = math.random(1.5, 2.5)
    local actionList2 = {}
    actionList2[#actionList2 + 1] =
        cc.CallFunc:create(
        function()
            if func then
                func()
            end
            -- changePosY = math.random( 130,300 )
        end
    )
    actionList2[#actionList2 + 1] = cc.MoveTo:create(0.05, cc.p(oldPos.x, oldPos.y - changePosY))
    actionList2[#actionList2 + 1] = cc.MoveTo:create(0.05, cc.p(oldPos.x, oldPos.y + changePosY))
    local seq2 = cc.Sequence:create(actionList2)
    local action = cc.RepeatForever:create(seq2)
    node:runAction(action)
    return action
end

function FourInOnePomiMiniMachine:CreatFireBall(posList, time)
    self.m_GuoChangView:setVisible(true)
    self.m_GuoChangView:playParticle()
end

-- 更新Link类数据
function FourInOnePomiMiniMachine:SpinResultParseResultData(result)
    self.m_runSpinResultData:parseResultData(result, self.m_lineDataPool)
end

--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function FourInOnePomiMiniMachine:checkTriggerInReSpin()
    local isPlayGameEff = false

    return isPlayGameEff
end

function FourInOnePomiMiniMachine:requestSpinReusltData()
    self.m_isWaitingNetworkData = true
    self:setGameSpinStage(WAITING_DATA)

    self.m_parent:requestSpinReusltData()
end

function FourInOnePomiMiniMachine:initSelfUI()
    -- init UI
    self:createLocalAnimation()

    -- jackpotbar
    -- self.m_jackPorBar = util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiJackPotBarView")
    -- self:findChild("Jackpot"):addChild(self.m_jackPorBar)
    -- self.m_jackPorBar:initMachine(self)

    self.m_PomiRespinBarView = util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiRespinBarView")
    self:findChild("respinbar"):addChild(self.m_PomiRespinBarView)
    self.m_PomiRespinBarView:initMachine(self)
    self.m_PomiRespinBarView:setVisible(false)

    self:findChild("bgChangeAct"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    self.m_bgChangeAct = util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiBgChangeActView")
    self:findChild("bgChangeAct"):addChild(self.m_bgChangeAct)
    self.m_bgChangeAct:setVisible(false)

    self.m_respinBarPosY = self:findChild("respinbar"):getPositionY()

    -- 过场
    self.m_GuoChangView = util_createView("CodeFourInOneSrc.LinkReels.PomiSrc.PomiFireBallArrayView")
    self:findChild("Node_fir_Down"):addChild(self.m_GuoChangView, -1)
    self.m_GuoChangView:setVisible(false)
end

function FourInOnePomiMiniMachine:initMachineBg()
    self.m_parent.m_PomiGameBg:setVisible(true)
    self.m_gameBg = self.m_parent.m_PomiGameBg

    self.m_gameBg:runCsbAction("idleframe", true)
    self.m_gameBg:findChild("Pomi_bg2"):setVisible(true)
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function FourInOnePomiMiniMachine:resetMusicBg(isMustPlayMusic, selfMakePlayMusicName)
end

function FourInOnePomiMiniMachine:clearCurMusicBg()
end

---
-- 清空掉产生的数据
--
function FourInOnePomiMiniMachine:clearSlotoData()
    -- -- 清空掉全局信息
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

function FourInOnePomiMiniMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end

    BaseSlots.onExit(self)

    if self.m_ReelsBgActHandlerID then
        scheduler.unscheduleGlobal(self.m_ReelsBgActHandlerID)
        self.m_ReelsBgActHandlerID = nil
    end

    if self.m_showLineHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_showLineHandlerID)
        self.m_showLineHandlerID = nil
    end

    if self.m_fsOverHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_fsOverHandlerID)
        self.m_fsOverHandlerID = nil
    end

    -- scheduler.unschedulesByTargetName(self:getModuleName())
    gLobalNoticManager:removeAllObservers(self)

    --停止背景音乐
    -- gLobalSoundManager:stopBgMusic()
    -- gLobalSoundManager:stopAllSounds()

    self:removeObservers()

    self:clearFrameNodes()
    self:clearSlotNodes()
    -- gLobalSoundManager:stopBackgroudMusic()
    -- 卸载金边
    for i, v in pairs(self.m_reelRunAnima) do
        local reelNode = v[1]
        local reelAct = v[2]
        if not tolua.isnull(reelNode) then
            if reelNode:getParent() ~= nil then
                reelNode:removeFromParent()
            end

            reelNode:release()
        end

        if not tolua.isnull(reelAct) then
            reelAct:release()
        end

        self.m_reelRunAnima[i] = nil
    end

    if self.m_reelScheduleDelegate ~= nil then
        self.m_reelScheduleDelegate:unscheduleUpdate()
    end

    if self.m_handerIdAutoSpin ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdAutoSpin)
        self.m_handerIdAutoSpin = nil
    end

    if self.m_beginStartRunHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
        self.m_beginStartRunHandlerID = nil
    end

    if self.m_respinNodeInfo ~= nil and #self.m_respinNodeInfo > 0 then
        for k = 1, #self.m_respinNodeInfo do
            local node = self.m_respinNodeInfo[k].node
            if not tolua.isnull(node) then
                node:removeFromParent()
            end
        end
    end
    self.m_respinNodeInfo = {}
    -- clear view childs
    local viewLayer = gLobalViewManager.p_ViewLayer
    if viewLayer ~= nil then
    -- viewLayer:removeAllChildren()
    end

    self:removeSoundHandler()

    --离开，清空
    -- gLobalActivityManager:clear()

    self:clearSlotoData()
    -- globalData.userRate:leaveLevel()
    -- scheduler.unschedulesByTargetName("BaseSlotoManiaMachine")
    -- self:stopTimeOut()
    if self.clearLayerChildReferenceCount then
        self:clearLayerChildReferenceCount()
    end
end

---
-- 清理掉 所有slot node 节点
function FourInOnePomiMiniMachine:clearSlotNodes()
    self:clearNewCaches()
    self:clearCacheMap()

    for nodeIndex = #self.m_reelNodePool, 1, -1 do
        local node = self.m_reelNodePool[nodeIndex]
        if not tolua.isnull(node) then
            node:clear()

            node:removeAllChildren() -- 必须加上这个，否则ccb的节点无法卸载，因为未加入到显示列表

            node:release()
        end
        self.m_reelNodePool[nodeIndex] = nil
    end
    self.m_reelNodePool = nil

    for key, v in pairs(self.m_reelAnimNodePool) do
        for nodeIndex = #v, 1, -1 do
            local node = v[nodeIndex]
            if not tolua.isnull(node) then
                node:clear()

                node:removeAllChildren() -- 必须加上这个，否则ccb的节点无法卸载，因为未加入到显示列表

                node:release()
            end
            v[nodeIndex] = nil
        end
        self.m_reelAnimNodePool[key] = nil
    end
    self.m_reelAnimNodePool = nil

    for i = 1, #self.m_slotParents do
        local parentData = self.m_slotParents[i]
        local slotParent = parentData.slotParent
        local childs = slotParent:getChildren()
        self:clearSlotChilds(childs)
        local slotParentBig = parentData.slotParentBig
        if slotParentBig then
            local childsBig = slotParent:getChildren()
            self:clearSlotChilds(childsBig)
        end
    end

    -- 清空掉所有遮罩提示的 SlotNode
    local nodeLen = #self.m_lineSlotNodes
    for lineNodeIndex = nodeLen, 1, -1 do
        local lineNode = self.m_lineSlotNodes[lineNodeIndex]

        if not tolua.isnull(lineNode) then -- TODO 补丁
            if lineNode.clear ~= nil then
                lineNode:clear()
            end

            if lineNode:getReferenceCount() > 1 then
                lineNode:release()
            end

            if lineNode:getParent() ~= nil then
                lineNode:removeFromParent()
            end
        end
    end

    for i = #self.m_lineSlotNodes, 1, -1 do
        self.m_lineSlotNodes[i] = nil
    end
end

function FourInOnePomiMiniMachine:clearSlotChilds(childs)
    for childIndex = 1, #childs, 1 do
        local node = childs[childIndex]

        if not tolua.isnull(node) then
            if node.clear ~= nil then
                node:clear()
            end

            if node.stopAllActions == nil then
                release_print("__cname  is nil")
                if node.__cname ~= nil then
                    release_print("报错的node 类型为" .. node.__cname)
                elseif tolua.type(node) ~= nil then
                    release_print("报错的node 类型为" .. tostring(tolua.type(node)))
                end
            end

            node:stopAllActions()
            node:removeAllChildren()
            --                printInfo("xcyy node referencecount %d",node:getReferenceCount())
            if node:getReferenceCount() > 1 then
                node:release()
            end
            release_print("__cname end")
        end
    end
end

return FourInOnePomiMiniMachine
