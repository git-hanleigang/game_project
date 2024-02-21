---
--xcyy
--2018年5月23日
--OwlsomeWizardSlotsNode.lua

local OwlsomeWizardSlotsNode = class("OwlsomeWizardSlotsNode",util_require("Levels.SlotsNode"))
local IMAGE_NAMES = {
    ["92"] = {"#OwlsomeWizardSymbol/Socre_OwlsomeWizard_1.png","0","0","0.5"},
    ["95"] = {"#OwlsomeWizardSymbol/Socre_OwlsomeWizard_2.png","0","0","0.5"},
    ["96"] = {"#OwlsomeWizardSymbol/Socre_OwlsomeWizard_3.png","0","0","0.5"},

}

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function OwlsomeWizardSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
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
    
    local imageName 
    if symbolType then
        imageName = IMAGE_NAMES[tostring(symbolType)]
    end
    
    if not imageName then
        imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
    end


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

return OwlsomeWizardSlotsNode