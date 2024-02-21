--[[
Author: cxc
Date: 2021-12-15 14:39:12
LastEditTime: 2021-12-15 14:39:13
LastEditors: your name
Description: 乐透上一期玩家UI
FilePath: /SlotNirvana/src/views/lottery/other/LotteryUserInfoView.lua
--]]
local LotteryUserInfoView = class("LotteryUserInfoView", BaseView)

function LotteryUserInfoView:ctor(_userInfo)
    LotteryUserInfoView.super.ctor(self)

    self.m_userInfo = _userInfo
end

function LotteryUserInfoView:initUI()
    LotteryUserInfoView.super.initUI(self)
    
    self:initView()
end

function LotteryUserInfoView:getCsbName()
    return "Lottery/csd/Lottery_tanban_show_player.csb"
end

function LotteryUserInfoView:initView()
    -- 头像
    local nodeHead = self:findChild("node_head")
    local spHeadBg = self:findChild("sp_default")
    local fbid = self.m_userInfo:getFbId() 
    local sysHead = self.m_userInfo:getSysHead() 
    local robotHead = self.m_userInfo:getRobotHead() 
    local frameId = self.m_userInfo:getUserFrameId()
    local headSize = spHeadBg:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, sysHead, frameId, robotHead, headSize)
    nodeHead:addChild(nodeAvatar)

    -- 等级
    local level = self.m_userInfo:getUserLevel() 
    local lbLevel = self:findChild("lb_level")
    lbLevel:setString("LV " .. level)

    -- 名字
    local name = self.m_userInfo:getUserName() 
    local lbName = self:findChild("lb_name")
    local layerName = self:findChild("layout_name")
    name = util_getFormatFixSubStr(name, "**")
    lbName:setString(name)
    util_wordSwing(lbName, 1, layerName, 2, 30, 2)
end

return LotteryUserInfoView
