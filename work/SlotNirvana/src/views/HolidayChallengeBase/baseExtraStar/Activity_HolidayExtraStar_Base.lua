--[[
    @desc: 2022超级碗聚合挑战 宣传弹板-额外奖励星星
    time:2022-01-19 16:25:55
]]
local Activity_HolidayExtraStar_Base = class("Activity_HolidayExtraStar_Base", BaseLayer)

function Activity_HolidayExtraStar_Base:ctor()
    Activity_HolidayExtraStar_Base.super.ctor(self)

    self:setLandscapeCsbName(self:getSelfCsbName())
end

function Activity_HolidayExtraStar_Base:getSelfCsbName()
    local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    return  config.RESPATH.HOLIDAY_EXTRASTAR_LAYER
end

function Activity_HolidayExtraStar_Base:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self.m_nodeSpine = self:findChild("node_spine")
    self:startButtonAnimation("btn_start", "sweep", true)
end

function Activity_HolidayExtraStar_Base:onKeyBack()
    -- 手机点击返回按钮也会调用这里
    self:closeUI(function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end)
end

-- 重写父类方法 
function Activity_HolidayExtraStar_Base:onShowedCallFunc( )
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
end

function Activity_HolidayExtraStar_Base:initView()
    self.m_djsLabel = self:findChild("lb_time")
    self:initSpineNode()
    --self:showDownTimer()
end 

function Activity_HolidayExtraStar_Base:initSpineNode()
    --添加纸钞人spine
    if self.m_nodeSpine then
        local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
        if config.RESPATH["SPINE_PATH_EXTRASTAR"] then
            self.m_SpineAct = util_spineCreate(config.RESPATH["SPINE_PATH_EXTRASTAR"], true, true, 1)
            self.m_SpineAct:setScale(1)
            self.m_nodeSpine:addChild(self.m_SpineAct)
            local actName = "idle"
            if config.RESPATH["SPINE_PATH_EXTRASTAR_ACT_NAME_MAIN"]  then
                actName = config.RESPATH["SPINE_PATH_EXTRASTAR_ACT_NAME_MAIN"]
            end
            util_spinePlay(self.m_SpineAct, actName, true)
        end
    end
end

--显示倒计时
function Activity_HolidayExtraStar_Base:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function Activity_HolidayExtraStar_Base:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function Activity_HolidayExtraStar_Base:updateLeftTime()
    local gameData = G_GetMgr(ACTIVITY_REF.ChallengePassExtraStar):getRunningData()
    if gameData ~= nil then
        local leftTime = math.max(gameData:getExpireAt(), 0)
        local strLeftTime = util_daysdemaining(leftTime)
        self.m_djsLabel:setString(strLeftTime)
    else
        self:stopTimerAction()
    end
end

function Activity_HolidayExtraStar_Base:playShowAction()
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
    Activity_HolidayExtraStar_Base.super.playShowAction(self, userDefAction)
end

function Activity_HolidayExtraStar_Base:onEnter()
    Activity_HolidayExtraStar_Base.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.ChallengePassExtraStar then
                self:closeUI(function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function Activity_HolidayExtraStar_Base:onExit()
    self:stopTimerAction()
    Activity_HolidayExtraStar_Base.super.onExit(self)
end

function Activity_HolidayExtraStar_Base:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_start" then
        local callback = function()
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):showMainLayer()
            -- 结束弹板
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
        end
        self:closeUI(callback)
    elseif senderName == "btn_close" then
        self:closeUI(function()
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end)
    end
end

return Activity_HolidayExtraStar_Base
