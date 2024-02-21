

local CharmsNode = class("CharmsNode", util_require("Levels.RespinNode"))

function CharmsNode:checkRemoveNextNode()
    return true
end
function CharmsNode:initMachine(machine)
    self.m_machine = machine
end
function CharmsNode:changeNodeDisplay( node )
    if node.p_symbolType and self.m_machine:isFixSymbol(node.p_symbolType) ~= true then

        -- node:runAnim("animation0") 

        local ccbNode = node:getCCBNode()
        if ccbNode then
            ccbNode:setVisible(false)
        end

        if node.m_ccbName then
            local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
            if imageName  then  -- 直接添加ccb
                
                local offsetX = 0
                local offsetY = 0
                local scale = 1
                if tolua.type(imageName) == "table" then
                    imageName = imageName[1]
                    if #imageName == 3 then
                        offsetX = imageName[2]
                        offsetY = imageName[3]
                    elseif #imageName == 4 then
                        offsetX = imageName[2]
                        offsetY = imageName[3]
                        scale = imageName[4]
                    end
                end
                local darkImgName = "#Symbol/Charms_L4_1.png"

                if imageName == "#Symbol/Charms_L4.png" then
                    darkImgName = "#Symbol/Charms_L4_1.png"

                elseif imageName == "#Symbol/Charms_L3.png" then
                    darkImgName = "#Symbol/Charms_L3_1.png"

                elseif imageName == "#Symbol/Charms_L2.png" then
                    darkImgName = "#Symbol/Charms_L2_1.png"

                elseif imageName == "#Symbol/Charms_L1.png" then
                    darkImgName = "#Symbol/Charms_L1_1.png"

                elseif imageName == "#Symbol/Charms_M4.png" then
                    darkImgName = "#Symbol/Charms_M4_1.png"

                elseif imageName == "#Symbol/Charms_M3.png" then
                    darkImgName = "#Symbol/Charms_M3_1.png"

                elseif imageName == "#Symbol/Charms_M2.png" then
                    darkImgName = "#Symbol/Charms_M2_1.png"

                elseif imageName == "#Symbol/Charms_M1.png" then
                    darkImgName = "#Symbol/Charms_M1_1.png"

                elseif imageName == "#Symbol/Charms_H1.png" then
                    darkImgName = "#Symbol/Charms_H1_1.png"

                elseif imageName == "#Symbol/Charms_scatter.png" then
                    darkImgName = "#Symbol/Charms_Scatter_zhihui.png"

                elseif imageName == "#Symbol/Charms_wild.png" then
                    darkImgName = "#Symbol/Charms_wild_1.png"

                end

                if node.p_symbolImage == nil then
                    node.p_symbolImage = display.newSprite(darkImgName)
                    node:addChild(node.p_symbolImage)
                else
                    node:spriteChangeImage(node.p_symbolImage,darkImgName)
                end
                node.p_symbolImage:setPositionX(offsetX)
                node.p_symbolImage:setPositionY(offsetY)
                node.p_symbolImage:setScale(scale)
                node.p_symbolImage:setVisible(true)
            end

        end

        
    end
    
end

return CharmsNode