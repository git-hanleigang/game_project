---
--island
--2019年3月14日
--InboxItem_facebook.lua


local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_facebook = class("InboxItem_facebook",InboxItem_base)

function InboxItem_facebook:getCsbName()
    return "InBox/InboxItem_facebook.csb"
end

function InboxItem_facebook:initView()
    self:initReward()
    self:initDesc()
end

function InboxItem_facebook:initReward()
    -- 金币
    self.m_uiList = {}
    local strCoins = util_formatCoins(globalData.FBRewardData:getCoins(),6)
    self.m_lb_coin:setString(strCoins)
    local size = self.m_sp_coin:getContentSize()
    local scale = self.m_sp_coin:getScale()
    table.insert(self.m_uiList, {node = self.m_sp_coin, alignX = -size.width/2*scale})
    table.insert(self.m_uiList, {node = self.m_lb_coin, alignX = 5.5})
    table.insert(self.m_uiList, {node = self.m_lb_add, alignX = 3.5})
    local sp = util_createSprite("InBox/ui/fb_sale.png")
    self.m_node_reward:addChild(sp)
    table.insert(self.m_uiList, {node = sp, alignX = 3.5})
    self:alignLeft(self.m_uiList)
end

function InboxItem_facebook:initDesc()
    self.m_lb_desc:setString("LOGIN WITH FACEBOOK")
end

function InboxItem_facebook:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_inbox" then

        if gLobalSendDataManager:getIsFbLogin() == true then
            return
        end
        gLobalViewManager:addLoadingAnima(false, nil, 5)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        performWithDelay(
            self,
            function()
                self:fbBtnTouchEvent()
            end,
            0.2
        )
    end
end
-- fb 点击事件
function InboxItem_facebook:fbBtnTouchEvent()
    if gLobalSendDataManager:getIsFbLogin() == false then
        if globalFaceBookManager:getFbLoginStatus() then
            release_print("xcyy : FbLoginStatus")
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon():FBLoginGame(LOG_ENUM_TYPE.BindFB_Inbox)
        else
            globalFaceBookManager:fbLogin()
            release_print("xcyy : FbLoginStatus fail")
        end
    else
        globalFaceBookManager:fbLogOut()
        gLobalSendDataManager:getNetWorkLogon():logoutGame()
    end
end

function InboxItem_facebook:getLanguageTableKeyPrefix()
    return nil
end

return InboxItem_facebook
