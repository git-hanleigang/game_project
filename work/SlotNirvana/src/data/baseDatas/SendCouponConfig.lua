--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local SendCouponConfig = class("SendCouponConfig")

SendCouponConfig.p_expire = nil
SendCouponConfig.p_multiple = nil
SendCouponConfig.p_sysTime = nil
SendCouponConfig.p_bIsExist = nil
SendCouponConfig.p_bUpdateFlag = nil
SendCouponConfig.p_vecTickets = nil
function SendCouponConfig:ctor()
    self.p_bIsExist = false
    self.p_maxCoupon = 0
end

function SendCouponConfig:parseData(data, key)
      local ticket = {}
      ticket.multiple = tonumber(data.buffMultiple)
      self.p_maxCoupon = math.max(self.p_maxCoupon, ticket.multiple)
      self.p_expire = data.buffExpire
      self.p_sysTime = os.time()
      if self.p_vecTickets == nil then
            self.p_vecTickets = {}
      end
      self.p_vecTickets[key] = ticket
      self.p_bIsExist = true
      self:updateSendCoupon()
end

function SendCouponConfig:isContainKey(key)
      if self.p_vecTickets == nil then
            return false
      end
      return self.p_vecTickets[key] ~= nil
end

function SendCouponConfig:getCouponMultiple(key)
      if self.p_vecTickets[key] then
            return self.p_vecTickets[key].multiple
      end
      return 0
end

function SendCouponConfig:getSendCouponLeftTime()
      if self.p_bIsExist ~= true then
            return 0
      end
      local times = os.time() - self.p_sysTime
      return self.p_expire - times  -- util_count_down_str
end

function SendCouponConfig:removeSendCoupon()
      self.p_expire = nil
      self.p_multiple = nil
      self.p_sysTime = nil
      self.p_bIsExist = false
      self.p_bUpdateFlag = false
end

function SendCouponConfig:isExist()
      return self.p_bIsExist
end

function SendCouponConfig:updateSendCoupon()
      if self.p_bUpdateFlag ~= true and self.p_timeUpdateHandlerId == nil then
            self.p_bUpdateFlag = true
            self.p_timeUpdateHandlerId = scheduler.scheduleGlobal(function()
                  local leftTime = self:getSendCouponLeftTime()
                  if leftTime <= 0 then
                        self:removeSendCoupon()
                        --屏蔽调用次数可能很多
                        -- G_GetMgr(G_REF.Inbox):getDataMessage()
                        gLobalSendDataManager:getNetWorkFeature():sendQueryShopConfig()
                        if self.p_timeUpdateHandlerId ~= nil then
                              scheduler.unscheduleGlobal(self.p_timeUpdateHandlerId)
                              self.p_timeUpdateHandlerId = nil
                        end
                  end
            end, 1)
      end
end

return  SendCouponConfig