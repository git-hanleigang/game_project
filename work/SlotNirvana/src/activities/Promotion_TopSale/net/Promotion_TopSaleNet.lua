local BaseNetModel = require("net.netModel.BaseNetModel")
local Promotion_TopSaleNet = class("Promotion_TopSaleNet", BaseNetModel)

function Promotion_TopSaleNet:getInstance()
    if self.instance == nil then
        self.instance = Promotion_TopSaleNet.new()
    end
    return self.instance
end

function Promotion_TopSaleNet:afterCloseBuyView()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    local successCallback = function (_result)
        if not _result or _result.error then 
            return
        end
        local activityData = G_GetMgr(ACTIVITY_REF.Promotion_TopSale):getRunningData()
        if activityData then
            activityData:changeToDirty()
        end
    end

    local failedCallback = function (errorCode, errorData)

    end

    self:sendActionMessage(ActionType.StoreUpscaleSaleUpdate,tbData,successCallback,failedCallback)
end


return Promotion_TopSaleNet