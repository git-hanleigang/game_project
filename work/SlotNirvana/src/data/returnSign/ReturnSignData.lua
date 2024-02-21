--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-08-25 15:24:50
]]
local ShopItem = require "data.baseDatas.ShopItem"
local ReturnSignData = class("ReturnSignData") 

function ReturnSignData:ctor()
    self.m_isRunning = false
    self.m_noticNextCount = 10
    self.m_noticOverCount = 10
end

function ReturnSignData:parseData(_data)
    self.p_returnUser = _data.returnUser
    self.p_churnUser = _data.churnUser
    self.p_begin = _data.begin
    self.p_day = _data.day
    self.p_gameId = _data.gameId
    self.p_nextExpireAt = tonumber(_data.nextExpireAt)
    self.p_expireAt = tonumber(_data.expireAt)
    self.p_days = self:parseDays(_data.days)
    self.p_returnVersion = _data.returnVersion
    self.m_isRunning = true
    
    self.m_isReturnUser = self:getIsChurnReturn()

    self:startUpdate()
end

function ReturnSignData:getIsChurnReturn()
    if self.p_returnUser or self.p_churnUser then
        return true
    end
    return false
end

function ReturnSignData:isReturnUser()
    return self.m_isReturnUser
end

function ReturnSignData:getReturnVersion()
    return self.p_returnVersion
end

function ReturnSignData:isNewVersion2()
    return self.p_returnVersion == "V2"
end

function ReturnSignData:parseDays(_days)
    local days = {}
    if _days and #_days > 0 then 
        for i,v in ipairs(_days) do
            local temp = {}
            temp.p_day = v.day
            temp.p_coins = tonumber(v.coins)
            temp.p_gems = tonumber(v.gems)
            temp.p_collected = v.collected
            temp.p_items = self:parseItemsData(v.items)
            temp.p_spinItems = self:parseItemsData(v.spinItems)
            table.insert(days, temp)
        end
    end
    return days
end

-- 解析道具数据
function ReturnSignData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function ReturnSignData:getDayData(_index)
    local dayData = self.p_days[_index]
    return dayData
end

function ReturnSignData:getDayNum()
    return self.p_day
end

function ReturnSignData:getGems()
    local dayData = self.p_days[self.p_day]
    return dayData.p_gems
end

function ReturnSignData:isRunning()
    if self.m_isRunning then
        if self:getExpireAt() > 0 then
            return self:getLeftTime() > 0
        end 
    end
    return false
end

function ReturnSignData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function ReturnSignData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function ReturnSignData:isPopView()
    local isPopView = false
    
    for i,v in ipairs(self.p_days) do
        if i <= self.p_day and v.p_collected == false then 
            isPopView = true
        end
    end
    return isPopView
end

--停止刷帧
function ReturnSignData:stopUpdate()
    if self.m_expireALLHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_expireALLHandlerId)
        self.m_expireALLHandlerId = nil
    end
end

--开启刷帧
function ReturnSignData:startUpdate()
    if not self.p_returnUser then 
        return 
    end

    self:stopUpdate()

    self.m_expireALLHandlerId =
        scheduler.scheduleGlobal(
        function()
            -- local nextTime = util_getLeftTime(self.p_nextExpireAt)
            local overTime = util_getLeftTime(self.p_expireAt)

            if overTime <= 0 then 
                self.p_returnUser = false
                self.p_churnUser = false
                self.m_noticOverCount = self.m_noticOverCount - 1
                if self.m_noticOverCount == 0 then 
                    self:stopUpdate()
                end
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RETURN_SIGN_OVER_TIME)
                return
            end

            -- if nextTime <= 0 and self.p_nextExpireAt ~= 0 then 
            --     self.p_returnUser = false
            --     self.p_churnUser = false
            --     self.m_noticNextCount = self.m_noticNextCount - 1
            --     if self.m_noticNextCount == 0 then 
            --         self:stopUpdate()
            --     end
            --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RETURN_SIGN_NEXT_TIME)
            -- end
        end,
        1
    )
end

return ReturnSignData