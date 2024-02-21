---
--xcyy
--2018年5月23日
--JackpotOGoldJackPotMinorBarView.lua

local JackpotOGoldJackPotMinorBarView = class("JackpotOGoldJackPotMinorBarView",util_require("Levels.BaseLevelDialog"))

function JackpotOGoldJackPotMinorBarView:initUI()

    self:createCsbNode("JackpotOGold_Jackpot_Minor.csb")

    self:runCsbAction("idle",true)

end


function JackpotOGoldJackPotMinorBarView:onEnter()
    JackpotOGoldJackPotMinorBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function JackpotOGoldJackPotMinorBarView:onExit()
    JackpotOGoldJackPotMinorBarView.super.onExit(self)
end

function JackpotOGoldJackPotMinorBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function JackpotOGoldJackPotMinorBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    self:changeNode(self:findChild("m_lb_coins"),4,true)

    self:updateSize()
end

function JackpotOGoldJackPotMinorBarView:updateSize()

    local label1=self.m_csbOwner["m_lb_coins"]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,436)

end

function JackpotOGoldJackPotMinorBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return JackpotOGoldJackPotMinorBarView