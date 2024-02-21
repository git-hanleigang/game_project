--对应服务器的HallShowPopup
local NovicePopupControlData = class("NovicePopupControlData")


function NovicePopupControlData:ctor()
    self.p_registerDays = nil --开启时间
    self.p_expireAt = nil --结束时间
    self.p_reference = nil --程序引用名
    self.p_hallShow = nil --是否显示展示图
    self.p_hallPriority = nil --展示图层级
    self.p_slidShow = nil --是否显示轮播图
    self.p_slidPriority = nil --轮播图层级
    self.p_loginShow = nil --是否登录弹窗
    self.p_loginPriority = nil --登录弹窗层级
    -- 活动入口是否显示
    self.p_entryShow = false
    -- 活动入口显示优先级
    self.p_entryProiority = nil
end

function NovicePopupControlData:parseData(data)
    self.p_popupId = data.popupId
    self.p_expireAt = tonumber(data.expireAt or 0)
    self.p_registerDays = data.registerDays or 0 --开启时间
    self.p_reference = data.name --程序引用名
    self.p_hallShow = tonumber(data.hallShow or 0) --是否显示展示图
    self.p_hallPriority = tonumber(data.hallShowPriority or 0) --展示图层级
    self.p_slidShow = tonumber(data.slideShow or 0) --是否显示轮播图
    self.p_slidPriority = tonumber(data.slidePriority or 0) --轮播图层级
    self.p_loginShow = tonumber(data.loginShow or 0) --是否登录弹窗
    self.p_loginPriority = tonumber(data.loginShowPriority or 0) --登录弹窗层级
    self.p_entryShow = tonumber(data.popupShow or 0)
    self.p_entryProiority = tonumber(data.popupPriority or 0)
end

function NovicePopupControlData:getRefName()
    return self.p_reference
end

--开始正常应该会弹出
function NovicePopupControlData:isOpen()
    -- local otherZone = 28800
    -- local dt = os.date("!*t",globalData.userRunData.p_serverTime/1000)
    -- local strStarDate = string.format( "%d%02d%02d",dt.year,dt.month,dt.day)
    -- local strCurDate = ""..self.p_openTime
    -- if strStarDate == strCurDate then
    --       return true
    -- end
    if globalData.userRunData.p_serverTime >= self.p_expireAt then
        return false
    end
    return true
end

function NovicePopupControlData:isEntryOpen()
    return self.p_entryShow
end

return NovicePopupControlData
