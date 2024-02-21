local CardDropBox = class("CardDropBox", BaseView)
function CardDropBox:getCsbName()
    return "CardsBase201903/CardRes/season201903/cash201903_drop_box.csb"
end

function CardDropBox:getBoxSize()
    return cc.size(423, 353)
end

function CardDropBox:initCsbNodes()
    self.m_spBox = self:findChild("sp_box")
    self.m_spBoxOpen = self:findChild("kaixiang_2")
    self.m_lbNum = self:findChild("lb_box_num")
end

function CardDropBox:updateUI(_dropType, _num)
    if _dropType == CardSysConfigs.CardDropType.normal then
        util_changeTexture(self.m_spBox, "CardsBase201903/CardRes/Other/Card201903_drop_box_normal.png")
    elseif _dropType == CardSysConfigs.CardDropType.link then
        util_changeTexture(self.m_spBox, "CardsBase201903/CardRes/Other/Card201903_drop_box_nado.png")
    elseif _dropType == CardSysConfigs.CardDropType.obsidian_gold then
        util_changeTexture(self.m_spBox, "CardsBase201903/CardRes/Other/Obsidian_drop_box_gold.png")
        util_changeTexture(self.m_spBoxOpen, "CardsBase201903/CardRes/Other/Obsidian_drop_box_gold_open.png")
    elseif _dropType == CardSysConfigs.CardDropType.obsidian_copper then
        util_changeTexture(self.m_spBox, "CardsBase201903/CardRes/Other/Obsidian_drop_box_copper.png")
        util_changeTexture(self.m_spBoxOpen, "CardsBase201903/CardRes/Other/Obsidian_drop_box_copper_open.png")
    elseif _dropType == CardSysConfigs.CardDropType.obsidian_purple then
        util_changeTexture(self.m_spBox, "CardsBase201903/CardRes/Other/Obsidian_drop_box_purple.png")
        util_changeTexture(self.m_spBoxOpen, "CardsBase201903/CardRes/Other/Obsidian_drop_box_purple_open.png")
    end

    if _num and _num > 1 then
        self.m_lbNum:setVisible(true)
        self.m_lbNum:setString("X" .. _num)
    else
        self.m_lbNum:setVisible(false)
    end
end

function CardDropBox:playStart(overFunc)
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

function CardDropBox:playBreathe()
    self:runCsbAction("breathe", true)
end

function CardDropBox:playOpen(over1, over2)
    self:runCsbAction(
        "open1",
        false,
        function()
            if not tolua.isnull(self) then
                if over1 then
                    over1()
                end
                self:runCsbAction(
                    "open2",
                    false,
                    function()
                        if not tolua.isnull(self) then
                            if over2 then
                                over2()
                            end
                        end
                    end
                )
            end
        end
    )
end

return CardDropBox
