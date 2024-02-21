--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-29 15:53:26
]]
--[[
    推币机任务入口按钮
]]
local ActivityTaskBottom_newCoinPusher = class("ActivityTaskBottom_newCoinPusher", util_require("views.Activity_Mission.ActivityTaskBottomBase"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

local logoPathConfig = {
    -- 常规主题
    Activity_NewCoinPusherTask = "Activity_Mission/ui_NewPusherMission_entryNode/CoinPusher_mission_logo.png",
}


function ActivityTaskBottom_newCoinPusher:initUI()
    ActivityTaskBottom_newCoinPusher.super.initUI(self)

    -- 入口图片
    local spIcon = self:findChild("sp_logo")
    local themeName = G_GetMgr(ACTIVITY_REF.CoinPusherTask):getThemeName()
    local imgPath = logoPathConfig[themeName]
    if not imgPath then
        local theme = "Activity_NewCoinPusherTask"
        imgPath = logoPathConfig[theme]
    end
    util_changeTexture(spIcon, imgPath)
end

function ActivityTaskBottom_newCoinPusher:getCsbName()
    return "Activity_Mission/csd/COIN_NEWPUSHER_MissionEntryNode.csb"
end

function ActivityTaskBottom_newCoinPusher:getActivityName()
    return ACTIVITY_REF.Activity_NewCoinPusherTask
end

function ActivityTaskBottom_newCoinPusher:getHasProgress()
    return true
end

function ActivityTaskBottom_newCoinPusher:clickFunc()
    if self.m_isCanTouch then
        return
    end
    self.m_isCanTouch = true
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    G_GetMgr(ACTIVITY_REF.NewCoinPusherTask):showMainLayer()
    -- local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(self:getActivityName())
    -- if taskDataObj and taskDataObj:isRunning() then
    -- end
    self.m_isCanTouch = false
end

function ActivityTaskBottom_newCoinPusher:updateTaskProgress()
    ActivityTaskBottom_newCoinPusher.super.updateTaskProgress(self)
    self.m_lbProgressNum:setScale(0.8)
end

return ActivityTaskBottom_newCoinPusher
