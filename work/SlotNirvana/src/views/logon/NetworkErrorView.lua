--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-11-22 19:02:13
--

local NetworkErrorView = class("NetworkErrorView", util_require("base.BaseView"))

NetworkErrorView.m_okFunc = nil



function NetworkErrorView:initUI(csb_path, okFunc)

      self.m_okFunc = okFunc
      local isAutoScale =true
      if CC_RESOLUTION_RATIO==3 then
          isAutoScale=false
      end
      self:createCsbNode(csb_path, isAutoScale)
      local root = self:findChild("root")
      if root then
            self:runCsbAction("idle")
                  self:commonShow(root,function()
            end)
      else
            self:runCsbAction("show")
      end
  end

function NetworkErrorView:clickFunc(sender)
      local name = sender:getName()
      local tag = sender:getTag()
      gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

      if name == "btn_ok" then
            --点击OK按钮回调
            if self.m_okFunc ~= nil then
                  local root = self:findChild("root")
                  if root then
                      self:commonHide(root,function()
                        self.m_okFunc()

                        self:removeFromParent()
                      end)
                  end
            end
      end
end

return  NetworkErrorView