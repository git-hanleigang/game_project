---
--xhkj
--2018年6月11日
--FrogPrinceBonusBox.lua

local FrogPrinceBonusBox = class("FrogPrinceBonusBox", util_require("base.BaseView"))

function FrogPrinceBonusBox:initUI(data)
    self:createCsbNode("FrogPrince_baoxiang.csb")
    local value = data._value 
    local num = data._multiples
    if num == nil then
        num = 0
    end
    self.m_clickFlag = false
    self:setNum(value,num)
    self:addClick(self:findChild("touch_panel"))
end


function FrogPrinceBonusBox:onEnter()
 
end

function FrogPrinceBonusBox:setNum(value,num)
    local label =  self:findChild("BitmapFontLabel_1") -- 获得子节点
    label:setString(value)
    local Numlabel =  self:findChild("BitmapFontLabel_2") -- 获得子节点
    Numlabel:setString(num .. "x")
end

function FrogPrinceBonusBox:setLabNum(num)
    local Numlabel =  self:findChild("BitmapFontLabel_2") -- 获得子节点
    Numlabel:setString(num .. "x")
end

function FrogPrinceBonusBox:onExit()
    
end

function FrogPrinceBonusBox:setClickFlag(flag)
    self.m_clickFlag = flag
end

function FrogPrinceBonusBox:setClickFunc(func)
    self.m_clickFunc = func
end
function FrogPrinceBonusBox:setSelectClick()
    self:runCsbAction("idleframe2")
end
function FrogPrinceBonusBox:setParent(parent)
    self.m_parent = parent
end
--默认按钮监听回调
function FrogPrinceBonusBox:clickFunc(sender)
    if self.m_clickFlag == false then
        return
    end
    if self.m_parent:getClickFlag() == false then
        return 
    end
    self.m_clickFlag = false
    if self.m_clickFunc ~= nil then
        self.m_clickFunc()
    end
end

return FrogPrinceBonusBox