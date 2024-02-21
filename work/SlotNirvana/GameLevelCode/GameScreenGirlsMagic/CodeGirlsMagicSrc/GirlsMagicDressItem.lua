---
--xcyy
--2018年5月23日
--GirlsMagicDressItem.lua

local GirlsMagicDressItem = class("GirlsMagicDressItem",util_require("base.BaseView"))

local COLOR_RED         =       1       --红色
local COLOR_BULE        =       2       --蓝色
local COLOR_CYAN        =       3       --青色
local COLOR_YELLOW      =       4       --黄色
local COLOR_TYPE = {
    [COLOR_RED] = "hong",
    [COLOR_BULE] = "lan",
    [COLOR_CYAN] = "qing",
    [COLOR_YELLOW] = "huang"
}

local BAG_TYPE_BROWN                =       1       --棕色包
local BAG_TYPE_PURPLE               =       2       --紫色包
local BAG_TYPE_BULE                 =       3       --蓝色包
local BAG_TYPE = {
    [BAG_TYPE_BROWN] = "zong",
    [BAG_TYPE_PURPLE] = "fen",
    [BAG_TYPE_BULE] = "lan",
}

local PATTERN_TYPE_WHITE            =       1       --白色花纹
local PATTERN_TYPE_BROWN            =       2       --棕色花纹
local PATTERN_TYPE = {
    [PATTERN_TYPE_WHITE] = "bai",
    [PATTERN_TYPE_BROWN] = "zong",
}


function GirlsMagicDressItem:initUI(params)
    self:createCsbNode("GirlsMagic_Dress.csb")

    self.m_spineManager = params.spineManager
    --1 衣服颜色 2 配饰 3 花纹
    self.m_spines = {}

    --选中光效
    self.m_light = util_createAnimation("GirlsMagic_xuanzhongBG.csb")
    local parentNode = params.parentNode
    local scale = parentNode:getScale()
    self:findChild("Node"):addChild(self.m_light)
    self.m_light:setScale(1 + (1 - scale))
    self.m_light:setVisible(false)
end


function GirlsMagicDressItem:onEnter()
   
end

function GirlsMagicDressItem:onExit()

end

--[[
    选中光效
]]
function GirlsMagicDressItem:lightAni()
    self.m_light:setVisible(true)
    self.m_light:findChild("Particle_1"):resetSystem()
    self.m_light:runCsbAction("actionframe",false,function(  )
        self.m_light:setVisible(false)
    end)
end

--[[
    设置衣服
]]
function GirlsMagicDressItem:setDressInfo(clothType,udid)
    self.m_clothType = clothType
    self.m_udid = udid

    local node = self:findChild("Node_1")
    node:removeAllChildren(true)
    local spine_model = self.m_spineManager:getChooseClothes(-1,-1,true)
    node:addChild(spine_model)
    for index = 1,#clothType do
        local spine = self.m_spineManager:getChooseClothes(index,clothType[index],true,true)
        node:addChild(spine)
        if index == 2 then
            spine:setLocalZOrder(10)
        else
            spine:setLocalZOrder(index)
        end
        self.m_spines[index] = spine
    end

    local shadow = util_spineCreate("GirlsMagic_BonusSpin_pick3" ,true,true)
    node:addChild(shadow,20)
    util_spinePlay(shadow,"mask_idle",false)
    self.m_spines[4] = shadow
    shadow:setVisible(false)
end

--[[
    清空衣服
]]
function GirlsMagicDressItem:clearCloth()
    local node = self:findChild("Node_1")
    node:removeAllChildren(true)
end

--[[
    显示动画
]]
function GirlsMagicDressItem:showAni()
    self:runCsbAction("actionframe",false,function(  )
        self:runCsbAction("idle")
    end)
end

--[[
    显示阴影
]]
function GirlsMagicDressItem:showShadow()
    self.m_spines[4]:setVisible(true)
    util_spinePlay(self.m_spines[4],"mask_start")
    util_spineEndCallFunc(self.m_spines[4],"mask_start",handler(nil,function(  )
        util_spinePlay(self.m_spines[4],"mask_idle")
    end))
end

--[[
    隐藏阴影
]]
function GirlsMagicDressItem:hideShadow()
    self.m_spines[4]:setVisible(true)
    util_spinePlay(self.m_spines[4],"mask_over")
end

--[[
    匹配动画
]]
function GirlsMagicDressItem:matchAni(matchType)
    local ani1,ani2,matchIndex
    if matchType == "color" then
        matchIndex = 1
        local color = self.m_clothType[1]
        ani1 = "X_yifu_"..COLOR_TYPE[color].."_glow"
        ani2 = "X_yifu_"..COLOR_TYPE[color].."_idle"
    elseif matchType == "bag" then
        matchIndex = 2
        ani1 = "X_bao_"..BAG_TYPE[self.m_clothType[2]].."_glow"
        ani2 = "X_bao_"..BAG_TYPE[self.m_clothType[2]].."_idle"
    else
        matchIndex = 3
        ani1 = "X_huawen_"..PATTERN_TYPE[self.m_clothType[3]].."_glow"
        ani2 = "X_huawen_"..PATTERN_TYPE[self.m_clothType[3]].."_idle"
    end

    local color = self.m_clothType[1]
    self.m_spines[4]:setVisible(true)
    util_spinePlay(self.m_spines[4],"mask_over")

    --提高展示动画层级
    util_spinePlay(self.m_spines[matchIndex],ani1)
    util_spineEndCallFunc(self.m_spines[matchIndex],ani1,handler(nil,function(  )
        util_spinePlay(self.m_spines[matchIndex],ani2)
    end))

    --缩放动作
    local seq = cc.Sequence:create({
        cc.DelayTime:create(1.33),
        cc.CallFunc:create(function(  )
            self:lightAni()
        end),
        cc.ScaleTo:create(0.5,1.2),
        cc.ScaleTo:create(0.5,1),
        cc.DelayTime:create(1.5),
        cc.CallFunc:create(function(  )
            self:showShadow()
        end)
    }) 
    self:runAction(seq)
end



return GirlsMagicDressItem