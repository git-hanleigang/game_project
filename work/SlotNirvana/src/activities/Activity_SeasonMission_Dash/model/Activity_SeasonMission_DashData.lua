local SaleItemConfig = require("data.baseDatas.SaleItemConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

local BaseActivityData = require "baseActivity.BaseActivityData"
local Activity_SeasonMission_DashData = class("Activity_SeasonMission_DashData", BaseActivityData)

function Activity_SeasonMission_DashData:ctor()
    Activity_SeasonMission_DashData.super.ctor(self)
    self.p_open = true

    self._rewardDataList = {}
end

function Activity_SeasonMission_DashData:parseData(data)
    Activity_SeasonMission_DashData.super.parseData(self,data)
    self._rewardDataList = {}
    if data.items and #data.items > 0 then
        for i = 1,#data.items do
            local value = data.items[i]
            local shopItem = ShopItem:create()
            shopItem:parseData(value)
            table.insert(self._rewardDataList, shopItem)
        end
    end

    if data:HasField("sendMail") then
        self._sendMail = data.sendMail
    end
end

function Activity_SeasonMission_DashData:getItems()
    return self._rewardDataList
end

function Activity_SeasonMission_DashData:hasSendMail()
    return self._sendMail
end

return Activity_SeasonMission_DashData