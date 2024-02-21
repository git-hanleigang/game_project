---
--xcyy
--2018年5月23日
--ScarabChestBaseCoinsView.lua
local PublicConfig = require "ScarabChestPublicConfig"
local ScarabChestBaseCoinsView = class("ScarabChestBaseCoinsView",util_require("Levels.BaseLevelDialog"))

function ScarabChestBaseCoinsView:initUI(_machine)

    self:createCsbNode("ScarabChest_baoxiang_jidi.csb")

    self.m_machine = _machine

    self.baseCoinsText = self:findChild("m_lb_coins")

    self:setIdle()
    self.m_maxWidth = 236

    self.m_scScheduleNode = cc.Node:create()
    self:addChild(self.m_scScheduleNode)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:setLastBaseCoins(0)
end

-- idle
function ScarabChestBaseCoinsView:setIdle()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle", true)
end

-- 进free
function ScarabChestBaseCoinsView:enterFreeStart()
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start1", false, function()
        self:runCsbAction("idle", true)
    end)
end

-- 出现
function ScarabChestBaseCoinsView:showStart()
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

-- over
function ScarabChestBaseCoinsView:closeBaseCoins(_isInit)
    local isInit = _isInit
    self:setLastBaseCoins(0)
    util_resetCsbAction(self.m_csbAct)
    if isInit then
        self:setVisible(false)
    else
        self:runCsbAction("over", false, function()
            self:setVisible(false)
        end)
    end
end

-- 开始涨钱
function ScarabChestBaseCoinsView:startJumpCouns(params)
    self:clearScheduleNode()
    self:setVisible(true)
    self.m_boxLevel = 1
    self.m_endCoins = params.endCoins or 0   --结束金币数
    self.m_duration = params.duration or 2   --持续时间
    self.m_maxWidth = params.maxWidth or 236 --lable最大宽度
    self.m_curWinCoins = params.curWinCoins -- 当次spin赢的线钱
    self.m_endCallFunc = params.endCallFunc -- 结束回调
    --每帧跳动上涨金币数
    self.m_coinRiseNum =  self.m_curWinCoins / self.m_duration
    self.m_curCoins = self:getLastBaseCoins()
    if self.m_scScheduleNode ~= nil then
        self.m_scScheduleNode:onUpdate(function(delayTime)
            self:jumpBaseCoins(delayTime)
        end)
    end
end

-- 最终赢钱涨钱
function ScarabChestBaseCoinsView:jumpBaseCoins(delayTime)
    self.m_curCoins = self.m_curCoins + self.m_coinRiseNum * delayTime
    if self.m_curCoins >= self.m_endCoins then
        self:clearScheduleNode(true)
        self:setBaseCoins(self.m_endCoins)
        self:setLastBaseCoins(self.m_endCoins)
    else
        self:setBaseCoins(self.m_curCoins)
    end
end

-- 基底
function ScarabChestBaseCoinsView:setBaseCoins(_baseCoins, _isInit)
    self.baseCoinsText:setString(util_formatCoins(_baseCoins, 3))
    self:updateLabelSize({label=self.baseCoinsText,sx=1.0,sy=1.0},self.m_maxWidth)
    if _isInit then
        self:setLastBaseCoins(_baseCoins)
    end
end

function ScarabChestBaseCoinsView:clearScheduleNode(_isOver)
    local isOver = _isOver
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle", true)
    if self.m_scScheduleNode ~= nil then
        self.m_scScheduleNode:unscheduleUpdate()
    end
end

function ScarabChestBaseCoinsView:setLastBaseCoins(_lastBaseCoins)
    self.m_lastBaseCoins = _lastBaseCoins
end

function ScarabChestBaseCoinsView:getLastBaseCoins()
    return self.m_lastBaseCoins
end

return ScarabChestBaseCoinsView
