---
-- xcyy
-- 2018-12-18 
-- FourInOneBaseMiniMachine.lua
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


local FourInOneBaseMiniMachine = class("FourInOneBaseMiniMachine", BaseMiniMachine)


FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_A1 =	100
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_A2 = 101
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_A3 =	102
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_A4 =	103
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_A5 =	104
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_B1 =	105
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_B2 =	106
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_B3 =	107
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_B4 =	108
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_B5 =	109
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_SC =	190
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_WILD	= 192
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_BONUS =	194
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_ALL = 1105
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_GRAND = 1104
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_MAJOR = 1103
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_MINOR = 1102
FourInOneBaseMiniMachine.SYMBOL_ChilliFiesta_MINI = 1101



FourInOneBaseMiniMachine.SYMBOL_Charms_P1 =	200
FourInOneBaseMiniMachine.SYMBOL_Charms_P2	= 201
FourInOneBaseMiniMachine.SYMBOL_Charms_P3	= 202
FourInOneBaseMiniMachine.SYMBOL_Charms_P4	= 203
FourInOneBaseMiniMachine.SYMBOL_Charms_P5	= 204
FourInOneBaseMiniMachine.SYMBOL_Charms_Ace =	205
FourInOneBaseMiniMachine.SYMBOL_Charms_King =	206
FourInOneBaseMiniMachine.SYMBOL_Charms_Queen = 207
FourInOneBaseMiniMachine.SYMBOL_Charms_Jack =	208
FourInOneBaseMiniMachine.SYMBOL_Charms_Scatter = 290
FourInOneBaseMiniMachine.SYMBOL_Charms_Wild = 292
FourInOneBaseMiniMachine.SYMBOL_Charms_bonus = 294

FourInOneBaseMiniMachine.SYMBOL_Charms_MINOR = 2104
FourInOneBaseMiniMachine.SYMBOL_Charms_MINI = 2103
FourInOneBaseMiniMachine.SYMBOL_Charms_SYMBOL_DOUBLE = 2105
FourInOneBaseMiniMachine.SYMBOL_Charms_SYMBOL_BOOM = 2109
FourInOneBaseMiniMachine.SYMBOL_Charms_MINOR_DOUBLE = 2106
FourInOneBaseMiniMachine.SYMBOL_Charms_SYMBOL_NULL = 2107
FourInOneBaseMiniMachine.SYMBOL_Charms_SYMBOL_BOOM_RUN = 2108
FourInOneBaseMiniMachine.SYMBOL_Charms_UNLOCK_SYMBOL = -2 -- 解锁状态的轮盘,这个是服务器给的解锁信号
FourInOneBaseMiniMachine.SYMBOL_Charms_NULL_LOCK_SYMBOL = -1 -- 未解锁状态的轮盘,这个是服务器给的空轮盘的信号


FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_Wild = 392
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_H1 = 300
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_H2 = 301
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_H3 = 302
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_L1 = 303
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_L2 = 304
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_L3 = 305
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_L4 = 306
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_L5 = 307
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_L6 = 308
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_SC = 390
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_Bonus = 394
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_MINI = 3102       
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_MINOR = 3103
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_MAJOR = 3104
FourInOneBaseMiniMachine.SYMBOL_HowlingMoon_GRAND = 3105

FourInOneBaseMiniMachine.SYMBOL_Pomi_Scatter = 490
FourInOneBaseMiniMachine.SYMBOL_Pomi_H1 =	400
FourInOneBaseMiniMachine.SYMBOL_Pomi_H2 =	401
FourInOneBaseMiniMachine.SYMBOL_Pomi_H3 =	402
FourInOneBaseMiniMachine.SYMBOL_Pomi_H4 =	403
FourInOneBaseMiniMachine.SYMBOL_Pomi_L1 =	404
FourInOneBaseMiniMachine.SYMBOL_Pomi_L2 =	405
FourInOneBaseMiniMachine.SYMBOL_Pomi_L3 =	406
FourInOneBaseMiniMachine.SYMBOL_Pomi_L4 =	407
FourInOneBaseMiniMachine.SYMBOL_Pomi_L5 =	408
FourInOneBaseMiniMachine.SYMBOL_Pomi_Wild = 492
FourInOneBaseMiniMachine.SYMBOL_Pomi_Bonus = 494
FourInOneBaseMiniMachine.SYMBOL_Pomi_GRAND = 4104
FourInOneBaseMiniMachine.SYMBOL_Pomi_MAJOR = 4103
FourInOneBaseMiniMachine.SYMBOL_Pomi_MINOR = 4102
FourInOneBaseMiniMachine.SYMBOL_Pomi_MINI = 4101
FourInOneBaseMiniMachine.SYMBOL_Pomi_Reel_Up = 4105 -- 服务器没定义
FourInOneBaseMiniMachine.SYMBOL_Pomi_Double_bet = 4106 -- 服务器没定义

FourInOneBaseMiniMachine.m_runCsvData = nil
FourInOneBaseMiniMachine.m_machineIndex = nil 

FourInOneBaseMiniMachine.gameResumeFunc = nil
FourInOneBaseMiniMachine.gameRunPause = nil
FourInOneBaseMiniMachine.m_isAllReelDown = nil

FourInOneBaseMiniMachine.m_isRuning = nil

local HowlingMoon_Reels = "HowlingMoon"
local Pomi_Reels = "Pomi"
local ChilliFiesta_Reels = "ChilliFiesta"
local Charms_Reels = "Charms"



-- 构造函数
function FourInOneBaseMiniMachine:ctor()
    BaseMiniMachine.ctor(self)

    
end

function FourInOneBaseMiniMachine:initData_( data )

    self.gameResumeFunc = nil
    self.gameRunPause = nil


    self.m_reelType =  data.reelType
    self.m_machineIndex = data.reelId
    self.m_parent = data.parent 

    self.m_change = data.change
    self.m_isRuning = false


    --滚动节点缓存列表
    self.cacheNodeMap = {}
    self.m_quickStopBackDistance = 20
    --init
    self:initGame()
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData: 
    @return:
]]
function FourInOneBaseMiniMachine:setScatterDownScound( )
    for i = 1, 5 do
        local soundPath = nil
        if i <= 2 then
            soundPath = "FourInOneSounds/FourInOne_scatter_down1.mp3"
        elseif i > 2 and i < 5 then
            soundPath = "FourInOneSounds/FourInOne_scatter_down2.mp3"
        else
            soundPath = "FourInOneSounds/FourInOne_scatter_down3.mp3"
        end
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = soundPath
    end
end

function FourInOneBaseMiniMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("FourInOne_Base_".. self.m_reelType .."Config.csv",
                                             "LevelFourInOne_Base_".. self.m_reelType .."_Config.lua")

    --初始化基本数据
    self:initMachine(self.m_moduleName)

end



-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function FourInOneBaseMiniMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "FourInOne"
end

function FourInOneBaseMiniMachine:getMachineConfigName()

    local str = ""

    if self.m_reelType then
        str = "_Base_".. self.m_reelType
    end

    return self.m_moduleName.. str .. "Config"..".csv"
end



---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function FourInOneBaseMiniMachine:MachineRule_GetSelfCCBName(symbolType)
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
function FourInOneBaseMiniMachine:readCSVConfigData( )
    --读取csv配置
    -- if self.m_configData == nil then
    --     self.m_configData = gLobalResManager:getCSVLevelConfigData(self:getMachineConfigName())
    -- end
    -- globalData.slotRunData.levelConfigData = self.m_configData
end

--[[
    @desc: 读取轮盘配置信息
    time:2020-07-11 18:55:11
]]
function FourInOneBaseMiniMachine:readReelConfigData()
    self.m_ScatterShowCol = self.m_configData.p_scatterShowCol --标识哪一列会出现scatter 
    self.m_validLineSymNum = self.m_configData.p_validLineSymNum --触发sf，bonus需要的数量
    self:setReelEffect(self.m_configData.p_reelEffectRes)--配置快滚效果资源名称
    self.m_changeLineFrameTime = self.m_configData:getShowLinesTime() or 3  --连线框播放时间
end


function FourInOneBaseMiniMachine:initMachineCSB( )
    self.m_winFrameCCB = "WinFrame" .. self.m_moduleName
    if self.m_reelType == HowlingMoon_Reels then
        self.m_winFrameCCB = "WinFrameFourInOne_4x5"
    end
    
    -- gLobalBuglyControl:log(resourceFilename)
    self:createCsbNode("BaseReels/" .. self.m_reelType .. "_reel.csb")
    self.m_csbNode:setLocalZOrder(GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER)
    self.m_machineNode = self.m_csbNode
    self.m_root = self:findChild("root")
end
--
---
--
function FourInOneBaseMiniMachine:initMachine()
    self.m_moduleName = "FourInOne" -- self:getModuleName()
    
    BaseMiniMachine.initMachine(self)

    self:initSelfUI()

end

function FourInOneBaseMiniMachine:initSelfUI( )

    self.m_RunDi = {}
    for i=1,5 do

        local longRunDi =  util_createAnimation("WinFrameFourInOne_Big_di.csb") 
        self:findChild("root"):addChild(longRunDi,1) 
        longRunDi:setPosition(cc.p(self:findChild("sp_reel_"..(i - 1)):getPosition()))
        table.insert( self.m_RunDi, longRunDi )
        longRunDi:setVisible(false)
    end

    self.m_triggerEffect = util_createAnimation("BaseReels/reel_light.csb") 
    self:findChild("root"):addChild(self.m_triggerEffect,1)
    self.m_triggerEffect:setVisible(false)


end

-- 快滚相关
function FourInOneBaseMiniMachine:setReelLongRun(reelCol)
    local isTriggerLongRun = false

    --长滚效果
    local reelRunData = self.m_reelRunInfo[reelCol]

    local nodeData = reelRunData:getSlotsNodeInfo()

    -- 处理长滚动
    if reelRunData:getNextReelLongRun() == true and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        isTriggerLongRun = true -- 触发了长滚动
        -- if  self:getGameSpinStage() == QUICK_RUN  then
        --     gLobalSoundManager:playSound(self.m_reelDownSound)
        -- end
        for i = reelCol + 1, self.m_iReelColumnNum do
            --添加金边
            if i == reelCol + 1 then
                if self.m_reelRunInfo[i]:getReelLongRun() then
                    self:creatReelRunAnimation(i)
                    self:creatReelRunAnimationBg(i - 1)
                end
            end
            --后面列停止加速移动
            local parentData = self.m_slotParents[i]
            local slotParent = parentData.slotParent

            parentData.moveSpeed = self.m_configData.p_reelLongRunSpeed
        end
    end
    return isTriggerLongRun
end
---
--添加金边
function FourInOneBaseMiniMachine:creatReelRunAnimation(col)
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

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)
    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end
--添加快滚背景
function FourInOneBaseMiniMachine:creatReelRunAnimationBg(col)
    local rundi = self.m_RunDi[col]
    if rundi then
        rundi:setVisible(true)
        rundi:playAction("open",false,function ()
            rundi:playAction("actionframe",true)
        end)
    end
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function FourInOneBaseMiniMachine:getPreLoadSlotNodes()
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

function FourInOneBaseMiniMachine:addSelfEffect()

end


function FourInOneBaseMiniMachine:MachineRule_playSelfEffect(effectData)
    
    return true
end




function FourInOneBaseMiniMachine:onEnter()
    BaseMiniMachine.onEnter(self) -- 必须调用不予许删除
    self:addObservers()
end

function FourInOneBaseMiniMachine:reelDownNotifyBaseReelsPlayGameEffect( )
    self:playGameEffect()
end

-- 重写此函数 一点要调用 BaseMachine.reelDownNotifyPlayGameEffect(self) 而不是 self:playGameEffect()
function FourInOneBaseMiniMachine:reelDownNotifyPlayGameEffect( )
    -- self:playGameEffect()
end

function FourInOneBaseMiniMachine:slotReelDown()
    BaseMiniMachine.slotReelDown(self) 
    self.m_isAllReelDown = true
    if self.m_parent then
        self.m_parent:baseReelDownNotify( 4 )
    end
        
end


---
-- 每个reel条滚动到底
function FourInOneBaseMiniMachine:slotOneReelDown(reelCol)
    local haveScatter = false
    if reelCol == 1 then
        self.m_iScatterNum = 0
    end
    for iRow = 1, self.m_iReelRowNum do
        local symbolType = self.m_stcValidSymbolMatrix[iRow][reelCol]
        if symbolType == self:getScatterSymbolType() then
            haveScatter = true
            self.m_iScatterNum = self.m_iScatterNum + 1
        end
    end

    if haveScatter == false and self:getInScatterShowCol(reelCol) then
        self:hideRunDi()
        for col = reelCol + 1,self.m_iReelColumnNum do
            self.m_reelRunInfo[col]:setReelLongRun(false)
        end
    end

    --快滚重写
    local parentData = self.m_slotParents[reelCol]
    local slotParent = parentData.slotParent
    local isTriggerLongRun = false
    ---下列是否长滚
    if self:getNextReelIsLongRun(reelCol + 1) and (self:getGameSpinStage() ~= QUICK_RUN or self.m_hasBigSymbol == true) then
        self:creatReelRunAnimationBg(reelCol)
    end


    if self.m_reelDownSoundPlayed then
        self:playReelDownSound(reelCol,self.m_reelDownSound )
    else
        gLobalSoundManager:playSound(self.m_reelDownSound) 
    end


    ---本列是否开始长滚
    isTriggerLongRun = self:setReelLongRun(reelCol)

    if haveScatter and (self.m_iScatterNum == 1 and reelCol == 2) and self:getGameSpinStage() ~= QUICK_RUN then
        self:creatReelRunAnimationBg(reelCol)
    end
    if haveScatter and self.m_iScatterNum == 3 and reelCol == 4 and self:getGameSpinStage() ~= QUICK_RUN then
        local rundi = self.m_RunDi[reelCol]
        if rundi then
            rundi:setVisible(true)
            rundi:playAction("open",false,function ()
                rundi:playAction("actionframe",true)
            end)
        end
    end
    --最后列滚完之后隐藏长滚
    if self.m_reelRunAnima ~= nil then
        if reelCol > 1 then
            local reelEffectNode = self.m_reelRunAnima[reelCol - 1]
            if reelEffectNode ~= nil and reelEffectNode[1]:isVisible() then
                reelEffectNode[1]:runAction(cc.Hide:create())
            end
        end
    end
    
    if self:getGameSpinStage() == QUICK_RUN then
        --快停的话就不用出来了
        self:hideRunDi()
    end
    -- 出发了长滚动则不允许点击快停按钮
    if isTriggerLongRun == true then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, false})
    end
end

--去掉快滚背景
function FourInOneBaseMiniMachine:hideRunDi()
    for col,rundi in ipairs(self.m_RunDi) do
        if rundi:isVisible() then
            rundi:playAction("end",false,function(  )
                rundi:setVisible(false)
            end)
        end
    end
end

function FourInOneBaseMiniMachine:getVecGetLineInfo( )
    return self.m_runSpinResultData.p_winLines
end


function FourInOneBaseMiniMachine:playEffectNotifyChangeSpinStatus( )

    if self.m_parent then
        self.m_parent:baseReelShowSpinNotify( 4 )
    end
    

end


function FourInOneBaseMiniMachine:quicklyStopReel(colIndex)

    if self.m_isRuning and self.m_isAllReelDown ~= true then
        BaseMiniMachine.quicklyStopReel(self, colIndex)
    end

    
end


function FourInOneBaseMiniMachine:requestSpinReusltData()
        self.m_isWaitingNetworkData = true
        self:setGameSpinStage( WAITING_DATA )
end



function FourInOneBaseMiniMachine:beginMiniReel()
    self.m_isAllReelDown = false
    BaseMiniMachine.beginReel(self)
end


-- 消息返回更新数据
function FourInOneBaseMiniMachine:netWorkCallFun(spinResult)

    self.m_runSpinResultData:parseResultData(spinResult,self.m_lineDataPool)

    self:updateNetWorkData()
end

function FourInOneBaseMiniMachine:enterLevel( )
    
end

function FourInOneBaseMiniMachine:enterSelfLevel( )
    -- 由于进入关卡有进入场景动画， 所以等待动画播放完毕后再处理 断点续传

    local hasFeature = false
    local isPlayGameEffect = false

    
    local features =  self.m_parent.m_runSpinResultData.p_features 
    local freeSpinsLeftCount = self.m_parent.m_runSpinResultData.p_freeSpinsLeftCount 
    local freeSpinsTotalCount = self.m_parent.m_runSpinResultData.p_freeSpinsTotalCount 

    self.m_initSpinData = self.m_runSpinResultData

    if features  and #features >= 2  then
        hasFeature = true

    elseif   self.m_parent.m_respinTriggerData and  self.m_parent.m_respinTriggerData.respin and  self.m_parent.m_respinTriggerData.respin.reSpinsTotalCount ~= nil 
            and  self.m_parent.m_respinTriggerData.respin.reSpinsTotalCount > 0 and  self.m_parent.m_respinTriggerData.respin.reSpinCurCount > 0 then
                -- respin过程中断线
                hasFeature = true   
    elseif freeSpinsLeftCount and freeSpinsTotalCount and freeSpinsTotalCount > 0 and freeSpinsLeftCount > 0 then    
        hasFeature = true    
    end

    if self.m_change then
        self.m_change = nil
        hasFeature = false
    end

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


function FourInOneBaseMiniMachine:operaNetWorkData()
    -- 与底层区别只是注释了这里，为了不影响主轮子，设置按钮状态
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,
    --                                     {SpinBtn_Type.BtnType_Stop,true})
    self:setGameSpinStage( GAME_MODE_ONE_RUN )
    self:perpareStopReel()
end


-- 轮盘停止回调(自己实现)
function FourInOneBaseMiniMachine:setDownCallFunc(func )
    self.m_reelDownCallback = func
end

function FourInOneBaseMiniMachine:playEffectNotifyNextSpinCall( )
    if self.m_reelDownCallback ~= nil then
        self.m_reelDownCallback(self.m_machineIndex)
    end
end



-- 处理特殊关卡 遮罩层级
function FourInOneBaseMiniMachine:changeSlotsParentZOrder(zOrder,parentData,slotParent)
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


function FourInOneBaseMiniMachine:getResultLines( )
   return self.m_runSpinResultData.p_winLines -- self.m_reelResultLines
end



function FourInOneBaseMiniMachine:checkGameResumeCallFun( )
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

function FourInOneBaseMiniMachine:checkGameRunPause()
    if self.gameRunPause == true then
        return true
    else
        return false
    end
end

function FourInOneBaseMiniMachine:pauseMachine()
    -- if self:getGameSpinStage() == GAME_MODE_ONE_RUN then
        self.gameRunPause = true
    -- end
end

function FourInOneBaseMiniMachine:resumeMachine()
    self.gameRunPause = nil
    -- 小轮盘关卡内的暂停函数单独处理
    if self.gameResumeFunc then
        self.gameResumeFunc()
    end
    self.gameResumeFunc = nil
end

-- *********** respin赋值相关

function FourInOneBaseMiniMachine:isScoreFixSymbol(symbolType )
    
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

function FourInOneBaseMiniMachine:updateAllScoreFixSymbol( )

    
    for iCol = 1, self.m_iReelColumnNum do

        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType then
                local symbolType = targSp.p_symbolType
                if self:isScoreFixSymbol(symbolType) then
                    -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
                    -- self:runAction(callFun)
                    self:setSpecialNodeScore(self,{targSp})
                end
            end

        end

    end

    
end


function FourInOneBaseMiniMachine:updateReelGridNode(node)
    local symbolType = node.p_symbolType
    if self:isScoreFixSymbol(symbolType) then
        -- local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        -- self:runAction(callFun)
        self:setSpecialNodeScore(self,{node})
    end
end

function FourInOneBaseMiniMachine:setSlotCacheNodeWithPosAndType(node, symbolType, row, col, isLastSymbol)
    BaseMiniMachine.setSlotCacheNodeWithPosAndType(self,node, symbolType, row, col, isLastSymbol)
    
    if  self:isScoreFixSymbol(symbolType) then
            
        --下帧调用 才可能取到 x y值
        -- 给respinBonus小块进行赋值
        local callFun = cc.CallFunc:create(handler(self,self.setSpecialNodeScore),{node})
        self:runAction(callFun)
    end

end

-- 给respin小块进行赋值
function FourInOneBaseMiniMachine:setSpecialNodeScore(sender,param)
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
            local lab = symbolNode:getCcbProperty("m_lb_score")
            if lab and lab.setString and lab.setVisible then
                lab:setString(score)
                lab:setVisible(true)
            end
            local scoreNode1 = symbolNode:getCcbProperty("m_lb_score1")
            if scoreNode1 and scoreNode1.setString then
                scoreNode1:setString("")
            end
        end

        if symbolNode.p_symbolType then
            symbolNode:runAnim("idleframe")
        end
        

    else
        local score =  self:randomDownRespinSymbolScore(symbolNode.p_symbolType) -- 获取随机分数（本地配置）
        if score ~= nil  then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            if score == nil then
                score = 1
            end
            score = score * lineBet
            score = util_formatCoins(score, 3,nil,nil, true)
            local lab = symbolNode:getCcbProperty("m_lb_score")
            if lab and lab.setString and lab.setVisible then
                lab:setString(score)
                lab:setVisible(true)
            end
            local scoreNode1 = symbolNode:getCcbProperty("m_lb_score1")
            if scoreNode1 and scoreNode1.setString then
                scoreNode1:setString("")
            end
            
            if symbolNode.p_symbolType then
                symbolNode:runAnim("idleframe")
            end
        end
        
    end

end

-- 根据网络数据获得respinBonus小块的分数
function FourInOneBaseMiniMachine:getReSpinSymbolScore(id)
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

function FourInOneBaseMiniMachine:randomDownRespinSymbolScore(symbolType)
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

function FourInOneBaseMiniMachine:getScatterSymbolType(  )
    

    if self.m_reelType == HowlingMoon_Reels then
        return self.SYMBOL_HowlingMoon_SC
    elseif self.m_reelType == Pomi_Reels then
        return self.SYMBOL_Pomi_Scatter
    elseif self.m_reelType == ChilliFiesta_Reels then
        return self.SYMBOL_ChilliFiesta_SC
    elseif self.m_reelType == Charms_Reels then
        return self.SYMBOL_Charms_Scatter
    end


end

function FourInOneBaseMiniMachine:getWildSymbolType(  )
    
    if self.m_reelType == HowlingMoon_Reels then
        return self.SYMBOL_HowlingMoon_Wild
    elseif self.m_reelType == Pomi_Reels then
        return self.SYMBOL_Pomi_Wild
    elseif self.m_reelType == ChilliFiesta_Reels then
        return self.SYMBOL_ChilliFiesta_WILD
    elseif self.m_reelType == Charms_Reels then
        return self.SYMBOL_Charms_Wild
    end


end

function FourInOneBaseMiniMachine:isScatterSymbolType( symbolType )

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

function FourInOneBaseMiniMachine:isBonusSymbolType( symbolType )

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

function FourInOneBaseMiniMachine:isWildSymbolType( symbolType )

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
function FourInOneBaseMiniMachine:getBounsScatterDataZorder(symbolType )
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

-- ***** 快滚的修改
---
--@param groupNums table 滚动时生成假数据的列信息，
--@param bInclScatter bool 是否计算scatter
--@param bInclBonus bool 是否计算Bonus
--@param bPlayScatterAction bool 是否播放Bonus动画
--@param bPlayBonusAction bool 是否播放Bonus动画
function FourInOneBaseMiniMachine:slotsReelRunData(groupNums, bInclScatter, bInclBonus, bPlayScatterAction, bPlayBonusAction,autospinGroupNums,freespinGroupNums)
    if groupNums == nil or #groupNums ~= self.m_iReelColumnNum then
        return
    end


    if globalData.GameConfig.checkNormalReel and globalData.GameConfig:checkNormalReel() == true then
        autospinGroupNums = groupNums
        freespinGroupNums = groupNums
    else
        if autospinGroupNums == nil then
            autospinGroupNums = self.m_configData.p_autospinReelRunDatas
            if autospinGroupNums == nil then
                autospinGroupNums = groupNums
            end
        end
        if freespinGroupNums == nil then
            freespinGroupNums = self.m_configData.p_freespinReelRunDatas
            if freespinGroupNums == nil then
                freespinGroupNums = groupNums
            end
        end
    end
    
    local groupCount = #groupNums
    
    self.m_reelRunInfo = {}

    --初始化长滚数据 每列初始化一个reelRunData数据
    for col = 1, self.m_iReelColumnNum, 1 do
        local reelRunData = FourInOneSlotsReelRunData.new()
        local runLen = groupNums[col]

        reelRunData:setMachine( self )

        reelRunData:initReelRunInfo(groupNums[col], bInclScatter, bInclBonus, bPlayScatterAction, bPlayBonusAction,autospinGroupNums[col],freespinGroupNums[col])
        self.m_reelRunInfo[#self.m_reelRunInfo + 1] = reelRunData

        self.m_longRunAddZorder[#self.m_longRunAddZorder + 1] = 0
    end

    -- 计算哪个列滚动的时间最长
    -- local preReelMax = 0
    local moveSpeed = self.m_configData.p_reelMoveSpeed
    local preReelTime = 0
    for i = 1, groupCount do

        local columnData = self.m_reelColDatas[i]

        local reelTime = columnData.p_showGridH * groupNums[i] / moveSpeed -- 滚动时间
        if i ~= 1 then
            reelTime = reelTime + i * self.m_reelDelayTime
        end

        if reelTime > preReelTime then
            self.m_maxHeightColumnIndex = i
        end
    end
    self.m_runHeightColumnIndex = self.m_maxHeightColumnIndex
    -- printInfo("xcyy : %s","")
end

function FourInOneBaseMiniMachine:checkIsInLongRun(col, symbolType)
    local scatterShowCol = self.m_ScatterShowCol

    if symbolType == self:getScatterSymbolType(  ) then
        if scatterShowCol ~= nil then
            if self:getInScatterShowCol(col) then
                return true
            else 
                return false
            end
        end
    end

    return true
end

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

--设置bonus scatter 信息
function FourInOneBaseMiniMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == self:getScatterSymbolType(  ) then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
            local bPlaySymbolAnima = bPlayAni
        
            allSpecicalSymbolNum = allSpecicalSymbolNum + 1
            
            if bRun == true then
                
                soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

                local soungName = nil
                if soundType == runStatus.DUANG then
                    if allSpecicalSymbolNum == 1 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                    elseif allSpecicalSymbolNum == 2 then
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                    else
                        soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                    end
                else
                    --不应当播放动画 (么戏了)
                    bPlaySymbolAnima = false
                end

                reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

            else
                -- bonus scatter不参与滚动设置
                local soundName = nil
                if bPlaySymbolAnima == true then
                    --自定义音效
                    
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                else 
                    reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
                end
            end
        end
        
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

--设置长滚信息
function FourInOneBaseMiniMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    local addLens = false
    for col=1,iColumn do
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
                if col == 3 then
                    self.m_reelRunInfo[col]:setReelLongRun(false)
                    self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 10)
                    self:setLastReelSymbolList()
                elseif col == 4 then
                    self.m_reelRunInfo[col]:setReelLongRun(false)
                    self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 8)
                    self:setLastReelSymbolList()
                elseif col == 5 then
                    self.m_reelRunInfo[col]:setReelLongRun(false)
                    self.m_reelRunInfo[col]:setReelRunLen(self.m_reelRunInfo[col - 1]:getReelRunLen() + 6)
                    self:setLastReelSymbolList()
                end
            end
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(self:getScatterSymbolType() , col , scatterNum, bRunLong)  
    
        if col == 2 and scatterNum == 1 then
            addLens = true
        end
        if bRunLong == true and col == 3 and scatterNum < 2 then
            self.m_reelRunInfo[col]:setNextReelLongRun(false)
            bRunLong = false
            addLens = true
        end
    end
end

--增加提示节点
function FourInOneBaseMiniMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then
            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            if self:isBonusSymbolType( slotNode.p_symbolType ) then
                slotNode:runAnim("buling",false,function(  )
                    -- slotNode:runAnim("idleframe",true)
                end)
                self.m_reelDownAddTime = 15/30
            end
            if slotNode.p_symbolType == self:getScatterSymbolType(  ) or slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
                if self:isPlayTipAnima(slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode) == true then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            end
        --                        end
        end
    end -- end for i=1,#nodes
    return tipSlotNoes
end

-- 特殊信号下落时播放的音效
function FourInOneBaseMiniMachine:playScatterBonusSound(slotNode)
    if slotNode ~= nil then
        local iCol = slotNode.p_cloumnIndex
        local soundPath = nil
        local soundType = nil
        if slotNode.p_symbolType == self:getScatterSymbolType(  ) then
            soundType = "ScatterSymbolType"
            if self.m_scatterBulingSoundArry == nil or not tolua.isnull(self.m_scatterBulingSoundArry) then
                return
            end
            self.m_nScatterNumInOneSpin = self.m_nScatterNumInOneSpin + 1
            if self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin] ~= nil then
                soundPath =self.m_scatterBulingSoundArry[self.m_nScatterNumInOneSpin]
            elseif self.m_scatterBulingSoundArry["auto"] ~= nil then
                soundPath =self.m_scatterBulingSoundArry["auto"]
            end
        elseif slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            soundType = slotNode.p_symbolType
            if self.m_bonusBulingSoundArry == nil or not tolua.isnull(self.m_bonusBulingSoundArry) then
                return
            end
            self.m_nBonusNumInOneSpin = self.m_nBonusNumInOneSpin + 1
            if self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin] ~= nil then
                soundPath =self.m_bonusBulingSoundArry[self.m_nBonusNumInOneSpin]
            elseif self.m_bonusBulingSoundArry["auto"] ~= nil then
                soundPath =self.m_bonusBulingSoundArry["auto"]
            end
        end
        if soundPath then
            if self.playBulingSymbolSounds then
                self:playBulingSymbolSounds( iCol,soundPath,soundType )
            else
                gLobalSoundManager:playSound(soundPath)
            end
        end
    end
end

---
-- 检测传递进来的格子是否 在连线上
-- @param symbols 信号列表 {1,1} 放置的是数组 存储row  col的位置
-- @return table 返回在线上的信号列表，如果为空表明都不在，
function FourInOneBaseMiniMachine:checkSymbolInLines(symbols)

    local iColumn = self.m_iReelColumnNum
    local lineSizeSize = self.m_lineTypeSize
    local inLineSymbols = {} -- 在连线上的symbol
    for i = 1,  lineSizeSize , 1 do --遍历所有线类型
        local stcLineTypeTmp = self.m_vecLineType[i]

        -- 寻找相同小块标记
        local preSymbolType = nil
        for lineColIndex=1,iColumn do
            local lineRowIndex = stcLineTypeTmp.iLineMapInfo[lineColIndex] + 1
            local symbolType = self.m_stcValidSymbolMatrix[lineRowIndex][lineColIndex]
            if symbolType ~= self:getWildSymbolType(  ) then
                preSymbolType = symbolType
                break
            end
        end

        -- scatter不算
        if preSymbolType == self:getScatterSymbolType(  ) then
            break
        end

        -- 5个wild
        if not preSymbolType then
            preSymbolType = self:getWildSymbolType(  )
        end

        -- 相同数量
        local sameCount = 1
        for lineColIndex=2,iColumn do
            local lineRowIndex = stcLineTypeTmp.iLineMapInfo[lineColIndex] + 1
            local symbolType = self.m_stcValidSymbolMatrix[lineRowIndex][lineColIndex]
            if preSymbolType == symbolType or
                symbolType == self:getWildSymbolType(  ) then
                sameCount = sameCount + 1
            else
                break
            end
        end

        if sameCount >= 3 then  -- 这里的3以后会进行扩展
            for sameColIndex=1,sameCount do
                local sameRowIndex = stcLineTypeTmp.iLineMapInfo[sameColIndex] + 1

                for symbolIndex=#symbols,1,-1 do
                    local rowIndex = symbols[symbolIndex][1]
                    local colIndex = symbols[symbolIndex][2]
                    if rowIndex == sameRowIndex and sameColIndex == colIndex then

                        inLineSymbols[#inLineSymbols + 1] = symbols[symbolIndex]
                        table.remove(symbols,symbolIndex)

                        if #symbols == 0 then
                            return inLineSymbols
                        end
                    end
                end

            end

        end

    end

    return inLineSymbols
end

--[[
    @desc: 对比 winline 里面的所有线， 将相同的线 进行合并，
    这个主要用来处理， winLines 里面会存在两条一样的触发 fs的线，其中一条线winAmount为0，另一条
    有值， 这中情况主要使用与
    time:2018-08-16 19:30:23
    @return:  只保留一份 scatter 赢钱的线，如果存在允许scatter 赢钱的话
]]
function FourInOneBaseMiniMachine:compareScatterWinLines(winLines)

    local scatterLines = {}
    local winAmountIndex = -1
    for i=1,#winLines do
        local winLineData = winLines[i]
        local iconsPos = winLineData.p_iconPos
        local enumSymbolType = self:getWildSymbolType(  )
        for posIndex=1,#iconsPos do
            local posData = iconsPos[posIndex]
            
            local rowColData = self:getRowAndColByPos(posData)
                
            local symbolType = self.m_stcValidSymbolMatrix[rowColData.iX][rowColData.iY]
            if symbolType ~= self:getWildSymbolType(  ) then
                enumSymbolType = symbolType
                break  -- 一旦找到不是wild 的元素就表明了代表这条线的元素类型， 否则就全部是wild
            end
        end

        if enumSymbolType == self:getScatterSymbolType(  ) then
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

function FourInOneBaseMiniMachine:clearLittleReelsLinesEffect( )
    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
end


-- ****************  bonus 处理
---
-- 显示bonus 触发的小游戏
function FourInOneBaseMiniMachine:showBaseMiniEffect_Bonus( func )


    self.m_triggerEffect:setVisible(true)
    self.m_triggerEffect:playAction("idleframe",true)

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()
    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()

    -- 停止播放背景音乐
    self:clearCurMusicBg()

    
    gLobalSoundManager:playSound("FourInOneSounds/FourInOne_Fs_Trigger.mp3")


    local lineLen = #self.m_reelResultLines
    local bonusLineValue = nil
    for i=1,lineLen do
        local lineValue = self.m_reelResultLines[i]
        if lineValue.enumSymbolEffectType == GameEffect.EFFECT_BONUS then
            bonusLineValue = lineValue
            table.remove(self.m_reelResultLines,i)
            break
        end
    end

    if bonusLineValue ~= nil  then

        bonusLineValue:clean()
        self.m_reelLineInfoPool[#self.m_reelLineInfoPool + 1] = bonusLineValue
    end

    
    self:showBonusTriggerTip(function()

        if func then
            func()
        end
    end )

    -- 播放提示时播放音效
    self:playBonusTipMusicEffect()
   

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus,self.m_iOnceSpinLastWin)

    return true
end

function FourInOneBaseMiniMachine:showBonusTriggerTip(func )

    local isFixSymbol = function( symbolType )
        if symbolType == self:getScatterSymbolType(  ) then

            return true
        end

        return false
    end


    -- 播放 respinbonus buling 动画
    local ActionTime = 0
    for icol = 1,self.m_iReelColumnNum do
        for irow = 1, self.m_iReelRowNum do

            local node = self:getReelParent(icol):getChildByTag(self:getNodeTag(icol, irow, SYMBOL_NODE_TAG))

            if node and  node.p_symbolType then
                if isFixSymbol(node.p_symbolType) then

                    self:createOneActionSymbol(node,"actionframe")
                    ActionTime = 3.5
                end
            end
        
        end
    end

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,ActionTime)
end


function FourInOneBaseMiniMachine:lineLogicEffectType(winLineData, lineInfo,iconsPos)
    local enumSymbolType = self:getWinLineSymboltType(winLineData,lineInfo)
            
    if iconsPos ~= nil and #iconsPos >= self.m_validLineSymNum then
        if enumSymbolType == self:getScatterSymbolType(  ) then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_FREE_SPIN -- 检测是否添加effect 效果
            
        elseif enumSymbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then
            lineInfo.enumSymbolEffectType = GameEffect.EFFECT_BONUS
        end
    end

    return enumSymbolType
end
---
-- 根据类型获取对应节点
--
function FourInOneBaseMiniMachine:getSlotNodeBySymbolType(symbolType)
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
function FourInOneBaseMiniMachine:getBaseReelGridNode()
    return "CodeFourInOneSrc.FourInOneSlotFastNode"
end

function FourInOneBaseMiniMachine:triggerCharmsRespin( func )
    
    gLobalSoundManager:playSound("FourInOneSounds/CharmsSounds/music_Charms_trigger_respin.mp3")

    local isFixSymbol = function( symbolType )
        if math.abs(symbolType) == self.SYMBOL_Charms_bonus  or 
            math.abs(symbolType) == self.SYMBOL_Charms_SYMBOL_DOUBLE  or
            math.abs(symbolType) == self.SYMBOL_Charms_MINI or 
            math.abs(symbolType) == self.SYMBOL_Charms_MINOR or
            math.abs(symbolType) == self.SYMBOL_Charms_MINOR_DOUBLE then

            return true
        end

        return false
    end


    -- 播放 respinbonus buling 动画
    local ActionTime = 4.7
    for icol = 1,self.m_iReelColumnNum do
        for irow = 1, self.m_iReelRowNum do

            local node = self:getReelParent(icol):getChildByTag(self:getNodeTag(icol, irow, SYMBOL_NODE_TAG))

            if node and  node.p_symbolType then
                if isFixSymbol(node.p_symbolType) then

                    self:createOneActionSymbol(node,"actionframe")
                    ActionTime = node:getAniamDurationByName("actionframe")
                end
            end
        
        end
    end

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,ActionTime)

end

function FourInOneBaseMiniMachine:triggerPomiRespin( func )

    gLobalSoundManager:playSound("FourInOneSounds/PomiSounds/music_Pomi_Trigger_Respin.mp3")

    local ActionTime = 4.5

    local isFixSymbol = function( symbolType )
        if symbolType == self.SYMBOL_Pomi_Bonus or 
            symbolType == self.SYMBOL_Pomi_MINI or 
            symbolType == self.SYMBOL_Pomi_MINOR or 
            symbolType == self.SYMBOL_Pomi_MAJOR or 
            symbolType == self.SYMBOL_Pomi_GRAND or
            symbolType == self.SYMBOL_Pomi_Reel_Up or
            symbolType == self.SYMBOL_Pomi_Double_bet  then

            return true
        end
        return false
    end


    for iCol = 1, self.m_iReelColumnNum do

        for iRow = 1, self.m_iReelRowNum do
            local targSp = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if targSp and targSp.p_symbolType then
                if isFixSymbol(targSp.p_symbolType) then

                    self:createOneActionSymbol(targSp,"actionframe")
                    
                    performWithDelay(self,function(  )
                        self:createOneActionSymbol(targSp,"actionframe")
                    end,2)

                    performWithDelay(self,function(  )
                        targSp:runAnim("idle",true)
                    end,4)
                    
                end
            end

        end

    end

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,ActionTime)
end

function FourInOneBaseMiniMachine:triggerHowlingMoonRespin( func )
    

    gLobalSoundManager:playSound("FourInOneSounds/HowlingMoonSounds/music_HowlingMoon_enter_bonus.mp3")

    local ActionTime = 6.5



    -- 播放自定义light动画
    for j = 1, self.m_iReelColumnNum, 1 do
        for i = 1, self.m_iReelRowNum, 1 do

            local symbolNode = self:getReelParent(j):getChildByTag(self:getNodeTag(j,i,SYMBOL_NODE_TAG))
            if symbolNode and symbolNode.p_symbolType then

                    local symbolType = symbolNode.p_symbolType

                    if symbolType == self.SYMBOL_HowlingMoon_Bonus or
                    symbolType == self.SYMBOL_HowlingMoon_MINI or  
                    symbolType == self.SYMBOL_HowlingMoon_MINOR or
                    symbolType == self.SYMBOL_HowlingMoon_MAJOR or
                    symbolType == self.SYMBOL_HowlingMoon_GRAND then
                            local symbolNode = self:getReelParent(j):getChildByTag(self:getNodeTag(j,i,SYMBOL_NODE_TAG))

                            self:createOneActionSymbol(symbolNode,"actionframe1")
                    
                            performWithDelay(self,function(  )
                                self:createOneActionSymbol(symbolNode,"actionframe1")
                            end,3)

                    end
            end
        end
    end

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,ActionTime)


end

function FourInOneBaseMiniMachine:triggerChilliFiestaRespin( func )
    
    gLobalSoundManager:playSound("FourInOneSounds/ChilliFiestaSounds/music_ChilliFiesta_respinTrigger.mp3")

    local ActionTime = 5

    

    -- 播放自定义light动画
    for j = 1, self.m_iReelColumnNum, 1 do
        for i = 1, self.m_iReelRowNum, 1 do

            local symbolNode = self:getReelParent(j):getChildByTag(self:getNodeTag(j,i,SYMBOL_NODE_TAG))
            if symbolNode and symbolNode.p_symbolType then

                local symbolType = symbolNode.p_symbolType

                if symbolType == self.SYMBOL_ChilliFiesta_BONUS or
                symbolType == self.SYMBOL_ChilliFiesta_ALL or 
                symbolType == self.SYMBOL_ChilliFiesta_GRAND or  
                symbolType == self.SYMBOL_ChilliFiesta_MAJOR or
                symbolType == self.SYMBOL_ChilliFiesta_MINOR or
                symbolType == self.SYMBOL_ChilliFiesta_MINI then
                        
                        self:createOneActionSymbol(symbolNode,"actionframe")

                end
            end
        end
    end

    performWithDelay(self,function(  )
        if func then
            func()
        end
    end,ActionTime)
end

function FourInOneBaseMiniMachine:createOneActionSymbol(endNode,actionName )

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
        local pos = self:findChild("root"):convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
        self:findChild("root"):addChild(node , 100000 + endNode.p_rowIndex)
        node:setPosition(pos)
    
        local storedIcons = self.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        local symbolIndex = self:getPosReelIdx(endNode.p_rowIndex, endNode.p_cloumnIndex)
        local score = self:getReSpinSymbolScore(symbolIndex) --获取分数（网络数据）
        local index = 0
        if score ~= nil and type(score) ~= "string" then
            local lineBet = globalData.slotRunData:getCurTotalBet() / 4
            score = score * lineBet
            score = util_formatCoins(score, 3)
            local scoreNode = node:findChild("m_lb_score")
            local scoreNode1 = node:findChild("m_lb_score1")
            if scoreNode1 then
                scoreNode1:setString("")
            end

            
            if scoreNode and endNode.p_symbolType and self:isScoreFixSymbol(endNode.p_symbolType ) then
                scoreNode:setVisible(true)
                scoreNode:setString(score)
            end
        end
                
    
        return node
end
function FourInOneBaseMiniMachine:showBaseMiniEffect_Respin( func )
    

    self.m_triggerEffect:setVisible(true)
    self.m_triggerEffect:playAction("idleframe",true)

    local curCall = function(  )
        
        if func then
            func()
        end
        
    end

    if self.m_reelType == HowlingMoon_Reels then
        self:triggerHowlingMoonRespin( curCall )
    elseif self.m_reelType == Pomi_Reels then
        self:triggerPomiRespin( curCall )
    elseif self.m_reelType == ChilliFiesta_Reels then
        self:triggerChilliFiestaRespin( curCall )
    elseif self.m_reelType == Charms_Reels then
        self:triggerCharmsRespin( curCall )
    else
        if curCall then
            curCall()
        end
    end


    
end

-- 更新Link类数据
function FourInOneBaseMiniMachine:SpinResultParseResultData( result)
    self.m_runSpinResultData:parseResultData(result,self.m_lineDataPool)
end

-- 处理特殊关卡 scatterBonus等快滚元素的特殊动画效果 继承
function FourInOneBaseMiniMachine:specialSymbolActionTreatment( node)
    if node and node.p_symbolType then
        if self:isScatterSymbolType( node.p_symbolType ) then
            node:runAnim("buling",false,function(  )
                node:runAnim("idleframe")
            end)
        end
        
    end
end


---
-- 恢复当前背景音乐
--
--@isMustPlayMusic 是否必须播放音乐
function FourInOneBaseMiniMachine:resetMusicBg(isMustPlayMusic,selfMakePlayMusicName)
   
end

function FourInOneBaseMiniMachine:clearCurMusicBg( )
    
end


---
-- 清空掉产生的数据
--
function FourInOneBaseMiniMachine:clearSlotoData()
    
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

function FourInOneBaseMiniMachine:onExit()

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
    if not tolua.isnull(viewLayer) then
        viewLayer:removeAllChildren()
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
function FourInOneBaseMiniMachine:clearSlotNodes()
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

function FourInOneBaseMiniMachine:clearSlotChilds(childs)
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


function FourInOneBaseMiniMachine:showLineFrame()
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

return FourInOneBaseMiniMachine
