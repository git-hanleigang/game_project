
local RespinNode = util_require("Levels.RespinNode")
local LightCherryRespinNode = class("LightCherryRespinNode",RespinNode )


function LightCherryRespinNode:initClipNode(clipNode,opacity)
    RespinNode.initClipNode(self,clipNode,200)
end

return LightCherryRespinNode