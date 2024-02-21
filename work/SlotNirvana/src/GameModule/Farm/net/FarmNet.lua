--[[
    author:JohnnyFred
    time:2020-06-15 14:44:50
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local FarmNet = class("FarmNet", BaseNetModel)

function FarmNet:getInstance()
    if self.instance == nil then
        self.instance = FarmNet.new()
    end
    return self.instance
end

function FarmNet:sendSowing(_cropId, _lands)
    local tbData = {
        data = {
            params = {
                crop = _cropId,
                lands = _lands
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_SOWING, {crop = _cropId, lands = _lands})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_SOWING, {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmSowing, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendHarvest(_lands)
    local tbData = {
        data = {
            params = {
                lands = _lands
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_HARVEST, {lands = _lands, resData = resData})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_HARVEST, {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmHarvest, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendExpedite(_landId, _gem)
    local tbData = {
        data = {
            params = {
                land = _landId,
                gem = _gem
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_EXPEDITE, {landId = _landId})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_EXPEDITE)
    end

    self:sendActionMessage(ActionType.FarmRipen, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendSell(_wares)
    local tbData = {
        data = {
            params = {
                id = _wares.id,
                num = _wares.num,
                type = _wares.type
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_SELL, resData)
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_SELL, {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmSell, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendBuySeed(_cropID, _num)
    local tbData = {
        data = {
            params = {
                crop = _cropID,
                num = _num
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_BUY_SEED, resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_BUY_SEED, {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmBuy, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendFarmInfoUpdate(_name)
    local tbData = {
        data = {
            params = {
                name = _name
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_SET_NAME, resData)
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_SET_NAME)
    end

    self:sendActionMessage(ActionType.FarmInfoUpdate, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendDailyReward()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        if not resData or resData.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_DAILY_REWARD)
        end

        resData.type = "dailyReward"
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_DAILY_REWARD, resData)
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_DAILY_REWARD)
    end

    self:sendActionMessage(ActionType.FarmDailyRewardCollect, tbData, successCallFun, failedCallFun)
end

-- _friendType: 1-公会，2-陌生人，3-好友    _openType：1-打开界面，2-刷新界面
function FarmNet:sendFriends(_friendType, _openType, _redPoints)
    local tbData = {
        data = {
            params = {
                type = _friendType,
                redPoints = _redPoints
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_FRIENDS, {resData = resData, friendType = _friendType, openType = _openType})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_FRIENDS, {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmFriends, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendOthersFarm(_othersData, _type)
    local tbData = {
        data = {
            params = {
                udid = _othersData.udid,
                type = _type
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_OTHERS_FARM, {resData = resData, othersData = _othersData, type = _type})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_OTHERS_FARM,  {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmFriendFarm, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendStealRecord(_redPoints)
    local tbData = {
        data = {
            params = {
                redPoints = _redPoints
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        local farmData = G_GetMgr(G_REF.Farm):getRunningData()
        if farmData and resData then
            local redPoint = farmData:saveRecords(resData.records)
            local redList = resData.redPoints or {0, 0, 0, 0}
            redList[4] = redPoint
            resData.redPoints = redList
        end

        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_STEAL_RECORD, {resData = resData, friendType = 3, openType = 2})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_STEAL_RECORD,  {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmStealRecord, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendSteal(_udid, _type, _landId, _initTime)
    local tbData = {
        data = {
            params = {
                udid = _udid,
                type = _type,
                land = _landId,
                group = _initTime
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_STEAL, {resData = resData, landId = _landId})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_STEAL,  {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmSteal, tbData, successCallFun, failedCallFun)
end

function FarmNet:sendLandUnlock(_landId)
    local tbData = {
        data = {
            params = {
                land = _landId
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_LAND_UNLOCK, {landId = _landId})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_LAND_UNLOCK, {code = code, errorMsg = errorMsg})
    end

    self:sendActionMessage(ActionType.FarmLandUnlock, tbData, successCallFun, failedCallFun)
end

-- 新手引导
function FarmNet:sendGuide(_saveData, _type)
    local tbData = {
        data = {
            params = {
                saveData = _saveData,
                type = _type or 0 -- 1是偷取引导
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        if _type and _type == 1 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_FARM_STEAL_GUIDE_SUC, resData)
        end
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    self:sendActionMessage(ActionType.FarmGuide, tbData, successCallFun, failedCallFun)
end

return FarmNet
