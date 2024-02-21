local BeatlesBottomUI = class("BeatlesBottomUI", util_require("views.gameviews.GameBottomNode"))

function BeatlesBottomUI:getSpinUINode( )
    return "CodeBeatlesSrc.BeatlesSpinBtn"
end

return BeatlesBottomUI