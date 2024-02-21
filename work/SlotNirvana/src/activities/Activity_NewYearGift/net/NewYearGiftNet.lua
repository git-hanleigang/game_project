--[[
    新年送礼
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local NewYearGiftNet = class("NewYearGiftNet", util_require("baseActivity.BaseActivityManager"))

function NewYearGiftNet:getInstance()
    if self.m_instance == nil then
        self.m_instance = NewYearGiftNet.new()
	end
	return self.m_instance
end

-- 领取奖励
function NewYearGiftNet:sendCollectReward(_suc, _fail)
    gLobalViewManager:addLoadingAnima()
	local function successCallFunc(target, resData)
        gLobalViewManager:removeLoadingAnima()
        local re = cjson.decode(resData.result)
        local coins = tonumber(re.coins)
        local items = {}
        if re.items and #re.items > 0 then
            for i = 1, #re.items do
                local itemData = ShopItem:create()
                itemData:parseData(re.items[i])
                table.insert(items, itemData)
            end
        end
        if _suc then
            _suc(coins, items)
        end
    end
    local function failedCallFunc(target, code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        if _fail then
            _fail()
        end
        gLobalViewManager:showReConnect()
    end
    local actionData = self:getSendActionData(ActionType.EndYearRewardCollect)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFunc, failedCallFunc)
end

return NewYearGiftNet 