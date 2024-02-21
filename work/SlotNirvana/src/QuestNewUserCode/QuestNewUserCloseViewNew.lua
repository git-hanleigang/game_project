--[[
Author: cxcs
Date: 2021-07-02 18:03:04
LastEditTime: 2021-07-22 16:18:57
LastEditors: Please set LastEditors
Description: 新手quest 新的完成弹板
FilePath: /SlotNirvana/src/QuestNewUserCode/Quest/QuestNewUserCloseViewNew.lua
-- 
--]]
local QuestNewUserCloseViewNew = class("QuestNewUserCloseViewNew", BaseLayer)
local ACTIVITY_INFO = util_require("views.lobby.BottomNode").ACTIVITY_INFO or {}

function QuestNewUserCloseViewNew:ctor()
    QuestNewUserCloseViewNew.super.ctor(self)
    self:setPauseSlotsEnabled(true)

    self:setLandscapeCsbName("QuestNewUser/Activity/csd/NewUser_QuestLinkOverBGroup.csb")
end

function QuestNewUserCloseViewNew:initView()
    QuestNewUserCloseViewNew.super.initView(self)

    self.item1 = self:findChild("node_stage_1")
    self.item2 = self:findChild("node_stage_2")
    self:setButtonLabelContent("btn_showem", "SHOW ME")
    self:startButtonAnimation("btn_showem", "breathe", true)

    -- copy BottomNode中 大活动显示逻辑
    local newData, comingSoon = self:checkCurrShowActivityNode()
    local bShowAct = newData ~= nil

    -- 有 大活动时 把大活动也显示出来(更大厅 BottomNode中的逻辑一样)
    local has_activity = false
    if bShowAct and newData.activityName then
        local actName = newData.activityName
        local actData = G_GetActivityDataByRef(actName, true)
        if actData then
            local themeName = ""
            if actData.getThemeName then
                themeName = actData:getThemeName()
            end
            if not themeName or themeName == "" then
                themeName = actName
            end
            local iconStr = "icon_" .. string.split(themeName, "Activity_")[2] .. ".png"
            local iconPath = "CommonTaskIcon/" .. iconStr
            local spIconAct = self:findChild("sp_icon_act")
            local bSuccess = util_changeTexture(spIconAct, iconPath)
            has_activity = bSuccess
        end
    end

    self.item1:setVisible(not has_activity)
    self.item2:setVisible(has_activity)
end

function QuestNewUserCloseViewNew:onShowedCallFunc()
    QuestNewUserCloseViewNew.super.onShowedCallFunc(self)

    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle", true)
        end,
        60
    )
end

function QuestNewUserCloseViewNew:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clicked then
        return
    end
    self.m_clicked = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_showem" then
        self:runCsbAction(
            "over",
            false,
            function()
                globalData.userRunData:saveLeveToLobbyRestartInfo()
                if globalData.slotRunData.isPortrait == true then
                    globalData.slotRunData.isChangeScreenOrientation = true
                    globalData.slotRunData:changeScreenOrientation(false)
                end

                util_restartGame()
            end,
            60
        )
    end
end

-- 专门用来检测 活动节点  copy 自 BottomNode中的方法
function QuestNewUserCloseViewNew:checkCurrShowActivityNode()
    --配置了当前的所有活动
    -- isRunning 代表当前活动有数据，当前等级允许running 这个活动
    local canShow = false
    local actInfo = nil
    local comingsoon = false

    --1. 检测当前是否有正在进行时的活动
    for i = 1, #ACTIVITY_INFO do
        local act_info = ACTIVITY_INFO[i]
        if G_GetActivityDataByRef(act_info.activityName, true) then
            -- 检测到当前活动是否在活动时间内,不用考虑等级是否到达
            canShow = true
            actInfo = act_info
            break
        end
    end

    --2. 如果当前没有正在进行时的活动,遍历检测出距离近期时间内会开启的活动 显示coming soon
    local recentActvityData = {}
    if canShow == false then
        -- 遍历近期开启的活动中是否有我们配置好的活动,有的话加出来，设置成coming soon
        for i = 1, #ACTIVITY_INFO do
            local act_info = ACTIVITY_INFO[i]
            local data = globalData.GameConfig:getRecentActivityConfigByRef(act_info.activityName)
            if data then
                local newData = {
                    act_info = act_info,
                    data = data
                }
                table.insert(recentActvityData, newData)
            end
        end
    end

    --3. 比较当前时间跟近期会开启的活动时间，选取离得最近的活动展示
    local lastTime = nil
    for i = 1, table.nums(recentActvityData) do
        local data = recentActvityData[i].data
        local act_info = recentActvityData[i].act_info
        local starTimer = util_getymd_time(data.p_start)
        if lastTime == nil or (starTimer < lastTime) then
            lastTime = starTimer
            actInfo = act_info
            comingsoon = true
        -- print("---- lasttime "..lastTime.. " starTimer = "..starTimer)
        -- print("p_reference = "..actInfo.p_reference)
        end
    end

    return actInfo, comingsoon
end

return QuestNewUserCloseViewNew
