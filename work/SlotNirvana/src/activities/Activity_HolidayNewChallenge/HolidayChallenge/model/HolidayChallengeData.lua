--[[
    圣诞聚合
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local HolidayChallengeData = class("HolidayChallengeData", BaseActivityData)

--[[
    message HolidayNewChallenge {
        optional string activityId = 1; // 活动的id
        optional string activityName = 2;// 活动的名称
        optional string begin = 3;// 活动的开启时间
        optional string end = 4;// 活动的结束时间
        optional int64 expireAt = 5; // 活动倒计时
        optional int64 curPoints = 6; // 累计的点数
        optional int64 passBegin = 7;// pass的开启时间戳
        optional int64 rankBegin = 8;// 排行榜的开启时间戳
    }
]]
function HolidayChallengeData:parseData(_data)
    -- _data = self:getTestData()
    HolidayChallengeData.super.parseData(self, _data)
    self.p_curPoints = _data.curPoints
    self.p_passBegin = _data.passBegin or 0
    self.p_rankBegin = _data.rankBegin or 0
end

function HolidayChallengeData:getTestData()
    local data = {
        activityId = "HNC001",
        activityName = "Activity_HolidayNewChallenge",
        expireAt = 1702719407000,
        curPoints = 3000,
        passBegin = 1701423407000,
        rankBegin = 1701423407000,
    }
    return data
end

function HolidayChallengeData:getPositionBar()
    return 1
end

function HolidayChallengeData:getCurPoints()
    return self.p_curPoints or 0
end

function HolidayChallengeData:getPassBeginAt()
    return self.p_passBegin / 1000
end

function HolidayChallengeData:getRankBeginAt()
    return self.p_rankBegin / 1000
end

return HolidayChallengeData
