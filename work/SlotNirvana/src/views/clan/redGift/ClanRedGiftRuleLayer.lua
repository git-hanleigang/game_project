--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-07 16:15:16
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-07 16:15:32
FilePath: /SlotNirvana/src/views/clan/redGift/ClanRedGiftRuleLayer.lua
Description: 公会送红包 规则界面
--]]
local ClanRedGiftRuleLayer = class("ClanRedGiftRuleLayer", BaseLayer)

function ClanRedGiftRuleLayer:ctor()
    ClanRedGiftRuleLayer.super.ctor(self)

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/Gift/Gift_Rule.csb")
end

function ClanRedGiftRuleLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return ClanRedGiftRuleLayer
