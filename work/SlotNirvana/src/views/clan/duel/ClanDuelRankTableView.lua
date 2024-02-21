local ClanConfig = util_require("data.clanData.ClanConfig")
local BaseTable = util_require("base.BaseTable")
local ClanDuelRankTableView = class("ClanDuelRankTableView", BaseTable)

function ClanDuelRankTableView:ctor(param)
    ClanDuelRankTableView.super.ctor(self, param)
    self.m_bNeedUpdateSelf = false
end

function ClanDuelRankTableView:cellSizeForTable(table, idx)
    if globalData.slotRunData.isPortrait then
        return 589, 92
    end
    return 854, 72
end

function ClanDuelRankTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        local cellWidth, cellHeight = self:cellSizeForTable()
        cell.view = util_createView("views.clan.duel.ClanDuelRankCell")
        cell:addChild(cell.view)
        cell.view:move(cellWidth * 0.5, cellHeight * 0.5)
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1)
    self._cellList[idx + 1] = cell.view

    return cell
end

-- set 是否需要刷新本公会显隐信息
function ClanDuelRankTableView:setNeedUpdateSelfUI(_bool)
    self.m_bNeedUpdateSelf = _bool
end

function ClanDuelRankTableView:scrollViewDidScroll()
    ClanDuelRankTableView.super.scrollViewDidScroll(self)
    if not self.m_bNeedUpdateSelf then
        return
    end

    self:updateFlotSelfRankInfoVisible()
end

function ClanDuelRankTableView:updateFlotSelfRankInfoVisible()
    local container = self._unitTableView:getContainer()
    local children = container:getChildren()
    if #children < 2 then
        return
    end

    local rankMin = 0
    local rankMax = 0
    for i = 1, #children do
        local view = children[i].view
        local rank = view:getRank()
        if i == 1 then
            rankMin = rank
            rankMax = rank
        end
        rankMin = math.min(rankMin, rank)
        rankMax = math.max(rankMax, rank)
    end

    gLobalNoticManager:postNotification(ClanConfig.EVENT_NAME.UPDATE_DUEL_RANK_SELF_VIEW_VISIBLE, {rankMin, rankMax})
end

return ClanDuelRankTableView
