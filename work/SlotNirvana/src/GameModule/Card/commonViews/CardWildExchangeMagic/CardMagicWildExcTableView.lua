--[[
    集卡  Magic卡 wild兑换  tb
--]]
local BaseTable = util_require("base.BaseTable")
local CardMagicWildExcTableView = class("CardMagicWildExcTableView", BaseTable)

function CardMagicWildExcTableView:ctor(param)
    CardMagicWildExcTableView.super.ctor(self, param)
end

function CardMagicWildExcTableView:cellSizeForTable(table, idx)
    local data = self._viewData[idx + 1]
    if not data then
        return 958, 470
    end

    local cardList = data.cards
    if #cardList <= 4 then
        return 958, 270
    end
    return 958, 470
end

function CardMagicWildExcTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end

    local width, height = self:cellSizeForTable(table, idx)
    if cell.view == nil then
        local cellPath = "GameModule.Card.commonViews.CardWildExchangeMagic.CardMagicWildExcCell"
        cell.view = util_createView(cellPath, self.m_bShowAll)
        cell:addChild(cell.view)
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1)
    cell.view:move(width * 0.5, height - 270)
    return cell
end

-- 刷新数据
function CardMagicWildExcTableView:releadCardsData(_cardClanList, _bShowAll)
    if not _cardClanList then
        return
    end
    self.m_bShowAll = _bShowAll
    self:reload(_cardClanList)
end

function CardMagicWildExcTableView:updateCellSelState()
    local container = self._unitTableView:getContainer()

    for k, cell in pairs(container:getChildren()) do
        if not tolua.isnull(cell.view) then
            cell.view:updateCellSelState()
        end
    end
end

return CardMagicWildExcTableView
