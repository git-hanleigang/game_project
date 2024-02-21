--[[
    公会对决
--]]
local ClanDuelData = class("ClanDuelData")
local ClanDuelRankData = util_require("data.clanData.ClanDuelRankData")
local ShopItem = util_require("data.baseDatas.ShopItem")
local ClanBaseInfoData = util_require("data.clanData.ClanBaseInfoData")
local IS_OPEN_TEST_DATA = false
--[[
    message ClanDuel {
        optional int32 expire = 1;
        optional int64 expireAt = 2;
        optional int64 points = 3;
        optional string duelCid = 4; //敌对公会id
        optional string duelName = 5; //敌对公会名称
        optional string duelHead = 6; //敌对公会头像
        optional int64 duelPoints = 7; //敌对公会积分
        optional int64 coinPool = 8;
        repeated ShopItem items = 9;
        optional string status = 10; // 对决状态 UP DOWN SAME
    }
]]
function ClanDuelData:ctor()
    self.m_expireAt = 0
    self.m_points = 0
    self.m_duelCid = ""
    self.m_duelName = ""
    self.m_duelHead = ""
    self.m_duelPoints = 0
    self.m_coins = 0
    self.m_status = "" -- 对决状态
    self.m_myClanInfo = ClanBaseInfoData:create() -- 我的公会信息
    self.m_items = {}
    self.m_rankList = {} -- 榜单
    local selfRankData = {
        name = globalData.userRunData.nickName, --玩家名字
        facebookId = globalData.userRunData.facebookBindingID or "", --玩家facebookId
        udid = globalData.userRunData.userUdid, --玩家udid
        head = globalData.userRunData.HeadName, --玩家头像
        frame = globalData.userRunData.avatarFrameId, --玩家头像框
        rank = 0, --玩家排名
        points = 0, --点数
        coins = 0,
        items = {}
    }
    self.m_selfRankInfo = ClanDuelRankData:create() -- 玩家所在榜单信息
    self.m_selfRankInfo:parseData(selfRankData)
    local isFirstPop = gLobalDataManager:getBoolByField("isFirstPopClanDuelOpenLayer", true)
    self.m_redPoints = isFirstPop and 1 or 0
end

function ClanDuelData:parseData(_data, myClanInfo)
    self.m_myClanInfo = myClanInfo -- 我的公会信息
    if IS_OPEN_TEST_DATA then
        self:testData()
        return
    end
    if not _data then
        return
    end
    self.m_expire = tonumber(_data.expire or 0)
    self.m_expireAt = tonumber(_data.expireAt or 0)
    self.m_points = tonumber(_data.points or 0)
    self.m_duelCid = _data.duelCid or ""
    self.m_duelName = _data.duelName or ""
    self.m_duelHead = _data.duelHead or ""
    self.m_duelPoints = tonumber(_data.duelPoints or 0)
    self.m_coins = tonumber(_data.coinPool or 0)
    self.m_items = self:parseShopItemData(_data.items or {})
    self.m_status = _data.status or "" -- 对决状态 UP DOWN SAME
end

function ClanDuelData:parseRankList(_list)
    self.m_rankList = {}
    for i = 1, #_list do
        local rankInfo = _list[i]
        local rankData = ClanDuelRankData:create()
        rankData:parseData(rankInfo, true)
        table.insert(self.m_rankList, rankData)
    end
end

-- 解析所有道具信息
function ClanDuelData:parseShopItemData(_items)
    local itemList = {}
    for _, data in ipairs(_items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(itemList, shopItem)
    end
    return itemList
end

function ClanDuelData:parseRankInfo(_data)
    if not _data then
        return
    end
    if _data.rankUsers then
        self:parseRankList(_data.rankUsers)
    end
    if _data.myRank then
        self.m_selfRankInfo:parseData(_data.myRank)
    end
end

function ClanDuelData:getExpireAt()
    return math.floor(self.m_expireAt / 1000)
end

function ClanDuelData:isRunning()
    -- 集卡新手期 不显示 duel
    local bCardNovice = CardSysManager:isNovice()
    if bCardNovice then
        return false
    end
    local curTime = util_getCurrnetTime()
    if curTime >= self:getExpireAt() then
        return false
    end

    return true
end

-- 是否匹配上对手
function ClanDuelData:isMatchRival()
    return self.m_duelCid and self.m_duelCid ~= ""
end

-- 榜单
function ClanDuelData:getRankList()
    return self.m_rankList or {}
end

-- 玩家榜单信息
function ClanDuelData:getSelfRankInfo()
    return self.m_selfRankInfo
end

--金币奖励
function ClanDuelData:getCoins()
    return self.m_coins or 0
end

--道具奖励
function ClanDuelData:getItems()
    return self.m_items or {}
end

--得到我的公会信息 (数据类 ClanBaseInfoData)
function ClanDuelData:getMyClanInfo()
    return self.m_myClanInfo
end

function ClanDuelData:getMyPoints()
    return self.m_points
end

function ClanDuelData:setMyPoints(_val)
    self.m_points = _val
end

--得到对决公会ID
function ClanDuelData:getDuelClanID()
    return self.m_duelCid
end

--得到对决公会名称
function ClanDuelData:getDuelClanName()
    return self.m_duelName
end

--得到对决公会头像
function ClanDuelData:getDuelClanHead()
    return self.m_duelHead
end

--得到对决公会积分
function ClanDuelData:getDuelClanPoints()
    return self.m_duelPoints
end

--设置对决公会积分
function ClanDuelData:setDuelClanPoints(_val)
    self.m_duelPoints = _val
end

--对决状态 UP DOWN SAME
function ClanDuelData:getDuelStatus()
    return self.m_status
end

--设置对决状态 UP DOWN SAME
function ClanDuelData:setDuelStatus(_val)
    self.m_status = _val or "SAME"
end

--得到红点个数
function ClanDuelData:getDuelRedPoints()
    return self.m_redPoints or 0
end

--设置红点个数
function ClanDuelData:setDuelRedPoints(_val)
    self.m_redPoints = _val
end

--********************************** 测试数据 **********************************--
function ClanDuelData:testData()
    self.m_expireAt = 1795912413000
    self.m_points = 10000
    self.m_duelCid = "2"
    self.m_duelName = "OTHERCLAN"
    self.m_duelHead = "10"
    self.m_duelPoints = 1000000
    self.m_coins = 99999999999
    self.m_status = "SAME" -- 对决状态
    self.m_myClanInfo = ClanBaseInfoData:create() -- 我的公会信息
    local clan = {
        cid = 1,
        name = "MYCLAN",
        logo = 3
    }
    self.m_myClanInfo:parseData(clan)

    self.m_items = {
        {
            id = 800001,
            description = "普通3星卡卡包",
            icon = "Rank_6",
            item = 0,
            num = 1,
            activityId = -1,
            type = "Package",
            buff = 0,
            expireAt = 0
        },
        {
            id = 800001,
            description = "普通3星卡卡包",
            icon = "Rank_6",
            item = 0,
            num = 1,
            activityId = -1,
            type = "Package",
            buff = 0,
            expireAt = 0
        },
        {
            id = 800001,
            description = "普通3星卡卡包",
            icon = "Rank_6",
            item = 0,
            num = 1,
            activityId = -1,
            type = "Package",
            buff = 0,
            expireAt = 0
        }
    }
    self.m_items = self:parseShopItemData(self.m_items)

    self.m_rankList = {} -- 榜单
    local data = {
        name = globalData.userRunData.nickName, --玩家名字
        facebookId = "", --玩家facebookId
        udid = globalData.userRunData.userUdid, --玩家udid
        head = globalData.userRunData.HeadName, --玩家头像
        frame = globalData.userRunData.avatarFrameId, --玩家头像框
        rank = 10, --玩家排名
        points = 10 * 1000, --点数
        coins = 10 * 99999,
        items = {
            {
                id = 800001,
                description = "普通3星卡卡包",
                icon = "Rank_6",
                item = 0,
                num = 1,
                activityId = -1,
                type = "Package",
                buff = 0,
                expireAt = 0
            },
            {
                id = 800001,
                description = "普通3星卡卡包",
                icon = "Rank_6",
                item = 0,
                num = 1,
                activityId = -1,
                type = "Package",
                buff = 0,
                expireAt = 0
            },
            {
                id = 800001,
                description = "普通3星卡卡包",
                icon = "Rank_6",
                item = 0,
                num = 1,
                activityId = -1,
                type = "Package",
                buff = 0,
                expireAt = 0
            }
        }
    }
    self.m_selfRankInfo = ClanDuelRankData:create() -- 玩家所在榜单信息
    self.m_selfRankInfo:parseData(data)
    for i = 1, 100 do
        local data = {
            name = "Guest00" .. i, --玩家名字
            facebookId = "", --玩家facebookId
            udid = "", --玩家udid
            head = util_random(1, 10), --玩家头像
            frame = tostring(util_random(1, 10)), --玩家头像框
            rank = i, --玩家排名
            points = i * 1000, --点数
            coins = i * 9999999,
            items = {
                {
                    id = 800001,
                    description = "普通3星卡卡包",
                    icon = "Rank_6",
                    item = 0,
                    num = 1,
                    activityId = -1,
                    type = "Package",
                    buff = 0,
                    expireAt = 0
                },
                {
                    id = 800001,
                    description = "普通3星卡卡包",
                    icon = "Rank_6",
                    item = 0,
                    num = 1,
                    activityId = -1,
                    type = "Package",
                    buff = 0,
                    expireAt = 0
                },
                {
                    id = 800001,
                    description = "普通3星卡卡包",
                    icon = "Rank_6",
                    item = 0,
                    num = 1,
                    activityId = -1,
                    type = "Package",
                    buff = 0,
                    expireAt = 0
                }
            }
        }
        if i == 10 then
            data.udid = globalData.userRunData.userUdid
        end
        local rankData = ClanDuelRankData:create()
        rankData:parseData(data)
        table.insert(self.m_rankList, rankData)
    end
end

return ClanDuelData
