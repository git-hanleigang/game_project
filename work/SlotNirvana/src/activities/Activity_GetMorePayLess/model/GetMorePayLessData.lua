--[[
    付费目标
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local GetMorePayLessData = class("GetMorePayLessData", BaseActivityData)

function GetMorePayLessData:ctor()
    GetMorePayLessData.super.ctor(self)

    self.p_ActiviyOpen = false
end

-- message GetMorePayLess {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated GetMorePayLessStage stageList = 4;//阶段
--     optional int32 totalAmount = 5;//累计充值金额
--     optional bool open = 6;//是否开启
--     optional string action = 7;//数据刷新途径（Login、Purchase、None）
--   }
function GetMorePayLessData:parseData(_data)
    GetMorePayLessData.super.parseData(self, _data)
    
    self.p_totalAmount = _data.totalAmount
    self.p_stage = self:parseStageData(_data.stageList)
    self.p_open = _data.open
    self.p_action = _data.action
    self.p_expireAt = _data.expireAt

    if self.p_action == "Login" then   -- 第一次解析数据，不处理
        self.p_ActiviyOpen = _data.open
    elseif self.p_action == "Purchase" and self.p_ActiviyOpen == false and self.p_open then  -- 之后解析，游戏中活动开启
        if G_GetMgr(ACTIVITY_REF.GetMorePayLess):isDownloadRes() then
            local activityDatas = globalData.commonActivityData:getActivitys()
            local data = activityDatas[ACTIVITY_REF.GetMorePayLess]
            if data then
                self.p_ActiviyOpen = true
                local params = {}
                params.hall = {info = {activity = data}, index = 1}
                params.slide = {data = data, luaName = "Activity_GetMorePayLess.Icons.Activity_GetMorePayLessSlideNode", order = 1, key = data:getID()}
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_INSERT_HALL_AND_SLIDE, params)
            end
        end
    end
end

-- message GetMorePayLessStage {
--     optional int32 index = 1;
--     optional int32 amount = 2;//阶段金额
--     optional int64 coins = 3;
--     repeated ShopItem items = 4;
--     optional bool completed = 5;//是否达成
--     optional bool collected = 6;//是否领取
--   }
function GetMorePayLessData:parseStageData(_data)
    local stageList = {}
    if _data then
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_index = v.index
            tempData.p_amount = v.amount
            tempData.p_completed = v.completed
            tempData.p_collected = v.collected
            tempData.p_coins = tonumber(v.coins)
            tempData.p_items = self:parseItems(v.items)
            table.insert(stageList, tempData)
        end
    end

    return stageList
end

function GetMorePayLessData:parseItems(_items)
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

function GetMorePayLessData:getTotalAmount()
    return self.p_totalAmount    
end

function GetMorePayLessData:getStage()
    return self.p_stage
end

function GetMorePayLessData:getOpen()
    return self.p_open
end

function GetMorePayLessData:checkStageStatus()
    local needAmount = 0
    local completAll = true
    for i,v in ipairs(self.p_stage) do
        if not v.p_completed then
            needAmount = v.p_amount
            completAll = false
            break
        end
    end

    return completAll, needAmount - self.p_totalAmount
end

return GetMorePayLessData
