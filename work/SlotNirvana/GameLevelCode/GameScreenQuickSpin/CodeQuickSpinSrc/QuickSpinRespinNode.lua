

local QuickSpinNode = class("QuickSpinNode",
                                    util_require("Levels.RespinNode"))

function QuickSpinNode:checkRemoveNextNode()
    return true
end

return QuickSpinNode