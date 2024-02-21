--说明界面
local CollectRule = class("CollectRule", BaseLayer)

function CollectRule:ctor(_type)
    CollectRule.super.ctor(self)
    self:setExtendData("CollectRule")
    self:setLandscapeCsbName("CollectionLevel/csd/Activity_CollectionLevel_Explain.csb")
end

function CollectRule:initCsbNodes()
end

function CollectRule:initView()
end

function CollectRule:clickStartFunc(sender)
end

function CollectRule:closeUI()
    CollectRule.super.closeUI(self)
end

function CollectRule:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_addnow" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECTLEVEL_CLOSE)
        self:closeUI()
    end
end

return CollectRule