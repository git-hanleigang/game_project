--
-- 发送 iap消息
-- Author:{author}
-- Date: 2019-05-16 18:13:45
--
local NetworkLog = require "network.NetworkLog"
local LogScore = class("LogScore",NetworkLog)


function LogScore:ctor()
      NetworkLog.ctor(self)
end

function LogScore:sendLogMessage( ... )
      local args = {...}
      --TODO 在这里组织你感兴趣的数据

      NetworkLog.sendLogData(self)
end

function LogScore:sendScoreLog(p_type,p_site,p_pageName,p_pageOrder,p_grade,p_rewardCoins)
      gL_logData:syncUserData()
      gL_logData:syncEventData("Score")
      local messageData = {}
      if p_type then
            messageData.type = p_type
      end
      if p_site then
            messageData.site = p_site
      end
      if p_pageName then
            messageData.pageName = p_pageName
      end
      if p_pageOrder then
            messageData.pageOrder = p_pageOrder
      end
      if p_grade then
            messageData.grade = p_grade
      end
      if p_rewardCoins then
            messageData.rewardCoins = p_rewardCoins
      end
      -- 弹出RateUs评价的次数
      messageData.condition = globalData.rateUsData.m_rateUsCount or 0
      gL_logData.p_data = messageData
      self:sendLogData()
end

return  LogScore