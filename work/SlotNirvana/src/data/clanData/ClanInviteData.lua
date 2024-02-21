--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-27 16:01:12
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-27 16:01:20
FilePath: /SlotNirvana/src/data/clanData/ClanInviteData.lua
Description: 公会受邀请数据
--]]
local ClanInviteData = class("ClanInviteData") 
local ClanBaseInfoData = util_require("data.clanData.ClanBaseInfoData")

function ClanInviteData:ctor()
    self.m_inviteUid = "" --邀请人UID
    self.m_inviteUdid = "" --邀请人udid
    self.m_clanInfo = ClanBaseInfoData:create() -- 邀请公会基础信息
end

function ClanInviteData:parseData(_data)
    if not _data then
        return
    end
    
    self.m_inviteUid = _data.uid or "" --邀请人UID
    self.m_inviteUdid = _data.udid or "" --邀请人udid
    self.m_clanInfo:parseData(_data.clan) -- 邀请公会基础信息
    self.m_clanInfo:setCurMemberCount(_data.current) --成员人数
    self.m_clanInfo:setLimitMemberCount(_data.limit) --成员人数上限
end

function ClanInviteData:getInviteUid()
    return self.m_inviteUid
end

function ClanInviteData:getInviteUdid()
    return self.m_inviteUdid
end

function ClanInviteData:getClanBaseInfo()
    return self.m_clanInfo
end

return ClanInviteData