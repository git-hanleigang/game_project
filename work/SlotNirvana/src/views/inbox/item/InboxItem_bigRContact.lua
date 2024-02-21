--[[--
    调查问卷
]]
local InboxItem_bigRContact = class("InboxItem_bigRContact", util_require("views.inbox.item.InboxItem_baseNoReward"))

function InboxItem_bigRContact:getCsbName()
    return "InBox/InboxItem_BigRContact.csb"
end
-- 描述说明
function InboxItem_bigRContact:getDescStr()
    local str = "WANT A DIRECT CONTACT WITH US?\nADD OUR OFFICIAL FACEBOOK\nVIP SERVICE @Jessie Cash"
    if globalData.InboxFbJumpData and globalData.InboxFbJumpData.fbJumpName then
        --跳转名字
        str = "WANT A DIRECT CONTACT WITH US?\nADD OUR OFFICIAL FACEBOOK\nVIP SERVICE @" .. globalData.InboxFbJumpData.fbJumpName
    end
    return str
end

function InboxItem_bigRContact:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_inbox" then
        --判断当前fb登录状态
        if gLobalSendDataManager:getIsFbLogin() == false then
            -- 创建弹板
            local view = util_createView("views.dialogs.BigRContactGoFacebookLayer")
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_NETWORK)
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            local url = globalData.constantData.BIGRCONTACT_URL
            if globalData.InboxFbJumpData and globalData.InboxFbJumpData.fbJumpUrl then
                --fb跳转地址
                url = globalData.InboxFbJumpData.fbJumpUrl
            end
            cc.Application:getInstance():openURL(url)
        end
    end
end

return InboxItem_bigRContact
