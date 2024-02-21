-- word 玛雅小游戏数据
local POSITION_TYPE = {
    unopen = 1,
    opened_totem = 2,
    opened_coin = 3
}
local ShopItem = util_require("data.baseDatas.ShopItem")
local WordOpenStoneResponseData = util_require("activities.Activity_Word.model.WordOpenStoneResponseData")
local WordMayaGameData = class("WordMayaGameData")

-- message WordMayaGame {
--     optional int32 number = 1; // 第几轮玛雅游戏
--     optional int32 picks = 2; // 挖宝次数
--     optional int32 hitPicks = 3;//必中次数
--     repeated int32 positions = 4; //每个位置的奖励
--     optional int64 coins = 5;
--     repeated ShopItem items = 6;
--     repeated int32 findIcons = 7;// 已获得图标
--     optional string coinsV2 = 8;
--   }
function WordMayaGameData:parseData(_netData)
    self.p_number = _netData.number
    self.p_picks = _netData.picks
    self.p_hitPicks = _netData.hitPicks

    self.p_positions = {}
    if _netData.positions and #_netData.positions > 0 then
        for i = 1, #_netData.positions do
            table.insert(self.p_positions, _netData.positions[i])
        end
    end

    self.p_findIcons = {}
    if _netData.findIcons and #_netData.findIcons > 0 then
        for i = 1, #_netData.findIcons do
            table.insert(self.p_findIcons, _netData.findIcons[i])
        end
    end

    self.p_coins = _netData.coinsV2

    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i = 1, #_netData.items do
            local sItem = ShopItem:create()
            sItem:parseData(_netData.items[i])
            table.insert(self.p_items, sItem)
        end
    end
end

function WordMayaGameData:getNumber()
    return self.p_number
end

function WordMayaGameData:getPicks()
    return self.p_picks
end

function WordMayaGameData:getHitPicks()
    return self.p_hitPicks
end

function WordMayaGameData:getPositions()
    return self.p_positions
end

function WordMayaGameData:getFindIcons()
    return self.p_findIcons
end

function WordMayaGameData:getCoins()
    return self.p_coins
end

function WordMayaGameData:getItems()
    return self.p_items
end

--[[--
    解析数据返回值
]]
function WordMayaGameData:parseOpenStoneData(_responseData)
    self.p_openStoneData = WordOpenStoneResponseData:create()
    self.p_openStoneData:parseData(_responseData)
end

function WordMayaGameData:getOpenStoneResponseData()
    return self.p_openStoneData
end

--[[--
    扩展函数
]]
function WordMayaGameData:isPositionOpened(_posValue)
    if _posValue == -1 then
        return false
    end
    return true
end

function WordMayaGameData:isPositionTotem(_posValue)
    if _posValue >= 1 and _posValue <= 8 then
        return true
    end
    return false
end

function WordMayaGameData:isPositionCoin(_posValue)
    if _posValue == 999 then
        return true
    end
    return false
end

function WordMayaGameData:isFindIcon(_totemIndex)
    local findIcons = self:getFindIcons()
    if findIcons and #findIcons > 0 then
        for i = 1, #findIcons do
            if findIcons[i] == _totemIndex then
                return true
            end
        end
    end
    return false
end

return WordMayaGameData
