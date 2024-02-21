---
--xcyy
--2018年5月23日
--WildGorillaSlotsNode.lua
-- FIX IOS 139
local WildGorillaSlotsNode = class("WildGorillaSlotsNode", util_require("Levels.SlotsNode"))
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SYMBOL_BONUS_LINK = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
local SYMBOL_BONUS_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8
local SYMBOL_BONUS_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
local SYMBOL_BONUS_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
local SYMBOL_BONUS_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11

function WildGorillaSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

function WildGorillaSlotsNode:initSlotNodeByCCBName(ccbName, symbolType)
    if symbolType ~= -1 and self.m_actionDatas == nil then -- 表明是滚动的格子
        self.m_actionDatas = {}
    end

    self.m_ccbName = ccbName

    self.p_symbolType = symbolType
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    self.m_symbolClipCanReset = true

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
    self.m_imageName = imageName
    if imageName == nil then -- 直接添加ccb
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
        if self.p_symbolImage == nil then
            self.p_symbolImage = display.newSprite(self.m_imageName)
            self:addChild(self.p_symbolImage)
        else
            self:spriteChangeImage(self.p_symbolImage, self.m_imageName)
        end
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
end

function WildGorillaSlotsNode:isBonusSymbolByType(symbolType)
    if SYMBOL_BONUS_LINK == symbolType or SYMBOL_BONUS_MINI == symbolType or SYMBOL_BONUS_MINOR == symbolType or SYMBOL_BONUS_MAJOR == symbolType or SYMBOL_BONUS_GRAND == symbolType then
        return true
    end
    return false
end

function WildGorillaSlotsNode:updateDistance(distance)
    if self.m_bigSymbolPos then
        self:setPositionY(self.m_originalDistance - distance + self.m_bigSymbolPos)
    else
        self:setPositionY(self.m_originalDistance - distance)
        if self.m_bonusLab then
            self.m_bonusLab:setPosition(cc.p(self:getPosition()))
        end
    end
end

function WildGorillaSlotsNode:createBonusLab()
    if self.m_bonusLab == nil then
        local ccbName = self:getBonusLabNameByType(self.p_symbolType)
        self.m_bonusLab = util_createAnimation(ccbName..".csb")
        local parent = self:getParent()
        self.m_bonusLab:setPosition(cc.p(self:getPosition()))
        local zorder = self:getLocalZOrder() + 20
        parent:addChild(self.m_bonusLab, zorder)
    end
end

function WildGorillaSlotsNode:changeBonusLabParent(_tag)
    if self.m_bonusLab then
        if _tag == 1 then
            self.m_bonusLab:setLocalZOrder(self:getLocalZOrder() + 20)
        else
            local worldPos = self.m_bonusLab:getParent():convertToWorldSpace(cc.p(self.m_bonusLab:getPosition()))
            local parent = self:getParent()
            local pos = parent:convertToNodeSpace(worldPos)
            self.m_bonusLab:setPosition(pos.x, pos.y)
            util_changeNodeParent(parent, self.m_bonusLab, self:getLocalZOrder() + 20)
        end
    end
end

function WildGorillaSlotsNode:getBonusLabNameByType(symbolType)
    if SYMBOL_BONUS_LINK == symbolType then
        return "Socre_WildGorilla_Bonuslink"
    elseif SYMBOL_BONUS_MINI == symbolType then
        return "Socre_WildGorilla_Mini"
    elseif SYMBOL_BONUS_MINOR == symbolType then
        return "Socre_WildGorilla_Minor"
    elseif SYMBOL_BONUS_MAJOR == symbolType then
        return "Socre_WildGorilla_Major"
    elseif SYMBOL_BONUS_GRAND == symbolType then
        return "Socre_WildGorilla_Grand"
    end
end

function WildGorillaSlotsNode:setBonusLabNum(num)
    if self.p_symbolType == SYMBOL_BONUS_LINK then
        local lab1 = self.m_bonusLab:findChild("BitmapFontLabel_5")
        if lab1 then
            lab1:setString(num)
        end
    end
end

function WildGorillaSlotsNode:removeBonusSymbolSpine()
    if self.m_bonusLab then
        self.m_bonusLab:removeFromParent()
        self.m_bonusLab = nil
    end
end
---
-- 还原到初始被创建的状态
function WildGorillaSlotsNode:reset()
    self.p_idleIsLoop = false
    self.p_preParent = nil
    self.p_preX = nil
    self.p_preY = nil
    self.p_slotNodeH = 0
    self:removeBonusSymbolSpine()
    self:setVisible(true)
    self.m_reelTargetX = nil
    self.m_reelTargetY = nil
    self.m_isLastSymbol = nil
    --    self.p_maxRowIndex = nil
    self.m_lineMatrixPos = nil
    self.m_imageName = nil
    self.m_lineAnimName = nil
    self.m_idleAnimName = nil
    self.m_bInLine = true
    self.m_callBackFun = nil
    self.m_bRunEndTarge = false
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

    self:setScale(1)
    self:setOpacity(255)
    self:setRotation(0)

    if self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(true)
    end
    self:setScale(1)
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode, self.p_symbolType)
        end
    end

    self.p_symbolType = nil
    self.p_idleIsLoop = false

    self.m_currAnimName = nil
    self.p_reelDownRunAnima = nil
    self.p_reelDownRunAnimaTimes = nil
    -- 清空掉当前的actions
    if self.m_actionDatas ~= nil then
        table_clear(self.m_actionDatas)
    end

    self:hideBigSymbolClip()
end

function WildGorillaSlotsNode:clear()
    self:removeBonusSymbolSpine()

    self.m_currAnimName = nil
    self.m_actionDatas = nil
    self.p_preParent = nil
    self.m_callBackFun = nil
    self:unregisterScriptHandler() -- 卸载掉注册事件

    -- 检测释放掉添加进来的动画节点
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:clear()

        ccbNode:removeAllChildren()

        if ccbNode:getReferenceCount() > 1 then
            ccbNode:release()
        end

        ccbNode:removeFromParent()
    end

    if self.p_symbolImage ~= nil and self.p_symbolImage:getParent() ~= nil then
        self.p_symbolImage:removeFromParent()
    end

    self.p_symbolImage = nil
end

function WildGorillaSlotsNode:removeAndPushCcbToPool()
    self:removeBonusSymbolSpine()
    local ccbNode = self:getCCBNode()

    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        if ccbNode.__cname ~= nil and ccbNode.__cname == "SlotsSpineAnimNode" then
            if util_isSupportVersion("1.1.4") then
                ccbNode.m_spineNode:resetAnimation()
            end
        end
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode, self.p_symbolType)
        end
    end
end

function WildGorillaSlotsNode:runAnim(animName, loop, func)
    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
    end

    local isPlay = ccbNode:runAnim(animName, loop, func)

    if isPlay == true then
        self.m_slotAnimaLoop = loop
        self.m_currAnimName = animName

        if self.m_animaCallBackFun ~= nil then
            self.m_animaCallBackFun(self)
        end
    end
    if self:isBonusSymbolByType(self.p_symbolType) then
        if self.m_bonusLab then
            self.m_bonusLab:runCsbAction(animName, loop)
        end
    end
end

return WildGorillaSlotsNode
