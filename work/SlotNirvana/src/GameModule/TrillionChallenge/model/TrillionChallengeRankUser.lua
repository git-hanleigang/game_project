--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:26:20
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/model/TrillionChallengeRankUser.lua
Description: 亿万赢钱挑战 排行榜 玩家数据
--]]
local TrillionChallengeRankUser = class("TrillionChallengeRankUser")
function TrillionChallengeRankUser:ctor(_data)
    self._points = tonumber(_data.points) or 0
    self._rank = _data.rank or 0
    self._udid = _data.udid or ""
    self._name = _data.name or ""
    self._fbId = _data.facebookId or ""
    self._head = _data.head
    self._frameId = _data.frame

    self._bMe = self._udid == globalData.userRunData.userUdid
end

function TrillionChallengeRankUser:setCurTotalWin(_value)
    self._points = tonumber(_value) or 0
end
function TrillionChallengeRankUser:getPoints()
    return self._points or 0
end
--成员名称
function TrillionChallengeRankUser:getName()
    if self._bMe then
        self._name = globalData.userRunData.nickName
    end
    return self._name
end
--头像
function TrillionChallengeRankUser:getHead()
    if self._bMe then
        self._head = globalData.userRunData.HeadName
    end
    return self._head
end
--用户udid
function TrillionChallengeRankUser:getUdid()
    return self._udid
end
--用户头像框
function TrillionChallengeRankUser:getFrameId()
    if self._bMe then
        self._frameId = globalData.userRunData.avatarFrameId
    end
    return self._frameId
end
--facebook ID
function TrillionChallengeRankUser:getFacebookId()
    return self._fbId
end
--排名
function TrillionChallengeRankUser:setRank(_rank)
    self._rank = tonumber(_rank) or 0
end
function TrillionChallengeRankUser:getRank()
    return self._rank
end

function TrillionChallengeRankUser:checkIsMe()
    return self._bMe
end

return TrillionChallengeRankUser