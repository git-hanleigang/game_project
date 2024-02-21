--pick 返回数据解析
local ShopItem = require "data.baseDatas.ShopItem"
local BlastJackData = require "activities.Activity_Blast.model.BlastJackData"
local BlastBoxData = require "activities.Activity_Blast.model.BlastBoxData"
local BlastStageData = require "activities.Activity_Blast.model.BlastStageData"
local BlastResultData = class("BlastResultData")

-- 解析翻牌数据
-- {
--     -- 翻牌奖励
--     "box":{
--         "coins":0,
--         "items":[
--             {
--                 "activityId":"-1",
--                 "description":"BLAST宝箱加成",
--                 "expireAt":0,
--                 "icon":"Blast",
--                 "id":80003,
--                 "item":{
--                     "createTime":1597809316000,
--                     "description":"BLAST宝箱加成",
--                     "duration":-1,
--                     "icon":"/XX/XX.png",
--                     "id":119,
--                     "lastUpdateTime":1597809316000,
--                     "linkId":"-1",
--                     "type1":1,
--                     "type2":1
--                 },
--                 "num":10,
--                 "type":"Item"
--             }
--         ],
--         "jackpot":0, -- 获得jackpot星星的类型(mini minor major grand)
--         "rewardCoinsEnd":720720000,
--         "rewardCoinsStart":655200000
--         "gems":0,
--         "treasurePositions":["1","2","3"]
--     },
--     "stage":{}, -- 过关奖励
--     "round":{}, -- 通关奖励
--     "jackpots":[{"jackpot":1,"count":0, "coins":100000},{"jackpot":2,"count":0, "coins":100000},{"jackpot":3,"count":0, "coins":100000}]
--     "boxType":"STAGE_COINS"
--     "currentClearItems":1
--     "totalClearItems":1
-- }

function BlastResultData:ctor()
end

function BlastResultData:parseData(data)
    self.m_boxType = data.boxType --奖励类型
    self.m_jackpots = {}
    if data.jackpots and #data.jackpots > 0 then
        self:parseJackpotsData(data.jackpots)
    end
    self.m_currentClearItems = data.currentClearItems
    self.m_totalClearItems = data.totalClearItems
    self.m_box = {}
    if data.box then
        local box = BlastBoxData:create()
        box:parseData(data.box)
        self.m_box = box
    end
    self.m_stageR = nil
    if data.stage then
        self.m_stageR = BlastStageData:create()
        self.m_stageR:parseData(data.stage)
    end

    self.m_roundR = nil
    if data.round then
        self.m_roundR = BlastStageData:create()
        self.m_roundR:parseData(data.round)
    end
end

function BlastResultData:parseJackpotsData(_data)
    for i,v in ipairs(_data) do
        local jack = BlastJackData:create()
        jack:parseData(v)
        table.insert(self.m_jackpots,jack)
    end
end

function BlastResultData:getBoxType()
    return self.m_boxType
end

function BlastResultData:getJackpot()
    return self.m_jackpots
end

function BlastResultData:getBox()
    return self.m_box
end

function BlastResultData:getCurrentClear()
    return self.m_currentClearItems
end

function BlastResultData:getTotalClear()
    return self.m_totalClearItems
end

function BlastResultData:getStageR()
    return self.m_stageR
end

function BlastResultData:getRoundR()
    return self.m_roundR
end

return BlastResultData
