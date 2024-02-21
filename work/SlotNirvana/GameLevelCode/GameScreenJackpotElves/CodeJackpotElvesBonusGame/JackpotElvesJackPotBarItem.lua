---
--xcyy
--2018年5月23日
--JackpotElvesJackPotBarItem.lua

local JackpotElvesJackPotBarItem = class("JackpotElvesJackPotBarItem",util_require("Levels.BaseLevelDialog"))

local JACKPOT_TYPE = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini"
}

function JackpotElvesJackPotBarItem:initUI(params)
    self.m_csbName = params.csbName
    self.m_jackpotType = params.jackpotType
    self:createCsbNode(self.m_csbName)

    --收集进度
    self.m_collectItems = {}
    for index = 1,3 do
        local item = util_createAnimation("JackpotElves_jackpot_point.csb")
        self:findChild("Node_point"..index):addChild(item)
        self.m_collectItems[index] = item

        --刷新显示
        for k,jackpotType in pairs(JACKPOT_TYPE) do
            item:findChild("Node_"..jackpotType):setVisible(jackpotType == self.m_jackpotType)
        end

    end

    if self.m_jackpotType == "epic" then
        self.m_nodeLock = util_createAnimation("JackpotElves_jackpotsuo_epic.csb")
    elseif self.m_jackpotType == "grand" then
        self.m_nodeLock = util_createAnimation("JackpotElves_jackpotsuo_grand.csb")
    end
    if self.m_nodeLock ~= nil then
        self:findChild("Node_suo"):addChild(self.m_nodeLock)
        self.m_nodeLock:setVisible(false)
        self.m_nodeLock:pauseForIndex(0)
    end
    
end
--[[
    锁定jackpot
]]
function JackpotElvesJackPotBarItem:showLockIdle()
    self:runCsbAction("idle2")
    self.m_nodeLock:setVisible(true)
end
--[[
    显示压暗
]]
function JackpotElvesJackPotBarItem:showDarkAni(func)
    if self.m_isDarkStatus then
        return
    end

    self.m_isDarkStatus = true
    self:runCsbAction("dark")
    self:showAllCollect()
end

--新增绿色压黑
function JackpotElvesJackPotBarItem:showDarkAniForLv(func)
    if self.m_isDarkStatus then
        return
    end

    self.m_isDarkStatus = true
    self:runCsbAction("dark1_idle",false,function ()
        self:runCsbAction("dark1_idle",true)
    end)
    self:showAllCollect()
end

--[[
    获取收集点
]]
function JackpotElvesJackPotBarItem:getCollectItem(count)
    return self.m_collectItems[count]
end
--[[
    重置显示
]]
function JackpotElvesJackPotBarItem:resetShow()
    self.m_isDarkStatus = false
    self.m_count = 0
    self:runIdleAnim()
    --重置收集点
    for i,item in ipairs(self.m_collectItems) do
        item:playAction("idle1")
    end
end

--[[
    刷新收集数量
]]
function JackpotElvesJackPotBarItem:updateCollectCount(count,func)
    local item = self.m_collectItems[count]
    self.m_count = count
    item:playAction("fankui2", false)
    self:delayCallBack(28/60,function ()
        if count == 2 then
            self.m_collectItems[3]:playAction("idle3_start", false, function ()
                self.m_collectItems[3]:playAction("idle3", true)
            end)
        else
            item:playAction("idle2")
        end
    end)
end

--[[
    中奖动画
]]
function JackpotElvesJackPotBarItem:runRewardAnim()
    self:runCsbAction("actionframe", true)
end

--[[
    idle 动画
]]
function JackpotElvesJackPotBarItem:runIdleAnim()
    self:runCsbAction("idle")
    if self.m_nodeLock ~= nil then
        self.m_nodeLock:setVisible(false)
    end
    
end

--[[
    取消期待动画
]]
function JackpotElvesJackPotBarItem:expectOverAnim()
    if self.m_count == 2 then
        self.m_collectItems[3]:playAction("idle3_over")
    end
end

--[[
    一次展示剩余的收集
]]
function JackpotElvesJackPotBarItem:showAllCollect()
    while self.m_count < 3 do
        self.m_count = self.m_count + 1
        self.m_collectItems[self.m_count]:playAction("fankui2")
    end
end

--[[
    延迟回调
]]
function JackpotElvesJackPotBarItem:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return JackpotElvesJackPotBarItem