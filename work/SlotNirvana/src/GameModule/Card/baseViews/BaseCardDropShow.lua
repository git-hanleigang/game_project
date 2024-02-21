--[[
    集卡系统 卡片卡组掉落界面
]]
local BaseCardDropShow = class("BaseCardDropShow")

function BaseCardDropShow:ctor()
end

function BaseCardDropShow:purge()
end

--创建时候的初始化方法
function BaseCardDropShow:initData_(baseNode)
    self.m_listView = baseNode
    self.m_listView:setScrollBarEnabled(false)
    self.m_listView:onScroll(handler(self, self.scrollViewDidScroll))
end

--显示卡片
function BaseCardDropShow:createSlider(rowNum, cellSize)
    self.m_vCellSize = cellSize
    self.m_cardRowNum = rowNum
    --调用这个才会显示界面

    -- 创建 slider滑动条 --
    local listSize = self.m_listView:getContentSize()
    local bgFile = cc.Sprite:create(CardResConfig.DropSliderBg)
    local progressFile = cc.Sprite:create(CardResConfig.DropSliderBg)
    local thumbFile = cc.Sprite:create(CardResConfig.DropSliderMark)

    self.m_slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
    self.m_slider:setPosition(listSize.width * 0.5 - 20, self.m_listView:getPositionY() - 10)
    self.m_slider:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_slider:setRotation(90)
    self.m_slider:setEnabled(true)
    self.m_slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)

    self.m_slider:setVisible(true)
    local valueMin = -(self.m_vCellSize.height * self.m_cardRowNum - listSize.height)
    self.m_slider:setMinimumValue(valueMin)
    self.m_slider:setMaximumValue(0)
    self.m_slider:setValue(valueMin)

    self.m_listView:getParent():addChild(self.m_slider)

    -- 创建一个长背景条 保证滑块上下齐边 --
    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect()
    local addBgNode = ccui.ImageView:create(CardResConfig.DropSliderBg)
    addBgNode:setAnchorPoint(cc.p(0.5, 0.5))
    addBgNode:setScale9Enabled(true)
    addBgNode:setSize(cc.size(markSize.width + bgSize.width, bgSize.height))
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true
end
-- slider 滑动事件 --
function BaseCardDropShow:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        local sliderOff = self.m_slider:getValue()
        self.m_listView:setInnerContainerPosition(cc.p(0, sliderOff))
    end
    self.m_moveTable = true
end

-- tableView回调事件 --
--滚动事件
function BaseCardDropShow:scrollViewDidScroll(event)
    self.m_moveSlider = false
    if self.m_moveTable == true then
        if self.m_slider ~= nil then
            local offY = self.m_listView:getInnerContainerPosition().y
            self.m_slider:setValue(offY)
        end
    end
    self.m_moveSlider = true
end

-- 创建卡片单元
function BaseCardDropShow:createCards(cardDatas, layoutSize, isOnly)
    local spanX = 35
    local scale = 0.2384
    local cellWidth = 418 * scale
    local startX = (layoutSize.width - cellWidth * 6 - spanX * 5) * 0.5 + cellWidth * 0.5
    local layout = ccui.Layout:create()
    layout:setContentSize(layoutSize)
    local onlyXList = {0, 0, 0, 0, 0, 0}
    if isOnly then
        --只有一排时候特殊处理
        scale = 0.371
        if #cardDatas == 1 then
            onlyXList[1] = layoutSize.width * 0.5
        elseif #cardDatas == 2 then
            local newSpanX = 150
            onlyXList[1] = layoutSize.width * 0.5 - newSpanX
            onlyXList[2] = layoutSize.width * 0.5 + newSpanX
        elseif #cardDatas == 3 then
            local newSpanX = 250
            onlyXList[1] = layoutSize.width * 0.5 - newSpanX
            onlyXList[2] = layoutSize.width * 0.5
            onlyXList[3] = layoutSize.width * 0.5 + newSpanX
        elseif #cardDatas == 4 then
            local newSpanX = 120
            onlyXList[1] = layoutSize.width * 0.5 - newSpanX * 3
            onlyXList[2] = layoutSize.width * 0.5 - newSpanX
            onlyXList[3] = layoutSize.width * 0.5 + newSpanX
            onlyXList[4] = layoutSize.width * 0.5 + newSpanX * 3
        elseif #cardDatas == 5 then
            local newSpanX = 180
            onlyXList[1] = layoutSize.width * 0.5 - newSpanX * 2
            onlyXList[2] = layoutSize.width * 0.5 - newSpanX
            onlyXList[3] = layoutSize.width * 0.5
            onlyXList[4] = layoutSize.width * 0.5 + newSpanX
            onlyXList[5] = layoutSize.width * 0.5 + newSpanX * 2
        elseif #cardDatas == 6 then
            local newSpanX = 85
            onlyXList[1] = layoutSize.width * 0.5 - newSpanX * 5
            onlyXList[2] = layoutSize.width * 0.5 - newSpanX * 3
            onlyXList[3] = layoutSize.width * 0.5 - newSpanX
            onlyXList[4] = layoutSize.width * 0.5 + newSpanX
            onlyXList[5] = layoutSize.width * 0.5 + newSpanX * 3
            onlyXList[6] = layoutSize.width * 0.5 + newSpanX * 5
        end
    end
    for i = 1, #cardDatas do
        local cardData = cardDatas[i]
        local cardSprite = nil
        if cardData.type == CardSysConfigs.CardType.puzzle then
            -- 拼图卡
            cardSprite = util_createView("GameModule.Card.views.PuzzleCardUnitView", cardData, "show", cardData.firstDrop == true)
        else
            cardSprite = util_createView("GameModule.Card.views.MiniCardUnitView", cardData, nil, "show", true, self.m_useClanIcon, nil, true)
        end
        layout:addChild(cardSprite)
        cardSprite:setScale(scale)
        --光圈
        if cardData.type == CardSysConfigs.CardType.link then
            if cardSprite.bg then
                local spEff = util_createSprite(CardResConfig.DropLinkEff)
                spEff:setScale(2.73)
                cardSprite.bg:getParent():addChild(spEff, -1)
            end
        elseif cardData.type == CardSysConfigs.CardType.golden then
            if cardSprite.bg then
                local spEff = util_createSprite(CardResConfig.DropGoldEff)
                spEff:setScale(2.73)
                cardSprite.bg:getParent():addChild(spEff, -1)
            end
        end
        if isOnly then
            cardSprite:setPosition(onlyXList[i], layoutSize.height * 0.5)
        else
            cardSprite:setPosition(startX + (i - 1) * (spanX + cellWidth), layoutSize.height * 0.5)
        end
    end
    self.m_listView:pushBackCustomItem(layout)
end

--显示卡片
function BaseCardDropShow:flyCards(flyCardsData, useClanIcon)
    self.m_useClanIcon = useClanIcon
    local flyTime = 0.1
    local rowNum = 0
    local layoutSize = cc.size(900, 180)
    local index = 0
    local listData = {}
    if #flyCardsData <= 6 then
        --只有一行
        layoutSize.height = layoutSize.height * 2
        rowNum = rowNum + 1
        self:createCards(flyCardsData, layoutSize, true)
    else
        for i = 1, #flyCardsData do
            index = index + 1
            listData[#listData + 1] = flyCardsData[i]
            if index >= 6 then
                index = 0
                rowNum = rowNum + 1
                self:createCards(listData, layoutSize)
                listData = {}
            end
        end
        --最后一行不满的情况
        if #listData > 0 then
            rowNum = rowNum + 1
            self:createCards(listData, layoutSize)
        end
        if rowNum > 2 then
            --创建进度条
            self:createSlider(rowNum, layoutSize)
            performWithDelay(
                self.m_listView,
                function()
                    self.m_listView:scrollToBottom(0.5, true)
                end,
                0.7
            )
        end
    end
    return flyTime
end
return BaseCardDropShow
