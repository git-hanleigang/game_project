--[[
    @desc: 圣诞节聚合挑战 宣传弹板-付费
    time:2021-12-06 17:10:47
]]
local Activity_HolidayPay_Base = class("Activity_HolidayPay_Base", BaseLayer)

function Activity_HolidayPay_Base:ctor()
    Activity_HolidayPay_Base.super.ctor(self)

    self:setLandscapeCsbName(self:getSelfCsbName())
end

function Activity_HolidayPay_Base:getSelfCsbName()
    local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    return  config.RESPATH.HOLIDAY_PAY_LAYER
end

function Activity_HolidayPay_Base:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self.m_nodeSpine = self:findChild("Node_spine")
    self:startButtonAnimation("btn_start", "sweep", true) 
end

function Activity_HolidayPay_Base:initView()
    self:initSpineNode()
end
function Activity_HolidayPay_Base:initSpineNode()
    if self.m_nodeSpine then
        local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
        if config.RESPATH["SPINE_PATH_PAY"] then
            self.m_SpineAct = util_spineCreate(config.RESPATH["SPINE_PATH_PAY"], true, true, 1)
            self.m_SpineAct:setScale(1)
            self.m_nodeSpine:addChild(self.m_SpineAct)
            util_spinePlay(self.m_SpineAct, "idle", true)
        end
    end
end

function Activity_HolidayPay_Base:onKeyBack()
    -- 手机点击返回按钮也会调用这里
    self:closeUI(function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end)
end

-- 重写父类方法 
function Activity_HolidayPay_Base:onShowedCallFunc( )
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
end

function Activity_HolidayPay_Base:playShowAction()
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
    Activity_HolidayPay_Base.super.playShowAction(self, userDefAction)
end

function Activity_HolidayPay_Base:onEnter()
    Activity_HolidayPay_Base.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.ChallengePassPay then
                self:closeUI(function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function Activity_HolidayPay_Base:onExit()
    Activity_HolidayPay_Base.super.onExit(self)
end

function Activity_HolidayPay_Base:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_start" then
        local callback = function()
            G_GetMgr(ACTIVITY_REF.HolidayChallenge):createPayLayer()
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

return Activity_HolidayPay_Base
