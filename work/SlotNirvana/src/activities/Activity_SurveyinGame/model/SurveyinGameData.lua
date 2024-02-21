--[[
    关卡挑战数据部分
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local SurveyinGameData = class("SurveyinGameData",BaseActivityData)

-- message SurveyConfig {
--     optional string activityId = 1; //活动分id
--     optional string activityType = 2; //活动类型
--     optional string start = 3; //开始日期
--     optional string end = 4; //结束日期
--     optional int32 expire = 5; //剩余时间
--     optional int64 expireAt = 6; //截止时间
--     optional string name = 7; // 活动名称
--     optional bool isSuccess = 8; // 是否填写成功
--     optional bool isReceiveAward = 9; // 是否领取奖励
--     optional int64 coins = 10; // 金币奖励
--     repeated ShopItem item = 11; // 道具奖励
--     optional int64 gems = 12; // 宝石奖励
--   }

function SurveyinGameData:parseData(_data)
    SurveyinGameData.super.parseData(self,_data)

    self.p_isSuccess = _data.success
    self.p_isReceiveAward = _data.receiveAward
    self.p_coins = tonumber(_data.coins)
    -- self.p_gems = tonumber(_data.gems)
    -- self.p_items = self:parseItem(_data.item)
end

-- 解析道具数据
function SurveyinGameData:parseItem(_data)
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

function SurveyinGameData:getCoins()
    return self.p_coins or 0
end

function SurveyinGameData:getGems()
    return self.p_gems or 0
end

function SurveyinGameData:getItems()
    return self.p_items
end

function SurveyinGameData:isSuccess()
    return self.p_isSuccess
end

function SurveyinGameData:isReceiveAward()
    return self.p_isReceiveAward
end

function SurveyinGameData:isCanCollect()
    if self.p_isSuccess and not self.p_isReceiveAward then 
        return true
    else
        return false
    end
end

return SurveyinGameData

