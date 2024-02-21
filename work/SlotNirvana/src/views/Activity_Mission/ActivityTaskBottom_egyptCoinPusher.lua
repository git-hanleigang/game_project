--[[
    推币机任务入口按钮
]]
local ActivityTaskBottom_egyptCoinPusher = class("ActivityTaskBottom_egyptCoinPusher", util_require("views.Activity_Mission.ActivityTaskBottomBase"))

local logoPathConfig = {
    -- 常规主题
    Activity_EgyptCoinPusherTask = "Activity_Mission/ui_EgyptPusherMission_entryNode/EgyptCoinPusher_mission_logo.png",
}


function ActivityTaskBottom_egyptCoinPusher:initUI()
    ActivityTaskBottom_egyptCoinPusher.super.initUI(self)

    -- 入口图片
    local spIcon = self:findChild("sp_logo")
    local themeName = G_GetMgr(ACTIVITY_REF.CoinPusherTask):getThemeName()
    local imgPath = logoPathConfig[themeName]
    if not imgPath then
        local theme = "Activity_EgyptCoinPusherTask"
        imgPath = logoPathConfig[theme]
    end
    util_changeTexture(spIcon, imgPath)
end

function ActivityTaskBottom_egyptCoinPusher:getCsbName()
    return "Activity_Mission/csd/COIN_NEWPUSHER_MissionEntryNode.csb"
end

function ActivityTaskBottom_egyptCoinPusher:getActivityName()
    return ACTIVITY_REF.Activity_EgyptCoinPusherTask
end

function ActivityTaskBottom_egyptCoinPusher:getHasProgress()
    return true
end

function ActivityTaskBottom_egyptCoinPusher:clickFunc()
    G_GetMgr(ACTIVITY_REF.EgyptCoinPusherTask):showMainLayer()
end

function ActivityTaskBottom_egyptCoinPusher:updateTaskProgress()
    ActivityTaskBottom_egyptCoinPusher.super.updateTaskProgress(self)
    self.m_lbProgressNum:setScale(0.8)
end

return ActivityTaskBottom_egyptCoinPusher
