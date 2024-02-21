--[[
    层级进度条
]]
-- local ballFirstPosY = 0
-- local ballInterval = 115
-- local ballHeight = 100
local CSMainProgress = class("CSMainProgress", BaseView)

function CSMainProgress:initDatas()
    self.m_curShowBallIndex = self:getProgress() -- 缓存当前指针指向的层级
    self.m_ballFirstPosY = 0
    self.m_ballInterval = 115
end

function CSMainProgress:getCsbName()
    return CardSeekerCfg.csbPath .. "Seeker_MainLayer_Progress.csb"
end

function CSMainProgress:initCsbNodes()
    self.m_lbNum = self:findChild("lb_guanqia")
    self.m_spNormalBox = self:findChild("sp_bg_normal")
    self.m_spSpecialBox = self:findChild("sp_bg_special")
    self.m_nodeArrow = self:findChild("node_arrow")
    self.m_nodeBalls = self:findChild("node_balls")
    self.m_oriPosY = self.m_nodeBalls:getPositionY()
    self.m_panelBall = self:findChild("Panel_clip")
    self.m_panelBallSize = self.m_panelBall:getContentSize()
end

function CSMainProgress:initUI()
    CSMainProgress.super.initUI(self)
    self:initView()
end

function CSMainProgress:initView()
    self:initIcon()
    self:initProgress()
    self:initArraw()
    self:initBalls()
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CSMainProgress:initIcon()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local curLevelConfig = GameData:getCurLevelConfig()
    if not curLevelConfig then
        return
    end
    local special = curLevelConfig:getSpecial()
    self.m_spNormalBox:setVisible(special == CardSeekerCfg.LevelType.normal)
    self.m_spSpecialBox:setVisible(special == CardSeekerCfg.LevelType.special)
end

function CSMainProgress:initProgress()
    local cur, max = self:getProgress()
    if cur and max and cur > 0 and max > 0 then
        self.m_lbNum:setString(cur .. "/" .. max)
    else
        self.m_lbNum:setString("")
    end
end

function CSMainProgress:initArraw()
    self.m_arraw = util_createAnimation(CardSeekerCfg.csbPath .. "Seeker_MainLayer_Progress_arraw.csb")
    self.m_nodeArrow:addChild(self.m_arraw)
end

function CSMainProgress:initBalls()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local curIndex = GameData:getCurLevelIndex()
    local count = GameData:getLevelCount()
    if not (count and count > 0) then
        return
    end
    self.m_balls = {}
    self.m_ballYs = {}
    for i = 1, count do
        local ball = util_createView(CardSeekerCfg.luaPath .. "mainUI.CSMainProgressBall", i)
        self.m_nodeBalls:addChild(ball)
        local ballY = self.m_ballFirstPosY - self.m_ballInterval * (i - 1)
        ball:setPosition(cc.p(0, ballY))
        table.insert(self.m_balls, ball)
        table.insert(self.m_ballYs, ballY)
    end
    local ballsY = self.m_oriPosY + self.m_ballInterval * (curIndex - 1)
    self.m_nodeBalls:setPositionY(ballsY)
    self:setBallVisible()
end

-- 露出面积在30%以上才显示
function CSMainProgress:setBallVisible()
    local ballsY = self.m_nodeBalls:getPositionY()
    for i = 1, #self.m_ballYs do
        local ball = self.m_balls[i]
        local ballY = self.m_ballYs[i]
        local ballRealY = ballsY + ballY
        local isVisible = true
        if ballRealY <= 0 then
            isVisible = false
        end
        if ballRealY >= self.m_panelBallSize.height then
            isVisible = false
        end
        ball:setVisible(isVisible)
    end
end

function CSMainProgress:playArrawLightStart()
    self.m_arraw:playAction(
        "light_start",
        false,
        function()
            if not tolua.isnull(self) then
                self.m_arraw:playAction("light_idle", true, nil, 60)
            end
        end,
        60
    )
end
function CSMainProgress:playArrawLightOver()
    self.m_arraw:playAction("light_over", false, nil, 60)
end

function CSMainProgress:moveBalls(_moveOver)
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local nextBallIndex = GameData:getCurLevelIndex()
    if nextBallIndex == self.m_curShowBallIndex then
        if _moveOver then
            _moveOver()
        end
        return
    end

    -- 添加一个计时器实时检测位置做显隐
    if self.m_timer then
        self:stopAction(self.m_timer)
        self.m_timer = nil
    end
    self.m_timer =
        schedule(
        self.m_nodeBalls,
        function()
            self:setBallVisible()
        end,
        0.01
    )
    -- 移动效果
    local lastBallIndex = self.m_curShowBallIndex
    self.m_curShowBallIndex = nextBallIndex
    -- 箭头光消失，移动
    -- 移动结束时，箭头光出现，球光出现
    local posX = self.m_nodeBalls:getPositionX()
    local posY = self.m_nodeBalls:getPositionY()
    local actionList = {}
    actionList[#actionList + 1] =
        cc.Spawn:create(
        cc.CallFunc:create(
            function()
                if not tolua.isnull(self) then
                    self:playArrawLightOver()
                end
            end
        ),
        cc.MoveTo:create(0.5, cc.p(posX, posY + self.m_ballInterval))
    )
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if not tolua.isnull(self) then
                self:playArrawLightStart()
                self:initProgress()
                self:initIcon()
                self.m_balls[lastBallIndex]:resetView()
                self.m_balls[nextBallIndex]:resetView()
                if self.m_timer then
                    self:stopAction(self.m_timer)
                    self.m_timer = nil
                end
                if _moveOver then
                    _moveOver()
                end
            end
        end
    )
    self.m_nodeBalls:runAction(cc.Sequence:create(actionList))
end

function CSMainProgress:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

function CSMainProgress:getProgress()
    local GameData = self:getTSGameData()
    if not GameData then
        return
    end
    local cur = GameData:getCurLevelIndex()
    local max = GameData:getLevelCount()
    return cur, max
end

return CSMainProgress
