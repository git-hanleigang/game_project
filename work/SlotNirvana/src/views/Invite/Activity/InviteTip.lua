-- 分享奖励
local InviteTip = class("InviteTip", BaseLayer)

function InviteTip:ctor()
    InviteTip.super.ctor(self)
    local path = "Activity/systempopup.csb"
    self:setLandscapeCsbName(path)
    self:setExtendData("InviteTip")
    self.config = G_GetMgr(G_REF.Invite):getConfig()
end

function InviteTip:initUI()
    InviteTip.super.initUI(self)
end

function InviteTip:initCsbNodes()
    self.lb_text1 = self:findChild("lb_text1")
end

function InviteTip:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
    self.lb_text1:setString("Your level is over "..globalData.constantData.INVITE_LEVEL.." so you can't be invited.")
    local label = self:findChild("label_1")
    label:setScale(0.85)
end

function InviteTip:registerListener()
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function()
    --         G_GetMgr(G_REF.Invite):showInviterLayer()
    --     end,
    --     self.config.EVENT_NAME.INVITEE_UPDATA_PAY
    -- )
end

function InviteTip:clickFunc(sender)
    local btnName = sender:getName()
    if btnName == "btn_x" then
        self:closeUI()
    elseif btnName == "btn_spin" then
        G_GetMgr(G_REF.Invite):showInviterLayer()
    end
end

function InviteTip:closeUI()
    local root = self:findChild("root")
    self:commonHide(
        root,
        function()
            self:removeFromParent(true)
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
    )
end
return InviteTip
