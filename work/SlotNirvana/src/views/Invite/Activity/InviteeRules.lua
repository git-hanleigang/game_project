local InviteeRules = class("InviteeRules", BaseLayer)

function InviteeRules:ctor()
    InviteeRules.super.ctor(self)
    self:setLandscapeCsbName("Activity/Inviteerules.csb")
end

function InviteeRules:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
end

function InviteeRules:initCsbNodes()
end

function InviteeRules:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return InviteeRules