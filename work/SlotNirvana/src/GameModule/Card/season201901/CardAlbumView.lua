--[[
    集卡系统  
    卡册选择面板子类 201901赛季
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
    self.m_caption_1_1:setString("Complete the Magic Album to win a prize")
end

-- 重写
function CardAlbumView:initBookUI()
    local bookPi1 = self:findChild("book_pi")
    local bookPi2 = self:findChild("book_pi_0")
    local kace = self:findChild("kace_1")

    util_changeTexture(bookPi1, "CardRes/other/CashCards_book_fanye2019.png")
    util_changeTexture(bookPi2, "CardRes/other/CashCards_book_fanye2019.png")
    util_changeTexture(kace, "CardRes/other/kace2019.png")
end

-- 重写
function CardAlbumView:updateTableView()
    CardAlbumViewBase.updateTableView(self)
    self:initTableView()
end

function CardAlbumView:initTableView()
    -- 规定3列
    self.m_col = 3
    self.m_colInterval = 10
    -- 数据
    local cardClanData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    self.m_tableViewLength = math.ceil(#cardClanData / self.m_col)

    -- UI数据
    -- 根节点
    self.m_tableViewNode = self:findChild("TableView")
    self.m_tableViewSize = self.m_tableViewNode:getContentSize()
    local offset = 0
    self.m_cellSize = cc.size(self.m_tableViewSize.width, 220)

    self.m_albumCellSize = cc.size(360, 230)

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
    self:initSlider(self.m_tableViewNode, CardResConfig.AlbumSliderBg, CardResConfig.AlbumSliderBg, CardResConfig.AlbumSliderMark, self.m_tableViewSize, self.m_cellSize, self.m_tableViewLength)
end

function CardAlbumView:numberOfCellsInTableView(table)
    return self.m_tableViewLength
end

function CardAlbumView:cellSizeForTable(table, idx)
    return self.m_cellSize.width, self.m_cellSize.height
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

    if nil == cell then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end

    local firstX = self.m_cellSize.width * 0.5 - (self.m_albumCellSize.width + self.m_colInterval)
    local y = self.m_cellSize.height * 0.5
    for i = 1, self.m_col do
        local dataIndex = self.m_col * (idx - 1) + i
        local cardClanData = CardSysRuntimeMgr:getAlbumTalbeviewData()
        local cellData = cardClanData[dataIndex]
        if cellData ~= nil then
            local view = util_createView("GameModule.Card.season201901.CardAlbumCell")
            view:setTag(1000 + i)
            local x = firstX + (i - 1) * (self.m_albumCellSize.width + self.m_colInterval)
            view:setPosition(cc.p(x, y))
            cell:addChild(view)
        end
    end

    for i = 1, self.m_col do
        local view = cell:getChildByTag(1000 + i)
        local dataIndex = self.m_col * (idx - 1) + i
        if nil ~= view then
            local cardClanData = CardSysRuntimeMgr:getAlbumTalbeviewData()
            local cellData = cardClanData[dataIndex]
            if cellData ~= nil then
                view:updateCell(dataIndex, cellData)
            end
        end
    end
    return cell
end

-- 滑动条 --
function CardAlbumView:initSlider(tableViewNode, bgIcon, proIcon, markIcon, tableViewSize, cellSize, cellNum)
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
    self.m_slider:setMinimumValue(-(cellSize.height * cellNum - tableViewSize.height))
    self.m_slider:setMaximumValue(0)
    self.m_slider:setValue(-(cellSize.height * cellNum - tableViewSize.height))
    tableViewNode:addChild(self.m_slider)

    -- 创建一个长背景条 保证滑块上下齐边 --
    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect()
    local addBgNode = ccui.ImageView:create(bgIcon)
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
function CardAlbumView:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        local sliderOff = self.m_slider:getValue()
        self.m_tableView:setContentOffset(cc.p(0, sliderOff))
    end
    self.m_moveTable = true
end

return CardAlbumView
