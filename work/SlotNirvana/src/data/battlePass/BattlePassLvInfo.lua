--[[
    等级及宝箱数据
    author:{author}
    time:2020-09-24 11:17:17
]]
local BattlePassBoxRewardInfo = require("data.battlePass.BattlePassBoxRewardInfo")
local BattlePassLvInfo = class("BattlePassLvInfo")

function BattlePassLvInfo:ctor()
    self.p_level = 1

    self.p_freeBoxInfo = nil

    self.p_payBoxInfo = nil
end

function BattlePassLvInfo:parseData(data)
    if not data then
        return
    end

    -- 跳过当前等级需要消耗的钻石
    self.p_gems = tonumber(data.gems)
    -- 等级
    self.p_level = data.level
    -- 免费奖励
    if data:HasField("free") == true then
        if not self.p_freeBoxInfo then
            self.p_freeBoxInfo = BattlePassBoxRewardInfo:create()
        end
        self.p_freeBoxInfo:parseData(data.free)
    end
    -- 付费奖励
    if data:HasField("pay") == true then
        if not self.p_payBoxInfo then
            self.p_payBoxInfo = BattlePassBoxRewardInfo:create()
        end
        self.p_payBoxInfo:parseData(data.pay)
    end
end

-- 免费箱子
function BattlePassLvInfo:getFreeBoxInfo()
    return self.p_freeBoxInfo
end

-- 付费箱子
function BattlePassLvInfo:getPayBoxInfo()
    return self.p_payBoxInfo
end

-- 当前等级
function BattlePassLvInfo:getLevel()
    return self.p_level or 1
end

return BattlePassLvInfo
