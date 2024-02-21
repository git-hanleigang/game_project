--[[
    送随机卡
]]
local RandomCardNode = class("RandomCardNode", BaseView)

function RandomCardNode:getCsbName()
    return "PigBank2022/csb/bubbles/node_RandomCards.csb"
end

function RandomCardNode:initCsbNodes()
    self.m_randomCardNode = self:findChild("node_cards")
end

function RandomCardNode:initUI()
    RandomCardNode.super.initUI(self)
    self:initPigRandomCardUI()
end

function RandomCardNode:initPigRandomCardUI()
    local actData = G_GetMgr(ACTIVITY_REF.PigRandomCard):getRunningData()
    if not actData then
        return
    end
    -- 以前缩放的是整体的PigRandomCardNode
    local cardScale = 0.25
    -- 只缩放chipUI
    local chipUIScale = 0.15
    -- 缩放Mask（star这个sprite）
    local maskScale = 1.1
    -- 缩放对号
    local checkScale = 0.5
    if globalData.slotRunData.isPortrait == true then
        cardScale = 0.2
        chipUIScale = 0.15
        maskScale = 1.2
        checkScale = 0.4
    end
    local cardsData = actData:getCards()
    local themeName = G_GetMgr(ACTIVITY_REF.PigRandomCard):getThemeName()
    assert(cardsData and #cardsData > 0, "配置表没有配置卡牌或者服务器数据错误")
    -- 初始化卡牌组件
    self.m_cardUIList = {}
    local cardsUI = self.m_randomCardNode:getChildren()
    if not cardsUI or #cardsUI == 0 then
        local infoList = {}
        for i = 1, #cardsData do
            local cardUI = util_createView(themeName..".PigRandomCardNode", cardsData[i])
            if cardUI then
                self.m_randomCardNode:addChild(cardUI)
                -- cardUI:setScale(cardScale)
                cardUI:setChipUIScale(chipUIScale)
                cardUI:setMaskAndCheckScale(maskScale, checkScale)
                table.insert(self.m_cardUIList, cardUI)
                table.insert(infoList, {node = cardUI, size = cc.size(290 * cardScale, 270 * cardScale), anchor = cc.p(0.5, 0.5)})
            end
        end
        if #infoList > 0 then
            util_alignCenter(infoList)
        end
    end
    -- 刷新卡牌
    if self.m_cardUIList and #self.m_cardUIList > 0 then
        for i = 1, #self.m_cardUIList do
            self.m_cardUIList[i]:setStarMaskShow(cardsData[i].count > 0)
            self.m_cardUIList[i]:setNewTagShow(cardsData[i].newCard == true)
            self.m_cardUIList[i]:setMaskAndCheckScale(maskScale, checkScale)
        end
    end
end

return RandomCardNode
