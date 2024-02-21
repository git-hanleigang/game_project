--[[
    大活动促销按钮上的通用价格
]]
local UIStatus = {
    Normal = 1,
    Discount = 2
}
local BasePromotionPrice = class("BasePromotionPrice", BaseView)

function BasePromotionPrice:initDatas(_prePrice, _curPrice, _isShowFirst, _isPortrait)
    self.m_prePrice = _prePrice
    self.m_curPrice = _curPrice
    self.m_isShowFirst = _isShowFirst
    self.m_isPortrait = _isPortrait
    self.m_UIStatus = self:getUIStatus()
end

function BasePromotionPrice:getCsbName()
    if self.m_isPortrait then
        return "CommonButton/csb_promotion_price/Common_Promotion_Price_shu.csb"
    else
        return "CommonButton/csb_promotion_price/Common_Promotion_Price_heng.csb"
    end
end

function BasePromotionPrice:initCsbNodes()
    self.m_nodeFirstTag = self:findChild("node_tag")
    self.m_lbPreNum1 = self:findChild("lb_num_pre_1")
    self.m_lbPreNum2 = self:findChild("lb_num_pre_2")
    self.m_lbCurNum = self:findChild("lb_num_cur")
end

function BasePromotionPrice:initUI()
    BasePromotionPrice.super.initUI(self)
    self:initView()
end

function BasePromotionPrice:initView()
    self:initUIStatus(true)
    self:initPrice()
    -- self:initFirstTag(true)
end

function BasePromotionPrice:updateUI(_prePrice, _curPrice, _isShowFirst)
    self.m_prePrice = _prePrice
    self.m_curPrice = _curPrice
    self.m_isShowFirst = _isShowFirst
    self.m_UIStatus = self:getUIStatus()

    self:initUIStatus()
    self:initPrice()
    -- self:initFirstTag()
end

function BasePromotionPrice:initUIStatus(_isInit)
    -- if self.m_UIStatus == UIStatus.Discount then
    --     if _isInit then
    --         self:playChange(
    --             function()
    --                 if not tolua.isnull(self) then
    --                     self:playDiscountIdle()
    --                 end
    --             end
    --         )
    --     else
    --         self:playDiscountIdle()
    --     end
    -- else
    --     self:playNormalIdle()
    -- end
    self:playNormalIdle()
end

function BasePromotionPrice:initPrice()
    if self.m_prePrice and self.m_prePrice ~= "" then
        self.m_lbPreNum1:setString("WAS $" .. self.m_prePrice)
        self.m_lbPreNum2:setString("ONLY $" .. self.m_prePrice)
    end
    if self.m_curPrice and self.m_curPrice ~= "" then
        self.m_lbCurNum:setString("ONLY $" .. self.m_curPrice)
    end
end

function BasePromotionPrice:initFirstTag(_init)
    if self:isShowFirstTag() then
        if not self.m_firstTag then
            self.m_firstTag = util_createAnimation("CommonButton/csb_promotion_price/Common_Promotion_Price_FirstTag.csb")
            self.m_nodeFirstTag:addChild(self.m_firstTag)
        end
        if _init then
            self:playFirstTagStart(
                function()
                    if not tolua.isnull(self) then
                        self:playFirstTagIdle()
                    end
                end
            )
        else
            self:playFirstTagIdle()
        end
    else
        if not tolua.isnull(self.m_firstTag) then
            self.m_firstTag:removeFromParent()
            self.m_firstTag = nil
        end
    end
end

function BasePromotionPrice:playFirstTagIdle()
    if self.m_firstTag then
        self.m_firstTag:playAction("idle", true, nil, 60)
    end
end

function BasePromotionPrice:playFirstTagStart(_over)
    if self.m_firstTag then
        self.m_firstTag:playAction("start", false, _over, 60)
    end
end

function BasePromotionPrice:playNormalIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function BasePromotionPrice:playChange(_over)
    self:runCsbAction("start", false, _over, 60)
end

function BasePromotionPrice:playDiscountIdle()
    self:runCsbAction("idle2", true, nil, 60)
end

function BasePromotionPrice:onEnter()
    BasePromotionPrice.super.onEnter(self)
end

function BasePromotionPrice:getUIStatus()
    if self.m_prePrice and self.m_prePrice ~= "" then
        return UIStatus.Discount
    end
    return UIStatus.Normal
end

function BasePromotionPrice:isShowFirstTag()
    if self.m_isShowFirst then
        return true
    end
    -- if not globalData.hasPurchase then
    --     return true
    -- end
    return false
end

return BasePromotionPrice
