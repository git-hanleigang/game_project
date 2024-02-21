--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-18 10:56:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-18 11:20:10
FilePath: /SlotNirvana/src/views/lobby/LevelCardNoviceDoubleRewardHallNode.lua
Description: 新手期集卡 双倍奖励  展示图
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelCardNoviceDoubleRewardHallNode = class("LevelCardNoviceDoubleRewardHallNode", LevelFeature)

function LevelCardNoviceDoubleRewardHallNode:initCsbNodes()
    LevelCardNoviceDoubleRewardHallNode.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
    self:setButtonLabelContent("btn_go", "GET IT")
end

function LevelCardNoviceDoubleRewardHallNode:createCsb()
    LevelCardNoviceDoubleRewardHallNode.super.createCsb(self)

    self:createCsbNode("NewUserAlbum_DoubleReward/Icons/Activity_NewUserAlbum_DoubleReward_Hall.csb")
    self:runCsbAction("idle", true)

    self.m_showData = G_GetMgr(G_REF.CardNoviceSale):getData()
    -- 时间
    self.m_scheduler = schedule(self, util_node_handler(self, self.onUpdateSec), 1)
    self:onUpdateSec()
end

function LevelCardNoviceDoubleRewardHallNode:onUpdateSec()
    local expireAt = self.m_showData:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self.m_lbTime:setString(timeStr)

    if not G_GetMgr(G_REF.CardNoviceSale):isRunning() then
        self:clearScheduler()
        gLobalNoticManager:postNotification(CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_DOUBLE_REWARD_HALL_SLIDE)
    end
end

-- 清楚定时器
function LevelCardNoviceDoubleRewardHallNode:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

function LevelCardNoviceDoubleRewardHallNode:clickFunc(sender)
    G_GetMgr(G_REF.CardNoviceSale):showDoubleRewardLayer()
end

return LevelCardNoviceDoubleRewardHallNode