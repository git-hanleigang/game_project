--[[
    周三公会积分双倍获取活动弹窗
]]

local ClanDoublePointsControl = class("ClanDoublePointsControl", BaseActivityControl)

function ClanDoublePointsControl:ctor()
    ClanDoublePointsControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ClanDoublePoints)
end

function ClanDoublePointsControl:showLeftTime()
    local data = self:getRunningData()
    if not data then
        return false
    end
    local clanDoublePoints = util_createView("views.clan.ClanDoublePointsCountDown")
    return clanDoublePoints
end

return ClanDoublePointsControl
