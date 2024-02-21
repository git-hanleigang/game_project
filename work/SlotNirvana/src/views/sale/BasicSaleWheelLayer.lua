--[[
    转盘
]]

local WheelControl = util_require("views.sale.BasicSaleWheelControl")
local BasicSaleWheelLayer = class("BasicSaleWheelLayer", BaseLayer)

function BasicSaleWheelLayer:initDatas(_data)
    self.m_wheelRotation = 0   -- 轮盘角度
    self.m_maxIndex = 8       -- 最大位置
    self.m_angleIndex = 0
    self.distance_pre = 0
    self.distance_now = 0

    self.m_testIndex = 0
    self.m_needAction = false
    self.m_isWheelRotate = false

    self.m_data = _data

    self:setLandscapeCsbName("SpecialSale/Turntable/TurntableMain.csb")
    self:setPortraitCsbName("SpecialSale/Turntable/TurntableMain_shu.csb")
    self:setExtendData("BasicSaleWheelLayer")
end

function BasicSaleWheelLayer:initCsbNodes()
    self.m_node_wheel = self:findChild("node_turntable")
    self.m_sp_coins = self:findChild("sp_coins")
    self.m_lb_coin = self:findChild("lb_coin")
    self.m_node_tips = self:findChild("node_tips")
    self.m_node_btn = self:findChild("node_btn")
    self.m_node_turntable = self:findChild("node_turntable")
    self.m_node_anniuguang = self:findChild("node_anniuguang")
    self.m_node_ef = self:findChild("node_ef")
end

function BasicSaleWheelLayer:initView()
    self:setCoins()
    self:addTip()
    self:addWheel()
    self:addWheelControl()
    self:addBtnAnniuguang()
    self:setButStatus()
end

function BasicSaleWheelLayer:setCoins(_coins)
    self.m_coins = _coins or self.m_data.saleData.p_coins
    self.m_lb_coin:setString(util_formatCoins(self.m_coins, 9))

    local UIList = {
        {node = self.m_sp_coins},
        {node = self.m_lb_coin, alignX = 1}
    }
    util_alignCenter(UIList)
end

function BasicSaleWheelLayer:addTip()
    self.m_tips = util_createView("views.sale.BasicSaleWheelTips", self.m_data)
    self.m_node_tips:addChild(self.m_tips)
end

function BasicSaleWheelLayer:addBtnAnniuguang()
    self.m_anniuguang, self.m_anniuguangAct = util_csbCreate("SpecialSale/Turntable/anniuguang.csb")
    if self.m_anniuguang then 
        self.m_anniuguang:setVisible(false)
        self.m_node_anniuguang:addChild(self.m_anniuguang)
    end
end

function BasicSaleWheelLayer:setButStatus()
    self.m_node_btn:setVisible(self.m_data.spin)
    self.m_node_anniuguang:setVisible(self.m_data.spin)
end

function BasicSaleWheelLayer:addWheel()
    self.m_wheel = util_createView("views.sale.BasicSaleWheel", self.m_data.saleData)
    self.m_node_turntable:addChild(self.m_wheel)
end

function BasicSaleWheelLayer:addWheelControl()
    self.m_nodeWheelControl = WheelControl:create(self.m_node_wheel, self.m_maxIndex, function()
        -- 滚动结束调用
        self:wheelRotateEnd()
     end,function(_distance, _targetStep, _isBack)
         -- 滚动实时调用
         self:setRotionWheel(_distance, _targetStep)
     end, nil, nil)
    self.m_node_wheel:addChild(self.m_nodeWheelControl)
end

function BasicSaleWheelLayer:wheelRotateEnd()
    if self.m_data and self.m_data.resule then
        local coins = self.m_data.resule.coins
        local index = self.m_data.resule.wheelIndex
        local func = function ()
            local discount, worldPos = self.m_wheel:getWedgeDiscount(index)
            local node = util_createView("views.sale.BasicSaleDiscountNode", discount)
            local midNode = self:findChild("node_middle")
            local nodePos = midNode:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
            node:setPosition(nodePos)
            node:addTo(midNode)
            local x , y = self.m_lb_coin:getPosition()
            local endWorlPos = self.m_lb_coin:getParent():convertToWorldSpace(cc.p(x, y))
            local endNodePos = midNode:convertToNodeSpace(cc.p(endWorlPos.x, endWorlPos.y))
            local move = cc.MoveTo:create(1.1, endNodePos)
            local ease = cc.EaseOut:create(move, 1)
            local callback = cc.CallFunc:create(function ()
                self:rollCoins(coins)
            end)
            node:runAction(cc.Sequence:create(ease, callback))
            node:playFlyAction()
        end
        self.m_wheel:pitchWedge(index, func)

        if self.m_wheelEf then
            self.m_wheelEf:playEnd()
        end
    end
end

function BasicSaleWheelLayer:rollCoins(_coins)
    local coinsLabelNode = self.m_lb_coin
    local startCoins = self.m_coins
    local endCoins = _coins
    local addCoins = (_coins - self.m_coins) / 20
    local spendTime = 1 / 20
    util_jumpNumExtra(
        coinsLabelNode,
        startCoins,
        endCoins,
        addCoins,
        spendTime,
        util_formatCoins,
        {9},
        nil,
        nil,
        function()
            self:setCoins(_coins)
            self:buyTip()
        end
    )
end

function BasicSaleWheelLayer:setRotionWheel(_distance, _targetStep)
    
end

-- 开始转动
function BasicSaleWheelLayer:rotateWheel(_index)
    if _index < 0 then
        return 
    end

    self.m_nodeWheelControl.m_currentDistance = self.m_wheelRotation
    self.m_nodeWheelControl:recvData(_index)
    self.m_nodeWheelControl:beginWheel()

    self.m_isWheelRotate = true 

    self.m_wheelEf = util_createView("views.sale.BasicSaleWheelEf")
    self.m_node_ef:addChild(self.m_wheelEf)
end

function BasicSaleWheelLayer:buyTip()
    --购买成功提示界面
    self.m_isBuy = true
    local view = util_createView("GameModule.Shop.BuyTip")
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_buy", DotUrlType.UrlName, false)
    end
    local buyType = BUY_TYPE.SPECIALSALE
    local saleData = self.m_data.saleData
    saleData.p_coins = self.m_data.resule.coins
    view:initBuyTip(buyType, saleData, saleData.p_coins)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function BasicSaleWheelLayer:updateDiscount()
    if self.m_data.resule.refresh then
        self.m_wheel:refresh(function ()
            self:closeUI(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BASIC_WHEEL_CLOSE)
            end)
        end)
    else
        local index = self.m_data.resule.wheelIndex
        self.m_wheel:levelUp(index, function ()
            self:closeUI(function ()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BASIC_WHEEL_CLOSE)
            end)
        end)
    end
end

function BasicSaleWheelLayer:clickFunc(_sender)
    if self.m_isTouch then
        return 
    end
    
    local name = _sender:getName()
    if name == "btn_spin" then
        if self.m_anniuguangAct then
            self.m_isTouch = true
            self.m_anniuguang:setVisible(true)
            util_csbPlayForKey(self.m_anniuguangAct, "start", false, function ()
                _sender:setVisible(false)
            end, 60)
        end
        self:rotateWheel(self.m_data.resule.wheelIndex)
    elseif name == "btn_close" then
        if self.m_data.spin then
            self.m_isTouch = true
            self.m_node_btn:setVisible(false)
            self:rotateWheel(self.m_data.resule.wheelIndex)
        else
            self:closeUI()
        end
    end
end

function BasicSaleWheelLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
    self.m_tips:playAction()
end


function BasicSaleWheelLayer:registerListener()
    BasicSaleWheelLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(
        self,
        function()
            self:updateDiscount()
        end,
        ViewEventType.NOTIFY_BASIC_WHEEL_REFRESH
    )
end

return BasicSaleWheelLayer