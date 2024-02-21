--[[
    @desc: new pass 点位配置信息
    author:csc
    time:2021-06-23 21:52:56
]]
local CommonRewards = require "data.baseDatas.CommonRewards"
local NewPassPointConfig = class("NewPassPointConfig")

-- optional int32 level = 1;
-- optional int64 exp = 2;
-- optional bool collected = 3;
-- optional CommonRewards rewards = 4;
-- optional string description = 5;
-- optional string label = 6; // 底色
function NewPassPointConfig:ctor()
    -- 奖励等级
    self.m_level = 1
    -- 奖励经验
    self.m_exp = 0
    -- 奖励领取状态
    self.m_collected = false
    -- 奖励道具
    self.m_rewards = nil
    -- 气泡文字
    self.m_desc = ""
    -- 底色
    self.m_labelColor = "0"
end

function NewPassPointConfig:parseData(data)
    if not data then
        return
    end

    -- 奖励等级
    self.m_level = data.level
    -- 奖励经验
    self.m_exp = tonumber(data.exp)
    -- 奖励领取状态
    self.m_collected = data.collected
    if data:HasField("rewards") then
        local config = CommonRewards:create()
        config:parseData(data.rewards)
        self.m_rewards = config
    end

    -- 气泡文字
    self.m_desc = data.description or ""
    -- 底色
    self.m_labelColor = data.label or "0"
end

function NewPassPointConfig:getLevel()
    return self.m_level
end

function NewPassPointConfig:getExp()
    return self.m_exp
end

function NewPassPointConfig:getCollected()
    return self.m_collected
end

function NewPassPointConfig:getRewards()
    return self.m_rewards
end

function NewPassPointConfig:getDesc()
    return self.m_desc
end

function NewPassPointConfig:getLabelColor()
    return self.m_labelColor
end

return NewPassPointConfig
