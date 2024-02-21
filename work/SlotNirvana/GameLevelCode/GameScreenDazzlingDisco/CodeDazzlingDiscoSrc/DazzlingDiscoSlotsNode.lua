---
--xcyy
--2018年5月23日
--DazzlingDiscoSlotsNode.lua

local DazzlingDiscoSlotsNode = class("DazzlingDiscoSlotsNode",util_require("Levels.SlotsNode"))
local IMAGE_NAMES = {
    ["92"] = {"#DazzlingDiscoSymbol/Socre_DazzlingDisco_WILD2.png","0","0","0.5"},
    ["93"] = {"#DazzlingDiscoSymbol/Socre_DazzlingDisco_WILD1.png","0","0","0.5"},
    ["101"] = {"#DazzlingDiscoSymbol/Socre_DazzlingDisco_MINI.png","0","0","0.5"}, --mini信号 101
    ["102"] = {"#DazzlingDiscoSymbol/Socre_DazzlingDisco_MINOR.png","0","0","0.5"}, -- minor信号 102
    ["103"] = {"#DazzlingDiscoSymbol/Socre_DazzlingDisco_MAJOR.png","0","0","0.5"}, -- major信号 103
    ["104"] = {"#DazzlingDiscoSymbol/Socre_DazzlingDisco_MEGA.png","0","0","0.5"}, -- mega信号 104
    ["105"] = {"#DazzlingDiscoSymbol/Socre_DazzlingDisco_GRAND.png","0","0","0.5"}, -- grand信号 105
}

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function DazzlingDiscoSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
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

function DazzlingDiscoSlotsNode:setMachine(machine)
    self.m_machine = machine
end

return DazzlingDiscoSlotsNode