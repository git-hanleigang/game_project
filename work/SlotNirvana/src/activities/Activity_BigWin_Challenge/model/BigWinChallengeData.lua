--[[
    author:{author}
    time:2020-07-21 10:52:08
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local BigWinChallengeData = class("BigWinChallengeData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

function BigWinChallengeData:ctor()
    BigWinChallengeData.super.ctor(self)
end

function BigWinChallengeData:parseData(data)
    BigWinChallengeData.super.parseData(self, data)
    self.p_expireAt = data.expireAt  --过期时间戳
    self.p_expire = tonumber(data.expire)   --活动剩余秒
    self.m_notLock = data.notLock
    self.m_bigwinNums = data.bigWinTimes
    self.m_lowBetLimit = data.lowBetLimit
    if self.m_lowBetLimit == "" then
        self.m_lowBetLimit = nil
    end
    if data.progressActivity then
        self:parseProgressData(data.progressActivity)
    end
    gLobalNoticManager:postNotification( ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH,{ name = ACTIVITY_REF.BigWin_Challenge } )
end

function BigWinChallengeData:parseProgressData(_data)
    self.m_progress = {}
    self.m_target = 0
    for i,v in ipairs(_data) do
        local item = {}
        item.id = v.target
        item.coins = v.coins
        item.isGet = v.get
        local shop = {}
        if v.items and #v.items > 0 then
            for k,n in ipairs(v.items) do
                local tempData = ShopItem:create()
                tempData:parseData(n)
                table.insert(shop, tempData)
            end
        end
        if v.coins and tonumber(v.coins) > 0 then
            local item_data = gLobalItemManager:createLocalItemData("Coins", tonumber(v.coins),{p_limit = 3})
            table.insert(shop,item_data)
        end
        item.items = shop
        table.insert(self.m_progress,item)
        self.m_target = v.target
    end
end

function BigWinChallengeData:getMaxReward()
    local item = nil
    if self.m_progress and self.m_progress[4] then
        item = self.m_progress[4].items
    end
    return item
end

function BigWinChallengeData:getProgressData()
    return self.m_progress
end

function BigWinChallengeData:getTargetIndex()
    return self.m_target
end

function BigWinChallengeData:getBigWinNums()
    return self.m_bigwinNums or 0
end

function BigWinChallengeData:setBigWinNums(_num)
    self.m_bigwinNums = _num
end

function BigWinChallengeData:setIsActive(_isactivite)
    self.m_notLock = _isactivite
end

function BigWinChallengeData:setBigWinReard(_index)
   for i,v in ipairs(self.m_progress) do
       if _index == i then
           v.isGet = true
       end
   end
end

function BigWinChallengeData:isRunning()
    if BigWinChallengeData.super.isRunning(self) then
        return true
    end
    return false
end

function BigWinChallengeData:getLowBetLimit()
    return self.m_lowBetLimit or 0
end

function BigWinChallengeData:setLowBetLimit(_bet)
    self.m_lowBetLimit = _bet
end

return BigWinChallengeData
