local InviterRules = class("InviterRules", BaseLayer)


function InviterRules:ctor()
    InviterRules.super.ctor(self)
    self:setLandscapeCsbName("Activity/Inviterrules.csb")
end

function InviterRules:initCsbNodes()
    self.page_view = self:findChild("PageView")
    self.btn_next = self:findChild("btn_next")
    self.btn_pre = self:findChild("btn_pre")
    self.btn_pre:setVisible(false)
end

function InviterRules:initView()
    self:runCsbAction(
        "idle",
        true,
        function()
        end,
        120
    )
end

function InviterRules:clickFunc(sender)
    local name = sender:getName()
    if name == "btnx" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeUI()
    elseif name == "btn_next" then
        --zuo
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local idx = self.page_view:getCurrentPageIndex()
        if idx == -1 or idx == 0 then
            self.page_view:setCurrentPageIndex(1)
        end
        self.btn_pre:setVisible(true)
        self.btn_next:setVisible(false)
    elseif name == "btn_pre" then
        --you
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local idx = self.page_view:getCurrentPageIndex()
        if idx == 1 then
            self.page_view:setCurrentPageIndex(0)
        end
        self.btn_pre:setVisible(false)
        self.btn_next:setVisible(true)
    end
end

return InviterRules