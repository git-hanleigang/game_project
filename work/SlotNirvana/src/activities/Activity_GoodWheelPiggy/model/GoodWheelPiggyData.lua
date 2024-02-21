--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-03-17 19:35:38
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local GoodWheelPiggyData = class("GoodWheelPiggyData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")
--[[ 
    message PigDish {
    optional int32 expire = 1; //剩余秒数
    optional int64 expireAt = 2; //过期时间
    optional string activityId = 3; //活动id
    optional string begin = 4;
    optional int32 buyTimes = 5;//购买次数
    optional int32 maxTimes = 6;//最大购买次数
    optional int32 lastSeq = 7;//上次位置
    optional int32 leftCount = 8;//剩余转盘次数 0或1 0-无抽奖次数，1-有抽奖次数
    repeated int32 seq = 9;//已翻开的位置
    repeated PigDishReward rewards = 10;//奖励配置
    }
    
    message PigDishReward {
    optional int32 seq = 1; // 奖励位置
    repeated ShopItem items = 2;
    optional int64 coins = 3; //奖励金币
    optional bool collected = 4;// 是否领取
    optional string type = 5;//奖励类型：ITEM,COINS
    optional int32 big = 6;//是否是大奖 1-大奖
    }
 ]]
function GoodWheelPiggyData:ctor()
    GoodWheelPiggyData.super.ctor(self)
end

function GoodWheelPiggyData:parseData(data)
    data = data or {}
    BaseActivityData.parseData(self, data)
    self.p_buyTimes = data.buyTimes
    self.p_maxTimes = data.maxTimes
    self.p_lastSeq = data.lastSeq
    self.p_leftCount = data.leftCount
    self.p_seq = data.seq
    self:parseReward(data.rewards)
end

function GoodWheelPiggyData:parseReward(data)
    self.p_rewards = {}
    for k, v in ipairs(data) do
        local rewardData = {}
        rewardData.seq = tonumber(v.seq)
        rewardData.coins = tonumber(v.coins)
        rewardData.collected = v.collected
        rewardData.type = tostring(v.type)
        rewardData.big = tonumber(v.big)
        rewardData.items = self:parseItems(v.items)

        self.p_rewards[k] = rewardData
    end
end

function GoodWheelPiggyData:parseItems(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

-------------------------- get --------------------------
function GoodWheelPiggyData:getBuyTimes()
    return self.p_buyTimes or 0
end

function GoodWheelPiggyData:getMaxTimes()
    return self.p_maxTimes or 8
end

function GoodWheelPiggyData:getLeftTimes()
    local leftTimes = self:getMaxTimes() - self:getBuyTimes()
    return math.max(leftTimes, 0)
end

function GoodWheelPiggyData:getLeftCount()
    return self.p_leftCount or 0
end

function GoodWheelPiggyData:getLastSeq()
    return self.p_lastSeq
end

function GoodWheelPiggyData:getSeq()
    return self.p_seq[#self.p_seq]
end

function GoodWheelPiggyData:getReward()
    return self.p_rewards
end

function GoodWheelPiggyData:getRewardNum()
    return #self.p_rewards
end

function GoodWheelPiggyData:getRewardByIndex(index)
    return self.p_rewards[index]
end

function GoodWheelPiggyData:getBigIndex()
    for k, v in ipairs(self.p_rewards) do
        if v.big > 0 then
            return k
        end
    end
    return 0
end

-------------------------- check --------------------------
function GoodWheelPiggyData:checkIsReconnectPop()
    return self:getLeftCount() > 0
end

-------------------------- @derive --------------------------
-- 检查完成条件
function GoodWheelPiggyData:checkCompleteCondition()
    return self:getLeftTimes() <= 0
end

return GoodWheelPiggyData
