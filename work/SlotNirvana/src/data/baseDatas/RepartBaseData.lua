--[[
    author:{author}
    time:2019-04-18 21:53:40
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local RepartBaseData = class("RepartBaseData",BaseActivityData)

function RepartBaseData:ctor()
    self.m_curPrize = toLongNumber(0)
    self.m_limit = toLongNumber(0)
end

--[[
    message RepeatConfig {
        optional int32 expire = 1; //剩余秒数
        optional int64 expireAt = 2; //过期时间
        optional string activityId = 3; //活动id
        optional string begin = 4;
        optional int64 limit = 5; //上限值
        optional int64 prize = 6; //jackpot奖励
        optional int64 multiple = 7; //当前奖励限制（bet X multiple）
        optional bool active = 8;// 活动是否激活
        optional string purchaseMul = 9; // 付费倍数
        optional string limitV2 = 10; //上限值V2
        optional string prizeV2 = 11; //jackpot奖励V2
    }
]]
function RepartBaseData:parseData(data)
    BaseActivityData.parseData(self,data)
    local lastPrize = self.m_curPrize
    self.m_curPrize:setNum(data.prize)              --当前奖池
    if data.prizeV2 and data.prizeV2 ~= "" then
        self.m_curPrize:setNum(data.prizeV2)
    end
    self.m_multiple = tonumber(data.multiple)           --当前奖励限制（bet X multiple）
    self.m_limit:setNum(data.limit)                 --上限值
    if data.limitV2 and data.limitV2 ~= "" then
        self.m_limit:setNum(data.limitV2)
    end
    self.m_lastActive = self.m_active                   --上次活动状态
    self.m_active = data.active                         --活动是否激活
    self.m_begin = data.begin                           --开始时间 打点使用
    if tolua.type(data.purchaseMul) == "table" then
        self.m_purchaseMul = data.purchaseMul
    elseif tolua.type(data.purchaseMul) == "string" and data.purchaseMul ~= "" then
        self.m_purchaseMul = cjson.decode(data.purchaseMul) --付费倍数
    end
    if lastPrize and lastPrize > toLongNumber(0) and lastPrize ~= self.m_curPrize then
        --奖池刷新提示
        self.m_updatePrize = true
    end
    if self.m_lastActive == false and self.m_active == true then
        --购买成功提示
        self.m_isBuyTips = true
    end
end
--获取刷新提示
function RepartBaseData:isUpdatePrizeTips()
    return self.m_updatePrize
end
--清空刷新提示
function RepartBaseData:clearPrizeTips()
    self.m_updatePrize = nil
end
--购买后是否提示
function RepartBaseData:isBuyTips()
    return self.m_isBuyTips
end
--清空购买提示
function RepartBaseData:clearBuyTips()
    self.m_isBuyTips = nil
end
--当前奖池
function RepartBaseData:getCurrentPrize()
    return self.m_curPrize
end
--奖池上线
function RepartBaseData:getLimitPrize()
    return self.m_limit
end
--获得奖励倍数
function RepartBaseData:getBetMultiple()
    return self.m_multiple
end
--活动是否激活
function RepartBaseData:isAlive()
    return self.m_active
end
--获取结束时间字符串
function RepartBaseData:getStrEndTime()
    local tm = os.date("*t",self:getExpireAt())
    local strEndTime = string.format("%d-%02d-%02d",tm.year,tm.month,tm.day)
    return strEndTime
end
--获取描述信息
function RepartBaseData:getStrPrize()
    return ""
end

return RepartBaseData