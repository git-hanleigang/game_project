--[[
    集装箱大亨
]]
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local ShopItem = require "data.baseDatas.ShopItem"
local BlindBoxPassData = require("activities.Activity_BlindBox.model.BlindBoxPassData")
local BlindBoxMissionData = require("activities.Activity_BlindBox.model.BlindBoxMissionData")
local BaseActivityData = require("baseActivity.BaseActivityData")
local BlindBoxData = class("BlindBoxData", BaseActivityData)


-- message BlindBox {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 keys = 4;//钥匙数
--     optional BlindBoxDetail box = 5;//箱子详情
--     repeated BlindBoxSale saleList = 6;//促销
--     optional string maxCoins = 7;//能开出的最大金币
--     optional bool unlockRank = 8;//解锁排行榜
--     optional bool openRank = 9;//开启排行榜展示
--     optional BlindBoxPass pass = 10;// pass
--     optional BlindBoxMission missionData = 11;// 任务数据
--     optional int32 unlockRankKeyNum = 12;//解锁排行榜所需钥匙数
--     optional int32 openKeyNum = 13;//开出的钥匙数
--     optional bool passOpen = 14; //pass开关
--     optional bool missionOpen = 15; //mission开关
--   }
function BlindBoxData:parseData(_data)
    BlindBoxData.super.parseData(self,_data)

    self.p_keys = _data.keys
    self.p_maxCoins = _data.maxCoins
    self.p_unlockRank = _data.unlockRank
    self.p_openRank = _data.openRank
    self.p_boxInfo = self:parseBoxInfo(_data.box)
    self.p_saleList = self:parseSaleList(_data.saleList)
    self.p_passData = self:parsePassData(_data.pass)
    self.p_missionData = self:parseMissionData(_data.missionData, self.p_passData:getUnlocked())
    self.p_unlockRankKeyNum = _data.unlockRankKeyNum
    self.p_openKeyNum = _data.openKeyNum

    self.p_passOpen = _data.passOpen
    self.p_missionOpen = _data.missionOpen
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.BlindBox})
end

-- message BlindBoxDetail {
--     optional int32 index = 1;
--     optional string minCoins = 2;//预估价值min
--     optional string maxCoins = 3;//预估价值max
--     optional int32 needKeys = 4;//所需钥匙
--     optional int32 color = 5;//颜色
--     optional int32 sticker = 6;//贴纸
--     optional int32 doodle = 7;//涂鸦
--     optional int32 light = 8;//灯
--     optional string coins = 9;//实际金币
--     optional string bubbles = 10;//气泡
--     optional int32 newKeys = 11;//开出的钥匙数
--     optional string type = 12;//类型NORMAL、HIGH
--   }
function BlindBoxData:parseBoxInfo(_data)
    local info = {}
    if _data  then 
        info.p_index = _data.index
        info.p_minCoins = _data.minCoins
        info.p_maxCoins = _data.maxCoins
        info.p_needKeys = _data.needKeys
        info.p_color = _data.color
        info.p_sticker = _data.sticker
        info.p_doodle = _data.doodle
        info.p_light = _data.light
        info.p_coins = _data.coins
        info.p_bubblesText = _data.bubbles
        info.p_newKeys = _data.newKeys
        info.p_type = _data.type
    end
    return info
end

-- message BlindBoxSale {
--     optional int32 index = 1;
--     optional string key = 2;
--     optional string keyId = 3;
--     optional string price = 4;
--     optional string coins = 5;
--     repeated ShopItem items = 6;
--   }
function BlindBoxData:parseSaleList(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_key = v.key
            temp.p_keyId = v.keyId
            temp.p_price = v.price
            temp.p_coins = v.coins
            temp.p_items = self:parseItems(v.items)
            table.insert(list, temp)
        end
    end
    return list
end

function BlindBoxData:parseItems(_items)
    -- 通用道具
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function BlindBoxData:parsePassData(_data)
    local passData = nil
    if _data then 
        passData = BlindBoxPassData:create()
        passData:parseData(_data)
    end
    return passData
end

function BlindBoxData:parseMissionData(_data, _isUnlockPass)
    local missionData = nil
    if _data then 
        missionData = BlindBoxMissionData:create()
        missionData:parseData(_data, _isUnlockPass)
    end
    return missionData
end

function BlindBoxData:getKeys()
    return self.p_keys
end

function BlindBoxData:getBoxInfo()
    return self.p_boxInfo
end

function BlindBoxData:getSaleList()
    return self.p_saleList
end

function BlindBoxData:getMaxCoins()
    return self.p_maxCoins
end

function BlindBoxData:getUnlockRank()
    return self.p_unlockRank
end

function BlindBoxData:getOpenRank()
    return self.p_openRank
end

function BlindBoxData:getPassData()
    return self.p_passData
end

function BlindBoxData:getMissionData()
    return self.p_missionData
end

-- 进榜需要的钥匙数
function BlindBoxData:getKeyMax()
    return self.p_unlockRankKeyNum
end

-- 开出的钥匙数
function BlindBoxData:getOpenKeyNum()
    return self.p_openKeyNum
end

function BlindBoxData:isPassOpen()
    return self.p_passOpen
end

function BlindBoxData:isMissionOpen()
    return self.p_missionOpen
end

-- 解析排行榜信息
function BlindBoxData:parseRankConfig(_data)
    if not _data then
        return
    end

    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self:setRank(myRankConfigInfo.p_rank)
    end
end

function BlindBoxData:getRankCfg()
    return self.p_rankCfg
end

return BlindBoxData
