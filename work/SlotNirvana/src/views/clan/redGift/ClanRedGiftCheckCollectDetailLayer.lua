--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-13 15:38:17
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-13 15:39:15
FilePath: /SlotNirvana/src/views/clan/redGift/ClanRedGiftCheckCollectDetailLayer.lua
Description: 公会红包 查看公会红包领取情况 弹板
--]]
local ClanRedGiftCheckCollectDetailLayer = class("ClanRedGiftCheckCollectDetailLayer", BaseLayer)

function ClanRedGiftCheckCollectDetailLayer:initDatas(_data)
    self.m_data = _data
    self.m_memberDataList = _data:getCollectUserList() 

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Club/csd/Gift/Gift_Details.csb")
    self:setExtendData("ClanRedGiftCheckCollectDetailLayer")
end

function ClanRedGiftCheckCollectDetailLayer:initView()
    -- listview 成员列表
    self:initMemberListView()
    -- 美刀价值
    self:initPriceUI()
    -- 谁发送的红包nameUI
    self:alignDescNode()
    -- 领取 个数信息
    self:initColCountUI()
end

-- listview 成员列表
function ClanRedGiftCheckCollectDetailLayer:initMemberListView()
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
function ClanRedGiftCheckCollectDetailLayer:createMemberLayout(_idx)
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
function ClanRedGiftCheckCollectDetailLayer:initPriceUI()
    local lbPrice = self:findChild("lb_price")
    local price = self.m_data:getTotalDollars() -- 总美刀
    lbPrice:setString("$ " .. price)
    util_scaleCoinLabGameLayerFromBgWidth(lbPrice, 94, 1)

    -- local nodeColInfo = self:findChild("node_collectInfo")
    -- nodeColInfo:setVisible(price > 0)
end
-- 谁发送的红包nameUI
function ClanRedGiftCheckCollectDetailLayer:alignDescNode()
    local node = self:findChild("node_collectInfo")
    local uiList = {}
    local children = node:getChildren() 
    for i=1, #children do
        table.insert(uiList, {node = children[i], alignX = i==1 and 0 or 5})
    end
    util_alignCenter(uiList)
end
-- 领取 个数信息
function ClanRedGiftCheckCollectDetailLayer:initColCountUI()
    local lbCount = self:findChild("lb_number")
    local remain = self.m_data:getRemainCount()
    local total = self.m_data:getTotalCount()

    lbCount:setString(string.format("GIFTS LEFT: %s/%s", remain, total))
end

function ClanRedGiftCheckCollectDetailLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return ClanRedGiftCheckCollectDetailLayer