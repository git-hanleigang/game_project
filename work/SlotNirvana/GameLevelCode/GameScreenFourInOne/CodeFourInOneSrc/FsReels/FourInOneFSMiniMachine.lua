---
-- xcyy
-- 2018-12-18 
-- FourInOneFSMiniMachine.lua
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

local FourInOneFSMiniMachine = class("FourInOneFSMiniMachine", BaseMiniMachine)


FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_A1 =	100
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_A2 = 101
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_A3 =	102
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_A4 =	103
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_A5 =	104
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_B1 =	105
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_B2 =	106
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_B3 =	107
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_B4 =	108
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_B5 =	109
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_SC =	190
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_WILD	= 192
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_BONUS =	194
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_ALL = 1105
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_GRAND = 1104
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_MAJOR = 1103
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_MINOR = 1102
FourInOneFSMiniMachine.SYMBOL_ChilliFiesta_MINI = 1101



FourInOneFSMiniMachine.SYMBOL_Charms_P1 =	200
FourInOneFSMiniMachine.SYMBOL_Charms_P2	= 201
FourInOneFSMiniMachine.SYMBOL_Charms_P3	= 202
FourInOneFSMiniMachine.SYMBOL_Charms_P4	= 203
FourInOneFSMiniMachine.SYMBOL_Charms_P5	= 204
FourInOneFSMiniMachine.SYMBOL_Charms_Ace =	205
FourInOneFSMiniMachine.SYMBOL_Charms_King =	206
FourInOneFSMiniMachine.SYMBOL_Charms_Queen = 207
FourInOneFSMiniMachine.SYMBOL_Charms_Jack =	208
FourInOneFSMiniMachine.SYMBOL_Charms_Scatter = 290
FourInOneFSMiniMachine.SYMBOL_Charms_Wild = 292
FourInOneFSMiniMachine.SYMBOL_Charms_bonus = 294

FourInOneFSMiniMachine.SYMBOL_Charms_MINOR = 2104
FourInOneFSMiniMachine.SYMBOL_Charms_MINI = 2103
FourInOneFSMiniMachine.SYMBOL_Charms_SYMBOL_DOUBLE = 2105
FourInOneFSMiniMachine.SYMBOL_Charms_SYMBOL_BOOM = 2109
FourInOneFSMiniMachine.SYMBOL_Charms_MINOR_DOUBLE = 2106
FourInOneFSMiniMachine.SYMBOL_Charms_SYMBOL_NULL = 2107
FourInOneFSMiniMachine.SYMBOL_Charms_SYMBOL_BOOM_RUN = 2108
FourInOneFSMiniMachine.SYMBOL_Charms_UNLOCK_SYMBOL = -2 -- 解锁状态的轮盘,这个是服务器给的解锁信号
FourInOneFSMiniMachine.SYMBOL_Charms_NULL_LOCK_SYMBOL = -1 -- 未解锁状态的轮盘,这个是服务器给的空轮盘的信号


FourInOneFSMiniMachine.SYMBOL_HowlingMoon_Wild = 392
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_H1 = 300
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_H2 = 301
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_H3 = 302
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_L1 = 303
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_L2 = 304
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_L3 = 305
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_L4 = 306
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_L5 = 307
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_L6 = 308
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_SC = 390
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_Bonus = 394
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_MINI = 3102       
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_MINOR = 3103
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_MAJOR = 3104
FourInOneFSMiniMachine.SYMBOL_HowlingMoon_GRAND = 3105

FourInOneFSMiniMachine.SYMBOL_Pomi_Scatter = 490
FourInOneFSMiniMachine.SYMBOL_Pomi_H1 =	400
FourInOneFSMiniMachine.SYMBOL_Pomi_H2 =	401
FourInOneFSMiniMachine.SYMBOL_Pomi_H3 =	402
FourInOneFSMiniMachine.SYMBOL_Pomi_H4 =	403
FourInOneFSMiniMachine.SYMBOL_Pomi_L1 =	404
FourInOneFSMiniMachine.SYMBOL_Pomi_L2 =	405
FourInOneFSMiniMachine.SYMBOL_Pomi_L3 =	406
FourInOneFSMiniMachine.SYMBOL_Pomi_L4 =	407
FourInOneFSMiniMachine.SYMBOL_Pomi_L5 =	408
FourInOneFSMiniMachine.SYMBOL_Pomi_Wild = 492
FourInOneFSMiniMachine.SYMBOL_Pomi_Bonus = 494
FourInOneFSMiniMachine.SYMBOL_Pomi_GRAND = 4104
FourInOneFSMiniMachine.SYMBOL_Pomi_MAJOR = 4103
FourInOneFSMiniMachine.SYMBOL_Pomi_MINOR = 4102
FourInOneFSMiniMachine.SYMBOL_Pomi_MINI = 4101
FourInOneFSMiniMachine.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
FourInOneFSMiniMachine.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

FourInOneFSMiniMachine.m_runCsvData = nil
FourInOneFSMiniMachine.m_machineIndex = nil 

FourInOneFSMiniMachine.gameResumeFunc = nil
FourInOneFSMiniMachine.gameRunPause = nil

FourInOneFSMiniMachine.m_maxReelIndex = nil

FourInOneFSMiniMachine.m_lockWildList = nil

FourInOneFSMiniMachine.m_oldlockWildList = nil

local BigMaxReelIndex = 1
local littleMaxReelIndex = 4

local HowlingMoon_Reels = "HowlingMoon"
local Pomi_Reels = "Pomi"
local ChilliFiesta_Reels = "ChilliFiesta"
local Charms_Reels = "Charms"


FourInOneFSMiniMachine.FS_LockWild_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 自定义动画的标识


-- 构造函数
function FourInOneFSMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    
end

function FourInOneFSMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil


    self.m_reelType =  data.reelType
    self.m_machineIndex = data.reelId
    self.m_parent = data.parent 

    if data.FSBig == true then
        self.m_maxReelIndex = BigMaxReelIndex
    else
        self.m_maxReelIndex = littleMaxReelIndex
    end

    self.m_lockWildList = {}
    self.m_oldlockWildList = {}
    
    --滚动节点缓存列表
    self.cacheNodeMap = {}

    --init
    self:initGame()
end

function FourInOneFSMiniMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("FourInOne_FSConfig.csv", 
                                "LevelFourInOne_FsConfig.lua")


    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FourInOneFSMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FourInOne"
end

function FourInOneFSMiniMachine:getMachineConfigName()

    local str = ""

    if self.m_reelType then
        str = self.m_reelType
    end

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FourInOneFSMiniMachine:MachineRule_GetSelfCCBName(symbolType)
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

--[[
    @desc: 读取轮盘配置信息
    time:2020-07-11 18:55:11
]]
function FourInOneFSMiniMachine:readReelConfigData()
    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol --标识哪一列会出现scatter 
    self.m_validLineSymNum = self.m_configData.p_validLineSymNum --触发sf，bonus需要的数量
    self:setReelEffect(self.m_configData.p_reelEffectRes)--配置快滚效果资源名称
    self.m_changeLineFrameTime = self.m_configData:getShowLinesTime() or 3  --连线框播放时间
end

---
-- 读取配置文件数据
--
function FourInOneFSMiniMachine:readCSVConfigData( )
    --读取csv配置
    if self.m_configData == nil then
        self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

function FourInOneFSMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName

    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("FSReels/freespin_reel.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end

--
---
--
function FourInOneFSMiniMachine:initMachine()
    self.m_moduleName = "FourInOne" -- self:getModuleName()

    BaseMiniMachine.initMachine(self)

end



function FourInOneFSMiniMachine:addLastWinSomeEffect() -- add big win or mega win
        -- BaseMiniMachine.addLastWinSomeEffect(self)
        self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FourInOneFSMiniMachine:getPreLoadSlotNodes()
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

function FourInOneFSMiniMachine:setWildList( )

    self.m_lockWildList = {}
    for iCol = 1, self.m_iReelColumnNum  do
        for iRow = self.m_iReelRowNum , 1, -1 do
            local targSp = self:getReelParentChildNode(iCol,iRow) 
            if targSp then
                if targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                    table.insert( self.m_lockWildList, targSp )
                end
            end
            
        end

        
    end
    
end



----------------------------- 玩法处理 -----------------------------------
function FourInOneFSMiniMachine:addSelfEffect()


    if self.m_parent:checkIsAddFsWildLock( )then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.FS_LockWild_EFFECT -- 动画类型
    end
end


function FourInOneFSMiniMachine:MachineRule_playSelfEffect(effectData)


    
    return true
end




function FourInOneFSMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function FourInOneFSMiniMachine:reelDownNotifyPlayGameEffect( )
    self:playGameEffect()

    if self.m_parent then
        self.m_parent:FSReelDownNotify( self.m_maxReelIndex  )
    end
end

function FourInOneFSMiniMachine:playReelDownSound(_iCol,_path )

    if self.m_machineIndex == 1 then

        if self:checkIsPlayReelDownSound( _iCol ) then
            gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_Reel_Stop.mp3")
        end
        self:setReelDownSoundId(_iCol,self.m_reelDownSoundPlayed ) 
    end


end
---
-- 每个reel条滚动到底
function FourInOneFSMiniMachine:slotOneReelDown(reelCol)
    BaseMiniMachine.slotOneReelDown(self,reelCol)

end

function FourInOneFSMiniMachine:getVecGetLineInfo( )
    return self.m_runSpinResultData.p_winLines
end

function FourInOneFSMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_parent then
        self.m_parent:FSReelShowSpinNotify( self.m_maxReelIndex )
    end
    

end


function FourInOneFSMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end


function FourInOneFSMiniMachine:beginMiniReel()
    BaseMiniMachine.beginReel(self)
end


-- 消息返回更新数据
function FourInOneFSMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function FourInOneFSMiniMachine:enterLevel( )
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传
    local isTriggerEffect = false
    local isPlayGameEffect = false
    if self.m_initSpinData ~= nil then 
        -- 检测上次的feature 信息
       
        if self.m_initFeatureData == nil  then
            -- 检测是否要触发 feature
            self:checkNetDataFeatures()
        end
        
        isPlayGameEffect = self:checkNetDataCloumnStatus()
        local isPlayFreeSpin =  self:checkTriggerINFreeSpin()

        isPlayGameEffect = isPlayGameEffect or isPlayFreeSpin --self:checkTriggerINFreeSpin()
        if isPlayGameEffect and self:checkHasGameEffectType(GameEffect.EFFECT_BONUS) == false then
            -- 这里只是用来检测是否 触发了 bonus ，如果触发了那么不调用数据生成
            isTriggerEffect = true
        end

        ----- 以下是检测初始化当前轮盘 ---- 
        local isTriggerCollect=false
        if self.m_initFeatureData ~= nil then
            isTriggerCollect=true
            -- 只处理纯粹feature 的类型， 如果有featureData 表明已经处于进行中了， 则直接弹出小游戏或者其他面板显示对应进度
            -- 如果上次退出时，处于feature中那么初始化各个关卡的feature 内容， 
            self:initFeatureInfo(self.m_initSpinData,self.m_initFeatureData)
        end

        self:MachineRule_initGame(self.m_initSpinData)
        
        --初始化收集数据
        if self.m_collectDataList ~= nil then
            self:initCollectInfo(self.m_initSpinData,self.m_initBetId,isTriggerCollect)
        end

        if self.m_jackpotList ~= nil then
            self:initJackpotInfo(self.m_jackpotList,self.m_initBetId)
        end
        
    end

    local hasFeature = self:checkHasFeature()

    if hasFeature == false then
      
        self:initRandomSlotNodes()
    else
      
        
        self:initCloumnSlotNodesByNetData()
    end
    
    if isPlayGameEffect or #self.m_gameEffects > 0 then
        self:sortGameEffects( )
        self:playGameEffect()
    end
end


function FourInOneFSMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end


-- 轮盘停止回调(自己实现)
function FourInOneFSMiniMachine:setDownCallFunc(func )
    self.m_reelDownCallback = func
end

function FourInOneFSMiniMachine:playEffectNotifyNextSpinCall( )
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end



-- 处理特殊关卡 遮罩层级
function FourInOneFSMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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


function FourInOneFSMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end


function FourInOneFSMiniMachine:checkGameResumeCallFun( )
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


function FourInOneFSMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FourInOneFSMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function FourInOneFSMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

-- *********** respin赋值相关

function FourInOneFSMiniMachine:isScoreFixSymbol(symbolType )
    
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

function FourInOneFSMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isScoreFixSymbol(symbolType) then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
        self:setSpecialNodeScore(self,{node})
    end
end

function FourInOneFSMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if  self:isScoreFixSymbol(symbolType) then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end

end

-- 给respin小块进行赋值
function FourInOneFSMiniMachine:setSpecialNodeScore(sender,param)
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
        local score = self:getReSpinSymbolScore(self:getPosReelIdx(iRow, iCol)) --获取分数（网络数据）
        local index = 0
        -- print(score .. "信号 "..symbolNode)
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            score = score * lineBet
            score = util_formatCoins(score, 3,nil,nil, true)
            if symbolNode.p_symbolType then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
            end
            
        end

        if symbolNode.p_symbolType then
            symbolNode:runAnim("idleframe")
        end

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet() /4
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3,nil,nil, true)
            
            if symbolNode.p_symbolType then
                if symbolNode:getCcbProperty("m_lb_score") then
                    symbolNode:getCcbProperty("m_lb_score"):setString(score)
                end
                symbolNode:runAnim("idleframe")
            end
        end
        
    end

end

-- 根据网络数据获得respinBonus小块的分数
function FourInOneFSMiniMachine:getReSpinSymbolScore(id)
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

    return score
end

function FourInOneFSMiniMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil
    
    if symbolType then
        if  self:isScoreFixSymbol(symbolType) then
            -- 根据配置表来获取滚动时 respinBonus小块的分数
            -- 配置在 Cvs_cofing 里面
            score = self.m_configData:getFixSymbolPro()
        end

    end

    return score
end



-- ***********  小块层级相关

function FourInOneFSMiniMachine:getScatterSymbolType(  )
    
    return self.SYMBOL_Pomi_Scatter

end


function FourInOneFSMiniMachine:isScatterSymbolType( symbolType )

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

function FourInOneFSMiniMachine:isBonusSymbolType( symbolType )

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

function FourInOneFSMiniMachine:isWildSymbolType( symbolType )

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
function FourInOneFSMiniMachine:getBounsScatterDataZorder(symbolType )
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

-- 更新 锁定wild
function FourInOneFSMiniMachine:updateFsLockWild(wildList)

    local isChange = false
    if wildList and #wildList > 0 then

        for i=1,#wildList do 

            local targSp =  wildList[i]
            if targSp then
                if targSp and targSp.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then

                    local targSpIcons = self:getPosReelIdx(targSp.p_rowIndex, targSp.p_cloumnIndex)

                    if not self:checkWildIsLocked( targSpIcons ) then
                        targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
                        targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                        targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                        targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                        local linePos = {}
                        linePos[#linePos + 1] = {iX = targSp.p_rowIndex, iY = targSp.p_cloumnIndex}
                        targSp.m_bInLine = true
                        targSp:setLinePos(linePos)
                        table.insert( self.m_oldlockWildList,targSp)
                    end

                    

                end
            end
            
        end
    end

        
end

-- 初始化 锁定wild
function FourInOneFSMiniMachine:initFsLockWild(wildPosList)

    if wildPosList and #wildPosList > 0 then

        for k, v in pairs(wildPosList) do
            local pos = tonumber(v)
            local fixPos = self:getRowAndColByPos(pos)
            local targSp =  self:getReelParentChildNode(fixPos.iY, fixPos.iX) 

            if targSp then
                targSp:changeCCBByName(self:getSymbolCCBNameByType(self, TAG_SYMBOL_TYPE.SYMBOL_WILD),TAG_SYMBOL_TYPE.SYMBOL_WILD)
                
                if targSp.p_symbolImage ~= nil and targSp.p_symbolImage:getParent() ~= nil then
                    targSp.p_symbolImage:removeFromParent()
                end
                targSp.p_symbolImage = nil

                targSp:setLocalZOrder(targSp:getLocalZOrder() + 10000  )
                targSp.m_symbolTag = SYMBOL_FIX_NODE_TAG
                targSp.m_showOrder = REEL_SYMBOL_ORDER.REEL_ORDER_3
                targSp.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_NODE
                local linePos = {}
                linePos[#linePos + 1] = {iX = fixPos.iX, iY = fixPos.iY}
                targSp.m_bInLine = true
                targSp:setLinePos(linePos)

                table.insert( self.m_oldlockWildList,targSp)
                
            end

            
        end
    end

end

function FourInOneFSMiniMachine:restSelfGameEffects( restType  )

    if self.m_gameEffects then
        for i = 1, #self.m_gameEffects , 1 do

            local effectData = self.m_gameEffects[i]
    
            if effectData.p_isPlay ~= true then
                local effectType = effectData.p_selfEffectType

                if effectType == restType then

                    effectData.p_isPlay = true
                    self:playGameEffect()
                    return 
                end
                
            end

        end
    end
    
end

function FourInOneFSMiniMachine:checkWildIsLocked( index )

    for i=1,#self.m_oldlockWildList do
        local wild = self.m_oldlockWildList[i]

        if wild then
            local iconsPos = self:getPosReelIdx(wild.p_rowIndex, wild.p_cloumnIndex)

            if index == iconsPos then
                return true
            end
            
        end

    end

    return false
    
end

-- function FourInOneFSMiniMachine:showLineFrame()
--     local winLines = self.m_reelResultLines

--     self:checkNotifyUpdateWinCoin()

--     self.m_lineSlotNodes = {}
--     self.m_eachLineSlotNode = {}
--     self:showInLineSlotNodeByWinLines(winLines, nil , nil)

--     self:clearFrames_Fun()


--     self:playInLineNodes()

--     local frameIndex = 1

--     local function showLienFrameByIndex()

--         self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
--             -- self:clearFrames_Fun()
--             if frameIndex > #winLines  then
--                 frameIndex = 1
--                 if self.m_showLineHandlerID ~= nil then

--                     scheduler.unscheduleGlobal(self.m_showLineHandlerID)
--                     self.m_showLineHandlerID = nil
--                     self:showAllFrame(winLines)
--                     self:playInLineNodes()
--                     showLienFrameByIndex()
--                 end
--                 return
--             end
--             self:playInLineNodesIdle()
--             -- 跳过scatter bonus 触发的连线
--             while true do
--                 if frameIndex > #winLines then
--                     break
--                 end
--                 -- print("showLine ... ")
--                 local lineData = winLines[frameIndex]

--                 if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or
--                    lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then

--                     if #winLines == 1 then
--                         break
--                     end

--                     frameIndex = frameIndex + 1
--                     if frameIndex > #winLines  then
--                         frameIndex = 1
--                     end
--                 else
--                     break
--                 end
--             end
--             -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
--             -- 所以打上一个判断
--             if frameIndex > #winLines  then
--                 frameIndex = 1
--             end

--             self:showLineFrameByIndex(winLines,frameIndex)

--             frameIndex = frameIndex + 1
--         end, self.m_changeLineFrameTime,self:getModuleName())

--     end

--     self:showAllFrame(winLines)
--     if #winLines > 1 then
--         showLienFrameByIndex()
--     end
-- end

---
-- 根据类型获取对应节点
--
function FourInOneFSMiniMachine:getSlotNodeBySymbolType(symbolType)
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
function FourInOneFSMiniMachine:getBaseReelGridNode()
    return "CodeFourInOneSrc.FourInOneSlotFastNode"
end

-- 更新Link类数据
function FourInOneFSMiniMachine:SpinResultParseResultData( result)
    self.m_runSpinResultData:parseResultData(result,self.m_lineDataPool)
end
--增加提示节点
-- function FourInOneFSMiniMachine:addReelDownTipNode(nodes)
--     local tipSlotNoes = {}
--     for i = 1, #nodes do
--         local slotNode = nodes[i]
--         local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

--         if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
--             --播放关卡中设置的小块效果
--              self:playCustomSpecialSymbolDownAct(slotNode)
--             if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
--                 local targSpIcons = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
--                 if not self:checkWildIsLocked( targSpIcons ) then
--                     slotNode:runAnim("buling")
--                     self.m_reelDownAddTime = 19/30
--                 end
--             end
--             if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
--                 if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
--                     tipSlotNoes[#tipSlotNoes + 1] = slotNode
--                 end
--             end
--         --                        end
--         end
--     end -- end for i=1,#nodes
--     return tipSlotNoes
-- end

--增加提示节点
function FourInOneFSMiniMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]
        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
                local targSpIcons = self:getPosReelIdx(slotNode.p_rowIndex, slotNode.p_cloumnIndex)
                if not self:checkWildIsLocked( targSpIcons ) then
                    slotNode:runAnim("buling")
                    self.m_reelDownAddTime = 19/30
                end
            end
            if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            end
        --                        end
        end
    end -- end for i=1,#nodes
    return tipSlotNoes
end

---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function FourInOneFSMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function FourInOneFSMiniMachine:clearCurMusicBg( )
    
end

---
-- 清空掉产生的数据
--
function FourInOneFSMiniMachine:clearSlotoData()
    
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

function FourInOneFSMiniMachine:onExit()

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
function FourInOneFSMiniMachine:clearSlotNodes()
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

function FourInOneFSMiniMachine:clearSlotChilds(childs)
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

function FourInOneFSMiniMachine:showLineFrame()
    local winLines = self.m_reelResultLines

    self.m_changeLineFrameTime = self.m_configData:getShowLinesTime() -- 各个关卡自己配置， low symbol 两个周期
    
    if self.m_changeLineFrameTime == nil then
        self.m_bGetSymbolTime = true
    else
        self.m_bGetSymbolTime = false
    end

    self:checkNotifyUpdateWinCoin()

    self.m_lineSlotNodes = {}
    self.m_eachLineSlotNode = {}
    self:showInLineSlotNodeByWinLines(winLines, nil , nil)

    self:clearFrames_Fun()


    self:playInLineNodes()

    local frameIndex = 1

    local function showLienFrameByIndex()

        self.m_showLineHandlerID = scheduler.scheduleGlobal(function()
            if frameIndex > #winLines  then
                frameIndex = 1
                if self.m_showLineHandlerID ~= nil then

                    scheduler.unscheduleGlobal(self.m_showLineHandlerID)
                    self.m_showLineHandlerID = nil
                    self:showAllFrame(winLines)
                    self:playInLineNodes()
                    showLienFrameByIndex()
                end
                return
            end
            self:playInLineNodesIdle()
            -- 跳过scatter bonus 触发的连线
            while true do
                if frameIndex > #winLines then
                    break
                end
                -- print("showLine ... ")
                local lineData = winLines[frameIndex]

                if lineData.enumSymbolEffectType == GameEffect.EFFECT_FREE_SPIN or
                   lineData.enumSymbolEffectType == GameEffect.EFFECT_BONUS then

                    if #winLines == 1 then
                        break
                    end

                    frameIndex = frameIndex + 1
                    if frameIndex > #winLines  then
                        frameIndex = 1
                    end
                else
                    break
                end
            end
            -- 打一个补丁， 因为同时触发 连线和 scatter时，会在播放scatter 时将scatter 连线移除掉
            -- 所以打上一个判断
            if frameIndex > #winLines  then
                frameIndex = 1
            end

            self:showLineFrameByIndex(winLines,frameIndex)

            frameIndex = frameIndex + 1
        end, self.m_changeLineFrameTime,self:getModuleName())

    end

    if self:getCurrSpinMode() == AUTO_SPIN_MODE or
        self:getCurrSpinMode() == FREE_SPIN_MODE then


        self:showAllFrame(winLines)  -- 播放全部线框

        -- if #winLines > 1 then
            showLienFrameByIndex()
        -- end

    else
        -- 播放一条线线框
        -- self:showLineFrameByIndex(winLines,1)
        -- frameIndex = 2
        -- if frameIndex > #winLines  then
        --     frameIndex = 1
        -- end

        
        if #winLines > 1 then
            self:showAllFrame(winLines)
            showLienFrameByIndex()
        else
            self:showLineFrameByIndex(winLines,1)
        end
        
    end
end


return FourInOneFSMiniMachine
