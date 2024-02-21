

local ChineseStyleNode = class("ChineseStyleNode", 
                                    util_require("Levels.RespinNode"))

function ChineseStyleNode:checkRemoveNextNode()
    return true
end
return ChineseStyleNode