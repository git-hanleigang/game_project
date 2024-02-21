

local GoldExpressNode = class("GoldExpressNode", 
                                    util_require("Levels.RespinNode"))

local SYMBOL_BONUS = 101

function GoldExpressNode:checkRemoveNextNode()
    return true
end

function GoldExpressNode:changeNodeDisplay( node )
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
    if node.p_symbolType == SYMBOL_BONUS then
        return
    end
    if imageName ~= nil then
        imageName = string.gsub(imageName, ".png", "_gray.png")
        node:removeAndPushCcbToPool()
        if node.p_symbolImage == nil then
            node.p_symbolImage = display.newSprite(imageName)
            node:addChild(node.p_symbolImage)
        else
            node:spriteChangeImage(node.p_symbolImage,imageName)
        end
        node.p_symbolImage:setVisible(true)
    end
end

return GoldExpressNode