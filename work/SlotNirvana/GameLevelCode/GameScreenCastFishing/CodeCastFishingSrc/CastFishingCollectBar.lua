local CastFishingCollectBar = class("CastFishingCollectBar",util_require("Levels.BaseLevelDialog"))

function CastFishingCollectBar:initDatas(_machine, _data)
    self.m_machine  = _machine

    self.m_progressValue = 0
end
function CastFishingCollectBar:initUI()

    self:createCsbNode("CastFishing_jindutiao.csb")

    self.m_fankuiAnim = util_createAnimation("CastFishing_jindutiao_fankui.csb")
    self:findChild("Node_fankui"):addChild(self.m_fankuiAnim)
    self.m_fankuiAnim:setVisible(false)

    local spProgress = self:findChild("sp_progress")
    local size = spProgress:getContentSize()
    self.m_progressSize  = cc.size(size.width, 180) 
    self.m_progressLayer = self:findChild("Layout_progress")

    local clipNode = cc.ClippingNode:create()
    self:findChild("Node_progress"):addChild(clipNode)

    self.m_processTimer = cc.ProgressTimer:create(util_createSprite("CastFishingUi/CastFishing_JinDu4_2.png"))
    self.m_processTimer:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.m_processTimer:setMidpoint(cc.p(1/size.height, 0.5))
    self:findChild("Node_progress"):addChild(self.m_processTimer)
    self.m_processTimer:setRotation(-90)
    self.m_processTimer:setOpacity(0)
    self.m_processTimer:setScale(3)
    
    clipNode:setStencil(self.m_processTimer)
    clipNode:setInverted(false)
    clipNode:setAlphaThreshold(1)
    local pos = util_convertToNodeSpace(self.m_progressLayer, clipNode)
    util_changeNodeParent(clipNode, self.m_progressLayer)
    self.m_progressLayer:setPosition(pos)

    self.m_areaRotation  = {50, 130}
    self.m_progressArrow = self:findChild("Panel_arrow")

    self:upDateProgress(0)
    self:runCsbAction("idle", true)
end


function CastFishingCollectBar:changeProgress(_value, _playAnim, _fun)
    self.m_progressLayer:stopAllActions()

    if _playAnim then
        local finish = 100 == _value
        local animName = finish and "actionframe" or "fankui"

        if not finish then
            self:playCollectAnim(animName, function()
                local changeValue = _value > self.m_progressValue and 1 or -1
                schedule(self.m_progressLayer,function()
                    local nextValue = self.m_progressValue + changeValue
                    nextValue = math.max(0 ,nextValue)
                    nextValue = math.min(100 ,nextValue)
                    self:upDateProgress(nextValue)
    
                    local bBreak   = (nextValue == _value) or (nextValue == 0) or (nextValue == 100)
                    if bBreak then
                        self.m_progressLayer:stopAllActions()
                        if _fun then
                            _fun()
                        end
                    end
                end,0.08)
            end)
        else
            local changeValue = _value > self.m_progressValue and 1 or -1
            schedule(self.m_progressLayer,function()
                local nextValue = self.m_progressValue + changeValue
                nextValue = math.max(0 ,nextValue)
                nextValue = math.min(100 ,nextValue)
                self:upDateProgress(nextValue)

                local bBreak   = (nextValue == _value) or (nextValue == 0) or (nextValue == 100)
                if bBreak then
                    self.m_progressLayer:stopAllActions()
                    self:playCollectAnim(animName, function()
                        if _fun then
                            _fun()
                        end
                    end)
                end
            end,0.04)
        end

    else
        self:upDateProgress(_value)
        if _fun then
            _fun()
        end
    end
end


function CastFishingCollectBar:upDateProgress(_value)
    self.m_progressValue = _value
    --进度条
    local startP   = self.m_areaRotation[1] / 180 * 100
    local endP     = self.m_areaRotation[2] / 180 * 100
    local pregress = startP + (endP - startP) * (self.m_progressValue / 100)
    pregress = pregress * 0.5
    self.m_processTimer:setPercentage(pregress)

    --箭头
    self:upDateArrow(_value)
end
--[[
    箭头坐标角度
]]
function CastFishingCollectBar:upDateArrow(_value)
    local rotation = 0

    local progress = _value/100
    local startR = self.m_areaRotation[1] + 1
    local endR   = self.m_areaRotation[2] + 1
    rotation = startR + (endR - startR) * (progress)
    rotation = math.ceil(rotation)

    self.m_progressArrow:setRotation(rotation)
end

function CastFishingCollectBar:playCollectAnim(_animName, _fun)
    self.m_fankuiAnim:setVisible(true)
    self.m_fankuiAnim:runCsbAction(_animName, false, function()
        self.m_fankuiAnim:setVisible(false)
        if _fun then
            _fun()
        end
    end)
end

function CastFishingCollectBar:getCollectEndPos()
    local worldPos = cc.p(0,0)    
    local node = self:findChild("Node_fankui")
    worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))

    return worldPos
end
return CastFishingCollectBar