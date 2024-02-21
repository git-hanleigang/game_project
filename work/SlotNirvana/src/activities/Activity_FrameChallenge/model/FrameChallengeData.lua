--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-15 11:22:35
]]
--[[
    message AvatarFrameChallenge {
        optional string activityId = 1;//活动id
        optional int64 expireAt = 2;//活动过期时间戳
        optional int32 expire = 3;//活动剩余秒数
        repeated AvatarFrameChallengeTask taskList = 4;//任务集合
        optional bool complete = 5;//是否全部完成
    }
      
    message AvatarFrameChallengeTask {
        optional int32 needAvatarFrames = 1;//任务所需头像框
        repeated ShopItem rewardList = 2;//奖励
        optional bool complete = 3;//是否完成
    }
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local ShopItem = util_require("data.baseDatas.ShopItem")
local FrameChallengeData = class("FrameChallengeData", BaseActivityData)

function FrameChallengeData:ctor()
    FrameChallengeData.super.ctor(self)
end

function FrameChallengeData:parseData(data)
    BaseActivityData.parseData(self, data)
    self.p_complete = data.complete
    self:parseTask(data.taskList)
    self:parseTaskId() -- 当前进行的任务id
    if not self.p_isFrist and self.p_taskId == 0 then
        self.p_isFrist = true
        self:initIsPopup()
    end
end

function FrameChallengeData:parseSlotData(_data)
    self.p_complete = _data.complete
    self:parseTask(_data.taskList)
    self:parseTaskId()
end

function FrameChallengeData:parseTask(data)
    self.p_taskList = {}
    for k, v in ipairs(data) do
        local taskData = {}
        taskData.needAvatarFrames = tonumber(v.needAvatarFrames)
        taskData.complete = v.complete
        taskData.rewardList = self:parseItems(v.rewardList)
        self.p_taskList[k] = taskData
    end
end

function FrameChallengeData:parseItems(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function FrameChallengeData:getComplete()
    return self.p_complete
end

function FrameChallengeData:getTaskData()
    return self.p_taskList or {}
end

function FrameChallengeData:getTaskDataByIndex(_inx)
    if #self.p_taskList <= 0 then
        return {}
    end
    return self.p_taskList[_inx] or {}
end

function FrameChallengeData:isCompleteByIndex(_inx)
    local taskData = self:getTaskDataByIndex(_inx)
    if #taskData <= 0 then
        return false
    end
    return taskData.complete
end

function FrameChallengeData:parseTaskId()
    self.p_taskId = 0
    for i,v in ipairs(self.p_taskList) do
        if v.complete then
            self.p_taskId = tonumber(i)
        end
    end
end

function FrameChallengeData:getTaskId()
    return self.p_taskId or 1
end

function FrameChallengeData:initIsPopup()
    local entityAttList = {}
    local attJson = cjson.encode(entityAttList)
    gLobalDataManager:setStringByField("FrameChallengeIsPopup", attJson)
end

function FrameChallengeData:setIsPopup(value)
    local attJson = gLobalDataManager:getStringByField("FrameChallengeIsPopup", "{}")
    local entityAttList = cjson.decode(attJson)
    entityAttList[self.p_taskId] = value
    local attJson = cjson.encode(entityAttList)
    gLobalDataManager:setStringByField("FrameChallengeIsPopup", attJson)
end

function FrameChallengeData:getIsPopup()
    --判断是否过关  过关需要清空数据
    local attJson = gLobalDataManager:getStringByField("FrameChallengeIsPopup", "{}")
    local entityAttList = cjson.decode(attJson)
    local task = entityAttList[self.p_taskId]
    if self.p_taskId == 0 then
        return true
    else
        if not task then
            return false
        else
            return task == 1
        end
    end
end

return FrameChallengeData
