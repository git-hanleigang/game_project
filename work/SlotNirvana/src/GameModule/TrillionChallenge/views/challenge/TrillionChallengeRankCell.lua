--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:27:47
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/challenge/TrillionChallengeRankCell.lua
Description: 亿万赢钱挑战 排行榜玩家 Ui
--]]
local TrillionChallengeRankCell = class("TrillionChallengeRankCell", BaseView)

function TrillionChallengeRankCell:initDatas() 
    TrillionChallengeRankCell.super.initDatas(self)
end

function TrillionChallengeRankCell:getCsbName()
    return "Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_rank_item.csb"
end

function TrillionChallengeRankCell:updateUI(_data)
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
function TrillionChallengeRankCell:updateBgVisible()
    local spBgSelf = self:findChild("sp_bg_self")
    spBgSelf:setVisible(self._data:checkIsMe())
end
-- 头像
function TrillionChallengeRankCell:updatHeadUI()
    local nodeHead = self:findChild("sp_head")
    nodeHead:removeAllChildren()

    local fbId = self._data:getFacebookId()
    local head = self._data:getHead()
    local frameId = self._data:getFrameId()
    local headSize = nodeHead:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, headSize)
    nodeAvatar:setPosition( cc.p( (headSize.width)/2, (headSize.height)/2 ) )
    nodeHead:addChild(nodeAvatar)

    if not self._touchAvatar then
        local layout = ccui.Layout:create()
        layout:setName("layout_touch")
        layout:setTouchEnabled(true)
        layout:setContentSize(nodeHead:getContentSize())
        self:addClick(layout)
        layout:addTo(nodeHead)
        self._touchAvatar = layout
    end

end
-- 用户名字
function TrillionChallengeRankCell:updateNameUI()
    local layoutName = self:findChild("layer_myId")
    local lbName = self:findChild("lb_myId")
    local name = self._data:getName()
    lbName:setString(name)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end
-- 排行信息
function TrillionChallengeRankCell:updateRankInfoUI()
    local rank = self._data:getRank()
    local bInRank = rank > 0
    if bInRank then
        self:updateInRankUI()
    else
        self:updateNoRankUI()
    end
    local nodeRank = self:findChild("node_rank")
    local nodeNoRank = self:findChild("node_noRank")
    nodeRank:setVisible(bInRank)
    nodeNoRank:setVisible(not bInRank)
end
-- 排行信息 有排名
function TrillionChallengeRankCell:updateInRankUI()
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
    local lbCoins = self:findChild("lb_gainCoins")
    local coins = self._data:getPoints()
    lbCoins:setString(util_formatCoins(coins, 9))

    -- 奖励
    local nodeReward = self:findChild("node_reward")
    local spLine = self:findChild("sp_line")
    spLine:setVisible(false)
    nodeReward:removeAllChildren()
    local rewardData = G_GetMgr(G_REF.TrillionChallenge):getRankRewardByRank(self._data:getRank())
    if rewardData then
        local itemList = rewardData:getRewardList()
        local node = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.TOP)
        nodeReward:addChild(node)
        spLine:setVisible(#itemList > 0)
    end
end
-- 排行信息 无排名
function TrillionChallengeRankCell:updateNoRankUI()
    local sysData = G_GetMgr(G_REF.TrillionChallenge):getRunningData()
    -- 任务 奖励
    local lbUnlockWin = self:findChild("lb_unlock_num")
    local needNum = sysData:getUnlockRankWin()
    lbUnlockWin:setString(util_formatCoins(needNum, 2))
    util_scaleCoinLabGameLayerFromBgWidth(lbUnlockWin, 40, 1)

    -- 当前 任务进度
    local lbCoinsCur = self:findChild("lb_coins_cur")
    local curNum = sysData:getCurTotalWin()
    lbCoinsCur:setString(util_formatCoins(curNum, 9))
end

function TrillionChallengeRankCell:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
        local udid = self._data:getUdid()
        local frameId = self._data:getFrameId()
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(udid, "", "", frameId)
    end
end

return TrillionChallengeRankCell