local FortuneCatsGameBottomNode = class("FortuneCatsGameBottomNode", 
                                    util_require("views.gameviews.GameBottomNode"))


function FortuneCatsGameBottomNode:getSpinUINode( )
    return "CodeFortuneCatsSrc.FortuneCatsSpinBtn"
end

return FortuneCatsGameBottomNode