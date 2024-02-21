local CookieCrunchLineFrameManager = class("CookieCrunchLineFrameManager",util_require("Levels.BaseLevelDialog"))
--[[
    _data = {
        parent,          --cc.Node

    }
]]
-- 放在底层连线的父节点上面 
function CookieCrunchLineFrameManager:initDatas(_machine, _data)
    self.m_machine  = _machine
    self.m_lineFrameParent = _data[1]
end

function CookieCrunchLineFrameManager:initUI()
    self.m_lineFrameList = {}
    for iCol=1,self.m_machine.m_iReelColumnNum do
        self.m_lineFrameList[iCol] = {}
        for iRow=1,self.m_machine.m_iReelRowNum do
            local lineFrame = util_createAnimation("WinFrameCookieCrunch.csb")
            self.m_lineFrameParent:addChild(lineFrame)
            lineFrame:setVisible(false)
            
            self.m_lineFrameList[iCol][iRow] = lineFrame
        end
    end
end


function CookieCrunchLineFrameManager:upDataPosition()
    for _iCol,_colData in ipairs(self.m_lineFrameList) do
        for _iRow,_anim in ipairs(_colData) do
            local nodePos = util_getPosByColAndRow(self.m_machine, _iCol, _iRow)
            local slotParent = self.m_machine:getReelParent(_iCol)
            local wordPos    = slotParent:convertToWorldSpace( nodePos )
            local curPos     = self.m_lineFrameParent:convertToNodeSpace(wordPos)

            _anim:setPosition(curPos)
        end
    end
end

function CookieCrunchLineFrameManager:stopAllLineFrame()
    for _iCol,_colData in ipairs(self.m_lineFrameList) do
        for _iRow,_anim in ipairs(_colData) do
            self:stopLineFrame(_iCol, _iRow)
        end
    end
end
--[[
    单个连线框
]]
function CookieCrunchLineFrameManager:runLineFrame(_iCol, _iRow)
    local anim = self.m_lineFrameList[_iCol][_iRow]
    anim:setVisible(true)
    anim:runCsbAction("actionframe", true)
end
function CookieCrunchLineFrameManager:stopLineFrame(_iCol, _iRow)
    local anim = self.m_lineFrameList[_iCol][_iRow]
    util_setCsbVisible(anim, false)
end


return CookieCrunchLineFrameManager