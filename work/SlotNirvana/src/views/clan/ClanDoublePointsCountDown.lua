--[[
Author: lishuai
Date: 2023-08-14 15:35:56
LastEditTime: 2023-08-17 15:36:03
LastEditors: 
Description: 公会双倍积分倒计时
FilePath: /SlotNirvana/src/views/clan/ClanDoublePointsCountDown.lua
--]]

local ClanDoublePointsCountDown = class("ClanDoublePointsCountDown", BaseView)

function ClanDoublePointsCountDown:initUI()
    local csbName = "Club/csd/ClanDoublePoints.csb"
    self:createCsbNode(csbName)

    self.m_lbTime = self:findChild("lb_time")

    self:initTime()
end

function ClanDoublePointsCountDown:initTime()
    local updateTimeLable = function()
        local data = G_GetMgr(ACTIVITY_REF.ClanDoublePoints):getRunningData()
        if not data then
            self.m_lbTime:stopAllActions()
            self:setVisible(false)
            return 
        end 
        local expireAt = data:getExpireAt()
        local time ,isOver = util_daysdemaining(expireAt, true)
        if isOver then
            self.m_lbTime:stopAllActions()
            self:setVisible(false)
        else
            self.m_lbTime:setString(tostring(time))
        end
    end
    util_schedule(self.m_lbTime, updateTimeLable, 1)
    updateTimeLable()
end

return ClanDoublePointsCountDown