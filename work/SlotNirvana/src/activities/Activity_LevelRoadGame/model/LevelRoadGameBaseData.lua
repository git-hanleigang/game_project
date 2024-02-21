--[[
    LevelRoadGame 小游戏数据层 解析服务器发来的数据

    message LevelRoadGameResult {
        optional int32 index = 1; // 小游戏序号
        optional int32 v = 2; // 玩家的v
        optional string status = 3; // 游戏的状态   INIT 在邮箱里， FINISH 校验游戏完成 10次付费后 变为INIT    领奖后结束，变为END 
        repeated int32 rewardMultiple = 4;// 奖励乘倍 -- 配置的左边竖条倍率
        optional int64 realTimeCoins = 5; // 最终的奖励
        optional int32 multiple = 6; // 最终的乘倍
        optional int64 baseCoins = 7; // 基底
        optional int32 selectNumber = 8; //选择的次数   -- 游戏开始 10次， 校验消息 0次， 付费后 15次
        repeated string free = 9; // 选择的结果 免费
        repeated string pay = 10; // 选择的结果 付费
        optional int64 expireAt = 11; //小游戏过期时间
        optional string key = 12; // 付费的档位
        optional string price = 13;// 付费的价格
        optional string keyId = 14;// 付费的链接
        optional bool payUnLocked = 15;// 是否付费
    }
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local LevelRoadGameBaseData = class("LevelRoadGameBaseData",BaseActivityData)

function LevelRoadGameBaseData:parseData(_data)
    LevelRoadGameBaseData.super.parseData(self, _data)

    self.p_index = _data.index
    self.p_v = _data.v
    self.p_status = _data.status
    self.p_rewardMultiple = _data.rewardMultiple
    self.p_realTimeCoins = _data.realTimeCoins
    self.p_multiple = _data.multiple
    self.p_baseCoins = _data.baseCoins
    self.p_selectNumber = _data.selectNumber
    self.p_free = _data.free
    self.p_pay = _data.pay
    self.p_expireAt = _data.expireAt
    self.p_key = _data.key
    self.p_price = _data.price
    self.p_keyId = _data.keyId
    self.p_payUnLocked = _data.payUnLocked
    
end

function LevelRoadGameBaseData:getIndex()
    return self.p_index
end

-- 获取现在游戏状态，INIT在邮箱里，FINISH 游戏完成
function LevelRoadGameBaseData:getStatus()
    return self.p_status
end

-- 获取剩余时间
function LevelRoadGameBaseData:getExpirationTime()
    local t = tonumber(self:getExpireAt())
    return t
end

-- repeated int32 rewardMultiple = 4;// 奖励乘倍
-- optional int64 realTimeCoins = 5; // 最终的奖励
-- optional int32 multiple = 6; // 最终的乘倍
-- optional int64 baseCoins = 7; // 基底

function LevelRoadGameBaseData:getRewardMultiple()   -- 数组
    return  self.p_rewardMultiple
end

function LevelRoadGameBaseData:getRealTimeCoins()
    return self.p_realTimeCoins
end

function LevelRoadGameBaseData:getMultiple()     -- 最终的乘倍
    return self.p_multiple
end

function LevelRoadGameBaseData:getBaseCoins()
    return self.p_baseCoins
end

function LevelRoadGameBaseData:getFreeList()
    return self.p_free
end

function LevelRoadGameBaseData:getFreeQueue()
    local queue = {}
    for i = 1, 8 do
        local t = tonumber(self.p_free[i])
        for j = 1, t do
            queue[#queue + 1] = i
        end
    end
    return queue
end

function LevelRoadGameBaseData:getPayQueue()
    local queue = {}
    -- for i = 1, 8 do
    --     if self.p_pay[i] == "1" then
    --         queue[#queue + 1] = i
    --     elseif self.p_pay[i] == "2" then
    --         queue[#queue + 1] = i
    --         queue[#queue + 1] = i
    --     elseif self.p_pay[i] == "3" then
    --         queue[#queue + 1] = i
    --         queue[#queue + 1] = i
    --         queue[#queue + 1] = i
    --     end
    -- end
    for i = 1, 8 do
        local t = tonumber(self.p_pay[i])
        for j = 1, t do
            queue[#queue + 1] = i
        end
    end
    return queue
end

function LevelRoadGameBaseData:getSelectNumber()
    return self.p_selectNumber
end


-- optional string key = 12; // 付费的档位
-- optional string price = 13;// 付费的价格
-- optional string value = 14;// 付费的链接

-- 付费的相关数据
function LevelRoadGameBaseData:getKey()
    return self.p_key
end

function LevelRoadGameBaseData:getPrice()
    return self.p_price
end

function LevelRoadGameBaseData:getKeyId()
    return self.p_keyId
end

function LevelRoadGameBaseData:isPayUnLocked()
    return self.p_payUnLocked == true
end

-- 是否可玩
function LevelRoadGameBaseData:isCanPlay()
    -- 计算过期
    if globalData.userRunData.p_serverTime * 0.001 - self:getExpirationTime() >= 0 then
        return false
    end

    -- -- 判断是否结束 没有次数，也不付费
    -- if not self:getSelectNumber() and self:getStatus()then
    --     return false
    -- end

    return true
end

return LevelRoadGameBaseData

