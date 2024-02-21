--[[

    author:{author}
    time:2020-07-21 10:52:08
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local RepartWinData = class("RepartWinData", BaseActivityData)

function RepartWinData:ctor()
    self.p_maxWinCoins = toLongNumber(0)
end

--[[
    message RepeatWinConfig { // NewUserRepeatWinConfig
        optional int32 multiple = 1; //返奖倍数
        optional string end = 2; //结束时间 格式：2019-06-15 10:10:10
        optional int64 maxWinCoins = 3; //已记录的最高大赢
        optional bool open = 4; // 开启状态
        optional int32 expire = 5; //剩余秒数
        optional string activityId = 6; //活动id
        optional int64 expireAt = 7; // 配置过期时间
        optional string maxWinCoinsV2 = 8; //已记录的最高大赢
    }
]]
function RepartWinData:parseData(data)
    RepartWinData.super.parseData(self, data)
    self.p_multiple = data.multiple
    self.p_end = data["end"]
    self.p_maxWinCoins:setNum(data.maxWinCoins)
    if data.maxWinCoinsV2 and data.maxWinCoinsV2 ~= "" then
        self.p_maxWinCoins:setNum(data.maxWinCoinsV2)
    end
    self.p_isBuy = data.open
    self.p_expire = data.expire
    self.p_activityId = data.activityId
    self.p_expireAt = tonumber(data.expireAt)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_SALE_GAMENODE)
end

function RepartWinData:updateRepeatWinRequest()
    if self.m_expireRepeatWinHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_expireRepeatWinHandlerId)
    end
    if self.p_expire then
        local expireUpdateTime = math.floor((self.p_expireAt - globalData.userRunData.p_serverTime) / 1000)
        if expireUpdateTime == 0 or expireUpdateTime > self.p_expire then
            expireUpdateTime = self.p_expire
        end
        if expireUpdateTime <= 0 then
            expireUpdateTime = 0
            return
        end
        -- local expireUpdateTime = 1
        self.m_expireRepeatWinHandlerId =
            scheduler.performWithDelayGlobal(
            function()
                gLobalSendDataManager:getNetWorkFeature():sendQueryRepeatWinConfig()
            end,
            expireUpdateTime,
            "RepeatWinConfig"
        )
    end
end

-- 是否已经购买
function RepartWinData:isBuy()
    return self.p_isBuy or false
end

return RepartWinData
