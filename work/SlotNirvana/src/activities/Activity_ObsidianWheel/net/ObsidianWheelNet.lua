--[[
    -- 活动网络通信模块
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local ObsidianWheelNet = class("ObsidianWheelNet", BaseNetModel)

function ObsidianWheelNet:sendFreeSpinRequest(_success, _fail)
    local tbData = {
        data = {
            params = {
            }
        }
    }    
    local success = function (_result)
        gLobalViewManager:removeLoadingAnima()
        if _result and _result.error then
            if _fail then
                _fail()
            end
            return
        end
        if _success then
            _success(_result)
        end
    end
    local failed = function (errorCode, errorData)
        if _fail then
            _fail()
        end
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end
    gLobalViewManager:addLoadingAnima()
    self:sendActionMessage(ActionType.ShortCardDrawFree, tbData, success, failed)
end

return ObsidianWheelNet