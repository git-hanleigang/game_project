--[[
    手指
]]
local StatueFingerNode = class("StatueFingerNode", BaseView)
function StatueFingerNode:initUI()
    StatueFingerNode.super.initUI(self)
    self:playIdle()
end

function StatueFingerNode:getCsbName()
    return "CardRes/season202102/Statue/Statue_box_zhouzhi.csb"
end

function StatueFingerNode:playIdle()
    self:runCsbAction("actionframe", true)
end

return StatueFingerNode