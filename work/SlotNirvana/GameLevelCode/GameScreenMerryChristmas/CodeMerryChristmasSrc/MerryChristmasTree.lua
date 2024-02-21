---
--xcyy
--2018年5月23日
--MerryChristmasTree.lua

local MerryChristmasTree = class("MerryChristmasTree", util_require("base.BaseView"))

function MerryChristmasTree:initUI()
    self:createCsbNode("MerryChristmas_shu.csb")
    self:runCsbAction("shengdanshu_man", true) -- 播放时间线
    self:initTreeGift()
end

function MerryChristmasTree:onEnter()
end

function MerryChristmasTree:onExit()
end

function MerryChristmasTree:initTreeGift()
    self.m_vecBox = {}
    for i = 1, 20 do
        local nodeName = "Node_" .. i
        local node = self:findChild(nodeName)
        local csbName = "MerryChristmas_box.csb"
        if i == 5 or i == 10 or i == 20 then
            csbName = "MerryChristmas_jackpot_tips.csb"
        end
        local csb = util_createAnimation(csbName)
        node:addChild(csb)
        self.m_vecBox[i] = csb
        if i == 5 or i == 10 then
            csb:runCsbAction("idle2")
        elseif i == 20 then
            csb:runCsbAction("idle1")
        else
            csb:runCsbAction("idle1")
        end
    end
end
function MerryChristmasTree:initReconnetUI(num)
    if num and num > 0 and num <= 20 then
        for i = 1, num do
            local csb = self.m_vecBox[i]
            if i == 5 or i == 10 then
                csb:runCsbAction("superidle")
            elseif i == 20 then
                csb:runCsbAction("grandidle")
            else
                csb:runCsbAction("idle2")
            end
        end
    end
end

function MerryChristmasTree:playTreeOver()
    for i = 1, 20 do
        local csb = self.m_vecBox[i]
        if i == 5 or i == 10 then
            csb:runCsbAction("idle2")
        else
            csb:runCsbAction("idle1")
        end
    end
end

function MerryChristmasTree:updataOpenBoxNum(num)
    if num > 0 and num <= 20 then
        local csb = self.m_vecBox[num]
        if num == 5 or num == 10 then
            csb:runCsbAction("super")
        elseif num == 20 then
            csb:runCsbAction("grand")
        else
            csb:runCsbAction("idle2")
        end
    end
end

function MerryChristmasTree:getMoveToTreeNode(_num)
    local nodeName = "Node_" .. _num
    local node = self:findChild(nodeName)
    if node then
        return node
    end
    return nil
end

return MerryChristmasTree
