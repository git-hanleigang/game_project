

local AllStarSpin = class("AllStarSpin", 
                        util_require("views.gameviews.SpinBtn"))


AllStarSpin.m_machine = nil                                   ---
--
function AllStarSpin:btnTouchBegan(sender)
      gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)

      self.m_bIsAuto = false

      local Timing = function()

            if globalData.slotRunData.currSpinMode ~= AUTO_SPIN_MODE then
                  --抛出auto spin start
                  self.m_bIsAuto = true
                  self:clearTimingHandler()

                  gLobalNoticManager:postNotification(ViewEventType.AUTO_SPIN_STAR)
                  release_print("STR_TOUCH_SPIN_BTN 触发了 auto spin")
                  if not globalData.slotRunData.m_isNewAutoSpin then
                        gLobalNoticManager:postNotification(ViewEventType.STR_TOUCH_SPIN_BTN)
                  end
                  release_print("btnTouchBegan 触发了 spin touch  " .. xcyy.SlotsUtil:getMilliSeconds())
            end

            self:clearTimingHandler()

      end

      if globalData.slotRunData.currSpinMode == NORMAL_SPIN_MODE then

            if self.m_machine then
                  if self.m_machine.m_InBonus then
                        return
                  end
            end
            
            
            performWithDelay(self,function (  )
                  -- 播放例子
                  if globalData.slotRunData.currSpinMode ~= AUTO_SPIN_MODE then
                  self.m_autoParticleNode:setVisible(true)
                  self.m_autoParticleNode:resetSystem()
                  end
            end,0.2)
            performWithDelay(self,Timing,1)
      end


end

function AllStarSpin:setMachine( machine)

      self.m_machine  = machine

end

return AllStarSpin