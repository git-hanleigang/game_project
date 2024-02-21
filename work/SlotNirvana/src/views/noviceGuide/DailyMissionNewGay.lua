local DailyMissionNewGay=class("DailyMissionNewGay",util_require("base.BaseView"))
DailyMissionNewGay.info = nil
function DailyMissionNewGay:initUI(func)
    local isAutoScale =true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_DailyMissionUnlock)
    end
    self:createCsbNode("unlockDailyTask/unlockDailyTask.csb",isAutoScale)
    self.m_func = func


    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(root,function()
            self:runCsbAction("idle", true, nil, 60)
        end)
    else
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true, nil, 60)
            -- globalData.slotRunData:checkViewAutoClick(self)
        end, 60)

    end
end

function DailyMissionNewGay:clickFunc(sender)
    local senderName = sender:getName()
     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
     if senderName =="btn_close" then
        if self.m_func then
            self.m_func()
            self.m_func = nil
        end
        self:closeUI()
    elseif senderName == "btn_show" then
          -- 打开每日任务界面
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_DailyQuest)
        end

        self:closeUI(function()
            -- csc 2021-07-06 修改创建 tasklayer 的点位
            gLobalDailyTaskManager:createDailyMissionPassMainLayer()
        end)
    end
end
function DailyMissionNewGay:onEnter()
end
function DailyMissionNewGay:onExit()
   -- gLobalNoticManager:removeAllObservers(self)
end
function DailyMissionNewGay:closeUI(callBack)
    if self.m_close then
        return
    end
    self.m_close= true
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")

    local root = self:findChild("root")
    if root then
        self:commonHide(root,function()
            if callBack then
                callBack()
            end
            self:removeFromParent()
        end)
    else
        self:runCsbAction("over", false, function()
            if callBack then
                callBack()
            end
            self:removeFromParent()
        end, 60)
    end

end
return DailyMissionNewGay