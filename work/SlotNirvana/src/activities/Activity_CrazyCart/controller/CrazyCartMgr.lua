--[[
]]
local CrazyCartNet = require("activities.Activity_CrazyCart.net.CrazyCartNet")
local CrazyCartMgr = class("CrazyCartMgr", BaseActivityControl)
local ShopItem = util_require("data.baseDatas.ShopItem")

function CrazyCartMgr:ctor()
    CrazyCartMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CrazyCart)
    self.m_crazyCartNet = CrazyCartNet:getInstance()
end

function CrazyCartMgr:getCuTime(time)
    local strDays = "%d DAYS"
    if time > 86400 then
        local t = math.floor((time) / 86400)

        local str = string.format(strDays, t)
        return str
    end

    return util_count_down_str(time)
end

function CrazyCartMgr:requestShare()
    local function successCallFun(result)
    end

    local function failedCallFun(errorCode, errorData)
    end

    self.m_crazyCartNet:requestShare(successCallFun, failedCallFun)
end

function CrazyCartMgr:requestCollect()
    local function successCallFun(result)
        if result and result.reward then
            self:parseConnect(result.reward)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CART_CORRECT)
    end

    local function failedCallFun(errorCode, errorData)
    end

    self.m_crazyCartNet:requestCollect(successCallFun, failedCallFun)
end

function CrazyCartMgr:parseConnect(_data)
    self.item_list = {}
    if _data.coins and tonumber(_data.coins) > 0 then
        self.m_coins = _data.coins
        local item_data = gLobalItemManager:createLocalItemData("Coins", _data.coins)
        table.insert(self.item_list,item_data)
    end
    if _data.itemList and #_data.itemList > 0 then
        for i,v in ipairs(_data.itemList) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(self.item_list, tempData)
        end
    end
end

function CrazyCartMgr:getItemList()
    return self.item_list or {}
end

function CrazyCartMgr:getItemCoins()
    return self.m_coins or 0
end

function CrazyCartMgr:setIsComplete(_iscomplete)
    self.m_isCompleted = _iscomplete
end

function CrazyCartMgr:getIsCompleted()
    return self.m_isCompleted or false
end

function CrazyCartMgr:isCanShowInEntrance()
    if self:getIsCompleted() then
        return false
    else
        return CrazyCartMgr.super.isCanShowInEntrance(self)
    end
end

function CrazyCartMgr:getCalendarStr(_time)
    if not _time then
        _time = globalData.userRunData.p_serverTime / 1000
    end
    _time = math.floor(_time)

    local tm = os.date("*t", _time)
    local last = string.sub(tm.day,string.len(tm.day),string.len(tm.day))
    local last_str = "th"
    if tonumber(last) == 1 then
        last_str = "st"
    elseif tonumber(last) == 2 then
        last_str = "nd"
    elseif tonumber(last) == 3 then
        last_str = "rd"
    end
    local yue = "Dec."
    if tm.day == 1 or tm.day == 2 then
        yue = "Jan."
    end
    return yue..tm.day..last_str
end

function CrazyCartMgr:getHallPath(hallName)
    return "" .. hallName .. "/" .. hallName ..  "HallNode"
end

function CrazyCartMgr:getSlidePath(slideName)
    return "" .. slideName .. "/" .. slideName ..  "SlideNode"
end

function CrazyCartMgr:getPopPath(popName)
    return "" .. popName .. "/" .. popName
end

return CrazyCartMgr
