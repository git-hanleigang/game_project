-----
---
---
-----
local RespinNode = util_require("Levels.RespinNode")
local FortuneCatsRespinNode = class("FortuneCatsRespinNode", RespinNode)
local MOVE_SPEED = 2600 --滚动速度 像素/每秒
local RES_DIS = 15
local RES_DIS_QUICKSTOP = 15

function FortuneCatsRespinNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end
--裁切位置
function FortuneCatsRespinNode:initClipNode()
    local nodeHeight = self.m_slotReelHeight / self.m_machineRow
    self.m_clipNode = cc.ClippingRectangleNode:create({x = -math.ceil(self.m_slotNodeWidth / 2), y = -nodeHeight / 2 + 4 , width = self.m_slotNodeWidth, height = nodeHeight - 6})
    if self.p_rowIndex == 1  then
        self.m_clipNode:setPosition(cc.p(0,1.06))
    elseif self.p_rowIndex == 2 then
        -- self.m_clipNode = cc.ClippingRectangleNode:create({x = -math.ceil(self.m_slotNodeWidth / 2), y = -nodeHeight / 2 + 4, width = self.m_slotNodeWidth, height = nodeHeight - 6})
    elseif self.p_rowIndex == 3 then
        -- self.m_clipNode = cc.ClippingRectangleNode:create({x = -math.ceil(self.m_slotNodeWidth / 2), y = -nodeHeight / 2+4 , width = self.m_slotNodeWidth, height = nodeHeight - 6})
        self.m_clipNode:setPosition(cc.p(0,-1.06))
    end
    self:addChild(self.m_clipNode)
end
--添加初始化
function FortuneCatsRespinNode:baseStartMove()
    self:initRunningData()
    RespinNode.baseStartMove(self)
end

--获取回弹action
function FortuneCatsRespinNode:getBaseResAction(startPos)
    local time1 = 0.2
    local time2 = 0.1
    local moveResDis = RES_DIS
    if self.m_isQuickStop then
        time1 = 0.1
        time2 = 0.05
        moveResDis = RES_DIS_QUICKSTOP
    end
    local dis =  startPos + moveResDis
    local timeDown = 0
    local speedActionTable = {}
    speedActionTable[#speedActionTable + 1] = cc.MoveBy:create(time1,cc.p(0, - moveResDis))
    speedActionTable[#speedActionTable + 1] = cc.MoveBy:create(time2,cc.p(0,moveResDis))
    timeDown = time1 + time2 + 0.1
    return speedActionTable, timeDown
end

function FortuneCatsRespinNode:getPosReelIdx(iRow, iCol)
    local index = (5 - iRow) * 5 + (iCol - 1)
    return index + 1
end

--回弹action
function FortuneCatsRespinNode:runBaseResAction()
    local downDelayTime = RespinNode.runBaseResAction(self)
    if self.m_isQuickStop then
        if self.m_rsView and self.m_rsView.m_isPlayedSound == false then
            gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_reel_stop2.mp3")  
            self.m_rsView.m_isPlayedSound = true
        end
    else
        performWithDelay(self,function()
            gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_reel_stop.mp3")   
        end,(downDelayTime - 0.2 - 0.1))
    end
    return downDelayTime
end

function FortuneCatsRespinNode:setRunLongNum(runNodeLen)
    self.m_runNodeNum = self.m_runNodeNum + runNodeLen
end

return FortuneCatsRespinNode
