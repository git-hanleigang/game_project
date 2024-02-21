--宣传弹板
local Activity_Invite = class("Activity_Invite",BaseLayer)

function Activity_Invite:ctor()
    Activity_Invite.super.ctor(self)
    self:setLandscapeCsbName("Activity/invitexct.csb")
    self.m_data = G_GetMgr(G_REF.Invite):getData()
    self.m_Mr = G_GetMgr(G_REF.Invite)
    self:setExtendData("Activity_Invite")
end

function Activity_Invite:initCsbNodes()
    self.m_btnClose = self:findChild("btnx")
end

function Activity_Invite:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, _index)
            if self.click then
                self.m_Mr:showInviterLayer("btn_pop")
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_INVITE_MAIN
    )
end
function Activity_Invite:initView()
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true, nil)
        end,
        60
    )

end

function Activity_Invite:closeUI(isNotify)
    if self.isClose then
        return
    end
    self.isClose = true
    local callFunc = function()
        self:removeFromParent()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end
    self:commonHide(
        self:findChild("root"),
        function()
            callFunc()
        end
    )
end

function Activity_Invite:clickFunc(sender)
    local name = sender:getName()
    if name == "btnx" then
        --关掉继续下一个
        self:closeUI()
    elseif name == "btn_invite" then
        --spin
        self.click = true
        self.m_Mr:sendDataReq()
        self:closeUI()
    end
end



return Activity_Invite