--[[
    周三公会积分双倍获取活动弹窗
    author:lishuai
    time:2023-08-14 10:52:08
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local ClanDoublePointsData = class("ClanDoublePointsData", BaseActivityData)
local clanMgr = util_require("manager.System.ClanManager"):getInstance()

function ClanDoublePointsData:ctor(data)
    ClanDoublePointsData.super.ctor(self)
    self.isFirst = true
end

function ClanDoublePointsData:parseData(data)
    ClanDoublePointsData.super.parseData(self, data)

    self.p_multiple = data.multiple
    self.p_inClan = data.inClan
end

function ClanDoublePointsData:isRunning()
    if not ClanDoublePointsData.super.isRunning(self) then
        return false
    end

    --是否加入公会
    if not self:getIsClanMember() then 
        return false
    end

    return true
end

function ClanDoublePointsData:getIsClanMember()
     --是否加入公会
    local bTeamMember = false
    if self.isFirst then
        bTeamMember = self.p_inClan
    else
        bTeamMember = clanMgr:checkIsMember() 
    end
    return bTeamMember
end

return ClanDoublePointsData
