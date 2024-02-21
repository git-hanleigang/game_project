--[[
    生日礼物促销 展示图
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelBirthdaySaleHallNode = class("LevelBirthdaySaleHallNode", LevelFeature)

function LevelBirthdaySaleHallNode:createCsb()
    LevelBirthdaySaleHallNode.super.createCsb(self)
    self:createCsbNode("Activity_Birthday/Promotion/Icons/Promotion_BirthdayHall.csb")
    self:runCsbAction("idle", true)
    self:initView()
end

function LevelBirthdaySaleHallNode:initView()
    
    local updateTime = function()
        local data = G_GetMgr(ACTIVITY_REF.Birthday):getRunningData()
        if data then
            local expireAt = data:getSaleExpirAt()
            local strLeftTime, isOver = util_daysdemaining(expireAt, true)
            if isOver then
                self:stopAllActions()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BIRTHDAY_PROMOTION_TIMEOUT)
            end
        else
            self:stopAllActions()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BIRTHDAY_PROMOTION_TIMEOUT)
        end
    end
    util_schedule(self, updateTime, 1)
    updateTime()
end

function LevelBirthdaySaleHallNode:clickFunc(sender)
    G_GetMgr(ACTIVITY_REF.Birthday):showBirthdayPromotionLayer()
end

return LevelBirthdaySaleHallNode