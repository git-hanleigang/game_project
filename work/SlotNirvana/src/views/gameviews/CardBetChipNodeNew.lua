--[[
    author:{author}
    time:2019-09-27 22:00:34
]]
local CardBetChipNode = class("CardBetChipNode", BaseView)

function CardBetChipNode:getLabelSize()
    local pLayer = self:findChild("Panel_size")
    if pLayer then
        local pSize = pLayer:getContentSize()
        pSize.height = math.min(pSize.height, 140)
        return cc.size(pSize.width, pSize.height)
    end
    return cc.size(280, 110)
end

function CardBetChipNode:initDatas()
    self.m_curBetIndex = self:getCurBetIndex()
end

function CardBetChipNode:getCsbName()
    return "CardBetChip/NewBetTip/CardBetChip.csb"
end

function CardBetChipNode:initCsbNodes()
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

function CardBetChipNode:initUI()
    CardBetChipNode.super.initUI(self)
    self:initProgressValue()
end

function CardBetChipNode:initProgressValue()
    self:initClip()
    self:initProgressBar()
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

function CardBetChipNode:initProgressBar()
    if not (globalData.slotRunData and globalData.slotRunData.machineData) then
        return
    end    
    local percent = self:getBetPercent(self.m_curBetIndex)
    self:updateProgressBar(percent)
end

function CardBetChipNode:changeBet()
    if not (globalData.slotRunData and globalData.slotRunData.machineData) then
        return
    end

    local nowIdx = self:getCurBetIndex()
    print("CardBetChipNode:changeBet=",nowIdx)
    if nowIdx == self.m_curBetIndex then
        return
    end
    local preIdx = self.m_curBetIndex
    self.m_curBetIndex = nowIdx    

    local prePercent = self:getBetPercent(preIdx)
    local nowPercent = self:getBetPercent(nowIdx)

    self:__changeProgress(prePercent, nowPercent)
end

function CardBetChipNode:__changeProgress(_prePercent, _nowPercent)

    if self.m_isChanging == true and self.m_target ~= nil then
        self:removeChangeTimer()
        self:updateProgressBar(self.m_target)
        self.m_isChanging = false
    end

    self.m_isChanging = true

    local cur = _prePercent
    local target = _nowPercent
    self.m_target = target
    
    local frameChange = (target - cur)/10
    if frameChange > 0 and frameChange < 1 then
        frameChange = 1
    elseif frameChange < 0 and frameChange > -1 then
        frameChange = -1
    end
    print("CardBetChipNode cur, target, frameChange=", cur, target, frameChange)

    self:updateProgressBar(cur)

    self.m_changeTimer =
        util_schedule(
        self,
        function()
            cur = cur + frameChange
            if frameChange > 0 and cur >= target then
                cur = target
                self:removeChangeTimer()
                self.m_isChanging = false
            elseif frameChange < 0 and cur <= target then
                cur = target
                self:removeChangeTimer()
                self.m_isChanging = false
            end
            self:updateProgressBar(cur)
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

function CardBetChipNode:updateProgressBar(_percent, isInit)
    self.m_progressBar:setPercent(_percent)

    local w = self.m_proBarSize.width * (_percent * 0.01)
    self.m_clipLayer:setContentSize(cc.size(w, self.m_proBarSize.height))

    local x = self.m_proBarSize.width * (_percent * 0.01)
    self.m_loadingbarParticle:setPositionX(x)

    -- 当进度条满的时候，播放粒子特效，宝箱变亮
    self.m_boxParticle:setVisible(_percent == 100)
    self.m_spBoxLight:setVisible(_percent == 100)

    -- 宝箱大小变化
    if not isInit then
        self.m_boxNode:setScale(1 + _percent * 0.01 * 0.1) -- 100-110之间
    end
end


function CardBetChipNode:onEnter()
    CardBetChipNode.super.onEnter(self)
    
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:changeBet()
        end,
        ViewEventType.NOTIFY_BET_CHANGE
    )
end

function CardBetChipNode:onExit()
    CardBetChipNode.super.onExit(self)
    self:removeChangeTimer()
end

function CardBetChipNode:getCurBetIndex()
    local curIndex = globalData.slotRunData:getCurBetIndex()
    return curIndex
end

function CardBetChipNode:getBetPercent(_betIndex)
    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    local percent = math.floor(_betIndex / (#betList) * 100)    
    return percent
end

return CardBetChipNode
