--[[
   圣诞聚合 -- 签到
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local AdventCalendarNet = class("AdventCalendarNet", BaseNetModel)

function AdventCalendarNet:sendSignIn(_day)
   local tbData = {
      data = {
         params = {
               day = _day
         }
      }
   }

   gLobalViewManager:addLoadingAnima(false, 1)

   local function successCallFun(resData)
      gLobalViewManager:removeLoadingAnima()

      resData.day = _day
      gLobalNoticManager:postNotification(ViewEventType.ADVENT_CALENDAR_SIGN_IN, resData)
   end

   local function failedCallFun(code, errorMsg)
      gLobalViewManager:removeLoadingAnima()
      gLobalNoticManager:postNotification(ViewEventType.ADVENT_CALENDAR_SIGN_IN)
   end

   self:sendActionMessage(ActionType.HolidayNewChallengeAdventCollectReward, tbData, successCallFun, failedCallFun)
end

function AdventCalendarNet:sendMakeUpSign(_day)
   local tbData = {
      data = {
         params = {
               day = _day
         }
      }
   }

   gLobalViewManager:addLoadingAnima(false, 1)

   local function successCallFun(resData)
      gLobalViewManager:removeLoadingAnima()

      resData.day = _day
      gLobalNoticManager:postNotification(ViewEventType.ADVENT_CALENDAR_SIGN_IN, resData)
   end

   local function failedCallFun(code, errorMsg)
      gLobalViewManager:removeLoadingAnima()
      gLobalNoticManager:postNotification(ViewEventType.ADVENT_CALENDAR_SIGN_IN)
   end

   self:sendActionMessage(ActionType.HolidayNewChallengeAdventRedeemSignIn, tbData, successCallFun, failedCallFun)
end

return AdventCalendarNet
