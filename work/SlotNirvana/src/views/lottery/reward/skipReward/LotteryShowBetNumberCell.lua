--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-11 16:48:31
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-11 16:48:35
FilePath: /SlotNirvana/src/views/lottery/reward/skipReward/LotteryShowBetNumberCell.lua
Description: 乐透 按跳过 本期个人所选号码 cell 
--]]
local LotteryYoursCell = util_require("views.lottery.base.LotteryYoursCell")
local LotteryShowBetNumberCell = class("LotteryShowBetNumberCell", LotteryYoursCell)

function LotteryShowBetNumberCell:getCsbName()
    return "Lottery/csd/Choose/Lottery_Reward_number_cell.csb"
end

-- 初始化节点
function LotteryShowBetNumberCell:initCsbNodes()
    LotteryShowBetNumberCell.super.initCsbNodes(self)

    self.m_lbOrder = self:findChild("lb_idx")
end

function LotteryShowBetNumberCell:updateView()
    LotteryShowBetNumberCell.super.updateView(self)

    self.m_lbOrder:setString(self.m_order)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbOrder, 70)
end

return LotteryShowBetNumberCell