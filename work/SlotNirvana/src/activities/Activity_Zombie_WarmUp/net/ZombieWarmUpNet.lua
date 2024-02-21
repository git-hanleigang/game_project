--[[--
    行尸走肉预热活动
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local ZombieWarmUpNet = class("ZombieWarmUpNet", BaseNetModel)


-- Prebook:参加预约
-- Config:拉取最新活动数据
function ZombieWarmUpNet:requestZombie(_type, _succ, _fail)
    local tbData = {
        data = {
            params = {
                type = _type
            }
        }
    }
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then 
            if _fail then
                _fail()
            end
            return
        end
        if _succ then
            _succ()
        end
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        if _fail then
            _fail()
        end
    end

    self:sendActionMessage(ActionType.ZombiePrebookConfig, tbData, successCallback, failedCallback)
end

return ZombieWarmUpNet
