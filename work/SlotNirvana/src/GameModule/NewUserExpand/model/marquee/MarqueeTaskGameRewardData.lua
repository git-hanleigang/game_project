--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-09 17:34:47
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-09 17:37:31
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/marquee/MarqueeTaskGameRewardData.lua
Description: 跑马灯游戏 奖励
--]]
local MarqueeTaskGameData = class("MarqueeTaskGameData")
-- 奖励-Type-res-颜色：
-- 大金币-C-A-7
-- 小金币-C-B-4
-- 乘倍-X-C-1
-- 炸弹-B-D-3
function MarqueeTaskGameData:parseData(_data)
    self.m_rewardType = _data.type or "" -- 类型
    self.m_resName = _data.res or "" -- 背景资源
    self.m_value = tonumber(_data.value) or 0 -- 奖励值
end

function MarqueeTaskGameData:getRewardType()
    return self.m_resName or ""
end
function MarqueeTaskGameData:getBgResName()
    return self.m_resName or ""
end
function MarqueeTaskGameData:getValue()
    return self.m_value or 0
end

return MarqueeTaskGameData