---
--xcyy
--2018年5月23日
--EpicElephantJackPotBarView.lua

local EpicElephantJackPotBarView = class("EpicElephantJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins3"

function EpicElephantJackPotBarView:initUI(params)

    self:createCsbNode("EpicElephant_jackpot.csb")

    self:initMachine(params.machine)

    self:runCsbAction("idle",true)

end

function EpicElephantJackPotBarView:onEnter()

    EpicElephantJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function EpicElephantJackPotBarView:onExit()
    EpicElephantJackPotBarView.super.onExit(self)
end

function EpicElephantJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function EpicElephantJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)

    self:updateSize()
end

function EpicElephantJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=0.67,sy=0.67}
    self:updateLabelSize(info1,895)
end

function EpicElephantJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return EpicElephantJackPotBarView