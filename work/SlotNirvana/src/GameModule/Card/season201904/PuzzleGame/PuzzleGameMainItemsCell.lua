
--[[--
    小游戏 - 拼图碎片
]]
local PuzzleItemCell = util_require("GameModule.Card.season201904.PuzzlePage.PuzzleItemCell")
local PuzzleGameMainItemsCell = class("PuzzleGameMainItemsCell", PuzzleItemCell)

function PuzzleGameMainItemsCell:getItemByIndex(index)
    if index == 0 then
        -- 这里只有当获得碎片后才会调用， 如果没有获得碎片，调用时请传具体index
        print(" --- PuzzleGameMainItemsCell:getNewItem something wrong ---")
        return
    end
    return self.m_spItemList[index]
end

-- 获得最新的
function PuzzleGameMainItemsCell:getNewItem()
    local data = self:getPuzzleItemsData()
    return self:getItemByIndex(data.count)
end

function PuzzleGameMainItemsCell:crackDisappear(disappearCall)
    self:runCsbAction("crackDisappear", false, function()
        if disappearCall then
            disappearCall()
        end
    end)
end

function PuzzleGameMainItemsCell:playIdle1()
    self:runCsbAction("idle1")
end

return PuzzleGameMainItemsCell
