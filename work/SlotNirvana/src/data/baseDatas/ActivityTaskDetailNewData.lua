--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-09-02 16:15:58
    describe:新版大活动任务详细数据
]]
--[[
    message ActivityMissionV2Config {
    optional string activityId = 1;
    optional string activityName = 2;
    optional int64 expireAt = 3;
    optional int32 expire = 4;
    optional string activityCommonType = 5; //小活动类型
    repeated ActivityMissionV2Mission missionList = 6;//任务列表
    optional int32 totalPoints = 7;//总点数
    optional int32 currentPoints = 8;//当前点数
    repeated ActivityMissionV2StageReward stageRewardList = 9;//阶段奖励列表
    optional string allFinish = 10;//所有轮次全部完成
    optional int32 round = 11;//当前轮次

    }

    message ActivityMissionV2Mission {
    optional string missionType = 1;//任务类型
    optional int32 missionId = 2;//任务索引
    optional int32 points = 3;//奖励点数
    optional string description = 4;//描述
    optional int64 param = 5;//目标
    optional int64 process = 6;//进度
    optional bool finish = 7;//是否完成
    }

    message ActivityMissionV2StageReward {
    optional int32 stage = 1;//阶段
    optional int32 needPoints = 2;//完成需要点数
    optional int64 coins = 3;
    repeated ShopItem itemList = 4;
    optional bool finish = 5;//是否完成
    optional bool collect = 6;//是否领奖
    }
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local ActivityTaskDetailNewData = class("ActivityTaskDetailNewData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

function ActivityTaskDetailNewData:ctor()
    ActivityTaskDetailNewData.super.ctor(self)
    self.m_oldData = nil
end

function ActivityTaskDetailNewData:parseData(_data)
    BaseActivityData.parseData(self, _data)
    self.p_activityId = _data.activityId --活动任务id
    self.p_activityName = _data.activityName --活动任务名称
    self.p_activityCommonType = _data.activityCommonType --活动类型
    self.p_missionList = self:parseMissionList(_data.missionList)
    self.p_currentPoints = tonumber(_data.currentPoints)
    self.p_totalPoints = tonumber(_data.totalPoints)
    self.p_stageRewardList = self:parseStageRewardList(_data.stageRewardList)
    self.m_allFinsh = _data.allFinish --所有任务都完成
    self.m_currentSate = _data.round
end

--解析任务数据
function ActivityTaskDetailNewData:parseMissionList(data)
    local infoList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.missionType = v.missionType
        info.missionId = v.missionId
        info.points = v.points
        info.description = tostring(v.description)
        info.param = v.param
        info.process = v.process
        info.finish = v.finish
        table.insert(infoList, info)
    end
    return infoList
end

--解析奖励数据
function ActivityTaskDetailNewData:parseStageRewardList(data)
    local infoList = {}
    for i, v in ipairs(data) do
        local info = {}
        info.stage = v.stage
        info.needPoints = v.needPoints
        info.coins = tonumber(v.coins)
        info.itemList = self:parseItems(v.itemList)
        info.finish = v.finish
        info.collect = v.collect
        table.insert(infoList, info)
    end
    return infoList
end

function ActivityTaskDetailNewData:parseItems(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            if tempData.p_type == "Buff" then
                tempData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
            else
                tempData:setTempData({p_mark = {ITEM_MARK_TYPE.CENTER_X}})
            end
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

--------------------------数据访问接口-----------------
function ActivityTaskDetailNewData:getActivityTaskID()
    return self.p_activityId
end

function ActivityTaskDetailNewData:getActivityTaskName()
    return self.p_activityName
end

function ActivityTaskDetailNewData:getActivityCommonType()
    return self.p_activityCommonType
end

function ActivityTaskDetailNewData:getMissionList()
    return self.p_missionList
end

function ActivityTaskDetailNewData:getCurrentPoints()
    return self.p_currentPoints
end

function ActivityTaskDetailNewData:getTotalPoints()
    return self.p_totalPoints
end

function ActivityTaskDetailNewData:getStageRewardList()
    return self.p_stageRewardList
end

function ActivityTaskDetailNewData:getCompleted()
    return self.p_currentPoints >= self.p_totalPoints
end

function ActivityTaskDetailNewData:getAllComplect()
    return self.m_allFinsh
end

function ActivityTaskDetailNewData:getCurrentStage()
    return self.m_currentSate or 1
end

function ActivityTaskDetailNewData:getCurrentStageInfo()
    return self.p_stageRewardList[self.m_currentSate]
end

--获得当前阶段比值
function ActivityTaskDetailNewData:getRatio(_point)
    local point = _point or self:getCurrentPoints()
    local stageRewardList = self:getStageRewardList()
    local stage, needPoint, nextPoint = 0, 0, 0
    local ratio = 0
    point = math.min(point, self:getTotalPoints())
    for i, v in ipairs(stageRewardList) do
        if v.needPoints <= point then
            stage = i
            needPoint = v.needPoints
        else
            nextPoint = v.needPoints
            break
        end
    end
    ratio = stage + (point - needPoint) / (nextPoint - needPoint)
    return ratio
end

return ActivityTaskDetailNewData
