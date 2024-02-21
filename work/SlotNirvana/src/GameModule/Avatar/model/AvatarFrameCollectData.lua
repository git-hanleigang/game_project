--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-17 17:38:37
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-17 17:41:03
FilePath: /SlotNirvana/src/GameModule/Avatar/model/AvatarFrameCollectData.lua
Description: 头像框 用户获得的数据
--]]
local AvatarFrameCollectData = class("AvatarFrameCollectData")

-- optional string name = 1; //名称
-- optional int64 collectAt = 2; //收藏时间
-- optional int64 expireAt = 3; //过期时间
function AvatarFrameCollectData:ctor(_data)
    self.m_farmeId = _data.name or ""
    self.m_collectAt = tonumber(_data.collectAt) or 0
    self.m_expireAt = tonumber(_data.expireAt) or 0

    self.name = _data.name or ""
    self.collectAt = tonumber(_data.collectAt) or 0
    self.expireAt = tonumber(_data.expireAt) or 0

    -- self.m_expireAt = util_getCurrnetTime()*1000 + 40000
end

function AvatarFrameCollectData:getFrameId()
    return self.m_farmeId
end
function AvatarFrameCollectData:getCollectTimeSec()
    return math.floor(self.m_collectAt * 0.001)
end
function AvatarFrameCollectData:getExpireTimeSec()
    return math.floor(self.m_expireAt * 0.001)
end

function AvatarFrameCollectData:checkIsEnbaled()
    if not self:checkIsTimeLimitType() then
        return string.len(self.m_farmeId) > 0
    end

    return string.len(self.m_farmeId) > 0 and self:getExpireTimeSec() > util_getCurrnetTime()
end

function AvatarFrameCollectData:checkIsTimeLimitType()
    return self:getExpireTimeSec() > 0
end
 

return AvatarFrameCollectData