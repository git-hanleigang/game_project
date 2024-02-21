---
--xcyy
--2018年5月23日
--FrozenJewelryJackPotBarView.lua

local FrozenJewelryJackPotBarView = class("FrozenJewelryJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 

function FrozenJewelryJackPotBarView:initUI()

    self:createCsbNode("FrozenJewelry_Jackpot.csb")

    -- self:runCsbAction("idleframe",true)

end

function FrozenJewelryJackPotBarView:onEnter()

    FrozenJewelryJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function FrozenJewelryJackPotBarView:onExit()
    FrozenJewelryJackPotBarView.super.onExit(self)
end

function FrozenJewelryJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function FrozenJewelryJackPotBarView:updateJackpotInfo()
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

function FrozenJewelryJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1.06,sy=1.06}
    local info2={label=label2,sx=1.06,sy=1.06}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1.06,sy=1.06}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1.06,sy=1.06}
    self:updateLabelSize(info1,190)
    self:updateLabelSize(info2,190)
    self:updateLabelSize(info3,190)
    self:updateLabelSize(info4,190)
end

function FrozenJewelryJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return FrozenJewelryJackPotBarView