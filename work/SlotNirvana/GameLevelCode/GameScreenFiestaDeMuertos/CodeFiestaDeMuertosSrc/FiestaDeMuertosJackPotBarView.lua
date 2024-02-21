---
--xcyy
--2018年5月23日
--FiestaDeMuertosJackPotBarView.lua

local FiestaDeMuertosJackPotBarView = class("FiestaDeMuertosJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_coins_1"
local MajorName = "m_lb_coins_2"
local MinorName = "m_lb_coins_3"

function FiestaDeMuertosJackPotBarView:initUI()

    self:createCsbNode("FiestaDeMuertos_jackpot.csb")

    -- self:runCsbAction("idleframe",true)

end

function FiestaDeMuertosJackPotBarView:onExit()
 
end

function FiestaDeMuertosJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function FiestaDeMuertosJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function FiestaDeMuertosJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3,true)

    self:updateSize()
end

function FiestaDeMuertosJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=0.9,sy=0.9}

    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=0.9,sy=0.9}

    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.9,sy=0.9}

    self:updateLabelSize(info1,329)
    self:updateLabelSize(info2,329)
    self:updateLabelSize(info3,329)

end

function FiestaDeMuertosJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function FiestaDeMuertosJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end


return FiestaDeMuertosJackPotBarView