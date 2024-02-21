local GameBottomNode = util_require("views.gameviews.GameBottomNode") 
local ScratchWinnerGameBottomNode = class("ScratchWinnerGameBottomNode", GameBottomNode)

function ScratchWinnerGameBottomNode:getSpinUINode()
    return "CodeScratchWinnerSrc.ScratchWinnerSpinBtn"
end

return ScratchWinnerGameBottomNode