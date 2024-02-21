--[[
    圣诞聚合 -- 小游戏
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local HolidaySideGameData = class("HolidaySideGameData", BaseActivityData)

-- message HolidayNewChallengeSideGame {
--     optional string activityId = 1; // 活动的id
--     optional string activityName = 2;// 活动的名称
--     optional string begin = 3;// 活动的开启时间
--     optional int64 expireAt = 4; // 活动倒计时
--     optional int32 highLimit = 5;// 特殊的限制
--     optional int32 normalLimit = 6;// 普通的限制
--     optional int32 highNum = 7;// 点中每个特殊的给多少道具数量
--     optional int32 normalNum = 8;// 点中每个普通的给多少道具数量
--     repeated int32 specialPosition = 9;// 特殊叶子出现的位置
--     optional string timeFlag = 10; //当前的时间 年月日
--     optional int32 curHighNum = 11; // 当前金色叶子
--     optional int32 curNormalNum = 12;// 当前普通叶子
--     optional int32 seconds = 13; // 游戏15秒 玩家进行到第几秒
--     optional string status = 14; // 小游戏的状态
--   }
function HolidaySideGameData:parseData(_data)
    HolidaySideGameData.super.parseData(self, _data)

    self.p_highLimit = _data.highLimit
    self.p_normalLimit = _data.normalLimit
    self.p_highNum = _data.highNum
    self.p_normalNum = _data.normalNum

    self.p_specialPosition = {}
    if _data.specialPosition and #_data.specialPosition > 0 then
        for i=1,#_data.specialPosition do
            table.insert(self.p_specialPosition, _data.specialPosition[i])
        end
    end

    self.p_timeFlag = _data.timeFlag

    -- 改为记录到本地，这里兼容一下老数据
    self.p_curHighNumOld = _data.curHighNum or 0
    -- 新数据从本地中获取
    self.p_curHighNum = self:getRecordLeafNum(HolidaySideGameConfig.LeafType.Golden)

    -- 改为记录到本地，这里兼容一下老数据
    self.p_curNormalNumOld = _data.curNormalNum or 0
    -- 新数据从本地中获取
    self.p_curNormalNum = self:getRecordLeafNum(HolidaySideGameConfig.LeafType.Normal)

    -- 改为记录到本地，这里兼容一下老数据
    self.p_seconds = self:getRecordGameSec()
    if _data.seconds and _data.seconds > 0 then
        self:recodeGameSec(_data.seconds)
    end

    -- 删除play接口后，服务器没有了play状态，客户端需要从本地数据判断是否已经开始了游戏，手动改为play状态
    self.p_status = _data.status
    if self.p_status == HolidaySideGameConfig.GameStatus.Start then
        if self.p_seconds > 0 or (self.p_curHighNumOld > 0 or self.p_curHighNum > 0) or (self.p_curNormalNumOld > 0 or self.p_curNormalNum > 0 ) then
            self.p_status = HolidaySideGameConfig.GameStatus.Play
        end
    end
end

function HolidaySideGameData:getTimeFlag()
    return self.p_timeFlag
end

function HolidaySideGameData:getHighLimit()
    return self.p_highLimit
end

function HolidaySideGameData:getNormalLimit()
    return self.p_normalLimit
end

function HolidaySideGameData:getHighNum()
    return self.p_highNum
end

function HolidaySideGameData:getNormalNum()
    return self.p_normalNum
end

function HolidaySideGameData:getSpecialPosition()
    return self.p_specialPosition
end

function HolidaySideGameData:getStatus()
    return self.p_status    
end

function HolidaySideGameData:getCurHighNumOld()
    return self.p_curHighNumOld    
end

function HolidaySideGameData:getCurNormalNumOld()
    return self.p_curNormalNumOld 
end

-- 断线重连用，游戏计时
function HolidaySideGameData:getGameSec()
    return self.p_seconds or 0
end

-- 断线重连用，已经收集的数量
function HolidaySideGameData:getCollectNum()
    local high = (self.p_curHighNum + self.p_curHighNumOld) * self.p_highNum
    local normal = (self.p_curNormalNum + self.p_curNormalNumOld) * self.p_normalNum
    return high + normal
end

function HolidaySideGameData:getCollectCount()
    local high = self.p_curHighNum + self.p_curHighNumOld
    local normal = self.p_curNormalNum + self.p_curNormalNumOld
    return high + normal
end

-- 距离今天24点的剩余时间
function HolidaySideGameData:getToday24HLeftTime()
    local nowTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        nowTime = globalData.userRunData.p_serverTime / 1000
    end
    local tm = util_UTC2TZ(nowTime, -8)
    -- 当前时间
    local curTime = os.time({year = tm.year, month = tm.month, day = tm.day, hour = tm.hour, min = tm.min, sec = tm.sec, isdst = false})
    -- 今天24点
    local Today24H = os.time({year = tm.year, month = tm.month, day = tm.day, hour = 24, min = 0, sec = 0, isdst = false})
    local tempTime = Today24H - curTime
    if tempTime <= 0 then
        tempTime = 0
    end
    return tempTime
end


-- _type
function HolidaySideGameData:getRecordKey(_type)
    return "HolidaySideGame_" .. self.p_timeFlag .. "_" .. _type
end

-- 
function HolidaySideGameData:recodeGameSec(_time)
    if not (_time and _time > 0) then
        return
    end
    self.p_seconds = _time
    local key = self:getRecordKey("time")
    gLobalDataManager:setNumberByField(key, _time)
end

function HolidaySideGameData:getRecordGameSec()
    local key = self:getRecordKey("time")
    local sec = gLobalDataManager:getNumberByField(key, 0)
    return sec or 0
end

function HolidaySideGameData:recodeLeafNum(_leafType, _addNum)
    if not (_addNum and _addNum > 0) then
        return
    end
    local key = self:getRecordKey(_leafType)
    if _leafType == HolidaySideGameConfig.LeafType.Normal then
        self.p_curNormalNum = self.p_curNormalNum + _addNum
        gLobalDataManager:setNumberByField(key, self.p_curNormalNum)
    else
        self.p_curHighNum = self.p_curHighNum + _addNum
        gLobalDataManager:setNumberByField(key, self.p_curHighNum)
    end
end

function HolidaySideGameData:getRecordLeafNum(_leafType)
    local key = self:getRecordKey(_leafType)
    local num = gLobalDataManager:getNumberByField(key, 0)
    return num or 0
end

function HolidaySideGameData:clearRecordData()
    local normalKey = self:getRecordKey(HolidaySideGameConfig.LeafType.Normal)
    gLobalDataManager:setNumberByField(normalKey, 0)

    local highKey = self:getRecordKey(HolidaySideGameConfig.LeafType.Golden)
    gLobalDataManager:setNumberByField(highKey, 0)

    local timeKey = self:getRecordKey("time")
    gLobalDataManager:setNumberByField(timeKey, 0)
end

return HolidaySideGameData
 