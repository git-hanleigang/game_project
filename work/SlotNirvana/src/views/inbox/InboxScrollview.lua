

local InboxScrollview = class("InboxScrollview")
function InboxScrollview:ctor()
end

function InboxScrollview:initScrollView()
    self.scrollView = ccui.ScrollView:create()
    self.scrollView:setDirection(ccui.LayoutType.VERTICAL)
    self.scrollView:setBounceEnabled(true)
    self.scrollView:setScrollBarEnabled(false)
    return self.scrollView
end

-- 设置显示列数
function InboxScrollview:setColNum(col)
    self.m_col = col
end

-- 设置ScrollView显示区域大小
function InboxScrollview:setDisplaySize(width, height)
    self.m_displayW, self.m_displayH = width, height
    if self.scrollView ~= nil then
        self.scrollView:setContentSize(cc.size(width, height))
    end
end

-- 单个cell的尺寸
function InboxScrollview:setCellSize(cellWidth, cellHeight)
    self.m_cellWidth, self.m_cellHeight = cellWidth, cellHeight
end

-- 设置间距
function InboxScrollview:setMargin(marginW, marginH)
    self.m_marginW = marginW
    self.m_marginH = marginH
end

-- 添加分割线
function InboxScrollview:setSplitLine(splitLineRes, offset)
    self.m_splitLineRes = splitLineRes
    self.m_splitLineOffset = offset or 0
end

-- 是否有选择状态
function InboxScrollview:setChoiceEnabled(canChoice)
    self.m_choiceEnabled = canChoice
end

function InboxScrollview:getChoiceEnabled()
    return self.m_choiceEnabled
end

-- 多选还是单选
function InboxScrollview:setChoiceType(type)
    self.m_choiceType = type
end

function InboxScrollview:getChoiceType()
    return self.m_choiceType
end

function InboxScrollview:resetList()
    self.scrollView:removeAllChildren()
    self.m_cellList = {}
end

-- 设置UI列表数据（锚点必须是0.5，0.5剧中对齐）
function InboxScrollview:initCellList(cellList)
    self.m_cellList = cellList
end

function InboxScrollview:getCellByIdx(index)
    return self.m_cellList[index]
end

--初始化UI列表
function InboxScrollview:initUIList()
    if self.scrollView ~= nil and #self.m_cellList > 0 then

        self.m_col = self.m_col or 1
        self.m_marginW = self.m_marginW or 0
        self.m_marginH = self.m_marginH or 0
        

        -- 显示的行数
        local row = math.ceil((#self.m_cellList)/self.m_col)

        local innerW, innerH = nil, nil
        innerW = self.m_col*self.m_cellWidth + (self.m_col-1)*self.m_marginW
        innerH = row*self.m_cellHeight + (row-1)*self.m_marginH
        -- 如果内部区域尺寸小于显示尺寸了，用显示尺寸当做内部尺寸，让显示贴在顶部
        innerH = math.max(self.m_displayH, innerH)
        -- 内容区域尺寸
        self.scrollView:setInnerContainerSize(cc.size(innerW, innerH))

        -- 计算 xIndexList, yIndexList
        self.m_xIndexList = {}
        for i=1,self.m_col do
            self.m_xIndexList[i] = (i-1)*(self.m_cellWidth + self.m_marginW)
        end
        self.m_yIndexList = {}
        for i=1,row do
            self.m_yIndexList[i] = innerH - i*self.m_cellHeight - (i-1)*self.m_marginH
        end
        
        -- 计算出每一个index的xy
        self.m_cellLayerList = {}
        for i=1,#self.m_cellList do
            local cell = self.m_cellList[i]
            cell:setAnchorPoint(cc.p(0.5, 0.5))
            cell:setPosition(self.m_cellWidth/2, self.m_cellHeight/2) -- 居中

            local layer = self:createCellLayer(i)
            layer:addChild(cell)
            self.scrollView:addChild(layer)
        end

        -- 添加分割线
        self:createSplitLine()
    
    end
end

function InboxScrollview:createCell(cellIndex)
    local cell = util_createView(self.m_cellPath, cellIndex, self)
    cell:setAnchorPoint(cc.p(0.5, 0.5))
    cell:setPosition(self.m_cellWidth/2, self.m_cellHeight/2) -- 居中
    return cell
end

function InboxScrollview:createCellLayer(cellIndex)
    local layout = ccui.Layout:create()
    layout:setSize(cc.size(self.m_cellWidth, self.m_cellHeight))
    local xIndex = cellIndex%self.m_col
    xIndex = xIndex ~= 0 and xIndex or self.m_col
    local layoutX = self.m_xIndexList[xIndex]
    local yIndex = math.ceil(cellIndex/self.m_col)
    local layoutY = self.m_yIndexList[yIndex]
    -- print("!!! ----------- cellIndex, xIndex, layoutX, yIndex, layoutY", cellIndex, xIndex, layoutX, yIndex, layoutY)
    layout:setPosition(cc.p(layoutX,layoutY))
    return layout
end

function InboxScrollview:createSplitLine()
    if self.m_splitLineRes and self.m_splitLineRes ~= "" then
        local row = math.ceil((#self.m_cellList)/self.m_col)
        if row > 1 then
            for i=1,row-1 do
                local splitLineSp = util_createSprite(self.m_splitLineRes)
                local splitLineSize = splitLineSp:getContentSize()
                local y = self.m_yIndexList[i] - splitLineSize.height*0.5 - self.m_splitLineOffset
                splitLineSp:setPosition(cc.p(0, y))
                splitLineSp:setAnchorPoint(cc.p(0, 0))
                self.scrollView:addChild(splitLineSp)
            end
        end
    end    
end


return InboxScrollview