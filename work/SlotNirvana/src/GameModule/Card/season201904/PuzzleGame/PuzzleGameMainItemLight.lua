--[[--
    碎片飞行结束后，在碎片位置播放的特效
]]
local BaseView = util_require("base.BaseView")
local PuzzleGameMainItemLight = class("PuzzleGameMainItemLight", BaseView)
function PuzzleGameMainItemLight:initUI()
    self:createCsbNode(CardResConfig.PuzzleGameMainLightRes)
end

function PuzzleGameMainItemLight:playLight(overFunc)
    self:runCsbAction("start", false, function()
        if overFunc then
            overFunc()
        end
        self:closeUI()
    end)
end

function PuzzleGameMainItemLight:closeUI()
    self:removeFromParent()
end

return PuzzleGameMainItemLight