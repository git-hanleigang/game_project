--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-04-14 14:46:47
    describe:10M每日任务送优惠券网络模块
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CouponChallengeNet = class("CouponChallengeNet", BaseNetModel)

-- 请求砸锤子
function CouponChallengeNet:requestBreak(_successCallback, _failCallback, _params)
    local tbData = {
        data = {
            params = _params
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if not _result or _result.error then
            if _failCallback then
                _failCallback()
            end
            return
        end

        if _successCallback then
            _successCallback(_result)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failCallback then
            _failCallback()
        end
    end

    self:sendActionMessage(ActionType.SmashHammerSmashIt, tbData, successCallback, failedCallback)
end

-- 积分商店兑换
function CouponChallengeNet:requestExchange(_successCallback, _failCallback, _params)
    local tbData = {
        data = {
            params = _params
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if _successCallback then
            _successCallback(_result)
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failCallback then
            _failCallback()
        end
    end

    self:sendActionMessage(ActionType.SmashHammerRewordExchange, tbData, successCallback, failedCallback)
end

-- 积分商店刷新
function CouponChallengeNet:requestShopRefresh(_successCallback, _failCallback, _params)
    local tbData = {
        data = {
            params = _params
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        if _successCallback then
            _successCallback()
        end
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if _failCallback then
            _failCallback()
        end
    end

    self:sendActionMessage(ActionType.SmashHammerPointsShopReset, tbData, successCallback, failedCallback)
end

return CouponChallengeNet
