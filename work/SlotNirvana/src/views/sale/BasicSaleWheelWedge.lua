--[[
    
]]
local BasicSaleWheelWedge = class("BasicSaleWheelWedge", BaseView)

function BasicSaleWheelWedge:getCsbName()
    return "SpecialSale/Turntable/TurntableMain_icon_shu_2.csb"
end

function BasicSaleWheelWedge:initDatas(_data, _maxDiscount)
    self.m_discountMax = _maxDiscount
    self.m_data = _data
    self.m_isMax = _maxDiscount == _data.p_discount
    self.m_bgPath = {
        "SpecialSale/Turntable/Turntable/Turntable_shu_mokuai4.png",
        "SpecialSale/Turntable/Turntable/Turntable_shu_mokuai2.png",
        "SpecialSale/Turntable/Turntable/Turntable_shu_mokuai5.png",
        "SpecialSale/Turntable/Turntable/Turntable_shu_mokuai3.png",
        "SpecialSale/Turntable/Turntable/Turntable_shu_mokuai5.png",
        "SpecialSale/Turntable/Turntable/Turntable_shu_mokuai4.png",
        "SpecialSale/Turntable/Turntable/Turntable_shu_mokuai3.png",
        "SpecialSale/Turntable/Turntable/Turntable_shu_mokuai2.png"
    }
end

function BasicSaleWheelWedge:initCsbNodes()
    self.m_sp_normal_bg = self:findChild("sp_normal_bg")
    self.m_lb_munber_normal = self:findChild("lb_munber_normal")
    self.m_lb_munber_special = self:findChild("lb_munber_special")
end

function BasicSaleWheelWedge:initUI(_data)
    BasicSaleWheelWedge.super.initUI(self)

    self:changeBg()
    self:setDiscount()
    self:playIdle()
end

function BasicSaleWheelWedge:changeBg()
    util_changeTexture(self.m_sp_normal_bg, self.m_bgPath[self.m_data.p_index])
end

function BasicSaleWheelWedge:setDiscount()
    self.m_lb_munber_normal:setString("X" .. self.m_data.p_discount)
    self.m_lb_munber_special:setString("X" .. self.m_data.p_discount)
end

function BasicSaleWheelWedge:getDiscount()
    local discount = self.m_data.p_discount
    local worldPos = cc.p(0, 0)
    if self.m_data.p_bigWin then
        local x, y = self.m_lb_munber_special:getPosition()
        worldPos = self.m_lb_munber_special:getParent():convertToWorldSpace(cc.p(x, y))
    else
        local x, y = self.m_lb_munber_normal:getPosition()
        worldPos = self.m_lb_munber_normal:getParent():convertToWorldSpace(cc.p(x, y))
    end

    return discount, worldPos
end

function BasicSaleWheelWedge:playIdle()
    if self.m_data.p_bigWin then
        self:runCsbAction("idle4", true)
    else
        self:runCsbAction("idle", true)
    end
end

function BasicSaleWheelWedge:playPitch(_func)
    if self.m_data.p_bigWin then
        self:runCsbAction("xuanzhong2", true, function ()
            if _func then
                _func()
            end
        end, 60)
    else
        self:runCsbAction("xuanzhong", true, function ()
            if _func then
                _func()
            end
        end, 60)
    end
end

function BasicSaleWheelWedge:levelUp(_func)
    self.m_lb_munber_special:setString("X" .. self.m_discountMax)

    self:runCsbAction("shengji", false, function ()
        if _func then
            _func()
        end
    end, 60)
end

function BasicSaleWheelWedge:levelDown(_data, maxDiscount, _func)
    self.m_lb_munber_normal:setString("X" .. _data.p_discount)

    if _func then
        performWithDelay(self, function ()
            _func()
        end, 25/60)
    end

    if _data.p_discount == maxDiscount then
        return
    end

    if self.m_isMax then
        self:runCsbAction("over", false, nil, 60)
    end
end

return BasicSaleWheelWedge
