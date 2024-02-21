--[[
    author:{author}
    time:2020-07-21 10:52:08
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local CashBackData = class("CashBackData", BaseActivityData)

function CashBackData:ctor()
    CashBackData.super.ctor(self)

    self.p_buffExpireAt = 0
    self.p_expireAt = 0
    self.p_coins = toLongNumber(0)
end

--[[
    message CashBackConfig {
        optional int32 expire = 1; // 剩余秒数
        optional string activityId = 2;
        optional int64 expireAt = 3; // 配置过期时间
        optional int32 buffExpire = 4; //buff剩余秒数
        optional int32 currentRate = 5; //当前返奖率
        optional int64 coins = 6; //已收集到的金币
        repeated BuffItem buffs = 7; //所有的CashBack buff列表，包含当前未激活buff
        optional bool open = 8; //活动是否开启
        optional bool active = 9; //CashBack是否激活
        optional string coinsV2 = 10; //已收集到的金币V2
    }
]]
function CashBackData:parseData(data)
    CashBackData.super.parseData(self, data)
    self.p_buffExpire = data.buffExpire
    self.p_currentRate = data.currentRate
    self.p_coins:setNum(data.coins)
    if data.coinsV2 and data.coinsV2 ~= "" then
        self.p_coins:setNum(data.coinsV2)
    end
    self.p_buffs = data.buffs
    self.p_buffExpireAt = 0
    --所有的cashback buff列表，包含当前未激活buff
    if data.buffs ~= nil and #data.buffs > 0 then
        self.p_buffExpireAt = globalData.userRunData.p_serverTime + self.p_buffExpire * 1000
    end

    -- 非新手期活动用 数据里的开启表， 新手期cashback使用正常活动数据
    if not self:isNovice() then
        self.p_open = data.open
        self.p_activityId = data.activityId
        self.p_expire = data.expire
        self.p_expireAt = math.max(tonumber(data.expireAt), 0)
    end 

    self.p_active = data.active
end

-- 是否忽略等级
function CashBackData:isIgnoreLevel()
    if self:getBuffFlag() then
        return true
    end

    return CashBackData.super.isIgnoreLevel(self)
end

function CashBackData:isRunning()
    if CashBackData.super.isRunning(self) then
        return true
    end

    if self.p_buffs and #self.p_buffs > 1 then
        return true
    end

    return false
end

function CashBackData:getExpireAt()
    return math.floor(math.max(self.p_expireAt, self.p_buffExpireAt) / 1000)
end

function CashBackData:getBuffFlag()
    return (self.p_buffExpireAt > self.p_expireAt)
end

function CashBackData:getType()
    if not self.p_activityType then
        local _config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.CashBack)
        if _config then
            self.p_activityType = _config.p_activityType
        end
    end
    return CashBackData.super.getType(self)
end

function CashBackData:isCanDelete()
    -- return not (self.p_buffs ~= nil and #self.p_buffs > 1)
    return self:getLeftTime() <= 0 and not (self.p_buffs ~= nil and #self.p_buffs > 1)
end

return CashBackData
