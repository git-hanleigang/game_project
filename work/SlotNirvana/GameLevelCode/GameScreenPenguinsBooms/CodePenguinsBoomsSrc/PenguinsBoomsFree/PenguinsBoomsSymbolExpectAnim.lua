--[[
    处理scatter期待动画
]]
local PenguinsBoomsSymbolExpectAnim = class("PenguinsBoomsSymbolExpectAnim", cc.Node)

function PenguinsBoomsSymbolExpectAnim:initData_(_data)
    --[[
        _data = {
            machine    = machine,
        }
    ]]
    self.m_initData      = _data
    self.m_machine     = _data.machine

    self.m_symbolList = {}
    self.m_symbolPool = {}
end


function PenguinsBoomsSymbolExpectAnim:playExpectAnim(_iCol, _iRow, _symbolType)
    local sMsg = "[PenguinsBoomsSymbolExpectAnim:playExpectAnim] "
    sMsg = string.format("%s %d %d %d", sMsg, _iCol or 0, _iRow or 0, _symbolType or 999)
    util_printLog(sMsg, true)

    if not _iRow then
        for iCol=1,_iCol do
            for iRow=1,self.m_machine.m_iReelRowNum do
                local slotsNode = self.m_machine:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotsNode.p_symbolType == _symbolType and not slotsNode.m_playBuling then
                    local tempSymbol = self:createExpectAnim(iCol, iRow, _symbolType)
                    tempSymbol:runAnim("idleframe1", true)
                end
            end
        end
    else
        local tempSymbol = self:createExpectAnim(_iCol, _iRow, _symbolType)
        tempSymbol:runAnim("idleframe1", true)
    end 
end
function PenguinsBoomsSymbolExpectAnim:createExpectAnim(_iCol, _iRow, _symbolType)
    local spine = nil
    for i,_symbolNode in ipairs(self.m_symbolPool) do
        if _symbolNode.m_symbolType == _symbolType then
            spine = table.remove(self.m_symbolPool, i)
            break
        end
    end
    if nil == spine then
        spine = self.m_machine:createPenguinsBoomsTempSymbol({
            symbolType = _symbolType,
            machine    = self,
        })
        self:addChild(spine)
        spine:setVisible(false)
    end

    local slotsNode = self.m_machine:getFixSymbol(_iCol, _iRow, SYMBOL_NODE_TAG)
    local slotsPos  = util_convertToNodeSpace(slotsNode, self)
    spine:setPosition(slotsPos)
    spine:setVisible(true)

    table.insert(self.m_symbolList, spine)
    return spine
end
function PenguinsBoomsSymbolExpectAnim:stopExpectAnim()
    for i,_tempSymbol in ipairs(self.m_symbolList) do
        _tempSymbol:runAnim("idleframe", false)
        _tempSymbol:setVisible(false)
        table.insert(self.m_symbolPool, _tempSymbol)
    end
    self.m_symbolList = {}
end

return PenguinsBoomsSymbolExpectAnim