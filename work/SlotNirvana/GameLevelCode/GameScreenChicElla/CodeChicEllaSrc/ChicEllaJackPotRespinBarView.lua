---
--xcyy
--2018年5月23日
--ChicEllaJackPotRespinBarView.lua

local ChicEllaJackPotRespinBarView = class("ChicEllaJackPotRespinBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins3"
local MajorName = "m_lb_coins1"
local MinorName = "m_lb_coins2"

function ChicEllaJackPotRespinBarView:initUI()

    self:createCsbNode("ChicElla_respin_jackpot.csb")

    self:runCsbAction("idle",true)

end


function ChicEllaJackPotRespinBarView:initMachine(machine)
    self.m_machine = machine
end

function ChicEllaJackPotRespinBarView:onEnter()
    ChicEllaJackPotRespinBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    -- schedule(self,function()
    --     self:updateJackpotInfo()
    -- end,0.08)
end

-- 更新jackpot 数值信息
--
function ChicEllaJackPotRespinBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)

    self:updateSize()
end

function ChicEllaJackPotRespinBarView:updateSize()

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

function ChicEllaJackPotRespinBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end



return ChicEllaJackPotRespinBarView