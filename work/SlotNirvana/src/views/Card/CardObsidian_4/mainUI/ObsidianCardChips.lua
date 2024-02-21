--[[
    特殊章节-购物主题 筹码
]]
local ObsidianCardChips = class("ObsidianCardChips", BaseView)

function ObsidianCardChips:initDatas(_pageIndex, _seasonId)
    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData(_seasonId)
    self.m_pageIndex = _pageIndex
    self.m_seasonId = _seasonId
    self.m_isHistory = data:isHistorySeason(_seasonId) or false
end

function ObsidianCardChips:getCsbName()
    return "CardRes/CardObsidian_4/csb/main/ObsidianAlbum_chips.csb"
end

function ObsidianCardChips:initCsbNodes()
    self.m_nodeChips = {}
    for i = 1, ObsidianCardCfg.pageCardNum do
        local nodeChip = self:findChild("node_chip_" .. i)
        table.insert(self.m_nodeChips, nodeChip)
    end
end

function ObsidianCardChips:initUI()
    ObsidianCardChips.super.initUI(self)
    self:initCells()
end

function ObsidianCardChips:initCells()
    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData(self.m_seasonId)
    if not data then
        return
    end
    local pageCards = data:getPageCards(self.m_pageIndex)
    self.m_chips = {}
    for i = 1, #self.m_nodeChips do
        local cardData = pageCards[i]
        if cardData then
            if self.m_isHistory then
                cardData.description = "CONGRATS;YOU'VE GOT THE CHIP"
                cardData.source = "491"
            end
            cardData.isHistory = self.m_isHistory
            local chip = util_createView("GameModule.Card.season201903.MiniChipUnit")
            chip:setScale(0.5)
            self.m_nodeChips[i]:addChild(chip)
            self.m_nodeChips[i]:setVisible(false)
            chip:playAnimByIndex(i, self.m_nodeChips[i], true)

            chip:reloadUI(cardData)
            chip:updateTagNew(cardData.newCard == true)
            chip:updateTagNum(cardData.count)
            chip:updateTouchBtn(true, true, true)
            table.insert(self.m_chips, chip)
        end
    end
end

function ObsidianCardChips:updateCells(_pageIndex, _over)
    if self.m_pageIndex == _pageIndex then
        if _over then
            _over()
        end
        return
    end
    -- 在刷新成下一页之前，将当前页new标签数据更改为false
    self:checkCardNewMark()

    self.m_pageIndex = _pageIndex

    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData(self.m_seasonId)
    if not data then
        return
    end
    local cards = data:getCards()
    for i = 1, #self.m_chips do
        local cardData = cards[i + ObsidianCardCfg.pageCardNum * (self.m_pageIndex - 1)]
        if cardData then
            self.m_nodeChips[i]:setVisible(false)
            if self.m_isHistory then
                cardData.description = "CONGRATS;YOU'VE GOT THE CHIP"
                cardData.source = "491"
            end
            cardData.isHistory = self.m_isHistory
            self.m_chips[i]:reloadUI(cardData)
            self.m_chips[i]:updateTagNew(cardData.newCard == true)
            self.m_chips[i]:updateTagNum(cardData.count)
            self.m_chips[i]:playAnimByIndex(
                i,
                self.m_nodeChips[i],
                true,
                function(_index)
                    if _index == #self.m_chips then
                        if _over then
                            _over()
                        end
                    end
                end
            )
        end
    end
end

-- 检测卡牌New操作 --
function ObsidianCardChips:checkCardNewMark()
    local data = G_GetMgr(G_REF.ObsidianCard):getSeasonData(self.m_seasonId)
    if not data then
        return
    end
    local pageNewCards = data:getPageNewCards(self.m_pageIndex)
    if pageNewCards and #pageNewCards == 0 then
        return
    end
    -- 更改缓存数据
    local cardIds = {}
    for i = 1, #pageNewCards do
        cardIds[#cardIds + 1] = pageNewCards[i]:getCardId()
        pageNewCards[i]:setNewCard(false)
    end
    -- 请求数据
    local clanId = data:getClanId()
    local albumId = data:getAlbumId()
    local cards = nil
    if #cardIds == 1 then
        cards = cardIds
    else
        cards = table.concat(cardIds, ";")
    end
    local tExtraInfo = {["albumId"] = albumId, ["clanId"] = clanId, ["cards"] = cards}
    CardSysNetWorkMgr:sendCardViewRequest(tExtraInfo)
end

return ObsidianCardChips
