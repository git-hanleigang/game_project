--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-15 14:18:23
]]
--[[
   word任务入口按钮
]]
local ActivityTaskEntry_word = class("ActivityTaskEntry_word", util_require("views.Activity_MissionNew.ActivityTaskEntryBase"))

function ActivityTaskEntry_word:initUI()
    ActivityTaskEntry_word.super.initUI(self)
end

function ActivityTaskEntry_word:getCsbName()
    return "Activity/Activity_MissionNew/csd/COIN_WORD_MissionBlossomEntryNode.csb"
end

function ActivityTaskEntry_word:getActivityName()
    return ACTIVITY_REF.WordTaskNew
end

function ActivityTaskEntry_word:openTaskView()
    G_GetMgr(ACTIVITY_REF.WordTaskNew):showMainLayer()
end

function ActivityTaskEntry_word:registerListener()
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         self:updateTaskProgress()
    --     end,
    --     ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_DATA
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateTaskProgress()
        end,
        ViewEventType.NOTIFY_WORD_REWARD_COLLECT
    )
    
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initTaskProgress()
        end,
        ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_UI
    )
end


return ActivityTaskEntry_word
