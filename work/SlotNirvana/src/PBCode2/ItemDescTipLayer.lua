--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-14 11:30:54
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-14 16:12:31
FilePath: /SlotNirvana/src/PBCode2/ItemDescTipLayer.lua
Description: 通用道具描述 提示弹板
--]]
local ItemDescTipLayer = class("ItemDescTipLayer", BaseLayer)
local CommonIcon_Info = util_require("luaStdTable.CommonIcon_Info")

function ItemDescTipLayer:ctor(_itemData, _itemSizeType, _mul)
    ItemDescTipLayer.super.ctor(self)

    self.m_itemData = clone(_itemData)
    self.m_itemSizeType = _itemSizeType
    self.m_mul = _mul

    self:setKeyBackEnabled(true)
    self:setName("ItemDescTipLayer")
    self:setLandscapeCsbName("PBRes/CommonItemRes/ItemReward_message.csb")
end

function ItemDescTipLayer:initView()
    self.m_itemData.p_mark = {0}

    -- 道具显示
    local itemParent = self:findChild("node_item")
    local itemNode = gLobalItemManager:createRewardNode(self.m_itemData, ITEM_SIZE_TYPE.REWARD_BIG, self.m_mul)
    itemParent:addChild(itemNode)
    local lb_value = itemNode:getValue()
    if lb_value then
        lb_value:setVisible(false)
    end

    -- 道具名字
    local lbName = self:findChild("lb_item_name")
    local name = CommonIcon_Info[self.m_itemData.p_icon][1]
    lbName:setString(name)

    -- 道具描述
    local lbDesc = self:findChild("lb_item_desc")
    local desc = CommonIcon_Info[self.m_itemData.p_icon][2]
    lbDesc:setString(desc)
    util_AutoLine(lbDesc, desc, 600, true)
end

function ItemDescTipLayer:clickFunc(sender)
    local btnName = sender:getName()
    if btnName == "btn_close" then
        self:closeUI()
    end
end

return ItemDescTipLayer