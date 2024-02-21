--[[
]]
local JewelManiaJewelData = class("JewelManiaJewelData")
local ShopItem = require "data.baseDatas.ShopItem"

function JewelManiaJewelData:ctor()
end

-- message JewelManiaJewel {
--     optional int32 index = 1;
--     optional int32 type = 2;
--     repeated int32 positionList = 3;
--     optional bool collected = 4;
--     optional bool mined = 5;
--     repeated ShopItem items = 6;//对应的奖励
--   }
function JewelManiaJewelData:parseData(_netData)
    self.p_index = _netData.index
    self.p_type = _netData.type
    
    self.p_positionList = {}
    if _netData.positionList and #_netData.positionList > 0 then
        for i=1,#_netData.positionList do
            table.insert(self.p_positionList, _netData.positionList[i])
        end
    end
    
    self.p_collected = _netData.collected
    self.p_mined = _netData.mined == true
    self.p_specialRewardIndex = _netData.specialRewardIndex

    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i=1,#_netData.items do
            local itemData = ShopItem:create()
            itemData:parseData(_netData.items[i])
            table.insert(self.p_items, itemData)
        end
    end

end

function JewelManiaJewelData:getIndex()
    return self.p_index
end

function JewelManiaJewelData:getType()
    return self.p_type
end

function JewelManiaJewelData:getPositionList()
    return self.p_positionList
end

function JewelManiaJewelData:isCollected() --特殊章节道具奖励是否收集
    return self.p_collected
end

function JewelManiaJewelData:isMined()  --普通章节宝石是否开采 / 特殊章节道具是否被挖出 
    return self.p_mined
end

function JewelManiaJewelData:getItems()
    return self.p_items
end

-- function JewelManiaJewelData:getSpecialRewardIndex()  
--     return self.p_specialRewardIndex
-- end


return JewelManiaJewelData