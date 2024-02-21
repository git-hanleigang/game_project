--[[
    特殊卡册页签小点
]]
local CardSpecialClanTab = class("CardSpecialClanTab", BaseView)

function CardSpecialClanTab:initDatas(_index)
    self.m_index = _index
end

function CardSpecialClanTab:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/main/MagicClanCheckbox.csb"
end

function CardSpecialClanTab:initCsbNodes()
    self.m_checkbox = self:findChild("CheckBox_1")
    self.m_checkbox:setTouchEnabled(false)
end

function CardSpecialClanTab:updateUI(_pageIndex)
    self.m_checkbox:setSelected(self.m_index == _pageIndex)
end

function CardSpecialClanTab:getTabSize()
    return cc.size(50, 50)
end

return CardSpecialClanTab
