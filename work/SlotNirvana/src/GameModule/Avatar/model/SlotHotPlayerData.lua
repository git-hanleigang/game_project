--[[
Author: cxc
Date: 2022-04-20 16:51:43
LastEditTime: 2022-04-20 16:51:44
LastEditors: cxc
Description: 关卡 热玩 玩家数据
FilePath: /SlotNirvana/src/GameModule/Avatar/model/SlotHotPlayerData.lua
--]]
local SlotHotPlayerData = class("SlotHotPlayerData")

function SlotHotPlayerData:ctor()
    self.m_udid = ""
    self.m_headId = ""
    self.m_fbId = ""
    self.m_robotName = ""
    self.m_nickName = ""
    self.m_avatarFrameId = ""
    self.m_score = 0
end

function SlotHotPlayerData:parseData(_data)
    self.m_udid = _data.udid or ""
    self.m_headId = _data.head or ""
    self.m_fbId = _data.facebookId or ""
    self.m_robotName = _data.robot or ""
    self.m_nickName = _data.nickName or ""
    self.m_avatarFrameId = _data.frame or ""
    self.m_score = _data.score or 0
end

-- get udid
function SlotHotPlayerData:getUdid()
    return self.m_udid
end
-- get game头像id
function SlotHotPlayerData:getHeadId()
    return self.m_headId
end
-- get facebook id
function SlotHotPlayerData:getFbId()
    return self.m_fbId
end
-- get 机器人名字
function SlotHotPlayerData:getRobotName()
    return self.m_robotName
end
-- get 玩家昵称
function SlotHotPlayerData:getNickName()
    return self.m_nickName
end
-- get 头像框id
function SlotHotPlayerData:getAvatarFrameId()
    return self.m_avatarFrameId
end
-- get 当前分数
function SlotHotPlayerData:getScore()
    return self.m_score
end

-- get 数据zorder优先级
function SlotHotPlayerData:getPriority()
    local priority = 1
    if tostring(self.m_avatarFrameId) == "" then
        return 1
    end

    local resInfo = G_GetMgr(G_REF.AvatarFrame):getAvatarFrameResPath(self.m_avatarFrameId)
    if not resInfo or not resInfo.season then
        return 1
    end

    local resType = resInfo.type
    priority = tonumber(resType .. "00" .. resInfo.season )
    return priority
end

return SlotHotPlayerData