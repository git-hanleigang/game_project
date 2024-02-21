---
--smy
--2018年4月17日
--JackPotTitleLayer.lua
local PoseidonJackPotLayer = class("FreeSpinBar", util_require("base.BaseView"))
PoseidonJackPotLayer.m_jackPotMaxNum = 4
PoseidonJackPotLayer.m_animaNodes = {}

function PoseidonJackPotLayer:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Poseidon_JackPot_UI.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe")
    self.m_animaNodes = {}
end

function PoseidonJackPotLayer:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self:findChild("m_lb_poseidon"),1,true)
    self:changeNode(self:findChild("m_lb_grand"),2,true)
    self:changeNode(self:findChild("m_lb_major"),3,true)
    self:changeNode(self:findChild("m_lb_minor"),4,false)
    self:changeNode(self:findChild("m_lb_mini"),5,false)
    -- self:updateSize()

    self:updateLabelSize({label=self:findChild("m_lb_poseidon"),sx=1.4,sy=1.4},225)
    self:updateLabelSize({label=self:findChild("m_lb_grand"),sx=1,sy=1},175)
    self:updateLabelSize({label=self:findChild("m_lb_major"),sx=1,sy=1},175)
    self:updateLabelSize({label=self:findChild("m_lb_minor"),sx=0.9,sy=0.9},170)
    self:updateLabelSize({label=self:findChild("m_lb_mini"),sx=0.9,sy=0.9},170)

end

function PoseidonJackPotLayer:playJpAnima(type)

        if type == "mini" then
        local node =  util_createAnimation("Poseidon_JackPot_UI_rim.csb")
        node:playAction("actionframe2",true)
        self:findChild("Node_mini"):addChild(node)
        self.m_animaNodes[#self.m_animaNodes + 1] = node
    elseif type == "minor" then
        local node =  util_createAnimation("Poseidon_JackPot_UI_rim.csb")
        node:playAction("actionframe2",true)
        self:findChild("Node_minor"):addChild(node)
        self.m_animaNodes[#self.m_animaNodes + 1] = node
    elseif type == "major" then
        local node =  util_createAnimation("Poseidon_JackPot_UI_rim.csb")
        node:playAction("actionframe1",true)
        self:findChild("Node_major"):addChild(node)
        self.m_animaNodes[#self.m_animaNodes + 1] = node
    elseif type == "mega" then
        local node =  util_createAnimation("Poseidon_JackPot_UI_rim.csb")
        node:playAction("actionframe1",true)
        self:findChild("Node_grand"):addChild(node)
        self.m_animaNodes[#self.m_animaNodes + 1] = node
    elseif type == "grand" then
        local node =  util_createAnimation("Poseidon_JackPot_UI_rim.csb")
        node:playAction("actionframe",true)
        self:findChild("Node_poseidon"):addChild(node)
        self.m_animaNodes[#self.m_animaNodes + 1] = node
    end
end

function PoseidonJackPotLayer:clearAnimaNode()
    for i=1,#self.m_animaNodes do
        local node = self.m_animaNodes[i]
        node:removeFromParent()
    end
    self.m_animaNodes = {}
end

--jackpot算法
function PoseidonJackPotLayer:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))

end

function PoseidonJackPotLayer:onEnter()
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

return PoseidonJackPotLayer