---
--xcyy
--2018年5月23日
--FrogPrinceSlotsNode.lua

local FrogPrinceSlotsNode = class("FrogPrinceSlotsNode",util_require("Levels.SlotsNode"))

-- FrogPrinceSlotsNode.m_num = 0
FrogPrinceSlotsNode.m_Corn = nil


function FrogPrinceSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function FrogPrinceSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
 
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
        if self.p_symbolImage == nil then
            self.p_symbolImage = display.newSprite(self.m_imageName)
            self:addChild(self.p_symbolImage)
        else
            self:spriteChangeImage(self.p_symbolImage,self.m_imageName)
        end
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
end

function FrogPrinceSlotsNode:removeAndPushCcbToPool()
    local ccbNode = self:getCCBNode()
    
    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        if ccbNode.__cname ~= nil and ccbNode.__cname == "SlotsSpineAnimNode" then
            ccbNode.m_spineNode:resetAnimation()
        end
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,  self.p_symbolType)
        end
    end
end

return FrogPrinceSlotsNode