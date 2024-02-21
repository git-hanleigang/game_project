--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-08 10:30:44
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-08 10:31:00
FilePath: /SlotNirvana/src/views/clan/rush/ClanRushTaskGiftUI.lua
Description: 公会rush 任务礼盒
--]]
local ClanRushTaskGiftUI = class("ClanRushTaskGiftUI", BaseView)

function ClanRushTaskGiftUI:initUI(_bEntry)
    ClanRushTaskGiftUI.super.initUI(self)
    
    self.m_bEntry = _bEntry
    self:runCsbAction("idle", true)
end

function ClanRushTaskGiftUI:updateUI(_idx, _bFinish)

    for i=1,3 do
        local node = self:findChild("sp_icon_" .. i)
        node:setVisible(_idx == i)
    end
    if _bFinish then
        self:runCsbAction(self.m_bEntry and "normalIdle" or "overIdle", true)
    end
end

function ClanRushTaskGiftUI:getCsbName()
    return "Club/csd/Rush/node_rush_gift.csb"
end

return ClanRushTaskGiftUI