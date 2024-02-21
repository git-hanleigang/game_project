---
-- xcyy
-- 2018-12-18 
-- FourInOneChilliFiestaMiniMachine.lua
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


local FourInOneChilliFiestaMiniMachine = class("FourInOneChilliFiestaMiniMachine", BaseMiniMachine)

FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_A1 =	100
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_A2 = 101
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_A3 =	102
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_A4 =	103
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_A5 =	104
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_B1 =	105
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_B2 =	106
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_B3 =	107
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_B4 =	108
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_B5 =	109
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_SC =	190
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_WILD	= 192


FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_BONUS =	194
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_ALL = 1105
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_GRAND = 1104
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_MAJOR = 1103
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_MINOR = 1102
FourInOneChilliFiestaMiniMachine.SYMBOL_ChilliFiesta_MINI = 1101



FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_P1 =	200
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_P2	= 201
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_P3	= 202
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_P4	= 203
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_P5	= 204
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_Ace =	205
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_King =	206
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_Queen = 207
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_Jack =	208
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_Scatter = 290
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_Wild = 292
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_bonus = 294

FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_MINOR = 2104
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_MINI = 2103
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_SYMBOL_DOUBLE = 2105
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_SYMBOL_BOOM = 2109
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_MINOR_DOUBLE = 2106
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_SYMBOL_NULL = 2107
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_SYMBOL_BOOM_RUN = 2108
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_UNLOCK_SYMBOL = -2 -- 解锁状态的轮盘,这个是服务器给的解锁信号
FourInOneChilliFiestaMiniMachine.SYMBOL_Charms_NULL_LOCK_SYMBOL = -1 -- 未解锁状态的轮盘,这个是服务器给的空轮盘的信号


FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_Wild = 392
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_H1 = 300
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_H2 = 301
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_H3 = 302
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_L1 = 303
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_L2 = 304
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_L3 = 305
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_L4 = 306
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_L5 = 307
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_L6 = 308
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_SC = 390
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_Bonus = 394
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_MINI = 3102       
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_MINOR = 3103
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_MAJOR = 3104
FourInOneChilliFiestaMiniMachine.SYMBOL_HowlingMoon_GRAND = 3105

FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_Scatter = 490
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_H1 =	400
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_H2 =	401
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_H3 =	402
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_H4 =	403
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_L1 =	404
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_L2 =	405
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_L3 =	406
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_L4 =	407
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_L5 =	408
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_Wild = 492
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_Bonus = 494
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_GRAND = 4104
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_MAJOR = 4103
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_MINOR = 4102
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_MINI = 4101
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
FourInOneChilliFiestaMiniMachine.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

FourInOneChilliFiestaMiniMachine.m_runCsvData = nil
FourInOneChilliFiestaMiniMachine.m_machineIndex = nil 

FourInOneChilliFiestaMiniMachine.gameResumeFunc = nil
FourInOneChilliFiestaMiniMachine.gameRunPause = nil


FourInOneChilliFiestaMiniMachine.m_chipList = nil
FourInOneChilliFiestaMiniMachine.m_playAnimIndex = 0
FourInOneChilliFiestaMiniMachine.m_lightScore = 0


FourInOneChilliFiestaMiniMachine.m_triggerRespinRevive = nil --触发额外增加次数
FourInOneChilliFiestaMiniMachine.m_isShowRespinChoice = nil--是否显示额外弹窗
FourInOneChilliFiestaMiniMachine.m_isPlayCollect = nil  --是否正在播放收集动画
FourInOneChilliFiestaMiniMachine.m_triggerAllSymbol = nil  --是否触发 金辣椒
FourInOneChilliFiestaMiniMachine.m_aimAllSymbolNodeList = {} --金辣椒列表
FourInOneChilliFiestaMiniMachine.m_flyCoinsTime = 0.25
FourInOneChilliFiestaMiniMachine.m_reconnect = nil
FourInOneChilliFiestaMiniMachine.m_isRespinReelDown = false

local parentScale = 1.66

local HowlingMoon_Reels = "HowlingMoon"
local Pomi_Reels = "Pomi"
local ChilliFiesta_Reels = "ChilliFiesta"
local Charms_Reels = "Charms"


-- 构造函数
function FourInOneChilliFiestaMiniMachine:ctor()
    BaseMiniMachine.ctor(self)


    self.m_aimAllSymbolNodeList = {}
    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self.m_bJackpotHeight = false
    
end

function FourInOneChilliFiestaMiniMachine:initData_( data )

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

function FourInOneChilliFiestaMiniMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("FourInOne_Link_".. self.m_reelType.."Config.csv", 
                                                "LevelFourInOne_Link_ChilliFiesta_Config.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FourInOneChilliFiestaMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FourInOne"
end

function FourInOneChilliFiestaMiniMachine:getMachineConfigName()

    local str = ""

    if self.m_reelType then
        str =  "_Link_" .. self.m_reelType
    end

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FourInOneChilliFiestaMiniMachine:MachineRule_GetSelfCCBName(symbolType)
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
function FourInOneChilliFiestaMiniMachine:readCSVConfigData( )
    --读取csv配置
    -- if self.m_configData == nil then
    --     self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelFourInOne_Link_ChilliFiesta_Config.lua")
    -- end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end
function FourInOneChilliFiestaMiniMachine:initMachineCSB( )
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
function FourInOneChilliFiestaMiniMachine:initMachine()
    self.m_moduleName = "FourInOne" -- self:getModuleName()

    self.m_machineModuleName = self.m_moduleName

    BaseMiniMachine.initMachine(self)
    
    
    self:initMachineBg()
    self:initSelfUI()

end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FourInOneChilliFiestaMiniMachine:getPreLoadSlotNodes()
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

function FourInOneChilliFiestaMiniMachine:addSelfEffect()

end


function FourInOneChilliFiestaMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end




function FourInOneChilliFiestaMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

  
end

function FourInOneChilliFiestaMiniMachine:checkNotifyUpdateWinCoin( )

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

---
-- 每个reel条滚动到底
function FourInOneChilliFiestaMiniMachine:slotOneReelDown(reelCol)
    BaseMiniMachine.slotOneReelDown(self,reelCol)

end

function FourInOneChilliFiestaMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function FourInOneChilliFiestaMiniMachine:addObservers()

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


function FourInOneChilliFiestaMiniMachine:requestSpinReusltData()


        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
        self.m_parent:requestSpinReusltData()

        self.m_curRequest = true
        self.m_reconnect = false
        self.m_isRespinReelDown = false

        if self:getCurrSpinMode() == RESPIN_MODE then
            self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount-1,self.m_runSpinResultData.p_reSpinsTotalCount)
        end
end


function FourInOneChilliFiestaMiniMachine:beginMiniReel()

    BaseMiniMachine.beginReel(self)

end


-- 消息返回更新数据
function FourInOneChilliFiestaMiniMachine:netWorkCallFun(spinResult)

     --respin中触发了 额外奖励次数
     if spinResult.respin.extra and spinResult.respin.extra.options then
        self.m_triggerRespinRevive = true
    end

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function FourInOneChilliFiestaMiniMachine:enterLevel( )
    -- BaseMiniMachine.enterLevel(self)
end

function FourInOneChilliFiestaMiniMachine:enterSelfLevel( )
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
        

      self.m_initSpinData = self.m_runSpinResultData

      local  features = self.m_parent.m_runSpinResultData.p_features 


      if features and #features > 1 and features[2] == RESPIN_MODE then
            self.m_reconnect = false
      else
            
            self.m_reconnect = true
      end
      

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

function FourInOneChilliFiestaMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end


-- 处理特殊关卡 遮罩层级
function FourInOneChilliFiestaMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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

function FourInOneChilliFiestaMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function FourInOneChilliFiestaMiniMachine:checkGameResumeCallFun( )
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


function FourInOneChilliFiestaMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FourInOneChilliFiestaMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function FourInOneChilliFiestaMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

-- *********** respin赋值相关

function FourInOneChilliFiestaMiniMachine:isScoreFixSymbol(symbolType )
    
    if symbolType == self.SYMBOL_ChilliFiesta_BONUS then

        return true

    elseif math.abs(symbolType) == self.SYMBOL_Charms_bonus  then

        return true

    elseif symbolType == self.SYMBOL_HowlingMoon_Bonus then

        return true

    elseif symbolType == self.SYMBOL_Pomi_Bonus then 

        return true
    elseif symbolType == self.SYMBOL_ChilliFiesta_ALL then
        return true
    end


    return false
end

function FourInOneChilliFiestaMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isScoreFixSymbol(symbolType) then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
        self:setSpecialNodeScore(self,{node})
    end

end

function FourInOneChilliFiestaMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if  self:isScoreFixSymbol(symbolType) then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end

end

--[[
    @desc: 根据symbolType 
    time:2019-03-20 15:12:12
    --@symbolType:
	--@row:
    --@col: 
    --@isLastSymbol:
    @return:
]]
-- function FourInOneChilliFiestaMiniMachine:getSlotNodeWithPosAndTypeUp(symbolType, row, col, isLastSymbol)
--     local tmpSymbolType = self:convertSymbolType(symbolType)
--     local symbolNode = self:getSlotNodeBySymbolType(tmpSymbolType)
--     self:setSlotCacheNodeWithPosAndTypeUp(symbolNode, symbolType, row, col, isLastSymbol)
    
--     return symbolNode
-- end

function FourInOneChilliFiestaMiniMachine:setSlotCacheNodeWithPosAndTypeUp(node, symbolType, row, col, isLastSymbol)
    BaseMiniMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)

    if  self:isScoreFixSymbol(symbolType) then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScoreUp),{node})
        self:runAction(callFun)
    end

    
end



-- ***********  小块层级相关

function FourInOneChilliFiestaMiniMachine:getScatterSymbolType(  )
    
    return self.SYMBOL_Pomi_Scatter

end


function FourInOneChilliFiestaMiniMachine:isScatterSymbolType( symbolType )

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

function FourInOneChilliFiestaMiniMachine:isBonusSymbolType( symbolType )

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

function FourInOneChilliFiestaMiniMachine:isWildSymbolType( symbolType )

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
function FourInOneChilliFiestaMiniMachine:getBounsScatterDataZorder(symbolType )
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
function FourInOneChilliFiestaMiniMachine:getSlotNodeBySymbolType(symbolType)
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
function FourInOneChilliFiestaMiniMachine:getBaseReelGridNode()
    return "CodeFourInOneSrc.FourInOneSlotFastNode"
end


---
-- 清空掉产生的数据
--
-- function FourInOneChilliFiestaMiniMachine:clearSlotoData()
    
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

function FourInOneChilliFiestaMiniMachine:initSelfUI()


    self.m_respinNode = self:findChild("node_respin")
    self.m_respinNode:setVisible(false)


    self:findChild("logo"):setVisible(false)

    self.m_reSpinPrize = util_createView("CodeFourInOneSrc.LinkReels.ChilliFiestaSrc.ChilliFiestaRespinPrize",self)
    self:findChild("freespinbar"):addChild(self.m_reSpinPrize)
    self.m_reSpinPrize:setVisible(false)


    self.m_double = util_createAnimation("LinkReels/ChilliFiestaLink/4in1_ChilliFiesta_double.csb")
    self:findChild("freespinbar"):addChild(self.m_double)
    self.m_double:setPosition(0,-40)
    self.m_double:setVisible(false)


    -- m_reSpinbar
    self.m_reSpinbar = util_createView("CodeFourInOneSrc.LinkReels.ChilliFiestaSrc.ChilliFiestaReSpinBar",self)
    self:findChild("respinBar"):addChild(self.m_reSpinbar)
    self.m_reSpinbar:setVisible(false)




end




-- 继承底层respinView
function FourInOneChilliFiestaMiniMachine:getRespinView()
    return "CodeFourInOneSrc.LinkReels.ChilliFiestaSrc.ChilliFiestaRespinView"
end
-- 继承底层respinNode
function FourInOneChilliFiestaMiniMachine:getRespinNode()
    return "CodeFourInOneSrc.LinkReels.ChilliFiestaSrc.ChilliFiestaRespinNode"
end

--触发respin
function FourInOneChilliFiestaMiniMachine:triggerReSpinCallFun(endTypes, randomTypes)

    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end
    
    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true

    -- self.m_logo:setVisible(false)

    self.m_reSpinbar:setVisible(true)
    self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)

    self.m_reSpinPrize:setVisible(true)
    self.m_reSpinPrize:updateView(0)
    self.m_reSpinPrize:changeTitle(0)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView.m_viewName = "Down"
    self.m_respinView:setMachine( self )
    if self:isRespinInit() then
        self.m_respinView:setAnimaState(0)
    end
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    --转换storeicons
    local storeIcons = {}
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    for i=1,#storedIcons do
        local pos = self:getRowAndColByPos(storedIcons[i][1])
        storeIcons[#storeIcons + 1] = {iX = pos.iX,iY = pos.iY, score = storedIcons[i][2]}
    end
    self.m_respinView:setStoreIcons(storeIcons)
    self:runCsbAction("idle2")
    self.m_respinNode:setVisible(true)
    

     -- 创建炸弹respin层
     self.m_respinViewUp = util_createView(self:getRespinView(), self:getRespinNode())
     self.m_respinViewUp.m_viewName = "Top"
     self.m_respinViewUp:setMachine( self )
     if self:isRespinInit() then
        self.m_respinViewUp:setAnimaState(0)
    else
        local score = self.m_runSpinResultData.p_rsExtraData.initAmountMultiple
        local lineBet = globalData.slotRunData:getCurTotalBet() / 4
        score = score * lineBet
        self.m_reSpinPrize:updateView(score)
        self.m_reSpinPrize:changeTitle(0)
     end
     self.m_respinViewUp:setCreateAndPushSymbolFun(
         function(symbolType,iRow,iCol,isLastSymbol)
             return self:getSlotNodeWithPosAndTypeUp(symbolType,iRow,iCol,isLastSymbol)
         end,
         function(targSp)
             self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
         end
     )
     self.m_clipUpParent:addChild(self.m_respinViewUp, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 10)

      --转换storeicons
    local storeIcons2 = {}
    local storedIcons2 = self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    for i=1,#storedIcons2 do
        local pos = self:getRowAndColByPos(storedIcons2[i][1])
        storeIcons2[#storeIcons2 + 1] = {iX = pos.iX,iY = pos.iY, score = storedIcons2[i][2]}
    end
    self.m_respinViewUp:setStoreIcons(storeIcons2)


    self:initRespinView(endTypes, randomTypes)----1

    if self.m_reconnect then
        local list = self.m_respinViewUp:getAllCleaningNode()
        for i=1,#list do
            list[i]:runAnim("idleframe",true)
        end
    end
end
function FourInOneChilliFiestaMiniMachine:isRespinInit()
    -- return true
    return self.m_runSpinResultData.p_reSpinCurCount == self.m_runSpinResultData.p_reSpinsTotalCount
end
--强制 执行变黑
function FourInOneChilliFiestaMiniMachine:respinInitDark()
    if self:isRespinInit() then
        local respinList = self.m_respinViewUp:getAllCleaningNode()
        for i=1,#respinList do
            respinList[i]:setVisible(false)--runAnim("Dack",true)
        end
    end
end

function FourInOneChilliFiestaMiniMachine:showReSpinStart( )
    if self:isRespinInit() then
        self.m_flyIndex = 1
        self.m_chipList = {}
        self.m_chipListUp = {}
        self.m_chipList = self.m_respinView:getAllCleaningNode()

        self.m_chipListUp = self.m_respinViewUp:getAllCleaningNode()

        --fly 动画
        self.m_collScore = 0
        self:flyCoins(function()
            self.m_flyIndex = 1
            self:flyDarkIcon(function()
                self.m_respinViewUp:setAnimaState(1)
                self.m_respinView:setAnimaState(1)
                self:runNextReSpinReel()--开始滚动
            end)
        end)

    else
        self:runNextReSpinReel()--开始滚动
    end
end

function FourInOneChilliFiestaMiniMachine:initRespinView(endTypes, randomTypes)

    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:reSpinEffectChange()
            self:playRespinViewShowSound()

            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            -- 更改respin 状态下的背景音乐
            self:changeReSpinBgMusic()
            

        end
    )
    self.m_respinViewUp:setEndSymbolType(endTypes, randomTypes)
    self.m_respinViewUp:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH, self.m_fReelWidth, self.m_fReelHeigth)

    local respinNodeInfoUp = self:reateRespinNodeInfoUp()

    self.m_respinViewUp:initRespinElement(
        respinNodeInfoUp,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:respinInitDark()
        end
    )

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
end

--开始下次ReSpin
function FourInOneChilliFiestaMiniMachine:runNextReSpinReel(_isDownStates)

    if self.m_triggerRespinRevive then --触发respin奖励次数
        if  self.m_isShowRespinChoice then
            return
        end
        self.m_isShowRespinChoice = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        performWithDelay(self,function()
            local view=util_createView("CodeFourInOneSrc.LinkReels.ChilliFiestaSrc.ChilliFiestaRespinChose",self.m_runSpinResultData.p_rsExtraData,function()
                self.m_triggerRespinRevive = false
                self.m_isShowRespinChoice = false
                self.m_reSpinbar:updateView(self.m_runSpinResultData.p_reSpinCurCount,self.m_runSpinResultData.p_reSpinsTotalCount)
                BaseMiniMachine.runNextReSpinReel(self)

                if _isDownStates then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
                end

            end,self)
            
            -- view:setPosition(display.width/2,685)
            self.m_parent:showSelfUI(view)

        end,0.5)
    else
        BaseMiniMachine.runNextReSpinReel(self)

        if _isDownStates then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
        end
    end
end



--下面辣椒往上飞
function FourInOneChilliFiestaMiniMachine:flyDarkIcon(func)
    if self.m_flyIndex > #self.m_chipList or self.m_flyIndex > #self.m_chipListUp then
        return
    end
    -- fly
    local symbolStartNode =  self.m_chipList[self.m_flyIndex]
    local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))

    local nodeEndSymbol =  self.m_chipListUp[self.m_flyIndex]
    local endPos = nodeEndSymbol:getParent():convertToWorldSpace(cc.p(nodeEndSymbol:getPosition()))

    self:runFlySymbolAction(nodeEndSymbol,0.01,0.5,startPos,endPos,function()
        self.m_flyIndex = self.m_flyIndex + 1
        if  self.m_flyIndex == #self.m_chipList + 1 then
            if func then
                func()
            end
        else
            self:flyDarkIcon(func)
        end
    end)

end

function FourInOneChilliFiestaMiniMachine:runFlySymbolAction(endNode,time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinBonusUpFly.mp3")

    local node = util_createAnimation("LinkReels/ChilliFiestaLink/4in1_Socre_ChilliFiesta_Bonus_fly.csb")
    -- node:setVisible(false)

    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    startPos = self:convertToNodeSpace(cc.p(startPos.x, startPos.y))
    endPos = self:convertToNodeSpace(cc.p(endPos.x, endPos.y))
    
    -- local scaleBet = self.m_parent.m_machineRootScale * parentScale
    -- startPos = cc.p(startPos.x * scaleBet ,  startPos.y * scaleBet  ) 
    -- endPos = cc.p(endPos.x * scaleBet ,  endPos.y * scaleBet  )

    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
        node:playAction("buling1")
    end)
    local bez=cc.BezierTo:create(flyTime,{cc.p(startPos.x-(startPos.x-endPos.x)*0.3,startPos.y-100),
    cc.p(startPos.x-(startPos.x-endPos.x)*0.6,startPos.y+50),endPos})
    actionList[#actionList + 1] = bez
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
        endNode:setVisible(true)

        gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinBonusUpBuling.mp3")

        endNode:runAnim("fuzhi",false,function()
            endNode:runAnim("idleframe",true)
        end)
        performWithDelay(self,function()
            if callback then
                callback()
            end
        end,0.5)
    end)
    node:runAction(cc.Sequence:create(actionList))
end

--金色的辣椒
function FourInOneChilliFiestaMiniMachine:flyCenterToSymbol(func)
    if self.m_flyIndex > #self.m_aimAllSymbolNodeList then
        return
    end
    local startPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(self.m_reSpinPrize:getPosition()))
    -- fl
    local symbolNode =  self.m_aimAllSymbolNodeList[self.m_flyIndex]
    if symbolNode:getParent() == nil or  symbolNode:getPosition() == nil  then
        self.m_flyIndex = self.m_flyIndex + 1
        self:flyCenterToSymbol(func)
        return
    end
    local endPos = symbolNode:getParent():convertToWorldSpace(cc.p(symbolNode:getPosition()))
    gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinBonusCollect.mp3")
    self.m_reSpinPrize.m_Particle_1:setVisible(true)

    self.m_reSpinPrize:runCsbAction("shouji")

    self:runFlyCoinsAction(0.01,self.m_flyCoinsTime,startPos,endPos,function()
        local score = self.m_runSpinResultData.p_rsExtraData.initAmountMultiple
        local coinsNum = self.m_runSpinResultData.p_rsExtraData.initAmountMultiple
        -- symbolNode
        local lineBet = globalData.slotRunData:getCurTotalBet() / 4
        score = score * lineBet
        score = util_formatCoins(score, 3)
        local lbs = symbolNode:getCcbProperty("m_lb_score")
        if lbs then
            lbs:setString(score)
        end

        local lbs1 = symbolNode:getCcbProperty("m_lb_score1")
        if lbs1 then
            lbs1:setString(score)
        end

        if lbs and lbs1 then
            lbs:setVisible(false)
            lbs1:setVisible(false)
            if coinsNum >= 8 then
                lbs1:setVisible(true)
            else
                lbs:setVisible(true)
            end
        end
        


        self.m_flyIndex = self.m_flyIndex + 1
        gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinBonusUpBuling.mp3")

        symbolNode:runAnim("fuzhi",false,function()
            symbolNode:runAnim("idleframe",true)
        end)
        performWithDelay(self,function()
            if  self.m_flyIndex == #self.m_aimAllSymbolNodeList + 1 then
                self.m_aimAllSymbolNodeList = {}
                if func then
                    func()
                end
            else
                self:flyCenterToSymbol(func)
            end
        end,0.5)
    end)

end


function FourInOneChilliFiestaMiniMachine:showRespinPrize(iRow, iCol)
    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol),true) --获取分数（网络数据）
    local lineBet = globalData.slotRunData:getCurTotalBet() / 4
    self.m_collScore = self.m_collScore + score * lineBet
    self.m_reSpinPrize:updateView(self.m_collScore)
    self.m_reSpinPrize:changeTitle(0)
end

--[[
    @desc: 初始阶段飞金币
    author:{author}
    time:2019-08-20 14:10:50
    --@func:
    @return:
]]
function FourInOneChilliFiestaMiniMachine:flyCoins(func)
    if self.m_flyIndex > #self.m_chipList then
        return
    end

    -- fly
    local symbolStartNode =  self.m_chipList[self.m_flyIndex]
    local startPos = symbolStartNode:getParent():convertToWorldSpace(cc.p(symbolStartNode:getPosition()))

    local endPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(self.m_reSpinPrize:getPosition()))
    gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinBonusCollect.mp3")
    symbolStartNode:runAnim("shouji",false,function()
        symbolStartNode:runAnim("idleframe",true)
    end)
    self:runFlyCoinsAction(0.01,self.m_flyCoinsTime,startPos,endPos,function()
        self:showRespinPrize(symbolStartNode.p_rowIndex,symbolStartNode.p_cloumnIndex)
        performWithDelay(self,function()
            self.m_flyIndex = self.m_flyIndex + 1
            if  self.m_flyIndex >= #self.m_chipList + 1 then
                if func then
                    func()
                end
            else
                self:flyCoins(func)
            end
        end,0.5)
    end)

end
function FourInOneChilliFiestaMiniMachine:runFlyCoinsAction(time,flyTime,startPos,endPos,callback)
    local actionList = {}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node = cc.ParticleSystemQuad:create("Effect/Effect_lajiaolaoren_lizi_1.plist")

    startPos = self:convertToNodeSpace(cc.p(startPos.x, startPos.y))
    endPos = self:convertToNodeSpace(cc.p(endPos.x, endPos.y))

    -- local scaleBet = self.m_parent.m_machineRootScale * parentScale
    -- startPos = cc.p(startPos.x * scaleBet ,  startPos.y * scaleBet  ) 
    -- endPos = cc.p(endPos.x * scaleBet ,  endPos.y * scaleBet  )

    node:setVisible(false)
    self:addChild(node, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)

    node:setPosition(startPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(true)
    end)
    local moveto=cc.MoveTo:create(flyTime,endPos)
    actionList[#actionList + 1] = moveto
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setVisible(false)
        if callback then
            callback()
        end
    end)
    node:runAction(cc.Sequence:create(actionList))


end

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function FourInOneChilliFiestaMiniMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            if self:isScatterSymbolType( symbolType) then
                symbolType = self.SYMBOL_ChilliFiesta_A1
            end 
            
            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
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

----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function FourInOneChilliFiestaMiniMachine:reateRespinNodeInfoUp()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolTypeUp(iRow, iCol)

            --层级
            local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
            --tag值
            local tag = self:getNodeTag(iRow, iCol, SYMBOL_NODE_TAG)
            --二维坐标
            local arrayPos = {iX = iRow, iY = iCol}

            --世界坐标
            local pos, reelHeight, reelWidth = self:getReelPosUp(iCol)
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

function FourInOneChilliFiestaMiniMachine:getReelPosUp(col)

    local reelNode = self:findChild("sp_reel_respin_" .. (col - 1))
    local posX = reelNode:getPositionX()
    local posY = reelNode:getPositionY()
    local worldPos = reelNode:getParent():convertToWorldSpace(cc.p(posX, posY))
    local reelHeight = reelNode:getContentSize().height
    local reelWidth = reelNode:getContentSize().width

    return worldPos, reelHeight, reelWidth
end

--- respin 快停
function FourInOneChilliFiestaMiniMachine:quicklyStop()
    BaseMiniMachine.quicklyStop(self)
    self.m_respinViewUp:quicklyStop()
end

--开始滚动
function FourInOneChilliFiestaMiniMachine:startReSpinRun()
    BaseMiniMachine.startReSpinRun(self)

    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_parent.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_parent.m_startSpinTime = nil
        end
    end

    

    self.m_respinViewUp:startMove()
end

---判断结算
function FourInOneChilliFiestaMiniMachine:reSpinReelDown(addNode)
    if self.m_isRespinReelDown then
        return
    end
    self.m_isRespinReelDown = true
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin

    local inner = function()

        self.m_parent:reSpinSelfReelDown(addNode,function(  )
            self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
        end,function(  )
            self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.UNDO)
        end)
    end
    -- if self.m_runSpinResultData.
    if self.m_triggerAllSymbol then
        performWithDelay(self,function()
            self.m_flyIndex = 1
            self:flyCenterToSymbol(function()
                self.m_triggerAllSymbol = false
                self.m_aimAllSymbolNodeList = {}
                performWithDelay(self,function()
                    inner()
                end,1)
            end)
        end,1)
    else
        inner()
    end
end

--结束移除小块调用结算特效
function FourInOneChilliFiestaMiniMachine:removeRespinNode()
    BaseMiniMachine.removeRespinNode(self)
    if self.m_respinViewUp == nil then
        --只是用到了 respin 模式 没有create respinView
        return
    end
    local allEndNodeUp = self.m_respinViewUp:getAllEndSlotsNode()
    for i = 1, #allEndNodeUp do
        local node = allEndNodeUp[i]
        node:removeFromParent()
    end
    self.m_respinViewUp:removeFromParent()
    self.m_respinViewUp = nil
end

function FourInOneChilliFiestaMiniMachine:MachineRule_respinTouchSpinBntCallBack()

    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.ALLOW then
        if self.m_beginStartRunHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_beginStartRunHandlerID)
            self.m_beginStartRunHandlerID = nil
        end
        self.m_respinView:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)

        self.m_respinViewUp:changeTouchStatus(ENUM_TOUCH_STATUS.WATING)

        self:startReSpinRun()
    elseif self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        --快停
        self:quicklyStop()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end


end


--接收到数据开始停止滚动
function FourInOneChilliFiestaMiniMachine:stopRespinRun()

    BaseMiniMachine.stopRespinRun(self)

    local storedNodeInfoUp = self:getRespinSpinDataUp()
    local unStoredReelsUp = self:getRespinReelsButStoredUp(storedNodeInfoUp)
    self.m_respinViewUp:setRunEndInfo(storedNodeInfoUp, unStoredReelsUp)
end
function FourInOneChilliFiestaMiniMachine:getMatrixPosSymbolTypeUp(iRow, iCol)
    local rowCount = #self.m_runSpinResultData.p_rsExtraData.upLastReels
    for rowIndex = 1, rowCount do
        local rowDatas = self.m_runSpinResultData.p_rsExtraData.upLastReels[rowIndex]
        local colCount = #rowDatas

        for colIndex = 1, colCount do
            if rowCount - rowIndex + 1 == iRow and iCol == colIndex then
                return rowDatas[colIndex]
            end
        end
    end
end
function FourInOneChilliFiestaMiniMachine:getRespinSpinDataUp()
    if not self.m_runSpinResultData.p_rsExtraData then
        return {}
    end
    local storedIcons = self.m_runSpinResultData.p_rsExtraData.upStoredIcons--p_storedIcons
    local index = 0
    local storedInfo = {}
    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
            for i = 1, #storedIcons do
                if storedIcons[i] == index then
                    local type = self:getMatrixPosSymbolTypeUp(iRow, iCol)

                    local pos = {iX = iRow, iY = iCol, type = type}
                    storedInfo[#storedInfo + 1] = pos
                end
            end
            index = index + 1
        end
    end
    return storedInfo
end
function FourInOneChilliFiestaMiniMachine:getRespinReelsButStoredUp(storedInfo)
    local reelData = {}
    local function getIsInStore(iRow, iCol)
        for i = 1, #storedInfo do
            local storeIcon = storedInfo[i]
            if storeIcon.iX == iRow and  storeIcon.iY == iCol then
                return true
            end
        end
        return false
    end

    for iRow = self.m_iReelRowNum, 1, -1 do
        for iCol = 1, self.m_iReelColumnNum do
           local type = self:getMatrixPosSymbolTypeUp(iRow, iCol)
           if getIsInStore(iRow, iCol) == false then
                local pos = {iX = iRow, iY = iCol, type = type}
                reelData[#reelData + 1] = pos
           end
        end
    end
    return reelData
end


-- 根据网络数据获得respinBonus小块的分数
function FourInOneChilliFiestaMiniMachine:getReSpinSymbolScore(id,onlyGetScore)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_storedIcons
    if storedIcons == nil then
        storedIcons = {}
    end
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
       return 0
    end
    if onlyGetScore then
        return score
    end
    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_ChilliFiesta_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MINOR  then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MAJOR  then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_ChilliFiesta_GRAND  then
        score = "GRAND"
    end

    return score
end


-- 根据网络数据获得respinBonus小块的分数
function FourInOneChilliFiestaMiniMachine:getReSpinSymbolScoreUp(id,onlyGetScore)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
    local storedIcons = self.m_runSpinResultData.p_rsExtraData.upStoredIcons
    if storedIcons == nil then
        storedIcons = {}
    end
    local score = nil
    local idNode = nil

    for i=1, #storedIcons do
        local values = storedIcons[i]
        if values and #values > 0 then
            if values[1] == id then
                score = values[2]
                idNode = values[1]
            end
        end
        
    end

    if score == nil then
       return 0
    end
    if onlyGetScore then
        return score
    end
    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolTypeUp(pos.iX, pos.iY)

    if symbolType == self.SYMBOL_ChilliFiesta_MINI then
        score = "MINI"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MINOR  then
        score = "MINOR"
    elseif symbolType == self.SYMBOL_ChilliFiesta_MAJOR  then
        score = "MAJOR"
    elseif symbolType == self.SYMBOL_ChilliFiesta_GRAND  then
        score = "GRAND"
    end

    return score
end


function FourInOneChilliFiestaMiniMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if symbolType == self.SYMBOL_ChilliFiesta_BONUS then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = self.m_configData:getFixSymbolPro()
    end

    return score
end

-- 给respin小块进行赋值
function FourInOneChilliFiestaMiniMachine:setSpecialNodeScore(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex



    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end


    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        if symbolNode.p_symbolType == self.SYMBOL_ChilliFiesta_ALL and self.m_reconnect == false then
            self.m_triggerAllSymbol = true
            print("m_aimAllSymbolNodeList-----------")
            if self.m_aimAllSymbolNodeList == nil then
                self.m_aimAllSymbolNodeList = {}
            end
            local has = false
            for i=1,#self.m_aimAllSymbolNodeList do
                if self.m_aimAllSymbolNodeList[i] == symbolNode then
                    has = true
                    break
                end
            end
            if has == false then
                self.m_aimAllSymbolNodeList[#self.m_aimAllSymbolNodeList+1] = symbolNode

                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString("")
                end
                if symbolNode:getCcbProperty("m_lb_score1") then
                    symbolNode:getCcbProperty("m_lb_score1"):setString("")
                end
                

            end
            return
        end
        --根据网络数据获取停止滚动时respin小块的分数
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local coinsNum = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode then

                local lab = symbolNode:getCcbProperty("m_lb_score")
                if lab then
                    lab:setString(score)
                end

                local lab1 = symbolNode:getCcbProperty("m_lb_score1")
                if lab1 then
                    lab1:setString(score)
                end
        
                if lab and lab1 then
                    lab:setVisible(false)
                    lab1:setVisible(false)
                    if coinsNum >= 8 then
                        lab1:setVisible(true)
                    else
                        lab:setVisible(true)
                    end
                end
            end
        end

        if symbolNode.p_symbolType and self:isFixSymbol(symbolNode.p_symbolType) then
            symbolNode:runAnim("idleframe")
        end


    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        local coinsNum = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            if score == nil then
                score = 1
            end
            
            score = score * lineBet
            score = util_formatCoins(score, 3)
            if symbolNode:getCcbProperty("m_lb_score") then
                symbolNode:getCcbProperty("m_lb_score"):setString(score)
            end
            if symbolNode:getCcbProperty("m_lb_score1") then
                symbolNode:getCcbProperty("m_lb_score1"):setString(score)
            end

            if symbolNode:getCcbProperty("m_lb_score") and symbolNode:getCcbProperty("m_lb_score1") then
                symbolNode:getCcbProperty("m_lb_score"):setVisible(false)
                symbolNode:getCcbProperty("m_lb_score1"):setVisible(false)
                if coinsNum >= 8 then
                    symbolNode:getCcbProperty("m_lb_score1"):setVisible(true)
                else
                    symbolNode:getCcbProperty("m_lb_score"):setVisible(true)
                end
            end

            if symbolNode.p_symbolType then
                symbolNode:runAnim("idleframe")
            end
        end

    end

end

-- 给respin小块进行赋值
function FourInOneChilliFiestaMiniMachine:setSpecialNodeScoreUp(sender,param)
    local symbolNode = param[1]
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    local rowCount = 0
    if iCol ~= nil then
        local columnData = self.m_reelColDatas[iCol]
        rowCount = columnData.p_showGridCount
    end

    if iRow ~= nil and iRow <= rowCount and iCol ~= nil and symbolNode.m_isLastSymbol == true then
        if symbolNode.p_symbolType == self.SYMBOL_ChilliFiesta_ALL and self.m_reconnect == false then
            self.m_triggerAllSymbol = true
            -- print("m_aimAllSymbolNodeList-----------")
            if self.m_aimAllSymbolNodeList == nil then
                self.m_aimAllSymbolNodeList = {}
            end
            local has = false
            for i=1,#self.m_aimAllSymbolNodeList do
                if self.m_aimAllSymbolNodeList[i] == symbolNode then
                    has = true
                    break
                end
            end
            if has == false then
                self.m_aimAllSymbolNodeList[#self.m_aimAllSymbolNodeList+1] = symbolNode
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString("")
                end
                if symbolNode:getCcbProperty("m_lb_score1") then
                    symbolNode:getCcbProperty("m_lb_score1"):setString("")
                end
                
            end
            return
        end
        --根据网络数据获取停止滚动时respin小块的分数
        local score = self:getReSpinSymbolScoreUp(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local coinsNum = self:getReSpinSymbolScoreUp(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）--
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            score = score * lineBet
            score = util_formatCoins(score, 3)

            if symbolNode:getCcbProperty("m_lb_score") then
                symbolNode:getCcbProperty("m_lb_score"):setString(score)
            end
            if symbolNode:getCcbProperty("m_lb_score1") then
                symbolNode:getCcbProperty("m_lb_score1"):setString(score)
            end

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

        -- symbolNode:runAnim("idleframe",true)

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        local coinsNum = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3)

            if symbolNode:getCcbProperty("m_lb_score") then
                symbolNode:getCcbProperty("m_lb_score"):setString(score)
            end
            if symbolNode:getCcbProperty("m_lb_score1") then
                symbolNode:getCcbProperty("m_lb_score1"):setString(score)
            end

            if symbolNode:getCcbProperty("m_lb_score") and symbolNode:getCcbProperty("m_lb_score1") then
                symbolNode:getCcbProperty("m_lb_score"):setVisible(false)
                symbolNode:getCcbProperty("m_lb_score1"):setVisible(false)
                if coinsNum >= 8 then
                    symbolNode:getCcbProperty("m_lb_score1"):setVisible(true)
                else
                    symbolNode:getCcbProperty("m_lb_score"):setVisible(true)
                end
            end

            -- symbolNode:runAnim("idleframe",true)
        end

    end

end

-- 是不是 respinBonus小块
function FourInOneChilliFiestaMiniMachine:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_ChilliFiesta_BONUS or
        symbolType == self.SYMBOL_ChilliFiesta_MINI or
        symbolType == self.SYMBOL_ChilliFiesta_MINOR or
        symbolType == self.SYMBOL_ChilliFiesta_MAJOR or
        symbolType == self.SYMBOL_ChilliFiesta_ALL or
        symbolType == self.SYMBOL_ChilliFiesta_GRAND then
        return true
    end
    return false
end

-- 结束respin收集
function FourInOneChilliFiestaMiniMachine:playLightEffectEnd()

    -- 通知respin结束
    self:respinOver()

end
--
function FourInOneChilliFiestaMiniMachine:respinOver()

    self:showRespinOverView()
end

function FourInOneChilliFiestaMiniMachine:playChipCollectAnim(isDouble)

    if self.m_playAnimIndex > #self.m_chipList then
        self.m_isPlayCollect = nil
        performWithDelay(self,function()
            self:playLightEffectEnd()
        end,2)
        return
    end

    local chipNode = self.m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))

    local addScore =  self.m_runSpinResultData.p_winLines[self.m_playAnimIndex].p_amount
    local nJackpotType = 0
   if chipNode.p_symbolType == self.SYMBOL_ChilliFiesta_GRAND then
        nJackpotType = 1
    elseif chipNode.p_symbolType == self.SYMBOL_ChilliFiesta_MAJOR then
        nJackpotType = 2
    elseif chipNode.p_symbolType == self.SYMBOL_ChilliFiesta_MINOR then
        nJackpotType = 3
    elseif chipNode.p_symbolType == self.SYMBOL_ChilliFiesta_MINI then
        nJackpotType = 4
    end
    self.m_lightScore = self.m_lightScore + addScore
    local function runCollect()
        if nJackpotType == 0 then
            self.m_playAnimIndex = self.m_playAnimIndex + 1
            self:playChipCollectAnim(isDouble)
        else
            self:showRespinJackpot(nJackpotType, addScore, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim(isDouble)
            end)
        end
    end
    local endPos = self.m_reSpinPrize:getParent():convertToWorldSpace(cc.p(self.m_reSpinPrize:getPosition()))


    gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinBonusCollect.mp3")

    chipNode:runAnim("shouji",false,function()
        chipNode:runAnim("idleframe",true)
    end)
   --最终收集阶段
   self:runFlyCoinsAction(0,0.4,nodePos,endPos,function()


        runCollect()

        self.m_reSpinPrize:updateView(self.m_lightScore)
        self.m_reSpinPrize:changeTitle(1)

        local coins = self.m_lightScore  
        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
        globalData.slotRunData.lastWinCoin = lastWinCoin  

    end)
end



--结束移除小块调用结算特效
function FourInOneChilliFiestaMiniMachine:reSpinEndAction()

    performWithDelay(self,function()
        -- 播放收集动画效果
        self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
        self.m_playAnimIndex = 1

        self.m_parent:clearCurMusicBg()

        -- 获得所有固定的respinBonus小块
        self.m_chipList = self.m_respinViewUp:getAllCleaningNode()
        local upList = self.m_respinView:getAllCleaningNode()

        self.upSymbolNum = #self.m_respinViewUp:getAllCleaningNode()

        for i=1,#upList do
            self.m_chipList[#self.m_chipList + 1] = upList[i]
        end
        self.m_parent.m_respinOverRunning = true

        local innerCollect = function(isDouble)
            if self.m_isPlayCollect == nil then
                self.m_isPlayCollect = true


                gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinOver.mp3")
                performWithDelay(self,function()
                    self.m_reSpinPrize:updateView(0)
                    self.m_reSpinPrize:changeTitle(1)
                    self:playChipCollectAnim(isDouble)
                end,3)
            end
        end

        if #self.m_chipList >= (self.m_iReelRowNum * self.m_iReelColumnNum)*2  then
            self:respinToDouble(function()
                innerCollect(true)
            end)
        else
            innerCollect(false)
        end
    end,0.5)

    



end
function FourInOneChilliFiestaMiniMachine:respinToDouble(callback)
    self.m_double:setVisible(true)
    self.m_double:playAction("auto",false,function()
        self.m_double:setVisible(false)
        local lineBet = globalData.slotRunData:getCurTotalBet() / 4

        for i=1,#self.m_chipList do
            local score = 0
            local iCol = self.m_chipList[i].p_cloumnIndex
            local iRow = self.m_chipList[i].p_rowIndex

            if i <= self.upSymbolNum then
                score = self:getReSpinSymbolScoreUp(self:getPosReelIdx(iRow ,iCol))
            else
                score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol))
            end
            if type(score) == "number" then
                local showScore = util_formatCoins(score*2*lineBet, 3)
                self.m_chipList[i]:getCcbProperty("m_lb_score"):setString(showScore)
                self.m_chipList[i]:getCcbProperty("m_lb_score1"):setString(showScore)

                self.m_chipList[i]:getCcbProperty("m_lb_score"):setVisible(false)
                self.m_chipList[i]:getCcbProperty("m_lb_score1"):setVisible(false)
                if score*2 >= 8 then
                    self.m_chipList[i]:getCcbProperty("m_lb_score1"):setVisible(true)
                else
                    self.m_chipList[i]:getCcbProperty("m_lb_score"):setVisible(true)
                end
                

            end
        end
        performWithDelay(self,function()
            if callback then
                callback()
            end
        end,0.1)
    end)
end


-- 根据本关卡实际小块数量填写
function FourInOneChilliFiestaMiniMachine:getRespinRandomTypes( )
    local symbolList = { self.SYMBOL_ChilliFiesta_A1,
    self.SYMBOL_ChilliFiesta_A2,
        self.SYMBOL_ChilliFiesta_A3,
        self.SYMBOL_ChilliFiesta_A4,
        self.SYMBOL_ChilliFiesta_A5,
        self.SYMBOL_ChilliFiesta_B1,
        self.SYMBOL_ChilliFiesta_B2,
        self.SYMBOL_ChilliFiesta_B3,
        self.SYMBOL_ChilliFiesta_B4,
        self.SYMBOL_ChilliFiesta_B5,
        self.SYMBOL_ChilliFiesta_BONUS,
        self.SYMBOL_ChilliFiesta_GRAND,
        self.SYMBOL_ChilliFiesta_MAJOR,
        self.SYMBOL_ChilliFiesta_MINOR,
        self.SYMBOL_ChilliFiesta_MINI

    }


    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function FourInOneChilliFiestaMiniMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_ChilliFiesta_BONUS, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_ChilliFiesta_GRAND, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_ChilliFiesta_MAJOR, runEndAnimaName = "buling", bRandom = false},
        {type = self.SYMBOL_ChilliFiesta_MINI, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_ChilliFiesta_MINOR, runEndAnimaName = "buling", bRandom = true},
        {type = self.SYMBOL_ChilliFiesta_ALL, runEndAnimaName = "buling", bRandom = true}
    }


    return symbolList
end

function FourInOneChilliFiestaMiniMachine:showRespinView()
    --先播放动画 再进入respin
    self:clearCurMusicBg()


    self.m_parent.m_bottomUI:updateWinCount("")
    
    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )

    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()
 
    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)




end


--ReSpin开始改变UI状态
function FourInOneChilliFiestaMiniMachine:changeReSpinStartUI(respinCount)

end

--ReSpin刷新数量
function FourInOneChilliFiestaMiniMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)

end



function FourInOneChilliFiestaMiniMachine:showEffect_RespinOver(effectData)
    self:checkFeatureOverTriggerBigWin(self.m_serverWinCoins , GameEffect.EFFECT_RESPIN_OVER)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 重置播放连线信息
    -- self:resetMaskLayerNodes()
    -- self:clearCurMusicBg()
    self:showRespinOverView(effectData)

    return true
end

function FourInOneChilliFiestaMiniMachine:showRespinOverView(effectData)

    gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_freespinOver.mp3")

    local strCoins= self.m_lightScore

    self.m_parent:showRespinOverView(strCoins)
end


-- --重写组织respinData信息
function FourInOneChilliFiestaMiniMachine:getRespinSpinData()
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

function FourInOneChilliFiestaMiniMachine:showEffect_Respin(effectData)
    -- effectData.p_isPlay = true

    --可随机的普通信息
    local randomTypes = self:getRespinRandomTypes( )
    --可随机的特殊信号
    local endTypes = self:getRespinLockTypes()

    --构造盘面数据
    self:triggerReSpinCallFun(endTypes, randomTypes)
   
    return true

end

-- 更新Link类数据
function FourInOneChilliFiestaMiniMachine:SpinResultParseResultData( result)
    self.m_runSpinResultData:parseResultData(result,self.m_lineDataPool)
end


--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function FourInOneChilliFiestaMiniMachine:checkTriggerInReSpin( )

    local isPlayGameEff = false

    return isPlayGameEff
end

---- lighting 断线重连时，随机转盘数据
function FourInOneChilliFiestaMiniMachine:respinModeChangeSymbolType( )
    
end

function FourInOneChilliFiestaMiniMachine:drawReelArea()
    BaseMiniMachine.drawReelArea(self)

    self.m_clipUpParent = self.m_csbOwner["sp_reel_respin_0"]:getParent()

end


---
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function FourInOneChilliFiestaMiniMachine:getRowAndColByPos(posData)

    if posData >= 15 then
        posData = posData - 15
    end

    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = self.m_iReelRowNum - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex,iY = colIndex}
end

function FourInOneChilliFiestaMiniMachine:showRespinJackpot(index,coins,func)

    -- gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_common_viewOpen.mp3")

    self.m_parent:showJackpotView(index,coins,func)

end

function FourInOneChilliFiestaMiniMachine:initMachineBg()
    
    self.m_parent.m_ChilliFiestaGameBg:setVisible(true)

    self.m_gameBg = self.m_parent.m_ChilliFiestaGameBg
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function FourInOneChilliFiestaMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function FourInOneChilliFiestaMiniMachine:clearCurMusicBg( )
    
end

---
-- 清空掉产生的数据
--
function FourInOneChilliFiestaMiniMachine:clearSlotoData()
    
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

function FourInOneChilliFiestaMiniMachine:onExit()

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
function FourInOneChilliFiestaMiniMachine:clearSlotNodes()
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

function FourInOneChilliFiestaMiniMachine:clearSlotChilds(childs)
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

--[[
    @desc: 根据symbolType
    time:2019-03-20 15:12:12
    --@symbolType:
	--@row:
    --@col:
    --@isLastSymbol:
    @return:
]]
function FourInOneChilliFiestaMiniMachine:getSlotNodeWithPosAndTypeUp( symbolType , row, col , isLastSymbol)
    if isLastSymbol == nil then
        isLastSymbol = false
    end
    local symblNode = self:getSlotNodeBySymbolType(symbolType)
    symblNode.p_cloumnIndex = col
    symblNode.p_rowIndex = row
    symblNode.m_isLastSymbol = isLastSymbol

    self:updateReelGridNodeUp(symblNode)
    return symblNode
end

function FourInOneChilliFiestaMiniMachine:updateReelGridNodeUp(node)
    local symbolType = node.p_symbolType

    if  self:isScoreFixSymbol(symbolType) then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        self:setSpecialNodeScoreUp(self,{node})
    end
end

return FourInOneChilliFiestaMiniMachine
