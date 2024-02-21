--[[
    网络协议数据
]]
local BaseMailData = util_require("GameModule.Inbox.model.mailData.BaseMailData")
local BaseServerMailData = class("BaseServerMailData", BaseMailData)

function BaseServerMailData:ctor()
    BaseServerMailData.super.ctor(self)
    -- 网络邮件
    self.m_isNetMail = true
    -- 有倒计时的
    self.m_isTimeLimit = true
end


-- message Awards {
--     optional int64 coins = 1;
--     optional int64 gems = 2;
--     repeated ShopItem items = 3; //额外奖励的道具和buff
--     optional int64 points = 4;
--     optional string coinsV2 = 5;
--     optional string bucks = 6;//第三货币
--   }

-- message Mail {
--     optional int64 id = 1;
--     optional string title = 2;
--     optional string content = 3;
--     required MailType type = 4;
--     optional Awards awards = 5;
--     required string status = 6;
--     optional string validStart = 7;
--     optional string validEnd = 8;
--     optional string udid = 9;
--     optional string extra = 10;
--     optional int64 expireAt = 11;
--   }

function BaseServerMailData:parseData(_netData)
    BaseServerMailData.super.parseData(self, _netData)
    self.title = _netData.title
    self.content = _netData.content
    self.awards = _netData.awards
    self.status = _netData.status
    self.validStart = _netData.validStart
    self.validEnd = _netData.validEnd
    self.udid = _netData.udid
    self.extra = _netData.extra
    self.expireAt = _netData.expireAt
end

-- 该邮件涉及常规集卡
function BaseServerMailData:isCardType()
    if self.type == "CARD" then
        return true
    end
    return false
end

-- 结束时间(单位：秒)
function BaseServerMailData:getExpireTime()
    local endTime = 0
    if self.expireAt and self.expireAt ~= "" and self.expireAt ~= 0 then
        endTime = tonumber(self.expireAt) / 1000
    elseif self.validEnd then
        endTime = util_getymd_time(self.validEnd)
    end
    return endTime
end

function BaseServerMailData:getLeftTime()
    local endTime = self:getExpireTime() or 0
    local leftTime  = endTime - util_getCurrnetTime()
    if leftTime > 0 then
        return leftTime
    end
    return 0
end

return BaseServerMailData
