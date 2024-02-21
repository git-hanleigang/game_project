

local ZeusNode = class("ZeusNode", 
                                    util_require("Levels.RespinNode"))

function ZeusNode:checkRemoveNextNode()
    return true
end

return ZeusNode