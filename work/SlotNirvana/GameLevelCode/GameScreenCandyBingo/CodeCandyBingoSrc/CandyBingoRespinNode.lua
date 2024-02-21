-----
---
---
-----
local RespinNode = util_require("Levels.RespinNode")
local CandyBingoRespinNode = class("CandyBingoRespinNode",RespinNode)

local MOVE_SPEED = 2200     --滚动速度 像素/每秒
--正常滚动  回弹高度应为图标的1/6
local RES_DIS = 18 --65
local RES_DIS_QUICKSTOP = 15

function CandyBingoRespinNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end
--修正裁切坐标
function CandyBingoRespinNode:changeNodePos()
      --偏移裁切区域
      if self.p_colIndex == 2  then
        local pos = cc.pAdd(self.m_clipNode.originalPos,cc.p(0,1))
        self.m_clipNode:setPosition(pos)
    end
end
function CandyBingoRespinNode:getPosReelIdx(iRow, iCol)
    local index = (5 - iRow) * 5 + (iCol - 1)
    return index + 1
end
--获取回弹action
function CandyBingoRespinNode:getBaseResAction(startPos)
    --正常滚动时 回弹时间 0.2 回弹距离 1/6 图标
    local time1 = 0.2 
    local time2 = 0.2 
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
    timeDown = time1 + time2 
    return speedActionTable, timeDown
end
--回弹action
function CandyBingoRespinNode:runBaseResAction()
    local downDelayTime = RespinNode.runBaseResAction(self)
    -- 一列只播一次改为由主轮盘播放
    -- if self.m_isQuickStop then
    --     if self.m_rsView and self.m_rsView.m_isPlayedSound == false then
    --         gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_reels_stop.mp3")  
    --         self.m_rsView.m_isPlayedSound = true
    --     end
    -- else
    --     if self.m_lastNode.p_rowIndex and self.m_lastNode.p_cloumnIndex  then
    --         if self:getPosReelIdx(self.m_lastNode.p_rowIndex,self.m_lastNode.p_cloumnIndex) == 11 then
    --             performWithDelay(self,function(  )
    --                 gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_reels_stop.mp3")     
    --             end,(downDelayTime - 0.2 - 0.1) * 2)
    --         end 
    --     end
    --     performWithDelay(self,function()
    --         gLobalSoundManager:playSound("CandyBingoSounds/music_CandyBingo_reels_stop.mp3")   
    --     end,(downDelayTime - 0.2 - 0.1))
    -- end
    return downDelayTime
end
return CandyBingoRespinNode