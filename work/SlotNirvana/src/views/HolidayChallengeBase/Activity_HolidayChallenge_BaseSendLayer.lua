--[[
    感恩节聚合挑战 登录弹板
    author:csc
    time:2021-11-10 17:52:06
]]
local Activity_HolidayChallenge_BaseSendLayer = class("Activity_HolidayChallenge_BaseSendLayer", BaseLayer)

function Activity_HolidayChallenge_BaseSendLayer:ctor()
    Activity_HolidayChallenge_BaseSendLayer.super.ctor(self)
end

function Activity_HolidayChallenge_BaseSendLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.MAINSENDER_LAYER)
end

function Activity_HolidayChallenge_BaseSendLayer:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self:startButtonAnimation("btn_go", "sweep", true) 
    self.m_djsLabel = self:findChild("lb_time")
    self.m_spineNode = self:findChild("node_spine")
    self.m_lb_des = self:findChild("lb_des")
    self.lb_des_1 = self:findChild("lb_des_1")

    local key = "" .. G_GetMgr(ACTIVITY_REF.HolidayChallenge):getThemeName() .."SendLayer:btn_go"
    local lbString = gLobalLanguageChangeManager:getStringByKey(key) ~= "" and gLobalLanguageChangeManager:getStringByKey(key) or "CAN'T WAIT"
    self:setButtonLabelContent("btn_go", lbString)
end

function Activity_HolidayChallenge_BaseSendLayer:initUI()
    Activity_HolidayChallenge_BaseSendLayer.super.initUI(self)
end

function Activity_HolidayChallenge_BaseSendLayer:initView()
    self:initSpine()
    if  self.m_activityConfig.ROAD_CONFIG["SENDLAYER_USETIME"] then
        self:showDownTimer()
    end
end 

function Activity_HolidayChallenge_BaseSendLayer:initSpine()
    if self.m_activityConfig.RESPATH["SPINE_PATH_SENDLAYER"] then
        self.m_SpineAct = util_spineCreate(self.m_activityConfig.RESPATH["SPINE_PATH_SENDLAYER"], true, true, 1)
        self.m_SpineAct:setScale(1)
        self.m_spineNode:addChild(self.m_SpineAct)
    end
end

--显示倒计时
function Activity_HolidayChallenge_BaseSendLayer:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function Activity_HolidayChallenge_BaseSendLayer:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function Activity_HolidayChallenge_BaseSendLayer:updateLeftTime()
    local gameData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if gameData ~= nil then
        local leftTime = math.max(gameData:getExpireAt(), 0)
        local strLeftTime,isOver,isFullDay = util_daysdemaining(leftTime,true)
        self.m_djsLabel:setString(strLeftTime)
        if self.m_lb_des then
            if isFullDay then
                if self.m_lb_des:isVisible() then
                    self.m_lb_des:setVisible(false)
                end
                if not self.lb_des_1:isVisible() then
                    self.lb_des_1:setVisible(true)
                end
            else
                if not self.m_lb_des:isVisible() then
                    self.m_lb_des:setVisible(true)
                end
                if  self.lb_des_1:isVisible() then
                    self.lb_des_1:setVisible(false)
                end
            end
        end
    else
        self:stopTimerAction()
    end
end

function Activity_HolidayChallenge_BaseSendLayer:onKeyBack()
    -- 手机点击返回按钮也会调用这里
    self:closeUI(function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end)
end

-- 重写父类方法 
function Activity_HolidayChallenge_BaseSendLayer:onShowedCallFunc( )
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
    if self.m_SpineAct then
        local actName = "idle"
        if self.m_activityConfig.RESPATH["SPINE_PATH_SENDLAYER_ACT_NAME_MAIN"] then
            actName = self.m_activityConfig.RESPATH["SPINE_PATH_SENDLAYER_ACT_NAME_MAIN"]
        end
        util_spinePlay(self.m_SpineAct, actName, true)
    end
end

function Activity_HolidayChallenge_BaseSendLayer:playShowAction()
    if self.m_SpineAct and self.m_activityConfig.RESPATH["SPINE_PATH_SENDLAYER_ACT_NAME_START"] then
        local sound = self.m_activityConfig.RESPATH["SEND_LAYER_START_MP3"]
        if sound then
            gLobalSoundManager:playSound(sound)
        end
        local actName = self.m_activityConfig.RESPATH["SPINE_PATH_SENDLAYER_ACT_NAME_START"]
        util_spinePlay(self.m_SpineAct, actName, false)
    end

    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    Activity_HolidayChallenge_BaseSendLayer.super.playShowAction(self, userDefAction)
end

function Activity_HolidayChallenge_BaseSendLayer:onEnter()
    Activity_HolidayChallenge_BaseSendLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:closeUI(function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function Activity_HolidayChallenge_BaseSendLayer:onExit()
    self:stopTimerAction()
    Activity_HolidayChallenge_BaseSendLayer.super.onExit(self)
end

function Activity_HolidayChallenge_BaseSendLayer:clickFunc(sender)
    if self.m_isIncAction then
        return
    end
    self.m_isIncAction = true

    local name = sender:getName()

    if name == "btn_go" then
        local callback = function (  )
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
        end
        self:closeUI(callback)
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    elseif name == "btn_close" then
        self:closeUI(function (  )
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        )
    end
end

return Activity_HolidayChallenge_BaseSendLayer
