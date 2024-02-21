--[[--
    拼图 - 碎片
]]
local BaseView = util_require("base.BaseView")
local PuzzleItem = class("PuzzleItem", BaseView)

function PuzzleItem:initUI()
    self:createCsbNode(CardResConfig.PuzzlePageItemsRes, isAutoScale)

    -- self.m_pageView = self:findChild("PageView_1")
    -- self.m_pageView:setVisible(false)
    self.m_nodeItems = self:findChild("node_items")
    self.m_pageLayout = self:findChild("Panel_1")
    self.m_nodeItems:setVisible(false)

    self.m_itemDis = 80

    -- self:initPageView()
    self:initItems()
end

-- function PuzzleItem:initPageView()
--     self.m_itemCells = {}
--     local _size = self.m_pageView:getContentSize()
--     local gameData = CardSysRuntimeMgr:getPuzzleGameData()
--     if gameData then
--         local puzzleDatas = gameData.puzzle
--         for i = 1, #puzzleDatas do
--             local _data = puzzleDatas[i]
--             -- 创建layout,内容添加到layout
--             local layout = ccui.Layout:create()
--             -- layout大小
--             layout:setContentSize(_size.width, _size.height)
--             -- 相对于PageView的位置
--             layout:setPosition(0, 0)

--             local itemCell = util_createView("GameModule.Card.season201904.PuzzlePage.PuzzleItemCell", _data.type)
--             layout:addChild(itemCell)
--             itemCell:setPosition(cc.p(_size.width / 2, _size.height / 2))
--             self.m_itemCells[_data.type] = itemCell

--             -- 加入pageView
--             self.m_pageView:addPage(layout)
--         end
--     end

--     self.m_pageView:addEventListener(handler(self, self.pageViewCallback))
-- end

function PuzzleItem:updateUI()
    if self.m_itemCells then
        for k,v in pairs(self.m_itemCells) do
            if v.updateUI then
                v:updateUI()
            end
        end
    end
end

function PuzzleItem:moveToPage(pageIndex)
    -- self.m_pageView:scrollToPage(pageIndex)
end

-- 翻页回调事件
-- function PuzzleItem:pageViewCallback(sender, event)
--     -- 翻页时
--     if event == ccui.PageViewEventType.turning then
--         -- getCurrentPageIndex() 获取当前翻到的页码 打印
--         local curPageIndex = self.m_pageView:getCurrentPageIndex()
--         printInfo("当前页码是" .. curPageIndex)
--         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_PUZZLE_ITEM, {pageIndex = curPageIndex})
--     end
-- end

function PuzzleItem:initItems()
    self.m_itemCells = {}
    local _size = self.m_pageLayout:getContentSize()
    local gameData = CardSysRuntimeMgr:getPuzzleGameData()
    if gameData then
        -- 创建node,内容添加到node
        self.m_rootNode = cc.Node:create()
        self.m_pageLayout:addChild(self.m_rootNode)
        local puzzleDatas = gameData.puzzle
        for i = 1, #puzzleDatas do
            local _data = puzzleDatas[i]

            local itemCell = util_createView("GameModule.Card.season201904.PuzzlePage.PuzzleItemCell", _data.type)
            self.m_rootNode:addChild(itemCell)
            itemCell:setPosition(cc.p(_size.width / 2 + (i - 1) * (_size.width + self.m_itemDis), _size.height / 2))
            self.m_itemCells[_data.type] = itemCell

            -- 加入pageView
            -- self.m_pageView:addPage(layout)
        end
    end
end

-- 更新页签坐标
function PuzzleItem:updatePageItemPos(offsetX)
    local nowX = self.m_rootNode:getPositionX()
    self.m_rootNode:setPositionX(nowX + offsetX)
end

function PuzzleItem:moveAct(desIdx, callbackFunc)
    local _size = self.m_pageLayout:getContentSize()
    local endPosX = (1 - desIdx) * (_size.width + self.m_itemDis)
    local moveAction = cc.MoveTo:create(0.2, cc.p(endPosX, 0))
    local callfunc =
        cc.CallFunc:create(
        function()
            if callbackFunc then
                callbackFunc()
            end
        end
    )
    local seq = cc.Sequence:create(moveAction, callfunc)
    self.m_rootNode:runAction(seq)
end

-- 取消移动回弹
function PuzzleItem:moveBackAct(offsetX, callbackFunc)
    local nowX = self.m_rootNode:getPositionX()
    local moveAction = cc.MoveTo:create(0.2, cc.p(nowX + offsetX, 0))
    local callfunc =
        cc.CallFunc:create(
        function()
            if callbackFunc then
                callbackFunc()
            end
        end
    )
    local seq = cc.Sequence:create(moveAction, callfunc)

    self.m_rootNode:runAction(seq)
end

return PuzzleItem
