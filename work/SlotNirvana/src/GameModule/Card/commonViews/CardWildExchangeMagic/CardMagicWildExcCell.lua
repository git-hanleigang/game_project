--[[
    集卡 Magic卡 wild兑换 卡片 cell (8个miniChip 为一个cell)
--]]
local CardMagicWildExcCell = class("CardMagicWildExcCell", BaseView)

function CardMagicWildExcCell:initDatas(_bShowAll)
    CardMagicWildExcCell.super.initDatas(self)

    self.m_bShowAll = _bShowAll
end

function CardMagicWildExcCell:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/wild/cash_wild_exchange_cell.csb"
end

-- 创建 可兑换的卡片
function CardMagicWildExcCell:updateUI(_cardClanData, _idx)
    if not _cardClanData then
        return
    end

    local cardList = _cardClanData.cards
    self.m_cardDataList = cardList
    for i = 1, 8 do
        local panel = self:findChild("Panel_" .. i)
        if panel then
            panel:setSwallowTouches(false)
            panel:setTag(i)
            local cardData = cardList[i]
            if cardData then
                self:createChipCell(cardData, panel, i)
            end
            panel:setVisible(cardData ~= nil)
        end
    end

    local lb_clanName = self:findChild("lb_card_name")
    lb_clanName:setString("" .. _cardClanData.name)

    -- 初始化icon --
    local node_logo = self:findChild("node_logo")
    local icon = CardResConfig.getCardClanIcon(_cardClanData.clanId)
    if not self.m_ClanIcon then
        self.m_ClanIcon = util_createSprite(icon)
        node_logo:addChild(self.m_ClanIcon)
        self.m_ClanIcon:setScale(self:getClanLogoScale())
    else
        util_changeTexture(self.m_ClanIcon, icon)
    end
end

function CardMagicWildExcCell:getClanLogoScale()
    return 0.25
end

function CardMagicWildExcCell:createChipCell(_cardData, _panel, _idx)
    local spYes = _panel:getChildByName("yes")
    local bSel = tonumber(_cardData.cardId) == tonumber(CardSysManager:getWildExcMgr():getSelCardId())
    spYes:setVisible(bSel)

    local spMask = _panel:getChildByName("mask")
    spMask:setVisible(false)

    local nodeParent = self:findChild("Node_" .. _idx)
    local nodeChip = nodeParent:getChildByName("MiniChipUnit")
    if not nodeChip then
        nodeChip = util_createView("GameModule.Card.season201903.MiniChipUnit")
        nodeChip:playIdle()
        nodeChip:setName("MiniChipUnit")
        nodeParent:addChild(nodeChip)
    end
    nodeChip:reloadUI(_cardData, true)
    if self.m_bShowAll then
        if _cardData.count == 0 then
            nodeChip:setCardGrey(true, cc.c3b(66, 66, 66))
        else
            nodeChip:setCardGrey(false)
        end
    end
    self:addClick(_panel)
end

-- 点击事件 --
function CardMagicWildExcCell:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if string.find(name, "Panel_") then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickCellByTag(tag)
    end
end

function CardMagicWildExcCell:clickCellByTag(_tag)
    local cardData = self.m_cardDataList[_tag]
    if not cardData then
        return
    end

    local excMainView = gLobalViewManager:getViewByName("CardMagicWildExcView")
    if not excMainView then
        return
    end

    local bSel = tonumber(cardData.cardId) == tonumber(CardSysManager:getWildExcMgr():getSelCardId())
    if bSel then
        CardSysManager:getWildExcMgr():setSelCardId(nil)
    else
        CardSysManager:getWildExcMgr():setSelCardId(cardData.cardId)
    end
    excMainView:updateCellSelState()
end

function CardMagicWildExcCell:updateCellSelState()
    for i = 1, #self.m_cardDataList do
        local cardData = self.m_cardDataList[i]
        local panel = self:findChild("Panel_" .. i)
        if cardData and panel then
            local spYes = panel:getChildByName("yes")

            local bSel = tonumber(cardData.cardId) == tonumber(CardSysManager:getWildExcMgr():getSelCardId())
            spYes:setVisible(bSel)
        end
    end
end

return CardMagicWildExcCell
