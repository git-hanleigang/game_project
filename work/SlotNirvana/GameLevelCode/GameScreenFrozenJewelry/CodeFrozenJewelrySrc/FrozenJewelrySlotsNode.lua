---
--xcyy
--2018年5月23日
--FrozenJewelryView.lua


local FrozenJewelrySlotsNode = class("FrozenJewelrySlotsNode", util_require("Levels.SlotsNode"))

local SPECIAL_SYMBOL_TYPE = {0,1,2,3,90,92}

function FrozenJewelrySlotsNode:getLineAnimName()

    if self.p_cloumnIndex == 3 and self:isDoubleReel() then
        return 'actionframe2'
    else
        return "actionframe"
    end

end

function FrozenJewelrySlotsNode:getIdleAnimName(  )

    if self.p_cloumnIndex == 3 and self:isDoubleReel() then
        return 'idleframe2'
    else
        return "idleframe"
    end
end

function FrozenJewelrySlotsNode:runTriggerAni()
    if self.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        if self.p_cloumnIndex == 3 and self:isDoubleReel() then
            self:runAnim("actionframe4")
        else
            self:runAnim("actionframe3")
        end
    else
        self:runLineAnim()
    end
end

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function FrozenJewelrySlotsNode:initSlotNodeByCCBName(ccbName,symbolType)

    if self.m_machine and symbolType == self.m_machine.Socre_FrozenJewelry_MYSTERY  then
        symbolType = self.m_machine:getMysteryType(symbolType)
        ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine,symbolType)
    end
     
    if symbolType ~= -1 and self.m_actionDatas == nil then  -- 表明是滚动的格子
        self.m_actionDatas = {}
    end
    
    self.m_ccbName = ccbName

    self.p_symbolType = symbolType
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    self.m_symbolClipCanReset = true
    
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
    
    self.m_imageName = imageName
    if imageName == nil then  -- 直接添加ccb
        if self.p_symbolImage ~= nil then
            self.p_symbolImage:setVisible(false)
        end

        self:checkLoadCCbNode()
    else
        local offsetX = 0
        local offsetY = 0
        local scale = 1
        if tolua.type(imageName) == "table" then
            self.m_imageName = imageName[1]
            if #imageName == 3 then
                offsetX = imageName[2]
                offsetY = imageName[3]
            elseif #imageName == 4 then
                offsetX = imageName[2]
                offsetY = imageName[3]
                scale = imageName[4]
            end
        end
        local name = self.m_imageName
        if self.p_cloumnIndex == 3 and self:isDoubleReel() and self:isSpecialType(symbolType) then
            name = name.."_1.png"
        elseif self.p_cloumnIndex == 3 and self:isDoubleReel() then
            name = name..".png"
            scale = scale * 0.5
        else
            name = name..".png"
        end
        if self.p_symbolImage == nil then
            self.p_symbolImage = display.newSprite(name)
            self:addChild(self.p_symbolImage)
        else
            self:spriteChangeImage(self.p_symbolImage,name)
        end
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
end

function FrozenJewelrySlotsNode:changeSymbolImageByName( ccbName,symbolType )

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
    self.m_imageName = imageName
    if imageName == nil then  -- 直接添加ccb
        print("changeSymbolImageByName imageName是 nil ")
    else
        local offsetX = 0
        local offsetY = 0
        local scale = 1
        if tolua.type(imageName) == "table" then
            self.m_imageName = imageName[1]
            if #imageName == 3 then
                offsetX = imageName[2]
                offsetY = imageName[3]
            elseif #imageName == 4 then
                offsetX = imageName[2]
                offsetY = imageName[3]
                scale = imageName[4]
            end
        end
        local name = self.m_imageName
        if self.p_cloumnIndex == 3 and self:isDoubleReel() and self:isSpecialType(symbolType) then
            name = name.."_1.png"
        elseif self.p_cloumnIndex == 3 and self:isDoubleReel() then
            name = name..".png"
            scale = scale * 0.5
        else
            name = name..".png"
        end
        if self.p_symbolImage == nil then
            
            self.p_symbolImage = display.newSprite(name)
            self:addChild(self.p_symbolImage)
        else
            self:spriteChangeImage(self.p_symbolImage,name)
        end
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
end

function FrozenJewelrySlotsNode:isDoubleReel()
    local minBet = self:getMinBet()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local doubleReel = false
    if totalBet >= minBet then
        doubleReel = true
    end

    return doubleReel
end

function FrozenJewelrySlotsNode:getMinBet( )
    local minBet = 0
    local maxBet = 0
    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    if specialBets and specialBets[1] then
        minBet = specialBets[1].p_totalBetValue
    end
    return minBet
end

function FrozenJewelrySlotsNode:isSpecialType(symbolType)
    for k,specialType in pairs(SPECIAL_SYMBOL_TYPE) do
        if specialType == symbolType then
            return true
        end
    end

    return false
end
return FrozenJewelrySlotsNode