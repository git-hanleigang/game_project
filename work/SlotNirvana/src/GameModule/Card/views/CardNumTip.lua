--[[
    卡牌右下角的提示
    在wild卡册中的提示中用时创建的
]]
local BaseView = util_require("base.BaseView")
local CardNumTip = class("CardNumTip", BaseView)
function CardNumTip:initUI()
    self:createCsbNode(CardResConfig.CardNumTipRes)
    self.m_tishi = self:findChild("tishi_1")
    self.m_num = self:findChild("num")
end

function CardNumTip:updateNum(cardData)
    self.m_cardData = cardData
    local str,x = self:getShowStr()
    if str == "" then
        self.m_tishi:setVisible(false)
    else
        self.m_tishi:setVisible(true)
        self.m_num:setString(str)
        if x then
            self.m_num:setPositionX(x)
        end
    end
end

function CardNumTip:getShowStr()
    if not self.m_cardData then
        return ""
    end
    if self.m_cardData.firstDrop == true then
        return "new", 30
    end
    if self.m_cardData.count > 1 then
        return "+"..(self.m_cardData.count-1), 28
    end
    return ""
end

return CardNumTip