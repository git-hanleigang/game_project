--[[
Author: cxc
Date: 2021-06-29 15:48:07
LastEditTime: 2021-06-30 15:11:59
LastEditors: Please set LastEditors
Description: 新手quest 展示图
FilePath: /SlotNirvana/src/views/lobby/LevelQuestNewUserHallNode.lua
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelQuestNewUserHallNode = class("LevelQuestNewUserHallNode", LevelFeature)

function LevelQuestNewUserHallNode:createCsb()
    LevelQuestNewUserHallNode.super.createCsb(self)
    local themeName = G_GetMgr(ACTIVITY_REF.Quest):getGroupName()
    if themeName == "GroupB" then
        self:createCsbNode("QuestNewUser/Icons/csd/GroupB/QuestNewUserHall.csb")
    else
        self:createCsbNode("QuestNewUser/Icons/csd/GroupA/QuestNewUserHall.csb")
    end

    self:initView()
end

function LevelQuestNewUserHallNode:initView()
    self.m_lbTime = self:findChild("lb_time")
    self.m_lbCoins = self:findChild("lb_coins")

    local themeName = G_GetMgr(ACTIVITY_REF.Quest):getGroupName()
    if themeName == "GroupB" then
        local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if act_data == nil then
            return
        end
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if not tolua.isnull(self) then
                    local phase_data = act_data:getCurPhaseData()
                    self.m_lbCoins:setString(util_formatCoins(tonumber(phase_data.p_phaseCoins) or 0, 13))
                end
            end,
            ViewEventType.NOTIFY_ACTIVITY_QUEST_STAGE_COMPLETE
        )

        local phase_data = act_data:getCurPhaseData()
        self.m_lbCoins:setString(util_formatCoins(tonumber(phase_data.p_phaseCoins) or 0, 13))
    else
        self.m_lbCoins:setString(util_formatCoins(tonumber(globalData.constantData.NOVICE_NEWUSERQUEST_LEVELUP_REWARD) or 0, 13))
    end
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbCoins, 160)
end

function LevelQuestNewUserHallNode:onEnter()
    LevelQuestNewUserHallNode.super.onEnter(self)

    self:runCsbAction("idle", true, nil, 60)
    self:updateActEndTime()
    schedule(self, handler(self, self.updateActEndTime), 1)
end

function LevelQuestNewUserHallNode:updateActEndTime()
    local act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if act_data == nil then
        return
    end

    -- time
    local strLeftTime = util_daysdemaining(act_data:getExpireAt(), true)
    self.m_lbTime:setString(strLeftTime)
end

function LevelQuestNewUserHallNode:clickFunc(sender)
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyDisplay")

    performWithDelay(
        self,
        function()
            gLobalSendDataManager:getLogQuestNewUserActivity():sendQuestEntrySite("lobbyDisplay")
            G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
        end,
        0.2
    )
end

return LevelQuestNewUserHallNode
