--[[
    @desc: ATT tan一级弹板
    time:2021-03-16 17:38:42
    陈思超
]]

local BigRContactGoFacebookLayer = class("BigRContactGoFacebookLayer", BaseLayer)

function BigRContactGoFacebookLayer:ctor()
    BigRContactGoFacebookLayer.super.ctor(self)

    self:setLandscapeCsbName("Dialog/BigRContact.csb")
end

function BigRContactGoFacebookLayer:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_ok" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalViewManager:addLoadingAnima(false, nil, 5)
        local callback = function()
            globalData.skipForeGround = true
            gLobalSendDataManager:getNetWorkLogon().m_fbLoginPos=LOG_ENUM_TYPE.BindFB_Settings
            globalFaceBookManager:fbLogin()
        end
        -- 关闭弹板,同时调用底层跳转到设置界面
        self:closeUI(callback)
    elseif senderName == "btn_close" then
        self:closeUI()
    end
end

return BigRContactGoFacebookLayer