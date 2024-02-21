local BeatlesShopEnterView = class("BeatlesShopEnterView", util_require("base.BaseView"))


function BeatlesShopEnterView:initUI(machine)
    self.m_machine = machine

    -- local resourceFilename = "Beatles_shop_enter.csb"
    -- self:createCsbNode(resourceFilename)
    self.shopEnterDi = util_spineCreate("Beatles_shop_enter2", true, true)
    self.shopEnter = util_spineCreate("Beatles_shop_enter", true, true)

    self.m_enterCoin = util_createAnimation("Beatles_shop_enter_coin.csb")
    util_spinePushBindNode(self.shopEnter,"shuzi",self.m_enterCoin)

    self.m_enter_feidie = util_createAnimation("Beatles_shop_enter_feidie.csb")
    self.m_enter_feidie:findChild("Node_1"):addChild(self.shopEnterDi)

    self.m_machine:findChild("Node_shop"):addChild(self.m_enter_feidie)
    self.m_machine:findChild("Node_shop"):addChild(self.shopEnter)
    -- self:addChild(self.shopEnter)
    -- self.shopEnter:setPosition(display.width * 0.5, display.height * 0.5)

    self:addClick(self.m_enterCoin:findChild("btn_click"))
    util_spinePlay(self.shopEnter, "idleframe", true)
    util_spinePlay(self.shopEnterDi, "idleframe", true)
end

function BeatlesShopEnterView:setWaiXingNiuCoin( num)
    if num > 9999999 then--大于7位数显示KMBT
        self.m_enterCoin:findChild("m_lb_coins"):setString(util_formatCoins(num,3))
    else
        self.m_enterCoin:findChild("m_lb_coins"):setString(util_formatCoins(num,50))
    end
    local label1=self.m_enterCoin:findChild("m_lb_coins")
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,104)
end

--默认按钮监听回调
function BeatlesShopEnterView:clickFunc(_sender)
    local name = _sender:getName()
    
    if not self.m_machine:getBtnTouch() then
        return
    end

    if globalData.slotRunData.m_isAutoSpinAction then
        return
    end

    if name == "btn_click" then
        util_spinePlay(self.shopEnter, "touch", false)
        util_spineEndCallFunc(self.shopEnter, "touch", function()
            util_spinePlay(self.shopEnter, "idleframe", true)
        end)
        self.m_enter_feidie:playAction("touch", false, function()
            self.m_enter_feidie:playAction("idleframe")
        end)

        self.m_machine:showOpenOrCloseShop(true)
        self.m_machine.m_ShopView:resetLimitData()
        self.m_machine.m_ShopView:openShopShow()
    end
end



function BeatlesShopEnterView:onEnter()

end

function BeatlesShopEnterView:onExit()

end

return BeatlesShopEnterView