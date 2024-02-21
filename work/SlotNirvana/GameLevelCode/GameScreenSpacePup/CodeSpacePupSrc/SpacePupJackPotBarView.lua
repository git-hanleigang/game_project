---
--xcyy
--2018年5月23日
--SpacePupJackPotBarView.lua

local SpacePupJackPotBarView = class("SpacePupJackPotBarView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_NAME = {"m_lb_grand", "m_lb_mega", "m_lb_major", "m_lb_minor", "m_lb_mini"}

function SpacePupJackPotBarView:initUI(params)

    self.m_index = params.pot_index
    self:createCsbNode(params.csbName)

    self:runCsbAction("idle",true)

    local lightNodeAni = util_createAnimation("SpacePup_jackpot_sg.csb")
    self:findChild("sg"):addChild(lightNodeAni)
    lightNodeAni:runCsbAction("idle", true)

end

function SpacePupJackPotBarView:onEnter()

    SpacePupJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function SpacePupJackPotBarView:onExit()
    SpacePupJackPotBarView.super.onExit(self)
end

function SpacePupJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function SpacePupJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(JACKPOT_NAME[self.m_index]),self.m_index,true)

    self:updateSize()
end

function SpacePupJackPotBarView:updateSize()

    local jackpotText = JACKPOT_NAME[self.m_index]
    local label1=self.m_csbOwner[jackpotText]

    local info1={label=label1,sx=0.8,sy=0.8}

    self:updateLabelSize(info1,203)
end

function SpacePupJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return SpacePupJackPotBarView
