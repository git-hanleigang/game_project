--版本更新
local NewVersionNode = class("NewVersionNode", util_require("base.BaseView"))
NewVersionNode.SHOW_START = 1
NewVersionNode.SHOW_IDLE = 2
NewVersionNode.HIDE_START = 3
NewVersionNode.HIDE_IDLE = 4
NewVersionNode.m_status = nil
function NewVersionNode:initUI()
    self:createCsbNode("NewVersion/NewVersionNode.csb")
    self.m_touchLayer  = util_newMaskLayer()
    self:addChild(self.m_touchLayer,-1)
    self.m_touchLayer:setVisible(false)
    self.m_touchLayer:onTouch( function(event)
        --屏蔽强更
        if globalData.isForceUpgrade then
            return true
        end
        --隐藏不监听
        if self.m_status == self.HIDE_IDLE then
            return false
        end
        --如果正在显示隐藏
        if self.m_status == self.SHOW_IDLE then
            if event.name == "ended" then
                self:hide()
            end
        end
        return true 
    end, false, true)
    self:start()
end

function NewVersionNode:onEnter()
    local newPos = self:convertToNodeSpace(cc.p(0,0))
    self.m_touchLayer:setPosition(newPos)
    gLobalNoticManager:addObserver(self,function()
        if self.show then
            self:show()
        end
    end, ViewEventType.NOTIFY_NEWVERSION_SHOW)
    gLobalNoticManager:addObserver(self,function()
        if self.hide then
            self:hide()
        end
    end, ViewEventType.NOTIFY_NEWVERSION_HIDE)
end

function NewVersionNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function NewVersionNode:clickFunc(sender)
    local sBtnName = sender:getName()
    if sBtnName == "btn_update"  then
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen","update")
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        xcyy.GameBridgeLua:rateUsForSetting()
    end
end

function NewVersionNode:start()
    self.m_status = self.HIDE_IDLE
    self:hideLoop()
end

function NewVersionNode:show()
    if self.m_status == self.SHOW_START then
        return
    end
    self.m_status = self.SHOW_START
    self.m_touchLayer:setVisible(true)
    self:runCsbAction("changeS",false,function()
        self.m_status = self.SHOW_IDLE
        self:runCsbAction("Sidle",true)
    end,60)
end

function NewVersionNode:hide()
    if globalData.isForceUpgrade then
        return
    end
    if self.m_status == self.HIDE_START then
        return
    end
    self.m_status = self.HIDE_START
    self:runCsbAction("changeH",false,function()
        self.m_status = self.HIDE_IDLE
        self.m_touchLayer:setVisible(false)
        self:hideLoop()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)--弹窗逻辑执行下一个事件
    end,60)
end

function NewVersionNode:hideLoop()
    if self.m_status ~= self.HIDE_IDLE then
        return
    end
    self:runCsbAction("Hidle")
    performWithDelay(self,function()
        self:hideLoop()
    end,3)
end

return NewVersionNode