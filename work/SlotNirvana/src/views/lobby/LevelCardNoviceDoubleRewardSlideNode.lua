--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-18 10:56:12
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-18 11:19:50
FilePath: /SlotNirvana/src/views/lobby/LevelCardNoviceDoubleRewardSlideNode.lua
Description: 新手期集卡 双倍奖励 轮播图
--]]
local LevelCardNoviceDoubleRewardSlideNode = class("LevelCardNoviceDoubleRewardSlideNode", BaseView)

function LevelCardNoviceDoubleRewardSlideNode:initCsbNodes()
    LevelCardNoviceDoubleRewardSlideNode.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
end

function LevelCardNoviceDoubleRewardSlideNode:initUI()
    LevelCardNoviceDoubleRewardSlideNode.super.initUI(self)

    self.m_showData = G_GetMgr(G_REF.CardNoviceSale):getData()
    self:runCsbAction("idle", true)

    -- 时间
    self.m_scheduler = schedule(self, util_node_handler(self, self.onUpdateSec), 1)
    self:onUpdateSec()
end

function LevelCardNoviceDoubleRewardSlideNode:getCsbName()
    return "NewUserAlbum_DoubleReward/Icons/Activity_NewUserAlbum_DoubleReward_Slide.csb"
end

function LevelCardNoviceDoubleRewardSlideNode:onUpdateSec()
    local expireAt = self.m_showData:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self.m_lbTime:setString(timeStr)

    if not G_GetMgr(G_REF.CardNoviceSale):isRunning() then
        self:clearScheduler()
        gLobalNoticManager:postNotification(CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_DOUBLE_REWARD_HALL_SLIDE)
    end
end

-- 清楚定时器
function LevelCardNoviceDoubleRewardSlideNode:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

--点击回调
function LevelCardNoviceDoubleRewardSlideNode:MyclickFunc()
    self:clickLayer()
end

function LevelCardNoviceDoubleRewardSlideNode:clickLayer(name)
    G_GetMgr(G_REF.CardNoviceSale):showDoubleRewardLayer()
end

return LevelCardNoviceDoubleRewardSlideNode