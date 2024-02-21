local LuckyChallengeGuideLayer = class("LuckyChallengeGuideLayer", util_require("base.BaseView"))
LuckyChallengeGuideLayer.info = nil
function LuckyChallengeGuideLayer:initUI(func)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    if globalPlatformManager.sendFireBaseLogDirect then
        globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_DailyMissionUnlock)
    end
    self:createCsbNode("unlockDailyTask/unlockLuckyChallenge.csb", isAutoScale)
    self.m_func = func

    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
                self:runCsbAction("idle", true, nil, 60)
            end
        )
    end
end

function LuckyChallengeGuideLayer:clickFunc(sender)
    local senderName = sender:getName()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
    if senderName == "btn_close" then
        if self.m_func then
            self.m_func()
            self.m_func = nil
        end
        self:closeUI()
    elseif senderName == "btn_show" then
        -- 打开每日任务界面
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        -- if globalPlatformManager.sendFireBaseLogDirect then
        --     globalPlatformManager:sendFireBaseLogDirect(FireBaseLogType.click_DailyQuest)
        -- end

        self:closeUI(
            function()
                G_GetMgr(ACTIVITY_REF.LuckyChallenge):showMainLayer(self.m_func)
            end
        )
    end
end
function LuckyChallengeGuideLayer:onEnter()
end
function LuckyChallengeGuideLayer:onExit()
    -- gLobalNoticManager:removeAllObservers(self)
end
function LuckyChallengeGuideLayer:closeUI(callBack)
    if self.m_close then
        return
    end
    self.m_close = true
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    local root = self:findChild("root")
    if root then
        if callBack then
            callBack()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_LEVELUP_OPEN)
        self:removeFromParent()
    end
end
return LuckyChallengeGuideLayer
