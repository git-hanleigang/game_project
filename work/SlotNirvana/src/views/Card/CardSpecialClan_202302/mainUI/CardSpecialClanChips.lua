--[[
    特殊章节 筹码
]]
local CardSpecialClanChips = class("CardSpecialClanChips", BaseView)

function CardSpecialClanChips:initDatas(_pageIndex)
    self.m_pageIndex = _pageIndex
end

function CardSpecialClanChips:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/main/MagicAlbum_chips.csb"
end

function CardSpecialClanChips:initCsbNodes()
    self.m_nodeChips = {}
    for i = 1, CardSpecialClanCfg.pageCardNum do
        local nodeChip = self:findChild("node_chip_" .. i)
        table.insert(self.m_nodeChips, nodeChip)
    end
end

function CardSpecialClanChips:initUI()
    CardSpecialClanChips.super.initUI(self)
    self:initCells()
end

function CardSpecialClanChips:initCells()
    local clanData = self:getClanData()
    if not clanData then
        return
    end
    local pageCards = clanData:getPageCards(self.m_pageIndex)
    self.m_chips = {}
    for i = 1, #self.m_nodeChips do
        local cardData = pageCards[i]
        if cardData then
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

function CardSpecialClanChips:updateCells(_pageIndex, _over)
    if self.m_pageIndex == _pageIndex then
        if _over then
            _over()
        end
        return
    end
    -- 在刷新成下一页之前，将当前页new标签数据更改为false
    self:checkCardNewMark()

    self.m_pageIndex = _pageIndex

    local clanData = self:getClanData()
    if not clanData then
        return
    end
    local cards = clanData:getCards()
    for i = 1, #self.m_chips do
        local cardData = cards[i + CardSpecialClanCfg.pageCardNum * (self.m_pageIndex - 1)]
        if cardData then
            self.m_nodeChips[i]:setVisible(false)
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
function CardSpecialClanChips:checkCardNewMark()
    local clanData = self:getClanData()
    if not clanData then
        return
    end
    local pageNewCards = clanData:getPageNewCards(self.m_pageIndex)
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
    local clanId = clanData:getClanId()
    local albumId = clanData:getAlbumId()
    local cards = nil
    if #cardIds == 1 then
        cards = cardIds
    else
        cards = table.concat(cardIds, ";")
    end
    local tExtraInfo = {["albumId"] = albumId, ["clanId"] = clanId, ["cards"] = cards}
    CardSysNetWorkMgr:sendCardViewRequest(tExtraInfo)
end

function CardSpecialClanChips:getClanData()
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if data then
        local clanData = data:getSpecialClanByIndex()
        return clanData
    end
    return nil
end

return CardSpecialClanChips
