---
--xcyy
--2018年5月23日
--PussJackPotBarView.lua

local PussJackPotBarView = class("PussJackPotBarView",util_require("base.BaseView"))

local GrandName = "BitmapFontLabel_2"
local MajorName = "BitmapFontLabel_2_0"
local MinorName = "BitmapFontLabel_2_0_0"

function PussJackPotBarView:initUI()

    self:createCsbNode("Puss_jackpot.csb")

    -- self:runCsbAction("idleframe",true)

end



function PussJackPotBarView:onExit()
 
end

function PussJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function PussJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function PussJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)

    self:updateSize()
end

function PussJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.6,sy=0.6}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.6,sy=0.6}
    self:updateLabelSize(info1,436)
    self:updateLabelSize(info2,359)
    self:updateLabelSize(info3,359)
end

function PussJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function PussJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return PussJackPotBarView