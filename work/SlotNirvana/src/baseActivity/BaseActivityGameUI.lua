local BaseActivityRotateUI = util_require("baseActivity.BaseActivityRotateUI")
local BaseActivityGameUI = class("BaseActivityGameUI", BaseActivityRotateUI)

function BaseActivityGameUI:ctor()
    BaseActivityRotateUI.ctor(self)
    self.bgNodeMap = {}
end
--是否是登录推送弹窗
function BaseActivityGameUI:setPushView(flag)
    self.isPushView = flag
end

function BaseActivityGameUI:setInitFlag(flag)
    self.initFlag = flag
end

function BaseActivityGameUI:getInitFlag()
    return self.initFlag
end

function BaseActivityGameUI:setButtonDisableFlag(flag)
    self.btnDisableFlag = flag
end

function BaseActivityGameUI:setSendMsgFlag(flag)
    self.sendMsgFlag = flag
end

function BaseActivityGameUI:getSendMsgFlag()
    return self.sendMsgFlag
end

function BaseActivityGameUI:setPreBgMusicName(name)
    self.preBgMusicName = name
end

function BaseActivityGameUI:setPauseBgMusicFlag(flag)
    self.pauseMusicFlag = flag
end

function BaseActivityGameUI:checkActivityTimer()
    self:stopActivityAction()
    local function updateTime()
        local gameData = self:getGameData()
        if gameData == nil or not gameData:isRunning() then
            self:stopActivityAction()
            self:close(nil, nil, false)
        end
    end
    self.activityAction = util_schedule(self, updateTime, 1)
    updateTime()
end

function BaseActivityGameUI:stopActivityAction()
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
        self.activityAction = nil
    end
end

function BaseActivityGameUI:closeOtherUI()
    local closeExtendKeyList = self:getCloseExtendKeyList()
    if closeExtendKeyList ~= nil then
        for k, v in ipairs(closeExtendKeyList) do
            local ui = gLobalViewManager:getViewByExtendData(v)
            if ui ~= nil and ui.removeFromParent ~= nil then
                ui:removeFromParent()
            end
        end
    end
end

function BaseActivityGameUI:close(callBack, clickCallBack, notRotateFlag)
    if not self.btnDisableFlag then
        self:setButtonDisableFlag(true)
        self:closeOtherUI()
        if not notRotateFlag then
            self:checkBackToPortraitOrLandscape()
        end
        if clickCallBack ~= nil then
            clickCallBack()
        end
        if callBack ~= nil then
            callBack()
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
            if gLobalViewManager:isLobbyView() then
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
            end
        end
        self:removeFromParent()
    end
end
------------------------------------------子类重写---------------------------------------
function BaseActivityGameUI:initUI(param)
    BaseActivityRotateUI.initUI(self, param)
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end

    -- tm test --
    if self:getCsbName() ~= nil then
        self:createCsbNode(self:getCsbName(), isAutoScale)
    end
    self:checkActivityTimer()
end

function BaseActivityGameUI:onEnter()
    self:registerListener()
    local lobbyNewIconKey = self:getLobbyNodeNewIconKey()
    if lobbyNewIconKey ~= nil and lobbyNewIconKey ~= "" then
        local newCount = gLobalDataManager:getNumberByField(lobbyNewIconKey, 0)
        newCount = newCount + 1
        gLobalDataManager:setNumberByField(lobbyNewIconKey, newCount)
    end
    --大厅推送弹窗弹出活动主题不应该中断
    if not self.isPushView then
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_FINISH)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
    local bgMusicPath = self:getBgMusicPath()
    -- local curMusicPath = gLobalSoundManager:getCurrBgMusicName()
    -- if curMusicPath ~= bgMusicPath then
    --     self:setPreBgMusicName(curMusicPath)
    -- end
    -- gLobalSoundManager:playBgMusic(bgMusicPath)
    -- gLobalSoundManager:setLockBgMusic(true)
    -- gLobalSoundManager:setLockBgVolume(true)
    if bgMusicPath and bgMusicPath ~= "" then
        gLobalSoundManager:playSubmodBgm(bgMusicPath, self.__cname, self:getZOrder())
    end
end

function BaseActivityGameUI:onExit()
    gLobalNoticManager:removeAllObservers(self)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {isPlayEffect = false})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    if gLobalViewManager:isPauseAndResumeMachine(self) then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
    end

    -- 移除背景音乐
    local bgMusicPath = self:getBgMusicPath()
    if bgMusicPath and bgMusicPath ~= "" then
        gLobalSoundManager:removeSubmodBgm(self.__cname)
    end
    -- gLobalSoundManager:setLockBgMusic(false)
    -- gLobalSoundManager:setLockBgVolume(false)
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESET_BG_MUSIC)
    -- if self.preBgMusicName ~= nil then
    --     gLobalSoundManager:playBgMusic(self.preBgMusicName)
    -- else
    --     gLobalSoundManager:stopAllAuido()
    --     gLobalSoundManager:uncacheAll()
    -- end
    -- if self.pauseMusicFlag then
    --     gLobalSoundManager:pauseBgMusic()
    -- end
end

function BaseActivityGameUI:registerListener()
    BaseActivityRotateUI.registerListener(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if not tolua.isnull(self) then
                self:close(nil, nil, false)
            end
        end,
        ViewEventType.NOTIFY_THEMESALE_CLICK
    )
    --大厅点跳转到关卡关闭活动界面事件

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == self:getActivityRefType() then
                target:close(nil, nil, false)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function BaseActivityGameUI:getCsbName()
    return ""
end

--关闭游戏界面时关闭其他界面的扩展key列表
function BaseActivityGameUI:getCloseExtendKeyList()
    return nil
end

function BaseActivityGameUI:getBgMusicPath()
    return ""
end

--大厅底部的new逻辑，3次之前显示new标签
function BaseActivityGameUI:getLobbyNodeNewIconKey()
    return ""
end

function BaseActivityGameUI:getGameData()
    return nil
end

function BaseActivityGameUI:getActivityRefType()
    return nil
end
return BaseActivityGameUI
------------------------------------------子类重写---------------------------------------
