---
--xcyy
--2018年5月23日
--MerryChristmasJackPotBarView.lua

local MerryChristmasJackPotBarView = class("MerryChristmasJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_coins_2"
local MajorName = "m_lb_coins_1"
local MinorName = "m_lb_coins_0"

function MerryChristmasJackPotBarView:initUI()

    self:createCsbNode("MerryChristmas_jackpot.csb")
end

function MerryChristmasJackPotBarView:onExit()
 
end

function MerryChristmasJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MerryChristmasJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function MerryChristmasJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3,true)

    self:updateSize()
end

function MerryChristmasJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}

    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=0.9,sy=0.9}

    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.9,sy=0.9}

    self:updateLabelSize(info1,232)
    self:updateLabelSize(info2,232)
    self:updateLabelSize(info3,232)

end

function MerryChristmasJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function MerryChristmasJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return MerryChristmasJackPotBarView
