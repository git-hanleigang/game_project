--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-15 14:18:23
]]
--[[
    blast任务入口按钮
]]
local ActivityTaskEntry_blast = class("ActivityTaskEntry_blast", util_require("views.Activity_MissionNew.ActivityTaskEntryBase"))

function ActivityTaskEntry_blast:initUI()
    self.BlastConfig = G_GetMgr(ACTIVITY_REF.Blast):getConfig()
    ActivityTaskEntry_blast.super.initUI(self)
end

function ActivityTaskEntry_blast:getCsbName()
    if self.BlastConfig.getThemeName() == self.BlastConfig.THEMES.BLOSSOM then
        -- 阿凡达主题
        return "Activity/Activity_MissionNew/csd/COIN_BLAST_MissionBlossomEntryNode.csb"
    end
end

function ActivityTaskEntry_blast:getActivityName()
    return ACTIVITY_REF.BlastTaskNew
end

function ActivityTaskEntry_blast:openTaskView()
    G_GetMgr(ACTIVITY_REF.BlastTaskNew):showMainLayer()
end

return ActivityTaskEntry_blast
