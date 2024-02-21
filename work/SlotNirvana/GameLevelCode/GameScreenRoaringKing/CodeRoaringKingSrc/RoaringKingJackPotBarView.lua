---
--xcyy
--2018年5月23日
--RoaringKingJackPotBarView.lua

local RoaringKingJackPotBarView = class("RoaringKingJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_Grand"
local MajorName = "m_lb_coins_Major"
local MinorName = "m_lb_coins_Minor"


function RoaringKingJackPotBarView:initUI()

    self:createCsbNode("RoaringKing_jackpot.csb")
    
end

function RoaringKingJackPotBarView:onEnter()

    RoaringKingJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function RoaringKingJackPotBarView:onExit()
    RoaringKingJackPotBarView.super.onExit(self)
end

function RoaringKingJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function RoaringKingJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3,true)


    self:updateSize()
end

function RoaringKingJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=0.9,sy=1}
    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=0.61,sy=0.61}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.61,sy=0.61}
    self:updateLabelSize(info1,225)
    self:updateLabelSize(info2,352)
    self:updateLabelSize(info3,338)
end

function RoaringKingJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end





return RoaringKingJackPotBarView