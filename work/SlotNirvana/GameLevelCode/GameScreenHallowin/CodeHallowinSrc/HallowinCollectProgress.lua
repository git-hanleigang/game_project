---
--xcyy
--2018年5月23日
--HallowinCollectProgress.lua

local HallowinCollectProgress = class("HallowinCollectProgress",util_require("base.BaseView"))
local COLLECT_NUM = 20

function HallowinCollectProgress:initUI()

    self:createCsbNode("Hallowin_xiaoyouljindutiao.csb")

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
    local startPosX = self:findChild("start"):getPositionX()
    local endPosX = self:findChild("end"):getPositionX()
    local distance = (endPosX - startPosX) / (COLLECT_NUM - 1)
    self.m_vecProgressItems = {}
    for i = 1, COLLECT_NUM, 1 do
        local item = util_createAnimation("Hallowin_shoujixiaoyouling.csb")
        self:addChild(item)
        item:setPosition(startPosX + (i - 1) * distance, 0)
        item:playAction("idle1")
        local particle = item:findChild("Particle_1")
        particle:stopSystem()
        self.m_vecProgressItems[#self.m_vecProgressItems + 1] = item
    end
    self.m_percet = 0
end

function HallowinCollectProgress:initProgress(collectNum)
    for i = 1, collectNum, 1 do
        local item = self.m_vecProgressItems[i]
        item:playAction("idle2")
    end
    self.m_percet = collectNum
end

function HallowinCollectProgress:updateProgress(addNum)
    for i = self.m_percet + 1, self.m_percet + addNum, 1 do
        local item = self.m_vecProgressItems[i]
        item:playAction("actionframe2")
        local particle = item:findChild("Particle_1")
        particle:resetSystem()
    end
    self.m_percet = self.m_percet + addNum
end

function HallowinCollectProgress:getEndNode(index)
    if self.m_percet ~= nil and self.m_percet + index <= COLLECT_NUM then
        return self.m_vecProgressItems[self.m_percet + index]
    end
end

function HallowinCollectProgress:resetProgress()
    for i = 1, #self.m_vecProgressItems, 1 do
        local item = self.m_vecProgressItems[i]
        item:playAction("idle1")
    end
    self.m_percet = 0
end

function HallowinCollectProgress:completedAnim()
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_collect_completed.mp3")
    for i = 1, #self.m_vecProgressItems, 1 do
        local item = self.m_vecProgressItems[i]
        item:playAction("actionframe1")
    end
end

function HallowinCollectProgress:onEnter()

end

function HallowinCollectProgress:onExit()
 
end

--默认按钮监听回调
function HallowinCollectProgress:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return HallowinCollectProgress