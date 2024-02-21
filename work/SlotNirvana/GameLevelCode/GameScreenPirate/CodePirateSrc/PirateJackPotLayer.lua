---
--PirateJackPotLayer.lua
local PirateJackPotLayer = class("PirateJackPotLayer", util_require("base.BaseView"))

function PirateJackPotLayer:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Pirate_Socre_Top.csb"
    self:createCsbNode(resourceFilename)
end

function PirateJackPotLayer:updateJackpotInfo()
    if not self.m_machine then
        return
    end
  
    self:changeNode(self:findChild("m_lb_grand"),4,true)
    self:changeNode(self:findChild("m_lb_major"),3,true)
    self:changeNode(self:findChild("m_lb_minor"),2,true)
    self:changeNode(self:findChild("m_lb_mini"),1,true)

    self:updateLabelSize({label=self:findChild("m_lb_mini"),sx=1,sy=1},147)
    self:updateLabelSize({label=self:findChild("m_lb_minor"),sx=1,sy=1},147)
    self:updateLabelSize({label=self:findChild("m_lb_major"),sx=1,sy=1},147)
    self:updateLabelSize({label=self:findChild("m_lb_grand"),sx=1,sy=1},147)

end

--jackpot算法
function PirateJackPotLayer:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,50))
end

function PirateJackPotLayer:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

return PirateJackPotLayer