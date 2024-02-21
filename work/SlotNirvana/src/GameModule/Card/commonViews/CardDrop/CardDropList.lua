local CardDropList = class("CardDropList", BaseView)

function CardDropList:initDatas(_cardDatas)
    self.m_cardDatas = CardSysManager:getDropMgr():resetDropCardData(_cardDatas)
    self.m_colNum = 5

    local totalCardNum = #self.m_cardDatas

    self.m_rowNum = math.floor(totalCardNum / self.m_colNum)
    if math.fmod(totalCardNum, self.m_colNum) > 0 then
        self.m_rowNum = self.m_rowNum + 1
    end
end

--移动资源到包内
function CardDropList:getCsbName()
    if globalData.slotRunData.isPortrait == true then
        return "CardsBase201903/CardRes/season201903/cash_drop_list_shu.csb"    
    end
    return "CardsBase201903/CardRes/season201903/cash_drop_list.csb"
end

function CardDropList:initCsbNodes()
    self.m_listView = self:findChild("ListView_cards")
end

function CardDropList:initUI()
    CardDropList.super.initUI(self)

    self:adaptListViewSize()
    self:initListView()

    util_setCascadeColorEnabledRescursion(self, true)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

-- 只有一行或两行时，放在中间
function CardDropList:adaptListViewSize()
    local oriSize = self.m_listView:getContentSize()

    local CardDropChip = util_require("GameModule.Card.commonViews.CardDrop.CardDropChip")
    local chipSize = CardDropChip:getViewSize()

    local chipsHeight = self.m_rowNum * chipSize.height
    if chipsHeight <= oriSize.height then
        self.m_listView:setContentSize(cc.size(oriSize.width, chipsHeight))
        self.m_listView:setTouchEnabled(false)
    end

    -- 只有横版时放大1.5倍，竖版不放大
    if globalData.slotRunData.isPortrait == false then
        if #self.m_cardDatas <= self.m_colNum then
            self.m_listView:setScale(1.5)
        end
    end
    local listSize = self.m_listView:getContentSize()
    self.m_listWidth = listSize.width
    self.m_listHeight = listSize.height
end

function CardDropList:initListView()
    local actionCardNum = 15
    local totalCardNum = #self.m_cardDatas
    self.m_listView:setScrollBarEnabled(false)

    local CardDropChip = util_require("GameModule.Card.commonViews.CardDrop.CardDropChip")
    local chipSize = CardDropChip:getViewSize()
    local layoutSize = cc.size(self.m_listWidth, chipSize.height)

    local FrameLoadManager = util_require("manager/FrameLoadManager")
    self.m_fm = FrameLoadManager:getInstance()

    self.m_chips = {}
    self.m_nadoChips = {}
    local frameNum = math.ceil(totalCardNum / self.m_colNum)
    self.m_fm:addInfo(
        "createDropCell",
        frameNum,
        function(curLoadCount, totalCount)
            if tolua.isnull(self) then
                return
            end
            local layout = ccui.Layout:create()
            layout:setAnchorPoint(cc.p(0.5, 0.5))
            layout:setContentSize(layoutSize)
            local layoutNode = cc.Node:create()
            layout:addChild(layoutNode)
            layoutNode:setPosition(cc.p(layoutSize.width / 2, layoutSize.height / 2))
            local UIList = {}
            for j = 1, self.m_colNum do
                local cardIndex = j + (curLoadCount - 1) * self.m_colNum
                if cardIndex <= totalCardNum then
                    local cardData = self.m_cardDatas[cardIndex]
                    local chip = util_createView("GameModule.Card.commonViews.CardDrop.CardDropChip", cardData, cardIndex, actionCardNum, totalCardNum)
                    layoutNode:addChild(chip)
                    local chipSize = chip:getViewSize()
                    table.insert(UIList, {node = chip, anchor = cc.p(0.5, 0.5), scale = 1, size = cc.size(chipSize.width + 6, chipSize.height + 6)})
                    table.insert(self.m_chips, chip)
                    chip:initStatus()
                    if cardData.type == CardSysConfigs.CardType.link then
                        table.insert(self.m_nadoChips, chip)
                    end
                end
            end
            util_alignCenter(UIList)
            self.m_listView:pushBackCustomItem(layout)
        end
    )
    self.m_fm:start("createDropCell")

    -- local index = #self.m_cardDatas < self.m_colNum and #self.m_cardDatas or self.m_colNum
    -- local secondsLine = (index - 1) / 5 -- 取自 MiniChipUnit:playAnimByIndex
    -- local delayTime = ((index - 1) % 5) * 0.08 + (secondsLine > 0 and 0.04 or 0) -- 取自 MiniChipUnit:playAnimByIndex

    -- local MiniChipUnit = util_require("GameModule.Card.season201903.MiniChipUnit")
    -- local apTime = MiniChipUnit:getAppearTime()

    -- local offsetTime = 0.3

    -- local totolTime = frameNum * (1 / 60) + delayTime + apTime + offsetTime
    -- util_performWithDelay(
    --     self,
    --     function()
    --         if not tolua.isnull(self) then
    --             for i = 1, #self.m_chips do
    --                 local chip = self.m_chips[i]
    --                 if not tolua.isnull(chip) and chip.initStatus then
    --                     chip:initStatus()
    --                 end
    --             end
    --         end
    --     end,
    --     totolTime
    -- )

    -- for i = 1, self.m_rowNum do
    --     local layout = ccui.Layout:create()
    --     layout:setAnchorPoint(cc.p(0.5, 0.5))
    --     layout:setContentSize(layoutSize)
    --     local layoutNode = cc.Node:create()
    --     layout:addChild(layoutNode)
    --     layoutNode:setPosition(cc.p(layoutSize.width / 2, layoutSize.height / 2))
    --     local UIList = {}
    --     for j = 1, self.m_colNum do
    --         local cardIndex = j + (i - 1) * self.m_colNum
    --         if cardIndex <= totalCardNum then
    --             local cardData = self.m_cardDatas[cardIndex]
    --             local chip = util_createView("GameModule.Card.commonViews.CardDrop.CardDropChip", cardData )
    --             layoutNode:addChild(chip)
    --             local chipSize = chip:getViewSize()
    --             table.insert(UIList, {node = chip, anchor = cc.p(0.5, 0.5), scale = 1, size = cc.size(chipSize.width + 6, chipSize.height + 6)})
    --             table.insert(self.m_chips, chip)
    --             if cardData.type == CardSysConfigs.CardType.link then
    --                 table.insert(self.m_nadoChips, chip)
    --             end
    --         end
    --     end
    --     util_alignCenter(UIList)
    --     self.m_listView:pushBackCustomItem(layout)
    -- end
end

function CardDropList:getChips()
    return self.m_chips
end

function CardDropList:getNadoChips()
    return self.m_nadoChips
end

function CardDropList:setListTouchEnabled(_isTouchEnabled)
    self.m_listView:setTouchEnabled(_isTouchEnabled)
end

-- function CardDropList:playStart(startMove)
--     self:runCsbAction(
--         "start",
--         false,
--         function()
--             if not tolua.isnull(self) then
--                 if startMove then
--                     startMove()
--                 end
--                 self:runCsbAction("idle", true)
--             end
--         end
--     )
-- end

-- function CardDropList:scrollToStoreChip(_over)
--     local function callFunc()
--         if not tolua.isnull(self) then
--             for i = 1, #self.m_chips do
--                 self.m_chips[i]:playSwitch()
--             end
--             if _over then
--                 _over()
--             end
--         end
--     end
--     if self.m_rowNum <= 2 then
--         callFunc()
--         return
--     end
--     local distance = self.m_rowNum - 2
--     local time = 0.5
--     local totalTime = distance * time
--     -- self.m_listView:scrollToBottom(totalTime, true)
--     self.m_listView:scrollToItem(self.m_rowNum - 1, cc.p(0.5, 1), cc.p(0.5, 1), totalTime)
--     performWithDelay(self, callFunc, totalTime)
-- end

-- function CardDropList:hideStoreTicketChips(_over)
--     if self.m_storeTicketChips and #self.m_storeTicketChips > 0 then
--         for i = 1, #self.m_storeTicketChips do
--             self.m_storeTicketChips[i]:runAction(cc.FadeOut:create(0.3))
--         end
--         performWithDelay(
--             self,
--             function()
--                 if _over then
--                     _over()
--                 end
--             end,
--             0.3
--         )
--     else
--         if _over then
--             _over()
--         end
--     end
-- end

return CardDropList
