--[[
    Minz数据层
]]
local BaseActivityData = util_require("baseActivity.BaseActivityData")
local MinzData = class("MinzData", BaseActivityData)
--[[
    message MinzData {
        optional int32 expire = 1;
        optional int64 expireAt = 2;
        optional string activityId = 3;
        repeated MinzAlbum albums = 4;
        optional int64 points = 5;
        optional int64 alicePrice = 6;
        optional int64 minzBet = 7;
        optional string extraBetPercent = 8; // 额外押注百分比
        optional int32 slotAlbumId = 9; // 当前正在minz关卡
        optional int32 gems = 10; // 花费第二货币多给几张雕像卡
        optional int32 moreStatueNum = 11; // 多给的数量
        optional int64 maxBet = 12; // 仅客户端展示气泡用
        optional bool openExtraCard = 13;//是否开启额外开卡
    }
]]
function MinzData:parseData(_data)
    MinzData.super.parseData(self, _data)

    self.p_themeAlbums = {}
    self.p_albums = self:parseMinzAlbum(_data.albums)
    self.p_points = tonumber(_data.points)
    self.p_alicePrice = tonumber(_data.alicePrice)
    self.p_minzBet = tonumber(_data.minzBet)
    self.p_extraBetPercent = tonumber(_data.extraBetPercent)
    self.p_slotAlbumId = tonumber(_data.slotAlbumId)
    self.p_gems = tonumber(_data.gems)
    self.p_moreStatueNum = tonumber(_data.moreStatueNum)
    self.m_maxBet = tonumber(_data.maxBet)

    self.p_openExtraCard = _data.openExtraCard
end

--[[
    message MinzAlbum {
        optional int32 themeId =1; //主题
        optional int32 albumId = 2;
        repeated MinzStatueConfig statues = 3;
        optional int32 freeSpins = 4;
        optional int32 total = 5; //冗余总进度
        optional int32 process = 6; //冗余进度
        optional bool active = 7;
    }
]]
function MinzData:parseMinzAlbum(_data)
    local AlbumList = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.themeId = v.themeId
            tempData.albumId = v.albumId
            tempData.statues = self:parseMinzStatue(v.statues)
            tempData.freeSpins = v.freeSpins
            tempData.total = v.total
            tempData.process = v.process -- 奖励物品
            tempData.active = v.active
            table.insert(AlbumList, tempData)
            if not self.p_themeAlbums[v.themeId] then
                self.p_themeAlbums[v.themeId] = {}
            end
            table.insert(self.p_themeAlbums[v.themeId], tempData)
        end
    end
    return AlbumList
end

--[[
    message MinzStatueConfig {
        optional int32 statueId = 1;// 雕像id
        optional int32 m = 2; // 星级
        optional bool collected = 3; // 是否领取
    }
]]
function MinzData:parseMinzStatue(_data)
    local info = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = {}
            tempData.statueId = v.statueId -- 雕像id
            tempData.stars = v.stars -- 星级
            tempData.collected = v.collected
            table.insert(info, tempData)
        end
    end
    return info
end

-- 设置点数
function MinzData:setPoints(_val)
    self.p_points = _val
end

-- 获得点数
function MinzData:getPoints()
    return self.p_points
end

-- 设置bet
function MinzData:setBet(_val)
    self.p_minzBet = _val
end

-- 获得bet
function MinzData:getBet()
    return self.p_minzBet
end

-- 获得价格
function MinzData:getAlicePrice()
    return self.p_alicePrice or 0
end

-- 获得5倍价格
function MinzData:getAlicePriceByNum(_num)
    local num = _num or 1
    local price = self:getAlicePrice()
    return price * num
end

-- 获得当前正在进行的卡册Id
function MinzData:getSlotAlbumId()
    return self.p_slotAlbumId or 0
end

-- 获得额外bet倍数
function MinzData:getExtraBetPercent()
    return self.p_extraBetPercent / 100
end

-- 获得卡册数据通过主题id和卡册id
function MinzData:getAlbumByAlbumId(_themeId, _albumId)
    for i = 1, #self.p_albums do
        local info = self.p_albums[i]
        if info.themeId == _themeId and info.albumId == _albumId then
            return info
        end
    end
    return nil
end

-- 获得全部卡册数据通过主题id
function MinzData:getAlbumByThemeId(_themeId)
    return self.p_themeAlbums[_themeId]
end

-- 获得传人卡册的进度
function MinzData:getProgressByAlbum(_albumData)
    local collectNum = 0
    if _albumData then
        local statueData = _albumData.statues
        for i, v in ipairs(statueData) do
            if v.collected then
                collectNum = collectNum + 1
            end
        end
    end
    return collectNum
end

-- 获得激活卡册的卡册数据
function MinzData:getAlbumDataByActive()
    if self.p_albums then
        for i = 1, #self.p_albums do
            local info = self.p_albums[i]
            if info.active then
                return info
            end
        end
    end
    return nil
end

--获取入口位置 1：左边，0：右边
function MinzData:getPositionBar()
    return 1
end

-- 获得玩家当前拥有的雕像id {themeId_albumId = { id }}
function MinzData:getOwnStatuesId()
    local ownIdList = {}
    for i = 1, #self.p_albums do
        local info = self.p_albums[i]
        local str = info.themeId .. "_" .. info.albumId
        if not ownIdList[str] then
            ownIdList[str] = {}
        end
        local statueData = info.statues
        for i, v in ipairs(statueData) do
            if v.collected then
                table.insert(ownIdList[str], v.statueId)
            end
        end
    end
    return ownIdList
end

function MinzData:isEnoughBuy()
    return self.p_points >= self.p_alicePrice
end

function MinzData:getGems()
    return self.p_gems or 0
end

function MinzData:getGemsByNum(_num)
    local num = _num or 1
    local gems = self:getGems()
    return gems * num
end

function MinzData:getMoreStatueNum()
    return self.p_moreStatueNum or 0
end

-- 是否弹出额外付费弹板
function MinzData:isPopExtraLayer()
    return self:getGems() > 0
end

-- 关卡内bet气泡的最大bet值
function MinzData:getBubbleMaxBet()
    return self.m_maxBet or 0
end

function MinzData:getOpenExtraCard()
    return self.p_openExtraCard
end

-- 重写
function MinzData:isRunning()
    if MinzData.super.isRunning(self) then
        return true
    end

    if self:getAlbumDataByActive() then
        return true
    end

    return false
end

-- 有激活的反奖玩法不能删除数据
function MinzData:isCanDelete()
    if self:getAlbumDataByActive() then
        return false
    end

    return true
end

return MinzData
