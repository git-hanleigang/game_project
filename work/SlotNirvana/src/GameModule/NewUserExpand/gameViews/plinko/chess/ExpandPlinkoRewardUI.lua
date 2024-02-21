--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-21 14:27:26
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-21 14:29:10
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/chess/ExpandPlinkoRewardUI.lua
Description: 扩圈小游戏 弹珠 底部奖励 UI
--]]
local ExpandGamePlinkoConfig = util_require("GameModule.NewUserExpand.config.ExpandGamePlinkoConfig")
local ExpandPlinkoRewardUI = class("ExpandPlinkoRewardUI", BaseView)

function ExpandPlinkoRewardUI:initDatas(_rewardData)
    ExpandPlinkoRewardUI.super.initDatas(self)

    self.m_rewardData = _rewardData
end

function ExpandPlinkoRewardUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_Reward.csb"
end

function ExpandPlinkoRewardUI:initUI()
    ExpandPlinkoRewardUI.super.initUI(self)

    -- 奖励 背景
    self:initRewardBgUI()
    -- 奖励 金币 数UI
    self:initRewardCoinsUI()
end

-- 奖励
function ExpandPlinkoRewardUI:initRewardBgUI()
    local spBg = self:findChild("sp_reward_bg")
    local bgName = self.m_rewardData:getBgRes()
    util_changeTexture(spBg, string.format("PlinkoGame/ui/PlinkoGame_reward_%s.png", bgName))
end

-- 奖励 金币 数UI
function ExpandPlinkoRewardUI:initRewardCoinsUI()
    local lbCurReward
    local resIdx = self.m_rewardData:getBgRes()
    for i = 1, 3 do
        local lbReward = self:findChild("lb_reward_" .. i)
        lbReward:setVisible(false)
        if resIdx == i then
            lbCurReward = lbReward
        end
    end
    if not lbCurReward then
        return
    end

    lbCurReward:setVisible(true)
    local coins = self.m_rewardData:getCoins()
    lbCurReward:setString(util_formatCoins(coins, 3))
end

function ExpandPlinkoRewardUI:playRewardColAni(_cb)
    self:runCsbAction("start", false, _cb, 60)
    gLobalSoundManager:playSound(ExpandGamePlinkoConfig.SOUNDS.BALL_REWARD)
end

return ExpandPlinkoRewardUI