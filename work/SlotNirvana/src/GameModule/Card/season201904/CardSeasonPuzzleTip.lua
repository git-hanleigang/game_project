--[[--
    小游戏入口提示
]]
local CardSeasonPuzzleTip = class("CardSeasonPuzzleTip", util_require("base.BaseView"))
function CardSeasonPuzzleTip:initUI()
    self:createCsbNode("CardRes/season201904/cash_season_cashpuzzle_qipao.csb")

    self:updateUI()

    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle", false)
            performWithDelay(
                self,
                function()
                    self:runCsbAction(
                        "over",
                        false,
                        function()
                            self:removeFromParent()
                        end
                    )
                end,
                1
            )
        end
    )
end

function CardSeasonPuzzleTip:updateUI()
end

function CardSeasonPuzzleTip:onEnter()
end

function CardSeasonPuzzleTip:onExit()
end

return CardSeasonPuzzleTip
