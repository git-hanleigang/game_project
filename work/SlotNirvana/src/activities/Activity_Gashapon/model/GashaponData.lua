--[[
Author: ZKK
Date: 2022-04-19 12:28:18
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BaseActivityData = require "baseActivity.BaseActivityData"
local GashaponData = class("GashaponData", BaseActivityData)


function GashaponData:parseData(data)
    GashaponData.super.parseData(self, data)
    if not self.m_gashaponPoint_Front then
        self.m_gashaponPoint_Front = data.props
    else
        if self.m_gashaponPoint then
            self.m_gashaponPoint_Front = self.m_gashaponPoint
        end
    end
    self.m_gashaponPoint = data.props --可用抽奖机会
    self.m_gashaponPoint_add = self.m_gashaponPoint - self.m_gashaponPoint_Front
    self.m_gashaponBigReward = {}
    if  data.displays then
        for i,v in ipairs(data.displays) do
            local rewardData = {}

            local shopItem = ShopItem:create()
            shopItem:parseData(v.item,true)
            rewardData.item = shopItem
            
            rewardData.phaseNumVec = v.phaseNum
            rewardData.lastLeftNum = v.lastLeftNum  --上次抽奖的次数
            rewardData.originNum = v.phaseNum[1]
            rewardData.currentNum = tonumber(v.phaseNum[1]) -- 当前数量 计算得
            self.m_gashaponBigReward[i] = rewardData
        end
    end
    
end

return GashaponData
