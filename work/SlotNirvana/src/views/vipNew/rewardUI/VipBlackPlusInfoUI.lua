--[[
    说明界面
]]
local VipBlackPlusInfoUI = class("VipBlackPlusInfoUI", BaseLayer)
function VipBlackPlusInfoUI:initDatas()
    self:setLandscapeCsbName("VipNew/csd/rewardUI/BlackPlusInfo.csb")
end

function VipBlackPlusInfoUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function VipBlackPlusInfoUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return VipBlackPlusInfoUI
