---
-- 有新版本需要更新
--

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_update = class("InboxItem_update", InboxItem_base)

function InboxItem_update:initData()
      InboxItem_update.super.initData(self)
      self.m_coins:setNum(3000000)
end

function InboxItem_update:getCsbName()
      return "InBox/InboxItem_update.csb"
end

-- 描述说明
function InboxItem_update:getDescStr()
      return "UPDATE FOR THE GIFT"
end

function InboxItem_update:clickFunc(sender)
      gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

      local name = sender:getName()
      local tag = sender:getTag()
      if name == "btn_inbox" then
            xcyy.GameBridgeLua:rateUsForSetting()
      end
end

return  InboxItem_update