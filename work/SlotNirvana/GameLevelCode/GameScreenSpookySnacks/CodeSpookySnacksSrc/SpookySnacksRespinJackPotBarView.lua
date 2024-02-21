---
--xcyy
--2018年5月23日
--SpookySnacksRespinJackPotBarView.lua
local PublicConfig = require "SpookySnacksPublicConfig"
local SpookySnacksRespinJackPotBarView = class("SpookySnacksRespinJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_num_grand"
local MajorName = "m_lb_num_major"
local MinorName = "m_lb_num_minor"
local MiniName = "m_lb_num_mini"

local WinningName = {
    "grand",
    "major",
    "minor",
    "mini"
}

local lightNode = {
    "grand_sg",
    "major_sg",
    "minor_sg",
    "mini_sg"
}
local jackpotIdleList = {"major_idle","major_mini","mini_idle","mini_minor","minor_idle","minor_major"}

function SpookySnacksRespinJackPotBarView:initUI(machine)
    self:createCsbNode("SpookySnacks_respin_jackpot.csb")
    self.m_machine = machine
    self.winList = {}

    self.actNode = cc.Node:create()
    self:addChild(self.actNode)

    self.jackpotNode = cc.Node:create()
    self:addChild(self.jackpotNode)

    self:addWinningEffect()
    self:addLightingEffect()
    self.m_jackpotIdleIndex = 1
    self:playJackpot()
    self:addLockEffect()
    self.m_lockStatus = false

    
end

function SpookySnacksRespinJackPotBarView:initMachine(machine)
    
end

function SpookySnacksRespinJackPotBarView:onEnter()
    SpookySnacksRespinJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

-- 更新jackpot 数值信息
--
function SpookySnacksRespinJackPotBarView:updateJackpotInfo()
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

function SpookySnacksRespinJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local info1 = {label = label1, sx = 1, sy = 1}
    local info2 = {label = label2, sx = 1, sy = 1}
    local label3 = self.m_csbOwner[MinorName]
    local info3 = {label = label3, sx = 1, sy = 1}
    local label4 = self.m_csbOwner[MiniName]
    local info4 = {label = label4, sx = 1, sy = 1}
    self:updateLabelSize(info1, 278)
    self:updateLabelSize(info2, 278)
    self:updateLabelSize(info3, 236)
    self:updateLabelSize(info4, 236)
end

function SpookySnacksRespinJackPotBarView:changeNode(label, index, isJump)
    local lineBet = globalData.slotRunData:getCurTotalBet()
    local m_runSpinResultData = self.m_machine.m_runSpinResultData or {}
    local selfData = m_runSpinResultData.p_selfMakeData or {}
    local avgBet = selfData.avgBet or nil
    if self.m_machine.m_isSuperFree and avgBet then
        lineBet = self.m_machine.m_runSpinResultData.p_selfMakeData.avgBet
    end
    local value = self.m_machine:BaseMania_updateJackpotScore(index,lineBet)
    label:setString(util_formatCoins(value, 20, nil, nil, true))
end

--中奖框
function SpookySnacksRespinJackPotBarView:addWinningEffect()
    self.winList = {}
    for i,v in ipairs(WinningName) do
        local item = util_createAnimation("SpookySnacks_respin_jackpot_zhongjiang.csb")
        self:findChild(v.."_win"):addChild(item)
        item.name = v
        item:setVisible(false)
        self.winList[v] = item
    end
end

--展示中奖框
function SpookySnacksRespinJackPotBarView:showWinningEffect(jackpotType)
    local type = string.lower(WinningName[jackpotType])
    self.jackpotNode:stopAllActions()
    self:runCsbAction(type .. "_idle",true)
    local item = self.winList[tostring(type)]
    if not tolua.isnull(item) then
        item:setVisible(true)
        item:runCsbAction("actionframe",true)
    end
end

function SpookySnacksRespinJackPotBarView:hideWinningEffect()
    for k, _node in pairs(self.winList) do
        if not tolua.isnull(_node) then
            _node:setVisible(false)
        end
    end
    self:playJackpot()
end

--lock
function SpookySnacksRespinJackPotBarView:addLightingEffect()
    for i,v in ipairs(lightNode) do
        local lightEffect = util_createAnimation("SpookySnacks_respin_jackpot_saoguang.csb")
        self:findChild(v):addChild(lightEffect)
        if i == 1 then
            lightEffect:runCsbAction("idle",true)
        else
            lightEffect:runCsbAction("idle2",true)
        end
    end
    
end

function SpookySnacksRespinJackPotBarView:addLockEffect()
    self.lockEffect = util_createAnimation("SpookySnacks_jackpot_lock.csb")
    self:findChild("Node_lock"):addChild(self.lockEffect)
    -- self.lockEffect:setVisible(false)
end

function SpookySnacksRespinJackPotBarView:showJackpotLock()
    self.actNode:stopAllActions()
    self.lockEffect:runCsbAction("over")
    self.m_lockStatus = true
    performWithDelay(self.actNode,function ()
        self.lockEffect:runCsbAction("idle")
    end,62/60)
end

function SpookySnacksRespinJackPotBarView:showJackpotUnLock()
    self.actNode:stopAllActions()
    self.lockEffect:runCsbAction("start")
    self.m_lockStatus = false
    performWithDelay(self.actNode,function ()
        self.lockEffect:runCsbAction("idle2")
    end,28/60)
end

-- 轮播 jackpot
function SpookySnacksRespinJackPotBarView:playJackpot()
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self:runCsbAction(jackpotIdleList[self.m_jackpotIdleIndex])
    end)
    if self.m_jackpotIdleIndex % 2 == 1 then
        actList[#actList + 1] = cc.DelayTime:create(5)
    else
        actList[#actList + 1] = cc.DelayTime:create(20/60)
    end
    
    actList[#actList + 1] = cc.CallFunc:create(function ()
        self.m_jackpotIdleIndex = self.m_jackpotIdleIndex + 1
        if self.m_jackpotIdleIndex > #jackpotIdleList then
            self.m_jackpotIdleIndex = 1
        end
        self:playJackpot()
    end)
    self.jackpotNode:runAction(cc.Sequence:create(actList))

end

-- 判断 是否解锁了
function SpookySnacksRespinJackPotBarView:checkIsJieSuo( )
    return self.m_lockStatus
end

return SpookySnacksRespinJackPotBarView
