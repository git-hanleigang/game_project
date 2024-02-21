--全部领取完成
local InvitaRewardAll = class("InvitaRewardAll",BaseLayer)

function InvitaRewardAll:ctor()
    InvitaRewardAll.super.ctor(self)
    self:setLandscapeCsbName("Activity/jilipopup.csb")
    self:setExtendData("InvitaRewardAll")
end

function InvitaRewardAll:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
end

function InvitaRewardAll:closeUI()
    local root = self:findChild("root")
    self:commonHide(
        root,
        function()
            self:removeFromParent(true)
        end
    )
end

function InvitaRewardAll:clickFunc(sender)
    self:closeUI()
end

return InvitaRewardAll