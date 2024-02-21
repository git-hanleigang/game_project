--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-09 16:27:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-09 18:19:46
FilePath: /SlotNirvana/src/views/clan/rank/topTeam/ClanRankTopTableView.lua
Description: 最强公会排行 tableView
--]]
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanRankTopTableViewCell = class("ClanRankTopTableViewCell", BaseView)

local TYPE_ENUM = {
    TopTeam = 1, -- 最强公会
    TopMembers = 2 -- 最强百人
}

function ClanRankTopTableViewCell:ctor(_type)
    ClanRankTopTableViewCell.super.ctor(self)

    local clanData = ClanManager:getClanData()
    self.m_simpleInfo = clanData:getClanSimpleInfo()
    self.m_rank = 0
    self.m_type = _type or TYPE_ENUM.TopTeam

    self:initUI()
end

function ClanRankTopTableViewCell:initUI()
    self.m_cellSelf  = util_createView("views.clan.rank.topTeam.ClanRankTopCell", true, self.m_type)
    self.m_cellOther = util_createView("views.clan.rank.topTeam.ClanRankTopCell", false, self.m_type)

    self.m_cellSelf:addTo(self)
    self.m_cellOther:addTo(self)
end

function ClanRankTopTableViewCell:updateUI(_data, _inx)
    self.m_rank = 0
    if not _data then
        return
    end

    self.m_rank = _data:getRank()
    local clanId = _data:getCid()
    local refreshCell = nil
    if self.m_type == TYPE_ENUM.TopTeam then
        if self.m_simpleInfo:getTeamCid() == clanId then
            self.m_cellSelf:setVisible(true)
            self.m_cellOther:setVisible(false)
    
            refreshCell = self.m_cellSelf
        else
            self.m_cellSelf:setVisible(false)
            self.m_cellOther:setVisible(true)
            
            refreshCell = self.m_cellOther
        end 
    else
        local udid = _data:getUdid()
        if globalData.userRunData.userUdid == udid then
            self.m_cellSelf:setVisible(true)
            self.m_cellOther:setVisible(false)
    
            refreshCell = self.m_cellSelf
        else
            self.m_cellSelf:setVisible(false)
            self.m_cellOther:setVisible(true)
            
            refreshCell = self.m_cellOther
        end 
    end
    refreshCell:updateUI(_data, self.m_simpleInfo, self.m_type)
end

function ClanRankTopTableViewCell:getRank()
    return self.m_rank
end


local BaseTable = util_require("base.BaseTable")
local ClanRankTopTableView = class("ClanRankTopTableView", BaseTable)

function ClanRankTopTableView:ctor(param)
    ClanRankTopTableView.super.ctor(self, param)
    self.m_bNeedUpdateSelf = false
    self.m_type = TYPE_ENUM.TopTeam -- 默认是最强公会排行榜
end

function ClanRankTopTableView:reload(sourceData, type)
    self.m_type = type or TYPE_ENUM.TopTeam
    ClanRankTopTableView.super.reload(self, sourceData)
end

function ClanRankTopTableView:cellSizeForTable(table, idx)
    return 540, 72
end

function ClanRankTopTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = ClanRankTopTableViewCell:create(self.m_type) 
        cell:addChild(cell.view)
        cell.view:move(580*0.5, 72*0.5)
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1)
    self._cellList[idx + 1] = cell.view

    return cell
end

-- set 是否需要刷新本公会显隐信息
function ClanRankTopTableView:setNeedUpdateSelfUI(_bool)
    self.m_bNeedUpdateSelf = _bool
end

function ClanRankTopTableView:scrollViewDidScroll()
    ClanRankTopTableView.super.scrollViewDidScroll(self)
    if not self.m_bNeedUpdateSelf then
        return
    end
    
    self:updateFlotSelfRankInfoVisible()
end

function ClanRankTopTableView:updateFlotSelfRankInfoVisible()
    local container = self._unitTableView:getContainer()
    local children = container:getChildren()
    if #children < 2 then
        return
    end

    local rankMin = 0
    local rankMax = 0
    for i=1, #children do
        local view = children[i].view
        local rank = view:getRank()
        if i == 1 then
            rankMin = rank
            rankMax = rank
        end
        rankMin = math.min(rankMin, rank)
        rankMax = math.max(rankMax, rank)
    end
    
    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.UPDATE_TOP_RANK_SELF_VIEW_VISIBLE, {rankMin, rankMax})
end

return ClanRankTopTableView 