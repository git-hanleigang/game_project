--
local BaseView = util_require("base.BaseView")
local CardRedPoint = class("CardRedPoint", BaseView)

function CardRedPoint:initUI()
    self:createCsbNode(self:getCsbName())

    self.m_numLB = self:findChild("num")
end

function CardRedPoint:getCsbName()
    return string.format(CardResConfig.seasonRes.CardRedPointRes, "season201903")
end

function CardRedPoint:updateNum(num, hideNum)
    if hideNum == true then
        self.m_numLB:setVisible(false)
    else
        if num and num > 0 then
            self.m_numLB:setVisible(true)
            self.m_numLB:setString(num)
            self:updateLabelSize({label = self.m_numLB, sx = 1, sy = 1}, 31)
        else
            self.m_numLB:setVisible(false)
        end
    end
end

return CardRedPoint
