--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-01-04 14:24:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-01-04 14:24:52
FilePath: /SlotNirvana/src/data/clanData/ClanSearchUserData.lua
Description: 公会搜索玩家 玩家数据
--]]
local ClanSearchUserData = class("ClanSearchUserData")
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanSearchUserData:ctor()
    self.m_name = "" --成员名称
    self.m_head = 0 --图像
    self.m_uid = "" --用户id
    self.m_udid = "" --用户udid
    self.m_frameId = "" --用户头像框
    self.m_facebookId = "" --facebook ID
    self.m_teamName = "" --公会名称
    self.m_status = ClanConfig.userState.NON --0：未入会，也未申请；1：未入会，已申请；2：已入会
end

function ClanSearchUserData:parseData(_data)
    if not _data then
        return
    end

    self.m_name = _data.name or "" --成员名称
    self.m_head = _data.head or 0 --图像
    self.m_uid = _data.uid or "" --用户id
    self.m_udid = _data.udid or "" --用户udid
    self.m_frameId = _data.frame or "" --用户头像框
    self.m_facebookId = _data.facebookId or "" --facebook ID
    self.m_teamName = _data.clanName or "" --公会名称
    self.m_status = _data.status or ClanConfig.userState.NON --0：未入会，也未申请；1：未入会，已申请；2：已入会
end

--成员名称
function ClanSearchUserData:getName()
    return self.m_name
end
--图像
function ClanSearchUserData:getHead()
    return self.m_head
end
--用户id
function ClanSearchUserData:getUid()
    return self.m_uid
end
--用户udid
function ClanSearchUserData:getUdid()
    return self.m_udid
end
--用户头像框
function ClanSearchUserData:getFrameId()
    return self.m_frameId
end
--facebook ID
function ClanSearchUserData:getFacebookId()
    return self.m_facebookId
end
--公会名称
function ClanSearchUserData:getTeamName()
    return self.m_teamName
end
--0：未入会，也未申请；1：未入会，已申请；2：已入会
function ClanSearchUserData:getTeamStatus()
    return self.m_status
end

return ClanSearchUserData