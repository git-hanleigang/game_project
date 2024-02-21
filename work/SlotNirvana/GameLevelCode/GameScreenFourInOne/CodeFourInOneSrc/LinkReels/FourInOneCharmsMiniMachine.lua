---
-- xcyy
-- 2018-12-18 
-- FourInOneCharmsMiniMachine.lua
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


local FourInOneCharmsMiniMachine = class("FourInOneCharmsMiniMachine", BaseMiniMachine)


FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_A1 =	100
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_A2 = 101
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_A3 =	102
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_A4 =	103
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_A5 =	104
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_B1 =	105
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_B2 =	106
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_B3 =	107
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_B4 =	108
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_B5 =	109
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_SC =	190
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_WILD	= 192
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_BONUS =	194
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_ALL = 1105
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_GRAND = 1104
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_MAJOR = 1103
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_MINOR = 1102
FourInOneCharmsMiniMachine.SYMBOL_ChilliFiesta_MINI = 1101


FourInOneCharmsMiniMachine.SYMBOL_Charms_P1 =	200
FourInOneCharmsMiniMachine.SYMBOL_Charms_P2	= 201
FourInOneCharmsMiniMachine.SYMBOL_Charms_P3	= 202
FourInOneCharmsMiniMachine.SYMBOL_Charms_P4	= 203
FourInOneCharmsMiniMachine.SYMBOL_Charms_P5	= 204
FourInOneCharmsMiniMachine.SYMBOL_Charms_Ace =	205
FourInOneCharmsMiniMachine.SYMBOL_Charms_King =	206
FourInOneCharmsMiniMachine.SYMBOL_Charms_Queen = 207
FourInOneCharmsMiniMachine.SYMBOL_Charms_Jack =	208
FourInOneCharmsMiniMachine.SYMBOL_Charms_Scatter = 290
FourInOneCharmsMiniMachine.SYMBOL_Charms_Wild = 292
FourInOneCharmsMiniMachine.SYMBOL_Charms_bonus = 294

FourInOneCharmsMiniMachine.SYMBOL_Charms_MINOR = 2104
FourInOneCharmsMiniMachine.SYMBOL_Charms_MINI = 2103
FourInOneCharmsMiniMachine.SYMBOL_Charms_SYMBOL_DOUBLE = 2105
FourInOneCharmsMiniMachine.SYMBOL_Charms_SYMBOL_BOOM = 2109
FourInOneCharmsMiniMachine.SYMBOL_Charms_MINOR_DOUBLE = 2106
FourInOneCharmsMiniMachine.SYMBOL_Charms_SYMBOL_NULL = 2107
FourInOneCharmsMiniMachine.SYMBOL_Charms_SYMBOL_BOOM_RUN = 2108
FourInOneCharmsMiniMachine.SYMBOL_Charms_UNLOCK_SYMBOL = -2 -- 解锁状态的轮盘,这个是服务器给的解锁信号
FourInOneCharmsMiniMachine.SYMBOL_Charms_NULL_LOCK_SYMBOL = -1 -- 未解锁状态的轮盘,这个是服务器给的空轮盘的信号


FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_Wild = 392
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_H1 = 300
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_H2 = 301
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_H3 = 302
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_L1 = 303
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_L2 = 304
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_L3 = 305
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_L4 = 306
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_L5 = 307
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_L6 = 308
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_SC = 390
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_Bonus = 394
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_MINI = 3102       
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_MINOR = 3103
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_MAJOR = 3104
FourInOneCharmsMiniMachine.SYMBOL_HowlingMoon_GRAND = 3105

FourInOneCharmsMiniMachine.SYMBOL_Pomi_Scatter = 490
FourInOneCharmsMiniMachine.SYMBOL_Pomi_H1 =	400
FourInOneCharmsMiniMachine.SYMBOL_Pomi_H2 =	401
FourInOneCharmsMiniMachine.SYMBOL_Pomi_H3 =	402
FourInOneCharmsMiniMachine.SYMBOL_Pomi_H4 =	403
FourInOneCharmsMiniMachine.SYMBOL_Pomi_L1 =	404
FourInOneCharmsMiniMachine.SYMBOL_Pomi_L2 =	405
FourInOneCharmsMiniMachine.SYMBOL_Pomi_L3 =	406
FourInOneCharmsMiniMachine.SYMBOL_Pomi_L4 =	407
FourInOneCharmsMiniMachine.SYMBOL_Pomi_L5 =	408
FourInOneCharmsMiniMachine.SYMBOL_Pomi_Wild = 492
FourInOneCharmsMiniMachine.SYMBOL_Pomi_Bonus = 494
FourInOneCharmsMiniMachine.SYMBOL_Pomi_GRAND = 4104
FourInOneCharmsMiniMachine.SYMBOL_Pomi_MAJOR = 4103
FourInOneCharmsMiniMachine.SYMBOL_Pomi_MINOR = 4102
FourInOneCharmsMiniMachine.SYMBOL_Pomi_MINI = 4101
FourInOneCharmsMiniMachine.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
FourInOneCharmsMiniMachine.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

FourInOneCharmsMiniMachine.m_runCsvData = nil
FourInOneCharmsMiniMachine.m_machineIndex = nil 

FourInOneCharmsMiniMachine.gameResumeFunc = nil
FourInOneCharmsMiniMachine.gameRunPause = nil

local parentScale = 1.66

-- 新添respinNode状态
FourInOneCharmsMiniMachine.CHARMS_RESPIN_NODE_STATUS = {
    UnLOCK = 104, --未解锁 bunus锁定状态
    NUllLOCK = 105, --空信号 状态
    UPLOCK = 106 --解锁 状态
}

--lockView状态
FourInOneCharmsMiniMachine.CHARMS_LOCKVIEW_NODE_STATUS = {
    LOCKDNODE = -1, --已经解锁了
    LOCKNULL = 0 --空信号 状态

}

FourInOneCharmsMiniMachine.m_respinLittleNodeSize = 2
FourInOneCharmsMiniMachine.m_chipList = nil
FourInOneCharmsMiniMachine.m_playAnimIndex = 0
FourInOneCharmsMiniMachine.m_lightScore = 0
FourInOneCharmsMiniMachine.m_lockList = {}

FourInOneCharmsMiniMachine.m_respinJackPotTipNodeList = {}

FourInOneCharmsMiniMachine.m_BoomList = {}
FourInOneCharmsMiniMachine.m_FirList = {}
FourInOneCharmsMiniMachine.m_isPlayRespinEnd = false

FourInOneCharmsMiniMachine.m_BoomReelsView = nil

--respin中连续Jackpot后显示背景
-- UI位置由左到右
FourInOneCharmsMiniMachine.m_respinJackpotBgName = {"Node_Grand","Node_Major_1","Node_Major_2","Node_Minor_1","Node_Minor_2","Node_Minor_3"}
FourInOneCharmsMiniMachine.m_respinJackpotBgViewName = {"Grand","Major","Major","Minor","Minor","Minor"}


local RESPIN_ROW_COUNT = 6
local NORMAL_ROW_COUNT = 3


local HowlingMoon_Reels = "HowlingMoon"
local Pomi_Reels = "Pomi"
local ChilliFiesta_Reels = "ChilliFiesta"
local Charms_Reels = "Charms"

-- 构造函数
function FourInOneCharmsMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    self.m_chipList = nil
    self.m_playAnimIndex = 0
    self.m_lightScore = 0
    self:initLockList( )
    self.m_BoomList = {}
    self.m_FirList = {}
    self.respinJackPotTipNodeList = {}
    self:initRespinJackPotTipNodeList()

    self.m_isPlayRespinEnd = false

    
end

function FourInOneCharmsMiniMachine:initData_( data )

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

function FourInOneCharmsMiniMachine:initGame()
    self.m_configData = gLobalResManager:getCSVLevelConfigData("FourInOne_Link_".. self.m_reelType.."Config.csv", 
                                                "LevelFourInOne_Link_Charms_Config.lua")


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FourInOneCharmsMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FourInOne"
end

function FourInOneCharmsMiniMachine:getMachineConfigName()

    local str = ""

    if self.m_reelType then
        str =  "_Link_" .. self.m_reelType
    end

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FourInOneCharmsMiniMachine:MachineRule_GetSelfCCBName(symbolType)
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
function FourInOneCharmsMiniMachine:readCSVConfigData( )
    --读取csv配置
    -- if self.m_configData == nil then
    --     self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName(), "LevelFourInOne_Link_Charms_Config.lua")
    -- end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end
function FourInOneCharmsMiniMachine:initMachineCSB( )
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
function FourInOneCharmsMiniMachine:initMachine()
    self.m_moduleName = "FourInOne" -- self:getModuleName()

    self.m_machineModuleName = self.m_moduleName

    BaseMiniMachine.initMachine(self)

    self:initMachineBg()
    self:initSelfUI()

end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FourInOneCharmsMiniMachine:getPreLoadSlotNodes()
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

function FourInOneCharmsMiniMachine:addSelfEffect()

end


function FourInOneCharmsMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end




function FourInOneCharmsMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()

   
end

function FourInOneCharmsMiniMachine:checkNotifyUpdateWinCoin( )

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

function FourInOneCharmsMiniMachine:getVecGetLineInfo( )
    return self.m_vecGetLineInfo
end


function FourInOneCharmsMiniMachine:playEffectNotifyChangeSpinStatus( )


    

end


function FourInOneCharmsMiniMachine:addObservers()

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


function FourInOneCharmsMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )

        self.m_parent:requestSpinReusltData()
end


-- 消息返回更新数据
function FourInOneCharmsMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function FourInOneCharmsMiniMachine:enterLevel( )
    -- BaseMiniMachine.enterLevel(self)
end

function FourInOneCharmsMiniMachine:enterSelfLevel( )
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


function FourInOneCharmsMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end




-- 处理特殊关卡 遮罩层级
function FourInOneCharmsMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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

function FourInOneCharmsMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function FourInOneCharmsMiniMachine:checkGameResumeCallFun( )
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


function FourInOneCharmsMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FourInOneCharmsMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function FourInOneCharmsMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

-- *********** respin赋值相关

function FourInOneCharmsMiniMachine:isScoreFixSymbol(symbolType )
    
    if symbolType == self.SYMBOL_ChilliFiesta_BONUS then

        return true

    elseif math.abs(symbolType) == self.SYMBOL_Charms_bonus  then

        return true

    elseif symbolType == self.SYMBOL_HowlingMoon_Bonus then

        return true

    elseif symbolType == self.SYMBOL_Pomi_Bonus then 

        return true
    elseif math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_DOUBLE then 

        return true

    end


    return false
end

function FourInOneCharmsMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isScoreFixSymbol(symbolType) then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
        self:setSpecialNodeScore(self,{node})
    end
end

function FourInOneCharmsMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if  self:isScoreFixSymbol(symbolType) then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end

end




-- ***********  小块层级相关

function FourInOneCharmsMiniMachine:getScatterSymbolType(  )
    
    return self.SYMBOL_Pomi_Scatter

end


function FourInOneCharmsMiniMachine:isScatterSymbolType( symbolType )

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

function FourInOneCharmsMiniMachine:isBonusSymbolType( symbolType )

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

function FourInOneCharmsMiniMachine:isWildSymbolType( symbolType )

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
function FourInOneCharmsMiniMachine:getBounsScatterDataZorder(symbolType )
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
function FourInOneCharmsMiniMachine:getSlotNodeBySymbolType(symbolType)
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
function FourInOneCharmsMiniMachine:getBaseReelGridNode()
    return "CodeFourInOneSrc.FourInOneSlotFastNode"
end
-- -------respin 逻辑

--[[
    @desc: 初始化lockViewList 默认开辟了30个地址
    author:{author}
    time:2019-05-20 18:21:13
    @return:
]]
function FourInOneCharmsMiniMachine:initLockList( )
    self.m_lockList = {}

    for i=1,5 do
        for i=1,6 do
            table.insert( self.m_lockList, self.CHARMS_LOCKVIEW_NODE_STATUS.LOCKNULL )
        end
    end

end

function FourInOneCharmsMiniMachine:initRespinJackPotTipNodeList( )
    for icol=1,5 do
        for irow=1,6 do
            table.insert( self.respinJackPotTipNodeList, 0)
        end
    end
end

function FourInOneCharmsMiniMachine:initSelfUI()


    -- self.m_reelRunSound = "CharmsSounds/music_Charms_LongRun.mp3"


    self:runCsbAction("idle")

    self:findChild("Node_respin_Lines"):setVisible(false)  



    for k,v in pairs(self.m_respinJackpotBgName) do
        self:findChild(v):setVisible(false) 
        local name = "CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsView"..self.m_respinJackpotBgViewName[k].."Bg" 
        local view = util_createView(name)
        view:setName("JackPotBg")
        self:findChild(v):addChild(view)
    end



    self.m_respinSpinbar = util_createView("CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsViewRespinBar")
    self:findChild("respinbar"):addChild(self.m_respinSpinbar,GAME_LAYER_ORDER.LAYER_ORDER_SPIN_BTN+10)
    self.m_respinSpinbar:setVisible(false)

 
    self:createLocalAnimation( )
end

function FourInOneCharmsMiniMachine:createLocalAnimation( )
    local pos = cc.p(self.m_parent.m_bottomUI.m_normalWinLabel:getPosition()) 
    
    -- self.m_respinEndActiom =  util_createView("CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsViewWinCoinsAction")
    -- self.m_parent.m_bottomUI.m_normalWinLabel:getParent():addChild(self.m_respinEndActiom,99999)
    -- self.m_respinEndActiom:setPosition(cc.p(pos.x ,pos.y - 8))

    -- self.m_respinEndActiom:setVisible(false)
end

function FourInOneCharmsMiniMachine:getValidSymbolMatrixArray()
    return  table_createTwoArr(6,5,
    TAG_SYMBOL_TYPE.SYMBOL_WILD)
end


function FourInOneCharmsMiniMachine:getPosReelIdx(iRow, iCol)
    local iReelRow = #self.m_runSpinResultData.p_reels 
    local index = (iReelRow- iRow) * self.m_iReelColumnNum + (iCol - 1)
    return index
end

function FourInOneCharmsMiniMachine:respinChangeReelGridCount(count)
    for i=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[i]
        columnData.p_showGridCount = count
    end
end

---- lighting 断线重连时，随机转盘数据
function FourInOneCharmsMiniMachine:respinModeChangeSymbolType( )
    if self.m_bIsInBonusFreeGame == true then
        return
    end
    if self.m_initSpinData ~= nil and self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then

        if self.m_runSpinResultData.p_reSpinCurCount > 0 then
            self.m_iReelRowNum = RESPIN_ROW_COUNT
            self:respinChangeReelGridCount(RESPIN_ROW_COUNT)

        else

            local storedIcons = self.m_initSpinData.p_storedIcons
            if storedIcons == nil or #storedIcons <= 0 then
                return
            end

            local function isInArry(iRow, iCol)
                for k = 1, #storedIcons do
                    local fix = self:getRowAndColByPos(storedIcons[k][1])
                    if fix.iX == iRow and fix.iY == iCol then
                        return true
                    end
                end
                return false
            end 

            for iRow = 1, #self.m_initSpinData.p_reels do
                local rowInfo = self.m_initSpinData.p_reels[iRow]
                for iCol = 1, #rowInfo do
                    if isInArry(#self.m_initSpinData.p_reels - iRow + 1, iCol) == false then
                        rowInfo[iCol] = xcyy.SlotsUtil:getArc4Random() % 8
                    end
                end            
            end

        end


        
    end
end

function FourInOneCharmsMiniMachine:getRespinAddNum( )
    local num = 0
    if self.m_runSpinResultData.p_reSpinsTotalCount and self.m_runSpinResultData.p_reSpinsTotalCount > 0 then
        num = 3
        return num
    end
    return num
end

---
-- 进入关卡时初始化上次轮盘， 根据每关不同需求处理各个node 
-- 
function FourInOneCharmsMiniMachine:initCloumnSlotNodesByNetData()
    --初始化节点
    self.m_initGridNode = true
    
    self:respinModeChangeSymbolType()
    for colIndex=self.m_iReelColumnNum,  1, -1 do

        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5

        local rowCount = columnData.p_showGridCount  --#self.m_initSpinData.p_reels

        local rowNum = columnData.p_showGridCount 
        local rowIndex = rowNum  -- 返回来的数据1位置是最上面一行。
        local isHaveBigSymbolIndex = false 
        local beginIndex = 1
        if self.m_initSpinData.p_reSpinsTotalCount and self.m_initSpinData.p_reSpinsTotalCount > 0 then
            if self.m_runSpinResultData.p_reSpinCurCount > 0 then
                beginIndex = 4 --  断线的时候respin  只从 后三行数据读取，初始化轮盘
            end
        end
        if self.m_initSpinData.p_selfMakeData ~= nil and self.m_initSpinData.p_selfMakeData.baseReels ~= nil then
            self.m_initSpinData.p_reels = self.m_initSpinData.p_selfMakeData.baseReels
        end
        while rowIndex >= beginIndex do 

            local rowDatas = self.m_initSpinData.p_reels[rowIndex]
            local changeRowIndex = rowCount - rowIndex + 1
            local symbolType = rowDatas[colIndex]
            local stepCount = 1
            -- 检测是否为长条模式 
            if self.m_bigSymbolInfos[symbolType] ~= nil then
                local symbolCount = self.m_bigSymbolInfos[symbolType]
                local sameCount = 1;
                local isUP = false
                if rowIndex == rowNum then
                    -- body
                    isUP  = true
                end
                for checkRowIndex = changeRowIndex + 1,rowNum do
                    local checkIndex = rowCount - checkRowIndex + 1
                    local checkRowDatas = self.m_initSpinData.p_reels[checkIndex]
                    local checkType = checkRowDatas[colIndex]
                    if checkType == symbolType then
                        if not isUP then
                            -- body
                            if  checkIndex == rowNum then
                                -- body
                                isUP  = true
                            end
                        end
                        sameCount = sameCount + 1
                        if symbolCount == sameCount then
                            break
                        end
                    else
                        break;
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
            local node = self:getSlotNodeWithPosAndType(symbolType,changeRowIndex,colIndex,true)
            node.p_slotNodeH = columnData.p_showGridH

            node.p_showOrder = self:getBounsScatterDataZorder(symbolType)
            
            parentData.slotParent:addChild(node,
                REEL_SYMBOL_ORDER.REEL_ORDER_1 - rowIndex + node.p_showOrder, colIndex * SYMBOL_NODE_TAG + changeRowIndex)

            node.p_symbolType = symbolType
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (changeRowIndex - 1) * columnData.p_showGridH + halfNodeH )
            node:runIdleAnim()      
            rowIndex = rowIndex - stepCount
        end  -- end while

    end
    self:initGridList()
end

-- 继承底层respinView
function FourInOneCharmsMiniMachine:getRespinView()
    return "CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsRespinView"
end
-- 继承底层respinNode
function FourInOneCharmsMiniMachine:getRespinNode()
    return "CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsRespinNode"
end

-- 炸弹respin层
-- 继承底层respinView
function FourInOneCharmsMiniMachine:getBoomRespinView()
    return "CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsBoomRespinView"
end
-- 继承底层respinNode
function FourInOneCharmsMiniMachine:getBoomRespinNode()
    return "CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsBoomRespinNode"
end

-- 根据网络数据获得respinBonus小块的分数
function FourInOneCharmsMiniMachine:getReSpinSymbolScore(id)
    -- p_storedIcons这个字段存储所有respinBonus的位置和倍数
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
       return 0
    end

    local pos = self:getRowAndColByPos(idNode)
    local symbolType = self:getMatrixPosSymbolType(pos.iX, pos.iY)

    if symbolType then
        if math.abs( symbolType )  == self.SYMBOL_Charms_MINI then
            score = "MINI"
        elseif math.abs( symbolType ) == self.SYMBOL_Charms_MINOR  then
            score = "MINOR"
        end
    end
    

    return score
end

function FourInOneCharmsMiniMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType then
        if math.abs(symbolType) == self.SYMBOL_Charms_bonus 
        or math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_DOUBLE  then
            -- 根据配置表来获取滚动时 respinBonus小块的分数
            -- 配置在 Cvs_cofing 里面
            score = self.m_configData:getFixSymbolPro()
        end
    end

    


    return score
end

-- 给respin小块进行赋值
function FourInOneCharmsMiniMachine:setSpecialNodeScore(sender,param)
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
        local symbolIndex = self:getPosReelIdx(iRow, iCol)
        local score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
        local coinsNum = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            score = score * lineBet
            score = util_formatCoins(score, 3)
            local scoreNode = symbolNode:getCcbProperty("m_lb_score")
            if scoreNode then
                scoreNode:setString(score)
            end

            local scoreNode1 = symbolNode:getCcbProperty("m_lb_score1")
            if scoreNode1 then
                scoreNode1:setString(score)
            end

            if scoreNode and scoreNode1 then
                scoreNode:setVisible(false)
                scoreNode1:setVisible(false)
                if coinsNum >= 8 then
                    scoreNode1:setVisible(true)
                else
                    scoreNode:setVisible(true)
                end
            end
            

            if symbolNode.p_symbolType then
                symbolNode:runAnim("idleframe")
            end
            
        end

        
    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        local coinsNum = self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            score = score * lineBet
            score = util_formatCoins(score, 3)
            local scoreNode = symbolNode:getCcbProperty("m_lb_score")
            if scoreNode then
                scoreNode:setString(score)
            end

            local scoreNode1 = symbolNode:getCcbProperty("m_lb_score1")
            if scoreNode1 then
                scoreNode1:setString(score)
            end

            if scoreNode and scoreNode1 then
                scoreNode:setVisible(false)
                scoreNode1:setVisible(false)
                if coinsNum >= 8 then
                    scoreNode1:setVisible(true)
                else
                    scoreNode:setVisible(true)
                end
            end
            
            if symbolNode.p_symbolType then
                symbolNode:runAnim("idleframe")
            end
            
        end

    end

end

-- 是不是 respinBonus小块
function FourInOneCharmsMiniMachine:isFixSymbol(symbolType)
    if math.abs(symbolType) == self.SYMBOL_Charms_bonus  or 
        math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_DOUBLE  or
        math.abs(symbolType) == self.SYMBOL_Charms_MINI or 
        math.abs(symbolType) == self.SYMBOL_Charms_MINOR or
        math.abs(symbolType) == self.SYMBOL_Charms_MINOR_DOUBLE then
        return true
    end
    return false
end

function FourInOneCharmsMiniMachine:removeAllReelsNode( )
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do

            local targSp = self:getFixSymbol(iCol, iRow , SYMBOL_NODE_TAG)
            
            if targSp then
                targSp:removeFromParent()
                self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
            end

        end
    end

end

function FourInOneCharmsMiniMachine:createRandomReelsNode(  )
    self:clearWinLineEffect()
    self:resetMaskLayerNodes()
    self:removeAllReelsNode( )
    self.m_runSpinResultData.p_reels = self.m_runSpinResultData.p_selfMakeData.baseReels
    local reels = {}
    for iRow = 1, 3 do
        reels[iRow] = self.m_runSpinResultData.p_selfMakeData.baseReels[#self.m_runSpinResultData.p_selfMakeData.baseReels - iRow + 1]
    end

    for iCol = 1, self.m_iReelColumnNum do
        local parentData = self.m_slotParents[iCol]
        local slotParent = parentData.slotParent

        for iRow = 1, 3 do

            local symbolType = reels[iRow][iCol]
            
            if symbolType then

                local newNode =  self:getSlotNodeWithPosAndType( symbolType , iRow, iCol , false)
                 
                local targSpPos =  cc.p(self:getThreeReelsTarSpPos(4 ))

                parentData.slotParent:addChild(
                    newNode,
                    REEL_SYMBOL_ORDER.REEL_ORDER_2,
                    iCol * SYMBOL_NODE_TAG + iRow
                )
                newNode.m_symbolTag = SYMBOL_NODE_TAG
                newNode.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_1
                newNode.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
                newNode.m_isLastSymbol = true
                newNode.m_bRunEndTarge = false
                local columnData = self.m_reelColDatas[iCol]
                newNode.p_slotNodeH = columnData.p_showGridH         
                newNode:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
                local halfNodeH = columnData.p_showGridH * 0.5
                newNode:setPositionY(  (iRow - 1) * columnData.p_showGridH + halfNodeH )
                  
                -- if newNode.p_symbolType and newNode.p_symbolType == self.SYMBOL_Charms_bonus then
                --     local score = math.random( 1, 4 )
                --     local lineBet = globalData.slotRunData:getCurTotalBet()
                --     score = score * lineBet
                --     score = util_formatCoins(score, 3)
                --     local lab = newNode:getCcbProperty("m_lb_score")
                --     if lab then
                --         lab:setString(score)
                --     end
                -- end 

            end

        end
    end
end

function FourInOneCharmsMiniMachine:showRespinJackpot(index,coins,func)
    
    -- -- gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_jackPotWinView.mp3")


    self.m_parent:showJackpotView(index,coins,func)

end

-- 结束respin收集
function FourInOneCharmsMiniMachine:playLightEffectEnd()

    
    -- self.m_respinEndActiom:setVisible(false)

    -- self.m_respinEndActiom:removeFromParent()
    -- 更新游戏内每日任务进度条 -- r
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    performWithDelay(self,function(  )
        self:showRespinOverView()
    end,1)
    

end

function FourInOneCharmsMiniMachine:isInsetDoubleSymbolInEndChip( )
    local isInster = true

    local lockBonusIndex = self.m_runSpinResultData.p_selfMakeData.lockBonus or {}
    local doubleSymbol = self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}

    for k,v in pairs(doubleSymbol) do
        for kk,vv in pairs(lockBonusIndex) do
            if vv == v then -- 如果双个信号有一个被锁住就不参与结算
                isInster = false
                return isInster
            end
        end
    end

    return isInster 
end

function FourInOneCharmsMiniMachine:getEndChip( )
    local chipList ={}

    local lockBonusIndex = self.m_runSpinResultData.p_selfMakeData.lockBonus  or {}
    local doubleSymbol = self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}

    for k,v in pairs(self.m_chipList) do
        local isIn = false
        local index = self:getPosReelIdx(v.p_rowIndex, v.p_cloumnIndex)
        for kk,vv in pairs(lockBonusIndex) do
            if vv == index then
                isIn = true
            end
        end
        if not isIn then
            table.insert( chipList,  v )
        end
    end

    local insterIndex = nil
    local insterNode = nil
    for i = #chipList,1,-1 do
        local chipNode = chipList[i]
        local isIn = false
        local index = self:getPosReelIdx(chipNode.p_rowIndex, chipNode.p_cloumnIndex)
        for kk,vv in pairs(doubleSymbol) do
            if vv == index then
                insterIndex = i
                if math.abs( chipNode.p_symbolType )  == self.SYMBOL_Charms_SYMBOL_DOUBLE 
                    or math.abs( chipNode.p_symbolType )  == self.SYMBOL_Charms_MINOR_DOUBLE  then
                        insterNode = chipNode
                end
                table.remove( chipList, i )
            end
        end
    end

    -- 把大块填进去
    if insterIndex and insterNode and self:isInsetDoubleSymbolInEndChip( ) then
        table.insert( chipList, insterIndex, insterNode )
    end
    

    return chipList
end

function FourInOneCharmsMiniMachine:getShowMinorIndx( )
    local index = nil
    local winRow = self.m_runSpinResultData.p_selfMakeData.series

    if #winRow == 3 then
        if winRow[2] == 2 then
            index = 4 -- 对应 m_respinJackpotBgName 中的位置 
        elseif winRow[2] == 3 then
            index = 5
        else
            index = 6
        end
    end

    return index
end

function FourInOneCharmsMiniMachine:getShowMajorIndx( )
    
    local index = nil
    local winRow = self.m_runSpinResultData.p_selfMakeData.series

    if #winRow == 4 then

        if winRow[2] == 2 then
            index = 2 -- 对应 m_respinJackpotBgName 中的位置
        else
            index = 3
        end
        
    end

    return index

end

function FourInOneCharmsMiniMachine:jackPotEndWin( func)
    
    local addScore = 0
    local score = self.m_runSpinResultData.p_selfMakeData.jackpot
    local winRow = self.m_runSpinResultData.p_selfMakeData.series
    local jackpotScore = 0
    local nJackpotType = 1
    local waitTimes = 0
    if score ~= nil then
        if score == "Grand" then
            jackpotScore = self.m_parent:BaseMania_getJackpotScore(1) 
            addScore = jackpotScore + addScore
            nJackpotType = 1
            self:findChild(self.m_respinJackpotBgName[1]):setVisible(true) 
            
            waitTimes = 2
            gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/Charms_WinJackPot3.mp3")

            local jpBg =  self:findChild(self.m_respinJackpotBgName[1]):getChildByName("JackPotBg")
            if jpBg then
                jpBg:runCsbAction("animation0",true)
            end
        elseif score == "Major" then
            waitTimes = 2
            gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/Charms_WinJackPot2.mp3")

            jackpotScore = self.m_parent:BaseMania_getJackpotScore(2)
            addScore = jackpotScore + addScore
            nJackpotType = 2
            local index = self:getShowMajorIndx( )
            self:findChild(self.m_respinJackpotBgName[index]):setVisible(true)
            local jpBg =  self:findChild(self.m_respinJackpotBgName[index]):getChildByName("JackPotBg")
            if jpBg then
                jpBg:runCsbAction("animation0",true)
            end
        
        elseif score == "Minor" then
            waitTimes = 1
            gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/Charms_WinJackPot1.mp3")

            jackpotScore =  self.m_parent:BaseMania_getJackpotScore(3)
            addScore =jackpotScore + addScore                 
            nJackpotType = 3
            local index = self:getShowMinorIndx( )
            self:findChild(self.m_respinJackpotBgName[index]):setVisible(true)
            local jpBg =  self:findChild(self.m_respinJackpotBgName[index]):getChildByName("JackPotBg")
            if jpBg then
                jpBg:runCsbAction("animation0",true)
            end
            
        elseif score == "Mini" then
            jackpotScore = self.m_parent:BaseMania_getJackpotScore(4)  
            addScore =  jackpotScore + addScore                     
            nJackpotType = 4
        end

        self.m_lightScore = self.m_lightScore + addScore

        performWithDelay(self,function(  )
            if self.m_bProduceSlots_InFreeSpin then
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin 
    
            else
                
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin  
            end
    
    
            -- 显示提示背景
    
            self:showRespinJackpot(nJackpotType,jackpotScore, function()
               if func then
                    func()
               end 

                for k,v in pairs(self.m_respinJackpotBgName) do
                    self:findChild(v):setVisible(false) 
                    local jpBg =  self:findChild(v):getChildByName("JackPotBg")
                    if jpBg then
                        jpBg:runCsbAction("animation0",true)
                    end
                    
                end
            end)
        end,3 + waitTimes)


    else
        if func then
            func()
       end 
    end

    
    
           

end

function FourInOneCharmsMiniMachine:playChipCollectAnim()

    self.m_isPlayRespinEnd = true

    local m_chipList = self:getEndChip( )
    
    if self.m_playAnimIndex > #m_chipList then --- 这里待确认  是否中了grand 其他小块就不赢钱
        
        -- 最后检查一下有没连续的列来触发jackpot
        self:jackPotEndWin( function(  )
            -- 此处跳出迭代
            self:playLightEffectEnd()
        end)

        return 
    end

    local chipNode = m_chipList[self.m_playAnimIndex]
    local nodePos = chipNode:getParent():convertToWorldSpace(cc.p(chipNode:getPositionX(),chipNode:getPositionY()))
    nodePos = self.m_clipParent:convertToNodeSpace(nodePos)

    local iCol = chipNode.p_cloumnIndex
    local iRow = chipNode.p_rowIndex            
    local nFixIdx = (self.m_iReelRowNum - iRow) * self.m_iReelColumnNum + iCol 

    -- 根据网络数据获得当前固定小块的分数
    local scoreIndx = self:getPosReelIdx(iRow ,iCol)
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
            self.m_playAnimIndex = self. m_playAnimIndex + 1
            self:playChipCollectAnim() 
        else
            self:showRespinJackpot(nJackpotType, jackpotScore, function()
                self.m_playAnimIndex = self.m_playAnimIndex + 1
                self:playChipCollectAnim() 
            end)
           
        end
    end

    -- 添加鱼飞行轨迹
    local function fishFly()

            
        self.m_parent:playCoinWinEffectUI()


            chipNode:runAnim("over")
            local noverAnimTime = 0.4

            gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_respinEnd_win.mp3")
            
            if self.m_bProduceSlots_InFreeSpin then
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin 
        
            else
                
                local coins = self.m_lightScore  
                local lastWinCoin = globalData.slotRunData.lastWinCoin
                globalData.slotRunData.lastWinCoin = 0
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{coins,false,false})
                globalData.slotRunData.lastWinCoin = lastWinCoin  
            end

            scheduler.performWithDelayGlobal(function()

                fishFlyEndJiesuan()    

            end,noverAnimTime,self:getModuleName())
        
    end


    fishFly()        


    
end



--结束移除小块调用结算特效
function FourInOneCharmsMiniMachine:reSpinEndAction()    
    
    self.m_respinSpinbar:changeRespinTimes(0)

    -- 播放收集动画效果
    self.m_chipList = {} -- 模拟逻辑判断出来的chip 列表
    self.m_playAnimIndex = 1

    -- 获得所有固定的respinBonus小块
    self.m_chipList = self.m_respinView:getAllCleaningNode()    

    self:removeAllRespinJackPotTipNode()

    self.m_respinSpinbar:setVisible(false)

    self.m_parent.m_respinOverRunning = true

    self.m_parent:clearCurMusicBg()

    gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_respinEndTip.mp3")
    performWithDelay(self, function(  )
        self:playChipCollectAnim()
    end,2)
    
end


-- 根据本关卡实际小块数量填写
function FourInOneCharmsMiniMachine:getRespinRandomTypes( )
    local symbolList = { self.SYMBOL_Charms_P1,
            self.SYMBOL_Charms_P2,
            self.SYMBOL_Charms_P3,
            self.SYMBOL_Charms_P4,
            self.SYMBOL_Charms_P5,
            self.SYMBOL_Charms_Ace,
            self.SYMBOL_Charms_King,
            self.SYMBOL_Charms_Queen,
            self.SYMBOL_Charms_Jack}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function FourInOneCharmsMiniMachine:getRespinLockTypes( )
    local symbolList = {
        {type = self.SYMBOL_Charms_SYMBOL_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_Charms_MINOR_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_Charms_bonus, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_Charms_MINI, runEndAnimaName = "buling2", bRandom = true},
        {type = self.SYMBOL_Charms_MINOR, runEndAnimaName = "buling2", bRandom = true},
        {type = -self.SYMBOL_Charms_SYMBOL_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_Charms_MINOR_DOUBLE, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_Charms_bonus, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_Charms_MINI, runEndAnimaName = "buling2", bRandom = true},
        {type = - self.SYMBOL_Charms_MINOR, runEndAnimaName = "buling2", bRandom = true}


    }

    return symbolList
end

-- 根据本关卡实际小块数量填写
function FourInOneCharmsMiniMachine:getBoomRespinRandomTypes( )
    local symbolList = { self.SYMBOL_Charms_SYMBOL_NULL,
self.SYMBOL_Charms_SYMBOL_BOOM_RUN}

    return symbolList
end

-- 根据本关卡实际锁定小块数量填写
function FourInOneCharmsMiniMachine:getBoomRespinLockTypes( )
    local symbolList = { 
    }

    return symbolList
end

function FourInOneCharmsMiniMachine:showRespinView()


      
        --可随机的普通信息
        local randomTypes = self:getRespinRandomTypes( )
        --可随机的特殊信号 
        local endTypes = self:getRespinLockTypes()

        -- 炸弹轮盘
        local boomEndTypes = self:getBoomRespinLockTypes( )
        local boomRandomTypes =  self:getBoomRespinRandomTypes( )

        self.m_iReelRowNum = RESPIN_ROW_COUNT
        self:respinChangeReelGridCount(RESPIN_ROW_COUNT)

        
        self:triggerReSpinCallFun(endTypes, randomTypes,boomEndTypes,boomRandomTypes) 


end

function FourInOneCharmsMiniMachine:getRespinNodeStates( symboltype )

    local states = nil

    states = RESPIN_NODE_STATUS.IDLE

    return states
end


----构造respin所需要的数据
--@machineElement: X Y 坐标 STATUS 状态 bCleaning 参与结算 Zorder层级 。。
function FourInOneCharmsMiniMachine:reateBoomRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self.SYMBOL_Charms_SYMBOL_NULL

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


            local symbolstatus = RESPIN_NODE_STATUS.IDLE
             if iRow > 3 then
                symbolstatus = RESPIN_NODE_STATUS.LOCK
            end
            local symbolNodeInfo = {
                status = symbolstatus ,
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
function FourInOneCharmsMiniMachine:reateRespinNodeInfo()
    local respinNodeInfo = {}

    for iCol = 1, self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[iCol]
        local rowCount = columnData.p_showGridCount
        for iRow = rowCount, 1, -1 do

            --信号类型
            local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

            if self:isScatterSymbolType( symbolType) then
                symbolType = self.SYMBOL_Charms_P1
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
                status = self:getRespinNodeStates( symbolType ) ,
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

-- 添加上大信号的信息
function FourInOneCharmsMiniMachine:triggerChangeRespinNodeInfo(respinNodeInfo )

    local bigBonusPositions =  self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}

    
    for k,v in pairs(bigBonusPositions) do
        local fixpos = self:getRowAndColByPosForSixRow(v)
        local iRow = fixpos.iX
        local iCol = fixpos.iY

        --信号类型
        local symbolType = self:getMatrixPosSymbolType(iRow, iCol)

        if math.abs( symbolType ) ==  self.SYMBOL_Charms_bonus  then
            symbolType = self.SYMBOL_Charms_SYMBOL_DOUBLE 
        elseif math.abs( symbolType ) == self.SYMBOL_Charms_MINOR then 
            symbolType = self.SYMBOL_Charms_MINOR_DOUBLE 
        end

        --层级
        local zorder = REEL_SYMBOL_ORDER.REEL_ORDER_2 - iRow
        --tag值
        local tag = self:getNodeTag(iRow + 100, iCol + 100, SYMBOL_NODE_TAG)
        --二维坐标
        local arrayPos = {iX = iRow, iY = iCol}

        --世界坐标
        local pos, reelHeight, reelWidth = self:getReelPos(iCol)
        pos.x = (pos.x + reelWidth / 2 * (self.m_parent.m_machineRootScale * parentScale)) + self.m_SlotNodeW/2 * (self.m_parent.m_machineRootScale * parentScale)
        local columnData = self.m_reelColDatas[iCol]
        local slotNodeH = columnData.p_showGridH   
        pos.y = pos.y + (iRow - 0.5) * slotNodeH * (self.m_parent.m_machineRootScale * parentScale)

        local symbolNodeInfo = {
            status = self:getRespinNodeStates( symbolType ) ,
            bCleaning = true,
            isVisible = true,
            Type = symbolType,
            Zorder = zorder,
            Tag = tag,
            Pos = pos,
            ArrayPos = arrayPos
        }
        respinNodeInfo[#respinNodeInfo + 1] = symbolNodeInfo

        break
    end

            

end


function FourInOneCharmsMiniMachine:initRespinView(endTypes, randomTypes,boomEndTypes,boomRandomTypes)
    
    --构造盘面数据
    local respinNodeInfo = self:reateRespinNodeInfo()

    --继承重写 改变盘面数据
    self:triggerChangeRespinNodeInfo(respinNodeInfo,randomTypes)

    self.m_respinView:initMachine(self)

    self.m_respinView:setEndSymbolType(endTypes, randomTypes)
    self.m_respinView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH  , self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_respinView:initRespinElement(
        respinNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
            self:playRespinViewShowSound()

            self:changeReSpinStartUI(self.m_runSpinResultData.p_reSpinCurCount)
            self.m_respinView:setVisible(true)
            self.m_BoomReelsView:setVisible(true)

            self:findChild("Node_respin_Lines"):setVisible(true) 
            self:findChild("Node_respin_Lines"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 11)
           
            self:findChild("Node_lines_re"):setVisible(true) 
            -- self:findChild("Node_lines_re"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 11)
           

            
        end
    )
    

    --炸弹轮盘
    --构造盘面数据
    local respinBoomNodeInfo = self:reateBoomRespinNodeInfo()
    self.m_BoomReelsView:initMachine(self)
    self.m_BoomReelsView:setEndSymbolType(boomEndTypes, boomRandomTypes)
    self.m_BoomReelsView:initRespinSize(self.m_SlotNodeW, self.m_SlotNodeH  , self.m_fReelWidth, self.m_fReelHeigth * self.m_respinLittleNodeSize)

    self.m_BoomReelsView:initRespinElement(
        respinBoomNodeInfo,
        self.m_iReelRowNum,
        self.m_iReelColumnNum,
        function()
           
        end
    )


    self.m_parent.m_bottomUI:updateWinCount("")

    self:hidAllUnLockUpSymbol()
    self.m_respinView:setVisible(true)
    self.m_BoomReelsView:setVisible(false)

    --隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)
    
    
end

---判断结算
function FourInOneCharmsMiniMachine:reSpinReelDown(addNode)
    --    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_BOTTOM_SPIN_RESPIN_STATUS,{self.m_runSpinResultData.p_reSpinCurCount})
    -- 更改spin btn 按钮显示和状态， 类型、是否可点击状态
    -- BtnType_Auto  BtnType_Stop  BtnType_Spin

    -- 轮盘全部停止时处理炸弹炸轮盘的

    local waitBulingTime = 0
    if self.m_boomNodeBulingList and #self.m_boomNodeBulingList > 0 then
        waitBulingTime = 1.65
    end

    performWithDelay(self,function(  )
        -- 是否播放炸开轮盘的动画
        local waitTime = self:checkBoomReels()

        performWithDelay(self,function(  )

           
            self.m_parent:reSpinSelfReelDown(addNode, function(  )
                self:checkRemoveNotNeedTipNode()
                self:createRespinJackPotTipNode()

                -- 移除火焰特效 
                self:removeAllFir( )
                -- 移除炸弹
                self:removeAllBoom( )
            end)


        end,waitTime)
    end,waitBulingTime)
    
    
end

function FourInOneCharmsMiniMachine:createFireNode(indexNum )


    local fixPos = self:getRowAndColByPosForSixRow(indexNum)
    local name = self.m_runSpinResultData.p_selfMakeData.unlock[tostring(fixPos.iY)] - fixPos.iX + 1
    
    if name < 0 and name > 6 then
        print("buduilelelele")
    end

    local pos = cc.p(self:getTarSpPos(indexNum))
    local fixY = fixPos.iX

    for i=2,name do
        local fir = util_createAnimation("LinkReels/CharmsLink/4in1_Charms_baozha_zhayao.csb")  
        self:findChild("Node_2"):addChild(fir,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 110)
        table.insert( self.m_FirList, fir )
        fir:setPosition(pos.x,pos.y + (self.m_SlotNodeH * (i - 1)))
        fir:setVisible(false)
        local posFireBoom = cc.p(pos.x,pos.y + (self.m_SlotNodeH * (i - 1)))
        performWithDelay(self,function(  )
            fir:setVisible(true)
            gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_Respin_Muzhang_Baozha.mp3")
            fir:playAction("actionframe",false,function(  )
                fir:setVisible(false)
            end) 


            local m_SymbolMatrix = self:getSymbolMatrixList( )

            for iRow = 1, self.m_iReelRowNum do
                if iRow == (fixY + (i - 1)) then
                    local symbolType = m_SymbolMatrix[iRow][fixPos.iY]
    
                    if symbolType == self.SYMBOL_Charms_UNLOCK_SYMBOL or self:getUpReelsMaxRow(fixPos.iY ,iRow) then


                        local index = self:getPosReelIdx(iRow ,fixPos.iY)
                        
                        self:removeOneRespinJackPotTipNode(index )
                        local isHide_1 = false
                        local isHide_2 = false
                        if type(self.m_lockList[index + 1]) ~= "number" then
                            isHide_1 = true
                        end
                        -- 解锁轮盘
                        self:removeLoclNodeForIndex(index)

                        if type(self.m_lockList[index + 1]) == "number" then
                            isHide_2 = true
                        end 

                        if isHide_1 and isHide_2 then
                            fir:setVisible(false)

                            local firBoom = util_createAnimation("LinkReels/CharmsLink/4in1_Charms_dangban.csb")  
                            self:findChild("Node_2"):addChild(firBoom,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 110)
                            
                            firBoom:setPosition(posFireBoom)
                            firBoom:playAction("actionframe",false,function(  )
                                firBoom:removeFromParent()
                            end) 
                        end 
                        -- 显示新轮盘  -2的
                        self:showOneUnLockUpSymbolFromColAndRow(fixPos.iY,iRow,symbolType )
        
                    end
                end
                
            end 

        end,0.16 * i )
    end



end

function FourInOneCharmsMiniMachine:checkBoomReels( )
    -- 是否播放炸开轮盘的动画

    local time = 0
    local fishNum = 0
    local dealyTime = 3
    local BoomCreateTime = 0
    local BoomShowtime = 1
    local BoomFireShowtime = 0
        
    

    local fish = self.m_runSpinResultData.p_selfMakeData.fish

    if fish and #fish > 0 then
        fishNum = #fish

        for k,v in pairs(fish) do
            local pos =  self:getTarSpPos(v )
            local Boom =  util_spineCreate("4in1_Socre_Charms_Boom1", true, true) -- util_createAnimation("4in1_Socre_Charms_Boom1.csb")  --
            util_spinePlay(Boom,"idleframe",true)
            -- Boom:playAction("idleframe",true)
            self:findChild("Node_2"):addChild(Boom,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 110)
            Boom.index = v
            Boom:setPosition(cc.p(pos))
            

            table.insert( self.m_BoomList, Boom )

            if k == fishNum then
                local fireReelsPos = self:getRowAndColByPosForSixRow(v)
                local fireNum = self.m_runSpinResultData.p_selfMakeData.unlock[tostring(fireReelsPos.iY)] - fireReelsPos.iX + 1
                BoomFireShowtime = BoomFireShowtime  + (0.16 * fireNum) 
            end
            
        end 

        performWithDelay(self,function(  )

            for k,v in pairs(fish) do
                local indexNum = v
                local indexid = k
                
                performWithDelay(self,function(  )

                    -- 炸弹炸开
                    
                    gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_Respin_Boom_Baozha_yinxian.mp3")
                    
                    util_spinePlay(self.m_BoomList[indexid],"actionframe",false)

                    -- self.m_BoomList[indexid]:playAction("actionframe",false,function(  )
                    --     -- self.m_BoomList[indexid]:setVisible(false) 
                    -- end,30)

                    performWithDelay(self,function(  )
                        gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_Respin_Boom_Baozha.mp3")
                          -- 显示烟火
                          self:createFireNode(indexNum )
                         
                    end,2)
 
                    
                end,dealyTime * (k - 1))
                
            end
        end,BoomCreateTime)


            

        time = ((fishNum)* dealyTime) + BoomCreateTime + BoomShowtime + BoomFireShowtime
    end

    

    return time

end

function FourInOneCharmsMiniMachine:hidAllUnLockUpSymbol( )
    local nodeList = self.m_respinView.m_respinNodes

    -- 双格特殊处理
    local bigBonusPositions =  self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}


    local m_SymbolMatrix = self:getSymbolMatrixList( )
    for k,v in pairs(nodeList) do
        local symbolType =  m_SymbolMatrix[v.p_rowIndex][v.p_colIndex]
        if symbolType <= self.SYMBOL_Charms_NULL_LOCK_SYMBOL 
            or self:getUpReelsMaxRow(v.p_colIndex ,v.p_rowIndex) then -- 双格特殊处理

                    v:setVisible(false)
        end

        -- 如果有双格信号特殊处理
        local index = self:getPosReelIdx(v.p_rowIndex,v.p_colIndex)
        for kv,vv in pairs(bigBonusPositions) do
            if vv == index then
                v:setVisible(false)
            end 
        end

        if math.abs( v.p_symbolType ) == self.SYMBOL_Charms_SYMBOL_DOUBLE 
            or math.abs( v.p_symbolType ) == self.SYMBOL_Charms_MINOR_DOUBLE  then
            if self:isInsetDoubleSymbolInEndChip()  then
                v:setVisible(true)
            else
                v:setVisible(false)
            end
        end
    end


    local cleanNodelist =   self.m_respinView:getAllCleaningNode()
    for k,v in pairs(cleanNodelist) do
        if v.p_symbolType <= self.SYMBOL_Charms_NULL_LOCK_SYMBOL 
            or self:getUpReelsMaxRow(v.p_cloumnIndex ,v.p_rowIndex) then     
                    
                    v:setVisible(false)
        end

        -- 如果有双格信号特殊处理
        local index = self:getPosReelIdx(v.p_rowIndex,v.p_cloumnIndex)
        for kv,vv in pairs(bigBonusPositions) do
            if vv == index then
                v:setVisible(false)
            end 
        end

        if math.abs( v.p_symbolType ) == self.SYMBOL_Charms_SYMBOL_DOUBLE
            or math.abs( v.p_symbolType ) == self.SYMBOL_Charms_MINOR_DOUBLE  then
            if self:isInsetDoubleSymbolInEndChip()  then
                v:setVisible(true)
            else
                v:setVisible(false)
            end
        end
        

    end

 
end

function FourInOneCharmsMiniMachine:showOneUnLockUpSymbolFromColAndRow(icol,irow,symboltype,syindex )
    local m_SymbolMatrix = self:getSymbolMatrixList( )
    local bigBonusPositions =  self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}

    local nodeList = self.m_respinView.m_respinNodes
    for k,v in pairs(nodeList) do
        
        --  symboltype 是 self.SYMBOL_Charms_SYMBOL_DOUBLE 的情况只有在respin开始时的动画结束时才会出现
        --  self.SYMBOL_Charms_SYMBOL_DOUBLE 目前只有一个所以可以真么
        if math.abs( symboltype ) == self.SYMBOL_Charms_SYMBOL_DOUBLE 
            or math.abs( symboltype ) == self.SYMBOL_Charms_MINOR_DOUBLE  then
        
                if (v.p_symbolType == self.SYMBOL_Charms_SYMBOL_DOUBLE or v.p_symbolType == self.SYMBOL_Charms_MINOR_DOUBLE )  and  v.p_colIndex == icol and v.p_rowIndex == irow   then
                    v:setVisible(true)
                    --利用两个小块的背景来显示双格块的背景
                    for kk,vk in pairs(nodeList) do
                        -- 如果有双格信号特殊处理
                        local index = self:getPosReelIdx(vk.p_rowIndex,vk.p_colIndex)
                        for kv,vv in pairs(bigBonusPositions) do
                            if vv == index then
                                vk:setVisible(true)
                            end 
                        end
                    end

                    break
                end

        else
            local symbolType =  m_SymbolMatrix[v.p_rowIndex][v.p_colIndex]
            if symbolType == symboltype and v.p_colIndex == icol and v.p_rowIndex == irow   then
                v:setVisible(true)
                break
            end
        end  
                    
            
        
    end

    local cleanNodelist = self.m_respinView:getAllCleaningNode()

    for k,v in pairs(cleanNodelist) do

        if math.abs( symboltype ) == self.SYMBOL_Charms_SYMBOL_DOUBLE 
            or math.abs( symboltype ) == self.SYMBOL_Charms_MINOR_DOUBLE  then
               

        else
            if v.p_symbolType == symboltype and v.p_cloumnIndex == icol and v.p_rowIndex == irow   then
                v:setVisible(true)
                break
            end

        end
       
    end


    for k,v in pairs(cleanNodelist) do

        local index = self:getPosReelIdx(v.p_rowIndex,v.p_cloumnIndex)
        for kv,vv in pairs(bigBonusPositions) do

            if syindex then
                if syindex == vv then
                    if math.abs( v.p_symbolType ) == self.SYMBOL_Charms_SYMBOL_DOUBLE 
                        or math.abs( v.p_symbolType ) == self.SYMBOL_Charms_MINOR_DOUBLE  then
                            v:setVisible(true)
                            break
                    end
                end
            else
                if vv == index then 
                    if math.abs( v.p_symbolType ) == self.SYMBOL_Charms_SYMBOL_DOUBLE 
                        or math.abs( v.p_symbolType ) == self.SYMBOL_Charms_MINOR_DOUBLE  then
                            v:setVisible(true)
    
                    else
                        v:setVisible(false)
                    end
    
                end 

            end
           
            
        end
    end


    
end

function FourInOneCharmsMiniMachine:showReSpinStart()
    

    -- 播放对应的添加上边轮盘的动画
    self:createRunningSymbolAnimation( function(  )

        performWithDelay(self,function(  )
            

            if self.m_DouDongid then
                gLobalSoundManager:stopAudio(self.m_DouDongid)
                self.m_DouDongid = nil
            end 
            -- 过场动画播完了 
            -- 给未解锁的加锁
            local LockSymbolTime =    self:createLockSymbol()

            performWithDelay(self,function(  )

            -- 是否播放炸开轮盘的动画
                local waitTime = self:checkBoomReels()

                performWithDelay(self,function(  )
                    self:checkRemoveNotNeedTipNode()

                    self:createRespinJackPotTipNode()

                    -- 移除火焰特效 
                    self:removeAllFir( )
                    -- 移除炸弹
                    self:removeAllBoom( )


                    self:runNextReSpinReel()
                end,waitTime)
            end,LockSymbolTime)
        end,1)
        
    
    end )

    
end


--ReSpin开始改变UI状态
function FourInOneCharmsMiniMachine:changeReSpinStartUI(respinCount)
   
    if self.m_RSjackPotBar then
        self.m_RSjackPotBar:setVisible(true)
    end
    
    -- 隐藏 盘面信息
    self:setReelSlotsNodeVisible(false)

    self:runCsbAction("actionframe1")
    self.m_respinSpinbar:setVisible(true)
    self.m_respinSpinbar:changeRespinTimes(respinCount,true)
    
end

--ReSpin刷新数量
function FourInOneCharmsMiniMachine:changeReSpinUpdateUI(curCount)
    print("当前展示位置信息  %d ", curCount)
    self.m_respinSpinbar:changeRespinTimes(curCount)
end

--ReSpin结算改变UI状态
function FourInOneCharmsMiniMachine:changeReSpinOverUI()

    
end

function FourInOneCharmsMiniMachine:showRespinOverView(effectData)


    gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_open_over_View.mp3")

    local strCoins= self.m_lightScore

    self.m_parent:showRespinOverView(strCoins)
end


-- --重写组织respinData信息
function FourInOneCharmsMiniMachine:getRespinSpinData()
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

-- 获取到炸弹的轮盘位置
function FourInOneCharmsMiniMachine:getBoomRespinReelsButStored( )
    local BoomList = {}
    if self.m_runSpinResultData.p_selfMakeData then
        local storedIcons = self.m_runSpinResultData.p_selfMakeData.fish or {}
        for k,v in pairs(storedIcons) do
            local fixPos = self:getRowAndColByPosForSixRow(v)
            table.insert( BoomList,  fixPos )
        end
    end
    return BoomList
end

---
-- 处理spin 结果轮盘数据
--
function FourInOneCharmsMiniMachine:MachineRule_network_ProbabilityCtrl()
    
    local rowCount = #self.m_runSpinResultData.p_reels
    for rowIndex=1,rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex=1,colCount do
            local symbolType = rowDatas[colIndex]
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
    local iRow = #self.m_runSpinResultData.p_reels -- self.m_iReelRowNum

    for colIndex=1,iColumn do
        
        local rowIndex= 1 + self:getRespinAddNum( )


        while true do
            if rowIndex > iRow then
                break
            end
            local symbolType = self.m_stcValidSymbolMatrix[rowIndex][colIndex]
            -- 判断是否有大信号内容
            if self.m_hasBigSymbol == true and self.m_bigSymbolInfos[symbolType] ~= nil  then

                local bigInfo = {startRowIndex = NONE_BIG_SYMBOL_FLAG,changeRows = {}}
                
                
                local colDatas = self.m_bigSymbolColumnInfo[colIndex]
                if colDatas == nil then
                    colDatas = {}
                    self.m_bigSymbolColumnInfo[colIndex] = colDatas
                end           

                colDatas[#colDatas + 1] = bigInfo     

                local symbolCount = self.m_bigSymbolInfos[symbolType]

                local hasCount = 1

                bigInfo.changeRows[#bigInfo.changeRows + 1] = rowIndex

                for checkIndex = rowIndex + 1,iRow do
                    local checkType = self.m_stcValidSymbolMatrix[checkIndex][colIndex]
                    if checkType == symbolType then
                        hasCount = hasCount + 1

                        bigInfo.changeRows[#bigInfo.changeRows + 1] = checkIndex
                    end
                end

                if symbolCount == hasCount or rowIndex > 1 then  -- 表明从对应索引开始的
                    bigInfo.startRowIndex = rowIndex
                else

                    bigInfo.startRowIndex = rowIndex - (symbolCount - hasCount)
                end

                rowIndex = rowIndex + hasCount - 1  -- 跳过上面有的

            end -- end if ~= nil 

            rowIndex = rowIndex + 1
        end

    end

end

function FourInOneCharmsMiniMachine:getSymbolMatrixList( )
    
    local m_SymbolMatrix = {}

    for row=1,6 do
        m_SymbolMatrix[row] = {}
       for col=1,5 do
            m_SymbolMatrix[row][col] = "null"
       end
    end

    local rowCount = #self.m_runSpinResultData.p_reels
    for rowIndex=1,rowCount do
        local rowDatas = self.m_runSpinResultData.p_reels[rowIndex]
        local colCount = #rowDatas

        for colIndex=1,colCount do
            local symbolType = rowDatas[colIndex]
            m_SymbolMatrix[rowCount - rowIndex + 1][colIndex] = symbolType
        end
        
    end

    return  m_SymbolMatrix
end

function FourInOneCharmsMiniMachine:getRunningInfo( )

    

    local m_SymbolMatrix = self:getSymbolMatrixList( )

    local doubleSymbol = self.m_runSpinResultData.p_selfMakeData.bigBonusPositions or {}
    

    local removeList = nil
    local removeIndex = nil

    local upLockInfoList = {}
    for iCol = 1, self.m_iReelColumnNum do
        for iRow = 1, self.m_iReelRowNum do
            local symbolType = m_SymbolMatrix[iRow][iCol]
            if symbolType < self.SYMBOL_Charms_UNLOCK_SYMBOL then

                local value = {}
                value.icol = iCol
                value.irow = iRow
                value.index = self:getPosReelIdx(iRow ,iCol)
                value.symboltype = symbolType
                if math.abs(value.symboltype) == self.SYMBOL_Charms_bonus  then
                    local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) --获取分数（网络数
                    local lineBet = globalData.slotRunData:getCurTotalBet() / 4 
                    score = score * lineBet
                    score = util_formatCoins(score, 3)

                    value.coins = score or 000000
                end
                table.insert( upLockInfoList,value )
            end

            -- 大块未解锁状态 给大块赋值为 bigBonusPositions 数组1 位置的信息
            if not self:isInsetDoubleSymbolInEndChip( ) then
                local index = self:getPosReelIdx(iRow, iCol)
                local vv = doubleSymbol[1]
                if vv == index  then
                    removeIndex = #upLockInfoList
                    if removeIndex == 0 then
                        removeIndex = 1
                    end

                    removeList = {}
                    removeList.icol = iCol
                    removeList.irow = iRow
                    removeList.index = self:getPosReelIdx(iRow ,iCol)
                    removeList.symboltype = symbolType
                    if math.abs(symbolType) == self.SYMBOL_Charms_bonus then
                        removeList.symboltype = self.SYMBOL_Charms_SYMBOL_DOUBLE
                        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow ,iCol)) --获取分数（网络数
                        local lineBet = globalData.slotRunData:getCurTotalBet() / 4
                        score = score * lineBet
                        score = util_formatCoins(score, 3)
                        removeList.coins = score or 000000
                    elseif math.abs(symbolType) == self.SYMBOL_Charms_MINOR then 
                        removeList.symboltype = self.SYMBOL_Charms_MINOR_DOUBLE

                    end
                end

            end

        end
    end

    
    for i = #upLockInfoList,1,-1 do
        local chipNode = upLockInfoList[i]
        local isIn = false
        local index = self:getPosReelIdx(chipNode.irow, chipNode.icol)
        for kk,vv in pairs(doubleSymbol) do
            if vv == index  then
                table.remove( upLockInfoList, i )
            end
        end
    end

    -- 把双格块塞进去
    if removeIndex and removeList then
        table.insert( upLockInfoList,removeIndex,removeList ) 
    end



    return upLockInfoList
end

function FourInOneCharmsMiniMachine:isInArray( array,value)
   local isIn = false
   for k,v in pairs(array) do
       if v == value then
            isIn = true
            break
       end

   end

   return isIn
end

--[[
    @desc: respin触发，飞行小块特效
    --@triggerFunc: 最后一个小块落地调用
]]
function FourInOneCharmsMiniMachine:createRunningSymbolAnimation( triggerFunc )
    
    local netData = self:getRunningInfo()
    if #netData <= 0 then
        if triggerFunc then
            triggerFunc()
        end
        return
    end

    local createdNetIndex = 1
    local createdNetMaxIndex = #netData
    local createdrandomIndex = 1
    
    local flayNode = cc.Node:create()
    flayNode:setName("flayNode")
    flayNode:setPosition(0,0)
    self:findChild("Node_2"):addChild(flayNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 13) 

    self.m_DouDongid = gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_DouDong.mp3")

    self:runCsbAction("dou_chuxian",false,function(  )
        self:runCsbAction("dou_idle",true)
    end)

    schedule(flayNode,function ()
        local iscreate = math.random( 1,2 )
        if iscreate == 1 then
            local  Createnum = math.random( 3,4 )
            for i=1,Createnum do
                local num = math.random( 1,6 )

                if createdNetIndex >  createdNetMaxIndex then
                    print("真的该结束了 不应该创建了 ") 
                    return 
                end

                createdrandomIndex = createdrandomIndex + 1
                local show = false

                local begin =  (createdrandomIndex % 10)
                if begin == 0 and createdrandomIndex > 5 and createdNetIndex <=  createdNetMaxIndex  then
                    show = true
                end

                local data = {}
                if show then -- 根据网络数据创建
                    
                    print("createdrandomIndex ======= "..createdrandomIndex)

                    data.symboltype = netData[createdNetIndex].symboltype  
                    data.machine = self
                    if math.abs(data.symboltype) == self.SYMBOL_Charms_bonus or math.abs(data.symboltype) == self.SYMBOL_Charms_SYMBOL_DOUBLE  then
                        data.coins = netData[createdNetIndex].coins 
                    end

                else -- 随机数据
                    data.symboltype = self:getRodomSymbolType()
                    data.machine = self
                    if math.abs(data.symboltype) == self.SYMBOL_Charms_bonus or math.abs(data.symboltype) == self.SYMBOL_Charms_SYMBOL_DOUBLE  then
                        data.coins = self:getFlyNodeRandomCoins()
                    end
                end
                
                local moveSymbol = util_createView("CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsViewFlyNode",data)
                local xPos = display.width / 2 + (display.width / 2  * 0.3 * ((createdrandomIndex % 5) - 3)) 
                local yPos = display.height
                moveSymbol:setPositionX(xPos)
                moveSymbol:setPositionY(yPos)
                flayNode:addChild(moveSymbol)
                local endPos = cc.p(xPos,0)
                local rand1 = math.random( 1,3 )
                local speed = 10 + rand1 * 0.5 * 30
                local func = nil

                if show then

                    -- 创建落地烟雾
                    local Smoke = util_createView("CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsViewSmoke") 
                    flayNode:addChild(Smoke)
                    if Smoke then
                        Smoke:setVisible(false)
                    end

                    
                    
                    local moveXDis = 0
                    if math.abs(data.symboltype) == self.SYMBOL_Charms_SYMBOL_DOUBLE or math.abs(data.symboltype) == self.SYMBOL_Charms_MINOR_DOUBLE  then
                        moveXDis = self.m_SlotNodeW/2
                    end
                    local roandomSymbolIndex =  netData[createdNetIndex].index  -- math.random( 1, 30) - 1
                    local nodePos = cc.p(self:getTarSpPos(roandomSymbolIndex ))
                    local targSpPos = cc.p(nodePos.x + moveXDis,nodePos.y) 
                    
                    endPos =  cc.p(targSpPos.x ,targSpPos.y ) 
                    moveSymbol:setPositionX(targSpPos.x)
                    Smoke:setPosition(endPos)

                    local netDataInfo = netData[createdNetIndex]
                    local endNetIndex = createdNetIndex
                    func = function(  )
                                print("dadadada========= "..endNetIndex)
                                gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_Respin_Boom_Down.mp3")

                                Smoke:setVisible(true)
                                Smoke:showAnimation(1,function(  )
                                    if Smoke then
                                        Smoke:setVisible(false)
                                    end

                                end)
                                -- if netDataInfo.icol == 3 and netDataInfo.irow == 5 then 
                                --     print("dadadada")
                                -- end
                                dump(netDataInfo)

                                self:showOneUnLockUpSymbolFromColAndRow(netDataInfo.icol,netDataInfo.irow,netDataInfo.symboltype,netDataInfo.index )

                                if endNetIndex >= createdNetMaxIndex then
                                    print("真的该结束了 " ..roandomSymbolIndex..targSpPos.y ) 

                                    flayNode:stopAllActions()
                                    
                                    performWithDelay(self,function(  )
                                        self:runCsbAction("dou_xiaoshi")
  
                                        if triggerFunc then
                                            triggerFunc()
                                        end

                                        -- local actionList={}
                                        -- actionList[#actionList+1]=cc.FadeOut:create(1)
                                        -- actionList[#actionList+1]=cc.CallFunc:create(function()
                                        
                                        -- end)
                                        -- local seq=cc.Sequence:create(actionList)  
                                        -- flayNode:runAction(cc.RepeatForever:create(seq))  --???  3 好像是设置动画 但是设置了怎样的动画不太理解

                                        
                                        flayNode:removeFromParent()
                                    end,1)
                                    
                                end
                                print("真实数据移动到结束" ..roandomSymbolIndex..targSpPos.y ) 
                            end


                    createdNetIndex = createdNetIndex + 1
                end
                
                --print("endPos ----"..endPos.x)
                self:moveAction(moveSymbol,endPos,func,speed)

                
            end
        end
    end,0.1)



end


function FourInOneCharmsMiniMachine:moveAction( node,endPos,func,speed)


    local finalPos = cc.p(endPos.x,endPos.y) 
    local finalSpeed = speed
    local symbolNode = node

    schedule(symbolNode,function ()
        
        local PosY = cc.p(symbolNode:getPosition()).y 

        --print("-----endpos"..PosY)
        local needHeight = PosY - endPos.y
        if PosY <= finalPos.y or  needHeight <= finalSpeed   then

            symbolNode:setPosition(finalPos)

            if func then
                func()
                
                func = nil     
            end

            if symbolNode then
                symbolNode:stopAllActions()  
                symbolNode:removeFromParent()
            end

        end

        symbolNode:setPositionY(PosY - finalSpeed)

        
    end,0.01)


end

function FourInOneCharmsMiniMachine:getRodomSymbolType(  )
    local symbolTypeList = {self.SYMBOL_Charms_MINOR,
                            self.SYMBOL_Charms_MINI,
                            self.SYMBOL_Charms_bonus,
                            self.SYMBOL_Charms_SYMBOL_DOUBLE}

    local rodomIndex = math.random( 1, #symbolTypeList )

    return symbolTypeList[rodomIndex]
end

function FourInOneCharmsMiniMachine:getFlyNodeRandomCoins( )

    
    local score =  self:randomDownRespinSymbolScore(self.SYMBOL_Charms_bonus) -- 获取随机分数（本地配置）
    if score ~= nil  then
        local lineBet = globalData.slotRunData:getCurTotalBet() / 4
        score = score * lineBet
        score = util_formatCoins(score, 3)
    else
        score = 000
    end

    return score
end

-- 只处理炸弹炸金块时 信号类型提前变为正数
function FourInOneCharmsMiniMachine:getUpReelsMaxRow(icol ,irow)
    local isBoom = false
    
    local netMaxNet =  self.m_runSpinResultData.p_selfMakeData.unlock
    local netFish = self.m_runSpinResultData.p_selfMakeData.fish
    if netFish and #netFish > 0 then

        for k,v in pairs(netFish) do
            local fixPos = self:getRowAndColByPosForSixRow(v)
            if fixPos.iY == icol then
               local maxRow =  netMaxNet[tostring(fixPos.iY)]

               if maxRow >= irow and irow > NORMAL_ROW_COUNT then
                    isBoom = true

                    break
               end
               
            end
        end
    end

    return isBoom
end

---------------- 创建锁定小块
function FourInOneCharmsMiniMachine:createLockSymbol( )

    local time = 0
    local delayTime = 0.3
    local isWite = false

    local m_SymbolMatrix = self:getSymbolMatrixList( )


    

    
    for iRow = 1, self.m_iReelRowNum do

        local isPlay = true

        local rowWaitTime = 0
        if iRow > 3 then
            rowWaitTime = (iRow -3) * delayTime
        end

        
        for iCol = 1, self.m_iReelColumnNum do

            local symbolType = m_SymbolMatrix[iRow][iCol]

            if symbolType < 0 or self:getUpReelsMaxRow(iCol, iRow) then

                isWite = true

                performWithDelay(self,function(  )

                    if isPlay == true then
                        gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/Charms_Lock.mp3")
                        isPlay = false
                    end

                    local index = self:getPosReelIdx(iRow ,iCol) 
                    local lockView = util_createView("CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsLockView")
                    local viewPos = self:getTarSpPos(index )
                    lockView.m_lock:runCsbAction("buling")
                    lockView:setPosition(viewPos)  
                    self:findChild("Node_2"):addChild(lockView,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100)

                    local topAct = util_createAnimation("LinkReels/CharmsLink/4in1_Charms_dangban_top.csb")
                    topAct:setPosition(viewPos) 
                    self:findChild("Node_2"):addChild(topAct,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 101)
                    topAct:playAction("buling",false,function(  )
                        topAct:removeFromParent()
                    end)
                    local downAct = util_createAnimation("LinkReels/CharmsLink/4in1_Charms_dangban_down.csb")
                    downAct:setPosition(viewPos) 
                    self:findChild("Node_2"):addChild(downAct,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 99)
                    downAct:playAction("buling",false,function(  )
                        downAct:removeFromParent()
                    end)
                    if self.m_lockList[index + 1] == self.CHARMS_LOCKVIEW_NODE_STATUS.LOCKNULL then
                        self.m_lockList[index + 1] = lockView
                    end
                end,rowWaitTime)
                
        
            end

        end
        
    end

    if isWite == true then
        time = delayTime * 3 + 1.5
    end
    
    return time
end
--[[
    @desc: 根据信号id进行小块移除
    -- index ：从一开始
]]
function FourInOneCharmsMiniMachine:removeLoclNodeForIndex(index,func )

    local posindex = index

    if type(self.m_lockList[posindex + 1]) == "number" then
        return
    end
    
    local node = self.m_lockList[posindex + 1].m_lock
    node:runCsbAction("actionframe")
    self.m_lockList[posindex + 1] = self.CHARMS_LOCKVIEW_NODE_STATUS.LOCKDNODE
    
    performWithDelay(self,function(  )
        if func then
            func()
        end

        if node then
            node:setVisible(false)
        end
        
        

        -- self.m_lockList[posindex + 1] = self.CHARMS_LOCKVIEW_NODE_STATUS.LOCKDNODE
       
    end,1.5)


   
    
    

end

function FourInOneCharmsMiniMachine:removeAllFir( )
   for k,v in pairs(self.m_FirList) do
        v:removeFromParent()
   end

   self.m_FirList = {}
end

function FourInOneCharmsMiniMachine:removeAllBoom( )
    
    for k,v in pairs(self.m_BoomList) do
        v:removeFromParent()
        
    end
    self.m_BoomList = {}
end

function FourInOneCharmsMiniMachine:removeAllLockNode( )

    for k,v in pairs(self.m_lockList) do
        if v and type(v) ~= "number" then
            v:removeFromParent() 
        end

        v = nil
    end
   
    self:initLockList()
end

----------------- 工具

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function FourInOneCharmsMiniMachine:getThreeReelsTarSpPos(index )
    local fixPos = self:getRowAndColByPos(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得节点的轮盘对应位置
    author:{author}
    time:2019-05-20 17:57:44
    --@index: 对应序号id
    @return: cc.p()
]]
function FourInOneCharmsMiniMachine:getTarSpPos(index )
    local fixPos = self:getRowAndColByPosForSixRow(index)
    local targSpPos =  self:getNodePosByColAndRow(fixPos.iX, fixPos.iY)


    return targSpPos
end

--[[
    @desc: 获得轮盘的位置
    time:2019-05-20 17:56:27
]]
function FourInOneCharmsMiniMachine:getNodePosByColAndRow(row, col)
    local reelNode = self:findChild("sp_reel_" .. (col - 1))

    local posX, posY = reelNode:getPosition()

    posX = posX + self.m_SlotNodeW * 0.5
    posY = posY + (row - 0.5) * self.m_SlotNodeH

    return cc.p(posX, posY)
end

--- respin下 6行的情况
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function FourInOneCharmsMiniMachine:getRowAndColByPosForSixRow(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_iReelColumnNum

    local rowIndex = RESPIN_ROW_COUNT - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex,iY = colIndex}
end

--  --- 新添一个respin轮盘专门滚炸弹
--- respin 快停
function FourInOneCharmsMiniMachine:quicklyStop()
    BaseMiniMachine.quicklyStop(self)
    self.m_BoomReelsView:quicklyStop()
end
--开始滚动
function FourInOneCharmsMiniMachine:startReSpinRun()
    
    if self.m_respinView:getouchStatus() == ENUM_TOUCH_STATUS.RUN then
        return
    end

    
    if globalData.GameConfig.checkNormalReel then
        if globalData.GameConfig:checkNormalReel() == false then
            self.m_parent.m_startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
        else
            self.m_parent.m_startSpinTime = nil
        end
    end
    
    --一次新的spin发个通知
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NORMAL_SPIN_BTNCALL)
    
    self:requestSpinReusltData()
    --    dump(self.m_runSpinResultData,"m_runSpinResultData")
    if self.m_runSpinResultData.p_reSpinCurCount - 1 >= 0 then
        self:changeReSpinUpdateUI(self.m_runSpinResultData.p_reSpinCurCount - 1)
    end

    self.m_respinView:startMove()


    self.m_BoomReelsView.m_boomNodeEndList = {} -- 每次开始滚动重置一下数组
    self.m_BoomReelsView.m_boomNodeBulingList = {}
    self.m_BoomReelsView:startMove()

    
end

--触发respin
function FourInOneCharmsMiniMachine:triggerReSpinCallFun(endTypes, randomTypes,boomEndTypes,boomRandomTypes)
    
    if self.changeTouchSpinLayerSize then
        self:changeTouchSpinLayerSize()
    end

    self:setCurrSpinMode( RESPIN_MODE )
    self.m_specialReels = true

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    if self.m_runSpinResultData.p_reSpinsTotalCount == 0 then
        self.m_runSpinResultData.p_reSpinsTotalCount = 3
    end

    self:clearWinLineEffect()

    self.m_respinView = util_createView(self:getRespinView(), self:getRespinNode())
    self.m_respinView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_respinView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE)

    

    -- 创建炸弹respin层
    self.m_BoomReelsView = util_createView(self:getBoomRespinView(), self:getBoomRespinNode())
    self.m_BoomReelsView:setCreateAndPushSymbolFun(
        function(symbolType,iRow,iCol,isLastSymbol)
            return self:getSlotNodeWithPosAndType(symbolType,iRow,iCol,isLastSymbol)
        end,
        function(targSp)
            self:pushSlotNodeToPoolBySymobolType(targSp.p_symbolType, targSp)
        end
    )
    self.m_clipParent:addChild(self.m_BoomReelsView, SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 10)

    

    self:initRespinView(endTypes, randomTypes,boomEndTypes,boomRandomTypes)
end

--接收到数据开始停止滚动
function FourInOneCharmsMiniMachine:stopRespinRun()
    local storedNodeInfo = self:getRespinSpinData()
    local unStoredReels = self:getRespinReelsButStored(storedNodeInfo)
    self.m_respinView:setRunEndInfo(storedNodeInfo, unStoredReels)

    local BoomStoredReels = self:getBoomRespinReelsButStored()
    self.m_BoomReelsView:setRunEndInfo(storedNodeInfo, unStoredReels,BoomStoredReels)

end

--开始下次ReSpin
function FourInOneCharmsMiniMachine:runNextReSpinReel(_isDownStates)
    
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


function FourInOneCharmsMiniMachine:checkRespinChangeOverTip(node,endAnimaName,loop)
    node:runAnim("idleframe")
    if type(endAnimaName) == "string" and endAnimaName ~= "" then
        node:runAnim(endAnimaName, loop)
    end
    if node.p_symbolType and node.p_rowIndex <= 3 then
        if self:isFixSymbol(node.p_symbolType) then
            node:runAnim("actionframe",true)
        end  
    end
end
--结束移除小块调用结算特效
function FourInOneCharmsMiniMachine:removeRespinNode()
    BaseMiniMachine.removeRespinNode(self)
    if self.m_BoomReelsView then
        self.m_BoomReelsView:removeFromParent()
        self.m_BoomReelsView = nil
    end
end

-- ----创建respin下连续触发jackpot提示

function FourInOneCharmsMiniMachine:checkRemoveNotNeedTipNode( )
    local nextJackpo = self.m_runSpinResultData.p_selfMakeData.nextJackpot
    if nextJackpo  then
        local IndexList = {}
        local removeIndex = nil
        for kk,vk in pairs(self.respinJackPotTipNodeList) do
            local isremove = false
            for k,v in pairs(nextJackpo) do
                local index = tonumber(k)  
                if type(vk) ~= "number"  then
                    if index == vk.index then
                        isremove = false
                    else
                        isremove = true
                        removeIndex = vk.index 
                    end
                end
                
            end

            if isremove and removeIndex then
                self:removeOneRespinJackPotTipNode(removeIndex )
            end
        end 
        
    end
end

function FourInOneCharmsMiniMachine:checkIsInTipNodeList( index )
    local isin = false
    for k,v in pairs(self.respinJackPotTipNodeList) do
        if type(v) ~= "number" and index == v.index then
           if v and  type(v) ~= "number" then
                isin = true
                break
           end
        end
    end
    return isin
end

function FourInOneCharmsMiniMachine:createRespinJackPotTipNode( )

    local nextJackpo = self.m_runSpinResultData.p_selfMakeData.nextJackpot
    if nextJackpo  then
        for k,v in pairs(nextJackpo) do
            local index = tonumber(k)
            if self:checkIsInTipNodeList( index ) then
                print("已经有相同位置的就不创建了,就检测是否应该变化状态就可以了")
                for kv,vv in pairs(self.respinJackPotTipNodeList) do
                    if vv and type(vv) ~= "number" and index == vv.index then

                        if vv.type ~= v then
                            self.respinJackPotTipNodeList[kv].type = v
                            local name = nil
                            if v == "Grand" then
                                name = "animation1"
                            elseif v == "Major" then
                                name = "animation2"
                            elseif v == "Minor" then
                                name = "animation3"
                            end

                            self.respinJackPotTipNodeList[kv]:runCsbAction(name,true)
                        end

                    end
                end
            else

                local pos =  self:getTarSpPos(index )
                local tipNode = util_createView("CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsHuXiActionView")

                local name = nil
                if v == "Grand" then
                    name = "animation1"
                elseif v == "Major" then
                    name = "animation2"
                elseif v == "Minor" then
                    name = "animation3"
                end

                tipNode:runCsbAction(name,true)

                self:findChild("Node_2"):addChild(tipNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE + 100)
                tipNode.index = index
                tipNode.jackPotType = v
                tipNode:setPosition(cc.p(pos))

                local listId = index + 1
                self.respinJackPotTipNodeList[listId] = tipNode
            end 
            
            
        end
    end
end

function FourInOneCharmsMiniMachine:removeOneRespinJackPotTipNode(index )
    for k,v in pairs(self.respinJackPotTipNodeList) do
        local indexId = index + 1
        if k == indexId  and type(v) ~= "number" then
            v:removeFromParent()
            self.respinJackPotTipNodeList[k] = 0
            break
        end
    end
end

function FourInOneCharmsMiniMachine:removeAllRespinJackPotTipNode( )
    for k,v in pairs(self.respinJackPotTipNodeList) do
        if v and type(v) ~= "number" then
            v:removeFromParent()
            v = nil
        end
    end

    self.respinJackPotTipNodeList = {}

    self:initRespinJackPotTipNodeList( )
end


function FourInOneCharmsMiniMachine:createOneActionSymbol(endNode,actionName)
    if not endNode or not endNode.m_ccbName  then
          return
    end
    
    local fatherNode = endNode
    endNode:setVisible(false)
    
    local node= util_createAnimation( endNode.m_ccbName..".csb")
    local func = function(  )
          if fatherNode then
                fatherNode:setVisible(true)
          end
          if node then
                node:removeFromParent()
          end
          
    end
    node:playAction(actionName,true,func)  

    local worldPos = fatherNode:getParent():convertToWorldSpace(cc.p(fatherNode:getPositionX(), fatherNode:getPositionY()))
    local pos = self:findChild("Node_2"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
    self:findChild("Node_2"):addChild(node , 100000 + endNode.p_rowIndex)
    node:setPosition(pos)

    local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
    local symbolIndex = self:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
    local score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
    local coinsNum = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
    local index = 0
    if score ~= nil and type(score) ~= "string" then
        local lineBet = globalData.slotRunData:getCurTotalBet() / 4
        score = score * lineBet
        score = util_formatCoins(score, 3)
        local scoreNode = node:findChild("m_lb_score")
        if scoreNode then
            scoreNode:setString(score)
        end

        local scoreNode1 = node:findChild("m_lb_score1")
        if scoreNode1 then
            scoreNode1:setString(score)
        end

        if scoreNode and scoreNode1 then
            scoreNode:setVisible(false)
            scoreNode1:setVisible(false)
            if coinsNum >= 8 then
                scoreNode1:setVisible(true)
            else
                scoreNode:setVisible(true)
            end
        end
    end
            

    return node
end

function FourInOneCharmsMiniMachine:onKeyBack()
    
    BaseMiniMachine.onKeyBack(self)
end

-- 创建飞行粒子
function FourInOneCharmsMiniMachine:createParticleFly(time,oldNode)

    local fly =  util_createView("CodeFourInOneSrc.LinkReels.CharmsSrc.CharmsBonusCollectView")
    
    -- fly:setScale(1.5)
    self.m_parent:addChild(fly,GD.GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 2)
    fly:findChild("Particle_1"):setDuration(time)
    fly:findChild("Particle_xiao"):setDuration(time)
    fly:findChild("Particle_jinkuai"):setDuration(time)
    
    
    fly:setPosition(cc.p(util_getConvertNodePos(oldNode,fly)))
    fly:setVisible(false)


    local changex  = 0
    fly:setVisible(true)

    

    local animation = {}

    local endPos = cc.p(util_getConvertNodePos(self.m_parent.m_bottomUI.m_normalWinLabel,fly))
    animation[#animation + 1] = cc.MoveTo:create(time, cc.p(endPos.x + 150,endPos.y) )
    animation[#animation + 1] = cc.CallFunc:create(function(  )

        fly:findChild("Particle_1"):stopSystem()
        fly:findChild("Particle_xiao"):stopSystem()
        fly:findChild("Particle_jinkuai"):stopSystem()

        performWithDelay(fly,function(  )
            fly:removeFromParent()
        end,1)
        

    end)

    fly:runAction(cc.Sequence:create(animation))

    
    
end


-- 更新Link类数据
function FourInOneCharmsMiniMachine:SpinResultParseResultData( result)
    self.m_runSpinResultData:parseResultData(result,self.m_lineDataPool)
end




--[[
    @desc: 检测是否切换到 处于 respin 状态中
    time:2019-01-04 17:58:12
    @return:
]]
function FourInOneCharmsMiniMachine:checkTriggerInReSpin( )

    local isPlayGameEff = false

    return isPlayGameEff
end


--[[
    @desc: 对比 winline 里面的所有线， 将相同的线 进行合并，
    这个主要用来处理， winLines 里面会存在两条一样的触发 fs的线，其中一条线winAmount为0，另一条
    有值， 这中情况主要使用与
    time:2018-08-16 19:30:23
    @return:  只保留一份 scatter 赢钱的线，如果存在允许scatter 赢钱的话
]]
function FourInOneCharmsMiniMachine:compareScatterWinLines(winLines)

    local scatterLines = {}
    local winAmountIndex = -1
    for i=1,#winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.p_iconPos
        local enumSymbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
        if iconsPos == nil then
            self.m_runSpinResultData.p_winLines[i].p_iconPos = {}
            iconsPos = {}
        end
        for posIndex=1,#iconsPos do
            local posData = iconsPos[posIndex]
            
            local rowColData = self:getRowAndColByPos(posData)
                
            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
                enumSymbolType = symbolType
                break  -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            scatterLines[#scatterLines + 1] = {i,winLineData.p_amount}
            if winLineData.p_amount > 0 then
                winAmountIndex = i
            end
        end
    end


    if #scatterLines > 0 and winAmountIndex > 0 then
        for i=#scatterLines,1,-1 do
            local lineData = scatterLines[i]
            if lineData[2] == 0 then
                table.remove(winLines,lineData[1])
            end
        end
    end


end


function FourInOneCharmsMiniMachine:initMachineBg()
    
    self.m_parent.m_CharmsGameBg:setVisible(true)

    self.m_gameBg = self.m_parent.m_CharmsGameBg
    
end


---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function FourInOneCharmsMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function FourInOneCharmsMiniMachine:clearCurMusicBg( )
    
end

---
-- 清空掉产生的数据
--
function FourInOneCharmsMiniMachine:clearSlotoData()
    
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

function FourInOneCharmsMiniMachine:onExit()

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
function FourInOneCharmsMiniMachine:clearSlotNodes()
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

function FourInOneCharmsMiniMachine:clearSlotChilds(childs)
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

return FourInOneCharmsMiniMachine
