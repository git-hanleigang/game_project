--pick 返回数据解析
local ShopItem = require "data.baseDatas.ShopItem"
local BlastJackData = require "activities.Activity_Blast.model.BlastJackData"
local BlastBoxData = require "activities.Activity_Blast.model.BlastBoxData"
local BlastStageData = require "activities.Activity_Blast.model.BlastStageData"
local BlastResultData = require "activities.Activity_Blast.model.BlastResultData"
local BlastBombRData = class("BlastBombRData")

function BlastBombRData:ctor()
end

function BlastBombRData:parseData(data,_id,_flag)
    --首先是本次炸弹炸出来的奖励
    self.m_currentData = BlastResultData:create()
    if _flag then
        self.m_currentData:parseData(data.bombReward)
    else
        self.m_currentData:parseData(data)
    end
    self.m_position = _id
    --解析炸弹爆炸所产生的奖励
    self.m_Bombs = {}
    if data.bomb and #data.bomb > 0 then
        self:parseBomb(data.bomb)
    end
    self.m_isCoin = 0
    self.m_jackPot = {} --jackport奖励
    self.m_jkFlay = {}
    self.m_first = {} --直接飞的，先判断有没有buff，有buff的话金币不放在第一梯队 ，pick,jackpot,buff,宝箱，宝石
    self.m_two = {} --章节加成，金币
    self.m_three = {} --过关道具
end

function BlastBombRData:parseBomb(_data)
    local reward = {}
    local bomb = {}
    for i,v in ipairs(_data) do
        local item = {}
        item.pos = v.position + 1
        item.parentPos = self.m_position
        local ru = BlastResultData:create()
        ru:parseData(v.bombReward)
        item.result = ru
        table.insert(reward,item)
        if v.bomb and #v.bomb > 0 then
            local bp = {}
            bp.parentPos = item.pos
            bp.bomb = v.bomb
            table.insert(bomb,bp)
        end
    end
    table.insert(self.m_Bombs,reward)
    if #bomb > 0 then
        self:parseTwo(bomb)
    end
end

function BlastBombRData:parseTwo(_data)
    local reward = {}
    local bomb = {}
    for i,v in ipairs(_data) do
        for k=1,#v.bomb do
            local item = {}
            local temp = v.bomb[k]
            item.pos = temp.position + 1
            item.parentPos = v.parentPos
            local ru = BlastResultData:create()
            ru:parseData(temp.bombReward)
            item.result = ru
            table.insert(reward,item)
            if temp.bomb and #temp.bomb > 0 then
                local bp = {}
                bp.parentPos = item.pos
                bp.bomb = temp.bomb
                table.insert(bomb,bp)
            end
        end
    end
    table.insert(self.m_Bombs,reward)
    if #bomb > 0 then
        self:parseTwo(bomb)
    end
end

function BlastBombRData:setAllReward()
    self.m_buffTime = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BLAST_TREASURE_BUFF) -- 宝箱
    if self.m_currentData:getBoxType() ~= "REFRESH_TREASURE" then
        local item = {}
        item.pos = self.m_position
        item.result = self.m_currentData
        self:setStageAndRound(self.m_currentData)
        self:setReward(item)
    end
   
    if #self.m_Bombs > 0 then
        for i,v in ipairs(self.m_Bombs) do
            for k=1,#v do
                self:setStageAndRound(v[k].result)
                self:setReward(v[k])
            end
        end
    end
end

function BlastBombRData:setStageAndRound(_pickdata)
    if _pickdata:getStageR() then
        self.m_stageR = _pickdata:getStageR()
    elseif _pickdata:getRoundR() then
        self.m_roundR = _pickdata:getRoundR()
    end
end

function BlastBombRData:setReward(_item)
    local result = _item.result
    local boxType = result:getBoxType()
    if boxType == "COINS" then
        if self.m_buffTime > 0 then
            self.m_isCoin = self.m_isCoin + 1
            table.insert(self.m_two,_item)
        else
            table.insert(self.m_first,_item)
        end
    elseif boxType == "ITEM_1" or boxType == "STAGE_COINS" or boxType == "ITEM_2" or boxType == "PICKS" or boxType == "GEMS" or boxType == "CARD" or boxType == "JACKPOT" then
        if boxType == "JACKPOT" then
            table.insert(self.m_jkFlay,_item)
            self:setJackPort(_item)
        end
        table.insert(self.m_first,_item)
    elseif boxType == "CLEAR" then
        table.insert(self.m_three,_item)
    end
end

function BlastBombRData:setJackPort(_item)
    local result = _item.result
    local box = result:getBox()
    local coins = box:getCoins()
    if coins and toLongNumber(coins) > toLongNumber(0) then
        table.insert(self.m_jackPot,_item)
    end
end

function BlastBombRData:getJackpotPot()
    return self.m_jackPot
end

function BlastBombRData:getJackpotFly()
    return self.m_jkFlay
end

function BlastBombRData:removeJack(_type)
    if #self.m_jackPot > 0 then
        table.remove(self.m_jackPot,1)
    end
end

function BlastBombRData:removeReward(_type)
    if _type == 1 then
        self.m_first = {}
        self.m_jkFlay = {}
    elseif _type == 2 then
        self.m_two = {}
    elseif _type == 3 then
        self.m_three = {}
    elseif _type == 4 then
        self.m_stageR = nil
    elseif _type == 5 then
        self.m_roundR = nil
    elseif _type == 6 then
        self.m_stageC = {}
    end
end

function BlastBombRData:getStageReward()
    return self.m_stageR
end

function BlastBombRData:getRoundReward()
    return self.m_roundR
end

function BlastBombRData:getIsCoin()
    return self.m_isCoin
end

function BlastBombRData:setIsCoin()
    self.m_isCoin = 0
end

function BlastBombRData:getFirst()
    return self.m_first
end

function BlastBombRData:getTwo()
    return self.m_two
end

function BlastBombRData:getThree()
    return self.m_three
end

--所有奖励
function BlastBombRData:getAllResult()
    return self.m_Bombs
end

--首炸的奖励
function BlastBombRData:getCurrentR()
    return self.m_currentData
end

--首炸的位置
function BlastBombRData:getCurrentPosition()
    return self.m_position
end

function BlastBombRData:getBoxType()
    return self.m_currentData:getBoxType()
end

function BlastBombRData:getJackpot()
    return self.m_currentData:getJackpot()
end

function BlastBombRData:getBox()
    return self.m_currentData:getBox()
end

function BlastBombRData:getCurrentClear()
    return self.m_currentData:getCurrentClear()
end

function BlastBombRData:getTotalClear()
    return self.m_currentData:getTotalClear()
end

function BlastBombRData:getStageR()
    return self.m_currentData:getStageR()
end

function BlastBombRData:getRoundR()
    return self.m_currentData:getRoundR()
end

return BlastBombRData
