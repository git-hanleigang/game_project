-- QuestNew 任务展示界面

local QuestNewEnterLayer = class("QuestNewEnterLayer", BaseLayer)

function QuestNewEnterLayer:ctor()
    QuestNewEnterLayer.super.ctor(self)
    self.m_taskNodeList = {}

    -- self:mergePlistInfos(QUEST_PLIST_PATH.QuestNewEnterLayer)

    self:setLandscapeCsbName(QUEST_RES_PATH.QuestNewEnterLayer)
    self:setPortraitCsbName(QUEST_RES_PATH.QuestNewEnterPorLayer)

    self:setPauseSlotsEnabled(true)
end

function QuestNewEnterLayer:initUI(data)
    --获取questConfig
    self.m_config = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if self.m_config ~= nil then
        self.m_taskData = self.m_config:getEnterGameTaskInfo()
    end
    QuestNewEnterLayer.super.initUI(self)
end

function QuestNewEnterLayer:initCsbNodes()
    self.m_btn_start = self:findChild("btn_start")
    self.m_logoNode = self:findChild("logo")
    self.m_taskNode = self:findChild("task_node")
    self.m_taskNode:setPosition(0, 100)
end

function QuestNewEnterLayer:initTask()
    if self.m_taskData == nil then
        return
    end
    local len = #self.m_taskData
    local list = {{-118}, {-68, -193}, {-33, -133, -233}}
    local posList = list[len]
    for i = 1, len do
        local d = self.m_taskData[i]
        local taskNode = self:createTaskNode(d)
        if taskNode ~= nil then
            taskNode:setPosition(-350, posList[i])
            self.m_taskNode:addChild(taskNode)
            self.m_taskNodeList[#self.m_taskNodeList + 1] = taskNode
            for k = 1, 3 do
                local sp = taskNode:findChild("sp_" .. k)
                if sp then
                    if k == i then
                        sp:setVisible(true)
                    else
                        sp:setVisible(false)
                    end
                end
            end

            taskNode:setVisible(false)
            performWithDelay(
                self,
                function()
                    taskNode:setVisible(true)
                    taskNode:runCsbAction("eject")
                end,
                0.3 * (i - 1)
            )
        end
    end
end

function QuestNewEnterLayer:initView()
    --关卡头像
    local levelName = ""
    if globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_levelName then
        levelName = globalData.slotRunData.machineData.p_levelName
    end

    if levelName ~= "" then
        local newPath = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.UNLOCK)
        if util_IsFileExist(newPath) then
            local sp = util_createSprite(newPath)
            if sp then
                self.m_logoNode:addChild(sp)
            end
        end
    end
end

--创建task node
function QuestNewEnterLayer:createTaskNode(data)
    if data == nil then
        return nil
    end
    local propNode = util_createFindView(QUESTNEW_CODE_PATH.QuestNewEnterCell, data)
    return propNode
end

function QuestNewEnterLayer:onShowedCallFunc()
    self:runCsbAction("idle")
    self:initTask()
end

function QuestNewEnterLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    QuestNewEnterLayer.super.playShowAction(self, "show")
end

function QuestNewEnterLayer:onEnter()
    QuestNewEnterLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.QuestNew then
                target:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function QuestNewEnterLayer:onStartTask()
    self:closeUI()
end

function QuestNewEnterLayer:onKeyBack()
    self:closeUI()
end

function QuestNewEnterLayer:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_start" then
        self:onStartTask()
        sender:setTouchEnabled(false)
    end
end

function QuestNewEnterLayer:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CHOICE_VIEW_CLOSE)
    end
    QuestNewEnterLayer.super.closeUI(self, callback)
end

return QuestNewEnterLayer
