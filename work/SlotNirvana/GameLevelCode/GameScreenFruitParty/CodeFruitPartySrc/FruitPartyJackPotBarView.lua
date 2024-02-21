---
--xcyy
--2018年5月23日
--FruitPartyJackPotBarView.lua

local FruitPartyJackPotBarView = class("FruitPartyJackPotBarView",util_require("base.BaseView"))

function FruitPartyJackPotBarView:initUI(params)

    self.m_machine = params.machine

    self:createCsbNode("FruitParty_jackpot.csb")

    local node_grand = util_createAnimation("FruitParty_jackpot_grand.csb")
    self.m_machine:findChild("Node_jackpot_grand"):addChild(node_grand)
    self.m_node_grand = node_grand

    self.m_lb_minor = self:findChild("m_lb_minor")
    self.m_lb_major = self:findChild("m_lb_major")
    self.m_lb_grand = node_grand:findChild("m_lb_grand")

    self:idleAni( )
end


function FruitPartyJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function FruitPartyJackPotBarView:onExit()
 
end

-- 更新jackpot 数值信息
--
function FruitPartyJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self.m_lb_grand,1,true)
    self:changeNode(self.m_lb_major,2,true)
    self:changeNode(self.m_lb_minor,3,true)

    self:updateSize()
end

function FruitPartyJackPotBarView:updateSize()

    local info1={label=self.m_lb_grand,sx=1,sy=1}
    local info2={label=self.m_lb_major,sx=0.9,sy=0.9}
    local info3={label=self.m_lb_minor,sx=0.7,sy=0.7}
    self:updateLabelSize(info1,335)
    self:updateLabelSize(info2,187)
    self:updateLabelSize(info3,200)
end

function FruitPartyJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function FruitPartyJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end

--[[
    jackpot动画
]]
function FruitPartyJackPotBarView:hitAni(type)
    if type == "minor" then
        self:runCsbAction("actionframe2",true)
        self.m_node_grand:runCsbAction("idle1",true)
    elseif type == "major" then
        self:runCsbAction("actionframe1",true)
        self.m_node_grand:runCsbAction("idle1",true)
    elseif type == "grand" then
        self:runCsbAction("idle1",true)
        self.m_node_grand:runCsbAction("actionframe",true)
    else
        self:idleAni()
    end
end

--[[
    idle动画
]]
function FruitPartyJackPotBarView:idleAni( )
    self:runCsbAction("idle1",true)
    self.m_node_grand:runCsbAction("idle1",true)
end


return FruitPartyJackPotBarView