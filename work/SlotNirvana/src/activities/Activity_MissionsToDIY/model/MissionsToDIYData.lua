-- 完成任务装饰圣诞树

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local MissionsToDIYData = class("MissionsToDIYData", BaseActivityData)

-- message MissionsToDiy {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional int32 curOrder = 4; //当前顺序
--     repeated MissionsToDiyTask taskList = 5; //任务数据
--     optional bool overReward = 6; //可领取最终大奖标识（全部任务完成）
--     optional string coins = 7; //最终大奖
--     repeated ShopItem items = 8; //最终大奖
--     optional bool share = 9; //可分享标识（已领取最终大奖）
--     repeated string selections = 10; //选择的装饰
--     optional string steerData = 11; //客户端引导数据
-- }
function MissionsToDIYData:parseData(_data)
    MissionsToDIYData.super.parseData(self, _data)

    self.p_expireAt = tonumber(_data.expireAt)
    self.p_curOrder = _data.curOrder
    self.p_overReward = _data.overReward
    self.p_coins = _data.coins
    self.p_share = _data.share
    self.p_selections = _data.selections
    self.p_steerData = _data.steerData

    self.p_taskList = self:parseTaskList(_data.taskList)
    self.p_items = self:parseItemData(_data.items)
    gLobalNoticManager:postNotification(ViewEventType.MISSIONS_TO_DIY_UPDATE_DATA)
end

-- message MissionsToDiyTask {
--     optional int32 order = 1; //顺序（与curOrder对应）
--     optional int32 taskId = 2; //任务id
--     optional string cur = 3; //当前进度
--     optional string total = 4; //总进度 (替换 %s)
--     optional string text = 5; //描述
--     optional string textB = 6; //描述复数
--     optional string param = 7; //描述替换参数（\s）
--     optional string coins = 8; //奖励金币数
--     repeated ShopItem items = 9; //奖励物品
--     optional bool collected = 10; //领取标识
--     optional bool finished = 11; //完成任务标识
-- }
function MissionsToDIYData:parseTaskList(_data)
    local reward = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local info = {}
            info.p_order = v.order
            info.p_taskId = v.taskId
            info.p_cur = v.cur
            info.p_total = v.total
            info.p_text = v.text
            info.p_textB = v.textB
            info.p_param = v.param
            info.p_coins = v.coins
            info.p_collected = v.collected
            info.p_finished = v.finished
            info.p_items = self:parseItemData(v.items)
            table.insert(reward, info)
        end
    end

    return reward
end 

function MissionsToDIYData:parseItemData(_items)
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

function MissionsToDIYData:getPositionBar()
    return 1
end

function MissionsToDIYData:getCurOrder()
    return self.p_curOrder
end

function MissionsToDIYData:getBigReward()
    return {coins = self.p_coins, items = self.p_items}
end 

function MissionsToDIYData:getTaskList()
    return self.p_taskList
end

function MissionsToDIYData:canCollectBigReward()
    return self.p_overReward
end 

function MissionsToDIYData:canShare()
    return self.p_share
end

function MissionsToDIYData:getSelections()
    return self.p_selections
end

function MissionsToDIYData:isCollectAll()
    local flag = true
    for i,v in ipairs(self.p_taskList) do
        if not v.p_collected then
            flag = false
            break
        end
    end

    return flag
end

function MissionsToDIYData:getCurTask()
    return self.p_taskList[self.p_curOrder]
end

function MissionsToDIYData:parseSpinData(_data)
    self.p_curOrder = _data.order
    self.p_overReward = _data.overReward
    local taskData = self.p_taskList[self.p_curOrder]
    taskData.p_finished = _data.finished
    taskData.p_cur = _data.cur
    taskData.p_collected = _data.collected
    gLobalNoticManager:postNotification(ViewEventType.MISSIONS_TO_DIY_UPDATE_DATA)
end

function MissionsToDIYData:getGuideData()
    local data = self.p_steerData
    if not data or data == "" then
        data = "{}"
    end
    return data
end

return MissionsToDIYData
