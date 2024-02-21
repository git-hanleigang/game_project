--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-19 16:21:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-19 17:31:38
FilePath: /SlotNirvana/src/GameModule/CardNovice/views/CardNoviceDoubleRewardMainLayer.lua
Description: 新手期集卡 双倍奖励 主弹板
--]]
local CardNoviceDoubleRewardMainLayer = class("CardNoviceDoubleRewardMainLayer", BaseLayer)

function CardNoviceDoubleRewardMainLayer:initDatas(_bInCardView)
    CardNoviceDoubleRewardMainLayer.super.initDatas(self)

    self.m_data = G_GetMgr(G_REF.CardNoviceSale):getData()
    self.m_bInCardView = _bInCardView
    self:setKeyBackEnabled(true)
    self:setName("CardNoviceDoubleRewardMainLayer")
    self:setLandscapeCsbName("NewUserAlbum_DoubleReward/Activity/csd/Activity_NewUserAlbum_DoubleReward.csb")
end

function CardNoviceDoubleRewardMainLayer:initCsbNodes()
    CardNoviceDoubleRewardMainLayer.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
end

function CardNoviceDoubleRewardMainLayer:initView()
    CardNoviceDoubleRewardMainLayer.super.initView(self)

    -- 时间
    self.m_scheduler = schedule(self, util_node_handler(self, self.onUpdateSec), 1)
    self:onUpdateSec()

    self:setButtonLabelContent("btn_go", "GET IT")

    self:runCsbAction("idle", true)
end

function CardNoviceDoubleRewardMainLayer:onUpdateSec()
    local expireAt = self.m_data:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self.m_lbTime:setString(timeStr)

    if bOver then
        self:clearScheduler()
        self:closeUI()
    end
end

function CardNoviceDoubleRewardMainLayer:clickFunc(sender)
    local senderName = sender:getName()

    if senderName == "btn_close" then
        self:closeUI()
    elseif senderName == "btn_go" then
        if self.m_bInCardView then
            self:closeUI()
            return
        end

        -- 跳转卡牌系统
        local cb = function() 
            if CardSysManager:isDownLoadCardRes() then
                CardSysRuntimeMgr:setIgnoreWild(true)
                CardSysManager:enterCardCollectionSys()
            end
        end
        self:closeUI(cb)
    end
end

-- 清楚定时器
function CardNoviceDoubleRewardMainLayer:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end


function CardNoviceDoubleRewardMainLayer:closeUI(_cb)
    if self.m_bClose then
        return
    end
    self.m_bClose = true
    
    CardNoviceDoubleRewardMainLayer.super.closeUI(self, _cb)
end

return CardNoviceDoubleRewardMainLayer