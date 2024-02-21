---
--xcyy
--2018年5月23日
--BadgedCowboyJackPotBarView.lua

local BadgedCowboyJackPotBarView = class("BadgedCowboyJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

function BadgedCowboyJackPotBarView:initUI()

    self:createCsbNode("BadgedCowboy_jackpot.csb")

    self:runCsbAction("idle",true)
end

function BadgedCowboyJackPotBarView:onEnter()

    BadgedCowboyJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function BadgedCowboyJackPotBarView:onExit()
    BadgedCowboyJackPotBarView.super.onExit(self)
end

function BadgedCowboyJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function BadgedCowboyJackPotBarView:playJackpotAction(_index, _isRespin)
    local index = _index
    local isRespin = _isRespin
    self:runCsbAction("actionframe", true)
    for i=1, 4 do
        local effectNode = self:findChild("NodeEffect_"..i)
        if isRespin then
            if i >= index then
                effectNode:setVisible(true)
            else
                effectNode:setVisible(false)
            end
        else
            if i == index then
                effectNode:setVisible(true)
            else
                effectNode:setVisible(false)
            end
        end
    end
end

function BadgedCowboyJackPotBarView:playJackpotIdle()
    self:runCsbAction("idle",true)
end

-- 更新jackpot 数值信息
--
function BadgedCowboyJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function BadgedCowboyJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1.0,sy=1.0}
    local info2={label=label2,sx=1.0,sy=1.0}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.95,sy=0.95}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.95,sy=0.95}
    self:updateLabelSize(info1,246)
    self:updateLabelSize(info2,246)
    self:updateLabelSize(info3,246)
    self:updateLabelSize(info4,246)
end

function BadgedCowboyJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return BadgedCowboyJackPotBarView
