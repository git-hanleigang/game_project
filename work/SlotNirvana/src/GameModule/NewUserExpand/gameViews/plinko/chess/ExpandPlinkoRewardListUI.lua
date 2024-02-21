--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 20:04:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 20:05:19
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/chess/ExpandPlinkoRewardListUI.lua
Description: 扩圈小游戏 弹珠 底部奖励 lsitUI
--]]
local ExpandPlinkoRewardListUI = class("ExpandPlinkoRewardListUI", BaseView)

function ExpandPlinkoRewardListUI:initDatas(_gameData)
    ExpandPlinkoRewardListUI.super.initDatas(self)

    self.m_rewardList = _gameData:getRewardList() 
end

function ExpandPlinkoRewardListUI:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_Reward_map.csb"
end

function ExpandPlinkoRewardListUI:initUI()
    ExpandPlinkoRewardListUI.super.initUI(self)

    -- 奖励
    self:initRewardListUI()
end

-- 奖励
function ExpandPlinkoRewardListUI:initRewardListUI()
    self.m_rewardNodeList = {}
    for i=1, 6 do
        local node = self:findChild("node_reward_" .. i)
        local rewardData = self.m_rewardList[i]
        local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.chess.ExpandPlinkoRewardUI", rewardData)
        node:addChild(view)
        self.m_rewardNodeList[i] = view
    end
end

function ExpandPlinkoRewardListUI:playRewardColAni(_idx, _cb)
    local curSpinHitIdx = _idx
    self.m_rewardNodeList[curSpinHitIdx]:playRewardColAni(_cb)
end

return ExpandPlinkoRewardListUI