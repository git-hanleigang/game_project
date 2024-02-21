---
--xcyy
--2018年5月23日
--AliceBonusCardPay.lua

local AliceBonusCardPay = class("AliceBonusCardPay",util_require("base.BaseView"))

function AliceBonusCardPay:initUI(data)

    self:createCsbNode("Alice_Bonuscard_2.csb")
    self.m_multip = data.multipe
    self.m_pay = data.pay

    self:findChild("labMultip"):setString(data.multipe.."x")
    
    self.m_vecItem = {}
    local index = 1
    while true do
        local node = self:findChild("node_card_" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusCardPayItem", data.pay[index])
            self.m_vecItem[index] = item
            node:addChild(item)
        else
            break
        end
        index = index + 1
    end

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
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusCardPay:showChoosed(result)
    for i = 1, #self.m_pay, 1 do
        local type = self.m_pay[i]
        if type == result then
            self.m_vecItem[i]:showChoosed()
        end
    end
end

function AliceBonusCardPay:showIdle(result)
    for i = 1, #self.m_pay, 1 do
        local type = self.m_pay[i]
        if type == result then
            self.m_vecItem[i]:showIdle()
        end
    end
end

function AliceBonusCardPay:showReward(func)
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function AliceBonusCardPay:getStartNode()
    return self:findChild("labMultip")
end

function AliceBonusCardPay:onEnter()
 
end

function AliceBonusCardPay:showAdd()
    
end

function AliceBonusCardPay:onExit()
 
end

--默认按钮监听回调
function AliceBonusCardPay:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceBonusCardPay