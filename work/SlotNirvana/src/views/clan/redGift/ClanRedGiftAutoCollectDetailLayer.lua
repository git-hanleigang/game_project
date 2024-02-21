--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-16 11:52:21
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-16 15:27:55
FilePath: /SlotNirvana/src/views/clan/redGift/ClanRedGiftAutoCollectDetailLayer.lua
Description: 公会红包 自动领取 详细弹板
--]]
local ClanRedGiftAutoCollectDetailLayer = class("ClanRedGiftAutoCollectDetailLayer", BaseLayer)

function ClanRedGiftAutoCollectDetailLayer:initDatas(_data)
    self.m_data = _data
    self.m_memberDataList = _data:getCollectUserList() 

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/Gift/Gift_Reward_auto_detail.csb")
    self:setExtendData("ClanRedGiftAutoCollectDetailLayer")
end

function ClanRedGiftAutoCollectDetailLayer:initView()
    -- 头像框
    self:initUserHeadUI()
    -- listview 成员列表
    self:initMemberListView()
    -- 美刀价值
    self:initPriceUI()
    -- 谁发送的红包nameUI
    self:initSenderNameUI()
    -- 领取 个数信息
    self:initColCountUI()
end

-- 头像框
function ClanRedGiftAutoCollectDetailLayer:initUserHeadUI()
    local sender = self.m_data:getRedPackageOwner()
    local headParent = self:findChild("node_head")
    local fbId = sender:getFacebookId()
    local head = sender:getHead()
    local frameId = sender:getFrameId()
    headParent:removeAllChildren()
    local headSize = cc.size(100, 100)
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, "", headSize)
    headParent:addChild(nodeAvatar)
end

-- listview 成员列表
function ClanRedGiftAutoCollectDetailLayer:initMemberListView()
    local listView = self:findChild("ListView_member")
    listView:removeAllItems()
	listView:setTouchEnabled(true)
    listView:setScrollBarEnabled(false)
    self.m_listViewSize = listView:getContentSize()

    local count = math.ceil(#self.m_memberDataList * 0.5)
    for i=1, count do
        local layout = self:createMemberLayout(i)
        listView:pushBackCustomItem(layout)
    end
end
function ClanRedGiftAutoCollectDetailLayer:createMemberLayout(_idx)
    local layout = ccui.Layout:create()
    layout:setTouchEnabled(false)
    local cellSize = cc.size(426, 120)
    local spaceX = self.m_listViewSize.width - cellSize.width * 2
    for i=1,2 do
        local memberIdx = (_idx-1) * 2 + i
        local memberData = self.m_memberDataList[memberIdx]
        if memberData then
            local memberCell = util_createView("views.clan.redGift.ClanRedGiftCheckCollectDetailCell", memberData)
            memberCell:move(cellSize.width*(i-0.5) + (i-1)*spaceX, cellSize.height*0.5)
            layout:addChild(memberCell)
        end
    end

    layout:setContentSize(cc.size(self.m_listViewSize.width, cellSize.height))
    return layout
end

-- 美刀价值
function ClanRedGiftAutoCollectDetailLayer:initPriceUI()
    local lbPrice = self:findChild("lb_price")
    local price = self.m_data:getDollars()
    lbPrice:setString("$" .. price)
end
-- 谁发送的红包nameUI
function ClanRedGiftAutoCollectDetailLayer:initSenderNameUI()
    local lbDesc = self:findChild("lb_name")
    local sender = self.m_data:getRedPackageOwner()
    local name = sender:getName()
    lbDesc:setString(string.format("%s'S GIFT.", name))

    util_scaleCoinLabGameLayerFromBgWidth(lbDesc, 370, 1)
end
-- 领取 个数信息
function ClanRedGiftAutoCollectDetailLayer:initColCountUI()
    local lbCount = self:findChild("lb_number")
    local remain = self.m_data:getRemainCount()
    local total = self.m_data:getTotalCount()

    lbCount:setString(string.format("GIFTS LEFT: %s/%s", remain, total))
end

function ClanRedGiftAutoCollectDetailLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function ClanRedGiftAutoCollectDetailLayer:closeUI(_cb)
    -- 隐藏粒子
    if self.hidePartiicles then
        self:hidePartiicles()
    end

    ClanRedGiftAutoCollectDetailLayer.super.closeUI(self, _cb)
end

return ClanRedGiftAutoCollectDetailLayer