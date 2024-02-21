--好友规则界面
local FirendRuleLayer = class("FirendRuleLayer", BaseLayer)

function FirendRuleLayer:ctor()
    FirendRuleLayer.super.ctor(self)
    self:setLandscapeCsbName("Friends/csd/Activity_FriendsRule.csb")
end

function FirendRuleLayer:initCsbNodes()
    self.pageview = self:findChild("pageview")
    self.pageview:setTouchEnabled(false)
    self.btn_left = self:findChild("btn_left")
    self.btn_right = self:findChild("btn_right")
end

function FirendRuleLayer:initView()
    self:runCsbAction("idle",true)
    self:updataPoint()
end

function FirendRuleLayer:updataPoint()
    local curPageIndex = self.pageview:getCurrentPageIndex()
    if curPageIndex == 0 or curPageIndex == -1 then
        self.btn_left:setVisible(false)
        self.btn_right:setVisible(true)
    elseif curPageIndex == 1 then
        self.btn_left:setVisible(true)
        self.btn_right:setVisible(false)
    end
end

function FirendRuleLayer:closeUI()
    FirendRuleLayer.super.closeUI(self)
end

function FirendRuleLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local idx = self.pageview:getCurrentPageIndex()
        self.pageview:setCurrentPageIndex(idx-1)
        self:updataPoint()
    elseif name == "btn_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local idx = self.pageview:getCurrentPageIndex()
        if idx == -1 then
            self.pageview:setCurrentPageIndex(1)
        else
            self.pageview:setCurrentPageIndex(idx+1)
        end
        self:updataPoint()
    end
end

return FirendRuleLayer