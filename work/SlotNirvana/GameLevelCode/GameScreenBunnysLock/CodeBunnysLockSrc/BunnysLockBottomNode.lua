---
--xcyy
--2018年5月23日
--BunnysLockBottomNode.lua

local BunnysLockBottomNode = class("BunnysLockBottomNode",util_require("views.gameviews.GameBottomNode"))

function BunnysLockBottomNode:getSpinUINode()
    return "CodeBunnysLockSrc.BunnysLockSpinBtn"
end


return BunnysLockBottomNode
