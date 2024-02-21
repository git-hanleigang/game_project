--升级界面

local FbLoginReward = class("FbLoginReward", util_require("base.BaseView"))
function FbLoginReward:initUI()
    self:createCsbNode("Logon/LogonLoginReward.csb")
    self.m_lb_coin = self:findChild("lab_coin")
    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(root,function()
        end)
    else
        self:runCsbAction("show",false)
    end

    globalData.userRunData.isGetFbReward = true
    local _coins = globalData.userRunData.coinNum + globalData.userRunData.FB_LOGIN_FIRST_REWARD
    globalData.userRunData:setCoins(_coins)
    self.m_lb_coin:setString(util_formatCoins(globalData.userRunData.FB_LOGIN_FIRST_REWARD,15))
end

function FbLoginReward:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
      local name = sender:getName()
      local tag = sender:getTag()
      if name == "Button_1" then
            local root = self:findChild("root")
            if root then
                self:commonHide(root,function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                    self:removeFromParent()
                end)
            else
                self:runCsbAction("over",false, function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum)
                    self:removeFromParent()
                end)
            end
      end
end


return FbLoginReward