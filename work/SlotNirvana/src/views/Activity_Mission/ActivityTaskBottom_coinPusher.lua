--[[
    推币机任务入口按钮
]]
local ActivityTaskBottom_coinPusher = class("ActivityTaskBottom_coinPusher", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

local logoPathConfig = {
    -- 常规主题
    Activity_CoinPusherTask = "Activity_Mission/ui_PusherMission_entryNode/m_game_logo.png",
    -- 复活节主题
    Activity_CoinPusherEasterTask = "Activity_Mission/ui_PusherMission_entryNode/m_game_logo_Easter.png",
    -- 独立日主题
    Activity_CoinPusherLibertyTask = "Activity_Mission/ui_PusherMission_entryNode/m_game_logo.png"
}


function ActivityTaskBottom_coinPusher:initUI()
    ActivityTaskBottom_coinPusher.super.initUI(self)

    -- 入口图片
    local spIcon = self:findChild("sp_bg")
    local themeName = G_GetMgr(ACTIVITY_REF.CoinPusherTask):getThemeName()
    local imgPath = logoPathConfig[themeName]
    util_changeTexture(spIcon, imgPath)
end

function ActivityTaskBottom_coinPusher:getCsbName()
    return "Activity_Mission/csd/COIN_PUSHER_MissionEntryNode.csb"
end

function ActivityTaskBottom_coinPusher:getActivityName()
    return ACTIVITY_REF.Activity_CoinPusherTask
end

function ActivityTaskBottom_coinPusher:getHasProgress()
    return true
end

function ActivityTaskBottom_coinPusher:clickFunc()
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    G_GetMgr(ACTIVITY_REF.CoinPusherTask):showMainLayer()
    -- local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(self:getActivityName())
    -- if taskDataObj and taskDataObj:isRunning() then
    -- end
    self.m_isCanTouch = false
end

return ActivityTaskBottom_coinPusher
