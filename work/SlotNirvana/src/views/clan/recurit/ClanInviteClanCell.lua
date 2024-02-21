--[[
Author: cxc
Date: 2021-02-26 11:53:29
LastEditTime: 2021-03-10 12:25:15
LastEditors: Please set LastEditors
Description: 公会邀请列表 cell
FilePath: /SlotNirvana/src/views/clan/recurit/ClanInviteClanCell.lua
--]]
local ClanInviteClanCell = class("ClanInviteClanCell", util_require("base.BaseView"))
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanConfig = util_require("data.clanData.ClanConfig")

-- local btnImgList = {
--     btn_agree = {
--         "Club/ui/anniu_agree.png",
--         "Club/ui/anniu_agree2.png"
--     },
--     btn_refuse = {
--         "Club/ui/anniu_refuse.png",
--         "Club/ui/anniu_refuse1.png"
--     }
-- }

function ClanInviteClanCell:initUI()
    local csbName = "Club/csd/Invite/ClubTeamInviteList.csb"
    self:createCsbNode(csbName)
end

function ClanInviteClanCell:updateUI(_inviteInfo)
    self.m_inviteUdid = _inviteInfo:getInviteUdid()
    
    local _clanInfo = _inviteInfo:getClanBaseInfo()
    self.m_clanInfo = _clanInfo

    -- 头像
    local clanLogo = _clanInfo:getTeamLogo()
    local spClanIconBg = self:findChild("sp_clanBg")
    local spClanLogo = self:findChild("sp_clanLogo")
    local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
    local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
    util_changeTexture(spClanIconBg, imgBgPath)
    util_changeTexture(spClanLogo, imgPath)

    -- 名字
    local name = _clanInfo:getTeamName()
    local lbName = self:findChild("font_name")
    lbName:setString(name)
    util_scaleCoinLabGameLayerFromBgWidth(lbName, 352, 0.8)

    -- 人数
    local curMCount = _clanInfo:getCurMemberCount()
    local maxMCount = _clanInfo:getLimitMemberCount()
    local lbMemberCount = self:findChild("font_renshu")
    lbMemberCount:setString(curMCount .. "/" .. maxMCount)
end

--[[
description: 改变按钮的 状态
param _btnName 按钮名字
param _type 1:normal 2:press
--]]
function ClanInviteClanCell:setBtnTouchedState(_btnName, _type)
    if not _btnName or not _type then
        return
    end
    
    local btn = self:findChild(_btnName)
    if tolua.isnull(btn) then
        return
    end
    -- local imgPath = btnImgList[_btnName][_type]
    -- if not imgPath then
    --     return
    -- end
    -- btn:loadTextureNormal(imgPath)
    self:setButtonLabelAction(btn, _type==2 and true or false)
end

-- 同意该玩家 入会
function ClanInviteClanCell:agreeCurUserJoinClan()
    ClanManager:requestClanJoin(self.m_clanInfo:getTeamCid())
end

-- 拒绝该玩家 入会
function ClanInviteClanCell:rejectCurUserJoinClan()
    ClanManager:requestRejectInviteClan(self.m_inviteUdid)
end

return ClanInviteClanCell