-- 隐私协议更新弹板

local PrivacyPolicyUpdateLayer = class("PrivacyPolicyUpdateLayer", BaseLayer)

function PrivacyPolicyUpdateLayer:ctor()
    PrivacyPolicyUpdateLayer.super.ctor(self)
    -- 横屏资源
    self:setLandscapeCsbName("Dialog/PrivacyPolicyUpdate.csb")
end

function PrivacyPolicyUpdateLayer:initCsbNodes()
    local lb_privacy = self:findChild("lb_privacy")
    if not tolua.isnull(lb_privacy) then
        -- lb_privacy:enableUnderline()
        self:addClick(lb_privacy)
    end
    local lb_service = self:findChild("lb_service")
    if not tolua.isnull(lb_service) then
        -- lb_privacy:enableUnderline()
        self:addClick(lb_service)
    end
end

function PrivacyPolicyUpdateLayer:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_ok" then
        self:closeUI(
            function()
                gLobalDataManager:setBoolByField("PrivacyPolicyUpdate", true)
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        )
    elseif name == "lb_privacy" then
        cc.Application:getInstance():openURL(PRIVACY_POLICY)
    elseif name == "lb_service" then
        cc.Application:getInstance():openURL(TERMS_OF_SERVICE)
    end
end

return PrivacyPolicyUpdateLayer
