--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 21:23:15
--
local IAPRunData = class("IAPRunData")
local FreeGameData = require "data.baseDatas.FreeGameData"
local BuffItem = require "data.baseDatas.BuffItem"
IAPRunData.buyBuffAllType = nil

-- 当前购买信息
IAPRunData.p_lastBuyId = nil
IAPRunData.p_lastBuyCoin = nil
IAPRunData.p_lastBuyType = nil
IAPRunData.p_lastBuyPrice = nil
IAPRunData.p_showData = nil
IAPRunData.p_discounts = nil
IAPRunData.p_activityId = nil
IAPRunData.p_contentId = nil

IAPRunData.iapExtraData = nil

IAPRunData.buyBuffItems = nil
function IAPRunData:ctor()
    self.buyBuffAllType = {
        {BUY_BUFF_TYPE_A, BUY_BUFF_TYPE_B, BUY_BUFF_TYPE_C},
        {BUY_BUFF_TYPE_D, BUY_BUFF_TYPE_E, BUY_BUFF_TYPE_F},
        {BUY_BUFF_TYPE_G, BUY_BUFF_TYPE_H, BUY_BUFF_TYPE_I},
        {BUY_BUFF_TYPE_J, BUY_BUFF_TYPE_K, BUY_BUFF_TYPE_L}
    }

    -- free spin 免费次数
    self.p_freeGameData = FreeGameData:create()
end

function IAPRunData:getBuyType(iIdx)
    return self.buyCoinAllType[iIdx]
end

-- 二维数组
function IAPRunData:getBuffBuyType(type, iIdx)
    return self.buyBuffAllType[type][iIdx]
end

function IAPRunData:syncBuybuffItems(buffData)
    if not buffData then
        return
    end
    self.buyBuffItems = {}
    for i = 1, #buffData do
        local buffItem = BuffItem:create()
        BuffItem:parseData(buffData[i])
        self.buyBuffItems[#self.buyBuffItems + 1] = BuffItem
    end
end

function IAPRunData:getFreeGameData()
    return self.p_freeGameData
end

return IAPRunData
