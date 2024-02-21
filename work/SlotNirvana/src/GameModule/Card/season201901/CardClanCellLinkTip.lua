--[[--
    卡组中link小游戏标记
    如果关闭link进入界面后，在link卡上要添加一个link小游戏的标记
]]
local CardClanCellLinkTip = class(CardClanCellLinkTip, util_require("base.BaseView"))
function CardClanCellLinkTip:initUI()
    self:createCsbNode(CardResConfig.CardClanCellLinkTipRes)
end
return CardClanCellLinkTip