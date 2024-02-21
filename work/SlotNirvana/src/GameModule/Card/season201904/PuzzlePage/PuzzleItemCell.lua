
--[[--
    小游戏 - 拼图碎片
]]
local BaseView = util_require("base.BaseView")
local PuzzleItemCell = class("PuzzleItemCell", BaseView)
function PuzzleItemCell:initUI(pageType)
    self:createCsbNode(CardResConfig.PuzzlePageItemsCellRes, isAutoScale)

    self.m_pageType = pageType

    self.m_iconName = self:getName()
    self:initNode()

    self:updateUI()
end


function PuzzleItemCell:getName()
    if self.m_pageType == "NORMAL" then
        return "Ordinary"
    elseif self.m_pageType == "GOLDEN" then
        return "Gold"
    elseif self.m_pageType == "NADO" then
        return "Nado"
    end
end

function PuzzleItemCell:getItemIconPath(index)
    return string.format("CardRes/season201904/CashPuzzle/img/PuzzleCard/CashPuzzle_PuzzleCard_Wild%s_%d.png", self.m_iconName, index)
end

function PuzzleItemCell:getBgIcon()  
    local icon = string.format("CardRes/season201904/CashPuzzle/img/PuzzleCard/CashPuzzle_PuzzleCard_Wild%s.png", self.m_iconName)
    local allIcon = string.format("CardRes/season201904/CashPuzzle/other/CashPuzzle_PuzzleCard_Wild_%s.png", self.m_iconName)
    return icon, allIcon
end

function PuzzleItemCell:initNode()
    local iconPath1, iconPath2 = self:getBgIcon()

    -- 完整版有缝隙
    self.Node_complete_crack = self:findChild("Node_complete_crack")
    self.sp_complete_crack = self:findChild("sp_complete_crack")
    util_changeTexture(self.sp_complete_crack, iconPath1)

    -- 完整版无缝隙
    self.Node_complete_nocrack = self:findChild("Node_complete_nocrack")
    self.sp_complete_nocrack = self:findChild("sp_complete_nocrack")
    util_changeTexture(self.sp_complete_nocrack, iconPath2)
    
    -- 碎片
    self.Node_items = self:findChild("Node_items")
    self.m_spItemList = {}
    for i=1,12 do
        local item = self:findChild("item_"..i)
        local path = self:getItemIconPath(i)
        util_changeTexture(item, path)
        self.m_spItemList[i] = item
    end

end

function PuzzleItemCell:getPuzzleItemsData()
    local data = CardSysRuntimeMgr:getPuzzleGameData()
    for i=1,#data.puzzle do
        local itemData = data.puzzle[i]
        if itemData.type == self.m_pageType then
            return data.puzzle[i]
        end
    end
end

-- noCheckMax:不将最大值12转换成0
function PuzzleItemCell:updateUI(noCheckMax)
    local data = self:getPuzzleItemsData()

    local count = data.count
    if not noCheckMax then
        count = count < 12 and count or 0
    end

    -- 碎片
    for i=1,#self.m_spItemList do
        local spItem = self.m_spItemList[i]
        spItem:setVisible(i > count)
    end
end

return PuzzleItemCell
