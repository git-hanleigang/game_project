--
-- 大厅展示图
--
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelAlbumMoreAwardHallNode = class("LevelAlbumMoreAwardHallNode", LevelFeature)

function LevelAlbumMoreAwardHallNode:createCsb()
    self:createCsbNode("Activity_AlbumMoreAward/Icons/AlbumMoreAward_Hall.csb")
end

function LevelAlbumMoreAwardHallNode:initView()
    self.m_lb_number = self:findChild("lb_number")
    self.m_lb_time = self:findChild("Text_time")

    local updateTimeLable = function()
        local gameData = G_GetMgr(ACTIVITY_REF.AlbumMoreAward):getRunningData()
        if gameData then
            local multiply = gameData:getMultiply()
            local number = multiply * 100
            self.m_lb_number:setString(number .. "%")
    
            local saleExpireAt = gameData:getSaleExpireAt()
            local strLeftTime, isOver = util_daysdemaining(saleExpireAt, true)
            if isOver then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ALBUM_MORE_AWARD_TIME_END)
            else
                self.m_lb_time:setString(strLeftTime)
            end
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ALBUM_MORE_AWARD_TIME_END)
        end
    end
    util_schedule(self.m_lb_time, updateTimeLable, 1)
    updateTimeLable()    

    self:setButtonLabelContent("hallButton", "HURRY")
end

function LevelAlbumMoreAwardHallNode:clickFunc(_sender)
    G_GetMgr(ACTIVITY_REF.AlbumMoreAward):showMainLayer()
end

function LevelAlbumMoreAwardHallNode:onEnter()
    LevelAlbumMoreAwardHallNode.super.onEnter(self)
    self:initView()
end

return LevelAlbumMoreAwardHallNode
