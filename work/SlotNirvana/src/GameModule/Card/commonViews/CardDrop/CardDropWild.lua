local CardDropWild = class("CardDropWild", BaseView)
function CardDropWild:getCsbName()
    --移动资源到包内
    return "CardsBase201903/CardRes/season201903/cash201903_drop_wild.csb"
    -- return string.format(CardResConfig.seasonRes.CardDropWildRes, "season201903")
end

function CardDropWild:getBoxSize()
    return cc.size(423, 353)
end

function CardDropWild:initCsbNodes()
    self.m_spWild = self:findChild("sp_wild")
end

function CardDropWild:playStart(overFunc)
    self:runCsbAction(
        "show",
        false,
        function()
            if not tolua.isnull(self) then
                if overFunc then
                    overFunc()
                end
                self:runCsbAction("idle", true)
            end
        end
    )
end

function CardDropWild:playBreathe()
    self:runCsbAction("breathe", true)
end

function CardDropWild:updateUI(dropType)
    -- 根据wild卡的类型显示不同的wild卡图片
    local path = "CardsBase201903/CardRes/season201903/Other/drop_" .. dropType .. ".png"
    if util_IsFileExist(path) then
        util_changeTexture(self.m_spWild, path)
    end
end

return CardDropWild
