---
--xcyy
--2018年5月23日
--BunnyBountyJackPotBarView.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyJackPotBarView = class("BunnyBountyJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_grand"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 

function BunnyBountyJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("BunnyBounty_base_jackpot.csb")
end

function BunnyBountyJackPotBarView:onEnter()

    BunnyBountyJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function BunnyBountyJackPotBarView:onExit()
    BunnyBountyJackPotBarView.super.onExit(self)
end

function BunnyBountyJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function BunnyBountyJackPotBarView:updateJackpotInfo()
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

function BunnyBountyJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local label3=self.m_csbOwner[MinorName]
    local label4=self.m_csbOwner[MiniName]
    

    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local info3={label=label3,sx=1,sy=1}
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,345)
    self:updateLabelSize(info2,345)
    self:updateLabelSize(info3,280)
    self:updateLabelSize(info4,280)
end

function BunnyBountyJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return BunnyBountyJackPotBarView