--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-23 15:57:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-23 15:57:43
FilePath: /SlotNirvana/src/GameModule/Card/commonViews/CardWildExchangeObsidian/CardObsidianWildExcTableView.lua
Description: 集卡  黑耀卡 wild兑换  tb
--]]
local BaseTable = util_require("base.BaseTable")
local CardObsidianWildExcTableView = class("CardObsidianWildExcTableView", BaseTable)

function CardObsidianWildExcTableView:ctor(param)
    CardObsidianWildExcTableView.super.ctor(self, param)
end

function CardObsidianWildExcTableView:cellSizeForTable(table, idx)
    return 960, 406
end

function CardObsidianWildExcTableView:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if nil == cell then
        cell = cc.TableViewCell:new()
    end
    if cell.view == nil then
        cell.view = util_createView("GameModule.Card.commonViews.CardWildExchangeObsidian.CardObsidianWildExcCell", self.m_bShowAll)
        cell:addChild(cell.view)
        cell.view:move(960*0.5, 406*0.5) 
    end

    local data = self._viewData[idx + 1]
    cell.view:updateUI(data, idx + 1 )
    return cell
end

-- 刷新数据
function CardObsidianWildExcTableView:releadCardsData(_cards, _bShowAll)
    if not _cards then
        return
    end

    local tbList = {}
    for idx, cardData in ipairs(_cards) do
        local pageIdx = math.ceil(idx / 10)
        if not tbList[pageIdx] then
            tbList[pageIdx] = {}
        end
        table.insert(tbList[pageIdx], cardData)
    end

    self.m_bShowAll = _bShowAll
    self:reload(tbList)
end

function CardObsidianWildExcTableView:updateCellSelState()
    local container = self._unitTableView:getContainer()
    
    for k, cell in pairs(container:getChildren()) do
        if not tolua.isnull(cell.view) then
            cell.view:updateCellSelState()
        end
    end
end

return CardObsidianWildExcTableView 