
local KittysCatchSlotsNode = class("KittysCatchSlotsNode",util_require("Levels.SlotsNode"))

--[[
    提层
]]
function KittysCatchSlotsNode:upToParent(parent, isClipParent)
    local preParent = self:getParent()
    if preParent == parent then
        return
    end

    local order = 0
    if isClipParent then
        order = self.m_showOrder or 0
    else
        order = self.p_showOrder or 0
    end

    local pos = util_convertToNodeSpace(self,parent)
    util_changeNodeParent(parent,self,order)
    self:setPosition(pos)
end

--[[
    还原
]]
function KittysCatchSlotsNode:downToBase(_clipParent)
    if not self.p_layerTag or self.p_layerTag~= SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE then
        return
    end

    local parentNode = self:getParent()

    if not _clipParent then
        --信号是否已经在该信号层上
        if self.m_baseNode and parentNode and self.m_baseNode ~= parentNode then
            local pos = util_convertToNodeSpace(self,self.m_baseNode)
            util_changeNodeParent(self.m_baseNode,self,self.p_showOrder)
            self:setPosition(pos)
        end
    else
        --信号是否已经在该信号层上
        if _clipParent and parentNode and _clipParent ~= parentNode then
            local pos = util_convertToNodeSpace(self,_clipParent)
            util_changeNodeParent(_clipParent,self,self.m_showOrder)
            self:setPosition(pos)
        end
    end
    
end

--重写
---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function KittysCatchSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
--    if ccbName == nil then
--        printInfo("xcyy : --ccbName %s", ccbName)
--    end
    
    if symbolType ~= -1 and self.m_actionDatas == nil then  -- 表明是滚动的格子
        self.m_actionDatas = {}
    end
    
    self.m_ccbName = ccbName

    self.p_symbolType = symbolType
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    self.m_symbolClipCanReset = true
    
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
    --改
    if (self.p_symbolType == 95 or self.p_symbolType == 96) and ccbName == "Socre_KittysCatch_Scatter2" then
        if self.p_symbolType == 95 then
            imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName("Socre_KittysCatch_Scatter2_Scatter")
        elseif self.p_symbolType == 96 then
            imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName("Socre_KittysCatch_Scatter2_Wild")
        end
    end
    --改
    
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

--重写
function KittysCatchSlotsNode:changeSymbolImageByName( ccbName )

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)

    --改
    if (self.p_symbolType == 95 or self.p_symbolType == 96) and ccbName == "Socre_KittysCatch_Scatter2" then
        if self.p_symbolType == 95 then
            imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName("Socre_KittysCatch_Scatter2_Scatter")
        elseif self.p_symbolType == 96 then
            imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName("Socre_KittysCatch_Scatter2_Wild")
        end
    end
    --改

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

function KittysCatchSlotsNode:getIdleAnimName(  )
    if self.p_symbolType == 96 then
        return "idleframe2"
    end
    if self.m_idleAnimName ~= nil then
        return self.m_idleAnimName
    else
        return "idleframe"
    end
end

return KittysCatchSlotsNode