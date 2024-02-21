local InviteLevel = class("InviteLevel", BaseLayer)

function InviteLevel:ctor()
    InviteLevel.super.ctor(self)
    local path = "Activity/LeveUp_Node.csb"
    self:setLandscapeCsbName(path)
    self:setExtendData("InviteLevel")
end

function InviteLevel:initCsbNodes()
end

function InviteLevel:initView()
end

function InviteLevel:clickFunc(sender)
    local btnName = sender:getName()
    if btnName == "btn_x" then
        self:closeUI()
    elseif btnName == "btn_spin" then
        self:closeUI()
    end
end

function InviteLevel:closeUI()
    local root = self:findChild("root")
    self:commonHide(
        root,
        function()
            self:removeFromParent(true)
        end
    )
end
return InviteLevel
