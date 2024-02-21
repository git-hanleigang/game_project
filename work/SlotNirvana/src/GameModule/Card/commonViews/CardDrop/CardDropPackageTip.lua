local CardDropPackageTip = class("CardDropPackageTip", BaseView)
function CardDropPackageTip:getCsbName()
    --移动资源到包内
    if globalData.slotRunData.isPortrait then
        return "CardsBase201903/CardRes/season201903/cash_drop_layer_jiantou_shu.csb"
    end
    return "CardsBase201903/CardRes/season201903/cash_drop_layer_jiantou.csb"
    -- return string.format(CardResConfig.seasonRes.CardDropPackageTipRes, "season201903")
end

function CardDropPackageTip:updateIcon(isWildPackage)
    if isWildPackage then
        self:findChild("tapChip"):setVisible(true)
        self:findChild("tapCard"):setVisible(false)
    else
        self:findChild("tapChip"):setVisible(false)
        self:findChild("tapCard"):setVisible(true)
    end
end

function CardDropPackageTip:playStart(overFunc)
    self:runCsbAction(
        "start",
        false,
        function()
            if not tolua.isnull(self) then
                self:runCsbAction("idle", true)
                if overFunc then
                    overFunc()
                end
            end
        end
    )
end

return CardDropPackageTip
