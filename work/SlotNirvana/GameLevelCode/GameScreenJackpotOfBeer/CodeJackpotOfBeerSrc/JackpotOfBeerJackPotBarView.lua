---
--xcyy
--2018年5月23日
--JackpotOfBeerJackPotBarView.lua

local JackpotOfBeerJackPotBarView = class("JackpotOfBeerJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 

function JackpotOfBeerJackPotBarView:initUI()

    self:createCsbNode("JackpotOfBeer_jackpot.csb")


end



function JackpotOfBeerJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function JackpotOfBeerJackPotBarView:onEnter()

    JackpotOfBeerJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function JackpotOfBeerJackPotBarView:onExit()
    JackpotOfBeerJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function JackpotOfBeerJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3,true)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function JackpotOfBeerJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,168)
    self:updateLabelSize(info2,155)
    self:updateLabelSize(info3,137)
    self:updateLabelSize(info4,137)
end

function JackpotOfBeerJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,30,nil,nil,true))
end



return JackpotOfBeerJackPotBarView