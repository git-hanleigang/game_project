local JackpotOGoldBaseData = {}

function JackpotOGoldBaseData:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end


function JackpotOGoldBaseData:getInstance()
    if self.instance == nil then
        self.instance = self:new()
        self.instance:initData()
    end
    return self.instance
end

--初始化一些基本数据
function JackpotOGoldBaseData:initData( )
    self.m_data = {}  --存储数据
    self.m_data.bonusMode = {}
    self.m_data.curBetValue = nil
end

--设置数据
function JackpotOGoldBaseData:setDataByKey(key, value)
    self.m_data[key] = value
end

--获取数据
function JackpotOGoldBaseData:getDataByKey(key)
    return self.m_data[key]
end

--设置当前的curBetValue
function JackpotOGoldBaseData:setCurBetValue(curBetValue)
    local bonusMode = self.m_data.bonusMode[curBetValue]
    if bonusMode == nil then
        bonusMode = {}
        bonusMode.getjackpot = {}
        bonusMode.totalbonus = tonumber(curBetValue)
        bonusMode.spintime = 0
    end
    self.m_data.bonusMode[curBetValue] = bonusMode
    self:setDataByKey("curBetValue", curBetValue)
    
end

--清空
function JackpotOGoldBaseData:clear(  )
    self.instance = nil
end

--初始化 各个玩法界面
function JackpotOGoldBaseData:initModes(selfMakeData)
    if not selfMakeData then
        selfMakeData = {}
        selfMakeData.getjackpot = {}
        selfMakeData.totalBonus = tonumber(self.m_data.curBetValue)
        selfMakeData.spinTimes = 0
    end
    self.m_data.bonusMode[self.m_data.curBetValue] = selfMakeData

end

return JackpotOGoldBaseData