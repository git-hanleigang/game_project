
local KoiBlissJackPotBarView = class("KoiBlissJackPotBarView",util_require("base.BaseView"))

local GrandName = "m_lb_coins_1"
local MajorName = "m_lb_coins_2"
local MinorName = "m_lb_coins_3"
local MiniName = "m_lb_coins_4"

function KoiBlissJackPotBarView:initUI()
    self:createCsbNode("KoiBliss_base_jackpotbar.csb")
    self:runCsbAction("idle",true)
end

function KoiBlissJackPotBarView:onExit()
    KoiBlissJackPotBarView.super.onExit(self)
end

function KoiBlissJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function KoiBlissJackPotBarView:onEnter()
    KoiBlissJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function KoiBlissJackPotBarView:updateJackpotInfo()
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

function KoiBlissJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MajorName]
    local label3 = self.m_csbOwner[MinorName]
    local label4 = self.m_csbOwner[MiniName]
    local info1 = {label=label1,sx=0.94,sy=1}
    local info2 = {label=label2,sx=0.94,sy=1}
    local info3 = {label=label3,sx=0.94,sy=1}
    local info4 = {label=label4,sx=0.94,sy=1}
    self:updateLabelSize(info1,299)
    self:updateLabelSize(info2,299)
    self:updateLabelSize(info3,255)
    self:updateLabelSize(info4,255)
end

function KoiBlissJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return KoiBlissJackPotBarView