

local FarmNode = class("FarmNode", 
                                    util_require("Levels.RespinNode"))
--最后一个小块是否提前移除
function FarmNode:checkRemoveNextNode()
    return true
end
return FarmNode