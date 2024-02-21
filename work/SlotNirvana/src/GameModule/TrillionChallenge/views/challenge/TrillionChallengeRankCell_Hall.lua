--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:27:22
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/challenge/TrillionChallengeRankCell_Hall.lua
Description: 亿万赢钱挑战 展示图排行  玩家UI
--]]
local TrillionChallengeRankCell_Hall = class("TrillionChallengeRankCell_Hall", BaseView)

function TrillionChallengeRankCell_Hall:initDatas() 
    TrillionChallengeRankCell_Hall.super.initDatas(self)
end

function TrillionChallengeRankCell_Hall:getCsbName()
    return "Icons/TrillionChallengeHall_rank.csb"
end

function TrillionChallengeRankCell_Hall:updateUI(_data)
    self._data = _data

    -- 背景显隐
    self:updateBgVisible()
    -- 头像
    self:updatHeadUI()
    -- 用户名字
    self:updateNameUI()
    -- 排行信息
    self:updateRankInfoUI()
end

-- 背景显隐
function TrillionChallengeRankCell_Hall:updateBgVisible()
    local nodeBgSelf = self:findChild("node_self")
    nodeBgSelf:setVisible(self._data:checkIsMe())
end
-- 头像
function TrillionChallengeRankCell_Hall:updatHeadUI()
    local nodeHead = self:findChild("sp_head")
    nodeHead:removeAllChildren()

    local fbId = self._data:getFacebookId()
    local head = self._data:getHead()
    local frameId = self._data:getFrameId()
    local headSize = nodeHead:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, headSize)
    nodeAvatar:setPosition( cc.p( (headSize.width)/2, (headSize.height)/2 ) )
    nodeHead:addChild(nodeAvatar)
end
-- 用户名字
function TrillionChallengeRankCell_Hall:updateNameUI()
    local layoutName = self:findChild("layout_name_other")
    local lbName = self:findChild("lb_name_other")
    if self._data:checkIsMe() then
        layoutName = self:findChild("layout_name_self")
        lbName = self:findChild("lb_name_self")
    end

    local name = self._data:getName()
    lbName:setString(name)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end
-- 排行信息
function TrillionChallengeRankCell_Hall:updateRankInfoUI()
    local rank = self._data:getRank()
  
    self:updateInRankUI()
end
-- 排行信息 有排名
function TrillionChallengeRankCell_Hall:updateInRankUI()
    -- 排名
    local sp1 = self:findChild("sp_1st")
    local sp2 = self:findChild("sp_2nd")
    local sp3 = self:findChild("sp_3rd")
    local lbRank = self:findChild("lb_rank")
    local rank = self._data:getRank()
    sp1:setVisible(rank == 1)
    sp2:setVisible(rank == 2)
    sp3:setVisible(rank == 3)
    lbRank:setVisible(rank > 3)
    if rank > 3 then
        lbRank:setString(rank)
    end

    -- 累积 金币
    local lbCoins = self:findChild("lb_coin_other")
    if self._data:checkIsMe() then
        lbCoins = self:findChild("lb_coin_self")
    end
    local coins = self._data:getPoints()
    lbCoins:setString(util_formatCoins(coins, 3))
end

return TrillionChallengeRankCell_Hall