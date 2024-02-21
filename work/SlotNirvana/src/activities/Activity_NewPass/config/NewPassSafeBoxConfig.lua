--[[
    @desc: new pass 保险箱数据
    author:csc
    time:2021年06月29日11:07:15
]]
local CommonRewards = require "data.baseDatas.CommonRewards"
local NewPassSafeBoxConfig = class("NewPassSafeBoxConfig")
-- optional int64 total = 1;
-- optional int64 pick = 2;
-- optional CommonRewards rewards = 3;
-- optional string icons = 4; //展示图标
function NewPassSafeBoxConfig:ctor()
    -- 总进度
    self.m_totalNum = nil
    -- 当前收集
    self.m_pickNum = nil
    -- 奖励
    self.m_rewards = nil
    self.m_icons = nil
end

function NewPassSafeBoxConfig:parseData(data)
    if not data then
        return
    end
    -- 总进度
    self.m_totalNum = tonumber(data.total)
    -- 当前收集
    self.m_pickNum = tonumber(data.pick)
    -- 奖励
    if data:HasField("rewards") then
        local config = CommonRewards:create()
        config:parseData(data.rewards)
        self.m_rewards = config
    end
    self.m_icons = {}
    if data.icons and data.icons ~= "" then
        local iconList = string.split(data.icons, ";")
        if iconList and #iconList > 0 then
            for i = 1, #iconList do
                table.insert(self.m_icons, iconList[i])
            end
        end
    end

    print("----csc NewPassSafeBoxConfig parseData over")
end

function NewPassSafeBoxConfig:getTotalNum()
    return self.m_totalNum
end

function NewPassSafeBoxConfig:getCurPickNum()
    return self.m_pickNum
end

function NewPassSafeBoxConfig:getRewards()
    return self.m_rewards
end

function NewPassSafeBoxConfig:getIcons()
    return self.m_icons
end
return NewPassSafeBoxConfig
