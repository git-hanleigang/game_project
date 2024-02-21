-- 活动 获得新次数弹框

local EntryNodeConfig = util_require("baseActivity.ActivityExtra.EntryNodeConfig")
local Activity_CollectMaxPop = class("Activity_CollectMaxPop", BaseLayer)

function Activity_CollectMaxPop:initDatas(activity_type, isAutoClose)
    -- 当前关卡横竖屏
    self:setShownAsPortrait(globalData.slotRunData:isFramePortrait())

    self.m_isAutoClose = isAutoClose or false

    self.activity_type = activity_type
    assert(self.activity_type, "Activity_CollectMaxPop 活动类型不明确")

    local activity_config = EntryNodeConfig.popup_config[self.activity_type]
    assert(activity_config, "Activity_CollectMaxPop EntryNodeConfig 的 popup_config配置没填写 " .. self.activity_type)

    self.activity_config = activity_config.collect_max
    assert(self.activity_config, "Activity_CollectMaxPop EntryNodeConfig 的 popup_config 配置中 collect 不存在 " .. self.activity_type)

    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName(self.activity_config.horizontal)
    self:setPortraitCsbName(self.activity_config.portrait)
end

function Activity_CollectMaxPop:initUI(activity_type)
    Activity_CollectMaxPop.super.initUI(self)

    self.activity_data = G_GetActivityDataByRef(self.activity_type)
    if not self.activity_data or not self.activity_data:isRunning() then
        self:setVisible(false)
        util_afterDrawCallBack(
            function()
                if not tolua.isnull(self) then
                    self:removeFromParent()
                end
            end
        )
    end

    -- 读取必要节点
    self:readNodes()

    self:setExtendData("Activity_CollectMaxPop")

    self.bl_bubbleOnShow = false

    --自动关闭界面
    self:initAutoClose()
end

function Activity_CollectMaxPop:initAutoClose()
    local lb_close = self:findChild("lb_close")
    if not lb_close then
        return
    end
    lb_close:setVisible(self.m_isAutoClose)
    self.m_lb_close = lb_close
    if self.m_isAutoClose then
        local onTick = function(sec)
            lb_close:setString(string.format("CLOSING IN %d S...", sec))
        end
        self:setAutoCloseUI(nil, onTick, handler(self, self.closeUI))
    end
end

function Activity_CollectMaxPop:stopAutoCloseUITimer()
    if self.m_lb_close then
        self.m_lb_close:setVisible(false)
    end
    Activity_CollectMaxPop.super.stopAutoCloseUITimer(self)
end

function Activity_CollectMaxPop:readNodes()
    self.root = self:findChild("root")
    assert(self.root, "缺少必要节点 root")

    local btn_close = self:findChild("btn_close")
    assert(btn_close, "缺少必要节点1")

    local btn_play = self:findChild("btn_play")
    assert(btn_play, "缺少必要节点2")

    self.lb_num = self:findChild("lb_num")
    assert(self.lb_num, "缺少必要节点3")
    local str_num = 0
    if self.activity_data.popupInStage_showMaxNum and self.activity_data.popupInStage_showMaxNum > 0 then
        str_num = self.activity_data.popupInStage_showMaxNum
    end
    self.lb_num:setString("X " .. str_num)

    -- assert(util_csbActionExists(self.m_csbAct, "show"), "show 动画不存在")
end

function Activity_CollectMaxPop:onEnter()
    Activity_CollectMaxPop.super.onEnter(self)
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == self.activity_type then
                self:removeFromParent()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- 发送打点日志
    self:logOpen()
    -- self:logOnPopup()
end

function Activity_CollectMaxPop:onExit()
    Activity_CollectMaxPop.super.onExit(self)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
end

function Activity_CollectMaxPop:clickFunc(sender)
    if self.m_touchEnabled == false then
        return
    end

    local senderName = sender:getName()
    if senderName == "btn_play" then
        gLobalSoundManager:playSound("Sounds/btn_click.mp3")
        self:logClick()
        -- self:logOnClick()
        self:gotoPlay()
    elseif senderName == "btn_close" then
        if self:showBubble() then
            gLobalSoundManager:playSound("Sounds/btn_click.mp3")
            return
        end
        self:closeUI()
    end
end

-- 跳转活动主界面
function Activity_CollectMaxPop:gotoPlay()
    local cb = function()
        -- 打开活动主界面
        local _mgr = G_GetMgr(self.activity_type)
        if _mgr then
            _mgr:showMainLayer()
        else
            local activity_file_name = self.activity_config.game_file -- 活动主界面索引名称
            assert(activity_file_name, "Activity_CollectMaxPop EntryNodeConfig 的 popup_config 配置中 game_file 不存在 " .. self.activity_type)
            gLobalActivityManager:showActivityMainView(self.activity_type, activity_file_name, nil, nil)
        end
    end
    self:closeUI(cb, true)
end

-- 关闭
function Activity_CollectMaxPop:closeUI(_call_back, _bPlayClose)
    local callback = function()
        if _call_back then
            _call_back()
        end
    end

    if self.logNovicePopup and not _bPlayClose then
        -- 回调关闭的不打印
        self:logNovicePopup("Close")
    end
    Activity_CollectMaxPop.super.closeUI(self, callback)
end

-- 弹出气泡
function Activity_CollectMaxPop:showBubble()
    if util_csbActionExists(self.m_csbAct, "show", self.__cname) and self.bl_bubbleOnShow == false then
        self.m_touchEnabled = false
        self:runCsbAction(
            "show",
            false,
            function()
                self.bl_bubbleOnShow = true
                self.m_touchEnabled = true
            end,
            60
        )
        return true
    else
        return false
    end
end

-- 发送打点日志
function Activity_CollectMaxPop:logOpen()
    if not self.activity_data or not self.activity_data:isRunning() then
        return
    end
    local curMachineData = globalData.slotRunData.machineData or {}
    gLobalSendDataManager:getLogIap():setEntryGame(curMachineData.p_name)
    local name = self.activity_type .. "StageCollectMax"
    gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", name)

    local logManager = gLobalSendDataManager:getActivityLogManager()
    if logManager then
        logManager:sendPageLog("GamePushPage", "Open", curMachineData.p_name)
    end

    if self.logNovicePopup then
        self:logNovicePopup("Open")
    end
end

-- 发送打点日志
function Activity_CollectMaxPop:logClick()
    if not self.activity_data or not self.activity_data:isRunning() then
        return
    end
    local curMachineData = globalData.slotRunData.machineData or {}
    gLobalSendDataManager:getLogIap():setEntryGame(curMachineData.p_name)
    local name = self.activity_type .. "StageCollectMax"
    gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", name)

    local logManager = gLobalSendDataManager:getActivityLogManager()
    if logManager then
        logManager:sendPageLog("GamePushPage", "Click", curMachineData.p_name)
    end

    if self.logNovicePopup then
        self:logNovicePopup("Play")
    end
end

-- -- 发送打点日志
-- function Activity_CollectMaxPop:logOnPopup()
--     local logManager = gLobalSendDataManager:getActivityLogManager()
--     if logManager then
--         local name = self.activity_type .. "StageCollectMax"
--         logManager:onPopup(self.activity_type, name, "Collect")
--     end
-- end

-- -- 发送打点日志
-- function Activity_CollectMaxPop:logOnClick()
--     local logManager = gLobalSendDataManager:getActivityLogManager()
--     if logManager then
--         local name = self.activity_type .. "StageCollectMax"
--         logManager:onClick(self.activity_type, name)
--     end
-- end

return Activity_CollectMaxPop
