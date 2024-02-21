--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-09 16:27:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-09 18:19:46
FilePath: /SlotNirvana/src/views/clan/rank/topTeam/ClanRankTopListLayer.lua
Description: 最强公会排行 主弹板
--]]
local ClanRankTopListLayer = class("ClanRankTopListLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanRankTopTableView = util_require("views.clan.rank.topTeam.ClanRankTopTableView")

local TYPE_ENUM = {
    TopTeam = 1, -- 最强公会
    TopMembers = 2 -- 最强百人
}

function ClanRankTopListLayer:initDatas(_type)
    local clanData = ClanManager:getClanData()
    self.m_topTeamData = clanData:getRankTopListData() --百强公会
    self.m_topMembersData = clanData:getRankTopMembersListData() -- 最强百人

    self.m_selfTeamRankInfo = self.m_topTeamData:getSelfTeamRankInfo()
    self.m_selfTeamRank = 0
    if self.m_selfTeamRankInfo then
        self.m_selfTeamRank = self.m_selfTeamRankInfo:getRank()
    end

    self.m_selfMembersRankInfo = self.m_topMembersData:getSelfTeamRankInfo()
    self.m_selfMembersRank = 0
    if self.m_selfMembersRankInfo then
        self.m_selfMembersRank = self.m_selfMembersRankInfo:getRank()
    end

    self.m_type = _type or TYPE_ENUM.TopTeam
    self.m_topData = self.m_topTeamData
    self.m_selfRankInfo = self.m_selfTeamRankInfo
    self.m_selfRank = self.m_selfTeamRank
    if self.m_type == TYPE_ENUM.TopMembers then
        self.m_topData = self.m_topMembersData
        self.m_selfRankInfo = self.m_selfMembersRankInfo
        self.m_selfRank = self.m_selfMembersRank
    end

    self.m_isAnimationing = false

    self:setKeyBackEnabled(true)
    self:setExtendData("ClanRankTopListLayer")
    self:setLandscapeCsbName("Club/csd/RANK/TopTeam/TopTeam_mainUI.csb")

    gLobalNoticManager:addObserver(self, "updateFlotSelfRankInfoVisibleEvt", ClanConfig.EVENT_NAME.UPDATE_TOP_RANK_SELF_VIEW_VISIBLE) -- 最强工会自己的信息显隐
end

function ClanRankTopListLayer:initCsbNodes()
    self.m_sp_logo_team = self:findChild("sp_logo")
    self.m_sp_logo_members = self:findChild("sp_logo2")
    self.m_btn_team = self:findChild("btn_team")
    self.m_btn_member = self:findChild("btn_member")
    self.m_sp_podiumTeam = self:findChild("sp_podiumTeam")
    self.m_sp_podiumMem = self:findChild("sp_podiumMem")
    util_csbPauseForIndex(self.m_csbAct, 610)
end

function ClanRankTopListLayer:initView()
    -- 背景
    self:initBgUI()
    -- 时间
    self:initTimeUI()
    -- 前三名公会
    self:initTopInfoUI()
    -- 本公会信息
    self:initSelfTeamInfoUI()
    -- 公会排行列表
    self:updateRankListUI()
    -- 百人排行榜列表
    self:updateMembersRankListUI()
    -- 初始化领奖台
    self:initRewardTable()
end

function ClanRankTopListLayer:onShowedCallFunc()
    self.m_isAnimationing = true
    self:runCsbAction("in", false, function()
        self:runCsbAction("idle", true)
        self.m_isAnimationing = false
    end, 60)
end

-- 背景
function ClanRankTopListLayer:initBgUI()
    local bgLeft = self:findChild("sp_bg1")
    local bgRight = self:findChild("sp_bg2")
    local bgSize = bgLeft:getContentSize()
    local scale = self:getUIScalePro()
    if scale == 1 and display.width > bgSize.width*2 then
        bgLeft:setScale(display.width * 0.5 / bgSize.width)
        bgRight:setScale(display.width * 0.5 / bgSize.width)
    else
        bgLeft:setScale(1 / scale)
        bgRight:setScale(1 / scale)
    end

    local isMemberVisible = self.m_type == TYPE_ENUM.TopMembers
    self.m_sp_logo_team:setVisible(not isMemberVisible)
    self.m_sp_logo_members:setVisible(isMemberVisible)

    self.m_btn_team:setEnabled(isMemberVisible)
    self.m_btn_member:setEnabled(not isMemberVisible)
end

-- 时间
function ClanRankTopListLayer:initTimeUI()
    local lbTime = self:findChild("txt_time")
    local timeStr = self.m_topData:getTimeStr()
    lbTime:setString(timeStr)
end

-- 前三名公会
function ClanRankTopListLayer:initTopInfoUI()
    for i=1, 3 do
        local parent = self:findChild("node_ranking" .. i)
        parent:removeAllChildren()
        local data = self.m_topData:getTeamRankInfoByIdx(i)
        local path = "views.clan.rank.topTeam.ClanRankTopLogoUI"
        if self.m_type == TYPE_ENUM.TopMembers then
            path = "views.clan.rank.topMembers.ClanRankTopMembersLogoUI"
        end
        local view = util_createView(path, data, i)
        parent:addChild(view)
        util_setCascadeOpacityEnabledRescursion(parent, true)
    end
end

-- 本公会信息
function ClanRankTopListLayer:initSelfTeamInfoUI()
    local count = self.m_selfRank > 0 and 2 or 1
    local clanData = ClanManager:getClanData()
    local simpleInfo = clanData:getClanSimpleInfo()
    for i=1, count do
        local parent = self:findChild(i == 1 and "node_self_bottom" or "node_self_top")
        parent:removeAllChildren()
        local view = util_createView("views.clan.rank.topTeam.ClanRankTopCell", true, self.m_type)
        parent:addChild(view)
        view:updateUI(self.m_selfRankInfo, simpleInfo, self.m_type)
        parent:setVisible(false)
    end

    if count == 1 then
        local nodeBottom = self:findChild("node_self_bottom")
        nodeBottom:setVisible(true)
    end
end

-- 公会排行列表
function ClanRankTopListLayer:updateRankListUI()
    local list = self.m_topData:getTeamRankList() 
    local listView = self:findChild("ListView_1")
    local size = listView:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = listView,
        directionType = 2
    }
    local tableView = ClanRankTopTableView.new(param)
    listView:addChild(tableView)
    tableView:reload(list, TYPE_ENUM.TopTeam)
    if self.m_selfTeamRank > 0 then
        tableView:setNeedUpdateSelfUI(true)
        tableView:updateFlotSelfRankInfoVisible()
    end
    self.m_teamTableView = tableView
    self.m_teamTableView:setVisible(self.m_type == TYPE_ENUM.TopTeam)
end

-- 百人排行列表
function ClanRankTopListLayer:updateMembersRankListUI()
    local list = self.m_topMembersData:getTeamRankList() 
    local listView = self:findChild("ListView_1")
    local size = listView:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = listView,
        directionType = 2
    }
    local tableView = ClanRankTopTableView.new(param)
    listView:addChild(tableView)
    tableView:reload(list, TYPE_ENUM.TopMembers)
    if self.m_selfMembersRank > 0 then
        tableView:setNeedUpdateSelfUI(true)
        tableView:updateFlotSelfRankInfoVisible()
    end
    self.m_membersTableView = tableView
    self.m_membersTableView:setVisible(self.m_type == TYPE_ENUM.TopMembers)
end

-- 初始化领奖台
function ClanRankTopListLayer:initRewardTable()
    local isTeamVisible = self.m_type == TYPE_ENUM.TopTeam
    local isMemberVisible = self.m_type == TYPE_ENUM.TopMembers
    self.m_sp_podiumTeam:setVisible(isTeamVisible)
    self.m_sp_podiumMem:setVisible(isMemberVisible)
end

function ClanRankTopListLayer:clickFunc(sender) 
    if self.m_isAnimationing then
        return
    end
    local name = sender:getName()
    if name == "btn_close" then
        local lizi = self:findChild("ef_lz")
        lizi:setVisible(false)
        self:closeUI()
    elseif name == "btn_team" then
        self:refreshView(TYPE_ENUM.TopTeam)
    elseif name == "btn_member" then
        self:refreshView(TYPE_ENUM.TopMembers)
    end
end

-- 最强工会自己的信息显隐
function ClanRankTopListLayer:updateFlotSelfRankInfoVisibleEvt(_params)
    if self.m_selfRank <= 0 then
        return
    end

    local rankMin = _params[1] or 0
    local rankMax = _params[2] or 9999

    local nodeTop = self:findChild("node_self_top")
    local nodeBottom = self:findChild("node_self_bottom")
    if self.m_selfRank < rankMin then
        nodeTop:setVisible(true)
        nodeBottom:setVisible(false)
    elseif self.m_selfRank > rankMax then
        nodeTop:setVisible(false)
        nodeBottom:setVisible(true)
    else
        nodeTop:setVisible(false)
        nodeBottom:setVisible(false)
    end

end

function ClanRankTopListLayer:refreshView(_type)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local tableView = self.m_teamTableView
    local isTeamVisible = _type == TYPE_ENUM.TopTeam
    local isMemberVisible = _type == TYPE_ENUM.TopMembers
    self.m_btn_team:setEnabled(isMemberVisible)
    self.m_btn_member:setEnabled(isTeamVisible)
    self.m_type = _type
    if isTeamVisible then
        self.m_topData = self.m_topTeamData
        self.m_selfRankInfo = self.m_selfTeamRankInfo
        self.m_selfRank = self.m_selfTeamRank
        tableView = self.m_teamTableView
    elseif isMemberVisible then
        self.m_topData = self.m_topMembersData
        self.m_selfRankInfo = self.m_selfMembersRankInfo
        self.m_selfRank = self.m_selfMembersRank
        tableView = self.m_membersTableView
    end
    self:initTimeUI()
    self:initSelfTeamInfoUI()
    self.m_sp_logo_team:setVisible(isTeamVisible)
    self.m_sp_logo_members:setVisible(isMemberVisible)

    self.m_isAnimationing = true
    gLobalSoundManager:playSound(ClanConfig.MUSIC_ENUM.CLUB_TOP_CHANGE)
    self:runCsbAction("out", false, function()
        self:initRewardTable()
        self:initTopInfoUI()
        self:runCsbAction("in", false, function()
            self.m_isAnimationing = false
            self:runCsbAction("idle", true)
        end, 60)
    end, 60)

    -- 刷新tableview
    self.m_teamTableView:setVisible(isTeamVisible)
    self.m_membersTableView:setVisible(isMemberVisible)
    tableView:reload(self.m_topData:getTeamRankList(), self.m_type)
    if self.m_selfRank > 0 then
        tableView:setNeedUpdateSelfUI(true)
        tableView:updateFlotSelfRankInfoVisible()
    end
end

return ClanRankTopListLayer