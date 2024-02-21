
local SlotsNode = util_require("Levels.SlotsNode")
local ChilliFiestaSlotNode = class("ChilliFiestaSlotNode",SlotsNode)

-- BitmapFontLabel_1

function ChilliFiestaSlotNode:initSlotNodeByCCBName(ccbName,symbolType)
    SlotsNode.initSlotNodeByCCBName(self,ccbName,symbolType)
    if symbolType == 94 then

    end
end

return ChilliFiestaSlotNode