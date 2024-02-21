--[[
    圣诞聚合 -- 排行榜
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local HolidayRankData = class("HolidayRankData", BaseActivityData)
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")

function HolidayRankData:ctor()
    HolidayRankData.super.ctor(self)
    self.p_open = true
end

function HolidayRankData:parseData(_data)
    HolidayRankData.super.parseData(self, _data)
end

-- 解析排行榜信息
function HolidayRankData:parseRankConfig(_data)
    if not _data then
        return
    end

    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self:setRank(myRankConfigInfo.p_rank)
    end
end

function HolidayRankData:getRankCfg()
    return self.p_rankCfg
end

return HolidayRankData
