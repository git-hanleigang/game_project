--[[
    
]]
local BasicSaleWheel = class("BasicSaleWheel", BaseView)

function BasicSaleWheel:getCsbName()
    return "SpecialSale/Turntable/TurntableMain_icon_shu.csb"
end

function BasicSaleWheel:initUI(_data)
    BasicSaleWheel.super.initUI(self)

    self.m_wedgeList = {}
    local specialWheel = _data:getSpecialWheel()
    local maxDiscount = _data:getMaxDiscount()
    for i,v in ipairs(specialWheel) do
        local node = self:findChild("node_wedge" .. i)
        if node then
            local wedge = util_createView("views.sale.BasicSaleWheelWedge", v, maxDiscount)
            node:addChild(wedge)
            table.insert(self.m_wedgeList, wedge)
        end
    end
end

function BasicSaleWheel:getWedgeDiscount(_index)
    local wedge = self.m_wedgeList[_index]
    if wedge then
        return wedge:getDiscount()
    end
    return 1, cc.p(0, 0)
end

function BasicSaleWheel:pitchWedge(_index, _func)
    local wedge = self.m_wedgeList[_index]
    if wedge then
        wedge:playPitch(_func)
    else
        if _func then
            _func()
        end
    end
end

function BasicSaleWheel:refresh(_func)
    local saleData = G_GetMgr(G_REF.SpecialSale):getRunningData()
    if saleData then
        local specialWheel = saleData:getSpecialWheel()
        local maxDiscount = saleData:getMaxDiscount()
        for i,v in ipairs(specialWheel) do
            local wedge = self.m_wedgeList[i]
            if wedge then
                if i == #specialWheel then
                    wedge:levelDown(v, maxDiscount, _func)
                else
                    wedge:levelDown(v, maxDiscount)
                end
            end
        end
    else
        if _func then
            _func()
        end
    end
end

function BasicSaleWheel:levelUp(_index, _func)
    local wedge = self.m_wedgeList[_index]
    if wedge then
        wedge:levelUp(_func)
    else
        if _func then
            _func()
        end
    end
end

return BasicSaleWheel
