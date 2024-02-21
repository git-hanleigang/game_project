

local ThreeLittlePigsSlotsNode = class("ThreeLittlePigsSlotsNode", util_require("Levels.SlotsNode"))

function ThreeLittlePigsSlotsNode:ctor()
    ThreeLittlePigsSlotsNode.super.ctor(self)
    self.m_icon = nil
    self.m_multiple = nil
end
--添加乘倍
function ThreeLittlePigsSlotsNode:addMultiple(mul)
    self.m_multiple = util_createAnimation("Socre_ThreeLittlePigs_Wild_Xbei.csb")
    if self.m_multiple:findChild("x"..mul) then
        self.m_multiple:findChild("x"..mul):setVisible(true)
    end
    self.m_multiple:setVisible(false)
    self:addChild(self.m_multiple,2)
end
function ThreeLittlePigsSlotsNode:runIdleAnim()
    if self.m_multiple then
        self.m_multiple:setVisible(false)
    end
    ThreeLittlePigsSlotsNode.super.runIdleAnim(self)
end
function ThreeLittlePigsSlotsNode:runLineAnim()
    if self.m_multiple then
        self.m_multiple:setVisible(true)
        self.m_multiple:playAction("actionframe",true)
    end
    ThreeLittlePigsSlotsNode.super.runLineAnim(self)
end

function ThreeLittlePigsSlotsNode:reset()
    if self.m_icon then
        self.m_icon:stopAllActions()
        self.m_icon:removeFromParent()
        self.m_icon = nil
    end
    if self.m_multiple then
        self.m_multiple:stopAllActions()
        self.m_multiple:removeFromParent()
        self.m_multiple = nil
    end
    ThreeLittlePigsSlotsNode.super.reset(self)
end

return ThreeLittlePigsSlotsNode
