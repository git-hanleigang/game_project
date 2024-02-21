---
--xcyy
--2018年5月23日
--GirlsMagicBonusIpadView.lua

local GirlsMagicBonusIpadView = class("GirlsMagicBonusIpadView",util_require("base.BaseView"))

local COLOR_RED         =       1       --红色
local COLOR_BULE        =       2       --蓝色
local COLOR_CYAN        =       3       --青色
local COLOR_YELLOW      =       4       --黄色

local COLOR_NODE = {
    [COLOR_RED] = "color_3",
    [COLOR_BULE] = "color_4",
    [COLOR_CYAN] = "color_1",
    [COLOR_YELLOW] = "color_2",
}

local BAG_TYPE_BROWN                =       1       --棕色包
local BAG_TYPE_PURPLE               =       2       --紫色包
local BAG_TYPE_BULE                 =       3       --蓝色包

local BAG_NODE = {
    [BAG_TYPE_BROWN] = "bag_1",
    [BAG_TYPE_PURPLE] = "bag_2",
    [BAG_TYPE_BULE] = "bag_3",
}

local PATTERN_TYPE_WHITE            =       1       --白色花纹
local PATTERN_TYPE_BROWN            =       2       --棕色花纹

local PATTERN_NODE = {
    [PATTERN_TYPE_WHITE] = "pattern_1",
    [PATTERN_TYPE_BROWN] = "pattern_2",
}

local MUTIPLES = {40,30,20}

local MAX_AUTO_TIME     =       4   --最大自动选择时间

function GirlsMagicBonusIpadView:initUI(params)
    self:createCsbNode("GirlsMagic_ipad.csb")

    self.m_parentView = params.parent

    local lbl_color = self:findChild("m_lb_num_color")
    local lbl_bag = self:findChild("m_lb_num_bag")
    local lbl_pattern = self:findChild("m_lb_num_pattern")
    lbl_color:setString("X"..MUTIPLES[1])
    lbl_bag:setString("X"..MUTIPLES[2])
    lbl_pattern:setString("X"..MUTIPLES[3])

    self.m_layouts_color = {}
    self.m_layouts_bag = {}
    self.m_layouts_pattern = {}

    --添加点击
    for index = 1,4 do
        if index <= 2 then
            local layout_pattern = self:createClickNode(self:findChild(PATTERN_NODE[index]),index)
            table.insert(self.m_layouts_pattern,#self.m_layouts_pattern + 1,layout_pattern)
        end

        if index <= 3 then
            local layout_bag = self:createClickNode(self:findChild(BAG_NODE[index]),index)
            table.insert(self.m_layouts_bag,#self.m_layouts_bag + 1,layout_bag)
        end

        local layout_color = self:createClickNode(self:findChild(COLOR_NODE[index]),index)
        table.insert(self.m_layouts_color,#self.m_layouts_color + 1,layout_color)
    end

    self.m_select_index = 1

    self.m_choose = {}
end

--[[
    重置状态
]]
function GirlsMagicBonusIpadView:resetStatus(choose)
    self.m_select_index = 1
    self.m_isWaitting = false
    self.m_choose = {}
    self:pauseForIndex(0)
end
--[[
    创建点击区域
]]
function GirlsMagicBonusIpadView:createClickNode(node,tag)
    local layout = ccui.Layout:create() 
    node:addChild(layout)    
    local nodeSize = node:getContentSize()
    layout:setAnchorPoint(0.5,0.5)
    layout:setContentSize(nodeSize)
    layout:setPosition(cc.p(nodeSize.width / 2,nodeSize.height / 2))
    layout:setTouchEnabled(true)
    layout:setTag(tag)
    self:addClick(layout)
    return layout
end

--默认按钮监听回调
function GirlsMagicBonusIpadView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_ipad_btn_click.mp3")
    --防止重复点击
    if self.m_isWaitting or self.m_parentView.m_isWaiting or self.m_select_index > 3 or self.m_choose[self.m_select_index] == tag then
        return
    end

    self.m_choose[self.m_select_index] = tag

    self.m_parentView:changeCloth(self.m_select_index,tag)
    local clickAni = util_createAnimation("GirlsMagic_ipad_L.csb")
    sender:addChild(clickAni)
    clickAni:runCsbAction("actionframe1",false,function(  )
        clickAni:removeFromParent(true)
    end)
end

--[[
    判断当前是否已选择
]]
function GirlsMagicBonusIpadView:isChoosed()
    if self.m_choose[self.m_select_index] then
        return true
    end

    return false
end

--[[
    变换选项
]]
function GirlsMagicBonusIpadView:changeOption()

    self:stopDelayFuncAct(self)
    self.m_isWaitting = true
    --选择结束
    if self.m_select_index > 3 then
        util_csbPauseForIndex(self.m_csbAct,315)
        return self.m_select_index
    end

    
    if self.m_select_index == 1 then    --选择颜色
        self:runCsbAction("start",false,function(  )
            self:runIdleAni("idle1")
            self.m_isWaitting = false
        end)
    elseif self.m_select_index == 2 then    --选择配饰
        self:runCsbAction("switch1_2",false,function(  )
            self:runIdleAni("idle2")
            self.m_isWaitting = false
        end)
    else    --选择花纹
        self:runCsbAction("switch2_3",false,function(  )
            self:runIdleAni("idle3")
            self.m_isWaitting = false
        end)
    end
    return self.m_select_index
end

function GirlsMagicBonusIpadView:resetForRestart()
    self.m_select_index = 1
    self:runIdleAni("idle1")
    self.m_isWaitting = false
end

--[[
    idle动画
]]
function GirlsMagicBonusIpadView:runIdleAni(aniName)
    self:runCsbAction(aniName)
    self:addDelayFuncAct(self,aniName,function(  )
        self:runIdleAni(aniName)
    end)
end

--添加动画回调(用延迟)
function GirlsMagicBonusIpadView:addDelayFuncAct(animationNode, animationName, func)
    self:stopDelayFuncAct(animationNode)
    
    animationNode.m_runDelayFuncAct =
        performWithDelay(
        animationNode,
        function()
            animationNode.m_runDelayFuncAct = nil
            if func then
                func()
            end
        end,
        util_csbGetAnimTimes(animationNode.m_csbAct, animationName)
    )
end
--停止动画回调
function GirlsMagicBonusIpadView:stopDelayFuncAct(animationNode)
    if animationNode and animationNode.m_runDelayFuncAct then
        animationNode:stopAction(animationNode.m_runDelayFuncAct)
        animationNode.m_runDelayFuncAct = nil
    end
end

--[[
    获取选择
]]
function GirlsMagicBonusIpadView:getChoosed()
    return self.m_choose
end

--[[
    改变当前进度
]]
function GirlsMagicBonusIpadView:changeCurStep(step)
    self.m_select_index = self.m_select_index + step
    if self.m_select_index <= 1 then
        self.m_select_index = 1
    end
end

--[[
    获取当前选择进度
]]
function GirlsMagicBonusIpadView:getCurIndex( )
    return self.m_select_index
end

function GirlsMagicBonusIpadView:onEnter()
   
end

function GirlsMagicBonusIpadView:onExit()
end

return GirlsMagicBonusIpadView