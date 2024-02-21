---
--xcyy
--2018年5月23日
--ThorFreeSpinStart.lua

local ThorFreeSpinStart = class("ThorFreeSpinStart", util_require("base.BaseView"))

function ThorFreeSpinStart:initUI(_data)
    self:createCsbNode("Thor/FreeSpinStart.csb")
    local num = _data.freespinCounts
    local numLab = self:findChild("m_lb_num")
    numLab:setString(num)
    self.m_click = true
    self:addClick(self:findChild("touchPanel"))

    local data = _data.triggerData
    local num = data._num
    local hasData = data.has
    if num == 1 then
        self:findChild("Node_2"):setVisible(false)
        self:findChild("Node_3"):setVisible(false)
    elseif num == 2 then
        self:findChild("Node_1"):setVisible(false)
        self:findChild("Node_3"):setVisible(false)
    elseif num == 3 then
        self:findChild("Node_1"):setVisible(false)
        self:findChild("Node_2"):setVisible(false)
    end

    local showNum = 1
    for i, v in ipairs(hasData) do
        local img = ""
        if v == true then
            if i == 1 then
                img = "Symbol/Socre_Thor_Bonus1_img.png"
            elseif i == 2 then
                img = "Symbol/Socre_Thor_Bonus2_img.png"
            elseif i == 3 then
                img = "Symbol/Socre_Thor_Bonus3_img.png"
            end
            local targetSp = self:findChild("Node_" .. num .. showNum)
             util_changeTexture(targetSp,img)
            showNum = showNum + 1
        end
    end
    self:runCsbAction(
        "idle",
        false,
        function()
          
        end
    )
    performWithDelay(
        self,
        function()
            self.m_click = false
        end,
        0.5
    )
    performWithDelay(
        self,
        function()
            self.m_click = true
            if self.m_func then
                self.m_func()
            end
        end,
        4
    )
end

function ThorFreeSpinStart:setFunCall(_func)
    self.m_func = _func
end

function ThorFreeSpinStart:onEnter()
end

function ThorFreeSpinStart:onExit()
end

--默认按钮监听回调
function ThorFreeSpinStart:clickFunc(sender)
    local name = sender:getName()
    if name == "touchPanel" then
        if self.m_click == true then
            return
        end
        self.m_click = true
        if self.m_func then
            self.m_func()
        end
    end
end

return ThorFreeSpinStart
