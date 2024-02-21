--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-09 16:27:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-09 18:19:46
FilePath: /SlotNirvana/src/views/clan/rank/topTeam/ClanRankTopCell.lua
Description: 最强公会排行 cell
--]]
local ClanRankTopCell = class("ClanRankTopCell", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

local TYPE_ENUM = {
    TopTeam = 1, -- 最强公会
    TopMembers = 2 -- 最强百人
}

function ClanRankTopCell:initDatas(_bMe, _type)
    ClanRankTopCell.super.initDatas(self)

    self.m_bMe = _bMe
    self.m_type = _type or TYPE_ENUM.TopTeam
end

-- 初始化节点
function ClanRankTopCell:initCsbNodes()
    --[[
        共存节点
    --]]
    -- rank
    self.m_lbRanking = self:findChild("lb_ranking")
    self.m_spRanking = self:findChild("sp_ranking")
    self.m_lbRanking:setVisible(false)
    self.m_spRanking:setVisible(false)

    -- logo
    self.m_spTeamLogoBG = self:findChild("sp_clubIconBg")
    self.m_spTeamLogo = self:findChild("sp_clubIcon")
    -- teamname
    self.m_layoutTeamName = self:findChild("layout_teamName")
    self.m_lbTeamName = self:findChild("lb_teamName")
    self.m_layoutTeamName:setTouchEnabled(false)
    -- points
    self.m_lbPoints = self:findChild("lb_points")

    --[[ TopTeam专有节点 ]]
    -- division
    self.m_spDivision = self:findChild("sp_division")

    --[[ TopMembers专有节点 ]]
    -- head
    self.m_node_head = self:findChild("node_head")
    -- membersName
    self.m_layoutMembersName = self:findChild("layout_memName")
    self.m_lbMembersName = self:findChild("lb_memName")
    if self.m_layoutMembersName then
        self.m_layoutMembersName:setTouchEnabled(false)
    end
end

function ClanRankTopCell:updateUI(_rankCellData, _selfClanSimpleInfo, _type)
    self.m_rankCellData = _rankCellData
    self.m_selfClanSimpleInfo = _selfClanSimpleInfo

    -- 公会 排名
    self:updateRankTxtUI()
    -- 公会 徽章logo
    self:updateTeamLogoUI()
    -- 公会 名字
    self:updateTeamNameUI()
    -- 公会 总点数
    self:updateTeamPointsUI()

    if _type == TYPE_ENUM.TopTeam then
        -- 公会 段位
        self:updateTeamDivisionUI()
    elseif _type == TYPE_ENUM.TopMembers then
        -- 公会 玩家头像、名字
        self:updateTeamHeadUI()
    end
end

-- 公会 排名
function ClanRankTopCell:updateRankTxtUI()
    local rank = self.m_rankCellData:getRank()
    if rank <= 0 then
        self.m_lbRanking:setVisible(true)
        self.m_spRanking:setVisible(false)
        self.m_lbRanking:setString("--")
    elseif rank > 3 then
        self.m_lbRanking:setVisible(true)
        self.m_spRanking:setVisible(false)
        self.m_lbRanking:setString(rank)
    else
        self.m_lbRanking:setVisible(false)
        self.m_spRanking:setVisible(true)
        util_changeTexture(self.m_spRanking, string.format("Club/ui/Rank/TopTeam/TopTeam_paiming_%d.png", rank))
    end
end

-- 公会 徽章logo
function ClanRankTopCell:updateTeamLogoUI()
    local clanLogo = self.m_rankCellData:getClanLogo() 
    if self.m_selfClanSimpleInfo:getTeamCid() == self.m_rankCellData:getCid() then
        clanLogo = self.m_selfClanSimpleInfo:getTeamLogo()
    end
    local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
    local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
    util_changeTexture(self.m_spTeamLogoBG, imgBgPath)
    util_changeTexture(self.m_spTeamLogo, imgPath)
end

-- 公会 名字
function ClanRankTopCell:updateTeamNameUI()
    local name = self.m_rankCellData:getName()
    if self.m_selfClanSimpleInfo:getTeamCid() == self.m_rankCellData:getCid() then
        name = self.m_selfClanSimpleInfo:getTeamName()
    end
    self.m_lbTeamName:setString(name)
    util_wordSwing(self.m_lbTeamName, 1, self.m_layoutTeamName, 3, 30, 3)
end

-- 公会 段位
function ClanRankTopCell:updateTeamDivisionUI()
    local division = self.m_rankCellData:getDivision()
    local iconPath = ClanManager:getRankDivisionIconPath(division)
    util_changeTexture(self.m_spDivision, iconPath)
end

-- 公会 总点数
function ClanRankTopCell:updateTeamPointsUI()
    local points = self.m_rankCellData:getPoints()
    self.m_lbPoints:setString(util_getFromatMoneyStr(points))
end

-- 公会 玩家头像、名字
function ClanRankTopCell:updateTeamHeadUI()
    if self.m_node_head then
        --设置头像
        local data = {
            p_fbid = self.m_rankCellData:getFacebookId(), 
            p_head = self.m_rankCellData:getUserHead(), 
            p_frameId = self.m_rankCellData:getUserFrame()}
        local limitSize = cc.size(56, 56)
        local nodeAvatar = self.m_node_head:getChildByName("CommonAvatarNode")
        if nodeAvatar then
            nodeAvatar:updateUI(data.p_fbid, data.p_head, data.p_frameId, nil, limitSize)
        else
            nodeAvatar =
                G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
                data.p_fbid,
                data.p_head,
                data.p_frameId,
                nil,
                limitSize
            )
            self.m_node_head:addChild(nodeAvatar)
            nodeAvatar:setName("CommonAvatarNode")

            local layout = ccui.Layout:create()
            layout:setName("layout_touch")
            layout:setTouchEnabled(true)
            layout:setContentSize(limitSize)
            layout:setPosition(-limitSize.width / 2, -limitSize.height / 2)
            layout:addTo(self.m_node_head)
            self:addClick(layout)
        end
    end

    if self.m_layoutMembersName and self.m_lbMembersName then
        local name = self.m_rankCellData:getUserName()
        self.m_lbMembersName:setString(name)
        util_wordSwing(self.m_lbMembersName, 1, self.m_layoutMembersName, 3, 30, 3)
    end
end

function ClanRankTopCell:clickFunc(sender)
    local name = sender:getName()
    if name == "layout_touch" then
        if not self.m_rankCellData then
            return
        end
        if not self.m_rankCellData:getUdid() then
            return
        end
        G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_rankCellData:getUdid(), "","",self.m_rankCellData:getUserFrame())
    end
end

function ClanRankTopCell:getCsbName()
    if self.m_type == TYPE_ENUM.TopTeam then
        if self.m_bMe then
            return "Club/csd/RANK/TopTeam/TopTeam_cell_self.csb"
        else
            return "Club/csd/RANK/TopTeam/TopTeam_cell_other.csb"
        end
    elseif self.m_type == TYPE_ENUM.TopMembers then
        if self.m_bMe then
            return "Club/csd/RANK/TopMembers/TopMembers_cell_self.csb"
        else
            return "Club/csd/RANK/TopMembers/TopMembers_cell_other.csb"
        end
    end
end

return ClanRankTopCell
