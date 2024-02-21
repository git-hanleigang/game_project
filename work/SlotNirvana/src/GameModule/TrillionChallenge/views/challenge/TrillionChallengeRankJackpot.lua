--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:28:13
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/challenge/TrillionChallengeRankJackpot.lua
Description: 亿万赢钱挑战 排行榜 奖池UI
--]]
local TrillionChallengeRankJackpot = class("TrillionChallengeRankJackpot", BaseView)

function TrillionChallengeRankJackpot:getCsbName()
    return "Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_rank_prize.csb"
end

-- 初始化节点
function TrillionChallengeRankJackpot:initCsbNodes()
    self.lbCoins = self:findChild("lb_coin")
    self.intLimit = self.lbCoins:getContentSize().width
end

function TrillionChallengeRankJackpot:initUI()
    TrillionChallengeRankJackpot.super.initUI(self)

    self:runCsbAction("idle", true)
end

function TrillionChallengeRankJackpot:updateUI(_coins)
    -- 奖池金币
    local coins = _coins or 0
    if coins > 0 then
        G_GetMgr(G_REF.TrillionChallenge):registerCoinAddComponent(self.lbCoins, self.intLimit, 12)
    else
        self.lbCoins:setString(util_formatCoins(coins, 99))
    end

    util_alignCenter({
        {node = self:findChild("sp_coin")},
        {node = self.lbCoins, alignX = 5}
    })

    self:setVisible(coins > 0)
end

return TrillionChallengeRankJackpot