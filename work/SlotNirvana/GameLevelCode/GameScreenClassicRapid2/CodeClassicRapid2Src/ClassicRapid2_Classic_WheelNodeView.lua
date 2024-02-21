---
--xcyy
--2018年5月23日
--ClassicRapid2_Classic_WheelNodeView.lua

local ClassicRapid2_Classic_WheelNodeView = class("ClassicRapid2_Classic_WheelNodeView",util_require("base.BaseView"))


function ClassicRapid2_Classic_WheelNodeView:initUI(data)
    local csbName = data

    self:createCsbNode(csbName .. ".csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function ClassicRapid2_Classic_WheelNodeView:onEnter()


end

function ClassicRapid2_Classic_WheelNodeView:setlabString(strTab )

    local sum = 0

    for k,v in pairs(strTab) do
        if v ~= "." and v ~= "," then
            sum = sum + 1
        end
    end

    local labNumIndex = 1

    for i=1,4 do
        local dian = self:findChild("m_lb_dian_".. i)
        if dian then
            dian:setString("")
        end

    end

    for i=1,5 do
        local num = self:findChild("m_lb_score_".. i)
        if num then
            num:setString("")
        end
    end

    if sum ==  0 or sum ==  1 then
        sum = 5
    end

    if sum == 5 then
        labNumIndex = 1
    elseif sum == 4 then
        labNumIndex = 2
    elseif sum == 3 then
        labNumIndex = 3
    elseif sum == 2 then
        labNumIndex = 4
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
            if dianindex >0 and dianindex < 5 then
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

function ClassicRapid2_Classic_WheelNodeView:onExit()

end


return ClassicRapid2_Classic_WheelNodeView