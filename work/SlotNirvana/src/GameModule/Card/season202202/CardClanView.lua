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
    return string.format(CardResConfig.seasonRes.CardClanViewRes, "season202202")
end

function CardClanView:getCellLua()
    return "GameModule.Card.season202202.CardClanCell"
end

function CardClanView:getTitleLua()
    return "GameModule.Card.season202202.CardClanTitle"
end

function CardClanView:getPageNum()
    return 22
end

function CardClanView:initView()
    CardClanView.super.initView(self)

    -- 标题
    local nodeTitle = self:findChild("Node_title")
    local posL = nodeTitle:getParent():convertToNodeSpace(cc.p(0, display.height))
    nodeTitle:setPositionY(posL.y)

    -- 关闭按钮
    local btnX = self:findChild("Button_x")
    btnX:setPositionY(posL.y - 76)
end


return CardClanView