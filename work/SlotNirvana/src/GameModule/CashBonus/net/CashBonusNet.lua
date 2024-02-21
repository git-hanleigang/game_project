-- CashBonus 消息处理

local NetWorkBase = util_require("network.NetWorkBase")
local BaseNetModel = require("net.netModel.BaseNetModel")
local CashBonusNet = class("CashBonusNet", BaseNetModel)

-- 返回bonus 网络消息发送时的类型
function CashBonusNet:getName(bonusType)
    if bonusType == CASHBONUS_TYPE.BONUS_WHEEL then
        return "WheelDaily"
    end
    return ""
end

---------------------------------- 网络协议迁移 ------------------------------------
-- 目前只针对每日轮盘 收集发送协议
function CashBonusNet:sendActionCashBonus(_bonusType, _isWatchAds)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successCallFun = function(data)
        local act_data = G_GetMgr(G_REF.CashBonus):getRunningData()
        if act_data then
            act_data:parseWheelData(data, false)
        end
        if data.extend and data.extend.highLimit then -- 解析高倍场数据
            globalData.syncDeluexeClubData(data.extend.highLimit)
        end
        if G_GetMgr(G_REF.Flower) and data.extend and data.extend.flowerCoins then
            G_GetMgr(G_REF.Flower):setFlowerCoins(data.extend.flowerCoins)
        end

        gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_COLLECT_ACTION_CALLBACK, {success = true, bonusType = _bonusType})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ADS_REWARDS_END)
    end

    local failedCallFun = function()
        gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_COLLECT_ACTION_CALLBACK, {success = false})
    end

    local proto_data = {}
    proto_data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    proto_data.balanceGems = 0
    proto_data.levelup = false
    proto_data.exp = globalData.userRunData.currLevelExper
    proto_data.level = globalData.userRunData.levelNum
    proto_data.version = NetWorkBase:getVersionNum()
    proto_data.rewardGems = 0
    proto_data.addExp = 0

    local params = {}
    params["name"] = self:getName(_bonusType)
    params["type"] = "wheel" -- 轮盘类型
    --if _bonusType == CASHBONUS_TYPE.BONUS_SILVER or _bonusType == CASHBONUS_TYPE.BONUS_MONEY or _bonusType == CASHBONUS_TYPE.BONUS_GOLD then
    --    params["type"] = "treasury"
    --end
    if _isWatchAds then
        params["watchVideo"] = 1
    end
    proto_data.params = params
    self:sendActionMessage(ActionType.CashBonusCollect, {data = proto_data}, successCallFun, failedCallFun)
end

--cashvault 收集
function CashBonusNet:sendActionCashVaultCollect(_type, _showCoins)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnimaDelay()
    local successCallFun = function(resData)
        gLobalViewManager:removeLoadingAnima()
        if resData and table.nums(resData) > 0 then
            G_GetMgr(G_REF.CashBonus):parseCashVaultGame(resData)
        end

        gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_VAULT_COLLECT_CALLBACK, {success = true, type = resData.type})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        -- gLobalViewManager:showReConnect()

        gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_VAULT_COLLECT_CALLBACK, {success = false})
    end

    local tbData = {
        data = {
            params = {
                type = _type,
                showCoins = _showCoins
            }
        }
    }
    self:sendActionMessage(ActionType.CashVaultCollect, tbData, successCallFun, failedCallFun)
end

-- cashbonus钞票小游戏 try take 请求接口修改
function CashBonusNet:sendActionCashMoneyRequest(act_type)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnimaDelay()

    local successCallFun = function(resData)
        gLobalViewManager:removeLoadingAnima()
        if resData and table.nums(resData) > 0 then
            if act_type == ActionType.MegaCashPlay then
                G_GetMgr(G_REF.CashBonus):parseMegaData(resData)
            elseif act_type == ActionType.MegaCashCollect then
                G_GetMgr(G_REF.CashBonus):parseMegaData(resData)
            end
        end
        gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_CASHMONEY_CALLBACK, {success = true, type = act_type})
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_CASHMONEY_CALLBACK, {success = false, type = act_type})
    end

    local params = {}
    self:sendActionMessage(act_type, params, successCallFun, failedCallFun)
end

-- 刷新倍增器 如果在DailyBonus 界面 则关闭时刷新
function CashBonusNet:refreshMultiply(func)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successCallFun = function(resData)
        if resData and table.nums(resData) > 0 then
            G_GetMgr(G_REF.CashBonus):parseMultipleData(resData)
            gLobalNoticManager:postNotification(ViewEventType.CASHBONUS_UPDATE_MULTIPLE)
            if func then
                func()
            end
        end
    end

    local failedCallFun = function()
        if func then
            func()
        end
    end

    local params = {}
    self:sendActionMessage(ActionType.CashBonusMultiply, params, successCallFun, failedCallFun)
end

return CashBonusNet
