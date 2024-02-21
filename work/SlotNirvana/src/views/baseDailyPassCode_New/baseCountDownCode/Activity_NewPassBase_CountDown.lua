--[[
    newpass 
    author:csc
    @tips ：csc 优化结构 继承 BaseLayer
]]
local Activity_NewPassBase_CountDown = class("Activity_NewPassBase_CountDown", BaseLayer)

function Activity_NewPassBase_CountDown:ctor()
    Activity_NewPassBase_CountDown.super.ctor(self)

    self:setLandscapeCsbName(self:getCsbName())
end

-- 子类必须重写
function Activity_NewPassBase_CountDown:getCsbName()
    
end

function Activity_NewPassBase_CountDown:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    -- self.m_labDiscount = self:findChild("lb_number")

    self.m_lb_time = self:findChild("lb_time")
    self.m_lb_time2 = self:findChild("lb_time2")

    self.m_node_time1 = self:findChild("node_time1")
    self.m_node_time2 = self:findChild("node_time2")

    self.m_ef_node_lizi = self:findChild("ef_lizi")
    self.m_ef_1 = self:findChild("Particle_1")
    self.m_ef_2= self:findChild("ef_jingbi")

    self:startButtonAnimation("btn_start", "breathe")
end

function Activity_NewPassBase_CountDown:initView()
    -- 计算倒计时
    local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if passActData then
        self:updateLeftTimeUI()
        self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTimeUI), 1)
    end
end

function Activity_NewPassBase_CountDown:updateLeftTimeUI()
    local passActData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if passActData then
        local expireAt = passActData:getExpireAt()
        local leftTime = math.max(expireAt, 0)
        local timeStr, isOver ,isFullDay = util_daysdemaining(leftTime,true)
        if isFullDay then
            if not  self.m_node_time1:isVisible() then
                self.m_node_time1:setVisible(true)
            end
            if  self.m_node_time2:isVisible() then
                self.m_node_time2:setVisible(false)
            end
            self.m_lb_time2:setString(timeStr)
        else
            if not  self.m_node_time2:isVisible() then
                self.m_node_time2:setVisible(true)
            end
            if  self.m_node_time1:isVisible() then
                self.m_node_time1:setVisible(false)
            end
            self.m_lb_time:setString(timeStr)
        end
    end
end

function Activity_NewPassBase_CountDown:onKeyBack()
    if DEBUG == 2 then
        self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        )
    end
end

function Activity_NewPassBase_CountDown:onShowedCallFunc()
    self:runCsbAction("idle",true,nil,60)
end

function Activity_NewPassBase_CountDown:onEnter()
    Activity_NewPassBase_CountDown.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.NewPassCountDown then
                local callback = function()
                    -- 下一个弹板
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end
                self:closeUI(callback)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function Activity_NewPassBase_CountDown:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_start" then
        local callback = function()
            gLobalDailyTaskManager:createDailyMissionPassMainLayer()
            -- 结束弹板
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        end
        self:closeUI(callback)
    elseif senderName == "btn_close" then
        local callback = function()
            -- 下一个弹板
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end
        self:closeUI(callback)
    end
end
function Activity_NewPassBase_CountDown:onExit()
    gLobalNoticManager:removeAllObservers(self)
    self:clearScheduler()
    Activity_NewPassBase_CountDown.super.onExit(self)
end

function Activity_NewPassBase_CountDown:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
    end
end

function Activity_NewPassBase_CountDown:closeUI(callbackFunc)
    if self.m_ef_node_lizi then
        self.m_ef_node_lizi:setVisible(false)
    end
    if self.m_ef_1 then
        self.m_ef_1:setVisible(false)
    end

    if self.m_ef_2 then
        self.m_ef_2:setVisible(false)
    end
    
    Activity_NewPassBase_CountDown.super.closeUI(self, callbackFunc)
end

function Activity_NewPassBase_CountDown:playShowAction()
    local themeName = G_GetMgr(ACTIVITY_REF.NewPass):getThemeName()
    if themeName == ACTIVITY_REF.NewPass or themeName == "Activity_NewPassHalloween2023" or themeName == "Activity_NewPassValentine" then
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        Activity_NewPassBase_CountDown.super.playShowAction(self, "start")
    else
        Activity_NewPassBase_CountDown.super.playShowAction(self, nil)
    end
end

return Activity_NewPassBase_CountDown
