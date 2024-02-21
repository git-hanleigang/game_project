--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 16:55:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 16:55:57
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/machine/MarqueeRewardItemUI.lua
Description: 扩圈小游戏 跑马灯 道具
--]]
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")
local MarqueeRewardItemUI = class("MarqueeRewardItemUI", BaseView)

function MarqueeRewardItemUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Ring_reward.csb"
end

function MarqueeRewardItemUI:initUI(_rewardData)
    MarqueeRewardItemUI.super.initUI(self)
    self.m_rewardData = _rewardData

    -- 道具 显隐
    self:updateItemVisible(_rewardData)
end

-- 道具 显隐
function MarqueeRewardItemUI:updateItemVisible(_rewardData)
    if not _rewardData then
        self:setVisible(false)
        return
    end

    self:setVisible(true)
    local rewardType =  _rewardData:getRewardType()
    local nodeContent = self:findChild("node_ring_piece")
    for _, _node in pairs(nodeContent:getChildren()) do
        local nodeName = _node:getName()
        _node:setVisible(nodeName == ExpandGameMarqueeConfig.TYPE_NODE_NAME[rewardType])
    end

    if ExpandGameMarqueeConfig.TYPE_NODE_NAME[rewardType] == "node_coin" then
        -- 金币
        self:updateCoinLbUI(_rewardData)
    elseif ExpandGameMarqueeConfig.TYPE_NODE_NAME[rewardType] == "node_X" then
        -- 成倍
        self:updateMulLbUI(_rewardData)
    end
end

-- 金币
function MarqueeRewardItemUI:updateCoinLbUI(_rewardData)
    local rewardType = _rewardData:getRewardType()
    local coinsV = _rewardData:getValue()

    local lbSmall = self:findChild("lb_coin_small")
    local lbBig = self:findChild("lb_coin_big")
    lbSmall:setString(util_formatCoins(coinsV, 3))
    lbBig:setString(util_formatCoins(coinsV, 3))

    lbSmall:setVisible(rewardType == "B")
    lbBig:setVisible(rewardType == "A")
end

-- 成倍
function MarqueeRewardItemUI:updateMulLbUI(_rewardData)
    local lbMul = self:findChild("lb_X")
    local mulV = _rewardData:getValue()

    lbMul:setString("X"..mulV)
end

return MarqueeRewardItemUI