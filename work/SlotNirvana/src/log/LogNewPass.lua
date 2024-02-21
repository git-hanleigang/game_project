--
-- 发送 iap消息
-- Author:{ZKK}
-- Date: 2022-04-13 18:13:45
--
local NetworkLog = require "network.NetworkLog"
local LogNewPass = class("LogNewPass",NetworkLog)


function LogNewPass:ctor()
      NetworkLog.ctor(self)
end

function LogNewPass:sendLogMessage( ... )
      local args = {...}
      --TODO 在这里组织你感兴趣的数据

      NetworkLog.sendLogData(self)
end

--[[
	payType:普通Pass Normal ,高级Pass Adv
	actionType:界面打开方式
]]
function LogNewPass:sendPassLog( actionType,payType )
	assert( actionType," !! pageOpenType is nil !! " )
	-- 发送数据
	if actionType then
		local gameData = G_GetActivityDataByRef(ACTIVITY_REF.NewPass)
		if not gameData or not gameData:isRunning() then
			return
		end
		local log_data = {}
		log_data.tp = actionType
		if payType then
			log_data.ptp = payType
		end
		log_data.en = "PassSecondPopup"
		gL_logData:syncEventData("PassPopup")
		gL_logData.p_data = log_data
		self:sendLogData()
	end
end
return  LogNewPass