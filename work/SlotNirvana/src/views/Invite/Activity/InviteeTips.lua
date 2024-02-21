--邀请者
local InviteeTips = class("InviteeTips",BaseLayer)

function InviteeTips:ctor()
    InviteeTips.super.ctor(self)
    self:setLandscapeCsbName("Activity/Inviteexct.csb")
    self:setExtendData("InviteeTips")
    self.config = G_GetMgr(G_REF.Invite):getConfig()
    self.m_data = G_GetMgr(G_REF.Invite):getData()
end

function InviteeTips:initCsbNodes()
    self.btn_close = self:findChild("btn_close")
end

function InviteeTips:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
    self:addClick(self.btn_close)
    self.m_data:setIsFirst(false)
end


function InviteeTips:closeUI()
    local root = self:findChild("root")
    self:commonHide(
        root,
        function()
            self:removeFromParent(true)
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
    )
end

function InviteeTips:clickFunc(sender)
	local name = sender:getName()
    if name == "btnx" then
        self:closeUI()
    elseif name == "btn_spin" then
        self:closeUI()
    end
end

return InviteeTips