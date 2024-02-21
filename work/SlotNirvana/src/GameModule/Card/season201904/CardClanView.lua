--[[
    集卡系统  指定卡组中卡片显示面板 数据来源于指定或手动选择的赛季
    201903
--]]
local CardClanView201903 = util_require("GameModule.Card.season201903.CardClanView")
local CardClanView = class("CardClanView", CardClanView201903)

function CardClanView:createCsb()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode(self:getCsbName(), isAutoScale)
end

function CardClanView:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanViewRes, "season201904")
end

function CardClanView:getCellLua()
    return "GameModule.Card.season201904.CardClanCell"
end

function CardClanView:getTitleLua()
    return "GameModule.Card.season201904.CardClanTitle"
end

function CardClanView:initAdapt()
    -- local btnX = self:findChild("Button_x")
    -- local localPos = btnX:getParent():convertToNodeSpace(cc.p(0, display.height-74))
    -- btnX:setPositionY(localPos.y)
end

return CardClanView