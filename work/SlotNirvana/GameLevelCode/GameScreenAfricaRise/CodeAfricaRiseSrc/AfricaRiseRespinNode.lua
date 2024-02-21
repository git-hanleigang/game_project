-----
---
---
-----
local RespinNode = util_require("Levels.RespinNode")
local AfricaRiseRespinNode = class("AfricaRiseRespinNode", RespinNode)

local NODE_TAG = 10
local MOVE_SPEED = 2200 --滚动速度 像素/每秒
local RES_DIS = 10
local RES_DIS_QUICKSTOP = 15

--子类可以重写修改滚动参数
function AfricaRiseRespinNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end
--创建slotsnode 播放动画
function AfricaRiseRespinNode:playCreateSlotsNodeAnima(node)
end

--获取回弹action
function AfricaRiseRespinNode:getBaseResAction(startPos)
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

--回弹action
function AfricaRiseRespinNode:runBaseResAction()
    local downDelayTime = RespinNode.runBaseResAction(self)
    if self.m_isQuickStop then
        if self.m_rsView and self.m_rsView.m_isPlayedSound == false then
            gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_reel_stop2.mp3")  
            self.m_rsView.m_isPlayedSound = true
        end
    else
        performWithDelay(self,function()
            gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_reel_stop.mp3")   
        end,(downDelayTime - 0.2 - 0.1))
    end
    return downDelayTime
end

function AfricaRiseRespinNode:getPosReelIdx(iRow, iCol)
    local index = (5 - iRow) * 5 + (iCol - 1)
    -- print(index .. "  ------------")
    return index + 1
end

return AfricaRiseRespinNode
