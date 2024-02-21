---
--xcyy
--2018年5月23日
--GirlsMagicBonusShowChooseView.lua

local GirlsMagicBonusShowChooseView = class("GirlsMagicBonusShowChooseView",util_require("base.BaseView"))

local BTN_TAG_SURE      =       1001        --确定
local BTN_TAG_CANCLE    =       1002        --取消

function GirlsMagicBonusShowChooseView:initUI(params)
    self:createCsbNode("GirlsMagic_YourDress_0.csb")

    self.m_parentView = params.parent
    self.m_machine = params.machine
    self.m_choose = {}

    self.m_node_clothes = self:findChild("Node_ren")

    self:findChild("Button_yes"):setTag(BTN_TAG_SURE)
    self:findChild("Button_no"):setTag(BTN_TAG_CANCLE)
end

--默认按钮监听回调
function GirlsMagicBonusShowChooseView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    self:stopAllActions()
    if tag == BTN_TAG_SURE then
        self.m_parentView:sendData(self.m_choose)
    else
        self.m_parentView:resetPadForRestart()
        self:hideView()
    end
end

function GirlsMagicBonusShowChooseView:onEnter()
   
end

function GirlsMagicBonusShowChooseView:onExit()
end

--[[
    显示界面
]]
function GirlsMagicBonusShowChooseView:showView(choose)
    local node = cc.Node:create()
    self.m_choose = choose
    --创建选择的衣服
    for index = 1,#choose do
        local spine = self.m_machine.m_spineManager:getChooseClothes(index,choose[index],false,true)
        node:addChild(spine)
        if index == 2 then
            spine:setLocalZOrder(10)
        else
            spine:setLocalZOrder(index)
        end
    end

    --展示动画
    self.m_node_clothes:removeAllChildren(true)
    self.m_node_clothes:addChild(node)
    self:setVisible(true)
    -- gLobalSoundManager:playSound("GirlsMagicSounds/sound_GirlsMagic_show_my_clothes.mp3")
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)

    if globalData.slotRunData.m_isNewAutoSpin and globalData.slotRunData.m_isAutoSpinAction then
        performWithDelay(self,function()
            self:clickFunc(self:findChild("Button_yes"))
        end,8)
    end
end

--[[
    隐藏界面
]]
function GirlsMagicBonusShowChooseView:hideView()
    self:setVisible(false)
end

return GirlsMagicBonusShowChooseView