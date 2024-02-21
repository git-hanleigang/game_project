--[[
    宝箱奖励和状态信息
    author:{author}
    time:2020-09-24 11:12:22
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local BattlePassBoxRewardInfo = class("BattlePassBoxRewardInfo")

function BattlePassBoxRewardInfo:ctor()
    -- 奖励资源图
    self.p_icon = ""
    -- 奖励描述
    self.p_description = ""
    -- 金币奖励价值
    self.p_coinValue = 0
    -- 奖励领取标识
    self.p_prized = false
    -- 奖励类型
    self.p_type = nil
    -- 物品奖励
    self.p_rewardItem = {}
end

function BattlePassBoxRewardInfo:parseData(data)
    if not data then
        return
    end

    -- 奖励资源图
    self.p_icon = data.icon
    -- 奖励描述
    self.p_description = data.description
    -- 金币奖励价值
    self.p_coinValue = data.coinValue
    -- 奖励领取标识
    self.p_prized = data.prized

    self.p_type = data.type

    if #data.rewardItems > 0 then
        for i = 1, #data.rewardItems do
            local _item = ShopItem:create()
            _item:parseData(data.rewardItems[i])
            table.insert(self.p_rewardItem, _item)
        end
    end
end

-- 金币数量
function BattlePassBoxRewardInfo:getCoin()
    return self.p_coinValue
end

-- 奖励类型
function BattlePassBoxRewardInfo:getType()
    return self.p_type or ""
end

-- 获得奖励物品数量显示
function BattlePassBoxRewardInfo:getRewardNumStr()
    if #self.p_rewardItem > 0 then
        local _info = self.p_rewardItem[1]
        if _info:getType() == "Buff" then
            local _buffInfo = _info:getBuffInfo()
            if not _buffInfo then
                return ""
            end
            local _duration = _buffInfo:getDuration()
            if _duration > 0 then
                return util_switchSecondsToHSM(_duration*60*_info:getNum())
            else
                return ""
            end
        elseif _info:getType() == "Item" or _info:getType() == "Package" then
            local _itemInfo = _info:getItemInfo()
            if not _itemInfo then
                return ""
            end
            if gLobalBattlePassManager:getItemsType(_itemInfo:getId()) == "coupon" then
                return _info:getNum().."%"
            end
            return "x" .. _info:getNum()
        end
    end
    return ""
end

-- 是否已领取
function BattlePassBoxRewardInfo:isPrized()
    return self.p_prized
end

-- 图标
function BattlePassBoxRewardInfo:getIcon()
    return self.p_icon or ""
end

-- 获得描述信息
function BattlePassBoxRewardInfo:getDescription()
    return self.p_description or ""
end

return BattlePassBoxRewardInfo
