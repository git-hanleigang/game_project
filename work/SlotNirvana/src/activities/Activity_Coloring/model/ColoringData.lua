--[[--
    涂色数据
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local ColoringData = class("ColoringData", BaseActivityData)

ColoringData.CHAPTER_STATUS = {
    FINISH = "Finish",
    UNLOCKED = "Unlocked",
    LOCKED = "Locked"
}

ColoringData.TYPE = {
    FREE = "FREE",
    PAY = "PAY",
}

-- message PaintData {
--     optional string activityId = 1;
--     optional string name = 2;
--     optional string begin = 3;
--     optional int64 expireAt = 4;
--     optional int32 expire = 5;
--     repeated PaintChapter chapters = 6; // 章节数据
--     optional int32 current = 7; // 当前章节
--     optional int32 leftPigments = 8;// 剩余颜料数量
--     optional PaintPay payPrice = 9; // 付费解锁信息
--   }

--   message PaintChapter {
    --     repeated PaintPiece pieces = 1; // 图块信息
    --     repeated ShopItem rewards = 2; // 奖励
    --     optional string type = 3;// pay & free
    --     optional int64 coins = 4; 
    --     optional string status = 5; // Finish Unlocked Locked
    --     optional int32 colorIndex = 6; // 图块位置
--   }
  
--   message PaintPiece {
--     optional int32 index = 1; // 图块位置
--     optional string color = 2; // 0 未涂色
--     repeated string colors = 3; //可选颜色
--   }

--   message PaintPay {
--     optional string key = 1;
--     optional string keyId = 2;
--     optional string price = 3;
--     optional int64 coins = 4;
--   }

function ColoringData:parseData(_data)
    ColoringData.super.parseData(self, _data)
    
    self.p_current = _data.current
    self.p_leftPigments = _data.leftPigments
    self.p_paintChapter = self:parsePaintChapter(_data.chapters)
    self.p_payPrice = self:parsePayPrice(_data.payPrice)
end

function ColoringData:parsePaintChapter(_data)
    local chapterData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_type = v.type
            tempData.p_coins = v.coins
            tempData.p_status = v.status
            tempData.p_colorIndex = v.colorIndex
            tempData.p_items  = self:parseItemsData(v.rewards) -- 奖励物品 
            tempData.p_pieces = self:parsePieces(v.pieces)
            table.insert(chapterData, tempData)
        end
    end
    return chapterData
end

function ColoringData:parsePieces(_data)
    local piecesData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_index = v.index
            tempData.p_color = v.color
            tempData.p_colors = v.colors
            piecesData[v.index] = tempData
        end
    end
    return piecesData
end

-- 解析道具数据
function ColoringData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function ColoringData:parsePayPrice(_data)
    local payData = {}
    payData.p_key = _data.key
    payData.p_keyId = _data.keyId
    payData.p_price = _data.price
    payData.p_coins = _data.coins
    return payData
end

function ColoringData:parseSlotPaintData(_data)
    self.p_iconNum = _data.iconNum
    self.p_dropNum = _data.dropNum
    self.p_leftPigments = _data.leftPigment
    if self.p_dropNum > 0 then 
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_COLORING_SLOT_DROP)
    end
end

function ColoringData:getSlotPaintData()
    return self.p_iconNum or 0, self.p_dropNum or 0
end

function ColoringData:getCurrentChapter()
    return self.p_current
end

function ColoringData:getLeftPigments()
    return self.p_leftPigments
end

-- 颜料盘
function ColoringData:getColors(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    local piecesIndex = chapterInfo.p_colorIndex
    return chapterInfo.p_pieces[piecesIndex].p_colors
end

-- 以涂颜色
function ColoringData:getColor(_chapterIndex, _index)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    return chapterInfo.p_pieces[_index].p_color
end

function ColoringData:getPiecesCount(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    return #chapterInfo.p_pieces
end

function ColoringData:getChapterStatus(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    return chapterInfo.p_status
end

function ColoringData:getChapter(_chapterIndex)
    return self.p_paintChapter[_chapterIndex]
end

function ColoringData:getChapterReward(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    return  chapterInfo.p_coins, chapterInfo.p_items
end

-- 付费点key
function ColoringData:getGoodsId()
    return self.p_payPrice.p_key
end

-- 价格
function ColoringData:getPrice()
    return self.p_payPrice.p_price
end

-- 付费奖励
function ColoringData:getPayCoins()
    return self.p_payPrice.p_coins
end

-- 章节完成
function ColoringData:isChapterFinish(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    return chapterInfo.p_status == self.CHAPTER_STATUS.FINISH
end

-- 章节未解锁
function ColoringData:isChapterLock(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    return chapterInfo.p_status == self.CHAPTER_STATUS.LOCKED
end

-- 章节解锁
function ColoringData:isChapterUnlock(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    return chapterInfo.p_status == self.CHAPTER_STATUS.UNLOCKED
end

-- 最后一个章节
function ColoringData:isLastChapter(_chapterIndex)
    return _chapterIndex == #self.p_paintChapter
end

-- 付费章节
function ColoringData:isPayChapter(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    if chapterInfo.p_type == self.TYPE.FREE then 
        return false
    elseif chapterInfo.p_type == self.TYPE.PAY then 
        return true
    end
end

-- 涂色进度
function ColoringData:getColorProgress(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    if chapterInfo.p_status == self.CHAPTER_STATUS.FINISH then 
        return #chapterInfo.p_pieces, #chapterInfo.p_pieces
    elseif chapterInfo.p_status == self.CHAPTER_STATUS.LOCKED then 
        return 0, #chapterInfo.p_pieces
    elseif chapterInfo.p_status == self.CHAPTER_STATUS.UNLOCKED then 
        return chapterInfo.p_colorIndex - 1, #chapterInfo.p_pieces
    end
end

-- 章节总数
function ColoringData:getChapterCount()
    return #self.p_paintChapter
end

-- 图块位置
function ColoringData:getColorIndex(_chapterIndex)
    local chapterInfo = self.p_paintChapter[_chapterIndex]
    return chapterInfo.p_colorIndex
end

function ColoringData:getChapterItemByIndex(_chapter, _index)
    local chapterInfo = self.p_paintChapter[_chapter]
    local items = chapterInfo.p_items
    return items[_index] 
end

function ColoringData:clearSlotPaintData()
    self.p_dropNum = 0
    self.p_iconNum = 0
end

function ColoringData:getPositionBar()
    return 1
end

return ColoringData
