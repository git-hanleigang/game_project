local ClanDuelRankData = class("ClanDuelRankData")
local ShopItem = util_require("data.baseDatas.ShopItem")

--[[
    message ClanDuelTopRank {
        optional int32 rank = 1;
        optional string name = 2;
        optional int32 points = 3;
        optional string facebookId = 4;
        optional string udid = 5;
        optional string head = 6; //头像
        optional string status = 7; //UP DOWN SAME
        optional string robotHead = 8; //机器人头像
        optional string frame = 9; //头像框
        repeated ShopItem items = 11; //物品奖励
        optional int64 coins = 12; //金币奖励
    }
]]
function ClanDuelRankData:ctor()
    self.m_rank = 0 --玩家排名
    self.m_name = "" --玩家名字
    self.m_points = 0 --玩家公会点数
    self.m_facebookId = "" --玩家facebookId
    self.m_udid = "" --玩家udid
    self.m_head = 0 --玩家头像
    self.m_status = "" --UP DOWN SAME
    self.m_robotHead = "" --机器人头像
    self.m_frame = "" --玩家头像框
    self.m_items = {} --奖励道具
    self.m_coins = 0 --奖励金币
end

function ClanDuelRankData:parseData(_data)
    if not _data then
        return
    end

    self.m_rank = tonumber(_data.rank) or 0
    self.m_name = _data.name or "" --玩家名字
    self.m_points = _data.points or 0 --玩家公会点数
    self.m_facebookId = _data.facebookId or "" --玩家facebookId
    self.m_udid = _data.udid or "" --玩家udid
    self.m_head = _data.head or 0 --玩家头像
    self.m_status = _data.status --UP DOWN SAME
    self.m_robotHead = _data.robotHead --机器人头像
    self.m_frame = _data.frame or "" --玩家头像框
    self.m_coins = _data.coins or 0 --奖励金币
    self.m_items = self:parseShopItemData(_data.items) --奖励道具
    self.m_bMe = self.m_udid == globalData.userRunData.userUdid
end

-- 解析所有道具信息
function ClanDuelRankData:parseShopItemData(_items)
    local itemList = {}
    for _, data in ipairs(_items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(itemList, shopItem)
    end
    return itemList
end

function ClanDuelRankData:checkIsBMe()
    return self.m_bMe
end

--排名
function ClanDuelRankData:getRank()
    return self.m_rank
end

--点数
function ClanDuelRankData:getPoints()
    return self.m_points
end

--玩家名字
function ClanDuelRankData:getUserName()
    if self.m_bMe then
        self.m_name = globalData.userRunData.nickName
    end
    return self.m_name
end

--玩家facebookId
function ClanDuelRankData:getFacebookId()
    return self.m_facebookId
end

--玩家头像
function ClanDuelRankData:getUserHead()
    if self.m_bMe then
        self.m_head = globalData.userRunData.HeadName
    end
    return self.m_head
end

--玩家头像框
function ClanDuelRankData:getUserFrame()
    if self.m_bMe then
        self.m_frame = globalData.userRunData.avatarFrameId
    end
    return self.m_frame
end

--玩家Udid
function ClanDuelRankData:getUdid()
    return self.m_udid
end

--金币奖励
function ClanDuelRankData:getCoins()
    return self.m_coins
end

--道具奖励
function ClanDuelRankData:getItems()
    return self.m_items
end

return ClanDuelRankData