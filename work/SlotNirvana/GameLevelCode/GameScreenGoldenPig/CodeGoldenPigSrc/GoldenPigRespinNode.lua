
local RespinNode = util_require("Levels.RespinNode")
local GoldenPigRespinNode = class("GoldenPigRespinNode",RespinNode)

function GoldenPigRespinNode:initClipNode(clipNode,opacity)
    RespinNode.initClipNode(self,clipNode,200)
end

return GoldenPigRespinNode