--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-28 11:18:46
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-28 11:18:50
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/plinko/PlinkoTaskGameRewardData.lua
Description: 弹珠游戏 奖励数据
--]]
local PlinkoTaskGameRewardData = class("PlinkoTaskGameRewardData")

function PlinkoTaskGameRewardData:parseData(_coins, _bgRes)
    self.m_coins = tonumber(_coins) or 0 
    self.m_bgRes = _bgRes or ""
end

function PlinkoTaskGameRewardData:getCoins()
    return self.m_coins or 0
end

function PlinkoTaskGameRewardData:getBgRes()
    return self.m_bgRes or ""
end

return PlinkoTaskGameRewardData