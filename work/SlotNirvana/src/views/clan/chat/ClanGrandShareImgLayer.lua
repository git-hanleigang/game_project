--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-03 15:25:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-03 15:25:37
FilePath: /SlotNirvana/src/views/clan/chat/ClanGrandShareImgLayer.lua
Description: 关卡grand大奖分享 图片 详情弹板
--]]
local ClanGrandShareImgLayer = class("ClanGrandShareImgLayer", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanGrandShareImgLayer:ctor(_imgPath, _msgId)
    ClanGrandShareImgLayer.super.ctor(self)

    self.m_imgPath = _imgPath
    self.m_msgId = _msgId
    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/Chat_New/Club_grand_share_img_layer.csb")

    local clanData = ClanManager:getClanData()
    self.m_simpleInfo = clanData:getClanSimpleInfo()
end

function ClanGrandShareImgLayer:initView()
    local parent = self:findChild("node_img")
    local sp = G_GetMgr(G_REF.MachineGrandShare):getShareImgSp(self.m_imgPath, cc.size(display.width*0.8, display.height*0.9))
    local size = sp:getContentSize()
    if size.width < size.height then
        -- sp:setRotation(-90)
    end
    parent:addChild(sp)

    gLobalSendDataManager:getLogFeature():sendPopGrandShareImgLog(self.m_msgId, "click", self.m_simpleInfo:getTeamCid(), self.m_simpleInfo:getTeamName())
end

function ClanGrandShareImgLayer:onClickMask()
    gLobalSendDataManager:getLogFeature():sendPopGrandShareImgLog(self.m_msgId, "close", self.m_simpleInfo:getTeamCid(), self.m_simpleInfo:getTeamName())
     self:closeUI()
end

return ClanGrandShareImgLayer