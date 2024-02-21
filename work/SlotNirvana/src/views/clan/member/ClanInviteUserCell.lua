--[[
Author: cxc
Date: 2021-02-23 10:45:39
LastEditTime: 2021-03-18 14:58:20
LastEditors: Please set LastEditors
Description: 邀请的 人 cell
FilePath: /SlotNirvana/src/views/clan/member/ClanInviteUserCell.lua
--]]
local ClanInviteUserCell = class("ClanInviteUserCell", util_require("base.BaseView"))
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

local btnNomalImgName = "Club/ui/facebook_invite.png"
local btnPressImgName = "Club/ui/facebook_invite2.png"

function ClanInviteUserCell:initUI()
    local csbName = "Club/csd/Invite/ClubInviteList.csb"
    self:createCsbNode(csbName)
    local btnInvite = self:findChild("btn_invite")
    btnInvite:setTouchEnabled(false)
end

function ClanInviteUserCell:updateUI(_searchUserInfo)
    self.m_searchUserInfo = _searchUserInfo

    -- 头像
    local nodeHead = self:findChild("sp_head")
    self:updateHeadUI(nodeHead)

    -- 名字
    local name = _searchUserInfo:getName()
    local lbName = self:findChild("font_name")
    lbName:setString(name)
    util_scaleCoinLabGameLayerFromBgWidth(lbName, 250, 0.8)
    self:createRichText(name, lbName, 1) -- 普通text控件

    -- uid
    local uid = _searchUserInfo:getUid()
    local lbUid = self:findChild("font_id")
    lbUid:setString(uid)
    util_scaleCoinLabGameLayerFromBgWidth(lbUid, 150, 1)
    self:createRichText(uid, lbUid)

    -- 邀请按钮
    self:updateBtnState(_searchUserInfo)

    -- 公会名字
    local layoutName = self:findChild("layout_name")
    local clanName = _searchUserInfo:getTeamName()
    local lbClanName = self:findChild("lb_clanName")
    lbClanName:setString(clanName)
    lbClanName:setVisible(#clanName > 0)    
    -- util_scaleCoinLabGameLayerFromBgWidth(lbClanName, 190, 0.8)
    local layoutNameWidth = layoutName:getContentSize().width
    local lbClanNameWidth = lbClanName:getContentSize().width * lbClanName:getScale()
    if layoutNameWidth < lbClanNameWidth then
        util_wordSwing(lbClanName, 1, layoutName, 3, 30, 3)
    else
        lbClanName:stopAllActions()
        lbClanName:setPositionX((layoutNameWidth-lbClanNameWidth) * 0.5)
    end
end

-- 邀请按钮
function ClanInviteUserCell:updateBtnState(_searchUserInfo)
    local status = _searchUserInfo:getTeamStatus()
    local btnInvite = self:findChild("btn_invite")
    local bCalnInvite = status ~= ClanConfig.userState.MEMBER -- 0：未入会，也未申请；1：未入会，已申请；2：已入会
    btnInvite:setVisible(bCalnInvite)
    self:setButtonLabelDisEnabled("btn_invite", status == ClanConfig.userState.NON) 
end

--[[
description: 改变按钮的 状态
param _type 1:normal 2:press
--]]
function ClanInviteUserCell:setBtnTouchedState(_type)
    -- if _type == 1 then
    --     local btnInvite = self:findChild("btn_invite")
    --     btnInvite:loadTextureNormal(btnNomalImgName)
    -- elseif _type == 2 then
    --     local btnInvite = self:findChild("btn_invite")
    --     btnInvite:loadTextureNormal(btnPressImgName)
    -- end
    local btnInvite = self:findChild("btn_invite")
    self:setButtonLabelAction(btnInvite, _type==2 and true or false)
end

-- 邀请玩家入会
function ClanInviteUserCell:inviteCurUser()
    local udid = self.m_searchUserInfo:getUdid()
    ClanManager:requestUserInvite(udid)
end

-- 更新玩家头像
function ClanInviteUserCell:updateHeadUI(_headParent)
    if tolua.isnull(_headParent) then
        return
    end
    _headParent:removeAllChildren()

    local fbId = self.m_searchUserInfo:getFacebookId()
    local head = self.m_searchUserInfo:getHead()
    local frameId = self.m_searchUserInfo:getFrameId()
    local headSize = _headParent:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, headSize)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    nodeAvatar:addTo(_headParent)
end

-- 创建富文本
function ClanInviteUserCell:createRichText(_handleStr, _refNode, _richType)
    local filterStr = ClanManager:getCurUserSearchStr()

    return ClanManager:createSearchRichText(_handleStr, _refNode, filterStr, _richType)
end

return ClanInviteUserCell