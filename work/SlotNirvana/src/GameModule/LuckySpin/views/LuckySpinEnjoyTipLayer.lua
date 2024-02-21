--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-05 11:58:28
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-05 14:21:05
FilePath: /SlotNirvana/src/GameModule/LuckySpin/views/LuckySpinEnjoyTipLayer.lua
Description: LuckySpin 先享后付 提示弹板
--]]
local LuckySpinEnjoyTipLayer = class("LuckySpinEnjoyTipLayer", BaseLayer)

function LuckySpinEnjoyTipLayer:ctor(_mainView)
    LuckySpinEnjoyTipLayer.super.ctor(self)
    
    self.m_mainView = _mainView
    self:setLandscapeCsbName("LuckySpin2/LuckySpin_Special_Tanban.csb")
end

function LuckySpinEnjoyTipLayer:onShowedCallFunc()
    LuckySpinEnjoyTipLayer.super.onShowedCallFunc(self)

    self:runCsbAction("idle", true)
end

function LuckySpinEnjoyTipLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        local cb = function()
            self.m_mainView:forceCloseUI()
        end
        self:closeUI(cb)
    elseif name == "btn_spinnow" then
        local cb = function()
            self.m_mainView:onShowEnjoyEvt()
        end
        self:closeUI(cb)
    end
end

return LuckySpinEnjoyTipLayer