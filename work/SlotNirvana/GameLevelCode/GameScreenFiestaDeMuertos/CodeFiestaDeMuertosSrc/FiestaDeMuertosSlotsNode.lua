---
--xcyy
--2018年5月23日
--FiestaDeMuertosSlotsNode.lua

local FiestaDeMuertosSlotsNode = class("FiestaDeMuertosSlotsNode", util_require("Levels.SlotsNode"))
local SlotsAnimNode = require "Levels.SlotsAnimNode"
local SYMBOL_BONUS_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1
local SYMBOL_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
local SYMBOL_BONUS_LAB_TAG = 100
local bonusData = {10, 15, 20, 30, 50, 80, 100, 150, 200, 250, 300, 500, 750, 1000}
local bonusDataWeight = {1620, 1300, 1200, 1200, 1200, 1200, 1000, 600, 300, 200, 100, 50, 25, 5}

function FiestaDeMuertosSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

function FiestaDeMuertosSlotsNode:initSlotNodeByCCBName(ccbName, symbolType)
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
    if symbolType == SYMBOL_BONUS_1 or symbolType == SYMBOL_BONUS_2 then
        self:createBonusSymbolLab()
    end
end

--通过权重获取随机的bonus数值
function FiestaDeMuertosSlotsNode:getRandomBonusData()
    local allNum = 0
    for i = 1, #bonusDataWeight do
        allNum = allNum + bonusDataWeight[i]
    end
    local randomNum = math.random(1, allNum)
    local index = 1
    local weight =0
    for i = 1, #bonusDataWeight, 1 do
        weight = weight + bonusDataWeight[i]
        if randomNum <= weight then
            index = i
            break
        end
    end
    local bonusNum = bonusData[index]
    return bonusNum
end

function FiestaDeMuertosSlotsNode:createBonusSymbolLab()
    if self.m_bonuslabel == nil then
        self.m_bonuslabel = SlotsAnimNode:create()
        local num = self:getRandomBonusData()
        self.m_bonuslabel:loadCCBNode("Socre_FiestaDeMuertos_Bonus_Lab", SYMBOL_BONUS_LAB_TAG)
        num = num * globalData.slotRunData:getCurTotalBet() / 30
        self.m_bonuslabel:runDefaultAnim()
        self:addChild(self.m_bonuslabel, 100)
        self:setBonusLabNum(num)
    end
end

function FiestaDeMuertosSlotsNode:setBonusLabNum(num)
    if self.p_symbolType == SYMBOL_BONUS_1 or self.p_symbolType == SYMBOL_BONUS_2 then
        if self.m_bonuslabel then
            local winRate = num / globalData.slotRunData:getCurTotalBet()
            local lab1 = self.m_bonuslabel:getCcbProperty("m_lb_coins_0") --lan
            local lab2 = self.m_bonuslabel:getCcbProperty("m_lb_coins_1") --zi
            if winRate > 4 then
                if lab1 and lab2 then
                    lab1:setVisible(false)
                    lab2:setVisible(true)
                    lab2:setString(util_formatCoins(num, 3))
                end
            else
                if lab1 and lab2 then
                    lab1:setVisible(true)
                    lab2:setVisible(false)
                    lab1:setString(util_formatCoins(num, 3))
                end
            end
        end
    end
end

function FiestaDeMuertosSlotsNode:removeBonusSymbolLab()
    if self.p_symbolType == SYMBOL_BONUS_1 or self.p_symbolType == SYMBOL_BONUS_2 then
        if self.m_bonuslabel then
            self.m_bonuslabel:clear()
            self.m_bonuslabel:removeFromParent()
            self.m_bonuslabel = nil
        end
    end
end

function FiestaDeMuertosSlotsNode:playBonusSymbolLabAction(actName)
    if self.p_symbolType == SYMBOL_BONUS_1 or self.p_symbolType == SYMBOL_BONUS_2 then
        if self.m_bonuslabel then
            self.m_bonuslabel:runAnim(actName, false)
        end
    end
end

---
-- 还原到初始被创建的状态
function FiestaDeMuertosSlotsNode:reset()
    self.p_idleIsLoop = false
    self.p_preParent = nil
    self.p_preX = nil
    self.p_preY = nil
    self.p_slotNodeH = 0
    self:removeBonusSymbolLab()
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

function FiestaDeMuertosSlotsNode:clear()
    self:removeBonusSymbolLab()

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

function FiestaDeMuertosSlotsNode:removeAndPushCcbToPool()
    self:removeBonusSymbolLab()
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

return FiestaDeMuertosSlotsNode
