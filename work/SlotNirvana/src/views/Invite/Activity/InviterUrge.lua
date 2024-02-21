--邀请者
local InviterUrge = class("InviterUrge",BaseLayer)

function InviterUrge:ctor()
    InviterUrge.super.ctor(self)
    self:setLandscapeCsbName("Activity/Guidence.csb")
    self:setExtendData("InviterUrge")
    self.config = G_GetMgr(G_REF.Invite):getConfig()
end

function InviterUrge:initCsbNodes()
    self.btn_close = self:findChild("btn_close")
end

function InviterUrge:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
    self:addClick(self.btn_close)
end


function InviterUrge:closeUI()
    local root = self:findChild("root")
    self:commonHide(
        root,
        function()
            self:removeFromParent(true)
        end
    )
end

function InviterUrge:clickFunc(sender)
	local name = sender:getName()
    if name == "btn_close" then
        --gLobalDataManager:setNumberByField(self.config.GUID,self.num)
        self:closeUI()
    end
end

return InviterUrge