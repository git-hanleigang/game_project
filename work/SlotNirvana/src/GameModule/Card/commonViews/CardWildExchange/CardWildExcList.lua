--[[--
    wild兑换 卡牌列表
]]
local CELL_WIDTH = 1043
local CELL_HEIGHT_1 = 310
local CELL_HEIGHT_2 = 495
local CardWildExcList = class("CardWildExcList", util_require("base.BaseView"))
function CardWildExcList:initUI(_parentNode, _albumData)
    -- self.m_vCellSize = cc.size(CELL_WIDTH, CELL_HEIGHT_2)
    self.m_tableViewSize = _parentNode:getContentSize()
    self.m_CurAlbumData = _albumData

    self:initTotalHeight()

    self:createTableView()
    -- self:createSlide()

    -- 监测互斥的方案 --
    self.m_moveTable = true
    self.m_moveSlider = true
end

function CardWildExcList:initTotalHeight()
    local cellWidth = CELL_WIDTH
    local cellHeight = CELL_HEIGHT_2

    for i = 1, #self.m_CurAlbumData.cardClans do
        local clanData = self.m_CurAlbumData.cardClans[i]
        if #clanData.cards == 0 then
            cellWidth = CELL_WIDTH
            cellHeight = 1
        elseif #clanData.cards <= 5 then
            cellWidth = CELL_WIDTH
            cellHeight = CELL_HEIGHT_1
        else
            cellWidth = CELL_WIDTH
            cellHeight = CELL_HEIGHT_2
        end
        self.m_totalH = (self.m_totalH or 0) + cellHeight
    end
end

function CardWildExcList:createTableView()
    --创建TableView
    self.m_tableView = cc.TableView:create(self.m_tableViewSize)
    --设置滚动方向  水平滚动
    self.m_tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    self.m_tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    self.m_tableView:setDelegate()
    self:addChild(self.m_tableView)

    --registerScriptHandler functions must be before the reloadData funtion
    self.m_tableView:registerScriptHandler(handler(self, self.numberOfCellsInTableView), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    self.m_tableView:registerScriptHandler(handler(self, self.cellSizeForTable), cc.TABLECELL_SIZE_FOR_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.tableCellAtIndex), cc.TABLECELL_SIZE_AT_INDEX)
    self.m_tableView:registerScriptHandler(handler(self, self.scrollViewDidScroll), cc.SCROLLVIEW_SCRIPT_SCROLL)

    --调用这个才会显示界面
    self.m_tableView:reloadData()
end

function CardWildExcList:createSlide()
    -- 创建 slider滑动条 --
    local bgFile = cc.Sprite:create(CardResConfig.RuleSliderBg)
    local progressFile = cc.Sprite:create(CardResConfig.RuleSliderBg)
    local thumbFile = cc.Sprite:create(CardResConfig.WildSliderMark)

    self.m_slider = cc.ControlSlider:create(bgFile, progressFile, thumbFile)
    self.m_slider:setPosition(self.m_tableViewSize.width - 30, self.m_tableViewSize.height / 2)
    self.m_slider:setAnchorPoint(cc.p(0.5, 0.5))
    self.m_slider:setRotation(90)
    self.m_slider:setEnabled(true)
    self.m_slider:setScale(0.8)
    self.m_slider:setMinimumValue(-(self.m_totalH - self.m_tableViewSize.height))
    self.m_slider:setMaximumValue(0)
    self.m_slider:setValue(-(self.m_totalH - self.m_tableViewSize.height))

    self.m_slider:registerControlEventHandler(handler(self, self.sliderMoveEvent), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
    -- -- 放到最后吧，往上放的话在切换赛季时偏移量会有问题，像是偏移量使用的上一个赛季的
    self:addChild(self.m_slider)
    -- 创建一个长背景条 保证滑块上下齐边 --
    local markSize = thumbFile:getTextureRect()
    local bgSize = bgFile:getTextureRect()
    local addBgNode = ccui.ImageView:create(CardResConfig.RuleSliderBg)
    addBgNode:setAnchorPoint(cc.p(0.5, 0.5))
    addBgNode:setScale9Enabled(true)
    addBgNode:setSize(cc.size(markSize.width + bgSize.width, bgSize.height))
    addBgNode:setPosition(cc.p(self.m_slider:getContentSize().width / 2, self.m_slider:getContentSize().height / 2))
    self.m_slider:addChild(addBgNode, -1)
end

-- slider 滑动事件 --
function CardWildExcList:sliderMoveEvent()
    self.m_moveTable = false
    if self.m_moveSlider == true then
        local sliderOff = self.m_slider:getValue()
        self.m_tableView:setContentOffset(cc.p(0, sliderOff))
    end
    self.m_moveTable = true
end

-- tableView回调事件 --
--滚动事件
function CardWildExcList:scrollViewDidScroll(view)
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

--cell的大小，注册事件就能直接影响界面，不需要主动调用
function CardWildExcList:cellSizeForTable(table, idx)
    local cellWidth = CELL_WIDTH
    local cellHeight = CELL_HEIGHT_2

    local cardNum = #(self.m_CurAlbumData.cardClans[idx + 1].cards)

    if cardNum == 0 then
        cellWidth = CELL_WIDTH
        cellHeight = 1
    elseif cardNum <= 5 then
        cellWidth = CELL_WIDTH
        cellHeight = CELL_HEIGHT_1
    else
        cellWidth = CELL_WIDTH
        cellHeight = CELL_HEIGHT_2
    end

    return cellWidth, cellHeight
end

--显示出可视部分的界面，出了裁剪区域的cell就会被复用
function CardWildExcList:tableCellAtIndex(table, idx)
    local cell = table:dequeueCell()
    if cell == nil then
        cell = cc.TableViewCell:new()
    end

    local clanCell = cell:getChildByTag(10)
    if clanCell ~= nil then
        cell:removeAllChildren()
    end
    local cellNum = #(self.m_CurAlbumData.cardClans[idx + 1].cards)
    local posY = 0
    local bShow = true
    local isOneLine = false
    if cellNum == 0 then
        posY = 0
        bShow = false
    elseif cellNum <= 5 then
        isOneLine = true
        posY = CELL_HEIGHT_1 / 2
    else
        posY = CELL_HEIGHT_2 / 2
    end

    if bShow then
        local clanCell = util_createView("GameModule.Card.commonViews.CardWildExchange.CardWildExcCell" .. self.m_CurAlbumData.albumId, isOneLine)
        clanCell:setTag(10)
        clanCell:setPosition(cc.p(self.m_tableViewSize.width / 2, posY))
        clanCell:loadDataRes(idx + 1, self.m_CurAlbumData.cardClans[idx + 1])
        cell:addChild(clanCell)
    end
    return cell
end

--设置cell个数，注册就能生效，不用主动调用
function CardWildExcList:numberOfCellsInTableView(table)
    return #self.m_CurAlbumData.cardClans
end

return CardWildExcList
