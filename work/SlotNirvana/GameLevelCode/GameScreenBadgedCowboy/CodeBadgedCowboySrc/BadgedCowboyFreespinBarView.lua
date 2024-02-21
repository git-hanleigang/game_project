---
--xcyy
--2018年5月23日
--BadgedCowboyFreespinBarView.lua

local BadgedCowboyFreespinBarView = class("BadgedCowboyFreespinBarView",util_require("Levels.BaseLevelDialog"))

BadgedCowboyFreespinBarView.m_freespinCurrtTimes = 0


function BadgedCowboyFreespinBarView:initUI()

    self:createCsbNode("BadgedCowboy_bar.csb")

    self:runCsbAction("idle", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end


function BadgedCowboyFreespinBarView:onEnter()

    BadgedCowboyFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function BadgedCowboyFreespinBarView:onExit()

    BadgedCowboyFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

function BadgedCowboyFreespinBarView:setRespinCoins(_type, _sScore)
    local sScore = _sScore
    local topCoins = self:findChild("m_lb_coins_1")
    topCoins:setString(sScore)
end

--respin相关
function BadgedCowboyFreespinBarView:setRespinAni()
    self:findChild("m_lb_coins_1"):setString("")
    self:runCsbAction("switch2", false, function()
        self:runCsbAction("idle2", true)
    end)
end

function BadgedCowboyFreespinBarView:addRespinTopCoins(_coins)
    local coins = _coins
    -- performWithDelay(self.m_scWaitNode, function()
        self:runCsbAction("actionframe1", false, function()
            -- self:runCsbAction("idle2", true)
        end)
        self:findChild("m_lb_coins_1"):setString(coins)
    -- end, 15/60)
end

function BadgedCowboyFreespinBarView:setRespinEndAni()
    self:findChild("m_lb_coins_2"):setString("")
    self:runCsbAction("switch3", false, function()
        self:runCsbAction("idle3", true)
    end)
end

--最后收集加钱
function BadgedCowboyFreespinBarView:addRespinTopEndCoins(_coins)
    local coins = _coins
    -- performWithDelay(self.m_scWaitNode, function()
        self:runCsbAction("jiesuan", false, function()
            -- self:runCsbAction("idle3", true)
        end)
        self:findChild("m_lb_coins_2"):setString(coins)
    -- end, 15/60)
end

--free相关
function BadgedCowboyFreespinBarView:setFreeAni(_isFreeMore)
    if not _isFreeMore then
        self:updateFreespinCount(0, "")
        self:findChild("m_lb_num"):setString("")
        self:runCsbAction("switch1", false, function()
            self:runCsbAction("idle1", true)
        end)
    end
end

function BadgedCowboyFreespinBarView:addFreeTopLeftCount(_count)
    local count = _count
    -- performWithDelay(self.m_scWaitNode, function()
        self:runCsbAction("actionframe", false, function()
            -- self:runCsbAction("idle1", true)
        end)
        self:updateFreespinCount(count, "")
    -- end, 15/60)
end

---
-- 更新freespin 剩余次数
--
function BadgedCowboyFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BadgedCowboyFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    if curtimes == 1 then
        self:findChild("freegame"):setVisible(true)
        self:findChild("freegames"):setVisible(false)
    else
        self:findChild("freegame"):setVisible(false)
        self:findChild("freegames"):setVisible(true)
    end
    
    self:findChild("m_lb_num"):setString(curtimes)
end

return BadgedCowboyFreespinBarView
