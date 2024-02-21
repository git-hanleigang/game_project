---
--xcyy
--2018年5月23日
--EgyptCollectBar.lua

local EgyptCollectBar = class("EgyptCollectBar",util_require("base.BaseView"))


function EgyptCollectBar:initUI()

    self:createCsbNode("Freespinjishu.csb")

    self:runCsbAction("idle", true)
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听

    self.m_vecLabCollect = {}
    -- self.m_vecNodeRespin = {}
    self.m_vecLabTotal = {}
    self.m_vecLabCount = {}
    self.m_vecSpinCount = {}
    self.m_vecLabOf = {}

    local index = 1
    while true do
        local node = self:findChild("collect_"..index)
        local nodeRespin =  self:findChild("respin_"..index)
        local labTotal =  self:findChild("total_"..index)
        local labCount =  self:findChild("count_"..index)
        local labOf =  self:findChild("Egypt_of_zi_"..index)
        if node ~= nil then
            node:setString("0")
            self.m_vecLabCollect[#self.m_vecLabCollect + 1] = node
            -- self.m_vecNodeRespin[#self.m_vecNodeRespin + 1] = nodeRespin
            self.m_vecLabTotal[#self.m_vecLabTotal + 1] = labTotal
            self.m_vecLabOf[#self.m_vecLabOf + 1] = labOf
            self.m_vecLabCount[#self.m_vecLabCount + 1] = labCount
            labTotal:setVisible(false)
            labOf:setVisible(false)
            labCount:setVisible(false)
            -- nodeRespin:setVisible(false)
        else
            break
        end
        index = index + 1
    end

    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end

function EgyptCollectBar:updateUI(vecNum, isRespin)
    for i = 1, #self.m_vecLabCollect, 1 do
        self.m_vecLabCollect[i]:setString(vecNum[i])
    end
end

function EgyptCollectBar:changeCollectNum(col, num)
    self.m_vecLabCollect[col]:setString(num)
end

function EgyptCollectBar:getLabArray()
    return self.m_vecLabCollect
end

function EgyptCollectBar:addEffect(col, num)
    local effectNode, effectAct = util_csbCreate("Socre_Egypt_bonus_fankui.csb")
    self.m_vecLabCollect[col]:getParent():addChild(effectNode)
    effectNode:setPosition(self.m_vecLabCollect[col]:getPositionX(), self.m_vecLabCollect[col]:getPositionY())
    util_csbPlayForKey(effectAct, "actionframe", false, function ()
        effectNode:removeFromParent()
    end)
    performWithDelay(self, function()
        self:changeCollectNum(col, num)
    end, 0.25)
end

function EgyptCollectBar:onEnter()
 
end

function EgyptCollectBar:changeRespinUI(col, total, count, func)
    self.m_vecSpinCount[col] = total - count
    self.m_vecLabCount[col]:setString(self.m_vecSpinCount[col])
    self.m_vecLabTotal[col]:setString(total)
    
    self:runCsbAction("animation"..col)
    gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_collect_effect.mp3")
    local effectNode, effectAct = util_csbCreate("Socre_Egypt_bonus_fankui.csb")
    self.m_vecLabCollect[col]:getParent():addChild(effectNode)
    effectNode:setPosition(self.m_vecLabCollect[col]:getPositionX(), self.m_vecLabCollect[col]:getPositionY())
    util_csbPlayForKey(effectAct, "StartClassic", false, function ()
        if func then
            func()
        end
        effectNode:removeFromParent()
    end)
    performWithDelay(self, function()
        self.m_vecLabCollect[col]:setVisible(false)
        -- self.m_vecNodeRespin[col]:setVisible(true)
        self.m_vecLabTotal[col]:setVisible(true)
        self.m_vecLabOf[col]:setVisible(true)
        self.m_vecLabCount[col]:setVisible(true)
    end, 0.25)
end

function EgyptCollectBar:changeRespinNum(col)
    self.m_vecSpinCount[col] = self.m_vecSpinCount[col] + 1
    self.m_vecLabCount[col]:setString(self.m_vecSpinCount[col])
end

function EgyptCollectBar:initFsRespinUI(col, total, count)
    self.m_vecLabCollect[col]:setVisible(false)
    -- self.m_vecNodeRespin[col]:setVisible(true)
    self.m_vecLabTotal[col]:setVisible(true)
    self.m_vecLabOf[col]:setVisible(true)
    self.m_vecLabCount[col]:setVisible(true)
    self.m_vecLabCount[col]:setString(total - count)
    self.m_vecLabTotal[col]:setString(total)
end

function EgyptCollectBar:resetLabNum()
    for i = 1, #self.m_vecLabCollect, 1 do
        self.m_vecLabCollect[i]:setString(0)
        self.m_vecLabCollect[i]:setVisible(true)
        -- self.m_vecNodeRespin[i]:setVisible(false)
        self.m_vecLabTotal[i]:setVisible(false)
        self.m_vecLabOf[i]:setVisible(false)
        self.m_vecLabCount[i]:setVisible(false)
        self.m_vecSpinCount[i] = 0
    end
    self:runCsbAction("idle", true)
end

function EgyptCollectBar:onExit()
 
end

--默认按钮监听回调
function EgyptCollectBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return EgyptCollectBar