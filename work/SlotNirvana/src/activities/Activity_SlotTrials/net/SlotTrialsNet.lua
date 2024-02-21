--[[

    author:{author}
    time:2021-10-02 20:21:39
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local SlotTrialsNet = class("SlotTrialsNet", util_require("baseActivity.BaseActivityManager"))

function SlotTrialsNet:getInstance()
    if self.instance == nil then
        self.instance = SlotTrialsNet.new()
    end
    return self.instance
end

-- 发送获取字母消息
function SlotTrialsNet:requestReward(taskIndex, successCallFun, failedCallFun)
    if self.isNetting == true then
        return
    end
    self.isNetting = true

    local function successFunc(target, resData)
        local result = util_cjsonDecode(resData.result)
        if result ~= nil then
            local reward_data = {}
            reward_data.coins = 0
            if result.coins and tonumber(result.coins) > 0 then
                reward_data.coins = tonumber(result.coins)
            end
            reward_data.items = {}
            if result.itemList and #result.itemList then
                for i, item_data in ipairs(result.itemList) do
                    if item_data then
                        local shopItem = ShopItem:create()
                        shopItem:parseData(item_data)
                        table.insert(reward_data.items, shopItem)
                    end
                end
            end

            if successCallFun then
                successCallFun(reward_data)
            end
            self.isNetting = false
        else
            if failedCallFun then
                failedCallFun()
            end
            self.isNetting = false
        end
    end

    local function failedFunc(target, errorCode, errorData)
        if failedCallFun then
            failedCallFun()
        end
        self.isNetting = false
    end

    local actionData = self:getSendActionData(ActionType.NewSlotChallengeCollect)
    local params = {}
    params.taskIndex = taskIndex
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedFunc)
end

return SlotTrialsNet
