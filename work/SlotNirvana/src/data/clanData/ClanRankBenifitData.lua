--[[
Author: cxc
Date: 2022-02-26 15:18:11
LastEditTime: 2022-02-26 15:18:22
LastEditors: cxc
Description: 公会排行 权益数据
FilePath: /SlotNirvana/src/data/clanData/ClanRankBenifitData.lua
--]]
local ClanRankBenifitData = class("ClanRankBenifitData")

--   message ClanDivisionInterest {
--     optional int32 division = 1; //段位
--     optional string shopGem = 2; //钻石商城加成
--     optional string treasure = 3; //宝箱加成
--     optional string massage = 4; //消息奖励加成
--     optional string card = 5; //请求卡cd加成
--   }

function ClanRankBenifitData:ctor()
    self.m_division = 1 -- 段位
    self.m_gemsRate = 0 -- 钻石商城加成
    self.m_coinsRate = 0 -- 消息奖励加成
    self.m_boxRate = 0 -- 宝箱加成
    self.m_cardRate = 0 -- 请求卡cd加成
end

function ClanRankBenifitData:parseData(_data)
    if not _data then
        return
    end

    self.m_division = tonumber(_data.division) or 1 -- 段位
    self.m_gemsRate = tonumber(_data.shopGem) or 0 -- 钻石商城加成
    self.m_coinsRate = tonumber(_data.massage) or 0 -- 消息奖励加成
    self.m_boxRate = tonumber(_data.treasure) or 0 -- 宝箱加成
    self.m_cardRate = tonumber(_data.card) or 0 -- 请求卡cd加成    
end

-- 段位
function ClanRankBenifitData:getDivision()
    return math.max(1, self.m_division)
end

-- 钻石商城加成
function ClanRankBenifitData:getGemsRate()
    return self.m_gemsRate
end
-- 消息奖励加成
function ClanRankBenifitData:getCoinsRate()
    return self.m_coinsRate
end
-- 宝箱加成
function ClanRankBenifitData:getBoxRate()
    return self.m_boxRate
end
-- 请求卡cd加成 配的分钟 返回 小时
function ClanRankBenifitData:getCardRateHour()
    return (self.m_cardRate / 60)
end

return ClanRankBenifitData