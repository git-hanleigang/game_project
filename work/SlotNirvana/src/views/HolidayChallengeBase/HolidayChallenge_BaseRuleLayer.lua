--[[
    任务弹板
]]
local HolidayChallenge_BaseRuleLayer = class("HolidayChallenge_BaseRuleLayer", BaseLayer)

function HolidayChallenge_BaseRuleLayer:initDatas(callback)
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.RULE_LAYER)
    self:addClickSound({"btn_go"}, SOUND_ENUM.SOUND_HIDE_VIEW)
    self.m_callback = callback
end

function HolidayChallenge_BaseRuleLayer:initCsbNodes()
    self.m_list_mission = self:findChild("list_mission")
end

function HolidayChallenge_BaseRuleLayer:initView()
    local holidayData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if holidayData then
        local cell_Path = "views.HolidayChallengeBase.HolidayChallenge_BaseMissonNode"
        if self.m_activityConfig and self.m_activityConfig.CODE_PATH.MISSION_NODE then
            cell_Path = self.m_activityConfig.CODE_PATH.MISSION_NODE
        end
        local taskData = holidayData:getTaskData() or {}
        for i,v in ipairs(taskData) do
            local missinoNode = util_createView(cell_Path, v)
            local size = missinoNode:getSize()
            local layout = ccui.Layout:create()
            layout:setContentSize(size)
            layout:addChild(missinoNode)
            missinoNode:setPosition(size.width/2, size.height/2)
            self.m_list_mission:pushBackCustomItem(layout)
        end
    end
end

function HolidayChallenge_BaseRuleLayer:clickFunc(sender)
    if self.m_isIncAction then
        return
    end
    self.m_isIncAction = true

    local name = sender:getName()
    if name == "btn_go" or name == "btn_close" then
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):clearCompleteTask()
        self:closeUI(function ()
            if self.m_callback then
                self.m_callback()
            end
        end)
    end
end

function HolidayChallenge_BaseRuleLayer:registerListener()
    HolidayChallenge_BaseRuleLayer.super.registerListener(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function HolidayChallenge_BaseRuleLayer:onShowedCallFunc( )
    self:runCsbAction("idle", true, nil,60)
end

return HolidayChallenge_BaseRuleLayer
