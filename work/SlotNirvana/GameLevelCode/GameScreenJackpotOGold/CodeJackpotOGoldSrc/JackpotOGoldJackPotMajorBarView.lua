---
--xcyy
--2018年5月23日
--JackpotOGoldJackPotMajorBarView.lua

local JackpotOGoldJackPotMajorBarView = class("JackpotOGoldJackPotMajorBarView",util_require("Levels.BaseLevelDialog"))

function JackpotOGoldJackPotMajorBarView:initUI()

    self:createCsbNode("JackpotOGold_Jackpot_Major.csb")

    self:runCsbAction("idle",true)

end


function JackpotOGoldJackPotMajorBarView:onEnter()
    JackpotOGoldJackPotMajorBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function JackpotOGoldJackPotMajorBarView:onExit()
    JackpotOGoldJackPotMajorBarView.super.onExit(self)
end

function JackpotOGoldJackPotMajorBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function JackpotOGoldJackPotMajorBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    self:changeNode(self:findChild("m_lb_coins"),3,true)

    self:updateSize()
end

function JackpotOGoldJackPotMajorBarView:updateSize()

    local label1=self.m_csbOwner["m_lb_coins"]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,436)

end

function JackpotOGoldJackPotMajorBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return JackpotOGoldJackPotMajorBarView