local CardDropStatue = class("CardDropStatue", BaseView)
function CardDropStatue:getCsbName()
    --移动资源到包内
    return "CardsBase201903/CardRes/season201903/cash201903_drop_statue.csb"
    -- return string.format(CardResConfig.seasonRes.CardDropStatueRes, "season201903")
end

function CardDropStatue:getBoxSize()
    return cc.size(423, 353)
end

function CardDropStatue:playStart(overFunc)
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

function CardDropStatue:playBreathe()
    self:runCsbAction("breathe", true)
end

function CardDropStatue:playOpen(over1, over2)
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

function CardDropStatue:updateUI(dropType)
end

return CardDropStatue
