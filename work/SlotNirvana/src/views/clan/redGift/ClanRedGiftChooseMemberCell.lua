--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-08 11:54:05
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-08 11:54:26
FilePath: /SlotNirvana/src/views/clan/redGift/ClanRedGiftChooseMemberCell.lua
Description:  公会红包  选择赠送成员 cell
--]]
local ClanRedGiftChooseMemberCell = class("ClanRedGiftChooseMemberCell", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRedGiftChooseMemberCell:getCsbName()
    return "Club/csd/Gift/Gift_Buy_information.csb"
end

function ClanRedGiftChooseMemberCell:initUI(_memberData)
    ClanRedGiftChooseMemberCell.super.initUI(self)
    self.m_memberData = _memberData

    -- 头像
    self:initUserHead()
    -- 名字
    self:initUserName()
    -- 选择状态
    self:updateSelState()
end

-- 头像
function ClanRedGiftChooseMemberCell:initUserHead()
    local _headParent = self:findChild("sp_head")
    _headParent:removeAllChildren()
    local fbId = self.m_memberData:getFacebookId()
    local head = self.m_memberData:getHead() 
    local frameId = self.m_memberData:getFrameId()
    local headSize = _headParent:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, headSize)
    nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    nodeAvatar:addTo(_headParent)
end

-- 名字
function ClanRedGiftChooseMemberCell:initUserName()
    local layoutName = self:findChild("layout_name")
    local lbName = self:findChild("lb_name")
    local name = self.m_memberData:getName()
    lbName:setString(name)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end

-- 选择状态
function ClanRedGiftChooseMemberCell:updateSelState()
    local bSel = ClanManager:checkExitChooseList(self.m_memberData:getUdid())
    local spUnSel = self:findChild("sp_unSel")
    local spSel = self:findChild("sp_sel")

    spSel:setVisible(bSel)
    spUnSel:setVisible(not bSel)
end

function ClanRedGiftChooseMemberCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_selAll" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local bSel = ClanManager:checkExitChooseList(self.m_memberData:getUdid())
        if bSel then
            ClanManager:removeGiftChooseUser(self.m_memberData:getUdid())
        else
            ClanManager:addGiftChooseUser(self.m_memberData:getUdid())
        end

        -- 更新主界面 选择all状态
        local view = gLobalViewManager:getViewByExtendData("ClanRedGiftChooseMemberLayer")
        if view then
            view:updateSelAllState()
            view:updateBuyBtnState()
        end

        self:updateSelState()
    end

end

return ClanRedGiftChooseMemberCell