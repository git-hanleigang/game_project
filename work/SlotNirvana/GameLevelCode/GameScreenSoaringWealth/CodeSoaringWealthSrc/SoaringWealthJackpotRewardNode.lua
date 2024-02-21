---
--SoaringWealthJackpotRewardNode.lua

local SoaringWealthJackpotRewardNode = class("SoaringWealthJackpotRewardNode",util_require("Levels.BaseLevelDialog"))

SoaringWealthJackpotRewardNode.m_machine = nil
SoaringWealthJackpotRewardNode.m_jackpot_machine = nil
SoaringWealthJackpotRewardNode.m_curIndex = nil

function SoaringWealthJackpotRewardNode:initUI(_m_machine, _jackpot_machine, _index)

    self:createCsbNode("SoaringWealth_JackpotBonus_Jinbi.csb")
    
    self.m_machine = _m_machine
    self.m_jackpot_machine = _jackpot_machine
    self.m_curIndex = _index

    self.m_rewardName = {}
    self.m_rewardName[1] = self:findChild("shuzi")
    self.m_rewardName[2] = self:findChild("Mini")
    self.m_rewardName[3] = self:findChild("Minor")
    self.m_rewardName[4] = self:findChild("Major")
    self.m_rewardName[5] = self:findChild("Mega")
    self.m_rewardName[6] = self:findChild("Grand")

    self.m_rewardAnName = {}
    self.m_rewardAnName[1] = self:findChild("shuzi_an")
    self.m_rewardAnName[2] = self:findChild("Mini_an")
    self.m_rewardAnName[3] = self:findChild("Minor_an")
    self.m_rewardAnName[4] = self:findChild("Major_an")
    self.m_rewardAnName[5] = self:findChild("Mega_an")
    self.m_rewardAnName[6] = self:findChild("Grand_an")
end

function SoaringWealthJackpotRewardNode:onExit()
    SoaringWealthJackpotRewardNode.super.onExit(self)
end

function SoaringWealthJackpotRewardNode:refreshReward(_reward, _isGrey)
    local reward = _reward
    local isGrey = _isGrey
    for i=1, 6 do
        if reward[1] == i - 1 then
            self.m_rewardName[i]:setVisible(true)
        else
            self.m_rewardName[i]:setVisible(false)
        end
    end
    self:findChild("m_lb_coins"):setString(util_formatCoins(reward[2],3))

    if isGrey then
        for i=1, 6 do
            if reward[1] == i - 1 then
                self.m_rewardAnName[i]:setVisible(true)
            else
                self.m_rewardAnName[i]:setVisible(false)
            end
        end
        self:findChild("m_lb_coins_an"):setString(util_formatCoins(reward[2],3))
    end
end

return SoaringWealthJackpotRewardNode
