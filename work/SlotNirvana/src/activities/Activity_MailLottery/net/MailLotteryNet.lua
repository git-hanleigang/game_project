--[[
    -- 
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local MailLotteryNet = class("MailLotteryNet", BaseNetModel)

-- 领奖
function MailLotteryNet:sendMail(_data,successCallback,failedCallback)
    local tbData = {
        data = {
            params = {
                mail = _data.mail
            }
        }
    }
    gLobalViewManager:addLoadingAnima(false, 1)
    self:sendActionMessage(ActionType.MailLotteryGetMail, tbData, successCallback, failedCallback)
end

return MailLotteryNet
