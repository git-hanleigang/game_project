--[[
    buff提示气泡
]]
local CardStatueBuffTipNode = class("CardStatueBuffTipNode", BaseView)
function CardStatueBuffTipNode:initUI(_num)
    self.m_buffNum = _num
    CardStatueBuffTipNode.super.initUI(self)
    self:initView()
end

function CardStatueBuffTipNode:getCsbName()
    return "BuffTip/CardStatueBuff.csb"
end

function CardStatueBuffTipNode:initCsbNodes()
    self.m_fntNum = self:findChild("chengbei")
end

function CardStatueBuffTipNode:initView()
    local mul = 0
    if self.m_buffNum and self.m_buffNum > 0 then
        mul = self.m_buffNum
    end
    self.m_fntNum:setString("X"..mul)
end

return CardStatueBuffTipNode