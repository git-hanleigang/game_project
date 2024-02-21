--[[
Author: cxc
Date: 2021-02-24 14:42:29
LastEditTime: 2021-03-19 16:48:45
LastEditors: Please set LastEditors
Description: 申请 列表 cell
FilePath: /SlotNirvana/src/views/clan/member/ClanApplicantUserCell.lua
--]]
local ClanApplicantUserCell = class("ClanApplicantUserCell", util_require("base.BaseView"))
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

function ClanApplicantUserCell:initUI()
    local csbName = "Club/csd/Application/ClubMemberAppList.csb"
    self:createCsbNode(csbName)
end

function ClanApplicantUserCell:updateUI(_userInfo)
    self.m_userInfo = _userInfo

    -- 头像
    local spHead = self:findChild("sp_head")
    self:updateHeadUI(spHead)

    -- 名字
    local name = _userInfo:getName()
    local lbName = self:findChild("font_name")
    lbName:setString(name)
    util_scaleCoinLabGameLayerFromBgWidth(lbName, 170)

    -- vip
    local vipLevel = _userInfo:getVipLevel() or 1
    local spVip = self:findChild("sp_viplogo")
    local vipImgPath = VipConfig.logo_shop .. vipLevel .. ".png"
    util_changeTexture(spVip, vipImgPath)

    -- 申请时间
    local applyTime = _userInfo:getApplyTime() or 0
    local applyTimeStr = self:getTimeStr(applyTime)
    local lbApplyTime = self:findChild("font_time")
    lbApplyTime:setString(applyTimeStr)
    util_scaleCoinLabGameLayerFromBgWidth(lbApplyTime, 258, 0.8)
end

--[[
description: 改变按钮的 状态
param _btnName 按钮名字
param _type 1:normal 2:press
--]]
function ClanApplicantUserCell:setBtnTouchedState(_btnName, _type)
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
function ClanApplicantUserCell:agreeCurUserJoinClan()
    ClanManager:requestClanApplyAgree(self.m_userInfo:getUdid())
end

-- 拒绝该玩家 入会
function ClanApplicantUserCell:rejectCurUserJoinClan()
    ClanManager:requestClanApplyRefuse(self.m_userInfo:getUdid())
end

-- 更新玩家头像
function ClanApplicantUserCell:updateHeadUI(_headParent)
    if tolua.isnull(_headParent) then
        return
    end
    _headParent:removeAllChildren()

    local fbId = self.m_userInfo:getFacebookId()
    local head = self.m_userInfo:getHead() 
    local frameId = self.m_userInfo:getFrameId()
    local headSize = _headParent:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, headSize)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    nodeAvatar:addTo(_headParent)
end

function ClanApplicantUserCell:getTimeStr(time)
    if time == 0 then
        return ""
    end

    local curTime = math.floor(util_getCurrnetTime()) -- 当前时间戳 s
    local applyTime = math.floor(time * 0.001)
    local diffTime = curTime - applyTime
    diffTime = math.max(0, diffTime)
    if diffTime < 86400 then
        return util_count_down_str(diffTime) .. " AGO"
    elseif diffTime < 172800 then
        return util_daysdemaining1(diffTime, "DAY AGO")
    end
    return util_daysdemaining1(diffTime, "DAYS AGO")
end

return ClanApplicantUserCell
