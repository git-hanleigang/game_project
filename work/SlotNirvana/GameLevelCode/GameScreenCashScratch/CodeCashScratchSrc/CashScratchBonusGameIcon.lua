local CashScratchBonusGameIcon = class("CashScratchBonusGameIcon",util_require("Levels.BaseLevelDialog"))


-- 构造函数
function CashScratchBonusGameIcon:ctor()
    CashScratchBonusGameIcon.super.ctor(self)

    self.m_symbolType = -1
    self.m_ccbName    = ""
    self.m_animNode   = nil

    self.m_initData = nil
end

function CashScratchBonusGameIcon:initUI()
    self.m_lightAnim = util_createAnimation("CashScratch_card_patterns_2.csb") 
    self:addChild(self.m_lightAnim)
end


--[[
    设置数据
    _initData = {
        machine    = machine,
        symbolType = 0,       -- 连线的符号类型
        iconType   = 0        -- 展示的图标类型
    }
]]
function CashScratchBonusGameIcon:setInitData(_initData)
    self.m_initData = _initData
    self.m_machine  = _initData.machine

    self:resetIcon()
end

function CashScratchBonusGameIcon:resetIcon()
    self.m_lineAnimName = nil
end

--[[
    icon 刷新
]]
function CashScratchBonusGameIcon:upDateIconShow()
    local iconType   = self.m_initData.iconType
    local spineSymbolData = self.m_machine.m_configData:getSpineSymbol(iconType)
    if nil ~= spineSymbolData then
        
    else
        local isABTest = self.m_machine:checkCashScratchABTest()
        -- 另外一套资源
        local commonWatermelon = self.m_animNode:findChild("watermelon")
        local commonLemon      = self.m_animNode:findChild("lemon")
        local commonMangosteen = self.m_animNode:findChild("mangosteen")
        local commonApple      = self.m_animNode:findChild("apple")
        local commonCherry     = self.m_animNode:findChild("cherry")

        commonWatermelon:setVisible(not isABTest and iconType == self.m_machine.SYMBOL_BONUSCARD_Watermelon)
        commonLemon:setVisible(not isABTest      and iconType == self.m_machine.SYMBOL_BONUSCARD_Lemon)
        commonMangosteen:setVisible(not isABTest and iconType == self.m_machine.SYMBOL_BONUSCARD_Mangosteen)
        commonApple:setVisible(not isABTest      and iconType == self.m_machine.SYMBOL_BONUSCARD_Apple)
        commonCherry:setVisible(not isABTest     and iconType == self.m_machine.SYMBOL_BONUSCARD_Cherry)

        -- abtest 的五套资源
        for _bonusIndex=1,5 do
            local cardAddValue = (_bonusIndex-1)*100

            local watermelonType = self.m_machine.SYMBOL_BONUSCARD_Watermelon + cardAddValue
            local lemonType      = self.m_machine.SYMBOL_BONUSCARD_Lemon + cardAddValue
            local mangosteenType = self.m_machine.SYMBOL_BONUSCARD_Mangosteen + cardAddValue
            local appleType      = self.m_machine.SYMBOL_BONUSCARD_Apple + cardAddValue
            local cherryType     = self.m_machine.SYMBOL_BONUSCARD_Cherry + cardAddValue

            local iconWatermelon = self.m_animNode:findChild( string.format("%d",watermelonType ) )
            local iconLemon      = self.m_animNode:findChild( string.format("%d",lemonType ) )
            local iconMangosteen = self.m_animNode:findChild( string.format("%d",mangosteenType ) )
            local iconApple      = self.m_animNode:findChild( string.format("%d",appleType ) )
            local iconCherry     = self.m_animNode:findChild( string.format("%d",cherryType ) )

            iconWatermelon:setVisible(isABTest and iconType == watermelonType)
            iconLemon:setVisible(isABTest      and iconType == lemonType)
            iconMangosteen:setVisible(isABTest and iconType == mangosteenType)
            iconApple:setVisible(isABTest      and iconType == appleType)
            iconCherry:setVisible(isABTest     and iconType == cherryType)
        end

    end

    self:runIdleAnim()
end

function CashScratchBonusGameIcon:runLineAnim()
    self:runIconAnim(self:getLineAnimName(), false)

    self:showLightAnim()
end
function CashScratchBonusGameIcon:runIdleAnim()
    local iconType   = self.m_initData.iconType
    local spineSymbolData = self.m_machine.m_configData:getSpineSymbol(iconType)
    local idleName = "idleframe"
    if nil ~= spineSymbolData then
        idleName = "idleframe2"
    end
    self:runIconAnim(idleName, false)
end


--[[
    时间线
]]
function CashScratchBonusGameIcon:setLineAnimName(_lineAnimName)
    self.m_lineAnimName = _lineAnimName
end
function CashScratchBonusGameIcon:getLineAnimName()
    if nil ~= self.m_lineAnimName then
        return self.m_lineAnimName
    else
        return "actionframe"
    end
end

--[[
    动画节点(spine|cocos)创建刷新
]]
function CashScratchBonusGameIcon:createAnimNode()
    if not self.m_animNode then
        local iconType = self.m_initData.iconType
        self.m_animNode = self.m_machine:createCashScratchTempSymbol(iconType)
        self:addChild(self.m_animNode, 10)

        self.m_symbolType = iconType
        self.m_ccbName    = self.m_machine:getSymbolCCBNameByType(self.m_machine, iconType)
    end
end
function CashScratchBonusGameIcon:upDateAnimNode()
    if self.m_animNode then
        local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_initData.iconType)
        if ccbName ~=  self.m_ccbName then
            self.m_animNode:removeFromParent()
            self.m_animNode = nil

            self:createAnimNode()
        end 
    else
        self:createAnimNode()
    end
end

function CashScratchBonusGameIcon:runIconAnim(_animName, _loop, _fun)
    self.m_machine:runCashScratchTempSymbolAnim(self.m_animNode, _animName, _loop, _fun)
end

--[[
    高亮格子
]]
function CashScratchBonusGameIcon:showLightAnim()
    self.m_lightAnim:runCsbAction("start", false, function()
        self.m_lightAnim:runCsbAction("idle", false)
    end)
end
function CashScratchBonusGameIcon:hideLightAnim()
    self.m_lightAnim:runCsbAction("over", false)
end

return CashScratchBonusGameIcon