---
--xcyy
--2018年5月23日
--PandaDeluxeJackPotBarView.lua

local PandaDeluxeJackPotBarView = class("PandaDeluxeJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_coin_0"
local MajorName = "m_lb_coin_1"
local MinorName = "m_lb_coin_2"
local MiniName = "m_lb_coin_3" 

function PandaDeluxeJackPotBarView:initUI()

    self:createCsbNode("PandaDeluxe_JackPot.csb")

end


function PandaDeluxeJackPotBarView:onExit()
 
end

function PandaDeluxeJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function PandaDeluxeJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function PandaDeluxeJackPotBarView:updateJackpotInfo()
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

function PandaDeluxeJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=0.5,sy=0.5}
    local info2={label=label2,sx=0.5,sy=0.5}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.4,sy=0.4}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.4,sy=0.4}
    self:updateLabelSize(info1,537)
    self:updateLabelSize(info2,465)
    self:updateLabelSize(info3,419)
    self:updateLabelSize(info4,419)
end

function PandaDeluxeJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function PandaDeluxeJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return PandaDeluxeJackPotBarView