--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-18 15:25:07
--
local ShopGift = class("ShopGift")
require("socket")
ShopGift.p_rewadCoin = nil  -- 奖励金币
ShopGift.p_coolDown = nil -- 倒计时时间

ShopGift.p_coolDownHandlerId = nil
ShopGift.m_loaclLastTime = nil --本地时间用来计算时间间隔
function ShopGift:ctor()
    
end

function ShopGift:checkUpdateCoolDown( )
      if self.p_coolDownHandlerId ~= nil then
            scheduler.unscheduleGlobal(self.p_coolDownHandlerId)
            self.p_coolDownHandlerId = nil
      end

      if self.p_coolDown > 0 then
            self.m_loaclLastTime = socket.gettime()
            self.p_coolDownHandlerId = scheduler.scheduleGlobal(function (  )
                  local delayTime = 1
                  if self.m_loaclLastTime then
                        local spanTime = socket.gettime()-self.m_loaclLastTime
                        self.m_loaclLastTime = socket.gettime()
                        if spanTime>0 then
                              delayTime = spanTime
                        end
                  end
                  self.p_coolDown = self.p_coolDown - delayTime
                  if self.p_coolDown <= 0 then
                        self.p_coolDown = 0
                        scheduler.unscheduleGlobal(self.p_coolDownHandlerId)
                        self.p_coolDownHandlerId = nil
                  end
            end,1)
      end

end

return  ShopGift