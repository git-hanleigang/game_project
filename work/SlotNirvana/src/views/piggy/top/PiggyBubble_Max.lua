local BasePiggyBubble = util_require("views.piggy.top.BasePiggyBubble")
local PiggyBubble_Max = class("PiggyBubble_Max", BasePiggyBubble)

function PiggyBubble_Max:initDatas()
    self:setName("PiggyBubble_Max")
end

function PiggyBubble_Max:getCsbName()
    if globalData.slotRunData.isMachinePortrait then
        return "GameNode/Piggy_MaxTip_Portrait.csb"
    end
    return "GameNode/Piggy_MaxTip.csb"
end

return PiggyBubble_Max
