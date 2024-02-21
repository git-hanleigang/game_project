--[[
   圣诞聚合 -- 商店
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local HolidayStoreNet = class("HolidayStoreNet", BaseNetModel)

-- 兑换
function HolidayStoreNet:storeExchange(data,successFunc,failedFunc)
   local _seq = data.data:getSeq()
   --local params = {seq = _seq,num = data.num}
   local tbData = {
      data = {
         params = {
            seq = _seq,num = data.num
         }
      }
   }
   gLobalViewManager:addLoadingAnima()
  self:sendActionMessage(ActionType.HolidayNewChallengeGoodsPurchase,tbData,successFunc,failedFunc)
end

-- 购买促销
function HolidayStoreNet:buySale(_data,success, fail)
   if not _data then
       return
   end

   gLobalSaleManager:purchaseGoods(
       BUY_TYPE.HOLIDAY_NEW_STORE_SALE, 
       _data.keyId,
       tostring(_data.price),
       0,
       0,
       success,
       fail
   )
end

return HolidayStoreNet
