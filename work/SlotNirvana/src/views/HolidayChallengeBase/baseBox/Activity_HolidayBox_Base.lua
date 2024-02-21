--[[
    @desc: 圣诞节聚合挑战 宣传弹板-付费
    time:2021-12-06 17:10:47
]]
local Activity_HolidayBox_Base = class("Activity_HolidayBox_Base", BaseLayer)

function Activity_HolidayBox_Base:ctor()
    Activity_HolidayBox_Base.super.ctor(self)

    self:setLandscapeCsbName(self:getSelfCsbName())
end

function Activity_HolidayBox_Base:getSelfCsbName()
    local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    return  config.RESPATH.HOLIDAY_BOX_LAYER
end

function Activity_HolidayBox_Base:initUI()
    Activity_HolidayBox_Base.super.initUI(self)
end

function Activity_HolidayBox_Base:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    self.m_nodeSpine = self:findChild("node_spine")
    self:startButtonAnimation("btn_start", "sweep", true) 
    self.m_lizi = self:findChild("node_lizi")
    self.m_lizi_1 = self:findChild("node_lizi1")
end

function Activity_HolidayBox_Base:onKeyBack()
    -- 手机点击返回按钮也会调用这里
    self:closeUI(function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end)
end
function Activity_HolidayBox_Base:initView()
    self:initSpineNode()
end
function Activity_HolidayBox_Base:initSpineNode()
    if self.m_nodeSpine then
        local config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
        if config.RESPATH["SPINE_PATH_BOX"] then
            self.m_SpineAct = util_spineCreate(config.RESPATH["SPINE_PATH_BOX"], true, true, 1)
            self.m_SpineAct:setScale(1)
            self.m_nodeSpine:addChild(self.m_SpineAct)
            util_spinePlay(self.m_SpineAct, "idle", true)
        end
    end
end
-- 重写父类方法 
function Activity_HolidayBox_Base:onShowedCallFunc( )
    -- 展开动画
    self:runCsbAction("idle", true, nil, 60)
end

function Activity_HolidayBox_Base:onEnter()
    Activity_HolidayBox_Base.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.ChallengePassBox then
                self:closeUI(function()
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                end)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function Activity_HolidayBox_Base:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_start" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local callback = function()
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

function Activity_HolidayBox_Base:playShowAction()
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
    Activity_HolidayBox_Base.super.playShowAction(self, userDefAction)
end

function Activity_HolidayBox_Base:closeUI(callbackFunc)
    if self.m_lizi then
        self.m_lizi:setVisible(false)
    end
    if self.m_lizi_1 then
        self.m_lizi_1:setVisible(false)
    end
    Activity_HolidayBox_Base.super.closeUI(self, callbackFunc)
end

return Activity_HolidayBox_Base
