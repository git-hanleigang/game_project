--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-13 17:32:29
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-13 17:33:38
FilePath: /SlotNirvana/src/views/clan/redGift/ClanRedGiftCheckCollectDetailCell.lua
Description: 公会红包 查看红包领取记录  个人信息
--]]
local ClanRedGiftCheckCollectDetailCell = class("ClanRedGiftCheckCollectDetailCell", BaseView)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanRedGiftCheckCollectDetailCell:getCsbName()
    return "Club/csd/Gift/Gift_Open_information.csb"
end

function ClanRedGiftCheckCollectDetailCell:initUI(_memberData)
    ClanRedGiftCheckCollectDetailCell.super.initUI(self)
    self.m_memberData = _memberData

    -- 头像
    self:initUserHead()
    -- 名字
    self:initUserName()
    -- 领取的金币价值
    self:initPriceUI()
end

-- 头像
function ClanRedGiftCheckCollectDetailCell:initUserHead()
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
function ClanRedGiftCheckCollectDetailCell:initUserName()
    local layoutName = self:findChild("layout_name")
    local lbName = self:findChild("lb_name")
    local name = self.m_memberData:getName()
    lbName:setString(name)
    util_wordSwing(lbName, 1, layoutName, 3, 30, 3)
end

-- 领取的金币价值
function ClanRedGiftCheckCollectDetailCell:initPriceUI()
    local lbPrice = self:findChild("lb_price")
    local price = self.m_memberData:getDollars()
    lbPrice:setString("$ " .. price)
    util_scaleCoinLabGameLayerFromBgWidth(lbPrice, 94, 1)
end

return ClanRedGiftCheckCollectDetailCell