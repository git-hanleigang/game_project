

local RespinNode = util_require("Levels.RespinNode")
local CrazyBombRespinNode = class("CrazyBombRespinNode", RespinNode)
local SYMBOL_BIG_WILD = 101
function CrazyBombRespinNode:changeNodeDisplay( node )
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
    if node.p_symbolType == SYMBOL_BIG_WILD then
        imageName = "#Symbol/CrazyBomb_gold.png"
    end
    if imageName ~= nil then
        imageName = string.gsub(imageName, ".png", "_gray.png")
        node:removeAndPushCcbToPool()
        if node.p_symbolImage == nil then
            node.p_symbolImage = display.newSprite(imageName)
            if node.p_symbolImage == nil then
            end
            node:addChild(node.p_symbolImage)
        else
            node:spriteChangeImage(node.p_symbolImage,imageName)
        end
        node.p_symbolImage:setVisible(true)
    end
end

return CrazyBombRespinNode