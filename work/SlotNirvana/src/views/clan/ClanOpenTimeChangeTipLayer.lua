--[[
Author: cxc
Date: 2022-03-22 11:12:33
LastEditTime: 2022-03-22 11:15:09
LastEditors: cxc
Description: 公会 宝箱开启时间改变  tip 弹板
FilePath: /SlotNirvana/src/views/clan/ClanOpenTimeChangeTipLayer.lua
--]]
local ClanOpenTimeChangeTipLayer = class("ClanOpenTimeChangeTipLayer", BaseLayer)

function ClanOpenTimeChangeTipLayer:ctor()
    ClanOpenTimeChangeTipLayer.super.ctor(self)
    self:setKeyBackEnabled(true)
    self:setExtendData("ClanOpenTimeChangeTipLayer")
    self:setLandscapeCsbName("Club/csd/RANK/Club_Time.csb")
end

function ClanOpenTimeChangeTipLayer:onShowedCallFunc()
    self:runCsbAction("start")
end

function ClanOpenTimeChangeTipLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return ClanOpenTimeChangeTipLayer