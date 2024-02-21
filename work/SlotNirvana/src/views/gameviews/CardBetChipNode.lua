--[[
    author:{author}
    time:2019-09-27 22:00:34
]]
local CardBetChipNode = class("CardBetChipNode", util_require("base.BaseView"))
function CardBetChipNode:initUI()
    self:createCsbNode("CardBetChip/CardBetChip.csb")

    self:initNode()
    self:initProgressValue()

    self:setUIShow(false)

    -- 隐藏界面计时器
    self.m_hideTime = 3
    if self.m_hideTimer == nil then
        self:initHideTimer()
    end
end

function CardBetChipNode:initNode()
    self.m_boxNode = self:findChild("Node_box")
    self.m_spBoxLight = self:findChild("sp_box_liang")
    self.m_clipLayer = self:findChild("clip_layer")
    self.m_fly2leftParticle = self:findChild("Particle_fly2left")
    self.m_loadingbarParticle = self:findChild("Particle_loadingbar")
    self.m_boxParticle = self:findChild("Particle_box")
    self.m_boxParticle:setVisible(false)
    self.m_progressBar = self:findChild("LoadingBar_1")
    self.m_proBarSize = self.m_progressBar:getContentSize()
end

function CardBetChipNode:initProgressValue()
    self:initClip()
    self:updateProgressBar(0, true)
end

function CardBetChipNode:initClip()
    -- 设置进度条的遮罩处理
    local mask = display.newSprite("CardBetChip/ui/CHIPBET_JINDUDING.png")
    mask:setAnchorPoint(0, 0.5)
    local clip_node = cc.ClippingNode:create()
    clip_node:setAlphaThreshold(0.9)
    clip_node:setStencil(mask)
    clip_node:setPosition(0, self.m_proBarSize.height * 0.5)
    self.m_progressBar:addChild(clip_node)

    -- 裁切往左飞的粒子
    self.m_clipLayer:removeFromParent()
    clip_node:addChild(self.m_clipLayer)
    self.m_clipLayer:setAnchorPoint(0, 0.5)
    self.m_clipLayer:setPosition(0, 0)

    -- 裁切竖线粒子
    self.m_loadingbarParticle:removeFromParent()
    clip_node:addChild(self.m_loadingbarParticle)
    self.m_loadingbarParticle:setPosition(self.m_proBarSize.width, 0)
end

function CardBetChipNode:initHideTimer()
    self.m_hideTimer =
        schedule(
        self,
        function()
            self.m_hideTime = self.m_hideTime - 1
            if self.m_hideTime <= 0 then
                self:removeHideTimer()
                return
            end
        end,
        1
    )
end

function CardBetChipNode:removeHideTimer()
    if self.m_hideTimer ~= nil then
        self:stopAction(self.m_hideTimer)
        self.m_hideTimer = nil
    end
    self:hideUI()
end

function CardBetChipNode:setUIShow(isShow)
    self.m_isUIShow = isShow
    self:setVisible(isShow)
end

function CardBetChipNode:isShowing()
    return self.m_isUIShow
end

function CardBetChipNode:playStart(overCall)
    self:runCsbAction(
        "show",
        false,
        function()
            if overCall then
                overCall()
            end
            self:runCsbAction("idle", true)
        end
    )
end

function CardBetChipNode:updateBoxScale()
end

function CardBetChipNode:popBetDefault(value)
    --  默认弹出，长得很快
    self:changeAction(value, true, true)
end

function CardBetChipNode:addBet(value, isUIShow)
    self:changeAction(value, nil, isUIShow)
end

function CardBetChipNode:delBet(value, isUIShow)
    self:changeAction(value, nil, isUIShow)
end

-- 动作
function CardBetChipNode:changeAction(value, isInit, isUIShow)
    if value == self.m_curValue then
        return
    end
    self.m_curValue = value

    if isUIShow then
        if isInit or (not self.m_isUIShow) then
            self:setUIShow(true)
            self:playStart(
                function()
                    self:changeBet(isInit)
                end
            )
        else
            self:changeBet()
        end
    end
end

-- 表现
function CardBetChipNode:changeBet(isInit)
    self:setUIShow(true)
    self:changeProgress(isInit)

    -- 隐藏界面计时器
    self.m_hideTime = 3
    if self.m_hideTimer == nil then
        self:initHideTimer()
    end
end

function CardBetChipNode:changeProgress(isInit)
    -- 变化量
    if isInit then
        self.m_chagneValue = math.max(1, self.m_curValue / 10)
    else
        if self.m_finalFrame and self.m_curValue < self.m_finalFrame then
            -- local changeValue = math.max(1, math.abs((self.m_finalFrame - self.m_curValue)/10))
            if self.m_finalFrame == 100 then
                -- 由100变到0
                self.m_chagneValue = -1 * math.max(1, math.abs((self.m_finalFrame - self.m_curValue) / 10))
            else
                self.m_chagneValue = -1
            end
        else
            if self.m_curValue == 100 then
                -- 由0涨到100
                self.m_finalFrame = self.m_finalFrame or 0
                self.m_chagneValue = 1 * math.max(1, math.abs((self.m_finalFrame - self.m_curValue) / 10))
            else
                self.m_chagneValue = 1 -- *math.max(1, self.m_curValue/10)
            end
        end
    end

    -- 最终值赋值
    self.m_finalFrame = self.m_curValue

    -- 第一次
    if not self.m_curFrame then
        self.m_curFrame = 0
        self:updateProgressBar(self.m_curFrame, isInit)
    end

    self.m_changeTimer =
        util_schedule(
        self,
        function()
            self.m_curFrame = self.m_curFrame + self.m_chagneValue
            if self.m_chagneValue > 0 and self.m_curFrame > self.m_finalFrame then
                self.m_curFrame = self.m_finalFrame
                self:removeChangeTimer()
            elseif self.m_chagneValue < 0 and self.m_curFrame < self.m_finalFrame then
                self.m_curFrame = self.m_finalFrame
                self:removeChangeTimer()
            end

            self:updateProgressBar(self.m_curFrame, isInit)
        end,
        0.01
    )
end

function CardBetChipNode:removeChangeTimer()
    if self.m_changeTimer ~= nil then
        self:stopAction(self.m_changeTimer)
        self.m_changeTimer = nil
    end
end

function CardBetChipNode:updateProgressBar(value, isInit)
    self.m_progressBar:setPercent(value)

    local w = self.m_proBarSize.width * (value * 0.01)
    self.m_clipLayer:setContentSize(cc.size(w, self.m_proBarSize.height))

    local x = self.m_proBarSize.width * (value * 0.01)
    self.m_loadingbarParticle:setPositionX(x)

    -- 当进度条满的时候，播放粒子特效，宝箱变亮
    self.m_boxParticle:setVisible(value == 100)
    self.m_spBoxLight:setVisible(value == 100)

    -- 宝箱大小变化
    if not isInit then
        self.m_boxNode:setScale(1 + value * 0.01 * 0.1) -- 100-110之间
    end
end

function CardBetChipNode:hideUI()
    if self.m_isUIShow == true then
        self:runCsbAction(
            "over",
            false,
            function()
                self:setUIShow(false)
            end
        )
    end
end

return CardBetChipNode
