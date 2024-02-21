--钻石挑战任务界面数据
local NewDCTaskData = class("NewDCTaskData")
local ShopItem = require "data.baseDatas.ShopItem"

-- message LuckyChallengeV2TaskInfo {
--   optional int32 index = 1;
--   optional string type = 2;
--   repeated string params = 3;//参数
--   repeated string process = 4;//进度
--   optional int32 exp = 5;//经验奖励
--   repeated ShopItem items = 6;
--   optional string description = 7; //描述
--   optional int32 gameId = 8;//关卡id
--   optional int64 expireAt = 9;//限时任务到期时间
--   repeated int32 availableGameIdList = 10;//可以选择的关卡id
--   optional int32 payRefreshNum = 11;//付费刷新需要的道具数量
--   optional string boost = 12;//加成系数默认0
--   optional int32 skipGems = 13;//跳过所需第二货币
--   optional bool completed = 14;//是否完成
--   optional int32 remainingTimes = 15;//剩余次数
--     optional bool canRefresh = 16;//是否可以刷新
--     optional int32 jump = 17;//跳转方式
-- }

function NewDCTaskData:ctor()
end

function NewDCTaskData:parseData(data)
    self.m_Index = data.index
    self.m_type = data.type
    if data.params and #data.params > 0 then
        self.m_param = {}
        for i,v in ipairs(data.params) do
            table.insert(self.m_param,v)
        end
    end
    if data.process and #data.process > 0 then
        self.m_progress = {}
        for i,v in ipairs(data.process) do
            table.insert(self.m_progress,v)
        end
    end
    self.m_exp = data.exp
    if data.items and #data.items > 0 then
        self.m_shop = {}
        for i,v in ipairs(data.items) do
            local shop = ShopItem:create()
            shop:parseData(v)
            table.insert(self.m_shop,shop)
        end
    end
    self.m_description = data.description
    self.m_gameId = data.gameId
    self.m_expireAt = data.expireAt
    self.m_remainingTimes = data.remainingTimes
    self.m_boost = data.boost
    self.m_skipGems = data.skipGems
    self.m_completed = data.completed
    if data.availableGameIdList and #data.availableGameIdList > 0 then
        self.m_gameList = {}
        for i,v in ipairs(data.availableGameIdList) do
            if v ~= -1 then
                table.insert(self.m_gameList,v)
            end
        end
    end
    self.m_payRefreshNum = data.payRefreshNum
    self.m_canRefresh = data.canRefresh
    self.m_jump = data.jump
end

function NewDCTaskData:getJump()
    return self.m_jump or 1
end

function NewDCTaskData:getCanRefresh()
    return m_canRefresh or false
end

function NewDCTaskData:getIndex()
    return self.m_Index or 0
end

function NewDCTaskData:getType()
    return self.m_type or 0
end

function NewDCTaskData:getParam()
    return self.m_param or {}
end

function NewDCTaskData:getPayRefreshNum()
    return self.m_payRefreshNum or 0
end

function NewDCTaskData:getBoost()
    return self.m_boost or 0
end

function NewDCTaskData:getSkipGems()
    return self.m_skipGems or 0
end

function NewDCTaskData:getCompleted()
    return self.m_completed or false
end

function NewDCTaskData:setCompleted()
    self.m_completed = true
end

function NewDCTaskData:getProgress()
    return self.m_progress or {}
end

function NewDCTaskData:setProgress(_pro)
    self.m_progress = {}
    for i,v in ipairs(_pro) do
        table.insert(self.m_progress,v)
    end
end

function NewDCTaskData:getExp()
    return self.m_exp or 0
end

function NewDCTaskData:setExp(_exp)
    self.m_exp = _exp
end

function NewDCTaskData:getItems()
    return self.m_shop or {}
end

function NewDCTaskData:getDec()
    return self.m_description or ""
end

function NewDCTaskData:getGameId()
    return self.m_gameId
end

function NewDCTaskData:getTotalTimes()
    return self.m_totalRefreshTimes or 0
end

function NewDCTaskData:getRemainTimes()
    return self.m_remainingTimes or 0
end

function NewDCTaskData:getGameList()
    return self.m_gameList or {}
end

function NewDCTaskData:getLimitTime()
    return self.m_expireAt or 0
end

function NewDCTaskData:getBaiFenBi()
    local bai = 0
    local pro = self:getProgress()[1]
    local zong = self:getParam()[1]
    if pro and zong then
        bai = pro/zong
    end
    return bai
end
return NewDCTaskData