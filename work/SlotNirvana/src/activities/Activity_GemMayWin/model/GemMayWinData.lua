--[[
    第二货币抽奖
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local GemMayWinData = class("GemMayWinData",BaseActivityData)

-- message GemMayWin {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int64 winGems = 4;//本次spin可得
--     optional int64 needGems = 5;//本次spin所需
--     optional int32 remainingTimes = 6;//>0表示可以继续spin
--     optional int32 showRemainingTimes = 7;//临时添加显示的剩余次数
--   }
function GemMayWinData:parseData(_data)
    GemMayWinData.super.parseData(self, _data)

    self.p_winGems = tonumber(_data.winGems)
    self.p_needGems = tonumber(_data.needGems)
    self.p_remainingTimes = tonumber(_data.remainingTimes)
    self.p_showRemainingTimes = _data.showRemainingTimes
end

function GemMayWinData:getWinGems()
    return self.p_winGems
end

function GemMayWinData:getNeedGems()
    return self.p_needGems
end

function GemMayWinData:isCanSpin()
    return self.p_remainingTimes > 0
end

function GemMayWinData:getShowRemainingTimes()
    return self.p_showRemainingTimes
end

return GemMayWinData
