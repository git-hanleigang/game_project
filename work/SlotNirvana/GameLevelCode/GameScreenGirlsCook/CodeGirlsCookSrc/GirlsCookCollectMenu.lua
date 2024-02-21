---
--xcyy
--2018年5月23日
--GirlsCookCollectMenu.lua

local GirlsCookCollectMenu = class("GirlsCookCollectMenu",util_require("base.BaseView"))

local STATUS_WITH_TIMER                 =       2001        --限时任务
local STATUS_WITH_SPINCOUNT_1           =       2002        --限次任务(在次数内)
local STATUS_WITH_SPINCOUNT_2           =       2003        --限次任务(超出次数)


function GirlsCookCollectMenu:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("GirlsCook_menu.csb")

    --创建进度条
    -- self.m_process = util_createAnimation("GirlsCook_menu_jindutiao.csb")
    -- self:findChild("Node_jindutiao_0"):addChild(self.m_process)

    --创建金币
    self.m_csb_coins = util_createAnimation("GirlsCook_menu_jinbi.csb")
    self:findChild("Node_jinbi_time"):addChild(self.m_csb_coins)

    --食物节点
    self.m_foodNode = self:findChild("Node_food_1")

    --倒计时标签
    self.m_lb_time = self:findChild("m_lb_time")
end


function GirlsCookCollectMenu:onEnter()

end


function GirlsCookCollectMenu:onExit()
 
end

--[[
    变换菜单项
]]
function GirlsCookCollectMenu:changeMenu(menuType)
    self:findChild("Node_time"):setVisible(menuType == STATUS_WITH_TIMER)
    self:findChild("Node_spinleft_1"):setVisible(menuType == STATUS_WITH_SPINCOUNT_1)
    self:findChild("Node_spinleft_2"):setVisible(menuType == STATUS_WITH_SPINCOUNT_2)


    --变更节点
    if menuType == STATUS_WITH_TIMER then
        self:changeParent(self.m_csb_coins,self:findChild("Node_jinbi_time"))
        -- self:changeParent(self.m_process,self:findChild("Node_jindutiao_0"))
    elseif menuType == STATUS_WITH_SPINCOUNT_1 then
        self:changeParent(self.m_csb_coins,self:findChild("Node_jinbi_spinleft_1"))
        -- self:changeParent(self.m_process,self:findChild("Node_jindutiao_1"))
    else
        self:changeParent(self.m_csb_coins,self:findChild("Node_jinbi_spinleft_2"))
        -- self:changeParent(self.m_process,self:findChild("Node_jindutiao_2"))
    end
end

--[[
    隐藏菜单项
]]
function GirlsCookCollectMenu:hideAllMenu()
    self:findChild("Node_time"):setVisible(false)
    self:findChild("Node_spinleft_1"):setVisible(false)
    self:findChild("Node_spinleft_2"):setVisible(false)
end

--[[
    开始动作
]]
function GirlsCookCollectMenu:startAni(func)
    self:setVisible(true)
    
    self:runCsbAction("start",false,function()
        self.m_isOver = false
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    结束动作
]]
function GirlsCookCollectMenu:overAni(func)
    self.m_isOver = true
    self:runCsbAction("over",false,function()
        self:setVisible(false)
    end)
    self.m_machine:delayCallBack(20 / 60,function()
        self:hideAllMenu()
    end)
end

--[[
    初始化食物
]]
function GirlsCookCollectMenu:initFood(dishData)
    self.m_foodItem = nil
    if not dishData then
        return
    end

    --变更菜单
    if dishData.collectType == "TIME" then
        self:changeMenu(STATUS_WITH_TIMER)
        
    elseif dishData.collectType == "COUNT" and dishData.spinCount < dishData.firstCount then
        self:changeMenu(STATUS_WITH_SPINCOUNT_1)
        self:updateLeftTimes(dishData)
    else
        self:changeMenu(STATUS_WITH_SPINCOUNT_2)
        self:updateLeftTimes(dishData)
    end

    --刷新奖励
    self:updateReward(dishData)
end


--[[
    刷新剩余次数
]]
function GirlsCookCollectMenu:updateLeftTimes(dishData)
    local leftTimes = dishData.firstCount - dishData.spinCount
    if leftTimes <= 0 then
        leftTimes = dishData.secondCount - dishData.spinCount

        self:changeMenu(STATUS_WITH_SPINCOUNT_2)
    end
end

--[[
    刷新奖金
]]
function GirlsCookCollectMenu:updateReward(dishData)
    local curBet = globalData.slotRunData:getCurTotalBet()
    if not dishData.baseAmount or dishData.baseAmount == 0 then
        local reward = curBet * dishData.totalReward
        self.m_csb_coins:findChild("m_lb_coins_0"):setString(util_formatCoins(reward or 0,3))
    else
        self.m_csb_coins:findChild("m_lb_coins_0"):setString(util_formatCoins(dishData.baseAmount or 0,3))
    end

    if not dishData.extraAmount or dishData.extraAmount == 0 then
        local reward = curBet * dishData.totalReward
        self:findChild("m_lb_extra"):setString(util_formatCoins(reward or 0,3))
    else
        self:findChild("m_lb_extra"):setString(util_formatCoins(dishData.extraAmount or 0,3))
    end
    
    self:findChild("m_lb_mul"):setString("X"..util_formatCoins(dishData.timeWithinMultiple or 0,3))
end

--[[
    修改父节点
]]
function GirlsCookCollectMenu:changeParent(node,newParent)
    local parent = node:getParent()
    if parent == newParent then
        return
    end

    util_changeNodeParent(newParent,node)
end


return GirlsCookCollectMenu