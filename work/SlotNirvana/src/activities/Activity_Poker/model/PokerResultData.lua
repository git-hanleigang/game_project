--[[
    deal 请求后数据
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local PokerResultData = class("PokerResultData")

function PokerResultData:ctor()
end

function PokerResultData:parseData(_resultData)
    self.p_progressItems = {}
    if _resultData.progressItems and #_resultData.progressItems > 0 then
        for i = 1, #_resultData.progressItems do
            local data = ShopItem:create()
            data:parseData(_resultData.progressItems[i])
            table.insert(self.p_progressItems, data)
        end
    end

    self.p_chapterCoins = _resultData.chapterCoins
    self.p_chapterItems = {}
    if _resultData.chapterItems and #_resultData.chapterItems > 0 then
        for i = 1, #_resultData.chapterItems do
            local data = ShopItem:create()
            data:parseData(_resultData.chapterItems[i])
            table.insert(self.p_chapterItems, data)
        end
    end

    self.p_roundCoins = _resultData.roundCoins
    self.p_roundItems = {}
    if _resultData.roundItems and #_resultData.roundItems > 0 then
        for i = 1, #_resultData.roundItems do
            local data = ShopItem:create()
            data:parseData(_resultData.roundItems[i])
            table.insert(self.p_roundItems, data)
        end
    end

    self.p_backProps = _resultData.backProps or 0 -- 溢出筹码，返还大活动道具
end

function PokerResultData:getProgressItems()
    return self.p_progressItems
end

function PokerResultData:getChapterCoins()
    return self.p_chapterCoins
end

function PokerResultData:getChapterItems()
    return self.p_chapterItems
end

function PokerResultData:getRoundCoins()
    return self.p_roundCoins
end

function PokerResultData:getRoundItems()
    return self.p_roundItems
end

function PokerResultData:getBackProps()
    return self.p_backProps
end

--[[--
    扩展方法
]]
function PokerResultData:hasChapterRewards()
    if self.p_chapterCoins and self.p_chapterCoins > 0 then
        return true
    end
    if self.p_chapterItems and #self.p_chapterItems > 0 then
        return true
    end
    return false
end

function PokerResultData:hasRoundRewards()
    if self.p_roundCoins and self.p_roundCoins > 0 then
        return true
    end
    if self.p_roundItems and #self.p_roundItems > 0 then
        return true
    end
    return false
end

function PokerResultData:hasRecallGame()
    local items = self:getProgressItems()
    if items and #items > 0 then
        return true
    end
    return false
end

return PokerResultData
