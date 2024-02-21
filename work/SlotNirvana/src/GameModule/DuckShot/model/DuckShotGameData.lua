local BaseActivityData = require "baseActivity.BaseActivityData"
local DuckShotGameData = class("DuckShotGameData",BaseActivityData)
local ShopItem = require "data.baseDatas.ShopItem"

function DuckShotGameData:ctor()
    DuckShotGameData.super.ctor(self)

end
-- message DuckShotGame {
--   optional int32 index = 1; //序号
--   optional string keyId = 2;
--   optional string key = 3;
--   optional string price = 4; //价格
--   optional int64 expireAt = 5; //过期时间
--   optional int64 expire = 6; //剩余时间
--   optional string status = 7; //游戏状态:init, playing
--   repeated DuckShotLayer layers = 8; //层数据
--   repeated int64 jackpots = 9; //jackpots
--   optional bool flag = 10;//是否保底
--   optional bool mark = 11;//是否带付费项
--   optional bool pay = 12;//是否付过费
--   optional int32 phase = 13;//阶段
--   optional string source = 14; //投放来源
--   repeated ShopItem items = 15;//物品奖励
--   optional int64 coins = 16;//金币奖励
--   optional int32 jackpot = 17;//jackpot
--   optional int64 payLaunchCount = 18; //带付费项球数
--   optional int64 payJackpot = 19; //带付费项最多能获取金币数
--   optional string hitRange = 20; //球速度阀值
--   }

function DuckShotGameData:parseData(_data)
    DuckShotGameData.super.parseData(self,_data)

    self.m_index  = _data.index     -- 序号
    self.m_KeyId = _data.keyId     -- 付费点
    self.m_Key    = _data.key       -- 付费点
    self.m_price  = _data.price     -- 价格
    self.m_status = _data.status    -- 游戏状态:init, playing
    self.m_flag   = _data.flag      -- 是否保底
    self.m_mark   = _data.mark      -- 是否带付费项
    self.m_pay    = _data.pay       -- 是否付过费
    self.m_phase  = _data.phase     -- 阶段
    self.m_source = _data.source    -- 投放来源
    self.m_coins  = tonumber(_data.coins)     -- 已获得的总金币奖励
    self.m_jackpot = _data.jackpot  -- 转盘的转到的奖励
    self.m_payJackpot  = tonumber(_data.payJackpot)     -- 带付费项最多能获取金币数
    self.m_payLaunchCount  = tonumber(_data.payLaunchCount)     -- 带付费项球数
    self.m_hitRange = tonumber(_data.hitRange)

    self.m_totalItems  = self:parseItems(_data.items)      -- 已获得的总物品奖励
    self.m_DuckLayers  = self:parseLayers(_data.layers)      -- 层数据
    self.m_jackpotList = self:parseJackpots(_data.jackpots)  -- jackpots
    self.m_payDuckLayers = self:parseLayers(_data.payLayers)
    self.m_payJackpotList = self:parseJackpots(_data.payJackpots)
end

-- message DuckShotLayer {
--     optional int32 layer = 1; //层
--     optional int32 leftShotTimes = 2;//剩余射击次数
--     optional int32 payShotTimes = 3;//付费给的射击总次数
--     repeated DuckShotRow rows = 4; //行数据
--     bulletMoveTime 子弹移动时间
--   }
function DuckShotGameData:parseLayers(_layers)
    local duckLayers = {}
    if _layers and #_layers > 0 then 
        for i,v in ipairs(_layers) do
            local info = {}
            info.m_layer = v.layer
            info.m_leftShotTimes = v.leftShotTimes
            info.m_payShotTimes = v.payShotTimes
            info.m_bulletMoveTime = tonumber(v.bulletMoveTime)
            info.m_rows = self:parseRows(v.rows)
            table.insert(duckLayers, info)
            if not self.m_curStage and v.leftShotTimes > 0 then 
                self.m_curStage = v.layer
            end
        end
    end
    return duckLayers
end

-- message DuckShotRow {
--     optional int32 row = 1; //行
--     repeated DuckShotBall balls = 2;//球数据
--     intervalTime 生成鸭子的间隔时间
--     duckMoveTime 鸭子移动时间
--   }
function DuckShotGameData:parseRows(_rows)
    local rows = {}
    if _rows and #_rows > 0 then 
        for i,v in ipairs(_rows) do
            local info = {}
            info.m_index = 1
            info.m_row = v.row
            info.m_intervalTime = tonumber(v.intervalTime)
            info.m_duckMoveTime = tonumber(v.duckMoveTime)
            info.m_balls = self:parseBalls(v.balls)
            table.insert(rows, info)
        end
    end
    return rows
end

-- message DuckShotBall {
--     optional int32 id = 1; //球id
--     optional int64 coins = 2;//金币奖励
--     repeated ShopItem items = 3;//物品奖励
--   }
function DuckShotGameData:parseBalls(_balls)
    local balls = {}
    if _balls and #_balls > 0 then 
        for i,v in ipairs(_balls) do
            local info = {}
            info.m_id = v.id
            info.m_coins = tonumber(v.coins)
            info.m_items = self:parseItems(v.items)
            table.insert(balls, info)
        end
    end
    return balls
end

function DuckShotGameData:parseItems(_items)
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

function DuckShotGameData:parseJackpots(_jackpots)
    local coinList = {}
    if _jackpots and #_jackpots > 0 then 
        for i,v in ipairs(_jackpots) do
            local coins = tonumber(v)
            table.insert(coinList, coins)
        end
    end

    if #coinList > 0 then 
        table.sort(
            coinList,
            function(a, b)
                return a < b
            end
        )
    end
    return coinList
end

function DuckShotGameData:getBulletMoveTime(_stage)
    return self.m_DuckLayers[_stage].m_bulletMoveTime
end

function DuckShotGameData:getIntervalTime(_stage, _rowIndex)
    return self.m_DuckLayers[_stage].m_rows[_rowIndex].m_intervalTime
end

function DuckShotGameData:getDuckMoveTime(_stage, _rowIndex)
    return self.m_DuckLayers[_stage].m_rows[_rowIndex].m_duckMoveTime
end

function DuckShotGameData:getJackpotList()
    return self.m_jackpotList
end

function DuckShotGameData:getPayJackpotList()
    return self.m_payJackpotList
end

function DuckShotGameData:getDuckLayers()
    return self.m_DuckLayers
end

function DuckShotGameData:getPayDuckLayers()
    return self.m_payDuckLayers
end

function DuckShotGameData:getIndex()
    return self.m_index
end

function DuckShotGameData:getBuyKey()
    return self.m_Key
end

function DuckShotGameData:getPrice()
    return self.m_price
end

function DuckShotGameData:getCurStage()
    return self.m_phase
end

function DuckShotGameData:getSource()
    return self.m_source
end

function DuckShotGameData:getHitRange()
    return self.m_hitRange or 0.2
end

function DuckShotGameData:getTotalRewardCoins()
    return self.m_coins or 0
end

function DuckShotGameData:getTotalRewardItems()
    return self.m_totalItems or {}
end

function DuckShotGameData:getJackpotIndex()
    return self.m_jackpot
end

function DuckShotGameData:getPayJackpotCoins()
    return self.m_payJackpot
end

function DuckShotGameData:getPayLaunchCount()
    return self.m_payLaunchCount
end

function DuckShotGameData:getShopItem()
    return {}
end

function DuckShotGameData:isPlaying()
    if self.m_status == "INIT" then 
        return false
    elseif self.m_status == "PLAYING" then 
        return true
    end
end

function DuckShotGameData:isInit()
    if self.m_status == "INIT" then 
        return true
    end
    return false
end

function DuckShotGameData:isHit()
    return self.m_flag
end

function DuckShotGameData:isPayGame()
    return self.m_mark
end

function DuckShotGameData:isPaid()
    return self.m_pay
end

function DuckShotGameData:isRunning()
    if self:getExpireAt() > 0 then
        return self:getLeftTime() > 0
    else
        return false
    end
end

function DuckShotGameData:getBallsTotal(_layer, _row)
    local layerConfig = self.m_DuckLayers
    for i,v in ipairs(layerConfig) do
        if v.m_layer == _layer then 
            for n,m in ipairs(v.m_rows) do
                if m.m_row == _row then 
                    return #m.m_balls
                end
            end
        end
    end
    return 1
end

function DuckShotGameData:getRowsDataByIndex(_layer, _row, _index)
    local errMsg = ""
    local layerConfig = self.m_DuckLayers
    for i,v in ipairs(layerConfig) do
        errMsg = errMsg .. tostring(i) .. ","
        if v.m_layer == _layer then 
            errMsg = errMsg .. "rowData,"
            for n,m in ipairs(v.m_rows) do
                errMsg = errMsg .. tostring(n) .. ","
                if m.m_row == _row then 
                    errMsg = errMsg .. "balls:" .. tostring(#m.m_balls)
                    if _index > #m.m_balls then 
                        _index = 1
                    end
                    return m.m_balls[_index]
                end
            end
        end
    end
    
    errMsg = errMsg .. ",layer:" .. tostring(_layer) .. ",row:" .. tostring(_row) .. ",index:" .. tostring(_index)
    release_print(errMsg)
    util_sendToSplunkMsg("DuckShotDataError", errMsg)
    return {}
end

function DuckShotGameData:setWaitPayData()
    self.m_phase  = 1     -- 阶段
    self.m_coins  = 0     -- 已获得的总金币奖励
    self.m_totalItems  ={}      -- 已获得的总物品奖励
    self.m_DuckLayers  = self.m_payDuckLayers      -- 层数据
    self.m_jackpotList = self.m_payJackpotList  -- jackpots
end

return DuckShotGameData