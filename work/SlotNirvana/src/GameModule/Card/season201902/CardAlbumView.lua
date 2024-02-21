--[[
    集卡系统
    卡册选择面板子类 2020赛季
    数据来源于年度开启的赛季
--]]
local CardAlbumViewBase = util_require("GameModule.Card.baseViews.CardAlbumViewBase")
local CardAlbumView = class("CardAlbumView", CardAlbumViewBase)
-- 初始化UI --
-- function CardAlbumView:initUI(isPlayStart)
--     CardAlbumViewBase.initUI(self, isPlayStart)
-- end

-- 重写
function CardAlbumView:initTitle()
    self.m_caption_1_1:setString("Complete the Garden Album to win a prize")
end

-- 重写
function CardAlbumView:initBookUI()
    local bookPi1 = self:findChild("book_pi")
    local bookPi2 = self:findChild("book_pi_0")
    local kace = self:findChild("kace_1")

    util_changeTexture(bookPi1, "CardRes/ui/CashCards_book_fanye2020.png")
    util_changeTexture(bookPi2, "CardRes/ui/CashCards_book_fanye2020.png")
    util_changeTexture(kace, "CardRes/ui/kace2020.png")
end

-- 重写
function CardAlbumView:updateTableView()
    CardAlbumViewBase.updateTableView(self)
    self:initTableViewData()
    self:initTableView()
end

-- 获得一行卡册中起始的卡册index
-- 从0开始
function CardAlbumView:getStartClanIndexByCellIdx(cellType, cellIdx)
    local startClanIndex = 0
    if cellType == "WILD" then
        startClanIndex = self.m_wildCol * (cellIdx - 1)
    elseif cellType == "NORMAL" then
        cellIdx = cellIdx - self.m_wildLength
        startClanIndex = self.m_wildClanNum + self.m_normalCol * (cellIdx - 1)
    end
    return startClanIndex
end

-- 获得显示的一行中所有的卡册的数据
function CardAlbumView:getCellDataListByCellIdx(cellType, cellIdx)
    local cellDataList = {}
    if cellType == "WILD" then
        -- 3列数据
        for i = 1, self.m_wildCol do
            local dataIdx = self.m_wildCol * (cellIdx - 1) + i
            local wildClanData = self.m_wildClans[dataIdx]
            if wildClanData ~= nil then
                cellDataList[#cellDataList + 1] = wildClanData
            end
        end
    elseif cellType == "NORMAL" then
        -- 4列数据
        cellIdx = cellIdx - self.m_wildLength
        -- 正常数据走到这里一定是 cellIdx > 0 的
        if cellIdx <= 0 then
            print("data or logic is wrong!!!")
            return
        end
        for i = 1, self.m_normalCol do
            local dataIdx = self.m_normalCol * (cellIdx - 1) + i
            local normalClanData = self.m_normalClans[dataIdx]
            if normalClanData ~= nil then
                cellDataList[#cellDataList + 1] = normalClanData
            end
        end
    end
    return cellDataList
end

-- 到底何种方法有利于以后扩展
function CardAlbumView:initTableViewData()
    self.m_tableViewData, self.m_wildClans, self.m_normalClans = CardSysRuntimeMgr:getAlbumTalbeviewData()

    -- wild卡册的数量
    self.m_wildClanNum = #self.m_wildClans
    -- 通用卡册的数量
    self.m_normalClanNum = #self.m_normalClans

    -- TODO:wild卡册排序 没提需求先放着

    -- 根节点
    self.m_tableViewNode = self:findChild("TableView")
    self.m_tableViewSize = self.m_tableViewNode:getContentSize()

    -- tableview cell总个数
    self.m_tableViewLength = 0
    -- tableview每层的高度
    self.m_cellSizeList = {}

    -- 一行是一个tableview的cell
    -- 因为wild和normal的章节大小不一样，所以策划需要保证普通章节和wild章节不会在一行中显示

    -- 计算普通章节的行数
    self:initWildData()
    -- 通用章节
    self:initNormalData()

    -- dump(self.m_cellSizeList, "!!! -------------- self.m_cellSizeList == ", 3)
end

function CardAlbumView:initWildData()
    -- wild章节
    self.m_wildCol = 3
    self.m_wildCellSize = cc.size(self.m_tableViewSize.width, 270)
    -- 行数
    self.m_wildLength = math.ceil(self.m_wildClanNum / self.m_wildCol) -- wild占用的cell个数，这里是行数

    self.m_tableViewLength = self.m_tableViewLength + self.m_wildLength
    if self.m_wildLength > 0 then
        for i = 1, self.m_wildLength do
            self.m_cellSizeList[#self.m_cellSizeList + 1] = self.m_wildCellSize
        end
    end
end

function CardAlbumView:initNormalData()
    -- 通用章节
    self.m_normalCol = 4
    self.m_normalCellSize = cc.size(self.m_tableViewSize.width, 180)
    -- 行数
    self.m_normalLength = math.ceil(self.m_normalClanNum / self.m_normalCol) -- 占用的cell个数，这里是行数

    self.m_tableViewLength = self.m_tableViewLength + self.m_normalLength
    if self.m_normalLength > 0 then
        for i = 1, self.m_normalLength do
            self.m_cellSizeList[#self.m_cellSizeList + 1] = self.m_normalCellSize
        end
    end
end

function CardAlbumView:initTableView()
    -- 创建
    self.m_tableView = cc.TableView:create(self.m_tableViewSize)
    self.m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.m_tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_tableView:setDelegate()
    self.m_tableViewNode:addChild(self.m_tableView)

    -- 注册
    --registerScriptHandler functions must be before the reloadData funtion
    self.m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)
    self.m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
    --调用这个才会显示界面
    self.m_tableView:reloadData()

    local cellTotalSize = 0
    for i = 1, #self.m_cellSizeList do
        cellTotalSize = cellTotalSize + self.m_cellSizeList[i].height
    end
    self.maxCellSize = cellTotalSize
    self:initSlider(self.m_tableViewNode, CardResConfig.AlbumSliderBg, CardResConfig.AlbumSliderBg, CardResConfig.AlbumSliderMark, self.m_tableViewSize, cellTotalSize, self.m_tableViewLength)
end

function CardAlbumView:numberOfCellsInTableView(table)
    return self.m_tableViewLength
end

function CardAlbumView:cellSizeForTable(table, idx)
    print("!!! ----------------- idx ==", idx, self.m_cellSizeList[idx + 1].height) -- 从0开始计数
    return self.m_cellSizeList[idx + 1].width, self.m_cellSizeList[idx + 1].height
end

-- tableView回调事件 --
--滚动事件
function CardAlbumView:scrollViewDidScroll()
    self.m_moveSlider = false

    if self.m_moveTable == true then
        local offY = self.m_tableView:getContentOffset().y

        if self.m_slider ~= nil then
            local sliderY = self.m_slider:getValue()
            self.m_slider:setValue(offY)
        end
    end

    self.m_moveSlider = true
end

-- cell 更新 --
function CardAlbumView:tableCellAtIndex(table, idx)
    idx = idx + 1
    local cell = table:dequeueCell()
    if cell == nil then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end

    -- 区分不同高度类型的cell
    -- wild的高，normal的低
    local cellType = nil
    local cellSize = {}
    if idx <= self.m_wildLength then
        cellType = "WILD"
        cellSize = self.m_wildCellSize
    else
        cellType = "NORMAL"
        cellSize = self.m_normalCellSize
    end

    -- -- 调试代码
    -- local offset = cc.p(cell:getPosition())
    -- print("----- index offset ===== ", idx, offset.x, offset.y)
    -- dump(cellSize, " --- cellSize --- ", 3)

    if cellType ~= nil then
        local child = cell:getChildByName("ALBUMCELL")
        if not child then
            child = util_createView("GameModule.Card.season201902.CardAlbumCell")
            cell:addChild(child)
            child:setName("ALBUMCELL")
        end
        child:setPosition(cc.p(cellSize.width * 0.5, cellSize.height * 0.5))
        local startClanIndex = self:getStartClanIndexByCellIdx(cellType, idx)
        local cellDataList = self:getCellDataListByCellIdx(cellType, idx)
        assert(cellDataList ~= nil, "data wrong !!!")
        child:updateCell(idx, startClanIndex, cellType, cellDataList)
    end

    return cell
end

-- 滑动条 --
function CardAlbumView:initSlider(tableViewNode, bgIcon, proIcon, markIcon, tableViewSize, cellTotalSize, cellNum)
    -- 创建 slider滑动条 --
    local bgFile = cc.Sprite:create(bgIcon)
    local progressFile = cc.Sprite:create(proIcon)
    local thumbFile = cc.Sprite:create(markIcon)

    self.m_slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
    self.m_slider:setPosition(tableViewSize.width - 30, tableViewSize.height / 2)
    self.m_slider:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_slider:setRotation(90)
    self.m_slider:setEnabled(true)
    self.m_slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
    self.m_slider:setMinimumValue(-(cellTotalSize - tableViewSize.height))
    self.m_slider:setMaximumValue(0)
    self.m_slider:setValue(-(cellTotalSize - tableViewSize.height))
    tableViewNode:addChild(self.m_slider)

    self.m_sliderHeight = cellTotalSize - tableViewSize.height

    -- 创建一个长背景条 保证滑块上下齐边 --
    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect()
    local addBgNode = ccui.ImageView:create(bgIcon)
    addBgNode:setAnchorPoint(cc.p(0.5, 0.5))
    addBgNode:setScale9Enabled(true)
    addBgNode:setSize(cc.size(markSize.width + bgSize.width, bgSize.height))
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)

    --滑动条上面的link标志
    local bookNode = self:findChild("book")
    self.m_topLink = util_createView("GameModule.Card.views.CardAlbumSliderLinkTip", "up") -- cc.Sprite:create(CardResConfig.CARD_LINK_UP)
    bookNode:addChild(self.m_topLink)
    self.m_bottomLink = util_createView("GameModule.Card.views.CardAlbumSliderLinkTip", "down") -- cc.Sprite:create(CardResConfig.CARD_LINK_DOWN)
    bookNode:addChild(self.m_bottomLink)
    -- util_linkTipAction(self.m_topLink)
    -- util_linkTipAction(self.m_bottomLink)

    local posX, posY = self.m_tableViewNode:getPosition()
    self.m_topLink:setPosition(posX + tableViewSize.width / 2 - 30, posY + tableViewSize.height / 2 - 70)
    self.m_bottomLink:setPosition(posX + tableViewSize.width / 2 - 30, posY - tableViewSize.height / 2 + 70)

    self:afterSliderMove()
    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true
end

function CardAlbumView:afterSliderMove()
    if not self.m_sliderHeight then
        return
    end
    local sliderOff = self.m_slider:getValue()
    local bottom = -1 * sliderOff
    local top = self.maxCellSize - self.m_tableViewSize.height - bottom
    local topIndex
    local cellTotalSize = 0
    for i = 1, #self.m_cellSizeList do
        cellTotalSize = cellTotalSize + self.m_cellSizeList[i].height
        if top < cellTotalSize then
            topIndex = i - 1
            break
        end
    end

    local bottomIndex
    cellTotalSize = 0
    for i = #self.m_cellSizeList, 1, -1 do
        cellTotalSize = cellTotalSize + self.m_cellSizeList[i].height
        if bottom < cellTotalSize then
            bottomIndex = i + 1
            break
        end
    end

    local hasTop = false
    for i = 1, topIndex do
        local state = self:getIdxIsLink(i)
        if state and state == true then
            hasTop = true
            break
        end
    end
    if self.m_topLink:isVisibleEx() ~= hasTop then
        self.m_topLink:setVisible(hasTop)
    end
    local hasBottom = false
    for i = bottomIndex, #self.m_cellSizeList do
        local state = self:getIdxIsLink(i)
        if state and state == true then
            hasBottom = true
            break
        end
    end
    if self.m_bottomLink:isVisibleEx() ~= hasBottom then
        self.m_bottomLink:setVisible(hasBottom)
    end
end
function CardAlbumView:getIdxIsLink(idx)
    local cellType
    if idx <= self.m_wildLength then
        cellType = "WILD"
        return false
    else
        cellType = "NORMAL"
        local cellDataList = self:getCellDataListByCellIdx(cellType, idx)
        if cellDataList then
            for i = 1, #cellDataList do
                local unUse = CardSysRuntimeMgr:haveUnuseLinkCard(cellDataList[i].cards)
                if unUse then
                    return true
                end
            end
        end
        return false
    end
end
-- slider 滑动事件 --
function CardAlbumView:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        local sliderOff = self.m_slider:getValue()
        self.m_tableView:setContentOffset(cc.p(0, sliderOff))
    end
    self:afterSliderMove()
    self.m_moveTable = true
end

return CardAlbumView
