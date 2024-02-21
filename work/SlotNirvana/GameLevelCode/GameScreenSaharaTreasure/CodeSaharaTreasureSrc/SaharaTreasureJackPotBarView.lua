---
--xcyy
--2018年5月23日
--SaharaTreasureJackPotBarView.lua

local SaharaTreasureJackPotBarView = class("SaharaTreasureJackPotBarView",util_require("base.BaseView"))

local UPDATE_LAB_SIZE_ARRAY = 
{
    {sx = 1, sy = 1, width = 430},
    {sx = 0.9, sy = 0.9, width = 398},
    {sx = 0.8, sy = 0.8, width = 326},
    {sx = 0.8, sy = 0.8, width = 280},
    {sx = 0.8, sy = 0.8, width = 264},
}

function SaharaTreasureJackPotBarView:initUI()

    self:createCsbNode("SaharaTreasure_jackpot.csb")

    self:runCsbAction("idle1")
    self.m_winEffect = util_createAnimation("SaharaTreasure_jackpot_win.csb")
    self:findChild("Node_1"):addChild(self.m_winEffect)
    self.m_winEffect:setVisible(false)
    self.m_winEffect:playAction("actionframe", true)

    self.m_selectEffect = util_createAnimation("SaharaTreasure_jackpot_win_0.csb")
    self:findChild("Node_1"):addChild(self.m_selectEffect)
    self.m_selectEffect:setVisible(false)
    
end



function SaharaTreasureJackPotBarView:onExit()
 
end

function SaharaTreasureJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function SaharaTreasureJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function SaharaTreasureJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    for i = 1, 5, 1 do
        self:changeNode(self:findChild("ml_b_coins"..i), i, true)
    end

    self:updateSize()
end

function SaharaTreasureJackPotBarView:updateSize()

    for i = 1, 5, 1 do
        local label = self.m_csbOwner["ml_b_coins"..i]
        local data = UPDATE_LAB_SIZE_ARRAY[i]
        local info = {label = label ,sx = data.sx, sy = data.sy}
        self:updateLabelSize(info, data.width)
    end
end

function SaharaTreasureJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function SaharaTreasureJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end

function SaharaTreasureJackPotBarView:shwoWinEffect(index)
    if index > 9 then
        index = 9
    end
    self.m_winEffect:setVisible(true)
    local node = self:findChild("win"..index)
    local pos = cc.p(node:getPosition())
    self.m_winEffect:setPosition(pos)
    local scaleX = node:getScaleX()
    self.m_winEffect:setScaleX(scaleX)

    self.m_selectEffect:setVisible(true)
    self.m_selectEffect:playAction("win"..index)
end

function SaharaTreasureJackPotBarView:hideWinEffect()
    self.m_winEffect:setVisible(false)
    self.m_selectEffect:setVisible(false)
end

return SaharaTreasureJackPotBarView