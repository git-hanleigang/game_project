local MrCashGoLevelBoxManager = class("MrCashGoLevelBoxManager",util_require("Levels.BaseLevelDialog"))

function MrCashGoLevelBoxManager:initDatas(_machine)
    self.m_machine  = _machine
end

function MrCashGoLevelBoxManager:initUI()
    
    self.m_levelBoxIcons = {}
    for iCol=1,self.m_machine.m_iReelColumnNum do
        self.m_levelBoxIcons[iCol] = {}
        for iRow=1,self.m_machine.m_iReelRowNum do
            
            local levelBox = util_createView("CodeMrCashGoSrc.MrCashGoLevelBoxIcon", self.m_machine)
            self:addChild(levelBox)
            local order = 10 - iRow
            levelBox:setLocalZOrder(order)
            levelBox:setVisible(false)

            self.m_levelBoxIcons[iCol][iRow] = levelBox

        end
    end
end

function MrCashGoLevelBoxManager:upDatelevelBoxPos()
    for _iCol,_colData in ipairs(self.m_levelBoxIcons) do
        for _iRow,_levelBox in ipairs(_colData) do
            local nodePos = util_getPosByColAndRow(self.m_machine, _iCol, _iRow)
            local slotParent = self.m_machine:getReelParent(_iCol)
            local wordPos = slotParent:convertToWorldSpace( nodePos )
            local curPos = self:convertToNodeSpace(wordPos)
            curPos.y = math.floor(curPos.y)
            -- print("[MrCashGoLevelBoxManager:upDatelevelBoxPos] ",_iCol,_iRow, curPos.x,curPos.y)

            _levelBox:setPosition(curPos)
        end
    end
end
-- free结束时淡出背景框并清理数据
function MrCashGoLevelBoxManager:clearLevelBoxList()
    local time = 0
    for _iCol,_colData in ipairs(self.m_levelBoxIcons) do
        for _iRow,_levelBox in ipairs(_colData) do
            _levelBox:clearIconData()
            _levelBox:resetIconShow()
            _levelBox:setVisible(false)
        end
    end

    return time
end

function MrCashGoLevelBoxManager:upDateLevelBoxData(_iCol, _iRow, _data)
    local levelBox = self.m_levelBoxIcons[_iCol][_iRow]
    levelBox:setIconData(_data)
end

-- 断线重连
function MrCashGoLevelBoxManager:upDateLevelBoxIconReconnect(_levelBoxDataList)
    for _boxLevel,_boxPosList in ipairs(_levelBoxDataList) do
        for i,_pos in ipairs(_boxPosList) do
            
            local iPos = tonumber(_pos)
            local fixPos = self.m_machine:getRowAndColByPos(iPos)
            local levelBox = self.m_levelBoxIcons[fixPos.iY][fixPos.iX]
            local iconData = {
                symbolType = self.m_machine:getLevelBoxSymbolType(_boxLevel),             
            }

            levelBox:setIconData(iconData)
            levelBox:upDateFrameShow()
            levelBox:setVisible(true)

        end
    end
end

-- 刷新框体展示 _isTransfer : 是否是弹射升级
function MrCashGoLevelBoxManager:upDateLevelBoxIcon(_iCol, _iRow, _data, _playSound, _isTransfer)
    local levelBox = self.m_levelBoxIcons[_iCol][_iRow]
    self:upDateLevelBoxData(_iCol, _iRow, _data)
    levelBox:setVisible(true)

    return levelBox:upDateFrameShow(_playSound, _isTransfer)
end
-- 展示赢钱背景
function MrCashGoLevelBoxManager:upDateCoinsBgShow(_iCol, _iRow)
    local levelBox = self.m_levelBoxIcons[_iCol][_iRow]
    return levelBox:upDateCoinsBgShow()
end
-- 展示赢钱
function MrCashGoLevelBoxManager:upDateCoinsShow(_iCol, _iRow)
    local levelBox = self.m_levelBoxIcons[_iCol][_iRow]
    return levelBox:upDateCoinsShow()
end


function MrCashGoLevelBoxManager:getLevelBox(_iCol, _iRow)
    local levelBox = self.m_levelBoxIcons[_iCol][_iRow]
    return levelBox
end


return MrCashGoLevelBoxManager