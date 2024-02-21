local CashOrConkJackPotBarView = class("CashOrConkJackPotBarView", util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

function CashOrConkJackPotBarView:initUI(data)
    self:createCsbNode("CashOrConk_jackpot_sanxuanyi.csb")

    for i,v in ipairs({"grand","mega","major","minor","mini"}) do
        local anim = util_createAnimation("CashOrConk_jackpot_tx.csb")
        self:findChild("Node_idle_"..v):addChild(anim)
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.5*i),
            cc.CallFunc:create(function()
                anim:playAction("idle",true)
            end)
        ))
    end
end

function CashOrConkJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function CashOrConkJackPotBarView:onEnter()
    CashOrConkJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

function CashOrConkJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data = self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MegaName), 2, true)
    self:changeNode(self:findChild(MajorName), 3, true)
    self:changeNode(self:findChild(MinorName), 4)
    self:changeNode(self:findChild(MiniName), 5)

    self:updateSize()
end

function CashOrConkJackPotBarView:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.66,sy = 0.66}
    local info2 = {label = label2, sx = 0.66,sy = 0.66}
    local info3 = {label = label3, sx = 0.66,sy = 0.66}
    local info4 = {label = label4, sx = 0.66,sy = 0.66}
    local info5 = {label = label5, sx = 0.66,sy = 0.66}

    self:updateLabelSize(info1, 364)
    self:updateLabelSize(info2, 364)
    self:updateLabelSize(info3, 364)
    self:updateLabelSize(info4, 364)
    self:updateLabelSize(info5, 364)
end

function CashOrConkJackPotBarView:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value, 12, nil, nil, true))
end

return CashOrConkJackPotBarView