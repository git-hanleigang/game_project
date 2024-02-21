--[[
Author: cxc
Date: 2022-04-20 19:26:00
LastEditTime: 2022-04-20 19:26:01
LastEditors: cxc
Description: 关卡 热玩 玩家信息UI
FilePath: /SlotNirvana/src/views/ChooseLevel/SlotHotPlayerUI.lua
--]]

local SlotHotPlayerUI = class("SlotHotPlayerUI", BaseView)
local SlotHotPlayerTableView = util_require("views.ChooseLevel.SlotHotPlayerTableView")
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")

function SlotHotPlayerUI:getCsbName()
    return "BetChoice/BetChoice_userInfo.csb"
end

function SlotHotPlayerUI:initCsbNodes()
    self.m_nodeAvatar = self:findChild("node_avatar")
    self.m_lbName = self:findChild("lb_name")
    self.m_layoutSw = self:findChild("layout_name")
    self.m_layoutSize = self.m_layoutSw:getContentSize()
    self.m_lbNameSw = self:findChild("lb_nameSw")
    local btn = self:findChild("btn_head")
    btn:setTouchEnabled(false)
end

function SlotHotPlayerUI:updateUI(_data, _idx)
    self.m_palyerData = _data

    -- 更新 头像 头像框
    self:updateAvatarUI()
    -- 更新名字
    self:updateNickName()
end

--[[
    @desc: 创建通用头像+头像框
    --@_fId: facebook id 
	--@_headId: 游戏game 存储的头像id
	--@_headFrameId: 游戏game 存储的头像框 id
	--@_robotHeadName: 机器人头像名字
	--@_size:  头像限制大小
	--@_bFBFromCache: facebook头像是否从（缓存）中获取 默认true
    @return: node
]]

-- 更新 头像 头像框
function SlotHotPlayerUI:updateAvatarUI()
    local size = cc.size(142,142)
    local node = self.m_nodeAvatar:getChildByName("CommonAvatarNode")
    if node then
        node:updateUI(self.m_palyerData:getFbId(), 
        self.m_palyerData:getHeadId(), 
        self.m_palyerData:getAvatarFrameId(), 
        self.m_palyerData:getRobotName(),
        size)
    else
        self.m_nodeAvatar:removeAllChildren()
        node = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(
            self.m_palyerData:getFbId(), 
            self.m_palyerData:getHeadId(), 
            self.m_palyerData:getAvatarFrameId(), 
            self.m_palyerData:getRobotName(),
            size)
        self.m_nodeAvatar:addChild(node)
    end
end

-- 更新名字
function SlotHotPlayerUI:updateNickName()
    local name = self.m_palyerData:getNickName()
    self.m_lbName:setString(name)
    self.m_lbNameSw:setString(name)

    local lbSize = self.m_lbName:getContentSize()
    if lbSize.width > self.m_layoutSize.width then
        self.m_lbName:setVisible(false)
        self.m_layoutSw:setVisible(true)
        util_wordSwing(self.m_lbNameSw, 1, self.m_layoutSw, 2, 30, 2) 
    else
        self.m_lbName:setVisible(true)
        self.m_layoutSw:setVisible(false)
        self.m_lbNameSw:stopAllActions()
    end

end

function SlotHotPlayerUI:clickCell()
    G_GetMgr(G_REF.UserInfo):sendInfoMationReq(self.m_palyerData.m_udid, self.m_palyerData.m_robotName,self.m_palyerData.m_nickName,self.m_palyerData.m_avatarFrameId)
end

return SlotHotPlayerUI