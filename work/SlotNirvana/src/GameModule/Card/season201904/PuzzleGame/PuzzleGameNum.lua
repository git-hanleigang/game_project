local PuzzleGameNum = class("PuzzleGameNum", util_require("base.BaseView"))
function PuzzleGameNum:initUI()
    self:createCsbNode(CardResConfig.PuzzleGameNumRes)
    self.lb_GemNum = self:findChild("lb_Num")
end

function PuzzleGameNum:updateNum(num)
    self.lb_GemNum:setString(num)
end

return PuzzleGameNum