--[[--
    说明按钮弹出的气泡
]]
local VipInfoBubble = class("VipInfoBubble", BaseView)

function VipInfoBubble:getCsbName()
    return "VipNew/csd/mainUI/Vip_qipao.csb"
end

function VipInfoBubble:initUI()
    VipInfoBubble.super.initUI(self)
end

function VipInfoBubble:playShow(_over)
    self:runCsbAction("start", false, _over, 60)
end

function VipInfoBubble:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function VipInfoBubble:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

return VipInfoBubble
