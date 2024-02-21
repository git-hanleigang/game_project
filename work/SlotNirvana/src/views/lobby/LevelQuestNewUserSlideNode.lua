--[[
Author: cxc
Date: 2021-06-29 15:48:07
LastEditTime: 2021-07-01 21:23:50
LastEditors: Please set LastEditors
Description: 新手quest 轮播图
FilePath: /SlotNirvana/src/views/lobby/LevelQuestNewUserSlideNode.lua
--]]
local LevelQuestNewUserSlideNode = class("LevelQuestNewUserSlideNode", BaseView)

function LevelQuestNewUserSlideNode:initUI()
    local groupName = G_GetMgr(ACTIVITY_REF.Quest):getGroupName()
    if groupName == "GroupB" then
        self:createCsbNode("QuestNewUser/Icons/csd/GroupB/QuestNewUserSlide.csb")
    else
        self:createCsbNode("QuestNewUser/Icons/csd/GroupA/QuestNewUserSlide.csb")
    end

    self:initView()
end

function LevelQuestNewUserSlideNode:initView()
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

function LevelQuestNewUserSlideNode:onEnter()
    LevelQuestNewUserSlideNode.super.onEnter(self)

    self:runCsbAction("idle", true, nil, 60)
    self:updateActEndTime()
    schedule(self, handler(self, self.updateActEndTime), 1)
end

function LevelQuestNewUserSlideNode:updateActEndTime()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig == nil then
        return
    end

    local strLeftTime = util_daysdemaining(questConfig:getExpireAt(), true)
    self.m_lbTime:setString(strLeftTime)
end

--点击回调
function LevelQuestNewUserSlideNode:MyclickFunc()
    self:clickLayer()
end

function LevelQuestNewUserSlideNode:clickLayer(name)
    --gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyCarousel")

    performWithDelay(
        self,
        function()
            gLobalSendDataManager:getLogQuestNewUserActivity():sendQuestEntrySite("lobbyCarousel")
            G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
        end,
        0.2
    )
end

return LevelQuestNewUserSlideNode
