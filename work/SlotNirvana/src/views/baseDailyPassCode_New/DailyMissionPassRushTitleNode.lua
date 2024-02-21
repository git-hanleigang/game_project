--[[
    --新版每日任务pass主界面 任务界面礼物节点
    csc 2021-06-22
]]
local DailyMissionPassRushTitleNode = class("DailyMissionPassRushTitleNode", util_require("base.BaseView"))
function DailyMissionPassRushTitleNode:initUI(_source)
    
    -- 根据当前任务类型创建不同的节点
    self:createCsbNode(DAILYPASS_RES_PATH.DailyMissionPass_MissionRushNode)
    
    self.m_nodeSpine = self:findChild("spine_node_fire")
    self.m_touchPanel = self:findChild("touch_panel")
    
    self:addClick(self.m_touchPanel)
    self:updateView(_source)

end

function DailyMissionPassRushTitleNode:updateView(_source)
    -- 换图
    local actName = "idle"
    if _source == "Daily" then
        if gLobalDailyTaskManager:getIsDailyMissionPlus() then
            actName = "idle_plus"
        end
    elseif _source == "Season" then
        actName = "idle"
    end
    self.m_source = _source
    self:runCsbAction(actName, true, nil, 60)

    local spineNode = util_spineCreate(DAILYPASS_RES_PATH.DailyMissionPass_RushTitleFire, false, true, 1)
    if spineNode then
        self.m_nodeSpine:addChild(spineNode)
        util_spinePlay(spineNode,"animation",true)
    end
end

function DailyMissionPassRushTitleNode:clickFunc(sender)
    local name = sender:getName()

    if name == "touch_panel" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local activityData = nil
        if self.m_source == "Daily" then
            activityData = G_GetMgr(ACTIVITY_REF.DailyMissionRush):getRunningData()
        elseif self.m_source == "Season" then
            activityData = G_GetMgr(ACTIVITY_REF.SeasonMissionRush):getRunningData()
        end
        gLobalDailyTaskManager:createRushSendLayer(activityData)
    end
end


return DailyMissionPassRushTitleNode