local TakeOrStakeBottomUI = class("TakeOrStakeBottomUI", util_require("views.gameviews.GameBottomNode"))

function TakeOrStakeBottomUI:getSpinUINode( )
    return "CodeTakeOrStakeSrc.TakeOrStakeSpinBtn"
end

return TakeOrStakeBottomUI