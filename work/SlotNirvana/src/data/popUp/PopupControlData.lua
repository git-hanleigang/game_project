--对应服务器的HallShowPopup
local PopupControlData = class("PopupControlData")


function PopupControlData:ctor()
    self.p_openTime = nil --开启时间
    self.p_reference = nil --程序引用名
    self.p_hallShow = nil --是否显示展示图
    self.p_hallPriority = nil --展示图层级
    self.p_slidShow = nil --是否显示轮播图
    self.p_slidPriority = nil --轮播图层级
    self.p_loginShow = nil --是否登录弹窗
    self.p_loginPriority = nil --登录弹窗层级
end

function PopupControlData:parseData(data)
    self.p_openTime = tonumber(data.openTime) or 0 --开启时间
    self.p_reference = data.activityName --程序引用名
    self.p_hallShow = data.hallShow --是否显示展示图
    self.p_hallPriority = data.hallPriority --展示图层级
    self.p_slidShow = data.slidShow --是否显示轮播图
    self.p_slidPriority = data.slidPriority --轮播图层级
    self.p_loginShow = data.loginShow --是否登录弹窗
    self.p_loginPriority = data.loginPriority --登录弹窗层级
end

function PopupControlData:getRefName()
    return self.p_reference
end

--开始正常应该会弹出
function PopupControlData:isOpen()
    -- local otherZone = 28800
    -- local dt = os.date("!*t",globalData.userRunData.p_serverTime/1000)
    -- local strStarDate = string.format( "%d%02d%02d",dt.year,dt.month,dt.day)
    -- local strCurDate = ""..self.p_openTime
    -- if strStarDate == strCurDate then
    --       return true
    -- end
    return true
end

return PopupControlData
