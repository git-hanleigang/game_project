---
--xcyy
--2018年5月23日
--GhostBlasterEnemyItem.lua
local PublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterEnemyItem = class("GhostBlasterEnemyItem",util_require("base.BaseView"))

local MAX_HP = 5
local BOX_CONFIG = {
    "GhostBlaster_Box_Red",
    "GhostBlaster_Box_Blur",
    "GhostBlaster_Box_Green"
}

function GhostBlasterEnemyItem:initUI(params)
    self.m_parentView = params.parent
    self.m_machine = params.machine
    
    self.m_index = params.index
    self.m_spineName = params.spineName
    self.m_spineType = params.spineType
    self.m_ghostAni = util_spineCreate(self.m_spineName,true,true)
    self:addChild(self.m_ghostAni)

    self.m_isShowBox = false

    --宝箱
    self.m_boxAni = util_spineCreate(BOX_CONFIG[self.m_spineType],true,true)
    self:addChild(self.m_boxAni)
    self.m_boxAni:setVisible(false)

    self:runGhostIdleAni()
    
    self.m_hp = MAX_HP

    self.m_hpSign = util_createAnimation("GhostBlaster_xuetiao.csb")
    self:addChild(self.m_hpSign)
    self.m_hpSign:setPositionY(100)

    for index = 1,3 do
        self.m_hpSign:findChild("Node_"..index):setVisible(index == self.m_spineType)
    end

    --开始飞金币节点
    self.m_coinsNodes = {}
    for index = 1,6 do
        local node = cc.Node:create()
        self:addChild(node)

        self.m_coinsNodes[index] = node

        local posX = -20 + math.floor((index - 1) / 3) * 40
        local posY = 90 + math.floor((index - 1) % 3) * 50
        node:setPosition(cc.p(posX,posY))
    end
end

--[[
    重置界面
]]
function GhostBlasterEnemyItem:resetView(hp)
    self:setCurHp(hp)

    local boxPos = util_convertToNodeSpace(self.m_machine:findChild("Node_freebox"..self.m_index.."_0"),self)
    self.m_boxAni:setPosition(boxPos)

    if hp <= 0 then
        self.m_hpSign:setVisible(false)
    else
        self.m_hpSign:setVisible(true)
        self.m_hpSign:runCsbAction("idleframe")
    end

    self.m_isShowBox = false
    if self:isDefeat() then
        self.m_boxAni:setVisible(true)
        self.m_ghostAni:setVisible(false)
        self.m_isShowBox = true
    else
        self.m_boxAni:setVisible(false)
        self.m_ghostAni:setVisible(true)
        self.m_isShowBox = false
    end
end

--[[
    设置当前血量
]]
function GhostBlasterEnemyItem:setCurHp(hp)
    if hp <= 0 then
        hp = 0
    end
    self.m_hp = hp
    for index = 1,5 do
        self.m_hpSign:findChild("Node_"..self.m_spineType.."_"..index):setVisible(index <= hp)
    end
end

function GhostBlasterEnemyItem:isDefeat()
    return self.m_hp <= 0
end

--[[
    受击动效
]]
function GhostBlasterEnemyItem:hitGhostAni(hp,coins,count,func)
    if self.m_hp > 0 then
        -- self.m_hpSign:runCsbAction("over")
    end
    local sound
    if self.m_hp == MAX_HP then
        if self.m_index == 1 or self.m_index == 5 then
            gLobalSoundManager:playSound(PublicConfig.Music_FeedBack_Green)
        elseif self.m_index == 2 or self.m_index == 4 then
            gLobalSoundManager:playSound(PublicConfig.Music_FeedBack_Blue)
        else
            gLobalSoundManager:playSound(PublicConfig.Music_FeedBack_Red)
        end
    end
    self:setCurHp(hp)

    if hp > 0 then
        --小鬼还没被打死
        gLobalSoundManager:playSound(PublicConfig.Music_Shoot_FeedBack)
        util_spinePlay(self.m_ghostAni,"free_actionframe")
        util_spineEndCallFunc(self.m_ghostAni,"free_actionframe",function()
            if type(func) == "function" then
                func()
            end
        end)

        local pos = util_convertToNodeSpace(self,self.m_machine.m_effectNode)
        self.m_machine:hitGhostDropCoinsInFree(self.m_index,pos,false,"ghost")
    else
        --小鬼被打死变宝箱
        if not self.m_isShowBox then
            if self.m_index == 1 or self.m_index == 5 then
                gLobalSoundManager:playSound(PublicConfig.Music_Die_Green)
            elseif self.m_index == 2 or self.m_index == 4 then
                gLobalSoundManager:playSound(PublicConfig.Music_Die_Blue)
            else
                gLobalSoundManager:playSound(PublicConfig.Music_Die_Red)
            end
            self.m_isShowBox = true
            util_spinePlay(self.m_ghostAni,"free_over")
            util_spineEndCallFunc(self.m_ghostAni,"free_over",function()
                self.m_ghostAni:setVisible(false)
            end)

            local pos = util_convertToNodeSpace(self,self.m_machine.m_effectNode)
            self.m_machine:hitGhostDropCoinsInFree(self.m_index,pos,false,"change")

            self.m_hpSign:runCsbAction("over2",false,function()
                self.m_hpSign:setVisible(false)
            end)
            performWithDelay(self,function()
                self.m_boxAni:setVisible(true)
                --变宝箱动画
                gLobalSoundManager:playSound(PublicConfig.Music_Free_SmallBox_Down)
                util_spinePlay(self.m_boxAni,"start")
                util_spineEndCallFunc(self.m_boxAni,"start",function()
                    if type(func) == "function" then
                        func()
                    end
                end)
            end,20 / 30)
        else
            local pos = util_convertToNodeSpace(self.m_boxAni,self.m_machine.m_effectNode)
            self.m_machine:hitGhostDropCoinsInFree(self.m_index,pos,false,"box")
            --宝箱受击
            gLobalSoundManager:playSound(PublicConfig.Music_Free_Box_FeedBack)
            util_spinePlay(self.m_boxAni,"actionframe")
            util_spineEndCallFunc(self.m_boxAni,"actionframe",function()
                if type(func) == "function" then
                    func()
                end
            end)
        end
    end
    
end

--[[
    idle
]]
function GhostBlasterEnemyItem:runGhostIdleAni()
    util_spinePlay(self.m_ghostAni,"free_idleframe2",true)
    util_spinePlay(self.m_boxAni,"idle",true)
end

--[[
    获取飞金币起点
]]
function GhostBlasterEnemyItem:getFlyNode(index)
    while index > #self.m_coinsNodes do
        index = index - #self.m_coinsNodes
    end

    return self.m_coinsNodes[index]
end

return GhostBlasterEnemyItem