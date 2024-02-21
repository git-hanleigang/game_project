---
-- xcyy
-- 2018-12-18 
-- FourInOneHowlingMoonMiniMachine.lua
--
--

-- local BaseMiniMachine = require "Levels.BaseMiniMachine"
local BaseMiniMachine = require "Levels.BaseMiniMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseSlots = require "Levels.BaseSlots"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local BaseMachineGameEffect = require "Levels.BaseMachineGameEffect"
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"

local BaseView = util_require("base.BaseView")
local SpinWinLineData = require "data.slotsdata.SpinWinLineData"
local FourInOneSlotsReelRunData = require "CodeFourInOneSrc.FourInOneSlotsReelRunData"
local FourInOneSlotFastNode = require "CodeFourInOneSrc.FourInOneSlotFastNode"


local FourInOneHowlingMoonMiniMachine = class("FourInOneHowlingMoonMiniMachine", BaseMiniMachine)


FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_A1 =	100
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_A2 = 101
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_A3 =	102
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_A4 =	103
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_A5 =	104
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_B1 =	105
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_B2 =	106
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_B3 =	107
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_B4 =	108
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_B5 =	109
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_SC =	190
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_WILD	= 192
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_BONUS =	194
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_ALL = 1105
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_GRAND = 1104
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_MAJOR = 1103
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_MINOR = 1102
FourInOneHowlingMoonMiniMachine.SYMBOL_ChilliFiesta_MINI = 1101



FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_P1 =	200
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_P2	= 201
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_P3	= 202
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_P4	= 203
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_P5	= 204
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_Ace =	205
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_King =	206
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_Queen = 207
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_Jack =	208
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_Scatter = 290
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_Wild = 292
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_bonus = 294

FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_MINOR = 2104
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_MINI = 2103
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_SYMBOL_DOUBLE = 2105
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_SYMBOL_BOOM = 2109
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_MINOR_DOUBLE = 2106
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_SYMBOL_NULL = 2107
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_SYMBOL_BOOM_RUN = 2108
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_UNLOCK_SYMBOL = -2 -- 解锁状态的轮盘,这个是服务器给的解锁信号
FourInOneHowlingMoonMiniMachine.SYMBOL_Charms_NULL_LOCK_SYMBOL = -1 -- 未解锁状态的轮盘,这个是服务器给的空轮盘的信号


FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_Wild = 392
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_H1 = 300
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_H2 = 301
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_H3 = 302
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_L1 = 303
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_L2 = 304
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_L3 = 305
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_L4 = 306
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_L5 = 307
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_L6 = 308
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_SC = 390
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_Bonus = 394
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_MINI = 3102       
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_MINOR = 3103
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_MAJOR = 3104
FourInOneHowlingMoonMiniMachine.SYMBOL_HowlingMoon_GRAND = 3105

FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_Scatter = 490
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_H1 =	400
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_H2 =	401
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_H3 =	402
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_H4 =	403
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_L1 =	404
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_L2 =	405
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_L3 =	406
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_L4 =	407
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_L5 =	408
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_Wild = 492
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_Bonus = 494
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_GRAND = 4104
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_MAJOR = 4103
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_MINOR = 4102
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_MINI = 4101
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
FourInOneHowlingMoonMiniMachine.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

FourInOneHowlingMoonMiniMachine.m_runCsvData = nil
FourInOneHowlingMoonMiniMachine.m_machineIndex = nil 

FourInOneHowlingMoonMiniMachine.gameResumeFunc = nil
FourInOneHowlingMoonMiniMachine.gameRunPause = nil


FourInOneHowlingMoonMiniMachine.m_respinAddRow = 4
FourInOneHowlingMoonMiniMachine.m_respinLittleNodeSize = 2
FourInOneHowlingMoonMiniMachine.m_lockNodeArray = {}
FourInOneHowlingMoonMiniMachine.m_lockNumArray = {8,12,16,20}

FourInOneHowlingMoonMiniMachine.m_littleSymbolScaleSize = nil

local parentScale = 1.66

local RESPIN_ROW_COUNT = 8
local NORMAL_ROW_COUNT = 4

local HowlingMoon_Reels = "HowlingMoon"
local Pomi_Reels = "Pomi"
local ChilliFiesta_Reels = "ChilliFiesta"
local Charms_Reels = "Charms"


-- 构造函数
function FourInOneHowlingMoonMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    self.m_lightScore = 0
    self.m_lockNodeArray = {}
    self.m_littleSymbolScaleSize = 1
end

function FourInOneHowlingMoonMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil


    self.m_reelType =  data.reelType
    self.m_machineIndex = data.reelId
    self.m_parent = data.parent 


    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function FourInOneHowlingMoonMiniMachine:initGame()
    
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FourInOne_Link_".. self.m_reelType.."Config.csv", 
                                        "LevelFourInOne_Link_HowlingMoon_Config.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FourInOneHowlingMoonMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FourInOne"
end

function FourInOneHowlingMoonMiniMachine:getMachineConfigName()

    local str = ""

    if self.m_reelType then
        str =  "_Link_" .. self.m_reelType
    end

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FourInOneHowlingMoonMiniMachine:MachineRule_GetSelfCCBName(symbolType)
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
    elseif self.SYMBOL_Charms_bonus == math.abs( symbolType )  then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_2"
    elseif symbolType == self.SYMBOL_Charms_UNLOCK_SYMBOL then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_".. math.random( 1, 4 ) 
    elseif symbolType == self.SYMBOL_Charms_NULL_LOCK_SYMBOL then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_".. math.random( 1, 4 )
    elseif math.abs( symbolType ) == self.SYMBOL_Charms_SYMBOL_DOUBLE then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_3"
    elseif math.abs( symbolType ) == self.SYMBOL_Charms_MINOR then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_minor"
    elseif math.abs( symbolType ) == self.SYMBOL_Charms_MINOR_DOUBLE then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_minor"
    elseif math.abs( symbolType ) == self.SYMBOL_Charms_MINI then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_mini"
    elseif math.abs( symbolType ) == self.SYMBOL_Charms_SYMBOL_BOOM  then
        return "4in1_Socre_Charms_Boom1"
    elseif math.abs( symbolType ) == self.SYMBOL_Charms_SYMBOL_NULL  then
        return "LinkReels/CharmsLink/4in1_Socre_Charms_Bonus_NULL"
    elseif math.abs( symbolType ) == self.SYMBOL_Charms_SYMBOL_BOOM_RUN  then
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
function FourInOneHowlingMoonMiniMachine:readCSVConfigData( )
    --读取csv配置
    -- if self.m_configData == nil then
    --     self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelFourInOne_Link_HowlingMoon_Config.lua")
    -- end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function FourInOneHowlingMoonMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName
    
    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("LinkReels/" .. self.m_reelType .."Link/" .. "4in1_" .. self.m_reelType .."_link_reel.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function FourInOneHowlingMoonMiniMachine:initMachine()
    self.m_moduleName = "FourInOne" -- self:getModuleName()

    BaseMiniMachine.initMachine(self)

    self:initMachineBg()
    self:initSelfUI( )

    

end


---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FourInOneHowlingMoonMiniMachine:getPreLoadSlotNodes()
    local loadNode = BaseMiniMachine:getPreLoadSlotNodes()

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_A5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_B5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_SC,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_WILD,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_BONUS,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_ALL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_GRAND,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_ChilliFiesta_MINI,count =  2}


    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_P5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Ace,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_King,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Queen,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Jack,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Scatter,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_Wild,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_bonus,count =  2}


    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_Charms_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_Charms_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_MINOR_DOUBLE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_SYMBOL_DOUBLE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_Charms_MINOR_DOUBLE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = - self.SYMBOL_Charms_SYMBOL_DOUBLE,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_SYMBOL_BOOM,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_SYMBOL_NULL,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Charms_SYMBOL_BOOM_RUN,count =  2}

    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_UNLOCK_SYMBOL, count = 2}
    loadNode[#loadNode + 1] = {symbolType = self.SYMBOL_Charms_NULL_LOCK_SYMBOL, count = 2}


    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_Wild,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_H1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_H2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_H3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_L6,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_SC,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_Bonus,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_HowlingMoon_GRAND,count =  2}

    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Scatter,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_H1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_H2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_H3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_H4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L1,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L2,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L3,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L4,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_L5,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Wild,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Bonus,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_GRAND,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_MAJOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_MINOR,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_MINI,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Reel_Up,count =  2}
    loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_Pomi_Double_bet,count =  2}
    

    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

function FourInOneHowlingMoonMiniMachine:addSelfEffect()

end


function FourInOneHowlingMoonMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end




function FourInOneHowlingMoonMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function FourInOneHowlingMoonMiniMachine:checkNotifyUpdateWinCoin( )

    -- 这里作为freespin下 连线时通知钱数更新的接口

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_parent.m_bProduceSlots_InFreeSpin == true and self.m_parent:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end 

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_parent.m_iOnceSpinLastWin,isNotifyUpdateTop})


end

function FourInOneHowlingMoonMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function FourInOneHowlingMoonMiniMachine:addObservers()

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


function FourInOneHowlingMoonMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )

        self.m_parent:requestSpinReusltData()
end


-- 消息返回更新数据
function FourInOneHowlingMoonMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)
    self:getRandomList()
    self:stopRespinRun()
end

function FourInOneHowlingMoonMiniMachine:enterLevel( )
    -- BaseMiniMachine.enterLevel(self)
end

function FourInOneHowlingMoonMiniMachine:enterSelfLevel( )
      -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传

        self.m_initSpinData = self.m_runSpinResultData

        self:MachineRule_initGame(self.m_initSpinData)
        

        if self.m_jackpotList ~= nil then
            self:initJackpotInfo(self.m_jackpotList,self.m_initBetId)
        end
          

        self:initCloumnSlotNodesByNetData()

      
        if  #self.m_gameEffects > 0 then
            self:sortGameEffects( )
            self:playGameEffect()
        end
end


function FourInOneHowlingMoonMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end





-- 处理特殊关卡 遮罩层级
function FourInOneHowlingMoonMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
    local maxzorder = 0
    local zorder = 0
    for i=1,self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[i][parentData.cloumnIndex]
        local zorder = self:getBounsScatterDataZorder(symbolType)
        if zorder >  maxzorder then
            maxzorder = zorder
        end
    end

    slotParent:getParent():setLocalZOrder(maxzorder + self.m_longRunAddZorder[parentData.cloumnIndex])
end

function FourInOneHowlingMoonMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function FourInOneHowlingMoonMiniMachine:checkGameResumeCallFun( )
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


function FourInOneHowlingMoonMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FourInOneHowlingMoonMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function FourInOneHowlingMoonMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

-- *********** respin赋值相关

function FourInOneHowlingMoonMiniMachine:isScoreFixSymbol(symbolType )
    
    if symbolType == self.SYMBOL_ChilliFiesta_BONUS then

        return true

    elseif math.abs(symbolType) == self.SYMBOL_Charms_bonus  then

        return true

    elseif symbolType == self.SYMBOL_HowlingMoon_Bonus then

        return true

    elseif symbolType == self.SYMBOL_Pomi_Bonus then 

        return true

    end


    return false
end

function FourInOneHowlingMoonMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isScoreFixSymbol(symbolType) then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
        self:setSpecialNodeScore(self,{node})
    end
end

function FourInOneHowlingMoonMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if  self:isScoreFixSymbol(symbolType) then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end

end




-- ***********  小块层级相关

function FourInOneHowlingMoonMiniMachine:getScatterSymbolType(  )
    
    return self.SYMBOL_Pomi_Scatter

end


function FourInOneHowlingMoonMiniMachine:isScatterSymbolType( symbolType )

    local scatterList = {self.SYMBOL_ChilliFiesta_SC,
                self.SYMBOL_Charms_Scatter,
                self.SYMBOL_HowlingMoon_SC,
                self.SYMBOL_Pomi_Scatter}

    for i=1,#scatterList do
        local scatterType = scatterList[i]
        if symbolType == scatterType then
           return true 
        end
    end

    return false

end

function FourInOneHowlingMoonMiniMachine:isBonusSymbolType( symbolType )

    local bonusList = {self.SYMBOL_ChilliFiesta_BONUS ,
                self.SYMBOL_ChilliFiesta_ALL ,
                self.SYMBOL_ChilliFiesta_GRAND ,
                self.SYMBOL_ChilliFiesta_MAJOR ,
                self.SYMBOL_ChilliFiesta_MINOR ,
                self.SYMBOL_ChilliFiesta_MINI ,
                self.SYMBOL_Charms_bonus ,
                self.SYMBOL_Charms_MINOR ,
                self.SYMBOL_Charms_MINI ,
                self.SYMBOL_Charms_SYMBOL_DOUBLE ,
                self.SYMBOL_Charms_SYMBOL_BOOM ,
                self.SYMBOL_Charms_MINOR_DOUBLE ,
                self.SYMBOL_Charms_SYMBOL_NULL ,
                self.SYMBOL_Charms_SYMBOL_BOOM_RUN ,
                self.SYMBOL_HowlingMoon_Bonus ,
                self.SYMBOL_HowlingMoon_MINI ,    
                self.SYMBOL_HowlingMoon_MINOR ,
                self.SYMBOL_HowlingMoon_MAJOR ,
                self.SYMBOL_HowlingMoon_GRAND ,
                self.SYMBOL_Pomi_Bonus ,
                self.SYMBOL_Pomi_GRAND ,
                self.SYMBOL_Pomi_MAJOR ,
                self.SYMBOL_Pomi_MINOR ,
                self.SYMBOL_Pomi_MINI ,
                self.SYMBOL_Pomi_Reel_Up ,
                self.SYMBOL_Pomi_Double_bet }

    for i=1,#bonusList do
        local bonusType = bonusList[i]
        if math.abs( symbolType )  == bonusType then
           return true 
        end
    end

    return false

    
end

function FourInOneHowlingMoonMiniMachine:isWildSymbolType( symbolType )

    local wildList = {self.SYMBOL_ChilliFiesta_WILD ,
            self.SYMBOL_Charms_Wild ,
            self.SYMBOL_HowlingMoon_Wild ,
            self.SYMBOL_Pomi_Wild }

    for i=1,#wildList do
        local wildType = wildList[i]
        if symbolType == wildType then
           return true 
        end
    end

    return false

end

---
--设置bonus scatter 层级
function FourInOneHowlingMoonMiniMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if self:isScatterSymbolType( symbolType ) then

        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2

    elseif self:isBonusSymbolType( symbolType ) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif self:isWildSymbolType( symbolType ) then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < self:getScatterSymbolType(  ) then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + ( self:getScatterSymbolType(  ) - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end
    return order

end

---
-- 根据类型获取对应节点
--
function FourInOneHowlingMoonMiniMachine:getSlotNodeBySymbolType(symbolType)
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
    reelNode:setMachine(self )
    local ccbName = self:getSymbolCCBNameByType(self, symbolType)
    reelNode:initSlotNodeByCCBName(ccbName, symbolType)
    return reelNode
end

--小块
function FourInOneHowlingMoonMiniMachine:getBaseReelGridNode()
    return "CodeFourInOneSrc.FourInOneSlotFastNode"
end


---
-- 清空掉产生的数据
--
-- function FourInOneHowlingMoonMiniMachine:clearSlotoData()
    
--     -- 清空掉全局信息
--     -- globalData.slotRunData.levelConfigData = nil
--     -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
--     -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

--     if self.m_runSpinResultData ~= nil then
--         self.m_runSpinResultData:clear()
--     end

--     self.m_runSpinResultData = nil

--     if self.m_lineDataPool ~= nil then

--         for i=#self.m_lineDataPool,1,-1 do
--             self.m_lineDataPool[i] = nil
--         end

--     end
-- end

----  **************respin逻辑代码
function FourInOneHowlingMoonMiniMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(8,5,
    TAG_SYMBOL_TYPE.SYMBOL_WILD)
end

function FourInOneHowlingMoonMiniMachine:respinChangeReelGridCount(count)
    for i=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end

-- 断线重连
function FourInOneHowlingMoonMiniMachine:MachineRule_initGame( initSpinData )
    


        self.m_iReelRowNum = #self.m_runSpinResultData.p_reels
        self:respinChangeReelGridCount(#self.m_runSpinResultData.p_reels)
    

        -- if globalData.slotRunData.currSpinMode == RESPIN_MODE then
        --     self:showAllLockNode()
            
        -- end

    
end

--ReSpin结算改变UI状态
function FourInOneHowlingMoonMiniMachine:changeReSpinOverUI()

    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        self:showFreeSpinBar()
    end
end

function FourInOneHowlingMoonMiniMachine:getRespinView()
    return "CodeFourInOneSrc.LinkReels.HowlingMoonSrc.HowlingMoonRespinView"
end

function FourInOneHowlingMoonMiniMachine:getRespinNode()

    return "CodeFourInOneSrc.LinkReels.HowlingMoonSrc.HowlingMoonRespinNode"
end


function FourInOneHowlingMoonMiniMachine:setLockDataInfo()      
    self.m_allLockNodeReelPos = {}
      for i=1,#self.m_runSpinResultData.p_storedIcons do
          local iconInfo = self.m_runSpinResultData.p_storedIcons[i]
          self.m_allLockNodeReelPos[#self.m_allLockNodeReelPos + 1] = {iconInfo[1], iconInfo[2]}
      end
end
function FourInOneHowlingMoonMiniMachine:getChangeSymbolType(score)
      if score == 20 then
          return self.SYMBOL_HowlingMoon_MINI
      elseif score == 50 then
          return self.SYMBOL_HowlingMoon_MINOR
      elseif score == 100 then
          return self.SYMBOL_HowlingMoon_MAJOR
      elseif score == 500 then
              return self.SYMBOL_HowlingMoon_GRAND
      else
          return nil
      end
end

-- 获得respin显示分数
function FourInOneHowlingMoonMiniMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local score = nil
    local idNode = nil

      for i=1, #storedIcons do
          local values = storedIcons[i]
          if values[1] == id then
              score = values[2]
              idNode = values[1]
          end
      end
  
      if score == nil then
          return nil
      end

    local pos = self:getRowAndColByPos(idNode)
    local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    
      if type == self.SYMBOL_HowlingMoon_MINI then
          score = "MINI"
      elseif type == self.SYMBOL_HowlingMoon_MINOR then
          score = "MINOR"
      elseif type == self.SYMBOL_HowlingMoon_MAJOR then
          score = "MAJOR"
      elseif type == self.SYMBOL_HowlingMoon_GRAND then
              score = "GRAND"
      end

    return score
end

function FourInOneHowlingMoonMiniMachine:randomDownRespinSymbolScore(symbolType)
  
  local score = nil

  if self.m_bProduceSlots_InFreeSpin then
      if symbolType == self.SYMBOL_HowlingMoon_Bonus then
          score = math.random( 1, 2 )
      else
          score = "jackpot"
      end
  else
      if symbolType == self.SYMBOL_HowlingMoon_Bonus then
          score = math.random( 1, 2 )
      else
          score = "jackpot"
      end
  end
   
  return score
end

-- 设置respin分数
function FourInOneHowlingMoonMiniMachine:setSpecialNodeScore(sender, parma)
    local symbolNode = parma[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
      if iCol ~= nil then
          local columnData = self.m_reelColDatas[iCol]
          rowCount = columnData.p_showGridCount
      end
  
  
      if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then 
          --获取分数
                  local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
                  local coinsNum = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol))
                  if score then
                      local index = 0
                      if type(score) ~= "string" then
                            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
                            score = score * lineBet
                            score = util_formatCoins(score, 3)
                            local lab = symbolNode:getCcbProperty("m_lb_score")
                            local lab1 = symbolNode:getCcbProperty("m_lb_score1")
                            if lab and lab1 then

                                symbolNode:getCcbProperty("m_lb_score"):setString(score)

                                symbolNode:getCcbProperty("m_lb_score1"):setString(score)

                                if symbolNode:getCcbProperty("m_lb_score") and symbolNode:getCcbProperty("m_lb_score1") then
                                    symbolNode:getCcbProperty("m_lb_score"):setVisible(false)
                                    symbolNode:getCcbProperty("m_lb_score1"):setVisible(false)
                                    if coinsNum >= 8 then
                                        symbolNode:getCcbProperty("m_lb_score1"):setVisible(true)
                                    else
                                        symbolNode:getCcbProperty("m_lb_score"):setVisible(true)
                                    end
                                end
                            end

                            

                      end
                  end
          --   symbolNode:runAnim("buling")
  
      else
          local score = nil
          local coinsNum = nil
          if globalData.slotRunData.currSpinMode == RESPIN_MODE then
              if symbolNode.p_symbolType == self.SYMBOL_HowlingMoon_Bonus then
                  score = symbolNode.score
                  coinsNum = symbolNode.score
              else
                  score = "jackpot"
                  coinsNum = "jackpot"
              end
          else
              score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
              coinsNum = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
          end

          if type(score) ~= "string" then
                local lineBet = globalData.slotRunData:getCurTotalBet() / 4
                if score == nil then
                    score = 1
                end
                score = score * lineBet
                score = util_formatCoins(score, 3)

                local lab = symbolNode:getCcbProperty("m_lb_score")
                local lab1 = symbolNode:getCcbProperty("m_lb_score1")
                if lab and lab1 then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)

                    symbolNode:getCcbProperty("m_lb_score1"):setString(score)
    
                    if symbolNode:getCcbProperty("m_lb_score") and symbolNode:getCcbProperty("m_lb_score1") then
                        symbolNode:getCcbProperty("m_lb_score"):setVisible(false)
                        symbolNode:getCcbProperty("m_lb_score1"):setVisible(false)
                        if coinsNum and coinsNum >= 8 then
                            symbolNode:getCcbProperty("m_lb_score1"):setVisible(true)
                        else
                            symbolNode:getCcbProperty("m_lb_score"):setVisible(true)
                        end
                    end
                end

                

          end
          --   symbolNode:runAnim("buling")
      end
end


function FourInOneHowlingMoonMiniMachine:getPosReelIdx(iRow, iCol)
      local iReelRow = #self.m_runSpinResultData.p_reels 
      local index = (iReelRow- iRow) * self.m_iReelColumnNum + (iCol - 1)
  return index
end

--ReSpin开始改变UI状态
function FourInOneHowlingMoonMiniMachine:changeReSpinStartUI(respinCount)
    --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)
    


end
--ReSpin刷新数量
function FourInOneHowlingMoonMiniMachine:changeReSpinUpdateUI(curCount)
  print("当前展示位置信息  %d ", curCount)
  -- 更新respin次数
  if self.m_wonBonusTimes then
        self.m_wonBonusTimes:updataRespinTimes(curCount)
  end

  
end

-- RespinView
function FourInOneHowlingMoonMiniMachine:showRespinView(effectData)


    self.m_triggerSpecialGame = true


    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)  
    self:runCsbAction("animation0",false,function(  )
                    
    end) 
    self:findChild("Node_tittle"):setVisible(false)


    self:findChild("black_bg"):setVisible(true)
    self:runCsbAction("actionframe1")
    
    util_setCsbVisible(self.m_wonBonusTimes,true)
    self.m_parent.m_bottomUI:checkClearWinLabel()
    self.m_wonBonusTimes:updataRespinTimes(self.m_runSpinResultData.p_reSpinCurCount,true)
        

    

    gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/sound_HowlingMoon_reels_change.mp3")
    
    --可随机的普通信息
    local randomTypes = 
    { self.SYMBOL_HowlingMoon_H1,
        self.SYMBOL_HowlingMoon_H2,
        self.SYMBOL_HowlingMoon_H3,
        self.SYMBOL_HowlingMoon_L1,
        self.SYMBOL_HowlingMoon_L2,
        self.SYMBOL_HowlingMoon_L3,
        self.SYMBOL_HowlingMoon_L4,
        self.SYMBOL_HowlingMoon_L5,
        self.SYMBOL_HowlingMoon_L6
    }

    

    --可随机的特殊信号 
    local endTypes = 
    {
        {type = self.SYMBOL_HowlingMoon_Bonus, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_HowlingMoon_MINI , runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_HowlingMoon_MINOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_HowlingMoon_MAJOR, runEndAnimaName = "", bRandom = true},
        {type = self.SYMBOL_HowlingMoon_GRAND, runEndAnimaName = "", bRandom = true}

    }
            
            
    --构造盘面数据 
    scheduler.performWithDelayGlobal(function()
            self:showAllLockNode()
            

            self.m_iReelRowNum =8
            self:respinChangeReelGridCount(8)
            
            if globalData.slotRunData.currSpinMode ~= RESPIN_MODE then
                self:triggerReSpinCallFun(endTypes, randomTypes)
            else
            -- 由玩法触发出来， 而不是多个元素触发
                if self.m_runSpinResultData.p_reSpinCurCount == 0 then
                    self.m_runSpinResultData.p_reSpinCurCount = 3
                end
                self:triggerReSpinCallFun(endTypes, randomTypes)
            end   
    end,4.5 , self:getModuleName())    





end

 --结束移除小块调用结算特效
function FourInOneHowlingMoonMiniMachine:reSpinEndAction()
      scheduler.performWithDelayGlobal(function()
        if self.m_wonBonusTimes then
            self.m_wonBonusTimes:overAction(false)
        end

        self.m_parent:clearCurMusicBg()
        
        gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_spin_respin_Over.mp3")

        self:reSpinEndAllLightAction()
        
          self:clearCurMusicBg()
          scheduler.performWithDelayGlobal(function()
  
              self:playTriggerLight()
  
          end,3.1 , self:getModuleName())     
  
      end,1.3 , self:getModuleName())            
      
end
-- respin 结束全部light动画
function FourInOneHowlingMoonMiniMachine:reSpinEndAllLightAction(  )
    local lightArray = self.m_respinView:getAllCleaningNode() 

    for k,v in pairs(lightArray) do
        v:getLastNode():runAnim("actionframe1",false)
        self.m_respinView:createOneActionSymbol(v:getLastNode(),"actionframe1")
    end
end

-- lighting 完毕之后 播放动画
function FourInOneHowlingMoonMiniMachine:playLightEffectEnd()

      self:respinOver()
end

function FourInOneHowlingMoonMiniMachine:playTriggerLight(reSpinOverFunc)


      self:showAllLockNodelightAction()
      -- 播放收集动画效果
      self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
      self.m_playAnimIndex = 1
  
      -- --gLobalSoundManager:stopBackgroudMusic()
      
      self.m_chipList = self.m_respinView:getAllCleaningNode()  
      
      util_setCsbVisible(self.m_wonThings,true)
      self.m_wonThings:findChild("m_lb_coin"):setString("0")
      if self.m_wonBonusTimes then
            util_setCsbVisible(self.m_wonBonusTimes,false)
      end
      
      self.m_parent.m_respinOverRunning = true

      util_setCascadeOpacityEnabledRescursion(self.m_wonThings,true)
      self.m_wonThings:setOpacity(0)
      util_playFadeInAction(self.m_wonThings,0.5)

      util_playFadeOutAction(self.m_parent:findChild("4in1_jackpot"),0.5,function(  )
        self.m_parent:findChild("4in1_jackpot"):setOpacity(255)
        self.m_parent:findChild("4in1_jackpot"):setVisible(false)
      end)
      
      
    
       
      
  
      local nDelayTime = #self.m_chipList * (0.1 + 0.85) + 0.5
      self:playChipCollectAnim()
      
end
      
function FourInOneHowlingMoonMiniMachine:playChipCollectAnim()
    if self.m_playAnimIndex > #self.m_chipList then
        if #self.m_chipList >= 40 then
        

            scheduler.performWithDelayGlobal(function()

                self:playLightEffectEnd()
        
            end,0.1 , self:getModuleName())   
            
        else
            scheduler.performWithDelayGlobal(function()

                self:playLightEffectEnd()
        
            end,0.1 , self:getModuleName())        
        end
        return 
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_colIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
    
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
                addScore =  jackpotScore + addScore                      
                nJackpotType = 1
        elseif score == "MAJOR" then
                jackpotScore = self.m_parent:BaseMania_getJackpotScore(2)
                addScore = jackpotScore + addScore
                nJackpotType = 2
        elseif score == "MINOR" then
                jackpotScore =  self.m_parent:BaseMania_getJackpotScore(3)
                addScore =jackpotScore + addScore                  
                nJackpotType = 3
        elseif score == "MINI" then
                jackpotScore = self.m_parent:BaseMania_getJackpotScore(4)  
                addScore =  jackpotScore + addScore                      
                nJackpotType = 4
        
        end
    end
    
    self.m_lightScore = self.m_lightScore + addScore

    local function fishFlyEndJiesuan()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim() 
        else 
        scheduler.performWithDelayGlobal(function()
            
            self:showRespinJackpot(nJackpotType, jackpotScore, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim() 
            end)
    
        end,0.5 , self:getModuleName())  
            
        end
    end

    local function fishFly()    
        
        local coins = self.m_lightScore  
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
        globalData.slotRunData.lastWinCoin = lastWinCoin  

        fishFlyEndJiesuan()    

    end

    chipNode:getLastNode():runAnim("actionframe3")
    chipNode:setLocalZOrder(10000 + self.m_playAnimIndex)

    local time = 0.4

    gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_spin_respin_RunOver.mp3")
    
    self.m_wonThings:showCollectCoin(util_formatCoins(self.m_lightScore,30))
    
    -- self:flySymblos(startPos, endPos, func, csbPath, actionName, time)
    self.m_respinView:createRsOverOneActionSymbol(chipNode, "actionframe3",self.m_clipParent)
      
    scheduler.performWithDelayGlobal(function()
        fishFly()        
    end, 0.4 , self:getModuleName())

    chipNode:getLastNode():runAnim("actionframe",true)

    
      
end
  
function FourInOneHowlingMoonMiniMachine:showRespinJackpot(index,coins,func)
    --   --gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_show_JackPOt_view.mp3")
    self.m_parent:showJackpotView(index,coins,func)
    
end
  
function FourInOneHowlingMoonMiniMachine:playRespinViewShowSound()


end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function FourInOneHowlingMoonMiniMachine:reateRespinNodeInfo()
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
                    symbolType = math.random( 300, 308 )
                end
            else
                symbolType = self:getMatrixPosSymbolType(iRow, iCol)
            end
            
            if self:isScatterSymbolType( symbolType) then
                symbolType = self.SYMBOL_HowlingMoon_H1
            end 
            

            if symbolType == 394 then
                print("dada")
            end

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPos(iCol)
            pos.x = pos.x + reelWidth  / 2 * (self.m_parent.m_machineRootScale * parentScale )
            local columnData = self.m_reelColDatas[iCol]
            local slotNodeH = columnData.p_showGridH   
            pos.y = pos.y + (iRow - 0.5) * slotNodeH * (self.m_parent.m_machineRootScale * parentScale )

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
function FourInOneHowlingMoonMiniMachine:triggerChangeRespinNodeInfo(respinNodeInfo)
    for k,v in pairs(respinNodeInfo) do
        if v.Type == nil then
            v.Type = math.random( 300, 308) -- 随机信号
        end
    end
end

function FourInOneHowlingMoonMiniMachine:initRespinView(endTypes, randomTypes)
    

    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:initMachine(self)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH , self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()

            self:runNextReSpinReel()
          
        end
    )
    
    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

function FourInOneHowlingMoonMiniMachine:startReSpinRun( )

    FourInOneHowlingMoonMiniMachine.super.startReSpinRun(self)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_parent.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_parent.m_startSpinTime = nil
        end
    end

    
end

--开始下次ReSpin
function FourInOneHowlingMoonMiniMachine:runNextReSpinReel(_isDownStates)

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
-- 重写Respinstar
function FourInOneHowlingMoonMiniMachine:showReSpinStart(func)



    --也可以这样写 self:showDialog("ReSpinStart",nil,func,true)
end

function FourInOneHowlingMoonMiniMachine:respinOver()
    
    
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    scheduler.performWithDelayGlobal(function()
        self:showRespinOverView()
    end,1 , self:getModuleName())  
    
end
function FourInOneHowlingMoonMiniMachine:showRespinOverView(effectData)
            
        

          gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_show_view.mp3")
        local strCoins= self.m_lightScore

        self.m_parent:showRespinOverView(strCoins)
     

end


function FourInOneHowlingMoonMiniMachine:getRespinSpinData()
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    local storedInfo = {}   

    for i=1, #storedIcons do
        local id = storedIcons[i][1]
        local pos = self:getRowAndColByPos(id)
        local type = self:getMatrixPosSymbolType(pos.iX, pos.iY)

        storedInfo[#storedInfo + 1] = {iX = pos.iX, iY = pos.iY, type = type}
    end

    return storedInfo
end

function FourInOneHowlingMoonMiniMachine:transitionView( )
    gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_spin_transition.mp3")
    self.m_respinStartAction:toAction("actionframe",false,function(  )
        util_setCsbVisible(self.m_respinStartAction,false)
    end)
    util_setCsbVisible(self.m_respinStartAction,true)
 
end

--[[
    @desc: 处理 锁行
    author:{author}
    time:2019-01-08 21:55:18
    @return:
]]
function FourInOneHowlingMoonMiniMachine:hideAllLockNode( )

    for k,v in pairs(self.m_lockNodeArray) do
        v:setVisible(false)
        v.actionType = 0
    end
end

function FourInOneHowlingMoonMiniMachine:showAllLockNode( )
    
    scheduler.performWithDelayGlobal(function()
        for k,v in pairs(self.m_lockNodeArray) do
        
            v:IdleAction(false)
            scheduler.performWithDelayGlobal(function()
                v:setVisible(true)
                v:updateLockLeftNum("")
                gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/sound_HowlingMoon_showlock.mp3")
            end,0.2*k , self:getModuleName())  
        end
    
        scheduler.performWithDelayGlobal(function()
            self:getShouldLockNodeShowNum()
        end,1 , self:getModuleName()) 
    end,0.7 , self:getModuleName()) 
    
    
end

function FourInOneHowlingMoonMiniMachine:showAllLockNodelightAction( )

    for k,v in pairs(self.m_lockNodeArray) do
        
        if v:isVisible() then
            v:lightAction(false)
        end
        
    end
end

---返回没有锁的行个数
function FourInOneHowlingMoonMiniMachine:getLockNodeShowNum( )
    local num = 0
    for k,v in pairs(self.m_lockNodeArray) do
        if v.actionType == 1 then
            num = num + 1
        end
    end
    return num
end

---返回应该锁行个数 断线用 第一次进入respin
function FourInOneHowlingMoonMiniMachine:getShouldLockNodeShowNum( )
    self:showLeftLockNum()

    local alllockNum = self:getLockNodeShowNum() + 4 -- 本地已经解锁的个数

    local unlockedLines = self.m_runSpinResultData.p_rsExtraData.unlockedLines -- 服务器已经解锁的个数
    local lockedSymbols = self.m_runSpinResultData.p_rsExtraData.totalRewardSignals -- 服务器已经锁住的信号数

    local shouldUnLockLines = unlockedLines - alllockNum
    if shouldUnLockLines >= 0 and alllockNum~= 8 then
        self:unlockedNode(shouldUnLockLines)
    end
end

-- 解锁
function FourInOneHowlingMoonMiniMachine:unlockedNode(shouldUnLockLines )
    for i = 1,shouldUnLockLines do
        for k,v in pairs(self.m_lockNodeArray) do
            if v:isVisible() and v.actionType == 0 then
                v.actionType =1
                v:unLockAction(false,function(  )
                    v:setVisible(false)
                end)
                break
            end
        end 
    end
end

-- 解锁
function FourInOneHowlingMoonMiniMachine:unlockedOneNode(index )

    if self.m_lockNodeArray[index]:isVisible() and self.m_lockNodeArray[index].actionType ~= 1 then
        self.m_lockNodeArray[index]:unLockAction(false,function(  )
            self.m_lockNodeArray[index]:setVisible(false)
        end)
    end
    self.m_lockNodeArray[index].actionType = 1

end

-- 显示剩余个数
function FourInOneHowlingMoonMiniMachine:showLeftLockNum( )
    local lightnum = 0
    local lockedSymbols = self.m_runSpinResultData.p_rsExtraData.totalRewardSignals -- 服务器已经锁住的信号数

    if not lockedSymbols then
        for i=1,#self.m_runSpinResultData.p_reelsData do
        local reels = self.m_runSpinResultData.p_reelsData[i]
            for j=1,#reels do
                local type = reels[j]
                if type == self.SYMBOL_HowlingMoon_Bonus or
                type == self.SYMBOL_HowlingMoon_MINI or  
                type == self.SYMBOL_HowlingMoon_MINOR or
                type == self.SYMBOL_HowlingMoon_MAJOR or
                type == self.SYMBOL_HowlingMoon_GRAND then
                        lightnum = lightnum + 1
                end 
            end
        end
        lockedSymbols = lightnum
    end
    
    
    for k,v in pairs(self.m_lockNodeArray) do
        v:updateLockLeftNum( self.m_lockNumArray[k] - lockedSymbols ,true)
    end
    
    

end

--[[
    @desc: 飞信号方法
    author:{author}
    time:2018-12-26 11:32:59
]]                

function FourInOneHowlingMoonMiniMachine:flySymblos(startPos,endPos,func,csbPath,actionName,flytimes)
    local flyNode = cc.Node:create()
    -- flyNode:setOpacity()
    self:addChild(flyNode,30000) -- 是否添加在最上层
    local time = 0.05
    local count = 1
    local flyTime = 0.3
    if flytimes then
        flyTime = flytimes
    end
    for i=1,count do
        self:runFlySymblosAction(flyNode,time*i,flyTime,startPos,endPos,i,csbPath,actionName)
    end
    performWithDelay(flyNode,function()
        if func then
            func()
        end
        flyNode:removeFromParent()
    end,flyTime+time*count)
end

function FourInOneHowlingMoonMiniMachine:runFlySymblosAction(flyNode,time,flyTime,startPos,endPos,index,csbPath,actionName)
    local actionList = {}
    local opacityList = {185,145,105,65,25,1,1,1,1,1}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node,csbAct=util_csbCreate(csbPath)
    -- node:setVisible(false)
    util_csbPlayForKey(csbAct,actionName,true)

    util_setCascadeOpacityEnabledRescursion(node,true)
    node:setOpacity(opacityList[index])
    actionList[#actionList + 1] = cc.CallFunc:create(function()
    --     node:setVisible(true)
          node:runAction(cc.ScaleTo:create(flyTime,self.m_littleSymbolScaleSize))
    end)
    flyNode:addChild(node,6-index)
    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, cc.p(endPos))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
          node:setLocalZOrder(index)
    end)
    
    node:runAction(cc.Sequence:create(actionList))
end


-- 更新Link类数据
function FourInOneHowlingMoonMiniMachine:SpinResultParseResultData( result)
    self.m_runSpinResultData:parseResultData(result,self.m_lineDataPool)
end


---判断结算 控制类处理
function FourInOneHowlingMoonMiniMachine:reSpinReelDown(addNode)
    self.m_parent:reSpinSelfReelDown(addNode)
end

--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function FourInOneHowlingMoonMiniMachine:checkTriggerInReSpin( )

    local isPlayGameEff = false

    return isPlayGameEff
end

---- lighting 断线重连时，随机转盘数据
function FourInOneHowlingMoonMiniMachine:respinModeChangeSymbolType( )
    
end

function FourInOneHowlingMoonMiniMachine:initSelfUI( )

    self:findChild("Node_tx"):setLocalZOrder(2010)
    
    -- ui添加
    self:findChild("node_lock"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)
    for i=1,4 do
        self.m_lockNodeArray[#self.m_lockNodeArray + 1] = util_createView("CodeFourInOneSrc.LinkReels.HowlingMoonSrc.HowlingMoonRespinLockReels")
        local index = 5-i
        self:findChild("Node_lock"..index):addChild(self.m_lockNodeArray[#self.m_lockNodeArray]) 
    end
    self:hideAllLockNode()

    local targetNode = self:findChild("node_show")
    targetNode:setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_wonThings = util_createView("CodeFourInOneSrc.LinkReels.HowlingMoonSrc.HowlingMoonWonThings")
    targetNode:addChild(self.m_wonThings)
    util_setCsbVisible(self.m_wonThings,false)

    self:findChild("node_freespin_father"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 105)
    self:findChild("node_freespin"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 105)
    self.m_wonBonusTimes = util_createView("CodeFourInOneSrc.LinkReels.HowlingMoonSrc.HowlingMoonBonusGameTittle")
    self:findChild("node_freespin"):addChild(self.m_wonBonusTimes,GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN+1)
    self.m_wonBonusTimes:setVisible(false)
end


function FourInOneHowlingMoonMiniMachine:initMachineBg()
    

    self.m_parent.m_HowlingMoonGameBg:setVisible(true)
    self.m_gameBg = self.m_parent.m_HowlingMoonGameBg
    
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function FourInOneHowlingMoonMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function FourInOneHowlingMoonMiniMachine:clearCurMusicBg( )
    
end

---
-- 清空掉产生的数据
--
function FourInOneHowlingMoonMiniMachine:clearSlotoData()
    
    -- -- 清空掉全局信息
    -- globalData.slotRunData.levelConfigData = nil
    -- globalData.slotRunData.levelGetAnimNodeCallFun = nil
    -- globalData.slotRunData.levelPushAnimNodeCallFun = nil

    if self.m_runSpinResultData ~= nil then
        self.m_runSpinResultData:clear()
    end

    self.m_runSpinResultData = nil

    if self.m_lineDataPool ~= nil then

        for i=#self.m_lineDataPool,1,-1 do
            self.m_lineDataPool[i] = nil
        end

    end
end

function FourInOneHowlingMoonMiniMachine:onExit()

    if gLobalViewManager:isViewPause() then
        return
    end

    BaseSlots.onExit(self)

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

    

    self:removeSoundHandler( )

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
function FourInOneHowlingMoonMiniMachine:clearSlotNodes()
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

function FourInOneHowlingMoonMiniMachine:clearSlotChilds(childs)
    for childIndex = 1, #childs, 1 do
        local node = childs[childIndex]

        if not tolua.isnull(node) then
            if node.clear ~= nil then
                node:clear()
            end

            if  node.stopAllActions == nil then
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

return FourInOneHowlingMoonMiniMachine
