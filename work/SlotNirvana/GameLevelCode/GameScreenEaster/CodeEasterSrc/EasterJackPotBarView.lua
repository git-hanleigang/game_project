---
--xcyy
--2018年5月23日
--EasterJackPotBarView.lua

local EasterJackPotBarView = class("EasterJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function EasterJackPotBarView:initUI()

    self:createCsbNode("JackPotBar.csb")

    -- self:runCsbAction("idleframe",true)

end

function EasterJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function EasterJackPotBarView:onExit()
 
end

function EasterJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function EasterJackPotBarView:updateJackpotInfo()
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

function EasterJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.9,sy=0.9}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.8,sy=0.8}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.8,sy=0.8}
    self:updateLabelSize(info1,350)
    self:updateLabelSize(info2,285)
    self:updateLabelSize(info3,280)
    self:updateLabelSize(info4,280)
end

function EasterJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return EasterJackPotBarView