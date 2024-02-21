--
-- 大厅展示图
--
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelHourDealHallNode = class("LevelHourDealHallNode", LevelFeature)

function LevelHourDealHallNode:createCsb()
    self:createCsbNode("Promotion_HourDeal/Icons/Promotion_HourDeal/HourDealHall.csb")
    self:initView()
end

function LevelHourDealHallNode:initView()
    self.m_lb_time = self:findChild("lb_time")
    
    local updateTimeLable = function()
        local gameData = G_GetMgr(G_REF.HourDeal):getRunningData()
        if gameData == nil or not gameData:isRunning() then
            self.m_lb_time:stopAllActions()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_TIMEOUT)
        else
            local count = gameData:getNoExtractCount()
            if count <= 0 then
                self.m_lb_time:stopAllActions()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_TIMEOUT)
            else
                local strLeftTime = util_daysdemaining(gameData:getShowExpireAt(), true)
                self.m_lb_time:setString(strLeftTime)
            end
        end
    end
    util_schedule(self.m_lb_time, updateTimeLable, 1)
    updateTimeLable()
end

function LevelHourDealHallNode:clickFunc(sender)
    local gameData = G_GetMgr(G_REF.HourDeal):getRunningData()
    if gameData then
        local leftShowTime = gameData:getLeftShowTime()
        local count = gameData:getNoExtractCount()
        if leftShowTime <= 0 then
            G_GetMgr(G_REF.HourDeal):showExtendSaleLayer()
        else
            G_GetMgr(G_REF.HourDeal):showMainLayer()
        end
    end
end

return LevelHourDealHallNode
