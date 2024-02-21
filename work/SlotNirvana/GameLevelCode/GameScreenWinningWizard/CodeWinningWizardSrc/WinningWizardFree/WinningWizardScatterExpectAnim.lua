--[[
    处理scatter期待动画
]]
local WinningWizardScatterExpectAnim = class("WinningWizardScatterExpectAnim", cc.Node)

function WinningWizardScatterExpectAnim:initData_(_data)
    --[[
        _data = {
            machine = machine,
        }
    ]]
    self.m_initData      = _data
    self.m_machine     = _data.machine

    self.m_symbolList = {}
    self.m_symbolPool = {}
end


function WinningWizardScatterExpectAnim:playExpectAnim(_iCol, _iRow)
    if not _iRow then
        for iCol=1,_iCol-1 do
            for iRow=1,self.m_machine.m_iReelRowNum do
                local slotsNode = self.m_machine:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
                if slotsNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER and not slotsNode.m_playBuling then
                    local spine = self:createExpectAnim(iCol, iRow)
                    util_spinePlay(spine, "idleframe3", true)
                end
            end
        end
    else
        local spine = self:createExpectAnim(_iCol, _iRow)
        util_spinePlay(spine, "idleframe3", true)
    end 
end
function WinningWizardScatterExpectAnim:createExpectAnim(_iCol, _iRow)
    local spine = nil
    if #self.m_symbolPool > 0 then
        spine = table.remove(self.m_symbolPool, 1)
    end
    if nil == spine then
        spine = util_spineCreate("Socre_WinningWizard_Scatter",true,true)
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
function WinningWizardScatterExpectAnim:stopExpectAnim()
    for i,_spine in ipairs(self.m_symbolList) do
        util_spinePlay(_spine, "idleframe", false)
        _spine:setVisible(false)
        table.insert(self.m_symbolPool, _spine)
    end
    self.m_symbolList = {}
end

return WinningWizardScatterExpectAnim