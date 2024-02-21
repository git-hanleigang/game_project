--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local FlamingoJackpotNet = class("FlamingoJackpotNet", BaseNetModel)

-- function FlamingoJackpotNet:requestStart(_key, _levelName, successCallFun, failedCallFun)
--     gLobalViewManager:addLoadingAnimaDelay()
--     local failedFunc = function(p1, p2, p3)
--         gLobalViewManager:removeLoadingAnima()
--         if failedCallFun then
--             failedCallFun()
--         end
--     end
--     local successFunc = function(resJson)
--         gLobalViewManager:removeLoadingAnima()
--         local result = util_cjsonDecode(resJson.result)
--         if result ~= nil and result ~= "" and result["error"] ~= nil then
--             -- assert(false, result["error"])
--             if failedCallFun then
--                 failedCallFun()
--             end
--             return
--         end
--         if successCallFun then
--             successCallFun(resJson)
--         end
--     end
--     local tbData = {
--         data = {
--             params = {}
--         }
--     }
--     tbData.data.params.key = _key
--     tbData.data.params.game = _levelName
--     self:sendActionMessage(ActionType.JillionJackpotPlay, tbData, successFunc, failedFunc)
-- end

return FlamingoJackpotNet
