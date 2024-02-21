---
--xhkj
--2018年6月11日
--CandyBingoWheelNode.lua

local CandyBingoWheelNode = class("CandyBingoWheelNode", util_require("base.BaseView"))

function CandyBingoWheelNode:initUI(name)

    local resourceFilename = name
    self:createCsbNode(resourceFilename)

end


function CandyBingoWheelNode:onEnter()
   
end


function CandyBingoWheelNode:onExit()
    
end


function CandyBingoWheelNode:setlabString(strTab )

    local sum = 0

    for k,v in pairs(strTab) do
        if v ~= "." and v ~= "," then
            sum = sum + 1
        end
    end

    local labNumIndex = 1

    for i=1,3 do
        local dian = self:findChild("m_lb_dian_".. i)
        if dian then
            dian:setString("")
        end
        
    end

    for i=1,4 do
        local num = self:findChild("m_lb_score_".. i)
        if num then
            num:setString("")
        end
    end

    if sum ==  0 or sum ==  1 then
        sum = 4 
    end

    if sum == 4 then
        labNumIndex = 1
    elseif sum == 3 then
        labNumIndex = 2
    elseif sum == 2 then
        labNumIndex = 3
    end

    local allSum = 0
    for k,v in pairs(strTab) do
        if  v ~= "," then
            allSum = allSum + 1
        end
    end

    for i = allSum,1,-1 do
        local num = strTab[i]
        if num == "." then
            local dianindex = labNumIndex - 1
            if dianindex >0 and dianindex < 4 then
                local dianName = "m_lb_dian_".. dianindex
                local dianLab =  self:findChild(dianName)
                if dianLab then
                    dianLab:setString(".")
                end
            end

            
        else
            

            local numName = "m_lb_score_".. labNumIndex
            local numLab =  self:findChild(numName)
            if numLab then
                numLab:setString(num)
            end

            labNumIndex = labNumIndex + 1
        end

        
    end

end


return CandyBingoWheelNode