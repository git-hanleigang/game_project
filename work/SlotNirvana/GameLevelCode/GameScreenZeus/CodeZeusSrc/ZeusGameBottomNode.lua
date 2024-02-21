---
--xcyy
--2018年5月23日
--ZeusGameBottomNode.lua

local ZeusGameBottomNode = class("ZeusGameBottomNode",util_require("views.gameviews.GameBottomNode"))

function ZeusGameBottomNode:getSpinUINode( )
    return "CodeZeusSrc.ZeusSpinBtn"
end

return ZeusGameBottomNode