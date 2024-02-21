---
--xcyy
--2018年5月23日
--GirlsCookRespinNode.lua
local RespinNode = util_require("Levels.RespinNode")
local GirlsCookRespinNode = class("GirlsCookRespinNode",RespinNode)

--获取网络消息
function GirlsCookRespinNode:setRunInfo(runNodeLen, lastNodeType)
    self.m_isGetNetData = true
    self.m_runNodeNum = runNodeLen
    self.m_runLastNodeType = lastNodeType
end

return GirlsCookRespinNode