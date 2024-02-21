--[[
    author:{author}
    time:2020-09-01 14:56:53
]]
local CardClanView201901 = require("GameModule.Card.season201901.CardClanView")

local CardClanView = class("CardClanView", CardClanView201901)

-- function CardClanView:getPageNum()
--     return 23
-- end

-- 加载标题
function CardClanView:updateTitle(curPage)
    local clanData = self:getClanData(curPage)
    if not clanData then
        return
    end
    self.m_titleNode:removeAllChildren()

    local titleUI = self.m_titleNode:getChildByName("Title201902")
    if not titleUI then
        local showType = self:getShowType(curPage)
        if showType == 1 then
            titleUI = util_createView("GameModule.Card.season201902.CardClanTitle", CardResConfig.CardClanTitle201902WildRes)
        elseif showType == 2 then
            titleUI = util_createView("GameModule.Card.season201901.CardClanTitle", CardResConfig.CardClanTitle201902NormalRes)
        end
        if titleUI then
            titleUI:setName("Title201902")
            self.m_titleNode:addChild(titleUI)
        end
    end

    if titleUI then
        titleUI:updateView(curPage, clanData)
    end
end

return CardClanView
