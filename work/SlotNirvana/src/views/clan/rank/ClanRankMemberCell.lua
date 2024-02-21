--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-09 16:27:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-09 18:19:46
FilePath: /SlotNirvana/src/views/clan/rank/ClanRankMemberCell.lua
Description: 本公会 各成员贡献排行 cell
--]]
local ClanRankMemberCell = class("ClanRankMemberCell", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

function ClanRankMemberCell:updateUI(_memberRankData)
    self.m_memberRankData = _memberRankData
    self.m_bMe = globalData.userRunData.userUdid == _memberRankData:getUdid() 

    -- 背景显隐
    self:initBgUI()
    -- 排行icon
    self:initRankIconUI()
    -- 个人头像
    self:initUserHead()
    -- 用户等级
    self:initUserLevelUI()
    -- 用户名字
    self:initUserNameUI()
    -- 个人奖励
    self:initCurRankRewardsUI()
    -- 当前公会点数
    self:initTeamPoints()
end

function ClanRankMemberCell:getCsbName()
    return "Club/csd/RANK/ClubRewardCell.csb"
end

-- 背景显隐
function ClanRankMemberCell:initBgUI()
    local spMe = self:findChild("Sp_myrank")
    local spOther = self:findChild("Sp_otherrank")
    spMe:setVisible(self.m_bMe)
    spOther:setVisible(not self.m_bMe)
end

-- 排行icon
function ClanRankMemberCell:initRankIconUI()
    local sp1 = self:findChild("sp_1st")
    local sp2 = self:findChild("sp_2nd")
    local sp3 = self:findChild("sp_3rd")
    local lbRank = self:findChild("lb_rank")
    local rank = self.m_memberRankData:getRank()
    sp1:setVisible(rank == 1)
    sp2:setVisible(rank == 2)
    sp3:setVisible(rank == 3)
    lbRank:setVisible(rank > 3)
    if rank > 4 then
        lbRank:setString(rank)
    end
end

-- 个人头像
function ClanRankMemberCell:initUserHead()
    local nodeHead = self:findChild("sp_head")
    self:updateHeadUI(nodeHead)
    local layout = ccui.Layout:create()
    layout:setName("layout_touch")
    layout:setTouchEnabled(true)
    layout:setContentSize(nodeHead:getContentSize())
    self:addClick(layout)
    layout:addTo(nodeHead)
end

-- 用户等级
function ClanRankMemberCell:initUserLevelUI()
    local lbLevel = self:findChild("lb_mylevel")
    if not self.m_bMe then
        lbLevel = self:findChild("lb_otherlevel")
    end
    local level = self.m_memberRankData:getLevel()
    lbLevel:setString("LV" .. level)
end

-- 用户名字
function ClanRankMemberCell:initUserNameUI()
    local layoutName = self:findChild("layout_myName")
    local lbName = self:findChild("lb_myName")
    if not self.m_bMe then
        layoutName = self:findChild("layout_otherName")
        lbName = self:findChild("lb_otherName")
    end
    local name = self.m_memberRankData:getName()
    lbName:setString(name)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end

-- 个人奖励
function ClanRankMemberCell:initCurRankRewardsUI()
    local lbCoins = self:findChild("lb_coin_shuzi")
    local nodePoints = self:findChild("node_points")
    local lbPoints = self:findChild("lb_points")

    local coins = self.m_memberRankData:getCoins() --金币
    local deluxePints = self.m_memberRankData:getHighLimitPoints() --高倍场点数
    if deluxePints > 0 then
        lbCoins:setString(util_formatCoins(coins, 4) .. "+")
        nodePoints:setVisible(true)
        lbPoints:setString(util_getFromatMoneyStr(deluxePints))
    else
        lbCoins:setString(util_formatCoins(coins, 4))
        nodePoints:setVisible(false)
    end
end

-- 当前公会点数
function ClanRankMemberCell:initTeamPoints()
    local lbPoints = self:findChild("lb_clubpoint_shuzi")
    local points = self.m_memberRankData:getPoints()
    lbPoints:setString(util_getFromatMoneyStr(points))
end

-- 更新玩家头像
function ClanRankMemberCell:updateHeadUI(_headParent)
    if tolua.isnull(_headParent) then
        return
    end
    _headParent:removeAllChildren()

    local fbId = self.m_memberRankData:getFacebookId()
    local head = self.m_memberRankData:getHead() 
    local frameId = self.m_memberRankData:getFrameId() 
    local headSize = _headParent:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, headSize)
    nodeAvatar:setPosition( cc.p( (headSize.width)/2, (headSize.height)/2 ) )
    nodeAvatar:addTo(_headParent)
end

function ClanRankMemberCell:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_memberRankData:getUdid(), "", "", self.m_memberRankData:getFrameId())
    end
end

-- 获取cellSize
function ClanRankMemberCell:getContentSize()
    return self:findChild("Sp_myrank"):getContentSize()
end

function ClanRankMemberCell:getData()
    return self.m_memberRankData
end

return ClanRankMemberCell