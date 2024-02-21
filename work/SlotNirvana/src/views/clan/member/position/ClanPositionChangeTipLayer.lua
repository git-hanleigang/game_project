--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-25 11:16:06
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-25 11:17:19
FilePath: /SlotNirvana/src/views/clan/member/position/ClanPositionChangeTipLayer.lua
Description: 职位变化 玩家提示弹板
--]]
local ClanPositionChangeTipLayer = class("ClanPositionChangeTipLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanPositionChangeTipLayer:initDatas(_type)
    ClanPositionChangeTipLayer.super.initDatas(self)

    self.m_positionType = _type

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/ClubEstablish/ClubNotice_tanban.csb")
    self:setExtendData("ClanPositionChangeTipLayer")
    self:addClickSound("btn_ok", SOUND_ENUM.SOUND_HIDE_VIEW)
end

function ClanPositionChangeTipLayer:initView()
    ClanPositionChangeTipLayer.super.initView(self)

    -- 职位
    self:initPositionStrUI()
end

-- 职位
function ClanPositionChangeTipLayer:initPositionStrUI()
    local lbPosition = self:findChild("lb_position")
    lbPosition:setString(self.m_positionType)
end

function ClanPositionChangeTipLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_ok" then
        self:closeUI()
    end
end

return ClanPositionChangeTipLayer