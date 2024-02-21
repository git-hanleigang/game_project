---
-- 有新版本需要更新
--
-- 2019-12-23 17:38:35  修改去掉 later 情况， 这个界面主要是提示强制更新

local NewVersion = class("NewVersion", util_require("base.BaseView"))

function NewVersion:initUI( isForce )

      self:createCsbNode("Dialog/UpdateLayer.csb")
      local root = self:findChild("root")
      if root then
          self:runCsbAction("idle")
          self:commonShow(root,function()

          end)
      else
            self:runCsbAction("show")
      end
      
      self:setButtonLabelContent("btn_update", "UPDATE")

      scheduler.performWithDelayGlobal(function (  )
            self:runCsbAction("idle",true)

      end, 0.7,"NewVersion_Delay")
end


function NewVersion:clickFunc(sender)
      gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

      local name = sender:getName()
      local tag = sender:getTag()
      if name == "btn_update" then

            xcyy.GameBridgeLua:rateUsForSetting()
      end
end

function NewVersion:onKeyBack()

end

function NewVersion:onExit( )
      scheduler.unschedulesByTargetName("NewVersion_Delay")
end

return  NewVersion