--[[
    
]]

local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksRankSale = class("SidekicksRankSale", BaseView)

function SidekicksRankSale:getCsbName()
    return string.format("Sidekicks_%s/csd/rank/Sidekicks_Rank_sale.csb", self.m_seasonIdx)
end

function SidekicksRankSale:initDatas(_seasonIdx, _mainLayer)
    self.m_seasonIdx = _seasonIdx
    self.m_mainLayer = _mainLayer
end

function SidekicksRankSale:initCsbNodes()
    self.m_lb_level = self:findChild("lb_level")
    self.m_lb_limit = self:findChild("lb_limit")
    self.m_lb_sale = self:findChild("lb_sale")
    self.m_listView = self:findChild("ListView_1")
    self.m_lb_num = self:findChild("lb_buff_num")

    self.m_Node_1 = self:findChild("Node_1")
    self.m_Node_2 = self:findChild("Node_2")
    self.m_box = self:findChild("box")
    self.m_Node_3 = self:findChild("Node_3")
    self.m_node_rank_sale = self:findChild("node_rank_sale")
    self.m_boxPos = cc.p(self.m_box:getPosition())
end

function SidekicksRankSale:updateUI(_data, _curLevel, _level)
    self.m_saleData = _data
    self.m_canPay = false
    self.m_isTouch = false

    local rankName = SidekicksConfig.RANK_NAME
    local name = rankName[_level]
    self.m_lb_level:setString(name .. " SPECIAL SALE")
    
    self.m_listView:removeAllItems()
    if _data then
        self:updateItems(_data)
        local name = "idle_lock"
        local text = "LOCKED"
        if _curLevel >= _level then
            name = "idle"
            text = "$" .. _data:getPrice()
            self.m_canPay = true
        end
        self:runCsbAction(name, true)
        self:setButtonLabelContent("btn_pay", text)
        self.m_lb_limit:setString("PURCHASE LIMIT: 1")
    else
        self:collectOver()
    end
end

function SidekicksRankSale:updateItems(_data)
    self.m_listView:removeAllItems()
    self.m_listView:setScrollBarEnabled(false)
    self.m_listView:setBounceEnabled(false)

    local coins = _data:getCoins() 
    local items = _data:getItemList()
    local itemDatas = {}
    if coins > toLongNumber(0) then
        local tempData = gLobalItemManager:createLocalItemData("Coins", coins)
        tempData:setTempData({p_limit = 3})
        table.insert(itemDatas, tempData)
    end

    for i,v in ipairs(items) do
        local tempData = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
        table.insert(itemDatas, tempData)
    end
    
    for k, v in ipairs(itemDatas) do
        local size = cc.size(70, 100)
        local layout = ccui.Layout:create()
        layout:setSize(size)
        local itemNode = gLobalItemManager:createRewardNode(v, ITEM_SIZE_TYPE.SIDEKICKS)
        itemNode:setScale(0.55)
        itemNode:setPosition(size.width / 2, size.height / 2)
        layout:addChild(itemNode)
        self.m_listView:pushBackCustomItem(layout)
    end
end

function SidekicksRankSale:collectReward(_func, _pos)
    self:addMask()

    self:runCsbAction("complete0", false, function ()
        local endPos = self.m_node_rank_sale:convertToNodeSpace(cc.p(_pos.x, _pos.y))
        local move = cc.MoveTo:create(30/60, endPos)
        local easeIn = cc.EaseIn:create(move, 1)
        self.m_box:runAction(easeIn)
        
        self:runCsbAction("complete", false, function ()
            self:runCsbAction("over", false, function ()
                if _func then
                    _func()
                end
                self:collectOver()
            end)
        end)
    end)
    gLobalSoundManager:playSound(string.format("Sidekicks_%s/sound/Sidekicks_honor_sale_gift_fly.mp3", self.m_seasonIdx))
end

function SidekicksRankSale:addMask()
    self.m_maskLayer = util_newMaskLayer()
    self.m_node_rank_sale:addChild(self.m_maskLayer, 20)
    self.m_box:setZOrder(100)
end

function SidekicksRankSale:removeMask()
    self.m_Node_1:setZOrder(1)
    self.m_Node_2:setZOrder(2)
    self.m_box:setZOrder(3)
    self.m_Node_3:setZOrder(4)
    self.m_box:setPosition(self.m_boxPos)

    if self.m_maskLayer then 
        self.m_maskLayer:removeFromParent()
        self.m_maskLayer = nil
    end
end

function SidekicksRankSale:collectOver()
    self.m_listView:removeAllItems()
    self.m_lb_limit:setString("PURCHASE LIMIT: 0")
    self:removeMask()
    self:runCsbAction("idle_2", false)
end

function SidekicksRankSale:clickFunc(_sender)
    if self.m_isTouch then
        return
    end

    local name = _sender:getName()
    if name == "btn_pay" then
        if self.m_canPay then
            self.m_isTouch = true
            self.m_mainLayer:setTouch(true)
            G_GetMgr(G_REF.Sidekicks):buyHonorSale(self.m_saleData)
        end
    end
end

function SidekicksRankSale:setTouch(_flag)
    self.m_isTouch = _flag
end

return SidekicksRankSale