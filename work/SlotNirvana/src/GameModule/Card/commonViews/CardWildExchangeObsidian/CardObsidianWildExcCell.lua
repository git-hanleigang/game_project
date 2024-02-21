--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-24 14:17:04
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-24 15:00:05
FilePath: /SlotNirvana/src/GameModule/Card/commonViews/CardWildExchangeObsidian/CardObsidianWildExcCell.lua
Description: 集卡 黑耀卡 wild兑换 卡片 cell (10个miniChip 为一个cell)
--]]
local CardObsidianWildExcCell = class("CardObsidianWildExcCell", BaseView)

function CardObsidianWildExcCell:initDatas(_bShowAll)
    CardObsidianWildExcCell.super.initDatas(self)

    self.m_bShowAll = _bShowAll
    self.m_seasonId = G_GetMgr(G_REF.ObsidianCard):getSeasonId()
end

function CardObsidianWildExcCell:getCsbName()
    return string.format("CardRes/CardObsidian_%s/csb/wild/cash_wild_exchange_cell.csb", self.m_seasonId)
end

-- 创建 可兑换的卡片
function CardObsidianWildExcCell:updateUI(_cardDataList, _idx)
    self.m_cardDataList = _cardDataList

    for i=1, 10 do
        local panel = self:findChild("Panel_" .. i)
        panel:setSwallowTouches(false)
        panel:setTag(i)
        local cardData = _cardDataList[i]
        if cardData then
            self:createChipCell(cardData, panel, i)
        end

        panel:setVisible(cardData ~= nil)
    end
end

function CardObsidianWildExcCell:createChipCell(_cardData, _panel, _idx)
    local spYes = _panel:getChildByName("yes")
    local bSel = tonumber(_cardData.cardId) == tonumber(CardSysManager:getWildExcMgr():getSelCardId())
    spYes:setVisible(bSel)
    spYes:setScale(1.1)

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
function CardObsidianWildExcCell:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if string.find(name, "Panel_") then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickCellByTag(tag)
    end
end

function CardObsidianWildExcCell:clickCellByTag(_tag)
    local cardData = self.m_cardDataList[_tag]
    if not cardData then
        return
    end

    -- if cardData.count > 0 then  有卡了也让选
    --     return
    -- end

    local excMainView = gLobalViewManager:getViewByName("CardObsidianWildExcView")
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

function CardObsidianWildExcCell:updateCellSelState()

    for i=1, 10 do
        local cardData = self.m_cardDataList[i]
        if cardData then
            local panel = self:findChild("Panel_" .. i)
            local spYes = panel:getChildByName("yes")

            local bSel = tonumber(cardData.cardId) == tonumber(CardSysManager:getWildExcMgr():getSelCardId())
            spYes:setVisible(bSel)
        end
    end

end

return CardObsidianWildExcCell