local FruitFarmBaseData = {}

function FruitFarmBaseData:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end


function FruitFarmBaseData:getInstance()
    if self.instance == nil then
        self.instance = self:new()
        self.instance:initData()
    end
    return self.instance
end

--初始化一些基本数据
function FruitFarmBaseData:initData( )
    self.m_data = {}  --存储数据
    self.m_data.doorArry = {}
    self.m_data.spin_num = 0
    self.m_data.curBetValue = nil
    self.m_data.betData = {}
    self.m_data.betLevel = 0 --当前的高低bet
    self.m_data.row_max = {false, false, false, false, false}  --每列是否是最大值
end

--设置数据
function FruitFarmBaseData:setDataByKey(key, value)
    self.m_data[key] = value
end

--获取数据
function FruitFarmBaseData:getDataByKey(key)
    return self.m_data[key]
end

function FruitFarmBaseData:setSpinNum(spinNum)
    self.m_data.spin_num = spinNum
    local betData = self.m_data.betData[self.m_data.curBetValue]
    betData.spinTimes = spinNum
end

--设置当前的curBetValue
function FruitFarmBaseData:setCurBetValue(curBetValue)
    local betData = self.m_data.betData[curBetValue]
    if betData == nil then
        betData = {}
        betData.upReels = {}
        betData.spinTimes = 0
    end
    self.m_data.betData[curBetValue] = betData
    self:setDataByKey("curBetValue", curBetValue)
    self:setDataByKey("spin_num", betData.spinTimes)
    self:initDoorArry(betData.upReels)
end

--清空
function FruitFarmBaseData:clear(  )
    self.instance = nil
end

--初始化 主界面上面door的数据 isFree 是否是freeGame
function FruitFarmBaseData:initDoorArry(reels, isFree)
    if not isFree then
        local betData = self.m_data.betData[self.m_data.curBetValue]
        betData.upReels = reels
    end
    local row = 5 
    local col = 3
    for iRow = row, 1, -1 do
        local reel_Data = reels[iRow] or {}
        for iCol=1, col do
            if self.m_data.doorArry[iCol]  == nil then
                self.m_data.doorArry[iCol] = {}
            end
            self.m_data.doorArry[iCol][row - iRow + 1] = reel_Data[iCol] or -1
        end
    end
end

return FruitFarmBaseData