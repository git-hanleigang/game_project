---
--xcyy
--2018年5月23日
--FortuneGodJackPotBarView.lua

local FortuneGodJackPotBarView = class("FortuneGodJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins"
local MajorName = "m_lb_coins_0"
local MinorName = "m_lb_coins_1"
local MiniName = "m_lb_coins_2" 

function FortuneGodJackPotBarView:initUI()

    self:createCsbNode("FortuneGod_jackpot.csb")

end



function FortuneGodJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function FortuneGodJackPotBarView:onEnter()

    FortuneGodJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function FortuneGodJackPotBarView:onExit()
    FortuneGodJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function FortuneGodJackPotBarView:updateJackpotInfo()
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

function FortuneGodJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.96,sy=0.96}
    local info2={label=label2,sx=0.92,sy=0.92}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.84,sy=0.84}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.76,sy=0.76}
    self:updateLabelSize(info1,232)
    self:updateLabelSize(info2,232)
    self:updateLabelSize(info3,232)
    self:updateLabelSize(info4,232)
end

function FortuneGodJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end



return FortuneGodJackPotBarView