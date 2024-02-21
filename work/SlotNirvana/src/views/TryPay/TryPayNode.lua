
-- Created by jfwang on 2019-05-05.
local TryPayNode = class("TryPayNode",util_require("base.BaseView"))
function TryPayNode:initUI(index,data,func)
    if index == 3 then
        self:createCsbNode("TryPay/TryPay_Node2.csb")
    else
        self:createCsbNode("TryPay/TryPay_Node1.csb")
    end
    self.m_index = index
    self.m_saleData = data
    self.m_func = func
    self:initView()
end

function TryPayNode:initView()
    local btn_show = self:findChild("btn_show")
    local node_iteml = self:findChild("node_iteml")
    local node_itemr = self:findChild("node_itemr")
    local node_itemc = self:findChild("node_itemc")
    self:initBPInfoNode(node_iteml,node_itemr,node_itemc)
end

------------新增提示功能
function TryPayNode:initBPInfoNode(node_iteml,node_itemr,node_itemc)
    --常规促销默认没有道具
    local itemlist = {}
    --商品附带道具
    if self.m_saleData.p_items ~= nil and #self.m_saleData.p_items > 0 then
        for i=1,#self.m_saleData.p_items do
            itemlist[#itemlist+1] = self.m_saleData.p_items[i]
        end
    end
    itemlist = gLobalItemManager:checkAddLocalItemList(self.m_saleData,itemlist)
    if #itemlist == 1 then
        --创建提示节点
        local propNode = gLobalItemManager:createDescNode(itemlist[1])
        if propNode ~= nil then
            node_itemc:addChild(propNode)
        end
    else
        --创建提示节点
        local propNode1 = gLobalItemManager:createDescNode(itemlist[1])
        if propNode1 ~= nil then
            node_iteml:addChild(propNode1)
        end
        --创建提示节点
        local propNode2 = gLobalItemManager:createDescNode(itemlist[2])
        if propNode2 ~= nil then
            node_itemr:addChild(propNode2)
        end
    end
end

function TryPayNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- 尝试重新连接 network
    if name == "btn_show" then
        if self.m_func then
            self.m_func(self.m_index,self.m_saleData)
        end
    end
end

return TryPayNode