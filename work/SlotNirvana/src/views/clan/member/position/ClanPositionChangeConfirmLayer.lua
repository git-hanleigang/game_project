--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-10-21 17:25:00
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-10-21 17:25:13
FilePath: /SlotNirvana/src/views/clan/member/position/ClanPositionChangeConfirmLayer.lua
Description: 会长 任命成员职位 确认弹板
--]]
local ClanPositionChangeConfirmLayer = class("ClanPositionChangeConfirmLayer", BaseLayer)
local ClanConfig = util_require("data.clanData.ClanConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanPositionChangeConfirmLayer:initDatas(_memberData, _type)
    ClanPositionChangeConfirmLayer.super.initDatas(self)

    self.m_memberData = _memberData
    self.m_positionType = _type

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/ClubEstablish/Club_Confirm.csb")
    self:setExtendData("ClanPositionChangeConfirmLayer")
    self:addClickSound({"btn_no", "btn_yes"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function ClanPositionChangeConfirmLayer:initView()
    ClanPositionChangeConfirmLayer.super.initView(self)

    -- 成员名
    self:initMemberNameUI()
    -- 职位
    self:initPositionStrUI()
    -- 提示文本
    self:initDescTipUI()
end

-- 成员名
function ClanPositionChangeConfirmLayer:initMemberNameUI()
    local lbName = self:findChild("lb_name")
    lbName:setString(self.m_memberData:getName())
    util_scaleCoinLabGameLayerFromBgWidth(lbName, 368, 1)
end

-- 职位
function ClanPositionChangeConfirmLayer:initPositionStrUI()
    local lbPosition = self:findChild("lb_position")
    lbPosition:setString(self.m_positionType)
end

 -- 提示文本
 function ClanPositionChangeConfirmLayer:initDescTipUI()
    local lbElite = self:findChild("lb_desc_elite")
    local lbLeader = self:findChild("lb_desc_leader")
   
    lbElite:setVisible(self.m_positionType == ClanConfig.userIdentity.ELITE)
    lbLeader:setVisible(self.m_positionType == ClanConfig.userIdentity.LEADER)
end

function ClanPositionChangeConfirmLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_yes" then
        if self.m_positionType == ClanConfig.userIdentity.LEADER then
            ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.LEADER_POSITION_CHANGE_TIP, util_node_handler(self, self.sendChangePositionReq))
            return
        end
        self:sendChangePositionReq()
    elseif name == "btn_no" or name == "btn_close" then
        self:closeUI()
    end
end

-- 发送改变 成员职位
function ClanPositionChangeConfirmLayer:sendChangePositionReq()
    local cUdid = self.m_memberData:getUdid()
    ClanManager:sendChangePositionReq(cUdid, self.m_positionType)
end

-- 注册事件
function ClanPositionChangeConfirmLayer:registerListener(  )
    ClanPositionChangeConfirmLayer.super.registerListener(self)
    gLobalNoticManager:addObserver(self, "closeUI", ClanConfig.EVENT_NAME.RECIEVE_CHANGE_MEMBER_POSITION)
end


return ClanPositionChangeConfirmLayer