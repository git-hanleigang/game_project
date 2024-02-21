---
--xcyy
--2018年5月23日
--BankCrazeJackPotBarView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeJackPotBarView = class("BankCrazeJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

function BankCrazeJackPotBarView:initUI()
    self:createCsbNode("BankCraze_JackpotBar.csb")
    self:runCsbAction("idle", true)

    self.m_jackpotWinNodeTbl = {}
    for i=1, 4 do
        self.m_jackpotWinNodeTbl[i] = util_createAnimation("BankCraze_JackpotBar_win.csb")
        local jackpotNode = self:findChild("Node_win"..i)
        if jackpotNode then
            jackpotNode:addChild(self.m_jackpotWinNodeTbl[i])
        else
            self:addChild(self.m_jackpotWinNodeTbl[i])
        end
        self.m_jackpotWinNodeTbl[i]:setVisible(false)
    end
end

function BankCrazeJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function BankCrazeJackPotBarView:onEnter()
    BankCrazeJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

-- jackpot触发
function BankCrazeJackPotBarView:playTriggerJackpot(_jackpotType)
    local jackpotType = _jackpotType
    local jackpotIndex = 4
    local jackpotTypeTbl = {"grand", "major", "minor", "mini"}
    for i=1, 4 do
        if string.lower(jackpotType) == jackpotTypeTbl[i] then
            jackpotIndex = i
            break
        end
    end
    self.m_jackpotWinNodeTbl[jackpotIndex]:setVisible(true)
    self.m_jackpotWinNodeTbl[jackpotIndex]:runCsbAction("actionframe", true)
end

-- 关闭jackpot光效
function BankCrazeJackPotBarView:closeJackpotAct(_jackpotIndex)
    local jackpotIndex = _jackpotIndex
    self.m_jackpotWinNodeTbl[jackpotIndex]:setVisible(false)
end

-- 更新jackpot 数值信息
--
function BankCrazeJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MajorName), 2, true)
    self:changeNode(self:findChild(MinorName), 3)
    self:changeNode(self:findChild(MiniName), 4)

    self:updateSize()
end

function BankCrazeJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 0.98, sy = 0.98}
    local info2 = {label = label2, sx = 0.98, sy = 0.98}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 0.88, sy = 0.88}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 0.88, sy = 0.88}
    self:updateLabelSize(info1, 298)
    self:updateLabelSize(info2, 298)
    self:updateLabelSize(info3, 298)
    self:updateLabelSize(info4, 298)
end

function BankCrazeJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value, 12, nil, nil, true))
end

return BankCrazeJackPotBarView
