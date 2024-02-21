-- Quest 任务展示界面

local QuestEnterLayer = class("QuestEnterLayer", BaseLayer)

function QuestEnterLayer:ctor()
    QuestEnterLayer.super.ctor(self)
    self.m_taskNodeList = {}

    self:setLandscapeCsbName(QUEST_RES_PATH.QuestEnterLayer)
    self:setPortraitCsbName(QUEST_RES_PATH.QuestEnterPorLayer)

    self:setPauseSlotsEnabled(true)
end

function QuestEnterLayer:initDatas()
    self.act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if self.act_data ~= nil then
        self.m_taskData = self.act_data:getCurTaskInfo()
    end
end

function QuestEnterLayer:initCsbNodes()
    self.m_btn_start = self:findChild("btn_start")
    self.m_logoNode = self:findChild("logo")
    self.m_taskNode = self:findChild("task_node")
end

function QuestEnterLayer:initTask()
    if self.m_taskData == nil then
        return
    end

    local offset = 0
    if not G_GetMgr(ACTIVITY_REF.Quest):isNewUserQuest() then
        offset = 30
    end
    local total_height = 0
    for idx = 1, #self.m_taskData do
        local data = self.m_taskData[idx]
        local taskNode = self:createTaskNode(data, idx)
        if taskNode ~= nil then
            self.m_taskNode:addChild(taskNode)
            taskNode:runCsbAction("eject", false, nil, 60)
            taskNode:setVisible(false)
            self.m_taskNodeList[#self.m_taskNodeList + 1] = taskNode
            total_height = total_height + taskNode:getHieght()
            if idx > 1 then
                total_height = total_height + offset
            end
        end
    end

    local top = total_height / 2
    for idx, taskNode in ipairs(self.m_taskNodeList) do
        local height = taskNode:getHieght()
        taskNode:setPositionY(top - height / 2)
        top = top - height - offset

        performWithDelay(
            self,
            function()
                taskNode:setVisible(true)
                taskNode:runCsbAction("eject")
            end,
            0.3 * (idx - 1)
        )
    end
end

function QuestEnterLayer:initView()
    --关卡头像
    local levelName = ""
    if globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_levelName then
        levelName = globalData.slotRunData.machineData.p_levelName
    end

    if levelName ~= "" then
        local newPath
        if G_GetMgr(ACTIVITY_REF.Quest):isNewUserQuest() then
            newPath = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.SMALL)
        else
            newPath = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.UNLOCK)
        end

        if newPath and util_IsFileExist(newPath) then
            local sp = util_createSprite(newPath)
            if sp then
                self.m_logoNode:addChild(sp)
            end
        end
    end
end

--创建task node
function QuestEnterLayer:createTaskNode(data, idx)
    if data == nil then
        return nil
    end
    local propNode = util_createFindView(QUEST_CODE_PATH.QuestEnterCell, data, idx)
    return propNode
end

function QuestEnterLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    self:initTask()
end

function QuestEnterLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    QuestEnterLayer.super.playShowAction(self, "show")
end

function QuestEnterLayer:onEnter()
    QuestEnterLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.Quest then
                target:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function QuestEnterLayer:onStartTask()
    self:closeUI()
end

function QuestEnterLayer:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_start" then
        self:onStartTask()
        sender:setTouchEnabled(false)
    end
end

function QuestEnterLayer:closeUI()
    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE)
    end
    QuestEnterLayer.super.closeUI(self, callback)
end

return QuestEnterLayer
