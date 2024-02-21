--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-04 15:17:21
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-04 17:19:16
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/views/TomorrowGiftMainButtonUI.lua
Description: 次日礼物主界面  按钮UI
--]]
local TomorrowGiftMainButtonUI = class("TomorrowGiftMainButtonUI", BaseView)

function TomorrowGiftMainButtonUI:getCsbName()
    return "Activity/TomorrowGift/csb/TomorrowGift_button.csb"
end

function TomorrowGiftMainButtonUI:initUI(_mainLayer, _bUnlock)
    TomorrowGiftMainButtonUI.super.initUI(self)

    self._mainLayer = _mainLayer
    self:updateBtnTextUI(_bUnlock)
end

function TomorrowGiftMainButtonUI:updateBtnTextUI(_bUnlock)
    local str = "GO SPINNING"
    if _bUnlock then
        str = "COLLECT"
    end
    self.m_bUnlock = _bUnlock
    self:setButtonLabelContent("btn_collect", str)
end

function TomorrowGiftMainButtonUI:clickFunc(_sender)
    local name = _sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_collect" then
        if self.m_bUnlock then
            G_GetMgr(G_REF.TomorrowGift):sendCollectReq() 
        else
            self._mainLayer:closeUI()
        end
    end
end

return TomorrowGiftMainButtonUI