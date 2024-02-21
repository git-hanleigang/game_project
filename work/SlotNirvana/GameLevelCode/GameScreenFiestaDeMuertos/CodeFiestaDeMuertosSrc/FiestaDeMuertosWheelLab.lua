---
--xhkj
--2018年6月11日
--FiestaDeMuertosWheelLab.lua

local FiestaDeMuertosWheelLab = class("FiestaDeMuertosWheelLab", util_require("base.BaseView"))

function FiestaDeMuertosWheelLab:initUI(data)
    local strName
    self.labType = 0
    if data == "Minor" then
        strName = "FiestaDeMuertos_minor.csb"
    elseif data == "Grand" then
        strName = "FiestaDeMuertos_grand.csb"
    elseif data == "Major" then
        strName = "FiestaDeMuertos_major.csb"
    elseif data == "3X" or data == "2X" or data == "5X" or data == "MulLab" then
        self.labType = 2
        strName = "FiestaDeMuertos_5x.csb"
    else
        self.labType = 1
        strName = "FiestaDeMuertos_shuzi_2.csb"
    end
    self:createCsbNode(strName)
end

function FiestaDeMuertosWheelLab:onEnter()
end

function FiestaDeMuertosWheelLab:onExit()
end

function FiestaDeMuertosWheelLab:setLab(num, index)
    if self.labType == 1 then
        for i = 1, 3, 1 do
            local lab = self:findChild("m_lb_coins_" .. i)
            if lab then
                lab:setVisible(false)
            end
        end

        local str = string.format("%s", num)
        local strLen = string.len(str)
        for i = 1, strLen, 1 do
            subStr = string.sub(str, i, i)
            local lab = self:findChild("m_lb_coins_" .. i)
            if lab then
                lab:setVisible(true)
                lab:setString(subStr)
            end
        end
    elseif self.labType == 2 then
        local lab = self:findChild("FiestaDeMuertos_texi_5")
        lab:setString(num)
    end
end

return FiestaDeMuertosWheelLab
