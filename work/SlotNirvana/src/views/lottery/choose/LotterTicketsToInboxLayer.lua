--[[
Author: your name
Date: 2021-11-23 11:38:49
LastEditTime: 2021-11-23 11:39:16
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/choose/LotterTicketsToInboxLayer.lua
--]]
local LotterTicketsToInboxLayer = class("LotterTicketsToInboxLayer", BaseLayer)

function LotterTicketsToInboxLayer:ctor()
    LotterTicketsToInboxLayer.super.ctor(self)
    
    self:setPauseSlotsEnabled(true) 
    self:setKeyBackEnabled(true)
    self:setExtendData("LotterTicketsToInboxLayer")
    self:setLandscapeCsbName("Lottery/csd/Lottery_choose_tanban2.csb")
end

function LotterTicketsToInboxLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_yes" then
        self:closeUI()
    end
end

return LotterTicketsToInboxLayer