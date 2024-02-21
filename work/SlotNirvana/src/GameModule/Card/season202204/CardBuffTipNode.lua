--[[
    buff提示气泡
]]
local CardBuffTipNode = class("CardBuffTipNode", BaseView)
function CardBuffTipNode:initUI(_num)
    self.m_buffNum = _num
    CardBuffTipNode.super.initUI(self)
    self:initView()
end

function CardBuffTipNode:getCsbName()
    return "CardRes/season202204/cash_coin_buff.csb"
end

function CardBuffTipNode:initCsbNodes()
    self.m_fntNum = self:findChild("chengbei")
end

function CardBuffTipNode:initView()
    local mul = 0
    if self.m_buffNum and self.m_buffNum > 0 then
        mul = self.m_buffNum * 100
    end
    self.m_fntNum:setString("" .. mul .. "%")
end

return CardBuffTipNode
