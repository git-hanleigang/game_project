
local RespinView = util_require("Levels.RespinView")
local QuickSpinRespinView = class("QuickSpinRespinView",RespinView)


QuickSpinRespinView.SYMBOL_SPECIAL_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1 -- 自定义的小块类型
QuickSpinRespinView.SYMBOL_SUPER_BONUS = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2 -- 自定义的小块类型

function QuickSpinRespinView:readyMove()
      local fixNode =  self:getFixSlotsNode()
      local nBeginAnimTime = 0
      local tipTime = 0

      self:changeTouchStatus(ENUM_TOUCH_STATUS.ALLOW)
      if self.m_startCallFunc then
            self.m_startCallFunc()
      end

end
-- function QuickSpinRespinView:initClipNodes()
      
-- end
function QuickSpinRespinView:runNodeEnd(endNode)
      local aniNode = endNode
      if aniNode.p_symbolType == self.SYMBOL_SPECIAL_BONUS
       or aniNode.p_symbolType == self.SYMBOL_SUPER_BONUS  then
            gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_bonus.mp3")
            -- aniNode:runAnim("buling",false,function(  )
            --       aniNode:runAnim("idleframe",true)
            -- end)
            --[[
                  bugly: buling时间线结束回调执行idleframe时间线时，提示信号的 ccbNode 和 类型 都为nil。
                  这个关卡没有reSpin结束时的收集效果和结束弹板，猜测如果最后一次reSpin滚出了需要buling的信号,那么reSpin释放接口会紧跟着buling逻辑执行。
                  在信号buling期间执行了 SlotsNode:reset() , 不过本地确实难以复现。
                  观察buling的最后一帧和idleframe没有差别，就直接把转播idleframe的逻辑注释掉了。
            ]]
            aniNode:runAnim("buling",false)
      end
end

function QuickSpinRespinView:oneReelDown()
      gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_reel_down.mp3")
end


return QuickSpinRespinView