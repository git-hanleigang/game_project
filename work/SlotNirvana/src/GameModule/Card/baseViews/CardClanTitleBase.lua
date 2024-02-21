--[[
    卡册标题
    base
]]
local CardClanTitleBase = class("CardClanTitleBase", BaseView)
CardClanTitleBase.m_index = nil
CardClanTitleBase.m_clanData = nil

function CardClanTitleBase:initUI()
    CardClanTitleBase.super.initUI(self)
end

function CardClanTitleBase:initCsbNodes()
    self.m_cardLogo         = self:findChild("card_logo")
    self.m_coinNormal       = self:findChild("Node_show1")
    self.m_coinWild         = self:findChild("Node_show2")
    self.m_coinCompleted    = self:findChild("Node_show3")    
end

function CardClanTitleBase:updateView(index, clanData)
    self.m_index = index
    self.m_clanData = clanData
end

return CardClanTitleBase