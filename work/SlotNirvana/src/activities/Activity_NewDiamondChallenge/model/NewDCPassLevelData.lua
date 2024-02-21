-- 暂时没用，先留着
local ShopItem = require "data.baseDatas.ShopItem"
local NewDCPassLevelData = class("NewDCPassLevelData")

--[[
    message LuckyChallengeV2PassLevel {
        optional int32 level = 1;
        optional int32 exp = 2;
        optional string rewardType = 3;//奖励类型
        optional string coins = 4;
        repeated ShopItem items = 5;
        optional int32 miniGameType = 6;//小游戏类型
    }
]]

function NewDCPassLevelData:parseData(_data)
    self.p_level = _data.level
    self.p_exp = _data.exp
    self.p_rewardType = _data.rewardType
    self.coins = _data.coins

    self.p_items = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local item = ShopItem:create()
            item:parseData(v)
            table.insert(self.p_levelList, item)
        end
    end

    self.p_miniGameType = _data.miniGameType
end

function NewDCPassLevelData:getTotalExp()
    return self.p_level
end

function NewDCPassLevelData:getCurExp()
    return self.p_exp
end

function NewDCPassLevelData:getLevelList()
    return self.p_rewardType
end

function NewDCPassLevelData:getLevelList()
    return self.p_items
end

function NewDCPassLevelData:getLevelList()
    return self.p_miniGameType
end

return NewDCPassLevelData