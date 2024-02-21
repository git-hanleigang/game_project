--[[--
    小游戏 - 拼图
]]

-- 虽然继承了PuzzleItem，但是所有方法都重写了，其实没有继承的意义，只是用了同一个csb
-- local PuzzleItem = util_require("GameModule.Card.season201904.PuzzlePage.PuzzleItem")

local BaseView = util_require("base.BaseView")
local PuzzleGameMainItems = class("PuzzleGameMainItems", BaseView)
function PuzzleGameMainItems:initUI(pageType, puzzleType)
    self:createCsbNode(CardResConfig.PuzzlePageItemsRes, isAutoScale)
    
    self.m_itemsNode = self:findChild("node_items")

    self.m_pageType = pageType
    self.m_puzzleType = puzzleType
    self:initItems()
end

function PuzzleGameMainItems:getPuzzleType()
    return self.m_puzzleType
end

function PuzzleGameMainItems:getPageType()
    return self.m_pageType
end

function PuzzleGameMainItems:initItems()
    self.m_itemsUI = util_createView("GameModule.Card.season201904.PuzzleGame.PuzzleGameMainItemsCell", self.m_pageType)
    self.m_itemsNode:addChild(self.m_itemsUI)
end

function PuzzleGameMainItems:getItemUI()
    return self.m_itemsUI
end

function PuzzleGameMainItems:updateUI(noCheckMax)
    if self.m_itemsUI and self.m_itemsUI.updateUI then
        self.m_itemsUI:updateUI(noCheckMax)
    end
end

return PuzzleGameMainItems