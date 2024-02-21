local TestDataManager = class("TestDataManager")
TestDataManager.m_instance = nil

local rewardTable = {} 
local eum ={1,2,3,4,5}
local m_isOpen = nil  --是否开始
local m_isPay = nil   --是否付费
local m_bet = nil      --当前bet档位
local m_pay = nil  --选择的
local m_start_time = nil  --开启时间
local m_level_time = nil    -- 升级时间
local m_cash_time = nil     --cashbonus 升级时间
local m_spin_times = nil  --spin次数
local m_coin = nil --  消耗的金币
local m_cash_info = nil  
local m_level_info = nil  

function TestDataManager:getInstance()
    if TestDataManager.m_instance == nil then
        TestDataManager.m_instance = TestDataManager.new()
    end
    return TestDataManager.m_instance
end

-- 构造函数
function TestDataManager:ctor()
    m_isOpen = false
    m_isPay = false
    m_bet = 5
    m_pay = 1
    m_start_time = 0
    m_spin_times = 0
    m_coin = 0
    m_cash_time = 0
    m_cash_info= {}
    m_level_info ={}
    self:initEvent()
end
function TestDataManager:initEvent(  )
    if DEBUG ~= 2  then
        return
    end
    gLobalNoticManager:addObserver(self,function(self,params)
        if m_isOpen == false then
            return
        end
        m_spin_times =  m_spin_times + 1
        m_coin = m_coin + params
    end,"NOTIFY_DEBUG_SPIN")
end
function TestDataManager:setPayStats( flg )
    if DEBUG ~= 2 then
        return
    end
    m_isPay = flg
end
function TestDataManager:start()
    if DEBUG ~= 2 then
        return
    end
    m_isOpen = true
    if m_start_time == 0 then
        m_start_time = os.time()
        m_cash_time = m_start_time
        m_level_time = m_start_time
        self:initLevelInfo()
    end
    
end
function TestDataManager:isOpen(  )
    if DEBUG == 2 and m_isOpen  then
        return true
    end
    return false
end
function TestDataManager:initLevelInfo(  )
    local level = globalData.userRunData.levelNum
    m_level_info[#m_level_info + 1] = {level = level, coin = "???",spinTimes = "???",time = "???",allTime = "???"}
end

function TestDataManager:setBet(count)
    if DEBUG ~= 2 then
        return
    end
    m_bet = count
end

function TestDataManager:setPay(count)
    if DEBUG ~= 2 then
        return
    end
    m_pay = count
end

function TestDataManager:levelUp(oldLv)
    if DEBUG ~= 2 or m_isOpen == false then
        return
    end
    local tmp_time = os.time()
    local time =   math.floor(tmp_time  - m_level_time)
    m_level_time = tmp_time
    local alltime = math.floor((m_level_time - m_start_time)/60) 
    m_level_info[#m_level_info] = {level = oldLv,coin = m_coin,spinTimes = m_spin_times,time = time,allTime = alltime}
    m_level_info[#m_level_info + 1] = {level = globalData.userRunData.levelNum, coin = "???",spinTimes = "???",time = "???",allTime = "???"}
    gLobalNoticManager:postNotification("TEST_DATA_LEVEL_UP")
end

function TestDataManager:spinLevelUp(lv)
    if DEBUG ~= 2 or m_isOpen == false then
        return
    end
    local tmp_time = os.time()
    local time =   math.floor((tmp_time  - m_cash_time)/60)
    m_cash_time = tmp_time
    local alltime = math.floor((m_cash_time - m_start_time)/60) 
    m_cash_info[#m_cash_info + 1] = {spinTimes = m_spin_times,time = time,allTime = alltime}
    gLobalNoticManager:postNotification("TEST_DATA_SPIN_UP")
end

function TestDataManager:getLevelInfo( )
    return m_level_info
end

function TestDataManager:getCashInfo( )
    return m_cash_info
end
return TestDataManager
