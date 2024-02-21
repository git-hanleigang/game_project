---
--xcyy
--2018年5月23日
--AliceBonusHatBoard.lua

local AliceBonusHatBoard = class("AliceBonusHatBoard",util_require("base.BaseView"))

AliceBonusHatBoard.m_total = nil
AliceBonusHatBoard.m_vecEndNode = nil
AliceBonusHatBoard.m_vecMultip = nil
AliceBonusHatBoard.m_onlyTwo = nil

function AliceBonusHatBoard:initUI(data)

    self:createCsbNode("Alice_Bonus_hat2.csb")

    self:runCsbAction("idleframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    local index = 1
    while true do
        local icon = self:findChild("cake"..index)
        if icon ~= nil then
            if index ~= data.index then
                icon:setVisible(false)
            end
        else
            break
        end
        index = index + 1
    end
    self.m_vecEndNode = {}
    self.m_vecMultip = {}
    for i = 1, 3, 1 do
        local multip = data.table[i]
        local lab1 = self:findChild("lab_1_"..i)
        local lab2 = self:findChild("lab_2_"..i)
        if multip == nil then
            self:findChild("Node_2"):setVisible(false)
            self:findChild("hat_mark"):setVisible(true)
            self.m_onlyTwo = true
        else
            self:findChild("hat_mark"):setVisible(false)
            lab1:setString(multip.."x")
            lab2:setString(multip.."x")

            self.m_vecMultip[i] = multip
        end
        self.m_vecEndNode[i] = lab1
    end
    local addPick = self:findChild("2pick_0")
    self.m_vecEndNode[#self.m_vecEndNode + 1] = addPick
    self.m_total = 0

    util_setCascadeOpacityEnabledRescursion(self,true)
end


function AliceBonusHatBoard:onEnter()
 
end

function AliceBonusHatBoard:showAdd()
    
end

function AliceBonusHatBoard:onExit()
 
end

function AliceBonusHatBoard:showBoardIdle()
    self.m_total = self.m_total + 1
    if self.m_onlyTwo == true and self.m_total == 2 then
        self:runCsbAction("idleframe0")
    else
        self:runCsbAction("idleframe"..self.m_total)
    end
    
end

function AliceBonusHatBoard:showBoardAnim(func)
    if self.m_onlyTwo == true and self.m_total == 2 then
        self:runCsbAction("animation0", false, function()
            if func ~= nil then
                func()
            end
        end)
    else
        self:runCsbAction("actionframe"..self.m_total, false, function()
            if func ~= nil then
                func()
            end
        end)
    end
end

function AliceBonusHatBoard:getEndNode()
    self.m_total = self.m_total + 1
    return self.m_vecEndNode[self.m_total]
end

function AliceBonusHatBoard:getPickNode()
    return self.m_vecEndNode[#self.m_vecEndNode]
end

function AliceBonusHatBoard:getChooseNum()
    return self.m_total
end

function AliceBonusHatBoard:getCollectNodeAndMul(index)
    return self.m_vecEndNode[index], self.m_vecMultip[index]
end

--默认按钮监听回调
function AliceBonusHatBoard:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceBonusHatBoard