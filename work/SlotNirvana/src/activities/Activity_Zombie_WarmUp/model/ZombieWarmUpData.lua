--[[--
    行尸走肉预热活动
]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local ZombieWarmUpData = class("ZombieWarmUpData", BaseActivityData)

-- message ZombiePrebook {
--     optional string begin = 1;
--     optional int32 expire = 2;
--     optional int64 expireAt = 3;
--     optional string activityId = 4;
--     repeated int64 coins = 5; // 每个阶段金币
--     optional bool prebook = 6; // 是否预约
--     optional int32 players = 7; //当前预约人数
--     repeated int64 stageDemands = 8; // 每个阶段预约人数
--   }
function ZombieWarmUpData:parseData(_netData)
    ZombieWarmUpData.super.parseData(self, _netData)

    self.p_coins = {}
    if _netData.coins and #_netData.coins > 0 then
        for i=1,#_netData.coins do
            table.insert(self.p_coins, tonumber(_netData.coins[i]))
        end
    end

    self.p_prebook = _netData.prebook

    self.p_players = tonumber(_netData.players)

    self.p_stageDemands = {}
    if _netData.stageDemands and #_netData.stageDemands > 0 then
        for i=1,#_netData.stageDemands do
            table.insert(self.p_stageDemands, tonumber(_netData.stageDemands[i]))
        end
    end
end

function ZombieWarmUpData:getCoins()
    return self.p_coins
end

function ZombieWarmUpData:isPrebook()
    return self.p_prebook == true
end

function ZombieWarmUpData:getCurPlayerNum()
    return self.p_players
end

function ZombieWarmUpData:getPlayerNums()
    return self.p_stageDemands
end

return ZombieWarmUpData
