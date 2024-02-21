--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-19 16:21:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-19 17:29:37
FilePath: /SlotNirvana/src/GameModule/CardNovice/views/CardNoviceDoubleRewardSignUI.lua
Description: 新手期集卡 双倍奖励 标签
--]]
local CardNoviceDoubleRewardSignUI = class("CardNoviceDoubleRewardSignUI", BaseView)

function CardNoviceDoubleRewardSignUI:initCsbNodes()
    CardNoviceDoubleRewardSignUI.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
end

function CardNoviceDoubleRewardSignUI:getCsbName()
    return "CardRes/season302301/Node_biaoqian.csb"
end

function CardNoviceDoubleRewardSignUI:initUI()
    CardNoviceDoubleRewardSignUI.super.initUI(self)

    self.m_data = G_GetMgr(G_REF.CardNoviceSale):getData()

    -- 倒计时
    self.m_scheduler = schedule(self, util_node_handler(self, self.onUpdateSec), 1)
    self:onUpdateSec()
end

function CardNoviceDoubleRewardSignUI:onUpdateSec()
    local expireAt = self.m_data:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self.m_lbTime:setString(timeStr)

    if bOver then
        self:clearScheduler()
        self:removeSelf()
    end
end

-- 清楚定时器
function CardNoviceDoubleRewardSignUI:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

return CardNoviceDoubleRewardSignUI