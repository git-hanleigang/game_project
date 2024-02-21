---
--xcyy
--2018年5月23日
--AliceBonusCardPayItem.lua

local AliceBonusCardPayItem = class("AliceBonusCardPayItem",util_require("base.BaseView"))

local CARD_TYPE = {"A", "B", "C", "D", "E"}

function AliceBonusCardPayItem:initUI(data)

    self:createCsbNode("Alice_Bonuscard_1.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
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
    for i = 1, #CARD_TYPE, 1 do
        local type = CARD_TYPE[i]
        local card1 = self:findChild("card_"..type)
        local card2 = self:findChild("card_1_"..type)
        if data ~= type then
            card1:setVisible(false)
            card2:setVisible(false)
        end
    end
    self:runCsbAction("idleframe1")

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusCardPayItem:showChoosed()
    if self.m_isShow ~= true then
        self.m_isShow = true
        self:runCsbAction("click")
    end
end

function AliceBonusCardPayItem:showIdle()
    self.m_isShow = true
    self:runCsbAction("idleframe2")
end

function AliceBonusCardPayItem:onEnter()
 

end

function AliceBonusCardPayItem:showAdd()
    
end
function AliceBonusCardPayItem:onExit()
 
end

--默认按钮监听回调
function AliceBonusCardPayItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceBonusCardPayItem