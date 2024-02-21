--[[
    处理wild变化列表
    坐标向两侧扩张
]]
local WinningWizardWildChangeList = class("WinningWizardWildChangeList", cc.Node)

WinningWizardWildChangeList.SymbolTypeList = {
    TAG_SYMBOL_TYPE.SYMBOL_SCORE_9,
    TAG_SYMBOL_TYPE.SYMBOL_SCORE_8,
    TAG_SYMBOL_TYPE.SYMBOL_SCORE_7,
    TAG_SYMBOL_TYPE.SYMBOL_SCORE_6,
    TAG_SYMBOL_TYPE.SYMBOL_SCORE_5,
    TAG_SYMBOL_TYPE.SYMBOL_SCORE_4,
    TAG_SYMBOL_TYPE.SYMBOL_SCORE_3,
}

function WinningWizardWildChangeList:initData_(_data)
    --[[
        _data = {
            tubiaoPath  = "",
            tubiaoWidth = 50,
        }
    ]]
    self.m_initData      = _data
    self.m_tubiaoCsbPath = _data.tubiaoPath

    self.m_csb = util_createAnimation("WinningWizard_wildChangeList.csb")
    self:addChild(self.m_csb)

    self:initUI()
end
function WinningWizardWildChangeList:initUI()
    
    self.m_symbolList = {}
    for i=1,#self.SymbolTypeList do
        local tubiaoCsb = util_createAnimation(self.m_tubiaoCsbPath)
        self.m_csb:findChild("Node_symbol"):addChild(tubiaoCsb)
        tubiaoCsb:setVisible(false)
        table.insert(self.m_symbolList, tubiaoCsb)
    end
end
function WinningWizardWildChangeList:setWildChangeTubiao(_tubiaoCsb, _symbolType)
    for i,symbolType in ipairs(self.SymbolTypeList) do
        local node     = _tubiaoCsb:findChild(string.format("symbol_%d", symbolType))
        local bVisible = symbolType == _symbolType
        node:setVisible(bVisible)
    end
end
function WinningWizardWildChangeList:resetWildChangeListVisible()
    for i,_tubiaoCsb in ipairs(self.m_symbolList) do
        _tubiaoCsb:setVisible(false)
    end
end

function WinningWizardWildChangeList:updateWildChangeList(_symbolList, _bShowLab)
    local symbolCount = #_symbolList
    local tubiaoWidth = self.m_initData.tubiaoWidth
    local interval    = 5

    local symbolLength  = symbolCount * tubiaoWidth + (symbolCount-1) * interval
    local labLength     = 0
    if _bShowLab then
        local spIndex = 1
        local spName  = string.format("sp_%d", spIndex)
        local spNode  = self.m_csb:findChild(spName)
        while nil ~= spNode do
            local spSize  = spNode:getContentSize()
            labLength = labLength + interval + spSize.width
            spIndex = spIndex + 1
            spName  = string.format("sp_%d", spIndex)
            spNode  = self.m_csb:findChild(spName)
        end
    end

    local length      = symbolLength + labLength
    local startPosX   = -(length / 2) + 0.5 * tubiaoWidth
    self:resetWildChangeListVisible()
    for i,_tubiaoCsb in ipairs(self.m_symbolList) do
        if i <= symbolCount then
            local posX = startPosX + (i - 1) * (tubiaoWidth + interval)
            _tubiaoCsb:setPositionX(posX)
            local symbolType = _symbolList[i]
            self:setWildChangeTubiao(_tubiaoCsb, symbolType)
            _tubiaoCsb:setVisible(true)
        else
            break
        end
    end

    if _bShowLab then
        local spIndex = 1
        local spName  = string.format("sp_%d", spIndex)
        local spNode  = self.m_csb:findChild(spName)
        local lastPosX = startPosX + (symbolCount - 1) * (tubiaoWidth + interval) + 0.5 * tubiaoWidth
        while nil ~= spNode do
            local spSize  = spNode:getContentSize()
            local newPosX = lastPosX + interval + spSize.width/2
            spNode:setPositionX(newPosX)
            lastPosX = lastPosX + interval + spSize.width
            spIndex = spIndex + 1
            spName  = string.format("sp_%d", spIndex)
            spNode  = self.m_csb:findChild(spName)
        end
    end
    self.m_csb:findChild("Node_sprite"):setVisible(_bShowLab)
end



return WinningWizardWildChangeList