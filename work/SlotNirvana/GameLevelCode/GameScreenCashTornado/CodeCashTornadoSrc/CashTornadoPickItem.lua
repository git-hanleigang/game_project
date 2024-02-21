---
--xcyy
--2018年5月23日
--CashTornadoPickItem.lua
local PublicConfig = require "CashTornadoPublicConfig"
local CashTornadoPickItem = class("CashTornadoPickItem",util_require("Levels.BaseLevelDialog"))


function CashTornadoPickItem:initUI(parent)
    self.m_parent = parent
    self.m_isClicked = false    --是否已经点击

    self:createCsbNode("CashTornado_chaopiao.csb")

    self.m_bonusBill = util_spineCreate("CashTornado_pidk_chaopiao", true, true)
    self:findChild("Node_chaopiao"):addChild(self.m_bonusBill)

    util_spinePlay(self.m_bonusBill, "idleframe", true)

    self.lighting = util_createAnimation("CashTornado_chaopiao_g.csb")
    self:findChild("Node_guang"):addChild(self.lighting)
    self.lighting:runCsbAction("idleframe",true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_guang"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("Node_guang"), true)
    -- self.lighting:setVisible(false)

    self:runCsbAction("idleframe",true)

    self:addClick(self:findChild("click_bill")) -- 非按钮节点得手动绑定监听

end

function CashTornadoPickItem:showClickAction()
    self:runCsbAction("dianji",false,function ()
        self:runCsbAction("idle1",true)
    end)
end

function CashTornadoPickItem:hideClickBill()
    self:runCsbAction("show")
end

function CashTornadoPickItem:setShowNum(_data)
    self:findChild("Node_coin"):setVisible(self.m_parent:getRewardType(_data) == "coins")
    self:findChild("Node_Jackpot"):setVisible(self.m_parent:getRewardType(_data) == "jackpot")
    self:findChild("Node_Pick"):setVisible(self.m_parent:getRewardType(_data) == "pick")
    if self.m_parent:getRewardType(_data) == "pick" then
        self:findChild("pick2"):setVisible(_data == 102)
        self:findChild("pick3"):setVisible(_data == 103)
        self:findChild("pick5"):setVisible(_data == 105)
    elseif self.m_parent:getRewardType(_data) == "coins" then
        local lineBet = globalData.slotRunData:getCurTotalBet()
        self:findChild("m_lb_coins"):setString(util_formatCoinsLN(_data * lineBet,3))
        local info={label = self:findChild("m_lb_coins"),sx = 1,sy = 1}
        self:updateLabelSize(info,139)
    elseif self.m_parent:getRewardType(_data) == "jackpot" then
        self:findChild("grand"):setVisible(_data == 500)
        self:findChild("mega"):setVisible(_data == 100)
        self:findChild("major"):setVisible(_data == 50)
    end
end

function CashTornadoPickItem:changeLightingShow(_data)
    if self.m_parent:getRewardType(_data) == "pick" then
        self.lighting:findChild("Node_1"):setVisible(false)
        self.lighting:findChild("Node_2"):setVisible(true)
    elseif self.m_parent:getRewardType(_data) == "coins" then
        self.lighting:findChild("Node_1"):setVisible(true)
        self.lighting:findChild("Node_2"):setVisible(false)
    elseif self.m_parent:getRewardType(_data) == "jackpot" then
        self.lighting:findChild("Node_1"):setVisible(true)
        self.lighting:findChild("Node_2"):setVisible(false)
    end
end

--[[
    默认按钮监听回调
]]
function CashTornadoPickItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    --判断是否可以点击
    if self.m_parent:isTouch() then
        --数据发送
        -- self.m_parent:setCurClickBillNode(self)
        -- self.m_parent:sendData(1)
        if name == "click_bill" then
            self.m_parent:clickFunc( self ) 
        end
    end
    
    
end


return CashTornadoPickItem