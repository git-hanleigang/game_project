---
--xcyy
--2018年5月23日
--JackpotOGoldJackPotMiniBarView.lua

local JackpotOGoldJackPotMiniBarView = class("JackpotOGoldJackPotMiniBarView",util_require("Levels.BaseLevelDialog"))

function JackpotOGoldJackPotMiniBarView:initUI()

    self:createCsbNode("JackpotOGold_Jackpot_Mini.csb")

    self:runCsbAction("idle",true)

end


function JackpotOGoldJackPotMiniBarView:onEnter()
    JackpotOGoldJackPotMiniBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function JackpotOGoldJackPotMiniBarView:onExit()
    JackpotOGoldJackPotMiniBarView.super.onExit(self)
end

function JackpotOGoldJackPotMiniBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function JackpotOGoldJackPotMiniBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end

    self:changeNode(self:findChild("m_lb_coins"),5,true)

    self:updateSize()
end

function JackpotOGoldJackPotMiniBarView:updateSize()

    local label1=self.m_csbOwner["m_lb_coins"]
    local info1={label=label1,sx=0.95,sy=0.95}
    self:updateLabelSize(info1,436)

end

function JackpotOGoldJackPotMiniBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return JackpotOGoldJackPotMiniBarView