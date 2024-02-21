---
--xcyy
--2018年5月23日
--MerryChristmasFsCollect.lua

local MerryChristmasFsCollect = class("MerryChristmasFsCollect", util_require("base.BaseView"))

function MerryChristmasFsCollect:initUI()
    self:createCsbNode("MerryChristmas_fs_tishitiao.csb")
    local max = self:findChild("texi_2")
    max:setVisible(false)
    local particle1 = self:findChild("Particle_1")
    particle1:setVisible(false)
end

function MerryChristmasFsCollect:onEnter()
end

function MerryChristmasFsCollect:showColletNum(_num1, _num2, _num3, bMax)
    local lab1 = self:findChild("m_lb_num_0") --收集的临界值
    local lab2 = self:findChild("m_lb_num_1") --轮盘个数
    local lab3 = self:findChild("m_lb_num_2") --收集个数
    lab1:setString(tostring(_num1))
    lab2:setString(tostring(_num2))
    lab3:setString(tostring(_num3))
    if bMax then
        local particle1 = self:findChild("Particle_1")
        particle1:setVisible(false)
        lab3:setVisible(false)
        local max = self:findChild("texi_2")
        max:setVisible(true)
    else
        lab3:setVisible(true)
        local max = self:findChild("texi_2")
        max:setVisible(false)
    end
end

function MerryChristmasFsCollect:updataChangeColletNum(_num1, _num2, _num3, bMax)
    -- print("收集的临界值 _num1 ===============" .. _num1)
    -- print("轮盘个数 _num2 ==========================" .. _num2)
    -- print("收集个数 _num3 ====================================" .. _num3)
    self:showColletNum(_num1, _num2, _num3, bMax)
    if not bMax then
        local particle1 = self:findChild("Particle_1")
        particle1:setVisible(true)
        particle1:setPositionType(0)
        particle1:resetSystem()
    end
end

function MerryChristmasFsCollect:onExit()
end

function MerryChristmasFsCollect:getCollectNode()
    local node = self:findChild("m_lb_num_2")
    return node
end

return MerryChristmasFsCollect
