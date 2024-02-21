local BeatlesBaseData = {}

function BeatlesBaseData:new(obj)
    obj = obj or {}
    setmetatable(obj, self)
    self.__index = self
    return obj
end


function BeatlesBaseData:getInstance()
    if self.instance == nil then
        self.instance = self:new()
        self.instance:initData()
    end
    return self.instance
end

--初始化一些基本数据
function BeatlesBaseData:initData( )
    self.m_data = {}  --存储数据
    self.m_data.modes = {0, 0, 0, 0, 0}
    self.m_data.spin_num = 0
    self.m_data.curBetValue = nil
    self.m_data.multi = 0 --倍数
    self.m_data.choose_index = {1, 0, 0, 0, 0} --选择的玩法默认为1
    self.m_data.bonusMode = {}
    self.m_data.storeData = {}
    self.m_data.shopNum = {1,0,0,0,0,0}
end

--设置数据
function BeatlesBaseData:setDataByKey(key, value)
    self.m_data[key] = value
end

--获取数据
function BeatlesBaseData:getDataByKey(key)
    return self.m_data[key]
end

function BeatlesBaseData:setSpinNum(spinNum)
    self.m_data.spin_num = spinNum
    local bonusMode = self.m_data.bonusMode[self.m_data.curBetValue]
    bonusMode.spinTimes = spinNum
end

--设置当前的curBetValue
function BeatlesBaseData:setCurBetValue(curBetValue)
    local bonusMode = self.m_data.bonusMode[curBetValue]
    if bonusMode == nil then
        bonusMode = {}
        bonusMode.modes = {0, 0, 0, 0, 0}
        bonusMode.spinTimes = 0
    end
    self.m_data.bonusMode[curBetValue] = bonusMode
    self:setDataByKey("curBetValue", curBetValue)
    self:setDataByKey("spin_num", bonusMode.spinTimes)
    self.m_data.modes = bonusMode.modes
end

--清空
function BeatlesBaseData:clear(  )
    self.instance = nil
end

--初始化 各个玩法界面
function BeatlesBaseData:initModes(modes)
    if not modes then
        modes = {0, 0, 0, 0, 0}
    end
    local bonusMode = self.m_data.bonusMode[self.m_data.curBetValue]
    bonusMode.modes = modes
    self.m_data.modes = modes
end

return BeatlesBaseData